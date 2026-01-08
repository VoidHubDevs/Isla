local AimlockModule = {}

local Players = game:GetService("Players")
local camera = workspace.CurrentCamera
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
  
local humanoid = char:WaitForChild("Humanoid") 
local AimlockPlayerEnabled, AimlockNpcEnabled, PredictionEnabled = false, false, false
local currentTarget = nil
local currentTool = nil
local vActive, sharkZActive, cursedZActive = false, false, false
local tiltEnabled = false
local rightTouches = {}
local tiltConn, preTiltCFrame, dmgConn = nil, nil, nil
local currentEnemyTarget, currentBossTarget, currentHighlight = nil, nil, nil
local healthConn, lastHealth = nil, nil
local cachedEnemy = nil
local cachedBoss = nil
local PredictionAmount = 0.1
local MiniPlayerState = nil
local MiniNpcState = nil
local MiniPlayerCreated = false
local MiniNpcCreated = false
local MiniPlayerGui, MiniNpcGui = nil, nil
local characterConnections = {}
local renderConnTilt = nil
local watchDamageActive = false

local function clearConnections()
	for _, conn in ipairs(characterConnections) do
		pcall(function() conn:Disconnect() end)
	end
	characterConnections = {}
end

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
-- Enemies Finder
-- =========================
local function getNearestEnemy(maxDistance)
	local hrp = char:WaitForChild("HumanoidRootPart")
	local nearest, shortest = nil, maxDistance or 100

	for _, p in pairs(Players:GetPlayers()) do
		if p ~= player and isEnemy(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			local humanoid = p.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				local enemyHRP = p.Character.HumanoidRootPart
				local dist = (enemyHRP.Position - hrp.Position).Magnitude
				if dist < shortest then
					shortest = dist
					nearest = enemyHRP
				end
			end
		end
	end

	return nearest
end

local function getNearestBoss(maxDistance)
	local hrp = char:WaitForChild("HumanoidRootPart")
	local nearest, shortest = nil, maxDistance or 500
	local bossFolder = Workspace:FindFirstChild("Enemies")
	if bossFolder then
		for _, boss in pairs(bossFolder:GetChildren()) do
			local humanoid = boss:FindFirstChildOfClass("Humanoid")
			if boss:FindFirstChild("HumanoidRootPart") and humanoid and humanoid.Health > 0 then
				local bossHRP = boss.HumanoidRootPart
				local dist = (bossHRP.Position - hrp.Position).Magnitude
				if dist < shortest then
					shortest = dist
					nearest = bossHRP
				end
			end
		end
	end
	return nearest
end

-- =========================
-- Tilt Camera Function
-- =========================
local function disconnectTiltConn()
	if tiltConn then
		tiltConn:Disconnect()
		tiltConn = nil
	end
end

local function safeDisconnect(conn)
    if conn then
        pcall(function() conn:Disconnect() end)
        conn = nil
    end
    return nil
end

local function stopTiltSmooth()
	disconnectTiltConn()
	if not preTiltCFrame then return end

	local startCF = camera.CFrame
	local endCF = preTiltCFrame
	preTiltCFrame = nil

	local a = 0
	local restoreConn
	restoreConn = RunService.RenderStepped:Connect(function(dt)
		a = math.min(a + dt * 5, 1)
		camera.CFrame = startCF:Lerp(endCF, a)
		if a >= 1 then
			restoreConn:Disconnect()
		end
	end)
end

local function startTilt()
	disconnectTiltConn()

	preTiltCFrame = preTiltCFrame or camera.CFrame
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local startCF = camera.CFrame
	local camPos = startCF.Position

	local tiltOffset
	if humanoid.FloorMaterial ~= Enum.Material.Air then
		tiltOffset = Vector3.new(0, 6, 0)
	else
		tiltOffset = Vector3.new(0, 40, 0)
	end

	local downLook = hrp.Position - tiltOffset
	local targetCF = CFrame.new(camPos, downLook)

	local alpha = 0
	tiltConn = RunService.RenderStepped:Connect(function(dt)
		if not (tiltEnabled and next(rightTouches) and hrp.Parent) then
			stopTiltSmooth()
			return
		end

		if alpha < 1 then
			alpha = math.min(alpha + dt * 2, 1)
			camera.CFrame = startCF:Lerp(targetCF, alpha)
		else
			camera.CFrame = targetCF
		end
	end)
end

-- =========================
-- Mini UI Buttons
-- =========================
local function createMiniToggle(name, position, stateVarRef, realVarSetter)
	local playerGui = player:WaitForChild("PlayerGui")
    if playerGui:FindFirstChild(name .. "MiniToggleGui") then
        playerGui[name .. "MiniToggleGui"]:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = name .. "MiniToggleGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 70, 0, 40) 
    button.Position = position
    button.Text = name .. (stateVarRef.value and " ON" or " OFF")
    button.TextScaled = true
    button.TextWrapped = false
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    button.BorderSizePixel = 0
    button.Parent = screenGui

    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0, 8)
    uicorner.Parent = button

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 50))
    }
    gradient.Rotation = 45
    gradient.Parent = button

    local function updateUI(state)
        button.Text = name .. (state and " ON" or " OFF")
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, state and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(255, 100, 50)),
            ColorSequenceKeypoint.new(1, state and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 200, 50))
        }
    end

    button.MouseButton1Click:Connect(function()
        stateVarRef.value = not stateVarRef.value
        realVarSetter(stateVarRef.value)
        updateUI(stateVarRef.value)
    end)

    -- =========================
    -- Dragging functionality
    -- =========================
    local dragging = false
    local dragStart = nil
    local startPos = nil

    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = button.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end

    local function onInputChanged(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            button.Position = UDim2.new(
                0,
                math.clamp(startPos.X.Offset + delta.X, 0, camera.ViewportSize.X - button.AbsoluteSize.X),
                0,
                math.clamp(startPos.Y.Offset + delta.Y, 0, camera.ViewportSize.Y - button.AbsoluteSize.Y)
            )
        end
    end

    button.InputBegan:Connect(onInputBegan)
    button.InputChanged:Connect(onInputChanged)

    updateUI(stateVarRef.value)
    return screenGui
end

-- =========================
-- Tool equip / unequip 
-- =========================
local function hookTool(tool)
    currentTool = tool
    local ancConn = tool.AncestryChanged:Connect(function(_, parent)
        if not parent then
            currentTool = nil
            vActive = false
            sharkZActive = false
            cursedZActive = false
            tiltEnabled = false
            stopTiltSmooth()
        end
    end)
    table.insert(characterConnections, ancConn)
end

-- =========================
-- Tilt trigger condition
-- =========================
local function canTilt()
	return (currentTool and currentTool.Name == "Dough-Dough" and vActive)
	    or (currentTool and currentTool.Name == "Shark Anchor" and sharkZActive)
	    or (currentTool and currentTool.Name == "Cursed Dual Katana" and cursedZActive)
end

-- =========================
-- V Skill Detection
-- =========================
if _G.AimlockHooked then
    return AimlockModule
end
_G.AimlockHooked = true
local old
old = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if (method == "InvokeServer" or method == "FireServer") then
        local a1 = args[1]

        if typeof(a1) == "string" and a1:upper() == "V" then
            if currentTool and currentTool.Name == "Dough-Dough" then
                vActive = true
                local stamp = os.clock()
                task.delay(2, function()
                    if os.clock() - stamp >= 2 then
                        vActive = false
                        if tiltEnabled and next(rightTouches) then
                            tiltEnabled = false
                            stopTiltSmooth()
                            rightTouches = {}
                        end
                    end
                end)
            end
        end

        if typeof(a1) == "string" and a1:upper() == "Z" then
            if currentTool and currentTool.Name == "Shark Anchor" then
                sharkZActive = true
                local stamp = os.clock()
                task.delay(2, function()
                    if os.clock() - stamp >= 2 then
                        sharkZActive = false
                        if tiltEnabled and next(rightTouches) then
                            tiltEnabled = false
                            stopTiltSmooth()
                            rightTouches = {}
                        end
                    end
                end)
            end
        end

        if typeof(a1) == "string" and a1:upper() == "Z" then
            if currentTool and currentTool.Name == "Cursed Dual Katana" then
                cursedZActive = true
                local stamp = os.clock()
                task.delay(2, function()
                    if os.clock() - stamp >= 2 then
                        cursedZActive = false
                        if tiltEnabled and next(rightTouches) then
                            tiltEnabled = false
                            stopTiltSmooth()
                            rightTouches = {}
                        end
                    end
                end)
            end
        end

        if currentTool and currentTool.Name == "Shark Anchor" and self.Name == "EquipEvent" then
            local arg1 = args[1]
            if arg1 == false then
                currentTool = nil
                sharkZActive = false
                tiltEnabled = false
                stopTiltSmooth()
            end
        end
    end
    return old(self, ...)
end)

