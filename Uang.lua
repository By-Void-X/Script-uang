-- menu_debug.lua — Delta, menu paling simpel dulu buat mastiin muncul
-- built by odil9 — discord.gg/xGDFJ29MmA

print("[odil9/debug] script mulai")
if not getgenv then warn("[odil9/debug] no getgenv — bukan executor"); return end
if not game:IsLoaded() then game.Loaded:Wait() end

local ok_gui, err_gui = pcall(function()
    local gui = Instance.new("ScreenGui")
    gui.Name = "odil9_debug"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999

    -- coba parent berurutan, catat mana yang berhasil
    local parent_berhasil = nil
    local kandidat = {}
    if gethui then table.insert(kandidat, { nama = "gethui()", fn = gethui }) end
    if get_hidden_gui then table.insert(kandidat, { nama = "get_hidden_gui()", fn = get_hidden_gui }) end
    table.insert(kandidat, { nama = "CoreGui", fn = function() return game:GetService("CoreGui") end })
    table.insert(kandidat, { nama = "LocalPlayer.PlayerGui", fn = function() return game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui", 5) end })

    for _, k in ipairs(kandidat) do
        local ok, hasil = pcall(k.fn)
        if ok and hasil then
            local ok2, err2 = pcall(function() gui.Parent = hasil end)
            if ok2 then
                parent_berhasil = k.nama
                break
            else
                print("[odil9/debug] parent " .. k.nama .. " gagal:", err2)
            end
        else
            print("[odil9/debug] kandidat " .. k.nama .. " gak ada")
        end
    end

    if not parent_berhasil then
        warn("[odil9/debug] SEMUA parent gagal, gui gak ke-mount")
        return nil
    end
    print("[odil9/debug] gui ke-mount di:", parent_berhasil)

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 300)
    frame.Position = UDim2.new(0.5, -200, 0.5, -150)
    frame.BackgroundColor3 = Color3.fromRGB(18, 16, 22)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = gui

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 60, 180)
    stroke.Thickness = 2
    stroke.Parent = frame

    local judul = Instance.new("TextLabel")
    judul.Size = UDim2.new(1, -20, 0, 30)
    judul.Position = UDim2.new(0, 10, 0, 8)
    judul.BackgroundTransparency = 1
    judul.Text = "odil9 debug — kalau lo liat ini, parent jalan"
    judul.TextColor3 = Color3.fromRGB(255, 60, 180)
    judul.Font = Enum.Font.Code
    judul.TextSize = 14
    judul.Parent = frame

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -20, 1, -50)
    info.Position = UDim2.new(0, 10, 0, 42)
    info.BackgroundTransparency = 1
    info.Text = "parent: " .. parent_berhasil ..
                  "\nexecutor: " .. tostring(identifyexecutor and identifyexecutor() or "?") ..
                  "\nhui: " .. tostring(gethui ~= nil) ..
                  "\ncoregui: coba akses"
    info.TextColor3 = Color3.fromRGB(230, 225, 235)
    info.Font = Enum.Font.Code
    info.TextSize = 12
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.TextYAlignment = Enum.TextYAlignment.Top
    info.Parent = frame

    local tutup = Instance.new("TextButton")
    tutup.Size = UDim2.new(0, 80, 0, 24)
    tutup.Position = UDim2.new(1, -90, 1, -32)
    tutup.BackgroundColor3 = Color3.fromRGB(40, 34, 48)
    tutup.BorderSizePixel = 0
    tutup.Text = "tutup"
    tutup.TextColor3 = Color3.fromRGB(230, 225, 235)
    tutup.Font = Enum.Font.Code
    tutup.TextSize = 12
    tutup.Parent = frame
    tutup.MouseButton1Click:Connect(function() gui:Destroy() end)

    return gui
end)

if ok_gui and err_gui then
    getgenv().odil9_debug_gui = err_gui
    print("[odil9/debug] OK, gui di getgenv().odil9_debug_gui")
elseif ok_gui then
    print("[odil9/debug] OK tapi gui nil — parent gagal")
else
    warn("[odil9/debug] ERROR:", err_gui)
end
