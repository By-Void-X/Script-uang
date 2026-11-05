-- Universal Mobile Cheat Menu | Untuk Delta Executor
-- Fitur: Speed, Multi Jump, Fly, ESP, Aimbot Smooth
-- Kompatibel: HP & PC

local Player = game:GetService("Players").LocalPlayer
local Mouse = Player:GetMouse()
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- GUI Utama
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VantaMenu"
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MenuFrame = Instance.new("Frame")
MenuFrame.Name = "MenuFrame"
MenuFrame.Size = UDim2.new(0, 260, 0, 380)
MenuFrame.Position = UDim2.new(0.02, 0, 0.5, -190)
MenuFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MenuFrame.BorderSizePixel = 2
MenuFrame.BorderColor3 = Color3.fromRGB(80, 180, 255)
MenuFrame.Active = true
MenuFrame.Draggable = true
MenuFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
Title.Text = "VANTA MENU"
Title.TextColor3 = Color3.fromRGB(120, 210, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = MenuFrame

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 60, 0, 60)
ToggleButton.Position = UDim2.new(0.93, -30, 0.5, -30)
ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 180, 255)
ToggleButton.Text = "M"
ToggleButton.TextColor3 = Color3.new(1,1,1)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 24
ToggleButton.Parent = ScreenGui

local function createToggle(parent, name, pos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.85, 0, 0, 38)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
    btn.BorderSizePixel = 1
    btn.BorderColor3 = Color3.fromRGB(100, 100, 120)
    btn.Text = name
    btn.TextColor3 = Color3.new(0.9,0.9,0.9)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.Parent = parent
    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(40, 160, 90) or Color3.fromRGB(60, 60, 75)
        callback(state)
    end)
    return btn
end

local function createSlider(parent, name, pos, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0.85, 0, 0, 50)
    container.Position = pos
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,0,20)
    label.Position = UDim2.new(0,0,0,0,0)
    label.Text = name .. ": " .. default
    label.TextColor3 = Color3.new(0.9,0.9,0.9)
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.BackgroundTransparency = 1
    label.Parent = container
    
    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1,0,0,12)
    barBg.Position = UDim2.new(0,0,0,28,0)
    barBg.BackgroundColor3 = Color3.fromRGB(50,50,65)
    barBg.Parent = container
    
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new((default-min)/(max-min),0,1,0)
    bar.BackgroundColor3 = Color3.fromRGB(60,180,255)
    bar.Parent = barBg
    
    local value = default
    local isDragging = false
    barBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = true end end)
    UIS.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = false end end)
    RunService.RenderStepped:Connect(function()
        if isDragging then
            local absPos = barBg.AbsolutePosition
            local absSize = barBg.AbsoluteSize
            local percent = math.clamp((Mouse.X - absPos.X) / absSize.X, 0, 1)
            value = min + (max - min) * percent
            label.Text = name .. ": " .. math.floor(value)
            bar.Size = UDim2.new(percent, 0, 1, 0)
            callback(value)
        end
    end)
    return container
end

-- Tampil/Sembunyikan Menu
local menuVisible = true
ToggleButton.MouseButton1Click:Connect(function()
    menuVisible = not menuVisible
    MenuFrame.Visible = menuVisible
end)

-- VARIABEL
local speedEnabled = false
local speedVal = 16
local jumpEnabled = false
local jumpCount = 0
local maxJumps = 2
local flyEnabled = false
local flySpeed = 16
local espEnabled = false
local aimEnabled = false
local aimSmooth = 8
local aimPart = "Head"

-- FUNGSI FITUR

-- Speed
createToggle(MenuFrame, "⚡ Speed Hack", UDim2.new(0.075,0,0.12,0), function(state)
    speedEnabled = state
end)
createSlider(MenuFrame, "Kecepatan", UDim2.new(0.075,0,0.20,0), 16, 250, 35, function(val)
    speedVal = val
end)

-- Multi Jump
createToggle(MenuFrame, "🦘 Multi Jump", UDim2.new(0.075,0,0.33,0), function(state)
    jumpEnabled = state
    jumpCount = 0
end)

-- Fly
createToggle(MenuFrame, "🕊️ Fly Mode", UDim2.new(0.075,0,0.43,0), function(state)
    flyEnabled = state
    if state then
        Player.Character.Humanoid.PlatformStand = true
    else
        Player.Character.Humanoid.PlatformStand = false
    end
end)

local flyBtnUp = Instance.new("TextButton")
flyBtnUp.Size = UDim2.new(0, 70, 0, 32)
flyBtnUp.Position = UDim2.new(0.075,0,0.53,0)
flyBtnUp.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
flyBtnUp.Text = "⬆️ Naik"
flyBtnUp.TextColor3 = Color3.new(1,1,1)
flyBtnUp.Font = Enum.Font.Gotham
flyBtnUp.TextSize = 11
flyBtnUp.Parent = MenuFrame

local flyBtnDown = Instance.new("TextButton")
flyBtnDown.Size = UDim2.new(0, 70, 0, 32)
flyBtnDown.Position = UDim2.new(0.45,0,0.53,0)
flyBtnDown.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
flyBtnDown.Text = "⬇️ Turun"
flyBtnDown.TextColor3 = Color3.new(1,1,1)
flyBtnDown.Font = Enum.Font.Gotham
flyBtnDown.TextSize = 11
flyBtnDown.Parent = MenuFrame

createSlider(MenuFrame, "Kecepatan Terbang", UDim2.new(0.075,0,0.62,0), 8, 120, 24, function(val)
    flySpeed = val
end)

