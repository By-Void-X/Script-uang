--[[
    Voxel Assassin v3
    UI: Rayfield (Bisa di-hide, support tombol di HP)
    fitur:
      1. Target Lock TP (nempel 1 musuh sampai mati, baru pindah)
      2. Custom Offset TP (X, Y, Z)
      3. Save Waypoint / Set Poin
      4. Speed Glitch
      5. Manual TP
    absolute ollie, built by olivia
--]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local State = {
    -- Lock TP
    LockEnabled = false,
    LockThread = nil,
    LockDelay = 0.1,
    LockedTarget = nil,     -- Player object
    OffsetX = 0, OffsetY = 0, OffsetZ = 3,
    -- Speed Glitch
    SpeedGlitchEnabled = false,
    SpeedGlitchSpeed = 2,
    SpeedGlitchThread = nil,
    -- Waypoints
    Waypoints = {},
    SelectedWaypoint = nil,
    -- Manual TP
    SelectedPlayer = nil,
}

local function notify(t, c)
    Rayfield:Notify({ Title = t, Content = c, Duration = 3 })
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

-- cari musuh baru (yang hidup)
local function findNewTarget()
    local enemies = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if isEnemy(p) then
            local hum = getPlayerHum(p)
            if hum and hum.Health > 0 and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(enemies, p)
            end
        end
    end
    if #enemies > 0 then
        return enemies[math.random(1, #enemies)]
    end
    return nil
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

-- ============================================================
-- TARGET LOCK (Nempel sampai mati)
-- ============================================================
local function startLockTP()
    State.LockEnabled = true
    State.LockedTarget = nil -- reset
    
    if State.LockThread then task.cancel(State.LockThread) end
    State.LockThread = task.spawn(function()
        while State.LockEnabled do
            -- Cek target saat ini: masih idup?
            local isValid = false
            if State.LockedTarget then
                local hum = getPlayerHum(State.LockedTarget)
                if hum and hum.Health > 0 and State.LockedTarget.Character then
                    isValid = true
                end
            end

            -- Kalau target mati / ilang, cari target baru
            if not isValid then
                State.LockedTarget = findNewTarget()
                if State.LockedTarget then
                    notify("Lock TP", "Target: " .. State.LockedTarget.Name)
                end
            end

            -- Eksekusi TP kalau target valid
            if State.LockedTarget then
                tpBehindTarget(State.LockedTarget)
            end

            task.wait(State.LockDelay)
        end
    end)
end

local function stopLockTP()
    State.LockEnabled = false
    State.LockedTarget = nil
    if State.LockThread then task.cancel(State.LockThread); State.LockThread = nil end
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
local function deleteWaypoint(name) State.Waypoints[name] = nil end
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
-- UI RAYFIELD
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name = "Voxel Assassin v3",
    LoadingTitle = "Voxel Assassin",
    LoadingSubtitle = "Target Lock TP",
    ConfigurationSaving = { Enabled = false },
    Keybind = Enum.KeyCode.RightShift, -- Bisa di-hide di HP
})

local AssassinTab = Window:CreateTab("Assassin (Lock TP)", 4483362458)
AssassinTab:CreateSection("Auto Lock TP")
AssassinTab:CreateToggle({
    Name = "Enable Lock TP",
    CurrentValue = false,
    Flag = "LockToggle",
    Callback = function(v)
        if v then startLockTP() else stopLockTP() end
    end,
})
AssassinTab:CreateSlider({
    Name = "TP Delay (detik)",
    Range = {0.05, 1},
    Increment = 0.05,
    Suffix = "s",
    CurrentValue = 0.1,
    Flag = "LockDelay",
    Callback = function(v) State.LockDelay = v end,
})
AssassinTab:CreateParagraph({ Title = "Info", Content = "Nempel ke 1 musuh (TP belakang) terus-terusan sampai dia MATI. Baru pindah target." })

AssassinTab:CreateSection("Offset TP")
AssassinTab:CreateSlider({
    Name = "Offset X (kiri/kanan)", Range = {-10, 10}, Increment = 1, Suffix = "X",
    CurrentValue = 0, Flag = "OffX", Callback = function(v) State.OffsetX = v end,
})
AssassinTab:CreateSlider({
    Name = "Offset Y (atas/bawah)", Range = {-10, 10}, Increment = 1, Suffix = "Y",
    CurrentValue = 0, Flag = "OffY", Callback = function(v) State.OffsetY = v end,
})
AssassinTab:CreateSlider({
    Name = "Offset Z (belakang/depan)", Range = {-10, 20}, Increment = 1, Suffix = "Z",
    CurrentValue = 3, Flag = "OffZ", Callback = function(v) State.OffsetZ = v end,
})

local WpTab = Window:CreateTab("Set Poin (Waypoint)", 4483362458)
WpTab:CreateSection("Save / Load Poin")
local wpInput = WpTab:CreateInput({
    Name = "Nama Poin",
    Placeholder = "contoh: base, spawn, sniper",
    CurrentValue = "",
    Flag = "WpInput",
    RemoveTextAfterFocusLost = false,
})
WpTab:CreateButton({
    Name = "Set Poin di Posisi Lo",
    Callback = function()
        if wpInput.Value == "" then notify("Set Poin", "isi nama dulu"); return end
        if saveWaypoint(wpInput.Value) then
            notify("Set Poin", "Disimpan: " .. wpInput.Value)
            wpDropdown:Refresh(getWaypointNames())
        end
    end,
})
local wpDropdown
wpDropdown = WpTab:CreateDropdown({
    Name = "Pilih Poin",
    Options = getWaypointNames(),
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "WpSelect",
    Callback = function(opt) if opt and opt[1] then State.SelectedWaypoint = opt[1] end end,
})
WpTab:CreateButton({
    Name = "TP ke Poin",
    Callback = function()
        if not State.SelectedWaypoint then notify("Set Poin", "pilih poin dulu"); return end
        if loadWaypoint(State.SelectedWaypoint) then notify("Set Poin", "TP ke " .. State.SelectedWaypoint) end
    end,
})
WpTab:CreateButton({
    Name = "Hapus Poin",
    Callback = function()
        if not State.SelectedWaypoint then return end
        deleteWaypoint(State.SelectedWaypoint)
        wpDropdown:Refresh(getWaypointNames())
        notify("Set Poin", "Dihapus")
    end,
})

local GlitchTab = Window:CreateTab("Speed Glitch", 4483362458)
GlitchTab:CreateSection("Speed Glitch (CFrame)")
GlitchTab:CreateToggle({
    Name = "Enable Speed Glitch", CurrentValue = false, Flag = "SGToggle",
    Callback = function(v) if v then startSpeedGlitch() else stopSpeedGlitch() end end,
})
GlitchTab:CreateSlider({
    Name = "Glitch Speed", Range = {0.5, 20}, Increment = 0.5, Suffix = "studs/frame",
    CurrentValue = 2, Flag = "SGSpeed", Callback = function(v) State.SpeedGlitchSpeed = v end,
})
GlitchTab:CreateParagraph({ Title = "Info", Content = "Geser CFrame, bukan ubah WalkSpeed. Bisa nembus server-authoritative." })

local ManualTab = Window:CreateTab("Manual TP", 4483362458)
ManualTab:CreateSection("TP ke Player")
local playerDropdown
playerDropdown = ManualTab:CreateDropdown({
    Name = "Pilih Player",
    Options = getPlayerNames(),
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "PlayerSelect",
    Callback = function(opt) if opt and opt[1] then State.SelectedPlayer = opt[1] end end,
})
ManualTab:CreateButton({
    Name = "TP ke Player (pake offset)",
    Callback = function()
        if not State.SelectedPlayer then notify("TP", "pilih player dulu"); return end
        tpToPlayer(State.SelectedPlayer)
    end,
})
ManualTab:CreateButton({
    Name = "Refresh Player List",
    Callback = function()
        playerDropdown:Refresh(getPlayerNames())
    end,
})

Players.PlayerAdded:Connect(function() task.wait(0.5); playerDropdown:Refresh(getPlayerNames()) end)
Players.PlayerRemoving:Connect(function() task.wait(0.5); playerDropdown:Refresh(getPlayerNames()) end)

notify("Voxel Assassin", "v3 loaded — Target Lock siap")
