local RaidsModule = {}

local player = game.Players.LocalPlayer
local backpack = player:WaitForChild("Backpack")
local character = player.Character or player.CharacterAdded:Wait()
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
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
		if backpack:FindFirstChild(weaponName) or character:FindFirstChild(weaponName) then
			return weaponName
		end
	end
	return nil
end

local SelectWeapon = checkForWeapons()

function AutoHaki()
    if not game:GetService("Players").LocalPlayer.Character:FindFirstChild("HasBuso") then
        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("Buso")
    end
end

function EquipTool(ToolSe)
    if game.Players.LocalPlayer.Backpack:FindFirstChild(ToolSe) then
        local tool = game.Players.LocalPlayer.Backpack:FindFirstChild(ToolSe)
        wait()
        game.Players.LocalPlayer.Character.Humanoid:EquipTool(tool)
    end
end

do
    local _ENV = (getgenv or getrenv or getfenv)()

    local function SafeWaitForChild(parent, childName)
        local success, result = pcall(function()
            return parent:WaitForChild(childName)
        end)
        if not success or not result then
            warn("noooooo: " .. childName)
        end
        return result
    end

    local function WaitChilds(path, ...)
        local last = path
        for _, child in {...} do
            last = last:FindFirstChild(child) or SafeWaitForChild(last, child)
            if not last then break end
        end
        return last
    end

    local VirtualInputManager = game:GetService("VirtualInputManager")
    local CollectionService = game:GetService("CollectionService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local TeleportService = game:GetService("TeleportService")
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local Player = Players.LocalPlayer

    if not Player then
        warn("Không tìm thấy người chơi cục bộ.")
        return
    end

    local Remotes = SafeWaitForChild(ReplicatedStorage, "Remotes")
    if not Remotes then return end

    local Validator = SafeWaitForChild(Remotes, "Validator")
    local CommF = SafeWaitForChild(Remotes, "CommF_")
    local CommE = SafeWaitForChild(Remotes, "CommE")

    local ChestModels = SafeWaitForChild(workspace, "ChestModels")
    local WorldOrigin = SafeWaitForChild(workspace, "_WorldOrigin")
    local Characters = SafeWaitForChild(workspace, "Characters")
    local Enemies = SafeWaitForChild(workspace, "Enemies")
    local Map = SafeWaitForChild(workspace, "Map")

    local EnemySpawns = SafeWaitForChild(WorldOrigin, "EnemySpawns")
    local Locations = SafeWaitForChild(WorldOrigin, "Locations")

    local RenderStepped = RunService.RenderStepped
    local Heartbeat = RunService.Heartbeat
    local Stepped = RunService.Stepped

    local Modules = SafeWaitForChild(ReplicatedStorage, "Modules")
    local Net = SafeWaitForChild(Modules, "Net")

    local sethiddenproperty = sethiddenproperty or function(...) return ... end
    local setupvalue = setupvalue or (debug and debug.setupvalue)
    local getupvalue = getupvalue or (debug and debug.getupvalue)

    local Settings = {
        AutoClick = true,
        ClickDelay = 0,
    }

    local Module = {}

    Module.FastAttack = (function()
        if _ENV.rz_FastAttack then
            return _ENV.rz_FastAttack
        end

        local FastAttack = {
            Distance = 100,
            attackMobs = true,
            attackPlayers = true,
            Equipped = nil
        }

        local RegisterAttack = SafeWaitForChild(Net, "RE/RegisterAttack")
        local RegisterHit = SafeWaitForChild(Net, "RE/RegisterHit")

        local function IsAlive(character)
        return character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0
        end

        local function ProcessEnemies(OthersEnemies, Folder)
            local BasePart = nil
            for _, Enemy in Folder:GetChildren() do
                local Head = Enemy:FindFirstChild("Head")
                if Head and IsAlive(Enemy) and Player:DistanceFromCharacter(Head.Position) < FastAttack.Distance then
                    if Enemy ~= Player.Character then
                        table.insert(OthersEnemies, { Enemy, Head })
                        BasePart = Head
                    end
                end
            end
            return BasePart
        end

        function FastAttack:Attack(BasePart, OthersEnemies)
            if not BasePart or #OthersEnemies == 0 then return end
            RegisterAttack:FireServer(Settings.ClickDelay or 0)
            RegisterHit:FireServer(BasePart, OthersEnemies)
        end

        function FastAttack:AttackNearest()
            local OthersEnemies = {}
            local Part1 = ProcessEnemies(OthersEnemies, Enemies)
            local Part2 = ProcessEnemies(OthersEnemies, Characters)
            if #OthersEnemies > 0 then
                self:Attack(Part1 or Part2, OthersEnemies)
            else
                task.wait(0)
            end
        end

        function FastAttack:BladeHits()
            local Equipped = IsAlive(Player.Character) and Player.Character:FindFirstChildOfClass("Tool")
            if Equipped and Equipped.ToolTip ~= "Gun" then
                self:AttackNearest()
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

        _ENV.rz_FastAttack = FastAttack
        return FastAttack
    end)()
end

function Tween2(KG)
    local Distance = (KG.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
    local Speed = 160
    local tweenInfo = TweenInfo.new(Distance / Speed, Enum.EasingStyle.Linear)
    local tween = game:GetService("TweenService"):Create(game.Players.LocalPlayer.Character.HumanoidRootPart, tweenInfo, {
        CFrame = KG
    })
    tween:Play()
    if _G.StopTween2 then
        tween:Cancel()
    end
    _G.Clip2 = true
    wait(Distance / Speed)
    _G.Clip2 = false
end
function BKP(Point)
    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = Point
    task.wait()
    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = Point
end
TweenSpeed = 350
function Tween(KG)
    local Distance = (KG.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
    local Speed = TweenSpeed  
    local tweenInfo = TweenInfo.new(Distance / Speed, Enum.EasingStyle.Linear)
    local tween = game:GetService("TweenService"):Create(game.Players.LocalPlayer.Character.HumanoidRootPart, tweenInfo, {
        CFrame = KG
    })
    tween:Play()
    if _G.StopTween then
        tween:Cancel()
    end
end

RunService.Heartbeat:Connect(function()
	if bringmob 
		and game.Players.LocalPlayer.Character 
		and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") 
	then
		pcall(function()
			local player = game.Players.LocalPlayer
			local char = player.Character
			local hrp = char:FindFirstChild("HumanoidRootPart")
			local enemies = workspace:FindFirstChild("Enemies")

			if not enemies or not hrp then return end

			local nearestEnemy = nil
			local nearestDistance = math.huge
			local MAX_RANGE = 400

			for _, enemy in pairs(enemies:GetChildren()) do
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
				Tween(abovePos)
			else
				-- No enemy within range; ignore tween
			end
		end)
	end
end)

task.spawn(function()
    while task.wait(2) do
        if Auto_Buy_Chips_Raid and SelectChip then
            pcall(function()
	            if game:GetService("Players")["LocalPlayer"].PlayerGui.Main.Timer.Visible == false then
					if not game:GetService("Players").LocalPlayer.Backpack:FindFirstChild("Special Microchip") then
		                local args = {"RaidsNpc", "Select", SelectChip}
		                game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer(unpack(args))
					end
				end
            end)
        end
    end
end)

spawn(function()
    while task.wait(0.1) do
        pcall(function()
            if not Auto_StartRaidSecond then return end

            local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
            local mainGui = playerGui and playerGui:FindFirstChild("Main")
            local timerVisible = mainGui and mainGui:FindFirstChild("Timer") and mainGui.Timer.Visible

            if timerVisible == false then
                local backpack = game:GetService("Players").LocalPlayer:FindFirstChild("Backpack")
                local hasChip = backpack and backpack:FindFirstChild("Special Microchip")

                if hasChip then
                    while Auto_StartRaidSecond and timerVisible == false and backpack:FindFirstChild("Special Microchip") do                        
                        local cd = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("CircleIsland")
                        cd = cd and cd:FindFirstChild("RaidSummon2") and cd.RaidSummon2:FindFirstChild("Button")
                        cd = cd and cd:FindFirstChild("Main") and cd.Main:FindFirstChild("ClickDetector")
                        if cd then
                            fireclickdetector(cd)
                        end

                        task.wait(0.6)

                        playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
                        mainGui = playerGui and playerGui:FindFirstChild("Main")
                        timerVisible = mainGui and mainGui:FindFirstChild("Timer") and mainGui.Timer.Visible
                        backpack = game:GetService("Players").LocalPlayer:FindFirstChild("Backpack")
                        if not backpack then break end
                    end
                end
            end
        end)
    end
end)

spawn(function()
    while task.wait(0.1) do
        pcall(function()
            if not Auto_StartRaidThird then return end

            local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
            local mainGui = playerGui and playerGui:FindFirstChild("Main")
            local timerVisible = mainGui and mainGui:FindFirstChild("Timer") and mainGui.Timer.Visible

            if timerVisible == false then
                local backpack = game:GetService("Players").LocalPlayer:FindFirstChild("Backpack")
                local hasChip = backpack and backpack:FindFirstChild("Special Microchip")

                if hasChip then
                    while Auto_StartRaidThird and timerVisible == false and backpack:FindFirstChild("Special Microchip") do
                        local cd = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Boat Castle")
                        cd = cd and cd:FindFirstChild("RaidSummon2") and cd.RaidSummon2:FindFirstChild("Button")
                        cd = cd and cd:FindFirstChild("Main") and cd.Main:FindFirstChild("ClickDetector")
                        if cd then
                            fireclickdetector(cd)
                        end

                        task.wait(0.6)

                        playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
                        mainGui = playerGui and playerGui:FindFirstChild("Main")
                        timerVisible = mainGui and mainGui:FindFirstChild("Timer") and mainGui.Timer.Visible
                        backpack = game:GetService("Players").LocalPlayer:FindFirstChild("Backpack")
                        if not backpack then break end
                    end
                end
            end
        end)
    end
end)

spawn(function()
    local visitedIslands = {}

    while task.wait(1) do
        if AutoNextIsland then
            pcall(function()
                local player = game.Players.LocalPlayer
                local character = player.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                local locations = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("Locations")

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
                            Tween(island.CFrame)
                            visitedIslands[islandName] = true
                            wait(0.5)
                        else
                            -- too far
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
	        EquipTool(SelectWeapon)
			AutoHaki()
        end
    end
end)

spawn(
    function()
        while task.wait() do
            if AutoAwakenAbilities then
                pcall(
                    function()
                        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("Awakener", "Awaken")
                    end
                )
            end
        end
    end
)

spawn(function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local CommF = ReplicatedStorage.Remotes.CommF_

	local fruits = {
		"Rocket-Rocket",
		"Spin-Spin",
		"Chop-Chop",
		"Spring-Spring",
		"Bomb-Bomb",
		"Smoke-Smoke",
		"Spike-Spike",
		"Flame-Flame",
		"Falcon-Falcon",
		"Ice-Ice",
		"Sand-Sand",
		"Dark-Dark",
		"Ghost-Ghost",
		"Diamond-Diamond",
		"Light-Light",
		"Rubber-Rubber",
		"Barrier-Barrier"
	}

	local loadedFruit = nil

	local function hasFruitInList()
		local backpack = game.Players.LocalPlayer:FindFirstChild("Backpack")
		if backpack then
			for _, item in pairs(backpack:GetChildren()) do
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
						local success = CommF:InvokeServer("LoadFruit", fruitName)
						if success then
							loadedFruit = fruitName
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

local TweenService = game:GetService("TweenService")

local function Tweens(targetCFrame)
	if not targetCFrame then return end
	local info = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local goal = {CFrame = hrp.CFrame + Vector3.new(0, 1, 0)}
	local tween = TweenService:Create(targetCFrame, info, goal)
	tween:Play()
end

spawn(function()
	while task.wait(0.1) do
		if BringFruits then
			for _, v in pairs(workspace:GetChildren()) do
				if v:IsA("Tool") and v:FindFirstChild("Handle") then
					Tweens(v.Handle)
				end
			end
		end
	end
end)

spawn(function()
    pcall(function()
        game:GetService("RunService").Stepped:Connect(function()
            if NoClip then
                for _, v in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.CanCollide = false    
                    end
                end
            end
        end)
    end)
end)

function RaidsModule:SetWalkWater(state: boolean)
    WalkWaterEnabled = state
    if WalkWaterEnabled then
        waterPart.Size = Vector3.new(1000,110,1000)
    else
        waterPart.Size = Vector3.new(1000,80,1000)
    end
end

function RaidsModule:SetBuyChip(state: boolean)
    Auto_Buy_Chips_Raid = state
end

function RaidsModule:SetNoClip(state: boolean)
    NoClip = state
end

function RaidsModule:SetStartRaidSecond(state: boolean)
    Auto_StartRaidSecond = state
end

function RaidsModule:SetStartRaidThird(state: boolean)
    Auto_StartRaidThird = state
end

function RaidsModule:SetAutoRaid(state: boolean)
    AutoKill = state
    bringmob = state
    FastAttackEnabled = state
end

function RaidsModule:SetAutoAwaken(state: boolean)
    AutoAwakenAbilities = state
end

function RaidsModule:SetBringFruits(state: boolean)
    BringFruits = state
end

function RaidsModule:SetGetFruits(state: boolean)
    Autofruit = state
end

function RaidsModule:SetNextIsland(state: boolean)
    AutoNextIsland = state
end

function RaidsModule:SetSelectChip(chip: string)
    SelectChip = chip
end

return RaidsModule
