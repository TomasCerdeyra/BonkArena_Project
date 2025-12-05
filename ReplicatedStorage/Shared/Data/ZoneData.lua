local ZoneData = {
	["ArenaFloor"] = {
		-- DATOS VISUALES (Para el Cliente: Carteles y GUI)
		Name = "Piso 1: Arena Fácil",
		MinimumLevel = 1,
		CoinMultiplier = 1,

		-- REGLAS DE JUEGO (Para el Server: Spawneo)
		MAX_ENEMIES = 5,            -- Tope máximo de enemigos vivos a la vez
		BASE_SPAWN_MULTIPLIER = 2,  -- Cuántos enemigos spawnean por cada jugador extra
		IDLE_SPAWN_RATE = 1,        -- Cuántos spawnean si no hay nadie (o mínimo)
		Enemies = {"ZombieRigg", "eneCapuRigg"},    -- Qué enemigos salen aquí (Nombres de EnemyData)
	},

	["MediumArenaFloor"] = {
		Name = "Piso 2: Arena Media",
		MinimumLevel = 5,
		CoinMultiplier = 2,

		MAX_ENEMIES = 10,
		BASE_SPAWN_MULTIPLIER = 2,
		IDLE_SPAWN_RATE = 1,
		Enemies = {"MemTeleRig", "guest666Rigg"},
	},

	["Arena3"] = {
		Name = "Piso 3: Arena Fácil",
		MinimumLevel = 10,
		CoinMultiplier = 3,

		MAX_ENEMIES = 10,
		BASE_SPAWN_MULTIPLIER = 2,
		IDLE_SPAWN_RATE = 1,
		Enemies = {"FantasmaNOR", "eneOrcoRig"},
	},

	["Arena4"] = {
		Name = "Piso 4: Arena Media",
		MinimumLevel = 15,
		CoinMultiplier = 3,

		MAX_ENEMIES = 5,
		BASE_SPAWN_MULTIPLIER = 2,
		IDLE_SPAWN_RATE = 1,
		Enemies = {"GolemHieloRigg", "yetRigg"},
	},

	["Arena5"] = {
		Name = "Piso 5: Arena Fácil",
		MinimumLevel = 20,
		CoinMultiplier = 3,

		MAX_ENEMIES = 5,
		BASE_SPAWN_MULTIPLIER = 2,
		IDLE_SPAWN_RATE = 1,
		Enemies = {"Arbol"},
	},

	["Arena6"] = {
		Name = "Piso 6: Arena Media",
		MinimumLevel = 20,
		CoinMultiplier = 4,

		MAX_ENEMIES = 10,
		BASE_SPAWN_MULTIPLIER = 2,
		IDLE_SPAWN_RATE = 1,
		Enemies = {"Zombie"},
	},

	["Arena7"] = {
		Name = "Piso 7: Arena Fácil",
		MinimumLevel = 20,
		CoinMultiplier = 4,

		MAX_ENEMIES = 10,
		BASE_SPAWN_MULTIPLIER = 2,
		IDLE_SPAWN_RATE = 1,
		Enemies = {"Fantasma02"},
	},

	["Arena8"] = {
		Name = "Piso 8: Arena Media",
		MinimumLevel = 20,
		CoinMultiplier = 5,

		MAX_ENEMIES = 20,
		BASE_SPAWN_MULTIPLIER = 2,
		IDLE_SPAWN_RATE = 1,
		Enemies = {"FantasmaHielo"},
	},
}

return ZoneData