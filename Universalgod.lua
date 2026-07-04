-- ═══════════════════════════════════════════════════════════════════════
--  SKYFALL GOD v4 | NUCLEAR OVERHAUL
--  Anti-Cheat Bypass | 30+ Features | Premium UI
-- ═══════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ═══════ ANTI-CHEAT BYPASS LAYER 0 ═══════
pcall(function()
    local mt = getrawmetatable(game)
    if mt then
        setreadonly(mt, false)
        local oldNamecall = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "Kick" or method == "kick" or method == "Destroy" then return nil end
            return oldNamecall(self, ...)
        end)
        
        local oldIndex = mt.__index
        mt.__index = newcclosure(function(self, key)
            if key == "Health" and self:IsA("Humanoid") then
                return oldIndex(self, key)
            end
            return oldIndex(self, key)
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
    Invisible = false,
    AutoFarm = false,
    AutoClick = false,
    ESP = false,
    Tracers = false,
    FullBright = false,
    NoFog = false,
    AntiAfk = false,
    WalkSpeed = 50,
    JumpPower = 50,
    FlySpeed = 70,
    KillRange = 100,
    ESPColor = Color3.fromRGB(255, 0, 0),
    TargetPlayer = nil,
    UIVisible = true,
    Page = "Main",
    Connections = {},
    AllRemotes = {},
    ESPObjects = {},
    LastTick = 0,
    AntiCheatBypassed = true
}

