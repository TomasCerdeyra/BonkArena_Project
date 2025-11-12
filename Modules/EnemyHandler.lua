-- Script: EnemyHandler (VERSION 40 - Final con Vida, Rotación y GUI)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemysFolder = ReplicatedStorage:WaitForChild("Enemys") -- Carpeta de modelos de enemigos
local HealthBarTemplate = ReplicatedStorage:WaitForChild("EnemyHealthBar") -- Plantilla de la GUI de vida
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Módulo local para almacenar el CombatHandler después de la carga inicial
local CombatHandler 

-- Constantes
local ENEMY_SPEED = 5
local SPAWN_DISTANCE = 50
local DETECTION_RANGE = 50

-- =======================================================
-- 1. FUNCIÓN DE IA Y MOVIMIENTO (Con Rotación Corregida)
-- =======================================================

local function getClosestPlayer(enemyPrimaryPartPosition)
	local closestPlayerTorso = nil; 
	local minDistance = math.huge;

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character;
		if character then
			local torso = character:FindFirstChild("HumanoidRootPart");
			if torso then
				local distance = (torso.Position - enemyPrimaryPartPosition).Magnitude;

				if distance < minDistance and distance <= DETECTION_RANGE then
					minDistance = distance;
					closestPlayerTorso = torso
				end
			end
		end
	end;

	return closestPlayerTorso, minDistance
end


local function moveEnemy(enemy)
	local primaryPart = enemy.PrimaryPart
	if not primaryPart then enemy:Destroy(); return end

	-- ¡NUEVO! Obtener el offset de rotación guardado
	local rotationTag = enemy:FindFirstChild("RotationOffset")
	local rotationOffsetDeg = (rotationTag and rotationTag.Value) or 0
	-- Convertimos los grados a radianes y creamos un CFrame de rotación
	local rotationOffsetCFrame = CFrame.Angles(0, math.rad(rotationOffsetDeg), 0)

	primaryPart.Anchored = true

	-- Variables para la Patrulla
	local patrolTimer = 0
	local nextPatrolTarget = primaryPart.Position
	local PATROL_MOVE_DURATION = 5
	local PATROL_RADIUS = 20

	while enemy.Parent == Workspace do
		-- Obtenemos el jugador más cercano DENTRO DEL RANGO DE DETECCIÓN
		local targetTorso, distance = getClosestPlayer(primaryPart.Position)
		local direction = Vector3.new(0, 0, 0)
		local isMoving = false

		if targetTorso then
			-- MODO PERSECUCIÓN
			local targetPosition = targetTorso.Position
			local currentPosition = primaryPart.Position
			direction = (targetPosition - currentPosition) * Vector3.new(1, 0, 1) -- Perseguir en XZ
			isMoving = true
		else
			-- MODO PATRULLA / BÚSQUEDA
			if (primaryPart.Position - nextPatrolTarget).Magnitude < 1 or patrolTimer <= 0 then
				local randomAngle = math.random() * 2 * math.pi
				local randomRadius = math.random() * PATROL_RADIUS
				nextPatrolTarget = primaryPart.Position + Vector3.new(
					math.cos(randomAngle) * randomRadius,
					0,
					math.sin(randomAngle) * randomRadius
				)
				patrolTimer = PATROL_MOVE_DURATION
			end

			direction = (nextPatrolTarget - primaryPart.Position) * Vector3.new(1, 0, 1)
			isMoving = true
		end

		-- Lógica de movimiento unificada
		if isMoving and direction.Magnitude > 0.1 then
			direction = direction.Unit
			local displacement = direction * ENEMY_SPEED * (0.1) -- Usamos 0.1 como dt
			local newPosition = primaryPart.Position + displacement
			local lookAtPosition = Vector3.new(nextPatrolTarget.X, newPosition.Y, nextPatrolTarget.Z)

			-- Si estamos en modo Persecución, miramos al jugador. Si estamos en Patrulla, miramos el punto.
			if targetTorso then
				lookAtPosition = Vector3.new(targetTorso.Position.X, newPosition.Y, targetTorso.Position.Z)
			end

			-- APLICAR ROTACIÓN CON OFFSET
			local lookAtCFrame = CFrame.lookAt(newPosition, lookAtPosition)
			local newCFrame = lookAtCFrame * rotationOffsetCFrame -- ¡APLICAMOS OFFSET!

			enemy:SetPrimaryPartCFrame(newCFrame)
			patrolTimer = patrolTimer - 0.1 -- Disminuir el temporizador en cada paso
		end

		wait(0.1)
	end
end

