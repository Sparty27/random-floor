-- ProfileController: кнопка та панель статистики гравця
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local LOG = "[Profile]"

local gameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local getPlayerStats = gameEvents:WaitForChild("GetPlayerStats")

-- ── Створення GUI ─────────────────────────────────────────────────────────────

local profileGui = Instance.new("ScreenGui")
profileGui.Name = "ProfileGui"
profileGui.ResetOnSpawn = false
profileGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
profileGui.Parent = player.PlayerGui

-- Кнопка 📊 (знизу зліва)
local statsBtn = Instance.new("TextButton")
statsBtn.Name = "StatsBtn"
statsBtn.Size = UDim2.fromOffset(50, 50)
statsBtn.AnchorPoint = Vector2.new(0, 1)
statsBtn.Position = UDim2.new(0, 10, 1, -10)
statsBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
statsBtn.BackgroundTransparency = 0.2
statsBtn.BorderSizePixel = 0
statsBtn.Text = "📊"
statsBtn.TextSize = 24
statsBtn.Font = Enum.Font.GothamBold
statsBtn.Parent = profileGui

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 10)
btnCorner.Parent = statsBtn

-- Панель статистики (центр екрану)
local panel = Instance.new("Frame")
panel.Name = "ProfilePanel"
panel.Size = UDim2.fromOffset(340, 356)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
panel.BackgroundTransparency = 0
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = profileGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 16)
panelCorner.Parent = panel

-- Заголовок
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
header.BackgroundTransparency = 0
header.BorderSizePixel = 0
header.Parent = panel

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 16)
headerCorner.Parent = header

