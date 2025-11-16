-- Script: EnemyHandler (VERSION 2.0 - Centralized Loop)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")

-- Referencias
local EnemysFolder = ReplicatedStorage:WaitForChild("Enemys")
local HealthBarTemplate = ReplicatedStorage:WaitForChild("EnemyHealthBar")

-- Importar la IA
local SimpleAI = require(ServerScriptService.Modules.AI.SimpleAI)

local EnemyHandler = {}

-- Configuración
local SPAWN_DISTANCE = 50

-- Lista maestra de enemigos activos (¡Aquí está la magia!)
local activeEnemies = {}

-- =======================================================
-- 1. BUCLE CENTRALIZADO (EL CORAZÓN DEL SISTEMA)
-- =======================================================
RunService.Heartbeat:Connect(function(dt)
	-- Recorremos la lista de enemigos activos
	for i = #activeEnemies, 1, -1 do -- Iteramos al revés para poder borrar seguramente
		local enemy = activeEnemies[i]

		if enemy.Parent then
			-- Si el enemigo existe, le decimos a la IA que lo mueva un paso
			SimpleAI.update(enemy, dt)
		else
			-- Si el enemigo ya no existe (se borró), lo sacamos de la lista
			SimpleAI.removeEnemy(enemy) -- Limpiamos su memoria en la IA
			table.remove(activeEnemies, i)
		end
	end
end)

-- =======================================================
-- 2. SPAWN ENEMY (Solo crea y añade a la lista)
-- =======================================================
function EnemyHandler.spawnEnemy(battleCenter, zoneName, enemyData)
	local enemyTemplate = EnemysFolder:FindFirstChild(enemyData.ModelName)
	if not enemyTemplate then return end

	local enemyClone = enemyTemplate:Clone()

	-- Posición aleatoria
	local angle = math.random() * 2 * math.pi
	local offset = Vector3.new(math.cos(angle) * SPAWN_DISTANCE, 0, math.sin(angle) * SPAWN_DISTANCE)
	local spawnPosition = battleCenter + offset

	enemyClone:SetPrimaryPartCFrame(CFrame.new(spawnPosition))
	enemyClone.Parent = Workspace

	-- Etiquetas (Tags) - VITAL PARA EL COMBATE Y LA LIMPIEZA
	local zoneTag = Instance.new("StringValue")
	zoneTag.Name = "Zone"
	zoneTag.Value = zoneName
	zoneTag.Parent = enemyClone

	local rotationTag = Instance.new("NumberValue")
	rotationTag.Name = "RotationOffset"
	rotationTag.Value = enemyData.RotationOffset or 0
	rotationTag.Parent = enemyClone

	local health = Instance.new("IntValue")
	health.Name = "Health"
	health.Value = enemyData.Health or 100
	health.Parent = enemyClone

	local maxHealth = Instance.new("IntValue")
	maxHealth.Name = "MaxHealth"
	maxHealth.Value = enemyData.Health or 100
	maxHealth.Parent = enemyClone

	-- Agregar Tag de CollectionService (Para que el CombatController lo vea)
	CollectionService:AddTag(enemyClone, "Enemy")

	-- Barra de Vida
	local primaryPart = enemyClone.PrimaryPart
	if HealthBarTemplate and primaryPart then
		local partToAttachTo = enemyClone:FindFirstChild("HealthBarAttach") 
			or enemyClone:FindFirstChild("Head") 
			or primaryPart

		local healthBarClone = HealthBarTemplate:Clone()
		healthBarClone.Parent = partToAttachTo
	end

	-- Física
	for _, part in ipairs(enemyClone:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true -- ¡SIEMPRE ANCHORED! La IA lo mueve con CFrame
			part.CanCollide = false -- Evita que se choquen entre ellos
			part.CanTouch = true
		end
	end

	-- ¡AQUÍ ESTÁ EL CAMBIO!
	-- En vez de iniciar un bucle 'while', solo lo metemos a la lista.
	table.insert(activeEnemies, enemyClone)
end

-- =======================================================
-- 3. DESPAWN ALL (Optimizado)
-- =======================================================
function EnemyHandler.despawnAllEnemies()
	-- Limpiamos workspace
	for _, item in ipairs(Workspace:GetChildren()) do
		if item:FindFirstChild("Zone") then
			item:Destroy()
		end
	end
	-- La lista 'activeEnemies' se limpiará sola en el próximo Heartbeat
end

-- Función para manejar la muerte con animación
function EnemyHandler.handleDeath(enemy)
	-- Si ya se está muriendo, ignorar (para evitar doble recompensa/error)
	if enemy:GetAttribute("IsDead") then return end

	-- 1. Marcar como muerto (La IA leerá esto y se detendrá)
	enemy:SetAttribute("IsDead", true)

	-- 2. Desactivar colisiones y barra de vida para limpiar visualmente
	local humanoid = enemy:FindFirstChild("Humanoid")
	local root = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
	if humanoid then humanoid.Health = 0 end
	if root then root.Anchored = true end -- Asegurar que no se mueva

	local healthBar = enemy:FindFirstChild("HealthBarAttach") and enemy.HealthBarAttach:FindFirstChild("EnemyHealthBar")
	if healthBar then healthBar:Destroy() end

	-- 3. Reproducir Animación de Muerte (Usando la IA para cargarla)
	-- Requerimos la IA aquí mismo para no crear referencias circulares al inicio
	local SimpleAI = require(ServerScriptService.Modules.AI.SimpleAI)
	SimpleAI.playDeathAnimation(enemy)

	-- 4. Esperar y Destruir
	task.delay(2.5, function()
		if enemy and enemy.Parent then
			-- Efecto de desvanecerse o simplemente borrar
			enemy:Destroy()
		end
	end)
end

return EnemyHandler