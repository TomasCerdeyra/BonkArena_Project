-- Script: ProductHandler

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

-- Define los productos y cuánto dan
local PRODUCTS = {
	-- Pega tu ID de Producto de Desarrollador aquí
	[3439582471] = {Amount = 100}, -- ID del producto = Monedas que otorga

	-- Puedes añadir más productos aquí si los creas
	-- [ID_OTRO_PRODUCTO] = {Amount = 500}, 
}

-- Esta es la función principal que maneja la compra
local function processReceipt(receiptInfo)

	-- 1. Encontrar al jugador
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Si el jugador se fue justo después de comprar, no podemos darle las monedas
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- 2. Verificar qué producto compró
	local productInfo = PRODUCTS[receiptInfo.ProductId]
	if not productInfo then
		-- El ID del producto no está en nuestra lista
		print("Error: Producto desconocido ID: " .. receiptInfo.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- 3. Entregar las monedas (BonkCoins)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local bonkCoins = leaderstats:FindFirstChild("BonkCoin")
		if bonkCoins then
			bonkCoins.Value = bonkCoins.Value + productInfo.Amount
			print("Compra exitosa: " .. productInfo.Amount .. " BonkCoins añadidas a " .. player.Name)

			-- ¡Importante! Indicar a Roblox que la compra fue exitosa
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	-- Si algo falló (ej. no se encontró leaderstats), intentar de nuevo más tarde
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Conectar la función al servicio de Roblox
MarketplaceService.ProcessReceipt = processReceipt
