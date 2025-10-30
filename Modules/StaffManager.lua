-- Script: StaffManager (VERSION 9 - Rotación Corregida del Báculo Equipado)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players") -- CRÍTICO: Definido correctamente para conexiones

-- RemoteEvents (Deben existir en ReplicatedStorage)
local RequestStaffBuy = ReplicatedStorage:WaitForChild("RequestStaffBuy")
local RequestEquipStaff = ReplicatedStorage:WaitForChild("RequestEquipStaff")

-- REQUIRES
local SoundHandler = require(ServerScriptService.Modules.SoundHandler)

-- Contenedor de modelos (Asegúrate que existen en ReplicatedStorage)
local StaffModelsContainer = ReplicatedStorage:WaitForChild("StaffModels") 
local ProjectilesContainer = ReplicatedStorage:WaitForChild("Projectiles") 

local module = {}

-- Tabla local para rastrear el modelo de báculo actualmente equipado
local equippedStaffModels = {} 
local isInitialized = false -- Para el control de GameHandler

module.STAFFS = {
	["BasicStaff"] = {
		Name = "Báculo Básico",
		Cost = 0,
		AttackRate = 1.0, 
		Damage = 1,
		Range = 50,
		CriticalChance = 0.05, 
		Projectile = "BasicMagicBall", 
		ModelId = "BasicStaffModel", 
		Multiplier = 1.0,
		Description = "Cadencia: 1.0/s | Crítico: 5%" 
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
		Description = "Cadencia: 2.0/s | Crítico: 10%" 
	},
}

function module.getStaffData(staffName)
	local staffData = module.STAFFS[staffName]
	if not staffData then
		warn("StaffManager: Se solicitó un báculo desconocido: " .. staffName .. ". Usando BasicStaff.")
		return module.STAFFS["BasicStaff"]
	end
	return staffData
end

-- =======================================================
-- FUNCIÓN: Desequipar Modelo Visual
-- =======================================================
local function unequipStaffModel(player)
	if equippedStaffModels[player] then
		equippedStaffModels[player]:Destroy()
		equippedStaffModels[player] = nil
	end
end

-- =======================================================
-- FUNCIÓN: Equipar Modelo Visual (CRÍTICO: Usando los contenedores)
-- =======================================================
local function equipStaffModel(player, staffName)
	local staffData = module.STAFFS[staffName]
	-- ... (Código de verificación sin cambios)

	local staffModelTemplate = StaffModelsContainer:FindFirstChild(staffData.ModelId)
	local character = player.Character

	if not staffModelTemplate or not character then return end

	-- 1. Limpiar cualquier báculo viejo
	unequipStaffModel(player)

	-- 2. Clonar y adjuntar
	local staffClone = staffModelTemplate:Clone()
	staffClone.Parent = character

	-- 3. Crear el Weld para adjuntar a la mano derecha
	local rightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	local handle = staffClone:FindFirstChild("Handle")

	if rightHand and handle then

		-- Detenemos la física del Handle (es solo una parte visual)
		handle.CanCollide = false 

		-- Creamos un JointInstance (Weld) en lugar de WeldConstraint para más control:
		local weldJoint = Instance.new("Weld")
		weldJoint.Part0 = rightHand
		weldJoint.Part1 = handle
		weldJoint.C0 = CFrame.new(0, -0.5, 0) -- Posición relativa del RightHand

		-- CRÍTICO: Corrección de la Rotación y Posición
		-- Rotación del Handle: Girar 90 grados en el eje Z para que el báculo quede en la dirección de la mano (como si lo estuviera sujetando).
		-- math.rad(-90) en Z lo gira a lo largo del brazo.
		-- math.pi / 4 es una leve inclinación (45 grados) para que no esté perfectamente vertical.

		weldJoint.C1 = CFrame.new(0, -1.2, 0) * CFrame.Angles(0.8, 0, math.rad(0))

		weldJoint.Parent = handle

		-- Añadimos el báculo al rastreador.
		equippedStaffModels[player] = staffClone
	else
		warn("StaffManager: No se pudo adjuntar el báculo (falta RightHand o Handle).")
		staffClone:Destroy()
	end
end

-- =======================================================
-- LÓGICA DE EQUIPAMIENTO (Toggle y Visual)
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
		equippedStaffValue.Value = "" -- Desequipar: Deja una cadena vacía
		unequipStaffModel(player)
		print("StaffManager: El jugador " .. player.Name .. " desequipó " .. staffName)
		return
	end

	-- Equipar
	if equippedStaffValue then
		equippedStaffValue.Value = staffName
		equipStaffModel(player, staffName)
		print("StaffManager: El jugador " .. player.Name .. " equipó " .. staffName)
	end
end

-- =======================================================
-- LÓGICA DE COMPRA
-- =======================================================
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

	-- 1. Verificar si ya lo posee
	if staffInventory:FindFirstChild(staffName) then
		print("StaffManager: El jugador " .. player.Name .. " ya posee " .. staffName)
		return
	end

	-- 2. Verificar si tiene suficientes monedas
	if playerCoins.Value >= cost then
		-- 3. Restar monedas y añadir al inventario
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

-- =======================================================
-- INICIALIZACIÓN (Llamada desde GameHandler)
-- =======================================================
module.init = function()
	if isInitialized then return end

	-- 1. Conexiones de RemoteEvents
	RequestStaffBuy.OnServerEvent:Connect(handleStaffBuy)
	RequestEquipStaff.OnServerEvent:Connect(handleEquipStaff)

	-- 2. Conexión de equipamiento visual al cargar el personaje
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