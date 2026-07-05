-- THESKYFALL-HUB v30.1 ORION EDITION
-- Converted from Rayfield | Delta Compatible | Follow 25 Studs

local success, OrionLib = pcall(function()
    return loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Orion/main/source'))()
end)

if not success then
    warn("[SKYFALL] Failed to load Orion! Try updating Delta.")
    return
end

local Window = OrionLib:MakeWindow({Name = "THESKYFALL-HUB v30.1", HidePremium = false, SaveConfig = true, ConfigFolder = "SkyfallHub"})

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local WS = game:GetService("Workspace")
local TCS = game:GetService("TextChatService")
local RepSt = game:GetService("ReplicatedStorage")
local LT = game:GetService("Lighting")
local TeleS = game:GetService("TeleportService")

local Char = LP.Character or LP.CharacterAdded:Wait()
local Hum = Char:FindFirstChildWhichIsA("Humanoid")
local RP = Char:FindFirstChild("HumanoidRootPart")
local Cam = WS.CurrentCamera

local PS = {WalkSpeed=16, JumpPower=50, FlySpeed=50, HoverHeight=12, FollowHeight=25, FollowDistance=10}
local Binds = {}
local SelectedPlr = nil
local FollowTgt = nil
local LastSafe = RP and RP.CFrame or CFrame.new(0,10,0)

local function SB(n,p,f)
    pcall(function() RS:UnbindFromRenderStep(n) end)
    RS:BindToRenderStep(n,p,f)
    Binds[n] = true
end

local function SU(n)
    pcall(function() RS:UnbindFromRenderStep(n) end)
    Binds[n] = nil
end

local function ApplyStats()
    pcall(function()
        if Hum then
            Hum.WalkSpeed = PS.WalkSpeed
            Hum.JumpPower = PS.JumpPower
        end
    end)
end

local function GroundH(pos)
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {Char}
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local r = WS:Raycast(Vector3.new(pos.X, pos.Y+200, pos.Z), Vector3.new(0,-600,0), rp)
    return r and r.Position.Y or (pos.Y - 20)
end

local function GetKiller()
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Team then
            local t = string.lower(tostring(p.Team.Name))
            if string.find(t,"killer") or string.find(t,"murderer") then
                return p.Character
            end
        end
    end
    return nil
end

local function SendChat(msg)
    pcall(function()
        if TCS.ChatVersion == Enum.ChatVersion.LegacyChatService then
            local ce = RepSt:FindFirstChild("DefaultChatSystemChatEvents")
            if ce then
                local sm = ce:FindFirstChild("SayMessageRequest")
                if sm then sm:FireServer(msg,"All") end
            end
        else
            local ch = TCS:FindFirstChild("TextChannels") and TCS.TextChannels:FindFirstChild("RBXGeneral")
            if ch then ch:SendAsync(msg) end
        end
    end)
end

-- MOVEMENT TAB
local MoveTab = Window:MakeTab({Name = "Movement", Icon = "rbxassetid://7733960981"})

MoveTab:AddSlider({Name = "WalkSpeed", Min = 16, Max = 500, Default = 16, Increment = 1, Callback = function(v) PS.WalkSpeed = v; ApplyStats() end})
MoveTab:AddSlider({Name = "JumpPower", Min = 50, Max = 1000, Default = 50, Increment = 1, Callback = function(v) PS.JumpPower = v; ApplyStats() end})

