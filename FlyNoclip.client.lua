--[[
	FLY + NOCLIP (bật là bay và xuyên tường luôn)
	Cách dùng: đặt LocalScript này vào StarterPlayer > StarterPlayerScripts
	- Phím F hoặc nút "FLY: OFF/ON" trên màn hình (dùng được cả điện thoại) để bật/tắt
	- W/A/S/D (hoặc joystick) bay theo hướng camera
	- Space: bay lên | LeftShift / LeftCtrl: bay xuống
	- Phím + / - : tăng / giảm tốc độ
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local FLY_SPEED = 60
local SPEED_STEP = 10
local MIN_SPEED, MAX_SPEED = 10, 300

local flying = false
local up, down = false, false
local heartbeatConn, steppedConn

local controls
task.spawn(function()
	local ok, module = pcall(function()
		return require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
	end)
	if ok then controls = module end
end)

local function getCharacter()
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hrp and hum then return char, hrp, hum end
end

-- Noclip: tắt va chạm toàn bộ bộ phận nhân vật
local function setNoclip(char)
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") and part.CanCollide then
			part.CanCollide = false
		end
	end
end

local function stopFly()
	flying = false
	if heartbeatConn then heartbeatConn:Disconnect() heartbeatConn = nil end
	if steppedConn then steppedConn:Disconnect() steppedConn = nil end

	local char, hrp, hum = getCharacter()
	if hum then
		hum.PlatformStand = false
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
	if hrp then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.CanCollide = true
	end
	-- Bật lại va chạm cho các phần thân chính
	if char then
		for _, name in ipairs({ "Head", "UpperTorso", "LowerTorso", "Torso" }) do
			local p = char:FindFirstChild(name)
			if p and p:IsA("BasePart") then p.CanCollide = true end
		end
	end
end

local function startFly()
	local char, hrp, hum = getCharacter()
	if not char then return end

	flying = true
	hum.PlatformStand = true

	-- Noclip chạy mỗi frame vật lý để các bộ phận không bị bật lại va chạm
	steppedConn = RunService.Stepped:Connect(function()
		local c = player.Character
		if c then setNoclip(c) end
	end)

	heartbeatConn = RunService.Heartbeat:Connect(function()
		local c, root = getCharacter()
		if not c then return end

		local move = Vector3.zero
		if controls then
			local mv = controls:GetMoveVector() -- x: phải, z: lùi
			move = camera.CFrame.RightVector * mv.X + camera.CFrame.LookVector * (-mv.Z)
		end
		if up then move += Vector3.yAxis end
		if down then move -= Vector3.yAxis end

		if move.Magnitude > 0 then
			move = move.Unit * FLY_SPEED
		end

		root.AssemblyLinearVelocity = move -- không có trọng lực khi bay
		root.AssemblyAngularVelocity = Vector3.zero
		-- Xoay nhân vật theo hướng camera
		root.CFrame = CFrame.lookAt(root.Position, root.Position + Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z))
	end)
end

-- Nút bật/tắt trên màn hình
local gui = Instance.new("ScreenGui")
gui.Name = "FlyGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Size = UDim2.fromOffset(130, 44)
button.Position = UDim2.new(1, -145, 0.5, -22)
button.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
button.TextColor3 = Color3.new(1, 1, 1)
button.Font = Enum.Font.GothamBold
button.TextSize = 16
button.Text = "FLY: OFF"
button.Parent = gui
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

local function toggle()
	if flying then
		stopFly()
	else
		startFly()
	end
	button.Text = flying and "FLY: ON" or "FLY: OFF"
	button.BackgroundColor3 = flying and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(200, 60, 60)
end

button.Activated:Connect(toggle)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	local k = input.KeyCode
	if k == Enum.KeyCode.F then
		toggle()
	elseif k == Enum.KeyCode.Space then
		up = true
	elseif k == Enum.KeyCode.LeftShift or k == Enum.KeyCode.LeftControl then
		down = true
	elseif k == Enum.KeyCode.Equals or k == Enum.KeyCode.KeypadPlus then
		FLY_SPEED = math.min(MAX_SPEED, FLY_SPEED + SPEED_STEP)
	elseif k == Enum.KeyCode.Minus or k == Enum.KeyCode.KeypadMinus then
		FLY_SPEED = math.max(MIN_SPEED, FLY_SPEED - SPEED_STEP)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	local k = input.KeyCode
	if k == Enum.KeyCode.Space then
		up = false
	elseif k == Enum.KeyCode.LeftShift or k == Enum.KeyCode.LeftControl then
		down = false
	end
end)

-- Chết/respawn thì tắt bay
player.CharacterAdded:Connect(function()
	flying = false
	if heartbeatConn then heartbeatConn:Disconnect() heartbeatConn = nil end
	if steppedConn then steppedConn:Disconnect() steppedConn = nil end
	button.Text = "FLY: OFF"
	button.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
end)
