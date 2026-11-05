--═════════════════════════════════════════════════════
--  ⚡ UNIVERSAL HUB v2 ⚡
--  Fly | MultiJump | Speed | ESP | Aimbot | TP | Noclip
--  Delta Executor Compatible (Mobile/HP)
--═════════════════════════════════════════════════════

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

--═══════════ STATE ═══════════
local State = {
    Fly         = false,
    FlySpeed    = 60,
    MultiJump   = false,
    JumpDelay   = 0.15,
    Speed       = false,
    SpeedValue  = 50,
    Noclip      = false,
    ESP         = false,
    ESPName     = true,
    ESPTracer   = true,
    Aimbot      = false,
    AimSmooth   = 0.25,
    AimFOV      = 150,
    ShowFOV     = true,
}

local flyUp, flyDown = false, false

--═══════════ HELPER ═══════════
local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function notify(text)
    if NotificationLabel then
        NotificationLabel.Text = text
        task.delay(2, function()
            if NotificationLabel then NotificationLabel.Text = "" end
        end)
    end
end

--═══════════ FLY (FIXED - joystick HP + tombol GUI) ═══════════
local flyVelocity, flyGyro, flyConn

local function startFly()
    local root = getRoot()
    if not root then return end

    -- bersihin sisa lama
    if flyVelocity then flyVelocity:Destroy() end
    if flyGyro then flyGyro:Destroy() end

    flyVelocity = Instance.new("BodyVelocity")
    flyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    flyVelocity.Velocity = Vector3.zero
    flyVelocity.Parent = root

    flyGyro = Instance.new("BodyGyro")
    flyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    flyGyro.P = 9e4
    flyGyro.D = 500
    flyGyro.Parent = root

    flyConn = RunService.RenderStepped:Connect(function()
        if not State.Fly then return end
        local root = getRoot()
        local hum = getHum()
        if not root or not hum then return end

        local hum = getHum()
        if not hum then return end

        -- joystick HP / WASD PC sama-sama kebaca lewat MoveDirection
        local move = hum.MoveDirection

        -- tombol naik/turun dari GUI (hold)
        local vertical = Vector3.zero
        if flyUp then   vertical = Vector3.new(0, 1, 0)  end
        if flyDown then vertical = Vector3.new(0, -1, 0) end

        local velocity = (move * State.FlySpeed) + (vertical * State.FlySpeed)
        flyVelocity.Velocity = velocity

        -- biar karakter ngikutin arah kamera
        flyGyro.CFrame = CFrame.new(root.Position, root.Position + Camera.CFrame.LookVector)
    end)
end

local function stopFly()
    State.Fly = false
    if flyConn then flyConn:Disconnect() flyConn = nil end
    if flyVelocity then flyVelocity:Destroy() flyVelocity = nil end
    if flyGyro then flyGyro:Destroy() flyGyro = nil end
    -- reset velocity biar gak nge-glitch jatuh
    local root = getRoot()
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
    end
end

--═══════════ MULTIPLE JUMP (FIXED - true spam, respawn-safe) ═══════════
task.spawn(function()
    while task.wait() do
        if State.MultiJump then
            local hum = getHum()
            local root = getRoot()
            if hum and root and hum.Health > 0 then
                -- force jump state tanpa perlu nyentuh tanah
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
                root.AssemblyLinearVelocity = Vector3.new(
                    root.AssemblyLinearVelocity.X,
                    hum.JumpPower,
                    root.AssemblyLinearVelocity.Z
                )
            end
            task.wait(State.JumpDelay)
        end
    end
end)

--═══════════ SPEED HACK (FIXED - instant via Heartbeat) ═══════════
RunService.Heartbeat:Connect(function()
    local hum = getHum()
    if not hum then return end
    if State.Speed then
        if hum.WalkSpeed ~= State.SpeedValue then
            hum.WalkSpeed = State.SpeedValue
        end
        if hum.JumpPower ~= 50 then
            hum.JumpPower = 50
        end
    end
end)

--═══════════ NOCLIP ═══════════
RunService.Stepped:Connect(function()
    if not State.Noclip then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            part.CanCollide = false
        end
    end
end)

