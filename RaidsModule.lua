local RaidsModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local backpack = player:WaitForChild("Backpack")
local character = player.Character or player.CharacterAdded:Wait()

local function getHRP()
    local char = player.Character or player.CharacterAdded:Wait()
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
end

local waterPart = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("WaterBase-Plane")

local Auto_Buy_Chips_Raid = false
local Auto_StartRaidSecond = false
local Auto_StartRaidThird = false
local AutoNextIsland = false
local AutoKill = false
local FastAttackEnabled = false
local bringmob = false
local AutoAwakenAbilities = false
local Autofruit = false
local BringFruits = false
local WalkWaterEnabled = false
local NoClip = false

local SelectChip = nil
local weaponsToCheck = {"Godhuman", "Sanguine Art", "Dragon Talon"}

local function checkForWeapons()
	for _, weaponName in ipairs(weaponsToCheck) do
		if backpack:FindFirstChild(weaponName) or (player.Character and player.Character:FindFirstChild(weaponName)) then
			return weaponName
		end
	end
	return nil
end

local SelectWeapon = checkForWeapons()

local function safeInvokeRemote(remote, ...)
    if not remote then return end
    pcall(function() remote:InvokeServer(...) end)
end

local function safeFire(remote, ...)
    if not remote then return end
    pcall(function() remote:FireServer(...) end)
end

local function equipTool(toolName)
    pcall(function()
        local bp = player:FindFirstChild("Backpack")
        if not bp then return end
        local tool = bp:FindFirstChild(toolName) or player.Character and player.Character:FindFirstChild(toolName)
        if tool and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
            player.Character.Humanoid:EquipTool(tool)
        end
    end)
end

local function safeWaitForChild(parent, name, timeout)
    timeout = timeout or 5
    if not parent then return nil end
    local ok, res = pcall(function() return parent:WaitForChild(name, timeout) end)
    if ok then return res end
    return parent:FindFirstChild(name)
end

local VirtualInputManager = game:GetService("VirtualInputManager")
local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")

local Remotes = safeWaitForChild(ReplicatedStorage, "Remotes")
local Validator = Remotes and safeWaitForChild(Remotes, "Validator")
local CommF = Remotes and safeWaitForChild(Remotes, "CommF_")
local CommE = Remotes and safeWaitForChild(Remotes, "CommE")

local ChestModels = workspace:FindFirstChild("ChestModels")
local WorldOrigin = workspace:FindFirstChild("_WorldOrigin")
local Characters = workspace:FindFirstChild("Characters")
local Enemies = workspace:FindFirstChild("Enemies")
local Map = workspace:FindFirstChild("Map")

local EnemySpawns = WorldOrigin and safeWaitForChild(WorldOrigin, "EnemySpawns")
local Locations = WorldOrigin and safeWaitForChild(WorldOrigin, "Locations")

local Modules = safeWaitForChild(ReplicatedStorage, "Modules")
local Net = Modules and safeWaitForChild(Modules, "Net")
local RegisterAttack = Net and Net:FindFirstChild("RE/RegisterAttack")
local RegisterHit = Net and Net:FindFirstChild("RE/RegisterHit")

local Settings = {
    AutoClick = true,
    ClickDelay = 0,
}

do
    local FastAttack
    if _G.rz_FastAttack then
        FastAttack = _G.rz_FastAttack
    else
        FastAttack = {
            Distance = 100,
            attackMobs = true,
            attackPlayers = true,
            Equipped = nil
        }

        local function IsAlive(model)
            return model and model:FindFirstChild("Humanoid") and model.Humanoid.Health > 0
        end

        local function ProcessEnemies(OthersEnemies, Folder)
            local BasePart = nil
            if not Folder or not Folder.GetChildren then return nil end
            for _, Enemy in ipairs(Folder:GetChildren()) do
                local Head = Enemy:FindFirstChild("Head")
                local hrp = getHRP()
                if Head and IsAlive(Enemy) and hrp and (hrp.Position - Head.Position).Magnitude < FastAttack.Distance then
                    if Enemy ~= player.Character then
                        table.insert(OthersEnemies, { Enemy, Head })
                        BasePart = Head
                    end
                end
            end
            return BasePart
        end

        function FastAttack:Attack(BasePart, OthersEnemies)
            if not BasePart or #OthersEnemies == 0 then return end
            safeFire(RegisterAttack, Settings.ClickDelay or 0)
            safeFire(RegisterHit, BasePart, OthersEnemies)
        end

        function FastAttack:AttackNearest()
            local OthersEnemies = {}
            local Part1 = ProcessEnemies(OthersEnemies, Enemies)
            local Part2 = ProcessEnemies(OthersEnemies, Characters)
            if #OthersEnemies > 0 then
                FastAttack:Attack(Part1 or Part2, OthersEnemies)
            else
                task.wait(0)
            end
        end

        function FastAttack:BladeHits()
            local Equipped = player.Character and player.Character:FindFirstChildOfClass("Tool")
            if Equipped and Equipped.ToolTip ~= "Gun" then
                FastAttack:AttackNearest()
            else
                task.wait(0)
            end
        end

        task.spawn(function()
            while task.wait(Settings.ClickDelay) do
                if Settings.AutoClick and FastAttackEnabled then
                    FastAttack:BladeHits()
                end
            end
        end)

        _G.rz_FastAttack = FastAttack
    end
