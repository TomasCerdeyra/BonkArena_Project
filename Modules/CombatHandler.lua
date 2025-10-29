-- Script: CombatHandler (VERSION 31 - Implementando Golpe Crítico y XP)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris") -- Usando el servicio Debris directamente
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

-- REQUIRES
local SoundHandler = require(ServerScriptService.Modules.SoundHandler)
local VfxHandler = require(ServerScriptService.Modules.VfxHandler)
local ZoneManager = require(ServerScriptService.Modules.ZoneManager)
local RewardManager = require(ServerScriptService.Economy.RewardManager) -- ¡Módulo de Recompensas!

local ProjectileTemplate = ReplicatedStorage:WaitForChild("Projectile")

local PROJECTILE_SPEED = 100
local PROJECTILE_LIFETIME = 3
local COIN_REWARD = 1 

-- Constantes de Progresión
local XP_PER_KILL = 1 
local BASE_XP_MULTIPLIER = 10 

-- Constantes de Crítico
local BASE_CRIT_CHANCE = 0.05 
local CRIT_CHANCE_PER_LEVEL = 0.01 
local CRIT_MULTIPLIER = 2 

-- Rastreo del estado de disparo y nivel de cadencia
local CombatHandler = {} 
local playerFireData = {} 
local characterRemovalConnections = {}


-- =======================================================
-- FUNCIÓN: LÓGICA DE SUBIDA DE NIVEL (Necesaria para RewardManager)
-- NOTA: Esta lógica debería estar solo en RewardManager, pero se mantiene aquí para la V31 original.
-- =======================================================
local function tryLevelUp(player)
	local upgrades = player:FindFirstChild("Upgrades")
	if not upgrades then return end

	local playerLevel = upgrades:FindFirstChild("Level")
	local playerXP = upgrades:FindFirstChild("XP")

	if playerLevel and playerXP then
		local currentLevel = playerLevel.Value
		local xpNeeded = BASE_XP_MULTIPLIER * currentLevel

		if currentXP >= xpNeeded then
			while playerXP.Value >= xpNeeded do
				playerXP.Value = playerXP.Value - xpNeeded
				playerLevel.Value = playerLevel.Value + 1
				xpNeeded = BASE_XP_MULTIPLIER * playerLevel.Value

				print(player.Name .. " ha subido al Nivel " .. playerLevel.Value .. "!")
			end
		end
	end
end


-- =======================================================
-- FUNCIÓN: stopFiring (Limpieza forzada al morir/salir)
-- =======================================================
function CombatHandler.stopFiring(player)
	local data = playerFireData[player] 
	if data and data.ChangedConnection then
		data.ChangedConnection:Disconnect()
	end
	playerFireData[player] = nil

	if characterRemovalConnections[player] then
		characterRemovalConnections[player]:Disconnect()
		characterRemovalConnections[player] = nil
	end
	print(player.Name .. " ha dejado de disparar por orden externa.")
end


