local AimlockModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local AimlockPlayerEnabled, AimlockNpcEnabled, PredictionEnabled = false, false, false
local PredictionAmount = 0.1
local currentTarget = nil
local currentHighlight = nil
local cachedEnemy, cachedBoss = nil, nil

local renderConnection = nil
local dmgConnection = nil
local characterConnections = {}
local touchConnections = {}

local currentTool = nil
local vActive, sharkZActive, cursedZActive = false, false, false
local tiltEnabled = false
local rightTouches = {}
local tiltConn, preTiltCFrame = nil, nil

local function clearConnections()
    for _, conn in ipairs(characterConnections) do
        pcall(function() conn:Disconnect() end)
    end
    characterConnections = {}
end

local function safeDisconnect(conn)
    if conn then
        pcall(function() conn:Disconnect() end)
    end
    return nil
end

local function isAllyWithMe(targetPlayer)
    if not targetPlayer then return false end
    
    local success, result = pcall(function()
        local myGui = player:FindFirstChild("PlayerGui")
        if not myGui then return false end

        local main = myGui:FindFirstChild("Main")
        if not main then return false end
        
        local allies = main:FindFirstChild("Allies")
        if not allies then return false end
        
        local container = allies:FindFirstChild("Container")
        if not container then return false end
        
        local alliesFolder = container:FindFirstChild("Allies")
        if not alliesFolder then return false end
        
        local scrolling = alliesFolder:FindFirstChild("ScrollingFrame")
        if not scrolling then return false end

        for _, frame in pairs(scrolling:GetDescendants()) do
            if frame:IsA("ImageButton") and frame.Name == targetPlayer.Name then
                return true
            end
        end
        return false
    end)
    
    return success and result
end

local function isEnemy(targetPlayer)
    if not targetPlayer or targetPlayer == player then return false end

    local myTeam = player.Team
    local targetTeam = targetPlayer.Team

    if not myTeam or not targetTeam then return true end
    
    if myTeam.Name == "Pirates" and targetTeam.Name == "Marines" then return true end
    if myTeam.Name == "Marines" and targetTeam.Name == "Pirates" then return true end
    if myTeam.Name == "Pirates" and targetTeam.Name == "Pirates" then
        return not isAllyWithMe(targetPlayer)
    end
    if myTeam.Name == "Marines" and targetTeam.Name == "Marines" then return false end
    
    return true
end

