-- Script: GameHandler (VERSION 46 - Inicializaci�n Completa de Handlers)

-- =======================================================
-- 1. SERVICIOS Y CONFIGURACI�N
-- =======================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game.Players
-- REQUIRES CR�TICOS (con las nuevas rutas de carpetas)
local TeleportHandler = require(game.ServerScriptService.Modules.TeleportHandler)
local EnemyHandler = require(game.ServerScriptService.Modules.EnemyHandler)
local ZoneManager = require(game.ServerScriptService.Modules.ZoneManager) 

-- �CR�TICO! INICIALIZAR TODOS LOS LISTENERS
local PetHubHandler = require(game.ServerScriptService.Pets.PetHubHandler)
local RewardManager = require(game.ServerScriptService.Economy.RewardManager)


-- =======================================================
-- 2. CONFIGURACI�N CENTRAL
-- =======================================================
local CHECK_INTERVAL = 1 

-- =======================================================
-- 3. FUNCI�N PRINCIPAL DE GESTI�N (Bucle Sencillo)
-- =======================================================
local function manageZones()
	-- Este bucle mantiene el spawneo de enemigos en todas las zonas
	while true do
		ZoneManager.manageAllZones() 
		task.wait(CHECK_INTERVAL) 
	end
end

-- =======================================================
-- 4. L�GICA DE TELEPORTE DE PRUEBA
-- =======================================================

local function onPlayerAdded(player)
	TeleportHandler.teleportToLobby(player)
	local UpdateStatus = ReplicatedStorage:WaitForChild("UpdateStatus")
	UpdateStatus:FireClient(player, "�Bienvenido! Entra al portal para ir a la Torre.")
	print("Jugador " .. player.Name .. " unido al Lobby.")
end

-- Conexi�n de Jugadores
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)

-- Iniciar el Manager de Zonas
task.spawn(manageZones)