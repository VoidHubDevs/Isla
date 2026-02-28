local ESPModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- State
local BunnyHopEnabled = false
local DodgeEnabled = false
local ESPEnabled = false
local BusoEnabled = false
local AntiAfkEnabled = false

local dodgeLoop = nil
local renderConnection = nil
local espFolder = nil
local ESPs = {}

-- Colors
local Colors = {
    Pirates = Color3.fromRGB(220, 20, 60),
    Marines = Color3.fromRGB(0, 0, 128),
    Ally = Color3.fromRGB(0, 255, 127),
    Neutral = Color3.fromRGB(255, 255, 255),
    HP_Green = Color3.fromRGB(0, 255, 100),
    HP_Yellow = Color3.fromRGB(255, 200, 0),
    HP_Red = Color3.fromRGB(255, 50, 50)
}

-- Utils
local function getFolder()
    if espFolder and espFolder.Parent then return espFolder end
    espFolder = CoreGui:FindFirstChild("CleanESP") or Instance.new("Folder")
    espFolder.Name = "CleanESP"
    espFolder.Parent = CoreGui
    return espFolder
end

local function isAlly(target)
    local success, result = pcall(function()
        local gui = player:FindFirstChild("PlayerGui")
        if not gui then return false end
        local scroll = gui:FindFirstChild("Main") and gui.Main:FindFirstChild("Allies") and gui.Main.Allies:FindFirstChild("Container") and gui.Main.Allies.Container:FindFirstChild("Allies") and gui.Main.Allies.Container.Allies:FindFirstChild("ScrollingFrame")
        if not scroll then return false end
        for _, v in pairs(scroll:GetDescendants()) do
            if v:IsA("ImageButton") and v.Name == target.Name then return true end
        end
        return false
    end)
    return success and result
end

local function getColor(target)
    if target == player then return Colors.Ally end
    local myTeam, theirTeam = player.Team, target.Team
    if not myTeam or not theirTeam then return Colors.Neutral end
    local myName, theirName = myTeam.Name, theirTeam.Name
    
    if myName == theirName then
        if myName == "Pirates" then return isAlly(target) and Colors.Ally or Colors.Pirates
        elseif myName == "Marines" then return Colors.Marines end
    end
    if (myName == "Pirates" and theirName == "Marines") or (myName == "Marines" and theirName == "Pirates") then
        return myName == "Pirates" and Colors.Marines or Colors.Pirates
    end
    return Colors.Neutral
end

local function getHPColor(percent)
    if percent > 0.6 then return Colors.HP_Green
    elseif percent > 0.3 then return Colors.HP_Yellow
    else return Colors.HP_Red end
end

-- ESP Creation
local function createESP(target)
    if ESPs[target] then return end
    local char = target.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    
    local folder = getFolder()
    local billboard = Instance.new("BillboardGui")
    billboard.Name = target.Name
    billboard.Adornee = head
    billboard.Size = UDim2.fromOffset(180, 55)
    billboard.StudsOffset = Vector3.new(0, 2.4, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = folder
    
    -- Name
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
    
    -- Level & Distance
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
    
    -- Health Bar Background
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
    
    -- Health Bar Fill
    local hpFill = Instance.new("Frame")
    hpFill.Name = "HP_Fill"
    hpFill.Size = UDim2.new(1, 0, 1, 0)
    hpFill.BackgroundColor3 = Colors.HP_Green
    hpFill.BorderSizePixel = 0
    hpFill.Parent = hpBg
    
    local corner2 = Instance.new("UICorner")
    corner2.CornerRadius = UDim.new(0, 2)
    corner2.Parent = hpFill
    
    -- HP Text
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
    
    ESPs[target] = {
        Billboard = billboard,
        Name = nameLabel,
        Info = infoLabel,
        HP_Fill = hpFill,
        HP_Text = hpText,
        LastHP = 1
    }
end

local function removeESP(target)
    if ESPs[target] then
        pcall(function() ESPs[target].Billboard:Destroy() end)
        ESPs[target] = nil
    end
end

-- Render
local function startRender()
    if renderConnection then return end
    
    renderConnection = RunService.Heartbeat:Connect(function()
        if not ESPEnabled then
            for _, v in pairs(ESPs) do
                if v.Billboard then v.Billboard.Enabled = false end
            end
            return
        end
        
        local myChar = player.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        
        for _, target in pairs(Players:GetPlayers()) do
            if target == player then continue end
            
            if not ESPs[target] then createESP(target) end
            local esp = ESPs[target]
            if not esp then continue end
            
            local char = target.Character
            local head = char and char:FindFirstChild("Head")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            
            if char and head and hrp and humanoid and myHRP then
                esp.Billboard.Enabled = true
                esp.Billboard.Adornee = head
                
                local color = getColor(target)
                esp.Name.TextColor3 = color
                
                local dist = math.floor((myHRP.Position - hrp.Position).Magnitude)
                local hpPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                local hp = math.floor(hpPercent * 100)
                
                local level = "???"
                pcall(function()
                    local data = target:FindFirstChild("Data")
                    local lv = data and data:FindFirstChild("Level")
                    if lv then level = tostring(lv.Value) end
                end)
                
                esp.Info.Text = string.format("Lv. %s | %dm", level, dist)
                
                -- Animated Health Bar
                local targetSize = UDim2.new(hpPercent, 0, 1, 0)
                esp.HP_Fill:TweenSize(targetSize, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
                esp.HP_Fill.BackgroundColor3 = getHPColor(hpPercent)
                esp.HP_Text.Text = hp .. "%"
                esp.HP_Text.TextColor3 = getHPColor(hpPercent)
                
                esp.LastHP = hpPercent
            else
                esp.Billboard.Enabled = false
            end
        end
    end)
end

local function stopRender()
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end
end

-- Features
local function startDodge()
    if dodgeLoop then return end
    dodgeLoop = task.spawn(function()
        while DodgeEnabled do
            task.wait()
            pcall(function()
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
        end
        dodgeLoop = nil
    end)
end

local function stopDodge()
    DodgeEnabled = false
end

-- Hook
if not getgenv().ESPHooked then
    getgenv().ESPHooked = true
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
                            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
                        end)
                    end
                end
            end
        end
        return oldNamecall(self, ...)
    end)
end

-- Anti AFK
local function setupAntiAfk()
    player.Idled:Connect(function()
        if not AntiAfkEnabled then return end
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            local x = workspace.CurrentCamera.ViewportSize.X / 2
            local y = workspace.CurrentCamera.ViewportSize.Y / 2
            vim:SendMouseButtonEvent(x, y, 0, true, game, 1)
            task.wait(0.05)
            vim:SendMouseButtonEvent(x, y, 0, false, game, 1)
        end)
    end)
end

-- API
function ESPModule:SetBunnyhop(state)
    BunnyHopEnabled = state
end

function ESPModule:SetNoDodgeCD(state)
    DodgeEnabled = state
    if state then startDodge() else stopDodge() end
end

function ESPModule:SetAntiAfk(state)
    AntiAfkEnabled = state
    if state then setupAntiAfk() end
end

function ESPModule:SetBuso(state)
    BusoEnabled = state
    if state then
        pcall(function()
            if not player.Character:FindFirstChild("HasBuso") then
                ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
            end
        end)
    end
end

function ESPModule:SetESP(state)
    ESPEnabled = state
    if state then startRender() else stopRender() end
end

-- Cleanup
Players.PlayerRemoving:Connect(function(plr)
    removeESP(plr)
end)

return ESPModule
