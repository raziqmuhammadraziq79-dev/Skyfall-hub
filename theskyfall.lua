-- =============================================
-- THESKYFALL HUB - All In One
-- Buatan: [GANTI NAMA LU]
-- Executor: Delta Supported
-- =============================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

print("🚀 Theskyfall Hub Loading...")

-- Intro Popup
local IntroGui = Instance.new("ScreenGui")
IntroGui.ResetOnSpawn = false
IntroGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local IntroFrame = Instance.new("Frame")
IntroFrame.Size = UDim2.new(0, 420, 0, 280)
IntroFrame.Position = UDim2.new(0.5, -210, 0.5, -140)
IntroFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
IntroFrame.BorderSizePixel = 0
IntroFrame.Parent = IntroGui

local IntroTitle = Instance.new("TextLabel")
IntroTitle.Size = UDim2.new(1, 0, 0, 80)
IntroTitle.BackgroundTransparency = 1
IntroTitle.Text = "THESKYFALL HUB"
IntroTitle.TextColor3 = Color3.fromRGB(0, 200, 255)
IntroTitle.TextScaled = true
IntroTitle.Font = Enum.Font.GothamBlack
IntroTitle.Parent = IntroFrame

local IntroSub = Instance.new("TextLabel")
IntroSub.Size = UDim2.new(1, 0, 0, 60)
IntroSub.Position = UDim2.new(0, 0, 0, 80)
IntroSub.BackgroundTransparency = 1
IntroSub.Text = "All-In-One Professional\nBuatan: [GANTI NAMA LU]"
IntroSub.TextColor3 = Color3.fromRGB(200, 200, 200)
IntroSub.TextScaled = true
IntroSub.Font = Enum.Font.Gotham
IntroSub.Parent = IntroFrame

local IntroBtn = Instance.new("TextButton")
IntroBtn.Size = UDim2.new(0.6, 0, 0, 50)
IntroBtn.Position = UDim2.new(0.2, 0, 0.7, 0)
IntroBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
IntroBtn.Text = "LOAD HUB"
IntroBtn.TextColor3 = Color3.new(1,1,1)
IntroBtn.TextScaled = true
IntroBtn.Font = Enum.Font.GothamBold
IntroBtn.Parent = IntroFrame

-- Main Hub
local MainGui = Instance.new("ScreenGui")
MainGui.ResetOnSpawn = false
MainGui.Enabled = false
MainGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 450, 0, 520)
MainFrame.Position = UDim2.new(0.5, -225, 0.5, -260)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = MainGui

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 60)
TitleBar.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
TitleBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "THESKYFALL HUB"
Title.TextColor3 = Color3.new(1,1,1)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBlack
Title.Parent = TitleBar

local Scrolling = Instance.new("ScrollingFrame")
Scrolling.Size = UDim2.new(1, -20, 1, -100)
Scrolling.Position = UDim2.new(0, 10, 0, 70)
Scrolling.BackgroundTransparency = 1
Scrolling.ScrollBarThickness = 8
Scrolling.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 8)
UIList.Parent = Scrolling

local function CreateButton(text, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 55)
    Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Btn.Text = text
    Btn.TextColor3 = Color3.new(1,1,1)
    Btn.TextScaled = true
    Btn.Font = Enum.Font.GothamSemibold
    Btn.Parent = Scrolling
    Btn.MouseButton1Click:Connect(callback)
    return Btn
end

local flying, noclipping, espEnabled = false, false, false
local speed = 70
local espBoxes = {}
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Camera = workspace.CurrentCamera

CreateButton("🔥 Toggle Fly (F)", function()
    flying = not flying
    print("Fly:", flying and "ON" or "OFF")
    if flying then
        spawn(function()
            local bv = Instance.new("BodyVelocity")
            local bg = Instance.new("BodyGyro")
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bv.Parent = Character.HumanoidRootPart
            bg.Parent = Character.HumanoidRootPart
            while flying do
                local dir = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
                bv.Velocity = dir.Unit * speed
                bg.CFrame = Camera.CFrame
                RunService.Heartbeat:Wait()
            end
            bv:Destroy()
            bg:Destroy()
        end)
    end
end)

CreateButton("👻 Toggle NoClip", function()
    noclipping = not noclipping
    print("NoClip:", noclipping and "ON" or "OFF")
end)

CreateButton("👁️ Toggle ESP Players", function()
    espEnabled = not espEnabled
    print("ESP:", espEnabled and "ON" or "OFF")
    if espEnabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p \~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local box = Instance.new("BoxHandleAdornment")
                box.Adornee = p.Character.HumanoidRootPart
                box.Size = Vector3.new(4,6,2)
                box.Color3 = Color3.new(1,0,0)
                box.Transparency = 0.4
                box.AlwaysOnTop = true
                box.Parent = p.Character.HumanoidRootPart
                espBoxes[p] = box
            end
        end
    else
        for _, b in pairs(espBoxes) do b:Destroy() end
        espBoxes = {}
    end
end)

CreateButton("⚡ Speed Hack ON", function()
    if Character and Character:FindFirstChild("Humanoid") then Character.Humanoid.WalkSpeed = speed end
end)

CreateButton("⚡ Speed Hack OFF", function()
    if Character and Character:FindFirstChild("Humanoid") then Character.Humanoid.WalkSpeed = 16 end
end)

CreateButton("🦘 High Jump ON", function()
    if Character and Character:FindFirstChild("Humanoid") then Character.Humanoid.JumpPower = 150 end
end)

CreateButton("🦘 High Jump OFF", function()
    if Character and Character:FindFirstChild("Humanoid") then Character.Humanoid.JumpPower = 50 end
end)

CreateButton("❌ Close Hub", function()
    MainGui:Destroy()
end)

IntroBtn.MouseButton1Click:Connect(function()
    IntroGui:Destroy()
    MainGui.Enabled = true
    print("✅ Theskyfall Hub Loaded Successfully!")
end)

RunService.Stepped:Connect(function()
    if noclipping and Character then
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function(ch) Character = ch end)
