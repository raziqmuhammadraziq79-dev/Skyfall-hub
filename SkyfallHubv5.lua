-- ═══════════════════════════════════════════════════════════════════════
--  SKYFALL HUB v5 | SINGLE FILE | NO LOADER NEEDED
--  Kill All | Fly | Noclip | God Mode | ESP | Weapon Hijack | Teleport
-- ═══════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ═══════ ANTI-KICK ═══════
pcall(function()
    local mt = getrawmetatable(game)
    if mt then
        setreadonly(mt, false)
        local old = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            local m = getnamecallmethod()
            if m == "Kick" or m == "kick" then return nil end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    end
end)

-- ═══════ STATE ═══════
local State = {
    KillAll = false,
    GodMode = false,
    Fly = false,
    Noclip = false,
    ESP = false,
    FullBright = false,
    Speed = 50,
    FlySpeed = 70,
    KillRange = 100,
    LastTick = 0
}

-- ═══════ REMOTE SCANNER ═══════
local AllRemotes = {}
local function ScanRemotes()
    local keywords = {"slap","hit","damage","attack","punch","tool","weapon","glove","melee","gun","shoot","fire","equip","ability","skill","power","swing","strike","knock","push","throw","grab","use","activate","trigger","hurt","kill","combathit","hitreg","takedamage","applydamage","damageplayer"}
    
    local function Scan(inst)
        for _, child in ipairs(inst:GetDescendants()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                local info = {Remote = child, Name = child.Name, Type = child.ClassName, Score = 0}
                local lower = child.Name:lower()
                for _, kw in ipairs(keywords) do
                    if lower:find(kw) then info.Score = info.Score + 20 end
                end
                table.insert(AllRemotes, info)
            end
        end
    end
    
    Scan(ReplicatedStorage)
    Scan(Workspace)
    table.sort(AllRemotes, function(a, b) return a.Score > b.Score end)
end

-- ═══════ KILL ALL ═══════
local function KillAll()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local humanoid = char:FindFirstChild("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not humanoid or not hrp then continue end

            -- Remote brute force
            for _, remoteInfo in ipairs(AllRemotes) do
                pcall(function()
                    if remoteInfo.Type == "RemoteEvent" then
                        remoteInfo.Remote:FireServer(char, hrp.Position, 999999, "Head")
                        remoteInfo.Remote:FireServer(player.Name, 999999)
                    end
                end)
            end

            -- Direct damage
            pcall(function()
                humanoid.Health = 0
                humanoid:TakeDamage(999999)
                humanoid:BreakJoints()
            end)

            -- Network ownership
            pcall(function()
                if hrp:IsA("BasePart") and not hrp.Anchored then
                    hrp.AssemblyLinearVelocity = Vector3.new(0, -1000, 0)
                end
            end)

            -- Raw packet
            pcall(function()
                if fireserver then
                    fireserver("KillPlayer", player.Name)
                    fireserver("DamagePlayer", player.Name, 999999)
                end
            end)
        end
    end
end

-- ═══════ WEAPON HIJACK ═══════
local function HijackWeapon()
    local char = LocalPlayer.Character
    if not char then return end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end

    local tools = {}
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then table.insert(tools, tool) end
    end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then table.insert(tools, tool) end
    end

    for _, tool in ipairs(tools) do
        pcall(function()
            char.Humanoid:EquipTool(tool)
            tool:Activate()
            for _, event in ipairs(tool:GetDescendants()) do
                if event:IsA("RemoteEvent") then
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character then
                            pcall(function()
                                event:FireServer(player.Character, 999999, "Head")
                            end)
                        end
                    end
                end
            end
        end)
    end
end

-- ═══════ CHECKPOINT SKIP ═══════
local function SkipCheckpoint()
    local cps = {}
    for _, child in ipairs(Workspace:GetDescendants()) do
        local name = child.Name:lower()
        if (name:find("checkpoint") or name:find("stage") or name:find("finish") or name:find("goal") or name:find("winner")) and (child:IsA("BasePart") or child:IsA("Model")) then
            table.insert(cps, child)
        end
    end

    if #cps > 0 then
        table.sort(cps, function(a, b)
            local posA = a:IsA("Model") and a:GetPivot().Position or a.Position
            local posB = b:IsA("Model") and b:GetPivot().Position or b.Position
            return posA.Y > posB.Y
        end)

        local final = cps[1]
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local targetPos = final:IsA("Model") and final:GetPivot().Position or final.Position
            char.HumanoidRootPart.CFrame = CFrame.new(targetPos + Vector3.new(0, 5, 0))
        end
    end
end

-- ═══════ GOD MODE ═══════
local function EnableGodMode()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end

    humanoid.Health = humanoid.MaxHealth
    humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if humanoid.Health < humanoid.MaxHealth then
            humanoid.Health = humanoid.MaxHealth
        end
    end)
end

-- ═══════ FLY ═══════
local FlyBodyGyro, FlyBodyVelocity, FlyConnection

local function StartFly()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    FlyBodyGyro = Instance.new("BodyGyro")
    FlyBodyGyro.P = 9e4
    FlyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    FlyBodyGyro.CFrame = hrp.CFrame
    FlyBodyGyro.Parent = hrp

    FlyBodyVelocity = Instance.new("BodyVelocity")
    FlyBodyVelocity.Velocity = Vector3.zero
    FlyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    FlyBodyVelocity.Parent = hrp

    FlyConnection = RunService.RenderStepped:Connect(function()
        if not FlyBodyGyro or not FlyBodyVelocity then return end
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
        if dir.Magnitude > 0 then dir = dir.Unit * State.FlySpeed end
        FlyBodyVelocity.Velocity = dir
        FlyBodyGyro.CFrame = Camera.CFrame
    end)
end

local function StopFly()
    if FlyConnection then FlyConnection:Disconnect() FlyConnection = nil end
    if FlyBodyGyro then FlyBodyGyro:Destroy() FlyBodyGyro = nil end
    if FlyBodyVelocity then FlyBodyVelocity:Destroy() FlyBodyVelocity = nil end
end

-- ═══════ NOCLIP ═══════
local NoclipConnection
local function ToggleNoclip(enabled)
    if enabled then
        NoclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    else
        if NoclipConnection then NoclipConnection:Disconnect() NoclipConnection = nil end
    end
end

-- ═══════ FULL BRIGHT ═══════
local function ToggleFullBright(enabled)
    if enabled then
        Lighting.Brightness = 10
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
    else
        Lighting.Brightness = 2
        Lighting.GlobalShadows = true
    end
end

-- ═══════ ESP ═══════
local ESPObjects = {}
local function CreateESP(player)
    if player == LocalPlayer then return end
    if not player.Character then return end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local box = Instance.new("BoxHandleAdornment")
    box.Size = Vector3.new(4, 6, 2)
    box.Color3 = Color3.fromRGB(255, 0, 0)
    box.Transparency = 0.5
    box.AlwaysOnTop = true
    box.Adornee = hrp
    box.Parent = CoreGui

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 100, 0, 30)
    billboard.AlwaysOnTop = true
    billboard.Adornee = hrp
    billboard.Parent = CoreGui

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard

    table.insert(ESPObjects, {Box = box, Billboard = billboard, Player = player})
