--[[
    Silent Aim Module - Optimized v2.0
    Efficient targeting, minimal CPU usage
--]]

local SilentAimModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- State
local SilentAimPlayers = false
local SilentAimNPCs = false
local UserWantsPlayer = false
local UserWantsNPC = false
local PredictionEnabled = false
local HighlightEnabled = false
local AutoKen = false
local ZSkillOrM1 = false

-- Settings
local PredictionAmount = 0.135
local MaxRange = 1000
local TargetRefreshRate = 0.1

-- Runtime Data
local RenderConnection = nil
local AutoKenTask = nil
local CurrentHighlight = nil
local CurrentTool = nil
local TargetPosition = nil
local CurrentTarget = nil
local LastTargetUpdate = 0

local Skills = {"X", "C", "V", "Z"}
local Booms = {"TAP", "M1"}

-- Utility
local function SafeCall(func, ...)
    local success, result = pcall(func, ...)
    return success and result or nil
end

local function GetHRP(model)
    return model and model:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid(model)
    return model and model:FindFirstChildOfClass("Humanoid")
end

local function IsAlive(model)
    local hum = GetHumanoid(model)
    return hum and hum.Health > 0
end

-- Ally Check
local function IsAlly(targetPlayer)
    return SafeCall(function()
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
        local scroll = alliesFolder:FindFirstChild("ScrollingFrame")
        if not scroll then return false end
        for _, frame in pairs(scroll:GetDescendants()) do
            if frame:IsA("ImageButton") and frame.Name == targetPlayer.Name then
                return true
            end
        end
        return false
    end) or false
end

local function IsEnemy(targetPlayer)
    if not targetPlayer or targetPlayer == player then return false end
    local myTeam = player.Team
    local targetTeam = targetPlayer.Team
    if not myTeam or not targetTeam then return true end
    local myName, theirName = myTeam.Name, targetTeam.Name
    if myName == "Pirates" and theirName == "Marines" then return true end
    if myName == "Marines" and theirName == "Pirates" then return true end
    if myName == "Pirates" and theirName == "Pirates" then
        return not IsAlly(targetPlayer)
    end
    if myName == "Marines" and theirName == "Marines" then return false end
    return true
end

local function GetPredictedPosition(hrp)
    if not hrp then return nil end
    local humanoid = GetHumanoid(hrp.Parent)
    if not humanoid then return hrp.Position end
    if not PredictionEnabled or humanoid.WalkSpeed < 5 then
        return hrp.Position
    end
    return hrp.Position + (hrp.Velocity * PredictionAmount)
end

