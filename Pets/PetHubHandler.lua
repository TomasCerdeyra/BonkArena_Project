-- Script: PetHubHandler (VERSION 4 - Usando Funciones Seguras de PetManager)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetManager = require(game.ServerScriptService.Pets.PetManager)
local UpdateStatus = ReplicatedStorage:WaitForChild("UpdateStatus")

local RequestIncubation = ReplicatedStorage:WaitForChild("RequestIncubation")
local RequestEquipPet = ReplicatedStorage:WaitForChild("RequestEquipPet") 

local PetHubHandler = {}

-- 1. Manejo de Incubación (Compra)
RequestIncubation.OnServerEvent:Connect(function(player)
	local success, message = PetManager.requestIncubation(player)
	UpdateStatus:FireClient(player, message)
end)

-- 2. Manejo de Equipamiento/Desequipamiento (CORREGIDO)
RequestEquipPet.OnServerEvent:Connect(function(player, petName)
	local petInventory = player:FindFirstChild("PetInventory")
	if not petInventory then return end

	-- Usamos la función segura del PetManager para verificar el estado
	local isCurrentlyEquipped = PetManager.isPetEquipped(player, petName)

	if isCurrentlyEquipped then
		PetManager.unequipPet(player, petName)
		UpdateStatus:FireClient(player, petName .. " ha sido desequipada.")
	else
		PetManager.equipPet(player, petName)
		UpdateStatus:FireClient(player, petName .. " ha sido equipada.")
	end
end)

return PetHubHandler