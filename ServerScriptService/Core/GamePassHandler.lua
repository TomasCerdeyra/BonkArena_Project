-- Script: GamePassHandler (Maneja VIP y x2)
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopData = require(ReplicatedStorage.Shared.Data.ShopData)

-- Buscar IDs automáticamente desde ShopData
local VIP_ID = 0
local X2_ID = 0

for _, pass in ipairs(ShopData.Passes) do
	if pass.ID == "VIP" then VIP_ID = pass.PassId end
	if pass.ID == "x2Money" then X2_ID = pass.PassId end
end

-- Función para activar VIP
local function activateVIP(player)
	if player:GetAttribute("IsVip") then return end
	player:SetAttribute("IsVip", true)

	print("?? Activando VIP para " .. player.Name)

	-- Poner etiqueta visual
	local function addTag(character)
		local head = character:WaitForChild("Head", 10)
		if head and not head:FindFirstChild("VipTag") then
			local bg = Instance.new("BillboardGui")
			bg.Name = "VipTag"
			bg.Adornee = head
			bg.Size = UDim2.new(0, 200, 0, 50)
			bg.StudsOffset = Vector3.new(0, 2.5, 0)
			bg.AlwaysOnTop = true

			local label = Instance.new("TextLabel")
			label.Parent = bg
			label.Size = UDim2.new(1, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.Text = "?? VIP ??"
			label.TextColor3 = Color3.fromRGB(255, 215, 0)
			label.TextStrokeTransparency = 0
			label.Font = Enum.Font.FredokaOne
			label.TextScaled = true
			bg.Parent = head
		end
	end

	if player.Character then addTag(player.Character) end
	player.CharacterAdded:Connect(addTag)
end

-- Función para activar x2 Dinero
local function activateX2(player)
	if player:GetAttribute("HasX2") then return end

	-- ¡AQUÍ ESTÁ LA MAGIA! Ponemos el atributo para que RewardManager lo lea
	player:SetAttribute("HasX2", true)
	print("?? Activando x2 Dinero para " .. player.Name)
end

-- Chequeo Inicial (Al entrar)
local function checkPasses(player)
	-- Revisar VIP
	local s1, hasVip = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_ID) end)
	if s1 and hasVip then activateVIP(player) end

	-- Revisar x2
	local s2, hasX2 = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId, X2_ID) end)
	if s2 and hasX2 then activateX2(player) end
end

Players.PlayerAdded:Connect(checkPasses)

-- Chequeo de Compra en Vivo (Al comprar)
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
	if wasPurchased then
		if passId == VIP_ID then
			activateVIP(player)
		elseif passId == X2_ID then
			activateX2(player) -- ¡Esto actualiza el atributo al instante!
		end
	end
end)