-- Script: StaffManager (VERSION 10 - Con Daño y Críticos)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- RemoteEvents
local RequestStaffBuy = ReplicatedStorage:WaitForChild("RequestStaffBuy")
local RequestEquipStaff = ReplicatedStorage:WaitForChild("RequestEquipStaff")

-- REQUIRES
local SoundHandler = require(ServerScriptService.Modules.SoundHandler)

-- Contenedores
local StaffModelsContainer = ReplicatedStorage:WaitForChild("StaffModels") 
local ProjectilesContainer = ReplicatedStorage:WaitForChild("Projectiles") 

local module = {}

local equippedStaffModels = {} 
local isInitialized = false

-- =======================================================
-- CONFIGURACIÓN DE BÁCULOS (¡CON DAÑO!)
-- =======================================================
module.STAFFS = {
	["BasicStaff"] = {
		Name = "Báculo Básico",
		Cost = 0,
		AttackRate = 1.0, 
		Range = 50,
		CriticalChance = 0.05, 
		Damage = 50, -- ¡NUEVO!
		CriticalDamage = 2, -- ¡NUEVO! (2x de daño)
		Projectile = "BasicMagicBall", 
		ModelId = "BasicStaffModel", 
		Multiplier = 1.0,
		Description = "Cadencia: 1.0/s | Crítico: 5%" ,
		C1Correction = CFrame.new(-0.3, 0, 0),
		Angule = CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
	},
	["EmberWand"] = {
		Name = "Vara de Ascuas",
		Cost = 500, 
		AttackRate = 2.0, 
		Range = 60,
		CriticalChance = 0.10, 
		Damage = 75, -- ¡NUEVO!
		CriticalDamage = 2, -- ¡NUEVO!
		Projectile = "BasicMagicBall", 
		ModelId = "EmberWandModel", 
		Multiplier = 1.0, 
		Description = "Cadencia: 2.0/s | Crítico: 10%" ,
		C1Correction = CFrame.new(0, -0.5, 0.5),
		Angule = CFrame.Angles(math.rad(10), math.rad(0), math.rad(0))
	},
	["TunTunS"] = {
		Name = "Baculo Tun Tun Sahur",
		Cost = 500, 
		AttackRate = 2.0, 
		Range = 60,
		CriticalChance = 0.10, 
		Damage = 75, -- ¡NUEVO!
		CriticalDamage = 2, -- ¡NUEVO!
		Projectile = "BasicMagicBall", 
		ModelId = "TunTunSModel", 
		Multiplier = 1.0, 
		Description = "Cadencia: 2.0/s | Crítico: 10%" ,
		C1Correction = CFrame.new(-0.5, -0.5, 0),
		Angule = CFrame.Angles(math.rad(60), math.rad(0), math.rad(0))
	},
	["Balerina"] = {
		Name = "Baculo Balerina Capuchina",
		Cost = 500, 
		AttackRate = 2.0, 
		Range = 60,
		CriticalChance = 0.10, 
		Damage = 75, -- ¡NUEVO!
		CriticalDamage = 2, -- ¡NUEVO!
		Projectile = "BasicMagicBall", 
		ModelId = "BalerinaModel", 
		Multiplier = 1.0, 
		Description = "Cadencia: 2.0/s | Crítico: 10%" ,
		C1Correction = CFrame.new(0,0, 0),
		Angule = CFrame.Angles(math.rad(70), math.rad(0), math.rad(0))
	},
	["Bacu3"] = {
		Name = "Bacu3",
		Cost = 50, 
		AttackRate = 2.0, 
		Range = 60,
		CriticalChance = 0.10, 
		Damage = 75, -- ¡NUEVO!
		CriticalDamage = 2, -- ¡NUEVO!
		Projectile = "BasicMagicBall", 
		ModelId = "bacu3", 
		Multiplier = 1.0, 
		Description = "Cadencia: 2.0/s | Crítico: 10%" ,
		C1Correction = CFrame.new(0,0, 1),
		Angule = CFrame.Angles(math.rad(40), math.rad(0), math.rad(0))
	},
	["Bacu4"] = {
		Name = "Bacu4",
		Cost = 50, 
		AttackRate = 2.0, 
		Range = 60,
		CriticalChance = 0.10, 
		Damage = 75, -- ¡NUEVO!
		CriticalDamage = 2, -- ¡NUEVO!
		Projectile = "BasicMagicBall", 
		ModelId = "baculo4", 
		Multiplier = 1.0, 
		Description = "Cadencia: 2.0/s | Crítico: 10%" ,
		C1Correction = CFrame.new(0,-0.5, 0),
		Angule = CFrame.Angles(math.rad(60), math.rad(0), math.rad(0))
	},
	["Magic"] = {
		Name = "BacuMagic",
		Cost = 50, 
		AttackRate = 2.0, 
		Range = 60,
		CriticalChance = 0.10, 
		Damage = 75, -- ¡NUEVO!
		CriticalDamage = 2, -- ¡NUEVO!
		Projectile = "BasicMagicBall", 
		ModelId = "magic", 
		Multiplier = 1.0, 
		Description = "Cadencia: 2.0/s | Crítico: 10%" ,
		C1Correction = CFrame.new(0,-0.5, 0),
		Angule = CFrame.Angles(math.rad(100), math.rad(0), math.rad(0))
	},
}
-- =======================================================

