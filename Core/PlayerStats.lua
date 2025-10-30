-- Script: PlayerStats (VERSION 13 - Añadiendo StaffInventory)

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreManager = require(ServerScriptService.Persistence.DataStoreManager) 

local function initializeStats(player)
	-- CREACIÓN DE ESTRUCTURAS BÁSICAS
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local bonkCoins = Instance.new("IntValue")
	bonkCoins.Name = "BonkCoin"
	bonkCoins.Parent = leaderstats

	local upgrades = Instance.new("Folder")
	upgrades.Name = "Upgrades"
	upgrades.Parent = player

	-- FireRateLevel y CriticalChanceLevel ELIMINADOS

	local playerLevel = Instance.new("IntValue")
	playerLevel.Name = "Level"
	playerLevel.Parent = upgrades

	local playerXP = Instance.new("IntValue")
	playerXP.Name = "XP"
	playerXP.Parent = upgrades

	local coinMultiplierStat = Instance.new("NumberValue")
	coinMultiplierStat.Name = "CoinMultiplier"
	coinMultiplierStat.Parent = upgrades

	-- Báculo Equipado
	local equippedStaff = Instance.new("StringValue")
	equippedStaff.Name = "EquippedStaff"
	equippedStaff.Value = "BasicStaff" -- Báculo inicial por defecto
	equippedStaff.Parent = upgrades

	-- Carpeta para almacenar el inventario de mascotas (datos)
	local petInventory = Instance.new("Folder")
	petInventory.Name = "PetInventory"
	petInventory.Parent = player

	-- NUEVO: Carpeta para el inventario de Báculos
	local staffInventory = Instance.new("Folder")
	staffInventory.Name = "StaffInventory"
	staffInventory.Parent = player
	-- Añadimos el Báculo Básico al inventario por defecto
	local basicStaffOwned = Instance.new("BoolValue")
	basicStaffOwned.Name = "BasicStaff"
	basicStaffOwned.Value = true
	basicStaffOwned.Parent = staffInventory
end

local function onPlayerAdded(player)
	-- 1. Crear estructuras antes de cargar
	initializeStats(player) 

	-- 2. Delegar la carga de datos
	local success, loadedData = DataStoreManager.loadData(player)

	local leaderstats = player:FindFirstChild("leaderstats")
	local upgrades = player:FindFirstChild("Upgrades")
	local petInventory = player:FindFirstChild("PetInventory")
	local staffInventory = player:FindFirstChild("StaffInventory") -- Referencia al nuevo inventario

	if success and loadedData.PlayerData then
		local data = loadedData.PlayerData

		if not (leaderstats and upgrades and petInventory and staffInventory) then 
			warn("PlayerStats: Faltan carpetas de datos para " .. player.Name)
			return 
		end

		-- Cargar PlayerData (Eliminando referencias antiguas)
		leaderstats.BonkCoin.Value = data.BonkCoin or 0
		-- ELIMINAMOS: FireRateLevel y CriticalChanceLevel
		upgrades.Level.Value = data.Level or 1 
		upgrades.XP.Value = data.XP or 0
		upgrades.CoinMultiplier.Value = data.CoinMultiplier or 1.0 
		upgrades.EquippedStaff.Value = data.EquippedStaff or "BasicStaff" -- NUEVO: Cargar báculo equipado

		print("PlayerData cargada para " .. player.Name)

		-- Cargar PetInventory
		local petData = loadedData.PetData
		if petData and type(petData) == "table" then
			for petName, petMultiplier in pairs(petData) do
				local petValue = Instance.new("NumberValue")
				petValue.Name = petName 
				petValue.Value = petMultiplier
				petValue.Parent = petInventory
			end
			print("Inventario de mascotas cargado para " .. player.Name)
		end

		-- Cargar StaffInventory (NUEVO)
		local staffData = loadedData.StaffData
		if staffData and type(staffData) == "table" then
			-- Solo recreamos los que no son el BasicStaff (ya creado si es la primera vez)
			for staffName, isOwned in pairs(staffData) do
				local staffOwned = staffInventory:FindFirstChild(staffName)
				if not staffOwned then
					staffOwned = Instance.new("BoolValue")
					staffOwned.Name = staffName
					staffOwned.Parent = staffInventory
				end
				staffOwned.Value = isOwned
			end
			print("Inventario de báculos cargado para " .. player.Name)
		end


	else
		-- Inicializar valores por defecto si la carga falla o es la primera vez
		leaderstats.BonkCoin.Value = 0
		-- ELIMINAMOS: FireRateLevel y CriticalChanceLevel
		upgrades.Level.Value = 1
		upgrades.XP.Value = 0
		upgrades.CoinMultiplier.Value = 1.0
		upgrades.EquippedStaff.Value = "BasicStaff"

		print("Creando nuevos datos/valores por defecto para " .. player.Name)
	end
end

local function onPlayerRemoving(player)
	-- Delegar el guardado de datos
	DataStoreManager.saveData(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)