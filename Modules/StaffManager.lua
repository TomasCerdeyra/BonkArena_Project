-- Script: StaffManager (VERSION 9 - Rotaci�n Corregida del B�culo Equipado)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players") -- CR�TICO: Definido correctamente para conexiones

-- RemoteEvents (Deben existir en ReplicatedStorage)
local RequestStaffBuy = ReplicatedStorage:WaitForChild("RequestStaffBuy")
local RequestEquipStaff = ReplicatedStorage:WaitForChild("RequestEquipStaff")

-- REQUIRES
local SoundHandler = require(ServerScriptService.Modules.SoundHandler)

-- Contenedor de modelos (Aseg�rate que existen en ReplicatedStorage)
local StaffModelsContainer = ReplicatedStorage:WaitForChild("StaffModels") 
local ProjectilesContainer = ReplicatedStorage:WaitForChild("Projectiles") 

local module = {}

-- Tabla local para rastrear el modelo de b�culo actualmente equipado
local equippedStaffModels = {} 
local isInitialized = false -- Para el control de GameHandler

module.STAFFS = {
	["BasicStaff"] = {
		Name = "B�culo B�sico",
		Cost = 0,
		AttackRate = 1.0, 
		Damage = 1,
		Range = 50,
		CriticalChance = 0.05, 
		Projectile = "BasicMagicBall", 
		ModelId = "BasicStaffModel", 
		Multiplier = 1.0,
		Description = "Cadencia: 1.0/s | Cr�tico: 5%" 
	},
	["EmberWand"] = {
		Name = "Vara de Ascuas",
		Cost = 500, 
		AttackRate = 2.0, 
		Damage = 1,
		Range = 60,
		CriticalChance = 0.10, 
		Projectile = "BasicMagicBall", 
		ModelId = "EmberWandModel", 
		Multiplier = 1.0, 
		Description = "Cadencia: 2.0/s | Cr�tico: 10%" 
	},
}

function module.getStaffData(staffName)
	local staffData = module.STAFFS[staffName]
	if not staffData then
		warn("StaffManager: Se solicit� un b�culo desconocido: " .. staffName .. ". Usando BasicStaff.")
		return module.STAFFS["BasicStaff"]
	end
	return staffData
end

-- =======================================================
-- FUNCI�N: Desequipar Modelo Visual
-- =======================================================
local function unequipStaffModel(player)
	if equippedStaffModels[player] then
		equippedStaffModels[player]:Destroy()
		equippedStaffModels[player] = nil
	end
end

-- =======================================================
-- FUNCI�N: Equipar Modelo Visual (CR�TICO: Usando los contenedores)
-- =======================================================
local function equipStaffModel(player, staffName)
	local staffData = module.STAFFS[staffName]
	-- ... (C�digo de verificaci�n sin cambios)

	local staffModelTemplate = StaffModelsContainer:FindFirstChild(staffData.ModelId)
	local character = player.Character

	if not staffModelTemplate or not character then return end

	-- 1. Limpiar cualquier b�culo viejo
	unequipStaffModel(player)

	-- 2. Clonar y adjuntar
	local staffClone = staffModelTemplate:Clone()
	staffClone.Parent = character

	-- 3. Crear el Weld para adjuntar a la mano derecha
	local rightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	local handle = staffClone:FindFirstChild("Handle")

	if rightHand and handle then

		-- Detenemos la f�sica del Handle (es solo una parte visual)
		handle.CanCollide = false 

		-- Creamos un JointInstance (Weld) en lugar de WeldConstraint para m�s control:
		local weldJoint = Instance.new("Weld")
		weldJoint.Part0 = rightHand
		weldJoint.Part1 = handle
		weldJoint.C0 = CFrame.new(0, -0.5, 0) -- Posici�n relativa del RightHand

		-- CR�TICO: Correcci�n de la Rotaci�n y Posici�n
		-- Rotaci�n del Handle: Girar 90 grados en el eje Z para que el b�culo quede en la direcci�n de la mano (como si lo estuviera sujetando).
		-- math.rad(-90) en Z lo gira a lo largo del brazo.
		-- math.pi / 4 es una leve inclinaci�n (45 grados) para que no est� perfectamente vertical.

		weldJoint.C1 = CFrame.new(0, -1.2, 0) * CFrame.Angles(0.8, 0, math.rad(0))

		weldJoint.Parent = handle

		-- A�adimos el b�culo al rastreador.
		equippedStaffModels[player] = staffClone
	else
		warn("StaffManager: No se pudo adjuntar el b�culo (falta RightHand o Handle).")
		staffClone:Destroy()
	end
