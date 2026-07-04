-- ═══════════════════════════════════════════════════════════════════════
--  SKYFALL HUB | UNIVERSAL GOD MODE
--  Kill All | Fly | Noclip | God Mode | Weapon Hijack | Checkpoint Skip
-- ═══════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ═══════ STATE ═══════
local State = {
    KillAll = false,
    GodMode = false,
    Fly = false,
    Noclip = false,
    Speed = 50,
    KillRange = 100,
    Connections = {},
    AllRemotes = {},
    LastTick = 0
}

-- ═══════ REMOTE SCANNER ═══════
local function ScanRemotes()
    local all = {}
    local keywords = {"slap","hit","damage","attack","punch","tool","weapon","glove","melee","gun","shoot","fire","equip","ability","skill","power","special","swing","strike","knock","push","throw","grab","use","activate","trigger","damage","hurt","kill","combathit","hitreg","takedamage","applydamage"}

    local function Scan(inst)
        for _, child in ipairs(inst:GetDescendants()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                local info = {Remote = child, Name = child.Name, Type = child.ClassName, Score = 0}
                local lower = child.Name:lower()
                for _, kw in ipairs(keywords) do
                    if lower:find(kw) then info.Score = info.Score + 20 end
                end
                table.insert(all, info)
            end
        end
    end

    Scan(ReplicatedStorage)
    Scan(Workspace)
    table.sort(all, function(a, b) return a.Score > b.Score end)
    State.AllRemotes = all
    return all
end

-- ═══════ KILL ALL ENGINE ═══════
local function KillAll()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local humanoid = char:FindFirstChild("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not humanoid or not hrp then continue end

            -- Method 1: All remotes brute force
            for _, remoteInfo in ipairs(State.AllRemotes) do
                pcall(function()
                    if remoteInfo.Type == "RemoteEvent" then
                        remoteInfo.Remote:FireServer(char, hrp.Position, 999999, "Head")
                        remoteInfo.Remote:FireServer(player.Name, 999999)
                    end
                end)
            end

            -- Method 2: Direct health
            pcall(function()
                humanoid.Health = 0
                humanoid:TakeDamage(999999)
                humanoid:BreakJoints()
            end)

            -- Method 3: Network ownership
            pcall(function()
                if hrp:IsA("BasePart") and not hrp.Anchored then
                    hrp.AssemblyLinearVelocity = Vector3.new(0, -1000, 0)
                end
            end)

            -- Method 4: Destroy character
            pcall(function()
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part:Destroy() end
                end
            end)

            -- Method 5: Raw packet
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
    local keywords = {"checkpoint","stage","level","spawn","finish","goal","winner","victory","completed","end","final"}

    for _, child in ipairs(Workspace:GetDescendants()) do
        local name = child.Name:lower()
        for _, kw in ipairs(keywords) do
            if name:find(kw) and (child:IsA("BasePart") or child:IsA("Model")) then
                table.insert(cps, child)
                break
            end
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

    humanoid.StateChanged:Connect(function(_, new)
        if new == Enum.HumanoidStateType.Dead or new == Enum.HumanoidStateType.Ragdoll then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            humanoid.Health = humanoid.MaxHealth
        end
    end)
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

-- ═══════ FLY SYSTEM ═══════
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
        if dir.Magnitude > 0 then dir = dir.Unit * State.Speed end
        FlyBodyVelocity.Velocity = dir
        FlyBodyGyro.CFrame = Camera.CFrame
    end)
end

local function StopFly()
    if FlyConnection then FlyConnection:Disconnect() FlyConnection = nil end
    if FlyBodyGyro then FlyBodyGyro:Destroy() FlyBodyGyro = nil end
    if FlyBodyVelocity then FlyBodyVelocity:Destroy() FlyBodyVelocity = nil end
end

-- ═══════ MOBILE UI ═══════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SkyfallGod_" .. tostring(math.random(100000,999999))
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 260, 0, 340)
Main.Position = UDim2.new(0.02, 0, 0.1, 0)
Main.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 16)
local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(255, 0, 80)
stroke.Thickness = 2

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 36)
Title.BackgroundTransparency = 1
Title.Text = "☢️ SKYFALL GOD"
Title.TextColor3 = Color3.fromRGB(255, 0, 80)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBlack
Title.Parent = Main

