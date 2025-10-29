-- Script: ZoneManager (VERSION 7 - Niveles Mínimos y Multiplicadores)

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService") 
local EnemyHandler = require(game.ServerScriptService.Modules.EnemyHandler) 

local ZoneManager = {}
local SPAWN_HEIGHT = 7 

-- =======================================================
-- 1. CONFIGURACIÓN DE TODAS LAS ZONAS
-- =======================================================
ZoneManager.Zones = {
	["ArenaFloor"] = {
		-- Propiedades físicas
		FloorPart = Workspace:WaitForChild("ArenaFloor"),

		-- Propiedades de spawneo
		MAX_ENEMIES = 60, 
		BASE_SPAWN_MULTIPLIER = 2,
		IDLE_SPAWN_RATE = 1,       

		-- PROPIEDADES DE PROGRESIÓN
		MinimumLevel = 1, -- Nivel 1 (desbloqueado al inicio)
		CoinMultiplier = 1, 

		-- Estado actual (persiste durante el juego)
		CurrentEnemyCount = 0,
	},

	["MediumArenaFloor"] = {
		-- Propiedades físicas
		FloorPart = Workspace:WaitForChild("MediumArenaFloor"),

		-- Propiedades de spawneo
		MAX_ENEMIES = 60, 
		BASE_SPAWN_MULTIPLIER = 2, 
		IDLE_SPAWN_RATE = 1,       

		-- PROPIEDADES DE PROGRESIÓN
		MinimumLevel = 5, -- Requerirá Nivel 5 para acceder
		CoinMultiplier = 2, -- Mayor riesgo = mayor recompensa

		-- Estado actual (persiste durante el juego)
		CurrentEnemyCount = 0,
	},
}

-- =======================================================
-- 2. FUNCIÓN DE UTILIDAD: Obtener la Zona del Jugador
-- =======================================================

local function findFloorPartUnderPlayer(character) 
	local torso = character:FindFirstChild("HumanoidRootPart")
	if not torso then return nil end

	local ray = Ray.new(torso.Position, Vector3.new(0, -10, 0)) 
	local hit, position, normal, material = Workspace:FindPartOnRay(ray, character)

	if hit then 
		return hit
	end
	return nil
end

-- =======================================================
-- 3. GESTIÓN DE CONTADORES GLOBALES
-- =======================================================

function ZoneManager.enemyKilled(zoneName)
	local zone = ZoneManager.Zones[zoneName]
	if zone and zone.CurrentEnemyCount > 0 then
		zone.CurrentEnemyCount = zone.CurrentEnemyCount - 1
		print("ZoneManager: Enemigo asesinado en " .. zoneName .. ". Contador: " .. zone.CurrentEnemyCount)
	end
end

-- =======================================================
-- 4. FUNCIÓN PRINCIPAL DE GESTIÓN DE ZONAS 
-- =======================================================
function ZoneManager.manageAllZones()

	local playersInZones = {}

	-- 1. Mapear jugadores a sus zonas activas
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			local floorPart = findFloorPartUnderPlayer(character)
			if floorPart then
				local zoneName = floorPart.Name
				if ZoneManager.Zones[zoneName] then
					if not playersInZones[zoneName] then
						playersInZones[zoneName] = 0
					end
					playersInZones[zoneName] = playersInZones[zoneName] + 1
				end
			end
		end
	end

	-- 2. Procesar cada zona
	for zoneName, zone in pairs(ZoneManager.Zones) do

		local playerCount = playersInZones[zoneName] or 0
		local enemiesToSpawn = 0
		local battleCenter = zone.FloorPart.Position + Vector3.new(0, SPAWN_HEIGHT, 0)

		if zone.CurrentEnemyCount < zone.MAX_ENEMIES then
			if playerCount > 0 then
				enemiesToSpawn = zone.BASE_SPAWN_MULTIPLIER * playerCount
			else
				enemiesToSpawn = zone.IDLE_SPAWN_RATE
			end

			for i = 1, math.ceil(enemiesToSpawn) do
				EnemyHandler.spawnEnemy(battleCenter, zoneName) 
				zone.CurrentEnemyCount = zone.CurrentEnemyCount + 1 
			end
		end
	end
end

-- =======================================================
-- 5. EXPORTACIÓN DEL MÓDULO
-- =======================================================
return setmetatable(ZoneManager, {
	__index = {
		getFloorPartUnderPlayer = findFloorPartUnderPlayer,
		enemyKilled = ZoneManager.enemyKilled,
		manageAllZones = ZoneManager.manageAllZones,
		Zones = ZoneManager.Zones,
	}
})