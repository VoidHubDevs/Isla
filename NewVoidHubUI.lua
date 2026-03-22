local VoidLib = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

VoidLib.Icons = {
    accessibility = 10709751939, activity = 10709752035, airvent = 10709752131, airplay = 10709752254,
    alarmcheck = 10709752405, alarmclock = 10709752630, alarmclockoff = 10709752508, album = 10709752906,
    alertcircle = 10709752996, alertoctagon = 10709753064, alerttriangle = 10709753149, anchor = 10709761530,
    angry = 10709761629, annoyed = 10709761722, aperture = 10709761813, apple = 10709761889, archive = 10709762233,
    armchair = 10709762327, arrowbigdown = 10747796644, arrowbigleft = 10709762574, arrowbigright = 10709762727,
    arrowbigup = 10709762879, arrowdown = 10709767827, arrowdowncircle = 10709763034, arrowleft = 10709768114,
    arrowright = 10709768347, arrowup = 10709768939, asterisk = 10709769095, atsign = 10709769286,
    award = 10709769406, axe = 10709769508, backpack = 10709769841, ban = 10747360426, ["bar-chart"] = 10709773755,
    ["bar-chart-2"] = 10709770317, battery = 10709774640, batterycharging = 10709774068, batteryfull = 10709774206,
    beaker = 10709774756, bell = 10709775704, bellminus = 10709775241, belloff = 10709775320, bellplus = 10709775448,
    bike = 10709775894, binary = 10709776050, bitcoin = 10709776126, bluetooth = 10709776655, bold = 10747813908,
    bomb = 10709781460, bone = 10709781605, book = 10709781824, bookopen = 10709781717, bookmark = 10709782154,
    bot = 10709782230, box = 10709782497, briefcase = 10709782662, brush = 10709782758, bug = 10709782845,
    building = 10709783051, bus = 10709783137, cake = 10709783217, calculator = 10709783311, calendar = 10709789505,
    camera = 10709789686, car = 10709789810, cast = 10709790097, check = 10709790644, checkcircle = 10709790387,
    checksquare = 10709790537, chevrondown = 10709790948, chevronleft = 10709791281, chevronright = 10709791437,
    chevronup = 10709791523, chrome = 10709797725, circle = 10709798174, clipboard = 10709799288, clock = 10709805144,
    cloud = 10709806740, code = 10709810463, codepen = 10709810534, coffee = 10709810814, cog = 10709810948,
    coins = 10709811110, command = 10709811365, compass = 10709811445, copy = 10709812159, cpu = 10709813383,
    ["credit-card"] = 10709813473, crop = 10709818245, crosshair = 10709818534, crown = 10709818626,
    database = 10709818996, delete = 10709819059, diamond = 10709819149, dice = 10723343321, disc = 10723343537,
    ["dollar-sign"] = 10723343958, download = 10723344270, droplet = 10723344432, edit = 10734883598, eye = 10723346959,
    eyeoff = 10723346871, fastforward = 10723354521, feather = 10723354671, file = 10723374641, filetext = 10723367380,
    filter = 10723375128, flag = 10723375890, flame = 10723376114, flashlight = 10723376471, folder = 10723387563,
    gamepad = 10723395457, ["gamepad2"] = 10723395215, gift = 10723396402, globe = 10723404337, grid = 10723404936,
    hammer = 10723405360, heart = 10723406885, helpcircle = 10723406988, hexagon = 10723407092, home = 10723407389,
    image = 10723415040, inbox = 10723415335, info = 10723415903, joystick = 10723416527, key = 10723416652,
    keyboard = 10723416765, laptop = 10723423881, layers = 10723424505, layout = 10723425376, link = 10723426722,
    list = 10723433811, lock = 10723434711, ["log-in"] = 10723434830, ["log-out"] = 10723434906, mail = 10734885430,
    map = 10734886202, maximize = 10734886735, medal = 10734887072, megaphone = 10734887454, menu = 10734887784,
    messagecircle = 10734888000, messagesquare = 10734888228, mic = 10734888864, minimize = 10734895698,
    minus = 10734896206, monitor = 10734896881, moon = 10734897102, mouse = 10734898592, move = 10734900011,
    music = 10734905958, navigation = 10734906744, package = 10734909540, paperclip = 10734910927, pause = 10734919336,
    percent = 10734919919, phone = 10734921524, piechart = 10734921727, play = 10734923549, playcircle = 10734923214,
    plus = 10734924532, power = 10734930466, printer = 10734930632, radio = 10734931596, refreshccw = 10734933056,
    refreshcw = 10734933222, rocket = 10734934585, save = 10734941499, search = 10734943674, send = 10734943902,
    server = 10734949856, settings = 10734950309, shield = 10734951847, ship = 10734952036, shoppingbag = 10734952273,
    shoppingcart = 10734952479, shuffle = 10734953451, sidebar = 10734954301, skull = 10734962068, slash = 10734962600,
    sliders = 10734963400, smartphone = 10734963940, smile = 10734964441, snowflake = 10734964600, speaker = 10734965419,
    star = 10734966248, sun = 10734974297, sword = 10734975486, table = 10734976230, tablet = 10734976394,
    tag = 10734976528, target = 10734977012, terminal = 10734982144, thermometer = 10734983134, thumbsup = 10734983629,
    thumbsdown = 10734983359, tool = 10747383470, trash = 10747362393, trash2 = 10747362241, trendingup = 10747363465,
    trendingdown = 10747363205, trophy = 10747363809, truck = 10747364031, tv = 10747364593, umbrella = 10747364971,
    unlock = 10747366027, upload = 10747366434, user = 10747373176, users = 10747373426, videooff = 10747374721,
    video = 10747374938, volume = 10747376008, volumex = 10747375880, wallet = 10747376205, wand = 10747376565,
    watch = 10747376722, wifi = 10747382504, wind = 10747382750, wrench = 10747383470, x = 10747384394,
    xcircle = 10747383819, xsquare = 10747384217, zap = 10747384679, zoomin = 10747384552, zoomout = 10747384679
}

