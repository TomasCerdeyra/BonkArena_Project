-- Script: TeleportHandler (VERSION 14 - Carga Diferida y Retiro Seguro Corregido)

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UpdateStatus = ReplicatedStorage:WaitForChild("UpdateStatus")
local ServerScriptService = game:GetService("ServerScriptService")
local ZoneManager = require(ServerScriptService.Modules.ZoneManager) 

local LobbyFloor = Workspace:WaitForChild("LobbyFloor")
local MediumArenaFloor = Workspace:WaitForChild("MediumArenaFloor")
local ArenaFloor = Workspace:WaitForChild("ArenaFloor") 

local RetreatToLobby = ReplicatedStorage:WaitForChild("RetreatToLobby")

local module = {}
local EnemyHandler -- CRÍTICO: Carga diferida

local LOBBY_MESSAGE = "Estás en el Lobby, entra a un portal."

-- ===================================================
-- FUNCIÓN ÚNICA: Teleporte a cualquier Zona (con verificación)
-- ===================================================
function module.teleportToZone(player, zoneName)
	local character = player.Character
	if not character then return end

	local zoneData = ZoneManager.Zones[zoneName]
	local upgrades = player:FindFirstChild("Upgrades")
	if not upgrades then return end

	local playerLevel = upgrades:FindFirstChild("Level").Value

	if not zoneData then
		warn("TeleportHandler: Zona '" .. zoneName .. "' no encontrada.")
		return
	end

	if playerLevel < zoneData.MinimumLevel then
		UpdateStatus:FireClient(player, 
			"ERROR: Necesitas Nivel " .. zoneData.MinimumLevel .. " para acceder a " .. zoneName)
		return
	end

	local targetFloorPart = zoneData.FloorPart
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

	if humanoidRootPart and targetFloorPart then
		local ARENA_RADIUS = 70 
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

		character:SetPrimaryPartCFrame(CFrame.new(arenaSpawnPos))
		UpdateStatus:FireClient(player, " ")
		print(player.Name .. " teletransportado a " .. zoneName)
	end
end

-- ===================================================
-- TELEPORTE AL LOBBY (Mensaje Persistente)
-- ===================================================
function module.teleportToLobby(player)
	-- CRÍTICO: Carga diferida de EnemyHandler
	if not EnemyHandler then
		EnemyHandler = require(ServerScriptService.Modules.EnemyHandler)
	end

	local character = player.Character
	if character then
		-- Limpiar enemigos que lo esten persiguiendo (usando el nombre de V38)
		EnemyHandler.despawnAllEnemies() 

		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local lobbySpawnPos = LobbyFloor.Position + Vector3.new(0, 5, 0)
			character:SetPrimaryPartCFrame(CFrame.new(lobbySpawnPos))

			UpdateStatus:FireClient(player, LOBBY_MESSAGE)
		end
	end
end

-- ===================================================
-- CONEXIÓN AL CLIENTE (Recibe la solicitud de la GUI)
-- ===================================================
local RequestTeleport = ReplicatedStorage:WaitForChild("RequestTeleport")
RequestTeleport.OnServerEvent:Connect(function(player, zoneName)
	module.teleportToZone(player, zoneName)
end)

-- Conexión para el Botón de Retirada Segura
RetreatToLobby.OnServerEvent:Connect(function(player)
	print("Recibido evento de Retiro Seguro para: " .. player.Name)
	module.teleportToLobby(player) 
	-- (GameHandler no es requerido aquí, VfxHandler o SoundHandler podrían añadirse)
end)

return module