end

local function ClearESP()
    for _, esp in ipairs(ESPObjects) do
        pcall(function()
            esp.Box:Destroy()
            esp.Billboard:Destroy()
        end)
    end
    ESPObjects = {}
end

-- ═══════ UI ═══════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SkyfallHubV5"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 280, 0, 400)
Main.Position = UDim2.new(0.02, 0, 0.05, 0)
Main.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 16)
local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(255, 0, 80)
stroke.Thickness = 2

-- Top Bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 36)
TopBar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
TopBar.BorderSizePixel = 0
TopBar.Parent = Main
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 16)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.6, 0, 1, 0)
Title.Position = UDim2.new(0.05, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "☢️ SKYFALL HUB"
Title.TextColor3 = Color3.fromRGB(255, 0, 80)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBlack
Title.Parent = TopBar

-- Close
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -33, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBlack
CloseBtn.Parent = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

-- Minimize
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -65, 0, 4)
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
MinBtn.TextSize = 18
MinBtn.Font = Enum.Font.GothamBlack
MinBtn.Parent = TopBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 8)

-- Scroll
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(0.95, 0, 0, 340)
Scroll.Position = UDim2.new(0.025, 0, 0, 46)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 4
Scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 80)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 600)
Scroll.Parent = Main

-- Button maker
local function MakeBtn(text, y, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.95, 0, 0, 38)
    btn.Position = UDim2.new(0.025, 0, 0, y)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.Parent = Scroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function MakeToggle(text, y, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.95, 0, 0, 38)
    frame.Position = UDim2.new(0.025, 0, 0, y)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    frame.BorderSizePixel = 0
    frame.Parent = Scroll
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0.05, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 12
    label.Font = Enum.Font.GothamSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 50, 0, 24)
    toggle.Position = UDim2.new(1, -58, 0.5, -12)
    toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    toggle.Text = "OFF"
    toggle.TextColor3 = Color3.fromRGB(150, 150, 150)
    toggle.TextSize = 11
    toggle.Font = Enum.Font.GothamBold
    toggle.Parent = frame
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 8)

    local enabled = false
    toggle.MouseButton1Click:Connect(function()
        enabled = not enabled
        if enabled then
            toggle.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
            toggle.Text = "ON"
            toggle.TextColor3 = Color3.fromRGB(0, 0, 0)
        else
            toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            toggle.Text = "OFF"
            toggle.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
        callback(enabled)
    end)