end

-- =======================================================
-- L�GICA DE EQUIPAMIENTO (Toggle y Visual)
-- =======================================================
local function handleEquipStaff(player, staffName)
	local staffData = module.STAFFS[staffName]
	local upgrades = player:FindFirstChild("Upgrades")
	local staffInventory = player:FindFirstChild("StaffInventory")

	if not staffData or not upgrades or not staffInventory then return end
	if not staffInventory:FindFirstChild(staffName) then return end

	local equippedStaffValue = upgrades:FindFirstChild("EquippedStaff")

	-- Manejo del Toggie (Equipar/Desequipar)
	if equippedStaffValue.Value == staffName then
		equippedStaffValue.Value = "" -- Desequipar: Deja una cadena vac�a
		unequipStaffModel(player)
		print("StaffManager: El jugador " .. player.Name .. " desequip� " .. staffName)
		return
	end

	-- Equipar
	if equippedStaffValue then
		equippedStaffValue.Value = staffName
		equipStaffModel(player, staffName)
		print("StaffManager: El jugador " .. player.Name .. " equip� " .. staffName)
	end
end

-- =======================================================
-- L�GICA DE COMPRA
-- =======================================================
local function handleStaffBuy(player, staffName)
	local staffData = module.STAFFS[staffName]
	if not staffData then
		warn("StaffManager: El jugador " .. player.Name .. " intent� comprar un b�culo inexistente: " .. staffName)
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local staffInventory = player:FindFirstChild("StaffInventory")
	if not leaderstats or not staffInventory then return end

	local playerCoins = leaderstats.BonkCoin
	local cost = staffData.Cost

	-- 1. Verificar si ya lo posee
	if staffInventory:FindFirstChild(staffName) then
		print("StaffManager: El jugador " .. player.Name .. " ya posee " .. staffName)
		return
	end

	-- 2. Verificar si tiene suficientes monedas
	if playerCoins.Value >= cost then
		-- 3. Restar monedas y a�adir al inventario
		playerCoins.Value = playerCoins.Value - cost

		local newStaff = Instance.new("BoolValue")
		newStaff.Name = staffName
		newStaff.Value = true
		newStaff.Parent = staffInventory

		SoundHandler.playSound("Purchase", player.Character.PrimaryPart.Position)
		print("StaffManager: El jugador " .. player.Name .. " compr� " .. staffName)
	else
		SoundHandler.playSound("Error", player.Character.PrimaryPart.Position)
		print("StaffManager: El jugador " .. player.Name .. " no tiene fondos para " .. staffName)
	end
end

-- =======================================================
-- INICIALIZACI�N (Llamada desde GameHandler)
-- =======================================================
module.init = function()
	if isInitialized then return end

	-- 1. Conexiones de RemoteEvents
	RequestStaffBuy.OnServerEvent:Connect(handleStaffBuy)
	RequestEquipStaff.OnServerEvent:Connect(handleEquipStaff)

	-- 2. Conexi�n de equipamiento visual al cargar el personaje
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			local equippedStaffValue = player:FindFirstChild("Upgrades"):FindFirstChild("EquippedStaff")
			-- Esperamos para asegurar la carga completa
			task.wait(0.5) 
			if equippedStaffValue.Value ~= "" then
				equipStaffModel(player, equippedStaffValue.Value)
			end
		end)
	end)

	isInitialized = true
end

return module