-- Script: StaffHubOpenerScript (VERSION 3 - Enviando Configuración de Báculos al Cliente)

local Part = script.Parent 
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Evento creado manualmente en ReplicatedStorage
local OpenStaffShop = ReplicatedStorage:WaitForChild("OpenStaffShop") 

-- Módulo de Báculos
local StaffManager = require(ServerScriptService.Modules.StaffManager)

local COOLDOWN_TIME = 1 
local isInteracting = false

local function onPartTouched(otherPart)
	local character = otherPart.Parent
	local player = Players:GetPlayerFromCharacter(character)

	if player and not isInteracting then
		isInteracting = true 

		-- Disparar el evento al cliente para abrir la GUI
		-- NUEVO: Enviamos la tabla de configuración de báculos al cliente
		OpenStaffShop:FireClient(player, StaffManager.STAFFS)

		print(player.Name .. " ha tocado el Hub de Báculos.")

		-- Restablecer el cooldown
		task.wait(COOLDOWN_TIME)
		isInteracting = false
	end
end

Part.Touched:Connect(onPartTouched)