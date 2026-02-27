local ModernESP = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- Configuration
local Config = {
    Colors = {
        Pirates = Color3.fromRGB(220, 20, 60),      -- Crimson Red
        Marines = Color3.fromRGB(0, 0, 128),        -- Navy Blue
        Ally = Color3.fromRGB(0, 255, 127),         -- Spring Green
        Self = Color3.fromRGB(0, 255, 255),         -- Cyan
        Neutral = Color3.fromRGB(255, 255, 255),    -- White
        Background = Color3.fromRGB(15, 15, 25),    -- Dark background
        HealthHigh = Color3.fromRGB(0, 255, 127),
        HealthMid = Color3.fromRGB(255, 215, 0),
        HealthLow = Color3.fromRGB(255, 69, 0)
    },
    
    Fonts = {
        Primary = Enum.Font.GothamBold,
        Numeric = Enum.Font.RobotoMono
    },
    
    Sizes = {
        Name = 14,
        Level = 12,
        Distance = 11,
        Health = 10
    }
}

-- State Management
local State = {
    V3Enabled = false,
    BunnyHopEnabled = false,
    NoDodgeEnabled = false,
    ESPEnabled = false,
    BusoEnabled = false,
    AntiAfkEnabled = false,
    
    V3Thread = nil,
    DodgeThread = nil,
    RenderConnection = nil,
    
    ESPInstances = {},
    ESPFolder = nil,
    HookInstalled = false
}

-- Utility Functions
local function CreateCorner(radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    return corner
end

local function CreateStroke(color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(255, 255, 255)
    stroke.Thickness = thickness or 1
    stroke.Transparency = 0.8
    return stroke
end

local function CreateGradient(color1, color2, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(1, color2 or color1)
    })
    gradient.Rotation = rotation or 90
    return gradient
end

local function LerpColor(colorA, colorB, alpha)
    return Color3.new(
        colorA.R + (colorB.R - colorA.R) * alpha,
        colorA.G + (colorB.G - colorA.G) * alpha,
        colorA.B + (colorB.B - colorA.B) * alpha
    )
end

local function GetHealthColor(healthPercent)
    if healthPercent > 0.6 then
        return LerpColor(Config.Colors.HealthMid, Config.Colors.HealthHigh, (healthPercent - 0.6) / 0.4)
    elseif healthPercent > 0.3 then
        return LerpColor(Config.Colors.HealthLow, Config.Colors.HealthMid, (healthPercent - 0.3) / 0.3)
    else
        return Config.Colors.HealthLow
    end
end

-- ESP Container Management
local function GetESPFolder()
    if State.ESPFolder and State.ESPFolder.Parent then
        return State.ESPFolder
    end
    
    State.ESPFolder = CoreGui:FindFirstChild("ModernESP")
    if not State.ESPFolder then
        State.ESPFolder = Instance.new("Folder")
        State.ESPFolder.Name = "ModernESP"
        State.ESPFolder.Parent = CoreGui
    end
    
    return State.ESPFolder
end

local function ClearESPFolder()
    if State.ESPFolder then
        pcall(function()
            State.ESPFolder:ClearAllChildren()
        end)
    end
    State.ESPInstances = {}
end

-- Team & Relationship Logic
local function IsAlly(targetPlayer)
    if targetPlayer == LocalPlayer then return true end
    
    local success, result = pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then return false end
        
        local alliesFrame = playerGui:FindFirstChild("Main")
            and playerGui.Main:FindFirstChild("Allies")
            and playerGui.Main.Allies:FindFirstChild("Container")
            and playerGui.Main.Allies.Container:FindFirstChild("Allies")
            and playerGui.Main.Allies.Container.Allies:FindFirstChild("ScrollingFrame")
        
        if not alliesFrame then return false end
        
        for _, descendant in ipairs(alliesFrame:GetDescendants()) do
            if descendant:IsA("ImageButton") and descendant.Name == targetPlayer.Name then
                return true
            end
        end
        return false
    end)
    
    return success and result
end

