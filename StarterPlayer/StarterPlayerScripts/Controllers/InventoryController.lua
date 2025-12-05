-- LocalScript: InventoryController (SISTEMA DE MOCHILA ESCALABLE)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- === 1. CONFIGURACIÓN Y REFERENCIAS ===

-- Referencias a la GUI de Inventario
local InvGui = PlayerGui:WaitForChild("InventoryGui")
local MainFrame = InvGui:WaitForChild("MainFrame")
local CategoriesContainer = MainFrame:WaitForChild("CategoriesContainer")
local ItemsContainer = MainFrame:WaitForChild("ItemsContainer")
local Templates = InvGui:WaitForChild("Templates") -- Tu carpeta con los moldes
local CloseButton = MainFrame:WaitForChild("TopInfo"):WaitForChild("CloseButton")

-- Referencias al Botón del HUD (Para abrir la mochila)
local HUD = PlayerGui:WaitForChild("PlayerHUD")
local InvButton = HUD:WaitForChild("MenuContainer"):WaitForChild("InventoryButton")

-- Colores para el diseño (Activo / Inactivo)
local COLORS = {
	Active = Color3.fromRGB(85, 255, 127),   -- Verde (Seleccionado)
	Inactive = Color3.fromRGB(60, 60, 60),   -- Gris (No seleccionado)
	TextActive = Color3.fromRGB(20, 20, 20), -- Texto oscuro
	TextInactive = Color3.fromRGB(230, 230, 230) -- Texto claro
}

-- TABLA MAESTRA DE CATEGORÍAS (¡Aquí agregas cosas nuevas!)
-- Name: Texto del botón. 
-- Folder: Nombre de la carpeta en el Player.
-- EquipEvent: Nombre del evento remoto para equipar ese tipo de ítem.
local CATEGORIES = {
	{ 
		Name = "Báculos", 
		Folder = "StaffInventory", 
		EquipEvent = "RequestEquipStaff",
		EquipVal = "EquippedStaff", -- Nombre del StringValue en Upgrades
		DataModule = "StaffData"
	},
	{ 
		Name = "Mascotas", 
		Folder = "PetInventory", 
		EquipEvent = "RequestEquipPet",
		EquipVal = "EquippedPet",
		DataModule = "PetData"
	},
	-- Futuro ejemplo:
	-- { Name = "Sombreros", Folder = "HatInventory", EquipEvent = "RequestEquipHat", EquipVal = "EquippedHat" },
}

local currentCategoryIndex = 1 -- Empezamos en la 1 (Báculos)
local isOpen = false

-- =================================================================
-- 2. FUNCIONES VISUALES (Pintar botones)
-- =================================================================
local function updateCategoryVisuals()
	for _, button in ipairs(CategoriesContainer:GetChildren()) do
		if button:IsA("TextButton") then
			local index = button:GetAttribute("CategoryIndex")

			-- Animación de color suave
			local targetColor = (index == currentCategoryIndex) and COLORS.Active or COLORS.Inactive
			local targetTextColor = (index == currentCategoryIndex) and COLORS.TextActive or COLORS.TextInactive

			TweenService:Create(button, TweenInfo.new(0.2), {
				BackgroundColor3 = targetColor,
				TextColor3 = targetTextColor
			}):Play()
		end
	end
end

