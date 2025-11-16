-- LocalScript: PlayerStatsUIController (VERSION SEPARADA)
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local TweenService = game:GetService("TweenService")

local PlayerHUD = PlayerGui:WaitForChild("PlayerHUD")

-- 1. CONTENEDOR DE COMBATE (Vida/XP)
local TopRightContainer = PlayerHUD:WaitForChild("TopRightContainer")
local LevelXPBar = TopRightContainer:WaitForChild("LevelXPBar")
local LevelText = LevelXPBar:WaitForChild("LevelCircle"):WaitForChild("LevelText")
local XPBackground = LevelXPBar:WaitForChild("XPBackground")
local XPBar = XPBackground:WaitForChild("XPBar")
local XPText = XPBackground:WaitForChild("XPText")

local HealthBar = TopRightContainer:WaitForChild("HealthBar")
local HealthFill = HealthBar:WaitForChild("HealthFill")
local HealthText = HealthBar:WaitForChild("HealthText")

-- 2. CONTENEDOR DE ECONOMÍA (SEPARADO)
local EconomyContainer = PlayerHUD:WaitForChild("EconomyContainer")
local CoinsText = EconomyContainer:WaitForChild("CoinsText")

-- DATOS DEL SERVIDOR
local Upgrades = Player:WaitForChild("Upgrades")
local LevelVal = Upgrades:WaitForChild("Level")
local XPVal = Upgrades:WaitForChild("XP")
local MaxXPVal = Upgrades:WaitForChild("MaxXP")

local Leaderstats = Player:WaitForChild("leaderstats")
local CoinsVal = Leaderstats:WaitForChild("BonkCoin")

local TWEEN_INFO_BAR = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- === FUNCIONES ===

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

	-- Formato con comas para miles (Ej: 1,500)
	-- Esto es un truco de Lua para formatear números bonitos
	local formatted = tostring(coins):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")

	CoinsText.Text = formatted .. " ??" -- O el icono que prefieras
end

-- === CONEXIONES (IGUAL QUE ANTES) ===

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

task.wait(0.1)
updateXPUI(XPVal.Value, MaxXPVal.Value, LevelVal.Value)
updateCoinsUI(CoinsVal.Value)

pcall(function() game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false) end)