-- Script: CombatController (Cliente)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local Network = ReplicatedStorage:WaitForChild("Network")
local RequestFire = Network:WaitForChild("RequestFire")

-- Configuración (Esto podría venir de un módulo compartido en el futuro)
local AUTO_ATTACK_RANGE = 50
local ATTACK_COOLDOWN = 0.5 -- Valor inicial, luego se sincronizará con el báculo

local lastAttackTime = 0

-- =======================================================
-- 1. FUNCIÓN DE BÚSQUEDA OPTIMIZADA (Cliente)
-- =======================================================
local function findClosestEnemy()
	local character = player.Character
	if not character then return nil end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end

	local myPos = root.Position
	local closestEnemy = nil
	local minDistance = AUTO_ATTACK_RANGE

	-- Usamos CollectionService para no iterar sobre todo el mapa
	-- ¡IMPORTANTE!: Asegúrate de añadir el Tag "Enemy" a tus enemigos en el EnemyHandler
	local enemies = CollectionService:GetTagged("Enemy")

	-- Si aún no usas tags, usa tu método antiguo temporalmente:
	-- local enemies = workspace:GetChildren() -- (Menos eficiente, cámbialo pronto)

	for _, enemy in ipairs(enemies) do
		local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
		local health = enemy:FindFirstChild("Health")

		if enemyRoot and health and health.Value > 0 then
			local dist = (enemyRoot.Position - myPos).Magnitude
			if dist < minDistance then
				minDistance = dist
				closestEnemy = enemyRoot -- Devolvemos la parte, no el modelo
			end
		end
	end

	return closestEnemy
end

-- =======================================================
-- 2. BUCLE PRINCIPAL
-- =======================================================
RunService.Heartbeat:Connect(function(dt)
	local now = tick()

	-- === AGREGAR ESTO ===
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then 
		return -- Si no tiene vida, paramos aquí. No dispara.
	end
	-- ====================

	-- Sistema de Cooldown (lo que ya tenías)
	if now - lastAttackTime < ATTACK_COOLDOWN then return end

	local targetPart = findClosestEnemy()

	if targetPart then
		RequestFire:FireServer(targetPart.Position)
		lastAttackTime = now
	end
end)

-- Escuchar cambios de báculo para actualizar el cooldown (Opcional por ahora)
-- Podrías leer el atributo "AttackRate" de tu báculo equipado aquí.