local function GetRelationship(targetPlayer)
    if targetPlayer == LocalPlayer then
        return "Self", Config.Colors.Self
    end
    
    local localTeam = LocalPlayer.Team
    local targetTeam = targetPlayer.Team
    
    if not localTeam or not targetTeam then
        return "Neutral", Config.Colors.Neutral
    end
    
    local localTeamName = localTeam.Name
    local targetTeamName = targetTeam.Name
    
    if localTeamName == targetTeamName then
        if localTeamName == "Pirates" then
            return IsAlly(targetPlayer) and "Ally" or "Enemy", 
                   IsAlly(targetPlayer) and Config.Colors.Ally or Config.Colors.Pirates
        elseif localTeamName == "Marines" then
            return "Ally", Config.Colors.Marines
        end
    end
    
    if (localTeamName == "Pirates" and targetTeamName == "Marines") or
       (localTeamName == "Marines" and targetTeamName == "Pirates") then
        return "Enemy", localTeamName == "Pirates" and Config.Colors.Marines or Config.Colors.Pirates
    end
    
    return "Neutral", Config.Colors.Neutral
end

-- Modern ESP Creation
local function CreateModernESP(targetPlayer)
    if State.ESPInstances[targetPlayer] then return end
    
    local character = targetPlayer.Character
    if not character then return end
    
    local head = character:FindFirstChild("Head")
    if not head then return end
    
    local folder = GetESPFolder()
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = HttpService:GenerateGUID(false)
    billboard.Adornee = head
    billboard.Size = UDim2.fromOffset(200, 70)
    billboard.StudsOffset = Vector3.new(0, 2.8, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 10000
    billboard.Parent = folder
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "Container"
    mainFrame.Size = UDim2.fromScale(1, 1)
    mainFrame.BackgroundColor3 = Config.Colors.Background
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = billboard
    
    CreateCorner(8).Parent = mainFrame
    CreateStroke(Color3.fromRGB(255, 255, 255), 1.5).Parent = mainFrame
    
    local accentBar = Instance.new("Frame")
    accentBar.Name = "AccentBar"
    accentBar.Size = UDim2.new(1, 0, 0, 3)
    accentBar.Position = UDim2.new(0, 0, 0, 0)
    accentBar.BorderSizePixel = 0
    accentBar.Parent = mainFrame
    
    CreateCorner(2).Parent = accentBar
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Parent = mainFrame
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 6)
    padding.PaddingBottom = UDim.new(0, 4)
    padding.Parent = mainFrame
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, -10, 0, 16)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Config.Fonts.Primary
    nameLabel.TextSize = Config.Sizes.Name
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.TextYAlignment = Enum.TextYAlignment.Center
    nameLabel.RichText = true
    nameLabel.Parent = mainFrame
    
    local infoFrame = Instance.new("Frame")
    infoFrame.Name = "InfoFrame"
    infoFrame.Size = UDim2.new(1, -10, 0, 14)
    infoFrame.BackgroundTransparency = 1
    infoFrame.Parent = mainFrame
    
    local infoLayout = Instance.new("UIListLayout")
    infoLayout.FillDirection = Enum.FillDirection.Horizontal
    infoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    infoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    infoLayout.Padding = UDim.new(0, 8)
    infoLayout.Parent = infoFrame
    
    local levelBadge = Instance.new("Frame")
    levelBadge.Name = "LevelBadge"
    levelBadge.Size = UDim2.fromOffset(50, 14)
    levelBadge.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    levelBadge.BorderSizePixel = 0
    levelBadge.Parent = infoFrame
    
    CreateCorner(4).Parent = levelBadge
    
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "LevelText"
    levelLabel.Size = UDim2.fromScale(1, 1)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Font = Config.Fonts.Numeric
    levelLabel.TextSize = Config.Sizes.Level
    levelLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    levelLabel.Text = "Lv. ???"
    levelLabel.Parent = levelBadge
    
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "DistanceLabel"
    distanceLabel.Size = UDim2.fromOffset(60, 14)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Font = Config.Fonts.Numeric
    distanceLabel.TextSize = Config.Sizes.Distance
    distanceLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    distanceLabel.Text = "0m"
    distanceLabel.Parent = infoFrame
    
    local healthContainer = Instance.new("Frame")
    healthContainer.Name = "HealthContainer"
    healthContainer.Size = UDim2.new(1, -20, 0, 6)
    healthContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    healthContainer.BorderSizePixel = 0
    healthContainer.Parent = mainFrame
    
    CreateCorner(3).Parent = healthContainer
    
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.fromScale(1, 1)
    healthBar.BackgroundColor3 = Config.Colors.HealthHigh
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthContainer
    
    CreateCorner(3).Parent = healthBar
    
    local healthGradient = CreateGradient(
        Config.Colors.HealthHigh, 
        Color3.fromRGB(100, 255, 150), 
        0
    )
    healthGradient.Parent = healthBar
    
    local healthText = Instance.new("TextLabel")
    healthText.Name = "HealthText"
    healthText.Size = UDim2.fromScale(1, 1)
    healthText.BackgroundTransparency = 1
    healthText.Font = Config.Fonts.Numeric
    healthText.TextSize = Config.Sizes.Health
    healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
    healthText.TextStrokeTransparency = 0.5
    healthText.Text = "100%"
    healthText.Parent = healthContainer
    
    State.ESPInstances[targetPlayer] = {
        Billboard = billboard,
        MainFrame = mainFrame,
        AccentBar = accentBar,
        NameLabel = nameLabel,
        LevelLabel = levelLabel,
        DistanceLabel = distanceLabel,
        HealthBar = healthBar,
        HealthText = healthText,
        LastUpdate = tick()
    }
    
    mainFrame.Size = UDim2.fromScale(0, 1)
    TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Size = UDim2.fromScale(1, 1)
    }):Play()
