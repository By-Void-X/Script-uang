-- Language: Lua | Runtime: Roblox Delta Android
-- VANTA Ultimate Mobile GUI

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

local old = CoreGui:FindFirstChild("VANTA_ULTIMATE")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "VANTA_ULTIMATE"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = obj
end

local function create(class, props, parent)
    local obj = Instance.new(class)
    for k,v in pairs(props) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local main = create("Frame", {
    Size = UDim2.fromOffset(270, 390),
    Position = UDim2.new(.5, -135, .25, 0),
    BackgroundColor3 = Color3.fromRGB(18, 22, 33),
    BorderSizePixel = 0
}, gui)
corner(main, 14)

local header = create("TextButton", {
    Size = UDim2.new(1, 0, 0, 45),
    BackgroundColor3 = Color3.fromRGB(30, 110, 220),
    Text = "VANTA ULTIMATE  |  MOBILE",
    TextColor3 = Color3.new(1,1,1),
    TextSize = 14,
    Font = Enum.Font.GothamBold
}, main)
corner(header, 12)

-- Draggable panel
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
        local d = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Floating toggle
local floating = create("TextButton", {
    Size = UDim2.fromOffset(50,50),
    Position = UDim2.new(0,15,.5,0),
    BackgroundColor3 = Color3.fromRGB(30,120,255),
    Text = "V",
    TextColor3 = Color3.new(1,1,1),
    TextSize = 22
}, gui)
corner(floating, 25)

floating.Activated:Connect(function()
    main.Visible = not main.Visible
end)

local function humanoid()
    local char = player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function root()
    local char = player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local states = {
    speed = false,
    multiJump = false,
    fly = false
}

local function button(label, y, callback)
    local b = create("TextButton", {
        Size = UDim2.new(1,-20,0,39),
        Position = UDim2.fromOffset(10,y),
        BackgroundColor3 = Color3.fromRGB(42,53,75),
        TextColor3 = Color3.new(1,1,1),
        TextSize = 14,
        Font = Enum.Font.GothamSemibold,
        Text = label
    }, main)
    corner(b,8)
    b.Activated:Connect(callback)
    return b
end

local speedButton
speedButton = button("SPEED : OFF",55,function()
    states.speed = not states.speed
    speedButton.Text = "SPEED : "..(states.speed and "ON" or "OFF")
    local h = humanoid()
    if h then h.WalkSpeed = states.speed and 28 or 16 end
end)

local jumpButton
jumpButton = button("MULTI JUMP : OFF",100,function()
    states.multiJump = not states.multiJump
    jumpButton.Text = "MULTI JUMP : "..(states.multiJump and "ON" or "OFF")
end)

local flyButton
flyButton = button("FLY : OFF",145,function()
    states.fly = not states.fly
    flyButton.Text = "FLY : "..(states.fly and "ON" or "OFF")
end)

-- Fly controls
local up = false
local down = false

local upButton = button("FLY UP ▲",190,function()
    up = not up
end)

local downButton = button("FLY DOWN ▼",235,function()
    down = not down
end)

local flySpeed = 45

local speedLabel = create("TextLabel", {
    Size = UDim2.new(1,-20,0,25),
    Position = UDim2.fromOffset(10,280),
    BackgroundTransparency = 1,
    Text = "FLY SPEED",
    TextColor3 = Color3.new(1,1,1),
    TextSize = 13
},main)

local speedSlider = create("TextBox", {
    Size = UDim2.new(1,-20,0,35),
    Position = UDim2.fromOffset(10,310),
    BackgroundColor3 = Color3.fromRGB(42,53,75),
    Text = "45",
    TextColor3 = Color3.new(1,1,1),
    TextSize = 14,
    ClearTextOnFocus = false
},main)
corner(speedSlider,8)

speedSlider.FocusLost:Connect(function()
    local n = tonumber(speedSlider.Text)
    if n then
        flySpeed = math.clamp(n,10,100)
        speedSlider.Text = tostring(flySpeed)
    else
        speedSlider.Text = tostring(flySpeed)
    end
end)

-- Movement controller
local velocity
local attachment

local function stopFly()
    if velocity then velocity:Destroy() velocity = nil end
    if attachment then attachment:Destroy() attachment = nil end
end

RunService.Heartbeat:Connect(function()
    local h = humanoid()
    local r = root()

    if not h or not r then
        stopFly()
        return
    end

    if states.speed then
        h.WalkSpeed = 28
    end

    if states.fly then
        if not attachment then
            attachment = Instance.new("Attachment")
            attachment.Parent = r
        end

        if not velocity then
            velocity = Instance.new("LinearVelocity")
            velocity.Attachment0 = attachment
            velocity.RelativeTo = Enum.ActuatorRelativeTo.World
            velocity.MaxForce = math.huge
            velocity.Parent = r
        end

        local direction = h.MoveDirection * flySpeed
        local vertical = (up and flySpeed or 0) - (down and flySpeed or 0)
        velocity.VectorVelocity = direction + Vector3.new(0,vertical,0)
        h:ChangeState(Enum.HumanoidStateType.Physics)
    else
        stopFly()
    end
end)

UIS.JumpRequest:Connect(function()
    if states.multiJump then
        local h = humanoid()
        if h then
            h:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

player.CharacterAdded:Connect(function(char)
    stopFly()
    task.wait(0.5)
    local h = char:WaitForChild("Humanoid")
    h.WalkSpeed = states.speed and 28 or 16
end)

print("VANTA ULTIMATE MOBILE LOADED")
