-- =============================================
-- VANTA CHEAT MENU V3 | Delta / Fluxus Mobile
-- Sederhana, Pasti Muncul, Minim Bug
-- =============================================

-- Tunggu sampai PlayerGui siap
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui", 10)
if not PlayerGui then
    warn("[VANTA] PlayerGui tidak ditemukan!")
    return
end

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- =============================================
-- LANGKAH 1: BUAT GUI PALING DULU
-- =============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VantaMenuV3"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- TOMBOL UTAMA — DI SISI KANAN BAWAH, GAMPANG DICARI
local MainButton = Instance.new("TextButton")
MainButton.Name = "VantaMainBtn"
MainButton.Size = UDim2.new(0, 60, 0, 60)
MainButton.Position = UDim2.new(0.90, 0, 0.85, 0)
MainButton.BackgroundColor3 = Color3.fromRGB(30, 144, 255)
MainButton.Text = "V"
MainButton.TextColor3 = Color3.new(1,1,1)
MainButton.Font = Enum.Font.GothamBold
MainButton.TextSize = 28
MainButton.BorderSizePixel = 0
MainButton.AutoLocalize = false
MainButton.Parent = ScreenGui

-- FRAME MENU
local MenuFrame = Instance.new("Frame")
MenuFrame.Name = "VantaMenuFrame"
MenuFrame.Size = UDim2.new(0, 260, 0, 360)
MenuFrame.Position = UDim2.new(0.05, 0, 0.15, 0)
MenuFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
MenuFrame.BorderSizePixel = 2
MenuFrame.BorderColor3 = Color3.fromRGB(100, 180, 255)
MenuFrame.Visible = false
MenuFrame.Active = true
MenuFrame.Draggable = true
MenuFrame.Parent = ScreenGui

local MenuTitle = Instance.new("TextLabel")
MenuTitle.Size = UDim2.new(1, 0, 0, 40)
MenuTitle.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
MenuTitle.Text = "⚡ VANTA CHEAT MENU V3"
MenuTitle.TextColor3 = Color3.fromRGB(150, 210, 255)
MenuTitle.Font = Enum.Font.GothamBold
MenuTitle.TextSize = 14
MenuTitle.Parent = MenuFrame

-- =============================================
-- VARIABEL GLOBAL
-- =============================================
local MenuVisible = false
local SpeedEnabled = false
local SpeedVal = 32
local JumpEnabled = false
local JumpCount = 0
local MaxJumps = 2
local FlyEnabled = false
local FlySpeed = 20
local ESPEnabled = false
local AimbotEnabled = false
local AimbotSmooth = 10
local ESPObjects = {}
local Connections = {}

-- =============================================
-- FUNGSI BANTUAN
-- =============================================
local function CreateToggle(name, yPos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 220, 0, 40)
    btn.Position = UDim2.new(20, 0, yPos, 0)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    btn.Text = "❌ " .. name
    btn.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.AutoLocalize = false
    btn.Parent = MenuFrame
    
    local isOn = false
    btn.MouseButton1Click:Connect(function()
        isOn = not isOn
        btn.BackgroundColor3 = isOn and Color3.fromRGB(40, 160, 100) or Color3.fromRGB(60, 60, 80)
        btn.Text = isOn and "✅ " .. name or "❌ " .. name
        callback(isOn)
    end)
    return btn
end

local function CreateButton(name, xPos, yPos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 100, 0, 35)
    btn.Position = UDim2.new(xPos, 0, yPos, 0)
    btn.BackgroundColor3 = Color3.fromRGB(50, 130, 200)
    btn.Text = name
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.AutoLocalize = false
    btn.Parent = MenuFrame
    btn.MouseButton1Down:Connect(callback)
    return btn
end

local function GetChar() return Player.Character end
local function GetHum() local c = GetChar() return c and c:FindFirstChild("Humanoid") end
local function GetRoot() local c = GetChar() return c and c:FindFirstChild("HumanoidRootPart") end

-- =============================================
-- TOGGLE MENU BUKA/TUTUP
-- =============================================
MainButton.MouseButton1Click:Connect(function()
    MenuVisible = not MenuVisible
    MenuFrame.Visible = MenuVisible
    MainButton.Text = MenuVisible and "✕" or "V"
    MainButton.BackgroundColor3 = MenuVisible and Color3.fromRGB(220, 80, 80) or Color3.fromRGB(30, 144, 255)
end)

-- =============================================
-- BANGUN SEMUA TOMBOL
-- =============================================
CreateToggle("Speed Hack (32)", 55, function(v) SpeedEnabled = v end)
CreateToggle("Multi Jump (2x)", 105, function(v) JumpEnabled = v; JumpCount = 0 end)
CreateToggle("Fly Mode", 155, function(v)
    FlyEnabled = v
    local h = GetHum()
    if h then h.GravityScale = v and 0 or 1 end
end)

local btnUp = CreateButton("⬆️ NAIK", 20, 205)
local btnDown = CreateButton("⬇️ TURUN", 140, 205)

CreateToggle("ESP Pemain", 250, function(v)
    ESPEnabled = v
    if not v then
        for _, obj in pairs(ESPObjects) do pcall(function() obj:Destroy() end) end
        table.clear(ESPObjects)
    end
end)

