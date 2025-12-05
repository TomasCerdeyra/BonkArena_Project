-- LocalScript: ShopController
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- === DATA ===
local ShopData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Data"):WaitForChild("ShopData"))

-- === REFERENCIAS UI ===
local ShopGui = PlayerGui:WaitForChild("ShopGui")
local MainFrame = ShopGui:WaitForChild("MainFrame")
local TopBar = MainFrame:WaitForChild("TopBar")
local CloseButton = TopBar:WaitForChild("CloseButton")
local ProductsContainer = MainFrame:WaitForChild("ProductsContainer")
local Templates = ShopGui:WaitForChild("Templates")

-- Pestañas
local TabsContainer = TopBar:WaitForChild("TabsContainer")
local TabExclusives = TabsContainer:WaitForChild("TabExclusives")
local TabPasses = TabsContainer:WaitForChild("TabPasses")
local TabCash = TabsContainer:WaitForChild("TabCash")

-- Botón del HUD (Para abrir la tienda)
-- Asumimos que creaste un botón de tienda en tu MenuContainer, si no, usa uno temporal o conéctalo después.
local HUD = PlayerGui:WaitForChild("PlayerHUD")
local ShopButton = HUD:WaitForChild("MenuContainer"):WaitForChild("ShopButton")
-- local ShopButton = HUD:WaitForChild("MenuContainer"):WaitForChild("ShopButton") -- DESCOMENTAR CUANDO TENGAS EL BOTÓN

-- === CONFIGURACIÓN ===
local CURRENT_TAB = "Exclusives" -- Pestaña inicial
local COLORS = {
	Selected = Color3.fromRGB(255, 255, 255), -- Borde blanco para la pestaña activa
	Unselected = Color3.fromRGB(100, 100, 100) -- Oscuro para inactiva
}

-- =================================================================
-- 1. FUNCIÓN: CARGAR PRODUCTOS
-- =================================================================
local function loadProducts(categoryName)
	CURRENT_TAB = categoryName

	-- A. Limpiar contenedor
	for _, child in ipairs(ProductsContainer:GetChildren()) do
		if child:IsA("Frame") or child:IsA("ImageButton") then
			child:Destroy()
		end
	end

	-- B. Obtener lista de datos
	local itemsList = ShopData[categoryName] -- Ej: ShopData.Exclusives
	if not itemsList then return end

	-- C. Crear tarjetas
	for _, itemData in ipairs(itemsList) do
		local card = Templates.ProductTemplate:Clone()
		card.Name = itemData.Name
		card.Parent = ProductsContainer
		card.Visible = true

		-- Llenar datos visuales
		card.TitleLabel.Text = itemData.Name
		card.IconImage.Image = itemData.Image or "rbxassetid://13464502203" -- Fallback

		-- Botón de Precio
		local priceText = "R$ " .. itemData.Price
		if itemData.Price == 0 then priceText = "GRATIS" end
		card.BuyButton.Text = priceText

		-- Lógica de Compra (Clic)
		card.BuyButton.MouseButton1Click:Connect(function()
			print("Intentando comprar: " .. itemData.Name)

			if itemData.Type == "DevProduct" then
				-- Comprar Producto de Desarrollador (Consumible)
				MarketplaceService:PromptProductPurchase(Player, itemData.ProductId)

			elseif itemData.Type == "GamePass" then
				-- Comprar Pase de Juego (Permanente)
				MarketplaceService:PromptGamePassPurchase(Player, itemData.PassId)
			end
		end)
	end
end

-- =================================================================
-- 2. FUNCIÓN: CAMBIAR PESTAÑA (VISUAL)
-- =================================================================
local function switchTab(tabName, buttonRef)
	-- Resetear estilos (opcional, simple por ahora)
	TabExclusives.UIStroke.Color = COLORS.Unselected
	TabPasses.UIStroke.Color = COLORS.Unselected
	TabCash.UIStroke.Color = COLORS.Unselected

	-- Resaltar activa
	if buttonRef:FindFirstChild("UIStroke") then
		buttonRef.UIStroke.Color = COLORS.Selected
	end

	-- Cargar ítems
	loadProducts(tabName)
end

-- =================================================================
-- 3. ABRIR / CERRAR
-- =================================================================
local isOpen = false
local function toggleShop()
	isOpen = not isOpen
	ShopGui.Enabled = isOpen

	if isOpen then
		loadProducts(CURRENT_TAB) -- Recargar al abrir
		-- Animación Pop
		MainFrame.UIScale.Scale = 0.8
		TweenService:Create(MainFrame.UIScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Scale = 1}):Play()
	end
end

-- =================================================================
-- 4. INICIALIZACIÓN
-- =================================================================

-- Asegurar UIScale
if not MainFrame:FindFirstChild("UIScale") then
	local s = Instance.new("UIScale")
	s.Parent = MainFrame
end

-- Conectar Pestañas
TabExclusives.MouseButton1Click:Connect(function() switchTab("Exclusives", TabExclusives) end)
TabPasses.MouseButton1Click:Connect(function() switchTab("Passes", TabPasses) end)
TabCash.MouseButton1Click:Connect(function() switchTab("Cash", TabCash) end)

-- Conectar Cierre
CloseButton.MouseButton1Click:Connect(toggleShop)

-- Conectar Botón del HUD (Si existe)
if ShopButton then 
	ShopButton.MouseButton1Click:Connect(toggleShop) 
end

-- Carga inicial (por si la dejamos abierta en Studio para probar)
switchTab("Exclusives", TabExclusives)