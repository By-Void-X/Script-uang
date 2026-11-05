-- Language: Lua | Runtime: Roblox Delta Android
-- Mobile draggable GUI with movement controls

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local old = game:GetService("CoreGui"):FindFirstChild("VantaMobile")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "VantaMobile"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

local function round(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = obj
end

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(250, 310)
main.Position = UDim2.new(0.5, -125, 0.3, 0)
main.BackgroundColor3 = Color3.fromRGB(19, 22, 32)
main.BorderSizePixel = 0
main.Parent = gui
round(main, 14)

local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, 45)
header.BackgroundColor3 = Color3.fromRGB(35, 95, 180)
header.Text = "VANTA MOBILE"
header.TextColor3 = Color3.new(1,1,1)
header.TextSize = 17
header.Font = Enum.Font.GothamBold
header.Parent = main
round(header, 12)

-- Drag support for touch and mouse
local dragging = false
local dragStart, startPos

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement
    ) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

local floating = Instance.new("TextButton")
floating.Size = UDim2.fromOffset(48, 48)
floating.Position = UDim2.new(0, 15, 0.5, 0)
floating.Text = "V"
floating.TextSize = 22
floating.Font = Enum.Font.GothamBold
floating.TextColor3 = Color3.new(1,1,1)
floating.BackgroundColor3 = Color3.fromRGB(35, 125, 255)
floating.Parent = gui
round(floating, 24)

floating.Activated:Connect(function()
    main.Visible = not main.Visible
end)

local function getHumanoid()
    local char = player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local speed = false
local multiJump = false

local function makeButton(text, y, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -20, 0, 42)
    b.Position = UDim2.fromOffset(10, y)
    b.BackgroundColor3 = Color3.fromRGB(43, 51, 70)
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 14
    b.Text = text
    b.Parent = main
    round(b, 9)
    b.Activated:Connect(callback)
    return b
end

local speedButton = makeButton("SPEED : OFF", 60, function()
    speed = not speed
    speedButton.Text = "SPEED : " .. (speed and "ON" or "OFF")
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = speed and 28 or 16 end
end)

local jumpButton = makeButton("MULTI JUMP : OFF", 110, function()
    multiJump = not multiJump
    jumpButton.Text = "MULTI JUMP : " .. (multiJump and "ON" or "OFF")
end)

makeButton("JUMP", 160, function()
    local hum = getHumanoid()
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

player.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    task.wait(0.2)
    hum.WalkSpeed = speed and 28 or 16
end)

UIS.JumpRequest:Connect(function()
    if multiJump then
        local hum = getHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

print("VANTA MOBILE READY")
