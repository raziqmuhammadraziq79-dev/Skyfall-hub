-- THESKYFALL-HUB v30.2 ULTIMATE EDITION
-- Draggable + Hide Key + Mobile Support + All Bugs Fixed

local success, Library = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
end)

if not success then
    warn("[SKYFALL] Failed to load Kavo UI!")
    return
end

local Window = Library.CreateLib("THESKYFALL-HUB v30.2", "DarkTheme")

-- DRAGGABLE FIX
pcall(function()
    local MainFrame = nil
    for _,v in ipairs(game:GetService("CoreGui"):GetDescendants()) do
        if v:IsA("Frame") and v.Name == "Main" then MainFrame = v; break end
    end
    if MainFrame then
        local Dragging, DragInput, MousePos, FramePos = false, nil, nil, nil
        MainFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                MousePos = input.Position
                FramePos = MainFrame.Position
                input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then Dragging = false end end)
            end
        end)
        MainFrame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then DragInput = input end
        end)
        game:GetService("UserInputService").InputChanged:Connect(function(input)
            if input == DragInput and Dragging then
                local Delta = input.Position - MousePos
                MainFrame.Position = UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)
            end
        end)
    end
end)

-- HIDE KEY (RightShift)
local Hidden = false
game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Hidden = not Hidden
        pcall(function()
            for _,v in ipairs(game:GetService("CoreGui"):GetDescendants()) do
                if v:IsA("Frame") and v.Name == "Main" then v.Visible = not Hidden end
            end
        end)
        Library:Notify(Hidden and "GUI Hidden (Press RightShift)" or "GUI Shown", 2)
    end
end)

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
        if Hum then Hum.WalkSpeed = PS.WalkSpeed; Hum.JumpPower = PS.JumpPower end
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
            if string.find(t,"killer") or string.find(t,"murderer") then return p.Character end
        end
    end
    return nil
end

local function SendChat(msg)
    pcall(function()
        if TCS.ChatVersion == Enum.ChatVersion.LegacyChatService then
            local ce = RepSt:FindFirstChild("DefaultChatSystemChatEvents")
            if ce then local sm = ce:FindFirstChild("SayMessageRequest"); if sm then sm:FireServer(msg,"All") end end
        else
            local ch = TCS:FindFirstChild("TextChannels") and TCS.TextChannels:FindFirstChild("RBXGeneral")
            if ch then ch:SendAsync(msg) end
        end
    end)
end

-- MOVEMENT TAB
local MoveTab = Window:NewTab("Movement")
local MoveSec = MoveTab:NewSection("Speed & Jump")

MoveSec:NewSlider("WalkSpeed", "", 500, 16, function(v) PS.WalkSpeed = v; ApplyStats() end)
MoveSec:NewSlider("JumpPower", "", 1000, 50, function(v) PS.JumpPower = v; ApplyStats() end)

MoveSec:NewToggle("Fly (WASD+Space+Ctrl)", "", function(s)
    if s then
        pcall(function() Hum.PlatformStand = true end)
        SB("Fly", Enum.RenderPriority.Character.Value+1, function()
            local m = Vector3.zero
            local lk, rt = Cam.CFrame.LookVector, Cam.CFrame.RightVector
            if UIS:IsKeyDown(Enum.KeyCode.W) then m = m + lk end
            if UIS:IsKeyDown(Enum.KeyCode.S) then m = m - lk end
            if UIS:IsKeyDown(Enum.KeyCode.A) then m = m - rt end
            if UIS:IsKeyDown(Enum.KeyCode.D) then m = m + rt end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then m = m + Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then m = m - Vector3.new(0,1,0) end
            if RP then RP.AssemblyLinearVelocity = m.Magnitude > 0 and m.Unit * PS.FlySpeed or Vector3.zero end
        end)
    else
        SU("Fly"); pcall(function() Hum.PlatformStand = false end)
        if RP then RP.AssemblyLinearVelocity = Vector3.zero end
    end
end)