-- Draggable
local dragging, dragStart, startPos
Title.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = i.Position
        startPos = Main.Position
    end
end)
Title.InputChanged:Connect(function(i)
    if dragging then
        local delta = i.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
Title.InputEnded:Connect(function() dragging = false end)

-- Button maker
local function MakeBtn(text, y, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 40)
    btn.Position = UDim2.new(0.05, 0, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.Parent = Main
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    return btn
end

local KillAllBtn = MakeBtn("KILL ALL: OFF", 42, Color3.fromRGB(255, 0, 0))
local GrabWeaponBtn = MakeBtn("GRAB BEST WEAPON", 90, Color3.fromRGB(0, 200, 100))
local CheckpointBtn = MakeBtn("SKIP TO FINAL", 138, Color3.fromRGB(200, 100, 0))
local GodModeBtn = MakeBtn("GOD MODE: OFF", 186, Color3.fromRGB(255, 200, 0))
local FlyBtn = MakeBtn("FLY: OFF", 234, Color3.fromRGB(50, 150, 255))
local NoclipBtn = MakeBtn("NOCLIP: OFF", 282, Color3.fromRGB(150, 50, 255))

-- Status
local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 1, -24)
Status.BackgroundTransparency = 1
Status.Text = "Scanning..."
Status.TextColor3 = Color3.fromRGB(100, 255, 100)
Status.TextSize = 11
Status.Font = Enum.Font.Gotham
Status.Parent = Main

-- ═══════ BUTTON HANDLERS ═══════
local KillAllConnection

KillAllBtn.MouseButton1Click:Connect(function()
    State.KillAll = not State.KillAll
    if State.KillAll then
        KillAllBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        KillAllBtn.Text = "KILL ALL: ON ☢️"
        KillAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        KillAllConnection = RunService.Heartbeat:Connect(function()
            if tick() - State.LastTick >= 0.05 then
                State.LastTick = tick()
                KillAll()
            end
        end)
    else
        KillAllBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        KillAllBtn.Text = "KILL ALL: OFF"
        KillAllBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        if KillAllConnection then KillAllConnection:Disconnect() KillAllConnection = nil end
    end
end)

GrabWeaponBtn.MouseButton1Click:Connect(function()
    HijackWeapon()
    Status.Text = "Weapon hijacked!"
    Status.TextColor3 = Color3.fromRGB(0, 255, 100)
    task.delay(2, function() Status.TextColor3 = Color3.fromRGB(100, 255, 100) end)
end)

CheckpointBtn.MouseButton1Click:Connect(function()
    SkipCheckpoint()
    Status.Text = "Checkpoint skipped!"
    Status.TextColor3 = Color3.fromRGB(0, 255, 100)
    task.delay(2, function() Status.TextColor3 = Color3.fromRGB(100, 255, 100) end)
end)

GodModeBtn.MouseButton1Click:Connect(function()
    State.GodMode = not State.GodMode
    if State.GodMode then
        GodModeBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
        GodModeBtn.Text = "GOD MODE: ON 👑"
        GodModeBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        EnableGodMode()
    else
        GodModeBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        GodModeBtn.Text = "GOD MODE: OFF"
        GodModeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end)

FlyBtn.MouseButton1Click:Connect(function()
    State.Fly = not State.Fly
    if State.Fly then
        FlyBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
        FlyBtn.Text = "FLY: ON ✈️"
        FlyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        StartFly()
    else
        FlyBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        FlyBtn.Text = "FLY: OFF"
        FlyBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        StopFly()
    end
end)

NoclipBtn.MouseButton1Click:Connect(function()
    State.Noclip = not State.Noclip
    if State.Noclip then
        NoclipBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 255)
        NoclipBtn.Text = "NOCLIP: ON 👻"
        NoclipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        ToggleNoclip(true)
    else
        NoclipBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        NoclipBtn.Text = "NOCLIP: OFF"
        NoclipBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        ToggleNoclip(false)
    end
end)

-- ═══════ MOBILE FLY CONTROLS ═══════
local MobilePanel = Instance.new("Frame")
MobilePanel.Size = UDim2.new(0, 180, 0, 180)
MobilePanel.Position = UDim2.new(0.6, 0, 0.55, 0)
MobilePanel.BackgroundTransparency = 1
MobilePanel.Parent = ScreenGui

