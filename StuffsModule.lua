--[[
    Stuffs Module v2.0 - Optimized
    Fast Attack, FPS Boost, Utilities
--]]

local StuffsModule = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

-- State
local FastAttackEnabled = false
local FPSBoostEnabled = false
local InfiniteEnergy = false
local WalkWaterEnabled = false
local FogRemoved = false
local LavaRemoved = false
local FPSEnabled = false

-- Connections
local FastAttackConn = nil
local FPSConn = nil
local EnergyConn = nil
local DescendantConn = nil

-- GUI
local FPSGui = nil
local FPSLabel = nil

-- Utility
local function SafeCall(func, ...)
    local success, result = pcall(func, ...)
    return success and result or nil
end

-- FPS/Ping Display
local function CreateFPSGui()
    if FPSGui then return end
    
    FPSGui = Instance.new("ScreenGui")
    FPSGui.Name = "VoidHub_FPS"
    FPSGui.ResetOnSpawn = false
    FPSGui.Parent = player:WaitForChild("PlayerGui")
    
    FPSLabel = Instance.new("TextLabel")
    FPSLabel.Name = "FPSLabel"
    FPSLabel.Size = UDim2.new(0, 150, 0, 25)
    FPSLabel.Position = UDim2.new(1, -10, 0, 10)
    FPSLabel.AnchorPoint = Vector2.new(1, 0)
    FPSLabel.BackgroundTransparency = 1
    FPSLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    FPSLabel.Font = Enum.Font.SourceSansBold
    FPSLabel.TextSize = 18
    FPSLabel.TextXAlignment = Enum.TextXAlignment.Right
    FPSLabel.RichText = true
    FPSLabel.Parent = FPSGui
end

local function StartFPSDisplay()
    if FPSConn then return end
    
    CreateFPSGui()
    
    local lastTime = tick()
    local frameCount = 0
    
    FPSConn = RunService.RenderStepped:Connect(function()
        if not FPSEnabled then
            FPSGui.Enabled = false
            return
        end
        
        FPSGui.Enabled = true
        frameCount = frameCount + 1
        
        if tick() - lastTime >= 1 then
            local fps = frameCount
            frameCount = 0
            lastTime = tick()
            
            local ping = SafeCall(function()
                return math.floor(player:GetNetworkPing() * 2000)
            end) or 0
            
            local fpsColor = fps >= 60 and "00FF00" or fps >= 30 and "FFA500" or "FF0000"
            local pingColor = ping <= 80 and "00FF00" or ping <= 150 and "FFFF00" or "FF0000"
            
            if FPSLabel then
                FPSLabel.Text = string.format(
                    '<font color="#%s">FPS: %d</font> | <font color="#%s">Ping: %dms</font>',
                    fpsColor, fps, pingColor, ping
                )
            end
        end
    end)
end

local function StopFPSDisplay()
    if FPSConn then
        FPSConn:Disconnect()
        FPSConn = nil
    end
end

-- FPS Boost
local function ApplyFPSBoost()
    -- Lighting optimizations
    Lighting.FogEnd = 1e9
    Lighting.FogStart = 1e9
    Lighting.ClockTime = 12
    Lighting.GlobalShadows = false
    Lighting.Brightness = 2
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    
    -- Terrain optimizations
    local Terrain = Workspace:FindFirstChildOfClass("Terrain")
    if Terrain then
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 1
    end
    
    -- Process existing objects
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
    
    -- Monitor new objects
    if DescendantConn then
        DescendantConn:Disconnect()
        DescendantConn = nil
    end
    
    DescendantConn = Workspace.DescendantAdded:Connect(function(v)
        task.wait(0.1)
        SafeCall(function()
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
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v:Destroy()
            end
        end)
    end)
end

