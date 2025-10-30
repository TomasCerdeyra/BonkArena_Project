-- Script: CombatHandler (VERSION 44 - Auto-Apuntado con Búsqueda Directa Final)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris") 
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- REQUIRES
local SoundHandler = require(ServerScriptService.Modules.SoundHandler)
local VfxHandler = require(ServerScriptService.Modules.VfxHandler)
local ZoneManager = require(ServerScriptService.Modules.ZoneManager) -- Mantenemos el require de la V32 original
local RewardManager = require(ServerScriptService.Economy.RewardManager) 
local StaffManager = require(ServerScriptService.Modules.StaffManager) 

local EnemyHandler -- CRÍTICO: Declarado como nil, se cargará en handleHeartbeat

-- CRÍTICO: Carpeta para las balas de báculo
local ProjectilesContainer = ReplicatedStorage:WaitForChild("Projectiles") 

local PROJECTILE_SPEED = 100
local PROJECTILE_LIFETIME = 3
local CONE_ANGLE_COS = math.cos(math.rad(60)) -- Ángulo de 60 grados (120 total)

local CombatHandler = {} 
local playerFireData = {} 
local characterRemovalConnections = {}


-- [Funciones stopFiring, findClosestEnemy, fireProjectile (código completo)]

function CombatHandler.stopFiring(player)
	local data = playerFireData[player] 
	playerFireData[player] = nil

	if characterRemovalConnections[player] then
		characterRemovalConnections[player]:Disconnect()
		characterRemovalConnections[player] = nil
	end
	print(player.Name .. " ha dejado de disparar por orden externa.")
end

local function findClosestEnemy(torso, maxRange)
	local originPosition = torso.Position
	local playerLookVector = torso.CFrame.LookVector
	local closestEnemyPart = nil
	local minDistance = maxRange * maxRange 

	for _, item in ipairs(Workspace:GetChildren()) do
		if item.Name == "Enemy" then
			-- Buscamos el PrimaryPart, que ahora EnemyHandler V46 garantiza que exista
			local primaryPart = item.PrimaryPart

			if primaryPart and primaryPart.Parent == item then 
				local enemyPosition = primaryPart.Position
				local distanceSquared = (enemyPosition - originPosition).Magnitude^2

				if distanceSquared < minDistance then

					local directionToEnemy = (enemyPosition - originPosition).Unit

					local dotProduct = playerLookVector:Dot(directionToEnemy)

					if dotProduct >= CONE_ANGLE_COS then
						minDistance = distanceSquared
						closestEnemyPart = primaryPart
					end
				end
			end
		end
	end

	return closestEnemyPart
end


local function fireProjectile(player, torso, targetPart, staffData)
	local projectileTemplate = ProjectilesContainer:FindFirstChild(staffData.Projectile)

	if not projectileTemplate then
		warn("CombatHandler: No se encontró la plantilla de proyectil: " .. staffData.Projectile .. " en la carpeta 'Projectiles'.")
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
		startPosition = spawnPart -- Ya es la posición calculada (Vector3)
	else
		startPosition = spawnPart.Position -- Es una BasePart (como el torso), obtenemos su Vector3
	end
	local direction = (targetPart.Position - startPosition).Unit

	projectile.CFrame = CFrame.new(startPosition)
	projectile.Parent = Workspace
	projectile.Velocity = direction * PROJECTILE_SPEED

	if projectile:FindFirstChild("Handle") then
		local lookAt = startPosition + direction
		projectile.CFrame = CFrame.new(startPosition, lookAt)
	end

	SoundHandler.playSound("Shoot", startPosition)
	--VfxHandler.playEffect("Shoot", startPosition) 

	Debris:AddItem(projectile, PROJECTILE_LIFETIME) 

	projectile.Touched:Connect(function(otherPart)
		local enemyModel = otherPart:FindFirstAncestor("Enemy")

		if enemyModel and enemyModel.Parent == Workspace then 
			--if not otherPart.Parent:IsDescendantOf(projectile) then return end 

			local zoneTag = enemyModel:FindFirstChild("Zone")
			local zoneName = zoneTag and zoneTag.Value or nil

			if zoneName then

				local totalCritChance = staffData.CriticalChance
				local isCritical = math.random() <= totalCritChance

				RewardManager.processKill(player, zoneName, isCritical)

				if isCritical then
					SoundHandler.playSound("CriticalHit", enemyModel.PrimaryPart.Position) 
					VfxHandler.playEffect("CriticalHit", enemyModel.PrimaryPart.Position)
				else
					SoundHandler.playSound("Hit", enemyModel.PrimaryPart.Position)
					VfxHandler.playEffect("Hit", enemyModel.PrimaryPart.Position)
				end

				enemyModel:Destroy()
				projectile:Destroy()
			end
		end
	end)
end


-- Bucle principal de Heartbeat (CRÍTICO: Carga Diferida de EnemyHandler)
local function handleHeartbeat(dt)
	if not EnemyHandler then
		EnemyHandler = require(ServerScriptService.Modules.EnemyHandler)
	end

	for _, player in ipairs(Players:GetPlayers()) do
		local data = playerFireData[player]

		local upgradesFolder = player:FindFirstChild("Upgrades")
		if not upgradesFolder then continue end 

		-- Usamos las stats del báculo
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


-- [Resto del código de GESTIÓN DE CONEXIÓN Y DESCONEXIÓN sin cambios de la V32 original]
local function setupPlayerReferences(player)
	-- Ya no necesitamos esperar por FireRateLevel o CriticalChanceLevel
	local upgrades = player:WaitForChild("Upgrades")

	if not playerFireData[player] then
		playerFireData[player] = { LastFiredTime = 0 }
	end

	-- Mantenemos estas líneas de la V32 original
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