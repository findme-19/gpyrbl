--[[
  MOUNT ZIHAN v5 — CP NAVIGATOR + AUTO SCAN GOPAY
  BY ALFIAN
]]

local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local TweenSvc = game:GetService("TweenService")
local player   = Players.LocalPlayer

pcall(function()
    for _,g in ipairs(player.PlayerGui:GetChildren()) do
        if g.Name=="ZihanV5" then g:Destroy() end
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
-- CP LIST
-- ══════════════════════════════
local CP={
    Vector3.new(3.718,    9.096,    -814.067),
    Vector3.new(15.466,   0.587,    -1582.924),
    Vector3.new(52.487,   -2.904,   -2586.783),
    Vector3.new(697.765,  -2.904,   -3376.978),
    Vector3.new(763.092,  -2.904,   -4153.929),
    Vector3.new(716.686,  -0.304,   -5268.813),
    Vector3.new(719.614,  9.096,    -6661.167),
    Vector3.new(732.555,  65.928,   -7360.012),
    Vector3.new(730.029,  45.096,   -8256.237),
    Vector3.new(730.500,  45.096,   -8255.000),
    Vector3.new(693.703,  29.096,   -9473.930),
    Vector3.new(633.774,  17.096,   -10758.329),
    Vector3.new(-274.093, 13.096,   -10770.299),
    Vector3.new(-2132.081,65.096,   -10861.727),
    Vector3.new(-2079.158,49.096,   -12480.547),
    Vector3.new(-1986.328,177.096,  -13240.370),
    Vector3.new(-565.005, 173.096,  -13231.008),
    Vector3.new(367.000,  161.096,  -13302.000),
    Vector3.new(1970.672, 977.096,  -13425.370),
    Vector3.new(2916.492, 969.096,  -13417.518),
    Vector3.new(3791.164, 968.896,  -13518.130),
    Vector3.new(3807.351, 985.096,  -14792.040),
    Vector3.new(3923.011, 1061.096, -15996.030),
    Vector3.new(3786.341, 1053.096, -16987.496),
    Vector3.new(2837.195, 1109.096, -16993.457),
    Vector3.new(2091.328, 1193.096, -17300.779),
    Vector3.new(1784.328, 1185.096, -18236.371),
    Vector3.new(1762.944, 1333.096, -19254.902),
    Vector3.new(1748.221, 1297.096, -20034.227),
    Vector3.new(1782.646, 1269.096, -21033.840),
    Vector3.new(1769.587, 1477.096, -21856.654),
    Vector3.new(1796.448, 1485.096, -22655.854),
    Vector3.new(1795.741, 1509.096, -23597.246),
    Vector3.new(1799.751, 1505.096, -24445.350),
    Vector3.new(1886.418, 1505.096, -25389.225),
    Vector3.new(1920.820, 1493.096, -26689.889),
    Vector3.new(1979.090, 1249.096, -27825.799),
    Vector3.new(2126.400, 1557.096, -28848.203),
    Vector3.new(4527.858, 1557.096, -28726.459),
    Vector3.new(4577.239, 1545.096, -27849.279),
    Vector3.new(5582.329, 1865.096, -27783.371),
    Vector3.new(5572.785, 1869.096, -26636.680),
    Vector3.new(5655.672, 1989.096, -25737.371),
    Vector3.new(6649.654, 2161.096, -25626.457),
    Vector3.new(6632.943, 2153.096, -24752.887),
    Vector3.new(6627.004, 2149.096, -23977.115),
    Vector3.new(6659.955, 2181.096, -23020.305),
    Vector3.new(6544.157, 2133.096, -22056.053),
    Vector3.new(6632.839, 2167.344, -21428.551),
    Vector3.new(7466.051, 2165.096, -21427.057),
    Vector3.new(8303.392, 2540.896, -21564.656),
    Vector3.new(9209.609, 5054.228, -21342.803),
    Vector3.new(9814.756, 2951.411, -21591.408),
    Vector3.new(9795.221, 2950.692, -21588.719),
}

local CLAIM=Vector3.new(10284.1,3013.4,-21465.0)
local SCAN_RADIUS = 200  -- diperluas karena log terbukti 200 stud dari CP47
local CP_DELAY    = 1.5  -- delay antar CP sesuai permintaan

local GR =Color3.fromRGB(150,255,170)
local RD =Color3.fromRGB(255,100,100)
local YL =Color3.fromRGB(230,200,100)
local CY =Color3.fromRGB(100,210,255)
local WHT=Color3.fromRGB(230,230,230)
local DIM=Color3.fromRGB(100,100,100)
local PNL=Color3.fromRGB(14,14,14)
local MID=Color3.fromRGB(22,22,22)
local BRD=Color3.fromRGB(34,34,34)
local BRD2=Color3.fromRGB(50,50,50)
local SIL=Color3.fromRGB(153,153,153)
local DEEP=Color3.fromRGB(8,8,8)

local running   = false
local stopped   = false
local currentCP = 0
local SVl,SDot,PFill,PPct
local cpBtnRefs = {}

local function setStatus(msg,col)
    if not SVl then return end
    SVl.Text=msg
    local c=col=="done" and GR or col=="err" and RD
              or col=="wait" and YL or col=="cyan" and CY or WHT
    SVl.TextColor3=c
    if SDot then SDot.BackgroundColor3=c end
end

local function setProgress(cur,total)
    if not PFill or not PPct then return end
    local pct=math.clamp(cur/total,0,1)
    TweenSvc:Create(PFill,TweenInfo.new(0.2),{Size=UDim2.new(pct,0,1,0)}):Play()
    PPct.Text=cur.." / "..total
    PPct.TextColor3=pct>=1 and GR or pct>0.7 and YL or DIM
end

local function highlightCP(idx)
    for i,btn in ipairs(cpBtnRefs) do
        local active=(i==idx)
        btn.BackgroundColor3=active and Color3.fromRGB(30,30,30) or MID
        btn.TextColor3=active and WHT or DIM
        local sk=btn:FindFirstChildOfClass("UIStroke")
        if sk then sk.Color=active and SIL or BRD end
    end
    -- scroll CP ke posisi visible
    if cpBtnRefs[idx] then
        task.defer(function()
            local scroll=cpBtnRefs[idx].Parent
            if scroll and scroll:IsA("ScrollingFrame") then
                local rowH=32
                local cols=6
                local row=math.floor((idx-1)/cols)
                scroll.CanvasPosition=Vector2.new(0,math.max(0,(row-1)*rowH))
            end
        end)
    end
end

-- ══════════════════════════════
-- SCAN GOPAY
-- ══════════════════════════════
local KEYWORDS={"claim","voucher","gopay","redemption","klaim","reward"}
local KNOWN_OBJ={"RedemptionPointBasepart","Gopay","GopayPoint","Primary",
                  "VoucherPoint","ClaimPoint","Part"}

local function hasKW(s)
    if not s or s=="" then return false end
    local sl=s:lower()
    for _,kw in ipairs(KEYWORDS) do
        if sl:match(kw) then return true end
    end
    return false
end

local function isKnownObj(name)
    local nl=name:lower()
    for _,n in ipairs(KNOWN_OBJ) do
        if nl==n:lower() then return true end
    end
    return nl:match("redemption") or nl:match("gopay") or
           nl:match("voucher") or nl:match("claim")
end

local function getObjPos(obj)
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local pp=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        return pp and pp.Position
    end
end

local function scanGopayNear(centerPos, radius)
    local results,seen={},{}
    -- Pass 1: ProximityPrompt langsung
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") and not seen[v] then
            local at=v.ActionText or ""
            local ot=v.ObjectText or ""
            local pn=v.Parent and v.Parent.Name or ""
            if hasKW(at) or hasKW(ot) or hasKW(pn) or isKnownObj(pn) then
                local par=v.Parent
                if par then
                    local pos=getObjPos(par)
                    if pos and (pos-centerPos).Magnitude<=radius then
                        seen[v]=true
                        table.insert(results,{
                            prompt=v, pos=pos,
                            label=at~="" and at or pn,
                            dist=(pos-centerPos).Magnitude
                        })
                    end
                end
            end
        end
    end
    -- Pass 2: nama objek dikenal
    for _,v in ipairs(workspace:GetDescendants()) do
        if (v:IsA("BasePart") or v:IsA("Model")) and isKnownObj(v.Name) then
            local pos=getObjPos(v)
            if pos and (pos-centerPos).Magnitude<=radius then
                local pr=v:FindFirstChildOfClass("ProximityPrompt")
                if pr and not seen[pr] then
                    seen[pr]=true
                    table.insert(results,{
                        prompt=pr, pos=pos,
                        label=v.Name,
                        dist=(pos-centerPos).Magnitude
                    })
                end
            end
        end
    end
    -- Pass 3: BillboardGui / SurfaceGui text
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BillboardGui") or v:IsA("SurfaceGui") then
            local par=v.Parent
            if par then
                local pos=getObjPos(par)
                if pos and (pos-centerPos).Magnitude<=radius then
                    for _,c in ipairs(v:GetDescendants()) do
                        if (c:IsA("TextLabel") or c:IsA("TextButton")) and hasKW(c.Text) then
                            local pr=par:FindFirstChildOfClass("ProximityPrompt")
                            if pr and not seen[pr] then
                                seen[pr]=true
                                table.insert(results,{
                                    prompt=pr, pos=pos,
                                    label=c.Text,
                                    dist=(pos-centerPos).Magnitude
                                })
                            end
                            break
                        end
                    end
                end
            end
        end
    end
    -- sort by distance
    table.sort(results,function(a,b) return a.dist<b.dist end)
    return results
end

-- ══════════════════════════════
-- FIRE PROMPTS
-- ══════════════════════════════
local function firePrompts(results, hrp, hum)
    if not results or #results==0 then return 0 end
    local fired=0
    for _,r in ipairs(results) do
        local dir=(hrp.Position-r.pos)
        local safe=r.pos+(dir.Magnitude>0.1 and dir.Unit*7 or Vector3.new(0,0,7))
        hrp.CFrame=CFrame.new(safe+Vector3.new(0,3,0))
        task.wait(0.2)
        for _=1,3 do
            local ok=pcall(function() fireproximityprompt(r.prompt) end)
            if ok then fired=fired+1;break end
            task.wait(0.08)
        end
        if fired==0 then
            local d=(r.pos-hrp.Position)
            if d.Magnitude>0 then hrp.CFrame=CFrame.new(hrp.Position+d.Unit*3) end
            task.wait(0.12)
            pcall(function() fireproximityprompt(r.prompt) end)
            fired=fired+1
        end
        break -- claim pertama saja
    end
    return fired
end

-- ══════════════════════════════
-- GOTO CP
-- ══════════════════════════════
local function gotoCP(idx, hrp, hum, doScan)
    if not CP[idx] then return false,false end
    local pt=CP[idx]
    currentCP=idx
    highlightCP(idx)
    setStatus("CP "..idx.."/"..#CP,"wait")
    setProgress(idx,#CP)

    -- TP dengan retry
    for _=1,3 do
        hrp.CFrame=CFrame.new(pt+Vector3.new(0,5,0))
        task.wait(0.25)
        if (hrp.Position-pt).Magnitude<20 then break end
        hrp.CFrame=CFrame.new(pt+Vector3.new(0,3,0))
        task.wait(0.2)
    end

    if not doScan then return true,false end

    -- delay scan 1.5 detik setelah TP agar map load
    task.wait(CP_DELAY)
    if stopped then return false,false end

    -- scan gopay
    local results=scanGopayNear(pt, SCAN_RADIUS)
    if #results>0 then
        setStatus("⚡ GOPAY FOUND CP"..idx.." ("..math.floor(results[1].dist).."s)","cyan")
        if hum then hum.WalkSpeed=16 end
        task.wait(0.1)
        local fired=firePrompts(results,hrp,hum)
        if fired>0 then
            setStatus("✓ CLAIMED AT CP"..idx,"done")
            pcall(function()
                game:GetService("StarterGui"):SetCore("SendNotification",{
                    Title="Zihan v5",
                    Text="GoPay ditemukan di CP"..idx.."! Claim selesai.",
                    Duration=5
                })
            end)
            return true,true
        end
    end
    return true,false
end

-- ══════════════════════════════
-- FINAL CLAIM SEQUENCE
-- ══════════════════════════════
local function runFinalClaim(hrp, hum)
    setStatus("MENUJU CLAIM POINT","wait")
    if hum then hum.WalkSpeed=0 end
    hrp.CFrame=CFrame.new(9874.0,2960.8,-21571.6);task.wait(0.3)
    if stopped then return end
    hrp.CFrame=CFrame.new(9233.1,5064.2,-21332.8);task.wait(0.3)
    if stopped then return end
    hrp.CFrame=CFrame.new(9814.0,2956.7,-21591.3);task.wait(0.25)
    if stopped then return end
    hrp.CFrame=CFrame.new(CLAIM+Vector3.new(0,5,0));task.wait(0.5)
    if hum then hum.WalkSpeed=16 end;task.wait(0.15)

    local results=scanGopayNear(CLAIM,200)
    if #results>0 then
        local fired=firePrompts(results,hrp,hum)
        if fired>0 then setStatus("✓ CLAIMED","done");return end
    end
    -- jump fallback
    if hum then hum.Jump=true end;task.wait(0.12)
    local r2=scanGopayNear(CLAIM,200)
    if #r2>0 then firePrompts(r2,hrp,hum) end
    setStatus("DONE — CLAIM MANUAL","done")
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",
            {Title="Zihan v5",Text="Selesai! Claim voucher sekarang.",Duration=3})
    end)
end

-- ══════════════════════════════
-- SEQUENCES
-- ══════════════════════════════
local function runAutoCP(fromCP)
    if running then return end
    running=true;stopped=false
    task.spawn(function()
        local char=player.Character or player.CharacterAdded:Wait()
        local hrp=char:WaitForChild("HumanoidRootPart",5)
        if not hrp then setStatus("ERROR","err");running=false;return end
        local hum=char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed=0 end
        local from=math.clamp(fromCP or 1,1,#CP)
        for i=from,#CP do
            if stopped then setStatus("STOPPED","err");running=false;return end
            local ok,found=gotoCP(i,hrp,hum,true)
            if not ok then running=false;return end
            if found then running=false;return end
            -- tidak ada gopay, lanjut ke CP berikutnya
            -- (delay sudah ada di dalam gotoCP via CP_DELAY)
        end
        -- semua CP selesai, coba claim akhir
        if not stopped then runFinalClaim(hrp,hum) end
        running=false
    end)
end

local function runClaimOnly()
    if running then return end
    running=true;stopped=false
    task.spawn(function()
        local char=player.Character or player.CharacterAdded:Wait()
        local hrp=char:WaitForChild("HumanoidRootPart",5)
        if not hrp then setStatus("ERROR","err");running=false;return end
        local hum=char:FindFirstChildOfClass("Humanoid")
        runFinalClaim(hrp,hum)
        running=false
    end)
end

local function runGotoCPManual(idx)
    if running then return end
    running=true;stopped=false
    task.spawn(function()
        local char=player.Character or player.CharacterAdded:Wait()
        local hrp=char:WaitForChild("HumanoidRootPart",5)
        if not hrp then setStatus("ERROR","err");running=false;return end
        local hum=char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed=0 end
        local ok,found=gotoCP(idx,hrp,hum,true)
        if not found then setStatus("CP "..idx.." — NO GOPAY","done") end
        if hum then hum.WalkSpeed=16 end
        running=false
    end)
end

-- ══════════════════════════════
-- GUI
-- ══════════════════════════════
local sg=Instance.new("ScreenGui")
sg.Name="ZihanV5";sg.ResetOnSpawn=false
sg.DisplayOrder=9999;sg.IgnoreGuiInset=false
sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
sg.Parent=player.PlayerGui

-- PANEL 300 × 390
local F=Instance.new("Frame",sg)
F.Size=UDim2.new(0,300,0,390)
F.Position=UDim2.new(0.5,-150,0.5,-195)
F.BackgroundColor3=PNL;F.BorderSizePixel=0
F.Active=true;F.Draggable=true;F.ZIndex=10
do Instance.new("UICorner",F).CornerRadius=UDim.new(0,8) end
do Instance.new("UIStroke",F).Color=BRD end

local ac=Instance.new("Frame",F)
ac.Size=UDim2.new(1,-4,0,1);ac.Position=UDim2.new(0,2,0,0)
ac.BackgroundColor3=SIL;ac.BorderSizePixel=0;ac.ZIndex=15
do Instance.new("UICorner",ac).CornerRadius=UDim.new(0,1) end

-- TOPBAR y=0 h=38
local TB=Instance.new("Frame",F)
TB.Size=UDim2.new(1,0,0,38);TB.Position=UDim2.new(0,0,0,0)
TB.BackgroundColor3=DEEP;TB.BorderSizePixel=0;TB.ZIndex=11
do Instance.new("UICorner",TB).CornerRadius=UDim.new(0,8) end
do local fx=Instance.new("Frame",TB);fx.Size=UDim2.new(1,0,0,8);fx.Position=UDim2.new(0,0,1,-8);fx.BackgroundColor3=DEEP;fx.BorderSizePixel=0;fx.ZIndex=11 end
do local bx=Instance.new("Frame",TB);bx.Size=UDim2.new(1,0,0,1);bx.Position=UDim2.new(0,0,1,-1);bx.BackgroundColor3=BRD;bx.BorderSizePixel=0;bx.ZIndex=12 end

do local l=Instance.new("TextLabel",TB);l.Size=UDim2.new(1,-44,0,16);l.Position=UDim2.new(0,10,0,5);l.BackgroundTransparency=1;l.Text="MOUNT ZIHAN v5";l.TextColor3=WHT;l.Font=Enum.Font.GothamBold;l.TextSize=11;l.TextXAlignment=Enum.TextXAlignment.Left;l.ZIndex=13 end
do local l=Instance.new("TextLabel",TB);l.Size=UDim2.new(1,-44,0,12);l.Position=UDim2.new(0,10,0,22);l.BackgroundTransparency=1;l.Text="BY ALFIAN  ·  AUTO SCAN GOPAY PER CP  ·  1.5s/CP";l.TextColor3=DIM;l.Font=Enum.Font.Gotham;l.TextSize=7;l.TextXAlignment=Enum.TextXAlignment.Left;l.ZIndex=13 end

local XB=Instance.new("TextButton",TB)
XB.Size=UDim2.new(0,22,0,22);XB.Position=UDim2.new(1,-26,0.5,-11)
XB.BackgroundColor3=MID;XB.Text="✕";XB.TextColor3=DIM
XB.Font=Enum.Font.GothamBold;XB.TextSize=9;XB.BorderSizePixel=0;XB.ZIndex=14
do Instance.new("UICorner",XB).CornerRadius=UDim.new(0,5) end
do Instance.new("UIStroke",XB).Color=BRD2 end
XB.MouseEnter:Connect(function() XB.TextColor3=WHT end)
XB.MouseLeave:Connect(function() XB.TextColor3=DIM end)
XB.MouseButton1Click:Connect(function()
    TweenSvc:Create(F,TweenInfo.new(0.15),{Size=UDim2.new(0,300,0,0)}):Play()
    task.delay(0.15,function() sg:Destroy() end)
end)

-- STATUS y=46 h=22
local sr=Instance.new("Frame",F)
sr.Size=UDim2.new(1,-24,0,22);sr.Position=UDim2.new(0,12,0,46)
sr.BackgroundColor3=MID;sr.BorderSizePixel=0;sr.ZIndex=12
do Instance.new("UICorner",sr).CornerRadius=UDim.new(0,5) end
do Instance.new("UIStroke",sr).Color=BRD end
SDot=Instance.new("Frame",sr);SDot.Size=UDim2.new(0,5,0,5);SDot.Position=UDim2.new(0,8,0.5,-2);SDot.BackgroundColor3=GR;SDot.BorderSizePixel=0;SDot.ZIndex=13
do Instance.new("UICorner",SDot).CornerRadius=UDim.new(1,0) end
SVl=Instance.new("TextLabel",sr);SVl.Size=UDim2.new(1,-22,1,0);SVl.Position=UDim2.new(0,18,0,0);SVl.BackgroundTransparency=1;SVl.Text="READY";SVl.TextColor3=GR;SVl.Font=Enum.Font.GothamBold;SVl.TextSize=10;SVl.TextXAlignment=Enum.TextXAlignment.Left;SVl.TextTruncate=Enum.TextTruncate.AtEnd;SVl.ZIndex=13

-- PROGRESS y=76 h=16
local pb=Instance.new("Frame",F)
pb.Size=UDim2.new(1,-24,0,16);pb.Position=UDim2.new(0,12,0,76)
pb.BackgroundColor3=MID;pb.BorderSizePixel=0;pb.ZIndex=12
do Instance.new("UICorner",pb).CornerRadius=UDim.new(0,5) end
do Instance.new("UIStroke",pb).Color=BRD end
PFill=Instance.new("Frame",pb);PFill.Size=UDim2.new(0,0,1,0);PFill.BackgroundColor3=GR;PFill.BorderSizePixel=0;PFill.ZIndex=13
do Instance.new("UICorner",PFill).CornerRadius=UDim.new(0,5) end
PPct=Instance.new("TextLabel",pb);PPct.Size=UDim2.new(1,0,1,0);PPct.BackgroundTransparency=1;PPct.Text="0 / "..#CP;PPct.TextColor3=DIM;PPct.Font=Enum.Font.GothamBold;PPct.TextSize=8;PPct.TextXAlignment=Enum.TextXAlignment.Center;PPct.ZIndex=14

-- SCAN INFO y=100 h=16
local scanInfoLbl=Instance.new("TextLabel",F)
scanInfoLbl.Size=UDim2.new(1,-24,0,16);scanInfoLbl.Position=UDim2.new(0,12,0,100)
scanInfoLbl.BackgroundTransparency=1
scanInfoLbl.Text="🔍 Scan radius: "..SCAN_RADIUS.." stud  |  Delay: "..CP_DELAY.."s per CP  |  Klik CP untuk TP manual"
scanInfoLbl.TextColor3=Color3.fromRGB(50,50,65);scanInfoLbl.Font=Enum.Font.Gotham;scanInfoLbl.TextSize=7
scanInfoLbl.TextXAlignment=Enum.TextXAlignment.Left;scanInfoLbl.ZIndex=12

-- CP GRID y=120 h=170
local cpScroll=Instance.new("ScrollingFrame",F)
cpScroll.Size=UDim2.new(1,-24,0,170);cpScroll.Position=UDim2.new(0,12,0,120)
cpScroll.BackgroundColor3=DEEP;cpScroll.BorderSizePixel=0
cpScroll.ScrollBarThickness=2;cpScroll.ScrollBarImageColor3=BRD2
cpScroll.CanvasSize=UDim2.new(0,0,0,0);cpScroll.ZIndex=12
do Instance.new("UICorner",cpScroll).CornerRadius=UDim.new(0,6) end
do Instance.new("UIStroke",cpScroll).Color=BRD end

local cpGrid=Instance.new("UIGridLayout",cpScroll)
cpGrid.CellSize=UDim2.new(0,40,0,28)
cpGrid.CellPadding=UDim2.new(0,3,0,3)
cpGrid.SortOrder=Enum.SortOrder.LayoutOrder
local cpPad=Instance.new("UIPadding",cpScroll)
cpPad.PaddingLeft=UDim.new(0,4);cpPad.PaddingRight=UDim.new(0,4)
cpPad.PaddingTop=UDim.new(0,4);cpPad.PaddingBottom=UDim.new(0,4)

for i=1,#CP do
    local btn=Instance.new("TextButton",cpScroll)
    btn.LayoutOrder=i;btn.BackgroundColor3=MID;btn.BorderSizePixel=0
    btn.Text="CP"..i;btn.TextColor3=DIM
    btn.Font=Enum.Font.GothamBold;btn.TextSize=8;btn.ZIndex=13
    do Instance.new("UICorner",btn).CornerRadius=UDim.new(0,4) end
    do local s=Instance.new("UIStroke",btn);s.Color=BRD end
    table.insert(cpBtnRefs,btn)
    local ci=i
    btn.MouseButton1Click:Connect(function()
        if running then return end
        runGotoCPManual(ci)
    end)
end

cpGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    cpScroll.CanvasSize=UDim2.new(0,0,0,cpGrid.AbsoluteContentSize.Y+8)
end)

-- SEP y=298
local sep=Instance.new("Frame",F)
sep.Size=UDim2.new(1,-24,0,1);sep.Position=UDim2.new(0,12,0,298)
sep.BackgroundColor3=BRD;sep.BorderSizePixel=0;sep.ZIndex=12

-- ANTI-LAG y=306 h=24
local al=Instance.new("Frame",F)
al.Size=UDim2.new(1,-24,0,24);al.Position=UDim2.new(0,12,0,306)
al.BackgroundColor3=MID;al.BorderSizePixel=0;al.ZIndex=12
do Instance.new("UICorner",al).CornerRadius=UDim.new(0,5) end
do Instance.new("UIStroke",al).Color=BRD end
do local l=Instance.new("TextLabel",al);l.Size=UDim2.new(0.65,0,1,0);l.Position=UDim2.new(0,8,0,0);l.BackgroundTransparency=1;l.Text="ANTI-LAG / LOW GRAPHICS";l.TextColor3=DIM;l.Font=Enum.Font.GothamBold;l.TextSize=8;l.TextXAlignment=Enum.TextXAlignment.Left;l.ZIndex=13 end
local ALB=Instance.new("TextButton",al);ALB.Size=UDim2.new(0,38,0,18);ALB.Position=UDim2.new(1,-42,0.5,-9);ALB.BackgroundColor3=MID;ALB.Text="ON";ALB.TextColor3=WHT;ALB.Font=Enum.Font.GothamBold;ALB.TextSize=9;ALB.BorderSizePixel=0;ALB.ZIndex=13
do Instance.new("UICorner",ALB).CornerRadius=UDim.new(0,4) end
local ALsk=Instance.new("UIStroke",ALB);ALsk.Color=SIL
ALB.MouseButton1Click:Connect(function()
    local on=ALB.Text=="ON"
    ALB.Text=on and "OFF" or "ON";ALB.TextColor3=on and DIM or WHT;ALsk.Color=on and BRD or SIL
    if not on then applyAntiLag() end
end)

-- TOMBOL BAWAH y=338 h=42
-- STOP
local StopBtn=Instance.new("TextButton",F)
StopBtn.Size=UDim2.new(0,68,0,42);StopBtn.Position=UDim2.new(0,12,0,338)
StopBtn.BackgroundColor3=Color3.fromRGB(38,10,10);StopBtn.Text="■ STOP";StopBtn.TextColor3=RD
StopBtn.Font=Enum.Font.GothamBold;StopBtn.TextSize=10;StopBtn.BorderSizePixel=0;StopBtn.ZIndex=12
do Instance.new("UICorner",StopBtn).CornerRadius=UDim.new(0,7) end
do local s=Instance.new("UIStroke",StopBtn);s.Color=Color3.fromRGB(70,18,18) end
StopBtn.MouseButton1Click:Connect(function()
    stopped=true;StopBtn.Text="✓";StopBtn.TextColor3=YL
    task.delay(1.5,function() StopBtn.Text="■ STOP";StopBtn.TextColor3=RD end)
end)

-- CLAIM
local ClaimBtn=Instance.new("TextButton",F)
ClaimBtn.Size=UDim2.new(0,90,0,42);ClaimBtn.Position=UDim2.new(0,88,0,338)
ClaimBtn.BackgroundColor3=Color3.fromRGB(10,35,55);ClaimBtn.Text="⚡ CLAIM";ClaimBtn.TextColor3=CY
ClaimBtn.Font=Enum.Font.GothamBold;ClaimBtn.TextSize=10;ClaimBtn.BorderSizePixel=0;ClaimBtn.ZIndex=12
do Instance.new("UICorner",ClaimBtn).CornerRadius=UDim.new(0,7) end
do local s=Instance.new("UIStroke",ClaimBtn);s.Color=Color3.fromRGB(30,80,120) end
ClaimBtn.MouseButton1Click:Connect(function()
    if running then return end
    ClaimBtn.Text="⏳...";ClaimBtn.TextColor3=YL
    runClaimOnly()
    task.spawn(function()
        while running do task.wait(0.1) end
        task.wait(0.4)
        ClaimBtn.Text="⚡ CLAIM";ClaimBtn.TextColor3=CY
    end)
end)

-- AUTO CP
local StartBtn=Instance.new("TextButton",F)
StartBtn.Size=UDim2.new(1,-186,0,42);StartBtn.Position=UDim2.new(1,-114,0,338)
StartBtn.BackgroundColor3=WHT;StartBtn.Text="▶ AUTO CP"
StartBtn.TextColor3=DEEP;StartBtn.Font=Enum.Font.GothamBold
StartBtn.TextSize=10;StartBtn.BorderSizePixel=0;StartBtn.ZIndex=12
do Instance.new("UICorner",StartBtn).CornerRadius=UDim.new(0,7) end
do Instance.new("UIStroke",StartBtn).Color=BRD2 end

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
    StartBtn.BackgroundColor3=MID;StartBtn.TextColor3=YL;StartBtn.Text="▶ RUNNING"
    runAutoCP(1)
    task.spawn(function()
        while running do task.wait(0.1) end
        task.wait(0.4)
        StartBtn.BackgroundColor3=WHT;StartBtn.TextColor3=DEEP
        StartBtn.Text="▶ AUTO CP";pulsing=true
    end)
end)

UIS.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.KeyCode==Enum.KeyCode.F9 then F.Visible=not F.Visible end
end)

task.spawn(function() task.wait(0.5);applyAntiLag() end)

print("Mount Zihan v5 | By Alfian | "..#CP.." CP | Scan radius "..SCAN_RADIUS.."s | F9 toggle")
