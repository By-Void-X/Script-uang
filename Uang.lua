-- Universal Hub | Fly + MultiJump + Speed + ESP + Aimbot + TP
-- Delta Executor Compatible (Mobile/HP)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--= STATE =--
local State = {
    Fly = false,
    FlySpeed = 50,
    MultiJump = false,
    Speed = false,
    SpeedValue = 50,
    ESP = false,
    Aimbot = false,
    AimSmooth = 0.25,
}

--= FUNGSI DASAR =--
local function getRoot()
    local char = LocalPlayer.Character
    if char then return char:FindFirstChild("HumanoidRootPart") end
end

local function getHum()
    local char = LocalPlayer.Character
    if char then return char:FindFirstChildOfClass("Humanoid") end
end

--= FLY =--
local flyVelocity, flyGyro

local function startFly()
    local root = getRoot()
    if not root then return end

    flyVelocity = Instance.new("BodyVelocity")
    flyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    flyVelocity.Velocity = Vector3.zero
    flyVelocity.Parent = root

    flyGyro = Instance.new("BodyGyro")
    flyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    flyGyro.P = 9e4
    flyGyro.Parent = root

    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not State.Fly then conn:Disconnect() return end
        local root = getRoot()
        if not root then conn:Disconnect() return end

        local cam = Camera.CFrame
        local move = Vector3.zero

        -- arah berdasarkan kamera
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.RightVector end

        -- tombol naik/turun (untuk HP pakai tombol GUI)
        if flyUp then move += Vector3.new(0,1,0) end
        if flyDown then move -= Vector3.new(0,1,0) end

        flyVelocity.Velocity = move.Magnitude > 0 and move.Unit * State.FlySpeed or Vector3.zero
        flyGyro.CFrame = CFrame.new(root.Position, root.Position + cam.LookVector)
    end)
end

local function stopFly()
    State.Fly = false
    if flyVelocity then flyVelocity:Destroy() flyVelocity = nil end
    if flyGyro then flyGyro:Destroy() flyGyro = nil end
end

local flyUp, flyDown = false, false

--= MULTIPLE JUMP (SPAM) =--
task.spawn(function()
    while task.wait(0.1) do
        if State.MultiJump then
            local hum = getHum()
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

--= SPEED HACK =--
task.spawn(function()
    while task.wait(0.2) do
        local hum = getHum()
        if hum then
            if State.Speed then
                hum.WalkSpeed = State.SpeedValue
            elseif hum.WalkSpeed ~= 16 then
                hum.WalkSpeed = 16
            end
        end
    end
end)

--= ESP (Highlight + Line) =--
local espFolder = {}
local lines = {}

local function clearESP()
    for _,v in pairs(espFolder) do
        if v then v:Destroy() end
    end
    espFolder = {}
    for _,v in pairs(lines) do
        if v then v:Remove() end
    end
    lines = {}
end

local function setupESP(plr)
    local function add(char)
        if char == LocalPlayer.Character then return end
        local hl = Instance.new("Highlight")
        hl.FillColor = Color3.fromRGB(255, 0, 0)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.5
        hl.Parent = char
        espFolder[plr.Name.."_hl"] = hl

        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = Color3.fromRGB(0, 255, 0)
        line.Thickness = 1
        lines[plr.Name] = line
    end

    if plr.Character then add(plr.Character) end
    plr.CharacterAdded:Connect(function(c)
        task.wait(0.5)
        if State.ESP then add(c) end
    end)
end

local function toggleESP(on)
    if not on then clearESP() return end
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then setupESP(plr) end
    end
end

RunService.RenderStepped:Connect(function()
    if not State.ESP then return end
    local root = getRoot()
    if not root then return end

    local screenPos, _ = Camera:WorldToViewportPoint(root.Position)

    for name, line in pairs(lines) do
        local plr = Players:FindFirstChild(name)
        if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local pos, onScreen = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
            if onScreen then
                line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                line.To = Vector2.new(pos.X, pos.Y)
                line.Visible = true
            else
                line.Visible = false
            end
        end
    end
end)

--= AIMBOT SMOOTH =--
RunService.RenderStepped:Connect(function()
    if not State.Aimbot then return end
    local root = getRoot()
    if not root then return end

    local nearest, nearestDist = nil, math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if head and hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                    if dist < nearestDist then
                        nearest = head
                        nearestDist = dist
                    end
                end
            end
        end
    end

    if nearest then
        local targetCFrame = CFrame.new(Camera.CFrame.Position, nearest.Position)
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, State.AimSmooth)
    end
end)

