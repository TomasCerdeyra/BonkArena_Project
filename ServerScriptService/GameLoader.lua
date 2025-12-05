-- Script: GameLoader (Script Normal)
local ServerScriptService = game:GetService("ServerScriptService")

print("?? Iniciando Servidor BonkArena...")

-- 1. Cargar Servicios Críticos (Combate, Economía, etc)
-- Estos módulos usualmente devuelven {} pero inicializan eventos al requerirse
require(ServerScriptService.Services.CombatService) 
-- require(ServerScriptService.Services.EconomyService) -- (Futuro)

-- 2. Iniciar el Core del Juego (Zonas, Jugadores)
local GameService = require(ServerScriptService.Core.GameService)
GameService.init() -- Llamamos explícitamente al inicio

print("? ¡Servidor cargado y listo!")