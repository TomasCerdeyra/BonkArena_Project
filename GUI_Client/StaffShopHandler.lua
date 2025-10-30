-- Script: StaffShopHandler (VERSION 6 - Correcci�n de Acceso a BonkCoin)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = game.Players.LocalPlayer

-- RemoteEvents
local OpenStaffShop = ReplicatedStorage:WaitForChild("OpenStaffShop") 
local RequestStaffBuy = ReplicatedStorage:WaitForChild("RequestStaffBuy")
local RequestEquipStaff = ReplicatedStorage:WaitForChild("RequestEquipStaff")

-- GUI References (Aseg�rate que coincidan con tu redise�o)
local StaffShopGui = script.Parent
local StaffFrame = StaffShopGui:WaitForChild("StaffFrame")
local StaffListContainer = StaffFrame:WaitForChild("StaffListContainer") 
local CloseButton = StaffFrame:WaitForChild("CloseButton")
local StaffButtonTemplate = StaffListContainer:WaitForChild("StaffButtonTemplate") 

-- Referencias a las carpetas del jugador
local Upgrades = Player:WaitForChild("Upgrades")
local StaffInventory = Player:WaitForChild("StaffInventory")
local leaderstats = Player:WaitForChild("leaderstats") -- Referencia a la carpeta

local equippedStaffValue 
local staffConfigData 
local connections = {} 

-- =======================================================
-- 1. GENERACI�N DE BOTONES DE B�CULOS (L�gica Completa)
-- =======================================================
-- [Esta funci�n permanece sin cambios desde V5]
local function generateStaffButtons()
	StaffButtonTemplate.Visible = false

	-- Limpiar botones antiguos
	for _, item in ipairs(StaffListContainer:GetChildren()) do
		if item:IsA("TextButton") and item ~= StaffButtonTemplate then
			item:Destroy()
		end
	end

	if not staffConfigData then
		warn("StaffShopHandler: No hay datos de configuraci�n de b�culos para mostrar.")
		return
	end

	-- Recorrer la configuraci�n de b�culos 
	for staffId, data in pairs(staffConfigData) do

		local button = StaffButtonTemplate:Clone()
		button.Name = staffId
		button.Visible = true
		button.Parent = StaffListContainer

		-- Referencias a los labels de la plantilla 
		local nameLabel = button:WaitForChild("StaffNameLabel")
		local statsLabel = button:WaitForChild("StatsLabel")
		local priceButton = button:WaitForChild("PriceButton")
		local statusLabel = button:WaitForChild("StatusLabel")

		-- Llenar datos
		nameLabel.Text = data.Name
		statsLabel.Text = data.Description or ("Cadencia: " .. data.AttackRate .. "/s")

		-- Verificar estado (Pose�do, Equipado, Comprable)
		local isOwned = StaffInventory:FindFirstChild(staffId)
		local isEquipped = (equippedStaffValue.Value == staffId)

		if isEquipped then
			-- B�culo equipado actualmente
			statusLabel.Text = "(EQUIPADO)"
			priceButton.Text = "EQUIPADO"
			priceButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100) -- Gris
			priceButton.Active = false 

		elseif isOwned then
			-- B�culo pose�do, pero no equipado
			statusLabel.Text = "(POSE�DO)"
			priceButton.Text = "EQUIPAR"
			priceButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0) -- Verde
			priceButton.Active = true 

			priceButton.MouseButton1Click:Connect(function()
				RequestEquipStaff:FireServer(staffId)
			end)

		else
			-- B�culo no pose�do (Comprable)
			statusLabel.Text = ""
			priceButton.Text = "COMPRAR: " .. data.Cost
			priceButton.BackgroundColor3 = Color3.fromRGB(0, 85, 255) -- Azul
			priceButton.Active = true 

			priceButton.MouseButton1Click:Connect(function()
				RequestStaffBuy:FireServer(staffId)
			end)
		end
	end
end


-- =======================================================
-- 2. CONEXIONES DE GUI
-- =======================================================

-- Cierre
CloseButton.MouseButton1Click:Connect(function()
	StaffShopGui.Enabled = false
	-- Desconectar listeners cuando se cierra la GUI para ahorrar memoria
	for _, connection in pairs(connections) do
		connection:Disconnect()
	end
	connections = {}
end)

-- Apertura (Disparado por el servidor cuando tocas el HUB)
OpenStaffShop.OnClientEvent:Connect(function(staffConfig)

	-- 1. Asignar las variables 
	equippedStaffValue = Upgrades:WaitForChild("EquippedStaff")
	staffConfigData = staffConfig 

	-- 2. Limpiar conexiones antiguas (si el jugador la abre y cierra r�pido)
	for _, connection in pairs(connections) do
		connection:Disconnect()
	end
	connections = {}

	-- 3. Habilitar GUI y generar botones
	StaffShopGui.Enabled = true
	generateStaffButtons() 

	-- 4. CR�TICO: Conectar los listeners AHORA que las variables existen
	connections["StaffAdded"] = StaffInventory.ChildAdded:Connect(generateStaffButtons)
	connections["StaffRemoved"] = StaffInventory.ChildRemoved:Connect(generateStaffButtons)
	connections["StaffEquipped"] = equippedStaffValue.Changed:Connect(generateStaffButtons)

	-- CORRECCI�N DEL ERROR 'nil with Changed'
	local bonkCoinValue = leaderstats:WaitForChild("BonkCoin")
	connections["CoinsChanged"] = bonkCoinValue.Changed:Connect(generateStaffButtons) 

end)

-- Inicialmente, la GUI est� deshabilitada.
StaffShopGui.Enabled = false