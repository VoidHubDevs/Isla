--[[
    Aimbot Module - Optimized v2.0
    Smooth aiming, efficient targeting
--]]

local AimbotModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- State
local AimlockPlayer = false
local AimlockNPC = false
local PredictionEnabled = false
local PredictionAmount = 0.135
local MaxRange = 500

-- Runtime Data
local RenderConnection = nil
local CurrentHighlight = nil
local CachedEnemy = nil
local CachedNPC = nil
local LastUpdate = 0
local UpdateInterval = 0.1

-- Utility
local function SafeCall(func, ...)
    local success, result = pcall(func, ...)
    return success and result or nil
end

local function GetHRP(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid(char)
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function IsAlive(char)
    local hum = GetHumanoid(char)
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

local function GetNearestEnemy()
    local myChar = player.Character
    local myHRP = GetHRP(myChar)
    if not myHRP then return nil end
    
    local nearest, shortest = nil, MaxRange
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and IsEnemy(plr) then
            local char = plr.Character
            local hrp = GetHRP(char)
            
            if hrp and IsAlive(char) then
                local dist = (hrp.Position - myHRP.Position).Magnitude
                if dist < shortest then
                    shortest = dist
                    nearest = hrp
                end
            end
        end
    end
    
    return nearest
end

local function GetNearestNPC()
    local myChar = player.Character
    local myHRP = GetHRP(myChar)
    if not myHRP then return nil end
    
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return nil end
    
    local nearest, shortest = nil, MaxRange
    
    for _, npc in pairs(enemiesFolder:GetChildren()) do
        if npc:IsA("Model") then
            local hrp = GetHRP(npc)
            
            if hrp and IsAlive(npc) then
                local dist = (hrp.Position - myHRP.Position).Magnitude
                if dist < shortest then
                    shortest = dist
                    nearest = hrp
                end
            end
        end
    end
    
    return nearest
end

local function ClearHighlight()
    if CurrentHighlight then
        SafeCall(function() CurrentHighlight:Destroy() end)
        CurrentHighlight = nil
    end
end

local function SetHighlight(targetModel)
    ClearHighlight()
    
    if not targetModel or not IsAlive(targetModel) then
        return
    end
    
    SafeCall(function()
        local highlight = Instance.new("Highlight")
        highlight.FillColor = Color3.fromRGB(255, 255, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.Adornee = targetModel
        highlight.Parent = targetModel
        CurrentHighlight = highlight
    end)
end

local function UpdateTargets()
    local now = tick()
    if now - LastUpdate < UpdateInterval then return end
    LastUpdate = now
    
    if AimlockPlayer then
        if not CachedEnemy or not CachedEnemy.Parent or not IsAlive(CachedEnemy.Parent) then
            CachedEnemy = GetNearestEnemy()
        end
    else
        CachedEnemy = nil
    end
    
    if AimlockNPC then
        if not CachedNPC or not CachedNPC.Parent or not IsAlive(CachedNPC.Parent) then
            CachedNPC = GetNearestNPC()
        end
    else
        CachedNPC = nil
    end
    
    local target = CachedEnemy and CachedEnemy.Parent or CachedNPC and CachedNPC.Parent
    if target then
        SetHighlight(target)
    else
        ClearHighlight()
    end
end

local function AimAt(targetHRP)
    if not targetHRP then return end
    
    local camPos = camera.CFrame.Position
    local targetPos = targetHRP.Position
    
    if PredictionEnabled then
        local velocity = targetHRP.Velocity
        if velocity.Magnitude > 3 then
            targetPos = targetPos + (velocity * PredictionAmount)
        end
    end
    
    local dist = (targetPos - camPos).Magnitude
    local yOffset = math.clamp(dist / 40, 0, 0.06)
    
    local lookVector = (targetPos - camPos).Unit
    local tiltedLook = Vector3.new(lookVector.X, lookVector.Y - yOffset, lookVector.Z).Unit
    
    camera.CFrame = CFrame.new(camPos, camPos + tiltedLook)
end

local function StartRender()
    if RenderConnection then return end
    
    RenderConnection = RunService.RenderStepped:Connect(function()
        if not AimlockPlayer and not AimlockNPC then
            RenderConnection:Disconnect()
            RenderConnection = nil
            ClearHighlight()
            return
        end
        
        UpdateTargets()
        
        local target = CachedEnemy or CachedNPC
        if target then
            AimAt(target)
        end
    end)
end

-- API
function AimbotModule:SetPlayerAimlock(state)
    AimlockPlayer = state
    
    if state then
        CachedEnemy = GetNearestEnemy()
        if CachedEnemy then
            SetHighlight(CachedEnemy.Parent)
        end
        StartRender()
    else
        CachedEnemy = nil
        if not AimlockNPC then
            ClearHighlight()
        end
    end
end

function AimbotModule:SetNpcAimlock(state)
    AimlockNPC = state
    
    if state then
        CachedNPC = GetNearestNPC()
        if CachedNPC then
            SetHighlight(CachedNPC.Parent)
        end
        StartRender()
    else
        CachedNPC = nil
        if not AimlockPlayer then
            ClearHighlight()
        end
    end
end

function AimbotModule:SetPrediction(state)
    PredictionEnabled = state
end

function AimbotModule:SetPredictionTime(num)
    if type(num) == "number" then
        PredictionAmount = num
    end
end

function AimbotModule:SetMaxRange(num)
    if type(num) == "number" then
        MaxRange = num
    end
end

return AimbotModule
