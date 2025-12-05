-- Script: ServerScriptService/Economy/MarketplaceHandler
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Datos
local ShopData = require(ReplicatedStorage.Shared.Data.ShopData)
local SoundHandler = require(ServerScriptService.Modules.SoundHandler)

-- Función para buscar qué producto es (ya que tenemos listas separadas)
local function getProductInfo(productId)
	-- 1. Buscar en Dinero
	for _, item in ipairs(ShopData.Cash) do
		if item.ProductId == productId then return item, "Cash" end
	end
	-- 2. Buscar en Exclusivos
	for _, item in ipairs(ShopData.Exclusives) do
		if item.ProductId == productId then return item, "Item" end
	end
	return nil
end

-- === PROCESAR RECIBO (DevProducts) ===
local function processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end

	-- Buscar qué compró
	local product, category = getProductInfo(receiptInfo.ProductId)

	if not product then
		warn("MarketplaceHandler: Producto desconocido ID " .. receiptInfo.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	print("Procesando compra de: " .. product.Name .. " para " .. player.Name)

	-- === LÓGICA DE ENTREGA ===
	local success, err = pcall(function()

		if category == "Cash" then
			-- A) ENTREGA DE DINERO
			local leaderstats = player:FindFirstChild("leaderstats")
			local coins = leaderstats and leaderstats:FindFirstChild("BonkCoin")
			if coins then
				coins.Value = coins.Value + product.RewardAmount
				print("?? Se entregaron " .. product.RewardAmount .. " monedas.")
			end

		elseif category == "Item" then
			-- B) ENTREGA DE ÍTEM (Guardar en inventario especial)
			-- Aquí deberías tener una carpeta "SpecialInventory" o similar.
			-- Por ahora, solo imprimimos que lo recibió.
			print("?? Ítem especial comprado: " .. product.ID)

			-- Ejemplo: Dar un báculo si fuera un báculo especial
			-- local staffInv = player:FindFirstChild("StaffInventory")
			-- local newItem = Instance.new("BoolValue", staffInv)
			-- newItem.Name = product.ID
		end

		-- Sonido de éxito (Opcional)
		if player.Character and player.Character.PrimaryPart then
			-- SoundHandler.playSound("Purchase", player.Character.PrimaryPart.Position)
		end
	end)

	if success then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		warn("Error al entregar producto: " .. tostring(err))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

-- Conectar
MarketplaceService.ProcessReceipt = processReceipt