-- PlayerManager: спавн гравців та кімната спостереження
local PlayerManager = {}

local Players = game:GetService("Players")
local tilesFolder = workspace:WaitForChild("TilesFolder")
local obsSpawn = workspace:WaitForChild("ObsSpawn")
local playerEliminated = game.ServerScriptService:WaitForChild("PlayerEliminated")

local activePlayers = {}
local gameStarted = false

function PlayerManager.setGameStarted(value)
	gameStarted = value
end

-- Телепорт на арену
function PlayerManager.spawnOnArena(player)
	local character = player.Character
	if not character then
		player:LoadCharacter()
		character = player.CharacterAdded:Wait()
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		character = player.CharacterAdded:Wait()
		humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	end

	local humanoid = character:WaitForChild("Humanoid")

	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0

	repeat task.wait() until #tilesFolder:GetChildren() > 0

	local allTiles = tilesFolder:GetChildren()
	local randomTile = allTiles[math.random(1, #allTiles)]

	humanoidRootPart.CFrame = CFrame.new(randomTile.Position + Vector3.new(0, 3, 0))

	task.wait(1)

	humanoid.WalkSpeed = 16
	humanoid.JumpPower = 50

	activePlayers[player.UserId] = true
end

-- Телепорт в кімнату спостереження
function PlayerManager.sendToObservation(player)
	activePlayers[player.UserId] = nil

	local character = player.Character
	if not character then return end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	humanoidRootPart.CFrame = CFrame.new(
		obsSpawn.Position + Vector3.new(math.random(-15, 15), 3, math.random(-15, 15))
	)

	player:SetAttribute("IsSpectating", true)

	playerEliminated:Fire()
end

-- Відправляємо всіх в лобі
function PlayerManager.sendAllToLobby()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if not character then continue end
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then continue end

		humanoidRootPart.CFrame = CFrame.new(
			obsSpawn.Position + Vector3.new(math.random(-15, 15), 3, math.random(-15, 15))
		)

		player:SetAttribute("IsSpectating", false)
	end
end

-- Слідкуємо чи гравець впав
function PlayerManager.watchPlayer(player)
	repeat task.wait(0.1) until activePlayers[player.UserId]

	local character = player.Character
	if not character then return end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	while character and character.Parent do
		task.wait(0.1)
		if gameStarted and activePlayers[player.UserId] and humanoidRootPart.Position.Y < 10 then
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
	activePlayers = {}
	gameStarted = false
end

return PlayerManager
