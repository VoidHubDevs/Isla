local SilentAimModule = {}

local VSkillModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/VoidHubDevs/Isla/refs/heads/main/ZSkillModule.lua"))()

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Character = player.Character or player.CharacterAdded:Wait()
local UserInputService = game:GetService("UserInputService")  
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera
local RS = game:GetService("ReplicatedStorage")
local commE = RS:WaitForChild("Remotes"):WaitForChild("CommE")
local MouseModule = RS:FindFirstChild("Mouse")

local Services = setmetatable({}, {
    __index = function(self, serviceName)
        local good, service = pcall(game.GetService, game, serviceName)
        if good then
            self[serviceName] = service
            return service
        end
    end
})

local SilentAimPlayersEnabled = false
local SilentAimNPCsEnabled = false
local UserWantsplayerAim = false
local UserWantsNPCAim = false
local PredictionEnabled = false
local HighlightEnabled = false 
local AutoKen = false
local ZSkillorM1 = false
local autoKenRunning = false

local renderConnection = nil
local currentTool = nil
local playersaimbot = nil
local PlayersPosition = nil
local NPCaimbot = nil
local NPCPosition = nil
local currentHighlight = nil
local currentTargetType = nil
local Selectedplayer = nil
local MiniPlayerState = nil
local MiniNpcState = nil
local MiniPlayerCreated = false
local MiniNpcCreated = false
local MiniPlayerGui, MiniNpcGui = nil, nil

local characterConnections = {}
local Skills = {"X"}
local Booms = {"TAP"}

local PredictionAmount = 0.1
local maxRange = 1000

local function getHRP(model)
    if not model or not model:FindFirstChild("HumanoidRootPart") then return nil end
    return model.HumanoidRootPart
end

local function clearConnections()
    for _, conn in ipairs(characterConnections) do
        pcall(function() conn:Disconnect() end)
    end
    characterConnections = {}
end

local function getPredictedPosition(hrp)
    if not hrp then return nil end
    local humanoid = hrp.Parent:FindFirstChildOfClass("Humanoid")
    if not humanoid then return hrp.Position end
    if not PredictionEnabled or humanoid.WalkSpeed < 5 then return hrp.Position end
    return hrp.Position + (hrp.Velocity * PredictionAmount)
end

-- ========================= RESTYLED MINI TOGGLE =========================
local function createMiniToggle(name, position, stateVarRef, realVarSetter)
    local playerGui = player:WaitForChild("PlayerGui")
    if playerGui:FindFirstChild(name .. "MiniToggleGuiS") then
        playerGui[name .. "MiniToggleGuiS"]:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = name .. "MiniToggleGuiS"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    local rowFrame = Instance.new("Frame", screenGui)
    rowFrame.Size = UDim2.new(0, 140, 0, 32)
    rowFrame.Position = position
    rowFrame.BackgroundTransparency = 1

    local rowLayout = Instance.new("UIListLayout", rowFrame)
    rowLayout.FillDirection = Enum.FillDirection.Horizontal
    rowLayout.Padding = UDim.new(0, 4)
    rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local labelBtn = Instance.new("TextButton", rowFrame)
    labelBtn.Size = UDim2.new(0, 80, 0, 30)
    labelBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    labelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    labelBtn.Text = name
    labelBtn.Font = Enum.Font.GothamBold
    labelBtn.TextSize = 10
    labelBtn.BorderSizePixel = 0
    Instance.new("UICorner", labelBtn).CornerRadius = UDim.new(0, 6)
    local lg = Instance.new("UIGradient", labelBtn)
    lg.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 200)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 150, 255))
    }
    lg.Rotation = 45
    local lStroke = Instance.new("UIStroke", labelBtn)
    lStroke.Color = Color3.fromRGB(0, 200, 255)
    lStroke.Thickness = 1.2

    local statusBtn = Instance.new("TextButton", rowFrame)
    statusBtn.Size = UDim2.new(0, 52, 0, 30)
    statusBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    statusBtn.TextColor3 = Color3.fromRGB(255, 0, 50)
    statusBtn.Text = "OFF"
    statusBtn.Font = Enum.Font.GothamBold
    statusBtn.TextSize = 10
    statusBtn.BorderSizePixel = 0
    Instance.new("UICorner", statusBtn).CornerRadius = UDim.new(0, 6)
    local sStroke = Instance.new("UIStroke", statusBtn)
    sStroke.Color = Color3.fromRGB(255, 0, 50)
    sStroke.Thickness = 1.2

    local function updateUI(state)
        statusBtn.Text = state and "ON" or "OFF"
        statusBtn.TextColor3 = state and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 0, 50)
        sStroke.Color = state and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 0, 50)
    end

    local function toggle()
        stateVarRef.value = not stateVarRef.value
        realVarSetter(stateVarRef.value)
        updateUI(stateVarRef.value)
    end
    labelBtn.MouseButton1Click:Connect(toggle)
    statusBtn.MouseButton1Click:Connect(toggle)

    local dragging, dragStart, startPos = false, nil, nil
    labelBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = rowFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    labelBtn.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            rowFrame.Position = UDim2.new(
                0, math.clamp(startPos.X.Offset + delta.X, 0, camera.ViewportSize.X - rowFrame.AbsoluteSize.X),
                0, math.clamp(startPos.Y.Offset + delta.Y, 0, camera.ViewportSize.Y - rowFrame.AbsoluteSize.Y)
            )
        end
    end)

    updateUI(stateVarRef.value)
    return screenGui
