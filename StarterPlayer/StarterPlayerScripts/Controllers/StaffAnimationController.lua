-- LocalScript: StaffAnimationController
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StaffData = require(ReplicatedStorage.Shared.Data.StaffData)

local player = Players.LocalPlayer
local currentTrack = nil

-- Función para reproducir/detener la animación
local function playHoldAnimation(staffName)
	-- 1. Detener cualquier animación de báculo anterior
	if currentTrack then
		currentTrack:Stop()
		currentTrack = nil
	end

	-- 2. Si desequipamos (nombre vacío), terminamos
	if staffName == "" then return end

	-- 3. Cargar la nueva animación
	local data = StaffData[staffName]

	-- Si el báculo no tiene animación definida, no hacer nada
	if not data or not data.HoldAnimID then
		warn("StaffAnimationController: No se encontró HoldAnimID para " .. staffName)
		return
	end

	-- 4. Cargar y reproducir
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator")

	local anim = Instance.new("Animation")
	anim.AnimationId = data.HoldAnimID

	currentTrack = animator:LoadAnimation(anim)
	currentTrack.Priority = Enum.AnimationPriority.Action -- ¡VITAL!
	currentTrack.Looped = true
	currentTrack:Play()
end

-- --- Conexiones ---

-- Esperar a que los datos del jugador (Upgrades) existan
local upgrades = player:WaitForChild("Upgrades")
local equippedStaff = upgrades:WaitForChild("EquippedStaff")

-- Escuchar CADA VEZ que el báculo cambia (en la mochila, tienda, etc.)
equippedStaff.Changed:Connect(playHoldAnimation)

-- Reproducir la animación si ya entraste con un báculo equipado
playHoldAnimation(equippedStaff.Value)