-- Script: EnemyHealthBarController (LocalScript)
-- Ubicación: StarterPlayer > StarterPlayerScripts
-- VERSIÓN 8: ¡Números de Daño Flotantes implementados!

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService") -- ¡NUEVO!
local Debris = game:GetService("Debris") -- ¡NUEVO!

local player = Players.LocalPlayer

-- =======================================================
-- PLANTILLAS Y EVENTOS
-- =======================================================
local DamageIndicatorTemplate = ReplicatedStorage:WaitForChild("DamageIndicator") -- ¡NUEVO!
local ShowDamageEvent = ReplicatedStorage:WaitForChild("ShowDamageEvent") -- ¡NUEVO!

-- =======================================================
-- CONFIGURACIÓN DEL RADAR
-- =======================================================
local RENDER_DISTANCE = 80 
local RENDER_DISTANCE_SQUARED = RENDER_DISTANCE * RENDER_DISTANCE 
local CHECK_INTERVAL = 0.25 

-- =======================================================
-- CONFIGURACIÓN DE COLORES
-- =======================================================
-- Barra de Vida
local COLOR_VIDA_ALTA = Color3.fromRGB(85, 255, 127)
local COLOR_VIDA_MEDIA = Color3.fromRGB(255, 230, 0)
local COLOR_VIDA_BAJA = Color3.fromRGB(255, 60, 60)
-- Números de Daño
local COLOR_DANO_NORMAL = Color3.fromRGB(255, 255, 255) -- Blanco
local COLOR_DANO_CRITICO = Color3.fromRGB(255, 170, 0) -- Naranja/Amarillo

-- Almacena las conexiones de los enemigos que SÍ estamos gestionando
local managedEnemies = {} 

-- =======================================================
-- Función para actualizar la barra de vida (CON TEXTO)
-- =======================================================
local function updateHealthBar(healthBar, healthValue, maxHealthValue)
	-- 1. Verificación de existencia básica
	if not healthBar or not healthBar.Parent then return end

	-- 2. Verificación paso a paso (ROMPE LA CADENA DE ERRORES)
	local background = healthBar:FindFirstChild("Background")
	if not background then return end -- Si no hay fondo, paramos aquí

	local bar = background:FindFirstChild("Bar")
	if not bar then return end -- Si no hay barra, paramos aquí

	-- 3. Si llegamos aquí, es seguro actualizar
	local percentage = 0
	if maxHealthValue > 0 then
		percentage = healthValue / maxHealthValue
	end

	bar.Size = UDim2.new(percentage, 0, 1, 0)

	-- Lógica de color
	if percentage <= 0.25 then
		bar.BackgroundColor3 = COLOR_VIDA_BAJA
	elseif percentage <= 0.6 then
		bar.BackgroundColor3 = COLOR_VIDA_MEDIA
	else
		bar.BackgroundColor3 = COLOR_VIDA_ALTA
	end

	-- Texto
	local textLabel = healthBar:FindFirstChild("HealthValueText")
	if textLabel then
		local currentHealth = math.max(0, math.floor(healthValue))
		local maxHealth = math.floor(maxHealthValue)
		textLabel.Text = currentHealth .. " / " .. maxHealth
	end
end

-- =======================================================
-- FUNCIÓN DE LIMPIEZA (Para la barra de vida)
-- =======================================================
local function cleanupEnemy(enemyModel)
	local data = managedEnemies[enemyModel]

	if not data or typeof(data) ~= "table" then 
		return 
	end

	-- Limpiamos solo si aún no se ha limpiado
	if data.HealthConnection then data.HealthConnection:Disconnect() end
	if data.DestroyConnection then data.DestroyConnection:Disconnect() end

	local partToAttachTo = enemyModel:FindFirstChild("HealthBarAttach") or enemyModel:FindFirstChild("Head") or enemyModel.PrimaryPart
	local healthBar = partToAttachTo and partToAttachTo:FindFirstChild("EnemyHealthBar")
	if healthBar then
		healthBar.Enabled = false
	end

	managedEnemies[enemyModel] = nil
end

-- =======================================================
-- Función para GESTIONAR la barra de vida (está cerca)
-- =======================================================
local function setupEnemy(enemyModel)
	if managedEnemies[enemyModel] then return end 

	local health = enemyModel:WaitForChild("Health", 5)
	local maxHealth = enemyModel:WaitForChild("MaxHealth", 5)

	if not enemyModel.PrimaryPart then
		enemyModel:GetPropertyChangedSignal("PrimaryPart"):Wait()
	end

	local partToAttachTo = enemyModel:FindFirstChild("HealthBarAttach") or enemyModel:FindFirstChild("Head") or enemyModel.PrimaryPart
	local healthBar = partToAttachTo and partToAttachTo:WaitForChild("EnemyHealthBar", 5)

	if not (health and maxHealth and partToAttachTo and healthBar) then 
		warn("Controlador de Vida: Faltan componentes para configurar enemigo " .. enemyModel.Name)
		return 
	end

	-- No imprimimos esto en la consola, es mucho spam
	-- print("Controlador de Vida: Enemigo CERCANO detectado: " .. enemyModel.Name)

	healthBar.Enabled = true

	updateHealthBar(healthBar, health.Value, maxHealth.Value)

	local healthConnection = health.Changed:Connect(function(newHealthValue)
		updateHealthBar(healthBar, newHealthValue, maxHealth.Value)
	end)

	local destroyConnection = enemyModel.Destroying:Connect(function()
		cleanupEnemy(enemyModel)
	end)

	managedEnemies[enemyModel] = {
		HealthConnection = healthConnection,
		DestroyConnection = destroyConnection
	}