end
-- ========================================================================

local function isAllyWithMe(targetplayer)
    local myGui = player:FindFirstChild("PlayerGui")
    if not myGui then return false end
    local scrolling = myGui:FindFirstChild("Main")
        and myGui.Main:FindFirstChild("Allies")
        and myGui.Main.Allies:FindFirstChild("Container")
        and myGui.Main.Allies.Container:FindFirstChild("Allies")
        and myGui.Main.Allies.Container.Allies:FindFirstChild("ScrollingFrame")
    if scrolling then
        for _, frame in pairs(scrolling:GetDescendants()) do
            if frame:IsA("ImageButton") and frame.Name == targetplayer.Name then
                return true
            end
        end
    end
    return false
end

local function isEnemy(targetplayer)
    if not targetplayer or targetplayer == player then return false end
    local myTeam = player.Team
    local targetTeam = targetplayer.Team
    if myTeam and targetTeam then
        if myTeam.Name == "Pirates" and targetTeam.Name == "Marines" then return true end
        if myTeam.Name == "Marines" and targetTeam.Name == "Pirates" then return true end
        if myTeam.Name == "Pirates" and targetTeam.Name == "Pirates" then
            if isAllyWithMe(targetplayer) then return false end
            return true
        end
        if myTeam.Name == "Marines" and targetTeam.Name == "Marines" then return false end
    end
    return true
end

local function getClosestplayer(lpHRP)
    if not lpHRP then return nil end
    local closest, closestDist = nil, math.huge
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= player and isEnemy(pl) and pl.Character and pl.Character.Parent ~= nil then
            local hum = pl.Character:FindFirstChildWhichIsA("Humanoid")
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
    local enemiesFolder = workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return nil end
    local closest, closestDist = nil, math.huge
    for _, npc in ipairs(enemiesFolder:GetChildren()) do
        if npc:IsA("Model") then
            local hum = npc:FindFirstChildWhichIsA("Humanoid")
            local hrp = getHRP(npc)
            if hum and hum.Health > 0 and hrp then
                local dist = (hrp.Position - lpHRP.Position).Magnitude
                if dist <= maxRange and dist < closestDist then
                    closestDist = dist
                    closest = npc
                end
            end
        end
    end
    return closest
end

