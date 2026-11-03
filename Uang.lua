--[[
    Voxel Assassin v2
    UI: Fluent
    fitur:
      1. Auto Cycle TP ke Belakang Musuh (otomatis skip tim sendiri & target mati)
      2. Custom Offset TP (X, Y, Z)
      3. SAVE WAYPOINT (Set Poin lokasi, simpan nama, TP balik kapan aja)
      4. Speed Glitch (geser CFrame tiap frame)
      5. Manual TP (pake dropdown)
    executor: HP / PC — Fluent UI
    absolute ollie, built by olivia
--]]

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local State = {
    -- Cycle TP
    CycleEnabled = false,
    CycleThread = nil,
    CycleDelay = 0.3,
    OffsetX = 0, OffsetY = 0, OffsetZ = 3,
    CurrentTarget = nil,
    -- Speed Glitch
    SpeedGlitchEnabled = false,
    SpeedGlitchSpeed = 2,
    SpeedGlitchThread = nil,
    -- Waypoints
    Waypoints = {}, -- { [nama] = CFrame }
    SelectedWaypoint = nil,
    -- Manual TP
    SelectedPlayer = nil,
}

local function notify(t, c, dur)
    Fluent:Notify({ Title = t, Content = c, Duration = dur or 4 })
end
local function getChar() return LocalPlayer.Character end
local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getPlayerHRP(p)
    local c = p.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getPlayerHum(p)
    local c = p.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- ============================================================
-- TIM & MUSUH
-- ============================================================
local function isEnemy(p)
    if p == LocalPlayer then return false end
    if p.Team and LocalPlayer.Team then
        return p.Team ~= LocalPlayer.Team
    end
    return true
end

local function getEnemyList()
    local enemies = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if isEnemy(p) then
            local hum = getPlayerHum(p)
            if hum and hum.Health > 0 and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(enemies, p)
            end
        end
    end
    return enemies
end

-- ============================================================
-- CORE TP
-- ============================================================
local function tpBehindTarget(target)
    local myHRP = getHRP()
    local tHRP = getPlayerHRP(target)
    if not myHRP or not tHRP then return false end
    local offset = CFrame.new(State.OffsetX, State.OffsetY, State.OffsetZ)
    myHRP.CFrame = tHRP.CFrame * offset
    return true
end

