-- language: Lua, target: Roblox (Delta Executor), mobile-optimized UI
-- *modul ini membuat ScreenGui toggleable, memanipulasi HumanoidState, BodyVelocity, BillboardGui, dan Camera CFrame Lerp*

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- // UI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaModMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 60, 0, 60)
ToggleBtn.Position = UDim2.new(1, -70, 0.5, -30)
ToggleBtn.Text = "MENU"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.Parent = ScreenGui

local MenuFrame = Instance.new("Frame")
MenuFrame.Size = UDim2.new(0, 280, 0, 350)
MenuFrame.Position = UDim2.new(1, -300, 0.5, -175)
MenuFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MenuFrame.BorderSizePixel = 0
MenuFrame.Visible = false
MenuFrame.Parent = ScreenGui

local function createLabel(text, yPos)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 30)
    lbl.Position = UDim2.new(0, 10, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 16
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = MenuFrame
    return lbl
end

local function createToggle(text, yPos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.Text = text .. " [OFF]"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = MenuFrame
    
    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = text .. (state and " [ON]" or " [OFF]")
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 120, 215) or Color3.fromRGB(50, 50, 50)
        callback(state)
    end)
    return btn
end

local function createActionBtn(text, yPos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 130, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = MenuFrame
    btn.MouseButton1Click:Connect(callback)
    return btn
end

ToggleBtn.MouseButton1Click:Connect(function()
    MenuFrame.Visible = not MenuFrame.Visible
end)

createLabel("=== MOD MENU ===", 10)

-- // FEATURE 1: SPEED HACK //
local speedState = false
createToggle("Speed Hack", 50, function(state)
    speedState = state
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = state and 60 or 16
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    if speedState then char.Humanoid.WalkSpeed = 60 end
end)

-- // FEATURE 2: MULTI JUMP //
local multiJumpState = false
createToggle("Multi Jump", 95, function(state)
    multiJumpState = state
end)

UserInputService.JumpRequest:Connect(function()
    if multiJumpState then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- // FEATURE 3: FLY //
local flyState = false
local flyVelocity = 0
createToggle("Fly", 140, function(state)
    flyState = state
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    if state then
        local bv = Instance.new("BodyVelocity")
        bv.Name = "FlyVelocity"
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.new(0, 50, 0)
        bv.Parent = hrp
        flyVelocity = 50
    else
        local bv = hrp:FindFirstChild("FlyVelocity")
        if bv then bv:Destroy() end
        flyVelocity = 0
    end
end)

createActionBtn("Fly UP", 185, function()
    if flyState then
        flyVelocity = flyVelocity + 20
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and hrp:FindFirstChild("FlyVelocity") then
            hrp.FlyVelocity.Velocity = Vector3.new(0, flyVelocity, 0)
        end
    end
end)

createActionBtn("Fly DOWN", 185, function()
    if flyState then
        flyVelocity = math.max(-100, flyVelocity - 20)
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and hrp:FindFirstChild("FlyVelocity") then
            hrp.FlyVelocity.Velocity = Vector3.new(0, flyVelocity, 0)
        end
    end
end)
-- Adjust positioning for UP/DOWN buttons to sit side by side
MenuFrame:FindFirstChild("Fly UP").Position = UDim2.new(0, 10, 0, 185)
MenuFrame:FindFirstChild("Fly DOWN").Position = UDim2.new(0, 150, 0, 185)
MenuFrame:FindFirstChild("Fly UP").Size = UDim2.new(0, 120, 0, 35)
MenuFrame:FindFirstChild("Fly DOWN").Size = UDim2.new(0, 120, 0, 35)

-- // FEATURE 4: ESP PLAYER //
local espState = false
local espCache = {}

createToggle("Player ESP", 240, function(state)
    espState = state
    if not state then
        for _, esp in pairs(espCache) do
            if esp.Parent then esp:Destroy() end
        end
        table.clear(espCache)
    end
end)

local function updateESP()
    if not espState then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if not espCache[player] then
                local billboard = Instance.new("BillboardGui")
                billboard.Name = "ESP_Billboard"
                billboard.Size = UDim2.new(0, 200, 0, 50)
                billboard.StudsOffset = Vector3.new(0, 3, 0)
                billboard.AlwaysOnTop = true
                
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.TextColor3 = Color3.fromRGB(255, 50, 50)
                label.Font = Enum.Font.GothamBold
                label.TextSize = 16
                label.TextStrokeTransparency = 0.5
                label.Parent = billboard
                
                billboard.Parent = player.Character.HumanoidRootPart
                espCache[player] = {billboard = billboard, label = label}
            end
            
            local hrp = player.Character.HumanoidRootPart
            local distance = math.floor((hrp.Position - (LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart.Position or Vector3.new())).Magnitude)
            espCache[player].label.Text = player.Name .. " [" .. distance .. "m]"
        else
            if espCache[player] then
                if espCache[player].billboard.Parent then
                    espCache[player].billboard:Destroy()
                end
                espCache[player] = nil
            end
        end
    end
end

RunService.RenderStepped:Connect(updateESP)

-- // FEATURE 5: SMOOTH AIMBOT //
local aimbotState = false
local aimbotSmooth = 0.15 -- 0.1 to 1.0 (lower is smoother/slower)

createToggle("Smooth Aimbot", 285, function(state)
    aimbotState = state
end)

local function getNearestPlayer()
    local nearest = nil
    local minDist = math.huge
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    
    local hrpPos = char.HumanoidRootPart.Position
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local targetHrp = player.Character.HumanoidRootPart
            local dist = (targetHrp.Position - hrpPos).Magnitude
            if dist < minDist and dist < 200 then -- 200 stud range
                minDist = dist
                nearest = targetHrp
            end
        end
    end
    return nearest
end

RunService.RenderStepped:Connect(function()
    if aimbotState then
        local target = getNearestPlayer()
        if target then
            local targetPos = target.Position
            local currentCFrame = Camera.CFrame
            local lookAtCFrame = CFrame.new(currentCFrame.Position, targetPos)
            Camera.CFrame = currentCFrame:Lerp(lookAtCFrame, aimbotSmooth)
        end
    end
end)