--═══════════ ESP SYSTEM (FIXED - respawn safe, gak gambar diri sendiri) ═══════════
local DrawingOK = pcall(function() local d = Drawing.new("Line") d:Remove() end)
local ESPObjects = {}   -- [player] = {line=..., billboard=..., highlight=...}

local function clearOneESP(plr)
    local obj = ESPObjects[plr]
    if not obj then return end
    if obj.line then obj.line:Remove() end
    if obj.highlight then obj.highlight:Destroy() end
    if obj.billboard then obj.billboard:Destroy() end
    ESPObjects[plr] = nil
end

local function clearAllESP()
    for plr in pairs(ESPObjects) do
        clearOneESP(plr)
    end
end

local function buildESP(plr)
    if plr == LocalPlayer then return end
    if ESPObjects[plr] then return end

    local obj = {}

    -- highlight (box effect 3D)
    local hl = Instance.new("Highlight")
    hl.FillColor = Color3.fromRGB(255, 0, 60)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.7
    hl.OutlineTransparency = 0
    hl.Enabled = true

    -- name tag billboard
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 120, 0, 30)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    nameLabel.TextStrokeTransparency = 0.4
    nameLabel.TextSize = 13
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = bb

    -- tracer line
    if DrawingOK then
        local line = Drawing.new("Line")
        line.Color = Color3.fromRGB(0, 255, 100)
        line.Thickness = 1.5
        line.Transparency = 1
        line.Visible = false
        obj.line = line
    end

    obj.highlight = hl
    obj.billboard = bb
    obj.nameLabel = nameLabel
    ESPObjects[plr] = obj

    -- pasang ke char sekarang atau tunggu respawn
    local function attach(char)
        if not char or char == LocalPlayer.Character then
            hl.Parent = nil
            bb.Parent = nil
            return
        end
        local head = char:WaitForChild("Head", 5)
        if head then
            hl.Parent = char
            bb.Parent = head
        end
    end

    if plr.Character then attach(plr.Character) end
    plr.CharacterAdded:Connect(function(c)
        task.wait(0.3)
        if State.ESP then attach(c) end
    end)
end

RunService.RenderStepped:Connect(function()
    if not State.ESP then return end

    local myRoot = getRoot()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)

    for plr, obj in pairs(ESPObjects) do
        if not plr.Parent then
            clearOneESP(plr)
            continue
        end

        local char = plr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")

        if root and head and hum and hum.Health > 0 then
            local dist = myRoot and math.floor((root.Position - myRoot.Position).Magnitude) or 0
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
            local headPos = Camera:WorldToViewportPoint(head.Position)

            -- update name
            obj.nameLabel.Text = plr.Name .. " [" .. dist .. "m]"
            obj.nameLabel.TextColor3 = dist < 30 and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(0, 255, 100)

            -- tracer
            if obj.line then
                if onScreen and State.ESPTracer then
                    obj.line.From = center
                    obj.line.To = Vector2.new(headPos.X, headPos.Y)
                    obj.line.Visible = true
                else
                    obj.line.Visible = false
                end
            end

            -- name visibility
            obj.billboard.Enabled = State.ESPName and onScreen
            obj.highlight.Enabled = true
        else
            if obj.line then obj.line.Visible = false end
            obj.billboard.Enabled = false
            obj.highlight.Enabled = false
        end
    end
end)

local function toggleESP(on)
    State.ESP = on
    if not on then
        clearAllESP()
        return
    end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then buildESP(plr) end
    end
end

Players.PlayerAdded:Connect(function(plr)
    if State.ESP then
        task.wait(1)
        buildESP(plr)
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    clearOneESP(plr)
end)

--═══════════ AIMBOT (FIXED - smooth lerp + FOV circle, gak freeze) ═══════════
local fovCircle
if DrawingOK then
    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 1.5
    fovCircle.Color = Color3.fromRGB(255, 255, 255)
    fovCircle.Filled = false
    fovCircle.Transparency = 0.6
    fovCircle.Visible = false
end

