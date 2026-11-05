-- LocalScript → StarterPlayer > StarterPlayerScripts
-- Dev tools versi mobile untuk place sendiri. Otomatis mati di luar Studio.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer
local cam = workspace.CurrentCamera

local CFG = {FlySpeed = 60, WalkSpeed = 50, AimSmooth = 0.15, AimFOV = 220}
local S = {fly = false, esp = true, aim = false, up = false, down = false, tp = false}
local tpIndex = 0
local ON, OFF = Color3.fromRGB(40, 140, 80), Color3.fromRGB(35, 35, 40)

local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset = "DevToolsMobile", false, true
gui.Parent = lp:WaitForChild("PlayerGui")

-- Tombol sentuh (kanan layar), toggle atau tahan
local function button(text, row, mode, key)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(76, 44)
	b.Position = UDim2.new(1, -86, 0, 10 + (row - 1) * 52)
	b.Text, b.TextColor3, b.TextScaled = text, Color3.new(1, 1, 1), true
	b.BackgroundColor3 = (mode == "toggle" and S[key]) and ON or OFF
	b.Parent = gui
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)

	if mode == "toggle" then
		b.Activated:Connect(function()
			S[key] = not S[key]
			b.BackgroundColor3 = S[key] and ON or OFF
		end)
	elseif mode == "hold" then
		b.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
				S[key] = true
				b.BackgroundColor3 = ON
			end
		end)
		b.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
				S[key] = false
				b.BackgroundColor3 = OFF
			end
		end)
	else -- "tap"
		b.Activated:Connect(function() S[key] = true end)
	end
	return b
end

button("Fly", 1, "toggle", "fly")
button("Naik", 2, "hold", "up")
button("Turun", 3, "hold", "down")
button("ESP", 4, "toggle", "esp")
button("Aim", 5, "toggle", "aim")
button("TP", 6, "tap", "tp")

-- Target: pemain lain + model uji di workspace.TestTargets
local function getTargets()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= lp and p.Character then table.insert(list, p.Character) end
	end
	local folder = workspace:FindFirstChild("TestTargets")
	if folder then
		for _, m in ipairs(folder:GetChildren()) do
			if m:IsA("Model") then table.insert(list, m) end
		end
	end
	return list
end

local function rootOf(m) return m:FindFirstChild("HumanoidRootPart") end

-- ESP (highlight + garis dari bawah layar)
local overlays = {}
local function getOverlay(m)
	if not overlays[m] then
		local f = Instance.new("Frame")
		f.AnchorPoint, f.BorderSizePixel = Vector2.new(0.5, 0.5), 0
		f.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
		f.Parent = gui
		local h = Instance.new("Highlight")
		h.FillTransparency, h.Parent = 0.7, m
		overlays[m] = {frame = f, hl = h}
	end
	return overlays[m]
end

local function updateESP()
	local active = {}
	if S.esp then
		for _, m in ipairs(getTargets()) do
			local r = rootOf(m)
			if r then
				active[m] = true
				local o = getOverlay(m)
				local pos, onScreen = cam:WorldToViewportPoint(r.Position)
				o.frame.Visible, o.hl.Enabled = onScreen, true
				if onScreen then
					local a = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
					local b = Vector2.new(pos.X, pos.Y)
					local d = b - a
					o.frame.Size = UDim2.fromOffset(d.Magnitude, 2)
					o.frame.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
					o.frame.Rotation = math.deg(math.atan2(d.Y, d.X))
				end
			end
		end
	end
	for m, o in pairs(overlays) do
		if not active[m] then
			o.frame:Destroy()
			if o.hl then o.hl:Destroy() end
			overlays[m] = nil
		end
	end
end

-- Aim smooth: target terdekat ke tengah layar
local function nearestToCenter()
	local center = cam.ViewportSize / 2
	local best, bestD
	for _, m in ipairs(getTargets()) do
		local head = m:FindFirstChild("Head")
		if head then
			local p, on = cam:WorldToViewportPoint(head.Position)
			if on then
				local d = (Vector2.new(p.X, p.Y) - center).Magnitude
				if d < CFG.AimFOV and (not bestD or d < bestD) then best, bestD = head, d end
			end
		end
	end
	return best
end

-- Loop utama
RunService.RenderStepped:Connect(function()
	local char = lp.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and rootOf(char)
	if not (hum and root) then return end

	hum.WalkSpeed = CFG.WalkSpeed

	if S.fly then
		hum.PlatformStand = true
		local y = (S.up and 1 or 0) - (S.down and 1 or 0)
		root.AssemblyLinearVelocity = (hum.MoveDirection + Vector3.new(0, y, 0)) * CFG.FlySpeed
	elseif hum.PlatformStand then
		hum.PlatformStand = false
	end

	if S.tp then
		S.tp = false
		local t = getTargets()
		if #t > 0 then
			tpIndex = tpIndex % #t + 1
			local r = rootOf(t[tpIndex])
			if r then root.CFrame = r.CFrame * CFrame.new(0, 0, 4) end
		end
	end

	if S.aim then
		local head = nearestToCenter()
		if head then
			cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, head.Position), CFG.AimSmooth)
		end
	end

	updateESP()
end)

-- Multi jump: tombol lompat bawaan mobile memicu JumpRequest
UIS.JumpRequest:Connect(function()
	local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)
