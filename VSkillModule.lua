local ZSkillModule = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PlayerGui = player:WaitForChild("PlayerGui")

local currentTool = nil
local godhumanZActive = false
local dmgConn = nil
local characterConnections = {}
local rightTouchReleased = false
local rightTouching = false
local rightTouchTime = 0
local aimlockActive = false
local aimRenderConn = nil
local aimTimeoutTask = nil
local nearestTarget = nil
local ZSkillsEnabled = false
local TargetInfo = false 
local uiConn = nil

-- ========= SAFE DISCONNECT =========
local function clearConnections()
	for _, conn in ipairs(characterConnections) do
		pcall(function() conn:Disconnect() end)
	end
	characterConnections = {}

	if dmgConn then
		pcall(function() dmgConn:Disconnect() end)
		dmgConn = nil
	end

	if aimRenderConn then
		pcall(function() aimRenderConn:Disconnect() end)
		aimRenderConn = nil
	end

	if aimTimeoutTask then
		pcall(function() task.cancel(aimTimeoutTask) end)
		aimTimeoutTask = nil
	end
end

-- ========= NEAREST TARGET FINDER =========
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

local function GetNearestTarget(maxDistance)
	local lp = player
	local char = lp and lp.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end

	local hrp = char.HumanoidRootPart
	local closest, closestDist = nil, maxDistance or 100

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp and isEnemy(plr) and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") then
			local otherHRP = plr.Character.HumanoidRootPart
			local humanoid = plr.Character:FindFirstChild("Humanoid")
			if otherHRP and humanoid and humanoid.Health > 0 then
				local dist = (otherHRP.Position - hrp.Position).Magnitude
				if dist < closestDist then
					closest = plr.Character
					closestDist = dist
				end
			end
		end
	end

	return closest
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TargetUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local targetFrame = Instance.new("Frame")
targetFrame.Name = "TargetFrame"
targetFrame.Size = UDim2.new(0.25, 0, 0.08, 0)
targetFrame.Position = UDim2.new(0.5, 0, 0.05, 0)
targetFrame.AnchorPoint = Vector2.new(0.5, 0)
targetFrame.BackgroundTransparency = 1
targetFrame.Visible = false
targetFrame.Parent = screenGui

local targetName = Instance.new("TextLabel")
targetName.Name = "TargetName"
targetName.Size = UDim2.new(1, 0, 0.5, 0)
targetName.BackgroundTransparency = 1
targetName.TextScaled = true
targetName.Font = Enum.Font.GothamBold
targetName.TextColor3 = Color3.new(1, 1, 1)
targetName.Parent = targetFrame

local hpBackground = Instance.new("Frame")
hpBackground.Name = "HealthBarBackground"
hpBackground.Size = UDim2.new(1, 0, 0.35, 0)
hpBackground.Position = UDim2.new(0, 0, 0.55, 0)
hpBackground.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
hpBackground.BorderSizePixel = 0
hpBackground.Parent = targetFrame

local hpFill = Instance.new("Frame")
hpFill.Name = "HealthBarFill"
hpFill.Size = UDim2.new(1, 0, 1, 0)
hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
hpFill.BorderSizePixel = 0
hpFill.Parent = hpBackground

-- ========= TOOL HOOK =========
local function hookTool(tool)
	if not tool then return end
	currentTool = tool

	table.insert(characterConnections, tool.AncestryChanged:Connect(function(_, parent)
		if not parent then
			currentTool = nil
			godhumanZActive = false
			rightTouchReleased = false
			aimlockActive = false
		end
	end))
end

-- ========= STOP AIMLOCK =========
local function stopAimlock(reason)
	if not aimlockActive then return end
	aimlockActive = false
	nearestTarget = nil
	godhumanZActive = false

	if aimRenderConn then
		pcall(function() aimRenderConn:Disconnect() end)
		aimRenderConn = nil
	end

	if aimTimeoutTask then
		pcall(function() task.cancel(aimTimeoutTask) end)
		aimTimeoutTask = nil
	end
end

-- ========= START AIMLOCK =========
local function startAimlock()
	if not ZSkillsEnabled then return end
	if aimlockActive then return end

	nearestTarget = GetNearestTarget(1000)
	if not nearestTarget then return end

	aimlockActive = true

	aimRenderConn = RunService.RenderStepped:Connect(function()
		if not ZSkillsEnabled then
			stopAimlock("ZSkills disabled mid-aim")
			return
		end

		if aimlockActive and nearestTarget and nearestTarget:FindFirstChild("HumanoidRootPart") then
			local cam = workspace.CurrentCamera
			if cam then
				cam.CFrame = CFrame.lookAt(cam.CFrame.Position, nearestTarget.HumanoidRootPart.Position)
			end
		else
			stopAimlock("Lost target or inactive")
		end
	end)

	aimTimeoutTask = task.delay(1, function()
		if aimlockActive then
			stopAimlock("1s timeout")
		end
	end)
