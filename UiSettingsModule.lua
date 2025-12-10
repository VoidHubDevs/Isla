local UiSettingsModule = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local fillFrame = player:WaitForChild("PlayerGui"):WaitForChild("Main"):WaitForChild("RaceEnergy"):WaitForChild("Fill")

local V4Enabled = false
local FruitCheck = false
local TeleportFruit = false
local sizeConn 
local fruitLoop = nil
local teleportLoop = nil

-- =========================
-- Theme Data & Functions
-- =========================
UiSettingsModule.currentTheme = {
    SchemeColor = Color3.fromRGB(64, 64, 64),
    Background = Color3.fromRGB(0, 0, 0),
    Header = Color3.fromRGB(0, 0, 0),
    TextColor = Color3.fromRGB(255, 255, 255),
    ElementColor = Color3.fromRGB(20, 20, 20)
}

UiSettingsModule.themes = {
    Red = Color3.fromRGB(220, 59, 48),
    Green = Color3.fromRGB(48, 209, 88),
    Purple = Color3.fromRGB(175, 82, 222),
    Orange = Color3.fromRGB(255, 149, 0),
    Pink = Color3.fromRGB(220, 105, 180),
    Yellow = Color3.fromRGB(220, 204, 0),
    Cyan = Color3.fromRGB(0, 220, 220),
    Dark = Color3.fromRGB(100, 100, 100),
    White = Color3.fromRGB(220, 220, 220),
    Teal = Color3.fromRGB(64, 224, 208),
    Lime = Color3.fromRGB(191, 220, 0),
    Indigo = Color3.fromRGB(75, 0, 130)
}

UiSettingsModule.backgroundThemes = {
    Blood = Color3.fromRGB(150, 40, 40),
    Grape = Color3.fromRGB(120, 80, 140),
    Ocean = Color3.fromRGB(70, 100, 160),
    Synapse = Color3.fromRGB(90, 100, 90),
    Pink = Color3.fromRGB(200, 100, 150),
    Midnight = Color3.fromRGB(60, 80, 110),
    Sentinel = Color3.fromRGB(80, 80, 80),
    Dark = Color3.fromRGB(60, 60, 60),
    Light = Color3.fromRGB(200, 200, 200),
    Serpent = Color3.fromRGB(70, 90, 90)
}

function UiSettingsModule:updateSchemeColor(newColor, Library)
    self.currentTheme.SchemeColor = newColor
    local h, s, v = newColor:ToHSV()
    self.currentTheme.Header = Color3.fromHSV(h, s * 0.6, v * 0.3)
    self.currentTheme.ElementColor = Color3.fromHSV(h, s * 0.4, v * 0.2)
    Library:ChangeColor(self.currentTheme)
end

function UiSettingsModule:updateBackgroundColor(newColor, Library)
    self.currentTheme.Background = newColor
    Library:ChangeColor(self.currentTheme)
end

function UiSettingsModule:updateTextColor(newColor, Library)
    self.currentTheme.TextColor = newColor
    Library:ChangeColor(self.currentTheme)
end

function UiSettingsModule:getThemeNames()
    local names = {}
    for name, _ in pairs(self.themes) do
        table.insert(names, name)
    end
    return names
end

function UiSettingsModule:getBackgroundThemeNames()
    local names = {}
    for name, _ in pairs(self.backgroundThemes) do
        table.insert(names, name)
    end
    return names
end

-- =========================
-- Drag / Movable GUI
-- =========================
function UiSettingsModule:MakeDraggable(button)
    local UserInputService = game:GetService("UserInputService")
    local dragging, dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        button.Position = UDim2.new(
          startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = button.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    button.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

local function getAwakenRemote()
    local backpack = player:WaitForChild("Backpack")
    local awakening = backpack:FindFirstChild("Awakening")
    if awakening then
        return awakening:FindFirstChild("RemoteFunction")
    end
    return nil
end

local function tryAwaken()
    local awakenRemote = getAwakenRemote()
    if awakenRemote and fillFrame.Size.X.Scale >= 0.9 then
        awakenRemote:InvokeServer(true)
    end
end

local function Tween(targetCFrame)
	if not targetCFrame then return end
	local info = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local goal = {CFrame = hrp.CFrame + Vector3.new(0, 1, 0)}
	local tween = TweenService:Create(targetCFrame, info, goal)
	tween:Play()
end

local function startFruitLoop()
    if fruitLoop then return end

    fruitLoop = task.spawn(function()
        local notifiedFruits = {}

        while FruitCheck do
            task.wait(0.5)

            for _, v in pairs(workspace:GetChildren()) do
                if v:IsA("Tool") and not notifiedFruits[v] then
                    notifiedFruits[v] = true
                    setthreadcontext(5)
                    require(game.ReplicatedStorage.Notification).new(v.Name .. " Spawned"):Display()
                end
            end

            for fruit in pairs(notifiedFruits) do
                if not fruit.Parent then
                    notifiedFruits[fruit] = nil
                end
            end
        end

        fruitLoop = nil
    end)
end

local function startTeleportLoop()
    if teleportLoop then return end

    teleportLoop = task.spawn(function()
        while TeleportFruit do
            task.wait()
            for _, v in pairs(workspace:GetChildren()) do
                if v:IsA("Tool") and v:FindFirstChild("Handle") then
                    Tween(v.Handle)
                end
            end
        end

        teleportLoop = nil
    end)
end

function UiSettingsModule:SetWalkSpeed(value)
    getgenv().WalkSpeedValue = value
    local player = game:GetService("Players").LocalPlayer

    local function applySpeed(char)
        local humanoid = char:WaitForChild("Humanoid")
        humanoid.WalkSpeed = value
        humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if humanoid.WalkSpeed ~= value then
                humanoid.WalkSpeed = value
            end
        end)
    end

    if player.Character then
        applySpeed(player.Character)
    end

    player.CharacterAdded:Connect(function(char)
        char:WaitForChild("Humanoid")
        applySpeed(char)
    end)
end

function UiSettingsModule:SetV4(state)
    V4Enabled = state
    
    if V4Enabled then
        if not sizeConn then
            sizeConn = fillFrame:GetPropertyChangedSignal("Size"):Connect(function()
                tryAwaken()
            end)
        end
    else
        if sizeConn then
            sizeConn:Disconnect()
            sizeConn = nil
        end
    end
end

function UiSettingsModule:SetFruitCheck(state)
    FruitCheck = state
    if state then
        startFruitLoop()
    end
end

function UiSettingsModule:SetTeleportFruit(state)
    TeleportFruit = state
    if state then
        startTeleportLoop()
    end
end

return UiSettingsModule