end

local function tweenToCFrame(targetCFrame)
    local hrp = getHRP()
    if not hrp or not targetCFrame then return end
    local Distance = (targetCFrame.Position - hrp.Position).Magnitude
    local Speed = 350
    local tweenInfo = TweenInfo.new(math.max(Distance / Speed, 0.01), Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    return tween
end

local function teleportInstant(point)
    pcall(function()
        local hrp = getHRP()
        if hrp then hrp.CFrame = point end
    end)
end

RunService.Heartbeat:Connect(function()
    if bringmob and player.Character and getHRP() then
        pcall(function()
            local hrp = getHRP()
            local enemyList = workspace:FindFirstChild("Enemies")
            if not enemyList or not hrp then return end

            local nearestEnemy = nil
            local nearestDistance = math.huge
            local MAX_RANGE = 400

            for _, enemy in pairs(enemyList:GetChildren()) do
                local hrpEnemy = enemy:FindFirstChild("HumanoidRootPart")
                local hum = enemy:FindFirstChild("Humanoid")
                if hrpEnemy and hum and hum.Health > 0 then
                    local dist = (hrpEnemy.Position - hrp.Position).Magnitude
                    if dist < nearestDistance and dist <= MAX_RANGE then
                        nearestEnemy = hrpEnemy
                        nearestDistance = dist
                    end
                end
            end

            if nearestEnemy then
                local abovePos = nearestEnemy.CFrame * CFrame.new(0, 25, 0)
                tweenToCFrame(abovePos)
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(2) do
        if Auto_Buy_Chips_Raid and SelectChip then
            pcall(function()
                local playerGui = player:FindFirstChild("PlayerGui")
                local main = playerGui and playerGui:FindFirstChild("Main")
                local timerVisible = main and main:FindFirstChild("Timer") and main.Timer.Visible
                if timerVisible == false then
                    if not backpack:FindFirstChild("Special Microchip") then
                        safeInvokeRemote(CommF, "RaidsNpc", "Select", SelectChip)
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            if not Auto_StartRaidSecond then return end

            local playerGui = player:FindFirstChild("PlayerGui")
            local mainGui = playerGui and playerGui:FindFirstChild("Main")
            local timerVisible = mainGui and mainGui:FindFirstChild("Timer") and mainGui.Timer.Visible

            if timerVisible == false then
                local hasChip = backpack and backpack:FindFirstChild("Special Microchip")

                if hasChip then
                    while Auto_StartRaidSecond and timerVisible == false and backpack:FindFirstChild("Special Microchip") do
                        local cd = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("CircleIsland")
                        cd = cd and cd:FindFirstChild("RaidSummon2") and cd.RaidSummon2:FindFirstChild("Button")
                        cd = cd and cd:FindFirstChild("Main") and cd.Main:FindFirstChild("ClickDetector")
                        if cd then
                            pcall(function() fireclickdetector(cd) end)
                        end

                        task.wait(0.6)

                        playerGui = player:FindFirstChild("PlayerGui")
                        mainGui = playerGui and playerGui:FindFirstChild("Main")
                        timerVisible = mainGui and mainGui:FindFirstChild("Timer") and mainGui.Timer.Visible
                        if not backpack then break end
                    end
                end
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            if not Auto_StartRaidThird then return end

            local playerGui = player:FindFirstChild("PlayerGui")
            local mainGui = playerGui and playerGui:FindFirstChild("Main")
            local timerVisible = mainGui and mainGui:FindFirstChild("Timer") and mainGui.Timer.Visible

            if timerVisible == false then
                local hasChip = backpack and backpack:FindFirstChild("Special Microchip")

                if hasChip then
                    while Auto_StartRaidThird and timerVisible == false and backpack:FindFirstChild("Special Microchip") do
                        local cd = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Boat Castle")
                        cd = cd and cd:FindFirstChild("RaidSummon2") and cd.RaidSummon2:FindFirstChild("Button")
                        cd = cd and cd:FindFirstChild("Main") and cd.Main:FindFirstChild("ClickDetector")
                        if cd then
                            pcall(function() fireclickdetector(cd) end)
                        end

                        task.wait(0.6)

                        playerGui = player:FindFirstChild("PlayerGui")
                        mainGui = playerGui and playerGui:FindFirstChild("Main")
                        timerVisible = mainGui and mainGui:FindFirstChild("Timer") and mainGui.Timer.Visible
                        if not backpack then break end
                    end
                end
            end
        end)
    end
end)

task.spawn(function()
    local visitedIslands = {}

    while task.wait(1) do
        if AutoNextIsland then
            pcall(function()
                local hrp = getHRP()
                local locations = WorldOrigin and WorldOrigin:FindFirstChild("Locations")
                if not hrp or not locations then return end

                local pos = hrp.Position
                if (pos - Vector3.new(-6438.73535, 250.645355, -4501.50684)).Magnitude < 5
                    or (pos - Vector3.new(-5017.40869, 314.844055, -2823.0127)).Magnitude < 5 then
                    visitedIslands = {}
                end

                for i = 1, 5 do
                    local islandName = "Island " .. i
                    local island = locations:FindFirstChild(islandName)

                    if island and not visitedIslands[islandName] then
                        local distance = (island.Position - hrp.Position).Magnitude

                        if distance <= 3400 then
                            tweenToCFrame(island.CFrame)
                            visitedIslands[islandName] = true
                            task.wait(0.5)
                        end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if AutoKill then
	        equipTool(SelectWeapon)
			pcall(function()
                safeInvokeRemote(CommF, "Buso")
            end)
        end
    end
end)

task.spawn(function()
    while task.wait() do
        if AutoAwakenAbilities then
            pcall(function()
                safeInvokeRemote(CommF, "Awakener", "Awaken")
            end)
        end
    end
end)

task.spawn(function()
	local CommFLocal = CommF
	local fruits = {
		"Rocket-Rocket","Spin-Spin","Chop-Chop","Spring-Spring","Bomb-Bomb","Smoke-Smoke","Spike-Spike",
		"Flame-Flame","Falcon-Falcon","Ice-Ice","Sand-Sand","Dark-Dark","Ghost-Ghost","Diamond-Diamond",
		"Light-Light","Rubber-Rubber","Barrier-Barrier"
	}

	local function hasFruitInList()
		local bp = player:FindFirstChild("Backpack")
		if bp then
			for _, item in pairs(bp:GetChildren()) do
				for _, fruitName in ipairs(fruits) do
					if item.Name == fruitName then
						return true, item.Name
					end
				end
			end
		end
		return false, nil
	end

	while task.wait(1) do
		pcall(function()
			if Autofruit then
				local hasFruit, ownedFruit = hasFruitInList()
				if hasFruit then
					task.wait(3)
					return
				end

				local fruitLoaded = false
				for _, fruitName in ipairs(fruits) do
					if not hasFruit then
						local ok, success = pcall(function() return CommFLocal and CommFLocal:InvokeServer("LoadFruit", fruitName) end)
						if ok and success then
							fruitLoaded = true
							break
						end
					end
				end

				if not fruitLoaded then
					task.wait(10)
				end
			end
		end)
	end
end)

local StuffsStored = {}

local function isLavaPart(part)
    if not part or not part:IsA("BasePart") then return false end
    local n = part.Name and part.Name:lower() or ""
    if n:find("lava") or n:find("magma") or n:find("kill") or n:find("damage") then
        return true
    end
    local c = part.BrickColor and part.BrickColor.Name or ""
    if c:lower():find("red") or c:lower():find("orange") then
        return true
    end
    return false
end

local LavaEnabled = false

local function disableLavaOnce()
    for _, v in ipairs(workspace:GetDescendants()) do
        if isLavaPart(v) and not StuffsStored[v] then
            StuffsStored[v] = {
                CanTouch = v.CanTouch,
                CanCollide = v.CanCollide,
                Transparency = v.Transparency,
                Anchored = v.Anchored
            }
            pcall(function()
                v.CanTouch = false
                v.CanCollide = false
                v.Transparency = math.max(v.Transparency, 0.6)
                v.Anchored = true
            end)
        end
    end
end

local function restoreLavaOnce()
    for part, props in pairs(StuffsStored) do
        pcall(function()
            if part and part.Parent then
                part.CanTouch = props.CanTouch
                part.CanCollide = props.CanCollide
                part.Transparency = props.Transparency
                part.Anchored = props.Anchored
            end
        end)
    end
    table.clear(StuffsStored)
end

task.spawn(function()
    while task.wait(1) do
        if LavaEnabled then
            pcall(disableLavaOnce)
        end
    end
end)

local function createRemoveLavaGui()
    local success, err = pcall(function()
        local playerGui = player:FindFirstChild("PlayerGui")
        if not playerGui then return end

        if playerGui:FindFirstChild("CPS_RemoveLavaGui") then return end

        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "CPS_RemoveLavaGui"
        screenGui.ResetOnSpawn = false
        screenGui.Parent = playerGui

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 200, 0, 70)
        frame.Position = UDim2.new(0.02, 0, 0.6, 0)
        frame.BackgroundColor3 = Color3.fromRGB(16,16,16)
        frame.BorderSizePixel = 0
        frame.AnchorPoint = Vector2.new(0,0)
        frame.Parent = screenGui

        local corner = Instance.new("UICorner", frame)
        corner.CornerRadius = UDim.new(0, 8)

        local title = Instance.new("TextLabel", frame)
        title.Size = UDim2.new(1, -16, 0, 20)
        title.Position = UDim2.new(0, 8, 0, 6)
        title.BackgroundTransparency = 1
        title.Text = "Remove Lava"
        title.Font = Enum.Font.GothamSemibold
        title.TextSize = 14
        title.TextColor3 = Color3.fromRGB(240,240,240)
        title.TextXAlignment = Enum.TextXAlignment.Left

        local flameLabel = Instance.new("TextLabel", frame)
        flameLabel.Size = UDim2.new(1, -16, 0, 18)
        flameLabel.Position = UDim2.new(0, 8, 0, 30)
        flameLabel.BackgroundTransparency = 1
        flameLabel.Text = "Lava: OFF"
        flameLabel.Font = Enum.Font.Gotham
        flameLabel.TextSize = 12
        flameLabel.TextColor3 = Color3.fromRGB(200,200,200)
        flameLabel.TextXAlignment = Enum.TextXAlignment.Left

        local toggle = Instance.new("TextButton", frame)
        toggle.Size = UDim2.new(0, 60, 0, 28)
        toggle.Position = UDim2.new(1, -68, 0, 22)
        toggle.BackgroundColor3 = Color3.fromRGB(36,36,36)
        toggle.BorderSizePixel = 0
        toggle.Text = "OFF"
        toggle.Font = Enum.Font.GothamBold
        toggle.TextSize = 12
        toggle.TextColor3 = Color3.fromRGB(240,240,240)

        local dragActive = false
        local dragStart, startPos

        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragActive = true
                dragStart = input.Position
                startPos = frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragActive = false
                    end
                end)
            end
        end)

        frame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        game:GetService("UserInputService").InputChanged:Connect(function(input)
            if dragActive and dragStart and input.Position and startPos then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)

        local function updateUI()
            flameLabel.Text = "Lava: " .. (LavaEnabled and "ON" or "OFF")
            toggle.Text = LavaEnabled and "ON" or "OFF"
            toggle.BackgroundColor3 = LavaEnabled and Color3.fromRGB(0,180,120) or Color3.fromRGB(36,36,36)
        end

        toggle.MouseButton1Click:Connect(function()
            LavaEnabled = not LavaEnabled
            if LavaEnabled then
                pcall(disableLavaOnce)
            else
                pcall(restoreLavaOnce)
            end
            updateUI()
        end)

        task.spawn(function()
            while screenGui and screenGui.Parent do
                updateUI()
                task.wait(0.8)
            end
        end)
    end)
    if not success then
        -- GUI not critical; ignore errors
    end
end

createRemoveLavaGui()

function RaidsModule:SetWalkWater(state)
    WalkWaterEnabled = state
    if waterPart then
        if WalkWaterEnabled then
            pcall(function() waterPart.Size = Vector3.new(1000,110,1000) end)
        else
            pcall(function() waterPart.Size = Vector3.new(1000,80,1000) end)
        end
    end
end

function RaidsModule:SetBuyChip(state) Auto_Buy_Chips_Raid = state end
function RaidsModule:SetNoClip(state) NoClip = state end
function RaidsModule:SetStartRaidSecond(state) Auto_StartRaidSecond = state end
function RaidsModule:SetStartRaidThird(state) Auto_StartRaidThird = state end

function RaidsModule:SetAutoRaid(state)
    AutoKill = state
    bringmob = state
    FastAttackEnabled = state
end

function RaidsModule:SetAutoAwaken(state) AutoAwakenAbilities = state end
function RaidsModule:SetBringFruits(state) BringFruits = state end
function RaidsModule:SetGetFruits(state) Autofruit = state end
function RaidsModule:SetNextIsland(state) AutoNextIsland = state end
function RaidsModule:SetSelectChip(chip) SelectChip = chip end

return RaidsModule
