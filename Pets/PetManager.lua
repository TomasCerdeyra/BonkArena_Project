-- Script: PetManager (VERSION 12 - Retraso Forzado para Estabilizar Spawn)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService") 
local PetManager = {}

-- Constantes de Costo y Recompensa
PetManager.EGG_COST = 500 

-- Configuraci�n de las mascotas disponibles y sus probabilidades
PetManager.PetConfig = {
	["CommonRabbit"] = { Multiplier = 1.05, Chance = 0.60, ModelId = "rbxassetid://CommonRabbitId" }, 
	["RareWolf"] =     { Multiplier = 1.15, Chance = 0.30, ModelId = "rbxassetid://RareWolfId" },     
	["EpicDragon"] =   { Multiplier = 1.30, Chance = 0.10, ModelId = "rbxassetid://EpicDragonId" },   
}
PetManager.MAX_EQUIPPED_PETS = 1

local equippedPets = {}
local petModels = {}    
local playerInitialized = {} 

-- Constante de Seguimiento
local FOLLOW_DISTANCE = 6    
local FOLLOW_HEIGHT = 1      
local FOLLOW_SPEED = 0.2     
local INITIAL_SPAWN_DELAY = 1 -- �NUEVO! 3 segundos de espera despu�s de cargar el personaje

-- =======================================================
-- M�DULOS DE SOPORTE (DECLARACI�N ADELANTADA PARA �MBITO)
-- =======================================================

local spawnPetModel 
local despawnPetModel
local getRandomPet
local recalculateMultiplier

-- =======================================================
-- FUNCI�N: Bucle Heartbeat para Mover Mascotas (Sin Cambios)
-- =======================================================
local function updatePetMovement()
	for player, petModel in pairs(petModels) do
		local character = player.Character
		if petModel and petModel.PrimaryPart and character then
			local root = character:FindFirstChild("HumanoidRootPart")

			if root then
				local currentCFrame = petModel.PrimaryPart.CFrame

				local targetCFrame = root.CFrame * CFrame.new(0, FOLLOW_HEIGHT, FOLLOW_DISTANCE)

				local newCFrame = currentCFrame:Lerp(targetCFrame, FOLLOW_SPEED)

				petModel:SetPrimaryPartCFrame(newCFrame)
			else
				despawnPetModel(player) 
			end
		else
			despawnPetModel(player)
		end
	end
end

-- =======================================================
-- IMPLEMENTACI�N DE M�DULOS DE SOPORTE (Asignaci�n de Cuerpos)
-- =======================================================

spawnPetModel = function(player, petName) 
	local petModelTemplate = ReplicatedStorage:FindFirstChild(petName)

	if not petModelTemplate then
		warn("PetManager: Modelo de mascota '" .. petName .. "' no encontrado en ReplicatedStorage.")
		return 
	end

	despawnPetModel(player)

	local petModel = petModelTemplate:Clone()
	petModel.Parent = Workspace

	if not petModel.PrimaryPart then 
		warn("PetManager: Modelo de mascota '" .. petName .. "' no tiene PrimaryPart asignada.")
		petModel:Destroy()
		return 
	end

	petModel.PrimaryPart.Anchored = true

	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		local root = character.HumanoidRootPart
		petModel:SetPrimaryPartCFrame(root.CFrame * CFrame.new(0, FOLLOW_HEIGHT, FOLLOW_DISTANCE)) 
	end

	petModels[player] = petModel
end

despawnPetModel = function(player)
	if petModels[player] then
		petModels[player]:Destroy()
		petModels[player] = nil
	end
end

recalculateMultiplier = function(player)
	local totalMultiplier = 1.0

	local equippedList = equippedPets[player]
	if equippedList then
		for _, petValue in ipairs(equippedList) do
			totalMultiplier = totalMultiplier + (petValue.Value - 1.0) 
		end
	end

	local upgrades = player:FindFirstChild("Upgrades")
	local coinMultiplierStat = upgrades and upgrades:FindFirstChild("CoinMultiplier")

	if coinMultiplierStat then
		coinMultiplierStat.Value = totalMultiplier
	end
end

getRandomPet = function()
	local roll = math.random()
	local cumulativeChance = 0

	for petName, config in pairs(PetManager.PetConfig) do
		cumulativeChance = cumulativeChance + config.Chance
		if roll <= cumulativeChance then
			return petName, config.Multiplier
		end
	end
	return "CommonRabbit", PetManager.PetConfig.CommonRabbit.Multiplier
end

-- =======================================================
-- 3. GESTI�N DEL EQUIPAMIENTO (Funciones de M�dulo)
-- =======================================================

