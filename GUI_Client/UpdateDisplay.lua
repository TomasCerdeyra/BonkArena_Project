-- Script: UpdateDisplay (VERSION 24 - Conecta el Botón de Incubación)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = game.Players.LocalPlayer
local Upgrades = Player:WaitForChild("Upgrades")
local MarketplaceService = game:GetService("MarketplaceService")

local UpdateStatus = ReplicatedStorage:WaitForChild("UpdateStatus")
local RequestUpgrade = ReplicatedStorage:WaitForChild("RequestUpgrade")
local OpenPetHub = ReplicatedStorage:WaitForChild("OpenPetHub") 

-- Evento para solicitar la compra del huevo
local RequestIncubation = ReplicatedStorage:WaitForChild("RequestIncubation") 

local Overlay = script.Parent:WaitForChild("Overlay") 

local lobbyDisplay = Overlay:WaitForChild("LobbyDisplay") 
local upgradeFireRateButton = Overlay:WaitForChild("UpgradeFireRate")
local buyCoinsButton = Overlay:WaitForChild("Buy100Coins")

-- *** REFERENCIAS DEL HUD (Progresión) ***
local progressFrame = Overlay:WaitForChild("ProgressFrame")
local levelLabel = progressFrame:WaitForChild("LevelLabel")
local xpBarContainer = progressFrame:WaitForChild("XPBarContainer")
local xpBar = xpBarContainer:WaitForChild("XPBar")
local xpTextLabel = progressFrame:WaitForChild("XPTextLabel")

local upgradeCriticalButton = Overlay:WaitForChild("UpgradeCritical") 
-----------------------------------------------------------------------------

-- GUI de Mascotas (Debe ser creada manualmente como PetHubGui)
local PetHubGui = Player:WaitForChild("PlayerGui"):WaitForChild("PetHubGui")
local PetFrame = PetHubGui:WaitForChild("PetFrame")
local PetCloseButton = PetFrame:WaitForChild("CloseButton")
local IncubatorButton = PetFrame:WaitForChild("IncubatorButton") -- Botón de compra/incubación
local PetListFrame = PetFrame:WaitForChild("PetListFrame")

local PRODUCT_ID = 3439582471
local BASE_COST_FIRERATE = 10
local BASE_COST_CRITICAL = 25 
local BASE_XP_MULTIPLIER = 10 

-- Constante de Costo (Copiada del PetManager)
local EGG_COST = 500 

local playerLevel
local playerXP
local fireRateLevel
local criticalChanceLevel 

-- =======================================================
-- 2. FUNCIÓN DE ACTUALIZACIÓN DE ESTADO (Sin Cambios)
-- =======================================================
local function onStatusUpdate(messageText)
	lobbyDisplay.Text = messageText
end
UpdateStatus.OnClientEvent:Connect(onStatusUpdate)


-- =======================================================
-- 3. FUNCIONES DE CLIC DE BOTONES / 4. COSTOS (Conexión de Incubación)
-- =======================================================
local function onUpgradeFireRateClicked() RequestUpgrade:FireServer("FireRate") end
upgradeFireRateButton.MouseButton1Click:Connect(onUpgradeFireRateClicked)

local function onUpgradeCriticalClicked() RequestUpgrade:FireServer("CriticalChance") end 
upgradeCriticalButton.MouseButton1Click:Connect(onUpgradeCriticalClicked)

local function onBuyCoinsClicked() MarketplaceService:PromptProductPurchase(Player, PRODUCT_ID) end
buyCoinsButton.MouseButton1Click:Connect(onBuyCoinsClicked)

local function onIncubatorClicked()
	RequestIncubation:FireServer()
end
IncubatorButton.MouseButton1Click:Connect(onIncubatorClicked) -- CONEXIÓN CLAVE

-- =======================================================
-- 5. LÓGICA DE ACTUALIZACIÓN DE HUD (VISUAL Y COSTOS)
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
	-- Costo de Cadencia
	local fireRateLevelValue = fireRateLevel.Value
	local nextFireRateCost = BASE_COST_FIRERATE * fireRateLevelValue
	upgradeFireRateButton.Text = string.format("Mejorar Cadencia (Costo: %d)", nextFireRateCost)

	-- Costo Crítico
	local criticalLevelValue = criticalChanceLevel.Value
	local nextCriticalCost = BASE_COST_CRITICAL * criticalLevelValue
	upgradeCriticalButton.Text = string.format("Mejorar Crítico (Costo: %d)", nextCriticalCost)
end

-- =======================================================
-- 6. CONEXIONES INICIALES
-- =======================================================

playerLevel = Upgrades:WaitForChild("Level")
playerXP = Upgrades:WaitForChild("XP")
fireRateLevel = Upgrades:WaitForChild("FireRateLevel")
criticalChanceLevel = Upgrades:WaitForChild("CriticalChanceLevel") 

-- Conexiones de Eventos
fireRateLevel.Changed:Connect(updateButtonCosts)
criticalChanceLevel.Changed:Connect(updateButtonCosts) 
playerXP.Changed:Connect(updateProgressBar) 
playerLevel.Changed:Connect(updateProgressBar)

-- Conexión de Cierre de GUI
PetCloseButton.MouseButton1Click:Connect(function()
	PetHubGui.Enabled = false
end)

-- Actualizar el texto del botón de incubación
IncubatorButton.Text = string.format("INCUBAR HUEVO (%d BC)", EGG_COST)

updateButtonCosts() 
updateProgressBar()

-- =======================================================
-- 7. CONEXIÓN DEL HUB DE MASCOTAS
-- =======================================================
local OpenPetHub = ReplicatedStorage:WaitForChild("OpenPetHub") 

OpenPetHub.OnClientEvent:Connect(function()
	PetHubGui.Enabled = true
end)