-- AutoCurrency_Scanner_V3.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

local selectedObjects = {}
local allFoundObjects = {}

local gui = Instance.new("ScreenGui")
gui.Name = "AutoCurrencyScannerV3"
gui.ResetOnSpawn = false
gui.Parent = lp:WaitForChild("PlayerGui")

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0, 60, 0, 30)
toggle.Position = UDim2.new(0, 10, 0, 10)
toggle.Text = "MENU"
toggle.BackgroundColor3 = Color3.fromRGB(30,30,30)
toggle.TextColor3 = Color3.fromRGB(255,255,255)
toggle.Parent = gui

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 320, 0, 450)
panel.Position = UDim2.new(0, 10, 0, 50)
panel.BackgroundColor3 = Color3.fromRGB(20,20,20)
panel.Visible = false
panel.Parent = gui

-- UI Elemen
local amountBox = Instance.new("TextBox")
amountBox.Size = UDim2.new(0.45,0,0,30)
amountBox.Position = UDim2.new(0,10,0,10)
amountBox.Text = "999999"
amountBox.PlaceholderText = "Ubah Jadi..."
amountBox.Parent = panel

local filterBox = Instance.new("TextBox")
filterBox.Size = UDim2.new(0.45,0,0,30)
filterBox.Position = UDim2.new(0.55,0,0,10)
filterBox.Text = ""
filterBox.PlaceholderText = "Saldo Saat Ini..."
filterBox.Parent = panel

local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(1,-20,0,30)
scanBtn.Position = UDim2.new(0,10,0,50)
scanBtn.Text = "1. Scan & Filter"
scanBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
scanBtn.TextColor3 = Color3.fromRGB(255,255,255)
scanBtn.Parent = panel

local applyBtn = Instance.new("TextButton")
applyBtn.Size = UDim2.new(1,-20,0,30)
applyBtn.Position = UDim2.new(0,10,0,90)
applyBtn.Text = "2. Apply ke yang Dipilih"
applyBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
applyBtn.TextColor3 = Color3.fromRGB(255,255,255)
applyBtn.Parent = panel

local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.new(1,-20,0,280)
listFrame.Position = UDim2.new(0,10,0,130)
listFrame.BackgroundColor3 = Color3.fromRGB(35,35,35)
listFrame.CanvasSize = UDim2.new(0,0,0,0)
listFrame.Parent = panel

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Parent = listFrame
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder

toggle.MouseButton1Click:Connect(function() panel.Visible = not panel.Visible end)

-- Fungsi Reset Daftar
local function clearList()
    for _, child in ipairs(listFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    table.clear(selectedObjects)
    table.clear(allFoundObjects)
end

-- Fungsi Scan
scanBtn.MouseButton1Click:Connect(function()
    clearList()
    local filterVal = tonumber(filterBox.Text)
    local count = 0
    
    local function processObj(name, getVal, setFunc, typeStr)
        local val = getVal()
        if type(val) == "number" then
            -- Jika ada filter, dan nilainya tidak sama, lewati
            if filterVal and val ~= filterVal then return end
            
            count = count + 1
            local display = "["..typeStr.."] "..name.." = "..tostring(val)
            
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -10, 0, 30)
            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Text = display
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Parent = listFrame
            
            local isSelected = false
            btn.MouseButton1Click:Connect(function()
                isSelected = not isSelected
                if isSelected then
                    btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Merah (Dipilih)
                    table.insert(selectedObjects, setFunc)
                else
                    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    for i, v in ipairs(selectedObjects) do
                        if v == setFunc then table.remove(selectedObjects, i) break end
                    end
                end
            end)
        end
    end

    -- 1. Scan Atribut (Ini yang bikin versi "All" berhasil)
    for k, v in pairs(lp:GetAttributes()) do
        processObj(k, function() return v end, function(newVal) lp:SetAttribute(k, newVal) end, "Attr")
    end

    -- 2. Scan Player
    for _, v in ipairs(lp:GetDescendants()) do
        if v:IsA("ValueBase") and type(v.Value) == "number" then
            processObj(v.Name, function() return v.Value end, function(newVal) v.Value = newVal end, "Obj")
        end
    end

    -- 3. Scan ReplicatedStorage
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("ValueBase") and type(v.Value) == "number" then
            processObj(v.Name, function() return v.Value end, function(newVal) v.Value = newVal end, "RS")
        end
    end

    listFrame.CanvasSize = UDim2.new(0, 0, 0, count * 35)
    scanBtn.Text = "Ditemukan: "..count.." angka"
end)

-- Fungsi Apply
applyBtn.MouseButton1Click:Connect(function()
    local amount = tonumber(amountBox.Text) or 999999
    local changed = 0
    
    for _, setFunc in ipairs(selectedObjects) do
        pcall(function()
            setFunc(amount)
            changed = changed + 1
        end)
    end
    
    applyBtn.Text = "Berhasil ubah " .. changed .. " target!"
    task.wait(2)
    applyBtn.Text = "2. Apply ke yang Dipilih"
end)