-- Закриваємо округлення знизу заголовку
local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.fromScale(1, 0.5)
headerFix.Position = UDim2.fromScale(0, 0.5)
headerFix.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
headerFix.BorderSizePixel = 0
headerFix.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -50, 1, 0)
titleLabel.Position = UDim2.fromOffset(16, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "📊  Your Stats"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(36, 36)
closeBtn.AnchorPoint = Vector2.new(1, 0.5)
closeBtn.Position = UDim2.new(1, -8, 0.5, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Parent = header

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 8)
closeBtnCorner.Parent = closeBtn

-- ── XP секція ─────────────────────────────────────────────────────────────────

local xpSection = Instance.new("Frame")
xpSection.Size = UDim2.new(1, -24, 0, 60)
xpSection.Position = UDim2.fromOffset(12, 58)
xpSection.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
xpSection.BorderSizePixel = 0
xpSection.Parent = panel

local xpCorner = Instance.new("UICorner")
xpCorner.CornerRadius = UDim.new(0, 10)
xpCorner.Parent = xpSection

local levelLabel = Instance.new("TextLabel")
levelLabel.Name = "LevelLabel"
levelLabel.Size = UDim2.new(1, -16, 0, 22)
levelLabel.Position = UDim2.fromOffset(12, 8)
levelLabel.BackgroundTransparency = 1
levelLabel.Text = "🏅 Level 1"
levelLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
levelLabel.Font = Enum.Font.GothamBold
levelLabel.TextSize = 15
levelLabel.TextXAlignment = Enum.TextXAlignment.Left
levelLabel.Parent = xpSection

-- XP bar контейнер
local xpBarBg = Instance.new("Frame")
xpBarBg.Size = UDim2.new(1, -80, 0, 10)
xpBarBg.Position = UDim2.fromOffset(12, 36)
xpBarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
xpBarBg.BorderSizePixel = 0
xpBarBg.Parent = xpSection

local xpBarCorner = Instance.new("UICorner")
xpBarCorner.CornerRadius = UDim.new(0.5, 0)
xpBarCorner.Parent = xpBarBg

local xpBarFill = Instance.new("Frame")
xpBarFill.Name = "XpBarFill"
xpBarFill.Size = UDim2.fromScale(0, 1)  -- ширина встановлюється динамічно
xpBarFill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
xpBarFill.BorderSizePixel = 0
xpBarFill.Parent = xpBarBg

local xpBarFillCorner = Instance.new("UICorner")
xpBarFillCorner.CornerRadius = UDim.new(0.5, 0)
xpBarFillCorner.Parent = xpBarFill

local xpNumLabel = Instance.new("TextLabel")
xpNumLabel.Name = "XpNumLabel"
xpNumLabel.Size = UDim2.fromOffset(64, 14)
xpNumLabel.AnchorPoint = Vector2.new(1, 0.5)
xpNumLabel.Position = UDim2.new(1, -4, 0, 41)
xpNumLabel.BackgroundTransparency = 1
xpNumLabel.Text = "0 / 100"
xpNumLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
xpNumLabel.Font = Enum.Font.Gotham
xpNumLabel.TextSize = 11
xpNumLabel.TextXAlignment = Enum.TextXAlignment.Right
xpNumLabel.Parent = xpSection

-- ── Рядки статистики ──────────────────────────────────────────────────────────

local STATS_START_Y = 128
local ROW_HEIGHT = 32
local ROW_GAP = 4

local function makeStatRow(icon, labelText, yPos)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -24, 0, ROW_HEIGHT)
	row.Position = UDim2.fromOffset(12, yPos)
	row.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
	row.BorderSizePixel = 0
	row.Parent = panel

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 8)
	rowCorner.Parent = row

	local iconLbl = Instance.new("TextLabel")
	iconLbl.Size = UDim2.fromOffset(30, ROW_HEIGHT)
	iconLbl.BackgroundTransparency = 1
	iconLbl.Text = icon
	iconLbl.TextSize = 16
	iconLbl.Font = Enum.Font.GothamMedium
	iconLbl.Parent = row

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.fromScale(0.55, 1)
	nameLbl.Position = UDim2.fromOffset(32, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = labelText
	nameLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
	nameLbl.Font = Enum.Font.Gotham
	nameLbl.TextSize = 14
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.Parent = row

	local valLbl = Instance.new("TextLabel")
	valLbl.Name = "Value"
	valLbl.Size = UDim2.new(0.35, -8, 1, 0)
	valLbl.AnchorPoint = Vector2.new(1, 0)
	valLbl.Position = UDim2.new(1, -8, 0, 0)
	valLbl.BackgroundTransparency = 1
	valLbl.Text = "—"
	valLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	valLbl.Font = Enum.Font.GothamBold
	valLbl.TextSize = 14
	valLbl.TextXAlignment = Enum.TextXAlignment.Right
	valLbl.Parent = row

	return valLbl
end

local y = STATS_START_Y
local coinsVal   = makeStatRow("💰", "Coins",        y)
y += ROW_HEIGHT + ROW_GAP
local gamesVal   = makeStatRow("🎮", "Games played", y)
y += ROW_HEIGHT + ROW_GAP
local winsVal    = makeStatRow("🏆", "Wins",         y)
y += ROW_HEIGHT + ROW_GAP
local winRateVal = makeStatRow("📈", "Win rate",     y)
y += ROW_HEIGHT + ROW_GAP
local streakVal  = makeStatRow("🔥", "Streak",       y)
y += ROW_HEIGHT + ROW_GAP
local bestVal    = makeStatRow("⭐", "Best streak",  y)

-- ── Логіка відкриття/закриття ─────────────────────────────────────────────────

local isOpen = false

local PANEL_SHOWN_POS  = UDim2.fromScale(0.5, 0.5)
local PANEL_HIDDEN_POS = UDim2.fromScale(0.5, 1.5)
local TWEEN_OPEN  = TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = PANEL_SHOWN_POS })
local TWEEN_CLOSE = TweenService:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),  { Position = PANEL_HIDDEN_POS })

local function fillStats(stats)
	if not stats then
		print(LOG, "No stats received from server")
		return
	end

	levelLabel.Text = "🏅 Level " .. stats.level
	xpBarFill.Size = UDim2.fromScale(math.clamp(stats.xpInLevel / stats.xpForNextLevel, 0, 1), 1)
	xpNumLabel.Text = stats.xpInLevel .. " / " .. stats.xpForNextLevel

	coinsVal.Text   = tostring(stats.coins)
	gamesVal.Text   = tostring(stats.gamesPlayed)
	winsVal.Text    = tostring(stats.wins)
	winRateVal.Text = stats.winRate .. "%"
	streakVal.Text  = tostring(stats.currentStreak)
	bestVal.Text    = tostring(stats.longestStreak)
end

local function openPanel()
	isOpen = true
	panel.Position = PANEL_HIDDEN_POS
	panel.Visible = true

	-- Завантажуємо свіжі дані з сервера
	local stats = getPlayerStats:InvokeServer()
	fillStats(stats)

	TWEEN_OPEN:Play()
	print(LOG, "Panel opened")
end

local function closePanel()
	isOpen = false
	TWEEN_CLOSE:Play()
	task.wait(0.25)
	if not isOpen then
		panel.Visible = false
	end
	print(LOG, "Panel closed")
end

statsBtn.MouseButton1Click:Connect(function()
	if isOpen then
		closePanel()
	else
		openPanel()
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	if isOpen then
		closePanel()
	end
end)
