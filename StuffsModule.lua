local StuffsModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local PingsOrFpsEnabled = false
local FpsBoostEnabled = false
local InfiniteEnergy = false
local FastAttackEnabled = false
local WalkWaterEnabled = false
local Fog = false
local Lava = false
local V4Enabled = false
local V3Enabled = false
local FruitCheck = false
local TeleportFruit = false

local fpsConn, fastConn, energyConnection, fpsBoostConn = nil, nil, nil, nil
local v4Connection, v3Loop, fruitLoop, teleportLoop = nil, nil, nil, nil

local ScreenGui, MainFrame, FpsLabel, PingLabel, FpsBar, PingBar = nil, nil, nil, nil, nil, nil

local function createModernGui()
	if ScreenGui then return end
	
	local success, parent = pcall(function()
		return LocalPlayer:WaitForChild("PlayerGui")
	end)
	if not success then return end
	
	ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "VoidHubStats"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.Parent = parent
	
	MainFrame = Instance.new("Frame")
	MainFrame.Name = "StatsContainer"
	MainFrame.Size = UDim2.new(0, 220, 0, 80)
	MainFrame.Position = UDim2.new(1, -240, 0, 20)
	MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	MainFrame.BackgroundTransparency = 0.2
	MainFrame.BorderSizePixel = 0
	MainFrame.Parent = ScreenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = MainFrame
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(168, 85, 247)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.5
	stroke.Parent = MainFrame
	
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(168, 85, 247)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(88, 28, 135))
	})
	gradient.Rotation = 45
	gradient.Transparency = NumberSequence.new(0.9)
	gradient.Parent = MainFrame
	
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 20)
	title.Position = UDim2.new(0, 0, 0, 5)
	title.BackgroundTransparency = 1
	title.Text = "PERFORMANCE"
	title.TextColor3 = Color3.fromRGB(200, 200, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 12
	title.Parent = MainFrame
	
	local fpsBg = Instance.new("Frame")
	fpsBg.Name = "FpsBg"
	fpsBg.Size = UDim2.new(0, 200, 0, 6)
	fpsBg.Position = UDim2.new(0, 10, 0, 32)
	fpsBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	fpsBg.BorderSizePixel = 0
	fpsBg.Parent = MainFrame
	
	local fpsBgCorner = Instance.new("UICorner")
	fpsBgCorner.CornerRadius = UDim.new(0, 3)
	fpsBgCorner.Parent = fpsBg
	
	FpsBar = Instance.new("Frame")
	FpsBar.Name = "FpsBar"
	FpsBar.Size = UDim2.new(0, 0, 1, 0)
	FpsBar.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
	FpsBar.BorderSizePixel = 0
	FpsBar.Parent = fpsBg
	
	local fpsBarCorner = Instance.new("UICorner")
	fpsBarCorner.CornerRadius = UDim.new(0, 3)
	fpsBarCorner.Parent = FpsBar
	
	FpsLabel = Instance.new("TextLabel")
	FpsLabel.Name = "FpsLabel"
	FpsLabel.Size = UDim2.new(0, 100, 0, 16)
	FpsLabel.Position = UDim2.new(0, 10, 0, 40)
	FpsLabel.BackgroundTransparency = 1
	FpsLabel.Text = "FPS: --"
	FpsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	FpsLabel.Font = Enum.Font.GothamBold
	FpsLabel.TextSize = 14
	FpsLabel.TextXAlignment = Enum.TextXAlignment.Left
	FpsLabel.Parent = MainFrame
	
	local pingBg = Instance.new("Frame")
	pingBg.Name = "PingBg"
	pingBg.Size = UDim2.new(0, 200, 0, 6)
	pingBg.Position = UDim2.new(0, 10, 0, 62)
	pingBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	pingBg.BorderSizePixel = 0
	pingBg.Parent = MainFrame
	
	local pingBgCorner = Instance.new("UICorner")
	pingBgCorner.CornerRadius = UDim.new(0, 3)
	pingBgCorner.Parent = pingBg
	
	PingBar = Instance.new("Frame")
	PingBar.Name = "PingBar"
	PingBar.Size = UDim2.new(0, 0, 1, 0)
	PingBar.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
	PingBar.BorderSizePixel = 0
	PingBar.Parent = pingBg
	
	local pingBarCorner = Instance.new("UICorner")
	pingBarCorner.CornerRadius = UDim.new(0, 3)
	pingBarCorner.Parent = PingBar
	
	PingLabel = Instance.new("TextLabel")
	PingLabel.Name = "PingLabel"
	PingLabel.Size = UDim2.new(0, 100, 0, 16)
	PingLabel.Position = UDim2.new(0, 10, 0, 68)
	PingLabel.BackgroundTransparency = 1
	PingLabel.Text = "PING: --"
	PingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	PingLabel.Font = Enum.Font.GothamBold
	PingLabel.TextSize = 14
	PingLabel.TextXAlignment = Enum.TextXAlignment.Left
	PingLabel.Parent = MainFrame
	
	MainFrame.Size = UDim2.new(0, 0, 0, 80)
	TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Size = UDim2.new(0, 220, 0, 80)
	}):Play()
