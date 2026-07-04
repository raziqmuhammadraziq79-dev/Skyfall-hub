-- ═══════════════════════════════════════════════════════════════════════
--  SKYFALL HUB v6 | ADMIN CONSOLE | SINGLE FILE
--  Kill All | Fly | Noclip | God Mode | ESP | Admin Commands | Server Hijack
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
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

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
            if m == "Kick" or m == "kick" or m == "Destroy" then return nil end
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
    LastTick = 0,
    LoopKilled = {},
    FrozenPlayers = {},
    GoddedPlayers = {},
    SpeedBoosted = {},
    AdminRemotes = {},
    LogHistory = {}
}

-- ═══════ PLAYER GETTER ═══════
local function GetPlayer(name)
    if not name then return nil end
    name = name:lower()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name:lower():find(name) or player.DisplayName:lower():find(name) then
            return player
        end
    end
    return nil
end

-- ═══════ REMOTE SCANNER ═══════
local AllRemotes = {}
local function ScanRemotes()
    local keywords = {"slap","hit","damage","attack","punch","tool","weapon","glove","melee","gun","shoot","fire","equip","ability","skill","power","swing","strike","knock","push","throw","grab","use","activate","trigger","hurt","kill","combathit","hitreg","takedamage","applydamage","damageplayer","admin","command","cmd","moderator","mod","ban","kick","mute","warn","logs","server","replicate","broadcast","notify","message","chat","permission","rank","role","owner","creator","developer","dev"}
    
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
    
    State.AdminRemotes = {}
    for _, r in ipairs(AllRemotes) do
        if r.Score >= 20 then table.insert(State.AdminRemotes, r) end
    end
end

-- ═══════ ADMIN COMMAND EXECUTOR ═══════
local function ExecuteAdminCommand(cmd, target, args)
    for _, remoteInfo in ipairs(State.AdminRemotes) do
        pcall(function()
            if remoteInfo.Type == "RemoteEvent" then
                remoteInfo.Remote:FireServer(cmd, target, args)
                remoteInfo.Remote:FireServer("Command", cmd, target, args)
                remoteInfo.Remote:FireServer("Admin", cmd, target, args)
                remoteInfo.Remote:FireServer("Execute", cmd, target, args)
            elseif remoteInfo.Type == "RemoteFunction" then
                remoteInfo.Remote:InvokeServer(cmd, target, args)
            end
        end)
    end
    pcall(function()
        if fireserver then
            fireserver("AdminCommand", cmd, target, args)
            fireserver("ExecuteCommand", cmd, target, args)
        end
    end)
end