RunService.RenderStepped:Connect(function()
    -- FOV circle visual
    if fovCircle then
        if State.Aimbot and State.ShowFOV then
            fovCircle.Radius = State.AimFOV
            fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            fovCircle.Visible = true
        else
            fovCircle.Visible = false
        end
    end

    if not State.Aimbot then return end

    local myRoot = getRoot()
    if not myRoot then return end

    local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local nearest, nearestDist = nil, math.huge

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if head and hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                    -- hanya target yang ada dalam FOV circle
                    if dist < State.AimFOV and dist < nearestDist then
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

--═══════════ TP KE PLAYER (dropdown) ═══════════
local function tpTo(targetName)
    local target = Players:FindFirstChild(targetName)
    if not target or not target.Character then
        notify("⚠ Player gak ketemu / belum spawn")
        return
    end
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    local myRoot = getRoot()
    if targetRoot and myRoot then
        myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
        notify("✅ TP ke " .. targetName)
    end
end

--═══════════════════════════════════════════
--                     UI
--═══════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UniversalHubV2"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local ok = pcall(function() ScreenGui.Parent = CoreGui end)
if not ok then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Main Frame
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 250, 0, 420)
Main.Position = UDim2.new(0, 15, 0.25, 0)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = Main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(0, 255, 128)
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.5
mainStroke.Parent = Main

-- Title Bar (drag area)
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -70, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ UNIVERSAL HUB v2"
Title.TextColor3 = Color3.fromRGB(0, 255, 128)
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -32, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.TextSize = 13
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = CloseBtn

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 26, 0, 26)
MinBtn.Position = UDim2.new(1, -64, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(230, 180, 40)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.new(1, 1, 1)
MinBtn.TextSize = 13
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = TitleBar
local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(1, 0)
minCorner.Parent = MinBtn

-- Notification label
local NotificationLabel
do
    local notif = Instance.new("TextLabel")
    notif.Size = UDim2.new(1, -20, 0, 18)
    notif.Position = UDim2.new(0, 10, 0, 40)
    notif.BackgroundTransparency = 1
    notif.Text = ""
    notif.TextColor3 = Color3.fromRGB(255, 220, 80)
    notif.TextSize = 11
    notif.Font = Enum.Font.Gotham
    notif.Parent = Main
    NotificationLabel = notif
end

-- Scroll area
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -16, 1, -62)
Scroll.Position = UDim2.new(0, 8, 0, 56)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 4
Scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 128)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = Main

local scrollLayout = Instance.new("UIListLayout")
scrollLayout.Padding = UDim.new(0, 6)
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
scrollLayout.Parent = Scroll

local scrollPadding = Instance.new("UIPadding")
scrollPadding.PaddingLeft = UDim.new(0, 4)
scrollPadding.PaddingRight = UDim.new(0, 4)
scrollPadding.PaddingTop = UDim.new(0, 4)
scrollPadding.Parent = Scroll

--═══════════ UI BUILDERS ═══════════

-- Section header
local function makeSection(text, order)
    local sec = Instance.new("TextLabel")
    sec.Size = UDim2.new(1, 0, 0, 22)
    sec.BackgroundTransparency = 1
    sec.Text = "▸ " .. text
    sec.TextColor3 = Color3.fromRGB(0, 200, 255)
    sec.TextSize = 13
    sec.Font = Enum.Font.GothamBold
    sec.TextXAlignment = Enum.TextXAlignment.Left
    sec.LayoutOrder = order
    sec.Parent = Scroll
    return sec
end

-- Toggle button dengan warna dinamis
local function makeToggle(text, order, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    btn.Text = "  " .. text .. ":  OFF"
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.TextSize = 13
    btn.Font = Enum.Font.Gotham
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.LayoutOrder = order
    btn.Parent = Scroll

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    local enabled = false
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        btn.Text = "  " .. text .. ":  " .. (enabled and "ON" or "OFF")
        btn.BackgroundColor3 = enabled and Color3.fromRGB(0, 130, 70) or Color3.fromRGB(35, 35, 48)
        btn.TextColor3 = enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        callback(enabled, btn)
    end)

    return btn
end