VoidLib.Themes = {
    Default = {
        Hub1 = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 25)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(35, 35, 35)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 25))
        }),
        Hub2 = Color3.fromRGB(30, 30, 30),
        Stroke = Color3.fromRGB(60, 60, 60),
        Theme = Color3.fromRGB(88, 101, 242),
        Text = Color3.fromRGB(255, 255, 255),
        DarkText = Color3.fromRGB(180, 180, 180),
        ToggleOn = Color3.fromRGB(88, 101, 242),
        ToggleOff = Color3.fromRGB(60, 60, 60),
        ToggleKnobOn = Color3.fromRGB(255, 255, 255),
        ToggleKnobOff = Color3.fromRGB(180, 180, 180),
        BorderThickness = 1,
        BorderColor = Color3.fromRGB(60, 60, 60),
    },
    QuangHuy = {
        Hub1 = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)),
            ColorSequenceKeypoint.new(0.25, Color3.fromRGB(147, 51, 234)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(153, 50, 204)),
            ColorSequenceKeypoint.new(0.75, Color3.fromRGB(186, 85, 211)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(138, 43, 226))
        }),
        Hub2 = Color3.fromRGB(25, 0, 50),
        Stroke = Color3.fromRGB(186, 85, 211),
        Theme = Color3.fromRGB(147, 51, 234),
        Text = Color3.fromRGB(230, 200, 255),
        DarkText = Color3.fromRGB(180, 150, 220),
        ToggleOn = Color3.fromRGB(147, 51, 234),
        ToggleOff = Color3.fromRGB(60, 30, 90),
        ToggleKnobOn = Color3.fromRGB(230, 200, 255),
        ToggleKnobOff = Color3.fromRGB(150, 120, 190),
        BorderThickness = 1.5,
        BorderColor = Color3.fromRGB(186, 85, 211),
    },
    Midnight = {
        Hub1 = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 15, 25)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20, 20, 35)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 25))
        }),
        Hub2 = Color3.fromRGB(20, 20, 30),
        Stroke = Color3.fromRGB(70, 70, 100),
        Theme = Color3.fromRGB(100, 100, 255),
        Text = Color3.fromRGB(220, 220, 255),
        DarkText = Color3.fromRGB(150, 150, 200),
        ToggleOn = Color3.fromRGB(100, 100, 255),
        ToggleOff = Color3.fromRGB(40, 40, 60),
        ToggleKnobOn = Color3.fromRGB(220, 220, 255),
        ToggleKnobOff = Color3.fromRGB(120, 120, 160),
        BorderThickness = 1.2,
        BorderColor = Color3.fromRGB(70, 70, 100),
    },
    Crimson = {
        Hub1 = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 10, 10)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 15, 15)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 10, 10))
        }),
        Hub2 = Color3.fromRGB(50, 12, 12),
        Stroke = Color3.fromRGB(150, 50, 50),
        Theme = Color3.fromRGB(220, 50, 50),
        Text = Color3.fromRGB(255, 220, 220),
        DarkText = Color3.fromRGB(200, 150, 150),
        ToggleOn = Color3.fromRGB(220, 50, 50),
        ToggleOff = Color3.fromRGB(80, 25, 25),
        ToggleKnobOn = Color3.fromRGB(255, 220, 220),
        ToggleKnobOff = Color3.fromRGB(180, 120, 120),
        BorderThickness = 1.5,
        BorderColor = Color3.fromRGB(150, 50, 50),
    },
    Ocean = {
        Hub1 = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 30, 50)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 45, 70)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 30, 50))
        }),
        Hub2 = Color3.fromRGB(12, 35, 55),
        Stroke = Color3.fromRGB(50, 150, 200),
        Theme = Color3.fromRGB(0, 180, 220),
        Text = Color3.fromRGB(220, 250, 255),
        DarkText = Color3.fromRGB(150, 200, 220),
        ToggleOn = Color3.fromRGB(0, 180, 220),
        ToggleOff = Color3.fromRGB(25, 60, 80),
        ToggleKnobOn = Color3.fromRGB(220, 250, 255),
        ToggleKnobOff = Color3.fromRGB(120, 170, 190),
        BorderThickness = 1.3,
        BorderColor = Color3.fromRGB(50, 150, 200),
    },
    Forest = {
        Hub1 = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 40, 20)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20, 55, 30)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 40, 20))
        }),
        Hub2 = Color3.fromRGB(18, 45, 25),
        Stroke = Color3.fromRGB(60, 160, 80),
        Theme = Color3.fromRGB(50, 200, 100),
        Text = Color3.fromRGB(230, 255, 235),
        DarkText = Color3.fromRGB(160, 210, 175),
        ToggleOn = Color3.fromRGB(50, 200, 100),
        ToggleOff = Color3.fromRGB(30, 70, 40),
        ToggleKnobOn = Color3.fromRGB(230, 255, 235),
        ToggleKnobOff = Color3.fromRGB(130, 180, 145),
        BorderThickness = 1.2,
        BorderColor = Color3.fromRGB(60, 160, 80),
    },
    Golden = {
        Hub1 = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 35, 20)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(55, 48, 28)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 35, 20))
        }),
        Hub2 = Color3.fromRGB(48, 42, 25),
        Stroke = Color3.fromRGB(180, 150, 80),
        Theme = Color3.fromRGB(255, 200, 80),
        Text = Color3.fromRGB(255, 245, 220),
        DarkText = Color3.fromRGB(210, 190, 150),
        ToggleOn = Color3.fromRGB(255, 200, 80),
        ToggleOff = Color3.fromRGB(80, 70, 40),
        ToggleKnobOn = Color3.fromRGB(255, 245, 220),
        ToggleKnobOff = Color3.fromRGB(180, 165, 130),
        BorderThickness = 1.5,
        BorderColor = Color3.fromRGB(180, 150, 80),
    }
}