-- =======================================================
-- 2. FUNCIÓN DE SPAWNEO (MODIFICADA para enemyData)
-- =======================================================
function spawnEnemy(battleCenter, zoneName, enemyData) 
	if not battleCenter or not zoneName or not enemyData then 
		warn("EnemyHandler: Se llamó a spawnEnemy sin datos completos.")
		return 
	end

	-- CARGA DIFERIDA: Si CombatHandler es nil, lo requerimos AHORA.
	if not CombatHandler then
		CombatHandler = require(ServerScriptService.Modules.CombatHandler) 
	end

	-- Busca el template de enemigo por nombre DENTRO de la carpeta Enemys
	local enemyTemplate = EnemysFolder:FindFirstChild(enemyData.ModelName)

	-- Comprobación de seguridad
	if not enemyTemplate then
		warn("EnemyHandler: No se pudo encontrar el modelo de enemigo '" .. tostring(enemyData.ModelName) .. "' en la carpeta Enemys.")
		return 
	end

	local enemyClone = enemyTemplate:Clone()

	local angle = math.random() * 2 * math.pi
	local offset = Vector3.new(math.cos(angle) * SPAWN_DISTANCE, 0, math.sin(angle) * SPAWN_DISTANCE)
	local spawnPosition = battleCenter + offset

	enemyClone:SetPrimaryPartCFrame(CFrame.new(spawnPosition)) 
	enemyClone.Parent = Workspace

	-- Etiqueta de zona
	local zoneTag = Instance.new("StringValue")
	zoneTag.Name = "Zone"
	zoneTag.Value = zoneName 
	zoneTag.Parent = enemyClone

	-- Etiqueta de Rotación (leído desde enemyData)
	local rotationTag = Instance.new("NumberValue")
	rotationTag.Name = "RotationOffset"
	rotationTag.Value = enemyData.RotationOffset or 0
	rotationTag.Parent = enemyClone

	-- ¡NUEVO! Añadir la Vida al enemigo
	local health = Instance.new("IntValue")
	health.Name = "Health"
	health.Value = enemyData.Health or 100 -- Usa la vida del Config, o 100 si falla
	health.Parent = enemyClone

	-- ¡NUEVO! Añadir MaxHealth (para que el cliente sepa el 100%)
	local maxHealth = Instance.new("IntValue")
	maxHealth.Name = "MaxHealth"
	maxHealth.Value = enemyData.Health or 100 -- El mismo valor inicial
	maxHealth.Parent = enemyClone

	local primaryPart = enemyClone.PrimaryPart
	if not primaryPart then 
		warn("EnemyHandler: Enemigo '" .. enemyData.ModelName .. "' no tiene PrimaryPart. Destruyendo.")
		enemyClone:Destroy()
		return 
	end

	-- ¡BLOQUE MODIFICADO!
	if HealthBarTemplate then
		-- 1. Busca nuestra "Ancla"
		local partToAttachTo = enemyClone:FindFirstChild("HealthBarAttach") 
			-- 2. Si no la encuentra, busca la "Head"
			or enemyClone:FindFirstChild("Head") 
			-- 3. Si no, usa el PrimaryPart
			or primaryPart

		-- 2. Clonar y adjuntar al 'partToAttachTo'
		local healthBarClone = HealthBarTemplate:Clone()
		healthBarClone.Parent = partToAttachTo 
	end

	-- Configuramos las partes
	for _, part in ipairs(enemyClone:GetDescendants()) do
		if part:IsA("BasePart") then
			if part == primaryPart then
				part.Anchored = true 
				part.CanCollide = true
				part.CanTouch = true
			else
				part.Anchored = false 
				part.CanCollide = false
			end
		end
	end

	-- Lógica de colisión con jugador 
	primaryPart.Touched:Connect(function(otherPart)
		if otherPart and otherPart.Parent then
			local humanoid = otherPart.Parent:FindFirstChild("Humanoid")
			local player = Players:GetPlayerFromCharacter(otherPart.Parent)

			if humanoid then
				if player and CombatHandler then
					CombatHandler.stopFiring(player)
				end
				humanoid.Health = 0
			end
		end
	end)

	-- Iniciar la IA del enemigo
	task.spawn(function()
		moveEnemy(enemyClone)
	end)
end

-- =======================================================
-- 3. FUNCIONES DE LIMPIEZA / EXPORTAR
-- =======================================================

local function despawnAllEnemies()
	print("Limpiando enemigos restantes...")
	for _, item in ipairs(Workspace:GetChildren()) do
		-- MODIFICADO: Borra cualquier cosa que tenga nuestra etiqueta "Zone"
		if item:FindFirstChild("Zone") then
			item:Destroy()
		end
	end
end

-- Exportar las funciones públicas
return {
	spawnEnemy = spawnEnemy,
	despawnAllEnemies = despawnAllEnemies
}