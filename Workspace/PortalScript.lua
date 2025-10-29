-- Script: PortalScript (VERSION 2 - Abre GUI de Selección de Arena)

local Portal = script.Parent 
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- RemoteEvent que dispara al cliente para abrir la interfaz de selección.
local OpenArenaSelector = ReplicatedStorage:FindFirstChild("OpenArenaSelector")
if not OpenArenaSelector then
	OpenArenaSelector = Instance.new("RemoteEvent")
	OpenArenaSelector.Name = "OpenArenaSelector"
	OpenArenaSelector.Parent = ReplicatedStorage
end

-- Tiempo de enfriamiento para evitar doble toque
local COOLDOWN_TIME = 3
local isTeleporting = false

local function onPartTouched(otherPart)
	local character = otherPart.Parent
	local player = Players:GetPlayerFromCharacter(character)

	if player and not isTeleporting then
		isTeleporting = true -- Activar el cooldown

		-- 2. Disparar el evento al cliente para abrir la GUI
		OpenArenaSelector:FireClient(player)

		print(player.Name .. " ha tocado el portal. Abriendo selector de arenas.")

		-- 3. Restablecer el cooldown
		task.wait(COOLDOWN_TIME)
		isTeleporting = false
	end
end

Portal.Touched:Connect(onPartTouched)