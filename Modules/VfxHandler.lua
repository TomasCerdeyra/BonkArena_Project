-- Script: VfxHandler (VERSION 2 - Añadiendo VFX Crítico)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

-- Plantillas de VFX
local Effects = {
	["Hit"] = ReplicatedStorage:WaitForChild("Vfx_Hit"),
	["CriticalHit"] = ReplicatedStorage:WaitForChild("Vfx_CriticalHit")
}

local VfxHandler = {}

-- Función para reproducir un efecto en una posición
function VfxHandler.playEffect(effectName, position)
	local vfxTemplate = Effects[effectName]

	if vfxTemplate then
		local vfxClone = vfxTemplate:Clone()
		vfxClone.Position = position
		vfxClone.Parent = Workspace

		-- Activar las partículas
		vfxClone.ParticleEmitter.Enabled = true

		-- Autodestruir el efecto después de 1 segundo
		Debris:AddItem(vfxClone, 1)
	end
end

return VfxHandler