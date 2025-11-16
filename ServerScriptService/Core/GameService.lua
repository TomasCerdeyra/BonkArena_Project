-- Script: ServerScriptService/Core/GameService (ModuleScript)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game.Players

-- REQUIRES
local TeleportHandler = require(ServerScriptService.Modules.TeleportHandler)
local EnemyHandler = require(ServerScriptService.Modules.EnemyHandler) -- (Ya no se usa directo, pero por si acaso)
local ZoneManager = require(ServerScriptService.Modules.ZoneManager)
local PetHubHandler = require(ServerScriptService.Pets.PetHubHandler)
local RewardManager = require(ServerScriptService.Economy.RewardManager)
local StaffManager = require(ServerScriptService.Modules.StaffManager)

local GameService = {}

-- Bucle de zonas
local function manageZones()
	while true do
		ZoneManager.manageAllZones()
		task.wait(1) -- Intervalo de chequeo
	end
end

local function onPlayerAdded(player)
	-- Lógica de bienvenida
	TeleportHandler.teleportToLobby(player)
	local UpdateStatus = ReplicatedStorage:WaitForChild("UpdateStatus")
	UpdateStatus:FireClient(player, "¡Bienvenido! Entra al portal para ir a la Torre.")
	print("Jugador " .. player.Name .. " unido al Lobby.")
end

-- FUNCIÓN DE INICIO (INIT)
function GameService.init()
	print("?? Iniciando GameService...")

	-- 1. Iniciar StaffManager
	StaffManager.init()

	-- 2. Conectar Jugadores
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)

	-- 3. Arrancar el bucle de zonas (en un hilo separado para no trabar el script)
	task.spawn(manageZones)

	print("? GameService iniciado correctamente.")
end

return GameService