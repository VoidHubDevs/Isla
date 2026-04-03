--[[
    Z Skill Module - Optimized v2.0
    Godhuman Z Skill Auto-Aim
--]]

local ZSkillModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- State
local ZSkillsEnabled = false
local TargetInfoEnabled = false
local GodhumanZActive = false
local AimlockActive = false

-- Runtime Data
local CurrentTool = nil
local CharacterConnections = {}
local AimConnection = nil
local AimTimeout = nil
local UIConnection = nil
local DamageConnection = nil
local NearestTarget = nil

-- UI
local TargetGui = nil
local TargetFrame = nil
local TargetName = nil
local HPFill = nil

-- Utility
local function SafeCall(func, ...)
    local success, result = pcall(func, ...)
    return success and result or nil
end

local function ClearConnections()
    for _, conn in ipairs(CharacterConnections) do
        SafeCall(function() conn:Disconnect() end)
    end
    CharacterConnections = {}
    
    if DamageConnection then
        SafeCall(function() DamageConnection:Disconnect() end)
        DamageConnection = nil
    end
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

local function GetNearestTarget(maxDistance)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    local closest, closestDist = nil, maxDistance or 1000
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and IsEnemy(plr) then
            local pChar = plr.Character
            local pHRP = pChar and pChar:FindFirstChild("HumanoidRootPart")
            local hum = pChar and pChar:FindFirstChildOfClass("Humanoid")
            
            if pHRP and hum and hum.Health > 0 then
                local dist = (pHRP.Position - hrp.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = pChar
                end
            end
        end
    end
    
    return closest
end

local function StopAimlock()
    if not AimlockActive then return end
    
    AimlockActive = false
    NearestTarget = nil
    GodhumanZActive = false
    
    if AimConnection then
        SafeCall(function() AimConnection:Disconnect() end)
        AimConnection = nil
    end
    
    if AimTimeout then
        SafeCall(function() task.cancel(AimTimeout) end)
        AimTimeout = nil
    end
end

local function StartAimlock()
    if not ZSkillsEnabled or AimlockActive then return end
    
    NearestTarget = GetNearestTarget(1000)
    if not NearestTarget then return end
    
    AimlockActive = true
    
    AimConnection = RunService.RenderStepped:Connect(function()
        if not ZSkillsEnabled then
            StopAimlock()
            return
        end
        
        if AimlockActive and NearestTarget and NearestTarget:FindFirstChild("HumanoidRootPart") then
            camera.CFrame = CFrame.lookAt(camera.CFrame.Position, NearestTarget.HumanoidRootPart.Position)
        else
            StopAimlock()
        end
    end)
    
    AimTimeout = task.delay(1, function()
        if AimlockActive then
            StopAimlock()
        end
    end)
end

local function WatchDamageCounter()
    if DamageConnection then
        SafeCall(function() DamageConnection:Disconnect() end)
        DamageConnection = nil
    end
    
    local gui = SafeCall(function()
        return player:WaitForChild("PlayerGui"):WaitForChild("Main", 5)
    end)
    if not gui then return end
    
    local dmgCounter = gui:FindFirstChild("DmgCounter")
    if not dmgCounter then
        table.insert(CharacterConnections, gui.ChildAdded:Connect(function(child)
            if child.Name == "DmgCounter" then
                task.wait()
                WatchDamageCounter()
            end
        end))
        return
    end
    
    local dmgTextLabel = dmgCounter:FindFirstChild("Text")
    if not dmgTextLabel then
        table.insert(CharacterConnections, dmgCounter.ChildAdded:Connect(function(child)
            if child.Name == "Text" then
                task.wait()
                WatchDamageCounter()
            end
        end))
        return
    end
    
    DamageConnection = dmgTextLabel:GetPropertyChangedSignal("Text"):Connect(function()
        if not ZSkillsEnabled then return end
        local dmgText = tonumber(dmgTextLabel.Text) or 0
        if dmgText > 0 and AimlockActive then
            StopAimlock()
        end
    end)
end

local function CreateTargetUI()
    if TargetGui then return end
    
    TargetGui = Instance.new("ScreenGui")
    TargetGui.Name = "VoidHub_TargetUI"
    TargetGui.ResetOnSpawn = false
    TargetGui.Parent = player:WaitForChild("PlayerGui")
    
    TargetFrame = Instance.new("Frame")
    TargetFrame.Name = "TargetFrame"
    TargetFrame.Size = UDim2.new(0.25, 0, 0.08, 0)
    TargetFrame.Position = UDim2.new(0.5, 0, 0.05, 0)
    TargetFrame.AnchorPoint = Vector2.new(0.5, 0)
    TargetFrame.BackgroundTransparency = 1
    TargetFrame.Visible = false
    TargetFrame.Parent = TargetGui
    
    TargetName = Instance.new("TextLabel")
    TargetName.Name = "TargetName"
    TargetName.Size = UDim2.new(1, 0, 0.5, 0)
    TargetName.BackgroundTransparency = 1
    TargetName.TextScaled = true
    TargetName.Font = Enum.Font.GothamBold
    TargetName.TextColor3 = Color3.new(1, 1, 1)
    TargetName.Parent = TargetFrame
    
    local hpBg = Instance.new("Frame")
    hpBg.Name = "HP_BG"
    hpBg.Size = UDim2.new(1, 0, 0.35, 0)
    hpBg.Position = UDim2.new(0, 0, 0.55, 0)
    hpBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    hpBg.BorderSizePixel = 0
    hpBg.Parent = TargetFrame
    
    HPFill = Instance.new("Frame")
    HPFill.Name = "HP_Fill"
    HPFill.Size = UDim2.new(1, 0, 1, 0)
    HPFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    HPFill.BorderSizePixel = 0
    HPFill.Parent = hpBg
end

local function HookTool(tool)
    if not tool then return end
    CurrentTool = tool
    
    table.insert(CharacterConnections, tool.AncestryChanged:Connect(function(_, parent)
        if not parent then
            CurrentTool = nil
            GodhumanZActive = false
            StopAimlock()
        end
    end))
end

UserInputService.TouchEnded:Connect(function(touch)
    if not ZSkillsEnabled then return end
    if not camera or not touch.Position then return end
    
    if touch.Position.X > camera.ViewportSize.X / 2 then
        if CurrentTool and CurrentTool.Name == "Godhuman" and GodhumanZActive then
            if not AimlockActive then
                StartAimlock()
            end
        end
    end
end)

if not getgenv().VoidHub_ZSkillHooked then
    getgenv().VoidHub_ZSkillHooked = true
    
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if method == "InvokeServer" or method == "FireServer" then
            local a1 = args[1]
            if typeof(a1) == "string" and a1:upper() == "Z" then
                if CurrentTool and CurrentTool.Name == "Godhuman" then
                    GodhumanZActive = true
                end
            end
        end
        
        return oldNamecall(self, ...)
    end)