-- ESP
createToggle(MenuFrame, "👁️ ESP Pemain", UDim2.new(0.075,0,0.74,0), function(state)
    espEnabled = state
end)

-- Aimbot
createToggle(MenuFrame, "🎯 Aimbot Smooth", UDim2.new(0.075,0,0.84,0), function(state)
    aimEnabled = state
end)
createSlider(MenuFrame, "Halus Aimbot", UDim2.new(0.075,0,0.92,0), 1, 20, 8, function(val)
    aimSmooth = val
end)

-- LOOP UTAMA
RunService.RenderStepped:Connect(function()
    local Char = Player.Character
    if not Char then return end
    local Hum = Char:FindFirstChild("Humanoid")
    local Root = Char:FindFirstChild("HumanoidRootPart")
    if not Hum or not Root then return end

    -- Speed
    Hum.WalkSpeed = speedEnabled and speedVal or 16

    -- Multi Jump Logic
    if jumpEnabled then
        if Hum.FloorMaterial ~= Enum.Material.Air then
            jumpCount = 0
        end
    end

    -- Fly Logic
    if flyEnabled then
        local camCF = workspace.CurrentCamera.CFrame
        local moveDir = Vector3.new()
        if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir += camCF.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir -= camCF.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir -= camCF.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir += camCF.RightVector end
        moveDir = moveDir * Vector3.new(1,0,1).Unit * flySpeed
        Root.Velocity = moveDir
    end
end)

-- Fly Naik/Turun Tombol Sentuh
flyBtnUp.InputBegan:Connect(function()
    flyBtnUp.TempConn = RunService.RenderStepped:Connect(function()
        if flyEnabled and Player.Character then
            Player.Character.HumanoidRootPart.Velocity += Vector3.new(0, flySpeed * 0.6, 0)
        end
    end)
end)
flyBtnUp.InputEnded:Connect(function() if flyBtnUp.TempConn then flyBtnUp.TempConn:Disconnect() end end)

flyBtnDown.InputBegan:Connect(function()
    flyBtnDown.TempConn = RunService.RenderStepped:Connect(function()
        if flyEnabled and Player.Character then
            Player.Character.HumanoidRootPart.Velocity += Vector3.new(0, -flySpeed * 0.6, 0)
        end
    end)
end)
flyBtnDown.InputEnded:Connect(function() if flyBtnDown.TempConn then flyBtnDown.TempConn:Disconnect() end end)

-- Multi Jump Tekan
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.Space and jumpEnabled and Player.Character then
            local Hum = Player.Character:FindFirstChild("Humanoid")
            if Hum and jumpCount < maxJumps then
                Hum.Velocity = Vector3.new(Hum.Velocity.X, 48, Hum.Velocity.Z)
                jumpCount += 1
            end
        end
    end
    -- Tombol sentuh lompat untuk HP
    if input.UserInputType == Enum.UserInputType.Touch and jumpEnabled and Player.Character then
        local Hum = Player.Character:FindFirstChild("Humanoid")
        if Hum and jumpCount < maxJumps then
            Hum.Velocity = Vector3.new(Hum.Velocity.X, 48, Hum.Velocity.Z)
            jumpCount += 1
        end
    end
end)

-- ESP
local ESPObjects = {}
RunService.RenderStepped:Connect(function()
    for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
        if plr ~= Player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local Root = plr.Character.HumanoidRootPart
            local Head = plr.Character:FindFirstChild("Head")
            if espEnabled then
                if not ESPObjects[plr.UserId] then
                    local billboard = Instance.new("BillboardGui")
                    billboard.AlwaysOnTop = true
                    billboard.Size = UDim2.new(0, 150, 0, 40)
                    billboard.Parent = Root
                    local txt = Instance.new("TextLabel")
                    txt.BackgroundTransparency = 1
                    txt.Size = UDim2.new(1,0,1,0)
                    txt.Text = plr.Name
                    txt.TextColor3 = Color3.fromRGB(255,80,80)
                    txt.Font = Enum.Font.GothamBold
                    txt.TextSize = 12
                    txt.Parent = billboard
                    ESPObjects[plr.UserId] = billboard
                end
            else
                if ESPObjects[plr.UserId] then
                    ESPObjects[plr.UserId]:Destroy()
                    ESPObjects[plr.UserId] = nil
                end
            end
        else
            if ESPObjects[plr.UserId] then
                ESPObjects[plr.UserId]:Destroy()
                ESPObjects[plr.UserId] = nil
            end
        end
    end
end)

-- Aimbot Smooth
local function GetClosestPlayer()
    local closest, dist = nil, math.huge
    local cam = Workspace.CurrentCamera
    for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
        if plr ~= Player and plr.Character and plr.Character:FindFirstChild(aimPart) then
            local part = plr.Character[aimPart]
            local pos, vis = cam:WorldToViewportPoint(part.Position)
            if vis then
                local mDist = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(pos.X, pos.Y)).Magnitude
                if mDist < dist then
                    dist = mDist
                    closest = part
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if not aimEnabled then return end
    local target = GetClosestPlayer()
    if target then
        local cam = Workspace.CurrentCamera
        local tPos = CFrame.new(cam.CFrame.Position, target.Position)
        cam.CFrame = cam.CFrame:Lerp(tPos, 1 / aimSmooth)
    end
end)

-- Bersihkan saat ulang masuk
Player.CharacterAdded:Connect(function()
    jumpCount = 0
    if flyEnabled then
        flyEnabled = false
    end
end)

print("[Vanta Menu] Dimuat sukses! Tekan tombol M untuk buka/tutup menu")
