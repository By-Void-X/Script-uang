-- language: Lua, file: delta_cheat.lua, target: Roblox Delta / any executor with getgenv + Drawing
-- *re-derive offsets / method if game patches character or camera; standard LocalPlayer path*

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- // SETTINGS
local Settings = {
    Speed = 50,
    MultiJump = true,
    Fly = false,
    FlySpeed = 60,
    ESP = true,
    Aimbot = false,
    AimSmooth = 0.18,      -- lower = smoother
    AimFOV = 180,
    AimTeamCheck = false,
    MenuKey = Enum.KeyCode.RightControl,
}

-- // STATE
local Flying = false
local FlyBV = nil
local FlyBG = nil
local MenuOpen = true
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ESP_Container"
ESPFolder.Parent = game:GetService("CoreGui")

-- // GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaModMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 280, 0, 340)
Main.Position = UDim2.new(0.02, 0, 0.25, 0)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 36)
Title.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
Title.Text = "  DELTA  |  CHEAT"
Title.TextColor3 = Color3.fromRGB(220, 220, 230)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = Title

local function CreateToggle(name, y, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 32)
    frame.Position = UDim2.new(0, 10, 0, y)
    frame.BackgroundTransparency = 1
    frame.Parent = Main

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(200, 200, 210)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 48, 0, 22)
    btn.Position = UDim2.new(1, -52, 0.5, -11)
    btn.BackgroundColor3 = default and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(60, 60, 70)
    btn.Text = default and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(60, 60, 70)
        btn.Text = state and "ON" or "OFF"
        callback(state)
    end)
    return btn
end

local function CreateSlider(name, y, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 48)
    frame.Position = UDim2.new(0, 10, 0, y)
    frame.BackgroundTransparency = 1
    frame.Parent = Main

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. default
    label.TextColor3 = Color3.fromRGB(200, 200, 210)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.Parent = frame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 8)
    bar.Position = UDim2.new(0, 0, 0, 28)
    bar.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    bar.BorderSizePixel = 0
    bar.Parent = frame

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 4)
    barCorner.Parent = bar

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = fill

    local dragging = false
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            local val = math.floor(min + (max - min) * rel)
            label.Text = name .. ": " .. val
            callback(val)
        end
    end)
end

-- // TOGGLES
CreateToggle("Speed Hack", 50, true, function(v)
    Settings.Speed = v and Settings.Speed or 16
end)
CreateSlider("Walk Speed", 90, 16, 150, 50, function(v)
    Settings.Speed = v
end)
CreateToggle("Multi Jump", 145, true, function(v)
    Settings.MultiJump = v
end)
CreateToggle("Fly", 185, false, function(v)
    Settings.Fly = v
    if not v then
        Flying = false
        if FlyBV then FlyBV:Destroy() FlyBV = nil end
        if FlyBG then FlyBG:Destroy() FlyBG = nil end
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end)
CreateSlider("Fly Speed", 225, 20, 150, 60, function(v)
    Settings.FlySpeed = v
end)
CreateToggle("ESP Players", 280, true, function(v)
    Settings.ESP = v
    if not v then
        for _, c in pairs(ESPFolder:GetChildren()) do c:Destroy() end
    end
end)
CreateToggle("Smooth Aimbot", 320, false, function(v)
    Settings.Aimbot = v
end)

-- // SPEED
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and Settings.Speed > 16 then
        hum.WalkSpeed = Settings.Speed
    end
end)

-- // MULTI JUMP
local jumpsLeft = 0
UserInputService.JumpRequest:Connect(function()
    if not Settings.MultiJump then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if hum and root and hum:GetState() \~= Enum.HumanoidStateType.Dead then
        if jumpsLeft > 0 or hum.FloorMaterial == Enum.Material.Air then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            root.Velocity = Vector3.new(root.Velocity.X, 50, root.Velocity.Z)
            jumpsLeft = jumpsLeft - 1
        end
    end
end)
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.FloorMaterial \~= Enum.Material.Air then
        jumpsLeft = 3 -- hold jump for extra mid-air jumps
    end
end)

