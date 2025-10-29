-- Script: ShopHandler (VERSION 4 - A�adiendo Mejora Cr�tica)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RequestUpgrade = ReplicatedStorage:WaitForChild("RequestUpgrade")

local COSTS = {
	["FireRate"] = 10,
	["CriticalChance"] = 25 -- NUEVO: Costo base m�s alto para la nueva mejora
}

local function onUpgradeRequested(player, upgradeType)
	local leaderstats = player:FindFirstChild("leaderstats")
	local upgrades = player:FindFirstChild("Upgrades")
	if not (leaderstats and upgrades) then return end
	local bonkCoins = leaderstats:FindFirstChild("BonkCoin")

	-- Definir variables de nivel y costo gen�ricas
	local upgradeLevel
	local cost
	local costBase = COSTS[upgradeType]

	if upgradeType == "FireRate" then
		upgradeLevel = upgrades:FindFirstChild("FireRateLevel")
		cost = costBase * upgradeLevel.Value

	elseif upgradeType == "CriticalChance" then
		upgradeLevel = upgrades:FindFirstChild("CriticalChanceLevel")
		cost = costBase * upgradeLevel.Value -- Costo escala con el nivel

	else
		-- Tipo de mejora desconocido
		return
	end

	-- L�gica de compra
	if bonkCoins.Value >= cost then
		bonkCoins.Value = bonkCoins.Value - cost
		upgradeLevel.Value = upgradeLevel.Value + 1
		print("�Mejora '" .. upgradeType .. "' comprada por " .. player.Name .. "! Nuevo nivel: " .. upgradeLevel.Value)
	else
		print(player.Name .. " intent� comprar " .. upgradeType .. ", pero no tiene suficientes BonkCoins.")
	end
end

RequestUpgrade.OnServerEvent:Connect(onUpgradeRequested)