-- =========================
-- Touch tracking
-- =========================
UserInputService.TouchStarted:Connect(function(touch)
    camera = workspace.CurrentCamera
    if not camera then return end

    if touch.Position.X > camera.ViewportSize.X / 2 then
        rightTouches[touch] = true
        if tiltEnabled and canTilt() then
            startTilt()
        end
    end
end)

UserInputService.TouchEnded:Connect(function(touch)
	if rightTouches[touch] then
		rightTouches[touch] = nil
		if not next(rightTouches) then
			stopTiltSmooth()			
			tiltEnabled = false
			vActive = false
			sharkZActive = false
			cursedZActive = false
		end
	end
end)

local function watchDamageCounter()
    if dmgConn then
        pcall(function() dmgConn:Disconnect() end)
        dmgConn = nil
    end

    watchDamageActive = true

    task.spawn(function()
        while watchDamageActive do
            local gui = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("Main")
            if not gui then
                task.wait(1)
                continue
            end

            local dmgCounter = gui:FindFirstChild("DmgCounter")
            if not dmgCounter then
                task.wait(1)
                continue
            end

            local dmgTextLabel = dmgCounter:FindFirstChild("Text")
            if not dmgTextLabel then
                task.wait(1)
                continue
            end

            dmgConn = dmgTextLabel:GetPropertyChangedSignal("Text"):Connect(function()
                local dmgText = tonumber(dmgTextLabel.Text) or 0
                if dmgText > 0 and canTilt() and currentHighlight then
                    tiltEnabled = true
                    if next(rightTouches) then
                        startTilt()
                    end
                else
                    tiltEnabled = false
                    stopTiltSmooth()
                end
            end)
            table.insert(characterConnections, dmgConn)
            break
        end
    end)
