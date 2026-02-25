-- AchievementController: popup-нотифікація при отриманні досягнення
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local LOG = "[Achievement]"

local gameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local achievementAwarded = gameEvents:WaitForChild("AchievementAwarded")

-- ── GUI ───────────────────────────────────────────────────────────────────

local achieveGui = Instance.new("ScreenGui")
achieveGui.Name = "AchievementGui"
achieveGui.ResetOnSpawn = false
achieveGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
achieveGui.Parent = player.PlayerGui

local popup = Instance.new("Frame")
popup.Name = "AchievementPopup"
popup.Size = UDim2.fromOffset(260, 70)
popup.AnchorPoint = Vector2.new(1, 0)
popup.Position = UDim2.new(1.4, 0, 0, 100)  -- за правим краєм (прихований)
popup.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
popup.BackgroundTransparency = 0.1
popup.BorderSizePixel = 0
popup.Visible = false
popup.Parent = achieveGui

local popupCorner = Instance.new("UICorner")
popupCorner.CornerRadius = UDim.new(0, 12)
popupCorner.Parent = popup

-- Верхній рядок: "Achievement Unlocked!"
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -16, 0, 28)
titleLabel.Position = UDim2.fromOffset(12, 6)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Achievement Unlocked!"
titleLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 13
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = popup

-- Нижній рядок: іконка + назва
local nameLabel = Instance.new("TextLabel")
nameLabel.Name = "AchieveName"
nameLabel.Size = UDim2.new(1, -16, 0, 26)
nameLabel.Position = UDim2.fromOffset(12, 36)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "🏆 First Win!"
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLabel.Font = Enum.Font.GothamMedium
nameLabel.TextSize = 15
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Parent = popup

-- ── Анімація ──────────────────────────────────────────────────────────────

local POPUP_HIDDEN = UDim2.new(1.4, 0, 0, 100)
local POPUP_SHOWN  = UDim2.new(1, -10, 0, 100)

local TWEEN_IN  = TweenService:Create(popup, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = POPUP_SHOWN })
local TWEEN_OUT = TweenService:Create(popup, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),  { Position = POPUP_HIDDEN })

-- ── Черга ─────────────────────────────────────────────────────────────────

local queue = {}
local isShowing = false

local function showNext()
	if isShowing or #queue == 0 then return end
	isShowing = true

	local ach = table.remove(queue, 1)
	nameLabel.Text = ach.icon .. "  " .. ach.name

	popup.Position = POPUP_HIDDEN
	popup.Visible = true
	TWEEN_IN:Play()

	task.wait(3.2)

	TWEEN_OUT:Play()
	task.wait(0.35)
	popup.Visible = false

	isShowing = false
	showNext()
end

achievementAwarded.OnClientEvent:Connect(function(ach)
	print(LOG, "Achievement unlocked:", ach.name)
	table.insert(queue, ach)
	task.spawn(showNext)
end)
