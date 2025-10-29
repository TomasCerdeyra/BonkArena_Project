-- Script: RewardManager (VERSION 2 - Aplicando Multiplicador Global de Mascotas)

local Players = game:GetService("Players")
local ZoneManager = require(game.ServerScriptService.Modules.ZoneManager) -- RUTA ACTUALIZADA

local RewardManager = {}

-- Constantes de Progresión
local COIN_REWARD_BASE = 1 
local XP_PER_KILL = 1 
local BASE_XP_MULTIPLIER = 10 

-- =======================================================
-- 1. LÓGICA DE SUBIDA DE NIVEL
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
				xpNeeded = BASE_XP_MULTIPLIER * playerLevel.Value

				print(player.Name .. " ha subido al Nivel " .. playerLevel.Value .. "!")
			end
		end
	end
end

-- =======================================================
-- 2. FUNCIÓN PRINCIPAL: PROCESAR MUERTE DE ENEMIGO (CORREGIDO)
-- =======================================================
function RewardManager.processKill(player, zoneName, isCritical)
	local rewardMultiplier = isCritical and 2 or 1
	local upgrades = player:FindFirstChild("Upgrades")
	if not upgrades then return end

	-- OBTENER MULTIPLICADOR GLOBAL DE MONEDAS (NUEVO: DE STAT DE MASCOTAS)
	local petMultiplierStat = upgrades:FindFirstChild("CoinMultiplier")
	local petMultiplier = petMultiplierStat and petMultiplierStat.Value or 1.0

	-- Obtener Multiplicadores de Zona
	local zoneData = ZoneManager.Zones[zoneName]
	local zoneMultiplier = zoneData and zoneData.CoinMultiplier or 1

	-- 1. CÁLCULO DE RECOMPENSA FINAL (Multiplicación por Mascota)
	local finalCoinReward = math.floor(COIN_REWARD_BASE * zoneMultiplier * rewardMultiplier * petMultiplier) -- APLICA MULTIPLICADOR MASCOTA
	local finalXPReward = XP_PER_KILL * rewardMultiplier

	-- 2. OTORGAR MONEDAS
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local bonkCoins = leaderstats:FindFirstChild("BonkCoin")
		if bonkCoins then
			bonkCoins.Value = bonkCoins.Value + finalCoinReward
		end
	end

	-- 3. OTORGAR XP y VERIFICAR NIVEL
	local playerXP = upgrades:FindFirstChild("XP")
	if playerXP then
		playerXP.Value = playerXP.Value + finalXPReward
		tryLevelUp(player)
	end

	-- 4. NOTIFICAR AL ZONEMANAGER (para respawn de enemigos)
	for i = 1, rewardMultiplier do
		ZoneManager.enemyKilled(zoneName)
	end
end

return RewardManager