--= TP KE PLAYER =--
local function tpToPlayer(targetName)
    local target = Players:FindFirstChild(targetName)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local root = getRoot()
        if root then
            root.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
        end
    end
end

--= GUI UTAMA =--
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UniversalHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 220, 0, 380)
Main.Position = UDim2.new(0, 10, 0.3, 0)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "⚡ UNIVERSAL HUB"
Title.TextColor3 = Color3.fromRGB(0, 255, 128)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.Parent = Main

local function makeButton(text, posY, callback, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 32)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.BackgroundColor3 = color or Color3.fromRGB(45, 45, 60)
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 14
    btn.Font = Enum.Font.Gotham
    btn.Parent = Main
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local flyBtn = makeButton("✈️ Fly: OFF", 45, function()
    State.Fly = not State.Fly
    if State.Fly then startFly() else stopFly() end
    flyBtn.Text = "✈️ Fly: " .. (State.Fly and "ON" or "OFF")
end, State.Fly and Color3.fromRGB(0,120,60) or Color3.fromRGB(45,45,60))

-- Tombol Naik & Turun untuk Fly (khusus HP)
local upBtn = makeButton("⬆️ NAIK", 85, function()
    flyUp = not flyUp
    upBtn.Text = flyUp and "⬆️ NAIK (AKTIF)" or "⬆️ NAIK"
end, Color3.fromRGB(30,30,120))

local downBtn = makeButton("⬇️ TURUN", 125, function()
    flyDown = not flyDown
    downBtn.Text = flyDown and "⬇️ TURUN (AKTIF)" or "⬇️ TURUN"
end, Color3.fromRGB(30,30,120))

local jumpBtn = makeButton("🦘 Multi Jump: OFF", 165, function()
    State.MultiJump = not State.MultiJump
    jumpBtn.Text = "🦘 Multi Jump: " .. (State.MultiJump and "ON" or "OFF")
end)

local speedBtn = makeButton("🏃 Speed: OFF", 205, function()
    State.Speed = not State.Speed
    speedBtn.Text = "🏃 Speed: " .. (State.Speed and "ON" or "OFF")
end)

local espBtn = makeButton("👁️ ESP: OFF", 245, function()
    State.ESP = not State.ESP
    toggleESP(State.ESP)
    espBtn.Text = "👁️ ESP: " .. (State.ESP and "ON" or "OFF")
end)

local aimBtn = makeButton("🎯 Aimbot: OFF", 285, function()
    State.Aimbot = not State.Aimbot
    aimBtn.Text = "🎯 Aimbot: " .. (State.Aimbot and "ON" or "OFF")
end)

-- TP ke player terdekat
local tpBtn = makeButton("🌀 TP ke Player", 325, function()
    local root = getRoot()
    if not root then return end
    local nearest, dist = nil, math.huge
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local d = (plr.Character.HumanoidRootPart.Position - root.Position).Magnitude
            if d < dist then nearest = plr; dist = d end
        end
    end
    if nearest then tpToPlayer(nearest.Name) end
end, Color3.fromRGB(80,40,120))

-- Tombol minimize
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 30, 0, 30)
minBtn.Position = UDim2.new(1, -35, 0, 2)
minBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
minBtn.Text = "—"
minBtn.TextColor3 = Color3.new(1,1,1)
minBtn.TextSize = 18
minBtn.Font = Enum.Font.GothamBold
minBtn.Parent = Main
local mc = Instance.new("UICorner")
mc.CornerRadius = UDim.new(1, 0)
mc.Parent = minBtn

local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    for _,child in pairs(Main:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then
            if child ~= minBtn and child ~= Title then
                child.Visible = not minimized
            end
        end
    end
    Main.Size = minimized and UDim2.new(0, 220, 0, 40) or UDim2.new(0, 220, 0, 380)
end)

print("✅ Universal Hub loaded!")
