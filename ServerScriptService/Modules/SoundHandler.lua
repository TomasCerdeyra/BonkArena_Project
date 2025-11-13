-- Script: SoundHandler (VERSION 4 - Carga Robusta de Sonidos)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

-- Inicialmente nulo. Se llenará al primer uso.
local SoundCache = {} 

local SoundHandler = {}

-- Función auxiliar para inicializar la tabla SoundCache
local function initializeSoundCache()
	-- Solo inicializar una vez
	if next(SoundCache) == nil then 
		local soundsFolder = game.ReplicatedStorage:FindFirstChild("Sounds")

		if soundsFolder then
			for _, sound in pairs(soundsFolder:GetChildren()) do
				if sound:IsA("Sound") then
					-- Almacenamos el sonido por su nombre (Ej: "Shoot", "Hit")
					SoundCache[sound.Name] = sound
				end
			end
		else
			warn("SoundHandler: La carpeta 'Sounds' en ReplicatedStorage no fue encontrada. Los sonidos no funcionarán.")
		end
	end
end


function SoundHandler.playSound(soundName, position)
	-- Inicializamos el caché de sonidos al primer uso
	initializeSoundCache()

	-- El CombatHandler llama a playSound("Shoot"), pero el archivo de sonido
	-- es Sfx_Shoot. Necesitamos mapear si no está en la caché.

	local nameToFind = soundName
	if soundName == "Shoot" and not SoundCache[soundName] and SoundCache["Sfx_Shoot"] then
		nameToFind = "Sfx_Shoot"
	elseif soundName == "Hit" and not SoundCache[soundName] and SoundCache["Sfx_Hit"] then
		nameToFind = "Sfx_Hit"
	elseif soundName == "CriticalHit" and not SoundCache[soundName] and SoundCache["Sfx_CriticalHit"] then
		nameToFind = "Sfx_CriticalHit"
	end

	local soundTemplate = SoundCache[nameToFind]

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
		-- CRÍTICO: Asegurar que el sonido tenga el ID antes de reproducir
		if soundTemplate.SoundId ~= "" then
			soundClone.SoundId = soundTemplate.SoundId
		end

		-- Reproducimos el sonido
		soundClone:Play()

		-- Autodestruir la PARTE
		Debris:AddItem(soundPart, soundClone.TimeLength > 0 and soundClone.TimeLength + 0.1 or 1) -- Evitar error si TimeLength es 0
	else
		warn("SoundHandler: El sonido '" .. soundName .. "' no se encontró.")
	end
end

return SoundHandler