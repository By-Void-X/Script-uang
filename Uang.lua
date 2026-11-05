--═════════════════════════════════════════════════════
--  🎯 SOFT AIMBOT — Non-Lock Edition
--  Layar tetap bisa digerakkan manual!
--
--  • Micro-adjust: cuma tarik dikit ke target, gak megang kamera
--  • Mode "Hold" : aimbot cuma aktif saat tombol AIM ditahan
--  • Mode "Soft" : koreksi halus terus-menerus (masih bisa gerak)
--  • Delta-time stabil di semua fps
--═════════════════════════════════════════════════════

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

--═══════════ CONFIG ═══════════
local Mode        = "Hold"  -- "Hold" = tombol di layar, "Soft" = bantu terus tapi gak lock
local Strength    = 0.15    -- 0.05 = tarikan super halus, 0.3 = tarikan kuat
local FOV         = 130     -- radius pixel
local Deadzone    = 1.5     -- derajat; di bawah ini gak ganggu kamera
local MaxPull     = 2.5     -- derajat max per frame — ini yang bikin gak lock!
local TargetPart  = "Head"
local TeamCheck   = false
local ShowFOV     = true

local holding = false
local currentTarget = nil

--═══════════ DRAWING ═══════════
local DrawingOK = pcall(function()
    local d = Drawing.new("Circle")
    d:Remove()
end)

local fovCircle
if DrawingOK then
    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness    = 1.5
    fovCircle.Color        = Color3.fromRGB(255, 255, 255)
    fovCircle.Filled       = false
    fovCircle.Transparency = 0.55
    fovCircle.NumSides     = 60
    fovCircle.Visible      = false
end

--═══════════ TARGET ═══════════
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

local function scanTarget()
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

--═══════════ SOFT AIM CORE ═══════════
-- bedanya sama lock aimbot:
--   lock    → kamera DISET ke target tiap frame (layar mati)
--   soft    → kamera cuma DIGESER DIKIT ke arah target per frame (layar hidup)
local function softAim(dt)
    if currentTarget then
        local valid = isTargetValid(currentTarget)
        if not valid then
            currentTarget = nil
        else
            -- cek masih dalam FOV diperluas
            local part = currentTarget.Character:FindFirstChild(TargetPart)
            if part then
                local pos = Camera:WorldToViewportPoint(part.Position)
                local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                if (Vector2.new(pos.X, pos.Y) - center).Magnitude > FOV * 1.3 then
                    currentTarget = nil
                end
            else
                currentTarget = nil
            end
        end
    end

    if not currentTarget then
        currentTarget = scanTarget()
    end

    if not currentTarget then return end

    local part = currentTarget.Character:FindFirstChild(TargetPart)
    if not part then return end

    local camPos   = Camera.CFrame.Position
    local goalDir  = (part.Position - camPos).Unit
    local curDir   = Camera.CFrame.LookVector

    local dot   = math.clamp(curDir:Dot(goalDir), -1, 1)
    local angle = math.deg(math.acos(dot))

    -- udah hampir pas → gak usah ganggu kamera (anti jitter)
    if angle < Deadzone then return end

    --═══ INI KUNCINYA ═══
    -- tarikan dibatasi MaxPull derajat per frame.
    -- jadi kamera cuma "tertarik" pelan-pelan, dan lu bisa
    -- lawan tarikan ini dengan geser layar — full manual control.
    local pull = math.min(angle * Strength, MaxPull)

    local t = math.clamp(pull / angle, 0, 1)
    local newDir = curDir:Lerp(goalDir, t)

    if newDir.Magnitude > 0 then
        Camera.CFrame = CFrame.lookAt(camPos, camPos + newDir.Unit)
    end
end

--═══════════ MAIN LOOP ═══════════
RunService.RenderStepped:Connect(function(dt)
    local shouldAim = (Mode == "Soft") or (Mode == "Hold" and holding)

    if fovCircle then
        fovCircle.Radius   = FOV
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        fovCircle.Visible  = ShowFOV and shouldAim
    end

    if shouldAim then
        softAim(dt)
    else
        currentTarget = nil
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    currentTarget = nil
end)

--═══════════════════════════════════════════
--                     UI
--═══════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SoftAimbot"
ScreenGui.ResetOnSpawn = false

local ok = pcall(function() ScreenGui.Parent = CoreGui end)
if not ok then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 210, 0, 280)
Main.Position = UDim2.new(0, 12, 0.28, 0)
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
Title.Text = "🎯 SOFT AIM — FREE LOOK"
Title.TextColor3 = Color3.fromRGB(255, 70, 70)
Title.TextSize = 13
Title.Font = Enum.Font.GothamBold
Title.Parent = Main

