-- NeonUI Module
-- Provides neon colors, gradients, glow, and simple widget factories (button, toggle, slider, capsule)
-- Usage: local NeonUI = require(path.to.NeonUI)

local NeonUI = {}
NeonUI.__version = "1.0"

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- ===== Default Neon Palette (true neon) =====
NeonUI.Colors = {
    NEON_PINK    = Color3.fromRGB(255,   0, 180),
    NEON_CYAN    = Color3.fromRGB(0,   255, 255),
    NEON_GREEN   = Color3.fromRGB(0,   255, 120),
    NEON_PURPLE  = Color3.fromRGB(170,   0, 255),
    NEON_YELLOW  = Color3.fromRGB(255, 240,   0),
    NEON_RED     = Color3.fromRGB(255,  30,  30),
    NEON_BLUE    = Color3.fromRGB(0,   200, 255),
    NEON_MAGENTA = Color3.fromRGB(255,   0, 220),
    PANEL_BLACK  = Color3.fromRGB(2,2,2),
    VOID_BLACK   = Color3.fromRGB(8,8,10),
    ITEM_BG      = Color3.fromRGB(20,20,22),
    TEXT_WHITE   = Color3.fromRGB(245,245,245),
}

-- ===== Settings =====
NeonUI.settings = {
    mobileMode = UserInputService.TouchEnabled,
    defaultGlowLayers = UserInputService.TouchEnabled and 1 or 3,
    defaultGlowThickness = UserInputService.TouchEnabled and {3,8} or {6,12,20},
    defaultGlowTransparency = UserInputService.TouchEnabled and {0.8, 0.95} or {0.80, 0.92, 0.98},
    pulsePeriod = 1.2,
    gradientLerpWhite = 0.20,
}

-- ===== Helpers =====
local function safeParent(child, parent)
    pcall(function() child.Parent = parent end)
end

local function cloneOrNewUIGradient(target)
    local g = target:FindFirstChildOfClass("UIGradient")
    if not g then g = Instance.new("UIGradient") g.Parent = target end
    return g
end

-- ===== Functions =====

-- Apply a subtle neon gradient to a GuiObject (Frame, TextButton, etc.)
-- colorA (Color3), colorB optional (Color3). If colorB omitted it's lerped to white.
function NeonUI.ApplyGradient(target, colorA, colorB)
    if not target or not colorA then return nil, "bad_args" end
    local color2 = colorB or colorA:Lerp(Color3.new(1,1,1), NeonUI.settings.gradientLerpWhite)
    local g = cloneOrNewUIGradient(target)
    g.Rotation = 12
    g.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, colorA),
        ColorSequenceKeypoint.new(1, color2)
    }
    g.Transparency = NumberSequence.new{ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.05) }
    return g
end