CreateToggle("Aimbot Smooth", 300, function(v) AimbotEnabled = v end)

-- =============================================
-- FITUR: SPEED
-- =============================================
Connections.SpeedLoop = RunService.Heartbeat:Connect(function()
    local h = GetHum()
    if h then
        h.WalkSpeed = SpeedEnabled and SpeedVal or 16
    end
end)

-- =============================================
-- FITUR: MULTI JUMP
-- =============================================
Connections.Jump = UIS.JumpRequest:Connect(function()
    if not JumpEnabled then return end
    local h = GetHum()
    if not h then return end
    
    -- Reset saat menyentuh tanah
    if h.FloorMaterial ~= Enum.Material.Air then
        JumpCount = 0
        return
    end
    
    -- Lompat lagi di udara
    if JumpCount < MaxJumps then
        h:ChangeState(Enum.HumanoidStateType.Jumping)
        if GetRoot() then
            GetRoot().Velocity += Vector3.new(0, 35, 0)
        end
        JumpCount += 1
    end
end)

-- Reset otomatis saat mendarat
Connections.GroundCheck = RunService.Heartbeat:Connect(function()
    local h = GetHum()
    if h and h.FloorMaterial ~= Enum.Material.Air then
        JumpCount = 0
    end
end)

-- =============================================
-- FITUR: FLY — Naik/Turun
-- =============================================
local upConn, downConn

btnUp.MouseButton1Down:Connect(function()
    upConn = RunService.RenderStepped:Connect(function()
        if FlyEnabled and GetRoot() then
            GetRoot().Velocity += Vector3.new(0, FlySpeed * 0.7, 0)
        end
    end)
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and upConn then
        upConn:Disconnect()
    end
end)

btnDown.MouseButton1Down:Connect(function()
    downConn = RunService.RenderStepped:Connect(function()
        if FlyEnabled and GetRoot() then
            GetRoot().Velocity += Vector3.new(0, -FlySpeed * 0.7, 0)
        end
    end)
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and downConn then
        downConn:Disconnect()
    end
end)

-- Gerakan terbang WASD
Connections.FlyMove = RunService.RenderStepped:Connect(function()
    if not FlyEnabled then return end
    local root = GetRoot()
    if not root then return end
    local cam = Workspace.CurrentCamera
    local dir = Vector3.new()
    if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
    dir = Vector3.new(dir.X, 0, dir.Z).Unit * FlySpeed
    root.Velocity = Vector3.new(dir.X, root.Velocity.Y, dir.Z)
end)

-- =============================================
-- FITUR: ESP
-- =============================================
Connections.ESPLoop = RunService.RenderStepped:Connect(function()
    if not ESPEnabled then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local root = p.Character.HumanoidRootPart
            if not ESPObjects[p.UserId] then
                local bg = Instance.new("BillboardGui")
                bg.AlwaysOnTop = true
                bg.Size = UDim2.new(0, 150, 0, 40)
                bg.Parent = root
                local lbl = Instance.new("TextLabel")
                lbl.BackgroundTransparency = 1
                lbl.Size = UDim2.new(1,0,1,0)
                lbl.Text = p.Name
                lbl.TextColor3 = Color3.fromRGB(255, 60, 60)
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 12
                lbl.Parent = bg
                ESPObjects[p.UserId] = bg
            end
        else
            if ESPObjects[p.UserId] then
                pcall(function() ESPObjects[p.UserId]:Destroy() end)
                ESPObjects[p.UserId] = nil
            end
        end
    end
end)

-- =============================================
-- FITUR: AIMBOT
-- =============================================
local function GetNearestHead()
    local cam = Workspace.CurrentCamera
    local mousePos = Vector2.new(UIS:GetMouseLocation().X, UIS:GetMouseLocation().Y)
    local closest, dist = nil, 300
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local head = p.Character:FindFirstChild("Head")
            if head then
                local sp, vis = cam:WorldToViewportPoint(head.Position)
                if vis then
                    local d = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                    if d < dist then
                        dist = d
                        closest = head
                    end
                end
            end
        end
    end
    return closest
end

Connections.AimLoop = RunService.RenderStepped:Connect(function()
    if not AimbotEnabled then return end
    local target = GetNearestHead()
    if target then
        local cam = Workspace.CurrentCamera
        cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, target.Position), 1/AimbotSmooth)
    end
end)

-- =============================================
-- RESET SAAT RESPAWN
-- =============================================
Player.CharacterAdded:Connect(function()
    JumpCount = 0
    task.wait(0.15)
    if FlyEnabled then
        local h = GetHum()
        if h then h.GravityScale = 0 end
    end
end)

-- =============================================
-- SELESAI
-- =============================================
print(" ")
print("[✅] ======================================")
print("[✅] VANTA MENU V3 — BERHASIL DIMUAT!")
print("[✅] ======================================")
print("[📱] Tombol BUKA/TUTUP ada di pojok kanan bawah")
print("[📱] Ketuk tombol BIRU bertuliskan 'V'")
print("[✅] ======================================")
print(" ")
