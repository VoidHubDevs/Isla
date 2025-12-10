local ESPModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommE = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommE")
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid") 
local vim = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local V3Enabled = false
local BunnyHopEnabled = false
local DodgeEnabled = false 
local ESPEnabled = false
local BusoEnabled = false
local v3LoopRunning = false
local antiAfkEnabled = false

local NoDodgeCoroutine
local currentTool = nil
local ESPs = {}
local cooldownTime = 31
local v3Loop = nil

-- =========================
-- Team Check
-- =========================
local function isAllyWithMe(targetPlayer)
	local myGui = player:FindFirstChild("PlayerGui")
	if not myGui then return false end

	local scrolling = myGui:FindFirstChild("Main")
		and myGui.Main:FindFirstChild("Allies")
		and myGui.Main.Allies:FindFirstChild("Container")
		and myGui.Main.Allies.Container:FindFirstChild("Allies")
		and myGui.Main.Allies.Container.Allies:FindFirstChild("ScrollingFrame")

	if scrolling then
		for _, frame in pairs(scrolling:GetDescendants()) do
			if frame:IsA("ImageButton") and frame.Name == targetPlayer.Name then
				return true
			end
		end
	end

	return false
end

local function isEnemy(targetPlayer)
	if not targetPlayer or targetPlayer == player then
		return false
	end

	local myTeam = player.Team
	local targetTeam = targetPlayer.Team

	if myTeam and targetTeam then
		if myTeam.Name == "Pirates" and targetTeam.Name == "Marines" then
			return true
		elseif myTeam.Name == "Marines" and targetTeam.Name == "Pirates" then
			return true
		end

		if myTeam.Name == "Pirates" and targetTeam.Name == "Pirates" then
			if isAllyWithMe(targetPlayer) then
				return false -- ally, not enemy
			end
			return true
		end

		if myTeam.Name == "Marines" and targetTeam.Name == "Marines" then
			return false
		end
	end

	return true
end

-- =========================
-- Ability V3
-- =========================
local function clickActivateAbility()
    if CommE then
        CommE:FireServer("ActivateAbility")
    end
end

local function startV3Loop()
    if v3LoopRunning then return end
    v3LoopRunning = true
    v3Loop = task.spawn(function()
        while v3LoopRunning do
            if not player or not player.Parent then break end
            pcall(clickActivateAbility)
            task.wait(cooldownTime)
        end
        v3Loop = nil
    end)
end

local function stopV3Loop()
    if not v3LoopRunning then return end
    v3LoopRunning = false
    v3Loop = nil
end

local function NoDodgeCool()
    if DodgeEnabled then
        NoDodgeCoroutine = task.spawn(function()
            for i, v in next, getgc() do
                local character = game.Players.LocalPlayer.Character
                local dodge = character and character:FindFirstChild("Dodge")
                if dodge and typeof(v) == "function" and getfenv(v).script == dodge then
                    for i2, v2 in next, getupvalues(v) do
                        if tostring(v2) == "0.4" then
                            repeat
                                task.wait()
                                setupvalue(v, i2, 0)
                            until not DodgeEnabled
                        end
                    end
                end
            end
        end)
    else
        if NoDodgeCoroutine then
            task.cancel(NoDodgeCoroutine)
            NoDodgeCoroutine = nil
        end
    end
end

-- =========================
-- V Skill Detection
-- =========================
local old
old = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if (method == "InvokeServer" or method == "FireServer") then
        local a1 = args[1]

        if typeof(a1) == "string" and a1:upper() == "DODGE" then
            if BunnyHopEnabled then
                local ok, h = pcall(function() return humanoid end)
                if ok and h and h.Parent then
                    task.defer(function()
                        pcall(function()
                            h:ChangeState(Enum.HumanoidStateType.Jumping)
                        end)
                    end)
                end
            end
        end
    end
    return old(self, ...)
end)

-- =========================
-- Global Player ESP with Colors
-- =========================
local espFolder = game.CoreGui:FindFirstChild("GlobalESP")
if not espFolder then
    espFolder = Instance.new("Folder")
    espFolder.Name = "GlobalESP"
    espFolder.Parent = game.CoreGui