end

-- Buttons
MakeToggle("☢️ Kill All", 0, function(enabled)
    State.KillAll = enabled
    if enabled then
        local conn = RunService.Heartbeat:Connect(function()
            if tick() - State.LastTick >= 0.05 then
                State.LastTick = tick()
                KillAll()
            end
        end)
        table.insert(State.Connections or {}, conn)
    end
end)

MakeBtn("🔫 Weapon Hijack", 46, Color3.fromRGB(200, 50, 50), function()
    HijackWeapon()
end)

MakeBtn("🏁 Skip Checkpoint", 92, Color3.fromRGB(200, 150, 0), function()
    SkipCheckpoint()
end)

MakeToggle("👑 God Mode", 138, function(enabled)
    State.GodMode = enabled
    if enabled then EnableGodMode() end
end)

MakeToggle("✈️ Fly", 184, function(enabled)
    State.Fly = enabled
    if enabled then StartFly() else StopFly() end
end)

MakeToggle("👻 Noclip", 230, function(enabled)
    State.Noclip = enabled
    ToggleNoclip(enabled)
end)

MakeToggle("👁️ ESP", 276, function(enabled)
    State.ESP = enabled
    if enabled then
        for _, player in ipairs(Players:GetPlayers()) do
            CreateESP(player)
        end
    else
        ClearESP()
    end
end)

MakeToggle("💡 Full Bright", 322, function(enabled)
    State.FullBright = enabled
    ToggleFullBright(enabled)
end)

MakeBtn("📍 Teleport to Random", 368, Color3.fromRGB(150, 50, 255), function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(math.random(-500, 500), 100, math.random(-500, 500))
    end
end)

-- Open Button
local OpenBtn = Instance.new("TextButton")
OpenBtn.Size = UDim2.new(0, 50, 0, 50)
OpenBtn.Position = UDim2.new(0, 10, 0.5, -25)
OpenBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 80)
OpenBtn.Text = "☢️"
OpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenBtn.TextSize = 24
OpenBtn.Font = Enum.Font.GothamBlack
OpenBtn.Visible = false
OpenBtn.Parent = ScreenGui
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(1, 0)

