-- Script: ServerScriptService/Modules/AI/SimpleAI.lua (FIX COOLDOWN)
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local EnemyConfig = require(ServerScriptService.Modules.EnemyConfig)

local SimpleAI = {}

-- Configuración Global
local DETECTION_RANGE = 50
local ATTACK_RANGE = 4
local PATROL_RADIUS = 20
local PATROL_MOVE_DURATION = 5

local enemyStates = {} 

-- =======================================================
-- SISTEMA DE ANIMACIÓN
-- =======================================================
local function playAnimation(enemy, animType, state, speedOverride)
	local animId = state.Config[animType]

	if not animId and animType == "RunAnim" then
		animId = state.Config["WalkAnim"]
	end

	if not animId then return 0 end

	local finalSpeed = speedOverride or 1.0
	if not speedOverride then
		local configKey = animType .. "Speed"
		if state.Config[configKey] then
			finalSpeed = state.Config[configKey]
		end
	end

	if state.CurrentAnim == animType and state.CurrentTrack and state.CurrentTrack.IsPlaying then
		if state.CurrentTrack.Speed ~= finalSpeed then
			state.CurrentTrack:AdjustSpeed(finalSpeed)
		end
		return state.CurrentTrack.Length or 0
	end

	if state.CurrentTrack then
		state.CurrentTrack:Stop(0.2)
	end

	if not state.Tracks[animType] then
		local animObject = enemy:FindFirstChild("Humanoid") or enemy:FindFirstChild("AnimationController")
		local animator = animObject and animObject:FindFirstChild("Animator")

		if not animator and animObject then
			animator = Instance.new("Animator")
			animator.Parent = animObject
		end

		if animator then
			local animation = Instance.new("Animation")
			animation.AnimationId = animId

			local success, track = pcall(function()
				return animator:LoadAnimation(animation)
			end)

			if success and track then
				if animType == "AttackAnim" or animType == "DeathAnim" then
					track.Priority = Enum.AnimationPriority.Action
				else
					track.Priority = Enum.AnimationPriority.Movement
				end
				state.Tracks[animType] = track
			end
		end
	end

	local track = state.Tracks[animType]
	if track then
		track:Play(0.2, 1, finalSpeed)

		if animType == "WalkAnim" or animType == "RunAnim" or animType == "IdleAnim" then
			track.Looped = true
		else
			track.Looped = false
		end

		state.CurrentTrack = track
		state.CurrentAnim = animType

		if track.Length > 0 then return track.Length else return 1 end
	end
	return 0
end

