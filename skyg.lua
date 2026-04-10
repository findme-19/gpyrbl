--[[
  MOUNT SAKAHAYANG SCRIPT - CYBERPUNK REDESIGN (FIXED)
  BY ALFIAN AZHRA
]]

local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local TweenSvc = game:GetService("TweenService")
local player   = Players.LocalPlayer

-- Cleanup old GUI
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

-- DATA KOORDINAT
local LOCATIONS = {
    [1] = {
        TARGET = Vector3.new(-312.329, 654.005, -952.673),
        NEAR   = Vector3.new(-307.023, 653.096, -957.354)
    },
    [2] = {
        TARGET = Vector3.new(4356.271, 2238.856, -9533.901),
        NEAR   = Vector3.new(4353.229, 2237.096, -9544.040)
    }
}

local running = false

-- COLOR PALETTE
local CYBER_BLUE   = Color3.fromRGB(0, 255, 255)
local CYBER_PINK   = Color3.fromRGB(255, 0, 150)
local CYBER_YELLOW = Color3.fromRGB(255, 230, 0)
local CYBER_BG     = Color3.fromRGB(10, 11, 15)
local CYBER_DARK   = Color3.fromRGB(5, 6, 8)
local CYBER_SURFACE = Color3.fromRGB(20, 22, 28)
local CYBER_BORDER  = Color3.fromRGB(40, 45, 55)
local WHT          = Color3.fromRGB(240, 240, 240)
local RED_ERR      = Color3.fromRGB(255, 50, 50)

local SVl, SDot, StatusGlow
local function setStatus(msg, colType)
    if not SVl then return end
    SVl.Text = msg:upper()
    local targetCol = WHT
    if colType == "done" then targetCol = CYBER_BLUE
    elseif colType == "err" then targetCol = RED_ERR
    elseif colType == "wait" then targetCol = CYBER_PINK
    elseif colType == "ready" then targetCol = CYBER_YELLOW end
    SVl.TextColor3 = targetCol
    if SDot then SDot.BackgroundColor3 = targetCol end
    if StatusGlow then StatusGlow.Color = targetCol end
end

local function findPrompt(targetPos)
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
                if pos and (pos-targetPos).Magnitude<120 then return v,par end
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

-- runSequence with Custom Messages & Re-added Fallback Logic
local function runSequence(index, msgConnect, msgTravel, msgLocate, msgFire, notifTitle, notifText)
    if running then return end
    local data = LOCATIONS[index]
    if not data then return end
    
    msgConnect = msgConnect or "LINKING TO CP"..index
    msgTravel  = msgTravel  or "CYBER-DASH"
    msgLocate  = msgLocate  or "SCANNING OBJECT"
    msgFire    = msgFire    or "EXECUTING ACCESS"
    notifTitle = notifTitle or "MOUNT SAKAHAYANG"
    notifText  = notifText  or "DESTINATION REACHED!"

    running=true
    task.spawn(function()
        setStatus(msgConnect, "wait"); task.wait(0.2)
        local char=player.Character or player.CharacterAdded:Wait()
        local hrp=char:WaitForChild("HumanoidRootPart",5)
        if not hrp then setStatus("SYS ERROR", "err"); running=false; return end
        local hum=char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed=0 end

        setStatus(msgTravel, "wait")
        hrp.CFrame=CFrame.new(data.NEAR+Vector3.new(0,5,0)); task.wait(0.3)

        setStatus(msgLocate, "wait")
        local pr,obj=findPrompt(data.TARGET)
        if obj then
            local pos=getObjPos(obj)
            if pos then
                local off=(data.NEAR-pos)
                off=off.Magnitude>0.1 and off.Unit*7 or Vector3.new(0,0,7)
                hrp.CFrame=CFrame.new(pos+off+Vector3.new(0,3,0)); task.wait(0.25)
            end
        end

        if hum then hum.WalkSpeed=16 end
        setStatus(msgFire, "wait"); task.wait(0.12)

        local fired=false
        if pr then
            for _=1,3 do
                local ok=pcall(function() fireproximityprompt(pr) end)
                if ok then fired=true;break end
                task.wait(0.08)
            end
        end

        -- [KODE YANG TADI TERHAPUS: SMART REPOSITION FALLBACK]
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

        setStatus("ACCESS GRANTED", "done")
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = notifTitle,
                Text  = notifText,
                Duration = 4
            })
        end)
        running=false
    end)
end

