-- menu_fix.lua — Delta, recon + probe tanpa UIStroke
-- built by odil9 — discord.gg/xGDFJ29MmA
-- susunan: config, guard, parent, gui shell, log, tombol, recon, probe, unload

local Config = {
    judul = "odil9 recon+probe",
    ukuran = UDim2.new(0, 460, 0, 560),
    posisi = UDim2.new(0, 20, 0, 60),
    warna_bg = Color3.fromRGB(18, 16, 22),
    warna_border = Color3.fromRGB(255, 60, 180),
    warna_teks = Color3.fromRGB(230, 225, 235),
    warna_tombol = Color3.fromRGB(40, 34, 48),
    max_kedalaman = 8,
    max_hasil = 2000,
    timeout_invoke = 3,
    cooldown_probe = 0.5,
}

print("[odil9] mulai")
if not getgenv then warn("[odil9] no getgenv"); return end
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then warn("[odil9] no LocalPlayer"); return end

-- bersihin instance lama
if getgenv().odil9_menu_unload then pcall(getgenv().odil9_menu_unload) end

-- ===== Parent =====
local parent_gui = gethui and gethui() or game:GetService("CoreGui")
if not parent_gui then parent_gui = LocalPlayer:WaitForChild("PlayerGui", 5) end
print("[odil9] parent:", parent_gui and parent_gui:GetFullName() or "nil")

-- ===== GUI shell =====
local gui = Instance.new("ScreenGui")
gui.Name = "odil9_recon_probe"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999999
gui.Parent = parent_gui
print("[odil9] gui ke-mount")

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = Config.ukuran
frame.Position = Config.posisi
frame.BackgroundColor3 = Config.warna_bg
frame.BorderSizePixel = 2
frame.BorderColor3 = Config.warna_border
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local judul = Instance.new("TextLabel")
judul.Size = UDim2.new(1, -20, 0, 28)
judul.Position = UDim2.new(0, 10, 0, 6)
judul.BackgroundTransparency = 1
judul.Text = Config.judul .. " — absolute larp"
judul.TextColor3 = Config.warna_border
judul.Font = Enum.Font.Code
judul.TextSize = 14
judul.TextXAlignment = Enum.TextXAlignment.Left
judul.Parent = frame

local function buat_tombol(nama, x, w, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 0, 26)
    b.Position = UDim2.new(0, x, 0, 40)
    b.BackgroundColor3 = Config.warna_tombol
    b.BorderSizePixel = 1
    b.BorderColor3 = Config.warna_border
    b.Text = nama
    b.TextColor3 = Config.warna_teks
    b.Font = Enum.Font.Code
    b.TextSize = 12
    b.Parent = frame
    b.MouseButton1Click:Connect(cb)
    return b
end

-- ===== Log pane =====
local log_box = Instance.new("TextBox")
log_box.Size = UDim2.new(1, -20, 1, -120)
log_box.Position = UDim2.new(0, 10, 0, 74)
log_box.BackgroundColor3 = Color3.fromRGB(12, 11, 15)
log_box.BorderSizePixel = 1
log_box.BorderColor3 = Config.warna_border
log_box.Text = ""
log_box.TextColor3 = Config.warna_teks
log_box.Font = Enum.Font.Code
log_box.TextSize = 11
log_box.TextXAlignment = Enum.TextXAlignment.Left
log_box.TextYAlignment = Enum.TextYAlignment.Top
log_box.MultiLine = true
log_box.ClearTextOnFocus = false
log_box.TextEditable = false
log_box.Parent = frame

local log_buffer = {}
local log_dirty = false
local MAX_LOG = 5000

local function flush_log()
    if not log_dirty then return end
    log_box.Text = table.concat(log_buffer, "\n")
    log_dirty = false
end

local function tulis(...)
    local p = {}
    for i = 1, select("#", ...) do p[i] = tostring(select(i, ...)) end
    table.insert(log_buffer, table.concat(p, " "))
    if #log_buffer > MAX_LOG then table.remove(log_buffer, 1) end
    log_dirty = true
end
getgenv().odil9_log = tulis

