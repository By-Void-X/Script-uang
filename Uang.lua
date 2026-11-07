-- recon_menu.lua — Roblox Delta, mod menu + log copy
-- built by odil9 — discord.gg/xGDFJ29MmA
-- susunan: config, gui shell, log pane, tombol copy, recon engine, kait

local Config = {
    judul = "odil9 recon",
    ukuran = UDim2.new(0, 420, 0, 520),
    posisi = UDim2.new(0, 20, 0, 60),
    warna_bg = Color3.fromRGB(18, 16, 22),
    warna_aksen = Color3.fromRGB(255, 60, 180),
    warna_teks = Color3.fromRGB(230, 225, 235),
    scan_services = { "ReplicatedStorage", "ReplicatedFirst", "Workspace", "Players", "StarterGui", "StarterPack" },
    max_kedalaman = 8,
    max_hasil = 2000,
}

if not getgenv then warn("[odil9] bukan executor") return end
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

-- bersihin kalau udah pernah jalan
if getgenv().odil9_menu_gui then getgenv().odil9_menu_gui:Destroy() end

-- ===== GUI shell =====
local gui = Instance.new("ScreenGui")
gui.Name = "odil9_recon_menu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = Config.ukuran
frame.Position = Config.posisi
frame.BackgroundColor3 = Config.warna_bg
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local stroke = Instance.new("UIStroke")
stroke.Color = Config.warna_aksen
stroke.Thickness = 1.5
stroke.Parent = frame

local judul = Instance.new("TextLabel")
judul.Size = UDim2.new(1, -20, 0, 28)
judul.Position = UDim2.new(0, 10, 0, 6)
judul.BackgroundTransparency = 1
judul.Text = Config.judul .. " — absolute larp"
judul.TextColor3 = Config.warna_aksen
judul.Font = Enum.Font.Code
judul.TextSize = 14
judul.TextXAlignment = Enum.TextXAlignment.Left
judul.Parent = frame

-- tombol baris atas
local function tombol(nama, x, w, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 0, 26)
    b.Position = UDim2.new(0, x, 0, 40)
    b.BackgroundColor3 = Color3.fromRGB(40, 34, 48)
    b.BorderSizePixel = 0
    b.Text = nama
    b.TextColor3 = Config.warna_teks
    b.Font = Enum.Font.Code
    b.TextSize = 13
    b.Parent = frame
    local s = Instance.new("UIStroke")
    s.Color = Config.warna_aksen
    s.Thickness = 1
    s.Transparency = 0.6
    s.Parent = b
    b.MouseButton1Click:Connect(cb)
    return b
end

-- ===== Log pane =====
local log_box = Instance.new("TextBox")
log_box.Size = UDim2.new(1, -20, 1, -120)
log_box.Position = UDim2.new(0, 10, 0, 74)
log_box.BackgroundColor3 = Color3.fromRGB(12, 11, 15)
log_box.BorderSizePixel = 0
log_box.Text = ""
log_box.TextColor3 = Config.warna_teks
log_box.Font = Enum.Font.Code
log_box.TextSize = 12
log_box.TextXAlignment = Enum.TextXAlignment.Left
log_box.TextYAlignment = Enum.TextYAlignment.Top
log_box.MultiLine = true
log_box.ClearTextOnFocus = false
log_box.TextEditable = false -- read-only, tapi masih bisa select
log_box.Parent = frame

local log_stroke = Instance.new("UIStroke")
log_stroke.Color = Config.warna_aksen
log_stroke.Thickness = 1
log_stroke.Transparency = 0.7
log_stroke.Parent = log_box

-- buffer log: di-append ke tabel, di-flush ke TextBox biar gak lag tiap baris
local log_buffer = {}
local log_dirty = false

local function flush_log()
    if not log_dirty then return end
    log_box.Text = table.concat(log_buffer, "\n")
    log_dirty = false
end

local function tulis(...)
    local parts = {}
    for i = 1, select("#", ...) do
        parts[i] = tostring(select(i, ...))
    end
    local line = table.concat(parts, " ")
    table.insert(log_buffer, line)
    if #log_buffer > 5000 then table.remove(log_buffer, 1) end -- batas: jangan bikin TextBox raksasa
    log_dirty = true
end
getgenv().odil9_log = tulis