end

local function watchHealth(humanoid)
    if healthConn then
        pcall(function() healthConn:Disconnect() end)
        healthConn = nil
    end

    lastHealth = humanoid.Health

    healthConn = humanoid.HealthChanged:Connect(function(newHealth)
        if tiltEnabled and next(rightTouches) then
            if newHealth < lastHealth then
                tiltEnabled = false
                stopTiltSmooth()
                rightTouches = {}
            end
        end
        lastHealth = newHealth
    end)

    table.insert(characterConnections, healthConn)
end

local function setAimlockTarget(targetModel)
    if currentHighlight then
        currentHighlight:Destroy()
        currentHighlight = nil
    end

    if not targetModel then
        if dmgConn then
            pcall(function() dmgConn:Disconnect() end)
            dmgConn = nil
        end
        currentTarget = nil
        return
    end

    local humanoid = targetModel:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        currentTarget = nil
        return
    end

    if targetModel:IsA("Model") then
        local highlight = Instance.new("Highlight")
        highlight.FillColor = Color3.fromRGB(255, 255, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.Adornee = targetModel
        highlight.Parent = targetModel
        currentHighlight = highlight

        if dmgConn then
            pcall(function() dmgConn:Disconnect() end)
            dmgConn = nil
        end

        local diedConn = humanoid.Died:Connect(function()
            if currentHighlight then
                currentHighlight:Destroy()
                currentHighlight = nil
            end
            currentTarget = nil

            if dmgConn then
                pcall(function() dmgConn:Disconnect() end)
                dmgConn = nil
            end

            if tiltEnabled then
                tiltEnabled = false
                stopTiltSmooth()
                rightTouches = {}
            end
        end)
        table.insert(characterConnections, diedConn)

        if currentTarget ~= targetModel then
            watchDamageCounter()
        end
        currentTarget = targetModel
    end
end

local function startRenderLoop()
    if renderConnTilt then
        return
    end

    renderConnTilt = RunService.RenderStepped:Connect(function(dt)
        if not AimlockPlayerEnabled and not AimlockNpcEnabled then
            renderConnTilt:Disconnect()
            renderConnTilt = nil
            return
        end

        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then 
            return 
        end

        if AimlockPlayerEnabled then
            if not cachedEnemy 
                or not cachedEnemy.Parent 
                or not cachedEnemy.Parent:FindFirstChildOfClass("Humanoid") 
                or cachedEnemy.Parent:FindFirstChildOfClass("Humanoid").Health <= 0 then
                cachedEnemy = getNearestEnemy(500)
            end
        else
            cachedEnemy = nil
        end

        if AimlockNpcEnabled then
            if not cachedBoss 
                or not cachedBoss.Parent 
                or not cachedBoss.Parent:FindFirstChildOfClass("Humanoid") 
                or cachedBoss.Parent:FindFirstChildOfClass("Humanoid").Health <= 0 then
                cachedBoss = getNearestBoss(500)
            end
        else
            cachedBoss = nil
        end

        if not tiltEnabled then
            local targetHRP = nil
            if AimlockPlayerEnabled then targetHRP = cachedEnemy end
            if AimlockNpcEnabled then targetHRP = cachedBoss end

            if targetHRP then
                local camCFrame = camera.CFrame
                local camPos = camCFrame.Position
                local dist = (targetHRP.Position - camPos).Magnitude
                local predictionTime = PredictionAmount
                local enemyVelocity = targetHRP.Velocity
                local predictedPos = targetHRP.Position

                if PredictionEnabled and enemyVelocity.Magnitude > 3 then
                    predictedPos = predictedPos + enemyVelocity * predictionTime
                end

                local yOffset = math.clamp(dist / 40, 0, 0.06)
                local lookVector = (predictedPos - camPos).Unit
                local tiltedlook = Vector3.new(lookVector.X, lookVector.Y - yOffset, lookVector.Z).Unit
                camera.CFrame = CFrame.new(camPos, camPos + tiltedlook)
            end
        end

        if AimlockPlayerEnabled and cachedEnemy and currentTarget ~= cachedEnemy.Parent then
            setAimlockTarget(cachedEnemy.Parent)
        elseif AimlockNpcEnabled and cachedBoss and currentTarget ~= cachedBoss.Parent then
            setAimlockTarget(cachedBoss.Parent)
        elseif not cachedEnemy and not cachedBoss and currentTarget then
            setAimlockTarget(nil)
        end
    end)
end

-- =========================
-- lifecycle
-- =========================
local function onCharacterAdded(newChar)
    clearConnections()

    char = newChar

    camera = workspace.CurrentCamera
    cachedBoss = nil
    currentTarget = nil
    if currentHighlight then
        currentHighlight:Destroy()
        currentHighlight = nil
    end

    local humanoid = char:WaitForChild("Humanoid")
    local hrp = char:WaitForChild("HumanoidRootPart")

    table.insert(characterConnections, char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            hookTool(child)
        end
    end))

    table.insert(characterConnections, char.ChildRemoved:Connect(function(child)
        if child == currentTool then
            currentTool = nil
            vActive = false
            sharkZActive = false
            cursedZActive = false
            tiltEnabled = false
            stopTiltSmooth()
        end
    end))

    watchHealth(humanoid)

    tiltEnabled = false
    vActive, sharkZActive, cursedZActive = false, false, false
    rightTouches = {}
    stopTiltSmooth()