OpenBtn.MouseButton1Click:Connect(function()
    Main.Visible = true
    OpenBtn.Visible = false
end)

CloseBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    OpenBtn.Visible = true
end)

MinBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    OpenBtn.Visible = true
end)

-- Draggable
local dragging, dragStart, startPos
TopBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = i.Position
        startPos = Main.Position
    end
end)
TopBar.InputChanged:Connect(function(i)
    if dragging then
        local delta = i.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
TopBar.InputEnded:Connect(function() dragging = false end)

-- Mobile Fly
local MobilePanel = Instance.new("Frame")
MobilePanel.Size = UDim2.new(0, 170, 0, 170)
MobilePanel.Position = UDim2.new(0.6, 0, 0.55, 0)
MobilePanel.BackgroundTransparency = 1
MobilePanel.Parent = ScreenGui

local function MBtn(text, pos, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 55, 0, 55)
    b.Position = pos
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 22
    b.Font = Enum.Font.GothamBlack
    b.Parent = MobilePanel
    Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
    return b
end

local UpFly = MBtn("▲", UDim2.new(0.5, -27, 0, 0), Color3.fromRGB(50, 150, 255))
local DownFly = MBtn("▼", UDim2.new(0.5, -27, 1, -55), Color3.fromRGB(50, 150, 255))
local SpdUp = MBtn("+", UDim2.new(1, -55, 0.5, -27), Color3.fromRGB(0, 200, 100))
local SpdDn = MBtn("-", UDim2.new(0, 0, 0.5, -27), Color3.fromRGB(200, 100, 0))

local touch = {up = false, down = false}
UpFly.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then touch.up = true end end)
UpFly.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then touch.up = false end end)
DownFly.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then touch.down = true end end)
DownFly.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then touch.down = false end end)

SpdUp.MouseButton1Click:Connect(function()
    State.FlySpeed = math.min(State.FlySpeed + 15, 250)
end)
SpdDn.MouseButton1Click:Connect(function()
    State.FlySpeed = math.max(State.FlySpeed - 15, 10)
end)

RunService.RenderStepped:Connect(function()
    if State.Fly and FlyBodyVelocity then
        local v = FlyBodyVelocity.Velocity
        if touch.up then FlyBodyVelocity.Velocity = Vector3.new(v.X, State.FlySpeed, v.Z)
        elseif touch.down then FlyBodyVelocity.Velocity = Vector3.new(v.X, -State.FlySpeed, v.Z) end
    end
end)

-- Init
task.spawn(function()
    task.wait(2)
    ScanRemotes()
    print("[☢️ SKYFALL HUB v5] Loaded | " .. #AllRemotes .. " remotes")
end)

-- Death cleanup
LocalPlayer.CharacterAdded:Connect(function()
    if State.KillAll then State.KillAll = false end
    if State.Fly then State.Fly = false StopFly() end
    if State.Noclip then ToggleNoclip(true) end
    if State.GodMode then task.delay(0.5, EnableGodMode) end
    task.delay(1.5, ScanRemotes)
end)

-- Boot
local Boot = Instance.new("TextLabel")
Boot.Size = UDim2.new(0, 380, 0, 50)
Boot.Position = UDim2.new(0.5, -190, 0, -70)
Boot.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
Boot.Text = "☢️ SKYFALL HUB v5 ACTIVATED\nKill All | Fly | Noclip | ESP | God Mode"
Boot.TextColor3 = Color3.fromRGB(255, 0, 80)
Boot.TextSize = 14
Boot.Font = Enum.Font.GothamBlack
Boot.Parent = ScreenGui
Instance.new("UICorner", Boot).CornerRadius = UDim.new(0, 12)

TweenService:Create(Boot, TweenInfo.new(0.6), {Position = UDim2.new(0.5, -190, 0, 90)}):Play()
task.delay(3, function()
    TweenService:Create(Boot, TweenInfo.new(0.5), {Position = UDim2.new(0.5, -190, 0, -70)}):Play()
    task.delay(0.5, function() Boot:Destroy() end)
end)
