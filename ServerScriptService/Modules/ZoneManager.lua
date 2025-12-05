-- Script: ZoneManager (Servidor)
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService") 
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- REQUIRES
local EnemyHandler = require(ServerScriptService.Modules.EnemyHandler) 
local EnemyData = require(ReplicatedStorage.Shared.Data.EnemyData) 
local ZoneData = require(ReplicatedStorage.Shared.Data.ZoneData) -- Leemos la config completa

local ZoneManager = {}
local SPAWN_HEIGHT = 1

-- Tabla interna donde guardaremos el estado "vivo" de cada zona
ZoneManager.Zones = {}
local ArenasFolder = Workspace:WaitForChild("Arenas", 5) -- Esperamos la carpeta

-- =======================================================
-- 1. INICIALIZACIÓN (Convertir Data en Zonas Activas)
-- =======================================================
-- Recorremos la configuración y preparamos las zonas reales
for zoneKey, config in pairs(ZoneData) do
	-- Buscamos primero en la carpeta Arenas, si no, búsqueda global recursiva
	local floorPart = nil
	if ArenasFolder then
		floorPart = ArenasFolder:FindFirstChild(zoneKey)
	end

	if not floorPart then
		floorPart = Workspace:FindFirstChild(zoneKey, true)
	end

	if floorPart then
		-- Creamos una entrada en nuestra tabla de gestión
		ZoneManager.Zones[zoneKey] = {
			-- 1. Copiamos la configuración (MAX_ENEMIES, etc)
			Config = config, 

			-- 2. Agregamos las variables de ESTADO (Runtime)
			FloorPart = floorPart,
			CurrentEnemyCount = 0, -- Empieza en 0
		}
	else
		warn("ZoneManager: ?? No se encontró el objeto '" .. zoneKey .. "' en Workspace.")
	end
end

-- =======================================================
-- 2. UTILIDADES
-- =======================================================
local function findFloorPartUnderPlayer(character)
	local torso = character:FindFirstChild("HumanoidRootPart")
	if not torso then return nil end

	local ray = Ray.new(torso.Position, Vector3.new(0, -10, 0))
	local hit, position, normal, material = Workspace:FindPartOnRay(ray, character)

	if hit then
		if ZoneManager.Zones[hit.Name] then return hit end
		if hit.Parent and ZoneManager.Zones[hit.Parent.Name] then return hit.Parent end
	end
	return nil
end

function ZoneManager.enemyKilled(zoneName)
	local zone = ZoneManager.Zones[zoneName]
	if zone and zone.CurrentEnemyCount > 0 then
		zone.CurrentEnemyCount = zone.CurrentEnemyCount - 1
	end
end

-- =======================================================
-- 3. BUCLE PRINCIPAL (SPAWNER)
-- =======================================================
function ZoneManager.manageAllZones()
	-- 1. Contar jugadores por zona
	local playersInZones = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			local floorPart = findFloorPartUnderPlayer(character) 
			if floorPart then
				local zoneName = floorPart.Name
				if ZoneManager.Zones[zoneName] then
					playersInZones[zoneName] = (playersInZones[zoneName] or 0) + 1
				end
			end
		end
	end

	-- 2. Gestionar Spawns
	for zoneName, activeZone in pairs(ZoneManager.Zones) do
		local playerCount = playersInZones[zoneName] or 0
		local data = activeZone.Config -- Leemos la config aquí

		local floorPartReference = activeZone.FloorPart
		if floorPartReference:IsA("Model") then floorPartReference = floorPartReference.PrimaryPart end

		if not floorPartReference then continue end

		local topOfFloorY = floorPartReference.Position.Y + (floorPartReference.Size.Y / 2)
		local battleCenter = Vector3.new(floorPartReference.Position.X, topOfFloorY + SPAWN_HEIGHT, floorPartReference.Position.Z)

		-- Usamos los datos de config para decidir
		if activeZone.CurrentEnemyCount < data.MAX_ENEMIES then
			local enemiesToSpawn = 0

			if playerCount > 0 then
				enemiesToSpawn = data.BASE_SPAWN_MULTIPLIER * playerCount
			else
				enemiesToSpawn = data.IDLE_SPAWN_RATE
			end

			-- Capar para no exceder el máximo
			local spaceLeft = data.MAX_ENEMIES - activeZone.CurrentEnemyCount
			enemiesToSpawn = math.min(enemiesToSpawn, spaceLeft)

			for i = 1, math.ceil(enemiesToSpawn) do
				if data.Enemies and #data.Enemies > 0 then
					local randomIndex = math.random(1, #data.Enemies)
					local enemyKey = data.Enemies[randomIndex]
					local enemyStats = EnemyData[enemyKey] 

					if enemyStats then
						EnemyHandler.spawnEnemy(battleCenter, zoneName, enemyStats)
						activeZone.CurrentEnemyCount = activeZone.CurrentEnemyCount + 1
					end
				end
			end
		end
	end
end

return setmetatable(ZoneManager, {
	__index = {
		getFloorPartUnderPlayer = findFloorPartUnderPlayer,
		enemyKilled = ZoneManager.enemyKilled,
		manageAllZones = ZoneManager.manageAllZones,
		Zones = ZoneManager.Zones,
	}
})