VoidLib.CurrentTheme = VoidLib.Themes.Default

function VoidLib:SetTheme(themeName)
    if VoidLib.Themes[themeName] then
        VoidLib.CurrentTheme = VoidLib.Themes[themeName]
        return true
    end
    return false
end

function VoidLib:GetTheme()
    return VoidLib.CurrentTheme
end

function VoidLib:CreateWindow(config)
    local title = config.Title or "VoidHub"
    local subtitle = config.SubTitle or ""
    local theme = config.Theme or "Default"
    
    if VoidLib.Themes[theme] then
        VoidLib.CurrentTheme = VoidLib.Themes[theme]
    end
    
    local t = VoidLib.CurrentTheme
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "VoidHubUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = game.CoreGui
    
    local oldUI = game.CoreGui:FindFirstChild("VoidHubUI")
    if oldUI and oldUI ~= ScreenGui then
        oldUI:Destroy()
    end
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 600, 0, 400)
    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    MainFrame.BackgroundColor3 = t.Hub2
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = MainFrame
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = t.BorderColor
    Stroke.Thickness = t.BorderThickness
    Stroke.Parent = MainFrame
    
    local Gradient = Instance.new("UIGradient")
    Gradient.Color = t.Hub1
    Gradient.Rotation = 45
    Gradient.Parent = MainFrame
    
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 35)
    TopBar.BackgroundColor3 = t.Theme
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame
    
    local TopBarCorner = Instance.new("UICorner")
    TopBarCorner.CornerRadius = UDim.new(0, 8)
    TopBarCorner.Parent = TopBar
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "Title"
    TitleLabel.Size = UDim2.new(0, 200, 1, 0)
    TitleLabel.Position = UDim2.new(0, 15, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title
    TitleLabel.TextColor3 = t.Text
    TitleLabel.TextSize = 16
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TopBar
    
    local SubTitleLabel = Instance.new("TextLabel")
    SubTitleLabel.Name = "SubTitle"
    SubTitleLabel.Size = UDim2.new(0, 100, 0, 20)
    SubTitleLabel.Position = UDim2.new(0, 15, 0.5, 0)
    SubTitleLabel.BackgroundTransparency = 1
    SubTitleLabel.Text = subtitle
    SubTitleLabel.TextColor3 = t.DarkText
    SubTitleLabel.TextSize = 12
    SubTitleLabel.Font = Enum.Font.Gotham
    SubTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubTitleLabel.Parent = TopBar
    
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "Close"
    CloseBtn.Size = UDim2.new(0, 25, 0, 25)
    CloseBtn.Position = UDim2.new(1, -10, 0.5, 0)
    CloseBtn.AnchorPoint = Vector2.new(1, 0.5)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 14
    CloseBtn.Parent = TopBar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 4)
    CloseCorner.Parent = CloseBtn
    
    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
    
    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Name = "Minimize"
    MinimizeBtn.Size = UDim2.new(0, 25, 0, 25)
    MinimizeBtn.Position = UDim2.new(1, -40, 0.5, 0)
    MinimizeBtn.AnchorPoint = Vector2.new(1, 0.5)
    MinimizeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    MinimizeBtn.Text = "-"
    MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinimizeBtn.Font = Enum.Font.GothamBold
    MinimizeBtn.TextSize = 14
    MinimizeBtn.Parent = TopBar
    
    local MinimizeCorner = Instance.new("UICorner")
    MinimizeCorner.CornerRadius = UDim.new(0, 4)
    MinimizeCorner.Parent = MinimizeBtn
    
    local minimized = false
    MinimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        for _, child in pairs(MainFrame:GetChildren()) do
            if child.Name ~= "TopBar" then
                child.Visible = not minimized
            end
        end
        MinimizeBtn.Text = minimized and "+" or "-"
    end)
    
    local TabContainer = Instance.new("Frame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(0, 140, 1, -35)
    TabContainer.Position = UDim2.new(0, 0, 0, 35)
    TabContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    TabContainer.BackgroundTransparency = 0.5
    TabContainer.BorderSizePixel = 0
    TabContainer.Parent = MainFrame
    
    local TabList = Instance.new("UIListLayout")
    TabList.Padding = UDim.new(0, 5)
    TabList.SortOrder = Enum.SortOrder.LayoutOrder
    TabList.Parent = TabContainer
    
    local TabPadding = Instance.new("UIPadding")
    TabPadding.PaddingTop = UDim.new(0, 10)
    TabPadding.PaddingLeft = UDim.new(0, 10)
    TabPadding.PaddingRight = UDim.new(0, 10)
    TabPadding.Parent = TabContainer
    
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, -150, 1, -45)
    ContentContainer.Position = UDim2.new(0, 145, 0, 40)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = MainFrame
    
    local Window = {
        ScreenGui = ScreenGui,
        MainFrame = MainFrame,
        TabContainer = TabContainer,
        ContentContainer = ContentContainer,
        Tabs = {},
        CurrentTab = nil,
        Theme = t
    }
    
    local dragging = false
    local dragInput, dragStart, startPos
    
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    
    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    return Window
