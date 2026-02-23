-- LeaderboardUpdater: оновлення фізичної таблиці в лобі
local LeaderboardManager = require(game.ServerScriptService:WaitForChild("LeaderboardManager"))

local board = workspace:WaitForChild("LeaderboardScreen")
	:WaitForChild("SurfaceGui")
	:WaitForChild("Board")
	:WaitForChild("List")

-- Кольори для топ 3
local rankColors = {
	[1] = Color3.fromRGB(255, 215, 0),   -- золото
	[2] = Color3.fromRGB(192, 192, 192), -- срібло
	[3] = Color3.fromRGB(205, 127, 50),  -- бронза
}

local function updateBoard()
	-- Очищаємо старі записи
	for _, child in ipairs(board:GetChildren()) do
		child:Destroy()
	end

	local topPlayers = LeaderboardManager.getTopPlayers()

	if #topPlayers == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, 0, 0.1, 0)
		empty.BackgroundTransparency = 1
		empty.Text = "No data yet"
		empty.TextColor3 = Color3.fromRGB(200, 200, 200)
		empty.TextScaled = true
		empty.Font = Enum.Font.Gotham
		empty.Parent = board
		return
	end

	-- Додаємо UIListLayout для автоматичного розташування
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0.005, 0)
	layout.Parent = board

	for _, data in ipairs(topPlayers) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0.045, 0)
		row.BackgroundTransparency = data.rank % 2 == 0 and 0.8 or 0.6
		row.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		row.BorderSizePixel = 0
		row.LayoutOrder = data.rank
		row.Parent = board

		-- Місце
		local rankLabel = Instance.new("TextLabel")
		rankLabel.Size = UDim2.new(0.15, 0, 1, 0)
		rankLabel.Position = UDim2.new(0, 0, 0, 0)
		rankLabel.BackgroundTransparency = 1
		rankLabel.Text = "#" .. data.rank
		rankLabel.TextScaled = true
		rankLabel.Font = Enum.Font.GothamBold
		rankLabel.TextColor3 = rankColors[data.rank] or Color3.fromRGB(255, 255, 255)
		rankLabel.Parent = row

		-- Ім'я
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
		nameLabel.Position = UDim2.new(0.15, 0, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = data.name
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.Parent = row

		-- Перемоги
		local winsLabel = Instance.new("TextLabel")
		winsLabel.Size = UDim2.new(0.25, 0, 1, 0)
		winsLabel.Position = UDim2.new(0.75, 0, 0, 0)
		winsLabel.BackgroundTransparency = 1
		winsLabel.Text = "🏆 " .. data.wins
		winsLabel.TextScaled = true
		winsLabel.Font = Enum.Font.GothamBold
		winsLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		winsLabel.Parent = row
	end
end

-- Оновлюємо одразу і потім кожні 30 секунд
updateBoard()

-- Слухаємо сигнал оновлення після перемоги
local refreshEvent = game.ServerScriptService:WaitForChild("RefreshLeaderboard")
refreshEvent.Event:Connect(function()
	updateBoard()
end)

while true do
	task.wait(30)
	updateBoard()
end