-- LocalScript (StarterPlayerScripts) atau dijalankan via executor
-- AutoCurrencyModMenu.lua

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer

-- ===== CONFIG =====
local CONFIG = {
    AMOUNT = 999999,
    NAMES = {"Money","Cash","Coins","Coin","Currency","Uang","Gold","Gems","Points","Tokens"},
}
-- ==================

-- GUI root
local gui = Instance.new("ScreenGui")
gui.Name = "AutoCurrencyModMenu"
gui.ResetOnSpawn = false
gui.Parent = lp:WaitForChild("PlayerGui")

-- Toggle button
local toggle = Instance.new("TextButton")
toggle.Name = "Toggle"
toggle.Size = UDim2.new(0, 60, 0, 30)
toggle.Position = UDim2.new(0, 10, 0, 10)
toggle.Text = "MENU"
toggle.BackgroundColor3 = Color3.fromRGB(30,30,30)
toggle.TextColor3 = Color3.fromRGB(255,255,255)
toggle.Parent = gui

-- Panel
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 260, 0, 300)
panel.Position = UDim2.new(0, 10, 0, 50)
panel.BackgroundColor3 = Color3.fromRGB(20,20,20)
panel.Visible = false
panel.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,30)
title.Text = "Auto Currency Menu"
title.BackgroundColor3 = Color3.fromRGB(40,40,40)
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Parent = panel

-- Amount input
local amountBox = Instance.new("TextBox")
amountBox.Size = UDim2.new(1,-20,0,30)
amountBox.Position = UDim2.new(0,10,0,40)
amountBox.Text = tostring(CONFIG.AMOUNT)
amountBox.PlaceholderText = "Amount"
amountBox.Parent = panel

-- Names input
local namesBox = Instance.new("TextBox")
namesBox.Size = UDim2.new(1,-20,0,30)
namesBox.Position = UDim2.new(0,10,0,80)
namesBox.Text = table.concat(CONFIG.NAMES, ",")
namesBox.PlaceholderText = "Names (comma)"
namesBox.Parent = panel

-- Apply button
local applyBtn = Instance.new("TextButton")
applyBtn.Size = UDim2.new(1,-20,0,30)
applyBtn.Position = UDim2.new(0,10,0,120)
applyBtn.Text = "Apply"
applyBtn.Parent = panel

-- Scan button
local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(1,-20,0,30)
scanBtn.Position = UDim2.new(0,10,0,160)
scanBtn.Text = "Scan (Dry Run)"
scanBtn.Parent = panel

-- Status label
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1,-20,0,90)
status.Position = UDim2.new(0,10,0,200)
status.Text = "Ready"
status.TextWrapped = true
status.TextColor3 = Color3.fromRGB(180,255,180)
status.BackgroundTransparency = 1
status.Parent = panel

-- Toggle logic
toggle.MouseButton1Click:Connect(function()
    panel.Visible = not panel.Visible
end)

-- Helper: match names
local function nameMatches(n, list)
    n = string.lower(n)
    for _, k in ipairs(list) do
        if n == string.lower(k) or n:find(string.lower(k), 1, true) then
            return true
        end
    end
    return false
end

-- Helper: scan + apply
local function run(dryRun)
    local amount = tonumber(amountBox.Text) or 999999
    local names = {}
    for s in string.gmatch(namesBox.Text, "([^,]+)") do
        table.insert(names, (s:gsub("^%s+",""):gsub("%s+$","")))
    end

    local hits = {}
    local roots = {workspace, game:GetService("ReplicatedStorage"), lp}
    for _, root in ipairs(roots) do
        for _, d in ipairs(root:GetDescendants()) do
            if (d:IsA("IntValue") or d:IsA("NumberValue")) and nameMatches(d.Name, names) then
                table.insert(hits, d)
            end
        end
    end

    -- atribut player
    for k, v in pairs(lp:GetAttributes()) do
        if type(v) == "number" and nameMatches(k, names) then
            if not dryRun then lp:SetAttribute(k, amount) end
            table.insert(hits, {attr = k})
        end
    end

    -- leaderstats
    local stats = lp:FindFirstChild("leaderstats")
    if stats then
        for _, v in ipairs(stats:GetChildren()) do
            if (v:IsA("IntValue") or v:IsA("NumberValue")) and nameMatches(v.Name, names) then
                if not dryRun then v.Value = amount end
                table.insert(hits, v)
            end
        end
    end

    -- apply ke objek
    for _, h in ipairs(hits) do
        if h.Value ~= nil and not dryRun then
            h.Value = amount
        end
    end

    status.Text = (dryRun and "Scan: " or "Applied: ") .. tostring(#hits) .. " target(s)"
end

scanBtn.MouseButton1Click:Connect(function() run(true) end)
applyBtn.MouseButton1Click:Connect(function() run(false) end)