local function applyHighlight(targetModel, targetType)
    if not HighlightEnabled then return end
    if not targetModel then return end
    if currentHighlight and currentHighlight.Adornee == targetModel then return end
    if currentHighlight then
        currentHighlight:Destroy()
        currentHighlight = nil
        currentTargetType = nil
    end
    local hl = Instance.new("Highlight")
    hl.FillColor = Color3.fromRGB(255, 255, 0)
    hl.OutlineColor = Color3.fromRGB(255, 255, 0)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.Adornee = targetModel
    hl.Parent = targetModel
    currentHighlight = hl
    currentTargetType = targetType
    VSkillModule:CheckVSkillUsage(SilentAimModule)
end

local function clearHighlight()
    if currentHighlight then
        currentHighlight:Destroy()
        currentHighlight = nil
        currentTargetType = nil
    end
end

local function isSkillReadyForTool(toolName)
    if not toolName then return false end
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    local skillsFolder = playerGui:FindFirstChild("Main") and playerGui.Main:FindFirstChild("Skills")
    if not skillsFolder then return false end
    local toolFrame = skillsFolder:FindFirstChild(toolName)
    if not toolFrame then return false end
    for _, skillKey in ipairs({"Z","X","C","V"}) do
        local skill = toolFrame:FindFirstChild(skillKey)
        if skill and skill:FindFirstChild("Cooldown") and skill.Cooldown:IsA("Frame") then
            if skill.Cooldown.Size.X.Scale == 1.0 then return true end
        end
    end
    return false
end

local function isNotDoughValidCondition()
    return (currentTool and currentTool.Name == "Dough-Dough")
end

local function isNotValidCondition()
    return (currentTool and currentTool.Name == "Lightning-Lightning")
        or (currentTool and currentTool.Name == "Portal-Portal")
end

