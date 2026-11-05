-- Universal Mobile Cheat Menu V2.0 | Delta Executor
-- Perbaikan: UI, MultiJump, Fly, Touch Input, Cleanup

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

-- ==============================================
-- KELUARKAN GUI KE PLAYERGUI — INI YANG DULU BUG
-- ==============================================
local PlayerGui = Player:WaitForChild("PlayerGui")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VantaMenuV2"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = PlayerGui

-- TOMBOL TOGGLE MENU
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleButton"
ToggleBtn.Size = UDim2.new(0, 55, 0, 55)
ToggleBtn.Position = UDim2.new(0.91, 0, 0.45, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 130, 220)
ToggleBtn.BorderSizePixel = 3
ToggleBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Text = "M"
ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
ToggleBtn.TextSize = 22
ToggleBtn.Active = true
ToggleBtn.AutoLocalize = false
ToggleBtn.Parent = ScreenGui

-- FRAME MENU UTAMA
local MenuFrame = Instance.new("Frame")
MenuFrame.Name = "MenuFrame"
MenuFrame.Size = UDim2.new(0, 280, 0, 420)
MenuFrame.Position = UDim2.new(0.02, 0, 0.5, -210)
MenuFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
MenuFrame.BorderSizePixel = 2
MenuFrame.BorderColor3 = Color3.fromRGB(70, 160, 255)
MenuFrame.Active = true
MenuFrame.Draggable = true
MenuFrame.Visible = true
MenuFrame.Parent = ScreenGui

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
TitleBar.Parent = MenuFrame

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, 0, 1, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "⚡ VANTA CHEAT MENU"
TitleText.TextColor3 = Color3.fromRGB(110, 200, 255)
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 15
TitleText.Parent = TitleBar

-- ==============================================
-- FUNGSI PEMBUAT TOMBOL & SLIDER
-- ==============================================
local function CreateToggle(name, pos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 230, 0, 42)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
    btn.BorderSizePixel = 1
    btn.BorderColor3 = Color3.fromRGB(90, 90, 110)
    btn.Font = Enum.Font.Gotham
    btn.Text = "❌ " .. name
    btn.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    btn.TextSize = 14
    btn.AutoLocalize = false
    btn.Parent = MenuFrame
    
    local Enabled = false
    btn.MouseButton1Click:Connect(function()
        Enabled = not Enabled
        btn.BackgroundColor3 = Enabled and Color3.fromRGB(30, 140, 90) or Color3.fromRGB(55, 55, 70)
        btn.Text = Enabled and "✅ " .. name or "❌ " .. name
        callback(Enabled)
    end)
    return btn
end

local function CreateButton(name, pos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 110, 0, 38)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(50, 100, 180)
    btn.Font = Enum.Font.Gotham
    btn.Text = name
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 13
    btn.AutoLocalize = false
    btn.Parent = MenuFrame
    
    btn.MouseButton1Down:Connect(callback)
    return btn
end

local function CreateLabel(text, pos)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 230, 0, 28)
    lbl.Position = pos
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.new(0.75, 0.75, 0.8)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    lbl.Parent = MenuFrame
    return lbl
end

-- ==============================================
-- VARIABEL KONTROL
-- ==============================================
local MenuOpen = true
local SpeedEnabled = false
local SpeedValue = 32
local JumpEnabled = false
local MaxJumps = 2
local JumpCount = 0
local LastGroundState = true
local FlyEnabled = false
local FlySpeedValue = 24
local ESPEnabled = false
local AimbotEnabled = false
local AimbotSmoothness = 8
local ESPObjects = {}

-- ==============================================
-- TOGGLE MENU TAMPIL / SEMBUNYI
-- ==============================================
ToggleBtn.MouseButton1Click:Connect(function()
    MenuOpen = not MenuOpen
    MenuFrame.Visible = MenuOpen
end)

-- ==============================================
-- BANGUN MENU
-- ==============================================
CreateLabel("─── PERGERAKAN ───", UDim2.new(25, 0, 50, 0))

