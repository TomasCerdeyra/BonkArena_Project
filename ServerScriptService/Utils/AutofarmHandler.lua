-- Script: AutofarmHandler (VERSION 2 - Detección Corregida)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local AutofarmZone = Workspace:WaitForChild("AutofarmZone")
local REWARD_AMOUNT = 1
local CHECK_INTERVAL = 10 -- ASEGÚRATE DE QUE ESTO SEA 10

-- Función para verificar si un jugador está DENTRO de la zona (en el plano XZ)
local function isPlayerInZone(player)
	local character = player.Character
	if not character then return false end

	local torso = character:FindFirstChild("HumanoidRootPart")
	if not torso then return false end

	local zoneCFrame = AutofarmZone.CFrame
	local zoneSize = AutofarmZone.Size
	local relativePosition = zoneCFrame:PointToObjectSpace(torso.Position)

	local halfSize = zoneSize / 2
	local isInZone = (math.abs(relativePosition.X) <= halfSize.X) and (math.abs(relativePosition.Z) <= halfSize.Z)

	return isInZone
end

-- Bucle principal para dar recompensas
while true do
	-- *** LA ESPERA DEBE ESTAR PRIMERO ***
	wait(CHECK_INTERVAL)

	for _, player in ipairs(Players:GetPlayers()) do
		if isPlayerInZone(player) then
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats then
				local bonkCoins = leaderstats:FindFirstChild("BonkCoin")
				if bonkCoins then
					bonkCoins.Value = bonkCoins.Value + REWARD_AMOUNT
					print("Autofarm: Se dio " .. REWARD_AMOUNT .. " BonkCoin a " .. player.Name)
				end
			end
		end
	end
end