function module.getStaffData(staffName)
	local staffData = module.STAFFS[staffName]
	if not staffData then
		warn("StaffManager: Se solicitó un báculo desconocido: " .. staffName .. ". Usando BasicStaff.")
		return module.STAFFS["BasicStaff"]
	end
	return staffData
end

local function unequipStaffModel(player)
	if equippedStaffModels[player] then
		equippedStaffModels[player]:Destroy()
		equippedStaffModels[player] = nil
	end
end

local function equipStaffModel(player, staffName)
	local staffData = module.STAFFS[staffName] 

	if not staffData or not staffData.C1Correction then
		warn("StaffManager: Datos del báculo incompletos o falta C1Correction para: " .. staffName)
		return
	end

	local staffModelTemplate = StaffModelsContainer:FindFirstChild(staffData.ModelId)
	local character = player.Character

	if not staffModelTemplate or not character then return end

	unequipStaffModel(player)

	local staffClone = staffModelTemplate:Clone()
	staffClone.Parent = character

	local rightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	local handle = staffClone:FindFirstChild("Handle")

	if rightHand and handle then
		handle.CanCollide = false
		local weldJoint = Instance.new("Weld")
		weldJoint.Part0 = rightHand
		weldJoint.Part1 = handle
		weldJoint.C0 = CFrame.new(0, 0, -1)

		local StaffPosition = CFrame.new(0, 0, 0)
		local StaffRotation = staffData.Angule
		local staffCorrection = staffData.C1Correction 

		weldJoint.C1 = (StaffPosition * StaffRotation) * staffCorrection
		weldJoint.Parent = handle
		equippedStaffModels[player] = staffClone
	else
		warn("StaffManager: No se pudo adjuntar el báculo (falta RightHand o Handle).")
		staffClone:Destroy()
	end
end

local function handleEquipStaff(player, staffName)
	local staffData = module.STAFFS[staffName]
	local upgrades = player:FindFirstChild("Upgrades")
	local staffInventory = player:FindFirstChild("StaffInventory")

	if not staffData or not upgrades or not staffInventory then return end

	if not staffInventory:FindFirstChild(staffName) then
		warn("StaffManager: Jugador " .. player.Name .. " intentó equipar un báculo no poseído: " .. staffName)
		return
	end

	local equippedStaffValue = upgrades:FindFirstChild("EquippedStaff")
	if not equippedStaffValue then return end

	if equippedStaffValue.Value == staffName then
		equippedStaffValue.Value = "" 
		unequipStaffModel(player)
		print("StaffManager: El jugador " .. player.Name .. " desequipó " .. staffName)
		return
	end

	if equippedStaffValue then
		equippedStaffValue.Value = staffName
		equipStaffModel(player, staffName) 
		print("StaffManager: El jugador " .. player.Name .. " equipó " .. staffName)
	end
end

local function handleStaffBuy(player, staffName)
	local staffData = module.STAFFS[staffName]
	if not staffData then
		warn("StaffManager: El jugador " .. player.Name .. " intentó comprar un báculo inexistente: " .. staffName)
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local staffInventory = player:FindFirstChild("StaffInventory")
	if not leaderstats or not staffInventory then return end

	local playerCoins = leaderstats.BonkCoin
	local cost = staffData.Cost

	if staffInventory:FindFirstChild(staffName) then
		print("StaffManager: El jugador " .. player.Name .. " ya posee " .. staffName)
		return
	end

	if playerCoins.Value >= cost then
		playerCoins.Value = playerCoins.Value - cost
		local newStaff = Instance.new("BoolValue")
		newStaff.Name = staffName
		newStaff.Value = true
		newStaff.Parent = staffInventory
		SoundHandler.playSound("Purchase", player.Character.PrimaryPart.Position)
		print("StaffManager: El jugador " .. player.Name .. " compró " .. staffName)
	else
		SoundHandler.playSound("Error", player.Character.PrimaryPart.Position)
		print("StaffManager: El jugador " .. player.Name .. " no tiene fondos para " .. staffName)
	end
end

module.init = function()
	if isInitialized then return end

	RequestStaffBuy.OnServerEvent:Connect(handleStaffBuy)
	RequestEquipStaff.OnServerEvent:Connect(handleEquipStaff)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			local equippedStaffValue = player:FindFirstChild("Upgrades"):FindFirstChild("EquippedStaff")
			task.wait(0.5) 
			if equippedStaffValue.Value ~= "" then
				equipStaffModel(player, equippedStaffValue.Value)
			end
		end)
	end)

	isInitialized = true
end

return module