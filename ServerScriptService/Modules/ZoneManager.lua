-- Script: ZoneManager (VERSION 8 - Integrado con EnemyConfig)

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService") 

-- REQUIRES
local EnemyHandler = require(game.ServerScriptService.Modules.EnemyHandler) 
local EnemyConfig = require(game.ServerScriptService.Modules.EnemyConfig) -- ¡NUEVO REQUIRE!

local ZoneManager = {}
local SPAWN_HEIGHT = 5
local RAY_CAST_HEIGHT = 1000

-- =======================================================
-- 1. CONFIGURACIÓN DE TODAS LAS ZONAS
-- =======================================================

ZoneManager.Zones = {
	["ArenaFloor"] = {
		FloorPart = Workspace:WaitForChild("ArenaFloor"),
		MAX_ENEMIES = 5, 
		BASE_SPAWN_MULTIPLIER = 2,
		IDLE_SPAWN_RATE = 1, 
		MinimumLevel = 1,
		CoinMultiplier = 1, 
		Enemies = {"Brainrot1"}, -- ¡SIMPLIFICADO!
		CurrentEnemyCount = 0,
	},

	["MediumArenaFloor"] = {
		FloorPart = Workspace:WaitForChild("MediumArenaFloor"),
		MAX_ENEMIES = 10, 
		BASE_SPAWN_MULTIPLIER = 2, 
		IDLE_SPAWN_RATE = 1, 
		MinimumLevel = 5,
		CoinMultiplier = 2,
		Enemies = {"MiniEs"}, -- ¡SIMPLIFICADO!
		CurrentEnemyCount = 0,
	},
	["Arena3"] = {
		FloorPart = Workspace:WaitForChild("Arena3"),
		MAX_ENEMIES = 10, 
		BASE_SPAWN_MULTIPLIER = 2, 
		IDLE_SPAWN_RATE = 1, 
		MinimumLevel = 10,
		CoinMultiplier = 3,
		Enemies = {"BlueDragon"}, -- ¡SIMPLIFICADO!
		CurrentEnemyCount = 0,
	},
	["Arena4"] = {
		FloorPart = Workspace:WaitForChild("Arena4"),
		MAX_ENEMIES = 5, 
		BASE_SPAWN_MULTIPLIER = 2, 
		IDLE_SPAWN_RATE = 1, 
		MinimumLevel = 15,
		CoinMultiplier = 3,
		Enemies = {"GolemPiedra", }, -- ¡SIMPLIFICADO! (Puedes poner los que quieras)
		CurrentEnemyCount = 0,
	},
	["Arena5"] = {
		FloorPart = Workspace:WaitForChild("Arena5"),
		MAX_ENEMIES = 5, 
		BASE_SPAWN_MULTIPLIER = 2, 
		IDLE_SPAWN_RATE = 1, 
		MinimumLevel = 20, -- (Corregí tu comentario de Nivel 10 a 25)
		CoinMultiplier = 3,
		Enemies = {"Arbol"}, -- (Aún sin enemigos)
		CurrentEnemyCount = 0,
	},
	["Arena6"] = {
		FloorPart = Workspace:WaitForChild("Arena6"),
		MAX_ENEMIES = 10, 
		BASE_SPAWN_MULTIPLIER = 2, 
		IDLE_SPAWN_RATE = 1, 
		MinimumLevel = 20, -- (Corregí tu comentario)
		CoinMultiplier = 4,
		Enemies = {"Zombie"},
		CurrentEnemyCount = 0,
	},
	["Arena7"] = {
		FloorPart = Workspace:WaitForChild("Arena7"),
		MAX_ENEMIES = 10, 
		BASE_SPAWN_MULTIPLIER = 2, 
		IDLE_SPAWN_RATE = 1, 
		MinimumLevel = 20, -- (Corregí tu comentario)
		CoinMultiplier = 4,
		Enemies = {"Fantasma02"},
		CurrentEnemyCount = 0,
	},
	["Arena8"] = {
		FloorPart = Workspace:WaitForChild("Arena8"),
		MAX_ENEMIES = 20, 
		BASE_SPAWN_MULTIPLIER = 2, 
		IDLE_SPAWN_RATE = 1, 
		MinimumLevel = 20, -- (Corregí tu comentario)
		CoinMultiplier = 5,
		Enemies = {"FantasmaHielo"},
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
		if ZoneManager.Zones[hit.Name] then
			return hit
		end

		local currentParent = hit.Parent
		while currentParent and currentParent ~= Workspace do
			if ZoneManager.Zones[currentParent.Name] then
				return currentParent
			end
			currentParent = currentParent.Parent
		end
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

	for zoneName, zone in pairs(ZoneManager.Zones) do
		local playerCount = playersInZones[zoneName] or 0
		local enemiesToSpawn = 0
		local floorPartReference

		if zone.FloorPart:IsA("Model") then
			floorPartReference = zone.FloorPart.PrimaryPart
		elseif zone.FloorPart:IsA("BasePart") then
			floorPartReference = zone.FloorPart
		end

		if not floorPartReference then
			warn("ZoneManager: Objeto de zona '" .. zoneName .. "' inválido o sin PrimaryPart.")
			continue
		end

		local topOfFloorY = floorPartReference.Position.Y + (floorPartReference.Size.Y / 2)
		local battleCenter = Vector3.new(
			floorPartReference.Position.X,
			topOfFloorY + SPAWN_HEIGHT,
			floorPartReference.Position.Z
		)

		if zone.CurrentEnemyCount < zone.MAX_ENEMIES then
			if playerCount > 0 then
				enemiesToSpawn = zone.BASE_SPAWN_MULTIPLIER * playerCount
			else
				enemiesToSpawn = zone.IDLE_SPAWN_RATE
			end

			for i = 1, math.ceil(enemiesToSpawn) do

				-- =======================================================
				-- LÓGICA DE SPAWNEO (ACTUALIZADA)
				-- =======================================================
				if zone.Enemies and #zone.Enemies > 0 then

					-- 1. Elegir una clave de enemigo al azar (ej: "Brainrot1")
					local randomIndex = math.random(1, #zone.Enemies)
					local enemyKey = zone.Enemies[randomIndex]

					-- 2. Obtener TODOS los datos de ese enemigo desde el EnemyConfig
					local enemyData = EnemyConfig[enemyKey]

					-- 3. Comprobar que el enemigo existe en el config
					if enemyData then
						-- 4. Pasamos la TABLA ENTERA de datos al EnemyHandler
						EnemyHandler.spawnEnemy(battleCenter, zoneName, enemyData)
						zone.CurrentEnemyCount = zone.CurrentEnemyCount + 1
					else
						warn("ZoneManager: No se encontró la configuración para el enemigo: " .. enemyKey)
					end
				end
				-- =======================================================
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