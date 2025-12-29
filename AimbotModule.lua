local AimlockModule = {}

local Players = game:GetService("Players")
local camera = workspace.CurrentCamera
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local humanoid = char:WaitForChild("Humanoid") 

local AimlockPlayerEnabled, AimlockNpcEnabled, PredictionEnabled = false, false, false
local currentTarget = nil
local currentTool = nil
local vActive, sharkZActive, cursedZActive = false, false, false
local tiltEnabled = false
local rightTouches = {}
local tiltConn, preTiltCFrame, dmgConn = nil, nil, nil
local cachedEnemy, cachedBoss = nil, nil
local PredictionAmount = 0.1
local MiniPlayerState, MiniNpcState = nil, nil
local MiniPlayerCreated, MiniNpcCreated = false, false
local MiniPlayerGui, MiniNpcGui = nil, nil
local characterConnections = {}
local renderConnTilt = nil
local watchDamageActive = false

-- =========================
-- MINI TOGGLE (NEON PURPLE)
-- =========================
local function createMiniToggle(name, position, stateVarRef, realVarSetter)
	local playerGui = player:WaitForChild("PlayerGui")
	if playerGui:FindFirstChild(name .. "MiniToggleGui") then
		playerGui[name .. "MiniToggleGui"]:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = name .. "MiniToggleGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 90, 0, 38)
	button.Position = position
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	button.AutoButtonColor = false
	button.BorderSizePixel = 0
	button.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button

	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 45
	gradient.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5
	stroke.Color = Color3.fromRGB(200, 120, 255)
	stroke.Transparency = 0.6
	stroke.Parent = button

	-- Pulse tween
	local pulseTween
	local function startPulse()
		if pulseTween then pulseTween:Cancel() end
		pulseTween = TweenService:Create(
			stroke,
			TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{Transparency = 0.15}
		)
		pulseTween:Play()
	end

	local function stopPulse()
		if pulseTween then
			pulseTween:Cancel()
			pulseTween = nil
		end
	end

	-- Click animation
	local function clickAnim()
		local grow = TweenService:Create(
			button,
			TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = UDim2.new(0, 96, 0, 42)}
		)
		local shrink = TweenService:Create(
			button,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = UDim2.new(0, 90, 0, 38)}
		)
		grow:Play()
		grow.Completed:Connect(function()
			shrink:Play()
		end)
	end

	local function updateUI(state)
		button.Text = name .. (state and " ON" or " OFF")

		if state then
			gradient.Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 120, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(130, 60, 255))
			}
			stroke.Transparency = 0
			startPulse()
		else
			gradient.Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 60)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 40))
			}
			stroke.Transparency = 0.6
			stopPulse()
		end
	end

	button.MouseButton1Click:Connect(function()
		clickAnim()
		stateVarRef.value = not stateVarRef.value
		realVarSetter(stateVarRef.value)
		updateUI(stateVarRef.value)
	end)

	updateUI(stateVarRef.value)
	return screenGui
end

-- =========================
-- API
-- =========================
function AimlockModule:SetMiniTogglePlayerAimlock(state)
	AimlockPlayerEnabled = state
	if not MiniPlayerCreated then
		MiniPlayerState = { value = state }
		MiniPlayerGui = createMiniToggle("Player", UDim2.new(0,10,0,90), MiniPlayerState, function(val)
			AimlockPlayerEnabled = val
		end)
		MiniPlayerCreated = true
	end
end

function AimlockModule:SetMiniToggleNpcAimlock(state)
	AimlockNpcEnabled = state
	if not MiniNpcCreated then
		MiniNpcState = { value = state }
		MiniNpcGui = createMiniToggle("NPC", UDim2.new(0,10,0,50), MiniNpcState, function(val)
			AimlockNpcEnabled = val
		end)
		MiniNpcCreated = true
	end
end

function AimlockModule:SetPrediction(state)
	PredictionEnabled = state
end

function AimlockModule:SetPredictionTime(num)
	if typeof(num) == "number" then
		PredictionAmount = num
	end
end

return AimlockModule
