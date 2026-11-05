--═════════════════════════════════════════════════════
--  🎯 SMOOTH AIMBOT — STABLE EDITION
--  Delta Executor Compatible (Mobile/HP)
--
--  • delta-time damping → gerakan sama di 30/60/120 fps
--  • deadzone → gak ada jitter micro-movement
--  • target lock + hysteresis → gak flick antar player
--  • max turn speed → gak ada snap instan yang kelihatan bot
--  • auto drop target mati / off-screen / leave
--═════════════════════════════════════════════════════

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

--═══════════ CONFIG ═══════════
local Smoothness   = 0.35    -- 0.05 = super smooth, 1 = instan (jangan 1, gak stabil)
local FOV          = 120     -- radius pixel
local Deadzone     = 0.8     -- derajat; di bawah ini gak digerakkan (anti-jitter)
local MaxTurnSpeed = 240     -- derajat per detik (clamp biar gak snap)
local TargetPart   = "Head"  -- "Head" / "HumanoidRootPart" / "Torso"
local TeamCheck    = false   -- true = gak nembak teammate
local AimMode      = "Always" -- "Always" | "HoldKey" (tombol aim muncul di layar)
local ShowFOV      = true
local ShowLine     = true

-- internal (jangan diutak-atik)
local currentTarget = nil
local fovCircle, aimLine
local holdAiming = false

--═══════════ DRAWING SETUP ═══════════
local DrawingOK = pcall(function()
    local d = Drawing.new("Circle")
    d:Remove()
end)

if DrawingOK then
    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness   = 1.5
    fovCircle.Color       = Color3.fromRGB(255, 255, 255)
    fovCircle.Filled      = false
    fovCircle.Transparency = 0.5
    fovCircle.NumSides    = 60
    fovCircle.Visible     = false

    aimLine = Drawing.new("Line")
    aimLine.Thickness = 1
    aimLine.Color     = Color3.fromRGB(255, 50, 50)
    aimLine.Visible   = false
end

--═══════════ VALIDASI TARGET ═══════════
local function isTargetValid(plr)
    if not plr or not plr.Parent then return false end
    if plr == LocalPlayer then return false end

    local char = plr.Character
    if not char then return false end

    local part = char:FindFirstChild(TargetPart)
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not part or not hum or hum.Health <= 0 then return false end

    if TeamCheck and plr.Team == LocalPlayer.Team then return false end

    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
    if not onScreen then return false end

    return true, pos
end

--═══════════ SCAN TARGET BARU ═══════════
local function scanNewTarget()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local best, bestDist = nil, math.huge

    for _, plr in pairs(Players:GetPlayers()) do
        local valid, pos = isTargetValid(plr)
        if valid then
            local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
            if dist < FOV and dist < bestDist then
                best = plr
                bestDist = dist
            end
        end
    end

    return best
end

--═══════════ AIM STEP (CORE — delta-time damping) ═══════════
local function aimStep(dt)
    -- 1) validasi target sekarang, drop kalau invalid
    local valid = isTargetValid(currentTarget)
    if not valid then
        currentTarget = scanNewTarget()
    end

    -- hysteresis: target lama boleh sedikit keluar FOV tanpa langsung di-drop
    -- (cuma scan ulang kalau bener-bener udah jauh)
    if currentTarget then
        local part = currentTarget.Character and currentTarget.Character:FindFirstChild(TargetPart)
        if part then
            local pos = Camera:WorldToViewportPoint(part.Position)
            local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
            if dist > FOV * 1.5 then
                currentTarget = scanNewTarget()
            end
        end
    end

    if not currentTarget then
        if aimLine then aimLine.Visible = false end
        return
    end

    -- 2) hitung arah target
    local part = currentTarget.Character:FindFirstChild(TargetPart)
    if not part then return end

    local camPos = Camera.CFrame.Position
    local targetPos = part.Position
    local goalDir = (targetPos - camPos).Unit
    local curDir  = Camera.CFrame.LookVector

    -- sudut error saat ini (derajat)
    local dot = math.clamp(curDir:Dot(goalDir), -1, 1)
    local angle = math.deg(math.acos(dot))

    -- 3) deadzone — biarkan kalau udah hampir pas (anti jitter)
    if angle < Deadzone then
        if aimLine and ShowLine then
            local pos = Camera:WorldToViewportPoint(targetPos)
            aimLine.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            aimLine.To   = Vector2.new(pos.X, pos.Y)
            aimLine.Visible = true
        end
        return
    end

    -- 4) damping berbasis delta-time → framerate independent
    --    di 30fps ataupun 120fps hasilnya konsisten
    local alpha = 1 - Smoothness^(dt * 60)

    -- 5) clamp step biar gak ada snap lebih dari MaxTurnSpeed
    local maxStep = MaxTurnSpeed * dt
    local stepAngle = math.min(angle * alpha, maxStep)

    -- interpolasi arah kamera
    local t = math.clamp(stepAngle / angle, 0, 1)
    local newDir = curDir:Lerp(goalDir, t)
    if newDir.Magnitude > 0 then
        newDir = newDir.Unit
        Camera.CFrame = CFrame.lookAt(camPos, camPos + newDir)
    end

    -- 6) garis penanda target aktif
    if aimLine and ShowLine then
        local pos = Camera:WorldToViewportPoint(targetPos)
        aimLine.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        aimLine.To   = Vector2.new(pos.X, pos.Y)
        aimLine.Visible = true
    end
