-- Script: VfxHandler (VERSION 4 - Carga Robusta y Diferida de Plantillas)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Effects = nil 

local VfxHandler = {}

-- Funci�n auxiliar para inicializar la tabla Effects
local function initializeEffects()
	if Effects == nil then
		-- CR�TICO: Asumiendo que los VFX est�n directamente en ReplicatedStorage
		Effects = {
			["Hit"] = ReplicatedStorage:WaitForChild("Vfx_Hit"),
			["CriticalHit"] = ReplicatedStorage:WaitForChild("Vfx_CriticalHit"),
			["Shoot"] = ReplicatedStorage:WaitForChild("Vfx_Shoot") -- Nuevo efecto de disparo
		}
	end
end

-- Funci�n para reproducir un efecto en una posici�n
-- Funci�n para reproducir un efecto en una posici�n
-- Script: VfxHandler (Funci�n playEffect, CORREGIDA FINAL)
function VfxHandler.playEffect(effectName, position)
	initializeEffects()

	local vfxTemplate = Effects[effectName]

	if vfxTemplate then
		local vfxClone = vfxTemplate:Clone()
		vfxClone.Parent = Workspace 

		local partToMove = nil

		-- ===========================================
		-- 1. Verificar si el CLON ES el objeto a mover (para Partes o Attachments ra�z)
		-- ===========================================
		if vfxClone:IsA("BasePart") or vfxClone:IsA("Attachment") then
			partToMove = vfxClone
		else
			-- 2. Si es un Folder/Model, buscar la primera parte o attachment dentro
			partToMove = vfxClone:FindFirstChildOfClass("BasePart") or vfxClone:FindFirstChildOfClass("Attachment")
		end
		-- ===========================================

		if partToMove then
			partToMove.Position = position
		end

		-- 3. B�squeda y activaci�n del emisor (esta parte es correcta)
		local emitter = vfxClone:FindFirstChildOfClass("ParticleEmitter", true)

		if emitter then
			emitter.Enabled = true
		end

		-- Autodestruir el efecto despu�s de 1 segundo
		Debris:AddItem(vfxClone, 1)
	else
		warn("VfxHandler: No se encontr� el efecto: " .. effectName)
	end
end

return VfxHandler