-- Create a multi-layer glow behind a GuiObject. Returns the glow container frame.
-- options: { layers = n, thicknesses = table, transparencies = table, offset = number }
function NeonUI.ApplyGlow(target, glowColor, options)
    if not target or not glowColor then return nil, "bad_args" end
    options = options or {}
    local layers = options.layers or NeonUI.settings.defaultGlowLayers
    local thicknesses = options.thicknesses or NeonUI.settings.defaultGlowThickness
    local transparencies = options.transparencies or NeonUI.settings.defaultGlowTransparency
    local offset = options.offset or -4

    -- Remove existing glow created by this module
    local existing = target:FindFirstChild("__neon_glow")
    if existing then
        pcall(function() existing:Destroy() end)
    end

    local glow = Instance.new("Frame")
    glow.Name = "__neon_glow"
    -- Slightly bigger than the target
    glow.Size = UDim2.new(1, math.abs(offset)*2, 1, math.abs(offset)*2)
    glow.Position = UDim2.new(0, offset, 0, offset)
    glow.BackgroundTransparency = 1
    glow.ZIndex = (target.ZIndex or 1) - 1
    safeParent(glow, target)

    -- Create strokes (thicker + more transparent for outer layers)
    for i = 1, layers do
        local s = Instance.new("UIStroke")
        s.Parent = glow
        s.Color = glowColor
        s.Thickness = thicknesses[ math.min(i, #thicknesses) ] or thicknesses[#thicknesses]
        s.Transparency = transparencies[ math.min(i, #transparencies) ] or transparencies[#transparencies]
        -- produce smoother joins
        pcall(function() s.LineJoinMode = Enum.LineJoinMode.Round end)
    end

    return glow
end

-- Pulse a UIStroke (use on the first stroke in the glow container or any stroke)
-- minT, maxT (numbers 0..1), period seconds
function NeonUI.PulseStroke(stroke, minT, maxT, period)
    if not stroke or not stroke.Parent then return nil, "bad_stroke" end
    minT = minT or 0.15
    maxT = maxT or 0.6
    period = period or NeonUI.settings.pulsePeriod
    task.spawn(function()
        while stroke and stroke.Parent do
            pcall(function()
                TweenService:Create(stroke, TweenInfo.new(period/2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = minT}):Play()
            end)
            task.wait(period/2)
            pcall(function()
                TweenService:Create(stroke, TweenInfo.new(period/2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = maxT}):Play()
            end)
            task.wait(period/2)
        end
    end)
    return true
end

-- Remove neon glow previously applied
function NeonUI.RemoveGlow(target)
    local g = target and target:FindFirstChild("__neon_glow")
    if g then pcall(function() g:Destroy() end) end
end

-- Create a neon-styled button (returns the Button instance)
-- props: { parent, size, position, text, color, onClick (function) }
function NeonUI.CreateButton(props)
    props = props or {}
    local parent = props.parent or props.Parent
    if not parent then return nil, "missing_parent" end
    local btn = Instance.new("TextButton")
    btn.Size = props.size or UDim2.new(0,140,0,36)
    btn.Position = props.position or UDim2.new(0,0,0,0)
    btn.BackgroundColor3 = NeonUI.Colors.VOID_BLACK or Color3.fromRGB(8,8,10)
    btn.Text = props.text or "Button"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = props.textSize or 14
    btn.AutoButtonColor = false
    btn.TextColor3 = props.textColor or NeonUI.Colors.TEXT_WHITE
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    safeParent(btn, parent)

    local color = props.color or NeonUI.Colors.NEON_CYAN
    NeonUI.ApplyGradient(btn, color)
    local glow = NeonUI.ApplyGlow(btn, color, props.glowOptions)
    -- pulse the first stroke lightly
    if glow then
        local firstStroke = glow:FindFirstChildOfClass("UIStroke")
        if firstStroke then NeonUI.PulseStroke(firstStroke, 0.25, 0.85, props.pulsePeriod or NeonUI.settings.pulsePeriod) end
    end

    if type(props.onClick) == "function" then
        btn.MouseButton1Click:Connect(function()
            pcall(props.onClick)
        end)
    end
    return btn
end

-- Create a neon toggle (returns frame, and function getState() and setState(bool))
-- props: { parent, text, color, default (bool), onToggle(state) }
function NeonUI.CreateToggle(props)
    props = props or {}
    local parent = props.parent
    if not parent then return nil, "missing_parent" end

    local frame = Instance.new("Frame")
    frame.Size = props.size or UDim2.new(1,0,0,44)
    frame.BackgroundColor3 = props.bg or NeonUI.Colors.ITEM_BG
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)
    safeParent(frame, parent)

    local label = Instance.new("TextLabel", frame)
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0,12,0,0)
    label.Size = UDim2.new(0.6,0,1,0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = props.textSize or 14
    label.TextColor3 = props.textColor or NeonUI.Colors.TEXT_WHITE
    label.Text = props.text or "Toggle"
    label.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0,76,0,30)
    btn.Position = UDim2.new(1,-88,0.5,-15)
    btn.BackgroundColor3 = NeonUI.Colors.VOID_BLACK
    btn.Text = (props.default and "ON" or "OFF") or "OFF"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = (props.default and NeonUI.Colors.VOID_BLACK) or Color3.fromRGB(180,180,180)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    safeParent(btn, frame)

    local color = props.color or NeonUI.Colors.NEON_PINK
    NeonUI.ApplyGradient(btn, color)
    NeonUI.ApplyGlow(btn, color, props.glowOptions)

    local state = props.default and true or false
    btn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            btn.Text = "ON"; btn.TextColor3 = NeonUI.Colors.VOID_BLACK; btn.BackgroundColor3 = color
        else
            btn.Text = "OFF"; btn.TextColor3 = Color3.fromRGB(180,180,180); btn.BackgroundColor3 = NeonUI.Colors.VOID_BLACK
        end
        if type(props.onToggle) == "function" then pcall(props.onToggle, state) end
    end)

    local function getState() return state end
    local function setState(v)
        state = v and true or false
        if state then btn.Text = "ON"; btn.TextColor3 = NeonUI.Colors.VOID_BLACK; btn.BackgroundColor3 = color
        else btn.Text = "OFF"; btn.TextColor3 = Color3.fromRGB(180,180,180); btn.BackgroundColor3 = NeonUI.Colors.VOID_BLACK end
    end

    return frame, getState, setState
end

-- Create a neon slider (returns frame). Props: { parent, name, min, max, default, onChange }
function NeonUI.CreateSlider(props)
    props = props or {}
    local parent = props.parent
    if not parent then return nil, "missing_parent" end

    local frame = Instance.new("Frame")
    frame.Size = props.size or UDim2.new(1,0,0,64)
    frame.BackgroundColor3 = props.bg or NeonUI.Colors.ITEM_BG
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)
    safeParent(frame, parent)

    local label = Instance.new("TextLabel", frame)
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0,12,0,6)
    label.Size = UDim2.new(1,-24,0,20)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextColor3 = NeonUI.Colors.TEXT_WHITE
    local minv = props.min or 0
    local maxv = props.max or 100
    local default = props.default or minv
    label.Text = string.format("%s: %d", (props.name or "Slider"), default)

    local bar = Instance.new("Frame", frame)
    bar.Position = UDim2.new(0,12,0,34)
    bar.Size = UDim2.new(1,-24,0,10)
    bar.BackgroundColor3 = NeonUI.Colors.VOID_BLACK
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)

    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new((default - minv) / math.max((maxv - minv),1), 0, 1, 0)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
    NeonUI.ApplyGradient(fill, props.color or NeonUI.Colors.NEON_PURPLE)
    fill.BackgroundColor3 = props.color or NeonUI.Colors.NEON_PURPLE

    local trigger = Instance.new("TextButton", bar)
    trigger.Size = UDim2.new(1,0,1,0)
    trigger.BackgroundTransparency = 1
    trigger.Text = ""

    local dragging = false
    local function update(input)
        local pos = input.Position.X
        local barPos = bar.AbsolutePosition.X
        local barSize = bar.AbsoluteSize.X
        local pct = math.clamp((pos - barPos) / math.max(barSize, 1), 0, 1)
        local value = math.floor(minv + (maxv - minv) * pct)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        label.Text = string.format("%s: %d", (props.name or "Slider"), value)
        if type(props.onChange) == "function" then pcall(props.onChange, value) end
    end

    trigger.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; update(i) end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then update(i) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

    return frame
