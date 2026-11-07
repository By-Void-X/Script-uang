-- menu_compact.lua — Delta, versi pendek anti-kepotong
-- built by odil9 — discord.gg/xGDFJ29MmA

local ok, err = pcall(function()
    local gui = Instance.new("ScreenGui")
    gui.Name = "odil9_compact"
    gui.ResetOnSpawn = false
    gui.Parent = gethui() or game:GetService("CoreGui")
    
    local f = Instance.new("Frame", gui)
    f.Size = UDim2.new(0, 380, 0, 450)
    f.Position = UDim2.new(0, 20, 0, 60)
    f.BackgroundColor3 = Color3.fromRGB(18, 16, 22)
    f.BorderSizePixel = 2
    f.BorderColor3 = Color3.fromRGB(255, 60, 180)
    f.Active = true
    f.Draggable = true

    local title = Instance.new("TextLabel", f)
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Text = "odil9 compact — absolute larp"
    title.TextColor3 = Color3.fromRGB(255, 60, 180)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.Code
    title.TextSize = 14

    local log = Instance.new("TextBox", f)
    log.Size = UDim2.new(1, -20, 1, -80)
    log.Position = UDim2.new(0, 10, 0, 40)
    log.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    log.TextColor3 = Color3.fromRGB(200, 200, 200)
    log.Font = Enum.Font.Code
    log.TextSize = 11
    log.Multiline = true
    log.TextXAlignment = Enum.TextXAlignment.Left
    log.TextYAlignment = Enum.TextYAlignment.Top
    log.TextEditable = false
    log.Text = "[odil9] Menu muncul. Silakan pencet Scan atau Probe."

    local btnCopy = Instance.new("TextButton", f)
    btnCopy.Size = UDim2.new(0, 80, 0, 24)
    btnCopy.Position = UDim2.new(0, 10, 1, -30)
    btnCopy.Text = "Copy Log"
    btnCopy.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    btnCopy.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnCopy.Font = Enum.Font.Code

    local btnScan = Instance.new("TextButton", f)
    btnScan.Size = UDim2.new(0, 80, 0, 24)
    btnScan.Position = UDim2.new(0, 100, 1, -30)
    btnScan.Text = "Scan"
    btnScan.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    btnScan.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnScan.Font = Enum.Font.Code

    local btnProbe = Instance.new("TextButton", f)
    btnProbe.Size = UDim2.new(0, 80, 0, 24)
    btnProbe.Position = UDim2.new(0, 190, 1, -30)
    btnProbe.Text = "Probe"
    btnProbe.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    btnProbe.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnProbe.Font = Enum.Font.Code

    local function write(...)
        local p = {}
        for i = 1, select("#", ...) do p[i] = tostring(select(i, ...)) end
        log.Text = log.Text .. "\n" .. table.concat(p, " ")
    end

    btnCopy.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(log.Text)
            write("[odil9] Copied!")
        end
    end)

    btnScan.MouseButton1Click:Connect(function()
        log.Text = "[odil9] Scanning..."
        task.spawn(function()
            local hasil = { remote = {}, part = {} }
            local svcs = { game:GetService("ReplicatedStorage"), game:GetService("Workspace"), game:GetService("Players") }
            local total = 0
            for _, svc in pairs(svcs) do
                local function walk(inst, depth)
                    if depth > 6 then return end
                    total = total + 1
                    if inst:IsA("RemoteEvent") or inst:IsA("RemoteFunction") then
                        table.insert(hasil.remote, inst:GetFullName())
                    elseif inst:IsA("BasePart") and (inst.Transparency >= 0.9 or inst:FindFirstChildOfClass("ClickDetector")) then
                        table.insert(hasil.part, inst:GetFullName())
                    end
                    for _, c in ipairs(inst:GetChildren()) do walk(c, depth + 1) end
                end
                pcall(walk, svc, 0)
            end
            write("[odil9] total inst:", total)
            write("[odil9] remotes:", #hasil.remote)
            for _, r in ipairs(hasil.remote) do write("  " .. r) end
            write("[odil9] parts:", #hasil.part)
        end)
    end)

    btnProbe.MouseButton1Click:Connect(function()
        write("[odil9] Probing...")
        task.spawn(function()
            local rem = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
            if rem then
                local dev = rem:FindFirstChild("BuyDevProduct")
                if dev and dev:IsA("RemoteEvent") then
                    write("[probe] BuyDevProduct fire (Event, no return)")
                    pcall(function() dev:FireServer(1) end)
                end
                local single = rem:FindFirstChild("BuySingleProduct")
                if single then
                    pcall(function() single:FireServer(1, 1) end)
                    write("[probe] BuySingleProduct fired")
                end
                local gained = rem:FindFirstChild("DanceGained")
                if gained then
                    pcall(function() gained:FireServer("Troll") end)
                    write("[probe] DanceGained fired")
                end
            end
            local hd = game:GetService("ReplicatedStorage"):FindFirstChild("HDAdminHDClient")
            if hd then
                local sig = hd:FindFirstChild("Signals")
                if sig then
                    local rc = sig:FindFirstChild("RequestCommand")
                    if rc then
                        local ok, r = pcall(function() return rc:InvokeServer("help") end)
                        write("[probe] RequestCommand:", tostring(r))
                    end
                end
            end
            write("[odil9] Probe done.")
        end)
    end)
    
    print("[odil9] compact menu loaded")
end)

if not ok then
    warn("[odil9] GAGAL BIKIN GUI:", err)
    -- fallback tampilin error di layar
    local g = Instance.new("ScreenGui", gethui() or game:GetService("CoreGui"))
    local t = Instance.new("TextLabel", g)
    t.Size = UDim2.new(1, 0, 1, 0)
    t.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
    t.TextColor3 = Color3.fromRGB(255, 200, 200)
    t.Text = "ERROR:\n" .. tostring(err)
    t.TextWrapped = true
    t.Font = Enum.Font.Code
end
