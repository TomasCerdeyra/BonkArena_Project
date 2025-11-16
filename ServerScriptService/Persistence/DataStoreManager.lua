-- Script: DataStoreManager (VERSION 2 - Limpieza de Cadencia/Crítico y Añadir Báculos)

local DataStoreService = game:GetService("DataStoreService")

-- Definición de las DataStores usadas en el juego
local PLAYER_DATA_STORE = DataStoreService:GetDataStore("PlayerData_V1") 
local PET_INVENTORY_STORE = DataStoreService:GetDataStore("PetInventory_V1") 
local STAFF_INVENTORY_STORE = DataStoreService:GetDataStore("StaffInventory_V1") -- NUEVO

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

	-- NUEVO: Cargar inventario de báculos
	local success3, data3 = pcall(function()
		return STAFF_INVENTORY_STORE:GetAsync(userId)
	end)
	if success3 then
		results.StaffData = data3
	else
		success = false
		errors.StaffData = data3
		warn("DataStore Error: Failed to load StaffInventory for " .. player.Name .. ": " .. data3)
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
	local staffInventory = player:FindFirstChild("StaffInventory") -- NUEVO

	if not (leaderstats and upgrades and petInventory and staffInventory) then 
		warn("DataStore Error: Missing data folders for saving player " .. player.Name)
		return false
	end

	-- Recopilación de PlayerData (BonkCoins, Nivel, Upgrades)
	local playerDataToSave = {
		BonkCoin = leaderstats.BonkCoin.Value,
		-- FireRateLevel ELIMINADO
		-- CriticalChanceLevel ELIMINADO
		Level = upgrades.Level.Value, 
		XP = upgrades.XP.Value,
		EquippedStaff = upgrades.EquippedStaff.Value, -- NUEVO
		EquippedPet = upgrades.EquippedPet.Value
	}

	-- Recopilación de PetInventory
	local petsToSave = {}
	for _, petValue in ipairs(petInventory:GetChildren()) do
		petsToSave[petValue.Name] = petValue.Value
	end

	-- NUEVO: Recopilación de StaffInventory
	local staffsToSave = {}
	for _, staffValue in ipairs(staffInventory:GetChildren()) do
		staffsToSave[staffValue.Name] = staffValue.Value -- Guardamos true/false
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

	-- NUEVO: Guardar Báculos
	local success3, err3 = pcall(function()
		STAFF_INVENTORY_STORE:SetAsync(userId, staffsToSave)
	end)
	if not success3 then
		success = false
		warn("DataStore Error: Failed to save StaffInventory for " .. player.Name .. ": " .. err3)
	end

	return success
end


return DataStoreManager