end

local function updateBar(bar, label, value, max, prefix, isPing)
	local percent = math.clamp(value / max, 0, 1)
	local color
	if isPing then
		color = value < 80 and Color3.fromRGB(0, 255, 150) or 
				(value < 150 and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(255, 80, 80))
	else
		color = value > 50 and Color3.fromRGB(0, 255, 150) or 
				(value > 30 and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(255, 80, 80))
	end
	
	TweenService:Create(bar, TweenInfo.new(0.2), {
		Size = UDim2.new(percent, 0, 1, 0),
		BackgroundColor3 = color
	}):Play()
	
	label.Text = prefix .. ": " .. math.floor(value)
end

local function startFPSLoop()
	if fpsConn then return end
	
	local lastTime = tick()
	local frameCount = 0
	local displayedFps = 0
	local displayedPing = 0
	
	fpsConn = RunService.RenderStepped:Connect(function()
		if not PingsOrFpsEnabled then
			if ScreenGui then 
				TweenService:Create(MainFrame, TweenInfo.new(0.2), {
					Position = UDim2.new(1, 20, 0, 20)
				}):Play()
				task.wait(0.2)
				ScreenGui.Enabled = false 
			end
			return
		end
		
		createModernGui()
		ScreenGui.Enabled = true
		MainFrame.Position = UDim2.new(1, -240, 0, 20)
		
		frameCount = frameCount + 1
		local now = tick()
		
		if now - lastTime >= 0.5 then
			displayedFps = frameCount * 2
			frameCount = 0
			lastTime = now
			displayedPing = math.floor(LocalPlayer:GetNetworkPing() * 2000)
		end
		
		updateBar(FpsBar, FpsLabel, displayedFps, 144, "FPS", false)
		updateBar(PingBar, PingLabel, displayedPing, 300, "PING", true)
	end)
end

local function stopFPSLoop()
	if fpsConn then
		fpsConn:Disconnect()
		fpsConn = nil
	end
end