end

local function getESPColor(player)
	if player == game.Players.LocalPlayer then
		return Color3.fromRGB(0, 255, 0)
	elseif isAllyWithMe(player) then
		return Color3.fromRGB(0, 255, 0)
	elseif isEnemy(player) then
		return Color3.fromRGB(255, 255, 0)
	else
		return Color3.fromRGB(0, 255, 0)
	end
end

-- =========================
-- Optimized ESP System
-- =========================
local function createESP(targetPlayer)
	if ESPs[targetPlayer] then return end
	local char = targetPlayer.Character
	if not char then return end
	local head = char:FindFirstChild("Head")
	if not head then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = targetPlayer.Name
	billboard.Adornee = head
	billboard.Size = UDim2.fromOffset(220, 50)
	billboard.AlwaysOnTop = true
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.Parent = espFolder

	local levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "LevelLabel"
	levelLabel.Size = UDim2.new(1, 0, 0.5, 0)
	levelLabel.Position = UDim2.new(0, 0, 0, 0)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = "Lv. ???"
	levelLabel.TextColor3 = Color3.fromRGB(0, 170, 255)
	levelLabel.TextStrokeTransparency = 0.2
	levelLabel.Font = Enum.Font.SourceSansBold
	levelLabel.TextSize = 14
	levelLabel.TextXAlignment = Enum.TextXAlignment.Center
	levelLabel.Parent = billboard

	local mainLabel = Instance.new("TextLabel")
	mainLabel.Name = "MainLabel"
	mainLabel.Size = UDim2.new(1, 0, 0.5, 0)
	mainLabel.Position = UDim2.new(0, 0, 0.5, 0)
	mainLabel.BackgroundTransparency = 1
	mainLabel.Text = "[0] "..targetPlayer.DisplayName.." (0m)"
	mainLabel.TextColor3 = getESPColor(targetPlayer)
	mainLabel.TextStrokeTransparency = 0.2
	mainLabel.Font = Enum.Font.SourceSansBold
	mainLabel.TextSize = 16
	mainLabel.TextXAlignment = Enum.TextXAlignment.Center
	mainLabel.Parent = billboard

	ESPs[targetPlayer] = billboard
end

RunService.Heartbeat:Connect(function()
	if not ESPEnabled then
		for _, gui in pairs(ESPs) do
			if gui then gui.Enabled = false end
		end
		return
	end

	for _, targetPlayer in pairs(Players:GetPlayers()) do
		if targetPlayer ~= player then
			if not ESPs[targetPlayer] then
				createESP(targetPlayer)
			end

			local gui = ESPs[targetPlayer]
			if gui then
				local char = targetPlayer.Character
				local head = char and char:FindFirstChild("Head")
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				local humanoid = char and char:FindFirstChildOfClass("Humanoid")
				local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")

				if char and head and hrp and humanoid and myHRP then
					gui.Adornee = head
					gui.Enabled = true
					local dist = (myHRP.Position - hrp.Position).Magnitude
					local nameLabel = gui:FindFirstChild("MainLabel")
					local levelLabel = gui:FindFirstChild("LevelLabel")

					if levelLabel then
						local dataFolder = targetPlayer:FindFirstChild("Data")
						local levelValue = dataFolder and dataFolder:FindFirstChild("Level")
						levelLabel.Text = levelValue and ("Lv. "..levelValue.Value) or "Lv. ???"
					end
					if nameLabel then
						nameLabel.Text = "["..math.floor(humanoid.Health).."] "..targetPlayer.DisplayName.." ("..math.floor(dist).."m)"
						nameLabel.TextColor3 = getESPColor(targetPlayer)
					end
				else
					gui.Enabled = false
				end
			end
		end
	end
end)

