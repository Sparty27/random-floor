-- PlayerManager: спавн гравців та кімната спостереження
local PlayerManager = {}

local Players = game:GetService("Players")
local tilesFolder = workspace:WaitForChild("TilesFolder")
local obsSpawn = workspace:WaitForChild("ObsSpawn")
local playerEliminated = game.ServerScriptService:WaitForChild("PlayerEliminated")

local activePlayers = {}
local gameStarted = false
local arenaHeight = 20 -- оновлюється перед кожним раундом через setArenaHeight

local LOG = "[PlayerManager]"

function PlayerManager.setGameStarted(value)
	gameStarted = value
	print(LOG, "gameStarted =", value)
end

-- Встановлюємо висоту арени перед кожним раундом
function PlayerManager.setArenaHeight(height)
	arenaHeight = height
	print(LOG, "arenaHeight =", height)
end

-- Телепорт на арену
function PlayerManager.spawnOnArena(player)
	print(LOG, "spawnOnArena started for", player.Name)
	local character = player.Character
	if not character then
		print(LOG, player.Name, "has no character, loading...")
		player:LoadCharacter()
		character = player.CharacterAdded:Wait()
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		warn(LOG, player.Name, "missing HumanoidRootPart, waiting for respawn...")
		character = player.CharacterAdded:Wait()
		humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	end

	local humanoid = character:WaitForChild("Humanoid")

	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0

	repeat task.wait() until #tilesFolder:GetChildren() > 0

	-- Спавнимо тільки на стабільних плитках (не жовтих)
	local safeTiles = {}
	for _, tile in ipairs(tilesFolder:GetChildren()) do
		if tile.Name ~= "Tile_Unstable" then
			table.insert(safeTiles, tile)
		end
	end
	-- Якщо стабільних немає — використовуємо будь-яку
	if #safeTiles == 0 then
		safeTiles = tilesFolder:GetChildren()
		warn(LOG, player.Name, "no safe tiles available, using any tile")
	end
	local randomTile = safeTiles[math.random(1, #safeTiles)]

	humanoidRootPart.CFrame = CFrame.new(randomTile.Position + Vector3.new(0, 3, 0))
	print(LOG, player.Name, "placed on tile:", randomTile.Name, "at", randomTile.Position)

	task.wait(1)

	humanoid.WalkSpeed = 16
	humanoid.JumpPower = 50

	activePlayers[player.UserId] = true
	print(LOG, player.Name, "is now active on arena")
end

-- Телепорт в кімнату спостереження
function PlayerManager.sendToObservation(player)
	print(LOG, player.Name, "eliminated! Sending to observation")
	activePlayers[player.UserId] = nil

	local character = player.Character
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

	if humanoidRootPart then
		humanoidRootPart.CFrame = CFrame.new(
			obsSpawn.Position + Vector3.new(math.random(-15, 15), 3, math.random(-15, 15))
		)
	else
		warn(LOG, player.Name, "could not teleport to observation (no character or HRP)")
	end

	player:SetAttribute("IsSpectating", true)

	-- ЗАВЖДИ сигналізуємо про елімінацію, навіть якщо телепорт не вдався
	playerEliminated:Fire()
end

-- Відправляємо всіх в лобі
function PlayerManager.sendAllToLobby()
	local players = Players:GetPlayers()
	print(LOG, "Sending", #players, "players to lobby")
	for _, player in ipairs(players) do
		-- ЗАВЖДИ скидаємо спектатор, навіть якщо персонажа немає
		player:SetAttribute("IsSpectating", false)

		local character = player.Character
		if not character then
			print(LOG, player.Name, "has no character during lobby teleport, skipping TP")
			continue
		end
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			print(LOG, player.Name, "missing HRP during lobby teleport, skipping TP")
			continue
		end

		humanoidRootPart.CFrame = CFrame.new(
			obsSpawn.Position + Vector3.new(math.random(-15, 15), 3, math.random(-15, 15))
		)
	end
end

-- Слідкуємо чи гравець впав
function PlayerManager.watchPlayer(player)
	print(LOG, "watchPlayer started for", player.Name)

	-- Чекаємо поки гравець не з'явиться на арені, але не вічно
	local elapsed = 0
	repeat
		task.wait(0.1)
		elapsed += 0.1
	until activePlayers[player.UserId] or elapsed >= 15 or not player.Parent

	-- Гравець вийшов або не заспавнився вчасно — виходимо
	if not activePlayers[player.UserId] then
		warn(LOG, "watchPlayer exit:", player.Name, "not active (elapsed:", string.format("%.1f", elapsed), "s)")
		return
	end

	local character = player.Character
	if not character then
		warn(LOG, "watchPlayer exit:", player.Name, "no character")
		return
	end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		warn(LOG, "watchPlayer exit:", player.Name, "no HumanoidRootPart")
		return
	end

	print(LOG, "watchPlayer monitoring", player.Name, "| fallThreshold Y <", arenaHeight - 10)
	while character and character.Parent do
		task.wait(0.1)
		if gameStarted and activePlayers[player.UserId] and humanoidRootPart.Position.Y < (arenaHeight - 10) then
			print(LOG, player.Name, "fell! Y =", string.format("%.1f", humanoidRootPart.Position.Y))
			PlayerManager.sendToObservation(player)
			break
		end
	end
end

-- Хто зараз на арені
function PlayerManager.getActivePlayers()
	local result = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if activePlayers[player.UserId] then
			table.insert(result, player)
		end
	end
	return result
end

-- Скидаємо список активних гравців
function PlayerManager.resetActivePlayers()
	print(LOG, "Reset active players")
	activePlayers = {}
	gameStarted = false
end

-- Якщо гравець виходить під час раунду — прибираємо його з activePlayers і сигналізуємо
Players.PlayerRemoving:Connect(function(player)
	if activePlayers[player.UserId] then
		print(LOG, player.Name, "disconnected during round — removing from active")
		activePlayers[player.UserId] = nil
		playerEliminated:Fire()
	else
		print(LOG, player.Name, "disconnected (was not active in round)")
	end
end)

return PlayerManager