local function getHRP(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(char)
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getNearestEnemy(maxDistance)
    local char = player.Character
    local hrp = getHRP(char)
    if not hrp then return nil end

    local nearest, shortest = nil, maxDistance or 100

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and isEnemy(p) then
            local pChar = p.Character
            local pHRP = getHRP(pChar)
            local hum = getHumanoid(pChar)
            
            if pHRP and hum and hum.Health > 0 then
                local dist = (pHRP.Position - hrp.Position).Magnitude
                if dist < shortest then
                    shortest = dist
                    nearest = pHRP
                end
            end
        end
    end

    return nearest
end

local function getNearestBoss(maxDistance)
    local char = player.Character
    local hrp = getHRP(char)
    if not hrp then return nil end

    local nearest, shortest = nil, maxDistance or 500
    local bossFolder = Workspace:FindFirstChild("Enemies")
    
    if not bossFolder then return nil end

    for _, boss in pairs(bossFolder:GetChildren()) do
        if not boss:IsA("Model") then continue end
        
        local bossHRP = getHRP(boss)
        local hum = getHumanoid(boss)
        
        if bossHRP and hum and hum.Health > 0 then
            local dist = (bossHRP.Position - hrp.Position).Magnitude
            if dist < shortest then
                shortest = dist
                nearest = bossHRP
            end
        end
    end
    
    return nearest
end

local function clearHighlight()
    if currentHighlight then
        pcall(function() currentHighlight:Destroy() end)
        currentHighlight = nil
    end
end

local function setHighlight(targetModel)
    clearHighlight()
    
    if not targetModel then
        currentTarget = nil
        return
    end

    local hum = getHumanoid(targetModel)
    if not hum or hum.Health <= 0 then
        currentTarget = nil
        return
    end

    local success = pcall(function()
        local highlight = Instance.new("Highlight")
        highlight.FillColor = Color3.fromRGB(255, 255, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.Adornee = targetModel
        highlight.Parent = targetModel
        currentHighlight = highlight
    end)
    
    if success then
        currentTarget = targetModel
        
        local diedConn = hum.Died:Connect(function()
            clearHighlight()
            currentTarget = nil
        end)
        table.insert(characterConnections, diedConn)
    end
end

local function stopTiltSmooth()
    tiltConn = safeDisconnect(tiltConn)
    
    if not preTiltCFrame then return end
    
    local startCF = camera.CFrame
    local endCF = preTiltCFrame
    preTiltCFrame = nil

    local alpha = 0
    local restoreConn
    restoreConn = RunService.RenderStepped:Connect(function(dt)
        alpha = math.min(alpha + dt * 5, 1)
        camera.CFrame = startCF:Lerp(endCF, alpha)
        if alpha >= 1 then
            restoreConn:Disconnect()
        end
    end)
end

local function startTilt()
    tiltConn = safeDisconnect(tiltConn)
    
    preTiltCFrame = preTiltCFrame or camera.CFrame
    local char = player.Character
    local hrp = getHRP(char)
    local hum = getHumanoid(char)
    
    if not hrp or not hum then return end

    local startCF = camera.CFrame
    local camPos = startCF.Position

    local tiltOffset = (hum.FloorMaterial ~= Enum.Material.Air) and Vector3.new(0, 6, 0) or Vector3.new(0, 40, 0)
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

local function startRenderLoop()
    if renderConnection then return end

    renderConnection = RunService.RenderStepped:Connect(function()
        if not AimlockPlayerEnabled and not AimlockNpcEnabled then
            renderConnection = safeDisconnect(renderConnection)
            return
        end

        local char = player.Character
        local hrp = getHRP(char)
        if not hrp then return end

        if AimlockPlayerEnabled then
            if not cachedEnemy or not cachedEnemy.Parent or not getHumanoid(cachedEnemy.Parent) or getHumanoid(cachedEnemy.Parent).Health <= 0 then
                cachedEnemy = getNearestEnemy(500)
            end
        else
            cachedEnemy = nil
        end

        if AimlockNpcEnabled then
            if not cachedBoss or not cachedBoss.Parent or not getHumanoid(cachedBoss.Parent) or getHumanoid(cachedBoss.Parent).Health <= 0 then
                cachedBoss = getNearestBoss(500)
            end
        else
            cachedBoss = nil
        end

        if not tiltEnabled then
            local targetHRP = cachedEnemy or cachedBoss
            if targetHRP then
                local camCFrame = camera.CFrame
                local camPos = camCFrame.Position
                local dist = (targetHRP.Position - camPos).Magnitude
                
                local predictedPos = targetHRP.Position
                if PredictionEnabled then
                    local velocity = targetHRP.Velocity
                    if velocity.Magnitude > 3 then
                        predictedPos = predictedPos + velocity * PredictionAmount
                    end
                end

                local yOffset = math.clamp(dist / 40, 0, 0.06)
                local lookVector = (predictedPos - camPos).Unit
                local tiltedLook = Vector3.new(lookVector.X, lookVector.Y - yOffset, lookVector.Z).Unit
                camera.CFrame = CFrame.new(camPos, camPos + tiltedLook)
            end
        end

        if AimlockPlayerEnabled and cachedEnemy and currentTarget ~= cachedEnemy.Parent then
            setHighlight(cachedEnemy.Parent)
        elseif AimlockNpcEnabled and cachedBoss and currentTarget ~= cachedBoss.Parent then
            setHighlight(cachedBoss.Parent)
        elseif not cachedEnemy and not cachedBoss then
            clearHighlight()
            currentTarget = nil
        end
    end)
end

local function hookTool(tool)
    if not tool then return end
    currentTool = tool
    
    local ancConn = tool.AncestryChanged:Connect(function(_, parent)
        if not parent then
            currentTool = nil
            vActive, sharkZActive, cursedZActive = false, false, false
            tiltEnabled = false
            stopTiltSmooth()
        end
    end)
    table.insert(characterConnections, ancConn)
end

local function onCharacterAdded(newChar)
    clearConnections()
    
    local hrp = newChar:WaitForChild("HumanoidRootPart", 5)
    local hum = newChar:WaitForChild("Humanoid", 5)
    
    if not hrp or not hum then return end

    table.insert(characterConnections, newChar.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then hookTool(child) end
    end))
    
    table.insert(characterConnections, newChar.ChildRemoved:Connect(function(child)
        if child == currentTool then
            currentTool = nil
            vActive, sharkZActive, cursedZActive = false, false, false
            tiltEnabled = false
            stopTiltSmooth()
        end
    end))
    
    for _, child in pairs(newChar:GetChildren()) do
        if child:IsA("Tool") then hookTool(child) end
    end
    
    tiltEnabled = false
    rightTouches = {}
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then onCharacterAdded(player.Character) end

table.insert(touchConnections, UserInputService.TouchStarted:Connect(function(touch)
    camera = Workspace.CurrentCamera
    if not camera or not touch.Position then return end

    if touch.Position.X > camera.ViewportSize.X / 2 then
        rightTouches[touch] = true
        if tiltEnabled and currentTool then
            if (currentTool.Name == "Dough-Dough" and vActive) or
               (currentTool.Name == "Shark Anchor" and sharkZActive) or
               (currentTool.Name == "Cursed Dual Katana" and cursedZActive) then
                startTilt()
            end
        end
    end
end))

table.insert(touchConnections, UserInputService.TouchEnded:Connect(function(touch)
    if rightTouches[touch] then
        rightTouches[touch] = nil
        if not next(rightTouches) then
            stopTiltSmooth()
            tiltEnabled = false
            vActive, sharkZActive, cursedZActive = false, false, false
        end
    end
end))

if not getgenv().AimlockHooked then
    getgenv().AimlockHooked = true
    
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if method == "InvokeServer" or method == "FireServer" then
            local a1 = args[1]
            if typeof(a1) ~= "string" then return oldNamecall(self, ...) end
            
            local upperA1 = a1:upper()
            
            if upperA1 == "V" and currentTool and currentTool.Name == "Dough-Dough" then
                vActive = true
                task.delay(2, function()
                    vActive = false
                    if tiltEnabled and next(rightTouches) then
                        tiltEnabled = false
                        stopTiltSmooth()
                        rightTouches = {}
                    end
                end)
            elseif upperA1 == "Z" then
                if currentTool and currentTool.Name == "Shark Anchor" then
                    sharkZActive = true
                    task.delay(2, function()
                        sharkZActive = false
                        if tiltEnabled and next(rightTouches) then
                            tiltEnabled = false
                            stopTiltSmooth()
                            rightTouches = {}
                        end
                    end)
                elseif currentTool and currentTool.Name == "Cursed Dual Katana" then
                    cursedZActive = true
                    task.delay(2, function()
                        cursedZActive = false
                        if tiltEnabled and next(rightTouches) then
                            tiltEnabled = false
                            stopTiltSmooth()
                            rightTouches = {}
                        end
                    end)
                end
            end
        end
        
        return oldNamecall(self, ...)
    end)
end

function AimlockModule:SetPlayerAimlock(state)
    AimlockPlayerEnabled = state
    
    if not state then
        clearHighlight()
        cachedEnemy = nil
    else
        cachedEnemy = getNearestEnemy(500)
        if cachedEnemy then
            setHighlight(cachedEnemy.Parent)
        end
        startRenderLoop()
    end
end

function AimlockModule:SetNpcAimlock(state)
    AimlockNpcEnabled = state
    
    if not state then
        clearHighlight()
        cachedBoss = nil
    else
        cachedBoss = getNearestBoss(500)
        if cachedBoss then
            setHighlight(cachedBoss.Parent)
        end
        startRenderLoop()
    end
end

function AimlockModule:SetPrediction(state)
    PredictionEnabled = state
end

function AimlockModule:SetPredictionTime(num)
    if type(num) == "number" then
        PredictionAmount = num
    end
end

return AimlockModule
