-- Script: PetManager (FINAL - MODO GACHA)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Conexión a Data Compartida
local PetData = require(ReplicatedStorage.Shared.Data.PetData)

local PetManager = {}

PetManager.EGG_COST = 500 
PetManager.PetConfig = PetData 

-- Función interna para recalcular stats
local function recalculateMultiplier(player)
	local upgrades = player:FindFirstChild("Upgrades")
	if not upgrades then return end

	local equippedPetName = upgrades:FindFirstChild("EquippedPet").Value
	local coinMultiplierStat = upgrades:FindFirstChild("CoinMultiplier")

	local totalMultiplier = 1.0

	if equippedPetName ~= "" and PetManager.PetConfig[equippedPetName] then
		local petMult = PetManager.PetConfig[equippedPetName].Multiplier
		totalMultiplier = totalMultiplier + (petMult - 1.0)
	end

	if coinMultiplierStat then
		coinMultiplierStat.Value = totalMultiplier
	end
end

function PetManager.isPetEquipped(player, petName)
	local upgrades = player:FindFirstChild("Upgrades")
	local equippedVal = upgrades and upgrades:FindFirstChild("EquippedPet")
	return equippedVal and equippedVal.Value == petName
end

function PetManager.equipPet(player, petName)
	local petInventory = player:FindFirstChild("PetInventory")
	local upgrades = player:FindFirstChild("Upgrades")

	if not petInventory or not upgrades then return false end
	if not petInventory:FindFirstChild(petName) then return false end

	local equippedVal = upgrades:FindFirstChild("EquippedPet")
	equippedVal.Value = petName 

	recalculateMultiplier(player)
	return true
end

function PetManager.unequipPet(player, petName)
	local upgrades = player:FindFirstChild("Upgrades")
	if not upgrades then return false end

	local equippedVal = upgrades:FindFirstChild("EquippedPet")

	if equippedVal.Value == petName then
		equippedVal.Value = "" 
		recalculateMultiplier(player)
		return true
	end
	return false
end

-- FUNCIÓN PRINCIPAL DE COMPRA
-- En PetManager.lua

-- Nueva constante (puedes ponerla arriba con EGG_COST)
PetManager.DUPLICATE_REFUND = 150 -- Cuánto devuelves si sale repetida

function PetManager.requestIncubation(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local petInventory = player:FindFirstChild("PetInventory")

	if not (leaderstats and petInventory) then return false end
	local bonkCoins = leaderstats:FindFirstChild("BonkCoin")

	if bonkCoins.Value < PetManager.EGG_COST then
		return false, "Faltan Monedas"
	end

	-- 1. COBRAR (Primero cobramos el precio completo)
	bonkCoins.Value = bonkCoins.Value - PetManager.EGG_COST

	-- 2. SORTEO
	local roll = math.random()
	local cumulativeChance = 0
	local chosenPet = "CommonRabbit"
	local chosenData = nil

	for petName, data in pairs(PetManager.PetConfig) do
		local chance = data.Chance or 0.1 
		cumulativeChance = cumulativeChance + chance
		if roll <= cumulativeChance then
			chosenPet = petName
			chosenData = data
			break
		end
	end
	if not chosenData then chosenData = PetManager.PetConfig[chosenPet] end

	-- 3. VERIFICAR DUPLICADO
	local isDuplicate = false
	local refundAmount = 0

	if petInventory:FindFirstChild(chosenPet) then
		-- ¡YA LA TIENE! -> REEMBOLSO
		isDuplicate = true
		refundAmount = PetManager.DUPLICATE_REFUND

		-- Devolver dinero
		bonkCoins.Value = bonkCoins.Value + refundAmount
		print(player.Name .. " sacó duplicado: " .. chosenPet .. ". Reembolso: " .. refundAmount)
	else
		-- ¡ES NUEVA! -> CREAR
		local petValue = Instance.new("NumberValue") 
		petValue.Name = chosenPet
		petValue.Value = chosenData.Multiplier or 1
		petValue.Parent = petInventory

		-- Auto-equipar si no tiene nada
		local upgrades = player:FindFirstChild("Upgrades")
		if upgrades and upgrades.EquippedPet.Value == "" then
			PetManager.equipPet(player, chosenPet)
		end
	end

	-- 4. DEVOLVER MÁS DATOS
	-- Ahora devolvemos 3 cosas: Exito (true), Nombre, EsDuplicado, MontoReembolso
	return true, chosenPet, isDuplicate, refundAmount
end

return PetManager