CreateToggle("Speed Hack", UDim2.new(25, 0, 82, 0), function(v) SpeedEnabled = v end)

CreateToggle("Multi Jump (2x)", UDim2.new(25, 0, 132, 0), function(v)
    JumpEnabled = v
    JumpCount = 0
end)

CreateToggle("Fly Mode", UDim2.new(25, 0, 182, 0), function(v)
    FlyEnabled = v
    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Player.Character.Humanoid.PlatformStand = v
        Player.Character.Humanoid.GravityScale = v and 0 or 1
    end
end)

local btnUp = CreateButton("⬆️ NAIK", UDim2.new(25, 0, 232, 0))
local btnDown = CreateButton("⬇️ TURUN", UDim2.new(145, 0, 232, 0))

CreateLabel("─── VISUAL & AIMING ───", UDim2.new(25, 0, 280, 0))

CreateToggle("ESP Pemain", UDim2.new(25, 0, 312, 0), function(v)
    ESPEnabled = v
    if not v then
        for _, obj in pairs(ESPObjects) do obj:Destroy() end
        table.clear(ESPObjects)
    end
end)

CreateToggle("Aimbot Smooth", UDim2.new(25, 0, 362, 0), function(v) AimbotEnabled = v end)

-- ==============================================
-- FUNGSI BANTUAN
-- ==============================================
local function GetCharacter()
    return Player.Character
end

local function GetHumanoid()
    local char = GetCharacter()
    return char and char:FindFirstChild("Humanoid") or nil
end

local function GetRootPart()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart") or nil
end

-- ==============================================
-- MULTI JUMP — PAKAI JumpRequest, BENER SEKARANG
-- ==============================================
UIS.JumpRequest:Connect(function()
    if not JumpEnabled then return end
    local Hum = GetHumanoid()
    if not Hum then return end
    
    -- Saat menyentuh tanah, reset hitungan lompatan
    if Hum.FloorMaterial ~= Enum.Material.Air then
        JumpCount = 0
    end
    
    -- Bisa lompat lagi jika belum mencapai batas
    if JumpCount < MaxJumps and Hum.FloorMaterial == Enum.Material.Air then
        Hum:ChangeState(Enum.HumanoidStateType.Jumping)
        JumpCount += 1
    end
end)

-- Reset lompatan saat mendarat
RunService.Heartbeat:Connect(function()
    local Hum = GetHumanoid()
    if Hum then
        local onGround = (Hum.FloorMaterial ~= Enum.Material.Air)
        if onGround and not LastGroundState then
            JumpCount = 0
        end
        LastGroundState = onGround
    end
end)

-- ==============================================
-- FLY — TOMBOL NAIK TURUN
-- ==============================================
local function SetFlyVelocity(direction)
    if not FlyEnabled then return end
    local Root = GetRootPart()
    if Root then
        Root.Velocity += Vector3.new(0, direction * FlySpeedValue, 0)
    end
end

local upConn, downConn

btnUp.MouseButton1Down:Connect(function()
    upConn = RunService.RenderStepped:Connect(function() SetFlyVelocity(1) end)
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and upConn then
        upConn:Disconnect()
    end
end)

btnDown.MouseButton1Down:Connect(function()
    downConn = RunService.RenderStepped:Connect(function() SetFlyVelocity(-1) end)
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and downConn then
        downConn:Disconnect()
    end
end)

-- Gerakan terbang WASD
RunService.RenderStepped:Connect(function()
    if not FlyEnabled then return end
    local Root = GetRootPart()
    local Hum = GetHumanoid()
    if not Root or not Hum then return end
    
    local CamCF = Workspace.CurrentCamera.CFrame
    local moveDir = Vector3.new()
    
    if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir += CamCF.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir -= CamCF.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir -= CamCF.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir += CamCF.RightVector end
    
    moveDir = Vector3.new(moveDir.X, 0, moveDir.Z).Unit * FlySpeedValue
    Root.Velocity = Vector3.new(moveDir.X, Root.Velocity.Y, moveDir.Z)
end)

