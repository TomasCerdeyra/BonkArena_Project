-- Script: TeleportHandler (VERSIÓN LIMPIA - SOLO FÍSICA)
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Datos
local ZoneData = require(ReplicatedStorage.Shared.Data.ZoneData)

-- Referencias Red
local Network = ReplicatedStorage:WaitForChild("Network")
local UpdateStatus = Network:WaitForChild("UpdateStatus")
local RetreatToLobby = Network:WaitForChild("RetreatToLobby")
-- (Borramos RequestTeleport porque ya no usamos la GUI de selección)

-- Referencia al Lobby
local LobbyFloor = Workspace:WaitForChild("Lobby"):WaitForChild("LobbyFloor") 

local module = {}
local EnemyHandler 

local LOBBY_MESSAGE = "Estás en el Lobby, entra a un portal."

-- ===================================================
-- TELEPORTE A ZONA (Usada por PhysicalPortalHandler)
-- ===================================================
function module.teleportToZone(player, zoneID)
	local character = player.Character
	if not character then return end

	local zoneConfig = ZoneData[zoneID]

	if not zoneConfig then
		warn("TeleportHandler: Zona '" .. tostring(zoneID) .. "' no encontrada en ZoneData.")
		return
	end

	-- Verificar Nivel
	local upgrades = player:FindFirstChild("Upgrades")
	if not upgrades then return end
	local playerLevel = upgrades:FindFirstChild("Level").Value
	local requiredLevel = zoneConfig.MinimumLevel or 0

	if playerLevel < requiredLevel then
		UpdateStatus:FireClient(player, "?? Nivel " .. requiredLevel .. " necesario.")
		return
	end

	-- 3. Buscar el punto de destino físico
	-- Ahora buscamos dentro de la carpeta "Arenas" para ser ordenados
	local arenasFolder = Workspace:FindFirstChild("Arenas")
	local targetFloor = arenasFolder and arenasFolder:FindFirstChild(zoneID)

	-- Fallback: Si no está en la carpeta, buscamos en Workspace recursivamente (por si te olvidaste de mover alguna)
	if not targetFloor then
		targetFloor = Workspace:FindFirstChild(zoneID, true)
	end

	if not targetFloor then
		warn("TeleportHandler: No se encontró el piso físico '" .. zoneID .. "' en Workspace.")
		return
	end

	-- Calcular centro
	local center
	if targetFloor:IsA("Model") then
		if targetFloor.PrimaryPart then
			center = targetFloor.PrimaryPart.Position
		else
			center = targetFloor:GetModelCFrame().Position
		end
	elseif targetFloor:IsA("BasePart") then
		center = targetFloor.Position
	end

	if center then
		-- Teletransportar aleatoriamente dentro de la arena
		local ARENA_RADIUS = 15 
		local SPAWN_HEIGHT = 5

		local angle = math.random() * 2 * math.pi
		local offsetX = math.cos(angle) * (math.random() * ARENA_RADIUS)
		local offsetZ = math.sin(angle) * (math.random() * ARENA_RADIUS)

		local arenaSpawnPos = Vector3.new(center.X + offsetX, center.Y + SPAWN_HEIGHT, center.Z + offsetZ)

		character:SetPrimaryPartCFrame(CFrame.new(arenaSpawnPos))
		UpdateStatus:FireClient(player, "?? " .. (zoneConfig.Name or zoneID))
		print(player.Name .. " viajó a " .. zoneID)
	end
end

-- ===================================================
-- TELEPORTE AL LOBBY (Usada por el botón de Retirada)
-- ===================================================
function module.teleportToLobby(player)
	if not EnemyHandler then
		EnemyHandler = require(ServerScriptService.Modules.EnemyHandler)
	end

	local character = player.Character
	if character then
		local lobbySpawnPos = LobbyFloor.Position + Vector3.new(0, 5, 0)
		character:SetPrimaryPartCFrame(CFrame.new(lobbySpawnPos))
		UpdateStatus:FireClient(player, LOBBY_MESSAGE)
	end
end

-- ===================================================
-- CONEXIONES
-- ===================================================

-- Solo mantenemos la retirada, ya que la entrada ahora es por toque físico
RetreatToLobby.OnServerEvent:Connect(function(player)
	module.teleportToLobby(player) 
end)

return module