do
	local player = game:GetService("Players").LocalPlayer

	if antiAfkEnabled then
		player.Idled:Connect(function()
			pcall(function()
				vim:SendMouseButtonEvent(
					workspace.CurrentCamera.ViewportSize.X / 2, -- X position (center of screen)
					workspace.CurrentCamera.ViewportSize.Y / 2, -- Y position (center of screen)
					0,
					true,
					game,
					1
				)
				task.wait(0.05)
				vim:SendMouseButtonEvent(
					workspace.CurrentCamera.ViewportSize.X / 2,
					workspace.CurrentCamera.ViewportSize.Y / 2,
					0,
					false,
					game,
					1
				)
			end)
		end)
	end
end

-- =========================
-- State Toggles
-- =========================
function ESPModule:SetV3(state)
    V3Enabled = state
    if state then
        startV3Loop()
    else
        stopV3Loop()
    end
end

function ESPModule:SetBunnyhop(state)
    BunnyHopEnabled = state
end

function ESPModule:SetNoDodgeCD(state)
	DodgeEnabled = state
	if state then
		NoDodgeCool()
	else
		--ignore
	end
end

function ESPModule:SetAntiAfk(state)
    antiAfkEnabled = state
end

function ESPModule:SetBuso(state)
    BusoEnabled = state
    if state then
	    if not game:GetService("Players").LocalPlayer.Character:FindFirstChild("HasBuso") then
	        pcall(function() CommF:InvokeServer("Buso") end)
		end
    end
end

function ESPModule:SetESP(state)
	ESPEnabled = state
end

function ESPModule:SetGlobalFont(fontEnum)
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        for _, ui in pairs(playerGui:GetDescendants()) do
	        if not ui:IsDescendantOf(playerGui:FindFirstChild("ScreenGui")) then
	            if ui:IsA("TextLabel") or ui:IsA("TextButton") or ui:IsA("TextBox") then
	                ui.Font = fontEnum
	                ui.TextStrokeTransparency = 1
				end
            end
        end
    end
    playerGui.DescendantAdded:Connect(function(ui)
	    if not ui:IsDescendantOf(playerGui:FindFirstChild("ScreenGui")) then
		    if ui:IsA("TextLabel") or ui:IsA("TextButton") or ui:IsA("TextBox") then
	            ui.Font = fontEnum
	            ui.TextStrokeTransparency = 1
			end
        end
    end)
end