-- ═══════ KILL ALL ═══════
local function KillAll()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local humanoid = char:FindFirstChild("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not humanoid or not hrp then continue end

            for _, remoteInfo in ipairs(AllRemotes) do
                pcall(function()
                    if remoteInfo.Type == "RemoteEvent" then
                        remoteInfo.Remote:FireServer(char, hrp.Position, 999999, "Head")
                        remoteInfo.Remote:FireServer(player.Name, 999999)
                    end
                end)
            end

            pcall(function()
                humanoid.Health = 0
                humanoid:TakeDamage(999999)
                humanoid:BreakJoints()
            end)

            pcall(function()
                if hrp:IsA("BasePart") and not hrp.Anchored then
                    hrp.AssemblyLinearVelocity = Vector3.new(0, -1000, 0)
                end
            end)

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

-- ═══════ ADMIN COMMANDS ═══════
local Commands = {
    kill = function(target)
        if target == "all" then
            KillAll()
        else
            local player = GetPlayer(target)
            if player and player.Character then
                local humanoid = player.Character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.Health = 0
                    humanoid:TakeDamage(999999)
                    humanoid:BreakJoints()
                end
                ExecuteAdminCommand("Kill", player.Name, "")
            end
        end
    end,

    loopkill = function(target)
        if target == "all" then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    State.LoopKilled[player.UserId] = true
                end
            end
        else
            local player = GetPlayer(target)
            if player then State.LoopKilled[player.UserId] = true end
        end
    end,

    unloopkill = function(target)
        if target == "all" then
            State.LoopKilled = {}
        else
            local player = GetPlayer(target)
            if player then State.LoopKilled[player.UserId] = nil end
        end
    end,

    freeze = function(target)
        if target == "all" then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    State.FrozenPlayers[player.UserId] = true
                    for _, part in ipairs(player.Character:GetDescendants()) do
                        if part:IsA("BasePart") then part.Anchored = true end
                    end
                end
            end
        else
            local player = GetPlayer(target)
            if player and player.Character then
                State.FrozenPlayers[player.UserId] = true
                for _, part in ipairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.Anchored = true end
                end
            end
        end
    end,

    unfreeze = function(target)
        if target == "all" then
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Character then
                    State.FrozenPlayers[player.UserId] = nil
                    for _, part in ipairs(player.Character:GetDescendants()) do
                        if part:IsA("BasePart") then part.Anchored = false end
                    end
                end
            end
        else
            local player = GetPlayer(target)
            if player and player.Character then
                State.FrozenPlayers[player.UserId] = nil
                for _, part in ipairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.Anchored = false end
                end
            end
        end
    end,

    god = function(target)
        if target == "all" then
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Character then
                    State.GoddedPlayers[player.UserId] = true
                    local humanoid = player.Character:FindFirstChild("Humanoid")
                    if humanoid then
                        humanoid.MaxHealth = math.huge
                        humanoid.Health = math.huge
                    end
                end
            end
        else
            local player = GetPlayer(target)
            if player and player.Character then
                State.GoddedPlayers[player.UserId] = true
                local humanoid = player.Character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.MaxHealth = math.huge
                    humanoid.Health = math.huge
                end
            end
        end
    end,

    ungod = function(target)
        if target == "all" then
            State.GoddedPlayers = {}
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Character then
                    local humanoid = player.Character:FindFirstChild("Humanoid")
                    if humanoid then
                        humanoid.MaxHealth = 100
                        humanoid.Health = 100
                    end
                end
            end
        else
            local player = GetPlayer(target)
            if player then
                State.GoddedPlayers[player.UserId] = nil
                if player.Character then
                    local humanoid = player.Character:FindFirstChild("Humanoid")
                    if humanoid then
                        humanoid.MaxHealth = 100
                        humanoid.Health = 100
                    end
                end
            end
        end
    end,

    speed = function(target, speed)
        speed = tonumber(speed) or 50
        if target == "all" then
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Character then
                    State.SpeedBoosted[player.UserId] = speed
                    local humanoid = player.Character:FindFirstChild("Humanoid")
                    if humanoid then humanoid.WalkSpeed = speed end
                end
            end
        else
            local player = GetPlayer(target)
            if player and player.Character then
                State.SpeedBoosted[player.UserId] = speed
                local humanoid = player.Character:FindFirstChild("Humanoid")
                if humanoid then humanoid.WalkSpeed = speed end
            end
        end
    end,

    jumppower = function(target, power)
        power = tonumber(power) or 50
        if target == "all" then
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Character then
                    local humanoid = player.Character:FindFirstChild("Humanoid")
                    if humanoid then humanoid.JumpPower = power end
                end
            end
        else
            local player = GetPlayer(target)
            if player and player.Character then
                local humanoid = player.Character:FindFirstChild("Humanoid")
                if humanoid then humanoid.JumpPower = power end
            end
        end
    end,

    tp = function(target, destination)
        local player = GetPlayer(target)
        if not player then return end
        if destination == "me" then
            if player.Character and LocalPlayer.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp and myHRP then hrp.CFrame = myHRP.CFrame * CFrame.new(0, 0, 3) end
            end
        else
            local destPlayer = GetPlayer(destination)
            if destPlayer and destPlayer.Character and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                local destHRP = destPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp and destHRP then hrp.CFrame = destHRP.CFrame * CFrame.new(0, 0, 3) end
            end
        end
    end,

    bring = function(target)
        local player = GetPlayer(target)
        if player and player.Character and LocalPlayer.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp and myHRP then hrp.CFrame = myHRP.CFrame * CFrame.new(0, 0, 3) end
        end
    end,

    to = function(target)
        local player = GetPlayer(target)
        if player and player.Character and LocalPlayer.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp and myHRP then myHRP.CFrame = hrp.CFrame * CFrame.new(0, 0, 3) end
        end
    end,

    explode = function(target)
        if target == "all" then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local explosion = Instance.new("Explosion")
                        explosion.Position = hrp.Position
                        explosion.BlastRadius = 10
                        explosion.BlastPressure = 500000
                        explosion.Parent = Workspace
                        Debris:AddItem(explosion, 0.5)
                    end
                end
            end
        else
            local player = GetPlayer(target)
            if player and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local explosion = Instance.new("Explosion")
                    explosion.Position = hrp.Position
                    explosion.BlastRadius = 10
                    explosion.BlastPressure = 500000
                    explosion.Parent = Workspace
                    Debris:AddItem(explosion, 0.5)
                end
            end
        end
    end,

    fling = function(target)
        if target == "all" then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.AssemblyLinearVelocity = Vector3.new(math.random(-5000, 5000), math.random(-5000, 5000), math.random(-5000, 5000))
                    end
                end
            end
        else
            local player = GetPlayer(target)
            if player and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.AssemblyLinearVelocity = Vector3.new(math.random(-5000, 5000), math.random(-5000, 5000), math.random(-5000, 5000))
                end
            end
        end
    end,

    sit = function(target)
        if target == "all" then
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Character then
                    local humanoid = player.Character:FindFirstChild("Humanoid")
                    if humanoid then humanoid.Sit = true end
                end
            end
        else
            local player = GetPlayer(target)
            if player and player.Character then
                local humanoid = player.Character:FindFirstChild("Humanoid")
                if humanoid then humanoid.Sit = true end
            end
        end
    end,

    jump = function(target)
        if target == "all" then
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Character then
                    local humanoid = player.Character:FindFirstChild("Humanoid")
                    if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
                end
            end
        else
            local player = GetPlayer(target)
            if player and player.Character then
                local humanoid = player.Character:FindFirstChild("Humanoid")
                if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end
    end,

    respawn = function(target)
        if target == "all" then
            for _, player in ipairs(Players:GetPlayers()) do
                pcall(function() player:LoadCharacter() end)
            end
        else
            local player = GetPlayer(target)
            if player then pcall(function() player:LoadCharacter() end) end
        end
    end,

    announce = function(_, message)
        for _, player in ipairs(Players:GetPlayers()) do
            pcall(function()
                game:GetService("Chat"):Chat(player.Character, "[ADMIN] " .. (message or "Skyfall Admin"), Enum.ChatColor.Red)
            end)
        end
    end,

    serverhop = function()
        local servers = {}
        pcall(function()
            local req = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
            local data = HttpService:JSONDecode(req)
            for _, server in ipairs(data.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    table.insert(servers, server.id)
                end
            end
        end)
        if #servers > 0 then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
        end
    end,

    rejoin = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,

    shutdown = function()
        for _, player in ipairs(Players:GetPlayers()) do
            pcall(function() player:Kick("Server shutdown by Skyfall Admin") end)
        end
    end
}

-- ═══════ LOOP SYSTEMS ═══════
RunService.Heartbeat:Connect(function()
    for userId, _ in pairs(State.LoopKilled) do
        for _, player in ipairs(Players:GetPlayers()) do
            if player.UserId == userId and player.Character then
                local humanoid = player.Character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.Health = 0
                    humanoid:TakeDamage(999999)
                end
            end
        end
    end

    for userId, _ in pairs(State.GoddedPlayers) do
        for _, player in ipairs(Players:GetPlayers()) do
            if player.UserId == userId and player.Character then
                local humanoid = player.Character:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health < humanoid.MaxHealth then
                    humanoid.Health = humanoid.MaxHealth
                end
            end
        end
    end

    for userId, speed in pairs(State.SpeedBoosted) do
        for _, player in ipairs(Players:GetPlayers()) do
            if player.UserId == userId and player.Character then
                local humanoid = player.Character:FindFirstChild("Humanoid")
                if humanoid then humanoid.WalkSpeed = speed end
            end
        end
    end
end)

-- ═══════ UI ═══════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SkyfallHubV6"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 320, 0, 450)
Main.Position = UDim2.new(0.02, 0, 0.05, 0)
Main.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 18)
local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(255, 0, 0)
stroke.Thickness = 2

-- Top Bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
TopBar.BorderSizePixel = 0
TopBar.Parent = Main
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 18)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.5, 0, 1, 0)
Title.Position = UDim2.new(0.05, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "☢️ SKYFALL ADMIN"
Title.TextColor3 = Color3.fromRGB(255, 0, 0)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBlack
Title.Parent = TopBar

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

-- Command Input
local CmdFrame = Instance.new("Frame")
CmdFrame.Size = UDim2.new(0.95, 0, 0, 40)
CmdFrame.Position = UDim2.new(0.025, 0, 0, 50)
CmdFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
CmdFrame.BorderSizePixel = 0
CmdFrame.Parent = Main
Instance.new("UICorner", CmdFrame).CornerRadius = UDim.new(0, 10)

local CmdInput = Instance.new("TextBox")
CmdInput.Size = UDim2.new(0.7, 0, 1, 0)
CmdInput.Position = UDim2.new(0.05, 0, 0, 0)
CmdInput.BackgroundTransparency = 1
CmdInput.Text = ""
CmdInput.PlaceholderText = "Enter command (e.g. /kill all)"
CmdInput.TextColor3 = Color3.fromRGB(255, 255, 255)
CmdInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
CmdInput.TextSize = 12
CmdInput.Font = Enum.Font.GothamSemibold
CmdInput.ClearTextOnFocus = false
CmdInput.Parent = CmdFrame

local ExecuteBtn = Instance.new("TextButton")
ExecuteBtn.Size = UDim2.new(0.2, 0, 0.8, 0)
ExecuteBtn.Position = UDim2.new(0.78, 0, 0.1, 0)
ExecuteBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ExecuteBtn.Text = "EXECUTE"
ExecuteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ExecuteBtn.TextSize = 10
ExecuteBtn.Font = Enum.Font.GothamBold
ExecuteBtn.Parent = CmdFrame
Instance.new("UICorner", ExecuteBtn).CornerRadius = UDim.new(0, 8)

-- Scroll
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(0.95, 0, 0, 280)
Scroll.Position = UDim2.new(0.025, 0, 0, 100)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 4
Scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 0)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 800)
Scroll.Parent = Main

