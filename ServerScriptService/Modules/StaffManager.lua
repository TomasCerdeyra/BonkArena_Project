-- Script: StaffManager (CONECTADO A DATA COMPARTIDA)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- === AQUÍ ESTÁ EL CAMBIO ===
-- Importamos la data desde ReplicatedStorage/Shared/Data/StaffData
local StaffData = require(ReplicatedStorage.Shared.Data.StaffData)
-- ===========================

local SoundHandler = require(ServerScriptService.Modules.SoundHandler)

-- Eventos
local RequestStaffBuy = ReplicatedStorage:WaitForChild("Network"):WaitForChild("RequestStaffBuy") -- Asegurate de la ruta
local RequestEquipStaff = ReplicatedStorage:WaitForChild("Network"):WaitForChild("RequestEquipStaff")

local StaffModelsContainer = ReplicatedStorage:WaitForChild("StaffModels") 

local module = {}

-- Asignamos la tabla importada a la variable pública del módulo
module.STAFFS = StaffData 

local equippedStaffModels = {} 
local isInitialized = false

function module.getStaffData(staffName)
	local staffData = module.STAFFS[staffName]
	if not staffData then
		warn("StaffManager: Se solicitó un báculo desconocido: " .. tostring(staffName) .. ". Usando BasicStaff.")
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
	if not staffData then return end

	-- Ajustes visuales por defecto si faltan en la data
	local correction = staffData.C1Correction or CFrame.new(0,0,0)
	local angle = staffData.Angule or CFrame.Angles(0,0,0)
	-- Como movimos la data, asegurate de que el StaffData tenga el campo ModelId.
	-- Si en tu StaffData nuevo no pusiste ModelId, usa el nombre como ID:
	local modelId = staffData.ModelId or staffName 

	local staffModelTemplate = StaffModelsContainer:FindFirstChild(modelId)
	local character = player.Character

	if not staffModelTemplate or not character then return end

	unequipStaffModel(player)

	local staffClone = staffModelTemplate:Clone()
	staffClone.Parent = character

	local rightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	local handle = staffClone:FindFirstChild("Handle")

	if rightHand and handle then
		handle.CanCollide = false

		-- === CAMBIO A MOTOR6D ===
		local motor = Instance.new("Motor6D")
		motor.Name = "StaffMotor"
		motor.Part0 = rightHand
		motor.Part1 = handle

		-- Mantenemos tus ajustes de CFrame para que el báculo encaje en la mano
		motor.C0 = CFrame.new(0, 0, -1) -- Offset de la mano

		local StaffPosition = CFrame.new(0, 0, 0)
		local StaffRotation = staffData.Angule or CFrame.Angles(0,0,0)
		local staffCorrection = staffData.C1Correction or CFrame.new(0,0,0)

		motor.C1 = (StaffPosition * StaffRotation) * staffCorrection -- Offset del báculo

		motor.Parent = rightHand -- Un Motor6D debe ir en la parte que anima (la mano)
		-- =======================

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

	if not staffInventory:FindFirstChild(staffName) then return end

	local equippedStaffValue = upgrades:FindFirstChild("EquippedStaff")
	if not equippedStaffValue then return end

	if equippedStaffValue.Value == staffName then
		equippedStaffValue.Value = "" 
		unequipStaffModel(player)
	else
		equippedStaffValue.Value = staffName
		equipStaffModel(player, staffName) 
	end
end

local function handleStaffBuy(player, staffName)
	local staffData = module.STAFFS[staffName]
	if not staffData then return end

	local leaderstats = player:FindFirstChild("leaderstats")
	local staffInventory = player:FindFirstChild("StaffInventory")
	if not leaderstats or not staffInventory then return end

	local playerCoins = leaderstats:FindFirstChild("BonkCoin")
	local cost = staffData.Cost

	if staffInventory:FindFirstChild(staffName) then return end

	if playerCoins.Value >= cost then
		playerCoins.Value = playerCoins.Value - cost
		local newStaff = Instance.new("BoolValue")
		newStaff.Name = staffName
		newStaff.Value = true
		newStaff.Parent = staffInventory

		if player.Character and player.Character.PrimaryPart then
			SoundHandler.playSound("Purchase", player.Character.PrimaryPart.Position)
		end
		print("StaffManager: Comprado " .. staffName)
	else
		if player.Character and player.Character.PrimaryPart then
			SoundHandler.playSound("Error", player.Character.PrimaryPart.Position)
		end
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
			if equippedStaffValue and equippedStaffValue.Value ~= "" then
				equipStaffModel(player, equippedStaffValue.Value)
			end
		end)
	end)

	isInitialized = true
end

return module