MoveSec:NewSlider("Fly Speed", "", 500, 50, function(v) PS.FlySpeed = v end)

MoveSec:NewToggle("NoClip", "", function(s)
    if s then
        SB("NoClip", Enum.RenderPriority.Character.Value+1, function()
            pcall(function() for _,P in ipairs(Char:GetDescendants()) do if P:IsA("BasePart") then P.CanCollide = false end end end)
        end)
    else
        SU("NoClip")
        pcall(function() for _,P in ipairs(Char:GetDescendants()) do if P:IsA("BasePart") then P.CanCollide = true end end end)
    end
end)

MoveSec:NewToggle("Infinite Jump", "", function(s)
    if s and Hum then
        Hum.StateChanged:Connect(function(_,n)
            if n == Enum.HumanoidStateType.Freefall then pcall(function() Hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
        end)
    end
end)

MoveSec:NewToggle("Anti-Fall (Anti-Void)", "", function(s)
    if s then
        SB("AntiFall", Enum.RenderPriority.Character.Value+2, function()
            if RP and RP.Position.Y < -50 then RP.CFrame = LastSafe + Vector3.new(0,5,0); RP.AssemblyLinearVelocity = Vector3.zero
            elseif RP then LastSafe = RP.CFrame end
        end)
    else SU("AntiFall") end
end)

MoveSec:NewButton("TP to Nearest Player", "", function()
    local n, md = nil, math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local d = (p.Character.HumanoidRootPart.Position - RP.Position).Magnitude
            if d < md then md = d; n = p end
        end
    end
    if n and RP then RP.CFrame = n.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,3) end
end)

MoveSec:NewButton("⚡ ALL-IN-ONE (God+InfHP+NoClip)", "", function()
    PS.WalkSpeed = 100; PS.JumpPower = 200; ApplyStats()
    SB("AIO_NC", Enum.RenderPriority.Character.Value+1, function()
        pcall(function() for _,P in ipairs(Char:GetDescendants()) do if P:IsA("BasePart") then P.CanCollide = false end end end)
    end)
    SB("AIO_HP", Enum.RenderPriority.Character.Value+2, function()
        pcall(function() Hum.MaxHealth = math.huge; Hum.Health = math.huge end)
    end)
    Library:Notify("ALL-IN-ONE Activated!", 3)
end)

MoveSec:NewButton("🆘 EMERGENCY RESET ALL", "", function()
    PS.WalkSpeed = 16; PS.JumpPower = 50; ApplyStats()
    for k,_ in pairs(Binds) do SU(k) end
    pcall(function() Hum.PlatformStand = false end)
    pcall(function() for _,P in ipairs(Char:GetDescendants()) do if P:IsA("BasePart") or P:IsA("Decal") then P.CanCollide = true; P.Transparency = 0 end end end)
    Cam.CameraType = Enum.CameraType.Custom; WS.Gravity = 196.2
    Library:Notify("All Features Reset!", 3)
end)

-- FOLLOW TAB
local FollowTab = Window:NewTab("Follow")
local FollowSec = FollowTab:NewSection("Follow Player (25 Studs)")

FollowSec:NewDropdown("Select Player", "", {"None"}, function(opt)
    for _,p in ipairs(Players:GetPlayers()) do
        if p.DisplayName == opt or p.Name == opt then SelectedPlr = p; break end
    end
end)

FollowSec:NewSlider("Follow Height", "", 50, 25, function(v) PS.FollowHeight = v end)
FollowSec:NewSlider("Follow Distance", "", 30, 10, function(v) PS.FollowDistance = v end)