end

-- Create a capsule toggle (floating style) - returns the button instance
-- props: { parent (ScreenGui recommended), text, posY, color, width, height, onToggle }
function NeonUI.CreateCapsule(props)
    props = props or {}
    local parent = props.parent or props.Parent
    if not parent then return nil, "missing_parent" end
    local w = props.width or 120
    local h = props.height or 40
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, w, 0, h)
    btn.Position = UDim2.new(0, 20, 0, props.posY or 120)
    btn.BackgroundColor3 = NeonUI.Colors.VOID_BLACK
    btn.AutoButtonColor = false
    btn.Text = ""
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    safeParent(btn, parent)

    local color = props.color or NeonUI.Colors.NEON_CYAN
    local label = Instance.new("TextLabel", btn)
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = (props.text or "Capsule") .. " OFF"
    label.TextColor3 = color
    label.TextSize = math.max(12, math.floor(h/3))

    NeonUI.ApplyGradient(btn, color:Lerp(Color3.new(1,1,1), 0.14), color)
    local glow = NeonUI.ApplyGlow(btn, color)
    if glow then
        local s = glow:FindFirstChildOfClass("UIStroke")
        if s then NeonUI.PulseStroke(s, 0.2, 0.8, NeonUI.settings.pulsePeriod) end
    end

    makeDraggable(btn)

    local toggled = false
    btn.MouseButton1Click:Connect(function()
        toggled = not toggled
        if toggled then
            label.Text = (props.text or "Capsule") .. " ON"
            label.TextColor3 = NeonUI.Colors.VOID_BLACK
            btn.BackgroundColor3 = color
        else
            label.Text = (props.text or "Capsule") .. " OFF"
            label.TextColor3 = color
            btn.BackgroundColor3 = NeonUI.Colors.VOID_BLACK
        end
        if type(props.onToggle) == "function" then pcall(props.onToggle, toggled) end
    end)

    return btn
end

-- Allow runtime theme/palette changes
function NeonUI.SetPalette(tbl)
    if type(tbl) ~= "table" then return nil, "bad_args" end
    for k,v in pairs(tbl) do
        NeonUI.Colors[k] = v
    end
    return true
end

-- Quick helper: auto reduce glow for mobile
function NeonUI.SetMobileMode(enabled)
    NeonUI.settings.mobileMode = enabled and true or false
    if NeonUI.settings.mobileMode then
        NeonUI.settings.defaultGlowLayers = 1
        NeonUI.settings.defaultGlowThickness = {3,8}
        NeonUI.settings.defaultGlowTransparency = {0.8, 0.95}
    else
        NeonUI.settings.defaultGlowLayers = 3
        NeonUI.settings.defaultGlowThickness = {6,12,20}
        NeonUI.settings.defaultGlowTransparency = {0.80, 0.92, 0.98}
    end
end

return NeonUI