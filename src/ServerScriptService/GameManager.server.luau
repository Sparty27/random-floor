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

local LOG = "[GameManager]"
print(LOG, "Loaded")

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
	print(LOG, "announceWinner called, activePlayers:", #activePlayers)
	if #activePlayers == 1 then
		local name = activePlayers[1].Name
		print(LOG, "Winner:", name)
		showWinner:FireAllClients(name)
		broadcastGui("🏆 " .. name .. " wins!")
		LeaderboardManager.addWin(activePlayers[1])
		task.wait(1) -- чекаємо поки DataStore збереже
		refreshLeaderboard:Fire()
	elseif #activePlayers == 0 then
		print(LOG, "Draw — everyone fell")
		showWinner:FireAllClients("Нічия!")
		broadcastGui("🤝 Draw! Everyone fell!")
	else
		print(LOG, "Draw —", #activePlayers, "players survived (tiles ran out)")
		showWinner:FireAllClients("Нічия!")
		broadcastGui("🤝 Draw! " .. #activePlayers .. " players survived!")
	end
end

local function spawnAllPlayers()
	PlayerManager.resetActivePlayers()

	local playersToSpawn = Players:GetPlayers()
	print(LOG, "Spawning", #playersToSpawn, "players on arena")
	for _, player in ipairs(playersToSpawn) do
		task.spawn(PlayerManager.spawnOnArena, player)
		task.spawn(PlayerManager.watchPlayer, player)
	end

	-- Чекаємо максимум 10 секунд — захист від дедлоку якщо гравець від'єднається під час спавну
	local expectedCount = #playersToSpawn
	local elapsed = 0
	repeat
		task.wait(0.5)
		elapsed += 0.5
	until #PlayerManager.getActivePlayers() >= expectedCount or elapsed >= 10

	local actualCount = #PlayerManager.getActivePlayers()
	if actualCount < expectedCount then
		warn(LOG, "Spawn timeout! Expected:", expectedCount, "Got:", actualCount, "(elapsed:", elapsed, "s)")
	else
		print(LOG, "All", actualCount, "players spawned successfully")
	end
end

-- Головний ігровий цикл
local function gameLoop()
	while true do
		-- ЛОБІ
		currentState = GameState.LOBBY
		print(LOG, "=== STATE: LOBBY === Players online:", #Players:GetPlayers())
		for i = LOBBY_WAIT, 1, -1 do
			broadcastGui("⏳ Game starts in: " .. i .. " sec")
			task.wait(1)
		end

		-- ГЕНЕРАЦІЯ АРЕНИ
		broadcastGui("🏗️ Generating arena...")
		local playerCount = #Players:GetPlayers()
		print(LOG, "=== STATE: GENERATING === Players:", playerCount)
		TileManager.generateTiles(playerCount)
		PlayerManager.setArenaHeight(TileManager.getArenaHeight())
		print(LOG, "Arena height set to:", TileManager.getArenaHeight())
		task.wait(1)

		-- СПАВН ГРАВЦІВ
		currentState = GameState.PLAYING
		print(LOG, "=== STATE: PLAYING ===")
		broadcastGui("🎮 Game started! Stay on the tiles!")
		spawnAllPlayers()
		task.wait(3)
		PlayerManager.setGameStarted(true)
		print(LOG, "gameStarted = true, tile removal begins")

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
			print(LOG, "Player eliminated! Active players left:", #active)
			if #active <= 1 then
				print(LOG, "=== STATE: ENDING (via elimination) ===")
				announceWinner(active)
				currentState = GameState.ENDING
				roundActive = false
			end
		end)

		while roundActive do
			local canContinue = TileManager.removeRandomTiles(REMOVE_COUNT)
			if not roundActive then
				print(LOG, "Round ended during tile removal (elimination)")
				break
			end

			if not canContinue then
				print(LOG, "=== STATE: ENDING (tiles ran out) === Active players:", #PlayerManager.getActivePlayers())
				announceWinner(PlayerManager.getActivePlayers())
				currentState = GameState.ENDING
				roundActive = false
				break
			end

			print(LOG, "Tiles remaining:", TileManager.getTileCount(), "| Active players:", #PlayerManager.getActivePlayers())
			task.wait(REMOVE_INTERVAL)
		end

		eliminationConnection:Disconnect()
		counterActive = false

		-- КІНЕЦЬ РАУНДУ
		print(LOG, "=== ROUND CLEANUP ===")
		PlayerManager.setGameStarted(false)
		PlayerManager.sendAllToLobby()

		for i = LOBBY_WAIT, 1, -1 do
			broadcastGui("⏰ Next round in: " .. i .. " sec")
			task.wait(1)
		end
	end
end

task.spawn(gameLoop)
