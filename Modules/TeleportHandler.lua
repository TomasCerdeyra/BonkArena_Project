-- Script: TeleportHandler (VERSION 11 - Teleporte Unificado y con Bloqueo de Nivel)

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UpdateStatus = ReplicatedStorage:WaitForChild("UpdateStatus")
local ServerScriptService = game:GetService("ServerScriptService")
local ZoneManager = require(ServerScriptService.Modules.ZoneManager) -- Necesario para obtener datos de la zona

local LobbyFloor = Workspace:WaitForChild("LobbyFloor")
local MediumArenaFloor = Workspace:WaitForChild("MediumArenaFloor") -- Se mantiene la referencia
local ArenaFloor = Workspace:WaitForChild("ArenaFloor") -- Se mantiene la referencia

local module = {}

local LOBBY_MESSAGE = "Estás en el Lobby, entra a un portal."

-- ===================================================
-- FUNCIÓN ÚNICA: Teleporte a cualquier Zona (con verificación)
-- ===================================================
function module.teleportToZone(player, zoneName)
	local character = player.Character
	if not character then return end

	-- 1. Verificar si la zona existe y si el jugador cumple el nivel
	local zoneData = ZoneManager.Zones[zoneName]
	local upgrades = player:FindFirstChild("Upgrades")
	if not upgrades then return end -- Si upgrades no existe, no continuar

	local playerLevel = upgrades:FindFirstChild("Level").Value

	if not zoneData then
		warn("TeleportHandler: Zona '" .. zoneName .. "' no encontrada.")
		return
	end

	if playerLevel < zoneData.MinimumLevel then
		-- Enviar mensaje de fallo si el nivel es insuficiente
		UpdateStatus:FireClient(player, 
			"ERROR: Necesitas Nivel " .. zoneData.MinimumLevel .. " para acceder a " .. zoneName)
		return
	end

	-- 2. Teletransportar (Lógica Unificada)
	local targetFloorPart = zoneData.FloorPart
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

	if humanoidRootPart and targetFloorPart then
		-- Lógica de spawn seguro (copiada del handler anterior)
		local ARENA_RADIUS = 70 -- Usamos el radio que ajustaste
		local SPAWN_HEIGHT = 5

		local center = targetFloorPart.Position
		local angle = math.random() * 2 * math.pi
		local offsetX = math.cos(angle) * ARENA_RADIUS
		local offsetZ = math.sin(angle) * ARENA_RADIUS

		local arenaSpawnPos = Vector3.new(
			center.X + offsetX, 
			center.Y + SPAWN_HEIGHT, 
			center.Z + offsetZ
		)

		humanoidRootPart.CFrame = CFrame.new(arenaSpawnPos)

		-- Limpiar la pantalla al entrar a la Arena.
		UpdateStatus:FireClient(player, " ")
		print(player.Name .. " teletransportado a " .. zoneName)
	end
end

-- ===================================================
-- TELEPORTE AL LOBBY (Mensaje Persistente)
-- ===================================================
function module.teleportToLobby(player)
	local character = player.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local lobbySpawnPos = LobbyFloor.Position + Vector3.new(0, 5, 0)
			humanoidRootPart.CFrame = CFrame.new(lobbySpawnPos)

			-- Enviamos el mensaje persistente del Lobby.
			UpdateStatus:FireClient(player, LOBBY_MESSAGE)
		end
	end
end

-- Funciones antiguas ELIMINADAS/REEMPLAZADAS
-- function module.teleportToArena(player) -- REEMPLAZADA
-- function module.teleportToMediumArena(player) -- REEMPLAZADA

-- ===================================================
-- CONEXIÓN AL CLIENTE (Recibe la solicitud de la GUI)
-- ===================================================
local RequestTeleport = ReplicatedStorage:WaitForChild("RequestTeleport")
RequestTeleport.OnServerEvent:Connect(function(player, zoneName)
	module.teleportToZone(player, zoneName)
end)

return module