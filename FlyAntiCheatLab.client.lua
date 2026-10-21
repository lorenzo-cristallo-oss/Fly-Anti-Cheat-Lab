-- FlyAntiCheatLab.client.lua
-- Place in StarterPlayer > StarterPlayerScripts.
-- This UI starts/stops a server-side test session; it does not create flight.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local folder = ReplicatedStorage:WaitForChild("FlyAntiCheatLab")
local control = folder:WaitForChild("TestControl")
local status = folder:WaitForChild("TestStatus")

local gui = Instance.new("ScreenGui")
gui.Name = "FlyAntiCheatLabGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(310, 220)
frame.Position = UDim2.new(0.5, -155, 0.5, -110)
frame.BackgroundColor3 = Color3.fromRGB(24, 27, 35)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -48, 0, 38)
title.Position = UDim2.fromOffset(12, 0)
title.BackgroundTransparency = 1
title.Text = "FLY ANTI-CHEAT LAB"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(30, 28)
close.Position = UDim2.new(1, -36, 0, 5)
close.Text = "X"
close.Font = Enum.Font.GothamBold
close.TextSize = 14
close.TextColor3 = Color3.new(1, 1, 1)
close.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
close.Parent = frame
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)
close.MouseButton1Click:Connect(function() gui:Destroy() end)

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -24, 0, 24)
speedLabel.Position = UDim2.fromOffset(12, 45)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Test speed: 30"
speedLabel.TextColor3 = Color3.fromRGB(220, 225, 235)
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 13
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = frame

local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(1, -24, 0, 30)
speedBox.Position = UDim2.fromOffset(12, 70)
speedBox.BackgroundColor3 = Color3.fromRGB(39, 44, 56)
speedBox.TextColor3 = Color3.new(1, 1, 1)
speedBox.PlaceholderText = "1 - 100"
speedBox.Text = "30"
speedBox.ClearTextOnFocus = false
speedBox.Font = Enum.Font.Gotham
speedBox.TextSize = 14
speedBox.Parent = frame
Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0, 6)

local function makeButton(text, position, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.5, -18, 0, 34)
    b.Position = position
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Parent = frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local enable = makeButton("ENABLE TEST", UDim2.new(0, 12, 0, 110), Color3.fromRGB(45, 145, 95))
local disable = makeButton("DISABLE TEST", UDim2.new(0.5, 6, 0, 110), Color3.fromRGB(170, 65, 70))

local message = Instance.new("TextLabel")
message.Size = UDim2.new(1, -24, 0, 58)
message.Position = UDim2.fromOffset(12, 151)
message.BackgroundTransparency = 1
message.Text = "Authorized tester only. This panel does not enable flight."
message.TextWrapped = true
message.TextColor3 = Color3.fromRGB(170, 180, 195)
message.Font = Enum.Font.Gotham
message.TextSize = 11
message.Parent = frame

local function readSpeed()
    local n = math.clamp(tonumber(speedBox.Text) or 30, 1, 100)
    speedBox.Text = tostring(n)
    speedLabel.Text = "Test speed: " .. n
    return n
end

speedBox.FocusLost:Connect(function()
    control:FireServer("Speed", readSpeed())
end)
enable.MouseButton1Click:Connect(function()
    control:FireServer("Enable", readSpeed())
end)
disable.MouseButton1Click:Connect(function()
    control:FireServer("Disable")
end)

status.OnClientEvent:Connect(function(_, text)
    message.Text = text
end)

-- Drag by the title bar.
local dragging, dragStart, startPos
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