end

-- =======================================================
-- BUCLE PRINCIPAL (El "Radar" de la barra de vida)
-- =======================================================
local timeSinceLastCheck = 0
local lastPlayerPosition

RunService.Heartbeat:Connect(function(dt)
	timeSinceLastCheck = timeSinceLastCheck + dt
	if timeSinceLastCheck < CHECK_INTERVAL then
		return 
	end
	timeSinceLastCheck = 0

	local character = player.Character
	if not (character and character.PrimaryPart) then return end
	local playerPosition = character.PrimaryPart.Position

	if lastPlayerPosition and (playerPosition - lastPlayerPosition).Magnitude < 5 then
		-- (Optimización)
	else
		lastPlayerPosition = playerPosition
	end

	local enemiesToProcess = {}
	for enemyModel, _ in pairs(managedEnemies) do
		table.insert(enemiesToProcess, enemyModel)
	end

	-- Limpiar enemigos que se han alejado o desaparecido
	for _, enemyModel in ipairs(enemiesToProcess) do
		if not enemyModel:IsDescendantOf(Workspace) then
			cleanupEnemy(enemyModel)
		elseif enemyModel.PrimaryPart then
			local distanceSquared = (enemyModel.PrimaryPart.Position - playerPosition).Magnitude^2
			if distanceSquared > RENDER_DISTANCE_SQUARED then
				cleanupEnemy(enemyModel)
			end
		end
	end

	-- Buscar nuevos enemigos cercanos para gestionar
	for _, model in ipairs(Workspace:GetChildren()) do
		if model:FindFirstChild("Zone") and model.PrimaryPart then
			local distanceSquared = (model.PrimaryPart.Position - playerPosition).Magnitude^2

			if distanceSquared <= RENDER_DISTANCE_SQUARED then
				setupEnemy(model)
			end
		end
	end
end)


-- =======================================================
-- =======================================================
-- ¡¡NUEVA SECCIÓN: NÚMEROS DE DAÑO FLOTANTES!!
-- =======================================================
-- =======================================================

-- Información de la animación
local TWEEN_INFO_SUBIR = TweenInfo.new(
	0.8, -- Duración de la animación (0.8 segundos)
	Enum.EasingStyle.Quad, -- Estilo de animación
	Enum.EasingDirection.Out -- Dirección (empieza rápido, termina lento)
)
local TWEEN_INFO_FADE = TweenInfo.new(
	0.5, -- Duración del desvanecimiento
	Enum.EasingStyle.Linear,
	Enum.EasingDirection.In,
	0,
	false,
	0.3 -- Retraso (empieza a desvanecerse después de 0.3 segundos)
)

local function showDamageIndicator(partToAttachTo, damage, isCritical)
	-- 1. Clonar la plantilla
	local indicatorClone = DamageIndicatorTemplate:Clone()
	local textLabel = indicatorClone:FindFirstChild("DamageText")
	if not textLabel then return end

	-- 2. Ponerle un pequeño offset aleatorio para que no se apilen
	local randomOffsetX = math.random(-10, 10) / 10 -- entre -1.0 y 1.0 studs
	local randomOffsetZ = math.random(-10, 10) / 10
	indicatorClone.StudsOffset = Vector3.new(randomOffsetX, 0, randomOffsetZ)

	-- 3. Configurar el texto y el color
	textLabel.Text = "-" .. tostring(damage)

	if isCritical then
		textLabel.TextColor3 = COLOR_DANO_CRITICO
		textLabel.TextScaled = false -- Los críticos son más grandes
		textLabel.FontSize = Enum.FontSize.Size32 -- ¡Ajusta este tamaño!
	else
		textLabel.TextColor3 = COLOR_DANO_NORMAL
		textLabel.TextScaled = true -- El daño normal se ajusta
	end

	-- 4. Ponerlo en el mundo y activarlo
	indicatorClone.Parent = partToAttachTo
	indicatorClone.Enabled = true

	-- 5. Crear las animaciones
	-- Animación de subir
	local goalOffset = {StudsOffset = indicatorClone.StudsOffset + Vector3.new(0, 7, 0)} -- Subir 7 studs
	local tweenSubir = TweenService:Create(indicatorClone, TWEEN_INFO_SUBIR, goalOffset)

	-- Animación de desvanecerse
	local goalFade = {TextTransparency = 1}
	local tweenFade = TweenService:Create(textLabel, TWEEN_INFO_FADE, goalFade)

	-- 6. Iniciar animaciones y limpiar
	tweenSubir:Play()
	tweenFade:Play()

	-- 7. Destruir la GUI después de 1 segundo
	Debris:AddItem(indicatorClone, 1)
end


-- ¡CONECTAR EL EVENTO!
-- Esto "escucha" el aviso del servidor y llama a nuestra función.
ShowDamageEvent.OnClientEvent:Connect(showDamageIndicator)