MoveTab:AddToggle({Name = "Fly (WASD+Space+Ctrl)", Default = false, Callback = function(s)
    if s then
        pcall(function() Hum.PlatformStand = true end)
        SB("Fly", Enum.RenderPriority.Character.Value+1, function()
            local m = Vector3.zero
            local lk = Cam.CFrame.LookVector
            local rt = Cam.CFrame.RightVector
            if UIS:IsKeyDown(Enum.KeyCode.W) then m = m + lk end
            if UIS:IsKeyDown(Enum.KeyCode.S) then m = m - lk end
            if UIS:IsKeyDown(Enum.KeyCode.A) then m = m - rt end
            if UIS:IsKeyDown(Enum.KeyCode.D) then m = m + rt end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then m = m + Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then m = m - Vector3.new(0,1,0) end
            if RP then RP.AssemblyLinearVelocity = m.Magnitude > 0 and m.Unit * PS.FlySpeed or Vector3.zero end
        end)
    else
        SU("Fly")
        pcall(function() Hum.PlatformStand = false end)
        if RP then RP.AssemblyLinearVelocity = Vector3.zero end
    end
end})

MoveTab:AddSlider({Name = "Fly Speed", Min = 10, Max = 500, Default = 50, Increment = 1, Callback = function(v) PS.FlySpeed = v end})

MoveTab:AddToggle({Name = "NoClip", Default = false, Callback = function(s)
    if s then
        SB("NoClip", Enum.RenderPriority.Character.Value+1, function()
            pcall(function()
                for _,P in ipairs(Char:GetDescendants()) do
                    if P:IsA("BasePart") then P.CanCollide = false end
                end
            end)
        end)
    else
        SU("NoClip")
        pcall(function()
            for _,P in ipairs(Char:GetDescendants()) do
                if P:IsA("BasePart") then P.CanCollide = true end
            end
        end)
    end
end})

MoveTab:AddToggle({Name = "Infinite Jump", Default = false, Callback = function(s)
    if s and Hum then
        Hum.StateChanged:Connect(function(_,n)
            if n == Enum.HumanoidStateType.Freefall then
                pcall(function() Hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
            end
        end)
    end
end})

MoveTab:AddToggle({Name = "Anti-Fall (Anti-Void)", Default = false, Callback = function(s)
    if s then
        SB("AntiFall", Enum.RenderPriority.Character.Value+2, function()
            if RP and RP.Position.Y < -50 then
                RP.CFrame = LastSafe + Vector3.new(0,5,0)
                RP.AssemblyLinearVelocity = Vector3.zero
            elseif RP then
                LastSafe = RP.CFrame
            end
        end)
    else
        SU("AntiFall")
    end
end})

MoveTab:AddButton({Name = "TP to Nearest Player", Callback = function()
    local n, md = nil, math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local d = (p.Character.HumanoidRootPart.Position - RP.Position).Magnitude
            if d < md then md = d; n = p end
        end
    end
    if n and RP then RP.CFrame = n.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,3) end
end})

MoveTab:AddButton({Name = "⚡ ALL-IN-ONE (God+InfHP+NoClip+InfJump)", Callback = function()
    PS.WalkSpeed = 100; PS.JumpPower = 200; ApplyStats()
    SB("AIO_NC", Enum.RenderPriority.Character.Value+1, function()
        pcall(function()
            for _,P in ipairs(Char:GetDescendants()) do
                if P:IsA("BasePart") then P.CanCollide = false end
            end
        end)
    end)
    SB("AIO_HP", Enum.RenderPriority.Character.Value+2, function()
        pcall(function() Hum.MaxHealth = math.huge; Hum.Health = math.huge end)
    end)
    OrionLib:MakeNotification({Name = "ALL-IN-ONE", Content = "Activated!", Image = "rbxassetid://773365896", Time = 3})
end})

MoveTab:AddButton({Name = "🆘 EMERGENCY RESET ALL", Callback = function()
    PS.WalkSpeed = 16; PS.JumpPower = 50; ApplyStats()
    for k,_ in pairs(Binds) do SU(k) end
    pcall(function() Hum.PlatformStand = false end)
    pcall(function()
        for _,P in ipairs(Char:GetDescendants()) do
            if P:IsA("BasePart") or P:IsA("Decal") then
                P.CanCollide = true; P.Transparency = 0
            end
        end
    end)
    Cam.CameraType = Enum.CameraType.Custom
    WS.Gravity = 196.2
    OrionLib:MakeNotification({Name = "RESET", Content = "All features disabled!", Image = "rbxassetid://773365896", Time = 3})
end})

