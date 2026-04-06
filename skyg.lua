--[[
  MOUNT SAKAHAYANG SCRIPT
  BY ALFIAN
]]

local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local TweenSvc = game:GetService("TweenService")
local player   = Players.LocalPlayer

pcall(function()
    for _,g in ipairs(player.PlayerGui:GetChildren()) do
        if g.Name=="SakahayangAlfian" then g:Destroy() end
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

local TARGET = Vector3.new(4362.3, 2237.0, -9538.8)
local NEAR   = Vector3.new(4362.3, 2237.0, -9530.8)
local running = false

local GR =Color3.fromRGB(150,255,170)
local RD =Color3.fromRGB(220,70,70)
local RD2=Color3.fromRGB(255,90,90)
local YL =Color3.fromRGB(230,200,100)
local WHT=Color3.fromRGB(230,230,230)
local DIM=Color3.fromRGB(100,100,110)
local PNL=Color3.fromRGB(12,12,16)
local MID=Color3.fromRGB(18,18,24)
local SRF=Color3.fromRGB(24,24,32)
local BRD=Color3.fromRGB(36,36,48)
local BRD2=Color3.fromRGB(55,55,72)
local SIL=Color3.fromRGB(140,140,155)
local DEEP=Color3.fromRGB(7,7,10)
local GD =Color3.fromRGB(180,150,80)

local SVl,SDot,ALBtn,ALsk2
local function setStatus(msg,col)
    if not SVl then return end
    SVl.Text=msg
    local c=col=="done" and GR or col=="err" and RD2 or col=="wait" and YL or WHT
    SVl.TextColor3=c
    if SDot then SDot.BackgroundColor3=c end
end

local function findPrompt()
    for _,v in ipairs(workspace:GetDescendants()) do
        if v.Name=="ProxyAttachment" then
            local pr=v:FindFirstChildOfClass("ProximityPrompt")
            if pr then return pr,v end
            if v.Parent then
                local pr2=v.Parent:FindFirstChildOfClass("ProximityPrompt")
                if pr2 then return pr2,v.Parent end
            end
        end
    end
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local at=(v.ActionText or ""):lower()
            local pn=(v.Parent and v.Parent.Name or ""):lower()
            if at:match("ambil") or at:match("hadiah") or
               at:match("claim") or at:match("voucher") or
               pn:match("proxy") or pn:match("attachment") then
                return v,v.Parent
            end
        end
    end
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local par=v.Parent
            if par then
                local pos
                if par:IsA("BasePart") then pos=par.Position
                elseif par:IsA("Model") then
                    local pp=par.PrimaryPart or par:FindFirstChildWhichIsA("BasePart")
                    pos=pp and pp.Position
                end
                if pos and (pos-TARGET).Magnitude<120 then return v,par end
            end
        end
    end
    return nil,nil
end

local function getObjPos(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local pp=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        return pp and pp.Position
    end
    if obj:IsA("Attachment") then return obj.WorldPosition end
    return nil
end

local function runSequence()
    if running then return end
    running=true
    task.spawn(function()
        setStatus("CONNECTING","wait"); task.wait(0.15)
        local char=player.Character or player.CharacterAdded:Wait()
        local hrp=char:WaitForChild("HumanoidRootPart",5)
        if not hrp then setStatus("ERROR","err");running=false;return end
        local hum=char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed=0 end

        setStatus("FAST TRAVEL","wait")
        hrp.CFrame=CFrame.new(NEAR+Vector3.new(0,5,0)); task.wait(0.3)

        setStatus("LOCATING HADIAH","wait")
        local pr,obj=findPrompt()
        if obj then
            local pos=getObjPos(obj)
            if pos then
                local off=(NEAR-pos)
                off=off.Magnitude>0.1 and off.Unit*7 or Vector3.new(0,0,7)
                hrp.CFrame=CFrame.new(pos+off+Vector3.new(0,3,0)); task.wait(0.25)
            end
        end

        if hum then hum.WalkSpeed=16 end
        setStatus("FIRING PROMPT","wait"); task.wait(0.12)

        local fired=false
        if pr then
            for _=1,3 do
                local ok=pcall(function() fireproximityprompt(pr) end)
                if ok then fired=true;break end
                task.wait(0.08)
            end
        end
        if not fired and obj then
            local pos=getObjPos(obj)
            if pos then
                local d=(pos-hrp.Position)
                if d.Magnitude>0 then hrp.CFrame=CFrame.new(hrp.Position+d.Unit*3) end
                task.wait(0.15)
                if pr then
                    for _=1,3 do
                        local ok=pcall(function() fireproximityprompt(pr) end)
                        if ok then fired=true;break end
                        task.wait(0.08)
                    end
                end
            end
        end

        setStatus("ARRIVED — CLAIM MANUAL","done")
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification",
                {Title="Mount Sakahayang",Text="Sudah tiba. Ambil hadiah sekarang.",Duration=3})
        end)
        running=false
    end)
