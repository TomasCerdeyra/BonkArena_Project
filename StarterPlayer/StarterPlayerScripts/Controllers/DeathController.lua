-- Script: DeathController (Cliente)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Configuración
local RESPAWN_TIME = 3 -- Segundos que tarda en reaparecer

-- Referencias UI
local deathGui = playerGui:WaitForChild("DeathGui")
local background = deathGui:WaitForChild("Background")
local title = background:WaitForChild("Title")
local subtitle = background:WaitForChild("SubTitle")

-- Tweens
local fadeInInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local fadeOutInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local function showDeathScreen()
	deathGui.Enabled = true

	-- 1. Resetear transparencias
	background.BackgroundTransparency = 1
	title.TextTransparency = 1
	subtitle.TextTransparency = 1

	-- 2. Animar Entrada (Fade In)
	TweenService:Create(background, fadeInInfo, {BackgroundTransparency = 0.3}):Play() -- Fondo semitransparente oscuro
	TweenService:Create(title, fadeInInfo, {TextTransparency = 0}):Play()
	TweenService:Create(subtitle, fadeInInfo, {TextTransparency = 0}):Play()

	-- 3. Cuenta Regresiva
	for i = RESPAWN_TIME, 1, -1 do
		subtitle.Text = "Reapareciendo en " .. i .. "..."
		task.wait(1)
	end

	-- 4. Ocultar (Fade Out) justo antes de respawnear
	TweenService:Create(background, fadeOutInfo, {BackgroundTransparency = 1}):Play()
	TweenService:Create(title, fadeOutInfo, {TextTransparency = 1}):Play()
	TweenService:Create(subtitle, fadeOutInfo, {TextTransparency = 1}):Play()

	task.wait(0.5)
	deathGui.Enabled = false
end

local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")

	-- Desactivar que se desarme como Lego (Opcional, se ve más pro)
	humanoid.BreakJointsOnDeath = false

	humanoid.Died:Connect(function()
		showDeathScreen()
	end)
end

player.CharacterAdded:Connect(onCharacterAdded)

-- Si ya existe al entrar
if player.Character then
	onCharacterAdded(player.Character)
end