-- LeaderboardManager: зберігання та отримання рейтингу
local LeaderboardManager = {}

local DataStoreService = game:GetService("DataStoreService")
local PlayersService = game:GetService("Players")

local winsStore = DataStoreService:GetOrderedDataStore("PlayerWins_v1")

-- Додаємо перемогу гравцю
function LeaderboardManager.addWin(player)
	local userId = tonumber(player.UserId)
	local success, result = pcall(function()
		return winsStore:IncrementAsync(userId, 1)
	end)
	if success then
		return result
	else
		warn("Помилка збереження перемоги: " .. tostring(result))
		return nil
	end
end

-- Отримуємо топ 20 гравців
function LeaderboardManager.getTopPlayers()
	local success, pages = pcall(function()
		return winsStore:GetSortedAsync(false, 20)
	end)

	if not success then
		warn("Помилка GetSortedAsync: " .. tostring(pages))
		return {}
	end

	local topPlayers = {}
	for rank, entry in ipairs(pages:GetCurrentPage()) do
		local name = "Player"
		local nameSuccess, playerName = pcall(function()
			return PlayersService:GetNameFromUserIdAsync(tonumber(entry.key))
		end)
		if nameSuccess then
			name = playerName
		end

		table.insert(topPlayers, {
			rank = rank,
			name = name,
			wins = entry.value,
		})
	end

	return topPlayers
end

return LeaderboardManager
