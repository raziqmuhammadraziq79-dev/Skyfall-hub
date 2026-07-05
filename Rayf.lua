-- SKYFALL CUSTOM UI ENGINE v1.0
-- Buatan Sendiri | Draggable | Minimize | No External Lib

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local LP = Players.LocalPlayer

-- KONFIGURASI TEMA (GANTI SESUAI SELERA LU)
local Theme = {
    Main = Color3.fromRGB(20, 20, 25),
    Sidebar = Color3.fromRGB(25, 25, 30),
    Accent = Color3.fromRGB(80, 120, 255), -- Warna Biru Keren
    Text = Color3.fromRGB(240, 240, 240),
    DimText = Color3.fromRGB(150, 150, 150),
    ToggleOn = Color3.fromRGB(50, 200, 100),
    ToggleOff = Color3.fromRGB(60, 60, 60)
}

-- CORE UI BUILDER
local function CreateInstance(Class, Props)
    local Obj = Instance.new(Class)
    for k,v in pairs(Props) do Obj[k] = v end
    return Obj
end

-- SCREEN GUI SETUP
local ScreenGui = CreateInstance("ScreenGui", {Parent = LP:FindFirstChildWhichIsA("PlayerGui"), ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
local MainFrame = CreateInstance("Frame", {
    Parent = ScreenGui, Size = UDim2.new(0, 650, 0, 450), Position = UDim2.new(0.5, -325, 0.5, -225),
    BackgroundColor3 = Theme.Main, ClipsDescendants = true
})
CreateInstance("UICorner", {Parent = MainFrame, CornerRadius = UDim.new(0, 8)})
CreateInstance("UIStroke", {Parent = MainFrame, Color = Color3.fromRGB(40,40,40), Thickness = 1})

-- TITLE BAR (DRAGGABLE AREA)
local TitleBar = CreateInstance("Frame", {Parent = MainFrame, Size = UDim2.new(1, 0, 0, 35), BackgroundTransparency = 1})
local TitleLabel = CreateInstance("TextLabel", {
    Parent = TitleBar, Size = UDim2.new(1, -80, 1, 0), Position = UDim2.new(0, 15, 0, 0),
    BackgroundTransparency = 1, Text = "SKYFALL HUB v30.2 [CUSTOM]", TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left
})

-- MINIMIZE BUTTON
local MinBtn = CreateInstance("TextButton", {
    Parent = TitleBar, Size = UDim2.new(0, 35, 0, 35), Position = UDim2.new(1, -35, 0, 0),
    BackgroundTransparency = 1, Text = "_", TextColor3 = Theme.DimText, Font = Enum.Font.GothamBold, TextSize = 18
})
local IsMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    IsMinimized = not IsMinimized
    TS:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = IsMinimized and UDim2.new(0, 650, 0, 35) or UDim2.new(0, 650, 0, 450)}):Play()
    MinBtn.Text = IsMinimized and "+" or "_"
end)

-- DRAG LOGIC (SMOOTH & RESPONSIVE)
local Dragging, DragStart, StartPos = false, nil, nil
TitleBar.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
        Dragging, DragStart, StartPos = true, Input.Position, MainFrame.Position
        Input.Changed:Connect(function() if Input.UserInputState == Enum.UserInputState.End then Dragging = false end end)
    end
end)
UIS.InputChanged:Connect(function(Input)
    if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
        local Delta = Input.Position - DragStart
        MainFrame.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
    end
end)

-- SIDEBAR & CONTENT AREA
local Sidebar = CreateInstance("Frame", {Parent = MainFrame, Size = UDim2.new(0, 140, 1, -35), Position = UDim2.new(0, 0, 0, 35), BackgroundColor3 = Theme.Sidebar})
local ContentArea = CreateInstance("Frame", {Parent = MainFrame, Size = UDim2.new(1, -140, 1, -35), Position = UDim2.new(0, 140, 0, 35), BackgroundTransparency = 1})
local TabListLayout = CreateInstance("UIListLayout", {Parent = Sidebar, Padding = UDim.new(0, 2)})

-- TAB SYSTEM ENGINE
local Tabs = {}
local ActiveTab = nil

local function AddTab(Name)
    local TabBtn = CreateInstance("TextButton", {
        Parent = Sidebar, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1,
        Text = "   " .. Name, TextColor3 = Theme.DimText, Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left
    })
    local TabContent = CreateInstance("ScrollingFrame", {
        Parent = ContentArea, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        ScrollBarThickness = 4, Visible = false
    })
    CreateInstance("UIListLayout", {Parent = TabContent, Padding = UDim.new(0, 5)})
    CreateInstance("UIPadding", {Parent = TabContent, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10)})
    
    TabBtn.MouseButton1Click:Connect(function()
        if ActiveTab then 
            ActiveTab.Btn.TextColor3 = Theme.DimText
            ActiveTab.Content.Visible = false
        end
        TabBtn.TextColor3 = Theme.Accent
        TabContent.Visible = true
        ActiveTab = {Btn = TabBtn, Content = TabContent}
    end)
    
    Tabs[Name] = {Btn = TabBtn, Content = TabContent}
    if not ActiveTab then TabBtn.TextColor3 = Theme.Accent; TabContent.Visible = true; ActiveTab = {Btn = TabBtn, Content = TabContent} end
    return TabContent
end

-- COMPONENT BUILDERS (BUTTON, TOGGLE, SLIDER)
local function AddButton(Parent, Text, Callback)
    local Btn = CreateInstance("TextButton", {
        Parent = Parent, Size = UDim2.new(1, -20, 0, 35), BackgroundColor3 = Theme.Sidebar,
        Text = Text, TextColor3 = Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 13
    })
    CreateInstance("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 4)})
    Btn.MouseButton1Click:Connect(Callback)
    return Btn
end

local function AddToggle(Parent, Text, Default, Callback)
    local State = Default
    local Frame = CreateInstance("Frame", {Parent = Parent, Size = UDim2.new(1, -20, 0, 35), BackgroundColor3 = Theme.Sidebar})
    CreateInstance("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 4)})
    CreateInstance("TextLabel", {Parent = Frame, Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = Text, TextColor3 = Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left})
    
    local Indicator = CreateInstance("Frame", {Parent = Frame, Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -30, 0.5, -10), BackgroundColor3 = State and Theme.ToggleOn or Theme.ToggleOff})
    CreateInstance("UICorner", {Parent = Indicator, CornerRadius = UDim.new(1, 0)})
    
    Frame.InputBegan:Connect(function(I)
        if I.UserInputType == Enum.UserInputType.MouseButton1 then
            State = not State
            TS:Create(Indicator, TweenInfo.new(0.2), {BackgroundColor3 = State and Theme.ToggleOn or Theme.ToggleOff}):Play()
            Callback(State)
        end
    end)
end

-- CONTOH PENGGUNAAN (TAMBAHKAN FITUR LU DISINI)
local MoveTab = AddTab("Movement")
AddToggle(MoveTab, "Fly (WASD + Space)", false, function(s) print("Fly:", s) end)
AddButton(MoveTab, "TP to Nearest Player", function() print("Teleporting...") end)

local CombatTab = AddTab("Combat")
AddToggle(CombatTab, "Silent Aimbot", false, function(s) print("Aimbot:", s) end)

print("[SKYFALL CUSTOM UI] Loaded Successfully!")
