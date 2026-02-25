-- PlayerDataManager: XP, рівні, монети, статистика гравця, щоденні нагороди
local PlayerDataManager = {}

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local dataStore = DataStoreService:GetDataStore("PlayerData_v1")

local LOG = "[PlayerData]"

local DEFAULT_DATA = {
	xp = 0,
	level = 1,
	coins = 0,
	gamesPlayed = 0,
	wins = 0,
	currentStreak = 0,
	longestStreak = 0,
	lastDailyReward = 0,
	achievements = {},  -- { ["first_win"] = true, ... }
}

-- Кеш даних гравців (очищається при виході)
local cache = {} -- [userId] = data

-- XP потрібно для переходу з рівня level на level+1
local function xpForLevel(level)
	return level * 100
end

-- Перераховуємо рівень на основі поточного XP
local function recalculateLevel(data)
	local level = 1
	local remaining = data.xp
	while remaining >= xpForLevel(level) do
		remaining -= xpForLevel(level)
		level += 1
	end
	data.level = level
end

-- Оновлюємо папку leaderstats (видно у вкладці Tab в Roblox)
local function updateLeaderstats(player)
	local data = cache[player.UserId]
	if not data then return end

	local ls = player:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		ls.Parent = player
	end

	local function setStat(name, value)
		local stat = ls:FindFirstChild(name)
		if not stat then
			stat = Instance.new("IntValue")
			stat.Name = name
			stat.Parent = ls
		end
		stat.Value = value
	end

	setStat("Level", data.level)
	setStat("XP", data.xp)
	setStat("Coins", data.coins)
end

-- Завантажуємо дані гравця з DataStore
function PlayerDataManager.loadPlayer(player)
	local key = tostring(player.UserId)
	local success, result = pcall(dataStore.GetAsync, dataStore, key)

	local data = {}
	if success and type(result) == "table" then
		-- Merge зі значеннями за замовчуванням (для нових полів при оновленнях)
		for k, v in pairs(DEFAULT_DATA) do
			data[k] = result[k] ~= nil and result[k] or v
		end
		print(LOG, "Loaded", player.Name, "| Lv:", data.level, "XP:", data.xp, "Coins:", data.coins,
			"Games:", data.gamesPlayed, "Wins:", data.wins)
	else
		if not success then
			warn(LOG, "Load failed for", player.Name, ":", tostring(result))
		end
		for k, v in pairs(DEFAULT_DATA) do
			data[k] = v
		end
		print(LOG, "New player data for", player.Name)
	end

	cache[player.UserId] = data
	updateLeaderstats(player)
end

-- Зберігаємо дані гравця в DataStore
function PlayerDataManager.savePlayer(player)
	local key = tostring(player.UserId)
	local data = cache[player.UserId]
	if not data then
		warn(LOG, "No cached data to save for", player.Name)
		return
	end

	local success, err = pcall(dataStore.SetAsync, dataStore, key, data)
	if success then
		print(LOG, "Saved", player.Name)
	else
		warn(LOG, "Save failed for", player.Name, ":", tostring(err))
	end
end

-- Повертає кешовані дані гравця
function PlayerDataManager.getData(player)
	return cache[player.UserId]
end

-- Нараховуємо XP та перераховуємо рівень
-- Повертає true якщо гравець підвищив рівень
function PlayerDataManager.awardXP(player, amount)
	local data = cache[player.UserId]
	if not data then return false end

	local oldLevel = data.level
	data.xp += amount
	recalculateLevel(data)

	local leveledUp = data.level > oldLevel
	if leveledUp then
		print(LOG, player.Name, "LEVEL UP! →", data.level)
	end

	updateLeaderstats(player)
	return leveledUp
end

-- Нараховуємо монети
function PlayerDataManager.awardCoins(player, amount)
	local data = cache[player.UserId]
	if not data then return end

	data.coins += amount
	updateLeaderstats(player)
	print(LOG, player.Name, "+", amount, "coins → total:", data.coins)
end

