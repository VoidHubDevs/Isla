local StuffsModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

local PingsOrFpsEnabled = false
local FpsBoostEnabled = false
local InfiniteEnergy = false
local FastAttackEnabled = false
local WalkWaterEnabled = false
local Fog = false
local Lava = false

local fpsConn, fastConn, energyConnection, fpsBoostConn = nil, nil, nil, nil
local connections = {}

local ScreenGui, FpsPingLabel = nil, nil

local function createGui()
    if ScreenGui then return end
    
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FpsPingGui"
    ScreenGui.ResetOnSpawn = false
    
    local success, parent = pcall(function()
        return LocalPlayer:WaitForChild("PlayerGui")
    end)
    if not success then return end
    
    ScreenGui.Parent = parent

    FpsPingLabel = Instance.new("TextLabel")
    FpsPingLabel.Name = "FpsPingLabel"
    FpsPingLabel.Size = UDim2.new(0, 120, 0, 20)
    FpsPingLabel.Position = UDim2.new(1, -10, 0, 10)
    FpsPingLabel.AnchorPoint = Vector2.new(1, 0)
    FpsPingLabel.BackgroundTransparency = 1
    FpsPingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    FpsPingLabel.Font = Enum.Font.SourceSansBold
    FpsPingLabel.TextSize = 18
    FpsPingLabel.TextXAlignment = Enum.TextXAlignment.Right
    FpsPingLabel.RichText = true
    FpsPingLabel.Parent = ScreenGui
end

local function startFPSLoop()
    if fpsConn then return end
    
    local lastTime = tick()
    local frameCount = 0
    
    fpsConn = RunService.RenderStepped:Connect(function()
        if not PingsOrFpsEnabled then
            if ScreenGui then ScreenGui.Enabled = false end
            return
        end
        
        createGui()
        if ScreenGui then ScreenGui.Enabled = true end
        
        frameCount = frameCount + 1
        if tick() - lastTime >= 1 then
            local fps = frameCount
            frameCount = 0
            lastTime = tick()
            
            local ping = math.floor(LocalPlayer:GetNetworkPing() * 2000)
            
            local fpsColor = fps >= 50 and "00FF00" or (fps >= 30 and "FFA500" or "FF0000")
            local pingColor = ping <= 80 and "00FF00" or (ping <= 150 and "FFFF00" or "FF0000")
            
            if FpsPingLabel then
                FpsPingLabel.Text = string.format(
                    '<font color="#%s">FPS: %d</font>  |  <font color="#%s">Ping: %dms</font>',
                    fpsColor, fps, pingColor, ping
                )
            end
        end
    end)
end

local function stopFPSLoop()
    if fpsConn then
        fpsConn:Disconnect()
        fpsConn = nil
    end
end

local function FPSBoost()
    Lighting.FogEnd = 1e9
    Lighting.FogStart = 1e9
    Lighting.ClockTime = 12
    Lighting.GlobalShadows = false
    Lighting.Brightness = 2
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)

    local Terrain = Workspace:FindFirstChildOfClass("Terrain")
    if Terrain then
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 1
    end
    
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") or v:IsA("UnionOperation") or v:IsA("MeshPart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
            v.CastShadow = false
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v:Destroy()
        elseif v:IsA("ParticleEmitter") then
            v.Lifetime = NumberRange.new(0, 0)
        elseif v:IsA("Trail") then
            v.Lifetime = 0
        elseif v:IsA("Explosion") then
            v.BlastPressure = 1
            v.BlastRadius = 1
        elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") then
            v.Enabled = false
        end
    end
    
    if fpsBoostConn then
        fpsBoostConn:Disconnect()
        fpsBoostConn = nil
    end
    
    fpsBoostConn = Workspace.DescendantAdded:Connect(function(v)
        task.wait(0.1)
        if v:IsA("ParticleEmitter") then
            v.Lifetime = NumberRange.new(0, 0)
        elseif v:IsA("Trail") then
            v.Lifetime = 0
        elseif v:IsA("Explosion") then
            v.BlastPressure = 1
            v.BlastRadius = 1
        elseif v:IsA("BasePart") then
            v.CastShadow = false
        elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") then
            v.Enabled = false
        end
    end)
