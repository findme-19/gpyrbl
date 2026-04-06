--[[
  MOUNT MARAPI SCRIPT
  BY ALFIAN
]]

local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local TweenSvc = game:GetService("TweenService")
local player   = Players.LocalPlayer

pcall(function()
    for _,g in ipairs(player.PlayerGui:GetChildren()) do
        if g.Name=="MarapiAlfian" then g:Destroy() end
    end
end)

local function applyAntiLag()
    pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Level01 end)
    pcall(function() settings().Rendering.MeshPartDetailLevel=Enum.MeshPartDetailLevel.Level01 end)
    pcall(function() workspace.GlobalShadows=false end)
    pcall(function() settings().Rendering.MaxFrameRate=15 end)
    pcall(function()
        local L=game:GetService("Lighting")
        L.GlobalShadows=false;L.Brightness=1
        L.EnvironmentDiffuseScale=0;L.EnvironmentSpecularScale=0
        for _,v in ipairs(L:GetChildren()) do
            if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or
               v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or
               v:IsA("DepthOfFieldEffect") then v.Enabled=false end
        end
    end)
    pcall(function()
        for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Fire") or
               v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("Beam") then v.Enabled=false end
            if v:IsA("Decal") or v:IsA("Texture") then v.Transparency=1 end
        end
    end)
end

-- ══════════════════════════════
-- KOORDINAT DARI LOG
-- t=0.74 pos sebelum prompt t=1.60
-- obj = "RedemptionPointBasepart"
-- offset +8 Z agar tidak overlap
-- ══════════════════════════════
local TARGET = Vector3.new(437.4, 691.8, -2538.9)
local NEAR   = Vector3.new(437.4, 691.8, -2530.9) -- +8 Z

local running = false
local GR = Color3.fromRGB(150,255,170)
local RD = Color3.fromRGB(255,100,100)
local YL = Color3.fromRGB(230,200,100)
local WHT= Color3.fromRGB(230,230,230)

local SVl, SDot
local function setStatus(msg,col)
    if not SVl then return end
    SVl.Text=msg
    local c=col=="done" and GR or col=="err" and RD or col=="wait" and YL or WHT
    SVl.TextColor3=c
    if SDot then SDot.BackgroundColor3=c end
end

-- ══════════════════════════════
-- SCAN RedemptionPointBasepart
-- ══════════════════════════════
local function findRedemption()
    -- exact name dari log
    for _,v in ipairs(workspace:GetDescendants()) do
        if v.Name=="RedemptionPointBasepart" and
           (v:IsA("BasePart") or v:IsA("Model")) then
            return v
        end
    end
    -- fallback pattern
    for _,v in ipairs(workspace:GetDescendants()) do
        local n=v.Name:lower()
        if (n:match("redemption") or n:match("gopay") or
            n:match("voucher") or n:match("claim")) and
           (v:IsA("BasePart") or v:IsA("Model")) then
            local pos
            if v:IsA("BasePart") then pos=v.Position
            elseif v:IsA("Model") then
                local pp=v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
                pos=pp and pp.Position
            end
            if pos and (pos-TARGET).Magnitude < 150 then return v end
        end
    end
    return nil
end