local function MakeCmdBtn(text, y, color, cmd, arg1, arg2)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.95, 0, 0, 32)
    btn.Position = UDim2.new(0.025, 0, 0, y)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.Parent = Scroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(function()
        if Commands[cmd] then Commands[cmd](arg1, arg2) end
    end)
    return btn
end

-- Quick buttons
MakeCmdBtn("☠️ Kill All", 0, Color3.fromRGB(200, 0, 0), "kill", "all")
MakeCmdBtn("🔁 LoopKill All", 38, Color3.fromRGB(150, 0, 0), "loopkill", "all")
MakeCmdBtn("❄️ Freeze All", 76, Color3.fromRGB(0, 150, 200), "freeze", "all")
MakeCmdBtn("🔥 Explode All", 114, Color3.fromRGB(255, 100, 0), "explode", "all")
MakeCmdBtn("🌪️ Fling All", 152, Color3.fromRGB(150, 50, 200), "fling", "all")
MakeCmdBtn("👑 God All", 190, Color3.fromRGB(255, 200, 0), "god", "all")
MakeCmdBtn("⚡ Speed All (100)", 228, Color3.fromRGB(0, 200, 100), "speed", "all", "100")
MakeCmdBtn("🚀 Jump All (100)", 266, Color3.fromRGB(0, 200, 200), "jumppower", "all", "100")
MakeCmdBtn("💥 Bring All", 304, Color3.fromRGB(200, 50, 100), "bring", "all")
MakeCmdBtn("🔄 Respawn All", 342, Color3.fromRGB(100, 100, 200), "respawn", "all")
MakeCmdBtn("📢 Announce", 380, Color3.fromRGB(200, 200, 0), "announce", nil, "Skyfall Admin Active")
MakeCmdBtn("🚪 Server Hop", 418, Color3.fromRGB(100, 200, 100), "serverhop")
MakeCmdBtn("🔄 Rejoin", 456, Color3.fromRGB(100, 150, 200), "rejoin")
MakeCmdBtn("❌ UnLoopKill All", 494, Color3.fromRGB(100, 100, 100), "unloopkill", "all")
MakeCmdBtn("🌡️ Unfreeze All", 532, Color3.fromRGB(100, 100, 100), "unfreeze", "all")
MakeCmdBtn("😇 Ungod All", 570, Color3.fromRGB(100, 100, 100), "ungod", "all")
MakeCmdBtn("🧹 Clear Logs", 608, Color3.fromRGB(80, 80, 80), "clearlogs")
MakeCmdBtn("🔴 Shutdown Server", 646, Color3.fromRGB(255, 0, 0), "shutdown")