local function MBtn(text, pos, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 60, 0, 60)
    b.Position = pos
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 24
    b.Font = Enum.Font.GothamBlack
    b.Parent = MobilePanel
    Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
    return b
end

local UpBtn = MBtn("▲", UDim2.new(0.5, -30, 0, 0), Color3.fromRGB(50, 150, 255))
local DownBtn = MBtn("▼", UDim2.new(0.5, -30, 1, -60), Color3.fromRGB(50, 150, 255))
local SpdUp = MBtn("+", UDim2.new(1, -60, 0.5, -30), Color3.fromRGB(0, 200, 100))
local SpdDn = MBtn("-", UDim2.new(0, 0, 0.5, -30), Color3.fromRGB(200, 100, 0))

local touch = {up = false, down = false}
UpBtn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then touch.up = true end end)
UpBtn.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then touch.up = false end end)
DownBtn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then touch.down = true end end)
DownBtn.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then touch.down = false end end)

SpdUp.MouseButton1Click:Connect(function()
    State.Speed = math.min(State.Speed + 15, 250)
    Status.Text = "Speed: " .. State.Speed
end)
SpdDn.MouseButton1Click:Connect(function()
    State.Speed = math.max(State.Speed - 15, 10)
    Status.Text = "Speed: " .. State.Speed
end)

RunService.RenderStepped:Connect(function()
    if State.Fly and FlyBodyVelocity then
        local v = FlyBodyVelocity.Velocity
        if touch.up then FlyBodyVelocity.Velocity = Vector3.new(v.X, State.Speed, v.Z)
        elseif touch.down then FlyBodyVelocity.Velocity = Vector3.new(v.X, -State.Speed, v.Z) end
    end
end)

-- ═══════ ANTI-KICK ═══════
pcall(function()
    local mt = getrawmetatable(game)
    if mt then
        local old = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local m = getnamecallmethod()
            if m == "Kick" or m == "kick" then return nil end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    end
end)

-- ═══════ AUTO-INIT ═══════
task.spawn(function()
    task.wait(2)
    ScanRemotes()
    Status.Text = "God Ready | " .. #State.AllRemotes .. " remotes"
end)

-- ═══════ DEATH CLEANUP ═══════
LocalPlayer.CharacterAdded:Connect(function()
    if State.KillAll then
        State.KillAll = false
        if KillAllConnection then KillAllConnection:Disconnect() KillAllConnection = nil end
        KillAllBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        KillAllBtn.Text = "KILL ALL: OFF"
    end
    if State.Fly then
        State.Fly = false
        StopFly()
        FlyBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        FlyBtn.Text = "FLY: OFF"
    end
    if State.Noclip then ToggleNoclip(true) end
    if State.GodMode then task.delay(0.5, EnableGodMode) end
    task.delay(1.5, function()
        ScanRemotes()
        Status.Text = "Re-cached | " .. #State.AllRemotes .. " remotes"
    end)
end)

-- ═══════ BOOT ═══════
local Boot = Instance.new("TextLabel")
Boot.Size = UDim2.new(0, 400, 0, 60)
Boot.Position = UDim2.new(0.5, -200, 0, -80)
Boot.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
Boot.Text = "☢️ SKYFALL GOD ACTIVATED\nKill All | Fly | Noclip | God Mode | Weapon | Skip"
Boot.TextColor3 = Color3.fromRGB(255, 0, 80)
Boot.TextSize = 14
Boot.Font = Enum.Font.GothamBlack
Boot.Parent = ScreenGui
Instance.new("UICorner", Boot).CornerRadius = UDim.new(0, 14)

TweenService:Create(Boot, TweenInfo.new(0.7), {Position = UDim2.new(0.5, -200, 0, 100)}):Play()
task.delay(4, function()
    TweenService:Create(Boot, TweenInfo.new(0.5), {Position = UDim2.new(0.5, -200, 0, -80)}):Play()
    task.delay(0.5, function() Boot:Destroy() end)
end)

print("[☢️ SKYFALL GOD] Loaded | " .. os.date("%H:%M:%S"))