end

local function RemoveESP(targetPlayer)
    local espData = State.ESPInstances[targetPlayer]
    if not espData then return end
    
    pcall(function()
        local tween = TweenService:Create(espData.MainFrame, TweenInfo.new(0.2), {
            Size = UDim2.fromScale(0, 1),
            BackgroundTransparency = 1
        })
        tween:Play()
        tween.Completed:Wait()
        espData.Billboard:Destroy()
    end)
    
    State.ESPInstances[targetPlayer] = nil
end

-- Render Loop
local function StartRenderLoop()
    if State.RenderConnection then return end
    
    State.RenderConnection = RunService.Heartbeat:Connect(function()
        if not State.ESPEnabled then
            for _, espData in pairs(State.ESPInstances) do
                if espData and espData.Billboard then
                    espData.Billboard.Enabled = false
                end
            end
            return
        end
        
        local localCharacter = LocalPlayer.Character
        local localHRP = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
        
        for _, targetPlayer in ipairs(Players:GetPlayers()) do
            if targetPlayer == LocalPlayer then continue end
            
            if not State.ESPInstances[targetPlayer] then
                CreateModernESP(targetPlayer)
            end
            
            local espData = State.ESPInstances[targetPlayer]
            if not espData or not espData.Billboard then continue end
            
            local character = targetPlayer.Character
            local head = character and character:FindFirstChild("Head")
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            
            if not (character and head and hrp and humanoid and localHRP) then
                espData.Billboard.Enabled = false
                continue
            end
            
            espData.Billboard.Enabled = true
            espData.Billboard.Adornee = head
            
            local relation, baseColor = GetRelationship(targetPlayer)
            espData.AccentBar.BackgroundColor3 = baseColor
            
            local distance = (localHRP.Position - hrp.Position).Magnitude
            local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            local healthColor = GetHealthColor(healthPercent)
            
            local nameText = string.format(
                '<font color="#%02X%02X%02X">⬤</font> %s',
                math.floor(baseColor.R * 255),
                math.floor(baseColor.G * 255),
                math.floor(baseColor.B * 255),
                targetPlayer.DisplayName
            )
            espData.NameLabel.Text = nameText
            
            local success, level = pcall(function()
                local data = targetPlayer:FindFirstChild("Data")
                local levelValue = data and data:FindFirstChild("Level")
                return levelValue and levelValue.Value or "???"
            end)
            espData.LevelLabel.Text = string.format("Lv. %s", success and level or "???")
            
            espData.DistanceLabel.Text = string.format("%dm", math.floor(distance))
            espData.DistanceLabel.TextColor3 = distance < 50 and Color3.fromRGB(255, 100, 100) or 
                                               distance < 150 and Color3.fromRGB(255, 255, 100) or 
                                               Color3.fromRGB(100, 255, 100)
            
            local targetHealthSize = UDim2.fromScale(healthPercent, 1)
            espData.HealthBar.Size = targetHealthSize
            espData.HealthBar.BackgroundColor3 = healthColor
            espData.HealthText.Text = string.format("%d%%", math.floor(healthPercent * 100))
            
            espData.LastUpdate = tick()
        end
        
        for player, espData in pairs(State.ESPInstances) do
            if not player.Parent or (tick() - espData.LastUpdate > 5) then
                RemoveESP(player)
            end
        end
    end)