-- Log
local LogFrame = Instance.new("Frame")
LogFrame.Size = UDim2.new(0.95, 0, 0, 50)
LogFrame.Position = UDim2.new(0.025, 0, 0, 390)
LogFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
LogFrame.BorderSizePixel = 0
LogFrame.Parent = Main
Instance.new("UICorner", LogFrame).CornerRadius = UDim.new(0, 10)

local LogLabel = Instance.new("TextLabel")
LogLabel.Size = UDim2.new(0.95, 0, 0.9, 0)
LogLabel.Position = UDim2.new(0.025, 0, 0.05, 0)
LogLabel.BackgroundTransparency = 1
LogLabel.Text = "Ready | Use /command target"
LogLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
LogLabel.TextSize = 10
LogLabel.Font = Enum.Font.Gotham
LogLabel.TextWrapped = true
LogLabel.TextXAlignment = Enum.TextXAlignment.Left
LogLabel.TextYAlignment = Enum.TextYAlignment.Top
LogLabel.Parent = LogFrame

-- Command processor
local function ProcessCommand(input)
    input = input:gsub("^/", "")
    local args = {}
    for arg in input:gmatch("%S+") do
        table.insert(args, arg)
    end
    
    local cmd = table.remove(args, 1)
    local target = args[1] or "all"
    local extra = args[2]
    
    if Commands[cmd] then
        Commands[cmd](target, extra)
        LogLabel.Text = "Executed: /" .. cmd .. " " .. target .. (extra and " " .. extra or "")
    else
        LogLabel.Text = "Unknown: /" .. cmd
    end
