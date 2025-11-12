-- Script: ArenaGuiHandler (VERSIÓN 10 - Mejoras Estéticas)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

-- Declaración de variables (Inicializadas a nil, luego llenadas en initializeReferences)
local ArenaSelectionGui
local SelectionFrame
local ArenaListContainer
local CloseButton
local ArenaTemplate
local RetreatButton -- Agregado

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
local RetreatToLobby -- RemoteEvent de Retiro


-- Datos de Configuración de Arenas (Orden Fijo para la Torre)
local ARENA_CONFIG_ORDERED = {
	{ ZoneName = "ArenaFloor", Name = "Piso 1: Arena Fácil", MinLevel = 1, Rewards = "x1 Coin" },
	{ ZoneName = "MediumArenaFloor", Name = "Piso 2: Arena Media", MinLevel = 5, Rewards = "x2 Coins" },
	{ ZoneName = "Arena3", Name = "Piso 3: Arena Fácil", MinLevel = 10, Rewards = "x1 Coin" },
	{ ZoneName = "Arena4", Name = "Piso 4: Arena Media", MinLevel = 15, Rewards = "x2 Coins" },
	{ ZoneName = "Arena5", Name = "Piso 5: Arena Fácil", MinLevel = 10, Rewards = "x1 Coin" },
	{ ZoneName = "Arena6", Name = "Piso 6: Arena Media", MinLevel = 10, Rewards = "x2 Coins" },
	{ ZoneName = "Arena7", Name = "Piso 7: Arena Fácil", MinLevel = 15, Rewards = "x1 Coin" },
	{ ZoneName = "Arena8", Name = "Piso 8: Arena Media", MinLevel = 15, Rewards = "x2 Coins" },
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

-- Función para manejar el clic en el botón de Retiro
local function onRetreatClicked()
	print("GUI: Botón de Retiro Seguro clickeado. Notificando al servidor.")
	RetreatToLobby:FireServer()
	RetreatButton.Visible = false -- Ocultar inmediatamente después de enviar
end

local function generateArenaButtons()
	local ArenaTemplate = ArenaListContainer:WaitForChild("ArenaTemplate")
	ArenaTemplate.Visible = false

	-- Limpiar botones antiguos
	for _, item in ipairs(ArenaListContainer:GetChildren()) do
		if item:IsA("TextButton") and item ~= ArenaTemplate then
			item:Destroy()
		end
	end

	local currentLevel = playerLevel.Value

	-- ?? Paleta única de colores brillantes por piso
	local floorColors = {
		Color3.fromRGB(102, 255, 102),
		Color3.fromRGB(51, 204, 255),
		Color3.fromRGB(255, 255, 102),
		Color3.fromRGB(255, 153, 51),
		Color3.fromRGB(255, 51, 51),
		Color3.fromRGB(204, 102, 255),
		Color3.fromRGB(0, 255, 204),
		Color3.fromRGB(255, 102, 178),
	}

	-- Generar botones dinámicamente
	for index, data in ipairs(ARENA_CONFIG_ORDERED) do
		local zoneName = data.ZoneName
		local button = ArenaTemplate:Clone()
		button.Name = zoneName
		button.Visible = true
		button.LayoutOrder = index

		local requiredLevel = data.MinLevel
		local isUnlocked = (currentLevel >= requiredLevel)

		-- Referencias UI internas
		local TitleLabel = button:WaitForChild("TitleText")
		local SubLabel = button:WaitForChild("SubText")
		local LockIcon = button:FindFirstChild("LockIcon")

		-- Color base único para cada piso
		local baseColor = floorColors[index] or Color3.fromRGB(100, 100, 100)

		-- ?? CRÍTICO: Limpiar UIStroke/UIGradient para regenerar
		for _, child in ipairs(button:GetChildren()) do
			if child:IsA("UIStroke") or child:IsA("UIGradient") then
				child:Destroy()
			end
		end

		if isUnlocked then
			-- ?? Botón desbloqueado: MÁXIMO BRILLO Y CONTRASTE
			button.Active = true
			button.Selectable = true
			if LockIcon then LockIcon.Visible = false end

			-- Fondo brillante del color del piso
			button.BackgroundColor3 = baseColor
			button.BackgroundTransparency = 0 -- Totalmente opaco

			-- ? Efecto de borde con UIStroke (Blanco sutil para realzar)
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 3
			stroke.Color = Color3.fromRGB(255, 255, 255)
			stroke.Transparency = 0.3
			stroke.Parent = button

			-- ?? Degradado para dar un brillo central (opcional, pero mejora el efecto 3D)
			local gradient = Instance.new("UIGradient")
			gradient.Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.5, baseColor),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
			}
			gradient.Transparency = NumberSequence.new(0.6) -- Semi-transparente para no opacar el color base
			gradient.Rotation = 90
			gradient.Parent = button

			-- Texto principal: Blanco brillante para contraste
			TitleLabel.Text = string.format(data.Name, requiredLevel)
			TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			SubLabel.TextColor3 = Color3.fromRGB(230, 230, 230)

		else
			-- ?? Botón bloqueado: Color BRILANTE pero con EFECTO OSCURO/SOMBRA
			button.Active = false
			button.Selectable = false
			if LockIcon then LockIcon.Visible = true end

			-- Fondo oscuro, pero conservando el color base para el 'tentador' brillo
			button.BackgroundColor3 = baseColor
			button.BackgroundTransparency = 0.7 -- Hace que el color sea oscuro pero visible (efecto sombra)

			-- Borde sutil gris para el botón bloqueado
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 2
			stroke.Color = Color3.fromRGB(50, 50, 50)
			stroke.Transparency = 0
			stroke.Parent = button

			-- Texto apagado pero legible
			TitleLabel.TextColor3 = Color3.fromRGB(180, 180, 180) -- Gris claro para ser visible
			SubLabel.TextColor3 = Color3.fromRGB(120, 120, 120) -- Gris medio

			TitleLabel.Text = data.Name
		end

		-- Texto secundario
		SubLabel.Text = string.format("Nivel Requerido: %d | Recompensa: %s", requiredLevel, data.Rewards)

		-- ?? Comportamiento al clic
		button.MouseButton1Click:Connect(function()
			if isUnlocked then
				ArenaSelectionGui.Enabled = false
				RequestTeleport:FireServer(zoneName)
				RetreatButton.Visible = true
			else
				print("GUI: Arena bloqueada. Nivel necesario: " .. requiredLevel)
			end
		end)

		button.Parent = ArenaListContainer
	end

	if not ArenaTemplate.Parent then
		ArenaTemplate.Parent = ArenaListContainer
	end
