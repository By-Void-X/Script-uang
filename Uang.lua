-- AutoCurrency_Scanner.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

local CONFIG = { AMOUNT = 999999 }
local selectedObjects = {} -- Menyimpan objek yang dicentang

local gui = Instance.new("ScreenGui")
gui.Name = "AutoCurrencyScanner"
gui.ResetOnSpawn = false
gui.Parent = lp:WaitForChild("PlayerGui")

-- Toggle Button
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0, 60, 0, 30)
toggle.Position = UDim2.new(0, 10, 0, 10)
toggle.Text = "MENU"
toggle.BackgroundColor3 = Color3.fromRGB(30,30,30)
toggle.TextColor3 = Color3.fromRGB(255,255,255)
toggle.Parent = gui

-- Panel Utama
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 300, 0, 400)
panel.Position = UDim2.new(0, 10, 0, 50)
panel.BackgroundColor3 = Color3.fromRGB(20,20,20)
panel.Visible = false
panel.Parent = gui

-- Input Amount
local amountBox = Instance.new("TextBox")
amountBox.Size = UDim2.new(1,-20,0,30)
amountBox.Position = UDim2.new(0,10,0,10)
amountBox.Text = tostring(CONFIG.AMOUNT)
amountBox.Parent = panel

-- Tombol Scan
local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(1,-20,0,30)
scanBtn.Position = UDim2.new(0,10,0,50)
scanBtn.Text = "1. Scan (Riset Angka)"
scanBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
scanBtn.TextColor3 = Color3.fromRGB(255,255,255)
scanBtn.Parent = panel

-- Tombol Apply
local applyBtn = Instance.new("TextButton")
applyBtn.Size = UDim2.new(1,-20,0,30)
applyBtn.Position = UDim2.new(0,10,0,90)
applyBtn.Text = "2. Apply ke yang Dipilih"
applyBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
applyBtn.TextColor3 = Color3.fromRGB(255,255,255)
applyBtn.Parent = panel

-- Scrolling Frame untuk List
local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.new(1,-20,0,250)
listFrame.Position = UDim2.new(0,10,0,130)
listFrame.BackgroundColor3 = Color3.fromRGB(35,35,35)
listFrame.CanvasSize = UDim2.new(0,0,0,0)
listFrame.Parent = panel

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Parent = listFrame
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Toggle logic
toggle.MouseButton1Click:Connect(function()
    panel.Visible = not panel.Visible
end)

-- Fungsi Scan
scanBtn.MouseButton1Click:Connect(function()
    -- Bersihkan list lama
    for _, child in ipairs(listFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    table.clear(selectedObjects)
    
    local count = 0
    local function addToList(obj, displayName, currentValue)
        count = count + 1
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 30)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Text = displayName .. " [" .. tostring(currentValue) .. "]"
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = listFrame
        
        -- Simpan referensi objek di dalam tombol
        btn:SetAttribute("TargetPath", obj:GetFullName())
        
        btn.MouseButton1Click:Connect(function()
            if btn.BackgroundColor3 == Color3.fromRGB(60, 60, 60) then
                -- Pilih
                btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                table.insert(selectedObjects, obj)
            else
                -- Batal pilih
                btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                for i, v in ipairs(selectedObjects) do
                    if v == obj then table.remove(selectedObjects, i) break end
                end
            end
        end)
    end

    -- Scan Player (leaderstats, dll)
    for _, v in ipairs(lp:GetDescendants()) do
        if (v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("DoubleValue")) and type(v.Value) == "number" then
            addToList(v, v.Name, v.Value)
        end
    end

    -- Scan ReplicatedStorage (kadang game simpan config di sini)
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if (v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("DoubleValue")) and type(v.Value) == "number" then
            addToList(v, v.Name, v.Value)
        end
    end

    listFrame.CanvasSize = UDim2.new(0, 0, 0, count * 35)
    scanBtn.Text = "Scan Selesai ("..count.." angka ditemukan)"
end)

-- Fungsi Apply
applyBtn.MouseButton1Click:Connect(function()
    local amount = tonumber(amountBox.Text) or 999999
    local changed = 0
    
    for _, obj in ipairs(selectedObjects) do
        pcall(function()
            if obj:IsA("IntValue") or obj:IsA("NumberValue") or obj:IsA("DoubleValue") then
                obj.Value = amount
            elseif type(obj) == "table" and obj.SetAttribute then
                -- Kalau tipe atribut
                obj:SetAttribute(obj.Name, amount)
            end
            changed = changed + 1
        end)
    end
    
    applyBtn.Text = "Berhasil ubah " .. changed .. " angka!"
    task.wait(2)
    applyBtn.Text = "2. Apply ke yang Dipilih"
end)