end

local function OnCharacterAdded(char)
    ClearConnections()
    GodhumanZActive = false
    StopAimlock()
    
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") then
            HookTool(child)
        end
    end
    
    table.insert(CharacterConnections, char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            HookTool(child)
        end
    end))
    
    table.insert(CharacterConnections, char.ChildRemoved:Connect(function(child)
        if child == CurrentTool then
            CurrentTool = nil
            GodhumanZActive = false
            StopAimlock()
        end
    end))
    
    WatchDamageCounter()
end

player.CharacterAdded:Connect(OnCharacterAdded)
if player.Character then OnCharacterAdded(player.Character) end

-- API
function ZSkillModule:SetZSkills(state)
    ZSkillsEnabled = state
    if not state then
        StopAimlock()
        ClearConnections()
    end
end

function ZSkillModule:SetInfo(state)
    TargetInfoEnabled = state
    CreateTargetUI()
    
    if state then
        if UIConnection then return end
        
        UIConnection = RunService.RenderStepped:Connect(function()
            local target = GetNearestTarget(1000)
            
            if target and target:FindFirstChild("Humanoid") then
                local hp = target.Humanoid
                TargetName.Text = target.Name
                local fill = math.clamp(hp.Health / hp.MaxHealth, 0, 1)
                HPFill.Size = UDim2.new(fill, 0, 1, 0)
                TargetFrame.Visible = true
            else
                TargetName.Text = "No target available"
                TargetFrame.Visible = true
            end
        end)
    else
        if UIConnection then
            UIConnection:Disconnect()
            UIConnection = nil
        end
        if TargetFrame then
            TargetFrame.Visible = false
        end
    end
end

return ZSkillModule
