-- SpectatorController: UI та камера для гравців-спостерігачів
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local LOG = "[Spectator]"

local SPECTATOR_CF = CFrame.lookAt(Vector3.new(0, 80, 90), Vector3.new(0, 15, 0))

local watchingArena = false

-- ── UI ───────────────────────────────────────────────────────────────────────

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SpectatorGui"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player.PlayerGui

-- Нижній бар (статус)
local bar = Instance.new("Frame")
bar.Name = "Bar"
bar.Size = UDim2.new(1, 0, 0, 50)
bar.Position = UDim2.new(0, 0, 1, -50)
bar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
bar.BackgroundTransparency = 0.35
bar.BorderSizePixel = 0
bar.Parent = screenGui

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 1, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "💀 You were eliminated"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextSize = 18
statusLabel.Parent = bar

-- Кнопка тогл (права сторона, над баром)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleBtn"
toggleBtn.Size = UDim2.new(0, 200, 0, 40)
toggleBtn.Position = UDim2.new(1, -210, 1, -100)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleBtn.BackgroundTransparency = 0.2
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "📺  Watch Arena"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamMedium
toggleBtn.TextSize = 16
toggleBtn.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = toggleBtn

-- ── Логіка ───────────────────────────────────────────────────────────────────

local function enterArenaView()
	print(LOG, "Entering arena spectate view")
	watchingArena = true
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = SPECTATOR_CF
	statusLabel.Text = "👁️ You were eliminated – Spectating"
	toggleBtn.Text = "🚶  Walk Around"
end

local function exitArenaView()
	print(LOG, "Exiting arena view, returning to custom camera")
	watchingArena = false
	camera.CameraType = Enum.CameraType.Custom
	statusLabel.Text = "💀 You were eliminated"
	toggleBtn.Text = "📺  Watch Arena"
end

toggleBtn.MouseButton1Click:Connect(function()
	if watchingArena then
		exitArenaView()
	else
		enterArenaView()
	end
end)

local function onIsSpectatingChanged()
	local isSpectating = player:GetAttribute("IsSpectating")
	print(LOG, "IsSpectating changed to:", isSpectating)

	if isSpectating then
		screenGui.Enabled = true
		-- камера не чіпаємо — гравець сам вирішує
	else
		-- кінець раунду: скидаємо все
		if watchingArena then
			exitArenaView()
		end
		screenGui.Enabled = false
	end
end

player:GetAttributeChangedSignal("IsSpectating"):Connect(onIsSpectatingChanged)

if player:GetAttribute("IsSpectating") then
	onIsSpectatingChanged()
end
