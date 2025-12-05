-- Script: CombatService (Servidor)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Módulos y Librerías
local FastCast = require(ServerScriptService.Modules.FastCastRedux)
local StaffManager = require(ServerScriptService.Modules.StaffManager)
local RewardManager = require(ServerScriptService.Economy.RewardManager)
local SoundHandler = require(ServerScriptService.Modules.SoundHandler)

-- Eventos
local Network = ReplicatedStorage:WaitForChild("Network")
local RequestFire = Network:WaitForChild("RequestFire")
local ShowDamageEvent = ReplicatedStorage:WaitForChild("ShowDamageEvent")

-- Contenedores
local ProjectilesContainer = ReplicatedStorage:WaitForChild("Projectiles")

local VfxHandler = require(ServerScriptService.Modules.VfxHandler)

-- Configuración FastCast
local caster = FastCast.new() -- Creamos el "Lanzador"
-- CORRECTO:
local castBehavior = FastCast.newBehavior()
local castParams = RaycastParams.new()
castParams.FilterType = Enum.RaycastFilterType.Exclude 
castParams.IgnoreWater = true

-- Asignamos los parámetros de Roblox dentro del comportamiento de FastCast
castBehavior.RaycastParams = castParams
castBehavior.AutoIgnoreContainer = false -- Importante: Lo manejaremos nosotros manualmente
castBehavior.CosmeticBulletContainer = workspace.Projectiles -- Opcional, ayuda a la limpieza

-- Tabla para rastrear cooldowns reales de jugadores
local playerCooldowns = {}

-- =======================================================
-- 1. MANEJADORES DE FASTCAST (Qué pasa cuando la bala vuela/golpea)
-- =======================================================

-- A) Cuando la bala viaja (Actualizar posición visual en el server)
-- Nota: Para máxima optimización esto se hace en cliente, pero por ahora hazlo aquí.
local function onLengthChanged(cast, lastPoint, dir, length, velocity, bullet)
	if bullet then
		local bulletLength = bullet.Size.Z / 2
		local offset = CFrame.new(0, 0, -(length - bulletLength))
		bullet.CFrame = CFrame.lookAt(lastPoint, lastPoint + dir):ToWorldSpace(offset)
	end
end

-- B) Cuando la bala GOLPEA algo
local function onRayHit(cast, raycastResult, velocity, bullet)
	local hitPart = raycastResult.Instance
	local character = cast.UserData.Player.Character
	local damage = cast.UserData.Damage
	local isCritical = cast.UserData.IsCritical

	-- Destruir bala visual
	if bullet then bullet:Destroy() end

	-- Lógica de daño (Copiada y adaptada de tu código anterior)
	local enemyModel = hitPart:FindFirstAncestorWhichIsA("Model")
	if enemyModel and enemyModel:FindFirstChild("Zone") then
		local health = enemyModel:FindFirstChild("Health")
		if health and health.Value > 0 then

			-- Aplicar daño
			health.Value = health.Value - damage

			-- Feedback Visual (Daño flotante)
			local attach = enemyModel:FindFirstChild("HealthBarAttach") or enemyModel.PrimaryPart
			if attach then
				ShowDamageEvent:FireClient(cast.UserData.Player, attach, damage, isCritical)
			end

			-- Sonidos
			if isCritical then
				SoundHandler.playSound("CriticalHit", hitPart.Position)
				VfxHandler.playEffect("CriticalHit", hitPart.Position)
			else
				SoundHandler.playSound("Hit", hitPart.Position)
				VfxHandler.playEffect("Hit", hitPart.Position)
			end

			-- Muerte
			if health.Value <= 0 then
				-- Verificar que no esté muerto ya para no dar doble premio
				if not enemyModel:GetAttribute("IsDead") then
					RewardManager.processKill(cast.UserData.Player, enemyModel, isCritical)
					
					-- EN LUGAR DE DESTROY(), LLAMAMOS A HANDLEDEATH
					local EnemyHandler = require(ServerScriptService.Modules.EnemyHandler)
					EnemyHandler.handleDeath(enemyModel)
				end
			end
		end
	end
end

-- Conectar eventos de FastCast
caster.LengthChanged:Connect(onLengthChanged)
caster.RayHit:Connect(onRayHit)

-- =======================================================
-- 2. FUNCIÓN PRINCIPAL: DISPARAR
-- =======================================================
local function fire(player, targetPosition)
	-- Validaciones
	local char = player.Character
	if not char then return end
	
	-- === AGREGAR ESTO ===
	local humanoid = char:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	-- ====================

	-- Obtener datos del báculo
	local upgrades = player:FindFirstChild("Upgrades")
	local equippedName = upgrades and upgrades:FindFirstChild("EquippedStaff").Value or "BasicStaff"
	local staffData = StaffManager.getStaffData(equippedName)

	-- Validar Cooldown
	local lastFire = playerCooldowns[player] or 0
	local cooldown = 1 / staffData.AttackRate
	if tick() - lastFire < cooldown then return end -- Hack detectado o lag

	playerCooldowns[player] = tick()

	-- Calcular origen (desde el báculo)
	local origin = char.HumanoidRootPart.Position
	local staffModel = char:FindFirstChild(staffData.ModelId)
	if staffModel and staffModel:FindFirstChild("Handle") then
		origin = staffModel.Handle.Position
	end

	-- Dirección
	local direction = (targetPosition - origin).Unit

	-- Crear bala visual
	local bulletTemplate = ProjectilesContainer:FindFirstChild(staffData.Projectile)
	if bulletTemplate then
		local bullet = bulletTemplate:Clone()
		bullet.CFrame = CFrame.new(origin, origin + direction)
		bullet.Parent = workspace

		-- Ignorar al propio jugador y sus balas
		castParams.FilterDescendantsInstances = {char, workspace.Projectiles} 

		-- Cálculos de daño / crítico antes de disparar
		local isCrit = math.random() <= (staffData.CriticalChance or 0)
		local finalDamage = staffData.Damage * (isCrit and staffData.CriticalDamage or 1)

		-- ¡DISPARO FASTCAST!
		local activeCast = caster:Fire(origin, direction, 100, castBehavior)

		-- Guardamos datos en el "ActiveCast" para usarlos al impactar
		activeCast.UserData = {
			Player = player,
			Damage = finalDamage,
			IsCritical = isCrit
		}

		-- Asignamos la bala visual al cast para que FastCast la mueva
		activeCast.RayInfo.CosmeticBulletObject = bullet 

		SoundHandler.playSound("Shoot", origin)
	end
end

-- =======================================================
-- 3. CONEXIÓN DE RED
-- =======================================================
RequestFire.OnServerEvent:Connect(fire)

-- Limpieza al salir
Players.PlayerRemoving:Connect(function(player)
	playerCooldowns[player] = nil
end)

return {} -- Retorno vacío estándar para Services
