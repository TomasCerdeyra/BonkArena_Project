-- Script: ProductHandler

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

-- Define los productos y cu�nto dan
local PRODUCTS = {
	-- Pega tu ID de Producto de Desarrollador aqu�
	[3439582471] = {Amount = 100}, -- ID del producto = Monedas que otorga

	-- Puedes a�adir m�s productos aqu� si los creas
	-- [ID_OTRO_PRODUCTO] = {Amount = 500}, 
}

-- Esta es la funci�n principal que maneja la compra
local function processReceipt(receiptInfo)

	-- 1. Encontrar al jugador
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Si el jugador se fue justo despu�s de comprar, no podemos darle las monedas
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- 2. Verificar qu� producto compr�
	local productInfo = PRODUCTS[receiptInfo.ProductId]
	if not productInfo then
		-- El ID del producto no est� en nuestra lista
		print("Error: Producto desconocido ID: " .. receiptInfo.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- 3. Entregar las monedas (BonkCoins)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local bonkCoins = leaderstats:FindFirstChild("BonkCoin")
		if bonkCoins then
			bonkCoins.Value = bonkCoins.Value + productInfo.Amount
			print("Compra exitosa: " .. productInfo.Amount .. " BonkCoins a�adidas a " .. player.Name)

			-- �Importante! Indicar a Roblox que la compra fue exitosa
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	-- Si algo fall� (ej. no se encontr� leaderstats), intentar de nuevo m�s tarde
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Conectar la funci�n al servicio de Roblox
MarketplaceService.ProcessReceipt = processReceipt
