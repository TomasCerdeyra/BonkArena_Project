-- Script: EnemyHandler (VERSION 38 - Corrección de Dependencia Circular)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemyTemplate = ReplicatedStorage:WaitForChild("Enemy")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService") -- Necesario para la carga diferida

-- ELIMINAMOS EL REQUIRE DIRECTO: local CombatHandler = require(game.ServerScriptService.Modules.CombatHandler) 

local ENEMY_SPEED = 2
local SPAWN_DISTANCE = 50

-- Módulo local para almacenar el CombatHandler después de la carga inicial
local CombatHandler 

-- =======================================================
-- 1. FUNCIÓN DE IA Y MOVIMIENTO 
-- =======================================================
local function getClosestPlayer(enemyPrimaryPartPosition)
	local closestPlayer = nil; local minDistance = math.huge; 
	for _, player in ipairs(Players:GetPlayers()) do 
		local character = player.Character;
		if character then 
			local torso = character:FindFirstChild("HumanoidRootPart"); 
			if torso then 
				local distance = (torso.Position - enemyPrimaryPartPosition).Magnitude;
				if distance < minDistance then 
					minDistance = distance; 
					closestPlayer = torso 
				end 
			end 
		end 
	end;
	return closestPlayer
end

local function moveEnemy(enemy)
	local primaryPart = enemy.PrimaryPart
	if not primaryPart then enemy:Destroy(); return end

	primaryPart.Anchored = true 

	while enemy.Parent == Workspace do
		local targetTorso = getClosestPlayer(primaryPart.Position)
		if targetTorso then
			local targetPosition = targetTorso.Position
			local currentPosition = primaryPart.Position

			local direction = (targetPosition - currentPosition) * Vector3.new(1, 0, 1)

			if direction.Magnitude > 0.1 then
				direction = direction.Unit
				local displacement = direction * ENEMY_SPEED * (0.1)

				local newPosition = currentPosition + displacement 

				local lookAtPosition = Vector3.new(targetPosition.X, newPosition.Y, targetPosition.Z)
				local newCFrame = CFrame.lookAt(newPosition, lookAtPosition)

				enemy:SetPrimaryPartCFrame(newCFrame)
			end
		end
		wait(0.1)
	end
end

-- =======================================================
-- 2. FUNCIÓN DE SPAWNEO (MODIFICADA para cargar CombatHandler)
-- =======================================================
function spawnEnemy(battleCenter, zoneName) 
	if not battleCenter or not zoneName then 
		warn("EnemyHandler: Se llamó a spawnEnemy sin centro de batalla o nombre de zona.")
		return 
	end

	-- CARGA DIFERIDA: Si CombatHandler es nil, lo requerimos AHORA.
	if not CombatHandler then
		-- Asumiendo la ruta correcta en la carpeta Modules
		CombatHandler = require(ServerScriptService.Modules.CombatHandler) 
	end

	local enemyClone = EnemyTemplate:Clone()
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

	local primaryPart = enemyClone.PrimaryPart
	if not primaryPart then return end

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
				-- 1. Forzar el fin de disparos (CombatHandler ya está cargado aquí)
				if player and CombatHandler then
					CombatHandler.stopFiring(player)
				end

				-- 2. Matar al personaje
				humanoid.Health = 0
			end
		end
	end)

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
		if item.Name == "Enemy" then
			item:Destroy()
		end
	end
end

return {
	spawnEnemy = spawnEnemy,
	despawnAllEnemies = despawnAllEnemies
}