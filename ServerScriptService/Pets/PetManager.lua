-- Script: PetManager (VERSION OPTIMIZADA - Solo Datos)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PetManager = {}

-- Constantes
PetManager.EGG_COST = 500 

-- Configuración (Compartida con cliente idealmente, pero por ahora aquí)
PetManager.PetConfig = {
	["CommonRabbit"] = { Multiplier = 1.05, Chance = 0.50 }, 
	["RareWolf"] = { Multiplier = 1.15, Chance = 0.30 },
	["EpicDragon"] = { Multiplier = 1.30, Chance = 0.15 }, 
	["TortugaConAlas"] = { Multiplier = 2.05, Chance = 0.05 },
	["Pulpo"] = { Multiplier = 0.05, Chance = 0 },
	["Hada"] = { Multiplier = 0.05, Chance = 0 },
}

-- =======================================================
-- LÓGICA DE MULTIPLICADORES
-- =======================================================
local function recalculateMultiplier(player)
	local upgrades = player:FindFirstChild("Upgrades")
	if not upgrades then return end

	local equippedPetName = upgrades:FindFirstChild("EquippedPet").Value
	local coinMultiplierStat = upgrades:FindFirstChild("CoinMultiplier")

	local totalMultiplier = 1.0

	if equippedPetName ~= "" and PetManager.PetConfig[equippedPetName] then
		-- Restamos 1.0 porque la base es 1.0 (ej: 1.05 -> aporta +0.05)
		local petMult = PetManager.PetConfig[equippedPetName].Multiplier
		totalMultiplier = totalMultiplier + (petMult - 1.0)
	end

	if coinMultiplierStat then
		coinMultiplierStat.Value = totalMultiplier
	end
end

-- =======================================================
-- GESTIÓN PÚBLICA (Equipar/Desequipar)
-- =======================================================
function PetManager.isPetEquipped(player, petName)
	local upgrades = player:FindFirstChild("Upgrades")
	local equippedVal = upgrades and upgrades:FindFirstChild("EquippedPet")
	return equippedVal and equippedVal.Value == petName
end

function PetManager.equipPet(player, petName)
	local petInventory = player:FindFirstChild("PetInventory")
	local upgrades = player:FindFirstChild("Upgrades")

	if not petInventory or not upgrades then return false end

	-- Verificar si la tiene
	if not petInventory:FindFirstChild(petName) then return false end

	-- Actualizar valor replicado
	local equippedVal = upgrades:FindFirstChild("EquippedPet")
	equippedVal.Value = petName -- ¡Esto avisa al cliente automáticamente!

	recalculateMultiplier(player)
	print(player.Name .. " equipó " .. petName)
	return true
end

function PetManager.unequipPet(player, petName)
	local upgrades = player:FindFirstChild("Upgrades")
	if not upgrades then return false end

	local equippedVal = upgrades:FindFirstChild("EquippedPet")

	if equippedVal.Value == petName then
		equippedVal.Value = "" -- Desequipar
		recalculateMultiplier(player)
		print(player.Name .. " desequipó " .. petName)
		return true
	end
	return false
end

-- =======================================================
-- INCUBACIÓN
-- =======================================================
function PetManager.requestIncubation(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local petInventory = player:FindFirstChild("PetInventory")

	if not (leaderstats and petInventory) then return false end
	local bonkCoins = leaderstats:FindFirstChild("BonkCoin")

	if bonkCoins.Value < PetManager.EGG_COST then
		return false, "Faltan Monedas"
	end

	bonkCoins.Value = bonkCoins.Value - PetManager.EGG_COST

	-- Sistema de Probabilidad (Gacha)
	local roll = math.random()
	local cumulativeChance = 0
	local chosenPet = "CommonRabbit"
	local chosenData = PetManager.PetConfig["CommonRabbit"]

	for petName, data in pairs(PetManager.PetConfig) do
		if data.Chance > 0 then
			cumulativeChance = cumulativeChance + data.Chance
			if roll <= cumulativeChance then
				chosenPet = petName
				chosenData = data
				break
			end
		end
	end

	-- Dar mascota
	if not petInventory:FindFirstChild(chosenPet) then
		local petValue = Instance.new("NumberValue") 
		petValue.Name = chosenPet
		petValue.Value = chosenData.Multiplier
		petValue.Parent = petInventory
	end

	-- Auto-equipar si no tiene nada
	local upgrades = player:FindFirstChild("Upgrades")
	if upgrades and upgrades.EquippedPet.Value == "" then
		PetManager.equipPet(player, chosenPet)
	end

	return true, "¡Obtuviste " .. chosenPet .. "!"
end

return PetManager