--[[
    ESP Module - Optimized v2.0
    Minimal lag, efficient rendering
--]]

local ESPModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer

-- State
local V3Enabled = false
local BunnyHopEnabled = false
local DodgeEnabled = false
local ESPEnabled = false
local BusoEnabled = false
local AntiAfkEnabled = false

-- ESP Storage
local ESPFolder = nil
local ESPObjects = {}
local RenderConnection = nil
local V3Connection = nil
local DodgeConnection = nil

-- Colors
local Colors = {
    Pirates = Color3.fromRGB(220, 20, 60),
    Marines = Color3.fromRGB(0, 100, 255),
    Ally = Color3.fromRGB(0, 255, 127),
    Neutral = Color3.fromRGB(255, 255, 255),
    HP_Green = Color3.fromRGB(0, 255, 100),
    HP_Yellow = Color3.fromRGB(255, 200, 0),
    HP_Red = Color3.fromRGB(255, 50, 50),
}

-- Utility
local function SafeCall(func, ...)
    local success, result = pcall(func, ...)
    return success and result or nil
end

local function GetESPFolder()
    if ESPFolder and ESPFolder.Parent then return ESPFolder end
    ESPFolder = CoreGui:FindFirstChild("VoidHub_ESP") or Instance.new("Folder")
    ESPFolder.Name = "VoidHub_ESP"
    ESPFolder.Parent = CoreGui
    return ESPFolder
end

local function IsAlly(target)
    return SafeCall(function()
        local gui = player:FindFirstChild("PlayerGui")
        if not gui then return false end
        local main = gui:FindFirstChild("Main")
        if not main then return false end
        local allies = main:FindFirstChild("Allies")
        if not allies then return false end
        local container = allies:FindFirstChild("Container")
        if not container then return false end
        local alliesFolder = container:FindFirstChild("Allies")
        if not alliesFolder then return false end
        local scroll = alliesFolder:FindFirstChild("ScrollingFrame")
        if not scroll then return false end
        for _, v in pairs(scroll:GetDescendants()) do
            if v:IsA("ImageButton") and v.Name == target.Name then return true end
        end
        return false
    end) or false
end

local function GetTeamColor(target)
    if target == player then return Colors.Ally end
    local myTeam, theirTeam = player.Team, target.Team
    if not myTeam or not theirTeam then return Colors.Neutral end
    local myName, theirName = myTeam.Name, theirTeam.Name
    if myName == theirName then
        if myName == "Pirates" then return IsAlly(target) and Colors.Ally or Colors.Pirates
        elseif myName == "Marines" then return Colors.Marines end
    end
    if (myName == "Pirates" and theirName == "Marines") or (myName == "Marines" and theirName == "Pirates") then
        return myName == "Pirates" and Colors.Marines or Colors.Pirates
    end
    return Colors.Neutral
end

local function GetHPColor(percent)
    if percent > 0.6 then return Colors.HP_Green
    elseif percent > 0.3 then return Colors.HP_Yellow
    else return Colors.HP_Red end
end

-- Create ESP
local function CreateESP(target)
    if ESPObjects[target] then return end
    if target == player then return end
    local char = target.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    
    local folder = GetESPFolder()
    local billboard = Instance.new("BillboardGui")
    billboard.Name = target.Name .. "_ESP"
    billboard.Adornee = head
    billboard.Size = UDim2.fromOffset(180, 55)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = folder
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(1, 0, 0, 16)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Text = target.DisplayName
    nameLabel.Parent = billboard
    
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Name = "Info"
    infoLabel.Size = UDim2.new(1, 0, 0, 12)
    infoLabel.Position = UDim2.new(0, 0, 0, 16)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 11
    infoLabel.TextStrokeTransparency = 0.1
    infoLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    infoLabel.Text = "Lv. ??? | 0m"
    infoLabel.Parent = billboard
    
    local hpBg = Instance.new("Frame")
    hpBg.Name = "HP_BG"
    hpBg.Size = UDim2.new(1, -20, 0, 4)
    hpBg.Position = UDim2.new(0, 10, 0, 30)
    hpBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    hpBg.BorderSizePixel = 0
    hpBg.Parent = billboard
    
    local corner1 = Instance.new("UICorner")
    corner1.CornerRadius = UDim.new(0, 2)
    corner1.Parent = hpBg
    
    local hpFill = Instance.new("Frame")
    hpFill.Name = "HP_Fill"
    hpFill.Size = UDim2.new(1, 0, 1, 0)
    hpFill.BackgroundColor3 = Colors.HP_Green
    hpFill.BorderSizePixel = 0
    hpFill.Parent = hpBg
    
    local corner2 = Instance.new("UICorner")
    corner2.CornerRadius = UDim.new(0, 2)
    corner2.Parent = hpFill
    
    local hpText = Instance.new("TextLabel")
    hpText.Name = "HP_Text"
    hpText.Size = UDim2.new(1, 0, 0, 12)
    hpText.Position = UDim2.new(0, 0, 0, 34)
    hpText.BackgroundTransparency = 1
    hpText.Font = Enum.Font.GothamBold
    hpText.TextSize = 10
    hpText.TextStrokeTransparency = 0
    hpText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    hpText.Text = "100%"
    hpText.Parent = billboard
    
    ESPObjects[target] = {
        Billboard = billboard,
        Name = nameLabel,
        Info = infoLabel,
        HP_Fill = hpFill,
        HP_Text = hpText,
        LastUpdate = tick(),
    }
