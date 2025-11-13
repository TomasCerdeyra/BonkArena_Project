-- Script: LeaderboardHandler

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LeaderboardSurface = Workspace:WaitForChild("LeaderboardSurface")
local SurfaceGui = LeaderboardSurface:WaitForChild("SurfaceGui")
local DisplayLabel = SurfaceGui:WaitForChild("LeaderboardDisplay")
local UPDATE_INTERVAL = 5 -- Segundos para actualizar el tablero

-- Función para obtener y ordenar a los jugadores por BonkCoins
local function getSortedPlayers()
	local playersData = {}
	-- Recolectar datos
	for _, player in ipairs(Players:GetPlayers()) do
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local bonkCoins = leaderstats:FindFirstChild("BonkCoin")
			if bonkCoins then
				table.insert(playersData, {Name = player.Name, Coins = bonkCoins.Value})
			end
		end
	end

	-- Ordenar de mayor a menor
	table.sort(playersData, function(a, b)
		return a.Coins > b.Coins
	end)

	return playersData
end

-- Bucle principal para actualizar el tablero
while true do
	wait(UPDATE_INTERVAL)

	local sortedPlayers = getSortedPlayers()

	local displayText = "TOP JUGADORES (BonkCoins)\n" -- Título + Salto de línea
	displayText = displayText .. "====================\n"

	-- Mostrar los 5 mejores (o menos si hay menos jugadores)
	for i = 1, math.min(5, #sortedPlayers) do
		local data = sortedPlayers[i]
		displayText = displayText .. i .. ". " .. data.Name .. ": " .. data.Coins .. "\n"
	end

	-- Actualizar el TextLabel
	DisplayLabel.Text = displayText
end