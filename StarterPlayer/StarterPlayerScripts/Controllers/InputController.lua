-- LocalScript: InputController (DASH + UI VISUAL)
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService") -- Nuevo servicio

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") -- Referencia a la GUI

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- === REFERENCIAS UI ===
local HUD = playerGui:WaitForChild("PlayerHUD")
-- Busca el icono que acabas de crear. Ajusta la ruta si le pusiste otro nombre.
local DashUI = HUD:FindFirstChild("SkillContainer") and HUD.SkillContainer:FindFirstChild("DashIcon")
local CooldownOverlay = DashUI and DashUI:FindFirstChild("CooldownOverlay")

-- Configuración
local ACTION_NAME = "DashAction"
local DASH_POWER = 80 
local DASH_TIME = 0.15
local DASH_COOLDOWN = 2

local lastDashTime = 0
local isDashing = false

-- Actualizar referencias
player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = newChar:WaitForChild("Humanoid")
	rootPart = newChar:WaitForChild("HumanoidRootPart")
end)

-- Efecto Visual (Viento)
local function playDashVisuals()
	local attach = Instance.new("Attachment")
	attach.Parent = rootPart

	local emitter = Instance.new("ParticleEmitter")
	emitter.Parent = attach
	emitter.Texture = "rbxassetid://243098098"
	emitter.Rate = 50
	emitter.Lifetime = NumberRange.new(0.2, 0.4)
	emitter.Speed = NumberRange.new(10)
	emitter.Color = ColorSequence.new(Color3.new(1,1,1))
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})

	emitter:Emit(10)
	Debris:AddItem(attach, 1)
end

-- === FUNCIÓN VISUAL DE COOLDOWN ===
local function playCooldownAnimation()
	if not CooldownOverlay then return end

	-- 1. Poner oscuro (Inicio del Cooldown)
	CooldownOverlay.Visible = true
	CooldownOverlay.Size = UDim2.new(1, 0, 1, 0)
	CooldownOverlay.BackgroundTransparency = 0.2

	-- 2. Animar hacia abajo (como un reloj o cortina)
	-- O simplemente desvanecer. Haremos un efecto de "cortina bajando".

	local tweenInfo = TweenInfo.new(DASH_COOLDOWN, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(CooldownOverlay, tweenInfo, {
		Size = UDim2.new(1, 0, 0, 0), -- Se achica verticalmente
		Position = UDim2.new(0, 0, 1, 0) -- Se va hacia abajo
	})

	tween:Play()

	tween.Completed:Connect(function()
		-- Restaurar posición al terminar
		CooldownOverlay.Visible = false
		CooldownOverlay.Size = UDim2.new(1, 0, 1, 0)
		CooldownOverlay.Position = UDim2.new(0, 0, 0, 0)
	end)
end

-- La Función del Dash
local function performDash(actionName, inputState, inputObject)
	if inputState ~= Enum.UserInputState.Begin then return end

	local now = tick()
	if now - lastDashTime < DASH_COOLDOWN then return end
	if isDashing then return end

	-- Dirección
	local moveDir = humanoid.MoveDirection
	if moveDir.Magnitude == 0 then
		moveDir = rootPart.CFrame.LookVector
	end

	isDashing = true
	lastDashTime = now

	-- Activar UI
	playCooldownAnimation()

	-- Física
	local attachment = Instance.new("Attachment")
	attachment.Parent = rootPart

	local velocity = Instance.new("LinearVelocity")
	velocity.Parent = rootPart
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.MaxForce = math.huge 
	velocity.VectorVelocity = moveDir * DASH_POWER

	playDashVisuals()

	task.delay(DASH_TIME, function()
		velocity:Destroy()
		attachment:Destroy()
		isDashing = false
	end)
end

-- Conexión
ContextActionService:BindAction(
	ACTION_NAME,    
	performDash,    
	true,           
	Enum.KeyCode.Q, 
	Enum.KeyCode.ButtonX 
)

-- === CONFIGURACIÓN MÓVIL MEJORADA ===
local touchButton = ContextActionService:GetButton(ACTION_NAME)
if touchButton then
	-- 1. Texto Grande y Claro
	touchButton:SetTitle("DASH") 

	-- 2. (Opcional) Icono: Si prefieres imagen, descomenta y pon tu ID
	-- touchButton.Image = "rbxassetid://12703359609" -- Icono de correr

	-- 3. Posición Estratégica (Lejos del salto)
	-- UDim2.new(0.6, 0, 0.6, 0) lo mueve más arriba y a la izquierda
	ContextActionService:SetPosition(ACTION_NAME, UDim2.new(0.6, -20, 0.6, 0))

	-- 4. Tamaño (Hacerlo un poco más grande para dedos)
	-- Nota: ContextActionService usa Size interno, pero podemos intentar forzarlo
	touchButton.Size = UDim2.new(0, 60, 0, 60)
end