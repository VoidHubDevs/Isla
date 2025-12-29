local ESPModule = {}

-- // Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- // Settings (PERFORMANCE)
local UPDATE_INTERVAL = 0.15      -- ESP refresh rate (lower = smoother, higher = faster)
local MAX_DISTANCE = 3000         -- Studs before ESP hides

-- // State
local ESPEnabled = false
local ESPs = {}
local lastUpdate = 0

-- // ESP Folder
local espFolder = game.CoreGui:FindFirstChild("GlobalESP")
if not espFolder then
	espFolder = Instance.new("Folder")
	espFolder.Name = "GlobalESP"
	espFolder.Parent = game.CoreGui
end

-- =========================
-- Team Color
-- =========================
local function getNameColor(plr)
	if not plr or not plr.Team then
		return Color3.fromRGB(255, 255, 255)
	end

	if plr.Team.Name == "Pirates" then
		return Color3.fromRGB(255, 70, 70)
	elseif plr.Team.Name == "Marines" then
		return Color3.fromRGB(70, 130, 255)
	end

	return Color3.fromRGB(255, 255, 255)
end

-- =========================
-- Health Gradient
-- =========================
local function getHealthColor(percent)
	-- Green → Yellow → Red
	if percent > 0.5 then
		return Color3.fromRGB(
			math.clamp(255 * (1 - percent) * 2, 0, 255),
			255,
			0
		)
	else
		return Color3.fromRGB(
			255,
			math.clamp(255 * percent * 2, 0, 255),
			0
		)
	end
end

-- =========================
-- Create ESP
-- =========================
local function createESP(plr)
	if ESPs[plr] or plr == LocalPlayer then return end

	local char = plr.Character
	local head = char and char:FindFirstChild("Head")
	if not head then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = plr.Name
	billboard.Adornee = head
	billboard.Size = UDim2.fromOffset(220, 60)
	billboard.StudsOffset = Vector3.new(0, 3.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Enabled = false
	billboard.Parent = espFolder

	-- Health BG
	local healthBG = Instance.new("Frame")
	healthBG.Size = UDim2.new(1, 0, 0, 4)
	healthBG.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	healthBG.BorderSizePixel = 0
	healthBG.Parent = billboard

	-- Health Bar
	local healthBar = Instance.new("Frame")
	healthBar.Size = UDim2.new(1, 0, 1, 0)
	healthBar.BorderSizePixel = 0
	healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	healthBar.Parent = healthBG

	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 6)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextSize = 16
	nameLabel.TextStrokeTransparency = 0.15
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.Parent = billboard

	-- Info
	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(1, 0, 0.4, 0)
	infoLabel.Position = UDim2.new(0, 0, 0.55, 0)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Font = Enum.Font.SourceSans
	infoLabel.TextSize = 14
	infoLabel.TextStrokeTransparency = 0.25
	infoLabel.TextXAlignment = Enum.TextXAlignment.Center
	infoLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
	infoLabel.Parent = billboard

	ESPs[plr] = {
		Gui = billboard,
		HealthBar = healthBar,
		NameLabel = nameLabel,
		InfoLabel = infoLabel
	}
end

-- =========================
-- Cleanup
-- =========================
local function removeESP(plr)
	if ESPs[plr] then
		if ESPs[plr].Gui then
			ESPs[plr].Gui:Destroy()
		end
		ESPs[plr] = nil
	end
end

-- =========================
-- Player Hooks
-- =========================
Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function()
		task.wait(1)
		createESP(plr)
	end)
end)

Players.PlayerRemoving:Connect(removeESP)

-- =========================
-- Optimized Update Loop
-- =========================
RunService.Heartbeat:Connect(function(dt)
	if not ESPEnabled then
		for _, esp in pairs(ESPs) do
			esp.Gui.Enabled = false
		end
		return
	end

	lastUpdate += dt
	if lastUpdate < UPDATE_INTERVAL then return end
	lastUpdate = 0

	local myChar = LocalPlayer.Character
	local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myHRP then return end

	for plr, esp in pairs(ESPs) do
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local head = char and char:FindFirstChild("Head")

		if not (hrp and hum and head) then
			esp.Gui.Enabled = false
			continue
		end

		local dist = (myHRP.Position - hrp.Position).Magnitude
		if dist > MAX_DISTANCE then
			esp.Gui.Enabled = false
			continue
		end

		esp.Gui.Enabled = true
		esp.Gui.Adornee = head

		-- Name
		esp.NameLabel.Text = plr.DisplayName
		esp.NameLabel.TextColor3 = getNameColor(plr)

		-- Info
		local data = plr:FindFirstChild("Data")
		local lvl = data and data:FindFirstChild("Level")
		local lvlText = lvl and ("Lv. "..lvl.Value) or "Lv. ???"
		esp.InfoLabel.Text = lvlText.." | "..math.floor(dist).."m"

		-- Health
		local hpPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
		esp.HealthBar.Size = UDim2.new(hpPercent, 0, 1, 0)
		esp.HealthBar.BackgroundColor3 = getHealthColor(hpPercent)
	end
end)

-- =========================
-- Public API
-- =========================
function ESPModule:SetESP(state)
	ESPEnabled = state
end

-- Init existing players
for _, plr in pairs(Players:GetPlayers()) do
	if plr ~= LocalPlayer then
		createESP(plr)
	end
end

return ESPModule
