-- Script: SoundHandler (VERSION 3 - Añadiendo Sonido Crítico)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

-- Plantillas de Sonido (MODIFICADO)
local Sounds = {
	["Shoot"] = ReplicatedStorage:WaitForChild("Sfx_Shoot"),
	["Hit"] = ReplicatedStorage:WaitForChild("Sfx_Hit"),
	["CriticalHit"] = ReplicatedStorage:WaitForChild("Sfx_CriticalHit") -- NUEVO
}

local SoundHandler = {}

-- Función para reproducir un sonido en una posición específica (sin cambios)
function SoundHandler.playSound(soundName, position)
	local soundTemplate = Sounds[soundName]

	if soundTemplate then
		local soundClone = soundTemplate:Clone()

		-- Creamos una parte temporal e invisible para contener el sonido.
		local soundPart = Instance.new("Part")
		soundPart.Anchored = true
		soundPart.CanCollide = false
		soundPart.Transparency = 1
		soundPart.Size = Vector3.new(1, 1, 1) -- Tamaño mínimo
		soundPart.Position = position
		soundPart.Parent = Workspace

		-- Hacemos que el sonido sea hijo de la parte
		soundClone.Parent = soundPart

		-- Reproducimos el sonido
		soundClone:Play()

		-- Autodestruir la PARTE
		Debris:AddItem(soundPart, soundClone.TimeLength + 0.1) 
	end
end

return SoundHandler