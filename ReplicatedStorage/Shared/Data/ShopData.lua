local ShopData = {}

-- =================================================================
-- 1. EXCLUSIVOS (Items Permanentes / Engranaje)
-- Estos son DevProducts (se pueden comprar varias veces, pero aquí actuamos como si fueran únicos)
-- o Gamepasses si quieres que sean únicos de verdad. 
-- Para simplificar, usaremos el concepto de "Item" que se guarda en inventario.
-- =================================================================

-- ID TEMPORAL (Tu producto de 100 Monedas) ams adelante cambiarlo a cada uno
local PLACEHOLDER_ID = 3439582471
ShopData.Exclusives = {
	{
		ID = "FlyingCarpet", -- Identificador interno
		Type = "DevProduct", -- O "GamePass"
		ProductId = PLACEHOLDER_ID, -- ¡AQUÍ IRÁ EL ID DE ROBLOX! (Pon 0 por ahora)
		Price = 375,
		Name = "Alfombra Voladora",
		Image = "rbxassetid://118170724169726", -- Tu foto
		Description = "¡Vuela por el lobby con estilo!",
	},
	{
		ID = "BanHammer",
		Type = "DevProduct",
		ProductId = PLACEHOLDER_ID,
		Price = 1499,
		Name = "Martillo de Ban",
		Image = "rbxassetid://698605568",
		Description = "Lanza a los jugadores a la luna.",
	}
}

-- =================================================================
-- 2. PASES DE JUEGO (Beneficios Permanentes)
-- Estos SIEMPRE son GamePasses.
-- =================================================================
ShopData.Passes = {
	{
		ID = "VIP",
		Type = "GamePass",
		PassId = 1586599588, -- ID del GamePass
		Price = 499,
		Name = "VIP",
		Image = "rbxassetid://10936093413",
		Description = "Nombre dorado, Chat VIP y +10% XP.",
	},
	{
		ID = "x2Money",
		Type = "GamePass",
		PassId = 1586793472, 
		Price = 169,
		Name = "x2 Dinero",
		Image = "rbxassetid://4821311994",
		Description = "Gana el doble de monedas por siempre.",
	}
}

-- =================================================================
-- 3. DINERO (Monedas del Juego)
-- Estos son DevProducts consumibles.
-- =================================================================
ShopData.Cash = {
	{
		ID = "Coins_Small",
		Type = "DevProduct",
		ProductId = PLACEHOLDER_ID, -- ID del Producto de Desarrollador
		Price = 15,
		RewardAmount = 100, -- Cuántas monedas da
		Name = "Puuñado de Monedas",
		Image = "rbxassetid://18209598819",
	},
	{
		ID = "Coins_Medium",
		Type = "DevProduct",
		ProductId = PLACEHOLDER_ID,
		Price = 59,
		RewardAmount = 3000,
		Name = "Pila de Billetes",
		Image = "rbxassetid://18629620812",
	},
	{
		ID = "Coins_Large",
		Type = "DevProduct",
		ProductId = PLACEHOLDER_ID,
		Price = 379,
		RewardAmount = 25000,
		Name = "Maletín de Dinero",
		Image = "rbxassetid://18209598650",
	},
	{
		ID = "Coins_Large",
		Type = "DevProduct",
		ProductId = PLACEHOLDER_ID,
		Price = 379,
		RewardAmount = 25000,
		Name = "Maletín de Dinero",
		Image = "rbxassetid://18209598650",
	}
}

return ShopData