end

--═══════════ MAIN LOOP ═══════════
RunService.RenderStepped:Connect(function(dt)
    -- FOV circle
    if fovCircle then
        if ShowFOV and AimMode == "Always" or (ShowFOV and AimMode == "HoldKey" and holdAiming) then
            fovCircle.Radius   = FOV
            fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            fovCircle.Visible  = true
        else
            fovCircle.Visible = false
        end
    end

    -- jalankan aim sesuai mode
    if AimMode == "Always" then
        aimStep(dt)
    elseif AimMode == "HoldKey" and holdAiming then
        aimStep(dt)
    else
        currentTarget = nil
        if aimLine then aimLine.Visible = false end
    end
end)

-- reset target saat respawn / mati biar gak nyangkut
LocalPlayer.CharacterAdded:Connect(function()
    currentTarget = nil
end)

--═══════════════════════════════════════════
--                     UI
--═══════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StableAimbot"
ScreenGui.ResetOnSpawn = false

local ok = pcall(function() ScreenGui.Parent = CoreGui end)
if not ok then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 200, 0, 250)
Main.Position = UDim2.new(0, 12, 0.3, 0)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 60, 60)
stroke.Thickness = 1.5
stroke.Transparency = 0.4
stroke.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "🎯 AIMBOT — STABLE"
Title.TextColor3 = Color3.fromRGB(255, 70, 70)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.Parent = Main

-- status target
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 16)
StatusLabel.Position = UDim2.new(0, 0, 0, 30)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "target: —"
StatusLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Parent = Main

--═══════════ SLIDER BUILDER ═══════════
local function makeSlider(label, min, max, default, posY, isFloat, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -16, 0, 38)
    container.Position = UDim2.new(0, 8, 0, posY)
    container.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
    container.BorderSizePixel = 0
    container.Parent = Main
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 0, 15)
    lbl.Position = UDim2.new(0, 8, 0, 2)
    lbl.BackgroundTransparency = 1
    lbl.Text = label .. ": " .. default
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = container

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -16, 0, 5)
    bar.Position = UDim2.new(0, 8, 0, 24)
    bar.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
    bar.BorderSizePixel = 0
    bar.Parent = container
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    fill.BorderSizePixel = 0
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local dragging = false
    local function update(input)
        local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local v = min + (max - min) * rel
        v = isFloat and (math.floor(v * 100 + 0.5) / 100) or math.floor(v + 0.5)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        lbl.Text = label .. ": " .. v
        callback(v)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)
    bar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
end

--═══════════ TOGGLE ═══════════
local enabled = false
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, -16, 0, 30)
toggleBtn.Position = UDim2.new(0, 8, 0, 50)
toggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
toggleBtn.Text = "  Aimbot:  OFF"
toggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
toggleBtn.TextSize = 12
toggleBtn.Font = Enum.Font.Gotham
toggleBtn.TextXAlignment = Enum.TextXAlignment.Left
toggleBtn.Parent = Main
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

toggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    AimMode = enabled and "Always" or "HoldKey"
    toggleBtn.Text = "  Aimbot:  " .. (enabled and "ON" or "OFF")
    toggleBtn.BackgroundColor3 = enabled and Color3.fromRGB(160, 30, 30) or Color3.fromRGB(35, 35, 48)
    toggleBtn.TextColor3 = enabled and Color3.new(1, 1, 1) or Color3.fromRGB(200, 200, 200)
    if not enabled then currentTarget = nil end
end)

-- sliders
makeSlider("Smooth", 0.05, 1, Smoothness, 88, true, function(v) Smoothness = v end)
makeSlider("FOV", 50, 400, FOV, 130, false, function(v) FOV = v end)
makeSlider("MaxTurn", 60, 720, MaxTurnSpeed, 172, false, function(v) MaxTurnSpeed = v end)

-- team check toggle
local teamBtn = Instance.new("TextButton")
teamBtn.Size = UDim2.new(1, -16, 0, 26)
teamBtn.Position = UDim2.new(0, 8, 0, 214)
teamBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
teamBtn.Text = "  Team Check:  OFF"
teamBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
teamBtn.TextSize = 11
teamBtn.Font = Enum.Font.Gotham
teamBtn.TextXAlignment = Enum.TextXAlignment.Left
teamBtn.Parent = Main
Instance.new("UICorner", teamBtn).CornerRadius = UDim.new(0, 6)

teamBtn.MouseButton1Click:Connect(function()
    TeamCheck = not TeamCheck
    teamBtn.Text = "  Team Check:  " .. (TeamCheck and "ON" or "OFF")
    teamBtn.BackgroundColor3 = TeamCheck and Color3.fromRGB(30, 90, 160) or Color3.fromRGB(35, 35, 48)
end)

-- status updater
task.spawn(function()
    while task.wait(0.25) do
        if currentTarget and currentTarget.Parent then
            StatusLabel.Text = "🎯 " .. currentTarget.Name
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        else
            StatusLabel.Text = enabled and "cari target..." or "target: —"
            StatusLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
        end
    end
end)

--═══════════ DRAG ═══════════
do
    local dragging = false
    local dragStart, startPos

    Title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

print("═══ Stable Aimbot loaded ═══")