end

ExecuteBtn.MouseButton1Click:Connect(function()
    ProcessCommand(CmdInput.Text)
end)

CmdInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then ProcessCommand(CmdInput.Text) end
end)

-- Open Button
local OpenBtn = Instance.new("TextButton")
OpenBtn.Size = UDim2.new(0, 50, 0, 50)
OpenBtn.Position = UDim2.new(0, 10, 0.5, -25)
OpenBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
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
    task.wait(1)
    ScanRemotes()
    LogLabel.Text = "Admin Ready | " .. #State.AdminRemotes .. " remotes hijacked"
    print("[☢️ SKYFALL ADMIN v6] Loaded | " .. #State.AdminRemotes .. " remotes")
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
Boot.Size = UDim2.new(0, 400, 0, 60)
Boot.Position = UDim2.new(0.5, -200, 0, -80)
Boot.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
Boot.Text = "☢️ SKYFALL ADMIN v6 ACTIVATED\nServer Command Console | Full Access"
Boot.TextColor3 = Color3.fromRGB(255, 0, 0)
Boot.TextSize = 14
Boot.Font = Enum.Font.GothamBlack
Boot.Parent = ScreenGui
Instance.new("UICorner", Boot).CornerRadius = UDim.new(0, 14)

TweenService:Create(Boot, TweenInfo.new(0.7), {Position = UDim2.new(0.5, -200, 0, 100)}):Play()
task.delay(4, function()
    TweenService:Create(Boot, TweenInfo.new(0.5), {Position = UDim2.new(0.5, -200, 0, -80)}):Play()
    task.delay(0.5, function() Boot:Destroy() end)
end)