local function getPos(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local pp=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        return pp and pp.Position
    end
end

local function fireAllPrompts(obj, nearPos)
    local candidates,seen={},{}
    -- dari objek langsung
    if obj then
        for _,v in ipairs(obj:GetDescendants()) do
            if v:IsA("ProximityPrompt") and not seen[v] then
                seen[v]=true;table.insert(candidates,v)
            end
        end
    end
    -- scan workspace dekat target
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") and not seen[v] then
            local at=(v.ActionText or ""):lower()
            local pn=(v.Parent and v.Parent.Name or ""):lower()
            if at:match("claim") or at:match("voucher") or
               pn:match("redemption") or pn:match("gopay") then
                local par=v.Parent
                if par then
                    local pos
                    if par:IsA("BasePart") then pos=par.Position
                    elseif par:IsA("Model") then
                        local pp=par.PrimaryPart or par:FindFirstChildWhichIsA("BasePart")
                        pos=pp and pp.Position
                    end
                    if pos and (pos-(nearPos or TARGET)).Magnitude < 100 then
                        seen[v]=true;table.insert(candidates,v)
                    end
                end
            end
        end
    end
    local fired=0
    for _,pr in ipairs(candidates) do
        for _=1,3 do
            local ok=pcall(function() fireproximityprompt(pr) end)
            if ok then fired=fired+1;break end
            task.wait(0.08)
        end
    end
    return fired
end

local function runSequence()
    if running then return end
    running=true
    task.spawn(function()
        setStatus("CONNECTING","wait")
        task.wait(0.15)

        local char=player.Character or player.CharacterAdded:Wait()
        local hrp=char:WaitForChild("HumanoidRootPart",5)
        if not hrp then setStatus("ERROR","err");running=false;return end
        local hum=char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed=0 end

        -- TP ke NEAR (offset 8 stud)
        setStatus("FAST TRAVEL","wait")
        hrp.CFrame=CFrame.new(NEAR+Vector3.new(0,5,0))
        task.wait(0.25)

        -- scan objek
        setStatus("LOCATING POINT","wait")
        local obj=findRedemption()
        if obj then
            local pos=getPos(obj)
            if pos then
                local off=(NEAR-pos)
                off=off.Magnitude>0.1 and off.Unit*8 or Vector3.new(0,0,8)
                hrp.CFrame=CFrame.new(pos+off+Vector3.new(0,3,0))
                task.wait(0.2)
            end
        end

        if hum then hum.WalkSpeed=16 end
        setStatus("FIRING PROMPT","wait")
        task.wait(0.12)

        local fired=fireAllPrompts(obj,NEAR)

        -- nudge jika gagal
        if fired==0 and obj then
            local pos=getPos(obj)
            if pos then
                local d=(pos-hrp.Position)
                if d.Magnitude>0 then
                    hrp.CFrame=CFrame.new(hrp.Position+d.Unit*3)
                end
                task.wait(0.15)
                fired=fireAllPrompts(obj,NEAR)
            end
        end

        setStatus("ARRIVED — CLAIM MANUAL","done")
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification",
                {Title="Mount Marapi",Text="Sudah tiba. Claim voucher sekarang.",Duration=3})
        end)
        running=false
    end)
end

-- ══════════════════════════════
-- GUI
-- ══════════════════════════════
local PNL=Color3.fromRGB(14,14,14)
local MID=Color3.fromRGB(22,22,22)
local BRD=Color3.fromRGB(34,34,34)
local BRD2=Color3.fromRGB(50,50,50)
local DIM=Color3.fromRGB(100,100,100)
local SIL=Color3.fromRGB(153,153,153)
local DEEP=Color3.fromRGB(8,8,8)

local sg=Instance.new("ScreenGui")
sg.Name="MarapiAlfian";sg.ResetOnSpawn=false
sg.DisplayOrder=9999;sg.IgnoreGuiInset=false
sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
sg.Parent=player.PlayerGui

-- PANEL 240 × 185
local F=Instance.new("Frame",sg)
F.Size=UDim2.new(0,240,0,185)
F.Position=UDim2.new(0.5,-120,0.5,-92)
F.BackgroundColor3=PNL;F.BorderSizePixel=0
F.Active=true;F.Draggable=true;F.ZIndex=10
do Instance.new("UICorner",F).CornerRadius=UDim.new(0,8) end
do Instance.new("UIStroke",F).Color=BRD end

-- accent
local ac=Instance.new("Frame",F)
ac.Size=UDim2.new(1,-4,0,1);ac.Position=UDim2.new(0,2,0,0)
ac.BackgroundColor3=SIL;ac.BorderSizePixel=0;ac.ZIndex=15
do Instance.new("UICorner",ac).CornerRadius=UDim.new(0,1) end

-- TOPBAR y=0 h=40
local TB=Instance.new("Frame",F)
TB.Size=UDim2.new(1,0,0,40);TB.Position=UDim2.new(0,0,0,0)
TB.BackgroundColor3=DEEP;TB.BorderSizePixel=0;TB.ZIndex=11
do Instance.new("UICorner",TB).CornerRadius=UDim.new(0,8) end
do local fx=Instance.new("Frame",TB);fx.Size=UDim2.new(1,0,0,8);fx.Position=UDim2.new(0,0,1,-8);fx.BackgroundColor3=DEEP;fx.BorderSizePixel=0;fx.ZIndex=11 end
do local bx=Instance.new("Frame",TB);bx.Size=UDim2.new(1,0,0,1);bx.Position=UDim2.new(0,0,1,-1);bx.BackgroundColor3=BRD;bx.BorderSizePixel=0;bx.ZIndex=12 end