local function tryActivateV4AllMethods()
	pcall(function()
		local backpack = LocalPlayer:WaitForChild("Backpack")
		local awakening = backpack:FindFirstChild("Awakening")
		if awakening then
			local remoteFunc = awakening:FindFirstChild("RemoteFunction")
			if remoteFunc then
				remoteFunc:InvokeServer(true)
			end
		end
	end)
	
	pcall(function()
		local backpack = LocalPlayer:WaitForChild("Backpack")
		local awakening = backpack:FindFirstChild("Awakening")
		if awakening then
			local remoteEvent = awakening:FindFirstChild("RemoteEvent")
			if remoteEvent then
				remoteEvent:FireServer(true)
			end
		end
	end)
	
	pcall(function()
		local main = PlayerGui:WaitForChild("Main")
		local raceV4Btn = main:FindFirstChild("RaceV4Button")
		if raceV4Btn and (raceV4Btn:IsA("ImageButton") or raceV4Btn:IsA("TextButton")) then
			if raceV4Btn.Visible and raceV4Btn.Active then
				for _, conn in pairs(getconnections(raceV4Btn.MouseButton1Click)) do
					conn:Fire()
				end
				raceV4Btn:Activate()
			end
		end
	end)
	
	pcall(function()
		local remotes = ReplicatedStorage:WaitForChild("Remotes")
		local commE = remotes:FindFirstChild("CommE")
		if commE then
			commE:FireServer("ActivateAbility")
		end
	end)
	
	pcall(function()
		local main = PlayerGui:WaitForChild("Main")
		local raceV4Btn = main:FindFirstChild("RaceV4Button")
		if raceV4Btn then
			local absPos = raceV4Btn.AbsolutePosition
			local absSize = raceV4Btn.AbsoluteSize
			local clickX = absPos.X + absSize.X / 2
			local clickY = absPos.Y + absSize.Y / 2
			
			VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 1)
			task.wait(0.05)
			VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)
		end
	end)
end

local function startV4Loop()
	if v4Connection then return end
	
	local fillFrame = nil
	pcall(function()
		fillFrame = PlayerGui:WaitForChild("Main"):WaitForChild("RaceEnergy"):WaitForChild("Fill")
	end)
	
	if not fillFrame then
		v4Connection = task.spawn(function()
			while V4Enabled do
				task.wait(1)
				tryActivateV4AllMethods()
			end
			v4Connection = nil
		end)
		return
	end
	
	local lastFire = 0
	v4Connection = fillFrame:GetPropertyChangedSignal("Size"):Connect(function()
		if not V4Enabled then return end
		
		local success, scale = pcall(function()
			return fillFrame.Size.X.Scale
		end)
		
		if success and scale and scale >= 0.9 then
			if tick() - lastFire > 3 then
				lastFire = tick()
				tryActivateV4AllMethods()
			end
		end
	end)
end

local function stopV4Loop()
	V4Enabled = false
	if v4Connection then
		pcall(function() 
			if typeof(v4Connection) == "RBXScriptConnection" then
				v4Connection:Disconnect()
			else
				task.cancel(v4Connection)
			end
		end)
		v4Connection = nil
	end
end

local function tryActivateV3AllMethods()
	pcall(function()
		local remotes = ReplicatedStorage:WaitForChild("Remotes")
		local commE = remotes:FindFirstChild("CommE")
		if commE then
			commE:FireServer("ActivateAbility")
		end
	end)
	
	pcall(function()
		local remotes = ReplicatedStorage:WaitForChild("Remotes")
		local commF = remotes:FindFirstChild("CommF_")
		if commF then
			commF:InvokeServer("ActivateAbility")
		end
	end)
end

local function startV3Loop()
	if v3Loop then return end
	
	v3Loop = task.spawn(function()
		while V3Enabled do
			tryActivateV3AllMethods()
			task.wait(31)
		end
		v3Loop = nil
	end)
end

local function stopV3Loop()
	V3Enabled = false
end

local function Tween(targetCFrame)
	if not targetCFrame then return end
	local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	local info = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
	local goal = {CFrame = hrp.CFrame + Vector3.new(0, 1, 0)}
	TweenService:Create(targetCFrame, info, goal):Play()
end

local function startFruitLoop()
	if fruitLoop then return end
	
	local notifiedFruits = {}
	
	fruitLoop = task.spawn(function()
		while FruitCheck do
			task.wait(0.5)
			
			for _, v in pairs(workspace:GetChildren()) do
				if v:IsA("Tool") and not notifiedFruits[v] then
					notifiedFruits[v] = true
					pcall(function()
						require(ReplicatedStorage.Notification).new(v.Name .. " Spawned"):Display()
					end)
				end
			end
			
			for fruit in pairs(notifiedFruits) do
				if not fruit.Parent then
					notifiedFruits[fruit] = nil
				end
			end
		end
		fruitLoop = nil
	end)
