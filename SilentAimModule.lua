local SilentAimModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local SilentAimPlayersEnabled = false
local SilentAimNPCsEnabled = false
local UserWantsPlayerAim = false
local UserWantsNPCAim = false
local PredictionEnabled = false
local HighlightEnabled = false
local AutoKen = false
local ZSkillOrM1 = false
local autoKenRunning = false

local renderConnection = nil
local currentTool = nil
local PlayersPosition, NPCPosition = nil, nil
local currentHighlight = nil
local currentTargetType = nil
local SelectedPlayer = nil

local PredictionAmount = 0.1
local maxRange = 1000

local characterConnections = {}
local Skills = {"X"}
local Booms = {"TAP"}

local function getHRP(model)
    return model and model:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(model)
    return model and model:FindFirstChildOfClass("Humanoid")
end

local function clearConnections()
    for _, conn in ipairs(characterConnections) do
        pcall(function() conn:Disconnect() end)
    end
    characterConnections = {}
end

local function getPredictedPosition(hrp)
    if not hrp then return nil end
    local humanoid = getHumanoid(hrp.Parent)
    if not humanoid then return hrp.Position end
    if not PredictionEnabled or humanoid.WalkSpeed < 5 then
        return hrp.Position
    end
    return hrp.Position + (hrp.Velocity * PredictionAmount)
end

local function isAllyWithMe(targetPlayer)
    local success, result = pcall(function()
        local myGui = player:FindFirstChild("PlayerGui")
        if not myGui then return false end
        
        local scrolling = myGui:FindFirstChild("Main")
            and myGui.Main:FindFirstChild("Allies")
            and myGui.Main.Allies:FindFirstChild("Container")
            and myGui.Main.Allies.Container:FindFirstChild("Allies")
            and myGui.Main.Allies.Container.Allies:FindFirstChild("ScrollingFrame")
        
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

local function getClosestPlayer(lpHRP)
    if not lpHRP then return nil end
    
    local closest, closestDist = nil, math.huge
    
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= player and isEnemy(pl) and pl.Character then
            local hum = getHumanoid(pl.Character)
            local hrp = getHRP(pl.Character)
            
            if hum and hum.Health > 0 and hrp then
                local dist = (hrp.Position - lpHRP.Position).Magnitude
                if dist <= maxRange and dist < closestDist then
                    closestDist = dist
                    closest = pl
                end
            end
        end
    end
    return closest
end

local function getClosestNPC(lpHRP)
    if not lpHRP then return nil end
    
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return nil end
    
    local closest, closestDist = nil, math.huge
    
    for _, npc in ipairs(enemiesFolder:GetChildren()) do
        if not npc:IsA("Model") then continue end
        
        local hum = getHumanoid(npc)
        local hrp = getHRP(npc)
        
        if hum and hum.Health > 0 and hrp then
            local dist = (hrp.Position - lpHRP.Position).Magnitude
            if dist <= maxRange and dist < closestDist then
                closestDist = dist
                closest = npc
            end
        end
    end
    return closest
end

local function clearHighlight()
    if currentHighlight then
        pcall(function() currentHighlight:Destroy() end)
        currentHighlight = nil
        currentTargetType = nil
    end
end

local function applyHighlight(targetModel, targetType)
    if not HighlightEnabled or not targetModel then return end
    if currentHighlight and currentHighlight.Adornee == targetModel then return end
    
    clearHighlight()
    
    local success = pcall(function()
        local hl = Instance.new("Highlight")
        hl.FillColor = Color3.fromRGB(255, 255, 0)
        hl.OutlineColor = Color3.fromRGB(255, 255, 0)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.Adornee = targetModel
        hl.Parent = targetModel
        currentHighlight = hl
        currentTargetType = targetType
    end)
end

local function startRenderLoop()
    if renderConnection then return end
    
    renderConnection = RunService.RenderStepped:Connect(function()
        local lpChar = player.Character
        if not lpChar then return end
        local lpHRP = getHRP(lpChar)
        if not lpHRP then return end
        
        if not SilentAimPlayersEnabled and not SilentAimNPCsEnabled then
            return
        end
        
        local targetModel, lookTargetPos = nil, nil
        
        if SilentAimPlayersEnabled then
            local targetPlayer = SelectedPlayer or getClosestPlayer(lpHRP)
            if targetPlayer and targetPlayer ~= player and targetPlayer.Character then
                local hrp = getHRP(targetPlayer.Character)
                PlayersPosition = getPredictedPosition(hrp)
                lookTargetPos = PlayersPosition
                targetModel = targetPlayer.Character
                applyHighlight(targetModel, "player")
            else
                PlayersPosition = nil
            end
        elseif currentTargetType == "player" then
            PlayersPosition = nil
            clearHighlight()
        end
        
        if SilentAimNPCsEnabled then
            local closestNPC = getClosestNPC(lpHRP)
            if closestNPC then
                local hrp = getHRP(closestNPC)
                NPCPosition = getPredictedPosition(hrp)
                lookTargetPos = NPCPosition
                if not targetModel then
                    targetModel = closestNPC
                    applyHighlight(targetModel, "NPC")
                end
            else
                NPCPosition = nil
            end
        elseif currentTargetType == "NPC" then
            NPCPosition = nil
            clearHighlight()
        end
        
        if currentTool and lookTargetPos then
            local isDough = currentTool.Name == "Dough-Dough"
            if not isDough then
                local lookVector = (Vector3.new(lookTargetPos.X, lpHRP.Position.Y, lookTargetPos.Z) - lpHRP.Position).Unit
                lpHRP.CFrame = CFrame.new(lpHRP.Position, lpHRP.Position + lookVector)
            end
        end
    end)
end

local function stopRenderLoop()
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end
end

local function hookTool(tool)
    currentTool = tool
    table.insert(characterConnections, tool.AncestryChanged:Connect(function(_, parent)
        if not parent then currentTool = nil end
    end))
end

local function onCharacterAdded(char)
    clearConnections()
    
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") then hookTool(child) end
    end
    
    table.insert(characterConnections, char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then hookTool(child) end
    end))
    
    table.insert(characterConnections, char.ChildRemoved:Connect(function(child)
        if child == currentTool then currentTool = nil end
    end))
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then onCharacterAdded(player.Character) end

