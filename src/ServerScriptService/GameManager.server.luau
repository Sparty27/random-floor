-- GameManager: головна логіка раундів
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TileManager = require(game.ServerScriptService:WaitForChild("TileManager"))
local PlayerManager = require(game.ServerScriptService:WaitForChild("PlayerManager"))
local LeaderboardManager = require(game.ServerScriptService:WaitForChild("LeaderboardManager"))

local gameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local updateGui = gameEvents:WaitForChild("UpdateGui")
local showWinner = gameEvents:WaitForChild("ShowWinner")
local playerEliminated = game.ServerScriptService:WaitForChild("PlayerEliminated")
local refreshLeaderboard = game.ServerScriptService:WaitForChild("RefreshLeaderboard")

-- Налаштування
local LOBBY_WAIT = 10
local REMOVE_INTERVAL = 3
local REMOVE_COUNT = 10

-- Стани гри
local GameState = {
	LOBBY = "lobby",
	PLAYING = "playing",
	ENDING = "ending",
}
local currentState = GameState.LOBBY

local function broadcastGui(message)
	updateGui:FireAllClients(message)
end

local function announceWinner(activePlayers)
	if #activePlayers == 1 then
		local name = activePlayers[1].Name
		showWinner:FireAllClients(name)
		broadcastGui("🏆 " .. name .. " wins!")
		LeaderboardManager.addWin(activePlayers[1])
		task.wait(1) -- чекаємо поки DataStore збереже
		refreshLeaderboard:Fire()
	elseif #activePlayers == 0 then
		showWinner:FireAllClients("Нічия!")
		broadcastGui("🤝 Draw! Everyone fell!")
	end
end

local function spawnAllPlayers()
	PlayerManager.resetActivePlayers()

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(PlayerManager.spawnOnArena, player)
		task.spawn(PlayerManager.watchPlayer, player)
	end

	local totalPlayers = #Players:GetPlayers()
	repeat
		task.wait(0.5)
	until #PlayerManager.getActivePlayers() >= totalPlayers
end

-- Головний ігровий цикл
local function gameLoop()
	while true do
		-- ЛОБІ
		currentState = GameState.LOBBY
		for i = LOBBY_WAIT, 1, -1 do
			broadcastGui("⏳ Game starts in: " .. i .. " sec")
			task.wait(1)
		end

		-- ГЕНЕРАЦІЯ АРЕНИ
		broadcastGui("🏗️ Generating arena...")
		TileManager.generateTiles()
		task.wait(1)

		-- СПАВН ГРАВЦІВ
		currentState = GameState.PLAYING
		broadcastGui("🎮 Game started! Stay on the tiles!")
		spawnAllPlayers()
		task.wait(3)
		PlayerManager.setGameStarted(true)

		-- ЦИКЛ ЗНИКНЕННЯ ПЛИТОК
		local roundActive = true
		local counterActive = true

		task.spawn(function()
			while counterActive do
				task.wait(0.5)
				local active = PlayerManager.getActivePlayers()
				broadcastGui("👥 Players: " .. #active .. " | 🟫 Tiles: " .. TileManager.getTileCount())
			end
		end)

		local eliminationConnection
		eliminationConnection = playerEliminated.Event:Connect(function()
			if not roundActive then return end
			local active = PlayerManager.getActivePlayers()
			if #active <= 1 then
				announceWinner(active)
				currentState = GameState.ENDING
				roundActive = false
			end
		end)

		while roundActive do
			local canContinue = TileManager.removeRandomTiles(REMOVE_COUNT)
			if not roundActive then break end

			if not canContinue then
				announceWinner(PlayerManager.getActivePlayers())
				currentState = GameState.ENDING
				roundActive = false
				break
			end

			task.wait(REMOVE_INTERVAL)
		end

		eliminationConnection:Disconnect()
		counterActive = false

		-- КІНЕЦЬ РАУНДУ
		PlayerManager.setGameStarted(false)
		PlayerManager.sendAllToLobby()

		for i = LOBBY_WAIT, 1, -1 do
			broadcastGui("⏰ Next round in: " .. i .. " sec")
			task.wait(1)
		end
	end
end

task.spawn(gameLoop)