function PetManager.isPetEquipped(player, petName)
	local equippedList = equippedPets[player]
	if equippedList and equippedList[1] then
		return equippedList[1].Name == petName
	end
	return false
end

function PetManager.getEquippedPet(player)
	local equippedList = equippedPets[player]
	if equippedList and equippedList[1] then
		return equippedList[1].Name
	end
	return nil
end


function PetManager.equipPet(player, petName)
	local petInventory = player:FindFirstChild("PetInventory")
	local petValue = petInventory and petInventory:FindFirstChild(petName)

	if not petValue then return false, "Mascota no pose�da." end

	if not equippedPets[player] then equippedPets[player] = {} end 

	if #equippedPets[player] > 0 then
		PetManager.unequipPet(player, equippedPets[player][1].Name) 
	end

	equippedPets[player] = { petValue }

	recalculateMultiplier(player)

	spawnPetModel(player, petName) 

	print(player.Name .. " ha equipado " .. petName .. ". Multiplicador total: " .. string.format("%.2f", petValue.Value))
	return true
end

function PetManager.unequipPet(player, petName)
	local equippedList = equippedPets[player]
	if not equippedList then return end

	for i, petValue in ipairs(equippedList) do
		if petValue.Name == petName then
			table.remove(equippedList, i)
			recalculateMultiplier(player)

			despawnPetModel(player)

			print(player.Name .. " ha desequipado " .. petName)
			return true
		end
	end
	return false
end

-- =======================================================
-- 4. FUNCI�N PROCESAR INCUBACI�N/COMPRA
-- =======================================================

function PetManager.requestIncubation(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local petInventory = player:FindFirstChild("PetInventory")

	if not (leaderstats and petInventory) then return false, "Error: Estructuras de jugador no cargadas." end
	local bonkCoins = leaderstats:FindFirstChild("BonkCoin")

	if bonkCoins.Value < PetManager.EGG_COST then
		return false, "No tienes suficientes BonkCoins para incubar un huevo."
	end

	bonkCoins.Value = bonkCoins.Value - PetManager.EGG_COST

	local petName, petMultiplier = getRandomPet()

	local petValue = Instance.new("NumberValue") 
	petValue.Name = petName
	petValue.Value = petMultiplier 
	petValue.Parent = petInventory

	if PetManager.getEquippedPet(player) == nil then
		PetManager.equipPet(player, petName)
		return true, string.format("�Felicidades! Obtuviste %s (x%.2f). Equipada.", petName, petMultiplier)
	else
		return true, string.format("�Felicidades! Obtuviste %s (x%.2f). A�adida a tu inventario.", petName, petMultiplier)
	end
end

-- =======================================================
-- INICIALIZACI�N (SOLUCI�N DE SINCRONIZACI�N DEFINITIVA)
-- =======================================================

-- Funci�n que se ejecuta cuando el personaje aparece o reaparece
local function onCharacterLoaded(character, player)
	-- Solo inicializamos la mascota la PRIMERA vez que el jugador entra al juego.
	if not playerInitialized[player] then

		-- Usamos task.spawn para no bloquear el CharacterAdded si la carga de datos es lenta
		task.spawn(function()

			-- �CR�TICO!: Esperamos 3 segundos despu�s de que el personaje aparece para asegurar estabilidad.
			task.wait(INITIAL_SPAWN_DELAY) 

			local petInventory = player:WaitForChild("PetInventory")

			-- Si hay mascotas, equipamos la primera para que el modelo aparezca.
			if #petInventory:GetChildren() > 0 then
				PetManager.equipPet(player, petInventory:GetChildren()[1].Name) 
			end

			playerInitialized[player] = true -- Marcar como inicializado
		end)
	end
end

-- Conexi�n de PlayerAdded para configurar la conexi�n del personaje
Players.PlayerAdded:Connect(function(player)
	-- Inicializar la tabla de rastreo al unirse (necesario para equipar la primera mascota)
	if not equippedPets[player] then equippedPets[player] = {} end 

	-- Conectar a CharacterAdded: Esto asegura que el personaje est� cargado antes de spawnear.
	player.CharacterAdded:Connect(function(character)
		onCharacterLoaded(character, player)
	end)

	-- Manejar el caso de re-conexi�n o Studio testing (si el personaje ya existe)
	if player.Character then
		onCharacterLoaded(player.Character, player)
	end
end)


-- =======================================================
-- INICIALIZACI�N DEL MOVIMIENTO
-- =======================================================
RunService.Heartbeat:Connect(updatePetMovement) 

return PetManager