task.spawn(function()
    local ok, hookMeta = pcall(getrawmetatable, game)
    if not ok or not hookMeta then return end
    
    setreadonly(hookMeta, false)
    local oldNamecall = hookMeta.__namecall
    
    hookMeta.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if method == "FireServer" then
            if typeof(args[1]) == "Vector3" then
                if SilentAimPlayersEnabled and PlayersPosition then
                    args[1] = PlayersPosition
                elseif SilentAimNPCsEnabled and NPCPosition then
                    args[1] = NPCPosition
                end
            elseif type(args[1]) == "string" and table.find(Booms, args[1]) then
                if ZSkillOrM1 then
                    if SilentAimPlayersEnabled and PlayersPosition then
                        args[2] = PlayersPosition
                    elseif SilentAimNPCsEnabled and NPCPosition then
                        args[2] = NPCPosition
                    end
                end
            end
        elseif method == "InvokeServer" then
            if currentTool and currentTool.Name == "Buddy Sword" then
                if type(args[1]) == "string" and table.find(Skills, args[1]) then
                    if SilentAimPlayersEnabled and PlayersPosition then
                        args[2] = PlayersPosition
                    elseif SilentAimNPCsEnabled and NPCPosition then
                        args[2] = NPCPosition
                    end
                end
            end
        end
        
        return oldNamecall(self, unpack(args))
    end)
    
    setreadonly(hookMeta, true)
end)

