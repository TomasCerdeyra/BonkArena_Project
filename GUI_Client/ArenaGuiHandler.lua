-- Script: ArenaGuiHandler (VERSION 7 - Corrección de Ámbito y Conexión Final)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

-- Declaración de variables (Inicializadas a nil, luego llenadas en initializeReferences)
local ArenaSelectionGui
local SelectionFrame
local ArenaListContainer
local CloseButton
local ArenaTemplate

local PetHubGui
local PetFrame
local PetCloseButton
local IncubatorButton
local PetListFrame
local PetItemTemplate

local playerLevel

-- RemoteEvents (Declaradas aquí para que initializeReferences las defina)
local OpenArenaSelector 
local RequestTeleport
local OpenPetHub
local RequestIncubation
local RequestEquipPet 


-- Datos de Configuración de Arenas (Orden Fijo para la Torre)
local ARENA_CONFIG_ORDERED = {
	{ ZoneName = "ArenaFloor", Name = "Piso 1: Arena Fácil", MinLevel = 1, Rewards = "x1 Coin" },
	{ ZoneName = "MediumArenaFloor", Name = "Piso 2: Arena Media", MinLevel = 5, Rewards = "x2 Coins" }, 
}


-- =======================================================
-- 1. FUNCIONES AUXILIARES DE CLIC (DEBEN DECLARARSE PRIMERO)
-- =======================================================

local function onIncubatorClicked()
	-- Dispara el evento al servidor para comprar el huevo
	RequestIncubation:FireServer() 
end

local function onEquipPetClicked(petName)
	-- Dispara el evento al servidor para equipar/desequipar
	RequestEquipPet:FireServer(petName)
end

local function generateArenaButtons()
	-- ... (definición completa de generateArenaButtons)
	ArenaTemplate.Visible = false 

	for _, item in ipairs(ArenaListContainer:GetChildren()) do
		if item:IsA("TextButton") and item ~= ArenaTemplate then
			item:Destroy()
		end
	end

	local currentLevel = playerLevel.Value

	for _, data in ipairs(ARENA_CONFIG_ORDERED) do
		local zoneName = data.ZoneName
		local button = ArenaTemplate:Clone()
		button.Name = zoneName 
		button.Text = string.format("%s", data.Name)
		button.Visible = true

		local requiredLevel = data.MinLevel
		local isUnlocked = (currentLevel >= requiredLevel)

		local reqLabel = button:WaitForChild("LevelRequirementLabel")
		reqLabel.Text = string.format("Nivel Requerido: %d | Recompensa: %s", requiredLevel, data.Rewards)

		if isUnlocked then
			button.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
		else
			button.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
			button.TextTransparency = 0.5
		end

		button.MouseButton1Click:Connect(function()
			if isUnlocked then
				ArenaSelectionGui.Enabled = false
				RequestTeleport:FireServer(zoneName) 
			else
				print("GUI: Arena bloqueada. Nivel necesario: " .. requiredLevel)
			end
		end)

		button.Parent = ArenaListContainer
	end
end

local function generatePetButtons()
	-- ... (definición completa de generatePetButtons)
	PetItemTemplate.Visible = false 

	-- Limpiar botones antiguos (clones)
	for _, item in ipairs(PetListFrame:GetChildren()) do
		if item ~= PetItemTemplate and item:IsA("TextButton") then
			item:Destroy()
		end
	end

	local petInventory = Player:FindFirstChild("PetInventory")
	if not petInventory then return end

	-- Obtener el multiplicador de la mascota actualmente equipada
	local equippedMultiplier = Player:FindFirstChild("Upgrades"):FindFirstChild("CoinMultiplier").Value
	local isEquipped = equippedMultiplier > 1.0 

	for _, petValue in ipairs(petInventory:GetChildren()) do
		local petName = petValue.Name
		local petMultiplier = petValue.Value

		local currentlyEquipped = false
		if isEquipped and petValue.Value == equippedMultiplier then
			currentlyEquipped = true
		end

		local button = PetItemTemplate:Clone()
		button.Name = petName

		local equipStatus = currentlyEquipped and " (EQUIPADO)" or ""
		button.Text = string.format("%s (x%.2f)%s", petName, petMultiplier, equipStatus)
		button.Visible = true

		button.BackgroundColor3 = currentlyEquipped and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(100, 100, 100)

		button.MouseButton1Click:Connect(function()
			-- Llamamos a la función de equipar/desequipar
			onEquipPetClicked(petName)
		end)

		button.Parent = PetListFrame
	end
