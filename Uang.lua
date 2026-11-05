--═════════════════════════════════════════════════════
--  🎯 AIMBOT SMOOTH (Stand-Alone)
--  Delta Executor Compatible (Mobile/HP)
--═════════════════════════════════════════════════════

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

--═══════════ SETTING ═══════════
local Aimbot      = false
local AimSmooth   = 0.25   -- 0.05 = sangat smooth, 1 = snap langsung
local AimFOV      = 150    -- radius FOV (pixel)
local ShowFOV     = true   -- tampilkan lingkaran FOV
local TargetPart  = "Head" -- "Head" = headshot, ganti "HumanoidRootPart" = body

-- support Drawing? (delta support, tapi cek dulu biar aman)
local DrawingOK = pcall(function()
    local d = Drawing.new("Circle")
    d:Remove()
end)

--═══════════ FOV CIRCLE ═══════════
local fovCircle
if DrawingOK then
    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 1.5
    fovCircle.Color = Color3.fromRGB(255, 255, 255)
    fovCircle.Filled = false
    fovCircle.Transparency = 0.6
    fovCircle.NumSides = 60
    fovCircle.Visible = false
end

--═══════════ CARI TARGET TERDEKAT DALAM FOV ═══════════
local function getNearestTarget()
    local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local nearest, nearestDist = nil, math.huge

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local part = plr.Character:FindFirstChild(TargetPart)
            local hum  = plr.Character:FindFirstChildOfClass("Humanoid")
            if part and hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                    if dist < AimFOV and dist < nearestDist then
                        nearest = part
                        nearestDist = dist
                    end
                end
            end
        end
    end

    return nearest
end

--═══════════ LOOP AIMBOT ═══════════
RunService.RenderStepped:Connect(function()
    -- render FOV circle
    if fovCircle then
        if Aimbot and ShowFOV then
            fovCircle.Radius = AimFOV
            fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            fovCircle.Visible = true
        else
            fovCircle.Visible = false
        end
    end

    if not Aimbot then return end

    local target = getNearestTarget()
    if target then
        local targetCFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, AimSmooth)
    end
end)

--═══════════════════════════════════════════
--                     UI
--═══════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimbotUI"
ScreenGui.ResetOnSpawn = false

local ok = pcall(function() ScreenGui.Parent = CoreGui end)
if not ok then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 220, 0, 230)
Main.Position = UDim2.new(0, 15, 0.3, 0)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = Main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(255, 60, 60)
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.5
mainStroke.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 34)
Title.BackgroundTransparency = 1
Title.Text = "🎯 AIMBOT"
Title.TextColor3 = Color3.fromRGB(255, 60, 60)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.Parent = Main

-- Toggle ON/OFF
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, -20, 0, 34)
toggleBtn.Position = UDim2.new(0, 10, 0, 42)
toggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
toggleBtn.Text = "  Aimbot:  OFF"
toggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
toggleBtn.TextSize = 13
toggleBtn.Font = Enum.Font.Gotham
toggleBtn.TextXAlignment = Enum.TextXAlignment.Left
toggleBtn.Parent = Main

local tCorner = Instance.new("UICorner")
tCorner.CornerRadius = UDim.new(0, 6)
tCorner.Parent = toggleBtn

toggleBtn.MouseButton1Click:Connect(function()
    Aimbot = not Aimbot
    toggleBtn.Text = "  Aimbot:  " .. (Aimbot and "ON" or "OFF")
    toggleBtn.BackgroundColor3 = Aimbot and Color3.fromRGB(160, 30, 30) or Color3.fromRGB(35, 35, 48)
    toggleBtn.TextColor3 = Aimbot and Color3.new(1, 1, 1) or Color3.fromRGB(200, 200, 200)
end)

--═══════════ SLIDER ═══════════
local function makeSlider(label, min, max, default, posY, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 40)
    container.Position = UDim2.new(0, 10, 0, posY)
    container.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
    container.BorderSizePixel = 0
    container.Parent = Main

    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 6)
    cc.Parent = container

    local label2 = Instance.new("TextLabel")
    label2.Size = UDim2.new(1, -12, 0, 16)
    label2.Position = UDim2.new(0, 8, 0, 2)
    label2.BackgroundTransparency = 1
    label2.Text = label .. ": " .. default
    label2.TextColor3 = Color3.fromRGB(230, 230, 230)
    label2.TextSize = 12
    label2.Font = Enum.Font.Gotham
    label2.TextXAlignment = Enum.TextXAlignment.Left
    label2.Parent = container

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -16, 0, 6)
    bar.Position = UDim2.new(0, 8, 0, 24)
    bar.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    bar.BorderSizePixel = 0
    bar.Parent = container

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = bar

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local dragging = false
    local function update(input)
        local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local value = min + (max - min) * rel
        value = math.floor(value * 100 + 0.5) / 100  -- 2 desimal
        fill.Size = UDim2.new(rel, 0, 1, 0)
        label2.Text = label .. ": " .. value
        callback(value)
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

-- Slider Smooth (0.05 - 1)
makeSlider("Smooth", 0.05, 1, AimSmooth, 84, function(v)
    AimSmooth = v
end)

-- Slider FOV (50 - 500)
makeSlider("FOV", 50, 500, AimFOV, 128, function(v)
    AimFOV = math.floor(v)
end)

-- Toggle FOV circle visible
local fovBtn = Instance.new("TextButton")
fovBtn.Size = UDim2.new(1, -20, 0, 32)
fovBtn.Position = UDim2.new(0, 10, 0, 174)
fovBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
fovBtn.Text = "  ⭕ FOV Circle:  ON"
fovBtn.TextColor3 = Color3.new(1, 1, 1)
fovBtn.TextSize = 13
fovBtn.Font = Enum.Font.Gotham
fovBtn.TextXAlignment = Enum.TextXAlignment.Left
fovBtn.Parent = Main

local fCorner = Instance.new("UICorner")
fCorner.CornerRadius = UDim.new(0, 6)
fCorner.Parent = fovBtn

fovBtn.MouseButton1Click:Connect(function()
    ShowFOV = not ShowFOV
    fovBtn.Text = "  ⭕ FOV Circle:  " .. (ShowFOV and "ON" or "OFF")
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

print("═══ Aimbot loaded ═══")