end

function VoidLib:CreateTab(window, name, iconId)
    local t = VoidLib.CurrentTheme
    
    local TabButton = Instance.new("TextButton")
    TabButton.Name = name .. "Tab"
    TabButton.Size = UDim2.new(1, 0, 0, 30)
    TabButton.BackgroundColor3 = t.Hub2
    TabButton.Text = name
    TabButton.TextColor3 = t.Text
    TabButton.TextSize = 12
    TabButton.Font = Enum.Font.GothamMedium
    TabButton.Parent = window.TabContainer
    
    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = UDim.new(0, 6)
    TabCorner.Parent = TabButton
    
    if iconId then
        local Icon = Instance.new("ImageLabel")
        Icon.Name = "Icon"
        Icon.Size = UDim2.new(0, 16, 0, 16)
        Icon.Position = UDim2.new(0, 8, 0.5, 0)
        Icon.AnchorPoint = Vector2.new(0, 0.5)
        Icon.BackgroundTransparency = 1
        Icon.Image = "rbxassetid://" .. iconId
        Icon.ImageColor3 = t.Text
        Icon.Parent = TabButton
        TabButton.Text = "    " .. name
    end
    
    local Content = Instance.new("ScrollingFrame")
    Content.Name = name .. "Content"
    Content.Size = UDim2.new(1, 0, 1, 0)
    Content.BackgroundTransparency = 1
    Content.BorderSizePixel = 0
    Content.ScrollBarThickness = 4
    Content.ScrollBarImageColor3 = t.Theme
    Content.Visible = false
    Content.CanvasSize = UDim2.new(0, 0, 0, 0)
    Content.Parent = window.ContentContainer
    
    local ContentList = Instance.new("UIListLayout")
    ContentList.Padding = UDim.new(0, 8)
    ContentList.SortOrder = Enum.SortOrder.LayoutOrder
    ContentList.Parent = Content
    
    local ContentPadding = Instance.new("UIPadding")
    ContentPadding.PaddingTop = UDim.new(0, 10)
    ContentPadding.PaddingLeft = UDim.new(0, 10)
    ContentPadding.PaddingRight = UDim.new(0, 10)
    ContentPadding.PaddingBottom = UDim.new(0, 10)
    ContentPadding.Parent = Content
    
    ContentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Content.CanvasSize = UDim2.new(0, 0, 0, ContentList.AbsoluteContentSize.Y + 20)
    end)
    
    local Tab = {
        Button = TabButton,
        Content = Content,
        Name = name
    }
    
    table.insert(window.Tabs, Tab)
    
    TabButton.MouseButton1Click:Connect(function()
        for _, t in pairs(window.Tabs) do
            t.Content.Visible = false
            t.Button.BackgroundColor3 = VoidLib.CurrentTheme.Hub2
        end
        Content.Visible = true
        TabButton.BackgroundColor3 = VoidLib.CurrentTheme.Theme
        window.CurrentTab = Tab
    end)
    
    if #window.Tabs == 1 then
        TabButton.BackgroundColor3 = t.Theme
        Content.Visible = true
        window.CurrentTab = Tab
    end
    
    return Tab
