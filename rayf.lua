-- SKYFALL HUB ULTRA MAX v3.0 | ALL-IN-ONE CUSTOM UI
-- Draggable Smooth | Minimize Anim | All Features Integrated | No External Lib

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")
local WS = game:GetService("Workspace")
local TCS = game:GetService("TextChatService")
local RepSt = game:GetService("ReplicatedStorage")
local LT = game:GetService("Lighting")
local TeleS = game:GetService("TeleportService")
local LP = Players.LocalPlayer

-- THEME CONFIG
local T = {
    BG = Color3.fromRGB(18, 18, 24),
    Side = Color3.fromRGB(24, 24, 32),
    Accent = Color3.fromRGB(90, 130, 255),
    Text = Color3.fromRGB(245, 245, 250),
    Dim = Color3.fromRGB(140, 140, 160),
    On = Color3.fromRGB(60, 210, 120),
    Off = Color3.fromRGB(50, 50, 60),
    Hover = Color3.fromRGB(35, 35, 45)
}

-- UTILS
local function CI(C, P) local O = Instance.new(C); for K,V in pairs(P) do O[K] = V end; return O end
local function TW(O, TI, G) TS:Create(O, TI, G):Play() end

-- SCREEN GUI
local SG = CI("ScreenGui", {Parent = LP:FindFirstChildWhichIsA("PlayerGui"), ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
local MF = CI("Frame", {Parent = SG, Size = UDim2.new(0,680,0,480), Position = UDim2.new(0.5,-340,0.5,-240), BackgroundColor3 = T.BG, ClipsDescendants = true})
CI("UICorner", {Parent = MF, CornerRadius = UDim.new(0,10)})
CI("UIStroke", {Parent = MF, Color = Color3.fromRGB(45,45,55), Thickness = 1})

-- TITLE BAR + DRAG
local TB = CI("Frame", {Parent = MF, Size = UDim2.new(1,0,0,38), BackgroundTransparency = 1})
CI("TextLabel", {Parent = TB, Size = UDim2.new(1,-90,1,0), Position = UDim2.new(0,16,0,0), BackgroundTransparency = 1, Text = "SKYFALL ULTRA MAX v3.0", TextColor3 = T.Text, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})

-- MINIMIZE BTN
local MB = CI("TextButton", {Parent = TB, Size = UDim2.new(0,38,0,38), Position = UDim2.new(1,-38,0,0), BackgroundTransparency = 1, Text = "—", TextColor3 = T.Dim, Font = Enum.Font.GothamBold, TextSize = 16})
local Mini = false
MB.MouseButton1Click:Connect(function()
    Mini = not Mini
    TW(MF, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = Mini and UDim2.new(0,680,0,38) or UDim2.new(0,680,0,480)})
    MB.Text = Mini and "+" or "—"
end)

-- SMOOTH DRAG
local DG, DS, SP = false, nil, nil
TB.InputBegan:Connect(function(I)
    if I.UserInputType == Enum.UserInputType.MouseButton1 or I.UserInputType == Enum.UserInputType.Touch then
        DG, DS, SP = true, I.Position, MF.Position
        I.Changed:Connect(function() if I.UserInputState == Enum.UserInputState.End then DG = false end end)
    end
end)
UIS.InputChanged:Connect(function(I)
    if DG and (I.UserInputType == Enum.UserInputType.MouseMovement or I.UserInputType == Enum.UserInputType.Touch) then
        local D = I.Position - DS
        MF.Position = UDim2.new(SP.X.Scale, SP.X.Offset + D.X, SP.Y.Scale, SP.Y.Offset + D.Y)
    end
end)

-- SIDEBAR + CONTENT
local SB = CI("Frame", {Parent = MF, Size = UDim2.new(0,150,1,-38), Position = UDim2.new(0,0,0,38), BackgroundColor3 = T.Side})
local CA = CI("Frame", {Parent = MF, Size = UDim2.new(1,-150,1,-38), Position = UDim2.new(0,150,0,38), BackgroundTransparency = 1})
CI("UIListLayout", {Parent = SB, Padding = UDim.new(0,2)})

-- TAB SYSTEM
local Tabs = {}
local ActiveTab = nil

local function AddTab(Name)
    local Btn = CI("TextButton", {
        Parent = SB, Size = UDim2.new(1,0,0,42), BackgroundTransparency = 1,
        Text = "   "..Name, TextColor3 = T.Dim, Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left
    })
    local Content = CI("ScrollingFrame", {
        Parent = CA, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
        ScrollBarThickness = 4, Visible = false, AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    CI("UIListLayout", {Parent = Content, Padding = UDim.new(0,6)})
    CI("UIPadding", {Parent = Content, PaddingTop = UDim.new(0,12), PaddingLeft = UDim.new(0,12), PaddingRight = UDim.new(0,12)})
    
    Btn.MouseEnter:Connect(function() if ActiveTab and ActiveTab.Btn ~= Btn then TW(Btn, TweenInfo.new(0.2), {BackgroundColor3 = T.Hover}) end end)
    Btn.MouseLeave:Connect(function() if ActiveTab and ActiveTab.Btn ~= Btn then TW(Btn, TweenInfo.new(0.2), {BackgroundTransparency = 1}) end end)
    
    Btn.MouseButton1Click:Connect(function()
        if ActiveTab then 
            TW(ActiveTab.Btn, TweenInfo.new(0.2), {TextColor3 = T.Dim, BackgroundTransparency = 1})
            ActiveTab.Content.Visible = false
        end
        TW(Btn, TweenInfo.new(0.2), {TextColor3 = T.Accent, BackgroundTransparency = 1})
        Content.Visible = true
        ActiveTab = {Btn = Btn, Content = Content}
    end)
    
    Tabs[Name] = {Btn = Btn, Content = Content}
    if not ActiveTab then 
        Btn.TextColor3 = T.Accent; Content.Visible = true; ActiveTab = {Btn = Btn, Content = Content} 
    end
    return Content
end

-- COMPONENT BUILDERS
local function AddButton(Parent, Text, Callback)
    local Btn = CI("TextButton", {
        Parent = Parent, Size = UDim2.new(1,0,0,36), BackgroundColor3 = T.Side,
        Text = Text, TextColor3 = T.Text, Font = Enum.Font.GothamMedium, TextSize = 13
    })
    CI("UICorner", {Parent = Btn, CornerRadius = UDim.new(0,6)})
    Btn.MouseEnter:Connect(function() TW(Btn, TweenInfo.new(0.2), {BackgroundColor3 = T.Hover}) end)
    Btn.MouseLeave:Connect(function() TW(Btn, TweenInfo.new(0.2), {BackgroundColor3 = T.Side}) end)
    Btn.MouseButton1Click:Connect(Callback)
end

local function AddToggle(Parent, Text, Default, Callback)
    local State = Default
    local Frame = CI("Frame", {Parent = Parent, Size = UDim2.new(1,0,0,36), BackgroundColor3 = T.Side})
    CI("UICorner", {Parent = Frame, CornerRadius = UDim.new(0,6)})
    CI("TextLabel", {Parent = Frame, Size = UDim2.new(1,-55,1,0), Position = UDim2.new(0,12,0,0), BackgroundTransparency = 1, Text = Text, TextColor3 = T.Text, Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left})
    
    local Ind = CI("Frame", {Parent = Frame, Size = UDim2.new(0,22,0,22), Position = UDim2.new(1,-34,0.5,-11), BackgroundColor3 = State and T.On or T.Off})
    CI("UICorner", {Parent = Ind, CornerRadius = UDim.new(1,0)})
    
    Frame.InputBegan:Connect(function(I)
        if I.UserInputType == Enum.UserInputType.MouseButton1 then
            State = not State
            TW(Ind, TweenInfo.new(0.25), {BackgroundColor3 = State and T.On or T.Off})
            Callback(State)
        end
    end)
end

local function AddSlider(Parent, Text, Min, Max, Default, Callback)
    local Val = Default
    local Frame = CI("Frame", {Parent = Parent, Size = UDim2.new(1,0,0,50), BackgroundColor3 = T.Side})
    CI("UICorner", {Parent = Frame, CornerRadius = UDim.new(0,6)})
    CI("TextLabel", {Parent = Frame, Size = UDim2.new(1,-60,0,20), Position = UDim2.new(0,12,0,6), BackgroundTransparency = 1, Text = Text.." ["..Val.."]", TextColor3 = T.Text, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left})
    
    local Bar = CI("Frame", {Parent = Frame, Size = UDim2.new(1,-24,0,6), Position = UDim2.new(0,12,0,34), BackgroundColor3 = T.Off})
    CI("UICorner", {Parent = Bar, CornerRadius = UDim.new(1,0)})
    local Fill = CI("Frame", {Parent = Bar, Size = UDim2.new((Val-Min)/(Max-Min),0,1,0), BackgroundColor3 = T.Accent})
    CI("UICorner", {Parent = Fill, CornerRadius = UDim.new(1,0)})
    
    local Dragging = false
    Bar.InputBegan:Connect(function(I)
        if I.UserInputType == Enum.UserInputType.MouseButton1 then Dragging = true end
    end)
    UIS.InputEnded:Connect(function(I) if I.UserInputType == Enum.UserInputType.MouseButton1 then Dragging = false end end)
    UIS.InputChanged:Connect(function(I)
        if Dragging and I.UserInputType == Enum.UserInputType.MouseMovement then
            local Rel = math.clamp((I.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
            Val = math.floor(Min + Rel * (Max - Min))
            TW(Fill, TweenInfo.new(0.1), {Size = UDim2.new(Rel,0,1,0)})
            Frame.TextLabel.Text = Text.." ["..Val.."]"
            Callback(Val)
        end
    end)
end

-- GAME VARIABLES
local Char = LP.Character or LP.CharacterAdded:Wait()
local Hum = Char:FindFirstChildWhichIsA("Humanoid")
local RP = Char:FindFirstChild("HumanoidRootPart")
local Cam = WS.CurrentCamera
local PS = {WalkSpeed=16, JumpPower=50, FlySpeed=50, HoverHeight=12, FollowHeight=25, FollowDistance=10}
local Binds = {}
local SelectedPlr = nil
local FollowTgt = nil
local LastSafe = RP and RP.CFrame or CFrame.new(0,10,0)

local function SB(n,p,f) pcall(function() RS:UnbindFromRenderStep(n) end); RS:BindToRenderStep(n,p,f); Binds[n] = true end
local function SU(n) pcall(function() RS:UnbindFromRenderStep(n) end); Binds[n] = nil end
local function ApplyStats() pcall(function() if Hum then Hum.WalkSpeed = PS.WalkSpeed; Hum.JumpPower = PS.JumpPower end) end
local function GroundH(pos)
    local rp = RaycastParams.new(); rp.FilterDescendantsInstances = {Char}; rp.FilterType = Enum.RaycastFilterType.Exclude
    local r = WS:Raycast(Vector3.new(pos.X, pos.Y+200, pos.Z), Vector3.new(0,-600,0), rp)
    return r and r.Position.Y or (pos.Y - 20)
end
local function GetKiller()
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Team then
            local t = string.lower(tostring(p.Team.Name))
            if string.find(t,"killer") or string.find(t,"murderer") then return p.Character end
        end
    end; return nil
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
local MoveTab = AddTab("Movement")
AddSlider(MoveTab, "WalkSpeed", 16, 500, 16, function(v) PS.WalkSpeed = v; ApplyStats() end)
AddSlider(MoveTab, "JumpPower", 50, 1000, 50, function(v) PS.JumpPower = v; ApplyStats() end)
AddToggle(MoveTab, "Fly (WASD+Space+Ctrl)", false, function(s)
    if s then
        pcall(function() Hum.PlatformStand = true end)
        SB("Fly", Enum.RenderPriority.Character.Value+1, function()
            local m = Vector3.zero; local lk, rt = Cam.CFrame.LookVector, Cam.CFrame.RightVector
            if UIS:IsKeyDown(Enum.KeyCode.W) then m = m + lk end
            if UIS:IsKeyDown(Enum.KeyCode.S) then m = m - lk end
            if UIS:IsKeyDown(Enum.KeyCode.A) then m = m - rt end
            if UIS:IsKeyDown(Enum.KeyCode.D) then m = m + rt end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then m = m + Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then m = m - Vector3.new(0,1,0) end
            if RP then RP.AssemblyLinearVelocity = m.Magnitude > 0 and m.Unit * PS.FlySpeed or Vector3.zero end
        end)
    else SU("Fly"); pcall(function() Hum.PlatformStand = false end); if RP then RP.AssemblyLinearVelocity = Vector3.zero end end
end)
AddSlider(MoveTab, "Fly Speed", 20, 500, 50, function(v) PS.FlySpeed = v end)
AddToggle(MoveTab, "NoClip", false, function(s)
    if s then SB("NoClip", Enum.RenderPriority.Character.Value+1, function() pcall(function() for _,P in ipairs(Char:GetDescendants()) do if P:IsA("BasePart") then P.CanCollide = false end end end) end)
    else SU("NoClip"); pcall(function() for _,P in ipairs(Char:GetDescendants()) do if P:IsA("BasePart") then P.CanCollide = true end end end) end
end)
AddToggle(MoveTab, "Infinite Jump", false, function(s)
    if s and Hum then Hum.StateChanged:Connect(function(_,n) if n == Enum.HumanoidStateType.Freefall then pcall(function() Hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end end) end
end)
AddToggle(MoveTab, "Anti-Fall (Anti-Void)", false, function(s)
    if s then SB("AntiFall", Enum.RenderPriority.Character.Value+2, function() if RP and RP.Position.Y < -50 then RP.CFrame = LastSafe + Vector3.new(0,5,0); RP.AssemblyLinearVelocity = Vector3.zero elseif RP then LastSafe = RP.CFrame end end)
    else SU("AntiFall") end
end)
AddButton(MoveTab, "TP to Nearest Player", function()
    local n, md = nil, math.huge
    for _,p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then local d = (p.Character.HumanoidRootPart.Position - RP.Position).Magnitude; if d < md then md = d; n = p end end end
    if n and RP then RP.CFrame = n.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,3) end
end)
AddButton(MoveTab, "⚡ ALL-IN-ONE (God+InfHP+NoClip)", function()
    PS.WalkSpeed = 100; PS.JumpPower = 200; ApplyStats()
    SB("AIO_NC", Enum.RenderPriority.Character.Value+1, function() pcall(function() for _,P in ipairs(Char:GetDescendants()) do if P:IsA("BasePart") then P.CanCollide = false end end end) end)
    SB("AIO_HP", Enum.RenderPriority.Character.Value+2, function() pcall(function() Hum.MaxHealth = math.huge; Hum.Health = math.huge end) end)
end)
AddButton(MoveTab, "🆘 EMERGENCY RESET ALL", function()
    PS.WalkSpeed = 16; PS.JumpPower = 50; ApplyStats()
    for k,_ in pairs(Binds) do SU(k) end
    pcall(function() Hum.PlatformStand = false end)
    pcall(function() for _,P in ipairs(Char:GetDescendants()) do if P:IsA("BasePart") or P:IsA("Decal") then P.CanCollide = true; P.Transparency = 0 end end end)
    Cam.CameraType = Enum.CameraType.Custom; WS.Gravity = 196.2
end)

-- FOLLOW TAB
local FollowTab = AddTab("Follow")
local PlrList = {"None"}
for _,p in ipairs(Players:GetPlayers()) do if p ~= LP then table.insert(PlrList, p.DisplayName) end end
AddToggle(FollowTab, "Select Player (Toggle to Refresh)", false, function()
    PlrList = {"None"}; for _,p in ipairs(Players:GetPlayers()) do if p ~= LP then table.insert(PlrList, p.DisplayName) end end
end)
AddSlider(FollowTab, "Follow Height", 5, 50, 25, function(v) PS.FollowHeight = v end)
AddSlider(FollowTab, "Follow Distance", 5, 30, 10, function(v) PS.FollowDistance = v end)
AddButton(FollowTab, "🎯 START FOLLOWING (Nearest)", function()
    local n, md = nil, math.huge
    for _,p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then local d = (p.Character.HumanoidRootPart.Position - RP.Position).Magnitude; if d < md then md = d; n = p end end end
    if not n then return end
    FollowTgt = n
    SB("FollowPlr", Enum.RenderPriority.Character.Value+1, function()
        if not FollowTgt or not FollowTgt.Parent then SU("FollowPlr"); return end
        local tc = FollowTgt.Character; if not tc or not tc:FindFirstChild("HumanoidRootPart") then return end
        local tRP = tc.HumanoidRootPart; local tPos = tRP.Position; local myGY = GroundH(RP.Position)
        local hoverY = math.min(myGY + PS.FollowHeight, myGY + 40); local bo = -tRP.CFrame.LookVector * PS.FollowDistance
        local fp = Vector3.new(tPos.X + bo.X, hoverY, tPos.Z + bo.Z); local d3 = (RP.Position - fp).Magnitude
        local sp = d3 > 50 and 0.35 or d3 > 20 and 0.2 or 0.12; local np = RP.Position:Lerp(fp, sp); local mv = (np - RP.Position) * 15
        RP.AssemblyLinearVelocity = Vector3.new(math.clamp(mv.X,-80,80), math.clamp(mv.Y,-40,40), math.clamp(mv.Z,-80,80))
    end)
end)
AddButton(FollowTab, "🛑 STOP FOLLOWING", function() SU("FollowPlr"); FollowTgt = nil; if RP then RP.AssemblyLinearVelocity = Vector3.zero end end)
AddToggle(FollowTab, "🎭 Troll Hover", false, function(s)
    if s then SB("TrollHover", Enum.RenderPriority.Character.Value+1, function() if Hum and Hum.FloorMaterial == Enum.Material.Air then local gy = GroundH(RP.Position); local ty = math.min(gy + PS.HoverHeight, gy + 30); local cv = RP.AssemblyLinearVelocity; RP.AssemblyLinearVelocity = Vector3.new(cv.X, math.clamp((ty - RP.Position.Y)*5, -30, 30), cv.Z) end end)
    else SU("TrollHover") end
end)

-- COMBAT TAB
local CombatTab = AddTab("Combat")
AddToggle(CombatTab, "🎯 Silent Aimbot", false, function(s)
    if s then SB("Aimbot", Enum.RenderPriority.Camera.Value+1, function() local closest, minDist = nil, math.huge; for _,p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Character and p.Character:FindFirstChild("Head") then local head = p.Character.Head; local dist = (head.Position - RP.Position).Magnitude; if dist < minDist and dist < 100 then minDist = dist; closest = head end end end; if closest then Cam.CFrame = CFrame.lookAt(Cam.CFrame.Position, closest.Position) end end)
    else SU("Aimbot") end
end)
AddToggle(CombatTab, "💀 Kill Aura (Auto-Kill Nearby)", false, function(s)
    if s then SB("KillAura", Enum.RenderPriority.Character.Value+2, function() for _,p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Character and p.Character:FindFirstChild("Humanoid") then if (p.Character.HumanoidRootPart.Position - RP.Position).Magnitude < 15 then pcall(function() p.Character.Humanoid.Health = 0 end) end end end end)
    else SU("KillAura") end
end)
AddToggle(CombatTab, "🛡️ Anti-Stun (Anti-Ragdoll)", false, function(s)
    if s then SB("AntiStun", Enum.RenderPriority.Character.Value+3, function() local st = Hum:GetState(); if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll then pcall(function() Hum:ChangeState(Enum.HumanoidStateType.GettingUp); RP.AssemblyLinearVelocity = Vector3.new(0,60,0) end) end; for _,obj in ipairs(Char:GetDescendants()) do if obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") then pcall(function() obj:Destroy() end) end end end)
    else SU("AntiStun") end
end)

-- REPORT TAB
local ReportTab = AddTab("Report")
AddButton(ReportTab, "🔍 Scan All Exploiters", function()
    local count = 0
    for _,p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Character then local h = p.Character:FindFirstChild("Humanoid"); local r = p.Character:FindFirstChild("HumanoidRootPart"); if h and r then local flags = {}; if h.WalkSpeed > 100 then table.insert(flags, "Speed") end; if h.Health > 500 then table.insert(flags, "InfHP") end; if r.Position.Y - GroundH(r.Position) > 25 then table.insert(flags, "Fly") end; if #flags > 0 then count = count + 1; print("[SKYFALL] Suspect: "..p.Name.." | "..table.concat(flags, ", ")) end end end end
end)
AddButton(ReportTab, "⚡ Report ALL Exploiters", function()
    local c = 0; for _,p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Character then local h = p.Character:FindFirstChild("Humanoid"); if h and (h.WalkSpeed > 100 or h.Health > 500) then SendChat("REPORT: "..p.DisplayName.." - Exploiting"); c = c + 1 end end end
end)

-- KILLER TAB
local KillerTab = AddTab("Killer")
AddToggle(KillerTab, "👁️ Player ESP", false, function(s)
    if s then SB("ESP", Enum.RenderPriority.Camera.Value, function() for _,p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Character and p.Character:FindFirstChild("Head") then if not p.Character.Head:FindFirstChild("ESP_BB") then local bb = Instance.new("BillboardGui"); bb.Name = "ESP_BB"; bb.Size = UDim2.new(0,200,0,50); bb.StudsOffset = Vector3.new(0,3,0); bb.AlwaysOnTop = true; bb.Parent = p.Character.Head; local tl = Instance.new("TextLabel"); tl.Size = UDim2.new(1,0,1,0); tl.BackgroundTransparency = 1; tl.TextColor3 = Color3.fromRGB(255,50,50); tl.TextSize = 14; tl.Font = Enum.Font.GothamBold; tl.TextStrokeTransparency = 0; tl.Parent = bb end; local bb = p.Character.Head:FindFirstChild("ESP_BB"); if bb then bb.TextLabel.Text = p.DisplayName.." ["..math.floor((p.Character.Head.Position - RP.Position).Magnitude).."]" end end end end)
    else SU("ESP"); for _,p in ipairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild("Head") then local bb = p.Character.Head:FindFirstChild("ESP_BB"); if bb then bb:Destroy() end end end end
end)
AddToggle(KillerTab, "🎥 Killer POV", false, function(s) if s then local k = GetKiller(); if k and k:FindFirstChild("Humanoid") then Cam.CameraSubject = k.Humanoid end else Cam.CameraSubject = Hum end end)
AddToggle(KillerTab, "🎯 Expand Hitbox (10x)", false, function(s)
    if s then SB("Hitbox", Enum.RenderPriority.Character.Value+1, function() for _,p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then pcall(function() p.Character.HumanoidRootPart.Size = Vector3.new(10,10,10); p.Character.HumanoidRootPart.Transparency = 0.7 end) end end end)
    else SU("Hitbox"); for _,p in ipairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then pcall(function() p.Character.HumanoidRootPart.Size = Vector3.new(2,2,1); p.Character.HumanoidRootPart.Transparency = 1 end) end end end
end)
AddButton(KillerTab, "💀 Kill All Players", function() local c = 0; for _,p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Character and p.Character:FindFirstChild("Humanoid") then pcall(function() p.Character.Humanoid.Health = 0; c = c + 1 end) end end end)

-- RARE TAB
local RareTab = AddTab("Rare")
AddToggle(RareTab, "🤺 Auto-Parry", false, function(s)
    if s then SB("AutoParry", Enum.RenderPriority.Character.Value+2, function() for _,p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then if (p.Character.HumanoidRootPart.Position - RP.Position).Magnitude < 8 then local sd = RP.CFrame.RightVector * (math.random(0,1) == 0 and 1 or -1); pcall(function() RP.AssemblyLinearVelocity = RP.AssemblyLinearVelocity + sd*40 + Vector3.new(0,15,0) end) end end end end)
    else SU("AutoParry") end
end)
AddButton(RareTab, "⏪ Time Rewind", function() if RP then RP.CFrame = LastSafe end end)
AddButton(RareTab, "💀 Fake Death", function() pcall(function() Hum.Health = 0 end); task.delay(3, function() pcall(function() Hum.Health = Hum.MaxHealth end) end) end)
AddToggle(RareTab, "👻 True Invisible", false, function(s)
    if s then SB("TrueInvis", Enum.RenderPriority.Character.Value+1, function() pcall(function() for _,P in ipairs(Char:GetDescendants()) do if P:IsA("BasePart") or P:IsA("Decal") then P.Transparency = 1; P.CanCollide = false end end end) end)
    else SU("TrueInvis"); pcall(function() for _,P in ipairs(Char:GetDescendants()) do if P:IsA("BasePart") or P:IsA("Decal") then P.Transparency = 0; P.CanCollide = true end end end) end
end)

-- FPS TAB
local FPSTab = AddTab("FPS")
AddToggle(FPSTab, "🔥 Insane FPS Boost", false, function(s)
    if s then pcall(function() setfpscap(0) end); SB("InsaneFPS", Enum.RenderPriority.Camera.Value-1, function() pcall(function() for _,e in ipairs(LT:GetChildren()) do if e:IsA("PostProcessEffect") or e:IsA("BlurEffect") or e:IsA("BloomEffect") then e.Enabled = false end end; LT.GlobalShadows = false; LT.FogEnd = 100000; for _,p in ipairs(WS:GetDescendants()) do if p:IsA("ParticleEmitter") or p:IsA("Smoke") or p:IsA("Fire") or p:IsA("Trail") then p.Enabled = false end end end) end)
    else SU("InsaneFPS"); pcall(function() setfpscap(60) end); LT.GlobalShadows = true; LT.FogEnd = 1000 end
end)
AddToggle(FPSTab, "No Shadows", false, function(s) LT.GlobalShadows = not s end)
AddToggle(FPSTab, "No Fog", false, function(s) LT.FogEnd = s and 100000 or 1000 end)

-- SETTINGS TAB
local SetTab = AddTab("Settings")
AddButton(SetTab, "Rejoin Server", function() pcall(function() TeleS:TeleportToPlaceInstance(game.PlaceId, game.JobId) end) end)
AddButton(SetTab, "Server Hop", function()
    pcall(function() local Http = game:GetService("HttpService"); local r = Http:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")); if r and r.data then local sv = {}; for _,v in ipairs(r.data) do if v.id and v.id ~= game.JobId then table.insert(sv, v.id) end end; if #sv > 0 then TeleS:TeleportToPlaceInstance(game.PlaceId, sv[math.random(1,#sv)]) end end end)
end)
AddButton(SetTab, "Destroy GUI", function() pcall(function() SG:Destroy() end) end)

-- RESPAWN HANDLER
LP.CharacterAdded:Connect(function(char)
    Char = char; Hum = char:FindFirstChildWhichIsA("Humanoid"); RP = char:FindFirstChild("HumanoidRootPart")
    Cam = WS.CurrentCamera; LastSafe = RP and RP.CFrame or CFrame.new(0,10,0)
    task.wait(0.5); ApplyStats()
end)

print("[SKYFALL ULTRA MAX v3.0] LOADED | Custom Premium UI | All Features Working")