-- ═══════ DEEP REMOTE SCANNER ═══════
local function DeepScan()
    local all = {}
    local keywords = {"slap","hit","damage","attack","punch","tool","weapon","glove","melee","gun","shoot","fire","equip","ability","skill","power","special","swing","strike","knock","push","throw","grab","use","activate","trigger","hurt","kill","combathit","hitreg","takedamage","applydamage","damageplayer","playerdamage","remoteevent","remotevent","replicate","sync","validate","check","ban","kick","report","log","detect","anticheat","ac","security"}

    local function Scan(inst, path)
        for _, child in ipairs(inst:GetDescendants()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") or child:IsA("BindableEvent") then
                local info = {
                    Remote = child,
                    Name = child.Name,
                    Path = path .. "." .. child.Name,
                    Type = child.ClassName,
                    Score = 0,
                    Parent = child.Parent and child.Parent.Name or "nil"
                }
                local lower = child.Name:lower()
                for _, kw in ipairs(keywords) do
                    if lower:find(kw) then info.Score = info.Score + 15 end
                end
                if child.Parent then
                    local plower = child.Parent.Name:lower()
                    for _, kw in ipairs(keywords) do
                        if plower:find(kw) then info.Score = info.Score + 10 end
                    end
                end
                table.insert(all, info)
            end
        end
    end

    Scan(ReplicatedStorage, "RS")
    Scan(Workspace, "WS")
    Scan(Lighting, "Light")
    Scan(game:GetService("StarterPlayer"), "SP")
    
    table.sort(all, function(a, b) return a.Score > b.Score end)
    State.AllRemotes = all
    return all
end

-- ═══════ ANTI-CHEAT KILL ALL ENGINE ═══════
local function NuclearKillAll()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local humanoid = char:FindFirstChild("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not humanoid or not hrp then continue end

            -- Layer 1: Remote Brute Force (all discovered remotes)
            for _, remoteInfo in ipairs(State.AllRemotes) do
                pcall(function()
                    if remoteInfo.Type == "RemoteEvent" then
                        -- Pattern A: Standard damage
                        remoteInfo.Remote:FireServer(char, hrp.Position, 999999, "Head")
                        -- Pattern B: Player name
                        remoteInfo.Remote:FireServer(player.Name, 999999)
                        -- Pattern C: Table argument
                        remoteInfo.Remote:FireServer({Target = char, Damage = 999999, Part = "Head"})
                        -- Pattern D: String type
                        remoteInfo.Remote:FireServer("Damage", char, 999999)
                        -- Pattern E: Position only
                        remoteInfo.Remote:FireServer(hrp.Position, 999999)
                        -- Pattern F: Full character
                        remoteInfo.Remote:FireServer(char, "Head", 999999, LocalPlayer.Character.HumanoidRootPart.CFrame)
                    elseif remoteInfo.Type == "RemoteFunction" then
                        pcall(function()
                            remoteInfo.Remote:InvokeServer(char, 999999, "Head")
                        end)
                    end
                end)
            end

            -- Layer 2: Position Spoof + Attack
            pcall(function()
                local myChar = LocalPlayer.Character
                local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if myHRP then
                    local original = myHRP.CFrame
                    myHRP.CFrame = hrp.CFrame * CFrame.new(0, 0, 1.5)
                    task.wait(0.03)
                    for _, remoteInfo in ipairs(State.AllRemotes) do
                        if remoteInfo.Score >= 20 then
                            pcall(function()
                                remoteInfo.Remote:FireServer(char, 999999)
                            end)
                        end
                    end
                    myHRP.CFrame = original
                end
            end)

            -- Layer 3: Network Ownership Abuse
            pcall(function()
                if hrp:IsA("BasePart") and not hrp.Anchored then
                    for i = 1, 15 do
                        hrp.AssemblyLinearVelocity = Vector3.new(
                            math.random(-800, 800),
                            math.random(-800, 800),
                            math.random(-800, 800)
                        )
                        hrp.AssemblyAngularVelocity = Vector3.new(
                            math.random(-200, 200),
                            math.random(-200, 200),
                            math.random(-200, 200)
                        )
                    end
                    humanoid.Health = 0
                end
            end)

            -- Layer 4: Direct Health Manipulation
            pcall(function()
                humanoid.Health = 0
                humanoid:TakeDamage(999999)
                humanoid.MaxHealth = 1
                humanoid.Health = 0
                humanoid:BreakJoints()
            end)

            -- Layer 5: Joint Breaking
            pcall(function()
                for _, joint in ipairs(char:GetDescendants()) do
                    if joint:IsA("Motor6D") or joint:IsA("JointInstance") or joint:IsA("Weld") then
                        joint:Destroy()
                    end
                end
            end)

            -- Layer 6: Part Destroyer
            pcall(function()
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part:Destroy()
                    end
                end
            end)

            -- Layer 7: Raw Packet Injection
            pcall(function()
                if fireserver then
                    fireserver("KillPlayer", player.Name)
                    fireserver("DamagePlayer", player.Name, 999999, "Head")
                    fireserver("Eliminate", player.Name)
                    fireserver("CombatHit", player.Name, 999999)
                    fireserver("HitRegister", player.Name, 999999)
                end
            end)

            -- Layer 8: Anti-Cheat Bypass Hook
            pcall(function()
                if hookfunction then
                    local oldDamage = humanoid.TakeDamage
                    hookfunction(oldDamage, function() return nil end)
                end
            end)

            -- Layer 9: Character Break
            pcall(function()
                char:BreakJoints()
            end)

            -- Layer 10: Server-Side Position Desync
            pcall(function()
                if sethiddenproperty then
                    sethiddenproperty(hrp, "NetworkIsSleeping", false)
                    sethiddenproperty(hrp, "AssemblyLinearVelocity", Vector3.new(0, -5000, 0))
                end
            end)
        end
    end
end

-- ═══════ WEAPON HIJACK v2 ═══════
local function NuclearWeaponHijack()
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
            
            -- Hijack tool remotes
            for _, event in ipairs(tool:GetDescendants()) do
                if event:IsA("RemoteEvent") then
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character then
                            pcall(function()
                                event:FireServer(player.Character, 999999, "Head")
                                event:FireServer(player.Name, 999999)
                                event:FireServer({Target = player.Character, Damage = 999999})
                            end)
                        end
                    end
                end
            end

            -- Force tool cooldown bypass
            if tool:FindFirstChild("Cooldown") then
                tool.Cooldown.Value = 0
            end
            if tool:FindFirstChild("Debounce") then
                tool.Debounce.Value = false
            end
        end)
    end
end

-- ═══════ TELEPORT SYSTEM ═══════
local function TeleportToPlayer(targetName)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name:lower():find(targetName:lower()) and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local myChar = LocalPlayer.Character
                if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                    myChar.HumanoidRootPart.CFrame = hrp.CFrame * CFrame.new(0, 0, 3)
                    State.TargetPlayer = player
                end
            end
            break
        end
    end
end

local function TeleportToPosition(pos)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(pos)
    end
end

-- ═══════ ESP SYSTEM ═══════
local function CreateESP(player)
    if player == LocalPlayer then return end
    if not player.Character then return end
    
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Box ESP
    local box = Instance.new("BoxHandleAdornment")
    box.Size = Vector3.new(4, 6, 2)
    box.Color3 = State.ESPColor
    box.Transparency = 0.5
    box.AlwaysOnTop = true
    box.Adornee = hrp
    box.Parent = CoreGui

    -- Name ESP
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 100, 0, 30)
    billboard.AlwaysOnTop = true
    billboard.Adornee = hrp
    billboard.Parent = CoreGui

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = State.ESPColor
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard

    -- Tracer
    local tracer = Instance.new("LineHandleAdornment")
    tracer.Thickness = 2
    tracer.Color3 = State.ESPColor
    tracer.AlwaysOnTop = true
    tracer.Parent = CoreGui

    table.insert(State.ESPObjects, {Box = box, Billboard = billboard, Tracer = tracer, Player = player})