local function startRenderLoop()
    if renderConnection then return end
    renderConnection = RunService.RenderStepped:Connect(function()
        local lpChar = player.Character
        if not lpChar then return end
        local lpHRP = lpChar:FindFirstChild("HumanoidRootPart")
        if not lpHRP then return end
        if not SilentAimPlayersEnabled and not SilentAimNPCsEnabled then return end

        local targetModel = nil
        local lookTargetPos = nil

        if SilentAimPlayersEnabled then
            local targetplayer = Selectedplayer or getClosestplayer(lpHRP)
            if targetplayer and targetplayer ~= player and targetplayer.Character then
                playersaimbot = targetplayer.Name
                local hrp = getHRP(targetplayer.Character)
                PlayersPosition = getPredictedPosition(hrp)
                lookTargetPos = PlayersPosition
                targetModel = targetplayer.Character
                -- NO player highlight (removed)
            else
                playersaimbot, PlayersPosition = nil, nil
            end
        elseif currentTargetType == "player" then
            playersaimbot, PlayersPosition = nil, nil
            clearHighlight()
        end

        if SilentAimNPCsEnabled then
            local closestNPC = getClosestNPC(lpHRP)
            if closestNPC then
                NPCaimbot = closestNPC.Name
                local hrp = getHRP(closestNPC)
                NPCPosition = getPredictedPosition(hrp)
                lookTargetPos = NPCPosition
                if not targetModel then
                    targetModel = closestNPC
                    applyHighlight(targetModel, "NPC")
                end
            else
                NPCaimbot, NPCPosition = nil, nil
            end
        elseif currentTargetType == "NPC" then
            NPCaimbot, NPCPosition = nil, nil
            clearHighlight()
        end

        if currentTool and lookTargetPos and isSkillReadyForTool(currentTool.Name) and not isNotDoughValidCondition() then
            local lookVector = (Vector3.new(lookTargetPos.X, lpHRP.Position.Y, lookTargetPos.Z) - lpHRP.Position).Unit
            lpHRP.CFrame = CFrame.new(lpHRP.Position, lpHRP.Position + lookVector)
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

local function isValidCondition()
    return (currentTool and currentTool.Name == "Buddy Sword")
end

spawn(function()
    local ok, hookMeta = pcall(getrawmetatable, game)
    if ok and hookMeta then
        setreadonly(hookMeta, false)
        local OldHook
        OldHook = hookmetamethod(game, "__namecall", function(self, V1, V2, ...)
            local Method = (getnamecallmethod and getnamecallmethod():lower()) or ""
            if tostring(self) == "RemoteEvent" and Method == "fireserver" then
                if typeof(V1) == "Vector3" then
                    if SilentAimPlayersEnabled and PlayersPosition then
                        return OldHook(self, PlayersPosition, V2, ...)
                    elseif SilentAimNPCsEnabled and NPCPosition then
                        return OldHook(self, NPCPosition, V2, ...)
                    end
                end
                if type(V1) == "string" and table.find(Booms, V1) then
                    if ZSkillorM1 then
                        if SilentAimPlayersEnabled and PlayersPosition then
                            return OldHook(self, V1, PlayersPosition, nil, ...)
                        elseif SilentAimNPCsEnabled and NPCPosition then
                            return OldHook(self, V1, NPCPosition, nil, ...)
                        end
                    end
                end
            elseif Method == "invokeserver" then
                if isValidCondition() then
                    if type(V1) == "string" and table.find(Skills, V1) then
                        if SilentAimPlayersEnabled and PlayersPosition then
                            return OldHook(self, V1, PlayersPosition, nil, ...)
                        elseif SilentAimNPCsEnabled and NPCPosition then
                            return OldHook(self, V1, NPCPosition, nil, ...)
                        end
                    end
                end
            end
            return OldHook(self, V1, V2, ...)
        end)
        setreadonly(hookMeta, true)
    end
end)

if not isNotValidCondition() then
    if MouseModule and typeof(MouseModule) == "Instance" then
        local ok2, okResult = pcall(function() return require(MouseModule) end)
        if ok2 and okResult then
            Mouse = type(okResult) == "table" and okResult or nil
        else
            Mouse = nil
        end
        if Mouse then
            local Char = player.Character or player.CharacterAdded:Wait()
            local RootPart = Char and Char:FindFirstChild("HumanoidRootPart")
            if RootPart then
                pcall(function()
                    if type(Mouse) == "table" then
                        Mouse.Hit = CFrame.new(RootPart.Position)
                        Mouse.Target = RootPart
                    end
                end)
            else
                task.spawn(function()
                    local Char2 = player.Character or player.CharacterAdded:Wait()
                    local RootPart2 = Char2:WaitForChild("HumanoidRootPart")
                    pcall(function()
                        if type(Mouse) == "table" then
                            Mouse.Hit = CFrame.new(RootPart2.Position)
                            Mouse.Target = RootPart2
                        end
                    end)
                end)
            end
        end
        RunService.Heartbeat:Connect(function()
            if not ZSkillorM1 or (not SilentAimPlayersEnabled and not SilentAimNPCsEnabled) then return end
            if Mouse and ZSkillorM1 and (SilentAimPlayersEnabled or SilentAimNPCsEnabled) then
                local targetCFrame = nil
                if PlayersPosition then
                    targetCFrame = CFrame.new(PlayersPosition)
                elseif NPCPosition then
                    targetCFrame = CFrame.new(NPCPosition)
                end
                if targetCFrame then
                    pcall(function()
                        if type(Mouse) == "table" then
                            Mouse.Hit = targetCFrame
                            Mouse.Target = nil
                        end
                    end)
                    if MouseModule then
                        local ok3, MouseData = pcall(require, MouseModule)
                        if ok3 and type(MouseData) == "table" then
                            MouseData.Hit = targetCFrame
                            MouseData.Target = nil
                        end
                    end
                end
            end
        end)
    end
end

local HasTag = function(tagName)
    local char = player.Character
    if not char then return false end
    return Services.CollectionService:HasTag(char, tagName)
end

local function startAutoKenLoop()
    if autoKenRunning then return end
    autoKenRunning = true
    task.spawn(function()
        while AutoKen do
            task.wait(0.1)
            if HasTag("Ken") then
                local playerGui = player:FindFirstChild("PlayerGui")
                if playerGui then
                    local kenButton = playerGui:FindFirstChild("MobileContextButtons")
                        and playerGui.MobileContextButtons.ContextButtonFrame:FindFirstChild("BoundActionKen")
                    if kenButton and kenButton:GetAttribute("Selected") ~= true then
                        kenButton:SetAttribute("Selected", true)
                    end
                end
                local observationManager = getrenv()._G.OM
                if observationManager and not observationManager.active then
                    observationManager.radius = 0
                    observationManager:setActive(true)
                    commE:FireServer("Ken", true)
                end
            end
        end
        autoKenRunning = false
    end)
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

function SilentAimModule:SetAutoKen(state) AutoKen = state; if state then startAutoKenLoop() end end
function SilentAimModule:SetZSkillorM1(state) ZSkillorM1 = state end
function SilentAimModule:Pause() SilentAimPlayersEnabled = false; SilentAimNPCsEnabled = false end
function SilentAimModule:Restore() SilentAimPlayersEnabled = UserWantsplayerAim; SilentAimNPCsEnabled = UserWantsNPCAim end
function SilentAimModule:IsplayerAimEnabled() return SilentAimPlayersEnabled end
function SilentAimModule:IsNPCAimEnabled() return SilentAimNPCsEnabled end
function SilentAimModule:SetDistanceLimit(num) if typeof(num) == "number" then maxRange = num end end
function SilentAimModule:SetSelectedPlayer(playerName)
    if not playerName or playerName == "" then Selectedplayer = nil; return end
    local found = Players:FindFirstChild(playerName)
    if found then Selectedplayer = found end
end
function SilentAimModule:GetSelectedPlayer() return Selectedplayer and Selectedplayer.Name or "None" end
function SilentAimModule:SetPrediction(state) PredictionEnabled = state end
function SilentAimModule:SetHighlight(state) HighlightEnabled = state; if not state then clearHighlight() end end
function SilentAimModule:IsHighlightEnabled() return HighlightEnabled end
function SilentAimModule:SetPredictionAmount(num) if typeof(num) == "number" then PredictionAmount = num end end

function SilentAimModule:SetPlayerSilentAim(state)
    UserWantsplayerAim = state
    SilentAimPlayersEnabled = state
    if state then startRenderLoop()
    else if not SilentAimNPCsEnabled then stopRenderLoop() end end
end

function SilentAimModule:SetNPCSilentAim(state)
    UserWantsNPCAim = state
    SilentAimNPCsEnabled = state
    if state then startRenderLoop()
    else if not SilentAimPlayersEnabled then stopRenderLoop() end end
end

local function UpdateSilentAimState()
    SilentAimPlayersEnabled = MiniPlayerState and MiniPlayerState.value or false
    SilentAimNPCsEnabled    = MiniNpcState and MiniNpcState.value or false
    UserWantsplayerAim = SilentAimPlayersEnabled
    UserWantsNPCAim    = SilentAimNPCsEnabled
    if SilentAimPlayersEnabled or SilentAimNPCsEnabled then startRenderLoop()
    else stopRenderLoop(); clearHighlight() end
end

function SilentAimModule:SetMiniTogglePlayerSilentAim(state)
    if not MiniPlayerCreated and state then
        MiniPlayerState = { value = SilentAimPlayersEnabled }
        MiniPlayerGui = createMiniToggle("Player", UDim2.new(0,10,0,90), MiniPlayerState, function(val)
            MiniPlayerState.value = val; UpdateSilentAimState()
        end)
        MiniPlayerCreated = true
    elseif MiniPlayerCreated then
        if MiniPlayerGui then MiniPlayerGui.Enabled = state end
    end
end

function SilentAimModule:SetMiniToggleNpcSilentAim(state)
    if not MiniNpcCreated and state then
        MiniNpcState = { value = SilentAimNPCsEnabled }
        MiniNpcGui = createMiniToggle("NPC", UDim2.new(0,10,0,50), MiniNpcState, function(val)
            MiniNpcState.value = val; UpdateSilentAimState()
        end)
        MiniNpcCreated = true
    elseif MiniNpcCreated then
        if MiniNpcGui then MiniNpcGui.Enabled = state end
    end
end

return SilentAimModule
