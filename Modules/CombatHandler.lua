-- Script: CombatHandler (VERSION 48 - Corrección de typo LastFiredTime)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris") 
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- REQUIRES
local SoundHandler = require(ServerScriptService.Modules.SoundHandler)
local VfxHandler = require(ServerScriptService.Modules.VfxHandler)
local ZoneManager = require(ServerScriptService.Modules.ZoneManager)
local RewardManager = require(ServerScriptService.Economy.RewardManager) 
local StaffManager = require(ServerScriptService.Modules.StaffManager) 

local EnemyHandler

-- CONTENEDORES Y EVENTOS
local ProjectilesContainer = ReplicatedStorage:WaitForChild("Projectiles") 
local ShowDamageEvent = ReplicatedStorage:WaitForChild("ShowDamageEvent")

local PROJECTILE_SPEED = 100
local PROJECTILE_LIFETIME = 3

local CombatHandler = {} 
local playerFireData = {} 
local characterRemovalConnections = {}

function CombatHandler.stopFiring(player)
	local data = playerFireData[player] 
	playerFireData[player] = nil

	if characterRemovalConnections[player] then
		characterRemovalConnections[player]:Disconnect()
		characterRemovalConnections[player] = nil
	end
	print(player.Name .. " ha dejado de disparar por orden externa.")
end

-- =======================================================
-- FUNCIÓN findClosestEnemy (Sin cambios)
-- =======================================================
local function findClosestEnemy(torso, maxRange)
	local originPosition = torso.Position
	local closestEnemyPart = nil
	local minDistance = maxRange * maxRange

	for _, item in ipairs(Workspace:GetChildren()) do
		if item:FindFirstChild("Zone") then
			local primaryPart = item.PrimaryPart
			if primaryPart and primaryPart.Parent == item then
				local enemyPosition = primaryPart.Position
				local distanceSquared = (enemyPosition - originPosition).Magnitude^2

				if distanceSquared < minDistance then
					minDistance = distanceSquared
					closestEnemyPart = primaryPart
				end
			end
		end
	end

	return closestEnemyPart
end

-- =======================================================
-- FUNCIÓN fireProjectile (Con Evento de Daño)
-- =======================================================
local function fireProjectile(player, torso, targetPart, staffData)
	local projectileTemplate = ProjectilesContainer:FindFirstChild(staffData.Projectile)
	if not projectileTemplate then
		warn("CombatHandler: No se encontró la plantilla de proyectil: " .. staffData.Projectile)
		return
	end

	local projectile = projectileTemplate:Clone()

	local ownerTag = Instance.new("ObjectValue")
	ownerTag.Name = "Owner"
	ownerTag.Value = player
	ownerTag.Parent = projectile

	local character = player.Character
	local equippedStaffModel = character and character:FindFirstChild(staffData.ModelId)
	local spawnPart = torso 

	if equippedStaffModel then
		local handle = equippedStaffModel:FindFirstChild("Handle")
		if handle then
			spawnPart = handle.Position + handle.CFrame.LookVector * 1.5 
		end
	end

	local startPosition
	if typeof(spawnPart) == "Vector3" then
		startPosition = spawnPart
	else
		startPosition = spawnPart.Position
	end
	local direction = (targetPart.Position - startPosition).Unit
	local lookAt = startPosition + direction

	projectile.CFrame = CFrame.new(startPosition, lookAt) 
	projectile.Parent = Workspace
	projectile.Velocity = direction * PROJECTILE_SPEED

	SoundHandler.playSound("Shoot", startPosition)
	Debris:AddItem(projectile, PROJECTILE_LIFETIME) 

	projectile.Touched:Connect(function(otherPart)

		local enemyModel = otherPart:FindFirstAncestorWhichIsA("Model")

		if enemyModel and enemyModel:FindFirstChild("Zone") and enemyModel.Parent == Workspace then 

			local health = enemyModel:FindFirstChild("Health")
			if not health or health.Value <= 0 then 
				projectile:Destroy()
				return 
			end

			-- 2. Calcular el daño
			local totalCritChance = staffData.CriticalChance or 0
			local isCritical = math.random() <= totalCritChance
			local damage = staffData.Damage or 1 

			if isCritical then
				damage = damage * (staffData.CriticalDamage or 2) 
			end

			damage = math.floor(damage)

			-- 3. Aplicar el daño
			health.Value = health.Value - damage

			-- =======================================================
			-- ENVIAR EVENTO AL CLIENTE
			-- =======================================================
			local partToAttachTo = enemyModel:FindFirstChild("HealthBarAttach") 
				or enemyModel:FindFirstChild("Head") 
				or enemyModel.PrimaryPart

			if partToAttachTo then
				ShowDamageEvent:FireClient(player, partToAttachTo, damage, isCritical)
			end
			-- =======================================================

			-- 4. Destruir el proyectil
			projectile:Destroy()

			-- 5. Comprobar si el enemigo murió AHORA
			if health.Value <= 0 then
				local zoneTag = enemyModel:FindFirstChild("Zone")
				local zoneName = zoneTag and zoneTag.Value or nil

				if zoneName then
					RewardManager.processKill(player, enemyModel, isCritical)

					if isCritical then
						SoundHandler.playSound("CriticalHit", enemyModel.PrimaryPart.Position) 
						VfxHandler.playEffect("CriticalHit", enemyModel.PrimaryPart.Position)
					else
						SoundHandler.playSound("Hit", enemyModel.PrimaryPart.Position)
						VfxHandler.playEffect("Hit", enemyModel.PrimaryPart.Position)
					end
				end

				enemyModel:Destroy()

			else
				-- ENEMIGO GOLPEADO
				if isCritical then
					SoundHandler.playSound("CriticalHit", enemyModel.PrimaryPart.Position)
				else
					SoundHandler.playSound("Hit", enemyModel.PrimaryPart.Position)
				end
			end
		end
	end)