end

local function startTeleportLoop()
	if teleportLoop then return end
	
	teleportLoop = task.spawn(function()
		while TeleportFruit do
			task.wait()
			for _, v in pairs(workspace:GetChildren()) do
				if v:IsA("Tool") and v:FindFirstChild("Handle") then
					Tween(v.Handle)
				end
			end
		end
		teleportLoop = nil
	end)
end

local function FPSBoost()
	Lighting.FogEnd = 1e9
	Lighting.FogStart = 1e9
	Lighting.ClockTime = 12
	Lighting.GlobalShadows = false
	Lighting.Brightness = 2
	Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)

	local Terrain = Workspace:FindFirstChildOfClass("Terrain")
	if Terrain then
		Terrain.WaterWaveSize = 0
		Terrain.WaterWaveSpeed = 0
		Terrain.WaterReflectance = 0
		Terrain.WaterTransparency = 1
	end
	
	for _, v in ipairs(Workspace:GetDescendants()) do
		if v:IsA("BasePart") or v:IsA("UnionOperation") or v:IsA("MeshPart") then
			v.Material = Enum.Material.SmoothPlastic
			v.Reflectance = 0
			v.CastShadow = false
		elseif v:IsA("Decal") or v:IsA("Texture") then
			v:Destroy()
		elseif v:IsA("ParticleEmitter") then
			v.Lifetime = NumberRange.new(0, 0)
		elseif v:IsA("Trail") then
			v.Lifetime = 0
		elseif v:IsA("Explosion") then
			v.BlastPressure = 1
			v.BlastRadius = 1
		elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") then
			v.Enabled = false
		end
	end
	
	if fpsBoostConn then
		fpsBoostConn:Disconnect()
		fpsBoostConn = nil
	end
	
	fpsBoostConn = Workspace.DescendantAdded:Connect(function(v)
		task.wait(0.1)
		if v:IsA("ParticleEmitter") then
			v.Lifetime = NumberRange.new(0, 0)
		elseif v:IsA("Trail") then
			v.Lifetime = 0
		elseif v:IsA("Explosion") then
			v.BlastPressure = 1
			v.BlastRadius = 1
		elseif v:IsA("BasePart") then
			v.CastShadow = false
		elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") then
			v.Enabled = false
		end
	end)
end

local function infiniteStam(state)
	InfiniteEnergy = state
	local character = LocalPlayer.Character
	if not character then return end
	local energy = character:FindFirstChild("Energy")
	if not energy then return end

	if not state then
		if energyConnection then
			energyConnection:Disconnect()
			energyConnection = nil
		end
		return
	end
	
	if not energyConnection then
		energyConnection = energy.Changed:Connect(function()
			if InfiniteEnergy then
				energy.Value = energy.MaxValue
			end
		end)
	end
end

local Config = {
	AttackDistance = 200,
	AttackMobs = true,
	AttackPlayers = true,
	AttackCooldown = 0.001,
	ComboResetTime = 0.001,
	MaxCombo = 2,
	HitboxLimbs = {"RightLowerArm", "RightUpperArm", "LeftLowerArm", "LeftUpperArm", "RightHand", "LeftHand"},
	AutoClickEnabled = true
}

local FastAttack = {}
FastAttack.__index = FastAttack