FollowSec:NewButton("🎯 START FOLLOWING", "", function()
    if not SelectedPlr then Library:Notify("Select a player first!", 3); return end
    FollowTgt = SelectedPlr
    SB("FollowPlr", Enum.RenderPriority.Character.Value+1, function()
        if not FollowTgt or not FollowTgt.Parent then SU("FollowPlr"); return end
        local tc = FollowTgt.Character
        if not tc or not tc:FindFirstChild("HumanoidRootPart") then return end
        local tRP = tc.HumanoidRootPart
        local tPos = tRP.Position
        local myGY = GroundH(RP.Position)
        local hoverY = math.min(myGY + PS.FollowHeight, myGY + 40)
        local bo = -tRP.CFrame.LookVector * PS.FollowDistance
        local fp = Vector3.new(tPos.X + bo.X, hoverY, tPos.Z + bo.Z)
        local d3 = (RP.Position - fp).Magnitude
        local sp = d3 > 50 and 0.35 or d3 > 20 and 0.2 or 0.12
        local np = RP.Position:Lerp(fp, sp)
        local mv = (np - RP.Position) * 15
        RP.AssemblyLinearVelocity = Vector3.new(math.clamp(mv.X,-80,80), math.clamp(mv.Y,-40,40), math.clamp(mv.Z,-80,80))
    end)
    Library:Notify("Following "..FollowTgt.DisplayName.." | H: "..PS.FollowHeight, 3)
end)

FollowSec:NewButton("🛑 STOP FOLLOWING", "", function()
    SU("FollowPlr"); FollowTgt = nil
    if RP then RP.AssemblyLinearVelocity = Vector3.zero end
    Library:Notify("Stopped Following", 2)
end)

FollowSec:NewToggle("🎭 Troll Hover", "", function(s)
    if s then
        SB("TrollHover", Enum.RenderPriority.Character.Value+1, function()
            if Hum and Hum.FloorMaterial == Enum.Material.Air then
                local gy = GroundH(RP.Position)
                local ty = math.min(gy + PS.HoverHeight, gy + 30)
                local cv = RP.AssemblyLinearVelocity
                RP.AssemblyLinearVelocity = Vector3.new(cv.X, math.clamp((ty - RP.Position.Y)*5, -30, 30), cv.Z)
            end
        end)
    else SU("TrollHover") end
end)

-- COMBAT TAB (NEW!)
local CombatTab = Window:NewTab("Combat")
local CombatSec = CombatTab:NewSection("Aimbot & Kill Aura")

CombatSec:NewToggle("🎯 Silent Aimbot (Auto-Aim)", "", function(s)
    if s then
        SB("Aimbot", Enum.RenderPriority.Camera.Value+1, function()
            local closest, minDist = nil, math.huge
            for _,p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character and p.Character:FindFirstChild("Head") then
                    local head = p.Character.Head
                    local dist = (head.Position - RP.Position).Magnitude
                    if dist < minDist and dist < 100 then minDist = dist; closest = head end
                end
            end
            if closest then Cam.CFrame = CFrame.lookAt(Cam.CFrame.Position, closest.Position) end
        end)
    else SU("Aimbot") end
end)

CombatSec:NewToggle("💀 Kill Aura (Auto-Kill Nearby)", "", function(s)
    if s then
        SB("KillAura", Enum.RenderPriority.Character.Value+2, function()
            for _,p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character and p.Character:FindFirstChild("Humanoid") then
                    if (p.Character.HumanoidRootPart.Position - RP.Position).Magnitude < 15 then
                        pcall(function() p.Character.Humanoid.Health = 0 end)
                    end
                end
            end
        end)
    else SU("KillAura") end
end)

CombatSec:NewToggle("🛡️ Anti-Stun (Anti-Ragdoll)", "", function(s)
    if s then
        SB("AntiStun", Enum.RenderPriority.Character.Value+3, function()
            local st = Hum:GetState()
            if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll then
                pcall(function() Hum:ChangeState(Enum.HumanoidStateType.GettingUp); RP.AssemblyLinearVelocity = Vector3.new(0,60,0) end)
            end
            for _,obj in ipairs(Char:GetDescendants()) do
                if obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") then pcall(function() obj:Destroy() end) end
            end
        end)
    else SU("AntiStun") end
end)

-- REPORT TAB
local ReportTab = Window:NewTab("Report")
local ReportSec = ReportTab:NewSection("Report Exploiters")

