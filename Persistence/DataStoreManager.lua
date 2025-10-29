-- Script: DataStoreManager (VERSION 1 - Centralizando DataStore Logic)

local DataStoreService = game:GetService("DataStoreService")

-- Definición de las DataStores usadas en el juego
local PLAYER_DATA_STORE = DataStoreService:GetDataStore("PlayerData_V1") 
local PET_INVENTORY_STORE = DataStoreService:GetDataStore("PetInventory_V1") 

local DataStoreManager = {}

-- =======================================================
-- 1. CARGA DE DATOS (Recuperar la información guardada)
-- =======================================================
function DataStoreManager.loadData(player)
	local userId = player.UserId
	local results = {}
	local success = true
	local errors = {}

	-- Cargar datos principales del jugador
	local success1, data1 = pcall(function()
		return PLAYER_DATA_STORE:GetAsync(userId)
	end)
	if success1 then
		results.PlayerData = data1
	else
		success = false
		errors.PlayerData = data1
		warn("DataStore Error: Failed to load PlayerData for " .. player.Name .. ": " .. data1)
	end

	-- Cargar inventario de mascotas
	local success2, data2 = pcall(function()
		return PET_INVENTORY_STORE:GetAsync(userId)
	end)
	if success2 then
		results.PetData = data2
	else
		success = false
		errors.PetData = data2
		warn("DataStore Error: Failed to load PetInventory for " .. player.Name .. ": " .. data2)
	end

	return success, results, errors
end

-- =======================================================
-- 2. GUARDADO DE DATOS (Recopilar la información del objeto Player y guardar)
-- =======================================================
function DataStoreManager.saveData(player)
	local userId = player.UserId
	local success = true

	local leaderstats = player:FindFirstChild("leaderstats")
	local upgrades = player:FindFirstChild("Upgrades")
	local petInventory = player:FindFirstChild("PetInventory")

	if not (leaderstats and upgrades and petInventory) then 
		warn("DataStore Error: Missing data folders for saving player " .. player.Name)
		return false
	end

	-- Recopilación de PlayerData (BonkCoins, Nivel, Upgrades)
	local playerDataToSave = {
		BonkCoin = leaderstats.BonkCoin.Value,
		FireRateLevel = upgrades.FireRateLevel.Value,
		CriticalChanceLevel = upgrades.CriticalChanceLevel.Value, 
		Level = upgrades.Level.Value, 
		XP = upgrades.XP.Value        
	}

	-- Recopilación de PetInventory
	local petsToSave = {}
	for _, petValue in ipairs(petInventory:GetChildren()) do
		-- Guardamos el nombre y el multiplicador de la mascota
		petsToSave[petValue.Name] = petValue.Value
	end

	-- ----------------------------------------------------
	-- Ejecutar Guardado
	-- ----------------------------------------------------
	local success1, err1 = pcall(function()
		PLAYER_DATA_STORE:SetAsync(userId, playerDataToSave)
	end)
	if not success1 then
		success = false
		warn("DataStore Error: Failed to save PlayerData for " .. player.Name .. ": " .. err1)
	end

	local success2, err2 = pcall(function()
		PET_INVENTORY_STORE:SetAsync(userId, petsToSave)
	end)
	if not success2 then
		success = false
		warn("DataStore Error: Failed to save PetInventory for " .. player.Name .. ": " .. err2)
	end

	return success
end


return DataStoreManager