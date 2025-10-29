-- Script: GameHandler (VERSION 46 - Inicialización Completa de Handlers)

-- =======================================================
-- 1. SERVICIOS Y CONFIGURACIÓN
-- =======================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game.Players
-- REQUIRES CRÍTICOS (con las nuevas rutas de carpetas)
local TeleportHandler = require(game.ServerScriptService.Modules.TeleportHandler)
local EnemyHandler = require(game.ServerScriptService.Modules.EnemyHandler)
local ZoneManager = require(game.ServerScriptService.Modules.ZoneManager) 

-- ¡CRÍTICO! INICIALIZAR TODOS LOS LISTENERS
local PetHubHandler = require(game.ServerScriptService.Pets.PetHubHandler)
local RewardManager = require(game.ServerScriptService.Economy.RewardManager)


-- =======================================================
-- 2. CONFIGURACIÓN CENTRAL
-- =======================================================
local CHECK_INTERVAL = 1 

-- =======================================================
-- 3. FUNCIÓN PRINCIPAL DE GESTIÓN (Bucle Sencillo)
-- =======================================================
local function manageZones()
	-- Este bucle mantiene el spawneo de enemigos en todas las zonas
	while true do
		ZoneManager.manageAllZones() 
		task.wait(CHECK_INTERVAL) 
	end
end

-- =======================================================
-- 4. LÓGICA DE TELEPORTE DE PRUEBA
-- =======================================================

local function onPlayerAdded(player)
	TeleportHandler.teleportToLobby(player)
	local UpdateStatus = ReplicatedStorage:WaitForChild("UpdateStatus")
	UpdateStatus:FireClient(player, "¡Bienvenido! Entra al portal para ir a la Torre.")
	print("Jugador " .. player.Name .. " unido al Lobby.")
end

-- Conexión de Jugadores
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)

-- Iniciar el Manager de Zonas
task.spawn(manageZones)