end

local function infiniteStam(state)
    InfiniteEnergy = state
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local energy = character:FindFirstChild("Energy")
    if not energy then return end

    if not state then
        if energyConnection then
            energyConnection:Disconnect()
            energyConnection = nil
        end
        return
    end
    
    if not energyConnection then
        energyConnection = energy.Changed:Connect(function()
            if InfiniteEnergy then
                energy.Value = energy.MaxValue
            end
        end)
    end
end

local Config = {
    AttackDistance = 200,
    AttackMobs = true,
    AttackPlayers = true,
    AttackCooldown = 0.001,
    ComboResetTime = 0.001,
    MaxCombo = 2,
    HitboxLimbs = {"RightLowerArm", "RightUpperArm", "LeftLowerArm", "LeftUpperArm", "RightHand", "LeftHand"},
    AutoClickEnabled = true
}

local FastAttack = {}
FastAttack.__index = FastAttack

function FastAttack.new()
    local self = setmetatable({
        Debounce = 0,
        ComboDebounce = 0,
        ShootDebounce = 0,
        M1Combo = 0,
        EnemyRootPart = nil,
        Connections = {},
        CombatFlags = nil,
        ShootFunction = nil,
        HitFunction = nil,
        SpecialShoots = {}
    }, FastAttack)
    
    pcall(function()
        local Modules = ReplicatedStorage:WaitForChild("Modules")
        local Net = Modules:WaitForChild("Net")
        
        self.RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
        self.RegisterHit = Net:WaitForChild("RE/RegisterHit")
        self.ShootGunEvent = Net:WaitForChild("RE/ShootGunEvent")
        self.GunValidator = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Validator2")
        
        local FlagsModule = Modules:FindFirstChild("Flags")
        if FlagsModule then
            local flags = require(FlagsModule)
            if flags and flags.COMBAT_REMOTE_THREAD then
                self.CombatFlags = flags.COMBAT_REMOTE_THREAD
            end
        end
        
        local CombatController = ReplicatedStorage:FindFirstChild("Controllers") and 
                                ReplicatedStorage.Controllers:FindFirstChild("CombatController")
        if CombatController then
            local combatMod = require(CombatController)
            if combatMod and combatMod.Attack then
                self.ShootFunction = getupvalue(combatMod.Attack, 9)
            end
        end
        
        local playerScripts = LocalPlayer:WaitForChild("PlayerScripts")
        local localScript = playerScripts:FindFirstChildOfClass("LocalScript")
        if localScript and getsenv then
            local env = getsenv(localScript)
            if env and env._G and env._G.SendHitsToServer then
                self.HitFunction = env._G.SendHitsToServer
            end
        end
    end)
    
    return self
end

function FastAttack:IsEntityAlive(entity)
    local humanoid = entity and entity:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

function FastAttack:CheckStun(Character, Humanoid, ToolTip)
    local Stun = Character:FindFirstChild("Stun")
    local Busy = Character:FindFirstChild("Busy")
    
    if Humanoid.Sit and (ToolTip == "Sword" or ToolTip == "Melee" or ToolTip == "Blox Fruit") then
        return false
    elseif Stun and Stun.Value > 0 or Busy and Busy.Value then
        return false
    end
    return true
end

