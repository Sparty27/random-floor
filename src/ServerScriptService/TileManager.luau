-- TileManager: генерація та логіка плиток
local TileManager = {}

local tilesFolder = workspace:WaitForChild("TilesFolder")

local LOG = "[TileManager]"

-- Налаштування
local TILE_SIZE = 6
local TILE_GAP = 1
local ARENA_HEIGHT = 20
local COLOR_NORMAL = BrickColor.new("Medium stone grey")
local COLOR_UNSTABLE = BrickColor.new("Bright yellow")

-- Логіка нестабільної плитки
local function setupUnstableTile(tile)
	tile.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid then return end
		if tile:GetAttribute("Activated") then return end
		tile:SetAttribute("Activated", true)
		print(LOG, "Unstable tile activated at", tile.Position)

		local originalPosition = tile.Position
		task.spawn(function()
			for i = 1, 10 do
				tile.Position = originalPosition + Vector3.new(
					math.random(-3, 3) * 0.1, 0, math.random(-3, 3) * 0.1
				)
				task.wait(0.1)
			end
			tile.Position = originalPosition
			tile.BrickColor = BrickColor.new("Bright red")
			tile.Material = Enum.Material.Neon
			task.wait(0.5)
			for i = 1, 5 do
				tile.Transparency = i / 5
				task.wait(0.08)
			end
			tile:Destroy()
		end)
	end)
end

-- Генерація арени
function TileManager.generateTiles(playerCount)
	playerCount = playerCount or 1

	-- Масштабуємо сітку під кількість гравців
	local gridSize
	if playerCount <= 4 then
		gridSize = 8
	elseif playerCount <= 10 then
		gridSize = 10
	elseif playerCount <= 20 then
		gridSize = 14
	else
		gridSize = 18
	end

	-- Очищаємо старі плитки
	for _, tile in ipairs(tilesFolder:GetChildren()) do
		tile:Destroy()
	end

	for row = 1, gridSize do
		for col = 1, gridSize do
			local tile = Instance.new("Part")
			tile.Size = Vector3.new(TILE_SIZE, 1, TILE_SIZE)

			local x = (col - 1) * (TILE_SIZE + TILE_GAP) - (gridSize * (TILE_SIZE + TILE_GAP)) / 2
			local z = (row - 1) * (TILE_SIZE + TILE_GAP) - (gridSize * (TILE_SIZE + TILE_GAP)) / 2
			tile.Position = Vector3.new(x, ARENA_HEIGHT, z)

			local isUnstable = math.random(1, 100) <= 20
			if isUnstable then
				tile.BrickColor = COLOR_UNSTABLE
				tile.Name = "Tile_Unstable"
				setupUnstableTile(tile)
			else
				tile.BrickColor = COLOR_NORMAL
				tile.Name = "Tile_Normal"
			end

			tile.Material = Enum.Material.SmoothPlastic
			tile.Anchored = true
			tile.Parent = tilesFolder
		end
	end

	local unstableCount = 0
	for _, tile in ipairs(tilesFolder:GetChildren()) do
		if tile.Name == "Tile_Unstable" then
			unstableCount += 1
		end
	end
	print(LOG, "Generated", #tilesFolder:GetChildren(), "tiles (" .. gridSize .. "x" .. gridSize .. ") |", unstableCount, "unstable")
end

-- Повертає висоту арени (для динамічної перевірки падіння)
function TileManager.getArenaHeight()
	return ARENA_HEIGHT
end

-- Видалення випадкових плиток (один цикл)
function TileManager.removeRandomTiles(count)
	local allTiles = tilesFolder:GetChildren()
	if #allTiles <= 5 then
		print(LOG, "No more tiles to remove (remaining:", #allTiles, ")")
		return false
	end

	-- Перемішуємо
	for i = #allTiles, 2, -1 do
		local j = math.random(1, i)
		allTiles[i], allTiles[j] = allTiles[j], allTiles[i]
	end

	local removed = math.min(count, #allTiles - 5)
	print(LOG, "Removing", removed, "tiles | Before:", #allTiles, "| After: ~" .. (#allTiles - removed))
	for i = 1, removed do
		local tile = allTiles[i]
		if tile and tile.Parent then
			tile.BrickColor = BrickColor.new("Bright red")
			tile.Material = Enum.Material.Neon
		end
	end

	task.wait(1.5)

	for i = 1, removed do
		local tile = allTiles[i]
		if tile and tile.Parent then
			task.spawn(function()
				for j = 1, 5 do
					tile.Transparency = j / 5
					task.wait(0.08)
				end
				tile:Destroy()
			end)
		end
	end

	return #tilesFolder:GetChildren() > 5
end

-- Скільки плиток лишилось
function TileManager.getTileCount()
	return #tilesFolder:GetChildren()
end

return TileManager