function ESPModule:SetRTXMode(mode)
	local Lighting = game:GetService("Lighting")
	local Terrain = workspace.Terrain
	local currentSeason = mode
	
	for _, v in pairs(Lighting:GetChildren()) do
		if v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("ColorCorrectionEffect")
		or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") then
			v:Destroy()
		end
	end

	Lighting.Technology = Enum.Technology.Future
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.35
	Lighting.Brightness = 4
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.ExposureCompensation = 0
	Lighting.ClockTime = 8
	Lighting.GeographicLatitude = 66
	Lighting.Ambient = Color3.fromRGB(25, 25, 25)
	Lighting.OutdoorAmbient = Color3.fromRGB(50, 50, 50)

	local Atmosphere = Instance.new("Atmosphere", Lighting)
	local CC = Instance.new("ColorCorrectionEffect", Lighting)
	local SR = Instance.new("SunRaysEffect", Lighting)
	local DOF = Instance.new("DepthOfFieldEffect", Lighting)
	local Bloom = Instance.new("BloomEffect", Lighting)

	Bloom.Intensity = 0.15
	Bloom.Threshold = 0.6
	Bloom.Size = 1800

	if mode == "Summer" then
		Lighting.ColorShift_Top = Color3.fromRGB(255, 250, 225)
		Lighting.ColorShift_Bottom = Color3.fromRGB(170, 210, 255)
		Atmosphere.Color = Color3.fromRGB(255, 255, 255)
		Atmosphere.Decay = Color3.fromRGB(210, 210, 190)
		Atmosphere.Density = 0.35
		Atmosphere.Haze = 1
		CC.TintColor = Color3.fromRGB(255, 235, 190)
		CC.Brightness = 0.15
		CC.Contrast = 0.25
		CC.Saturation = 0.2
		SR.Intensity = 0.15
		SR.Spread = 0.2
		DOF.FocusDistance = 25
		DOF.InFocusRadius = 30
		Terrain.WaterColor = Color3.fromRGB(100, 160, 255)
		particleColor = ColorSequence.new(Color3.fromRGB(255, 245, 200)) -- warm light dust

	elseif mode == "Autumn" then
		Lighting.ColorShift_Top = Color3.fromRGB(255, 220, 160)
		Lighting.ColorShift_Bottom = Color3.fromRGB(140, 100, 70)
		Atmosphere.Color = Color3.fromRGB(255, 200, 160)
		Atmosphere.Decay = Color3.fromRGB(200, 130, 80)
		Atmosphere.Density = 0.4
		Atmosphere.Haze = 2
		CC.TintColor = Color3.fromRGB(230, 160, 70)
		CC.Brightness = 0.1
		CC.Contrast = 0.35
		CC.Saturation = -0.05
		SR.Intensity = 0.1
		SR.Spread = 0.15
		DOF.FocusDistance = 20
		DOF.InFocusRadius = 20
		Terrain.WaterColor = Color3.fromRGB(180, 130, 90)
		particleColor = ColorSequence.new(Color3.fromRGB(255, 170, 80)) -- leaf-like glow

	elseif mode == "Spring" then
		Lighting.ColorShift_Top = Color3.fromRGB(210, 255, 220)
		Lighting.ColorShift_Bottom = Color3.fromRGB(180, 220, 190)
		Atmosphere.Color = Color3.fromRGB(210, 255, 220)
		Atmosphere.Decay = Color3.fromRGB(180, 230, 180)
		Atmosphere.Density = 0.25
		Atmosphere.Haze = 1.5
		CC.TintColor = Color3.fromRGB(210, 255, 210)
		CC.Brightness = 0.2
		CC.Contrast = 0.2
		CC.Saturation = 0.3
		SR.Intensity = 0.12
		SR.Spread = 0.17
		DOF.FocusDistance = 30
		DOF.InFocusRadius = 25
		Terrain.WaterColor = Color3.fromRGB(120, 200, 140)
		particleColor = ColorSequence.new(Color3.fromRGB(190, 255, 200)) -- green pastel tone

	elseif mode == "Winter" then
		Lighting.ColorShift_Top = Color3.fromRGB(200, 230, 255)
		Lighting.ColorShift_Bottom = Color3.fromRGB(150, 170, 190)
		Atmosphere.Color = Color3.fromRGB(190, 220, 255)
		Atmosphere.Decay = Color3.fromRGB(160, 190, 220)
		Atmosphere.Density = 0.45
		Atmosphere.Haze = 2.5
		CC.TintColor = Color3.fromRGB(200, 230, 255)
		CC.Brightness = 0.05
		CC.Contrast = 0.3
		CC.Saturation = -0.1
		SR.Intensity = 0.08
		SR.Spread = 0.1
		DOF.FocusDistance = 22
		DOF.InFocusRadius = 15
		Terrain.WaterColor = Color3.fromRGB(180, 220, 255)
		particleColor = ColorSequence.new(Color3.fromRGB(220, 240, 255)) -- snow mist tone
	end

	Terrain.WaterWaveSize = 0.15
	Terrain.WaterTransparency = 0.2
	Terrain.WaterReflectance = 0.4
	
	for _, particle in pairs(workspace:GetDescendants()) do
		if particle:IsA("ParticleEmitter") then
			particle.Color = particleColor
		end
	end
end

-- =========================
-- Character Respawn Handling
-- =========================
local function onCharacterAdded(newChar)
    char = newChar
    humanoid = char:WaitForChild("Humanoid")

    if BunnyHopEnabled then
        -- nothing extra needed, the hookmetamethod will keep working
    end
    if V3Enabled then
        startV3Loop()
    end
    if DodgeEnabled then
        NoDodgeCool()
    end
    if BusoEnabled then
        if not game:GetService("Players").LocalPlayer.Character:FindFirstChild("HasBuso") then
	        pcall(function() CommF:InvokeServer("Buso") end)
		end
    end
end

if player.Character then
    onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

return ESPModule