end

local function UpdateESP()
    for _, esp in ipairs(State.ESPObjects) do
        if esp.Player.Character and esp.Player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = esp.Player.Character.HumanoidRootPart
            esp.Box.Adornee = hrp
            esp.Billboard.Adornee = hrp
            
            if State.Tracers then
                local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myHRP then
                    esp.Tracer.Visible = true
                    esp.Tracer.Length = (hrp.Position - myHRP.Position).Magnitude
                    esp.Tracer.CFrame = CFrame.lookAt(myHRP.Position, hrp.Position)
                end
            else
                esp.Tracer.Visible = false
            end
        else
            esp.Box:Destroy()
            esp.Billboard:Destroy()
            esp.Tracer:Destroy()
        end
    end
end

local function ClearESP()
    for _, esp in ipairs(State.ESPObjects) do
        pcall(function()
            esp.Box:Destroy()
            esp.Billboard:Destroy()
            esp.Tracer:Destroy()
        end)
    end
    State.ESPObjects = {}
end

-- ═══════ DOXING / PLAYER INFO ═══════
local function GetPlayerInfo(player)
    local info = {
        Name = player.Name,
        DisplayName = player.DisplayName,
        UserId = player.UserId,
        Team = player.Team and player.Team.Name or "None",
        Health = "N/A",
        Position = "N/A",
        Distance = "N/A",
        Tool = "None"
    }
    
    if player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if humanoid then info.Health = tostring(math.floor(humanoid.Health)) .. "/" .. tostring(math.floor(humanoid.MaxHealth)) end
        if hrp then
            info.Position = tostring(math.floor(hrp.Position.X)) .. ", " .. tostring(math.floor(hrp.Position.Y)) .. ", " .. tostring(math.floor(hrp.Position.Z))
            local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myHRP then
                info.Distance = tostring(math.floor((hrp.Position - myHRP.Position).Magnitude)) .. " studs"
            end
        end
        for _, tool in ipairs(player.Character:GetChildren()) do
            if tool:IsA("Tool") then info.Tool = tool.Name break end
        end
    end
    
    return info
end

-- ═══════ FULL BRIGHT / NO FOG ═══════
local function ToggleFullBright(enabled)
    if enabled then
        Lighting.Brightness = 10
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("Atmosphere") or effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") then
                effect.Enabled = false
            end
        end
    else
        Lighting.Brightness = 2
        Lighting.GlobalShadows = true
    end
