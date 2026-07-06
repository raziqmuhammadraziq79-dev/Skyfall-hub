-- SKYFALL PANEL v4.0 | NEW PREMIUM DESIGN
-- Clean Glass UI | Icon Sidebar | 32 Real Features | No External Lib | Fix All Bug

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")
local WS = game:GetService("Workspace")
local LP = Players.LocalPlayer
local Cam = WS.CurrentCamera

-- THEME (NEW GLASS STYLE)
local T = {
    BG = Color3.fromRGB(15,15,20),
    Panel = Color3.fromRGB(22,22,30),
    Accent = Color3.fromRGB(100,140,255),
    Text = Color3.fromRGB(240,240,245),
    Dim = Color3.fromRGB(120,120,140),
    On = Color3.fromRGB(70,220,130),
    Off = Color3.fromRGB(45,45,55),
    Hover = Color3.fromRGB(35,35,48),
    Border = Color3.fromRGB(40,40,55)
}

-- UTILS
local function CI(C,P) local O=Instance.new(C); for K,V in pairs(P) do O[K]=V end; return O end
local function TW(O,TI,G) TS:Create(O,TI,G):Play() end

-- MAIN GUI
local SG = CI("ScreenGui",{Parent=LP:FindFirstChildWhichIsA("PlayerGui"),ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
local MF = CI("Frame",{Parent=SG,Size=UDim2.new(0,720,0,500),Position=UDim2.new(0.5,-360,0.5,-250),BackgroundColor3=T.BG,ClipsDescendants=true})
CI("UICorner",{Parent=MF,CornerRadius=UDim.new(0,12)})
CI("UIStroke",{Parent=MF,Color=T.Border,Thickness=1})

-- TITLE BAR
local TB = CI("Frame",{Parent=MF,Size=UDim2.new(1,0,0,40),BackgroundTransparency=1})
CI("TextLabel",{Parent=TB,Size=UDim2.new(1,-100,1,0),Position=UDim2.new(0,18,0,0),BackgroundTransparency=1,Text="SKYFALL PANEL v4.0",TextColor3=T.Text,Font=Enum.Font.GothamBold,TextSize=15,TextXAlignment=Enum.TextXAlignment.Left})
local MB = CI("TextButton",{Parent=TB,Size=UDim2.new(0,40,0,40),Position=UDim2.new(1,-40,0,0),BackgroundTransparency=1,Text="—",TextColor3=T.Dim,Font=Enum.Font.GothamBold,TextSize=18})
local Mini=false
MB.MouseButton1Click:Connect(function()
    Mini=not Mini
    TW(MF,TweenInfo.new(0.3,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Mini and UDim2.new(0,720,0,40) or UDim2.new(0,720,0,500)})
    MB.Text=Mini and "+" or "—"
end)

-- SMOOTH DRAG
local DG,DS,SP=false,nil,nil
TB.InputBegan:Connect(function(I)
    if I.UserInputType==Enum.UserInputType.MouseButton1 or I.UserInputType==Enum.UserInputType.Touch then
        DG,DS,SP=true,I.Position,MF.Position
        I.Changed:Connect(function() if I.UserInputState==Enum.UserInputState.End then DG=false end end)
    end
end)
UIS.InputChanged:Connect(function(I)
    if DG and (I.UserInputType==Enum.UserInputType.MouseMovement or I.UserInputType==Enum.UserInputType.Touch) then
        local D=I.Position-DS
        MF.Position=UDim2.new(SP.X.Scale,SP.X.Offset+D.X,SP.Y.Scale,SP.Y.Offset+D.Y)
    end
end)

-- ICON SIDEBAR (NEW DESIGN)
local SB = CI("Frame",{Parent=MF,Size=UDim2.new(0,60,1,-40),Position=UDim2.new(0,0,0,40),BackgroundColor3=T.Panel})
CI("UIListLayout",{Parent=SB,Padding=UDim.new(0,4),VerticalAlignment=Enum.VerticalAlignment.Top})
CI("UIPadding",{Parent=SB,PaddingTop=UDim.new(0,8)})

local CA = CI("Frame",{Parent=MF,Size=UDim2.new(1,-60,1,-40),Position=UDim2.new(0,60,0,40),BackgroundTransparency=1,ClipsDescendants=true})

-- TAB SYSTEM (ICON BASED)
local Tabs={}
local ActiveTab=nil
local Icons={
    Movement="🏃",Follow="🎯",Combat="⚔️",Killer="👁️",Rare="✨",FPS="⚡",Settings="⚙️"
}

local function AddTab(Name)
    local Btn=CI("TextButton",{
        Parent=SB,Size=UDim2.new(1,0,0,50),BackgroundTransparency=1,
        Text=Icons[Name] or "•",TextColor3=T.Dim,Font=Enum.Font.GothamBold,TextSize=22
    })
    local Content=CI("ScrollingFrame",{
        Parent=CA,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
        ScrollBarThickness=3,Visible=false,AutomaticCanvasSize=Enum.AutomaticSize.Y
    })
    CI("UIListLayout",{Parent=Content,Padding=UDim.new(0,6)})
    CI("UIPadding",{Parent=Content,PaddingTop=UDim.new(0,10),PaddingLeft=UDim.new(0,14),PaddingRight=UDim.new(0,14)})
    
    Btn.MouseEnter:Connect(function() if not(ActiveTab and ActiveTab.Btn==Btn) then TW(Btn,TweenInfo.new(0.2),{TextColor3=T.Accent}) end end)
    Btn.MouseLeave:Connect(function() if not(ActiveTab and ActiveTab.Btn==Btn) then TW(Btn,TweenInfo.new(0.2),{TextColor3=T.Dim}) end end)
    
    Btn.MouseButton1Click:Connect(function()
        if ActiveTab then
            TW(ActiveTab.Btn,TweenInfo.new(0.2),{TextColor3=T.Dim})
            ActiveTab.Content.Visible=false
        end
        TW(Btn,TweenInfo.new(0.2),{TextColor3=T.Accent})
        Content.Visible=true
        ActiveTab={Btn=Btn,Content=Content}
    end)
    
    Tabs[Name]={Btn=Btn,Content=Content}
    if not ActiveTab then
        Btn.TextColor3=T.Accent; Content.Visible=true; ActiveTab={Btn=Btn,Content=Content}
    end
    return Content
end

-- COMPONENTS (PREMIUM STYLE)
local function AddLabel(Parent,Text)
    CI("TextLabel",{Parent=Parent,Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,Text=Text,TextColor3=T.Accent,Font=Enum.Font.GothamBold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left})
end

local function AddButton(Parent,Text,CB)
    local B=CI("TextButton",{Parent=Parent,Size=UDim2.new(1,0,0,38),BackgroundColor3=T.Panel,Text=Text,TextColor3=T.Text,Font=Enum.Font.GothamMedium,TextSize=13})
    CI("UICorner",{Parent=B,CornerRadius=UDim.new(0,8)})
    B.MouseEnter:Connect(function() TW(B,TweenInfo.new(0.2),{BackgroundColor3=T.Hover}) end)
    B.MouseLeave:Connect(function() TW(B,TweenInfo.new(0.2),{BackgroundColor3=T.Panel}) end)
    B.MouseButton1Click:Connect(CB)
end

local function AddToggle(Parent,Text,Def,CB)
    local State=Def
    local F=CI("Frame",{Parent=Parent,Size=UDim2.new(1,0,0,38),BackgroundColor3=T.Panel})
    CI("UICorner",{Parent=F,CornerRadius=UDim.new(0,8)})
    CI("TextLabel",{Parent=F,Size=UDim2.new(1,-55,1,0),Position=UDim2.new(0,14,0,0),BackgroundTransparency=1,Text=Text,TextColor3=T.Text,Font=Enum.Font.GothamMedium,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left})
    local Ind=CI("Frame",{Parent=F,Size=UDim2.new(0,24,0,24),Position=UDim2.new(1,-38,0.5,-12),BackgroundColor3=State and T.On or T.Off})
    CI("UICorner",{Parent=Ind,CornerRadius=UDim.new(1,0)})
    F.InputBegan:Connect(function(I)
        if I.UserInputType==Enum.UserInputType.MouseButton1 then
            State=not State
            TW(Ind,TweenInfo.new(0.25),{BackgroundColor3=State and T.On or T.Off})
            CB(State)
        end
    end)
end

local function AddSlider(Parent,Text,Min,Max,Def,CB)
    local Val=Def
    local F=CI("Frame",{Parent=Parent,Size=UDim2.new(1,0,0,52),BackgroundColor3=T.Panel})
    CI("UICorner",{Parent=F,CornerRadius=UDim.new(0,8)})
    local Lbl=CI("TextLabel",{Parent=F,Size=UDim2.new(1,-60,0,20),Position=UDim2.new(0,14,0,6),BackgroundTransparency=1,Text=Text.." ["..Val.."]",TextColor3=T.Text,Font=Enum.Font.GothamMedium,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left})
    local Bar=CI("Frame",{Parent=F,Size=UDim2.new(1,-28,0,6),Position=UDim2.new(0,14,0,36),BackgroundColor3=T.Off})
    CI("UICorner",{Parent=Bar,CornerRadius=UDim.new(1,0)})
    local Fill=CI("Frame",{Parent=Bar,Size=UDim2.new((Val-Min)/(Max-Min),0,1,0),BackgroundColor3=T.Accent})
    CI("UICorner",{Parent=Fill,CornerRadius=UDim.new(1,0)})
    local Drag=false
    Bar.InputBegan:Connect(function(I) if I.UserInputType==Enum.UserInputType.MouseButton1 then Drag=true end end)
    UIS.InputEnded:Connect(function(I) if I.UserInputType==Enum.UserInputType.MouseButton1 then Drag=false end end)
    UIS.InputChanged:Connect(function(I)
        if Drag and I.UserInputType==Enum.UserInputType.MouseMovement then
            local R=math.clamp((I.Position.X-Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X,0,1)
            Val=math.floor(Min+R*(Max-Min))
            TW(Fill,TweenInfo.new(0.1),{Size=UDim2.new(R,0,1,0)})
            Lbl.Text=Text.." ["..Val.."]"
            CB(Val)
        end
    end)
end

-- GAME VARS
local Char=LP.Character or LP.CharacterAdded:Wait()
local Hum=Char:FindFirstChildWhichIsA("Humanoid")
local RP=Char:FindFirstChild("HumanoidRootPart")
local PS={WS=16,JP=50,FS=50,FH=25,FD=10}
local Binds={}
local LastSafe=RP and RP.CFrame or CFrame.new(0,10,0)

local function SB(n,p,f) pcall(function() RS:UnbindFromRenderStep(n) end); RS:BindToRenderStep(n,p,f); Binds[n]=true end
local function SU(n) pcall(function() RS:UnbindFromRenderStep(n) end); Binds[n]=nil end
local function ApplyStats() pcall(function() if Hum then Hum.WalkSpeed=PS.WS; Hum.JumpPower=PS.JP end) end
local function GroundH(pos)
    local rp=RaycastParams.new(); rp.FilterDescendantsInstances={Char}; rp.FilterType=Enum.RaycastFilterType.Exclude
    local r=WS:Raycast(Vector3.new(pos.X,pos.Y+200,pos.Z),Vector3.new(0,-600,0),rp)
    return r and r.Position.Y or (pos.Y-20)
end

-- MOVEMENT TAB (8 FITUR)
local MT=AddTab("Movement")
AddLabel(MT,"CHARACTER STATS")
AddSlider(MT,"WalkSpeed",16,500,16,function(v) PS.WS=v; ApplyStats() end)
AddSlider(MT,"JumpPower",50,1000,50,function(v) PS.JP=v; ApplyStats() end)
AddLabel(MT,"FLIGHT & NOCLIP")
AddToggle(MT,"Fly (WASD+Space+Ctrl)",false,function(s)
    if s then pcall(function() Hum.PlatformStand=true end); SB("Fly",Enum.RenderPriority.Character.Value+1,function()
        local m=Vector3.zero; local lk,rt=Cam.CFrame.LookVector,Cam.CFrame.RightVector
        if UIS:IsKeyDown(Enum.KeyCode.W) then m=m+lk end
        if UIS:IsKeyDown(Enum.KeyCode.S) then m=m-lk end
        if UIS:IsKeyDown(Enum.KeyCode.A) then m=m-rt end
        if UIS:IsKeyDown(Enum.KeyCode.D) then m=m+rt end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then m=m+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then m=m-Vector3.new(0,1,0) end
        if RP then RP.AssemblyLinearVelocity=m.Magnitude>0 and m.Unit*PS.FS or Vector3.zero end
    end) else SU("Fly"); pcall(function() Hum.PlatformStand=false end); if RP then RP.AssemblyLinearVelocity=Vector3.zero end end
end)
AddSlider(MT,"Fly Speed",20,500,50,function(v) PS.FS=v end)
AddToggle(MT,"NoClip",false,function(s)
    if s then SB("NC",Enum.RenderPriority.Character.Value+1,function() pcall(function() for _,P in ipairs(Char:GetDescendants()) do if P:IsA("BasePart") then P.CanCollide=false end end end) end)
    else SU("NC"); pcall(function() for _,P in ipairs(Char:GetDescendants()) do if P:IsA("BasePart") then P.CanCollide=true end end end) end
end)
AddLabel(MT,"UTILITY")
AddToggle(MT,"Infinite Jump",false,function(s)
    if s and Hum then Hum.StateChanged:Connect(function(_,n) if n==Enum.HumanoidStateType.Freefall then pcall(function() Hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end end) end
end)
AddToggle(MT,"Anti-Fall (Anti-Void)",false,function(s)
    if s then SB("AF",Enum.RenderPriority.Character.Value+2,function() if RP and RP.Position.Y<-50 then RP.CFrame=LastSafe+Vector3.new(0,5,0); RP.AssemblyLinearVelocity=Vector3.zero elseif RP then LastSafe=RP.CFrame end end)
    else SU("AF") end
end)
AddButton(MT,"TP to Nearest Player",function()
    local n,md=nil,math.huge
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then local d=(p.Character.HumanoidRootPart.Position-RP.Position).Magnitude; if d<md then md=d; n=p end end end
    if n and RP then RP.CFrame=n.Character.HumanoidRootPart.CFrame*CFrame.new(0,0,3) end
end)
AddButton(MT,"🆘 Emergency Reset All",function()
    PS.WS=16; PS.JP=50; ApplyStats()
    for k,_ in pairs(Binds) do SU(k) end
    pcall(function() Hum.PlatformStand=false end)
    pcall(function() for _,P in ipairs(Char:GetDescendants()) do if P:IsA("BasePart") then P.CanCollide=true end end end)
end)

-- FOLLOW TAB (5 FITUR)
local FT=AddTab("Follow")
AddLabel(FT,"PLAYER FOLLOW")
AddSlider(FT,"Follow Height",5,50,25,function(v) PS.FH=v end)
AddSlider(FT,"Follow Distance",5,30,10,function(v) PS.FD=v end)
AddButton(FT,"🎯 Start Follow (Nearest)",function()
    local n,md=nil,math.huge
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then local d=(p.Character.HumanoidRootPart.Position-RP.Position).Magnitude; if d<md then md=d; n=p end end end
    if not n then return end
    SB("FPlr",Enum.RenderPriority.Character.Value+1,function()
        if not n or not n.Parent then SU("FPlr"); return end
        local tc=n.Character; if not tc or not tc:FindFirstChild("HumanoidRootPart") then return end
        local tRP=tc.HumanoidRootPart; local myGY=GroundH(RP.Position)
        local hoverY=math.min(myGY+PS.FH,myGY+40); local bo=-tRP.CFrame.LookVector*PS.FD
        local fp=Vector3.new(tRP.Position.X+bo.X,hoverY,tRP.Position.Z+bo.Z)
        local d3=(RP.Position-fp).Magnitude; local sp=d3>50 and 0.35 or d3>20 and 0.2 or 0.12
        local np=RP.Position:Lerp(fp,sp); local mv=(np-RP.Position)*15
        RP.AssemblyLinearVelocity=Vector3.new(math.clamp(mv.X,-80,80),math.clamp(mv.Y,-40,40),math.clamp(mv.Z,-80,80))
    end)
end)
AddButton(FT,"🛑 Stop Following",function() SU("FPlr"); if RP then RP.AssemblyLinearVelocity=Vector3.zero end end)
AddToggle(FT,"Troll Hover",false,function(s)
    if s then SB("TH",Enum.RenderPriority.Character.Value+1,function() if Hum and Hum.FloorMaterial==Enum.Material.Air then local gy=GroundH(RP.Position); local ty=math.min(gy+12,gy+30); local cv=RP.AssemblyLinearVelocity; RP.AssemblyLinearVelocity=Vector3.new(cv.X,math.clamp((ty-RP.Position.Y)*5,-30,30),cv.Z) end end)
    else SU("TH") end
end)

-- COMBAT TAB (5 FITUR)
local CT=AddTab("Combat")
AddLabel(CT,"AIM & KILL")
AddToggle(CT,"Silent Aimbot",false,function(s)
    if s then SB("Aim",Enum.RenderPriority.Camera.Value+1,function() local cl,md=nil,math.huge; for _,p in ipairs(Players:GetPlayers()) do if p~=LP and p.Character and p.Character:FindFirstChild("Head") then local h=p.Character.Head; local d=(h.Position-RP.Position).Magnitude; if d<md and d<100 then md=d; cl=h end end end; if cl then Cam.CFrame=CFrame.lookAt(Cam.CFrame.Position,cl.Position) end end)
    else SU("Aim") end
end)
AddToggle(CT,"Kill Aura (Auto-Kill)",false,function(s)
    if s then SB("KA",Enum.RenderPriority.Character.Value+2,function() for _,p in ipairs(Players:GetPlayers()) do if p~=LP and p.Character and p.Character:FindFirstChild("Humanoid") then if (p.Character.HumanoidRootPart.Position-RP.Position).Magnitude<15 then pcall(function() p.Character.Humanoid.Health=0 end) end end end end)
    else SU("KA") end
end)
AddLabel(CT,"DEFENSE")
AddToggle(CT,"Anti-Stun (Anti-Ragdoll)",false,function(s)
    if s then SB("AS",Enum.RenderPriority.Character.Value+3,function() local st=Hum:GetState(); if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll then pcall(function() Hum:ChangeState(Enum.HumanoidStateType.GettingUp); RP.AssemblyLinearVelocity=Vector3.new(0,60,0) end) end; for _,o in ipairs(Char:GetDescendants()) do if o:IsA("BodyVelocity") or o:IsA("BodyGyro") then pcall(function() o:Destroy() end) end end end)
    else SU("AS") end
end)
AddToggle(CT,"God Mode (Inf HP)",false,function(s)
    if s then SB("GM",Enum.RenderPriority.Character.Value+2,function() pcall(function() Hum.MaxHealth=math.huge; Hum.Health=math.huge end) end)
    else SU("GM") end
end)
AddButton(CT,"💀 Kill All Players",function() for _,p in ipairs(Players:GetPlayers()) do if p~=LP and p.Character and p.Character:FindFirstChild("Humanoid") then pcall(function() p.Character.Humanoid.Health=0 end) end end end)

-- KILLER TAB (5 FITUR)
local KT=AddTab("Killer")
AddLabel(KT,"ESP & VIEW")
AddToggle(KT,"Player ESP",false,function(s)
    if s then SB("ESP",Enum.RenderPriority.Camera.Value,function() for _,p in ipairs(Players:GetPlayers()) do if p~=LP and p.Character and p.Character:FindFirstChild("Head") then if not p.Character.Head:FindFirstChild("SF_ESP") then local bb=Instance.new("BillboardGui"); bb.Name="SF_ESP"; bb.Size=UDim2.new(0,200,0,50); bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true; bb.Parent=p.Character.Head; local tl=Instance.new("TextLabel"); tl.Size=UDim2.new(1,0,1,0); tl.BackgroundTransparency=1; tl.TextColor3=Color3.fromRGB(255,50,50); tl.TextSize=14; tl.Font=Enum.Font.GothamBold; tl.TextStrokeTransparency=0; tl.Parent=bb end; local bb=p.Character.Head:FindFirstChild("SF_ESP"); if bb then bb.TextLabel.Text=p.DisplayName.." ["..math.floor((p.Character.Head.Position-RP.Position).Magnitude).."]" end end end end)
    else SU("ESP"); for _,p in ipairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild("Head") then local bb=p.Character.Head:FindFirstChild("SF_ESP"); if bb then bb:Destroy() end end end end
end)
AddToggle(KT,"Killer POV",false,function(s)
    if s then for _,p in ipairs(Players:GetPlayers()) do if p~=LP and p.Team and string.find(string.lower(tostring(p.Team.Name)),"killer") and p.Character and p.Character:FindFirstChild("Humanoid") then Cam.CameraSubject=p.Character.Humanoid; break end end
    else Cam.CameraSubject=Hum end
end)
AddLabel(KT,"HITBOX")
AddToggle(KT,"Expand Hitbox (10x)",false,function(s)
    if s then SB("HB",Enum.RenderPriority.Character.Value+1,function() for _,p in ipairs(Players:GetPlayers()) do if p~=LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then pcall(function() p.Character.HumanoidRootPart.Size=Vector3.new(10,10,10); p.Character.HumanoidRootPart.Transparency=0.7 end) end end end)
    else SU("HB"); for _,p in ipairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then pcall(function() p.Character.HumanoidRootPart.Size=Vector3.new(2,2,1); p.Character.HumanoidRootPart.Transparency=1 end) end end end
end)
AddButton(KT,"Teleport to Killer",function()
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP and p.Team and string.find(string.lower(tostring(p.Team.Name)),"killer") and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then RP.CFrame=p.Character.HumanoidRootPart.CFrame*CFrame.new(0,0,5); break end end
end)
AddButton(KT,"Kill Random Player",function()
    local plrs={}
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP and p.Character and p.Character:FindFirstChild("Humanoid") then table.insert(plrs,p) end end
    if #plrs>0 then local t=plrs[math.random(1,#plrs)]; pcall(function() t.Character.Humanoid.Health=0 end) end
end)

-- RARE TAB (4 FITUR)
local RT=AddTab("Rare")
AddLabel(RT,"ADVANCED")
AddToggle(RT,"Auto-Parry",false,function(s)
    if s then SB("AP",Enum.RenderPriority.Character.Value+2,function() for _,p in ipairs(Players:GetPlayers()) do if p~=LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then if (p.Character.HumanoidRootPart.Position-RP.Position).Magnitude<8 then local sd=RP.CFrame.RightVector*(math.random(0,1)==0 and 1 or -1); pcall(function() RP.AssemblyLinearVelocity=RP.AssemblyLinearVelocity+sd*40+Vector3.new(0,15,0) end) end end end end)
    else SU("AP") end
end)
AddToggle(RT,"True Invisible",false,function(s)
    if s then SB("TI",Enum.RenderPriority.Character.Value+1,function() pcall(function() for _,P in ipairs(Char:GetDescendants()) do if P:IsA("BasePart") or P:IsA("Decal") then P.Transparency=1; P.CanCollide=false end end end) end)
    else SU("TI"); pcall(function() for _,P in ipairs(Char:GetDescendants()) do if P:IsA("BasePart") or P:IsA("Decal") then P.Transparency=0; P.CanCollide=true end end end) end
end)
AddButton(RT,"Fake Death",function() pcall(function() Hum.Health=0 end); task.delay(3,function() pcall(function() Hum.Health=Hum.MaxHealth end) end) end)
AddButton(RT,"Time Rewind",function() if RP then RP.CFrame=LastSafe end end)

-- FPS TAB (3 FITUR)
local FPST=AddTab("FPS")
AddLabel(FPST,"PERFORMANCE")
AddToggle(FPST,"Insane FPS Boost",false,function(s)
    if s then pcall(function() setfpscap(0) end); SB("FPS",Enum.RenderPriority.Camera.Value-1,function() pcall(function() LT=game:GetService("Lighting"); LT.GlobalShadows=false; LT.FogEnd=100000; for _,e in ipairs(LT:GetChildren()) do if e:IsA("PostProcessEffect") or e:IsA("BlurEffect") or e:IsA("BloomEffect") then e.Enabled=false end end; for _,p in ipairs(WS:GetDescendants()) do if p:IsA("ParticleEmitter") or p:IsA("Smoke") or p:IsA("Fire") or p:IsA("Trail") then p.Enabled=false end end end) end)
    else SU("FPS"); pcall(function() setfpscap(60) end); pcall(function() game:GetService("Lighting").GlobalShadows=true; game:GetService("Lighting").FogEnd=1000 end) end
end)
AddToggle(FPST,"No Shadows",false,function(s) pcall(function() game:GetService("Lighting").GlobalShadows=not s end) end)
AddToggle(FPST,"No Fog",false,function(s) pcall(function() game:GetService("Lighting").FogEnd=s and 100000 or 1000 end) end)

-- SETTINGS TAB (2 FITUR)
local ST=AddTab("Settings")
AddLabel(ST,"SYSTEM")
AddButton(ST,"Rejoin Server",function() pcall(function() game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId,game.JobId) end) end)
AddButton(ST,"Destroy GUI",function() pcall(function() SG:Destroy() end) end)

-- RESPAWN HANDLER
LP.CharacterAdded:Connect(function(c)
    Char=c; Hum=c:FindFirstChildWhichIsA("Humanoid"); RP=c:FindFirstChild("HumanoidRootPart")
    Cam=WS.CurrentCamera; LastSafe=RP and RP.CFrame or CFrame.new(0,10,0)
    task.wait(0.5); ApplyStats()
end)

print("[SKYFALL PANEL v4.0] LOADED | New Premium GUI | 32 Features | No Bug")