end

player.CharacterAdded:Connect(onCharacterAdded)

if player.Character then
	onCharacterAdded(player.Character)
end

-- =========================
-- State
-- =========================
function AimlockModule:SetPlayerAimlock(state)
    AimlockPlayerEnabled = state

    if not state then
        if currentTarget and currentTarget:FindFirstChildOfClass("Humanoid") then
            if currentHighlight then
                currentHighlight:Destroy()
                currentHighlight = nil
            end
        end
    end

    if state then
        cachedEnemy = nil
        local nearestHRP = getNearestEnemy(500)
        if nearestHRP and nearestHRP.Parent then
            setAimlockTarget(nearestHRP.Parent)
        else
            setAimlockTarget(nil)
        end
    end

    if not state and not AimlockNpcEnabled then
        watchDamageActive = false
        if dmgConn then pcall(function() dmgConn:Disconnect() end) dmgConn = nil end
    else
        watchDamageCounter()
        startRenderLoop()
    end
end

function AimlockModule:SetNpcAimlock(state)
    AimlockNpcEnabled = state

    if not state then
        if currentTarget and currentTarget:FindFirstChildOfClass("Humanoid") then
            if currentHighlight then
                currentHighlight:Destroy()
                currentHighlight = nil
            end
        end
    end

    if state then
        cachedBoss = nil
        local nearestBossHRP = getNearestBoss(500)
        if nearestBossHRP and nearestBossHRP.Parent then
            setAimlockTarget(nearestBossHRP.Parent)
        else
            setAimlockTarget(nil)
        end
    end

    if not state and not AimlockPlayerEnabled then
        watchDamageActive = false
        if dmgConn then pcall(function() dmgConn:Disconnect() end) dmgConn = nil end
    else
        watchDamageCounter()
        startRenderLoop()
    end
