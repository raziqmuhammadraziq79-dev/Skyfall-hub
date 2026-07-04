-- ═══════════════════════════════════════════════════════════════════════════
--  SKYFALL HUB v7 | ALL-IN-ONE | FIXED SERVER REPLICATION
--  by Axiom — rebuilt from scratch, honest about what replicates
--
--  REPLICATION TRUTH:
--    ✅ Physics on YOUR character    → replicate (you're network owner)
--    ✅ New instances in Workspace   → replicate (server sees them)
--    ✅ firetouchinterest            → triggers server Touched events
--    ✅ FireServer on RemoteEvents   → server executes
--    ✅ Explosions in Workspace      → replicate 100%
--    ❌ Setting Health of others     → client-side illusion only
--    ❌ Setting WalkSpeed of others  → client-side only
--    ❌ Anchoring other char parts   → you're not their network owner
-- ═══════════════════════════════════════════════════════════════════════════

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local Workspace      = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local CoreGui        = game:GetService("CoreGui")
local Debris         = game:GetService("Debris")
local Lighting       = game:GetService("Lighting")
local HttpService    = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Chat           = game:GetService("Chat")

local LP   = Players.LocalPlayer
local Cam  = Workspace.CurrentCamera

-- ═══════════════════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════════════════
local State = {
    Fly          = false,
    FlySpeed     = 80,
    Noclip       = false,
    GodMode      = false,
    AuraKill     = false,
    AuraRange    = 12,
    AuraCooldown = 0.7,
    ESP          = false,
    FullBright   = false,
    Speed        = 16,
    JumpPower    = 50,
    LoopKill     = {},   -- [userId] = true
    FrozenParts  = {},   -- [userId] = {BodyPos instances}
    LastAuraHit  = {},   -- [userId] = tick()
}

-- ═══════════════════════════════════════════════════════════════════════════
-- ANTI-KICK  (getrawmetatable → executor feature, works on Delta/Fluxus)
-- ═══════════════════════════════════════════════════════════════════════════
pcall(function()
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local old = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local m = getnamecallmethod()
        if m == "Kick" or m == "kick" then return nil end
        return old(self, ...)
    end)
    setreadonly(mt, true)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- REMOTE SCANNER
-- Scans ReplicatedStorage + Workspace for damage/hit/admin RemoteEvents
-- Higher score = more likely to be a damage remote
-- ═══════════════════════════════════════════════════════════════════════════
local ScannedRemotes = {}   -- {Remote, Name, Score}

local KEYWORDS = {
    "slap","hit","damage","attack","punch","weapon","glove","melee","gun",
    "shoot","fire","equip","ability","skill","swing","strike","knock","push",
    "throw","grab","hurt","kill","combathit","hitreg","takedamage","applydamage",
    "damageplayer","admin","command","replicate","broadcast"
}

local function ScanRemotes()
    ScannedRemotes = {}
    local function scan(root)
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                local score = 0
                local lower = obj.Name:lower()
                for _, kw in ipairs(KEYWORDS) do
                    if lower:find(kw) then score += 15 end
                end
                table.insert(ScannedRemotes, {Remote = obj, Name = obj.Name, Score = score, Type = obj.ClassName})
            end
        end
    end
    scan(ReplicatedStorage)
    scan(Workspace)
    table.sort(ScannedRemotes, function(a, b) return a.Score > b.Score end)
end

-- Fire all high-score remotes with a damage payload
local function BlastRemotes(targetChar, targetPlayer)
    for _, r in ipairs(ScannedRemotes) do
        if r.Score < 15 then break end
        pcall(function()
            if r.Type == "RemoteEvent" then
                -- Try multiple arg patterns used by common games
                r.Remote:FireServer(targetChar, targetChar.HumanoidRootPart.Position, 9999, "Head")
                r.Remote:FireServer(targetPlayer.Name, 9999)
                r.Remote:FireServer(targetPlayer, 9999)
                r.Remote:FireServer("Kill", targetPlayer.Name, "")
            elseif r.Type == "RemoteFunction" then
                r.Remote:InvokeServer(targetChar, 9999)
            end
        end)
    end
    -- Executor-level fireserver (Delta/Fluxus)
    pcall(function()
        if fireserver then
            fireserver("KillPlayer", targetPlayer.Name)
            fireserver("DamagePlayer", targetPlayer.Name, 9999)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPER: get character parts safely
-- ═══════════════════════════════════════════════════════════════════════════
local function GetChar(player)
    return player and player.Character
end
local function GetHRP(player)
    local c = GetChar(player)
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function GetHum(player)
    local c = GetChar(player)
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function MyChar()  return LP.Character end
local function MyHRP()   return MyChar() and MyChar():FindFirstChild("HumanoidRootPart") end
local function MyHum()   return MyChar() and MyChar():FindFirstChildOfClass("Humanoid") end

-- ═══════════════════════════════════════════════════════════════════════════
-- FLY  ✅ REPLICATES
-- BodyGyro + BodyVelocity on YOUR HRP → physics sync → all players see it
-- ═══════════════════════════════════════════════════════════════════════════
local FlyBG, FlyBV, FlyRSConn

local function StartFly()
    local hrp = MyHRP()
    if not hrp then return end
    if MyHum() then MyHum().PlatformStand = true end  -- disables default walk anim

    FlyBG = Instance.new("BodyGyro")
    FlyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    FlyBG.P         = 9e4
    FlyBG.D         = 100
    FlyBG.CFrame    = hrp.CFrame
    FlyBG.Parent    = hrp

    FlyBV = Instance.new("BodyVelocity")
    FlyBV.MaxForce  = Vector3.new(9e9, 9e9, 9e9)
    FlyBV.Velocity  = Vector3.zero
    FlyBV.Parent    = hrp

    FlyRSConn = RunService.RenderStepped:Connect(function()
        if not FlyBV or not FlyBG then return end
        local dir = Vector3.zero
        local cf  = Cam.CFrame

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then dir += Vector3.yAxis  end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis  end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)   then dir -= Vector3.yAxis  end

        FlyBV.Velocity = dir.Magnitude > 0 and dir.Unit * State.FlySpeed or Vector3.zero
        FlyBG.CFrame   = cf
    end)
end

local function StopFly()
    if FlyRSConn then FlyRSConn:Disconnect(); FlyRSConn = nil end
    if FlyBG  then FlyBG:Destroy();  FlyBG  = nil end
    if FlyBV  then FlyBV:Destroy();  FlyBV  = nil end
    local hum = MyHum()
    if hum then hum.PlatformStand = false end
end

local function ToggleFly()
    State.Fly = not State.Fly
    if State.Fly then StartFly() else StopFly() end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- NOCLIP  ✅ REPLICATES (your own char CanCollide → replicate)
-- ═══════════════════════════════════════════════════════════════════════════
local NoclipConn
local function ToggleNoclip(on)
    State.Noclip = on
    if NoclipConn then NoclipConn:Disconnect(); NoclipConn = nil end
    if on then
        NoclipConn = RunService.Stepped:Connect(function()
            local c = MyChar()
            if not c then return end
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- GOD MODE  ✅ REPLICATES (your own Humanoid → you are owner)
-- ═══════════════════════════════════════════════════════════════════════════
local GodConn
local function ToggleGodMode(on)
    State.GodMode = on
    if GodConn then GodConn:Disconnect(); GodConn = nil end
    if on then
        local hum = MyHum()
        if not hum then return end
        hum.Health = hum.MaxHealth
        GodConn = hum:GetPropertyChangedSignal("Health"):Connect(function()
            if hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SPEED / JUMPPOWER  ✅ REPLICATES (your own Humanoid)
-- ═══════════════════════════════════════════════════════════════════════════
local function SetSpeed(val)
    State.Speed = val
    local hum = MyHum()
    if hum then hum.WalkSpeed = val end
end

local function SetJump(val)
    State.JumpPower = val
    local hum = MyHum()
    if hum then hum.JumpPower = val end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FULLBRIGHT  ✅ LOCAL (Lighting changes local only — intended)
-- ═══════════════════════════════════════════════════════════════════════════
local OrigBright, OrigShadows = Lighting.Brightness, Lighting.GlobalShadows
local function ToggleFullBright(on)
    State.FullBright = on
    if on then
        Lighting.Brightness     = 10
        Lighting.GlobalShadows  = false
        Lighting.FogEnd         = 100000
        Lighting.Ambient        = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    else
        Lighting.Brightness     = OrigBright
        Lighting.GlobalShadows  = OrigShadows
        Lighting.Ambient        = Color3.fromRGB(70, 70, 70)
        Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 140)
        Lighting.FogEnd         = 100000
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ESP  ✅ LOCAL (visual only on your client — intended)
-- ═══════════════════════════════════════════════════════════════════════════
local ESPObjects = {}
local ESPUpdateConn

local function RemoveESP(player)
    if ESPObjects[player] then
        pcall(function() ESPObjects[player].Box:Destroy() end)
        pcall(function() ESPObjects[player].Bill:Destroy() end)
        ESPObjects[player] = nil
    end
end

local function AddESP(player)
    if player == LP then return end
    RemoveESP(player)
    local hrp = GetHRP(player)
    if not hrp then return end

    local box = Instance.new("BoxHandleAdornment")
    box.Size          = Vector3.new(4, 6, 2)
    box.Color3        = Color3.fromRGB(255, 30, 30)
    box.Transparency  = 0.4
    box.AlwaysOnTop   = true
    box.Adornee       = hrp
    box.Parent        = CoreGui

    local bill = Instance.new("BillboardGui")
    bill.Size         = UDim2.new(0, 120, 0, 36)
    bill.AlwaysOnTop  = true
    bill.Adornee      = hrp
    bill.StudsOffset  = Vector3.new(0, 3.5, 0)
    bill.Parent       = CoreGui

    local name = Instance.new("TextLabel")
    name.Size                 = UDim2.new(1, 0, 0.6, 0)
    name.BackgroundTransparency = 1
    name.Text                 = player.DisplayName
    name.TextColor3           = Color3.fromRGB(255, 60, 60)
    name.TextStrokeTransparency = 0
    name.TextSize             = 13
    name.Font                 = Enum.Font.GothamBold
    name.Parent               = bill

    local dist = Instance.new("TextLabel")
    dist.Size                 = UDim2.new(1, 0, 0.4, 0)
    dist.Position             = UDim2.new(0, 0, 0.6, 0)
    dist.BackgroundTransparency = 1
    dist.TextColor3           = Color3.fromRGB(255, 180, 0)
    dist.TextStrokeTransparency = 0
    dist.TextSize             = 11
    dist.Font                 = Enum.Font.Gotham
    dist.Parent               = bill

    ESPObjects[player] = {Box = box, Bill = bill, Dist = dist}
end

local function ToggleESP(on)
    State.ESP = on
    if ESPUpdateConn then ESPUpdateConn:Disconnect(); ESPUpdateConn = nil end

    if on then
        for _, p in ipairs(Players:GetPlayers()) do AddESP(p) end
        ESPUpdateConn = RunService.RenderStepped:Connect(function()
            local myHRP = MyHRP()
            for player, obj in pairs(ESPObjects) do
                local hrp = GetHRP(player)
                if not hrp or not obj.Dist then RemoveESP(player) continue end
                local d = myHRP and math.floor((myHRP.Position - hrp.Position).Magnitude) or 0
                local hum = GetHum(player)
                local hp  = hum and math.floor(hum.Health) or 0
                obj.Dist.Text = d .. "m | HP:" .. hp
            end
        end)
    else
        for player in pairs(ESPObjects) do RemoveESP(player) end
    end
end

Players.PlayerAdded:Connect(function(p)
    if State.ESP then
        p.CharacterAdded:Connect(function() task.wait(1); AddESP(p) end)
    end
end)
Players.PlayerRemoving:Connect(RemoveESP)

-- ═══════════════════════════════════════════════════════════════════════════
-- KILL ALL  
-- Layer 1: firetouchinterest  → triggers Touched events server-side  ✅
-- Layer 2: Explosion in Workspace → replicates 100%                  ✅
-- Layer 3: Weapon tool RemoteEvents → game-dependent                 ✅
-- Layer 4: Scanned damage RemoteEvents → game-dependent              ✅
-- Layer 5: BreakJoints (pcall) → might work in some games            ⚡
-- ═══════════════════════════════════════════════════════════════════════════
local function KillTarget(player)
    local c   = GetChar(player)
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    if not c or not hrp then return end

    local myHRP = MyHRP()

    -- Layer 1: firetouchinterest (most reliable on Delta/Fluxus)
    if myHRP then
        pcall(function()
            firetouchinterest(myHRP, hrp, 0)
            task.delay(0.08, function()
                pcall(function() firetouchinterest(myHRP, hrp, 1) end)
            end)
        end)
    end

    -- Layer 2: Explosion at their position — ALWAYS replicates from client
    local exp = Instance.new("Explosion")
    exp.Position     = hrp.Position
    exp.BlastRadius  = 8
    exp.BlastPressure = 800000
    exp.DestroyJointRadiusPercent = 1  -- destroys joints server-side
    exp.Parent = Workspace
    Debris:AddItem(exp, 0.5)

    -- Layer 3: Weapon tool RemoteEvents in their character
    pcall(function()
        for _, tool in ipairs(c:GetChildren()) do
            if tool:IsA("Tool") then
                for _, desc in ipairs(tool:GetDescendants()) do
                    if desc:IsA("RemoteEvent") then
                        desc:FireServer(c, 9999, "Head")
                    end
                end
            end
        end
    end)

    -- Layer 4: Blast scanned remotes
    BlastRemotes(c, player)

    -- Layer 5: Direct (client-side only, some games allow)
    pcall(function()
        if hum then
            hum.Health = 0
            hum:BreakJoints()
        end
    end)
end

local function KillAll()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then KillTarget(p) end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- LOOP KILL  (fires KillTarget every 0.5s for targeted players)
-- ═══════════════════════════════════════════════════════════════════════════
local LoopKillConn
local function StartLoopKill()
    if LoopKillConn then return end
    LoopKillConn = RunService.Heartbeat:Connect(function()
        for userId in pairs(State.LoopKill) do
            for _, p in ipairs(Players:GetPlayers()) do
                if p.UserId == userId and p ~= LP then
                    KillTarget(p)
                end
            end
        end
    end)
end
local function StopLoopKill()
    State.LoopKill = {}
    if LoopKillConn then LoopKillConn:Disconnect(); LoopKillConn = nil end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- AURA KILL  ✅ SERVER-SIDE via firetouchinterest + Explosion
-- Runs on RenderStepped, fires on players within AuraRange studs
-- ═══════════════════════════════════════════════════════════════════════════
local AuraConn
local function StartAura()
    if AuraConn then return end
    AuraConn = RunService.Heartbeat:Connect(function()
        local myHRP = MyHRP()
        if not myHRP then return end

        for _, player in ipairs(Players:GetPlayers()) do
            if player == LP then continue end
            local hrp = GetHRP(player)
            if not hrp then continue end

            local dist = (myHRP.Position - hrp.Position).Magnitude
            local now  = tick()
            local uid  = player.UserId

            if dist <= State.AuraRange and (not State.LastAuraHit[uid] or now - State.LastAuraHit[uid] >= State.AuraCooldown) then
                State.LastAuraHit[uid] = now

                -- firetouchinterest: tells server "my HRP touched their HRP"
                pcall(function()
                    firetouchinterest(myHRP, hrp, 0)
                    task.delay(0.06, function()
                        pcall(function() firetouchinterest(myHRP, hrp, 1) end)
                    end)
                end)

                -- Explosion at their feet — always replicates
                local exp = Instance.new("Explosion")
                exp.Position     = hrp.Position
                exp.BlastRadius  = 4
                exp.BlastPressure = 500000
                exp.DestroyJointRadiusPercent = 1
                exp.Parent = Workspace
                Debris:AddItem(exp, 0.3)

                -- Weapon tools
                local myChar = MyChar()
                if myChar then
                    pcall(function()
                        for _, tool in ipairs(myChar:GetChildren()) do
                            if tool:IsA("Tool") then
                                for _, desc in ipairs(tool:GetDescendants()) do
                                    if desc:IsA("RemoteEvent") then
                                        desc:FireServer(player.Character, 9999, "Head")
                                    end
                                end
                            end
                        end
                    end)
                end

                -- Scanned remotes
                BlastRemotes(player.Character, player)
            end
        end
    end)
end

local function StopAura()
    if AuraConn then AuraConn:Disconnect(); AuraConn = nil end
    State.LastAuraHit = {}
end

local function ToggleAura()
    State.AuraKill = not State.AuraKill
    if State.AuraKill then StartAura() else StopAura() end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FREEZE (BodyPosition anchored to current pos)  ⚡ PARTIALLY REPLICATES
-- Creates a BodyPosition instance on their HRP — new instances DO replicate
-- from LocalScript to server. Works on games with low security.
-- ═══════════════════════════════════════════════════════════════════════════
local function FreezePlayer(player)
    local hrp = GetHRP(player)
    if not hrp then return end

    -- Remove old freeze if exists
    if State.FrozenParts[player.UserId] then
        for _, inst in ipairs(State.FrozenParts[player.UserId]) do
            pcall(function() inst:Destroy() end)
        end
    end

    local frozen = {}

    local bp = Instance.new("BodyPosition")
    bp.Position  = hrp.Position
    bp.MaxForce  = Vector3.new(math.huge, math.huge, math.huge)
    bp.P         = 100000
    bp.D         = 9999
    bp.Parent    = hrp
    table.insert(frozen, bp)

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bg.P         = 100000
    bg.CFrame    = hrp.CFrame
    bg.Parent    = hrp
    table.insert(frozen, bg)

    State.FrozenParts[player.UserId] = frozen
end

local function UnfreezePlayer(player)
    if State.FrozenParts[player.UserId] then
        for _, inst in ipairs(State.FrozenParts[player.UserId]) do
            pcall(function() inst:Destroy() end)
        end
        State.FrozenParts[player.UserId] = nil
    end
end

local function FreezeAll()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then FreezePlayer(p) end
    end
end

local function UnfreezeAll()
    for _, p in ipairs(Players:GetPlayers()) do
        UnfreezePlayer(p)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FLING  ✅ Explosion = guaranteed fling (physics replicate)
-- Also tries AssemblyLinearVelocity (only works if you own their network)
-- ═══════════════════════════════════════════════════════════════════════════
local function FlingPlayer(player)
    local hrp = GetHRP(player)
    if not hrp then return end

    -- Explosion-based fling — 100% replicates
    local exp = Instance.new("Explosion")
    exp.Position      = hrp.Position
    exp.BlastRadius   = 6
    exp.BlastPressure = 9999999
    exp.DestroyJointRadiusPercent = 0  -- fling without killing
    exp.Parent = Workspace
    Debris:AddItem(exp, 0.5)

    -- Direct velocity attempt (works if you're somehow network owner)
    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.new(
            math.random(-3000, 3000),
            math.random(2000, 5000),
            math.random(-3000, 3000)
        )
    end)
end

local function FlingAll()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then FlingPlayer(p) end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPLODE ALL  ✅ 100% REPLICATES (Explosion instance in Workspace)
-- ═══════════════════════════════════════════════════════════════════════════
local function ExplodeAll()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local hrp = GetHRP(p)
            if hrp then
                local exp = Instance.new("Explosion")
                exp.Position      = hrp.Position
                exp.BlastRadius   = 12
                exp.BlastPressure = 999999
                exp.DestroyJointRadiusPercent = 1
                exp.Parent = Workspace
                Debris:AddItem(exp, 1)
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- TELEPORT (self) ✅ REPLICATES (you own your HRP)
-- ═══════════════════════════════════════════════════════════════════════════
local function TeleportTo(player)
    local hrp    = GetHRP(player)
    local myHRP  = MyHRP()
    if hrp and myHRP then
        myHRP.CFrame = hrp.CFrame * CFrame.new(0, 0, 3.5)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- BRING (BodyPosition on their HRP) ⚡ works on low-security games
-- Moves them toward your position using BodyPosition (new instance = replicates)
-- ═══════════════════════════════════════════════════════════════════════════
local function BringPlayer(player)
    local hrp   = GetHRP(player)
    local myHRP = MyHRP()
    if not hrp or not myHRP then return end

    -- Clean up any existing freeze first
    UnfreezePlayer(player)

    local bp = Instance.new("BodyPosition")
    bp.Position = myHRP.Position + Vector3.new(0, 0, 3.5)
    bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bp.P        = 50000
    bp.D        = 500
    bp.Parent   = hrp

    -- Auto-remove after 3s so they're not stuck
    Debris:AddItem(bp, 3)
end

local function BringAll()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then BringPlayer(p) end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SERVERHOP
-- ═══════════════════════════════════════════════════════════════════════════
local function ServerHop()
    pcall(function()
        local raw     = game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
        local data    = HttpService:JSONDecode(raw)
        local servers = {}
        for _, s in ipairs(data.data or {}) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                table.insert(servers, s.id)
            end
        end
        if #servers > 0 then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LP)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CHARACTER RESPAWN HANDLER — re-apply persistent states on respawn
-- ═══════════════════════════════════════════════════════════════════════════
LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    if State.GodMode    then ToggleGodMode(true)  end
    if State.Noclip     then ToggleNoclip(true)   end
    if State.Fly        then State.Fly = false; task.wait(0.2); ToggleFly() end
    if State.Speed ~= 16 then
        task.wait(0.3)
        SetSpeed(State.Speed)
    end
    task.delay(2, ScanRemotes)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- ══════════════════════════════ UI ════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════════════════
local C = {
    BG     = Color3.fromRGB(8,  8,  13),
    Panel  = Color3.fromRGB(14, 14, 22),
    Card   = Color3.fromRGB(20, 20, 32),
    Border = Color3.fromRGB(40, 0,  80),
    Red    = Color3.fromRGB(220, 30, 30),
    Purple = Color3.fromRGB(130, 40, 220),
    Green  = Color3.fromRGB(30,  200, 90),
    Yellow = Color3.fromRGB(255, 200, 0),
    Orange = Color3.fromRGB(255, 110, 0),
    Blue   = Color3.fromRGB(50,  140, 255),
    White  = Color3.fromRGB(240, 240, 255),
    Muted  = Color3.fromRGB(120, 120, 150),
}

-- Remove old GUI if reloading
pcall(function()
    local old = CoreGui:FindFirstChild("SkyfallHubV7")
    if old then old:Destroy() end
end)

local Gui = Instance.new("ScreenGui")
Gui.Name            = "SkyfallHubV7"
Gui.ResetOnSpawn    = false
Gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
Gui.IgnoreGuiInset  = true
Gui.Parent          = CoreGui

-- ─── Helpers ───────────────────────────────────────────────────────────────
local function corner(parent, radius)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, radius or 10)
    return c
end
local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke", parent)
    s.Color     = color or C.Border
    s.Thickness = thickness or 1.5
    return s
end
local function label(parent, text, size, color, font)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text       = text
    l.TextSize   = size or 12
    l.TextColor3 = color or C.White
    l.Font       = font or Enum.Font.GothamSemibold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent     = parent
    return l
end

-- ─── Main Window ───────────────────────────────────────────────────────────
local Win = Instance.new("Frame")
Win.Size            = UDim2.new(0, 340, 0, 520)
Win.Position        = UDim2.new(0, 20, 0, 60)
Win.BackgroundColor3= C.BG
Win.BorderSizePixel = 0
Win.Parent          = Gui
corner(Win, 16)
stroke(Win, C.Purple, 1.5)

-- ─── Top Bar ───────────────────────────────────────────────────────────────
local Bar = Instance.new("Frame")
Bar.Size            = UDim2.new(1, 0, 0, 44)
Bar.BackgroundColor3= C.Panel
Bar.BorderSizePixel = 0
Bar.Parent          = Win
corner(Bar, 16)

local BarTitle = label(Bar, "  ☢  SKYFALL HUB  v7", 14, C.Purple, Enum.Font.GothamBlack)
BarTitle.Size     = UDim2.new(0.7, 0, 1, 0)
BarTitle.Position = UDim2.new(0, 0, 0, 0)
BarTitle.TextXAlignment = Enum.TextXAlignment.Left

local StatusDot = Instance.new("Frame")
StatusDot.Size            = UDim2.new(0, 8, 0, 8)
StatusDot.Position        = UDim2.new(1, -75, 0.5, -4)
StatusDot.BackgroundColor3= C.Green
StatusDot.BorderSizePixel = 0
StatusDot.Parent          = Bar
corner(StatusDot, 4)

local function makeTopBtn(text, xOffset, bg, callback)
    local b = Instance.new("TextButton")
    b.Size            = UDim2.new(0, 28, 0, 28)
    b.Position        = UDim2.new(1, xOffset, 0.5, -14)
    b.BackgroundColor3= bg
    b.Text            = text
    b.TextColor3      = C.White
    b.TextSize        = 13
    b.Font            = Enum.Font.GothamBlack
    b.Parent          = Bar
    corner(b, 7)
    b.MouseButton1Click:Connect(callback)
    return b
end

makeTopBtn("×", -10, C.Red,    function() Win.Visible = false end)
makeTopBtn("−", -44, C.Yellow, function() Win.Visible = false end)

-- ─── Tab Bar ───────────────────────────────────────────────────────────────
local TabBar = Instance.new("Frame")
TabBar.Size            = UDim2.new(1, -16, 0, 34)
TabBar.Position        = UDim2.new(0, 8, 0, 50)
TabBar.BackgroundColor3= C.Card
TabBar.BorderSizePixel = 0
TabBar.Parent          = Win
corner(TabBar, 10)

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
TabLayout.Padding             = UDim.new(0, 4)
TabLayout.Parent              = TabBar

local Pages   = {}
local TabBtns = {}
local ActiveTab = nil

local function makeTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size            = UDim2.new(0, 72, 0, 26)
    btn.BackgroundColor3= C.Card
    btn.Text            = icon .. " " .. name
    btn.TextColor3      = C.Muted
    btn.TextSize        = 10
    btn.Font            = Enum.Font.GothamBold
    btn.Parent          = TabBar
    corner(btn, 7)

    local page = Instance.new("ScrollingFrame")
    page.Size              = UDim2.new(1, -16, 1, -100)
    page.Position          = UDim2.new(0, 8, 0, 92)
    page.BackgroundTransparency = 1
    page.BorderSizePixel   = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = C.Purple
    page.CanvasSize        = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible           = false
    page.Parent            = Win

    local layout = Instance.new("UIListLayout")
    layout.SortOrder        = Enum.SortOrder.LayoutOrder
    layout.Padding          = UDim.new(0, 6)
    layout.Parent           = page

    local pad = Instance.new("UIPadding", page)
    pad.PaddingTop = UDim.new(0, 4)

    Pages[name]   = page
    TabBtns[name] = btn

    btn.MouseButton1Click:Connect(function()
        for n, p in pairs(Pages)   do p.Visible = false end
        for n, b in pairs(TabBtns) do
            b.TextColor3      = C.Muted
            b.BackgroundColor3 = C.Card
        end
        page.Visible      = true
        btn.TextColor3    = C.White
        btn.BackgroundColor3 = C.Purple
        ActiveTab = name
    end)

    return page
end

local PgCombat = makeTab("Combat",  "⚔")
local PgSelf   = makeTab("Self",    "🧍")
local PgMisc   = makeTab("Misc",    "⚙")

-- ─── UI Components ─────────────────────────────────────────────────────────
local function sectionTitle(page, text)
    local f = Instance.new("Frame")
    f.Size            = UDim2.new(1, 0, 0, 22)
    f.BackgroundTransparency = 1
    f.LayoutOrder     = 0
    f.Parent          = page

    local l = label(f, "  " .. text, 10, C.Muted, Enum.Font.GothamBold)
    l.Size = UDim2.new(1, 0, 1, 0)
    l.TextXAlignment = Enum.TextXAlignment.Left
    return f
end

local function makeToggle(page, text, color, onToggle, defaultOn)
    local f = Instance.new("Frame")
    f.Size            = UDim2.new(1, 0, 0, 40)
    f.BackgroundColor3= C.Card
    f.BorderSizePixel = 0
    f.Parent          = page
    corner(f, 10)

    local lbl = label(f, "  " .. text, 12, C.White)
    lbl.Size     = UDim2.new(0.75, 0, 1, 0)
    lbl.Position = UDim2.new(0, 0, 0, 0)

    local toggle = Instance.new("TextButton")
    toggle.Size            = UDim2.new(0, 44, 0, 24)
    toggle.Position        = UDim2.new(1, -52, 0.5, -12)
    toggle.BackgroundColor3= defaultOn and color or C.Muted
    toggle.Text            = ""
    toggle.Parent          = f
    corner(toggle, 12)

    local knob = Instance.new("Frame")
    knob.Size              = UDim2.new(0, 18, 0, 18)
    knob.Position          = defaultOn and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3  = C.White
    knob.BorderSizePixel   = 0
    knob.Parent            = toggle
    corner(knob, 9)

    local on = defaultOn or false
    toggle.MouseButton1Click:Connect(function()
        on = not on
        TweenService:Create(toggle, TweenInfo.new(0.2), {
            BackgroundColor3 = on and color or C.Muted
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {
            Position = on and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        }):Play()
        onToggle(on)
    end)

    return f
end

local function makeButton(page, text, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size            = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3= color
    btn.Text            = text
    btn.TextColor3      = C.White
    btn.TextSize        = 12
    btn.Font            = Enum.Font.GothamBold
    btn.Parent          = page
    corner(btn, 10)

    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundTransparency = 0.3}):Play()
        task.delay(0.1, function()
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundTransparency = 0}):Play()
        end)
        callback()
    end)
    return btn
