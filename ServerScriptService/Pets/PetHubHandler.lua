-- Script: PetHubHandler (MODO GACHA)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Módulos
local PetManager = require(ServerScriptService.Pets.PetManager)
local PetData = require(ReplicatedStorage.Shared.Data.PetData)

-- Red
local Network = ReplicatedStorage:WaitForChild("Network")
local RequestIncubation = Network:WaitForChild("RequestIncubation")
local RequestEquipPet = Network:WaitForChild("RequestEquipPet")
local UpdateStatus = Network:WaitForChild("UpdateStatus")

-- =================================================================
-- 1. INCUBACIÓN (Ahora devuelve datos al cliente)
-- =================================================================
RequestIncubation.OnServerInvoke = function(player)
	-- Recibimos los 4 valores nuevos del manager
	local success, petName, isDuplicate, refundAmount = PetManager.requestIncubation(player)

	if success then
		local petInfo = PetData[petName]

		return {
			Success = true,
			PetName = petName,
			Rarity = petInfo.Rarity or "Común",
			Image = petInfo.Image,

			-- Datos nuevos para la UI
			IsDuplicate = isDuplicate,
			RefundAmount = refundAmount
		}
	else
		return {
			Success = false,
			Message = petName -- En caso de error, el 2do valor es el mensaje
		}
	end
end

-- =================================================================
-- 2. EQUIPAR (Sigue siendo Evento normal)
-- =================================================================
RequestEquipPet.OnServerEvent:Connect(function(player, petName)
	if PetManager.isPetEquipped(player, petName) then
		PetManager.unequipPet(player, petName)
	else
		PetManager.equipPet(player, petName)
	end
end)

return {}