-- GUI REDESIGN (CYBERPUNK THEME)
local sg=Instance.new("ScreenGui")
sg.Name="SakahayangAlfian"; sg.ResetOnSpawn=false
sg.DisplayOrder=9999; sg.IgnoreGuiInset=true
sg.Parent=player.PlayerGui

local F=Instance.new("Frame",sg)
F.Size=UDim2.new(0,260,0,500)
F.Position=UDim2.new(0,30,0,100)
F.BackgroundColor3=CYBER_BG; F.BorderSizePixel=0
F.Active=true; F.Draggable=true; F.ZIndex=10
do Instance.new("UICorner",F).CornerRadius=UDim.new(0,4) end
local MainStroke = Instance.new("UIStroke",F)
MainStroke.Color = CYBER_BLUE; MainStroke.Thickness = 2; MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local LLine = Instance.new("Frame",F)
LLine.Size = UDim2.new(0,2,1,0); LLine.BackgroundColor3 = CYBER_PINK; LLine.BorderSizePixel=0; LLine.ZIndex=11

local TB=Instance.new("Frame",F)
TB.Size=UDim2.new(1,0,0,50); TB.BackgroundColor3=CYBER_DARK; TB.BorderSizePixel=0; TB.ZIndex=11
do 
    local bLine = Instance.new("Frame",TB)
    bLine.Size = UDim2.new(1,0,0,1); bLine.Position = UDim2.new(0,0,1,0); bLine.BackgroundColor3 = CYBER_BLUE; bLine.BorderSizePixel=0; bLine.ZIndex=12
end

local TTitle=Instance.new("TextLabel",TB)
TTitle.Size=UDim2.new(1,-40,1,0); TTitle.Position=UDim2.new(0,15,0,0)
TTitle.BackgroundTransparency=1; TTitle.Text="SAKAHAYANG_OS [v2]"; TTitle.TextColor3=CYBER_BLUE
TTitle.Font=Enum.Font.Code; TTitle.TextSize=14; TTitle.TextXAlignment=Enum.TextXAlignment.Left; TTitle.ZIndex=13

local XB=Instance.new("TextButton",TB)
XB.Size=UDim2.new(0,30,0,30); XB.Position=UDim2.new(1,-35,0.5,-15)
XB.BackgroundColor3=CYBER_BG; XB.Text="X"; XB.TextColor3=CYBER_PINK
XB.Font=Enum.Font.Code; XB.TextSize=16; XB.ZIndex=14
do Instance.new("UIStroke",XB).Color = CYBER_PINK end
XB.MouseButton1Click:Connect(function() sg:Destroy() end)

local function mkCard(yp, h, title)
    local c=Instance.new("Frame",F)
    c.Size=UDim2.new(1,-30,0,h); c.Position=UDim2.new(0,18,0,yp)
    c.BackgroundColor3=CYBER_SURFACE; c.BorderSizePixel=0; c.ZIndex=12
    local s = Instance.new("UIStroke",c); s.Color=CYBER_BORDER; s.Thickness=1
    if title then
        local t = Instance.new("TextLabel",c)
        t.Size = UDim2.new(1,0,0,-15); t.Position = UDim2.new(0,0,0,-2)
        t.BackgroundTransparency=1; t.Text=title:upper(); t.TextColor3=CYBER_BORDER
        t.Font=Enum.Font.Code; t.TextSize=9; t.TextXAlignment=Enum.TextXAlignment.Left
    end
    return c
end

local sc = mkCard(70, 40, "System Status")
SDot = Instance.new("Frame",sc)
SDot.Size = UDim2.new(0,4,0,15); SDot.Position = UDim2.new(0,10,0.5,-7.5)
SDot.BackgroundColor3 = CYBER_YELLOW; SDot.BorderSizePixel=0; SDot.ZIndex=13
SVl = Instance.new("TextLabel",sc)
SVl.Size = UDim2.new(1,-30,1,0); SVl.Position = UDim2.new(0,25,0,0)
SVl.BackgroundTransparency=1; SVl.Text="SYSTEM READY"; SVl.TextColor3=CYBER_YELLOW
SVl.Font=Enum.Font.Code; SVl.TextSize=12; SVl.TextXAlignment=Enum.TextXAlignment.Left; SVl.ZIndex=13
StatusGlow = Instance.new("UIStroke", SVl)
StatusGlow.Color = CYBER_YELLOW; StatusGlow.Thickness = 0.5