end

-- =======================================================
-- Bucle principal de Heartbeat (Sin cambios)
-- =======================================================
local function handleHeartbeat(dt)
	if not EnemyHandler then
		EnemyHandler = require(ServerScriptService.Modules.EnemyHandler)
	end

	for _, player in ipairs(Players:GetPlayers()) do
		local data = playerFireData[player]
		local upgradesFolder = player:FindFirstChild("Upgrades")
		if not upgradesFolder then continue end 

		local equippedStaffValue = upgradesFolder:FindFirstChild("EquippedStaff")
		local staffName = equippedStaffValue and equippedStaffValue.Value or "BasicStaff"
		local staffData = StaffManager.getStaffData(staffName)

		if not staffData then continue end

		if data then 
			local character = player.Character
			local torso = character and character:FindFirstChild("HumanoidRootPart")

			if torso then
				local floorPart = ZoneManager.getFloorPartUnderPlayer(character)

				if floorPart and floorPart.Name:match("Arena") then
					local targetPart = findClosestEnemy(torso, staffData.Range)
					if targetPart then
						local calculatedFireRate = 1 / staffData.AttackRate 
						if tick() - data.LastFiredTime >= calculatedFireRate then
							fireProjectile(player, torso, targetPart, staffData)
							data.LastFiredTime = tick()
						end
					end
				end
			end
		end
	end
end

-- =======================================================
-- GESTIÓN DE CONEXIÓN Y DESCONEXIÓN (¡CON LA CORRECCIÓN!)
-- =======================================================
local function setupPlayerReferences(player)
	local upgrades = player:WaitForChild("Upgrades")

	-- ¡¡AQUÍ ESTÁ EL ARREGLO!!
	-- Cambiamos 'LastFDiredTime' por 'LastFiredTime'
	if not playerFireData[player] then
		playerFireData[player] = { LastFiredTime = 0 }
	end

	local fireRateValue = upgrades:FindFirstChild("FireRateLevel")
	if fireRateValue then 
		playerFireData[player].FireRateLevel = fireRateValue.Value 
		local changedConnection = fireRateValue.Changed:Connect(function(newLevel)
			if playerFireData[player] then
				playerFireData[player].FireRateLevel = newLevel
			end
		end)
		playerFireData[player].ChangedConnection = changedConnection 
	end
end

local function onCharacterAdded(character, player)
	if characterRemovalConnections[player] then
		characterRemovalConnections[player]:Disconnect()
	end

	characterRemovalConnections[player] = player.CharacterRemoving:Connect(function(removedCharacter)
		if removedCharacter == character then
			CombatHandler.stopFiring(player) 
		end
	end)

	task.spawn(function()
		setupPlayerReferences(player)
	end)
end

local function onPlayerRemoving(player)
	CombatHandler.stopFiring(player)
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(character, player)
	end)

	if player.Character then
		onCharacterAdded(player.Character, player)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

RunService.Heartbeat:Connect(handleHeartbeat)

return CombatHandler