end

local function openSelector()
	generateArenaButtons() 
	ArenaSelectionGui.Enabled = true
end

local function openPetHub()
	generatePetButtons() 
	PetHubGui.Enabled = true
end


-- =======================================================
-- 2. FUNCIÓN CRÍTICA: INICIALIZAR TODOS LOS OBJETOS
-- =======================================================
local function initializeReferences()
	-- 1. Inicializar RemoteEvents
	OpenArenaSelector = ReplicatedStorage:WaitForChild("OpenArenaSelector")
	RequestTeleport = ReplicatedStorage:WaitForChild("RequestTeleport")
	OpenPetHub = ReplicatedStorage:WaitForChild("OpenPetHub")
	RequestIncubation = ReplicatedStorage:WaitForChild("RequestIncubation")
	RequestEquipPet = ReplicatedStorage:WaitForChild("RequestEquipPet")

	-- 2. Inicializar GUI (Usando PlayerGui)
	local PlayerGui = Player:WaitForChild("PlayerGui")
	ArenaSelectionGui = PlayerGui:WaitForChild("ArenaSelectionGui")
	SelectionFrame = ArenaSelectionGui:WaitForChild("SelectionFrame")
	ArenaListContainer = SelectionFrame:WaitForChild("ArenaListContainer")
	CloseButton = SelectionFrame:WaitForChild("CloseButton")
	ArenaTemplate = ArenaListContainer:WaitForChild("ArenaTemplate")

	PetHubGui = PlayerGui:WaitForChild("PetHubGui")
	PetFrame = PetHubGui:WaitForChild("PetFrame")
	PetCloseButton = PetFrame:WaitForChild("CloseButton")
	IncubatorButton = PetFrame:WaitForChild("IncubatorButton") 
	PetListFrame = PetFrame:WaitForChild("PetListFrame")
	PetItemTemplate = PetListFrame:WaitForChild("PetItemTemplate") 

	-- 3. Inicializar Estadísticas del Jugador
	local Upgrades = Player:WaitForChild("Upgrades")
	playerLevel = Upgrades:WaitForChild("Level")

	-- 4. Inicializar las conexiones de eventos de la GUI
	IncubatorButton.MouseButton1Click:Connect(onIncubatorClicked) 
	PetCloseButton.MouseButton1Click:Connect(function() PetHubGui.Enabled = false end)
	CloseButton.MouseButton1Click:Connect(function() ArenaSelectionGui.Enabled = false end)

	OpenArenaSelector.OnClientEvent:Connect(openSelector)
	OpenPetHub.OnClientEvent:Connect(openPetHub)

	-- CRÍTICO: Conexiones de Progreso y Inventario
	local petInventory = Player:WaitForChild("PetInventory")
	petInventory.ChildAdded:Connect(generatePetButtons)
	petInventory.ChildRemoved:Connect(generatePetButtons)
	Upgrades:WaitForChild("CoinMultiplier").Changed:Connect(generatePetButtons)
	playerLevel.Changed:Connect(generateArenaButtons) 

	-- Llamada final para asegurar la GUI de mascotas está actualizada al inicio
	task.spawn(function()
		Player:WaitForChild("PetInventory")
		generatePetButtons()
	end)
end


-- =======================================================
-- LLAMADA FINAL: INICIAR EL SCRIPT
-- =======================================================
task.spawn(initializeReferences)