-- Slider
local function makeSlider(label, min, max, default, order, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 44)
    container.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
    container.BorderSizePixel = 0
    container.LayoutOrder = order
    container.Parent = Scroll

    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 6)
    cc.Parent = container

    local label2 = Instance.new("TextLabel")
    label2.Size = UDim2.new(1, -12, 0, 18)
    label2.Position = UDim2.new(0, 8, 0, 3)
    label2.BackgroundTransparency = 1
    label2.Text = label .. ": " .. default
    label2.TextColor3 = Color3.fromRGB(230, 230, 230)
    label2.TextSize = 12
    label2.Font = Enum.Font.Gotham
    label2.TextXAlignment = Enum.TextXAlignment.Left
    label2.Parent = container

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -16, 0, 6)
    bar.Position = UDim2.new(0, 8, 0, 28)
    bar.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    bar.BorderSizePixel = 0
    bar.Parent = container

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = bar

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 255, 128)
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local dragging = false
    local function update(input)
        local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * rel + 0.5)
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

    return container
end

-- Hold button (naik/turun) — aktif selama jari nempel
local function makeHoldButton(text, order, onHold, onRelease)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 100)
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.LayoutOrder = order
    btn.Parent = Scroll

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    btn.MouseButton1Down:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 160)
        onHold()
    end)
    btn.MouseButton1Up:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 100)
        onRelease()
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 100)
        onRelease()
    end)

    return btn
end

--═══════════ BUILD UI CONTENT ═══════════
local order = 0
local function nextOrder() order += 1 return order end

-- ── MOVEMENT ──
makeSection("MOVEMENT", nextOrder())

local flyBtn = makeToggle("✈️ Fly", nextOrder(), function(on)
    State.Fly = on
    if on then startFly() else stopFly() end
end)
makeSlider("Fly Speed", 20, 200, State.FlySpeed, nextOrder(), function(v) State.FlySpeed = v end)

makeHoldButton("⬆️  NAIK (hold)", nextOrder(), function() flyUp = true end, function() flyUp = false end)
makeHoldButton("⬇️  TURUN (hold)", nextOrder(), function() flyDown = true end, function() flyDown = false end)

makeToggle("🦘 Multi Jump (spam)", nextOrder(), function(on) State.MultiJump = on end)
makeSlider("Jump Delay", 0.05, 1, State.JumpDelay, nextOrder(), function(v) State.JumpDelay = v end)

makeToggle("🏃 Speed Hack", nextOrder(), function(on)
    State.Speed = on
    local hum = getHum()
    if hum then
        hum.WalkSpeed = on and State.SpeedValue or 16
    end
end)
makeSlider("Walk Speed", 16, 200, State.SpeedValue, nextOrder(), function(v) State.SpeedValue = v end)

makeToggle("👻 Noclip", nextOrder(), function(on) State.Noclip = on end)

-- ── VISUAL / ESP ──
makeSection("VISUAL — ESP", nextOrder())

makeToggle("👁️ ESP Master", nextOrder(), function(on) toggleESP(on) end)
makeToggle("🏷️ ESP Name + Jarak", nextOrder(), function(on) State.ESPName = on end)
makeToggle("📏 ESP Tracer (garis)", nextOrder(), function(on) State.ESPTracer = on end)

-- ── COMBAT ──
makeSection("COMBAT — AIMBOT", nextOrder())

makeToggle("🎯 Aimbot", nextOrder(), function(on) State.Aimbot = on end)
makeSlider("Aim Smooth", 0.05, 1, State.AimSmooth, nextOrder(), function(v) State.AimSmooth = v end)
makeSlider("Aim FOV", 50, 500, State.AimFOV, nextOrder(), function(v) State.AimFOV = v end)
makeToggle("⭕ Tampilkan FOV Circle", nextOrder(), function(on) State.ShowFOV = on end)

-- ── TELEPORT ──
makeSection("TELEPORT", nextOrder())

local tpListFrame = Instance.new("Frame")
tpListFrame.Size = UDim2.new(1, 0, 0, 0)
tpListFrame.AutomaticSize = Enum.AutomaticSize.Y
tpListFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
tpListFrame.BorderSizePixel = 0
tpListFrame.LayoutOrder = nextOrder()
tpListFrame.Parent = Scroll

