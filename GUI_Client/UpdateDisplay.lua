-- Script: UpdateDisplay (VERSION 25 - Eliminaci�n de la l�gica de Cadencia y Cr�tico)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = game.Players.LocalPlayer
local Upgrades = Player:WaitForChild("Upgrades")
local MarketplaceService = game:GetService("MarketplaceService")

local UpdateStatus = ReplicatedStorage:WaitForChild("UpdateStatus")
-- ELIMINAMOS la referencia a RequestUpgrade y CriticalChanceBuy
local OpenPetHub = ReplicatedStorage:WaitForChild("OpenPetHub") 

-- Evento para solicitar la compra del huevo
local RequestIncubation = ReplicatedStorage:WaitForChild("RequestIncubation") 

local Overlay = script.Parent:WaitForChild("Overlay") 

local lobbyDisplay = Overlay:WaitForChild("LobbyDisplay") 
-- ELIMINAMOS la referencia a upgradeFireRateButton
local buyCoinsButton = Overlay:WaitForChild("Buy100Coins")

-- *** REFERENCIAS DEL HUD (Progresi�n) ***
local progressFrame = Overlay:WaitForChild("ProgressFrame")
local levelLabel = progressFrame:WaitForChild("LevelLabel")
local xpBarContainer = progressFrame:WaitForChild("XPBarContainer")
local xpBar = xpBarContainer:WaitForChild("XPBar")
local xpTextLabel = progressFrame:WaitForChild("XPTextLabel")

-- ELIMINAMOS la referencia a upgradeCriticalButton
-----------------------------------------------------------------------------

-- GUI de Mascotas 
local PetHubGui = Player:WaitForChild("PlayerGui"):WaitForChild("PetHubGui")
local PetFrame = PetHubGui:WaitForChild("PetFrame")
local PetCloseButton = PetFrame:WaitForChild("CloseButton")
local IncubatorButton = PetFrame:WaitForChild("IncubatorButton") 
local PetListFrame = PetFrame:WaitForChild("PetListFrame")

local PRODUCT_ID = 3439582471
-- ELIMINAMOS las constantes de costo de mejoras
local BASE_XP_MULTIPLIER = 10 

-- Constante de Costo (Copiada del PetManager)
local EGG_COST = 500 

local playerLevel
local playerXP
-- ELIMINAMOS las referencias a fireRateLevel y criticalChanceLevel

-- =======================================================
-- 2. FUNCI�N DE ACTUALIZACI�N DE ESTADO 
-- =======================================================
local function onStatusUpdate(messageText)
	lobbyDisplay.Text = messageText
end
UpdateStatus.OnClientEvent:Connect(onStatusUpdate)


-- =======================================================
-- 3. FUNCIONES DE CLIC DE BOTONES (Solo compra de Monedas y Mascotas)
-- =======================================================
-- ELIMINAMOS las funciones onUpgradeFireRateClicked y onUpgradeCriticalClicked

local function onBuyCoinsClicked() MarketplaceService:PromptProductPurchase(Player, PRODUCT_ID) end
buyCoinsButton.MouseButton1Click:Connect(onBuyCoinsClicked)

local function onIncubatorClicked()
	RequestIncubation:FireServer()
end
IncubatorButton.MouseButton1Click:Connect(onIncubatorClicked) 

-- =======================================================
-- 5. L�GICA DE ACTUALIZACI�N DE HUD (VISUAL Y COSTOS)
-- =======================================================
local function updateProgressBar()
	local currentLevel = playerLevel.Value
	local currentXP = playerXP.Value
	local xpNeeded = BASE_XP_MULTIPLIER * currentLevel

	local progressRatio = math.min(currentXP / xpNeeded, 1) 

	xpBar:TweenSize(
		UDim2.new(progressRatio, 0, 1, 0), 
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Quart,
		0.2, 
		true
	)

	levelLabel.Text = "Nivel: " .. currentLevel
	xpTextLabel.Text = string.format("XP: %d/%d", currentXP, xpNeeded)
end

local function updateButtonCosts()
	-- Toda la l�gica de costo de Cadencia y Cr�tico ha sido ELIMINADA.
end

-- =======================================================
-- 6. CONEXIONES INICIALES
-- =======================================================

playerLevel = Upgrades:WaitForChild("Level")
playerXP = Upgrades:WaitForChild("XP")

-- Conexiones de Eventos
-- ELIMINAMOS las conexiones de fireRateLevel y criticalChanceLevel
playerXP.Changed:Connect(updateProgressBar) 
playerLevel.Changed:Connect(updateProgressBar)

-- Conexi�n de Cierre de GUI
PetCloseButton.MouseButton1Click:Connect(function()
	PetHubGui.Enabled = false
end)

-- Actualizar el texto del bot�n de incubaci�n
IncubatorButton.Text = string.format("INCUBAR HUEVO (%d BC)", EGG_COST)

updateButtonCosts() -- La llamamos, pero ahora est� vac�a
updateProgressBar()

-- =======================================================
-- 7. CONEXI�N DEL HUB DE MASCOTAS
-- =======================================================
local OpenPetHub = ReplicatedStorage:WaitForChild("OpenPetHub") 

OpenPetHub.OnClientEvent:Connect(function()
	PetHubGui.Enabled = true
end)
-- ELIMINAMOS el 'return module' para mantener la estructura original.