end

function VoidLib:CreateSection(tab, title)
    local t = VoidLib.CurrentTheme
    
    local Section = Instance.new("Frame")
    Section.Name = title .. "Section"
    Section.Size = UDim2.new(1, 0, 0, 30)
    Section.BackgroundTransparency = 1
    Section.Parent = tab.Content
    
    local SectionTitle = Instance.new("TextLabel")
    SectionTitle.Name = "Title"
    SectionTitle.Size = UDim2.new(1, 0, 0, 25)
    SectionTitle.BackgroundTransparency = 1
    SectionTitle.Text = title
    SectionTitle.TextColor3 = t.Theme
    SectionTitle.TextSize = 14
    SectionTitle.Font = Enum.Font.GothamBold
    SectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    SectionTitle.Parent = Section
    
    local Underline = Instance.new("Frame")
    Underline.Name = "Underline"
    Underline.Size = UDim2.new(1, 0, 0, 2)
    Underline.Position = UDim2.new(0, 0, 1, -5)
    Underline.BackgroundColor3 = t.Stroke
    Underline.BorderSizePixel = 0
    Underline.Parent = Section
    
    return Section
end

function VoidLib:CreateToggle(tab, config)
    local t = VoidLib.CurrentTheme
    local name = config.Name or "Toggle"
    local default = config.Default or false
    local callback = config.Callback or function() end
    
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Name = name .. "Toggle"
    ToggleFrame.Size = UDim2.new(1, 0, 0, 35)
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    ToggleFrame.BorderSizePixel = 0
    ToggleFrame.Parent = tab.Content
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 6)
    ToggleCorner.Parent = ToggleFrame
    
    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(1, -60, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = t.Text
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = ToggleFrame
    
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Name = "Toggle"
    ToggleBtn.Size = UDim2.new(0, 40, 0, 20)
    ToggleBtn.Position = UDim2.new(1, -10, 0.5, 0)
    ToggleBtn.AnchorPoint = Vector2.new(1, 0.5)
    ToggleBtn.BackgroundColor3 = default and t.ToggleOn or t.ToggleOff
    ToggleBtn.Text = ""
    ToggleBtn.Parent = ToggleFrame
    
    local ToggleBtnCorner = Instance.new("UICorner")
    ToggleBtnCorner.CornerRadius = UDim.new(0.5, 0)
    ToggleBtnCorner.Parent = ToggleBtn
    
    local Knob = Instance.new("Frame")
    Knob.Name = "Knob"
    Knob.Size = UDim2.new(0, 16, 0, 16)
    Knob.Position = default and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
    Knob.AnchorPoint = Vector2.new(0, 0.5)
    Knob.BackgroundColor3 = default and t.ToggleKnobOn or t.ToggleKnobOff
    Knob.BorderSizePixel = 0
    Knob.Parent = ToggleBtn
    
    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(0.5, 0)
    KnobCorner.Parent = Knob
    
    local enabled = default
    
    ToggleBtn.MouseButton1Click:Connect(function()
        enabled = not enabled
        TweenService:Create(Knob, TweenInfo.new(0.2), {
            Position = enabled and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
            BackgroundColor3 = enabled and t.ToggleKnobOn or t.ToggleKnobOff
        }):Play()
        TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = enabled and t.ToggleOn or t.ToggleOff
        }):Play()
        callback(enabled)
    end)
    
    return ToggleFrame, function() return enabled end, function(v) 
        enabled = v
        Knob.Position = enabled and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
        Knob.BackgroundColor3 = enabled and t.ToggleKnobOn or t.ToggleKnobOff
        ToggleBtn.BackgroundColor3 = enabled and t.ToggleOn or t.ToggleOff
    end
