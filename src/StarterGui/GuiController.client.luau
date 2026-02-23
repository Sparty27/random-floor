-- GuiController: оновлення GUI для гравця
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

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

showWinner.OnClientEvent:Connect(function(winnerName)
	if winnerName == "Нічия!" then
		winText.Text = "🤝 Draw! Everyone fell!"
		winText.TextColor3 = Color3.fromRGB(255, 255, 255)
	elseif winnerName == player.Name then
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