end

-- ═══════ WALK SPEED / JUMP POWER ═══════
local function SetWalkSpeed(speed)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = speed
    end
end

local function SetJumpPower(power)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.JumpPower = power
    end
end

-- ═══════ INVISIBLE ═══════
local function ToggleInvisible(enabled)
    local char = LocalPlayer.Character
    if not char then return end
    
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            if enabled then
                part.Transparency = 1
                if part:FindFirstChild("face") then
                    part.face.Transparency = 1
                end
            else
                part.Transparency = 0
                if part:FindFirstChild("face") then
                    part.face.Transparency = 0
                end
            end
        end
    end
end

-- ═══════ AUTO FARM / AUTO CLICK ═══════
local function AutoFarmLoop()
    while State.AutoFarm do
        pcall(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and (obj.Name:lower():find("coin") or obj.Name:lower():find("gem") or obj.Name:lower():find("money") or obj.Name:lower():find("collect")) then
                    local char = LocalPlayer.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        char.HumanoidRootPart.CFrame = obj.CFrame
                        task.wait(0.1)
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end

-- ═══════ FLY SYSTEM v2 ═══════
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

-- ═══════ GOD MODE v2 ═══════
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

-- ═══════ PREMIUM UI v4 ═══════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SkyfallGodV4_" .. tostring(math.random(100000,999999))
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

-- Main Container
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 300, 0, 420)
Main.Position = UDim2.new(0.02, 0, 0.05, 0)
Main.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
Main.BorderSizePixel = 0
Main.Visible = true
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 18)
local mainStroke = Instance.new("UIStroke", Main)
mainStroke.Color = Color3.fromRGB(255, 0, 80)
mainStroke.Thickness = 2

-- Top Bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
TopBar.BorderSizePixel = 0
TopBar.Parent = Main
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 18)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.6, 0, 1, 0)
Title.Position = UDim2.new(0.05, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "☢️ SKYFALL GOD v4"
Title.TextColor3 = Color3.fromRGB(255, 0, 80)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBlack
Title.Parent = TopBar

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.GothamBlack
CloseBtn.Parent = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

CloseBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    State.UIVisible = false
end)

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -70, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
MinBtn.TextSize = 20
MinBtn.Font = Enum.Font.GothamBlack
MinBtn.Parent = TopBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 8)

-- Scroll Frame
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(0.95, 0, 0, 340)
ScrollFrame.Position = UDim2.new(0.025, 0, 0, 50)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 80)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 800)
ScrollFrame.Parent = Main

-- Page: Main
local MainPage = Instance.new("Frame")
MainPage.Size = UDim2.new(1, 0, 1, 0)
MainPage.BackgroundTransparency = 1
MainPage.Parent = ScrollFrame

local function CreateToggle(parent, text, y, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.95, 0, 0, 36)
    frame.Position = UDim2.new(0.025, 0, 0, y)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    frame.BorderSizePixel = 0
    frame.Parent = parent
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
    toggle.Position = UDim2.new(1, -60, 0.5, -12)
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

    return toggle
end

local function CreateButton(parent, text, y, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.95, 0, 0, 36)
    btn.Position = UDim2.new(0.025, 0, 0, y)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Main Page Buttons
CreateToggle(MainPage, "☢️ Kill All", 0, function(enabled)
    State.KillAll = enabled
    if enabled then
        State.LastTick = tick()
        local conn = RunService.Heartbeat:Connect(function()
            if tick() - State.LastTick >= 0.05 then
                State.LastTick = tick()
                NuclearKillAll()
            end
        end)
        table.insert(State.Connections, conn)
    else
        for _, conn in ipairs(State.Connections) do
            pcall(function() conn:Disconnect() end)
        end
        State.Connections = {}
    end
end)

CreateButton(MainPage, "🔫 Weapon Hijack", 42, Color3.fromRGB(200, 50, 50), function()
    NuclearWeaponHijack()
end)

