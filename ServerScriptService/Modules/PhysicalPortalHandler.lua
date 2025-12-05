-- Script: PhysicalPortalHandler (VERSIÓN PARA TU ESTRUCTURA ACTUAL)
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local TeleportHandler = require(ServerScriptService.Modules.TeleportHandler)
local ZoneData = require(ReplicatedStorage.Shared.Data.ZoneData)

-- Referencia a tu carpeta (PortalZone > Porltals)
local PortalsFolder = Workspace:WaitForChild("PortalZone"):WaitForChild("Portals") 

local COOLDOWN = 2
local activePortals = {} 

local function setupPortal(portalPart)
	-- 1. Verificamos que sea una Parte (tu estructura)
	if not portalPart:IsA("BasePart") then return end

	-- 2. Buscamos el ID que acabas de crear adentro
	local zoneIdValue = portalPart:FindFirstChild("ZoneID")

	if not zoneIdValue then
		warn("?? El portal '" .. portalPart.Name .. "' no tiene el StringValue 'ZoneID'.")
		return
	end

	local zoneID = zoneIdValue.Value
	local zoneInfo = ZoneData[zoneID]

	-- Validación de seguridad
	if not zoneInfo then
		warn("? Error: El ID '" .. tostring(zoneID) .. "' puesto en " .. portalPart.Name .. " no existe en tu archivo ZoneData.")
		return
	end

	-- 3. Conectar el toque
	portalPart.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then return end

		if activePortals[player.UserId] then return end
		activePortals[player.UserId] = true

		print("?? " .. player.Name .. " viaja a: " .. (zoneInfo.Name or zoneID))

		-- Usamos tu TeleportHandler existente
		TeleportHandler.teleportToZone(player, zoneID)

		task.wait(COOLDOWN)
		activePortals[player.UserId] = nil
	end)
end

-- Inicializar
for _, child in ipairs(PortalsFolder:GetChildren()) do
	setupPortal(child)
end