end

function VoidLib:CreateButton(tab, config)
    local t = VoidLib.CurrentTheme
    local name = config.Name or "Button"
    local callback = config.Callback or function() end
    
    local Button = Instance.new("TextButton")
    Button.Name = name .. "Button"
    Button.Size = UDim2.new(1, 0, 0, 35)
    Button.BackgroundColor3 = t.Theme
    Button.Text = name
    Button.TextColor3 = t.Text
    Button.TextSize = 12
    Button.Font = Enum.Font.GothamBold
    Button.Parent = tab.Content
    
    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 6)
    ButtonCorner.Parent = Button
    
    Button.MouseButton1Click:Connect(callback)
    
    Button.MouseEnter:Connect(function()
        local c = t.Theme
        TweenService:Create(Button, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(math.min(c.R * 255 + 20, 255), math.min(c.G * 255 + 20, 255), math.min(c.B * 255 + 20, 255))
        }):Play()
    end)
    
    Button.MouseLeave:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = t.Theme}):Play()
    end)
    
    return Button
end

function VoidLib:CreateDropdown(tab, config)
    local t = VoidLib.CurrentTheme
    local name = config.Name or "Dropdown"
    local options = config.Options or {}
    local default = config.Default or options[1]
    local callback = config.Callback or function() end
    
    local DropdownFrame = Instance.new("Frame")
    DropdownFrame.Name = name .. "Dropdown"
    DropdownFrame.Size = UDim2.new(1, 0, 0, 35)
    DropdownFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    DropdownFrame.BorderSizePixel = 0
    DropdownFrame.Parent = tab.Content
    
    local DropdownCorner = Instance.new("UICorner")
    DropdownCorner.CornerRadius = UDim.new(0, 6)
    DropdownCorner.Parent = DropdownFrame
    
    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(0.5, 0, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = t.Text
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = DropdownFrame
    
    local Selected = Instance.new("TextButton")
    Selected.Name = "Selected"
    Selected.Size = UDim2.new(0.4, 0, 0, 25)
    Selected.Position = UDim2.new(1, -10, 0.5, 0)
    Selected.AnchorPoint = Vector2.new(1, 0.5)
    Selected.BackgroundColor3 = t.Hub2
    Selected.Text = default or "Select..."
    Selected.TextColor3 = t.Text
    Selected.TextSize = 11
    Selected.Font = Enum.Font.GothamMedium
    Selected.Parent = DropdownFrame
    
    local SelectedCorner = Instance.new("UICorner")
    SelectedCorner.CornerRadius = UDim.new(0, 4)
    SelectedCorner.Parent = Selected
    
    local selectedValue = default
    
    Selected.MouseButton1Click:Connect(function()
        local currentIndex = table.find(options, selectedValue) or 0
        local nextIndex = currentIndex + 1
        if nextIndex > #options then nextIndex = 1 end
        selectedValue = options[nextIndex]
        Selected.Text = selectedValue
        callback(selectedValue)
    end)
    
    return DropdownFrame, function() return selectedValue end, function(v)
        selectedValue = v
        Selected.Text = selectedValue
    end
end

function VoidLib:CreateSlider(tab, config)
    local t = VoidLib.CurrentTheme
    local name = config.Name or "Slider"
    local min = config.Min or 0
    local max = config.Max or 100
    local default = config.Default or min
    local callback = config.Callback or function() end
    
    local SliderFrame = Instance.new("Frame")
    SliderFrame.Name = name .. "Slider"
    SliderFrame.Size = UDim2.new(1, 0, 0, 50)
    SliderFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    SliderFrame.BorderSizePixel = 0
    SliderFrame.Parent = tab.Content
    
    local SliderCorner = Instance.new("UICorner")
    SliderCorner.CornerRadius = UDim.new(0, 6)
    SliderCorner.Parent = SliderFrame
    
    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(1, -20, 0, 20)
    Label.Position = UDim2.new(0, 10, 0, 5)
    Label.BackgroundTransparency = 1
    Label.Text = name .. ": " .. default
    Label.TextColor3 = t.Text
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = SliderFrame
    
    local SliderBg = Instance.new("Frame")
    SliderBg.Name = "Background"
    SliderBg.Size = UDim2.new(1, -20, 0, 8)
    SliderBg.Position = UDim2.new(0, 10, 0, 30)
    SliderBg.BackgroundColor3 = t.ToggleOff
    SliderBg.BorderSizePixel = 0
    SliderBg.Parent = SliderFrame
    
    local SliderBgCorner = Instance.new("UICorner")
    SliderBgCorner.CornerRadius = UDim.new(0.5, 0)
    SliderBgCorner.Parent = SliderBg
    
    local Fill = Instance.new("Frame")
    Fill.Name = "Fill"
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = t.Theme
    Fill.BorderSizePixel = 0
    Fill.Parent = SliderBg
    
    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(0.5, 0)
    FillCorner.Parent = Fill
    
    local Knob = Instance.new("Frame")
    Knob.Name = "Knob"
    Knob.Size = UDim2.new(0, 14, 0, 14)
    Knob.Position = UDim2.new((default - min) / (max - min), -7, 0.5, 0)
    Knob.AnchorPoint = Vector2.new(0, 0.5)
    Knob.BackgroundColor3 = t.ToggleKnobOn
    Knob.BorderSizePixel = 0
    Knob.Parent = SliderBg
    
    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(0.5, 0)
    KnobCorner.Parent = Knob
    
    local dragging = false
    local value = default
    
    SliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = math.clamp((input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1)
            value = math.floor(min + (max - min) * pos)
            Fill.Size = UDim2.new(pos, 0, 1, 0)
            Knob.Position = UDim2.new(pos, -7, 0.5, 0)
            Label.Text = name .. ": " .. value
            callback(value)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    return SliderFrame, function() return value end, function(v)
        value = math.clamp(v, min, max)
        local pos = (value - min) / (max - min)
        Fill.Size = UDim2.new(pos, 0, 1, 0)
        Knob.Position = UDim2.new(pos, -7, 0.5, 0)
        Label.Text = name .. ": " .. value
    end
end

function VoidLib:CreateLabel(tab, config)
    local t = VoidLib.CurrentTheme
    local text = config.Text or "Label"
    
    local LabelFrame = Instance.new("Frame")
    LabelFrame.Name = "LabelFrame"
    LabelFrame.Size = UDim2.new(1, 0, 0, 30)
    LabelFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    LabelFrame.BorderSizePixel = 0
    LabelFrame.Parent = tab.Content
    
    local LabelCorner = Instance.new("UICorner")
    LabelCorner.CornerRadius = UDim.new(0, 6)
    LabelCorner.Parent = LabelFrame
    
    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(1, -20, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = t.Text
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextWrapped = true
    Label.Parent = LabelFrame
    
    return LabelFrame, Label
end

function VoidLib:CreateInput(tab, config)
    local t = VoidLib.CurrentTheme
    local name = config.Name or "Input"
    local default = config.Default or ""
    local placeholder = config.Placeholder or "Enter text..."
    local callback = config.Callback or function() end
    
    local InputFrame = Instance.new("Frame")
    InputFrame.Name = name .. "Input"
    InputFrame.Size = UDim2.new(1, 0, 0, 35)
    InputFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    InputFrame.BorderSizePixel = 0
    InputFrame.Parent = tab.Content
    
    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 6)
    InputCorner.Parent = InputFrame
    
    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(0.4, 0, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = t.Text
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = InputFrame
    
    local TextBox = Instance.new("TextBox")
    TextBox.Name = "TextBox"
    TextBox.Size = UDim2.new(0.5, 0, 0, 25)
    TextBox.Position = UDim2.new(1, -10, 0.5, 0)
    TextBox.AnchorPoint = Vector2.new(1, 0.5)
    TextBox.BackgroundColor3 = t.Hub2
    TextBox.Text = default
    TextBox.PlaceholderText = placeholder
    TextBox.TextColor3 = t.Text
    TextBox.PlaceholderColor3 = t.DarkText
    TextBox.TextSize = 11
    TextBox.Font = Enum.Font.GothamMedium
    TextBox.ClearTextOnFocus = false
    TextBox.Parent = InputFrame
    
    local TextBoxCorner = Instance.new("UICorner")
    TextBoxCorner.CornerRadius = UDim.new(0, 4)
    TextBoxCorner.Parent = TextBox
    
    TextBox.FocusLost:Connect(function()
        callback(TextBox.Text)
    end)
    
    return InputFrame, function() return TextBox.Text end, function(v)
        TextBox.Text = v
    end
end

function VoidLib:Notify(title, text, duration)
    duration = duration or 3
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration
        })
    end)
end

return VoidLib
