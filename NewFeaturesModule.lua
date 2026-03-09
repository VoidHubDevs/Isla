local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local module = {}

local enabled = {
    gunAimbot = false,
    skillAimbot = false,
    teleport = false,
    walkOnWater = false,
}
local targetPlayerName = nil
local connections = {}

local waterPlane = Workspace.Map and Workspace.Map:FindFirstChild("WaterBase-Plane")
local defaultWaterSize = waterPlane and waterPlane.Size or Vector3.new(1000, 80, 1000)

local function getGun()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool:FindFirstChild("RemoteFunctionShoot") then
            return tool
        end
    end
    return nil
end

local function tweenTo(cframe)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local distance = (cframe.Position - hrp.Position).Magnitude
    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(distance / 350, Enum.EasingStyle.Linear),
        {CFrame = cframe}
    )
    tween:Play()
    return tween
end

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = { ... }

    if enabled.skillAimbot and method == "FireServer" and tostring(self) == "RemoteEvent" then
        local target = targetPlayerName and Players:FindFirstChild(targetPlayerName)
        if target and target.Character then
            local hrp = target.Character:FindFirstChild("HumanoidRootPart")
            if hrp and type(args[2]) ~= "boolean" then
                args[2] = hrp.Position
                return oldNamecall(self, unpack(args))
            end
        end
    end
    return oldNamecall(self, ...)
end)

local function updateGunAimbot()
    if not enabled.gunAimbot then return end
    local target = targetPlayerName and Players:FindFirstChild(targetPlayerName)
    if not target or not target.Character then return end
    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    local gun = getGun()
    if not gun or not targetHRP then return end

    pcall(function()
        if gun:FindFirstChild("Cooldown") then
            gun.Cooldown.Value = 0
        end
        local args = { targetHRP.Position, targetHRP }
        gun.RemoteFunctionShoot:InvokeServer(unpack(args))
        VirtualUser:Button1Down(Vector2.new(1280, 672))
    end)
end

local function updateTeleport()
    if not enabled.teleport then return end
    local target = targetPlayerName and Players:FindFirstChild(targetPlayerName)
    if not target or not target.Character then return end
    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    tweenTo(targetHRP.CFrame * CFrame.new(0, 5, 0))
end

local function updateWalkOnWater()
    if not waterPlane then return end
    if enabled.walkOnWater then
        waterPlane.Size = Vector3.new(1000, 112, 1000)
    else
        waterPlane.Size = defaultWaterSize
    end
end

local function reconnect()
    for _, conn in pairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    connections = {}

    if enabled.gunAimbot then
        connections.gunAimbot = RunService.Heartbeat:Connect(updateGunAimbot)
    end

    if enabled.teleport then
        connections.teleport = RunService.Heartbeat:Connect(updateTeleport)
    end

    updateWalkOnWater()
end

function module:SetTarget(name)
    targetPlayerName = name
end

function module:SetGunAimbot(state)
    if enabled.gunAimbot == state then return end
    enabled.gunAimbot = state
    reconnect()
end

function module:SetSkillAimbot(state)
    enabled.skillAimbot = state
end

function module:SetTeleport(state)
    if enabled.teleport == state then return end
    enabled.teleport = state
    reconnect()
end

function module:SetWalkOnWater(state)
    if enabled.walkOnWater == state then return end
    enabled.walkOnWater = state
    updateWalkOnWater()
end

function module:EnablePvP()
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("EnablePvp")
    end)
end

function module:Cleanup()
    enabled.gunAimbot = false
    enabled.skillAimbot = false
    enabled.teleport = false
    enabled.walkOnWater = false
    targetPlayerName = nil
    reconnect()
    if waterPlane then
        waterPlane.Size = defaultWaterSize
    end
end

return module