-- ===== Tombol =====
local function copy_semua()
    flush_log()
    local teks = table.concat(log_buffer, "\n")
    local ok = setclipboard and pcall(setclipboard, teks)
    if not ok then
        log_box:CaptureFocus()
        log_box.CursorPosition = #log_box.Text + 1
        log_box.SelectionStart = 1
        print("[odil9] clipboard gak support, Ctrl+A Ctrl+C manual")
    else
        print("[odil9] " .. #log_buffer .. " baris ke-copy, uwu")
    end
end

local function clear_log()
    log_buffer = {}
    log_dirty = true
    flush_log()
end

-- ===== Recon engine =====
local Services = {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    ReplicatedFirst  = game:GetService("ReplicatedFirst"),
    Workspace        = game:GetService("Workspace"),
    Players          = game:GetService("Players"),
    StarterGui       = game:GetService("StarterGui"),
    StarterPack      = game:GetService("StarterPack"),
}

local hasil = { remote = {}, part = {}, tool = {}, backdoor = {}, waktu = os.time() }
local total_inst = 0
local sedang_scan = false

local function walk(inst, kedalaman, cb)
    if kedalaman > Config.max_kedalaman then return end
    if #hasil.remote + #hasil.part + #hasil.tool + #hasil.backdoor > Config.max_hasil then return end
    total_inst = total_inst + 1
    cb(inst, kedalaman)
    local ok, anak = pcall(function() return inst:GetChildren() end)
    if not ok then return end
    for _, c in ipairs(anak) do walk(c, kedalaman + 1, cb) end
end

local function pindai()
    if sedang_scan then tulis("[odil9] scan masih jalan"); flush_log(); return end
    sedang_scan = true
    hasil.remote, hasil.part, hasil.tool, hasil.backdoor = {}, {}, {}, {}
    total_inst = 0
    tulis("[odil9] === mulai scan ===")
    tulis("[odil9] waktu:", os.date("%H:%M:%S"))
    tulis("[odil9] map:", game.PlaceId)

    for _, svc in pairs(Services) do
        pcall(function()
            walk(svc, 0, function(inst)
                if inst:IsA("RemoteEvent") or inst:IsA("RemoteFunction") or inst:IsA("UnreliableRemoteEvent") then
                    local nm = string.lower(inst.Name)
                    local curiga = string.find(nm, "admin") or string.find(nm, "give") or
                                   string.find(nm, "buy") or string.find(nm, "cash") or
                                   string.find(nm, "reward") or string.find(nm, "donate") or false
                    table.insert(hasil.remote, {
                        path = inst:GetFullName(), kelas = inst.ClassName, nama = inst.Name, curiga = curiga,
                    })
                end
            end)
        end)
    end
    tulis("[odil9] remote ketemu:", #hasil.remote)
    for _, r in ipairs(hasil.remote) do
        tulis(("[odil9] %s  %s%s"):format(r.kelas, r.path, r.curiga and "  <-- CURIGA" or ""))
    end

    pcall(function()
        walk(Services.Workspace, 0, function(inst)
            if inst:IsA("BasePart") then
                local sifat = {}
                if inst.Anchored then table.insert(sifat, "Anchored") end
                if inst.CanCollide == false then table.insert(sifat, "NoCollide") end
                if inst.Transparency >= 0.9 then table.insert(sifat, "Invisible") end
                if inst:FindFirstChildOfClass("ClickDetector") then table.insert(sifat, "ClickDetector") end
                if inst:FindFirstChildOfClass("ProximityPrompt") then table.insert(sifat, "ProximityPrompt") end
                if #sifat > 0 then table.insert(hasil.part, { path = inst:GetFullName(), sifat = sifat }) end
            end
        end)
    end)
    tulis("[odil9] part menarik:", #hasil.part)

    pcall(function()
        walk(Services.StarterPack, 0, function(inst)
            if inst:IsA("Tool") then table.insert(hasil.tool, { path = inst:GetFullName(), nama = inst.Name }) end
        end)
        walk(LocalPlayer, 0, function(inst)
            if inst:IsA("Tool") then table.insert(hasil.tool, { path = inst:GetFullName(), nama = inst.Name, ditangan = true }) end
        end)
    end)
    tulis("[odil9] tool:", #hasil.tool)

    local pola = { "loadstring", "getfenv", "setfenv", "HttpGet", "HttpService" }
    pcall(function()
        walk(LocalPlayer, 0, function(inst)
            if inst:IsA("LuaSourceContainer") then
                local ok, src = pcall(function() return inst.Source end)
                if ok and type(src) == "string" and #src < 500000 then
                    for _, p in ipairs(pola) do
                        if string.find(src, p, 1, true) then
                            table.insert(hasil.backdoor, { path = inst:GetFullName(), pola = p }); break
                        end
                    end
                end
            end
        end)
    end)
    tulis("[odil9] backdoor sinyal:", #hasil.backdoor)
    tulis("[odil9] total instance:", total_inst)
    tulis("[odil9] === scan selesai ===")
    getgenv().odil9_recon = hasil
    sedang_scan = false
    flush_log()
end

-- ===== Probe engine =====
local probe_hasil = { catatan = {}, remote = {}, hdadmin = {} }
getgenv().odil9_probe = probe_hasil

local function probe_tulis(...)
    local p = {}
    for i = 1, select("#", ...) do p[i] = tostring(select(i, ...)) end
    local line = table.concat(p, " ")
    table.insert(probe_hasil.catatan, line)
    tulis("[probe] " .. line)
end

local function resolve(path)
    local node = game
    for seg in string.gmatch(path, "[^%.]+") do
        node = node and node:FindFirstChild(seg)
    end
    return node
end

local function invoke_aman(rf, ...)
    if not rf or not rf:IsA("RemoteFunction") then return nil, "bukan RemoteFunction" end
    local res, selesai = nil, false
    task.spawn(function()
        local ok, v = pcall(function() return rf:InvokeServer(...) end)
        res = ok and v or ("ERR:" .. tostring(v)); selesai = true
    end)
    local t0 = os.clock()
    while not selesai and (os.clock() - t0) < Config.timeout_invoke do task.wait(0.05) end
    if not selesai then return nil, "timeout" end
    return res
end

local function probe_buy()
    local rem = resolve("ReplicatedStorage.Remotes")
    if not rem then probe_tulis("Remotes gak ada"); return end
    local dev = rem:FindFirstChild("BuyDevProduct")
    local single = rem:FindFirstChild("BuySingleProduct")
    if dev then
        local skema = { {0}, {1}, {"1"}, {1,1}, {0,1}, { {productId=1} }, {} }
        for i, args in ipairs(skema) do
            local r, err = invoke_aman(dev, table.unpack(args))
            probe_tulis(("[probe] BuyDevProduct #%d -> %s"):format(i, tostring(r or err)))
            if type(r) == "table" then
                for k, v in pairs(r) do probe_tulis("[probe]   " .. tostring(k) .. "=" .. tostring(v)) end
                probe_hasil.remote.BuyDevProduct = r; break
            end
            task.wait(Config.cooldown_probe)
        end
    end
    if single then
        local r, err = invoke_aman(single, "1", 1)
        probe_tulis("[probe] BuySingleProduct('1',1) -> " .. tostring(r or err))
        probe_hasil.remote.BuySingleProduct = r
    end
end

local function probe_dance()
    local rem = resolve("ReplicatedStorage.Remotes")
    if not rem then return end
    local gained = rem:FindFirstChild("DanceGained")
    local play   = rem:FindFirstChild("PlayDance")
    local sync   = rem:FindFirstChild("DanceSyncRequest")
    if gained then
        for _, arg in ipairs({ "Default", "Troll", "Dance1", "Emote" }) do
            pcall(function() gained:FireServer(arg) end)
            probe_tulis("[probe] DanceGained fire=" .. arg)
            task.wait(Config.cooldown_probe)
        end
    end
    if play then
        pcall(function() play:FireServer("Troll") end)
        probe_tulis("[probe] PlayDance fire='Troll'")
    end
    if sync then
        local r, err = invoke_aman(sync)
        probe_tulis("[probe] DanceSyncRequest -> " .. tostring(r or err))
    end
end

local function probe_hdadmin()
    local hd = resolve("ReplicatedStorage.HDAdminHDClient.Signals")
    if not hd then probe_tulis("HDAdmin gak ada"); return end
    local ranks = invoke_aman(hd:FindFirstChild("RetrieveServerRanks"))
    probe_tulis("[probe] RetrieveServerRanks -> " .. (type(ranks) == "table" and (#ranks .. " entri") or tostring(ranks)))
    if type(ranks) == "table" then
        for _, e in ipairs(ranks) do probe_tulis("[probe]   rank:", tostring(e)) end
        probe_hasil.hdadmin.ranks = ranks
    end
    local rc = hd:FindFirstChild("RequestCommand")
    if rc then
        local r, err = invoke_aman(rc, "help")
        probe_tulis("[probe] RequestCommand('help') -> " .. tostring(r or err))
        probe_hasil.hdadmin.help = r or err
    end
    local bc = hd:FindFirstChild("BecomeControlled")
    if bc then
        pcall(function() bc:FireServer() end)
        probe_tulis("[probe] BecomeControlled fire")
    end
    local ec = hd:FindFirstChild("ExecuteClientCommand")
    if ec then
        pcall(function() ec:FireServer("help") end)
        probe_tulis("[probe] ExecuteClientCommand('help')")
    end
end

local function jalankan_probe()
    probe_hasil = { catatan = {}, remote = {}, hdadmin = {} }
    getgenv().odil9_probe = probe_hasil
    probe_tulis("=== mulai probe ===")
    probe_tulis("map:", game.PlaceId)
    probe_buy()
    probe_dance()
    probe_hdadmin()
    probe_tulis("=== probe selesai ===")
    flush_log()
end

-- ===== Wire tombol =====
buat_tombol("Copy", 10, 70, copy_semua)
buat_tombol("Scan", 88, 70, function() task.spawn(pindai) end)
buat_tombol("Probe", 166, 70, function() task.spawn(jalankan_probe) end)
buat_tombol("Scan+Probe", 244, 110, function() task.spawn(function() pindai(); jalankan_probe() end) end)
buat_tombol("Clear", 362, 70, clear_log)

getgenv().odil9_menu_gui = gui
getgenv().odil9_scan_ulang = function() task.spawn(pindai) end
getgenv().odil9_jalankan_probe = function() task.spawn(jalankan_probe) end

-- auto scan pas load
task.spawn(pindai)

getgenv().odil9_menu_unload = function()
    gui:Destroy()
    getgenv().odil9_menu_gui = nil
    getgenv().odil9_log = nil
    getgenv().odil9_scan_ulang = nil
    getgenv().odil9_jalankan_probe = nil
    getgenv().odil9_menu_unload = nil
    getgenv().odil9_recon = nil
    getgenv().odil9_probe = nil
    print("[odil9] menu di-unload, absolute larp")
end

print("[odil9] menu kepasang — Scan, Probe, Copy. absolute larp, made by @odil9, join: discord.gg/xGDFJ29MmA")