end


local function generatePetButtons()
	-- ... (Código existente para generar botones de mascotas)
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
	-- Si el botón de retiro estaba visible (ya está en una arena), ocultarlo al abrir el selector.
	if RetreatButton then
		RetreatButton.Visible = false
	end
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
	RetreatToLobby = ReplicatedStorage:WaitForChild("RetreatToLobby") -- RemoteEvent de Retiro

	-- 2. Inicializar GUI (Usando PlayerGui)
	local PlayerGui = Player:WaitForChild("PlayerGui")
	ArenaSelectionGui = PlayerGui:WaitForChild("ArenaSelectionGui")
	SelectionFrame = ArenaSelectionGui:WaitForChild("SelectionFrame")
	ArenaListContainer = SelectionFrame:WaitForChild("ArenaListContainer")
	CloseButton = SelectionFrame:WaitForChild("CloseButton")
	ArenaTemplate = ArenaListContainer:WaitForChild("ArenaTemplate")

	-- CRÍTICO: Nueva ruta del botón de retiro (ahora es hijo de MainGui)
	local MainGui = PlayerGui:WaitForChild("MainGui")
	RetreatButton = MainGui:WaitForChild("RetreatButton")
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
	CloseButton.MouseButton1Click:Connect(function()
		ArenaSelectionGui.Enabled = false
		-- Al cerrar el selector, aseguramos que el botón de retiro se oculte si no estamos en la arena.
		if RetreatButton then
			RetreatButton.Visible = false
		end
	end)

	-- CRÍTICO: Conexión del botón de retiro
	if RetreatButton then
		RetreatButton.MouseButton1Click:Connect(onRetreatClicked)
	end

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