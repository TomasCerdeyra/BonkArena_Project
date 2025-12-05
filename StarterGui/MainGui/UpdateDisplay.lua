-- Script: UpdateDisplay (LIMPIO - Sin Barra de Nivel vieja)
-- Ubicación: StarterGui > MainGui > UpdateDisplay

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = game.Players.LocalPlayer
local MarketplaceService = game:GetService("MarketplaceService")

local Network = ReplicatedStorage:WaitForChild("Network")
local UpdateStatus = Network:WaitForChild("UpdateStatus") -- Si lo moviste
local OpenPetHub = Network:WaitForChild("OpenPetHub")
local RequestIncubation = Network:WaitForChild("RequestIncubation")

local Overlay = script.Parent:WaitForChild("Overlay") 
local lobbyDisplay = Overlay:WaitForChild("LobbyDisplay")

-- GUI de Mascotas 
local PetHubGui = Player:WaitForChild("PlayerGui"):WaitForChild("PetHubGui")
local PetFrame = PetHubGui:WaitForChild("PetFrame")
local PetCloseButton = PetFrame:WaitForChild("CloseButton")
local IncubatorButton = PetFrame:WaitForChild("IncubatorButton") 
local PetListFrame = PetFrame:WaitForChild("PetListFrame")

local PRODUCT_ID = 3439582471
local EGG_COST = 500 

-- =======================================================
-- 1. FUNCIÓN DE ACTUALIZACIÓN DE ESTADO (Lobby)
-- =======================================================
local function onStatusUpdate(messageText)
	lobbyDisplay.Text = messageText
end
UpdateStatus.OnClientEvent:Connect(onStatusUpdate)

-- =======================================================
-- 2. FUNCIONES DE CLIC DE BOTONES
-- =======================================================

local function onBuyCoinsClicked() 
	MarketplaceService:PromptProductPurchase(Player, PRODUCT_ID) 
end

--local function onIncubatorClicked()
	--RequestIncubation:FireServer()
--end
--IncubatorButton.MouseButton1Click:Connect(onIncubatorClicked) 

-- =======================================================
-- 3. CONEXIONES DE UI (Mascotas y Texto)
-- =======================================================

-- Conexión de Cierre de GUI Mascotas
PetCloseButton.MouseButton1Click:Connect(function()
	PetHubGui.Enabled = false
end)

-- Actualizar el texto del botón de incubación
IncubatorButton.Text = string.format("INCUBAR HUEVO (%d BC)", EGG_COST)

-- Conexión para abrir el Hub de Mascotas
OpenPetHub.OnClientEvent:Connect(function()
	PetHubGui.Enabled = true
end)