-- icon gunung
local TIco=Instance.new("TextLabel",TB)
TIco.Size=UDim2.new(0,24,0,24);TIco.Position=UDim2.new(0,10,0.5,-12)
TIco.BackgroundColor3=MID;TIco.BorderSizePixel=0;TIco.ZIndex=13
TIco.Text="🌋";TIco.TextColor3=WHT;TIco.Font=Enum.Font.Gotham;TIco.TextSize=13
TIco.TextXAlignment=Enum.TextXAlignment.Center;TIco.TextYAlignment=Enum.TextYAlignment.Center
do Instance.new("UICorner",TIco).CornerRadius=UDim.new(0,5) end
do Instance.new("UIStroke",TIco).Color=BRD2 end

do
    local l=Instance.new("TextLabel",TB)
    l.Size=UDim2.new(1,-80,0,16);l.Position=UDim2.new(0,40,0,7)
    l.BackgroundTransparency=1;l.Text="MOUNT MARAPI"
    l.TextColor3=WHT;l.Font=Enum.Font.GothamBold;l.TextSize=11
    l.TextXAlignment=Enum.TextXAlignment.Left;l.ZIndex=13
end
do
    local l=Instance.new("TextLabel",TB)
    l.Size=UDim2.new(1,-80,0,12);l.Position=UDim2.new(0,40,0,24)
    l.BackgroundTransparency=1;l.Text="BY ALFIAN  ·  AUTO CLAIM"
    l.TextColor3=DIM;l.Font=Enum.Font.Gotham;l.TextSize=8
    l.TextXAlignment=Enum.TextXAlignment.Left;l.ZIndex=13
end

local XB=Instance.new("TextButton",TB)
XB.Size=UDim2.new(0,22,0,22);XB.Position=UDim2.new(1,-26,0.5,-11)
XB.BackgroundColor3=MID;XB.Text="✕";XB.TextColor3=DIM
XB.Font=Enum.Font.GothamBold;XB.TextSize=9;XB.BorderSizePixel=0;XB.ZIndex=14
do Instance.new("UICorner",XB).CornerRadius=UDim.new(0,5) end
do Instance.new("UIStroke",XB).Color=BRD2 end
XB.MouseEnter:Connect(function() XB.TextColor3=WHT end)
XB.MouseLeave:Connect(function() XB.TextColor3=DIM end)
XB.MouseButton1Click:Connect(function()
    TweenSvc:Create(F,TweenInfo.new(0.15),{Size=UDim2.new(0,240,0,0)}):Play()
    task.delay(0.15,function() sg:Destroy() end)
end)

-- STATUS y=48 h=24
local sr=Instance.new("Frame",F)
sr.Size=UDim2.new(1,-24,0,24);sr.Position=UDim2.new(0,12,0,48)
sr.BackgroundColor3=MID;sr.BorderSizePixel=0;sr.ZIndex=12
do Instance.new("UICorner",sr).CornerRadius=UDim.new(0,5) end
do Instance.new("UIStroke",sr).Color=BRD end

SDot=Instance.new("Frame",sr)
SDot.Size=UDim2.new(0,5,0,5);SDot.Position=UDim2.new(0,8,0.5,-2)
SDot.BackgroundColor3=GR;SDot.BorderSizePixel=0;SDot.ZIndex=13
do Instance.new("UICorner",SDot).CornerRadius=UDim.new(1,0) end

SVl=Instance.new("TextLabel",sr)
SVl.Size=UDim2.new(1,-22,1,0);SVl.Position=UDim2.new(0,18,0,0)
SVl.BackgroundTransparency=1;SVl.Text="READY"
SVl.TextColor3=GR;SVl.Font=Enum.Font.GothamBold;SVl.TextSize=10
SVl.TextXAlignment=Enum.TextXAlignment.Left
SVl.TextTruncate=Enum.TextTruncate.AtEnd;SVl.ZIndex=13

-- KOORDINAT CARD y=80 h=28
local cc=Instance.new("Frame",F)
cc.Size=UDim2.new(1,-24,0,28);cc.Position=UDim2.new(0,12,0,80)
cc.BackgroundColor3=MID;cc.BorderSizePixel=0;cc.ZIndex=12
do Instance.new("UICorner",cc).CornerRadius=UDim.new(0,5) end
do Instance.new("UIStroke",cc).Color=BRD end

do
    local l=Instance.new("TextLabel",cc)
    l.Size=UDim2.new(0,52,1,0);l.Position=UDim2.new(0,8,0,0)
    l.BackgroundTransparency=1;l.Text="TARGET"
    l.TextColor3=DIM;l.Font=Enum.Font.GothamBold;l.TextSize=8
    l.TextXAlignment=Enum.TextXAlignment.Left;l.ZIndex=13