function FastAttack:GetBladeHits(Character, Distance)
    local Position = Character:GetPivot().Position
    local BladeHits = {}
    Distance = Distance or Config.AttackDistance
    
    local function ProcessTargets(Folder, CanAttack)
        if not Folder then return end
        for _, Enemy in ipairs(Folder:GetChildren()) do
            if Enemy ~= Character and self:IsEntityAlive(Enemy) then
                local limbName = Config.HitboxLimbs[math.random(#Config.HitboxLimbs)]
                local BasePart = Enemy:FindFirstChild(limbName) or Enemy:FindFirstChild("HumanoidRootPart")
                if BasePart and (Position - BasePart.Position).Magnitude <= Distance then
                    if not self.EnemyRootPart then
                        self.EnemyRootPart = BasePart
                    else
                        table.insert(BladeHits, {Enemy, BasePart})
                    end
                end
            end
        end
    end
    
    if Config.AttackMobs then
        ProcessTargets(Workspace:FindFirstChild("Enemies"))
    end
    if Config.AttackPlayers then
        ProcessTargets(Workspace:FindFirstChild("Characters"))
    end
    
    return BladeHits
end

function FastAttack:GetClosestEnemy(Character, Distance)
    local BladeHits = self:GetBladeHits(Character, Distance)
    local Closest, MinDistance = nil, math.huge
    
    for _, Hit in ipairs(BladeHits) do
        local Magnitude = (Character:GetPivot().Position - Hit[2].Position).Magnitude
        if Magnitude < MinDistance then
            MinDistance = Magnitude
            Closest = Hit[2]
        end
    end
    return Closest
end

function FastAttack:GetCombo()
    local Combo = (tick() - self.ComboDebounce) <= Config.ComboResetTime and self.M1Combo or 0
    Combo = Combo >= Config.MaxCombo and 1 or Combo + 1
    self.ComboDebounce = tick()
    self.M1Combo = Combo
    return Combo
end

function FastAttack:ShootInTarget(TargetPosition)
    local Character = LocalPlayer.Character
    if not self:IsEntityAlive(Character) then return end
    
    local Equipped = Character:FindFirstChildOfClass("Tool")
    if not Equipped or Equipped.ToolTip ~= "Gun" then return end
    
    local Cooldown = Equipped:FindFirstChild("Cooldown") and Equipped.Cooldown.Value or 0.3
    if (tick() - self.ShootDebounce) < Cooldown then return end
    
    local ShootType = self.SpecialShoots[Equipped.Name] or "Normal"
    
    pcall(function()
        Equipped:SetAttribute("LocalTotalShots", (Equipped:GetAttribute("LocalTotalShots") or 0) + 1)
        self.GunValidator:FireServer(self:GetValidator2())
        
        if ShootType == "TAP" and Equipped:FindFirstChild("RemoteEvent") then
            Equipped.RemoteEvent:FireServer("TAP", TargetPosition)
        else
            self.ShootGunEvent:FireServer(TargetPosition)
        end
    end)
    
    self.ShootDebounce = tick()
end

function FastAttack:GetValidator2()
    if not self.ShootFunction then return 0, 0 end
    
    local v1 = getupvalue(self.ShootFunction, 15) or 0
    local v2 = getupvalue(self.ShootFunction, 13) or 1
    local v3 = getupvalue(self.ShootFunction, 16) or 1
    local v4 = getupvalue(self.ShootFunction, 17) or 1
    local v5 = getupvalue(self.ShootFunction, 14) or 0
    local v6 = getupvalue(self.ShootFunction, 12) or 0
    local v7 = getupvalue(self.ShootFunction, 18) or 0
    
    local v8 = v6 * v2
    local v9 = (v5 * v2 + v6 * v1) % v3
    v9 = (v9 * v3 + v8) % v4
    v5 = math.floor(v9 / v3)
    v6 = v9 - v5 * v3
    v7 = v7 + 1
    
    setupvalue(self.ShootFunction, 15, v1)
    setupvalue(self.ShootFunction, 13, v2)
    setupvalue(self.ShootFunction, 16, v3)
    setupvalue(self.ShootFunction, 17, v4)
    setupvalue(self.ShootFunction, 14, v5)
    setupvalue(self.ShootFunction, 12, v6)
    setupvalue(self.ShootFunction, 18, v7)
    
    return math.floor(v9 / v4 * 16777215), v7
end

function FastAttack:UseNormalClick(Character, Humanoid, Cooldown)
    self.EnemyRootPart = nil
    local BladeHits = self:GetBladeHits(Character)
    
    if self.EnemyRootPart and self.RegisterAttack and self.RegisterHit then
        self.RegisterAttack:FireServer(Cooldown)
        if self.CombatFlags and self.HitFunction then
            self.HitFunction(self.EnemyRootPart, BladeHits)
        else
            self.RegisterHit:FireServer(self.EnemyRootPart, BladeHits)
        end
    end
end

function FastAttack:UseFruitM1(Character, Equipped, Combo)
    local range = Config.AttackDistance
    local Targets = self:GetBladeHits(Character, range)
    if not Targets[1] then return end

    local Direction = (Targets[1][2].Position - Character:GetPivot().Position).Unit
    if Equipped.LeftClickRemote then
        Equipped.LeftClickRemote:FireServer(Direction, Combo)
    end
end

function FastAttack:Attack()
    if not Config.AutoClickEnabled or (tick() - self.Debounce) < Config.AttackCooldown then return end
    
    local Character = LocalPlayer.Character
    if not Character or not self:IsEntityAlive(Character) then return end
    
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local Equipped = Character:FindFirstChildOfClass("Tool")
    if not Equipped or not Humanoid then return end
    
    local ToolTip = Equipped.ToolTip
    if not table.find({"Melee", "Blox Fruit", "Sword", "Gun"}, ToolTip) then return end
    
    local Cooldown = Equipped:FindFirstChild("Cooldown") and Equipped.Cooldown.Value or Config.AttackCooldown
    if not self:CheckStun(Character, Humanoid, ToolTip) then return end
    
    local Combo = self:GetCombo()
    Cooldown = Cooldown + (Combo >= Config.MaxCombo and 0.05 or 0)
    self.Debounce = Combo >= Config.MaxCombo and ToolTip ~= "Gun" and (tick() + 0.05) or tick()
    
    if ToolTip == "Blox Fruit" and Equipped:FindFirstChild("LeftClickRemote") then
        self:UseFruitM1(Character, Equipped, Combo)
    elseif ToolTip == "Gun" then
        local Target = self:GetClosestEnemy(Character, 120)
        if Target then
            self:ShootInTarget(Target.Position)
        end
    else
        self:UseNormalClick(Character, Humanoid, Cooldown)
    end
end

local AttackInstance = FastAttack.new()

local function startFastAttack()
    if fastConn then return end
    fastConn = RunService.Stepped:Connect(function()
        if FastAttackEnabled then
            AttackInstance:Attack()
        end
    end)
end

local function stopFastAttack()
    if fastConn then
        fastConn:Disconnect()
        fastConn = nil
    end
end

local function setWalkWater(state)
    WalkWaterEnabled = state
    local waterPart = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("WaterBase-Plane")
    if waterPart then
        waterPart.Size = state and Vector3.new(1000, 110, 1000) or Vector3.new(1000, 80, 1000)
    end
end

local function removeLava()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name == "Lava" then
            v:Destroy()
        end
    end
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v.Name == "Lava" then
            v:Destroy()
        end
    end
end

function StuffsModule:SetFpsBoost(state)
    FpsBoostEnabled = state
    if state then
        FPSBoost()
    else
        if fpsBoostConn then
            fpsBoostConn:Disconnect()
            fpsBoostConn = nil
        end
    end
end

function StuffsModule:SetINFEnergy(state)
    infiniteStam(state)
end

function StuffsModule:SetFog(state)
    Fog = state
    if state then
        Lighting.FogEnd = 100000
        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("Atmosphere") then
                v:Destroy()
            end
        end
    end
end

function StuffsModule:SetLava(state)
    Lava = state
    if state then removeLava() end
end

function StuffsModule:SetRejoinServer()
    local TeleportService = game:GetService("TeleportService")
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end

function StuffsModule:SetFastAttack(state)
    FastAttackEnabled = state
    if state then
        startFastAttack()
    else
        stopFastAttack()
    end
end

function StuffsModule:SetWalkWater(state)
    setWalkWater(state)
end

function StuffsModule:SetPingsOrFps(state)
    PingsOrFpsEnabled = state
    if state then
        startFPSLoop()
    else
        stopFPSLoop()
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if InfiniteEnergy then
        infiniteStam(true)
    end
end)

return StuffsModule