end

local function makeSlider(page, text, min, max, default, onChange)
    local f = Instance.new("Frame")
    f.Size            = UDim2.new(1, 0, 0, 52)
    f.BackgroundColor3= C.Card
    f.BorderSizePixel = 0
    f.Parent          = page
    corner(f, 10)

    local lbl = label(f, "  " .. text, 11, C.White)
    lbl.Size     = UDim2.new(0.7, 0, 0, 22)
    lbl.Position = UDim2.new(0, 0, 0, 2)

    local val = Instance.new("TextLabel")
    val.Size               = UDim2.new(0.28, 0, 0, 22)
    val.Position           = UDim2.new(0.72, 0, 0, 2)
    val.BackgroundTransparency = 1
    val.Text               = tostring(default)
    val.TextColor3         = C.Purple
    val.TextSize           = 11
    val.Font               = Enum.Font.GothamBold
    val.TextXAlignment     = Enum.TextXAlignment.Right
    val.Parent             = f

    local track = Instance.new("Frame")
    track.Size            = UDim2.new(1, -20, 0, 6)
    track.Position        = UDim2.new(0, 10, 1, -16)
    track.BackgroundColor3= C.Panel
    track.BorderSizePixel = 0
    track.Parent          = f
    corner(track, 3)

    local fill = Instance.new("Frame")
    fill.Size             = UDim2.new((default - min)/(max - min), 0, 1, 0)
    fill.BackgroundColor3 = C.Purple
    fill.BorderSizePixel  = 0
    fill.Parent           = track
    corner(fill, 3)

    local knob = Instance.new("TextButton")
    knob.Size             = UDim2.new(0, 14, 0, 14)
    knob.Position         = UDim2.new((default - min)/(max - min), -7, 0.5, -7)
    knob.BackgroundColor3 = C.White
    knob.Text             = ""
    knob.BorderSizePixel  = 0
    knob.Parent           = track
    corner(knob, 7)

    local dragging = false
    knob.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
            local pos    = track.AbsolutePosition
            local size   = track.AbsoluteSize
            local rel    = math.clamp((i.Position.X - pos.X) / size.X, 0, 1)
            local newVal = math.floor(min + rel * (max - min))
            val.Text  = tostring(newVal)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, -7, 0.5, -7)
            onChange(newVal)
        end
    end)

    return f