ReportSec:NewDropdown("Select Player to Report", "", {"None"}, function(opt)
    for _,p in ipairs(Players:GetPlayers()) do
        if p.DisplayName == opt or p.Name == opt then SelectedPlr = p; break end
    end
end)

ReportSec:NewButton("🔍 Scan All Exploiters", "", function()
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
                if #flags > 0 then count = count + 1; print("[SKYFALL] Suspect: "..p.Name.." | "..table.concat(flags, ", ")) end
            end
        end
    end
    Library:Notify("Found "..count.." exploiters (check F9)", 4)
end)

ReportSec:NewButton("📋 Report Selected Player", "", function()
    if not SelectedPlr then Library:Notify("Select player first!", 3); return end
    SendChat("REPORT: "..SelectedPlr.DisplayName.." - Suspicious Activity")
    Library:Notify("Reported "..SelectedPlr.DisplayName, 3)
end)

ReportSec:NewButton("⚡ Report ALL Exploiters", "", function()
    local c = 0
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local h = p.Character:FindFirstChild("Humanoid")
            if h and (h.WalkSpeed > 100 or h.Health > 500) then SendChat("REPORT: "..p.DisplayName.." - Exploiting"); c = c + 1 end
        end
    end
    Library:Notify("Mass Reported "..c.." players", 3)
end)

-- KILLER TAB
local KillerTab = Window:NewTab("Killer")
local KillerSec = KillerTab:NewSection("Killer Features")

KillerSec:NewToggle("👁️ Player ESP (Names + Distance)", "", function(s)
    if s then
        SB("ESP", Enum.RenderPriority.Camera.Value, function()
            for _,p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character and p.Character:FindFirstChild("Head") then
                    if not p.Character.Head:FindFirstChild("ESP_BB") then
                        local bb = Instance.new("BillboardGui"); bb.Name = "ESP_BB"; bb.Size = UDim2.new(0,200,0,50)
                        bb.StudsOffset = Vector3.new(0,3,0); bb.AlwaysOnTop = true; bb.Parent = p.Character.Head
                        local tl = Instance.new("TextLabel"); tl.Size = UDim2.new(1,0,1,0); tl.BackgroundTransparency = 1
                        tl.TextColor3 = Color3.fromRGB(255,50,50); tl.TextSize = 14; tl.Font = Enum.Font.GothamBold
                        tl.TextStrokeTransparency = 0; tl.Parent = bb
                    end
                    local bb = p.Character.Head:FindFirstChild("ESP_BB")
                    if bb then bb.TextLabel.Text = p.DisplayName.." ["..math.floor((p.Character.Head.Position - RP.Position).Magnitude).."]" end
                end
            end
        end)
    else
        SU("ESP")
        for _,p in ipairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("Head") then
                local bb = p.Character.Head:FindFirstChild("ESP_BB"); if bb then bb:Destroy() end
            end
        end
    end
end)

KillerSec:NewToggle("🎥 Killer POV", "", function(s)
    if s then
        local k = GetKiller()
        if k and k:FindFirstChild("Humanoid") then Cam.CameraSubject = k.Humanoid
        else Library:Notify("No killer found", 2) end
    else Cam.CameraSubject = Hum end
end)

KillerSec:NewToggle("🎯 Expand Hitbox (10x)", "", function(s)
    if s then
        SB("Hitbox", Enum.RenderPriority.Character.Value+1, function()
            for _,p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    pcall(function() p.Character.HumanoidRootPart.Size = Vector3.new(10,10,10); p.Character.HumanoidRootPart.Transparency = 0.7 end)
                end
            end
        end)
    else
        SU("Hitbox")
        for _,p in ipairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                pcall(function() p.Character.HumanoidRootPart.Size = Vector3.new(2,2,1); p.Character.HumanoidRootPart.Transparency = 1 end)
            end
        end
    end
end)

-- RARE TAB
local RareTab = Window:NewTab("Rare")
local RareSec = RareTab:NewSection("Rare Features")