-- ===== Tombol copy =====
local function copy_semua()
    local teks = table.concat(log_buffer, "\n")
    local ok = false
    if setclipboard then
        local p = pcall(setclipboard, teks)
        ok = p
    end
    if not ok then
        -- fallback: fokus ke TextBox, user Ctrl+A Ctrl+C manual
        log_box:CaptureFocus()
        log_box.CursorPosition = #log_box.Text + 1
        log_box.SelectionStart = 1
        tulis("[odil9] clipboard gak support, Ctrl+A lalu Ctrl+C manual")
    else
        tulis("[odil9] " .. #log_buffer .. " baris ke-copy ke clipboard, uwu")
    end
    flush_log()
end

local function export_json()
    local data = getgenv().odil9_recon
    if not data then tulis("[odil9] belum ada hasil scan"); flush_log(); return end
    local ok, js = pcall(function()
        return game:GetService("HttpService"):JSONEncode(data)
    end)
    if not ok then tulis("[odil9] JSONEncode gagal:", js); flush_log(); return end
    table.insert(log_buffer, "=== JSON ===")
    table.insert(log_buffer, js)
    log_dirty = true
    copy_semua()
end

tombol("Copy Semua", 10, 110, copy_semua)
tombol("Scan Ulang", 128, 100, function() getgenv().odil9_scan_ulang() end)
tombol("Export JSON", 236, 110, export_json)
tombol("Clear Log", 354, 60, function() log_buffer = {}; log_dirty = true; flush_log() end)

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
    tulis("[odil9] === mulai scan ===")
    tulis("[odil9] waktu:", os.date("%H:%M:%S"))
    tulis("[odil9] map:", game.PlaceId, "| game:", game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "?")

    -- remote
    for nama, svc in pairs(Services) do
        pcall(function()
            walk(svc, 0, function(inst)
                if inst:IsA("RemoteEvent") or inst:IsA("RemoteFunction") or inst:IsA("UnreliableRemoteEvent") then
                    table.insert(hasil.remote, {
                        path = inst:GetFullName(),
                        kelas = inst.ClassName,
                        curiga = string.find(string.lower(inst.Name), "admin") or
                                  string.find(string.lower(inst.Name), "give") or
                                  string.find(string.lower(inst.Name), "buy") or
                                  string.find(string.lower(inst.Name), "cash") or false,
                    })
                end
            end)
        end)
    end
    tulis("[odil9] remote ketemu:", #hasil.remote)
    for _, r in ipairs(hasil.remote) do
        tulis(("[odil9] %s  %s%s"):format(r.kelas, r.path, r.curiga and "  <-- CURIGA" or ""))
    end

    -- part
    pcall(function()
        walk(Services.Workspace, 0, function(inst)
            if inst:IsA("BasePart") then
                local sifat = {}
                if inst.Anchored then table.insert(sifat, "Anchored") end
                if inst.CanCollide == false then table.insert(sifat, "NoCollide") end
                if inst.Transparency >= 0.9 then table.insert(sifat, "Invisible") end
                if inst:FindFirstChildOfClass("ClickDetector") then table.insert(sifat, "ClickDetector") end
                if inst:FindFirstChildOfClass("ProximityPrompt") then table.insert(sifat, "ProximityPrompt") end
                if #sifat > 0 then
                    table.insert(hasil.part, { path = inst:GetFullName(), sifat = sifat, pos = tostring(inst.Position) })
                end
            end
        end)
    end)
    tulis("[odil9] part menarik:", #hasil.part)

    -- tool
    pcall(function()
        walk(Services.StarterPack, 0, function(inst)
            if inst:IsA("Tool") then
                table.insert(hasil.tool, { path = inst:GetFullName(), nama = inst.Name })
            end
        end)
        walk(LocalPlayer, 0, function(inst)
            if inst:IsA("Tool") then
                table.insert(hasil.tool, { path = inst:GetFullName(), nama = inst.Name, ditangan = true })
            end
        end)
    end)
    tulis("[odil9] tool:", #hasil.tool)

    -- backdoor signal
    local pola = { "loadstring", "getfenv", "setfenv", "HttpGet", "HttpService" }
    pcall(function()
        walk(LocalPlayer, 0, function(inst)
            if inst:IsA("LuaSourceContainer") then
                local ok, src = pcall(function() return inst.Source end)
                if ok and type(src) == "string" and #src < 500000 then
                    for _, p in ipairs(pola) do
                        if string.find(src, p, 1, true) then
                            table.insert(hasil.backdoor, { path = inst:GetFullName(), pola = p })
                            break
                        end
                    end
                end
            end
        end)
    end)
    tulis("[odil9] backdoor sinyal:", #hasil.backdoor)

    -- hook remote
    local old
    old = hookmetamethod(game, "__index", function(self, key)
        if key == "FireServer" or key == "InvokeServer" then
            local full = self:GetFullName()
            tulis(("[odil9] %s -> %s"):format(key, full))
            flush_log()
        end
        return old(self, key)
    end)

    tulis("[odil9] total instance di-walk:", total_inst)
    tulis("[odil9] === scan selesai ===")
    tulis("[odil9] akses data: getgenv().odil9_recon")
    tulis("[odil9] tombol 'Copy Semua' buat salin semua log")
    getgenv().odil9_recon = hasil
    flush_log()
end

getgenv().odil9_scan_ulang = function()
    hasil = { remote = {}, part = {}, tool = {}, backdoor = {}, waktu = os.time() }
    log_buffer = {}
    log_dirty = true
    pindai()
end

getgenv().odil9_menu_gui = gui
task.spawn(pindai)

-- teardown
getgenv().odil9_menu_unload = function()
    gui:Destroy()
    getgenv().odil9_menu_gui = nil
    getgenv().odil9_log = nil
    getgenv().odil9_scan_ulang = nil
    getgenv().odil9_menu_unload = nil
    print("[odil9] menu di-unload, absolute larp")
end

print("[odil9] menu kepasang — absolute larp, made by @odil9, join: discord.gg/xGDFJ29MmA")