end

-- ─── Log Bar ───────────────────────────────────────────────────────────────
local LogBar = Instance.new("Frame")
LogBar.Size            = UDim2.new(1, -16, 0, 34)
LogBar.Position        = UDim2.new(0, 8, 1, -42)
LogBar.BackgroundColor3= C.Card
LogBar.BorderSizePixel = 0
LogBar.Parent          = Win
corner(LogBar, 10)

local LogText = label(LogBar, "  Ready — " .. #ScannedRemotes .. " remotes scanned", 10, C.Green, Enum.Font.Gotham)
LogText.Size     = UDim2.new(1, 0, 1, 0)
LogText.TextXAlignment = Enum.TextXAlignment.Left

local function log(msg, color)
    LogText.Text      = "  " .. msg
    LogText.TextColor3 = color or C.Green
end

-- ═══════════════════════════════════════════════════════════════════════════
-- COMBAT TAB
-- ═══════════════════════════════════════════════════════════════════════════
sectionTitle(PgCombat, "— Kill —")

makeButton(PgCombat, "⚡  Kill All Players", C.Red, function()
    KillAll()
    log("Kill All fired — firetouchinterest + Explosion", C.Red)
end)

makeToggle(PgCombat, "🌀  Aura Kill  (auto, proximity)", C.Red, function(on)
    State.AuraKill = on
    if on then StartAura(); log("Aura Kill ON — range: "..State.AuraRange.."studs", C.Red)
    else StopAura(); log("Aura Kill OFF", C.Muted) end
end)

makeSlider(PgCombat, "Aura Range (studs)", 4, 40, State.AuraRange, function(v)
    State.AuraRange = v
end)

makeToggle(PgCombat, "🔁  Loop Kill All  (every tick)", C.Red, function(on)
    if on then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then State.LoopKill[p.UserId] = true end
        end
        StartLoopKill()
        log("Loop Kill ON", C.Red)
    else
        StopLoopKill()
        log("Loop Kill OFF", C.Muted)
    end
end)

sectionTitle(PgCombat, "— Control —")

makeButton(PgCombat, "❄  Freeze All  (BodyPosition)", C.Blue, function()
    FreezeAll()
    log("Freeze All — BodyPosition on HRP (low-sec games)", C.Blue)
end)

makeButton(PgCombat, "🔓  Unfreeze All", C.Muted, function()
    UnfreezeAll()
    log("Unfreeze All", C.Muted)
end)

makeButton(PgCombat, "💥  Explode All  (Workspace Explosion)", C.Orange, function()
    ExplodeAll()
    log("Explode All — 100% server-replicates", C.Orange)
end)

makeButton(PgCombat, "🌪  Fling All  (Explosion + velocity)", C.Purple, function()
    FlingAll()
    log("Fling All fired", C.Purple)
end)

makeButton(PgCombat, "🧲  Bring All  (BodyPosition)", Color3.fromRGB(200, 50, 100), function()
    BringAll()
    log("Bring All — BodyPosition to your pos", C.Yellow)
end)

sectionTitle(PgCombat, "— Scan —")

makeButton(PgCombat, "🔍  Rescan Game Remotes", C.Purple, function()
    ScanRemotes()
    log("Scanned: " .. #ScannedRemotes .. " remotes found", C.Green)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- SELF TAB
-- ═══════════════════════════════════════════════════════════════════════════
sectionTitle(PgSelf, "— Movement —")

makeToggle(PgSelf, "✈  Fly  [W/A/S/D + Space/Ctrl]", C.Blue, function(on)
    State.Fly = on
    if on then StartFly(); log("Fly ON — replicates via BodyVelocity", C.Blue)
    else StopFly(); log("Fly OFF", C.Muted) end
end)

makeSlider(PgSelf, "Fly Speed", 10, 250, State.FlySpeed, function(v)
    State.FlySpeed = v
    log("Fly Speed: " .. v, C.Blue)
end)

makeToggle(PgSelf, "👻  Noclip  (walk through walls)", C.Purple, function(on)
    ToggleNoclip(on)
    log(on and "Noclip ON" or "Noclip OFF", on and C.Purple or C.Muted)
end)

makeSlider(PgSelf, "Walk Speed", 4, 200, State.Speed, function(v)
    SetSpeed(v)
    log("Speed set to: " .. v, C.Green)
end)

makeSlider(PgSelf, "Jump Power", 20, 300, State.JumpPower, function(v)
    SetJump(v)
    log("Jump Power: " .. v, C.Green)
end)

sectionTitle(PgSelf, "— Survival —")

makeToggle(PgSelf, "🛡  God Mode  (own character)", C.Yellow, function(on)
    ToggleGodMode(on)
    log(on and "God Mode ON" or "God Mode OFF", on and C.Yellow or C.Muted)
end)

makeButton(PgSelf, "❤  Heal Self", C.Green, function()
    local hum = MyHum()
    if hum then hum.Health = hum.MaxHealth end
    log("Healed to full", C.Green)
end)

sectionTitle(PgSelf, "— Vision —")

makeToggle(PgSelf, "🌕  Full Bright", C.Yellow, function(on)
    ToggleFullBright(on)
    log(on and "FullBright ON" or "FullBright OFF", on and C.Yellow or C.Muted)
end)

makeToggle(PgSelf, "🎯  ESP  (name + distance + HP)", C.Red, function(on)
    ToggleESP(on)
    log(on and "ESP ON" or "ESP OFF", on and C.Red or C.Muted)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- MISC TAB
-- ═══════════════════════════════════════════════════════════════════════════
sectionTitle(PgMisc, "— Navigate —")

do
    local playerBtns = Instance.new("Frame")
    playerBtns.Size            = UDim2.new(1, 0, 0, 0)
    playerBtns.BackgroundTransparency = 1
    playerBtns.AutomaticSize  = Enum.AutomaticSize.Y
    playerBtns.Parent          = PgMisc

    local pLayout = Instance.new("UIListLayout")
    pLayout.Padding  = UDim.new(0, 4)
    pLayout.Parent   = playerBtns

    local title = label(playerBtns, "  Teleport to player:", 10, C.Muted, Enum.Font.Gotham)
    title.Size = UDim2.new(1, 0, 0, 18)

    local function refreshPlayers()
        for _, c in ipairs(playerBtns:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                local btn = Instance.new("TextButton")
                btn.Size            = UDim2.new(1, 0, 0, 32)
                btn.BackgroundColor3= C.Card
                btn.Text            = "  → " .. p.DisplayName .. " (" .. p.Name .. ")"
                btn.TextColor3      = C.White
                btn.TextSize        = 11
                btn.Font            = Enum.Font.Gotham
                btn.TextXAlignment  = Enum.TextXAlignment.Left
                btn.Parent          = playerBtns
                corner(btn, 8)
                btn.MouseButton1Click:Connect(function()
                    TeleportTo(p)
                    log("Teleported to " .. p.Name, C.Blue)
                end)
            end
        end
    end
    refreshPlayers()
    Players.PlayerAdded:Connect(refreshPlayers)
    Players.PlayerRemoving:Connect(function() task.wait(0.1); refreshPlayers() end)
end

sectionTitle(PgMisc, "— Server —")

makeButton(PgMisc, "🌐  Server Hop  (random server)", C.Green, function()
    log("Server hopping...", C.Yellow)
    ServerHop()
end)

makeButton(PgMisc, "🔄  Rejoin  (same game)", C.Blue, function()
    TeleportService:Teleport(game.PlaceId, LP)
end)

makeButton(PgMisc, "🔍  Rescan Remotes", C.Purple, function()
    ScanRemotes()
    log("Rescan done — " .. #ScannedRemotes .. " remotes", C.Green)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- DRAGGING
-- ═══════════════════════════════════════════════════════════════════════════
local dragging, dragStart, startPos
Bar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging  = true
        dragStart = i.Position
        startPos  = Win.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging then
        local d = i.Position - dragStart
        Win.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- OPEN BUTTON (when window hidden)
-- ═══════════════════════════════════════════════════════════════════════════
local OpenBtn = Instance.new("TextButton")
OpenBtn.Size            = UDim2.new(0, 48, 0, 48)
OpenBtn.Position        = UDim2.new(0, 10, 0.5, -24)
OpenBtn.BackgroundColor3= C.Purple
OpenBtn.Text            = "☢"
OpenBtn.TextColor3      = C.White
OpenBtn.TextSize        = 22
OpenBtn.Font            = Enum.Font.GothamBlack
OpenBtn.Visible         = false
OpenBtn.Parent          = Gui
corner(OpenBtn, 24)

OpenBtn.MouseButton1Click:Connect(function()
    Win.Visible     = true
    OpenBtn.Visible = false
end)

-- Reopen when Win hidden
Win:GetPropertyChangedSignal("Visible"):Connect(function()
    OpenBtn.Visible = not Win.Visible
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- MOBILE FLY CONTROLS (touch D-pad)
-- ═══════════════════════════════════════════════════════════════════════════
local MobileUp, MobileDown = false, false

local MPanel = Instance.new("Frame")
MPanel.Size               = UDim2.new(0, 160, 0, 160)
MPanel.Position           = UDim2.new(1, -175, 1, -185)
MPanel.BackgroundTransparency = 1
MPanel.Parent             = Gui

local function mBtn(icon, pos)
    local b = Instance.new("TextButton")
    b.Size            = UDim2.new(0, 52, 0, 52)
    b.Position        = pos
    b.BackgroundColor3= Color3.fromRGB(30, 30, 50)
    b.BackgroundTransparency = 0.3
    b.Text            = icon
    b.TextColor3      = C.White
    b.TextSize        = 20
    b.Font            = Enum.Font.GothamBlack
    b.Parent          = MPanel
    corner(b, 26)
    stroke(b, C.Purple, 1)
    return b
end

local BtnUp   = mBtn("▲", UDim2.new(0.5, -26, 0, 0))
local BtnDown = mBtn("▼", UDim2.new(0.5, -26, 1, -52))
local BtnSpdP = mBtn("+", UDim2.new(1, -52, 0.5, -26))
local BtnSpdM = mBtn("−", UDim2.new(0,   0,  0.5, -26))

BtnUp.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch then MobileUp = true end
end)
BtnUp.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch then MobileUp = false end
end)
BtnDown.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch then MobileDown = true end
end)
BtnDown.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch then MobileDown = false end
end)
BtnSpdP.MouseButton1Click:Connect(function()
    State.FlySpeed = math.min(State.FlySpeed + 20, 250)
    log("Fly Speed: " .. State.FlySpeed, C.Blue)
end)
BtnSpdM.MouseButton1Click:Connect(function()
    State.FlySpeed = math.max(State.FlySpeed - 20, 10)
    log("Fly Speed: " .. State.FlySpeed, C.Blue)
end)

RunService.RenderStepped:Connect(function()
    if State.Fly and FlyBV then
        if MobileUp   then FlyBV.Velocity = Vector3.new(FlyBV.Velocity.X, State.FlySpeed,  FlyBV.Velocity.Z) end
        if MobileDown then FlyBV.Velocity = Vector3.new(FlyBV.Velocity.X, -State.FlySpeed, FlyBV.Velocity.Z) end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- BOOT SEQUENCE
-- ═══════════════════════════════════════════════════════════════════════════

-- Default to Combat tab
TabBtns["Combat"]:MouseButton1Click:Wait()
do
    -- Manually activate combat tab
    Pages["Combat"].Visible = true
    TabBtns["Combat"].TextColor3     = C.White
    TabBtns["Combat"].BackgroundColor3 = C.Purple
end

task.spawn(function()
    -- Scan remotes on load
    task.wait(1.5)
    ScanRemotes()
    log("Loaded — " .. #ScannedRemotes .. " remotes scanned | Skyfall v7", C.Green)
    StatusDot.BackgroundColor3 = C.Green

    -- Boot toast
    local toast = Instance.new("Frame")
    toast.Size            = UDim2.new(0, 340, 0, 56)
    toast.Position        = UDim2.new(0.5, -170, 0, -70)
    toast.BackgroundColor3= C.Panel
    toast.BorderSizePixel = 0
    toast.Parent          = Gui
    corner(toast, 14)
    stroke(toast, C.Purple, 1.5)

    local tl = label(toast, "  ☢  SKYFALL HUB v7  |  Fixed Replication Build", 13, C.Purple, Enum.Font.GothamBlack)
    tl.Size     = UDim2.new(1, 0, 0.6, 0)
    tl.Position = UDim2.new(0, 0, 0, 0)
    local tl2 = label(toast, "  " .. #ScannedRemotes .. " remotes | firetouchinterest + Explosion layers active", 10, C.Muted, Enum.Font.Gotham)
    tl2.Size     = UDim2.new(1, 0, 0.4, 0)
    tl2.Position = UDim2.new(0, 0, 0.6, 0)

    TweenService:Create(toast, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, -170, 0, 20)
    }):Play()
    task.delay(4, function()
        TweenService:Create(toast, TweenInfo.new(0.4), {
            Position = UDim2.new(0.5, -170, 0, -70)
        }):Play()
        task.delay(0.5, function() toast:Destroy() end)
    end)
end)

-- Force open combat tab on load (after Wait() resolved)
task.defer(function()
    Pages["Combat"].Visible          = true
    TabBtns["Combat"].TextColor3     = C.White
    TabBtns["Combat"].BackgroundColor3 = C.Purple
end)

print("[☢ SKYFALL HUB v7] Loaded | Anti-kick active | Awaiting remote scan...")