end

-- ══════════════════════════════
-- GUI
-- ══════════════════════════════
local sg=Instance.new("ScreenGui")
sg.Name="SakahayangAlfian"; sg.ResetOnSpawn=false
sg.DisplayOrder=9999; sg.IgnoreGuiInset=true
sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
sg.Parent=player.PlayerGui

-- PANEL 260 × 520
local F=Instance.new("Frame",sg)
F.Size=UDim2.new(0,260,0,520)
F.Position=UDim2.new(0,20,0,60)
F.BackgroundColor3=PNL; F.BorderSizePixel=0
F.Active=true; F.Draggable=true; F.ZIndex=10
do Instance.new("UICorner",F).CornerRadius=UDim.new(0,10) end
do Instance.new("UIStroke",F).Color=BRD end

-- top accent
local TAc=Instance.new("Frame",F)
TAc.Size=UDim2.new(1,-4,0,2); TAc.Position=UDim2.new(0,2,0,0)
TAc.BackgroundColor3=SIL; TAc.BorderSizePixel=0; TAc.ZIndex=15
do Instance.new("UICorner",TAc).CornerRadius=UDim.new(0,2) end

-- helper
local function mkL(par,txt,col,sz,font,xa)
    local l=Instance.new("TextLabel",par)
    l.BackgroundTransparency=1; l.Text=txt
    l.TextColor3=col or WHT; l.Font=font or Enum.Font.Gotham
    l.TextSize=sz or 10; l.ZIndex=14
    l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.TextWrapped=true
    return l
end
local function mkSep(yp,col)
    local s=Instance.new("Frame",F)
    s.Size=UDim2.new(1,0,0,1); s.Position=UDim2.new(0,0,0,yp)
    s.BackgroundColor3=col or BRD; s.BorderSizePixel=0; s.ZIndex=12
end
local function mkCard(yp,h,col,skCol)
    local c=Instance.new("Frame",F)
    c.Size=UDim2.new(1,-24,0,h); c.Position=UDim2.new(0,12,0,yp)
    c.BackgroundColor3=col or MID; c.BorderSizePixel=0; c.ZIndex=12
    do Instance.new("UICorner",c).CornerRadius=UDim.new(0,6) end
    do local s=Instance.new("UIStroke",c); s.Color=skCol or BRD; s.Thickness=1 end
    return c
end

-- ══ TOPBAR  y=0 h=44
local TB=Instance.new("Frame",F)
TB.Size=UDim2.new(1,0,0,44); TB.Position=UDim2.new(0,0,0,0)
TB.BackgroundColor3=DEEP; TB.BorderSizePixel=0; TB.ZIndex=11
do Instance.new("UICorner",TB).CornerRadius=UDim.new(0,10) end
do local fx=Instance.new("Frame",TB);fx.Size=UDim2.new(1,0,0,12);fx.Position=UDim2.new(0,0,1,-12);fx.BackgroundColor3=DEEP;fx.BorderSizePixel=0;fx.ZIndex=11 end
do local bx=Instance.new("Frame",TB);bx.Size=UDim2.new(1,0,0,1);bx.Position=UDim2.new(0,0,1,-1);bx.BackgroundColor3=BRD;bx.BorderSizePixel=0;bx.ZIndex=12 end