-- Записуємо результат раунду та нараховуємо нагороди
-- won = true лише для переможця
function PlayerDataManager.recordRoundResult(player, won)
	local data = cache[player.UserId]
	if not data then return end

	data.gamesPlayed += 1

	-- Нагороди
	local xpGain = 10    -- базово за участь
	local coinsGain = 5  -- базово за участь

	if won then
		data.wins += 1
		data.currentStreak += 1
		if data.currentStreak > data.longestStreak then
			data.longestStreak = data.currentStreak
		end
		xpGain += 25
		coinsGain += 15
	else
		data.currentStreak = 0
	end

	local leveledUp = PlayerDataManager.awardXP(player, xpGain)
	PlayerDataManager.awardCoins(player, coinsGain)

	print(LOG, player.Name, won and "WON" or "played",
		"| +XP:", xpGain, "+Coins:", coinsGain,
		"| Games:", data.gamesPlayed, "Wins:", data.wins, "Streak:", data.currentStreak)

	return { xp = xpGain, coins = coinsGain, leveledUp = leveledUp, newLevel = data.level }
end

-- Повертає статистику для клієнта (RemoteFunction)
function PlayerDataManager.getStatsForClient(player)
	local data = cache[player.UserId]
	if not data then return nil end

	-- XP накопичений у межах поточного рівня
	local xpInLevel = data.xp
	for lvl = 1, data.level - 1 do
		xpInLevel -= lvl * 100
	end

	local winRate = data.gamesPlayed > 0
		and math.floor(data.wins / data.gamesPlayed * 100)
		or 0

	return {
		level          = data.level,
		xpInLevel      = xpInLevel,
		xpForNextLevel = data.level * 100,
		coins          = data.coins,
		gamesPlayed    = data.gamesPlayed,
		wins           = data.wins,
		winRate        = winRate,
		currentStreak  = data.currentStreak,
		longestStreak  = data.longestStreak,
	}
end

-- Перевіряємо та видаємо щоденну нагороду
-- Повертає кількість монет (0 якщо вже отримано сьогодні)
function PlayerDataManager.checkDailyReward(player)
	local data = cache[player.UserId]
	if not data then return 0 end

	local now = os.time()
	if now - (data.lastDailyReward or 0) >= 86400 then
		local reward = 50
		data.lastDailyReward = now
		PlayerDataManager.awardCoins(player, reward)
		print(LOG, player.Name, "claimed daily reward: +", reward, "coins")
		return reward
	else
		local remaining = 86400 - (now - data.lastDailyReward)
		local hours = math.floor(remaining / 3600)
		local mins = math.floor((remaining % 3600) / 60)
		print(LOG, player.Name, "daily reward not ready. Remaining:", hours .. "h " .. mins .. "m")
		return 0
	end
end

-- Авто-хуки
Players.PlayerAdded:Connect(function(player)
	PlayerDataManager.loadPlayer(player)
	-- Невелика затримка щоб клієнт встиг завантажитись
	task.delay(2, function()
		if player and player.Parent then
			PlayerDataManager.checkDailyReward(player)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerDataManager.savePlayer(player)
	cache[player.UserId] = nil
end)

-- Зберігаємо всіх при вимкненні сервера (паралельно, чекаємо завершення)
game:BindToClose(function()
	local pending = 0
	for _, player in ipairs(Players:GetPlayers()) do
		pending += 1
		task.spawn(function()
			PlayerDataManager.savePlayer(player)
			pending -= 1
		end)
	end
	while pending > 0 do
		task.wait(0.1)
	end
	print(LOG, "BindToClose: all players saved")
end)

-- Авто-збереження кожні 5 хвилин (захист від краша)
task.spawn(function()
	while true do
		task.wait(300)
		local count = 0
		for _, player in ipairs(Players:GetPlayers()) do
			PlayerDataManager.savePlayer(player)
			count += 1
			task.wait(1)  -- пауза між гравцями щоб не спамити DataStore
		end
		if count > 0 then
			print(LOG, "Auto-save: saved", count, "players")
		end
	end
end)

return PlayerDataManager