-- =======================================================
-- UPDATE LOOP
-- =======================================================
function SimpleAI.update(enemy, dt)
	if enemy:GetAttribute("IsDead") then return end

	local primaryPart = enemy.PrimaryPart
	if not primaryPart then return end

	-- 1. INICIALIZAR
	if not enemyStates[enemy] then
		local config = nil
		for _, data in pairs(EnemyConfig) do
			if data.ModelName == enemy.Name then
				config = data
				break
			end
		end
		if not config then config = { PatrolSpeed = 5, ChaseSpeed = 5 } end

		enemyStates[enemy] = {
			Status = "PATROL", 
			NextPatrolTarget = primaryPart.Position,
			Timer = 0, 
			Config = config,
			Tracks = {},
			CurrentTrack = nil,
			CurrentAnim = ""
		}
	end
	local state = enemyStates[enemy]

	local rotationTag = enemy:FindFirstChild("RotationOffset")
	local rotationOffsetDeg = (rotationTag and rotationTag.Value) or 0
	local rotationOffsetCFrame = CFrame.Angles(0, math.rad(rotationOffsetDeg), 0)

	-- 2. BUSCAR JUGADOR
	local closestPlayerTorso = nil
	local minDistance = DETECTION_RANGE
	local targetHumanoid = nil

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			local torso = character:FindFirstChild("HumanoidRootPart")
			local humanoid = character:FindFirstChild("Humanoid")
			if torso and humanoid and humanoid.Health > 0 then
				local distance = (torso.Position - primaryPart.Position).Magnitude
				if distance < minDistance then
					minDistance = distance
					closestPlayerTorso = torso
					targetHumanoid = humanoid
				end
			end
		end
	end

	-- 3. MÁQUINA DE ESTADOS
	local targetPos = nil
	local lookAtPos = nil
	local speed = state.Config.PatrolSpeed or 6
	local shouldMove = false
	local animToPlay = "IdleAnim"
	local animSpeed = 1 

	if state.Timer > 0 then
		state.Timer = state.Timer - dt
		if state.Status == "TURN" or state.Status == "ATTACKING" then
			return -- Bloqueado
		end
	end

	-- === REACTIVACIÓN DESPUÉS DE COOLDOWN (EL FIX) ===
	if state.Status == "COOLDOWN" and state.Timer <= 0 then
		state.Status = "CHASE"
	end
	-- =================================================

	if closestPlayerTorso then
		local distToTarget = (closestPlayerTorso.Position - primaryPart.Position).Magnitude

		if state.Status == "PATROL" then
			state.Status = "CHASE"

		elseif state.Status == "CHASE" or state.Status == "COOLDOWN" then
			-- Ahora sí podrá entrar aquí porque status ya cambió a CHASE
			if distToTarget <= ATTACK_RANGE and state.Status ~= "COOLDOWN" then
				-- ATACAR
				state.Status = "ATTACKING"

				local duration = playAnimation(enemy, "AttackAnim", state)

				-- Bloquear movimiento (asegurar mínimo 0.5s)
				local atkSpeed = state.Config.AttackAnimSpeed or 1
				local realDuration = duration / atkSpeed
				state.Timer = realDuration 
				if state.Timer < 0.5 then state.Timer = 0.5 end

				-- Retrasar Daño
				local delayTime = state.Config.DamageDelay or 0.4

				task.delay(delayTime, function()
					if enemy and enemy.Parent and targetHumanoid and targetHumanoid.Health > 0 then
						local distNow = (targetHumanoid.RootPart.Position - enemy.PrimaryPart.Position).Magnitude
						-- Margen de error para golpear
						if distNow <= ATTACK_RANGE + 3 then 
							local damage = state.Config.Damage or 10
							targetHumanoid:TakeDamage(damage)
						end
					end
				end)
				return 

			elseif distToTarget > ATTACK_RANGE then
				-- PERSEGUIR
				state.Status = "CHASE"
				targetPos = closestPlayerTorso.Position
				lookAtPos = Vector3.new(targetPos.X, primaryPart.Position.Y, targetPos.Z)
				speed = state.Config.ChaseSpeed or 10
				shouldMove = true
				animToPlay = "RunAnim" 
			else
				-- Cerca pero en Cooldown (Esperando próximo golpe)
				lookAtPos = Vector3.new(closestPlayerTorso.Position.X, primaryPart.Position.Y, closestPlayerTorso.Position.Z)
				animToPlay = "IdleAnim"
			end
		end

		-- Al terminar ataque, pasar a Cooldown
		if state.Status == "ATTACKING" and state.Timer <= 0 then
			state.Status = "COOLDOWN"
			state.Timer = state.Config.AttackCooldown or 1.5 -- Tiempo entre ataques (ajusta esto si quieres que pegue más seguido)
		end

	else
		-- PATRULLA
		state.Status = "PATROL"
		if state.Timer <= 0 or (primaryPart.Position - state.NextPatrolTarget).Magnitude < 2 then
			local angle = math.random() * 2 * math.pi
			local rad = math.random() * PATROL_RADIUS
			state.NextPatrolTarget = primaryPart.Position + Vector3.new(math.cos(angle)*rad, 0, math.sin(angle)*rad)
			state.Timer = PATROL_MOVE_DURATION
		end

		targetPos = state.NextPatrolTarget
		lookAtPos = Vector3.new(targetPos.X, primaryPart.Position.Y, targetPos.Z)
		shouldMove = true
		animToPlay = "WalkAnim"
		speed = state.Config.PatrolSpeed or 6
	end

	-- 4. MOVIMIENTO
	if shouldMove and targetPos then
		local dir = (targetPos - primaryPart.Position) * Vector3.new(1,0,1)
		if dir.Magnitude > 0.1 then
			dir = dir.Unit
			local displacement = dir * speed * dt
			local newPos = primaryPart.Position + displacement
			local lookCFrame = CFrame.lookAt(newPos, lookAtPos)
			enemy:SetPrimaryPartCFrame(lookCFrame * rotationOffsetCFrame)
		end
		playAnimation(enemy, animToPlay, state)
	else
		if lookAtPos then
			local lookCFrame = CFrame.lookAt(primaryPart.Position, lookAtPos)
			enemy:SetPrimaryPartCFrame(lookCFrame * rotationOffsetCFrame)
		end
		playAnimation(enemy, "IdleAnim", state)
	end
end

function SimpleAI.playDeathAnimation(enemy)
	local state = enemyStates[enemy]
	if not state then return end
	if state.CurrentTrack then state.CurrentTrack:Stop(0.1) end
	playAnimation(enemy, "DeathAnim", state)
end

function SimpleAI.removeEnemy(enemy)
	local state = enemyStates[enemy]
	if state and state.Tracks then
		for _, track in pairs(state.Tracks) do
			track:Stop()
			track:Destroy()
		end
	end
	enemyStates[enemy] = nil
end

return SimpleAI