local tpListLayout = Instance.new("UIListLayout")
tpListLayout.Padding = UDim.new(0, 4)
tpListLayout.SortOrder = Enum.SortOrder.LayoutOrder
tpListLayout.Parent = tpListFrame

local tpPadding = Instance.new("UIPadding")
tpPadding.PaddingLeft = UDim.new(0, 6)
tpPadding.PaddingRight = UDim.new(0, 6)
tpPadding.PaddingTop = UDim.new(0, 6)
tpPadding.PaddingBottom = UDim.new(0, 6)
tpPadding.Parent = tpListFrame

local function refreshTPList()
    for _, child in pairs(tpListFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local tpBtn = Instance.new("TextButton")
            tpBtn.Size = UDim2.new(1, 0, 0, 28)
            tpBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 90)
            tpBtn.Text = "🌀 " .. plr.Name
            tpBtn.TextColor3 = Color3.new(1, 1, 1)
            tpBtn.TextSize = 12
            tpBtn.Font = Enum.Font.Gotham
            tpBtn.LayoutOrder = nextOrder()
            tpBtn.Parent = tpListFrame

            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 5)
            c.Parent = tpBtn

            tpBtn.MouseButton1Click:Connect(function()
                tpTo(plr.Name)
            end)
        end
    end
end

local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(1, 0, 0, 30)
refreshBtn.BackgroundColor3 = Color3.fromRGB(70, 45, 110)
refreshBtn.Text = "🔄 Refresh List Player"
refreshBtn.TextColor3 = Color3.new(1, 1, 1)
refreshBtn.TextSize = 13
refreshBtn.Font = Enum.Font.GothamBold
refreshBtn.LayoutOrder = nextOrder()
refreshBtn.Parent = Scroll
local refreshCorner = Instance.new("UICorner")
refreshCorner.CornerRadius = UDim.new(0, 6)
refreshCorner.Parent = refreshBtn
refreshBtn.MouseButton1Click:Connect(refreshTPList)

-- tombol TP terdekat (shortcut)
local tpNearBtn = Instance.new("TextButton")
tpNearBtn.Size = UDim2.new(1, 0, 0, 30)
tpNearBtn.BackgroundColor3 = Color3.fromRGB(70, 45, 110)
tpNearBtn.Text = "⚡ TP ke Player Terdekat"
tpNearBtn.TextColor3 = Color3.new(1, 1, 1)
tpNearBtn.TextSize = 13
tpNearBtn.Font = Enum.Font.GothamBold
tpNearBtn.LayoutOrder = nextOrder()
tpNearBtn.Parent = Scroll
local tpNearCorner = Instance.new("UICorner")
tpNearCorner.CornerRadius = UDim.new(0, 6)
tpNearCorner.Parent = tpNearBtn
tpNearBtn.MouseButton1Click:Connect(function()
    local myRoot = getRoot()
    if not myRoot then return end
    local nearest, dist = nil, math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local r = plr.Character:FindFirstChild("HumanoidRootPart")
            if r then
                local d = (r.Position - myRoot.Position).Magnitude
                if d < dist then nearest = plr; dist = d end
            end
        end
    end
    if nearest then tpTo(nearest.Name) else notify("⚠ Gak ada player lain") end
end)

-- init list
refreshTPList()

--═══════════ DRAG SYSTEM ═══════════
do
    local dragging = false
    local dragInput, dragStart, startPos

    TitleBar.InputBegan:Connect(function(input)
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

--═══════════ MINIMIZE / CLOSE ═══════════
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Scroll.Visible = not minimized
    NotificationLabel.Visible = not minimized
    Main.Size = minimized and UDim2.new(0, 250, 0, 36) or UDim2.new(0, 250, 0, 420)
end)

CloseBtn.MouseButton1Click:Connect(function()
    stopFly()
    toggleESP(false)
    State.MultiJump = false
    State.Speed = false
    State.Noclip = false
    State.Aimbot = false
    if fovCircle then fovCircle:Remove() end
    local hum = getHum()
    if hum then hum.WalkSpeed = 16 end
    ScreenGui:Destroy()
end)

notify("✅ Universal Hub v2 loaded!")
print("═══ Universal Hub v2 loaded ═══")
