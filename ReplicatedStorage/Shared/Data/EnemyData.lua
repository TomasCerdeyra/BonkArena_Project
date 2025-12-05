local EnemyData = {

	-- Primeros Memes (Bajo HP, Baja Recompensa)
	["guest666Rigg"] = {
		ModelName = "guest666Rigg",
		RotationOffset =  -90,
		Health = 500, 
		BaseCoinReward = 5,  -- NUEVO
		BaseXpReward = 10,   -- NUEVO
		Damage = 10,
		-- MOVIMIENTO
		PatrolSpeed = 4,
		ChaseSpeed = 10,
		
		-- === NUEVA SECCIÓN DE SINCRONIZACIÓN (GAME FEEL) ===
		-- Velocidad de reproducción de la animación (1 = Normal, 2 = Doble rápido, 0.5 = Lento)
		WalkAnimSpeed = 0.5,   -- Caminar pesado
		RunAnimSpeed = 1.0,    -- Correr normal
		AttackAnimSpeed = 2, -- ¡GOLPE RÁPIDO! (Antes 1.5)

		-- Tiempo (en segundos) a esperar para aplicar el daño DESPUÉS de iniciar la animación
		DamageDelay = 0.1,     -- Ajusta esto: Si el daño sale antes, AUMENTA este número.

		AttackCooldown = 1.2, -- 
		-- ==================================================

		WalkAnim = "rbxassetid://125183496182061",   
		RunAnim = "rbxassetid://125183496182061",    
		AttackAnim = "rbxassetid://120198337264654",
		DeathAnim = "rbxassetid://97256581016440",
	},
	["ZombieRigg"] = {
		ModelName = "ZombieRigg",
		RotationOffset = -90,
		Health = 150, 
		BaseCoinReward = 8, 
		BaseXpReward = 15,
		Damage = 15,
		-- MOVIMIENTO
		PatrolSpeed = 4,
		ChaseSpeed = 10,

		-- === NUEVA SECCIÓN DE SINCRONIZACIÓN (GAME FEEL) ===
		-- Velocidad de reproducción de la animación (1 = Normal, 2 = Doble rápido, 0.5 = Lento)
		WalkAnimSpeed = 2,   -- Caminar pesado
		RunAnimSpeed = 5,    -- Correr normal
		AttackAnimSpeed = 3, -- ¡GOLPE RÁPIDO! (Antes 1.5)

		-- Tiempo (en segundos) a esperar para aplicar el daño DESPUÉS de iniciar la animación
		DamageDelay = 0.1,     -- Ajusta esto: Si el daño sale antes, AUMENTA este número.
		AttackCooldown = 1, -- Velocidad normal
		-- ==================================================
		--DeathAnim = "rbxassetid://97256581016440",
		WalkAnim = "rbxassetid://74556693407442", 
		RunAnim = "rbxassetid://74556693407442", 
		
	},

	-- Enemigos de Transición / Dificultad Media (HP 500, Recompensa Media)
	["MemTeleRig"] = {
		ModelName = "MemTeleRig",
		RotationOffset = -90,
		Health = 500, 
		BaseCoinReward = 20, 
		BaseXpReward = 40,
		Damage = 15,
		-- MOVIMIENTO
		PatrolSpeed = 4,
		ChaseSpeed = 10,

		-- === NUEVA SECCIÓN DE SINCRONIZACIÓN (GAME FEEL) ===
		-- Velocidad de reproducción de la animación (1 = Normal, 2 = Doble rápido, 0.5 = Lento)
		WalkAnimSpeed = 0.2,   -- Caminar pesado
		RunAnimSpeed = 1.0,    -- Correr normal
		AttackAnimSpeed = 4, -- ¡GOLPE RÁPIDO! (Antes 1.5)

		-- Tiempo (en segundos) a esperar para aplicar el daño DESPUÉS de iniciar la animación
		DamageDelay = 0.3,     -- Ajusta esto: Si el daño sale antes, AUMENTA este número.

		AttackCooldown = 2.5, -- El Golem es lento, descansa 2.5s entre golpes
		-- ==================================================

		WalkAnim = "rbxassetid://99774956597840",   
		RunAnim = "rbxassetid://99774956597840",    
		AttackAnim = "rbxassetid://113458977932108",
	},
	["FantasmaNOR"] = {
		ModelName = "FantasmaNOR",
		RotationOffset = -90,
		Health = 500, 
		BaseCoinReward = 22, 
		BaseXpReward = 45,
		Damage = 5,
		-- MOVIMIENTO
		PatrolSpeed = 4,
		ChaseSpeed = 10,

		-- === NUEVA SECCIÓN DE SINCRONIZACIÓN (GAME FEEL) ===
		-- Velocidad de reproducción de la animación (1 = Normal, 2 = Doble rápido, 0.5 = Lento)
		WalkAnimSpeed = 0.2,   -- Caminar pesado
		RunAnimSpeed = 1.0,    -- Correr normal
		AttackAnimSpeed = 3, -- ¡GOLPE RÁPIDO! (Antes 1.5)

		-- Tiempo (en segundos) a esperar para aplicar el daño DESPUÉS de iniciar la animación
		DamageDelay = 0.9,     -- Ajusta esto: Si el daño sale antes, AUMENTA este número.

		AttackCooldown = 2.5, -- El Golem es lento, descansa 2.5s entre golpes
		-- ==================================================

		--WalkAnim = "rbxassetid://93786374609023",   
		--RunAnim = "rbxassetid://95138932672413",    
		--AttackAnim = "rbxassetid://138545230014263",
		--DeathAnim = "rbxassetid://97256581016440",
	},
	["GolemHieloRigg"] = {
		ModelName = "GolemHieloRigg",
		RotationOffset = -90,
		Health = 500, 
		BaseCoinReward = 25, 
		BaseXpReward = 50,
		Damage = 15,
		-- MOVIMIENTO
		PatrolSpeed = 4,
		ChaseSpeed = 10,

		-- === NUEVA SECCIÓN DE SINCRONIZACIÓN (GAME FEEL) ===
		-- Velocidad de reproducción de la animación (1 = Normal, 2 = Doble rápido, 0.5 = Lento)
		WalkAnimSpeed = 0.5,   -- Caminar pesado
		RunAnimSpeed = 1.0,    -- Correr normal
		AttackAnimSpeed = 2, -- ¡GOLPE RÁPIDO! (Antes 1.5)

		-- Tiempo (en segundos) a esperar para aplicar el daño DESPUÉS de iniciar la animación
		DamageDelay = 0.9,     -- Ajusta esto: Si el daño sale antes, AUMENTA este número.

		AttackCooldown = 1.1, -- 
		-- ==================================================

		WalkAnim = "rbxassetid://117902404692621",   
		RunAnim = "rbxassetid://117902404692621",    
		AttackAnim = "rbxassetid://122874590637570",
		DeathAnim = "rbxassetid://97256581016440",
	},
	["yetRigg"] = {
		ModelName = "yetRigg",
		RotationOffset = -90,
		Health = 500, 
		BaseCoinReward = 30, 
		BaseXpReward = 60,
		Damage = 15,
		-- MOVIMIENTO
		PatrolSpeed = 4,
		ChaseSpeed = 10,

		-- === NUEVA SECCIÓN DE SINCRONIZACIÓN (GAME FEEL) ===
		-- Velocidad de reproducción de la animación (1 = Normal, 2 = Doble rápido, 0.5 = Lento)
		WalkAnimSpeed = 0.5,   -- Caminar pesado
		RunAnimSpeed = 1.0,    -- Correr normal
		AttackAnimSpeed = 3.6, -- ¡GOLPE RÁPIDO! (Antes 1.5)

		-- Tiempo (en segundos) a esperar para aplicar el daño DESPUÉS de iniciar la animación
		DamageDelay = 0.8,     -- Ajusta esto: Si el daño sale antes, AUMENTA este número.

		AttackCooldown = 1, -- El Golem es lento, descansa 2.5s entre golpes
		-- ==================================================

		WalkAnim = "rbxassetid://117902404692621",   
		RunAnim = "rbxassetid://117902404692621",    
		AttackAnim = "rbxassetid://122874590637570",
		DeathAnim = "rbxassetid://113152802727733",
	},
	-- Enemigos Avanzados (HP 500, Recompensa Alta)
	["eneCapuRigg"] = {
		ModelName = "eneCapuRigg",
		RotationOffset = -90,
		Health = 500, 
		BaseCoinReward = 40, 
		BaseXpReward = 80,
		Damage = 15,
		-- MOVIMIENTO
		PatrolSpeed = 4,
		ChaseSpeed = 10,

		-- === NUEVA SECCIÓN DE SINCRONIZACIÓN (GAME FEEL) ===
		-- Velocidad de reproducción de la animación (1 = Normal, 2 = Doble rápido, 0.5 = Lento)
		WalkAnimSpeed = 0.2,   -- Caminar pesado
		RunAnimSpeed = 1.0,    -- Correr normal
		AttackAnimSpeed = 1, -- ¡GOLPE RÁPIDO! (Antes 1.5)

		-- Tiempo (en segundos) a esperar para aplicar el daño DESPUÉS de iniciar la animación
		DamageDelay = 0.3,     -- Ajusta esto: Si el daño sale antes, AUMENTA este número.
		-- ==================================================

		WalkAnim = "rbxassetid://93786374609023",   
		RunAnim = "rbxassetid://95138932672413",    
		AttackAnim = "rbxassetid://109468213687213",
		DeathAnim = "rbxassetid://93184405810187",
		AttackCooldown = 1.5, -- Velocidad normal
	},
	["eneOrcoRig"] = {
		ModelName = "eneOrcoRig",
		RotationOffset = -90,
		Health = 500, 
		BaseCoinReward = 45, 
		BaseXpReward = 90,
		Damage = 15,
		-- VELOCIDADES
		PatrolSpeed = 4,   -- Camina lento y torpe al patrullar
		ChaseSpeed = 10,   -- Camina "apurado" al perseguirte (sin llegar a correr)

		-- AJUSTES VISUALES (El Truco del Zombie)
		WalkAnimSpeed = 0.7, -- Reproduce la caminata al 70% (lento/pesado)
		RunAnimSpeed = 1.6,  -- Reproduce la MISMA caminata al 160% (caminata rápida/agresiva)
		AttackAnimSpeed = 3,
		DamageDelay = 0.6,   -- Ajusta esto según cuando impacte el golpe en la animación
		AttackCooldown = 0.5, -- El Golem es lento, descansa 2.5s entre golpes

		-- ANIMACIONES
		WalkAnim = "rbxassetid://117902404692621",   -- Caminata Zombie
		RunAnim = "rbxassetid://117902404692621",    -- <--- ¡REPETIMOS LA CAMINATA AQUÍ!
		AttackAnim = "rbxassetid://91360013000322", -- Golpe
		DeathAnim = "rbxassetid://80178840916492",  -- Muerte

		-- Si no tienes Idle, puedes usar la de caminar (pausada o muy lenta) o dejar una genérica
		IdleAnim = "rbxassetid://93786374609023",
	},
	["Fantasma02"] = {
		ModelName = "Fantasma02",
		RotationOffset = -90,
		Health = 500, 
		BaseCoinReward = 50, 
		BaseXpReward = 100,
		Damage = 15,
		WalkAnim = "rbxassetid://507777826", -- ID Genérico de caminar R15
		IdleAnim = "rbxassetid://507766388", -- ID Genérico de idle R15
		AttackAnim = "rbxassetid://507768375"
	},
	["FantasmaHielo"] = {
		ModelName = "FantasmaHielo",
		RotationOffset = -90,
		Health = 500, 
		BaseCoinReward = 60, 
		BaseXpReward = 120,
		Damage = 15,
		WalkAnim = "rbxassetid://507777826", -- ID Genérico de caminar R15
		IdleAnim = "rbxassetid://507766388", -- ID Genérico de idle R15
		AttackAnim = "rbxassetid://507768375"
	},
	-- ... resto de enemigos
}
return EnemyData