-- AutoCurrency_BruteForce.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

local CONFIG = { AMOUNT = 999999 }

local gui = Instance.new("ScreenGui")
gui.Name = "AutoCurrencyBrute"
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
panel.Size = UDim2.new(0, 260, 0, 260)
panel.Position = UDim2.new(0, 10, 0, 50)
panel.BackgroundColor3 = Color3.fromRGB(20,20,20)
panel.Visible = false
panel.Parent = gui

local amountBox = Instance.new("TextBox")
amountBox.Size = UDim2.new(1,-20,0,30)
amountBox.Position = UDim2.new(0,10,0,10)
amountBox.Text = tostring(CONFIG.AMOUNT)
amountBox.Parent = panel

-- TOMBOL BRUTE FORCE (Ubah semua angka)
local bruteBtn = Instance.new("TextButton")
bruteBtn.Size = UDim2.new(1,-20,0,40)
bruteBtn.Position = UDim2.new(0,10,0,50)
bruteBtn.Text = "1. Brute Force All Numbers"
bruteBtn.Parent = panel

-- TOMBOL FIRE REMOTES (Pancing server)
local remoteBtn = Instance.new("TextButton")
remoteBtn.Size = UDim2.new(1,-20,0,40)
remoteBtn.Position = UDim2.new(0,10,0,100)
remoteBtn.Text = "2. Fire All Remotes (Test)"
remoteBtn.Parent = panel

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1,-20,0,100)
status.Position = UDim2.new(0,10,0,150)
status.Text = "Ready"
status.TextWrapped = true
status.TextColor3 = Color3.fromRGB(180,255,180)
status.BackgroundTransparency = 1
status.Parent = panel

toggle.MouseButton1Click:Connect(function()
    panel.Visible = not panel.Visible
end)

-- FUNGSI 1: Bantai semua ValueBase di Client
bruteBtn.MouseButton1Click:Connect(function()
    local amount = tonumber(amountBox.Text) or 999999
    local count = 0
    
    -- Scan Player, leaderstats, dan ReplicatedStorage
    local roots = {lp, ReplicatedStorage}
    for _, root in ipairs(roots) do
        for _, v in ipairs(root:GetDescendants()) do
            if v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("DoubleValue") then
                -- Hanya ubah jika nilainya angka (bukan health/walk speed)
                pcall(function()
                    if type(v.Value) == "number" and v.Value < amount then
                        v.Value = amount
                        count = count + 1
                    end
                end)
            end
        end
    end

    -- Scan Atribut
    for k, v in pairs(lp:GetAttributes()) do
        if type(v) == "number" then
            lp:SetAttribute(k, amount)
            count = count + 1
        end
    end

    status.Text = "Berhasil ubah " .. count .. " variabel Client!"
end)

-- FUNGSI 2: Fire semua RemoteEvent (Nembak server)
remoteBtn.MouseButton1Click:Connect(function()
    local amount = tonumber(amountBox.Text) or 999999
    local fired = 0
    
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            -- Kita coba tembak dengan angka besar, siapa tau server nelen
            pcall(function()
                v:FireServer(amount)
                fired = fired + 1
            end)
        end
    end
    
    status.Text = "Nembak " .. fired .. " RemoteEvent ke Server. Cek koin!"
end)
