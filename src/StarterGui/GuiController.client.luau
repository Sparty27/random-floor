-- GuiController: оновлення GUI для гравця
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LOG = "[GuiController]"

local player = Players.LocalPlayer
local gui = player.PlayerGui:WaitForChild("GameGui")
local topBar = gui:WaitForChild("TopBar")
local infoText = topBar:WaitForChild("InfoText")
local winScreen = gui:WaitForChild("WinScreen")
local winText = winScreen:WaitForChild("WinText")

local gameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local updateGui = gameEvents:WaitForChild("UpdateGui")
local showWinner = gameEvents:WaitForChild("ShowWinner")

local function fadeScreen(bgTransparencyStart, bgTransparencyEnd, textTransparencyStart, textTransparencyEnd, duration)
	local steps = 10
	local stepTime = duration / steps
	for i = 1, steps do
		local t = i / steps
		winScreen.BackgroundTransparency = bgTransparencyStart + (bgTransparencyEnd - bgTransparencyStart) * t
		winText.TextTransparency = textTransparencyStart + (textTransparencyEnd - textTransparencyStart) * t
		task.wait(stepTime)
	end
end

updateGui.OnClientEvent:Connect(function(message)
	infoText.Text = message
end)

-- ── Reward Popup ─────────────────────────────────────────────────────────────

local showRewards = gameEvents:WaitForChild("ShowRewards")

local rewardGui = Instance.new("ScreenGui")
rewardGui.Name = "RewardGui"
rewardGui.ResetOnSpawn = false
rewardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
rewardGui.Parent = player.PlayerGui

local rewardFrame = Instance.new("Frame")
rewardFrame.Name = "RewardFrame"
rewardFrame.Size = UDim2.fromOffset(320, 110)
rewardFrame.AnchorPoint = Vector2.new(0.5, 1)
rewardFrame.Position = UDim2.fromScale(0.5, 0.88)
rewardFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
rewardFrame.BackgroundTransparency = 0.15
rewardFrame.BorderSizePixel = 0
rewardFrame.Visible = false
rewardFrame.Parent = rewardGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 14)
frameCorner.Parent = rewardFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0, 36)
titleLabel.Position = UDim2.fromOffset(0, 6)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Round Complete! 🎮"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.Parent = rewardFrame

local rewardLabel = Instance.new("TextLabel")
rewardLabel.Name = "RewardLabel"
rewardLabel.Size = UDim2.new(1, 0, 0, 32)
rewardLabel.Position = UDim2.fromOffset(0, 42)
rewardLabel.BackgroundTransparency = 1
rewardLabel.Text = "+10 XP  |  +5 💰"
rewardLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
rewardLabel.Font = Enum.Font.GothamMedium
rewardLabel.TextSize = 20
rewardLabel.Parent = rewardFrame

local levelLabel = Instance.new("TextLabel")
levelLabel.Name = "LevelLabel"
levelLabel.Size = UDim2.new(1, 0, 0, 28)
levelLabel.Position = UDim2.fromOffset(0, 76)
levelLabel.BackgroundTransparency = 1
levelLabel.Text = "★ LEVEL UP! ★"
levelLabel.TextColor3 = Color3.fromRGB(100, 220, 255)
levelLabel.Font = Enum.Font.GothamBold
levelLabel.TextSize = 16
levelLabel.Visible = false
levelLabel.Parent = rewardFrame

local POPUP_HIDDEN_POS = UDim2.fromScale(0.5, 1.1)
local POPUP_SHOWN_POS  = UDim2.fromScale(0.5, 0.88)
local TWEEN_IN  = TweenService:Create(rewardFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = POPUP_SHOWN_POS })
local TWEEN_OUT = TweenService:Create(rewardFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),  { Position = POPUP_HIDDEN_POS })

showRewards.OnClientEvent:Connect(function(result)
	print(LOG, "ShowRewards received | XP:", result.xp, "Coins:", result.coins, "LevelUp:", result.leveledUp)

	titleLabel.Text = (result.xp >= 35) and "You Won! 🏆" or "Round Complete! 🎮"
	rewardLabel.Text = "+" .. result.xp .. " XP  |  +" .. result.coins .. " 💰"

	if result.leveledUp then
		levelLabel.Text = "★ LEVEL UP → " .. result.newLevel .. "! ★"
		levelLabel.Visible = true
		rewardFrame.Size = UDim2.fromOffset(320, 110)
	else
		levelLabel.Visible = false
		rewardFrame.Size = UDim2.fromOffset(320, 82)
	end

	rewardFrame.Position = POPUP_HIDDEN_POS
	rewardFrame.Visible = true
	TWEEN_IN:Play()
	task.wait(4)
	TWEEN_OUT:Play()
	TWEEN_OUT.Completed:Wait()
	rewardFrame.Visible = false
end)

-- ─────────────────────────────────────────────────────────────────────────────

showWinner.OnClientEvent:Connect(function(winnerName)
	print(LOG, "showWinner received:", winnerName)
	if winnerName == "Нічия!" then
		winText.Text = "🤝 Draw! Everyone fell!"
		winText.TextColor3 = Color3.fromRGB(255, 255, 255)
	elseif winnerName == player.Name then
		print(LOG, "Local player won!")
		winText.Text = "🏆 You win!"
		winText.TextColor3 = Color3.fromRGB(255, 215, 0)
	else
		winText.Text = "😔 " .. winnerName .. " wins!"
		winText.TextColor3 = Color3.fromRGB(200, 200, 200)
	end

	winScreen.Visible = true
	fadeScreen(1, 0.3, 1, 0, 0.5)
	task.wait(4)
	fadeScreen(0.3, 1, 0, 1, 0.5)
	winScreen.Visible = false
end)