-- =======================================================
-- 1. LÓGICA DE ATAQUE DE PROYECTIL 
-- =======================================================
local function fireProjectile(player, torso, calculatedFireRate)
	local projectile = ProjectileTemplate:Clone()
	local ownerTag = Instance.new("ObjectValue")
	ownerTag.Name = "Owner"
	ownerTag.Value = player
	ownerTag.Parent = projectile

	projectile.CFrame = CFrame.new(torso.Position + torso.CFrame.LookVector * 8) 
	projectile.Parent = workspace
	projectile.Velocity = torso.CFrame.LookVector * PROJECTILE_SPEED

	-- Limpieza original usando el servicio Debris
	Debris:AddItem(projectile, PROJECTILE_LIFETIME) 

	projectile.Touched:Connect(function(otherPart)
		local enemyModel = otherPart:FindFirstAncestor("Enemy")

		if enemyModel and enemyModel.Parent == workspace then
			local zoneTag = enemyModel:FindFirstChild("Zone")
			local zoneName = zoneTag and zoneTag.Value or nil

			if zoneName then

				-- OBTENER DATOS DE MEJORA CRÍTICA
				local upgrades = player:FindFirstChild("Upgrades")
				local critLevel = upgrades:FindFirstChild("CriticalChanceLevel").Value or 1 

				-- CALCULAR PROBABILIDAD Y HACER TIRADA CRÍTICA
				local totalCritChance = BASE_CRIT_CHANCE + (critLevel * CRIT_CHANCE_PER_LEVEL) 
				local isCritical = math.random() <= totalCritChance

				RewardManager.processKill(player, zoneName, isCritical)

				-- LÓGICA DE FX
				if isCritical then
					print(player.Name .. " **¡GOLPE CRÍTICO!**")
					SoundHandler.playSound("CriticalHit", enemyModel.PrimaryPart.Position) 
					VfxHandler.playEffect("CriticalHit", enemyModel.PrimaryPart.Position)
				else
					SoundHandler.playSound("Hit", enemyModel.PrimaryPart.Position)
					VfxHandler.playEffect("Hit", enemyModel.PrimaryPart.Position)
				end

				enemyModel:Destroy()
				projectile:Destroy()
			end
		elseif otherPart.Name == "Target" and otherPart.Parent == workspace then
			VfxHandler.playEffect("Hit", otherPart.Position)
			otherPart:Destroy()
			projectile:Destroy()
		end
	end)
end

-- Bucle principal de Heartbeat 
local function handleHeartbeat(dt)
	for _, player in ipairs(Players:GetPlayers()) do
		local data = playerFireData[player]
		if data and data.FireRateLevel then 
			local character = player.Character
			local torso = character and character:FindFirstChild("HumanoidRootPart")

			if torso then

				local floorPart = ZoneManager.getFloorPartUnderPlayer(character)

				if floorPart and floorPart.Name:match("Arena") then

					local fireRateLevel = data.FireRateLevel
					local calculatedFireRate = 1 / fireRateLevel 

					if tick() - data.LastFiredTime >= calculatedFireRate then
						fireProjectile(player, torso, calculatedFireRate)
						data.LastFiredTime = tick()
					end
				end
			end
		end
	end
end


-- =======================================================
-- 2. GESTIÓN DE CONEXIÓN Y DESCONEXIÓN
-- =======================================================

local function setupPlayerReferences(player)
	-- CRÍTICO: Esperar a que TODAS las estadísticas del PlayerStats existan antes de llamar a updateFireRate
	local upgrades = player:WaitForChild("Upgrades")
	local fireRateValue = upgrades:WaitForChild("FireRateLevel")
	local criticalChanceValue = upgrades:WaitForChild("CriticalChanceLevel") 
	local levelValue = upgrades:WaitForChild("Level") 
	local xpValue = upgrades:WaitForChild("XP")

	-- Ahora que todo existe, configuramos las variables de disparo
	if fireRateValue and criticalChanceValue and levelValue and xpValue then
		if not playerFireData[player] then
			playerFireData[player] = { LastFiredTime = 0 }
		end

		playerFireData[player].FireRateLevel = fireRateValue.Value

		-- Conexión de evento (si el valor de la cadencia cambia)
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

	-- task.spawn es CRÍTICO: No bloqueamos CharacterAdded. 
	task.spawn(function()
		-- ¡NOTA!: ESTO CAUSARÁ UN ERROR DE YIELD si se ejecuta antes de que PlayerStats termine.
		-- Pero esta es la versión solicitada sin la corrección de sincronización.
		setupPlayerReferences(player)
	end)
end

local function onPlayerRemoving(player)
	CombatHandler.stopFiring(player)
end

-- Conexión de Jugadores
local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(character, player)
	end)

	if player.Character then
		onCharacterAdded(player.Character, player)
	end
end

-- CONEXIÓN GLOBAL INICIAL
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Conectar el loop Heartbeat de forma global una sola vez
RunService.Heartbeat:Connect(handleHeartbeat)

return CombatHandler