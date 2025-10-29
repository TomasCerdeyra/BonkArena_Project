-- Script: PlayerStats (VERSION 11 - Refactorizado: Inicializador de Jugadores)

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreManager = require(ServerScriptService.Persistence.DataStoreManager) -- Módulo central de persistencia

-- Función auxiliar para la creación de todas las estructuras necesarias
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

	local fireRateLevel = Instance.new("IntValue")
	fireRateLevel.Name = "FireRateLevel"
	fireRateLevel.Parent = upgrades

	local criticalChanceLevel = Instance.new("IntValue")
	criticalChanceLevel.Name = "CriticalChanceLevel"
	criticalChanceLevel.Parent = upgrades

	local playerLevel = Instance.new("IntValue")
	playerLevel.Name = "Level"
	playerLevel.Parent = upgrades

	local playerXP = Instance.new("IntValue")
	playerXP.Name = "XP"
	playerXP.Parent = upgrades

	local coinMultiplierStat = Instance.new("NumberValue")
	coinMultiplierStat.Name = "CoinMultiplier"
	coinMultiplierStat.Parent = upgrades

	-- Carpeta para almacenar el inventario de mascotas (datos)
	local petInventory = Instance.new("Folder")
	petInventory.Name = "PetInventory"
	petInventory.Parent = player
end

local function onPlayerAdded(player)
	-- 1. Crear estructuras antes de cargar
	initializeStats(player) 

	-- 2. Delegar la carga de datos
	local success, loadedData = DataStoreManager.loadData(player)

	local upgrades = player:FindFirstChild("Upgrades")
	local petInventory = player:FindFirstChild("PetInventory")

	if success and loadedData.PlayerData then
		local data = loadedData.PlayerData

		-- Cargar PlayerData
		player.leaderstats.BonkCoin.Value = data.BonkCoin or 0
		upgrades.FireRateLevel.Value = data.FireRateLevel or 1
		upgrades.CriticalChanceLevel.Value = data.CriticalChanceLevel or 1
		upgrades.Level.Value = data.Level or 1 
		upgrades.XP.Value = data.XP or 0
		upgrades.CoinMultiplier.Value = 1.0 

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

	else
		-- Inicializar valores por defecto si la carga falla o es la primera vez
		player.leaderstats.BonkCoin.Value = 0
		upgrades.FireRateLevel.Value = 1
		upgrades.CriticalChanceLevel.Value = 1
		upgrades.Level.Value = 1
		upgrades.XP.Value = 0
		upgrades.CoinMultiplier.Value = 1.0

		print("Creando nuevos datos/valores por defecto para " .. player.Name)
	end
end

local function onPlayerRemoving(player)
	-- Delegar el guardado de datos
	DataStoreManager.saveData(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)