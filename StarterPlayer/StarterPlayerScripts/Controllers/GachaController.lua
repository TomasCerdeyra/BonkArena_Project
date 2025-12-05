-- LocalScript: GachaController (SISTEMA DE APERTURA)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- === REFERENCIAS UI (GACHA) ===
local GachaGui = PlayerGui:WaitForChild("GachaGui")
local Background = GachaGui:WaitForChild("Background")
local EggDisplay = Background:WaitForChild("EggDisplay")
local PetDisplay = Background:WaitForChild("PetDisplay")
local PetNameLabel = Background:WaitForChild("PetNameLabel")
local CloseButton = Background:WaitForChild("CloseButton")
local Sunburst = Background:FindFirstChild("Sunburst") -- Opcional

-- === REFERENCIA AL BOTÓN DE COMPRA (TIENDA) ===
-- Buscamos el botón dentro de la otra GUI (PetHubGui)
local PetHubGui = PlayerGui:WaitForChild("PetHubGui")
local IncubatorButton = PetHubGui:WaitForChild("PetFrame"):WaitForChild("IncubatorButton")

-- === RED ===
local Network = ReplicatedStorage:WaitForChild("Network")
local RequestIncubation = Network:WaitForChild("RequestIncubation") -- RemoteFunction

-- Estado
local isOpening = false

-- ====================================================
-- 1. FUNCIÓN: ANIMACIÓN DE APERTURA
-- ====================================================
local function playEggAnimation(petData)
	GachaGui.Enabled = true

	-- A. Resetear todo a estado inicial
	EggDisplay.Visible = true
	EggDisplay.Rotation = 0
	EggDisplay.Size = UDim2.new(0, 250, 0, 250) -- Tamaño original

	PetDisplay.Visible = false
	PetDisplay.Size = UDim2.new(0, 0, 0, 0) -- Empieza invisible/pequeña
	PetNameLabel.Visible = false
	CloseButton.Visible = false

	if Sunburst then Sunburst.Visible = false end

	-- B. Animación de Sacudida (Shake)
	local shakeInfo = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true)

	-- Hacemos 6 sacudidas izquierda-derecha
	for i = 1, 5 do
		local right = TweenService:Create(EggDisplay, shakeInfo, {Rotation = 15})
		local left = TweenService:Create(EggDisplay, shakeInfo, {Rotation = -15})
		right:Play()
		right.Completed:Wait()
		left:Play()
		left.Completed:Wait()
	end
	-- Volver al centro
	TweenService:Create(EggDisplay, shakeInfo, {Rotation = 0}):Play()

	-- C. Explosión / Revelación
	task.wait(0.1)
	EggDisplay.Visible = false -- ¡Puf! Desaparece el huevo

	-- Mostrar Rayos de Sol (Si existen)
	if Sunburst then
		Sunburst.Visible = true
		Sunburst.Rotation = 0
		-- Hacer que gire infinitamente mientras esté visible
		local spinInfo = TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
		TweenService:Create(Sunburst, spinInfo, {Rotation = 360}):Play()
	end

	-- Mostrar Mascota (Efecto Pop-Up elástico)
	if petData.Image then
		PetDisplay.Image = petData.Image
	else
		PetDisplay.Image = "rbxassetid://13464502203" -- Fallback
	end

	PetDisplay.Visible = true
	local popInfo = TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	-- Lo agrandamos a 450x450
	TweenService:Create(PetDisplay, popInfo, {Size = UDim2.new(0, 450, 0, 450)}):Play()

	-- D. Mostrar Datos Finales
	if petData.IsDuplicate then
		-- TEXTO DE DUPLICADO
		PetNameLabel.Text = string.upper(petData.PetName) .. "\n(REPETIDO: +" .. petData.RefundAmount .. "$)"
		PetNameLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Amarillo Oro
	else
		-- TEXTO DE NUEVA MASCOTA
		PetNameLabel.Text = "¡NUEVO! " .. string.upper(petData.PetName)
		PetNameLabel.TextColor3 = Color3.fromRGB(85, 255, 127) -- Verde Éxito
	end

	PetNameLabel.Visible = true

	-- Pequeña pausa dramática
	task.wait(0.5)
	CloseButton.Visible = true
end

-- ====================================================
-- 2. CONEXIÓN DEL BOTÓN DE COMPRA
-- ====================================================
IncubatorButton.MouseButton1Click:Connect(function()
	if isOpening then return end -- Evitar doble clic
	isOpening = true

	-- Feedback visual de "Cargando..."
	IncubatorButton.Text = "COMPRANDO..."

	-- Llamada al Servidor (Pausa el script hasta recibir respuesta)
	local success, response = pcall(function()
		return RequestIncubation:InvokeServer()
	end)

	if success and response and response.Success then
		-- ¡COMPRA EXITOSA! -> Iniciar el show
		IncubatorButton.Text = "INCUBAR HUEVO (500 BC)" -- Restaurar texto
		playEggAnimation(response) -- response trae {PetName, Image, Rarity}
	else
		-- ERROR (Falta dinero, error de server, etc)
		warn("Error al incubar:", response)
		IncubatorButton.Text = "ERROR / SIN FONDOS"
		task.wait(1)
		IncubatorButton.Text = "INCUBAR HUEVO (500 BC)"
		isOpening = false
	end
end)

-- ====================================================
-- 3. BOTÓN CERRAR
-- ====================================================
CloseButton.MouseButton1Click:Connect(function()
	-- Animación de salida simple
	GachaGui.Enabled = false
	isOpening = false -- Permitir comprar de nuevo
end)