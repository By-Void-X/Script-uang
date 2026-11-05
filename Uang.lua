-- Language: Lua | Runtime: Roblox Delta Executor | Android

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "VantaMobile"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(230, 280)
main.Position = UDim2.new(0, 20, 0.3, 0)
main.BackgroundColor3 = Color3.fromRGB(22, 25, 35)
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = main

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.fromOffset(48, 48)
toggle.Position = UDim2.new(0, 15, 0.5, 0)
toggle.Text = "V"
toggle.TextSize = 22
toggle.BackgroundColor3 = Color3.fromRGB(40, 130, 255)
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.Parent = gui

Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)

toggle.MouseButton1Click:Connect(function()
    main.Visible = not main.Visible
end)

local function createButton(name, y, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 38)
    button.Position = UDim2.fromOffset(10, y)
    button.Text = name
    button.TextSize = 14
    button.TextColor3 = Color3.new(1, 1, 1)
    button.BackgroundColor3 = Color3.fromRGB(45, 55, 75)
    button.Parent = main
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
    button.Activated:Connect(callback)
    return button
end

local fly = false
local speed = false
local jump = false
local flyConnection

local function getCharacter()
    return player.Character
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

createButton("FLY: OFF", 15, function()
    fly = not fly
    if fly then
        flyConnection = RunService.Heartbeat:Connect(function()
            local char = getCharacter()
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = getHumanoid()
            if root and hum then
                hum:ChangeState(Enum.HumanoidStateType.Freefall)
            end
        end)
    else
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
    end
end)

createButton("SPEED: ON/OFF", 60, function()
    speed = not speed
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = speed and 32 or 16
    end
end)

createButton("MULTI JUMP: ON/OFF", 105, function()
    jump = not jump
end)

createButton("JUMP NOW", 150, function()
    local hum = getHumanoid()
    if hum then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

UIS.JumpRequest:Connect(function()
    if jump then
        local hum = getHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

player.CharacterAdded:Connect(function(char)
    task.wait(1)
    local hum = char:WaitForChild("Humanoid")
    hum.WalkSpeed = speed and 32 or 16
end)

print("Vanta Mobile GUI Loaded")
