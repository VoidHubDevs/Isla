local ESPModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local V3Enabled = false
local BunnyHopEnabled = false
local DodgeEnabled = false
local ESPEnabled = false
local BusoEnabled = false
local AntiAfkEnabled = false
local v3LoopRunning = false

local NoDodgeCoroutine = nil
local v3Loop = nil
local espFolder = nil
local ESPs = {}
local renderConnection = nil

local function getESPFolder()
    if espFolder and espFolder.Parent then return espFolder end
    
    local coreGui = game:GetService("CoreGui")
    espFolder = coreGui:FindFirstChild("GlobalESP")
    
    if not espFolder then
        espFolder = Instance.new("Folder")
        espFolder.Name = "GlobalESP"
        espFolder.Parent = coreGui
    end
    
    return espFolder
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

local function getESPColor(targetPlayer)
    if targetPlayer == player then
        return Color3.fromRGB(0, 255, 0)
    elseif isAllyWithMe(targetPlayer) then
        return Color3.fromRGB(0, 255, 0)
    elseif isEnemy(targetPlayer) then
        return Color3.fromRGB(255, 255, 0)
    else
        return Color3.fromRGB(0, 255, 0)
    end
end

local function createESP(targetPlayer)
    if ESPs[targetPlayer] then return end
    
    local char = targetPlayer.Character
    if not char then return end
    
    local head = char:FindFirstChild("Head")
    if not head then return end
    
    local folder = getESPFolder()
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = targetPlayer.Name .. "_ESP"
    billboard.Adornee = head
    billboard.Size = UDim2.fromOffset(220, 50)
    billboard.AlwaysOnTop = true
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Parent = folder
    
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "LevelLabel"
    levelLabel.Size = UDim2.new(1, 0, 0.5, 0)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = "Lv. ???"
    levelLabel.TextColor3 = Color3.fromRGB(0, 170, 255)
    levelLabel.TextStrokeTransparency = 0.2
    levelLabel.Font = Enum.Font.SourceSansBold
    levelLabel.TextSize = 14
    levelLabel.TextXAlignment = Enum.TextXAlignment.Center
    levelLabel.Parent = billboard
    
    local mainLabel = Instance.new("TextLabel")
    mainLabel.Name = "MainLabel"
    mainLabel.Size = UDim2.new(1, 0, 0.5, 0)
    mainLabel.Position = UDim2.new(0, 0, 0.5, 0)
    mainLabel.BackgroundTransparency = 1
    mainLabel.Text = "[0] " .. targetPlayer.DisplayName .. " (0m)"
    mainLabel.TextColor3 = getESPColor(targetPlayer)
    mainLabel.TextStrokeTransparency = 0.2
    mainLabel.Font = Enum.Font.SourceSansBold
    mainLabel.TextSize = 16
    mainLabel.TextXAlignment = Enum.TextXAlignment.Center
    mainLabel.Parent = billboard
    
    ESPs[targetPlayer] = billboard
end

local function removeESP(targetPlayer)
    if ESPs[targetPlayer] then
        pcall(function() ESPs[targetPlayer]:Destroy() end)
        ESPs[targetPlayer] = nil
    end
end

local function startESPRender()
    if renderConnection then return end
    
    renderConnection = RunService.Heartbeat:Connect(function()
        if not ESPEnabled then
            for _, gui in pairs(ESPs) do
                if gui then gui.Enabled = false end
            end
            return
        end
        
        for _, targetPlayer in pairs(Players:GetPlayers()) do
            if targetPlayer == player then continue end
            
            if not ESPs[targetPlayer] then
                createESP(targetPlayer)
            end
            
            local gui = ESPs[targetPlayer]
            if not gui then continue end
            
            local char = targetPlayer.Character
            local head = char and char:FindFirstChild("Head")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            local myChar = player.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            
            if char and head and hrp and humanoid and myHRP then
                gui.Adornee = head
                gui.Enabled = true
                
                local dist = (myHRP.Position - hrp.Position).Magnitude
                local nameLabel = gui:FindFirstChild("MainLabel")
                local levelLabel = gui:FindFirstChild("LevelLabel")
                
                if levelLabel then
                    local dataFolder = targetPlayer:FindFirstChild("Data")
                    local levelValue = dataFolder and dataFolder:FindFirstChild("Level")
                    levelLabel.Text = levelValue and ("Lv. " .. levelValue.Value) or "Lv. ???"
                end
                
                if nameLabel then
                    nameLabel.Text = string.format("[%d] %s (%dm)", math.floor(humanoid.Health), targetPlayer.DisplayName, math.floor(dist))
                    nameLabel.TextColor3 = getESPColor(targetPlayer)
                end
            else
                gui.Enabled = false
            end
        end
    end)
end

local function stopESPRender()
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end
end

local function clickActivateAbility()
    pcall(function()
        local commE = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommE")
        commE:FireServer("ActivateAbility")
    end)
end

local function startV3Loop()
    if v3LoopRunning then return end
    v3LoopRunning = true
    
    v3Loop = task.spawn(function()
        while v3LoopRunning do
            if not player or not player.Parent then break end
            if V3Enabled then
                pcall(clickActivateAbility)
            end
            task.wait(31)
        end
        v3Loop = nil
    end)
end

local function stopV3Loop()
    v3LoopRunning = false
end

local function NoDodgeCool()
    if not DodgeEnabled then
        if NoDodgeCoroutine then
            task.cancel(NoDodgeCoroutine)
            NoDodgeCoroutine = nil
        end
        return
    end
    
    NoDodgeCoroutine = task.spawn(function()
        while DodgeEnabled do
            task.wait()
            pcall(function()
                for _, v in next, getgc() do
                    local char = player.Character
                    local dodge = char and char:FindFirstChild("Dodge")
                    if dodge and typeof(v) == "function" and getfenv(v).script == dodge then
                        for i2, v2 in next, getupvalues(v) do
                            if tostring(v2) == "0.4" then
                                setupvalue(v, i2, 0)
                            end
                        end
                    end
                end
            end)
        end
    end)
end

if not getgenv().ESPHooked then
    getgenv().ESPHooked = true
    
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if method == "FireServer" or method == "InvokeServer" then
            if type(args[1]) == "string" and args[1]:upper() == "DODGE" then
                if BunnyHopEnabled then
                    local char = player.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        task.defer(function()
                            pcall(function()
                                hum:ChangeState(Enum.HumanoidStateType.Jumping)
                            end)
                        end)
                    end
                end
            end
        end
        
        return oldNamecall(self, ...)
    end)
end

local function setupAntiAfk()
    if not AntiAfkEnabled then return end
    
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

function ESPModule:SetV3(state)
    V3Enabled = state
    if state then startV3Loop() else stopV3Loop() end
end

function ESPModule:SetBunnyhop(state)
    BunnyHopEnabled = state
end

function ESPModule:SetNoDodgeCD(state)
    DodgeEnabled = state
    NoDodgeCool()
end

function ESPModule:SetAntiAfk(state)
    AntiAfkEnabled = state
    if state then setupAntiAfk() end
end

function ESPModule:SetBuso(state)
    BusoEnabled = state
    if state then
        pcall(function()
            local commF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
            if not player.Character:FindFirstChild("HasBuso") then
                commF:InvokeServer("Buso")
            end
        end)
    end
end

function ESPModule:SetESP(state)
    ESPEnabled = state
    if state then
        startESPRender()
    else
        stopESPRender()
        for _, esp in pairs(ESPs) do
            if esp then esp.Enabled = false end
        end
    end
end

Players.PlayerRemoving:Connect(function(plr)
    removeESP(plr)
end)

return ESPModule
