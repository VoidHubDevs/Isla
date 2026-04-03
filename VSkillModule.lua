--[[
    V Skill Module - Optimized v2.0
    Dough V, Shark Anchor Z, Cursed Dual Katana Z
--]]

local VSkillModule = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- State
local VSkillsEnabled = false
local SharkZActive = false
local VActive = false
local CursedZActive = false
local RightTouchActive = false

-- Runtime Data
local CurrentTool = nil
local LastToolName = nil
local CharacterConnections = {}
local DamageConnection = nil
local SilentAimRef = nil

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

-- Silent Aim Control
local function DisableSilentAim()
    if SilentAimRef then
        SilentAimRef:Pause()
    end
end

local function EnableSilentAim()
    if SilentAimRef then
        SilentAimRef:Restore()
    end
end

-- Check if skill is active
local function IsSkillActive()
    return (CurrentTool and CurrentTool.Name == "Shark Anchor" and SharkZActive)
        or (LastToolName == "Dough-Dough" and VActive)
        or (CurrentTool and CurrentTool.Name == "Cursed Dual Katana" and CursedZActive)
end

-- Tool Hook
local function HookTool(tool)
    if not tool then return end
    CurrentTool = tool
    LastToolName = tool.Name
    
    table.insert(CharacterConnections, tool.AncestryChanged:Connect(function(_, parent)
        if not parent then
            CurrentTool = nil
            LastToolName = nil
            SharkZActive, VActive, CursedZActive = false, false, false
            RightTouchActive = false
            EnableSilentAim()
        end
    end))
end

-- Touch Input
UserInputService.TouchStarted:Connect(function(touch)
    if not camera or not touch.Position then return end
    
    if touch.Position.X > camera.ViewportSize.X / 2 then
        RightTouchActive = true
        
        if IsSkillActive() then
            DisableSilentAim()
        end
    end
end)

UserInputService.TouchEnded:Connect(function(touch)
    if not camera or not touch.Position then return end
    
    if touch.Position.X > camera.ViewportSize.X / 2 then
        RightTouchActive = false
        EnableSilentAim()
        SharkZActive, VActive, CursedZActive = false, false, false
    end
end)

-- Watch Damage Counter
local function WatchDamageCounter()
    if DamageConnection then
        SafeCall(function() DamageConnection:Disconnect() end)
        DamageConnection = nil
    end
    
    task.spawn(function()
        while true do
            local gui = SafeCall(function()
                return player:FindFirstChild("PlayerGui"):FindFirstChild("Main")
            end)
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
            
            DamageConnection = dmgTextLabel:GetPropertyChangedSignal("Text"):Connect(function()
                local dmgText = tonumber(dmgTextLabel.Text) or 0
                if dmgText > 0 and IsSkillActive() and RightTouchActive then
                    DisableSilentAim()
                elseif not RightTouchActive then
                    EnableSilentAim()
                end
            end)
            
            table.insert(CharacterConnections, DamageConnection)
            break
        end
    end)
end

-- Skill Detection Hook
if not getgenv().VoidHub_VSkillHooked then
    getgenv().VoidHub_VSkillHooked = true
    
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if method == "InvokeServer" or method == "FireServer" then
            local a1 = args[1]
            
            if typeof(a1) == "string" then
                local upperA1 = a1:upper()
                
                if upperA1 == "Z" then
                    if CurrentTool and CurrentTool.Name == "Shark Anchor" then
                        SharkZActive = true
                    elseif CurrentTool and CurrentTool.Name == "Cursed Dual Katana" then
                        CursedZActive = true
                    end
                elseif upperA1 == "V" then
                    if LastToolName == "Dough-Dough" then
                        VActive = true
                    end
                end
            end
        end
        
        return oldNamecall(self, ...)
    end)
end

-- Character Handler
local function OnCharacterAdded(char)
    ClearConnections()
    SharkZActive, VActive, CursedZActive = false, false, false
    RightTouchActive = false
    EnableSilentAim()
    
    table.insert(CharacterConnections, char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            HookTool(child)
        end
    end))
    
    table.insert(CharacterConnections, char.ChildRemoved:Connect(function(child)
        if child == CurrentTool and LastToolName then
            CurrentTool = nil
            LastToolName = nil
            SharkZActive, VActive, CursedZActive = false, false, false
            RightTouchActive = false
            EnableSilentAim()
        end
    end))
    
    WatchDamageCounter()
end

player.CharacterAdded:Connect(OnCharacterAdded)
if player.Character then OnCharacterAdded(player.Character) end

-- API
function VSkillModule:SetVSkills(state)
    VSkillsEnabled = state
    if not state then
        EnableSilentAim()
        SharkZActive, VActive, CursedZActive = false, false, false
    end
end

function VSkillModule:SetSilentAimRef(ref)
    SilentAimRef = ref
end

return VSkillModule
