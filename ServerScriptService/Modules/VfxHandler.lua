-- Script: VfxHandler (VERSION 4 - Carga Robusta y Diferida de Plantillas)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Effects = nil 

local VfxHandler = {}

-- Función auxiliar para inicializar la tabla Effects
local function initializeEffects()
	if Effects == nil then
		-- CRÍTICO: Asumiendo que los VFX están directamente en ReplicatedStorage
		Effects = {
			["Hit"] = ReplicatedStorage:WaitForChild("Vfx_Hit"),
			["CriticalHit"] = ReplicatedStorage:WaitForChild("Vfx_CriticalHit"),
			["Shoot"] = ReplicatedStorage:WaitForChild("Vfx_Shoot") -- Nuevo efecto de disparo
		}
	end
end

-- Función para reproducir un efecto en una posición
-- Función para reproducir un efecto en una posición
-- Script: VfxHandler (Función playEffect, CORREGIDA FINAL)
function VfxHandler.playEffect(effectName, position)
	initializeEffects()

	local vfxTemplate = Effects[effectName]

	if vfxTemplate then
		local vfxClone = vfxTemplate:Clone()
		vfxClone.Parent = Workspace 

		local partToMove = nil

		-- ===========================================
		-- 1. Verificar si el CLON ES el objeto a mover (para Partes o Attachments raíz)
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

		-- 3. Búsqueda y activación del emisor (esta parte es correcta)
		local emitter = vfxClone:FindFirstChildOfClass("ParticleEmitter", true)

		if emitter then
			emitter.Enabled = true
		end

		-- Autodestruir el efecto después de 1 segundo
		Debris:AddItem(vfxClone, 1)
	else
		warn("VfxHandler: No se encontró el efecto: " .. effectName)
	end
end

return VfxHandler