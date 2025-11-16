-- Script: RewardManager (VERSION FINAL - Corrección Matemática)

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local ZoneManager = require(ServerScriptService.Modules.ZoneManager)
local EnemyConfig = require(ServerScriptService.Modules.EnemyConfig)

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

	if playerLevel and playerXP then
		local currentLevel = playerLevel.Value
		local xpNeeded = BASE_XP_MULTIPLIER * currentLevel

		if playerXP.Value >= xpNeeded then
			while playerXP.Value >= xpNeeded do
				playerXP.Value = playerXP.Value - xpNeeded
				playerLevel.Value = playerLevel.Value + 1

				-- Recalcular XP necesaria
				xpNeeded = BASE_XP_MULTIPLIER * playerLevel.Value

				-- === AGREGAR ESTO ===
				-- Actualizar el valor visible para el cliente
				local maxXPVal = upgrades:FindFirstChild("MaxXP")
				if maxXPVal then
					maxXPVal.Value = xpNeeded
				end
				-- ====================

				print(player.Name, "ha subido al Nivel", playerLevel.Value)
			end
		end
	end
end

-- =======================================================
-- FUNCIÓN PRINCIPAL
-- =======================================================
function RewardManager.processKill(player, enemyModel, isCritical)

	-- 1. SEGURIDAD
	if not enemyModel then return end

	-- 2. OBTENER DATOS DEL ENEMIGO
	local enemyKey = enemyModel.Name
	local enemyData = EnemyConfig[enemyKey]

	if not enemyData then
		-- Fallback seguro
		enemyData = { BaseCoinReward = 1, BaseXpReward = 1 } 
	end

	local rewardMultiplier = isCritical and 2 or 1
	local upgrades = player:FindFirstChild("Upgrades")
	if not upgrades then return end

	-- 3. OBTENER ZONA
	local zoneTag = enemyModel:FindFirstChild("Zone")
	local zoneName = zoneTag and zoneTag.Value

	local zoneMultiplier = 1
	if zoneName and ZoneManager.Zones[zoneName] then
		zoneMultiplier = ZoneManager.Zones[zoneName].CoinMultiplier or 1
	end

	-- 4. MULTIPLICADOR DE MASCOTAS (¡CORREGIDO!)
	local petMultiplierStat = upgrades:FindFirstChild("CoinMultiplier")
	local petBonus = petMultiplierStat and petMultiplierStat.Value or 0 
	-- Si el valor es 0.05, queremos multiplicar por 1.05
	local totalPetMult = 1 + petBonus 

	-- 5. CÁLCULO FINAL (¡CORREGIDO!)
	local baseCoin = tonumber(enemyData.BaseCoinReward) or 1
	local baseXp = tonumber(enemyData.BaseXpReward) or 1

	-- Fórmula: Base * Zona * Critico * (1 + Mascota)
	local rawCoins = baseCoin * zoneMultiplier * rewardMultiplier * totalPetMult

	-- math.max(1, ...) asegura que SIEMPRE ganes al menos 1 moneda
	local finalCoinReward = math.max(1, math.floor(rawCoins))

	local finalXPReward = math.max(1, math.floor(baseXp * rewardMultiplier))

	-- 6. OTORGAR MONEDAS
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local bonkCoins = leaderstats:FindFirstChild("BonkCoin")
		if bonkCoins then
			bonkCoins.Value = bonkCoins.Value + finalCoinReward
			-- print("Ganaste: " .. finalCoinReward .. " monedas") -- Puedes descomentar esto si quieres verlo
		end
	end

	-- 7. OTORGAR XP
	local playerXP = upgrades:FindFirstChild("XP")
	if playerXP then
		playerXP.Value = playerXP.Value + finalXPReward
		tryLevelUp(player)
	end

	-- 8. RESPWAN
	if zoneName then
		for i = 1, rewardMultiplier do
			ZoneManager.enemyKilled(zoneName)
		end
	end
end

return RewardManager