end

-- ========= WATCH DAMAGE COUNTER =========
local function watchDamageCounter()
	if not ZSkillsEnabled then return end

	if dmgConn then
		pcall(function() dmgConn:Disconnect() end)
		dmgConn = nil
	end

	local gui = player:WaitForChild("PlayerGui"):WaitForChild("Main", 5)
	if not gui then return end

	local dmgCounter = gui:FindFirstChild("DmgCounter")
	if not dmgCounter then
		table.insert(characterConnections, gui.ChildAdded:Connect(function(child)
			if child.Name == "DmgCounter" then
				task.wait()
				watchDamageCounter()
			end
		end))
		return
	end

	local dmgTextLabel = dmgCounter:FindFirstChild("Text")
	if not dmgTextLabel then
		table.insert(characterConnections, dmgCounter.ChildAdded:Connect(function(child)
			if child.Name == "Text" then
				task.wait()
				watchDamageCounter()
			end
		end))
		return
	end

	dmgConn = dmgTextLabel:GetPropertyChangedSignal("Text"):Connect(function()
		if not ZSkillsEnabled then return end
		local dmgText = tonumber(dmgTextLabel.Text) or 0
		if dmgText > 0 and aimlockActive then
			stopAimlock("Damage detected")
		end
	end)
end

-- ========= TOUCH INPUT =========
UserInputService.TouchEnded:Connect(function(touch)
	if not ZSkillsEnabled then return end
	local cam = workspace.CurrentCamera
	if not cam or not touch or not touch.Position then return end

	if touch.Position.X > cam.ViewportSize.X / 2 then
		rightTouching = false
		rightTouchReleased = true

		if currentTool and currentTool.Name == "Godhuman" and godhumanZActive then
			if not aimlockActive then
				startAimlock()
			end
		end
	end
end)

-- ========= SKILL HOOK =========
if not getgenv().ZSkillHooked then
	getgenv().ZSkillHooked = true

	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
		local method = getnamecallmethod()
		local args = {...}
		
		if (method == "InvokeServer" or method == "FireServer") then
	        local a1 = args[1]

			if typeof(a1) == "string" and a1:upper() == "Z" then
				if currentTool then
					if currentTool.Name == "Godhuman" then
						godhumanZActive = true
					end
				end
			end
		end
		return oldNamecall(self, ...)
	end)
end

-- =========================
-- Character Handling
-- =========================
local function onCharacterAdded(char)
	if char ~= player.Character then return end

	clearConnections()

	godhumanZActive = false
	rightTouchReleased = false

	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("Tool") then
			hookTool(child)
		end
	end

	table.insert(characterConnections, char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			hookTool(child)
		end
	end))

	table.insert(characterConnections, char.ChildRemoved:Connect(function(child)
		if child == currentTool then
			currentTool = nil
			godhumanZActive = false
			rightTouchReleased = false
		end
	end))

	watchDamageCounter()
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then onCharacterAdded(player.Character) end

-- ========= PUBLIC TOGGLE FUNCTION =========
function ZSkillModule:SetZSkills(state)
	ZSkillsEnabled = state
	if not state then
		stopAimlock("ZSkills disabled")
		clearConnections()
	end
end

function ZSkillModule:SetInfo(state)
	TargetInfo = state

	if state then
		if uiConn == nil then
			uiConn = RunService.RenderStepped:Connect(function()
				local target = GetNearestTarget(1000)

				if target and target:FindFirstChild("Humanoid") then
					local hp = target.Humanoid

					targetName.Text = target.Name
					local fill = math.clamp(hp.Health / hp.MaxHealth, 0, 1)
					hpFill.Size = UDim2.new(fill, 0, 1, 0)

					hpBackground.Visible = true
					hpFill.Visible = true
					targetFrame.Visible = true
				else
					targetName.Text = "No target available"

					hpBackground.Visible = false
					hpFill.Visible = false
					targetFrame.Visible = true
				end
			end)
		end
	else
		if uiConn then
			uiConn:Disconnect()
			uiConn = nil
		end

		targetFrame.Visible = false
	end
end

return ZSkillModule
