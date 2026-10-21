-- FlyAntiCheatLab.server.lua
-- Place in ServerScriptService. Replace the example ID below.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AUTHORIZED_USER_IDS = {
    [123456789] = true, -- TODO: replace with your Roblox user ID
}

local MAX_TEST_SPEED = 100
local MAX_UPWARD_SPEED = 45
local SAMPLE_INTERVAL = 0.5
local REQUIRED_HITS = 4

local folder = ReplicatedStorage:FindFirstChild("FlyAntiCheatLab") or Instance.new("Folder")
folder.Name = "FlyAntiCheatLab"
folder.Parent = ReplicatedStorage

local event = folder:FindFirstChild("TestControl") or Instance.new("RemoteEvent")
event.Name = "TestControl"
event.Parent = folder

local status = folder:FindFirstChild("TestStatus") or Instance.new("RemoteEvent")
status.Name = "TestStatus"
status.Parent = folder

local sessions = {}
local samples = {}

local function allowed(player)
    return AUTHORIZED_USER_IDS[player.UserId] == true
end

event.OnServerEvent:Connect(function(player, action, value)
    if not allowed(player) then
        warn(("[FlyLab] Unauthorized control attempt: %s (%d)"):format(player.Name, player.UserId))
        return
    end

    if action == "Enable" then
        local speed = math.clamp(tonumber(value) or 30, 1, MAX_TEST_SPEED)
        sessions[player] = { speed = speed, started = os.clock() }
        samples[player] = { hits = 0, last = 0 }
        status:FireClient(player, true, "Test session enabled. Check server Output.")
        print(("[FlyLab] Session enabled for %s, requested test speed %.1f"):format(player.Name, speed))
    elseif action == "Disable" then
        sessions[player] = nil
        samples[player] = nil
        status:FireClient(player, false, "Test session disabled.")
        print(("[FlyLab] Session disabled for %s"):format(player.Name))
    elseif action == "Speed" and sessions[player] then
        sessions[player].speed = math.clamp(tonumber(value) or 30, 1, MAX_TEST_SPEED)
    end
end)

local accumulator = 0
RunService.Heartbeat:Connect(function(dt)
    accumulator += dt
    if accumulator < SAMPLE_INTERVAL then return end
    accumulator = 0

    for player, session in pairs(sessions) do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid or humanoid.Health <= 0 then
            samples[player] = { hits = 0, last = 0 }
            continue
        end

        local now = os.clock()
        local state = samples[player] or { hits = 0, last = 0 }
        local verticalVelocity = root.AssemblyLinearVelocity.Y
        local horizontalSpeed = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude

        -- Illustrative heuristic only: sustained high upward and horizontal speed while airborne.
        local suspicious = humanoid.FloorMaterial == Enum.Material.Air
            and verticalVelocity > MAX_UPWARD_SPEED
            and horizontalSpeed > session.speed * 0.8

        if suspicious then
            state.hits += 1
        else
            state.hits = math.max(0, state.hits - 1)
        end

        if state.hits >= REQUIRED_HITS and now - state.last > 3 then
            state.last = now
            warn(("[FlyLab] REVIEW FLAG: %s | horizontal=%.1f | vertical=%.1f")
                :format(player.Name, horizontalSpeed, verticalVelocity))
            status:FireClient(player, true, "Suspicious movement logged. Review server Output.")
        end

        samples[player] = state
    end
end)

Players.PlayerRemoving:Connect(function(player)
    sessions[player] = nil
    samples[player] = nil
end)