local lgc = mkCard(125, 40, "Optimization")
local lgLbl = Instance.new("TextLabel",lgc)
lgLbl.Size=UDim2.new(0.6,0,1,0); lgLbl.Position=UDim2.new(0,10,0,0); lgLbl.BackgroundTransparency=1
lgLbl.Text="LOW_GRAPHICS.exe"; lgLbl.TextColor3=WHT; lgLbl.Font=Enum.Font.Code; lgLbl.TextSize=10; lgLbl.TextXAlignment=Enum.TextXAlignment.Left; lgLbl.ZIndex=13
local ALBtn=Instance.new("TextButton",lgc)
ALBtn.Size=UDim2.new(0,50,0,20); ALBtn.Position=UDim2.new(1,-60,0.5,-10)
ALBtn.BackgroundColor3=CYBER_DARK; ALBtn.Text="ON"; ALBtn.TextColor3=CYBER_BLUE
ALBtn.Font=Enum.Font.Code; ALBtn.TextSize=10; ALBtn.ZIndex=13
do Instance.new("UIStroke",ALBtn).Color = CYBER_BLUE end

local alState=true
ALBtn.MouseButton1Click:Connect(function()
    alState=not alState
    ALBtn.Text=alState and "ON" or "OFF"
    ALBtn.TextColor3=alState and CYBER_BLUE or CYBER_BORDER
    if alState then applyAntiLag() end
end)

local btnW = (260 - 45) / 2
local StartBtn1=Instance.new("TextButton",F)
StartBtn1.Size=UDim2.new(0,btnW,0,40); StartBtn1.Position=UDim2.new(0,18,0,185)
StartBtn1.BackgroundColor3=CYBER_BLUE; StartBtn1.Text="ACCESS CP_01"
StartBtn1.TextColor3=CYBER_DARK; StartBtn1.Font=Enum.Font.Code; StartBtn1.TextSize=11; StartBtn1.ZIndex=12

local StartBtn2=Instance.new("TextButton",F)
StartBtn2.Size=UDim2.new(0,btnW,0,40); StartBtn2.Position=UDim2.new(0,btnW+28,0,185)
StartBtn2.BackgroundColor3=CYBER_PINK; StartBtn2.Text="ACCESS CP_02"
StartBtn2.TextColor3=CYBER_DARK; StartBtn2.Font=Enum.Font.Code; StartBtn2.TextSize=11; StartBtn2.ZIndex=12

local info = mkCard(250, 110, "Neural Link Author")
local function addInfo(txt, col, yp)
    local l = Instance.new("TextLabel",info)
    l.Size = UDim2.new(1,-20,0,15); l.Position = UDim2.new(0,10,0,yp)
    l.BackgroundTransparency=1; l.Text=txt; l.TextColor3=col; l.Font=Enum.Font.Code; l.TextSize=9; l.TextXAlignment=Enum.TextXAlignment.Left; l.ZIndex=13
end
addInfo("USER: ALFIAN AZHRA", WHT, 10)
addInfo("FB: Alfian Azhra", CYBER_BLUE, 30)
addInfo("WA: 08998289407", CYBER_YELLOW, 50)
addInfo("STATUS: OFFICIAL AUTHOR", CYBER_PINK, 75)

local lic = Instance.new("TextLabel",F)
lic.Size = UDim2.new(1,0,0,20); lic.Position = UDim2.new(0,0,1,-25)
lic.BackgroundTransparency=1; lic.Text="© 2026 SAKAHAYANG_NETWORKS"; lic.TextColor3=CYBER_BORDER
lic.Font=Enum.Font.Code; lic.TextSize=8; lic.ZIndex=11

StartBtn1.MouseButton1Click:Connect(function()
    runSequence(1, "ESTABLISHING_LINK...", "DASHING_TO_TARGET", "SCANNING_REWARD", "INJECTING_CODE", "CP 01 CONNECTED", "Cyber-Link CP 01 Berhasil!")
end)
StartBtn2.MouseButton1Click:Connect(function()
    runSequence(2, "BOOTING_PROTOCOL...", "WARPING_SPACE", "DETECTING_SIGNAL", "OVERRIDING_SYSTEM", "CP 02 CONNECTED", "Cyber-Link CP 02 Berhasil!")
end)

UIS.InputBegan:Connect(function(inp,gpe) if not gpe and inp.KeyCode==Enum.KeyCode.F9 then F.Visible=not F.Visible end end)
task.spawn(function() task.wait(0.5); applyAntiLag() end)
print("Sakahayang CyberOS Loaded | Re-Added Fallback")