local TIco=Instance.new("TextLabel",TB)
TIco.Size=UDim2.new(0,20,0,20); TIco.Position=UDim2.new(0,10,0.5,-10)
TIco.BackgroundTransparency=1; TIco.Text="🏔"; TIco.TextColor3=WHT
TIco.Font=Enum.Font.Gotham; TIco.TextSize=14; TIco.ZIndex=13
TIco.TextXAlignment=Enum.TextXAlignment.Center

local TTitle=mkL(TB,"MOUNT SAKAHAYANG",WHT,10,Enum.Font.GothamBold)
TTitle.Size=UDim2.new(1,-80,0,16); TTitle.Position=UDim2.new(0,34,0,8); TTitle.ZIndex=13

local TBy=mkL(TB,"by Alfian",DIM,8,Enum.Font.Gotham)
TBy.Size=UDim2.new(1,-80,0,12); TBy.Position=UDim2.new(0,34,0,25); TBy.ZIndex=13

local XB=Instance.new("TextButton",TB)
XB.Size=UDim2.new(0,22,0,22); XB.Position=UDim2.new(1,-26,0.5,-11)
XB.BackgroundColor3=MID; XB.Text="✕"; XB.TextColor3=DIM
XB.Font=Enum.Font.GothamBold; XB.TextSize=9; XB.BorderSizePixel=0; XB.ZIndex=14
do Instance.new("UICorner",XB).CornerRadius=UDim.new(0,5) end
do Instance.new("UIStroke",XB).Color=BRD2 end
XB.MouseEnter:Connect(function() XB.TextColor3=WHT end)
XB.MouseLeave:Connect(function() XB.TextColor3=DIM end)
XB.MouseButton1Click:Connect(function()
    TweenSvc:Create(F,TweenInfo.new(0.15),{BackgroundTransparency=1}):Play()
    task.delay(0.15,function() sg:Destroy() end)
end)

mkSep(44, BRD)

-- ══ SYSTEM PROTECTION NOTICE  y=52
local spLbl=mkL(F,"⚠  SYSTEM PROTECTION ACTIVE",YL,9,Enum.Font.GothamBold,Enum.TextXAlignment.Left)
spLbl.Size=UDim2.new(1,-24,0,14); spLbl.Position=UDim2.new(0,12,0,52); spLbl.ZIndex=12

-- ══ VERIFIED CARD  y=72
local vc=mkCard(72,28,MID,BRD2)
local vDot=Instance.new("Frame",vc)
vDot.Size=UDim2.new(0,6,0,6); vDot.Position=UDim2.new(0,10,0.5,-3)
vDot.BackgroundColor3=GR; vDot.BorderSizePixel=0; vDot.ZIndex=13
do Instance.new("UICorner",vDot).CornerRadius=UDim.new(1,0) end
local vTxt=mkL(vc,"SCRIPT VERIFIED",GR,9,Enum.Font.GothamBold)
vTxt.Size=UDim2.new(1,-30,1,0); vTxt.Position=UDim2.new(0,24,0,0); vTxt.ZIndex=13

-- blink dot
task.spawn(function()
    while sg and sg.Parent do
        TweenSvc:Create(vDot,TweenInfo.new(1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),
            {BackgroundTransparency=0.6}):Play(); task.wait(1)
        TweenSvc:Create(vDot,TweenInfo.new(1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),
            {BackgroundTransparency=0}):Play(); task.wait(1)
    end
end)

-- ══ STATUS CARD  y=108
local sc=mkCard(108,28,MID,BRD)
SDot=Instance.new("Frame",sc)
SDot.Size=UDim2.new(0,5,0,5); SDot.Position=UDim2.new(0,10,0.5,-2)
SDot.BackgroundColor3=GR; SDot.BorderSizePixel=0; SDot.ZIndex=13
do Instance.new("UICorner",SDot).CornerRadius=UDim.new(1,0) end
SVl=mkL(sc,"READY",GR,9,Enum.Font.GothamBold)
SVl.Size=UDim2.new(1,-24,1,0); SVl.Position=UDim2.new(0,20,0,0); SVl.ZIndex=13
SVl.TextTruncate=Enum.TextTruncate.AtEnd

