-- Script: PetHubOpenerScript (VERSION 1 - Abre la GUI del Hub)

local Part = script.Parent 
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Evento creado manualmente en ReplicatedStorage
local OpenPetHub = ReplicatedStorage:WaitForChild("OpenPetHub") 

local COOLDOWN_TIME = 1 -- Cooldown para evitar múltiples aperturas
local isInteracting = false

local function onPartTouched(otherPart)
	local character = otherPart.Parent
	local player = Players:GetPlayerFromCharacter(character)

	if player and not isInteracting then
		isInteracting = true 

		-- Disparar el evento al cliente para abrir la GUI
		OpenPetHub:FireClient(player)

		print(player.Name .. " ha tocado el Hub de Mascotas.")

		-- Restablecer el cooldown
		task.wait(COOLDOWN_TIME)
		isInteracting = false
	end
end

Part.Touched:Connect(onPartTouched)