-- // FLY
local function StartFly()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    hum.PlatformStand = true
    FlyBV = Instance.new("BodyVelocity")
    FlyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    FlyBV.Velocity = Vector3.zero
    FlyBV.Parent = root

    FlyBG = Instance.new("BodyGyro")
    FlyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    FlyBG.P = 9e4
    FlyBG.Parent = root
    Flying = true
end

RunService.RenderStepped:Connect(function()
    if not Settings.Fly then return end
    if not Flying then StartFly() end
    local char = LocalPlayer.Character
    if not char or not FlyBV or not FlyBG then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local camCF = Camera.CFrame
    local dir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + camCF.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - camCF.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - camCF.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + camCF.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end

    if dir.Magnitude > 0 then
        FlyBV.Velocity = dir.Unit * Settings.FlySpeed
    else
        FlyBV.Velocity = Vector3.zero
    end
    FlyBG.CFrame = camCF
end)

-- // ESP
local function CreateESP(plr)
    if plr == LocalPlayer then return end
    local bill = Instance.new("BillboardGui")
    bill.Name = plr.Name
    bill.AlwaysOnTop = true
    bill.Size = UDim2.new(0, 120, 0, 40)
    bill.StudsOffset = Vector3.new(0, 3, 0)
    bill.Adornee = nil
    bill.Parent = ESPFolder

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = plr.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    nameLabel.TextStrokeTransparency = 0.4
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 13
    nameLabel.Parent = bill

    local hpLabel = Instance.new("TextLabel")
    hpLabel.Size = UDim2.new(1, 0, 0.5, 0)
    hpLabel.Position = UDim2.new(0, 0, 0.5, 0)
    hpLabel.BackgroundTransparency = 1
    hpLabel.Text = "HP: ?"
    hpLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
    hpLabel.TextStrokeTransparency = 0.4
    hpLabel.Font = Enum.Font.Gotham
    hpLabel.TextSize = 12
    hpLabel.Parent = bill

    return bill, nameLabel, hpLabel
end

local ESPCache = {}
RunService.RenderStepped:Connect(function()
    if not Settings.ESP then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr \~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if not ESPCache[plr] then
                local bill, nameL, hpL = CreateESP(plr)
                ESPCache[plr] = {bill = bill, name = nameL, hp = hpL}
            end
            local data = ESPCache[plr]
            data.bill.Adornee = plr.Character.HumanoidRootPart
            if hum then
                data.hp.Text = string.format("HP: %d", math.floor(hum.Health))
            end
        elseif ESPCache[plr] then
            ESPCache[plr].bill:Destroy()
            ESPCache[plr] = nil
        end
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    if ESPCache[plr] then
        ESPCache[plr].bill:Destroy()
        ESPCache[plr] = nil
    end
end)

-- // SMOOTH AIMBOT (closest visible in FOV)
local function GetClosest()
    local closest, dist = nil, Settings.AimFOV
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if Settings.AimTeamCheck and plr.Team == LocalPlayer.Team then continue end
        local char = plr.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local head = char:FindFirstChild("Head")
        if not hum or not head or hum.Health <= 0 then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if not onScreen then continue end
        local mousePos = Vector2.new(Mouse.X, Mouse.Y)
        local delta = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        if delta < dist then
            dist = delta
            closest = head
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if not Settings.Aimbot then return end
    local target = GetClosest()
    if not target then return end

    local cam = Camera.CFrame
    local goal = CFrame.new(cam.Position, target.Position)
    Camera.CFrame = cam:Lerp(goal, Settings.AimSmooth)
end)

-- // MENU TOGGLE
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Settings.MenuKey then
        MenuOpen = not MenuOpen
        Main.Visible = MenuOpen
    end
end)

-- // CLEAN ON RESPAWN
LocalPlayer.CharacterAdded:Connect(function()
    Flying = false
    if FlyBV then FlyBV:Destroy() FlyBV = nil end
    if FlyBG then FlyBG:Destroy() FlyBG = nil end
    task.wait(0.5)
    jumpsLeft = 3
end)

print("[DELTA] loaded | RightCtrl = menu")