--═══════════ MODE BUTTONS ═══════════
local modeHoldBtn = Instance.new("TextButton")
modeHoldBtn.Size = UDim2.new(0.48, -6, 0, 28)
modeHoldBtn.Position = UDim2.new(0, 8, 0, 34)
modeHoldBtn.BackgroundColor3 = Color3.fromRGB(160, 30, 30)
modeHoldBtn.Text = "HOLD"
modeHoldBtn.TextColor3 = Color3.new(1, 1, 1)
modeHoldBtn.TextSize = 12
modeHoldBtn.Font = Enum.Font.GothamBold
modeHoldBtn.Parent = Main
Instance.new("UICorner", modeHoldBtn).CornerRadius = UDim.new(0, 6)

local modeSoftBtn = Instance.new("TextButton")
modeSoftBtn.Size = UDim2.new(0.48, -6, 0, 28)
modeSoftBtn.Position = UDim2.new(0.52, 0, 0, 34)
modeSoftBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
modeSoftBtn.Text = "SOFT"
modeSoftBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
modeSoftBtn.TextSize = 12
modeSoftBtn.Font = Enum.Font.GothamBold
modeSoftBtn.Parent = Main
Instance.new("UICorner", modeSoftBtn).CornerRadius = UDim.new(0, 6)

local function setMode(m)
    Mode = m
    currentTarget = nil
    modeHoldBtn.BackgroundColor3 = m == "Hold" and Color3.fromRGB(160, 30, 30) or Color3.fromRGB(35, 35, 48)
    modeHoldBtn.TextColor3 = m == "Hold" and Color3.new(1,1,1) or Color3.fromRGB(200,200,200)
    modeSoftBtn.BackgroundColor3 = m == "Soft" and Color3.fromRGB(160, 30, 30) or Color3.fromRGB(35, 35, 48)
    modeSoftBtn.TextColor3 = m == "Soft" and Color3.new(1,1,1) or Color3.fromRGB(200,200,200)
end

modeHoldBtn.MouseButton1Click:Connect(function() setMode("Hold") end)
modeSoftBtn.MouseButton1Click:Connect(function() setMode("Soft") end)

--═══════════ BIG HOLD BUTTON (layar) ═══════════
-- tombol besar kanan bawah — tahan buat aim
local holdBtn = Instance.new("TextButton")
holdBtn.Size = UDim2.new(0, 90, 0, 90)
holdBtn.Position = UDim2.new(1, -110, 1, -120)
holdBtn.BackgroundColor3 = Color3.fromRGB(160, 30, 30)
holdBtn.BackgroundTransparency = 0.35
holdBtn.Text = "AIM"
holdBtn.TextColor3 = Color3.new(1, 1, 1)
holdBtn.TextSize = 20
holdBtn.Font = Enum.Font.GothamBold
holdBtn.Parent = ScreenGui
Instance.new("UICorner", holdBtn).CornerRadius = UDim.new(1, 0)

local holdStroke = Instance.new("UIStroke")
holdStroke.Color = Color3.fromRGB(255, 80, 80)
holdStroke.Thickness = 2
holdStroke.Parent = holdBtn

holdBtn.MouseButton1Down:Connect(function()
    holding = true
    holdBtn.BackgroundTransparency = 0.1
end)
holdBtn.MouseButton1Up:Connect(function()
    holding = false
    holdBtn.BackgroundTransparency = 0.35
end)
holdBtn.MouseLeave:Connect(function()
    holding = false
    holdBtn.BackgroundTransparency = 0.35
end)

--═══════════ SLIDERS ═══════════
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

makeSlider("Strength", 0.03, 0.5, Strength, 70, true, function(v) Strength = v end)
makeSlider("FOV", 50, 400, FOV, 112, false, function(v) FOV = v end)
makeSlider("MaxPull", 0.5, 10, MaxPull, 154, true, function(v) MaxPull = v end)
makeSlider("Deadzone", 0.5, 5, Deadzone, 196, true, function(v) Deadzone = v end)

-- team check
local teamBtn = Instance.new("TextButton")
teamBtn.Size = UDim2.new(1, -16, 0, 26)
teamBtn.Position = UDim2.new(0, 8, 0, 242)
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

print("═══ Soft Aimbot loaded — layar bebas digerakkan ═══")