end

local function RemoveESP(target)
    local esp = ESPObjects[target]
    if esp then
        SafeCall(function() esp.Billboard:Destroy() end)
        ESPObjects[target] = nil
    end
end

local function UpdateESP(target)
    local esp = ESPObjects[target]
    if not esp then return end
    
    local char = target.Character
    local head = char and char:FindFirstChild("Head")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    
    if not char or not head or not hrp or not humanoid then
        esp.Billboard.Enabled = false
        return
    end
    
    esp.Billboard.Enabled = true
    esp.Billboard.Adornee = head
    
    local color = GetTeamColor(target)
    esp.Name.TextColor3 = color
    
    local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local dist = myHRP and math.floor((myHRP.Position - hrp.Position).Magnitude) or 0
    
    local level = "???"
    SafeCall(function()
        local data = target:FindFirstChild("Data")
        local lv = data and data:FindFirstChild("Level")
        if lv then level = tostring(lv.Value) end
    end)
    
    esp.Info.Text = string.format("Lv. %s | %dm", level, dist)
    
    local hpPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
    local hp = math.floor(hpPercent * 100)
    
    esp.HP_Fill.Size = UDim2.new(hpPercent, 0, 1, 0)
    esp.HP_Fill.BackgroundColor3 = GetHPColor(hpPercent)
    esp.HP_Text.Text = hp .. "%"
    esp.HP_Text.TextColor3 = GetHPColor(hpPercent)
    
    esp.LastUpdate = tick()
end

-- Render Loop (30 FPS cap)
local LastRender = 0
local RenderInterval = 1/30

local function StartRender()
    if RenderConnection then return end
    
    RenderConnection = RunService.Heartbeat:Connect(function()
        if not ESPEnabled then
            for _, esp in pairs(ESPObjects) do
                if esp.Billboard then esp.Billboard.Enabled = false end
            end
            return
        end
        
        local now = tick()
        if now - LastRender < RenderInterval then return end
        LastRender = now
        
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= player and not ESPObjects[plr] then
                CreateESP(plr)
            end
        end
        
        for plr, _ in pairs(ESPObjects) do
            if plr.Parent then
                UpdateESP(plr)
            else
                RemoveESP(plr)
            end
        end
    end)
end

local function StopRender()
    if RenderConnection then
        RenderConnection:Disconnect()
        RenderConnection = nil
    end
end

-- V3 System
local function StartV3()
    if V3Connection then return end
    V3Connection = task.spawn(function()
        while V3Enabled do
            SafeCall(function()
                ReplicatedStorage.Remotes.CommE:FireServer("ActivateAbility")
            end)
            task.wait(31)
        end
        V3Connection = nil
    end)
end

local function StopV3()
    V3Enabled = false
end

-- Dodge System
local function StartDodge()
    if DodgeConnection then return end
    DodgeConnection = RunService.Heartbeat:Connect(function()
        if not DodgeEnabled then return end
        SafeCall(function()
            for _, v in next, getgc() do
                if typeof(v) == "function" then
                    local char = player.Character
                    local dodge = char and char:FindFirstChild("Dodge")
                    if dodge and getfenv(v).script == dodge then
                        for i, upv in next, getupvalues(v) do
                            if tostring(upv) == "0.4" then
                                setupvalue(v, i, 0)
                            end
                        end
                    end
                end
            end
        end)
    end)
end

local function StopDodge()
    DodgeEnabled = false
    if DodgeConnection then
        DodgeConnection:Disconnect()
        DodgeConnection = nil
    end
end

-- BunnyHop Hook
if not getgenv().VoidHub_BunnyHooked then
    getgenv().VoidHub_BunnyHooked = true
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if method == "FireServer" or method == "InvokeServer" then
            if type(args[1]) == "string" and args[1]:upper() == "DODGE" then
                if BunnyHopEnabled then
                    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                    if hum then
                        task.defer(function()
                            SafeCall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
                        end)
                    end
                end
            end
        end
        return oldNamecall(self, ...)
    end)
end

-- Anti AFK
if not getgenv().VoidHub_AntiAfkSetup then
    getgenv().VoidHub_AntiAfkSetup = true
    player.Idled:Connect(function()
        if not AntiAfkEnabled then return end
        SafeCall(function()
            local vim = game:GetService("VirtualInputManager")
            local x = camera.ViewportSize.X / 2
            local y = camera.ViewportSize.Y / 2
            vim:SendMouseButtonEvent(x, y, 0, true, game, 1)
            task.wait(0.05)
            vim:SendMouseButtonEvent(x, y, 0, false, game, 1)
        end)
    end)
end

Players.PlayerRemoving:Connect(function(plr)
    RemoveESP(plr)
end)

-- API
function ESPModule:SetESP(state)
    ESPEnabled = state
    if state then StartRender() else StopRender() end
end

function ESPModule:SetV3(state)
    V3Enabled = state
    if state then StartV3() else StopV3() end
end

function ESPModule:SetBunnyhop(state)
    BunnyHopEnabled = state
end

function ESPModule:SetNoDodgeCD(state)
    DodgeEnabled = state
    if state then StartDodge() else StopDodge() end
end

function ESPModule:SetAntiAfk(state)
    AntiAfkEnabled = state
end

function ESPModule:SetBuso(state)
    BusoEnabled = state
    if state then
        SafeCall(function()
            if not player.Character:FindFirstChild("HasBuso") then
                ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
            end
        end)
    end
end

return ESPModule