-- FOLLOW TAB
local FollowTab = Window:MakeTab({Name = "Follow", Icon = "rbxassetid://7733960981"})

FollowTab:AddDropdown({Name = "Select Player", Options = {"None"}, Default = "None", Callback = function(opt)
    for _,p in ipairs(Players:GetPlayers()) do
        if p.DisplayName == opt or p.Name == opt then SelectedPlr = p; break end
    end
end})

task.spawn(function()
    while true do
        task.wait(3)
        pcall(function()
            -- Auto refresh dropdown (Orion limitation: manual re-add needed)
        end)
    end
end)

FollowTab:AddSlider({Name = "Follow Height", Min = 5, Max = 50, Default = 25, Increment = 1, Callback = function(v) PS.FollowHeight = v end})
FollowTab:AddSlider({Name = "Follow Distance", Min = 3, Max = 30, Default = 10, Increment = 1, Callback = function(v) PS.FollowDistance = v end})

FollowTab:AddButton({Name = "🎯 START FOLLOWING (Height: 25)", Callback = function()
    if not SelectedPlr then
        OrionLib:MakeNotification({Name = "Error", Content = "Select player first!", Time = 3})
        return
    end
    FollowTgt = SelectedPlr
    SB("FollowPlr", Enum.RenderPriority.Character.Value+1, function()
        if not FollowTgt or not FollowTgt.Parent then SU("FollowPlr"); return end
        local tc = FollowTgt.Character
        if not tc or not tc:FindFirstChild("HumanoidRootPart") then return end
        local tRP = tc.HumanoidRootPart
        local tPos = tRP.Position
        local myGY = GroundH(RP.Position)
        local hoverY = myGY + PS.FollowHeight
        if hoverY > myGY + 40 then hoverY = myGY + 40 end
        local tLook = tRP.CFrame.LookVector
        local bo = -tLook * PS.FollowDistance
        local fp = Vector3.new(tPos.X + bo.X, hoverY, tPos.Z + bo.Z)
        local d3 = (RP.Position - fp).Magnitude
        local sp = d3 > 50 and 0.35 or d3 > 20 and 0.2 or 0.12
        local np = RP.Position:Lerp(fp, sp)
        local mv = (np - RP.Position) * 15
        RP.AssemblyLinearVelocity = Vector3.new(
            math.clamp(mv.X, -80, 80),
            math.clamp(mv.Y, -40, 40),
            math.clamp(mv.Z, -80, 80)
        )
    end)
    OrionLib:MakeNotification({Name = "Following", Content = FollowTgt.DisplayName.." | Height: "..PS.FollowHeight, Time = 3})
end})

FollowTab:AddButton({Name = "🛑 STOP FOLLOWING", Callback = function()
    SU("FollowPlr"); FollowTgt = nil
    if RP then RP.AssemblyLinearVelocity = Vector3.zero end
    OrionLib:MakeNotification({Name = "Stopped", Content = "No longer following", Time = 2})
end})

FollowTab:AddToggle({Name = "🎭 Troll Hover", Default = false, Callback = function(s)
    if s then
        SB("TrollHover", Enum.RenderPriority.Character.Value+1, function()
            if Hum and Hum.FloorMaterial == Enum.Material.Air then
                local gy = GroundH(RP.Position)
                local ty = gy + PS.HoverHeight
                if ty > gy + 30 then ty = gy + 30 end
                local cv = RP.AssemblyLinearVelocity
                RP.AssemblyLinearVelocity = Vector3.new(cv.X, math.clamp((ty - RP.Position.Y)*5, -30, 30), cv.Z)
            end
        end)
    else
        SU("TrollHover")
    end
end})