end

local function StopRenderLoop()
    if State.RenderConnection then
        State.RenderConnection:Disconnect()
        State.RenderConnection = nil
    end
end

-- Feature Loops
local function StartV3Loop()
    if State.V3Thread then return end
    
    State.V3Enabled = true
    State.V3Thread = task.spawn(function()
        while State.V3Enabled do
            pcall(function()
                local commE = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommE")
                commE:FireServer("ActivateAbility")
            end)
            task.wait(31)
        end
        State.V3Thread = nil
    end)
end

local function StopV3Loop()
    State.V3Enabled = false
    State.V3Thread = nil
end

local function StartNoDodgeLoop()
    if State.DodgeThread then return end
    
    State.NoDodgeEnabled = true
    State.DodgeThread = task.spawn(function()
        while State.NoDodgeEnabled do
            task.wait()
            pcall(function()
                for _, func in next, getgc() do
                    if typeof(func) ~= "function" then continue end
                    
                    local char = LocalPlayer.Character
                    local dodge = char and char:FindFirstChild("Dodge")
                    
                    if dodge and getfenv(func).script == dodge then
                        for idx, upval in next, getupvalues(func) do
                            if tostring(upval) == "0.4" then
                                setupvalue(func, idx, 0)
                            end
                        end
                    end
                end
            end)
        end
        State.DodgeThread = nil
    end)
end

local function StopNoDodgeLoop()
    State.NoDodgeEnabled = false
    State.DodgeThread = nil
end

-- Anti-AFK
local function SetupAntiAfk()
    if not State.AntiAfkEnabled then return end
    
    LocalPlayer.Idled:Connect(function()
        if not State.AntiAfkEnabled then return end
        pcall(function()
            local VirtualInputManager = game:GetService("VirtualInputManager")
            local viewport = workspace.CurrentCamera.ViewportSize
            local x, y = viewport.X / 2, viewport.Y / 2
            
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
        end)
    end)
end

-- Hook Installation
local function InstallHooks()
    if State.HookInstalled then return end
    State.HookInstalled = true
    
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if method == "FireServer" or method == "InvokeServer" then
            if type(args[1]) == "string" and args[1]:upper() == "DODGE" then
                if State.BunnyHopEnabled then
                    local char = LocalPlayer.Character
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

-- Public API
function ModernESP:SetV3(state)
    State.V3Enabled = state
    if state then StartV3Loop() else StopV3Loop() end
end

function ModernESP:SetBunnyhop(state)
    State.BunnyHopEnabled = state
    InstallHooks()
end

function ModernESP:SetNoDodgeCD(state)
    State.NoDodgeEnabled = state
    if state then StartNoDodgeLoop() else StopNoDodgeLoop() end
end

function ModernESP:SetAntiAfk(state)
    State.AntiAfkEnabled = state
    if state then SetupAntiAfk() end
end

function ModernESP:SetBuso(state)
    State.BusoEnabled = state
    if state then
        pcall(function()
            local commF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
            if not LocalPlayer.Character:FindFirstChild("HasBuso") then
                commF:InvokeServer("Buso")
            end
        end)
    end
end

function ModernESP:SetESP(state)
    State.ESPEnabled = state
    if state then
        StartRenderLoop()
    else
        StopRenderLoop()
        ClearESPFolder()
    end
end

-- Cleanup
Players.PlayerRemoving:Connect(function(plr)
    RemoveESP(plr)
end)

InstallHooks()

return ModernESP