-- ==============================================
-- SPEED HACK
-- ==============================================
RunService.Heartbeat:Connect(function()
    local Hum = GetHumanoid()
    if Hum then
        Hum.WalkSpeed = SpeedEnabled and SpeedValue or 16
    end
end)

-- ==============================================
-- ESP PEMAIN
-- ==============================================
RunService.RenderStepped:Connect(function()
    if not ESPEnabled then return end
    
    for _, TargetPlayer in ipairs(Players:GetPlayers()) do
        if TargetPlayer ~= Player and TargetPlayer.Character then
            local Root = TargetPlayer.Character:FindFirstChild("HumanoidRootPart")
            local Head = TargetPlayer.Character:FindFirstChild("Head")
            if Root and not ESPObjects[TargetPlayer.UserId] then
                local Billboard = Instance.new("BillboardGui")
                Billboard.AlwaysOnTop = true
                Billboard.Size = UDim2.new(0, 200, 0, 50)
                Billboard.Parent = Root
                
                local NameLabel = Instance.new("TextLabel")
                NameLabel.BackgroundTransparency = 1
                NameLabel.Size = UDim2.new(1, 0, 1, 0)
                NameLabel.Text = "🎮 " .. TargetPlayer.Name
                NameLabel.TextColor3 = Color3.fromRGB(255, 70, 70)
                NameLabel.Font = Enum.Font.GothamBold
                NameLabel.TextSize = 13
                NameLabel.AutoLocalize = false
                NameLabel.Parent = Billboard
                
                ESPObjects[TargetPlayer.UserId] = Billboard
            end
        else
            -- Bersihkan ESP pemain yang keluar
            if ESPObjects[TargetPlayer.UserId] then
                ESPObjects[TargetPlayer.UserId]:Destroy()
                ESPObjects[TargetPlayer.UserId] = nil
            end
        end
    end
end)

-- ==============================================
-- AIMBOT SMOOTH
-- ==============================================
local function GetNearestEnemyHead()
    local Cam = Workspace.CurrentCamera
    local ClosestPart, MinDist = nil, math.huge
    local MousePos = Vector2.new(Mouse.X, Mouse.Y)
    
    for _, TargetPlayer in ipairs(Players:GetPlayers()) do
        if TargetPlayer ~= Player and TargetPlayer.Character then
            local Head = TargetPlayer.Character:FindFirstChild("Head")
            if Head then
                local ScreenPos, Visible = Cam:WorldToViewportPoint(Head.Position)
                if Visible then
                    local Dist = (MousePos - Vector2.new(ScreenPos.X, ScreenPos.Y)).Magnitude
                    if Dist < MinDist then
                        MinDist = Dist
                        ClosestPart = Head
                    end
                end
            end
        end
    end
    return ClosestPart
end

RunService.RenderStepped:Connect(function()
    if not AimbotEnabled then return end
    local Target = GetNearestEnemyHead()
    if not Target then return end
    
    local Cam = Workspace.CurrentCamera
    local DesiredCF = CFrame.new(Cam.CFrame.Position, Target.Position)
    Cam.CFrame = Cam.CFrame:Lerp(DesiredCF, 1 / AimbotSmoothness)
end)

-- ==============================================
-- RESET SAWAH KARAKTER BERUBAH
-- ==============================================
Player.CharacterAdded:Connect(function()
    JumpCount = 0
    -- Kembalikan nilai default saat respawn
    task.wait(0.1)
    if FlyEnabled then
        local Hum = GetHumanoid()
        if Hum then
            Hum.PlatformStand = true
            Hum.GravityScale = 0
        end
    end
end)

print("[✅] VANTA MENU V2 — BERHASIL DIMUAT!")
print("[📱] Tekan tombol 'M' di sebelah kanan layar untuk buka/tutup menu")