-- Infinite Energy
local function SetupInfiniteEnergy()
    if EnergyConn then
        EnergyConn:Disconnect()
        EnergyConn = nil
    end
    
    if not InfiniteEnergy then return end
    
    local char = player.Character
    if not char then return end
    
    local energy = char:FindFirstChild("Energy")
    if not energy then return end
    
    EnergyConn = energy.Changed:Connect(function()
        if InfiniteEnergy then
            energy.Value = energy.MaxValue
        end
    end)
end

-- Fast Attack System
local FastAttackConfig = {
    AttackDistance = 200,
    AttackCooldown = 0.001,
    ComboResetTime = 0.001,
    MaxCombo = 2,
    HitboxLimbs = {"RightLowerArm", "RightUpperArm", "LeftLowerArm", "LeftUpperArm", "RightHand", "LeftHand"},
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
        CombatFlags = nil,
        ShootFunction = nil,
        HitFunction = nil,
        RegisterAttack = nil,
        RegisterHit = nil,
        ShootGunEvent = nil,
        GunValidator = nil,
    }, FastAttack)
    
    -- Initialize remotes
    SafeCall(function()
        local Modules = ReplicatedStorage:WaitForChild("Modules")
        local Net = Modules:WaitForChild("Net")
        
        self.RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
        self.RegisterHit = Net:WaitForChild("RE/RegisterHit")
        self.ShootGunEvent = Net:WaitForChild("RE/ShootGunEvent")
        self.GunValidator = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Validator2")
        
        -- Get combat flags
        local FlagsModule = Modules:FindFirstChild("Flags")
        if FlagsModule then
            local flags = require(FlagsModule)
            if flags and flags.COMBAT_REMOTE_THREAD then
                self.CombatFlags = flags.COMBAT_REMOTE_THREAD
            end
        end
        
        -- Get shoot function
        local CombatController = ReplicatedStorage:FindFirstChild("Controllers") and 
                                ReplicatedStorage.Controllers:FindFirstChild("CombatController")
        if CombatController then
            local combatMod = require(CombatController)
            if combatMod and combatMod.Attack then
                self.ShootFunction = getupvalue(combatMod.Attack, 9)
            end
        end
        
        -- Get hit function
        local playerScripts = player:WaitForChild("PlayerScripts")
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
    Distance = Distance or FastAttackConfig.AttackDistance
    
    local function ProcessTargets(Folder)
        if not Folder then return end
        for _, Enemy in ipairs(Folder:GetChildren()) do
            if Enemy ~= Character and self:IsEntityAlive(Enemy) then
                local limbName = FastAttackConfig.HitboxLimbs[math.random(#FastAttackConfig.HitboxLimbs)]
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
    
    ProcessTargets(Workspace:FindFirstChild("Enemies"))
    ProcessTargets(Workspace:FindFirstChild("Characters"))
    
    return BladeHits
end

function FastAttack:GetCombo()
    local Combo = (tick() - self.ComboDebounce) <= FastAttackConfig.ComboResetTime and self.M1Combo or 0
    Combo = Combo >= FastAttackConfig.MaxCombo and 1 or Combo + 1
    self.ComboDebounce = tick()
    self.M1Combo = Combo
    return Combo
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

function FastAttack:ShootInTarget(TargetPosition)
    local Character = player.Character
    if not self:IsEntityAlive(Character) then return end
    
    local Equipped = Character:FindFirstChildOfClass("Tool")
    if not Equipped or Equipped.ToolTip ~= "Gun" then return end
    
    local Cooldown = Equipped:FindFirstChild("Cooldown") and Equipped.Cooldown.Value or 0.3
    if (tick() - self.ShootDebounce) < Cooldown then return end
    
    SafeCall(function()
        Equipped:SetAttribute("LocalTotalShots", (Equipped:GetAttribute("LocalTotalShots") or 0) + 1)
        self.GunValidator:FireServer(self:GetValidator2())
        
        if Equipped:FindFirstChild("RemoteEvent") then
            Equipped.RemoteEvent:FireServer("TAP", TargetPosition)
        else
            self.ShootGunEvent:FireServer(TargetPosition)
        end
    end)
    
    self.ShootDebounce = tick()
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
    local Targets = self:GetBladeHits(Character, FastAttackConfig.AttackDistance)
    if not Targets[1] then return end
    
    local Direction = (Targets[1][2].Position - Character:GetPivot().Position).Unit
    if Equipped.LeftClickRemote then
        Equipped.LeftClickRemote:FireServer(Direction, Combo)
    end
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

function FastAttack:Attack()
    if (tick() - self.Debounce) < FastAttackConfig.AttackCooldown then return end
    
    local Character = player.Character
    if not Character or not self:IsEntityAlive(Character) then return end
    
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local Equipped = Character:FindFirstChildOfClass("Tool")
    if not Equipped or not Humanoid then return end
    
    local ToolTip = Equipped.ToolTip
    if not table.find({"Melee", "Blox Fruit", "Sword", "Gun"}, ToolTip) then return end
    
    local Cooldown = Equipped:FindFirstChild("Cooldown") and Equipped.Cooldown.Value or FastAttackConfig.AttackCooldown
    if not self:CheckStun(Character, Humanoid, ToolTip) then return end
    
    local Combo = self:GetCombo()
    Cooldown = Cooldown + (Combo >= FastAttackConfig.MaxCombo and 0.05 or 0)
    self.Debounce = Combo >= FastAttackConfig.MaxCombo and ToolTip ~= "Gun" and (tick() + 0.05) or tick()
    
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

local function StartFastAttack()
    if FastAttackConn then return end
    
    FastAttackConn = RunService.Stepped:Connect(function()
        if FastAttackEnabled then
            AttackInstance:Attack()
        end
    end)
end

local function StopFastAttack()
    if FastAttackConn then
        FastAttackConn:Disconnect()
        FastAttackConn = nil
    end
end

-- Walk on Water
local function SetWalkWater(state)
    WalkWaterEnabled = state
    local waterPart = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("WaterBase-Plane")
    if waterPart then
        waterPart.Size = state and Vector3.new(1000, 110, 1000) or Vector3.new(1000, 80, 1000)
    end
end

-- Remove Lava
local function RemoveLava()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name == "Lava" then
            v:Destroy()
        end
    end
end

-- Remove Fog
local function RemoveFog()
    Lighting.FogEnd = 100000
    for _, v in pairs(Lighting:GetDescendants()) do
        if v:IsA("Atmosphere") then
            v:Destroy()
        end
    end
end

-- Rejoin Server
local function RejoinServer()
    local TeleportService = game:GetService("TeleportService")
    TeleportService:Teleport(game.PlaceId, player)
end

-- API
function StuffsModule:SetFpsBoost(state)
    FPSBoostEnabled = state
    if state then
        ApplyFPSBoost()
    else
        if DescendantConn then
            DescendantConn:Disconnect()
            DescendantConn = nil
        end
    end
end

function StuffsModule:SetINFEnergy(state)
    InfiniteEnergy = state
    SetupInfiniteEnergy()
end

function StuffsModule:SetFog(state)
    FogRemoved = state
    if state then RemoveFog() end
end

function StuffsModule:SetLava(state)
    LavaRemoved = state
    if state then RemoveLava() end
end

function StuffsModule:SetRejoinServer()
    RejoinServer()
end

function StuffsModule:SetFastAttack(state)
    FastAttackEnabled = state
    if state then
        StartFastAttack()
    else
        StopFastAttack()
    end
end

function StuffsModule:SetWalkWater(state)
    SetWalkWater(state)
end

function StuffsModule:SetPingsOrFps(state)
    FPSEnabled = state
    if state then
        StartFPSDisplay()
    else
        StopFPSDisplay()
    end
end

-- Character respawn handler
player.CharacterAdded:Connect(function()
    task.wait(1)
    if InfiniteEnergy then
        SetupInfiniteEnergy()
    end
end)

return StuffsModule
