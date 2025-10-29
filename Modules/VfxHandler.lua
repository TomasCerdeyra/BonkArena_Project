-- Script: VfxHandler (VERSION 2 - A�adiendo VFX Cr�tico)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

-- Plantillas de VFX
local Effects = {
	["Hit"] = ReplicatedStorage:WaitForChild("Vfx_Hit"),
	["CriticalHit"] = ReplicatedStorage:WaitForChild("Vfx_CriticalHit")
}

local VfxHandler = {}

-- Funci�n para reproducir un efecto en una posici�n
function VfxHandler.playEffect(effectName, position)
	local vfxTemplate = Effects[effectName]

	if vfxTemplate then
		local vfxClone = vfxTemplate:Clone()
		vfxClone.Position = position
		vfxClone.Parent = Workspace

		-- Activar las part�culas
		vfxClone.ParticleEmitter.Enabled = true

		-- Autodestruir el efecto despu�s de 1 segundo
		Debris:AddItem(vfxClone, 1)
	end
end

return VfxHandler