task.spawn(function()
    local MouseModule = ReplicatedStorage:FindFirstChild("Mouse")
    if not MouseModule then return end
    
    local ok, Mouse = pcall(require, MouseModule)
    if not ok or type(Mouse) ~= "table" then return end
    
    RunService.Heartbeat:Connect(function()
        if not ZSkillOrM1 or (not SilentAimPlayersEnabled and not SilentAimNPCsEnabled) then
            return
        end
        
        local targetCFrame = nil
        if PlayersPosition then
            targetCFrame = CFrame.new(PlayersPosition)
        elseif NPCPosition then
            targetCFrame = CFrame.new(NPCPosition)
        end
        
        if targetCFrame then
            pcall(function()
                Mouse.Hit = targetCFrame
                Mouse.Target = nil
            end)
        end
    end)
end)

local function HasTag(tagName)
    local char = player.Character
    if not char then return false end
    return CollectionService:HasTag(char, tagName)
end

local function startAutoKenLoop()
    if autoKenRunning then return end
    autoKenRunning = true
    
    task.spawn(function()
        while AutoKen do
            task.wait(0.1)
            
            if not HasTag("Ken") then continue end
            
            pcall(function()
                local playerGui = player:FindFirstChild("PlayerGui")
                if not playerGui then return end
                
                local mobileButtons = playerGui:FindFirstChild("MobileContextButtons")
                if not mobileButtons then return end
                
                local frame = mobileButtons:FindFirstChild("ContextButtonFrame")
                if not frame then return end
                
                local kenBtn = frame:FindFirstChild("BoundActionKen")
                if kenBtn and kenBtn:GetAttribute("Selected") ~= true then
                    kenBtn:SetAttribute("Selected", true)
                end
            end)
            
            pcall(function()
                local commE = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommE")
                commE:FireServer("Ken", true)
            end)
        end
        autoKenRunning = false
    end)
end

function SilentAimModule:SetAutoKen(state)
    AutoKen = state
    if state then startAutoKenLoop() end
end

function SilentAimModule:SetZSkillOrM1(state)
    ZSkillOrM1 = state
end

function SilentAimModule:Pause()
    SilentAimPlayersEnabled = false
    SilentAimNPCsEnabled = false
end

function SilentAimModule:Restore()
    SilentAimPlayersEnabled = UserWantsPlayerAim
    SilentAimNPCsEnabled = UserWantsNPCAim
end

function SilentAimModule:IsPlayerAimEnabled()
    return SilentAimPlayersEnabled
end

function SilentAimModule:IsNPCAimEnabled()
    return SilentAimNPCsEnabled
end

function SilentAimModule:SetDistanceLimit(num)
    if type(num) == "number" then
        maxRange = num
    end
end

function SilentAimModule:SetSelectedPlayer(playerName)
    if not playerName or playerName == "" then
        SelectedPlayer = nil
        return
    end
    SelectedPlayer = Players:FindFirstChild(playerName)
end

function SilentAimModule:GetSelectedPlayer()
    return SelectedPlayer and SelectedPlayer.Name or "None"
end

function SilentAimModule:SetPrediction(state)
    PredictionEnabled = state
end

function SilentAimModule:SetHighlight(state)
    HighlightEnabled = state
    if not state then clearHighlight() end
end

function SilentAimModule:IsHighlightEnabled()
    return HighlightEnabled
end

function SilentAimModule:SetPredictionAmount(num)
    if type(num) == "number" then
        PredictionAmount = num
    end
end

function SilentAimModule:SetPlayerSilentAim(state)
    UserWantsPlayerAim = state
    SilentAimPlayersEnabled = state
    
    if state then
        startRenderLoop()
    else
        if not SilentAimNPCsEnabled then
            stopRenderLoop()
            clearHighlight()
        end
    end
end

function SilentAimModule:SetNPCSilentAim(state)
    UserWantsNPCAim = state
    SilentAimNPCsEnabled = state
    
    if state then
        startRenderLoop()
    else
        if not SilentAimPlayersEnabled then
            stopRenderLoop()
            clearHighlight()
        end
    end
end

return SilentAimModule