function FastAttack.new()
	local self = setmetatable({
		Debounce = 0,
		ComboDebounce = 0,
		ShootDebounce = 0,
		M1Combo = 0,
		EnemyRootPart = nil,
		Connections = {},
		CombatFlags = nil,
		ShootFunction = nil,
		HitFunction = nil,
		SpecialShoots = {}
	}, FastAttack)
	
	pcall(function()
		local Modules = ReplicatedStorage:WaitForChild("Modules")
		local Net = Modules:WaitForChild("Net")
		
		self.RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
		self.RegisterHit = Net:WaitForChild("RE/RegisterHit")
		self.ShootGunEvent = Net:WaitForChild("RE/ShootGunEvent")
		self.GunValidator = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Validator2")
		
		local FlagsModule = Modules:FindFirstChild("Flags")
		if FlagsModule then
			local flags = require(FlagsModule)
			if flags and flags.COMBAT_REMOTE_THREAD then
				self.CombatFlags = flags.COMBAT_REMOTE_THREAD
			end
		end
		
		local CombatController = ReplicatedStorage:FindFirstChild("Controllers") and 
								ReplicatedStorage.Controllers:FindFirstChild("CombatController")
		if CombatController then
			local combatMod = require(CombatController)
			if combatMod and combatMod.Attack then
				self.ShootFunction = getupvalue(combatMod.Attack, 9)
			end
		end
		
		local playerScripts = LocalPlayer:WaitForChild("PlayerScripts")
		local localScript = playerScripts:FindFirstChildOfClass("LocalScript")
		if localScript and getsenv then
			local env = getsenv(localScript)
			if env and env._G and env._G.SendHitsToServer then
				self.HitFunction = env._G.SendHitsToServer
			end
		end
	end)
	
	return self
end

function FastAttack:IsEntityAlive(entity)
	local humanoid = entity and entity:FindFirstChildOfClass("Humanoid")
	return humanoid and humanoid.Health > 0
end

function FastAttack:CheckStun(Character, Humanoid, ToolTip)
	local Stun = Character:FindFirstChild("Stun")
	local Busy = Character:FindFirstChild("Busy")
	
	if Humanoid.Sit and (ToolTip == "Sword" or ToolTip == "Melee" or ToolTip == "Blox Fruit") then
		return false
	elseif Stun and Stun.Value > 0 or Busy and Busy.Value then
		return false
	end
	return true
end