-- ══ LOW GRAPHICS CARD  y=144
local lgc=mkCard(144,28,MID,BRD)
local lgLbl=mkL(lgc,"LOW GRAPHICS",DIM,9,Enum.Font.GothamBold)
lgLbl.Size=UDim2.new(0.65,0,1,0); lgLbl.Position=UDim2.new(0,10,0,0); lgLbl.ZIndex=13

ALBtn=Instance.new("TextButton",lgc)
ALBtn.Size=UDim2.new(0,38,0,18); ALBtn.Position=UDim2.new(1,-44,0.5,-9)
ALBtn.BackgroundColor3=SRF; ALBtn.Text="ON"; ALBtn.TextColor3=WHT
ALBtn.Font=Enum.Font.GothamBold; ALBtn.TextSize=9; ALBtn.BorderSizePixel=0; ALBtn.ZIndex=13
do Instance.new("UICorner",ALBtn).CornerRadius=UDim.new(0,4) end
ALsk2=Instance.new("UIStroke",ALBtn); ALsk2.Color=SIL; ALsk2.Thickness=1

local alState=true
ALBtn.MouseButton1Click:Connect(function()
    alState=not alState
    ALBtn.Text=alState and "ON" or "OFF"
    ALBtn.TextColor3=alState and WHT or DIM
    ALsk2.Color=alState and SIL or BRD
    if alState then applyAntiLag() end
end)

-- ══ START BUTTON  y=180
local StartBtn=Instance.new("TextButton",F)
StartBtn.Size=UDim2.new(1,-48,0,36); StartBtn.Position=UDim2.new(0,24,0,180)
StartBtn.BackgroundColor3=WHT; StartBtn.Text="START RUN"
StartBtn.TextColor3=DEEP; StartBtn.Font=Enum.Font.GothamBold
StartBtn.TextSize=12; StartBtn.BorderSizePixel=0; StartBtn.ZIndex=12
do Instance.new("UICorner",StartBtn).CornerRadius=UDim.new(0,8) end
do Instance.new("UIStroke",StartBtn).Color=BRD2 end

local pulsing=true
task.spawn(function()
    while sg and sg.Parent do
        if pulsing then
            TweenSvc:Create(StartBtn,TweenInfo.new(1.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),
                {BackgroundColor3=Color3.fromRGB(185,185,185)}):Play(); task.wait(1.2)
            if pulsing then
                TweenSvc:Create(StartBtn,TweenInfo.new(1.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),
                    {BackgroundColor3=WHT}):Play(); task.wait(1.2)
            end
        else task.wait(0.3) end
    end
end)

StartBtn.MouseButton1Click:Connect(function()
    if running then return end
    pulsing=false
    StartBtn.BackgroundColor3=MID; StartBtn.TextColor3=YL; StartBtn.Text="RUNNING..."
    runSequence()
    task.spawn(function()
        while running do task.wait(0.1) end; task.wait(0.4)
        StartBtn.BackgroundColor3=WHT; StartBtn.TextColor3=DEEP
        StartBtn.Text="START RUN"; pulsing=true
    end)
end)

mkSep(226, BRD)

-- ══ ANTI-CRACK NOTICE  y=234
local ac1=mkL(F,"⚠  ANTI-CRACK NOTICE",YL,9,Enum.Font.GothamBold,Enum.TextXAlignment.Left)
ac1.Size=UDim2.new(1,-24,0,14); ac1.Position=UDim2.new(0,12,0,234); ac1.ZIndex=12

local noticeLines={
    "Script ini dilindungi system.",
    "Akses ditolak jika tidak resmi.",
}
local ny=252
for _,t in ipairs(noticeLines) do
    local l=mkL(F,t,DIM,8,Enum.Font.Gotham,Enum.TextXAlignment.Left)
    l.Size=UDim2.new(1,-24,0,13); l.Position=UDim2.new(0,12,0,ny); l.ZIndex=12; ny=ny+13
end