-- REPORT TAB
local ReportTab = Window:MakeTab({Name = "Report", Icon = "rbxassetid://7733960981"})

ReportTab:AddDropdown({Name = "Select Player to Report", Options = {"None"}, Default = "None", Callback = function(opt)
    for _,p in ipairs(Players:GetPlayers()) do
        if p.DisplayName == opt or p.Name == opt then SelectedPlr = p; break end
    end
end})

ReportTab:AddButton({Name = "🔍 Scan All Exploiters", Callback = function()
    local count = 0
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local h = p.Character:FindFirstChild("Humanoid")
            local r = p.Character:FindFirstChild("HumanoidRootPart")
            if h and r then
                local flags = {}
                if h.WalkSpeed > 100 then table.insert(flags, "Speed") end
                if h.Health > 500 then table.insert(flags, "InfHP") end
                if r.Position.Y - GroundH(r.Position) > 25 then table.insert(flags, "Fly") end
                if #flags > 0 then
                    count = count + 1
                    print("[SKYFALL] Suspect: "..p.Name.." | "..table.concat(flags, ", "))
                end
            end
        end
    end
    OrionLib:MakeNotification({Name = "Scan Complete", Content = "Found "..count.." exploiters (check console)", Time = 4})
end})

ReportTab:AddButton({Name = "📋 Report Selected Player", Callback = function()
    if not SelectedPlr then
        OrionLib:MakeNotification({Name = "Error", Content = "Select player first!", Time = 3})
        return
    end
    SendChat("REPORT: "..SelectedPlr.DisplayName.." - Suspicious Activity")
    OrionLib:MakeNotification({Name = "Reported!", Content = SelectedPlr.DisplayName, Time = 3})
end})

ReportTab:AddButton({Name = "⚡ Report ALL Exploiters", Callback = function()
    local c = 0
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local h = p.Character:FindFirstChild("Humanoid")
            if h and (h.WalkSpeed > 100 or h.Health > 500) then
                SendChat("REPORT: "..p.DisplayName.." - Exploiting")
                c = c + 1
            end
        end
    end
    OrionLib:MakeNotification({Name = "Mass Report", Content = "Reported "..c.." players", Time = 3})
end})

-- KILLER TAB
local KillerTab = Window:MakeTab({Name = "Killer", Icon = "rbxassetid://7733960981"})

KillerTab:AddToggle({Name = "👁️ Player ESP", Default = false, Callback = function(s)
    if s then
        SB("ESP", Enum.RenderPriority.Camera.Value, function()
            for _,p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character and p.Character:FindFirstChild("Head") then
                    if not p.Character.Head:FindFirstChild("ESP_BB") then
                        local bb = Instance.new("BillboardGui")
                        bb.Name = "ESP_BB"; bb.Size = UDim2.new(0,200,0,50)
                        bb.StudsOffset = Vector3.new(0,3,0); bb.AlwaysOnTop = true
                        bb.Parent = p.Character.Head
                        local tl = Instance.new("TextLabel")
                        tl.Size = UDim2.new(1,0,1,0); tl.BackgroundTransparency = 1
                        tl.TextColor3 = Color3.fromRGB(255,50,50); tl.TextSize = 14
                        tl.Font = Enum.Font.GothamBold; tl.TextStrokeTransparency = 0
                        tl.Parent = bb
                    end
                    local bb = p.Character.Head:FindFirstChild("ESP_BB")
                    if bb then
                        bb.TextLabel.Text = p.DisplayName.." ["..math.floor((p.Character.Head.Position - RP.Position).Magnitude).."]"
                    end
                end
            end
        end)
    else
        SU("ESP")
        for _,p in ipairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("Head") then
                local bb = p.Character.Head:FindFirstChild("ESP_BB")
                if bb then bb:Destroy() end
            end
        end
    end
end})