end
do
    local l=Instance.new("TextLabel",cc)
    l.Size=UDim2.new(1,-60,1,0);l.Position=UDim2.new(0,58,0,0)
    l.BackgroundTransparency=1
    l.Text=string.format("%.1f  %.1f  %.1f",TARGET.X,TARGET.Y,TARGET.Z)
    l.TextColor3=SIL;l.Font=Enum.Font.Code;l.TextSize=9
    l.TextXAlignment=Enum.TextXAlignment.Left;l.ZIndex=13
end

-- ANTI-LAG y=116 h=24
local al=Instance.new("Frame",F)
al.Size=UDim2.new(1,-24,0,24);al.Position=UDim2.new(0,12,0,116)
al.BackgroundColor3=MID;al.BorderSizePixel=0;al.ZIndex=12
do Instance.new("UICorner",al).CornerRadius=UDim.new(0,5) end
do Instance.new("UIStroke",al).Color=BRD end

do
    local l=Instance.new("TextLabel",al)
    l.Size=UDim2.new(0.65,0,1,0);l.Position=UDim2.new(0,8,0,0)
    l.BackgroundTransparency=1;l.Text="ANTI-LAG / LOW GRAPHICS"
    l.TextColor3=DIM;l.Font=Enum.Font.GothamBold;l.TextSize=8
    l.TextXAlignment=Enum.TextXAlignment.Left;l.ZIndex=13
end

local ALB=Instance.new("TextButton",al)
ALB.Size=UDim2.new(0,38,0,18);ALB.Position=UDim2.new(1,-42,0.5,-9)
ALB.BackgroundColor3=MID;ALB.Text="ON";ALB.TextColor3=WHT
ALB.Font=Enum.Font.GothamBold;ALB.TextSize=9;ALB.BorderSizePixel=0;ALB.ZIndex=13
do Instance.new("UICorner",ALB).CornerRadius=UDim.new(0,4) end
local ALsk=Instance.new("UIStroke",ALB);ALsk.Color=SIL
local alOn=true
ALB.MouseButton1Click:Connect(function()
    alOn=not alOn;ALB.Text=alOn and "ON" or "OFF"
    ALB.TextColor3=alOn and WHT or DIM;ALsk.Color=alOn and SIL or BRD
    if alOn then applyAntiLag() end
end)

-- START BUTTON y=148 h=26
local StartBtn=Instance.new("TextButton",F)
StartBtn.Size=UDim2.new(1,-24,0,26);StartBtn.Position=UDim2.new(0,12,0,148)
StartBtn.BackgroundColor3=WHT;StartBtn.Text="[ START ]"
StartBtn.TextColor3=DEEP;StartBtn.Font=Enum.Font.GothamBold
StartBtn.TextSize=13;StartBtn.BorderSizePixel=0;StartBtn.ZIndex=12
do Instance.new("UICorner",StartBtn).CornerRadius=UDim.new(0,7) end
do Instance.new("UIStroke",StartBtn).Color=BRD2 end

-- pulse
local pulsing=true
task.spawn(function()
    while sg and sg.Parent do
        if pulsing then
            TweenSvc:Create(StartBtn,TweenInfo.new(1.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),
                {BackgroundColor3=Color3.fromRGB(190,190,190)}):Play()
            task.wait(1.2)
            if pulsing then
                TweenSvc:Create(StartBtn,TweenInfo.new(1.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),
                    {BackgroundColor3=WHT}):Play()
                task.wait(1.2)
            end
        else task.wait(0.3) end
    end
end)

StartBtn.MouseButton1Click:Connect(function()
    if running then return end
    pulsing=false
    StartBtn.BackgroundColor3=MID;StartBtn.TextColor3=YL;StartBtn.Text="[ TELEPORTING... ]"
    runSequence()
    task.spawn(function()
        while running do task.wait(0.1) end
        task.wait(0.4)
        StartBtn.BackgroundColor3=WHT;StartBtn.TextColor3=DEEP
        StartBtn.Text="[ START ]";pulsing=true
    end)
end)

UIS.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.KeyCode==Enum.KeyCode.F9 then F.Visible=not F.Visible end
end)

task.spawn(function() task.wait(0.5);applyAntiLag() end)

print("Mount Marapi | By Alfian | F9 toggle")