local denyLines={
    {"•  Resell tanpa izin",    RD},
    {"•  Share / leak script",  RD},
    {"•  Edit / bypass system", RD},
}
ny=ny+4
local dLabel=mkL(F,"Dilarang keras:",Color3.fromRGB(160,160,170),8,Enum.Font.GothamBold,Enum.TextXAlignment.Left)
dLabel.Size=UDim2.new(1,-24,0,13); dLabel.Position=UDim2.new(0,12,0,ny); dLabel.ZIndex=12; ny=ny+14
for _,d in ipairs(denyLines) do
    local l=mkL(F,d[1],d[2],8,Enum.Font.Gotham,Enum.TextXAlignment.Left)
    l.Size=UDim2.new(1,-24,0,13); l.Position=UDim2.new(0,12,0,ny); l.ZIndex=12; ny=ny+13
end

mkSep(ny+4, BRD)

-- ══ OFFICIAL AUTHOR  y=ny+12
local authY=ny+12
local authTitle=mkL(F,"OFFICIAL AUTHOR",GD,9,Enum.Font.GothamBold,Enum.TextXAlignment.Left)
authTitle.Size=UDim2.new(1,-24,0,13); authTitle.Position=UDim2.new(0,12,0,authY); authTitle.ZIndex=12

local authName=mkL(F,"Alfian Azhra",WHT,10,Enum.Font.GothamBold,Enum.TextXAlignment.Left)
authName.Size=UDim2.new(1,-24,0,14); authName.Position=UDim2.new(0,12,0,authY+16); authName.ZIndex=12

local authNote=mkL(F,"Pembelian resmi hanya melalui:",DIM,8,Enum.Font.Gotham,Enum.TextXAlignment.Left)
authNote.Size=UDim2.new(1,-24,0,13); authNote.Position=UDim2.new(0,12,0,authY+33); authNote.ZIndex=12

-- contact rows
local function mkContact(yp,icon,iconBG,iconClr,key,val)
    local row=Instance.new("Frame",F)
    row.Size=UDim2.new(1,-24,0,22); row.Position=UDim2.new(0,12,0,yp)
    row.BackgroundTransparency=1; row.ZIndex=12

    local ico=Instance.new("TextLabel",row)
    ico.Size=UDim2.new(0,18,0,18); ico.BackgroundColor3=iconBG; ico.BorderSizePixel=0; ico.ZIndex=13
    ico.Text=icon; ico.TextColor3=iconClr; ico.Font=Enum.Font.GothamBold; ico.TextSize=9
    ico.TextXAlignment=Enum.TextXAlignment.Center; ico.TextYAlignment=Enum.TextYAlignment.Center
    do Instance.new("UICorner",ico).CornerRadius=UDim.new(0,4) end

    local kl=mkL(row,key,DIM,8,Enum.Font.GothamBold)
    kl.Size=UDim2.new(0,54,1,0); kl.Position=UDim2.new(0,22,0,0); kl.ZIndex=13

    local vl=mkL(row,val,WHT,9,Enum.Font.GothamBold)
    vl.Size=UDim2.new(1,-80,1,0); vl.Position=UDim2.new(0,78,0,0); vl.ZIndex=13
end

mkContact(authY+49, "f",  Color3.fromRGB(18,28,60), Color3.fromRGB(100,150,255), "Facebook",  "Alfian Azhra")
mkContact(authY+74, "✆", Color3.fromRGB(10,35,18),  Color3.fromRGB(80,210,120),  "WhatsApp", "08998289407")

local warnNote=mkL(F,"⚠  Selain kontak di atas bukan author asli",YL,7,Enum.Font.GothamBold,Enum.TextXAlignment.Left)
warnNote.Size=UDim2.new(1,-24,0,13); warnNote.Position=UDim2.new(0,12,0,authY+100); warnNote.ZIndex=12

mkSep(authY+116, BRD)

-- ══ FOOTER
local footer=mkL(F,"© PROTECTED PRIVATE SCRIPT",Color3.fromRGB(55,55,70),7,Enum.Font.GothamBold,Enum.TextXAlignment.Center)
footer.Size=UDim2.new(1,-24,0,14); footer.Position=UDim2.new(0,12,0,authY+120); footer.ZIndex=12

-- resize
local totalH=authY+138
F.Size=UDim2.new(0,260,0,totalH)

UIS.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.KeyCode==Enum.KeyCode.F9 then F.Visible=not F.Visible end
end)

task.spawn(function() task.wait(0.5); applyAntiLag() end)

print("Mount Sakahayang | By Alfian | F9 toggle")