KillerTab:AddToggle({Name = "🎥 Killer POV", Default = false, Callback = function(s)
    if s then
        local k = GetKiller()
        if k and k:FindFirstChild("Humanoid") then
            Cam.CameraSubject = k.Humanoid
        else
            OrionLib:MakeNotification({Name = "Error", Content = "No killer found", Time = 2})
        end
    else
        Cam.CameraSubject = Hum
    end
end})

KillerTab:AddToggle({Name = "🎯 Expand Hitbox (10x)", Default = false, Callback = function(s)
    if s then
        SB("Hitbox", Enum.RenderPriority.Character.Value+1, function()
            for _,p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    pcall(function()
                        p.Character.HumanoidRootPart.Size = Vector3.new(10,10,10)
                        p.Character.HumanoidRootPart.Transparency = 0.7
                    end)
                end
            end
        end)
    else
        SU("Hitbox")
        for _,p in ipairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                pcall(function()
                    p.Character.HumanoidRootPart.Size = Vector3.new(2,2,1)
                    p.Character.HumanoidRootPart.Transparency = 1
                end)
            end
        end
    end
end})

KillerTab:AddButton({Name = "💀 Kill All Players", Callback = function()
    local c = 0
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("Humanoid") then
            pcall(function() p.Character.Humanoid.Health = 0; c = c + 1 end)
        end
    end
    OrionLib:MakeNotification({Name = "Kill Aura", Content = "Killed "..c.." players", Time = 3})
end})

-- RARE TAB
local RareTab = Window:MakeTab({Name = "Rare", Icon = "rbxassetid://7733960981"})

RareTab:AddToggle({Name = "🤺 Auto-Parry", Default = false, Callback = function(s)
    if s then
        SB("AutoParry", Enum.RenderPriority.Character.Value+2, function()
            for _,p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    if (p.Character.HumanoidRootPart.Position - RP.Position).Magnitude < 8 then
                        local sd = RP.CFrame.RightVector * (math.random(0,1) == 0 and 1 or -1)
                        pcall(function() RP.AssemblyLinearVelocity = RP.AssemblyLinearVelocity + sd*40 + Vector3.new(0,15,0) end)
                    end
                end
            end
        end)
    else
        SU("AutoParry")
    end
end})

RareTab:AddToggle({Name = "🛡️ Anti-Grab", Default = false, Callback = function(s)
    if s then
        SB("AntiGrab", Enum.RenderPriority.Character.Value+3, function()
            local st = Hum:GetState()
            if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll then
                pcall(function() Hum:ChangeState(Enum.HumanoidStateType.GettingUp); RP.AssemblyLinearVelocity = Vector3.new(0,60,0) end)
            end
            for _,obj in ipairs(Char:GetDescendants()) do
                if obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") then pcall(function() obj:Destroy() end) end
            end
        end)
    else
        SU("AntiGrab")
    end
end})

RareTab:AddButton({Name = "⏪ Time Rewind", Callback = function()
    if RP then RP.CFrame = LastSafe end
    OrionLib:MakeNotification({Name = "Time Rewind", Content = "Returned to previous position!", Time = 2})
end})

RareTab:AddButton({Name = "💀 Fake Death", Callback = function()
    pcall(function() Hum.Health = 0 end)
    task.delay(3, function() pcall(function() Hum.Health = Hum.MaxHealth end) end)
    OrionLib:MakeNotification({Name = "Fake Death", Content = "Playing dead for 3 seconds...", Time = 3})
end})

RareTab:AddButton({Name = "🧲 Gravity Gun (5s)", Callback = function()
    SB("GravGun", Enum.RenderPriority.Character.Value+1, function()
        for _,o in ipairs(WS:GetDescendants()) do
            if o:IsA("BasePart") and not o:IsDescendantOf(Char) and not o.Anchored and (o.Position - RP.Position).Magnitude < 40 then
                pcall(function() o.AssemblyLinearVelocity = (RP.Position - o.Position).Unit * 60 end)
            end
        end
    end)
    task.delay(5, function() SU("GravGun") end)
    OrionLib:MakeNotification({Name = "Gravity Gun", Content = "Active for 5 seconds!", Time = 5})
end})

