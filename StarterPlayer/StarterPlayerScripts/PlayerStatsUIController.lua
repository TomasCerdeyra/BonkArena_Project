-- LocalScript: PlayerStatsUIController (CON INDICADOR x2)
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService") -- NUEVO

local PlayerHUD = PlayerGui:WaitForChild("PlayerHUD")

-- 1. CONTENEDOR DE COMBATE
local TopRightContainer = PlayerHUD:WaitForChild("TopRightContainer")
local LevelXPBar = TopRightContainer:WaitForChild("LevelXPBar")
local LevelText = LevelXPBar:WaitForChild("LevelCircle"):WaitForChild("LevelText")
local XPBackground = LevelXPBar:WaitForChild("XPBackground")
local XPBar = XPBackground:WaitForChild("XPBar")
local XPText = XPBackground:WaitForChild("XPText")

local HealthBar = TopRightContainer:WaitForChild("HealthBar")
local HealthFill = HealthBar:WaitForChild("HealthFill")
local HealthText = HealthBar:WaitForChild("HealthText")

-- 2. CONTENEDOR DE ECONOMÍA
local EconomyContainer = PlayerHUD:WaitForChild("EconomyContainer")
local CoinsText = EconomyContainer:WaitForChild("CoinsText")
local MultiplierTag = EconomyContainer:WaitForChild("MultiplierTag") -- NUEVO REFERENCIA

-- DATOS
local Upgrades = Player:WaitForChild("Upgrades")
local LevelVal = Upgrades:WaitForChild("Level")
local XPVal = Upgrades:WaitForChild("XP")
local MaxXPVal = Upgrades:WaitForChild("MaxXP")

local Leaderstats = Player:WaitForChild("leaderstats")
local CoinsVal = Leaderstats:WaitForChild("BonkCoin")

-- Importamos ShopData para buscar el ID del pase x2 automáticamente
local ShopData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Data"):WaitForChild("ShopData"))

local TWEEN_INFO_BAR = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- === BUSCAR ID DEL PASE x2 ===
local X2_GAMEPASS_ID = 0
for _, pass in ipairs(ShopData.Passes) do
	if pass.ID == "x2Money" then
		X2_GAMEPASS_ID = pass.PassId
		break
	end
end

-- === FUNCIONES DE ACTUALIZACIÓN ===

local function updateHealthUI(currentHealth, maxHealth)
	if not HealthFill or not HealthText then return end
	local safeMax = math.max(1, maxHealth)
	local percentage = math.max(0, currentHealth / safeMax)

	local targetSize = UDim2.new(percentage, 0, 1, 0)
	TweenService:Create(HealthFill, TWEEN_INFO_BAR, { Size = targetSize }):Play()
	HealthText.Text = string.format("%i/%i", math.floor(currentHealth), math.floor(safeMax))
end

local function updateXPUI(currentXP, maxXP, level)
	if not XPBar or not XPText or not LevelText then return end
	local safeMax = math.max(1, maxXP)
	local percentage = math.max(0, currentXP / safeMax)
	percentage = math.min(percentage, 1) 

	local targetSize = UDim2.new(percentage, 0, 1, 0)
	TweenService:Create(XPBar, TWEEN_INFO_BAR, { Size = targetSize }):Play()

	LevelText.Text = tostring(level)
	XPText.Text = string.format("%i/%i", math.floor(currentXP), safeMax)
end

local function updateCoinsUI(coins)
	if not CoinsText then return end
	local formatted = tostring(coins):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
	CoinsText.Text = formatted .. " ??"
end

-- === NUEVA FUNCIÓN: VERIFICAR PASE ===
local function checkX2Pass()
	if X2_GAMEPASS_ID == 0 then return end

	-- Verificación simple (cacheada por Roblox en el cliente)
	local hasPass = false
	pcall(function()
		hasPass = MarketplaceService:UserOwnsGamePassAsync(Player.UserId, X2_GAMEPASS_ID)
	end)

	if hasPass then
		MultiplierTag.Visible = true
		-- Efecto visual opcional (latido)
		-- TweenService...
	end
end

-- === CONEXIONES ===

local function connectCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.HealthChanged:Connect(function(newHealth)
		updateHealthUI(newHealth, humanoid.MaxHealth)
	end)
	updateHealthUI(humanoid.Health, humanoid.MaxHealth)
end

Player.CharacterAdded:Connect(connectCharacter)
if Player.Character then connectCharacter(Player.Character) end

LevelVal.Changed:Connect(function(newLevel) updateXPUI(XPVal.Value, MaxXPVal.Value, newLevel) end)
XPVal.Changed:Connect(function(newXP) updateXPUI(newXP, MaxXPVal.Value, LevelVal.Value) end)
MaxXPVal.Changed:Connect(function(newMax) updateXPUI(XPVal.Value, newMax, LevelVal.Value) end)

CoinsVal.Changed:Connect(updateCoinsUI)

-- === NUEVO: DETECCIÓN DE COMPRA EN VIVO ===
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
	if player == Player and passId == X2_GAMEPASS_ID and wasPurchased then
		MultiplierTag.Visible = true
		print("¡x2 Dinero activado visualmente!")
	end
end)

-- Inicialización
task.wait(0.1)
updateXPUI(XPVal.Value, MaxXPVal.Value, LevelVal.Value)
updateCoinsUI(CoinsVal.Value)
checkX2Pass() -- Chequeo inicial

pcall(function() game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false) end)