local function startCycle()
    State.CycleEnabled = true
    if State.CycleThread then task.cancel(State.CycleThread) end
    State.CycleThread = task.spawn(function()
        while State.CycleEnabled do
            local enemies = getEnemyList()
            if #enemies > 0 then
                local target = enemies[math.random(1, #enemies)]
                if target then
                    tpBehindTarget(target)
                    State.CurrentTarget = target.Name
                end
            else
                State.CurrentTarget = "Nggak ada musuh hidup"
            end
            task.wait(State.CycleDelay)
        end
    end)
end

local function stopCycle()
    State.CycleEnabled = false
    State.CurrentTarget = nil
    if State.CycleThread then task.cancel(State.CycleThread); State.CycleThread = nil end
end

-- ============================================================
-- SPEED GLITCH
-- ============================================================
local function startSpeedGlitch()
    State.SpeedGlitchEnabled = true
    if State.SpeedGlitchThread then State.SpeedGlitchThread:Disconnect() end
    State.SpeedGlitchThread = RunService.Heartbeat:Connect(function()
        if not State.SpeedGlitchEnabled then return end
        local hrp = getHRP()
        local hum = getHum()
        if not hrp or not hum or hum.Health <= 0 then return end
        local dir = hum.MoveDirection
        if dir.Magnitude > 0 then
            local cf = hrp.CFrame
            local newPos = cf.Position + dir.Unit * State.SpeedGlitchSpeed
            hrp.CFrame = CFrame.new(newPos) * (cf - cf.Position)
        end
    end)
end

local function stopSpeedGlitch()
    State.SpeedGlitchEnabled = false
    if State.SpeedGlitchThread then State.SpeedGlitchThread:Disconnect(); State.SpeedGlitchThread = nil end
end

-- ============================================================
-- WAYPOINT
-- ============================================================
local function saveWaypoint(name)
    local hrp = getHRP()
    if not hrp then return false end
    State.Waypoints[name] = hrp.CFrame
    return true
end

local function loadWaypoint(name)
    local cf = State.Waypoints[name]
    if not cf then return false end
    local hrp = getHRP()
    if not hrp then return false end
    hrp.CFrame = cf
    return true
end

local function deleteWaypoint(name)
    State.Waypoints[name] = nil
end

local function getWaypointNames()
    local names = {}
    for n, _ in pairs(State.Waypoints) do table.insert(names, n) end
    return names
end

-- ============================================================
-- MANUAL TP
-- ============================================================
local function tpToPlayer(name)
    local target = Players:FindFirstChild(name)
    if not target then notify("TP", "player nggak ketemu"); return end
    local tHRP = getPlayerHRP(target)
    local hrp = getHRP()
    if not tHRP or not hrp then return end
    hrp.CFrame = tHRP.CFrame * CFrame.new(State.OffsetX, State.OffsetY, State.OffsetZ)
end

local function getPlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(names, p.Name) end
    end
    return names
end

-- ============================================================
-- UI FLUENT
-- ============================================================
local Window = Fluent:CreateWindow({
    Title = "Voxel Assassin v2",
    SubTitle = "Cycle TP + Save Poin",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 440),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift,
})

local Tabs = {
    Assassin = Window:AddTab({ Title = "Assassin", Icon = "crosshair" }),
    Waypoint = Window:AddTab({ Title = "Set Poin", Icon = "map-pin" }),
    Glitch = Window:AddTab({ Title = "Speed Glitch", Icon = "zap" }),
    Manual = Window:AddTab({ Title = "Manual TP", Icon = "user" }),
}

-- ============================================================
-- TAB: ASSASSIN (CYCLE)
-- ============================================================
Tabs.Assassin:AddParagraph({
    Title = "Auto TP Cycle",
    Content = "TP ke belakang musuh (beda tim) terus-menerus. Kalau target mati, otomatis ganti ke musuh lain.",
})

Tabs.Assassin:AddToggle("CycleToggle", {
    Title = "Enable Auto Cycle",
    Default = false,
    Callback = function(v)
        if v then startCycle() else stopCycle() end
    end,
})

Tabs.Assassin:AddSlider("CycleDelaySlider", {
    Title = "Delay Ganti Target (detik)",
    Default = 0.3,
    Min = 0.1,
    Max = 3,
    Rounding = 1,
    Callback = function(v) State.CycleDelay = v end,
})

local statusLabel = Tabs.Assassin:AddParagraph({
    Title = "Live Status",
    Content = "Target: -",
})
task.spawn(function()
    while true do
        task.wait(0.5)
        local txt = State.CurrentTarget or "Nggak ada musuh / mati"
        pcall(function()
            statusLabel:SetDesc("Target: " .. txt)
        end)
    end
end)

Tabs.Assassin:AddDivider()

Tabs.Assassin:AddSlider("OffX", {
    Title = "Offset X (kiri/kanan)",
    Default = 0, Min = -10, Max = 10, Rounding = 1,
    Callback = function(v) State.OffsetX = v end,
})
Tabs.Assassin:AddSlider("OffY", {
    Title = "Offset Y (atas/bawah)",
    Default = 0, Min = -10, Max = 10, Rounding = 1,
    Callback = function(v) State.OffsetY = v end,
})
Tabs.Assassin:AddSlider("OffZ", {
    Title = "Offset Z (belakang/depan)",
    Default = 3, Min = -10, Max = 20, Rounding = 1,
    Callback = function(v) State.OffsetZ = v end,
})

Tabs.Assassin:AddParagraph({
    Title = "Info Offset",
    Content = "Z positif = belakang target. Z negatif = depan. X = geser samping. Y = naik/turun.",
})

-- ============================================================
-- TAB: WAYPOINT (SET POIN)
-- ============================================================
Tabs.Waypoint:AddParagraph({
    Title = "Set Poin (Waypoint)",
    Content = "Simpan posisi sekarang dengan nama. Klik Load buat TP balik ke titik itu kapan aja.",
})

Tabs.Waypoint:AddInput("WpName", {
    Title = "Nama Poin",
    Placeholder = "contoh: base, spawn, sniper spot",
    Default = "",
})

Tabs.Waypoint:AddButton({
    Title = "Set Poin di Posisi Lo",
    Description = "Simpan posisi sekarang",
    Callback = function()
        local name = Tabs.Waypoint:GetInput("WpName").Value
        if not name or name == "" then
            notify("Set Poin", "isi nama dulu, contoh: 'base' atau 'spawn'")
            return
        end
        if saveWaypoint(name) then
            notify("Set Poin", "Poin '" .. name .. "' disimpan")
            wpDropdown:SetValues(getWaypointNames())
            wpDropdown:SetValue(name)
        else
            notify("Set Poin", "gagal simpan, karakter belum spawn")
        end
    end,
})

local wpDropdown
wpDropdown = Tabs.Waypoint:AddDropdown("WpSelect", {
    Title = "Pilih Poin",
    Values = getWaypointNames(),
    Multi = false,
    Default = 1,
})
wpDropdown:OnChanged(function(v) State.SelectedWaypoint = v end)

Tabs.Waypoint:AddButton({
    Title = "TP ke Poin",
    Description = "Teleport ke poin yang dipilih",
    Callback = function()
        local name = State.SelectedWaypoint
        if not name then notify("Set Poin", "pilih poin dulu"); return end
        if loadWaypoint(name) then
            notify("Set Poin", "TP ke '" .. name .. "'")
        else
            notify("Set Poin", "gagal TP, poin nggak ada / karakter belum spawn")
        end
    end,
})

Tabs.Waypoint:AddButton({
    Title = "Hapus Poin",
    Description = "Hapus poin yang dipilih",
    Callback = function()
        local name = State.SelectedWaypoint
        if not name then return end
        deleteWaypoint(name)
        wpDropdown:SetValues(getWaypointNames())
        notify("Set Poin", "Poin '" .. name .. "' dihapus")
    end,
})

Tabs.Waypoint:AddButton({
    Title = "Refresh List Poin",
    Callback = function()
        wpDropdown:SetValues(getWaypointNames())
        notify("Set Poin", "list refreshed")
    end,
})

Tabs.Waypoint:AddDivider()

Tabs.Waypoint:AddParagraph({
    Title = "Info",
    Content = "Poin disimpan cuma di memori script (hilang kalau lo mati atau rejoin). Kalau lo mau permanen, bilang gw tambahin save ke file.",
})

-- ============================================================
-- TAB: SPEED GLITCH
-- ============================================================
Tabs.Glitch:AddParagraph({
    Title = "Speed Glitch",
    Content = "Nggak ngubah WalkSpeed. Geser CFrame tiap frame. Server nggak bakal reset karena nggak ada velocity aneh.",
})
Tabs.Glitch:AddSlider("SGSpeed", {
    Title = "Glitch Speed (studs/frame)",
    Default = 2, Min = 0.5, Max = 20, Rounding = 1,
    Callback = function(v) State.SpeedGlitchSpeed = v end,
})
Tabs.Glitch:AddToggle("SGToggle", {
    Title = "Enable Speed Glitch",
    Default = false,
    Callback = function(v)
        if v then startSpeedGlitch() else stopSpeedGlitch() end
    end,
})

-- ============================================================
-- TAB: MANUAL TP
-- ============================================================
Tabs.Manual:AddParagraph({
    Title = "Manual TP",
    Content = "Pilih player, klik TP. TP bakal pakai offset yang di-set di tab Assassin.",
})

local playerDropdown
playerDropdown = Tabs.Manual:AddDropdown("PlayerSelect", {
    Title = "Pilih Player",
    Values = getPlayerNames(),
    Multi = false,
    Default = 1,
})
playerDropdown:OnChanged(function(v) State.SelectedPlayer = v end)

Tabs.Manual:AddButton({
    Title = "TP ke Player (pake offset)",
    Callback = function()
        if not State.SelectedPlayer then notify("TP", "pilih player dulu"); return end
        tpToPlayer(State.SelectedPlayer)
    end,
})
Tabs.Manual:AddButton({
    Title = "Refresh Player List",
    Callback = function()
        playerDropdown:SetValues(getPlayerNames())
        notify("TP", "list refreshed")
    end,
})

-- ============================================================
-- AUTO UPDATE LIST
-- ============================================================
Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    playerDropdown:SetValues(getPlayerNames())
end)
Players.PlayerRemoving:Connect(function()
    task.wait(0.5)
    playerDropdown:SetValues(getPlayerNames())
end)

notify("Voxel Assassin v2", "loaded — Assassin + Set Poin siap")