RareTab:AddToggle({Name = "👻 True Invisible", Default = false, Callback = function(s)
    if s then
        SB("TrueInvis", Enum.RenderPriority.Character.Value+1, function()
            pcall(function()
                for _,P in ipairs(Char:GetDescendants()) do
                    if P:IsA("BasePart") or P:IsA("Decal") then P.Transparency = 1; P.CanCollide = false end
                end
            end)
        end)
    else
        SU("TrueInvis")
        pcall(function()
            for _,P in ipairs(Char:GetDescendants()) do
                if P:IsA("BasePart") or P:IsA("Decal") then P.Transparency = 0; P.CanCollide = true end
            end
        end)
    end
end})

-- FPS TAB
local FPSTab = Window:MakeTab({Name = "FPS", Icon = "rbxassetid://7733960981"})

FPSTab:AddToggle({Name = "🔥 Insane FPS Boost", Default = false, Callback = function(s)
    if s then
        pcall(function() setfpscap(0) end)
        SB("InsaneFPS", Enum.RenderPriority.Camera.Value-1, function()
            pcall(function()
                for _,e in ipairs(LT:GetChildren()) do
                    if e:IsA("PostProcessEffect") or e:IsA("BlurEffect") or e:IsA("BloomEffect") then e.Enabled = false end
                end
                LT.GlobalShadows = false; LT.FogEnd = 100000
                for _,p in ipairs(WS:GetDescendants()) do
                    if p:IsA("ParticleEmitter") or p:IsA("Smoke") or p:IsA("Fire") or p:IsA("Trail") then p.Enabled = false end
                end
            end)
        end)
    else
        SU("InsaneFPS")
        pcall(function() setfpscap(60) end)
        LT.GlobalShadows = true; LT.FogEnd = 1000
    end
end})

FPSTab:AddToggle({Name = "No Shadows", Default = false, Callback = function(s) LT.GlobalShadows = not s end})
FPSTab:AddToggle({Name = "No Fog", Default = false, Callback = function(s) LT.FogEnd = s and 100000 or 1000 end})

-- SETTINGS TAB
local SetTab = Window:MakeTab({Name = "Settings", Icon = "rbxassetid://7733960981"})

SetTab:AddButton({Name = "Rejoin Server", Callback = function() pcall(function() TeleS:TeleportToPlaceInstance(game.PlaceId, game.JobId) end) end})
SetTab:AddButton({Name = "Server Hop", Callback = function()
    pcall(function()
        local Http = game:GetService("HttpService")
        local r = Http:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
        if r and r.data then
            local sv = {}
            for _,v in ipairs(r.data) do if v.id and v.id ~= game.JobId then table.insert(sv, v.id) end end
            if #sv > 0 then TeleS:TeleportToPlaceInstance(game.PlaceId, sv[math.random(1,#sv)]) end
        end
    end)
end})
SetTab:AddButton({Name = "Destroy GUI", Callback = function() pcall(function() OrionLib:Destroy() end) end})

-- RESPAWN HANDLER
LP.CharacterAdded:Connect(function(char)
    Char = char
    Hum = char:FindFirstChildWhichIsA("Humanoid")
    RP = char:FindFirstChild("HumanoidRootPart")
    Cam = WS.CurrentCamera
    LastSafe = RP and RP.CFrame or CFrame.new(0,10,0)
    task.wait(0.5)
    ApplyStats()
end)

OrionLib:MakeNotification({Name = "THESKYFALL-HUB v30.1", Content = "Loaded! Follow Height: 25 Studs", Time = 5})
print("[SKYFALL v30.1] LOADED | Orion Edition | Follow: 25 studs")
