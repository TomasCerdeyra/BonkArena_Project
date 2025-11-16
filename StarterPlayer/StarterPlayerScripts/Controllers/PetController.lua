-- Script: PetController (Cliente - Visuales y Movimiento)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Configuración de Movimiento
local FOLLOW_DISTANCE = 6
local FOLLOW_HEIGHT = 0.1 -- Un poco más alto para que no atraviese el piso
local SMOOTHNESS = 0.1 -- Cuanto menor, más "pesada" y suave se siente (Lerp)

local currentPetModel = nil

-- =======================================================
-- 1. FUNCIÓN PARA CARGAR MODELO
-- =======================================================
local function updatePetVisuals(petName)
	-- Limpiar mascota anterior
	if currentPetModel then
		currentPetModel:Destroy()
		currentPetModel = nil
	end

	if petName == "" then return end -- Si desequipó, terminamos aquí

	-- Buscar modelo en ReplicatedStorage (O donde los tengas guardados)
	-- Asegúrate de que el nombre del modelo coincida con el petName
	local template = ReplicatedStorage:WaitForChild("Pets"):FindFirstChild(petName) 
	-- OJO: En tu código anterior usabas ModelId. Si tus mascotas están en otra carpeta, ajusta esta ruta.
	-- Si están mezcladas con enemigos, está bien. Si tienes carpeta "Pets", mejor.

	-- Intento de buscar en raíz si no está en Enemys
	if not template then template = ReplicatedStorage:FindFirstChild(petName) end

	if template then
		currentPetModel = template:Clone()
		currentPetModel.Parent = workspace

		-- Configurar física para cliente (sin colisiones)
		for _, part in ipairs(currentPetModel:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.Anchored = true -- ¡IMPORTANTE! Lo movemos por CFrame
				part.CastShadow = false 
			end
		end

		-- Animaciones (Opcional: Aquí podrías cargar animaciones de Idle)
	else
		warn("PetController: No se encontró el modelo para " .. petName)
	end
end

-- =======================================================
-- 2. BUCLE DE MOVIMIENTO (RenderStepped = 60 FPS suave)
-- =======================================================
RunService.RenderStepped:Connect(function(dt)
	if not currentPetModel or not currentPetModel.PrimaryPart then return end

	local character = player.Character
	-- Verificamos si el jugador está vivo
	local humanoid = character and character:FindFirstChild("Humanoid")

	-- Si no hay personaje, o si está muerto (Health <= 0), ocultamos la mascota
	if not character or not character.Parent or (humanoid and humanoid.Health <= 0) then 
		currentPetModel.Parent = nil 
		return 
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		currentPetModel.Parent = workspace -- Asegurar que sea visible si estamos vivos

		-- Posición Objetivo
		local targetCFrame = root.CFrame * CFrame.new(3, FOLLOW_HEIGHT, 3) 
		local currentCFrame = currentPetModel.PrimaryPart.CFrame

		-- === ARREGLO ANTI-VUELO ===
		-- Calculamos la distancia. Si está muy lejos (ej: Respawn o Portal), teletransportar.
		if (targetCFrame.Position - currentCFrame.Position).Magnitude > 30 then
			currentPetModel:SetPrimaryPartCFrame(targetCFrame) -- ¡SNAP! Instantáneo
		else
			-- Movimiento suave normal
			local newCFrame = currentCFrame:Lerp(targetCFrame, 1 - math.pow(0.001, dt))
			currentPetModel:SetPrimaryPartCFrame(newCFrame)
		end
		-- ==========================
	end
end)

-- =======================================================
-- 3. CONEXIÓN INICIAL
-- =======================================================
local function setupListener()
	local upgrades = player:WaitForChild("Upgrades")
	local equippedPetVal = upgrades:WaitForChild("EquippedPet")

	-- Cargar inicial
	updatePetVisuals(equippedPetVal.Value)

	-- Escuchar cambios
	equippedPetVal.Changed:Connect(updatePetVisuals)
end

setupListener()