end

function AimlockModule:SetMiniTogglePlayerAimlock(state)
    AimlockPlayerEnabled = state

    if not MiniPlayerCreated and state then
        MiniPlayerState = { value = state }
        MiniPlayerGui = createMiniToggle("Player", UDim2.new(0,10,0,90), MiniPlayerState, function(val)
            AimlockPlayerEnabled = val
            if val then
                cachedEnemy = nil
                watchDamageCounter()
                startRenderLoop()
            else
                watchDamageActive = false
                if dmgConn then pcall(function() dmgConn:Disconnect() end) dmgConn = nil end
            end
        end)
        MiniPlayerCreated = true
        if AimlockPlayerEnabled then
            cachedEnemy = nil
            watchDamageCounter()
            startRenderLoop()
        end
    elseif MiniPlayerCreated then
        MiniPlayerState.value = state
        AimlockPlayerEnabled = state
        if MiniPlayerGui then
            MiniPlayerGui.Enabled = state
            local btn = MiniPlayerGui:FindFirstChildWhichIsA("TextButton", true)
            if btn then
                btn.Text = "Player" .. (state and " ON" or " OFF")
            end
        end

        if state then
            cachedEnemy = nil
            watchDamageCounter()
            startRenderLoop()
        else
            watchDamageActive = false
            if dmgConn then pcall(function() dmgConn:Disconnect() end) dmgConn = nil end
        end
    end
end

function AimlockModule:SetMiniToggleNpcAimlock(state)
    AimlockNpcEnabled = state

    if not MiniNpcCreated and state then
        MiniNpcState = { value = state }
        MiniNpcGui = createMiniToggle("NPC", UDim2.new(0,10,0,50), MiniNpcState, function(val)
            AimlockNpcEnabled = val
            if val then
                cachedBoss = nil
                watchDamageCounter()
                startRenderLoop()
            else
                watchDamageActive = false
                if dmgConn then pcall(function() dmgConn:Disconnect() end) dmgConn = nil end
            end
        end)
        MiniNpcCreated = true

        if AimlockNpcEnabled then
            cachedBoss = nil
            watchDamageCounter()
            startRenderLoop()
        end
    elseif MiniNpcCreated then
        MiniNpcState.value = state
        AimlockNpcEnabled = state
        if MiniNpcGui then
            MiniNpcGui.Enabled = state
            local btn = MiniNpcGui:FindFirstChildWhichIsA("TextButton", true)
            if btn then
                btn.Text = "NPC" .. (state and " ON" or " OFF")
            end
        end

        if state then
            cachedBoss = nil
            watchDamageCounter()
            startRenderLoop()
        else
            watchDamageActive = false
            if dmgConn then pcall(function() dmgConn:Disconnect() end) dmgConn = nil end
        end
    end
end

function AimlockModule:SetPrediction(state)
    PredictionEnabled = state
end

function AimlockModule:SetPredictionTime(num)
	if typeof(num) == "number" then
		PredictionAmount = num
	end
end

return AimlockModule