-- =================================================================
-- 3. CARGAR ÍTEMS (Llenar la grilla)
-- =================================================================
local function loadItems(categoryIndex)
	currentCategoryIndex = categoryIndex
	updateCategoryVisuals() -- Actualizar pestañas visualmente

	-- A. Limpiar grilla anterior
	for _, item in ipairs(ItemsContainer:GetChildren()) do
		if item:IsA("ImageButton") then
			item:Destroy()
		end
	end

	-- B. Obtener datos de la categoría
	local catData = CATEGORIES[categoryIndex]

	-- --- VERIFICACIÓN DE SEGURIDAD (NUEVO) ---
	if not catData.DataModule then
		warn("InventoryController: Falta 'DataModule' en la configuración de " .. catData.Name)
		return
	end

	-- Buscar la carpeta y el módulo con seguridad
	local sharedData = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Data")
	local dataModule = sharedData:FindFirstChild(catData.DataModule)

	if not dataModule then
		warn("InventoryController: No se encontró el archivo '" .. catData.DataModule .. "' en ReplicatedStorage/Shared/Data")
		return
	end

	-- Cargar la información
	local itemsInfo = require(dataModule)
	if not itemsInfo then
		warn("InventoryController: El módulo '" .. catData.DataModule .. "' no devolvió ninguna tabla (revisa el 'return').")
		return
	end
	-- ----------------------------------------

	local inventoryFolder = Player:FindFirstChild(catData.Folder)
	if not inventoryFolder then return end -- Si no ha cargado aún

	local upgrades = Player:WaitForChild("Upgrades")
	local equippedValue = upgrades:FindFirstChild(catData.EquipVal)

	-- C. Crear botones
	local items = inventoryFolder:GetChildren()

	for _, itemValue in ipairs(items) do
		-- 1. Buscar datos en la tabla cargada
		local info = itemsInfo[itemValue.Name] -- AQUÍ DABA EL ERROR

		-- 2. Filtro: Si el ítem no existe en la lista oficial, lo ignoramos (Fantasma)
		if not info then
			-- warn("Ocultando ítem desconocido o borrado: " .. itemValue.Name)
			continue 
		end

		-- 3. Clonar Plantilla
		local itemButton = Templates.ItemTemplate:Clone()
		itemButton.Name = itemValue.Name
		itemButton.Parent = ItemsContainer
		itemButton.Visible = true

		-- Texto
		local nameLabel = itemButton:FindFirstChild("ItemName")
		if nameLabel then nameLabel.Text = info.Name end 

		-- Imagen
		if info.Image then
			itemButton.Image = info.Image
		else
			itemButton.Image = "rbxassetid://13464502203" -- Interrogación por defecto
		end

		-- Estado Equipado
		local statusLabel = itemButton:FindFirstChild("Status")
		local isEquipped = (equippedValue and equippedValue.Value == itemValue.Name)

		if isEquipped then
			if statusLabel then statusLabel.Visible = true end
			local stroke = itemButton:FindFirstChild("UIStroke")
			if stroke then stroke.Color = COLORS.Active end
		else
			if statusLabel then statusLabel.Visible = false end
		end

		-- Clic para Equipar
		itemButton.MouseButton1Click:Connect(function()
			local event = ReplicatedStorage:WaitForChild("Network"):FindFirstChild(catData.EquipEvent)
			if event then
				event:FireServer(itemValue.Name)
				task.wait(0.1) -- Breve espera para que el servidor procese
				if isOpen and currentCategoryIndex == categoryIndex then
					loadItems(categoryIndex) -- Recargar visualmente
				end
			end
		end)
	end
end
-- =================================================================
-- 4. INICIALIZAR CATEGORÍAS (Crear pestañas arriba)
-- =================================================================
local function initCategories()
	-- Limpiar botones viejos si hubiera
	for _, child in ipairs(CategoriesContainer:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	-- Crear botones basados en la tabla CATEGORIES
	for i, catData in ipairs(CATEGORIES) do
		local btn = Templates.CategoryTemplate:Clone()
		btn.Name = catData.Name
		btn.Text = catData.Name
		btn.Parent = CategoriesContainer
		btn.Visible = true

		-- Guardamos el índice para saber cuál es
		btn:SetAttribute("CategoryIndex", i)

		btn.MouseButton1Click:Connect(function()
			loadItems(i)
		end)
	end
end

-- =================================================================
-- 5. ABRIR / CERRAR (Animación Pop-up)
-- =================================================================
local function toggleInventory()
	isOpen = not isOpen

	if isOpen then
		InvGui.Enabled = true
		loadItems(currentCategoryIndex) -- Cargar la última pestaña usada

		-- Efecto Pop de entrada
		MainFrame.UIScale.Scale = 0.8
		TweenService:Create(MainFrame.UIScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Scale = 1}):Play()
	else
		-- Efecto de salida
		InvGui.Enabled = false 
		-- (Podrías agregar tween de salida si quieres, pero así es más rápido)
	end
end

-- === SETUP INICIAL ===

-- Asegurar que MainFrame tenga UIScale para la animación
if not MainFrame:FindFirstChild("UIScale") then
	local s = Instance.new("UIScale")
	s.Parent = MainFrame
end

initCategories() -- Generar las pestañas

-- Conectar botones
InvButton.MouseButton1Click:Connect(toggleInventory)
if CloseButton then
	CloseButton.MouseButton1Click:Connect(toggleInventory)
end