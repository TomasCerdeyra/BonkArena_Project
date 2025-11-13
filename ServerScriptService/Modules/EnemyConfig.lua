-- Script: EnemyConfig.lua
-- Ubicación: ServerScriptService/Modules/EnemyConfig.lua
-- VERSION CON RECOMPENSAS

local EnemyConfig = {

	-- Primeros Memes (Bajo HP, Baja Recompensa)
	["TungTung"] = {
		ModelName = "TungTung",
		RotationOffset = 0,
		Health = 100, 
		BaseCoinReward = 5,  -- NUEVO
		BaseXpReward = 10,   -- NUEVO
	},
	["Brainrot1"] = {
		ModelName = "Brainrot1",
		RotationOffset = -90,
		Health = 150, 
		BaseCoinReward = 8, 
		BaseXpReward = 15,
	},

	-- Enemigos de Transición / Dificultad Media (HP 500, Recompensa Media)
	["BlueDragon"] = {
		ModelName = "BlueDragon",
		RotationOffset = -90,
		Health = 500, 
		BaseCoinReward = 20, 
		BaseXpReward = 40,
	},
	["GolemPiedra"] = {
		ModelName = "GolemPiedra",
		RotationOffset = -90,
		Health = 500, 
		BaseCoinReward = 22, 
		BaseXpReward = 45,
	},
	["MiniEs"] = {
		ModelName = "MiniEs",
		RotationOffset = -90,
		Health = 500, 
		BaseCoinReward = 25, 
		BaseXpReward = 50,
	},
	["Arbol"] = {
		ModelName = "Arbol",
		RotationOffset = -90,
		Health = 500, 
		BaseCoinReward = 30, 
		BaseXpReward = 60,
	},

	-- Enemigos Avanzados (HP 500, Recompensa Alta)
	["Toro"] = {
		ModelName = "Toro",
		RotationOffset = -90,
		Health = 500, 
		BaseCoinReward = 40, 
		BaseXpReward = 80,
	},
	["Zombie"] = {
		ModelName = "Zombie",
		RotationOffset = -90,
		Health = 500, 
		BaseCoinReward = 45, 
		BaseXpReward = 90,
	},
	["Fantasma02"] = {
		ModelName = "Fantasma02",
		RotationOffset = -90,
		Health = 500, 
		BaseCoinReward = 50, 
		BaseXpReward = 100,
	},
	["FantasmaHielo"] = {
		ModelName = "FantasmaHielo",
		RotationOffset = -90,
		Health = 500, 
		BaseCoinReward = 60, 
		BaseXpReward = 120,
	},

}

return EnemyConfig