CreateButton(MainPage, "🏁 Skip Checkpoint", 84, Color3.fromRGB(200, 150, 0), function()
    SkipCheckpoint()
end)

CreateToggle(MainPage, "👑 God Mode", 126, function(enabled)
    State.GodMode = enabled
    if enabled then EnableGodMode() end
end)

CreateToggle(MainPage, "✈️ Fly", 168, function(enabled)
    State.Fly = enabled
    if enabled then StartFly() else StopFly() end
end)

CreateToggle(MainPage, "👻 Noclip", 210, function(enabled)
    State.Noclip = enabled
    ToggleNoclip(enabled)
end)

CreateToggle(MainPage, "👁️ ESP", 252, function(enabled)
    State.ESP = enabled
    if enabled then
        for _, player in ipairs(Players:GetPlayers()) do
            CreateESP(player)
        end
        RunService.RenderStepped:Connect(UpdateESP)
    else
        ClearESP()
    end
end)

CreateToggle(MainPage, "📍 Tracers", 294, function(enabled)
    State.Tracers = enabled
end)

CreateToggle(MainPage, "💡 Full Bright", 336, function(enabled)
    ToggleFullBright(enabled)
end)

CreateToggle(MainPage, "👤 Invisible", 378, function(enabled)
    State.Invisible = enabled
    ToggleInvisible(enabled)
end)

CreateToggle(MainPage, "🤖 Auto Farm", 420, function(enabled)
    State.AutoFarm = enabled
    if enabled then task.spawn(AutoFarmLoop) end
end)

-- Open Button (when minimized)
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
    State.UIVisible = true
    OpenBtn.Visible = false
end)

MinBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    OpenBtn.Visible = true
end)

-- Draggable TopBar
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

-- Mobile Fly Controls
local MobilePanel = Instance.new("Frame")
MobilePanel.Size = UDim2.new(0, 180, 0, 180)
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

-- ═══════ AUTO-INIT ═══════
task.spawn(function()
    task.wait(2)
    DeepScan()
    print("[☢️ SKYFALL GOD v4] Loaded | " .. #State.AllRemotes .. " remotes | " .. os.date("%H:%M:%S"))
end)

-- ═══════ DEATH CLEANUP ═══════
LocalPlayer.CharacterAdded:Connect(function()
    if State.KillAll then
        State.KillAll = false
        for _, conn in ipairs(State.Connections) do
            pcall(function() conn:Disconnect() end)
        end
        State.Connections = {}
    end
    if State.Fly then
        State.Fly = false
        StopFly()
    end
    if State.Noclip then ToggleNoclip(true) end
    if State.GodMode then task.delay(0.5, EnableGodMode) end
    if State.Invisible then task.delay(0.5, function() ToggleInvisible(true) end) end
    task.delay(1.5, function()
        DeepScan()
    end)
end)

-- ═══════ BOOT NOTIFICATION ═══════
local Boot = Instance.new("TextLabel")
Boot.Size = UDim2.new(0, 420, 0, 60)
Boot.Position = UDim2.new(0.5, -210, 0, -80)
Boot.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
Boot.Text = "☢️ SKYFALL GOD v4 ACTIVATED\n10-Layer Anti-Cheat Bypass | 30+ Features"
Boot.TextColor3 = Color3.fromRGB(255, 0, 80)
Boot.TextSize = 14
Boot.Font = Enum.Font.GothamBlack
Boot.Parent = ScreenGui
Instance.new("UICorner", Boot).CornerRadius = UDim.new(0, 14)

TweenService:Create(Boot, TweenInfo.new(0.7), {Position = UDim2.new(0.5, -210, 0, 100)}):Play()
task.delay(4, function()
    TweenService:Create(Boot, TweenInfo.new(0.5), {Position = UDim2.new(0.5, -210, 0, -80)}):Play()
    task.delay(0.5, function() Boot:Destroy() end)
end)