function FastAttack:GetBladeHits(Character, Distance)
	local Position = Character:GetPivot().Position
	local BladeHits = {}
	Distance = Distance or Config.AttackDistance
	
	local function ProcessTargets(Folder, CanAttack)
		if not Folder then return end
		for _, Enemy in ipairs(Folder:GetChildren()) do
			if Enemy ~= Character and self:IsEntityAlive(Enemy) then
				local limbName = Config.HitboxLimbs[math.random(#Config.HitboxLimbs)]
				local BasePart = Enemy:FindFirstChild(limbName) or Enemy:FindFirstChild("HumanoidRootPart")
				if BasePart and (Position - BasePart.Position).Magnitude <= Distance then
					if not self.EnemyRootPart then
						self.EnemyRootPart = BasePart
					else
						table.insert(BladeHits, {Enemy, BasePart})
					end
				end
			end
		end
	end
	
	if Config.AttackMobs then
		ProcessTargets(Workspace:FindFirstChild("Enemies"))
	end
	if Config.AttackPlayers then
		ProcessTargets(Workspace:FindFirstChild("Characters"))
	end
	
	return BladeHits
end

function FastAttack:GetClosestEnemy(Character, Distance)
	local BladeHits = self:GetBladeHits(Character, Distance)
	local Closest, MinDistance = nil, math.huge
	
	for _, Hit in ipairs(BladeHits) do
		local Magnitude = (Character:GetPivot().Position - Hit[2].Position).Magnitude
		if Magnitude < MinDistance then
			MinDistance = Magnitude
			Closest = Hit[2]
		end
	end
	return Closest
end

function FastAttack:GetCombo()
	local Combo = (tick() - self.ComboDebounce) <= Config.ComboResetTime and self.M1Combo or 0
	Combo = Combo >= Config.MaxCombo and 1 or Combo + 1
	self.ComboDebounce = tick()
	self.M1Combo = Combo
	return Combo
end

function FastAttack:ShootInTarget(TargetPosition)
	local Character = LocalPlayer.Character
	if not self:IsEntityAlive(Character) then return end
	
	local Equipped = Character:FindFirstChildOfClass("Tool")
	if not Equipped or Equipped.ToolTip ~= "Gun" then return end
	
	local Cooldown = Equipped:FindFirstChild("Cooldown") and Equipped.Cooldown.Value or 0.3
	if (tick() - self.ShootDebounce) < Cooldown then return end
	
	local ShootType = self.SpecialShoots[Equipped.Name] or "Normal"
	
	pcall(function()
		Equipped:SetAttribute("LocalTotalShots", (Equipped:GetAttribute("LocalTotalShots") or 0) + 1)
		self.GunValidator:FireServer(self:GetValidator2())
		
		if ShootType == "TAP" and Equipped:FindFirstChild("RemoteEvent") then
			Equipped.RemoteEvent:FireServer("TAP", TargetPosition)
		else
			self.ShootGunEvent:FireServer(TargetPosition)
		end
	end)
	
	self.ShootDebounce = tick()
end

function FastAttack:GetValidator2()
	if not self.ShootFunction then return 0, 0 end
	
	local v1 = getupvalue(self.ShootFunction, 15) or 0
	local v2 = getupvalue(self.ShootFunction, 13) or 1
	local v3 = getupvalue(self.ShootFunction, 16) or 1
	local v4 = getupvalue(self.ShootFunction, 17) or 1
	local v5 = getupvalue(self.ShootFunction, 14) or 0
	local v6 = getupvalue(self.ShootFunction, 12) or 0
	local v7 = getupvalue(self.ShootFunction, 18) or 0
	
	local v8 = v6 * v2
	local v9 = (v5 * v2 + v6 * v1) % v3
	v9 = (v9 * v3 + v8) % v4
	v5 = math.floor(v9 / v3)
	v6 = v9 - v5 * v3
	v7 = v7 + 1
	
	setupvalue(self.ShootFunction, 15, v1)
	setupvalue(self.ShootFunction, 13, v2)
	setupvalue(self.ShootFunction, 16, v3)
	setupvalue(self.ShootFunction, 17, v4)
	setupvalue(self.ShootFunction, 14, v5)
	setupvalue(self.ShootFunction, 12, v6)
	setupvalue(self.ShootFunction, 18, v7)
	
	return math.floor(v9 / v4 * 16777215), v7
end

function FastAttack:UseNormalClick(Character, Humanoid, Cooldown)
	self.EnemyRootPart = nil
	local BladeHits = self:GetBladeHits(Character)
	
	if self.EnemyRootPart and self.RegisterAttack and self.RegisterHit then
		self.RegisterAttack:FireServer(Cooldown)
		if self.CombatFlags and self.HitFunction then
			self.HitFunction(self.EnemyRootPart, BladeHits)
		else
			self.RegisterHit:FireServer(self.EnemyRootPart, BladeHits)
		end
	end
end

function FastAttack:UseFruitM1(Character, Equipped, Combo)
	local range = Config.AttackDistance
	local Targets = self:GetBladeHits(Character, range)
	if not Targets[1] then return end

	local Direction = (Targets[1][2].Position - Character:GetPivot().Position).Unit
	if Equipped.LeftClickRemote then
		Equipped.LeftClickRemote:FireServer(Direction, Combo)
	end
end

function FastAttack:Attack()
	if not Config.AutoClickEnabled or (tick() - self.Debounce) < Config.AttackCooldown then return end
	
	local Character = LocalPlayer.Character
	if not Character or not self:IsEntityAlive(Character) then return end
	
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	local Equipped = Character:FindFirstChildOfClass("Tool")
	if not Equipped or not Humanoid then return end
	
	local ToolTip = Equipped.ToolTip
	if not table.find({"Melee", "Blox Fruit", "Sword", "Gun"}, ToolTip) then return end
	
	local Cooldown = Equipped:FindFirstChild("Cooldown") and Equipped.Cooldown.Value or Config.AttackCooldown
	if not self:CheckStun(Character, Humanoid, ToolTip) then return end
	
	local Combo = self:GetCombo()
	Cooldown = Cooldown + (Combo >= Config.MaxCombo and 0.05 or 0)
	self.Debounce = Combo >= Config.MaxCombo and ToolTip ~= "Gun" and (tick() + 0.05) or tick()
	
	if ToolTip == "Blox Fruit" and Equipped:FindFirstChild("LeftClickRemote") then
		self:UseFruitM1(Character, Equipped, Combo)
	elseif ToolTip == "Gun" then
		local Target = self:GetClosestEnemy(Character, 120)
		if Target then
			self:ShootInTarget(Target.Position)
		end
	else
		self:UseNormalClick(Character, Humanoid, Cooldown)
	end
end

local AttackInstance = FastAttack.new()

local function startFastAttack()
	if fastConn then return end
	fastConn = RunService.Stepped:Connect(function()
		if FastAttackEnabled then
			AttackInstance:Attack()
		end
	end)
end

local function stopFastAttack()
	if fastConn then
		fastConn:Disconnect()
		fastConn = nil
	end
end

local function setWalkWater(state)
	WalkWaterEnabled = state
	local waterPart = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("WaterBase-Plane")
	if waterPart then
		waterPart.Size = state and Vector3.new(1000, 110, 1000) or Vector3.new(1000, 80, 1000)
	end
end

local function removeLava()
	for _, v in pairs(Workspace:GetDescendants()) do
		if v.Name == "Lava" then
			v:Destroy()
		end
	end
	for _, v in pairs(ReplicatedStorage:GetDescendants()) do
		if v.Name == "Lava" then
			v:Destroy()
		end
	end
end

function StuffsModule:SetFpsBoost(state)
	FpsBoostEnabled = state
	if state then
		FPSBoost()
	else
		if fpsBoostConn then
			fpsBoostConn:Disconnect()
			fpsBoostConn = nil
		end
	end
end

function StuffsModule:SetINFEnergy(state)
	infiniteStam(state)
end

function StuffsModule:SetFog(state)
	Fog = state
	if state then
		Lighting.FogEnd = 100000
		for _, v in pairs(Lighting:GetDescendants()) do
			if v:IsA("Atmosphere") then
				v:Destroy()
			end
		end
	end
end

function StuffsModule:SetLava(state)
	Lava = state
	if state then removeLava() end
end

function StuffsModule:SetRejoinServer()
	local TeleportService = game:GetService("TeleportService")
	TeleportService:Teleport(game.PlaceId, LocalPlayer)
end

function StuffsModule:SetFastAttack(state)
	FastAttackEnabled = state
	if state then
		startFastAttack()
	else
		stopFastAttack()
	end
end

function StuffsModule:SetWalkWater(state)
	setWalkWater(state)
end

function StuffsModule:SetPingsOrFps(state)
	PingsOrFpsEnabled = state
	if state then
		startFPSLoop()
	else
		stopFPSLoop()
	end
end

function StuffsModule:SetV4(state)
	V4Enabled = state
	if state then
		startV4Loop()
	else
		stopV4Loop()
	end
end

function StuffsModule:SetV3(state)
	V3Enabled = state
	if state then
		startV3Loop()
	else
		stopV3Loop()
	end
end

function StuffsModule:SetFruitCheck(state)
	FruitCheck = state
	if state then
		startFruitLoop()
	end
end

function StuffsModule:SetTeleportFruit(state)
	TeleportFruit = state
	if state then
		startTeleportLoop()
	end
end

LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	if InfiniteEnergy then
		infiniteStam(true)
	end
end)

return StuffsModule
