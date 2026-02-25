-- AchievementManager: перевірка та видача досягнень
local AchievementManager = {}

local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LOG = "[Achievement]"

-- ── Визначення досягнень ───────────────────────────────────────────────────
-- Заповніть badgeId реальними ID з Roblox Creator Hub (0 = без Roblox-бейджу)

local ACHIEVEMENTS = {
	{ id = "first_win", name = "First Win!",  icon = "🏆", badgeId = 3950815589964935, check = function(d) return d.wins >= 1          end },
	{ id = "wins_5",    name = "5 Wins",       icon = "🏆", badgeId = 2634067799284943, check = function(d) return d.wins >= 5          end },
	{ id = "wins_10",   name = "10 Wins",      icon = "🏆", badgeId = 572385955451824, check = function(d) return d.wins >= 10         end },
	{ id = "games_25",  name = "Veteran",      icon = "🎮", badgeId = 4129668067748878, check = function(d) return d.gamesPlayed >= 25  end },
	{ id = "streak_3",  name = "Hot Streak",   icon = "🔥", badgeId = 2021857687916684, check = function(d) return d.longestStreak >= 3 end },
	{ id = "legend",    name = "Legend",       icon = "⭐", badgeId = 0, check = function(d) return d.wins >= 50         end },
}	

-- RemoteEvent: сервер → клієнт при отриманні досягнення
local gameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local achievementAwarded = Instance.new("RemoteEvent")
achievementAwarded.Name = "AchievementAwarded"
achievementAwarded.Parent = gameEvents

-- ── Публічний API ──────────────────────────────────────────────────────────

-- Перевіряє всі невидані досягнення і видає ті, умова яких виконана
function AchievementManager.checkAchievements(player, data)
	if not data then return end

	if not data.achievements then
		data.achievements = {}
	end

	for _, achievement in ipairs(ACHIEVEMENTS) do
		if data.achievements[achievement.id] then continue end

		if achievement.check(data) then
			data.achievements[achievement.id] = true
			print(LOG, player.Name, "unlocked:", achievement.name)

			-- Roblox Badge (якщо ID вказано)
			if achievement.badgeId > 0 then
				task.spawn(function()
					local ok, err = pcall(BadgeService.AwardBadge, BadgeService, player.UserId, achievement.badgeId)
					if not ok then
						warn(LOG, "AwardBadge failed for", achievement.name, ":", err)
					end
				end)
			end

			-- Нотифікація клієнта
			achievementAwarded:FireClient(player, { name = achievement.name, icon = achievement.icon })
		end
	end
end

return AchievementManager