local function GetClosestPlayer()
    local myChar = player.Character
    local myHRP = GetHRP(myChar)
    if not myHRP then return nil end
    
    local closest, closestDist = nil, MaxRange
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and IsEnemy(plr) then
            local char = plr.Character
            local hrp = GetHRP(char)
            local hum = GetHumanoid(char)
            
            if hrp and hum and hum.Health > 0 then
                local dist = (hrp.Position - myHRP.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = plr
                end
            end
        end
    end
    
    return closest
end

local function GetClosestNPC()
    local myChar = player.Character
    local myHRP = GetHRP(myChar)
    if not myHRP then return nil end
    
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return nil end
    
    local closest, closestDist = nil, MaxRange
    
    for _, npc in ipairs(enemiesFolder:GetChildren()) do
        if npc:IsA("Model") then
            local hrp = GetHRP(npc)
            local hum = GetHumanoid(npc)
            
            if hrp and hum and hum.Health > 0 then
                local dist = (hrp.Position - myHRP.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = npc
                end
            end
        end
    end
    
    return closest
end

local function ClearHighlight()
    if CurrentHighlight then
        SafeCall(function() CurrentHighlight:Destroy() end)
        CurrentHighlight = nil
    end
end

local function ApplyHighlight(targetModel)
    if not HighlightEnabled or not targetModel then return end
    if CurrentHighlight and CurrentHighlight.Adornee == targetModel then return end
    
    ClearHighlight()
    
    SafeCall(function()
        local hl = Instance.new("Highlight")
        hl.FillColor = Color3.fromRGB(255, 255, 0)
        hl.OutlineColor = Color3.fromRGB(255, 255, 0)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.Adornee = targetModel
        hl.Parent = targetModel
        CurrentHighlight = hl
    end)
end

local function UpdateTarget()
    local now = tick()
    if now - LastTargetUpdate < TargetRefreshRate then return end
    LastTargetUpdate = now
    
    TargetPosition = nil
    CurrentTarget = nil
    
    if SilentAimPlayers then
        local target = GetClosestPlayer()
        if target and target.Character then
            local hrp = GetHRP(target.Character)
            if hrp then
                TargetPosition = GetPredictedPosition(hrp)
                CurrentTarget = target.Character
                ApplyHighlight(target.Character)
                return
            end
        end
    end
    
    if SilentAimNPCs then
        local target = GetClosestNPC()
        if target then
            local hrp = GetHRP(target)
            if hrp then
                TargetPosition = GetPredictedPosition(hrp)
                CurrentTarget = target
                ApplyHighlight(target)
            end
        end
    end
    
    if not CurrentTarget then
        ClearHighlight()
    end
end

local function StartRender()
    if RenderConnection then return end
    
    RenderConnection = RunService.RenderStepped:Connect(function()
        if not SilentAimPlayers and not SilentAimNPCs then return end
        
        UpdateTarget()
        
        if CurrentTarget and TargetPosition then
            local myChar = player.Character
            local myHRP = GetHRP(myChar)
            
            if myHRP and CurrentTool then
                local isDough = CurrentTool.Name == "Dough-Dough"
                if not isDough then
                    local lookVector = (Vector3.new(TargetPosition.X, myHRP.Position.Y, TargetPosition.Z) - myHRP.Position).Unit
                    myHRP.CFrame = CFrame.new(myHRP.Position, myHRP.Position + lookVector)
                end
            end
        end
    end)
end

local function StopRender()
    if RenderConnection then
        RenderConnection:Disconnect()
        RenderConnection = nil
    end
    ClearHighlight()
end

local function OnToolEquipped(tool)
    CurrentTool = tool
end

local function SetupCharacter(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            OnToolEquipped(child)
        end
    end)
    
    char.ChildRemoved:Connect(function(child)
        if child == CurrentTool then
            CurrentTool = nil
        end
    end)
    
    for _, child in pairs(char:GetChildren()) do
        if child:IsA("Tool") then
            OnToolEquipped(child)
        end
    end
end

player.CharacterAdded:Connect(SetupCharacter)
if player.Character then SetupCharacter(player.Character) end

-- MetaMethod Hook
if not getgenv().VoidHub_SilentAimHooked then
    getgenv().VoidHub_SilentAimHooked = true
    
    local ok, hookMeta = pcall(getrawmetatable, game)
    if ok and hookMeta then
        setreadonly(hookMeta, false)
        local oldNamecall = hookMeta.__namecall
        
        hookMeta.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            
            if method == "FireServer" then
                if typeof(args[1]) == "Vector3" then
                    if TargetPosition and (SilentAimPlayers or SilentAimNPCs) then
                        args[1] = TargetPosition
                    end
                elseif type(args[1]) == "string" and table.find(Booms, args[1]) then
                    if ZSkillOrM1 and TargetPosition and (SilentAimPlayers or SilentAimNPCs) then
                        args[2] = TargetPosition
                    end
                end
            elseif method == "InvokeServer" then
                if CurrentTool and CurrentTool.Name == "Buddy Sword" then
                    if type(args[1]) == "string" and table.find(Skills, args[1]) then
                        if TargetPosition and (SilentAimPlayers or SilentAimNPCs) then
                            args[2] = TargetPosition
                        end
                    end
                end
            end
            
            return oldNamecall(self, unpack(args))
        end)
        
        setreadonly(hookMeta, true)
    end
end

-- Mouse Module Hook
if not getgenv().VoidHub_MouseHooked then
    getgenv().VoidHub_MouseHooked = true
    
    local MouseModule = ReplicatedStorage:FindFirstChild("Mouse")
    if MouseModule then
        local ok, Mouse = pcall(require, MouseModule)
        if ok and type(Mouse) == "table" then
            RunService.Heartbeat:Connect(function()
                if not ZSkillOrM1 or not TargetPosition then return end
                if not SilentAimPlayers and not SilentAimNPCs then return end
                
                SafeCall(function()
                    Mouse.Hit = CFrame.new(TargetPosition)
                    Mouse.Target = nil
                end)
            end)
        end
    end
end

-- Auto Ken
local function HasKenTag()
    local char = player.Character
    if not char then return false end
    return SafeCall(function()
        return game:GetService("CollectionService"):HasTag(char, "Ken")
    end) or false
end

local function StartAutoKen()
    if AutoKenTask then return end
    
    AutoKenTask = task.spawn(function()
        while AutoKen do
            if HasKenTag() then
                SafeCall(function()
                    local commE = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommE")
                    commE:FireServer("Ken", true)
                end)
            end
            task.wait(0.1)
        end
        AutoKenTask = nil
    end)
end

-- API
function SilentAimModule:SetPlayerSilentAim(state)
    UserWantsPlayer = state
    SilentAimPlayers = state
    
    if state then
        StartRender()
    elseif not SilentAimNPCs then
        StopRender()
    end
end

function SilentAimModule:SetNPCSilentAim(state)
    UserWantsNPC = state
    SilentAimNPCs = state
    
    if state then
        StartRender()
    elseif not SilentAimPlayers then
        StopRender()
    end
end

function SilentAimModule:SetPrediction(state)
    PredictionEnabled = state
end

function SilentAimModule:SetPredictionAmount(num)
    if type(num) == "number" then
        PredictionAmount = num
    end
end

function SilentAimModule:SetHighlight(state)
    HighlightEnabled = state
    if not state then ClearHighlight() end
end

function SilentAimModule:SetAutoKen(state)
    AutoKen = state
    if state then StartAutoKen() end
end

function SilentAimModule:SetZSkillOrM1(state)
    ZSkillOrM1 = state
end

function SilentAimModule:Pause()
    SilentAimPlayers = false
    SilentAimNPCs = false
end

function SilentAimModule:Restore()
    SilentAimPlayers = UserWantsPlayer
    SilentAimNPCs = UserWantsNPC
end

function SilentAimModule:IsPlayerAimEnabled()
    return SilentAimPlayers
end

function SilentAimModule:IsNPCAimEnabled()
    return SilentAimNPCs
end

function SilentAimModule:SetDistanceLimit(num)
    if type(num) == "number" then
        MaxRange = num
    end
end

return SilentAimModule
