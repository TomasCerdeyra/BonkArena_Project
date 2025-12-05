-- Script: RewardManager (OPTIMIZADO - LEE ATRIBUTOS)
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Módulos
local ZoneManager = require(ServerScriptService.Modules.ZoneManager)
local EnemyData = require(ReplicatedStorage.Shared.Data.EnemyData)

local RewardManager = {}

local BASE_XP_MULTIPLIER = 10 

-- =======================================================
-- LÓGICA DE SUBIDA DE NIVEL
-- =======================================================
local function tryLevelUp(player)
	local upgrades = player:FindFirstChild("Upgrades")
	if not upgrades then return end

	local playerLevel = upgrades:FindFirstChild("Level")
	local playerXP = upgrades:FindFirstChild("XP") 
	local maxXPVal = upgrades:FindFirstChild("MaxXP") 

	if playerLevel and playerXP then
		local currentLevel = playerLevel.Value
		local xpNeeded = BASE_XP_MULTIPLIER * currentLevel

		if playerXP.Value >= xpNeeded then
			while playerXP.Value >= xpNeeded do
				playerXP.Value = playerXP.Value - xpNeeded
				playerLevel.Value = playerLevel.Value + 1
				xpNeeded = BASE_XP_MULTIPLIER * playerLevel.Value

				if maxXPVal then maxXPVal.Value = xpNeeded end

				print(player.Name, "ha subido al Nivel", playerLevel.Value)

				-- (Opcional) Aquí podrías reproducir un sonido de Level Up
			end
		end
	end
end

-- =======================================================
-- FUNCIÓN PRINCIPAL: PROCESAR MUERTE
-- =======================================================
function RewardManager.processKill(player, enemyModel, isCritical)
	if not enemyModel then return end

	-- 1. OBTENER DATOS DEL ENEMIGO
	local enemyKey = enemyModel.Name
	local config = EnemyData[enemyKey]

	-- Fallback por seguridad si no hay config
	local baseCoin = (config and config.BaseCoinReward) or 5
	local baseXp = (config and config.BaseXpReward) or 10

	local rewardMultiplier = isCritical and 2 or 1

	-- 2. MULTIPLICADORES (Zona y Mascota)
	local upgrades = player:FindFirstChild("Upgrades")
	if not upgrades then return end

	local zoneTag = enemyModel:FindFirstChild("Zone")
	local zoneName = zoneTag and zoneTag.Value
	local zoneMultiplier = 1
	if zoneName and ZoneManager.Zones[zoneName] then
		zoneMultiplier = ZoneManager.Zones[zoneName].Config.CoinMultiplier or 1
	end

	local petMultiplierStat = upgrades:FindFirstChild("CoinMultiplier")
	local petBonus = petMultiplierStat and petMultiplierStat.Value or 1.0 

	-- 3. === MULTIPLICADOR DE GAMEPASS (OPTIMIZADO) ===
	local gamepassMultiplier = 1

	-- Leemos el atributo que puso el GamePassHandler (Es instantáneo)
	if player:GetAttribute("HasX2") then
		gamepassMultiplier = 2
		-- print("Bono x2 aplicado por Atributo") -- Descomentar para depurar
	end
	-- =================================================

	-- 4. CÁLCULO FINAL
	-- Fórmula: Base * Zona * Critico * Mascota * Gamepass
	local finalCoinReward = baseCoin * zoneMultiplier * rewardMultiplier * petBonus * gamepassMultiplier
	finalCoinReward = math.max(1, math.floor(finalCoinReward))

	local finalXPReward = math.max(1, math.floor(baseXp * rewardMultiplier))

	-- 5. ENTREGAR RECOMPENSAS
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local bonkCoins = leaderstats:FindFirstChild("BonkCoin")
		if bonkCoins then
			bonkCoins.Value = bonkCoins.Value + finalCoinReward
		end
	end

	local playerXP = upgrades:FindFirstChild("XP")
	if playerXP then
		playerXP.Value = playerXP.Value + finalXPReward
		tryLevelUp(player)
	end

	-- 6. NOTIFICAR RESPALDO A LA ZONA
	if zoneName then
		ZoneManager.enemyKilled(zoneName)
	end
end

return RewardManager