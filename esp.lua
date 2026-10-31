-- LocalScript: đặt trong StarterPlayer > StarterPlayerScripts
-- ESP cho người chơi khác và NPC/quái trong game của bạn

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer

local espEnabled = true -- trạng thái bật/tắt

local CONFIG = {
	ToggleKey = Enum.KeyCode.RightShift,       -- phím bật/tắt (PC)
	ShowButton = true,                          -- nút bật/tắt trên màn hình (hợp với điện thoại)
	PlayerColor = Color3.fromRGB(0, 170, 255), -- màu viền người chơi
	NPCColor = Color3.fromRGB(255, 60, 60),    -- màu viền NPC/quái
	MaxDistance = 500,                          -- ẩn nhãn nếu xa hơn (studs)
	ShowTeammates = true,
}

local function isPlayerCharacter(model)
	return Players:GetPlayerFromCharacter(model) ~= nil
end

local function createESP(model, color, displayName)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	if not humanoid or not root then return end
	if model:FindFirstChild("ESP_Highlight") then return end

	-- Viền sáng
	local highlight = Instance.new("Highlight")
	highlight.Name = "ESP_Highlight"
	highlight.FillColor = color
	highlight.FillTransparency = 0.7
	highlight.OutlineColor = color
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Adornee = model
	highlight.Parent = model

	-- Nhãn tên / máu / khoảng cách
	local gui = Instance.new("BillboardGui")
	gui.Name = "ESP_Label"
	gui.Adornee = root
	gui.Size = UDim2.new(0, 160, 0, 40)
	gui.StudsOffset = Vector3.new(0, 3.5, 0)
	gui.AlwaysOnTop = true
	gui.Parent = model

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.3
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui

	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not model.Parent or not root.Parent then
			conn:Disconnect()
			return
		end
		local cam = workspace.CurrentCamera
		local dist = (cam.CFrame.Position - root.Position).Magnitude
		local visible = espEnabled and dist <= CONFIG.MaxDistance
		gui.Enabled = visible
		highlight.Enabled = visible
		if visible then
			label.Text = string.format(
				"%s\n❤ %d/%d  |  %dm",
				displayName,
				math.floor(humanoid.Health),
				math.floor(humanoid.MaxHealth),
				math.floor(dist)
			)
		end
	end)

	model.AncestryChanged:Connect(function(_, parent)
		if not parent and conn then conn:Disconnect() end
	end)
end

-- Người chơi khác
local function onCharacter(player, character)
	if player == localPlayer then return end
	if not CONFIG.ShowTeammates and player.Team == localPlayer.Team then return end
	character:WaitForChild("HumanoidRootPart", 10)
	createESP(character, CONFIG.PlayerColor, player.DisplayName)
end

local function onPlayer(player)
	if player == localPlayer then return end
	if player.Character then onCharacter(player, player.Character) end
	player.CharacterAdded:Connect(function(char) onCharacter(player, char) end)
end

for _, p in ipairs(Players:GetPlayers()) do onPlayer(p) end
Players.PlayerAdded:Connect(onPlayer)

-- NPC / quái: mọi Model có Humanoid mà không phải nhân vật người chơi
local function tryNPC(instance)
	if not instance:IsA("Humanoid") then return end
	local model = instance.Parent
	if model and model:IsA("Model") and not isPlayerCharacter(model) then
		task.defer(createESP, model, CONFIG.NPCColor, model.Name)
	end
end

for _, d in ipairs(workspace:GetDescendants()) do tryNPC(d) end
workspace.DescendantAdded:Connect(tryNPC)

-- Bật/tắt ESP
local button

local function updateButton()
	if button then
		button.Text = espEnabled and "ESP: BẬT" or "ESP: TẮT"
		button.BackgroundColor3 = espEnabled and Color3.fromRGB(40, 160, 80) or Color3.fromRGB(160, 50, 50)
	end
end

local function toggleESP()
	espEnabled = not espEnabled
	updateButton()
end

-- Phím tắt
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == CONFIG.ToggleKey then
		toggleESP()
	end
end)

-- Nút trên màn hình
if CONFIG.ShowButton then
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ESP_Toggle"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

	button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 110, 0, 36)
	button.Position = UDim2.new(1, -120, 0, 10)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.Parent = screenGui
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

	button.MouseButton1Click:Connect(toggleESP)
	updateButton()
end