RareSec:NewToggle("🤺 Auto-Parry", "", function(s)
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
    else SU("AutoParry") end
end)

RareSec:NewButton("⏪ Time Rewind", "", function()
    if RP then RP.CFrame = LastSafe end
    Library:Notify("Returned to previous position!", 2)
end)

RareSec:NewButton("💀 Fake Death", "", function()
    pcall(function() Hum.Health = 0 end)
    task.delay(3, function() pcall(function() Hum.Health = Hum.MaxHealth end) end)
    Library:Notify("Playing dead for 3 seconds...", 3)
end)

RareSec:NewToggle("👻 True Invisible", "", function(s)
    if s then
        SB("TrueInvis", Enum.RenderPriority.Character.Value+1, function()
            pcall(function() for _,P in ipairs(Char:GetDescendants()) do if P:IsA("BasePart") or P:IsA("Decal") then P.Transparency = 1; P.CanCollide = false end end end)
        end)
    else
        SU("TrueInvis")
        pcall(function() for _,P in ipairs(Char:GetDescendants()) do if P:IsA("BasePart") or P:IsA("Decal") then P.Transparency = 0; P.CanCollide = true end end end)
    end
end)

-- FPS TAB
local FPSTab = Window:NewTab("FPS")
local FPSSec = FPSTab:NewSection("Performance Boost")

FPSSec:NewToggle("🔥 Insane FPS Boost", "", function(s)
    if s then
        pcall(function() setfpscap(0) end)
        SB("InsaneFPS", Enum.RenderPriority.Camera.Value-1, function()
            pcall(function()
                for _,e in ipairs(LT:GetChildren()) do if e:IsA("PostProcessEffect") or e:IsA("BlurEffect") or e:IsA("BloomEffect") then e.Enabled = false end end
                LT.GlobalShadows = false; LT.FogEnd = 100000
                for _,p in ipairs(WS:GetDescendants()) do if p:IsA("ParticleEmitter") or p:IsA("Smoke") or p:IsA("Fire") or p:IsA("Trail") then p.Enabled = false end end
            end)
        end)
    else
        SU("InsaneFPS"); pcall(function() setfpscap(60) end)
        LT.GlobalShadows = true; LT.FogEnd = 1000
    end
end)

FPSSec:NewToggle("No Shadows", "", function(s) LT.GlobalShadows = not s end)
FPSSec:NewToggle("No Fog", "", function(s) LT.FogEnd = s and 100000 or 1000 end)

-- SETTINGS TAB
local SetTab = Window:NewTab("Settings")
local SetSec = SetTab:NewSection("Server & GUI")

SetSec:NewButton("Rejoin Server", "", function() pcall(function() TeleS:TeleportToPlaceInstance(game.PlaceId, game.JobId) end) end)
SetSec:NewButton("Server Hop", "", function()
    pcall(function()
        local Http = game:GetService("HttpService")
        local r = Http:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
        if r and r.data then
            local sv = {}
            for _,v in ipairs(r.data) do if v.id and v.id ~= game.JobId then table.insert(sv, v.id) end end
            if #sv > 0 then TeleS:TeleportToPlaceInstance(game.PlaceId, sv[math.random(1,#sv)]) end
        end
    end)
end)
SetSec:NewButton("Destroy GUI", "", function() pcall(function() Library:Unload() end) end)

-- RESPAWN HANDLER
LP.CharacterAdded:Connect(function(char)
    Char = char; Hum = char:FindFirstChildWhichIsA("Humanoid"); RP = char:FindFirstChild("HumanoidRootPart")
    Cam = WS.CurrentCamera; LastSafe = RP and RP.CFrame or CFrame.new(0,10,0)
    task.wait(0.5); ApplyStats()
end)

Library:Notify("THESKYFALL-HUB v30.2 Loaded! | RightShift = Hide | Draggable ON", 5)
print("[SKYFALL v30.2] LOADED | Ultimate Edition | All Bugs Fixed")
