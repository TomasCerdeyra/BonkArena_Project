-- Script: PetManager (VERSION 12 - Retraso Forzado para Estabilizar Spawn)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService") 
local PetManager = {}

-- Constantes de Costo y Recompensa
PetManager.EGG_COST = 500 

-- Configuración de las mascotas disponibles y sus probabilidades
PetManager.PetConfig = {
	-- Mascotas NO animadas (deben tener un ModelId correcto en ReplicatedStorage)
	["CommonRabbit"] = { Multiplier = 1.05, Chance = 0, ModelId = "CommonRabbit", AnimationId = "" }, 
	["RareWolf"] = { Multiplier = 1.15, Chance = 0, ModelId = "RareWolf", AnimationId = "" },
	["EpicDragon"] = { Multiplier = 1.30, Chance = 0, ModelId = "EpicDragon", AnimationId = "" }, 

	-- ¡TU MASCOTA ANIMADA! (Usando tu Asset ID)
	-- NOTA: Asegúrate de que el ModelId ("TortugaConAlas") coincide con el nombre del modelo en ReplicatedStorage
	--       y que "TortugaConAlas" sea el nombre del NumberValue en el PetInventory.
	["TortugaConAlas"] = { 
		Multiplier = 2.05, -- Ejemplo de multiplicador, ajústalo según necesites
		Chance = 0.05, 
		ModelId = "TortugaConAlas", 
		AnimationId = "rbxassetid://120306152637743" 
	},
	["Pulpo"] = { 
		Multiplier = 0.05, -- Ejemplo de multiplicador, ajústalo según necesites
		Chance = 0, 
		ModelId = "Pulpo", 
		AnimationId = "" 
	},
	["Hada"] = { 
		Multiplier = 0.05, -- Ejemplo de multiplicador, ajústalo según necesites
		Chance = 10, 
		ModelId = "Hada", 
		AnimationId = "" 
	},
	
}
PetManager.MAX_EQUIPPED_PETS = 1

local equippedPets = {}
local petModels = {}    
local playerInitialized = {} 

-- Constante de Seguimiento
local FOLLOW_DISTANCE = 6    
local FOLLOW_HEIGHT = 1      
local FOLLOW_SPEED = 0.2     
local INITIAL_SPAWN_DELAY = 1 -- ¡NUEVO! 3 segundos de espera después de cargar el personaje

-- =======================================================
-- MÓDULOS DE SOPORTE (DECLARACIÓN ADELANTADA PARA ÁMBITO)
-- =======================================================

local spawnPetModel 
local despawnPetModel
local getRandomPet
local recalculateMultiplier

-- =======================================================
-- FUNCIÓN: Bucle Heartbeat para Mover Mascotas (Sin Cambios)
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
-- IMPLEMENTACIÓN DE MÓDULOS DE SOPORTE (Asignación de Cuerpos)
-- =======================================================

spawnPetModel = function(player, petName)
	-- OBTENER DATA DE CONFIGURACIÓN
	local petData = PetManager.PetConfig[petName] 
	local petModelTemplate = ReplicatedStorage:FindFirstChild(petData.ModelId) -- Usar ModelId

	if not petModelTemplate or not petData then
		warn("PetManager: Modelo o configuración de mascota '" .. petName .. "' no encontrado. ModelId: " .. tostring(petData and petData.ModelId))
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

	-- ******************************************************
	-- CÓDIGO DE ANIMACIÓN ESCALABLE
	-- ******************************************************
	local animId = petData.AnimationId

	if animId and animId ~= "" then 
		local animator = petModel:FindFirstChildOfClass("AnimationController")
		if animator then
			local animation = Instance.new("Animation")
			animation.AnimationId = animId -- Usa el ID ESPECÍFICO de la configuración

			local loader = animator:FindFirstChildOfClass("Animator")
			if not loader then
				loader = Instance.new("Animator")
				loader.Parent = animator
			end

			-- ******************************************************
			-- NOTA: Usamos el nombre del Asset para el rastreo en el despawn
			-- ******************************************************
			local trackName = animId:gsub("rbxassetid://", "Anim_")

			local track = loader:LoadAnimation(animation)
			track.Name = trackName 
			track.Looped = true
			track:Play()
		else
			warn("PetManager: Mascota animada '" .. petName .. "' no tiene AnimationController.")
		end
	end
	-- ******************************************************

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
-- 3. GESTIÓN DEL EQUIPAMIENTO (Funciones de Módulo)
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

	if not petValue then return false, "Mascota no poseída." end

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
-- 4. FUNCIÓN PROCESAR INCUBACIÓN/COMPRA
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
		return true, string.format("¡Felicidades! Obtuviste %s (x%.2f). Equipada.", petName, petMultiplier)
	else
		return true, string.format("¡Felicidades! Obtuviste %s (x%.2f). Añadida a tu inventario.", petName, petMultiplier)
	end
end

-- =======================================================
-- INICIALIZACIÓN (SOLUCIÓN DE SINCRONIZACIÓN DEFINITIVA)
-- =======================================================

-- Función que se ejecuta cuando el personaje aparece o reaparece
local function onCharacterLoaded(character, player)
	-- Solo inicializamos la mascota la PRIMERA vez que el jugador entra al juego.
	if not playerInitialized[player] then

		-- Usamos task.spawn para no bloquear el CharacterAdded si la carga de datos es lenta
		task.spawn(function()

			-- ¡CRÍTICO!: Esperamos 3 segundos después de que el personaje aparece para asegurar estabilidad.
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

-- Conexión de PlayerAdded para configurar la conexión del personaje
Players.PlayerAdded:Connect(function(player)
	-- Inicializar la tabla de rastreo al unirse (necesario para equipar la primera mascota)
	if not equippedPets[player] then equippedPets[player] = {} end 

	-- Conectar a CharacterAdded: Esto asegura que el personaje esté cargado antes de spawnear.
	player.CharacterAdded:Connect(function(character)
		onCharacterLoaded(character, player)
	end)

	-- Manejar el caso de re-conexión o Studio testing (si el personaje ya existe)
	if player.Character then
		onCharacterLoaded(player.Character, player)
	end
end)


-- =======================================================
-- INICIALIZACIÓN DEL MOVIMIENTO
-- =======================================================
RunService.Heartbeat:Connect(updatePetMovement) 

return PetManager