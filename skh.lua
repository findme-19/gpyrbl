--[[
  YUHU NAVIGATOR v7 — CYBER EDITION
  STREAMING-AWARE · PROXIMITY-FIRST · MULTI-PASS SCANNER
  PAUSE-ON-CLAIM · RESUME FROM NEXT CP · CP INPUT SUPPORT
]]

-- ════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ════════════════════════════════════════════════════════════

local CP = {
    Vector3.new(-312.329, 654.005, -952.673),
    Vector3.new(4356.271, 2238.856, -9533.901),
}

local KEYWORDS  = {"claim","voucher","gopay","redemption","klaim","reward"}
local KNOWN_OBJ = {
    "RedemptionPointBasepart","Gopay","GopayPoint","Primary",
    "VoucherPoint","ClaimPoint","Part",
}

local SCAN_RADII     = {50, 100, 200}
local SCAN_INTERVAL  = 0.2
local SCAN_TIMEOUT   = 5
local PROMPT_RETRIES = 3
local TP_RETRIES     = 3

-- ════════════════════════════════════════════════════════════
-- THEME  —  CYBER FUTURISTIC
-- ════════════════════════════════════════════════════════════

local T = {
    -- Deep space backgrounds
    BG_VOID    = Color3.fromRGB(3,   3,   10),
    BG_DEEP    = Color3.fromRGB(6,   6,   16),
    BG_PANEL   = Color3.fromRGB(9,   9,   22),
    BG_CARD    = Color3.fromRGB(14,  14,  34),
    BG_INPUT   = Color3.fromRGB(16,  16,  38),
    BG_HOVER   = Color3.fromRGB(22,  22,  50),

    -- Borders
    BORDER     = Color3.fromRGB(24,  28,  62),
    BORDER_HI  = Color3.fromRGB(44,  52,  108),
    BORDER_GLO = Color3.fromRGB(0,   200, 240),

    -- Neon palette
    NEON_CYAN  = Color3.fromRGB(0,   240, 255),
    NEON_BLUE  = Color3.fromRGB(41,  130, 255),
    NEON_PURP  = Color3.fromRGB(155, 70,  255),
    NEON_GREEN = Color3.fromRGB(0,   255, 140),
    NEON_RED   = Color3.fromRGB(255, 38,  68),
    NEON_YELL  = Color3.fromRGB(255, 210, 0),

    -- Text
    TXT_PRI    = Color3.fromRGB(210, 225, 248),
    TXT_MID    = Color3.fromRGB(110, 125, 160),
    TXT_DIM    = Color3.fromRGB(52,  58,  96),
    TXT_CODE   = Color3.fromRGB(0,   210, 230),
}

-- ════════════════════════════════════════════════════════════
-- SERVICES
-- ════════════════════════════════════════════════════════════

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player       = Players.LocalPlayer

-- ════════════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════════════

local state = {
    running   = false,
    stopped   = false,
    currentCP = 0,
    pausedAt  = 0,
    guiScale  = 1.0,
}

-- ════════════════════════════════════════════════════════════
-- CLEANUP OLD GUI
-- ════════════════════════════════════════════════════════════

pcall(function()
    for _, g in ipairs(player.PlayerGui:GetChildren()) do
        if g.Name == "ZihanNavigator" then g:Destroy() end
    end
end)

-- ════════════════════════════════════════════════════════════
-- UTILITY
-- ════════════════════════════════════════════════════════════

local function hasKeyword(str)
    if type(str) ~= "string" or str == "" then return false end
    local lo = str:lower()
    for _, kw in ipairs(KEYWORDS) do
        if lo:find(kw, 1, true) then return true end
    end
    return false
end

local function isKnownObj(name)
    if type(name) ~= "string" or name == "" then return false end
    local lo = name:lower()
    for _, n in ipairs(KNOWN_OBJ) do
        if lo == n:lower() then return true end
    end
    return lo:find("redemption",1,true) or lo:find("gopay",1,true)
        or lo:find("voucher",1,true)    or lo:find("claim",1,true)
end

local function getObjPos(obj)
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local pp = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        return pp and pp.Position or nil
    end
    return nil
end

local function safeFire(prompt)
    return pcall(function() fireproximityprompt(prompt) end)
end

local function notify(title, text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",
            {Title=title, Text=text, Duration=4})
    end)
end

-- ════════════════════════════════════════════════════════════
-- ANTI-LAG
-- ════════════════════════════════════════════════════════════

local AntiLag = {}

function AntiLag.apply()
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level03 end)
    pcall(function() settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level02 end)
    pcall(function() workspace.GlobalShadows = false end)
    pcall(function()
        local L = game:GetService("Lighting")
        L.GlobalShadows = false; L.Brightness = 1.5
        L.EnvironmentDiffuseScale = 0.3; L.EnvironmentSpecularScale = 0.2
        for _, v in ipairs(L:GetChildren()) do
            if v:IsA("BlurEffect") or v:IsA("SunRaysEffect")
                or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then
                v.Enabled = false
            end
        end
    end)
    pcall(function()
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Fire")
                or v:IsA("Smoke") or v:IsA("Sparkles") then
                v.Enabled = false
            end
        end
    end)
end

function AntiLag.restore()
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
    pcall(function() settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Automatic end)
    pcall(function() workspace.GlobalShadows = true end)
end

-- ════════════════════════════════════════════════════════════
-- SCANNER  (unified pass logic — no duplication)
-- ════════════════════════════════════════════════════════════

local Scanner = {}

function Scanner.acquireParts(center, radius)
    local ok, parts = pcall(function()
        return workspace:GetPartBoundsInRadius(center, radius)
    end)
    if ok and parts and #parts > 0 then return parts end
    local results = {}
    pcall(function()
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and (v.Position-center).Magnitude <= radius then
                table.insert(results, v)
            end
        end
    end)
    return results
end

local function makeResult(prompt, pos, label, dist, passNum)
    return {prompt=prompt, pos=pos, label=label, dist=dist, pass=passNum}
end

-- mode="first" → return on first hit · mode="all" → collect all
local function runPasses(parts, center, radius, seen, mode)
    local all = {}
    local function emit(r)
        if mode == "first" then return r end
        table.insert(all, r)
    end

    -- Pass 1: ProximityPrompt keyword/name match
    for _, part in ipairs(parts) do
        local candidates = {part}
        for _, ch in ipairs(part:GetChildren()) do
            if ch:IsA("ProximityPrompt") then table.insert(candidates, ch) end
        end
        for _, pr in ipairs(candidates) do
            if pr:IsA("ProximityPrompt") and not seen[pr] then
                local at = pr.ActionText or ""
                local ot = pr.ObjectText or ""
                local pn = pr.Parent and pr.Parent.Name or ""
                if hasKeyword(at) or hasKeyword(ot) or hasKeyword(pn) or isKnownObj(pn) then
                    local pos = getObjPos(pr.Parent)
                    if pos and (pos-center).Magnitude <= radius then
                        seen[pr] = true
                        local r = makeResult(pr, pos, at~="" and at or pn,
                            (pos-center).Magnitude, 1)
                        local ret = emit(r); if ret then return ret end
                    end
                end
            end
        end
    end

    -- Pass 2: object name matching
    for _, part in ipairs(parts) do
        local par = part.Parent
        if par and isKnownObj(par.Name) then
            local pos = getObjPos(par)
            if pos and (pos-center).Magnitude <= radius then
                for _, ch in ipairs(par:GetDescendants()) do
                    if ch:IsA("ProximityPrompt") and not seen[ch] then
                        seen[ch] = true
                        local r = makeResult(ch, pos, par.Name, (pos-center).Magnitude, 2)
                        local ret = emit(r); if ret then return ret end
                    end
                end
            end
        end
        if isKnownObj(part.Name) then
            local pos = part.Position
            if (pos-center).Magnitude <= radius then
                for _, ch in ipairs(part:GetChildren()) do
                    if ch:IsA("ProximityPrompt") and not seen[ch] then
                        seen[ch] = true
                        local r = makeResult(ch, pos, part.Name, (pos-center).Magnitude, 2)
                        local ret = emit(r); if ret then return ret end
                    end
                end
            end
        end
    end

    -- Pass 3: GUI text scan
    for _, part in ipairs(parts) do
        local par = part.Parent
        if not par then continue end
        local pos = getObjPos(par)
        if not pos or (pos-center).Magnitude > radius then continue end
        for _, gui in ipairs(par:GetChildren()) do
            if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
                for _, tc in ipairs(gui:GetDescendants()) do
                    if (tc:IsA("TextLabel") or tc:IsA("TextButton")) and hasKeyword(tc.Text) then
                        for _, dc in ipairs(par:GetDescendants()) do
                            if dc:IsA("ProximityPrompt") and not seen[dc] then
                                seen[dc] = true
                                local r = makeResult(dc, pos, tc.Text, (pos-center).Magnitude, 3)
                                local ret = emit(r); if ret then return ret end
                            end
                        end
                        break
                    end
                end
            end
        end
    end

    return mode == "first" and nil or all
end

function Scanner.scanRadius(center, radius)
    local parts = Scanner.acquireParts(center, radius)
    if not parts or #parts == 0 then return nil end
    return runPasses(parts, center, radius, {}, "first")
end

function Scanner.scanAll(center)
    for _, radius in ipairs(SCAN_RADII) do
        local r = Scanner.scanRadius(center, radius)
        if r then return r end
    end
    return nil
end

function Scanner.scanAllTargets(center)
    local all, seen = {}, {}
    for _, radius in ipairs(SCAN_RADII) do
        local parts = Scanner.acquireParts(center, radius)
        if parts and #parts > 0 then
            local res = runPasses(parts, center, radius, seen, "all")
            for _, r in ipairs(res) do table.insert(all, r) end
        end
    end
    table.sort(all, function(a,b) return a.dist < b.dist end)
    return all
end

function Scanner.adaptiveScanMulti(center, onTick)
    local elapsed = 0
    while elapsed < SCAN_TIMEOUT do
        if state.stopped then return {} end
        if onTick then onTick(elapsed) end
        local results = Scanner.scanAllTargets(center)
        if #results > 0 then return results end
        task.wait(SCAN_INTERVAL)
        elapsed = elapsed + SCAN_INTERVAL
    end
    return {}
end

-- ════════════════════════════════════════════════════════════
-- NAVIGATOR
-- ════════════════════════════════════════════════════════════

local Nav = {}

function Nav.getChar()
    local char = player.Character
    if not char then char = player.CharacterAdded:Wait(10) end
    if not char then return nil,nil,nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then hrp = char:WaitForChild("HumanoidRootPart",5) end
    if not hrp then return char,nil,nil end
    return char, hrp, char:FindFirstChildOfClass("Humanoid")
end

function Nav.tpTo(pos)
    local _, hrp = Nav.getChar()
    if not hrp then return false end
    for _ = 1, TP_RETRIES do
        if state.stopped then return false end
        hrp.CFrame = CFrame.new(pos + Vector3.new(0,5,0))
        task.wait(0.2)
        if (hrp.Position-pos).Magnitude < 25 then return true end
        hrp.CFrame = CFrame.new(pos + Vector3.new(0,3,0))
        task.wait(0.15)
    end
    return (hrp.Position-pos).Magnitude < 50
end

function Nav.firePrompts(results, onAttempt)
    if not results or #results == 0 then return 0 end
    local _, hrp, hum = Nav.getChar()
    if not hrp then return 0 end
    if hum then hum.WalkSpeed = 16 end
    local fired = 0
    for _, r in ipairs(results) do
        if state.stopped then break end
        local dir = hrp.Position - r.pos
        local offset = dir.Magnitude > 0.1 and dir.Unit*7 or Vector3.new(0,0,7)
        hrp.CFrame = CFrame.new(r.pos + offset + Vector3.new(0,3,0))
        task.wait(0.15)
        for retry = 1, PROMPT_RETRIES do
            if state.stopped then break end
            if onAttempt then onAttempt(r,retry) end
            if safeFire(r.prompt) then fired = fired+1; break end
            task.wait(0.08)
        end
        if fired > 0 then task.wait(0.1) end
    end
    return fired
end

function Nav.processCP(idx, setStatus, setProgress)
    if not CP[idx] then return false,false end
    local pt = CP[idx]
    state.currentCP = idx
    setStatus("CP "..idx.."/"..#CP.." - TELEPORT", "wait")
    setProgress(idx, #CP)
    if not Nav.tpTo(pt) then
        setStatus("CP "..idx.." - TP FAILED", "err"); return false,false
    end
    local results = Scanner.adaptiveScanMulti(pt, function(elapsed)
        setStatus("CP "..idx.." - SCAN "..string.format("%.1f",elapsed).."s", "wait")
    end)
    if state.stopped then return false,false end
    if #results == 0 then
        setStatus("CP "..idx.." - NO VOUCHER", "idle"); return true,false
    end
    setStatus(#results.." TARGET AT CP"..idx, "found")
    local fired = Nav.firePrompts(results, function(r,retry)
        setStatus("CP "..idx.." - FIRE ["..retry.."/"..PROMPT_RETRIES.."]", "found")
    end)
    if fired > 0 then
        setStatus("CLAIMED AT CP"..idx.." - PAUSED", "done")
        notify("Yuhu Navigator", "Claimed voucher at CP"..idx)
        return true,true
    end
    setStatus("CP "..idx.." - FIRE FAILED", "err"); return true,false
end

-- runAuto: visit each CP. Stop (pause) when voucher found. Resume from next CP next run.
function Nav.runAuto(fromCP, setStatus, setProgress, onCP, onDone)
    if state.running then return end
    state.running = true; state.stopped = false
    task.spawn(function()
        local _,_,hum = Nav.getChar()
        if not hum then
            setStatus("ERROR - NO CHARACTER","err")
            state.running = false
            if onDone then onDone(false,0) end; return
        end
        hum.WalkSpeed = 0
        local from = math.clamp(fromCP or 1, 1, #CP)
        for i = from, #CP do
            if state.stopped then
                setStatus("STOPPED AT CP"..i,"err")
                hum.WalkSpeed = 16; state.running = false
                if onDone then onDone(false, state.currentCP) end; return
            end
            if onCP then onCP(i) end
            local ok, found = Nav.processCP(i, setStatus, setProgress)
            if not ok then
                hum.WalkSpeed = 16; state.running = false
                if onDone then onDone(false,i) end; return
            end
            if found then
                state.pausedAt = i
                hum.WalkSpeed = 16; state.running = false
                if onDone then onDone(true,i) end; return
            end
        end
        state.pausedAt = 0
        setStatus("ALL "..#CP.." CP SCANNED - DONE","done")
        notify("Yuhu Navigator","All checkpoints scanned.")
        hum.WalkSpeed = 16; state.running = false
        if onDone then onDone(false,0) end
    end)
end

function Nav.runManual(idx, setStatus, setProgress, onCP)
    if state.running then return end
    state.running = true; state.stopped = false
    task.spawn(function()
        local _,_,hum = Nav.getChar()
        if not hum then
            setStatus("ERROR - NO CHARACTER","err")
            state.running = false; return
        end
        hum.WalkSpeed = 0
        if onCP then onCP(idx) end
        local ok, found = Nav.processCP(idx, setStatus, setProgress)
        if ok and not found then setStatus("CP "..idx.." - NO VOUCHER","idle") end
        hum.WalkSpeed = 16; state.running = false
    end)
end

-- ════════════════════════════════════════════════════════════
-- GUI  —  CYBER FUTURISTIC
-- ════════════════════════════════════════════════════════════

local GUI = {}
local R   = {}

-- ── Element factory ──────────────────────────────────────────
local function el(class, props)
    local inst = Instance.new(class)
    for k,v in pairs(props) do
        if k~="Corner" and k~="Stroke" and k~="Children" then
            pcall(function() inst[k]=v end)
        end
    end
    if props.Corner then
        local c = Instance.new("UICorner")
        c.CornerRadius = type(props.Corner)=="UDim"
            and props.Corner or UDim.new(0,props.Corner)
        c.Parent = inst
    end
    if props.Stroke then
        local s = Instance.new("UIStroke")
        if type(props.Stroke)=="table" then
            for k,v in pairs(props.Stroke) do pcall(function() s[k]=v end) end
        else s.Color = props.Stroke end
        s.Parent = inst
    end
    if props.Children then
        for _, ch in ipairs(props.Children) do ch.Parent=inst end
    end
    return inst
end

local function getStroke(inst)
    return inst and inst:FindFirstChildOfClass("UIStroke")
end

-- ── Cyber: corner brackets (L-shapes at each corner, inset safe for UICorner) ──
local function addBrackets(parent, color, zidx, len, thick, inset)
    len=len or 14; thick=thick or 2; inset=inset or 7; zidx=zidx or 22
    local function f(px,py,w,h)
        el("Frame",{
            Size=UDim2.new(0,w,0,h), Position=UDim2.new(px[1],px[2],py[1],py[2]),
            BackgroundColor3=color, ZIndex=zidx,
        }).Parent=parent
    end
    -- top-left
    f({0,inset},     {0,inset},      len, thick)
    f({0,inset},     {0,inset},      thick, len)
    -- top-right
    f({1,-inset-len},{0,inset},      len, thick)
    f({1,-inset-thick},{0,inset},    thick, len)
    -- bottom-left
    f({0,inset},     {1,-inset-thick},len, thick)
    f({0,inset},     {1,-inset-len}, thick, len)
    -- bottom-right
    f({1,-inset-len},{1,-inset-thick},len,thick)
    f({1,-inset-thick},{1,-inset-len},thick,len)
end

-- ── Cyber: scanline texture (thin horizontal lines across a frame) ────────────
local function addScanlines(parent, count, color, transparency, zidx)
    color=color or T.NEON_CYAN; transparency=transparency or 0.94; zidx=zidx or 12
    for i=0, count-1 do
        el("Frame",{
            Size=UDim2.new(1,0,0,1),
            Position=UDim2.new(0,0,i/(count),0),
            BackgroundColor3=color, BackgroundTransparency=transparency, ZIndex=zidx,
        }).Parent=parent
    end
end

-- ── Cyber: section header "[ > ] LABEL ─────────────────────" ────────────────
local function sectionHdr(parent, label, y, color)
    color = color or T.NEON_CYAN
    -- indicator dot
    el("Frame",{
        Size=UDim2.new(0,4,0,4), Position=UDim2.new(0,10,0,y+5),
        BackgroundColor3=color, ZIndex=13, Corner=UDim.new(1,0),
    }).Parent=parent
    -- glow behind dot
    el("Frame",{
        Size=UDim2.new(0,10,0,10), Position=UDim2.new(0,7,0,y+2),
        BackgroundColor3=color, BackgroundTransparency=0.8, ZIndex=12, Corner=UDim.new(1,0),
    }).Parent=parent
    -- label
    el("TextLabel",{
        Size=UDim2.new(0,110,0,12), Position=UDim2.new(0,18,0,y),
        BackgroundTransparency=1, Text=label,
        TextColor3=color, Font=Enum.Font.GothamBold, TextSize=7,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13,
    }).Parent=parent
    -- right line
    el("Frame",{
        Size=UDim2.new(1,-136,0,1), Position=UDim2.new(0,132,0,y+6),
        BackgroundColor3=color, BackgroundTransparency=0.7, ZIndex=12,
    }).Parent=parent
end

-- ── Status color map ──────────────────────────────────────────────────────────
local STATUS_COL = {
    done  = T.NEON_GREEN,
    err   = T.NEON_RED,
    wait  = T.NEON_YELL,
    found = T.NEON_CYAN,
    idle  = T.TXT_MID,
}

function GUI.setStatus(msg, typ)
    if not R.svTxt then return end
    local c = STATUS_COL[typ] or T.TXT_PRI
    R.svTxt.Text = msg; R.svTxt.TextColor3 = c
    if R.svDot  then R.svDot.BackgroundColor3  = c end
    if R.svGlow then R.svGlow.BackgroundColor3 = c end
    if R.svLine then R.svLine.BackgroundColor3 = c end
end

function GUI.setProgress(cur, total)
    if not R.pFill then return end
    local pct = math.clamp(cur/math.max(total,1), 0, 1)
    TweenService:Create(R.pFill, TweenInfo.new(0.25),
        {Size=UDim2.new(pct,0,1,0)}):Play()
    TweenService:Create(R.pGlow, TweenInfo.new(0.25),
        {Size=UDim2.new(pct,0,1,6)}):Play()
    if R.pTxt then
        R.pTxt.Text = string.format("%02d / %02d", cur, total)
        R.pTxt.TextColor3 = pct>=1 and T.NEON_GREEN
            or pct>0.5 and T.NEON_YELL or T.TXT_DIM
    end
end

function GUI.refreshCPGrid()
    if not R.cpScroll then return end
    for _, btn in ipairs(R.cpBtns or {}) do
        pcall(function() btn:Destroy() end)
    end
    R.cpBtns = {}
    for i = 1, #CP do
        local btn = el("TextButton",{
            Size=UDim2.new(0,38,0,26),
            BackgroundColor3=T.BG_INPUT,
            Text=string.format("%02d",i), TextColor3=T.TXT_DIM,
            Font=Enum.Font.Code, TextSize=9,
            AutoButtonColor=false, ZIndex=13,
            Corner=3, Stroke={Color=T.BORDER, Thickness=1},
        })
        btn.LayoutOrder=i; btn.Parent=R.cpScroll
        table.insert(R.cpBtns, btn)
        local ci=i
        btn.MouseButton1Click:Connect(function()
            if state.running then return end
            Nav.runManual(ci, GUI.setStatus, GUI.setProgress, GUI.highlightCP)
        end)
        btn.MouseEnter:Connect(function()
            if state.currentCP~=ci then
                btn.BackgroundColor3=T.BG_HOVER
                local s=getStroke(btn); if s then s.Color=T.BORDER_HI end
            end
        end)
        btn.MouseLeave:Connect(function()
            if state.currentCP~=ci then
                btn.BackgroundColor3=T.BG_INPUT
                local s=getStroke(btn); if s then s.Color=T.BORDER end
            end
        end)
    end
    if R.pTxt    then R.pTxt.Text    = string.format("00 / %02d",#CP) end
    if R.cpCount then R.cpCount.Text = string.format("[%03d CP LOADED]",#CP) end
end

function GUI.highlightCP(idx)
    for i,btn in ipairs(R.cpBtns or {}) do
        local active = i==idx
        btn.BackgroundColor3 = active and T.BG_CARD   or T.BG_INPUT
        btn.TextColor3       = active and T.NEON_CYAN or T.TXT_DIM
        local s = getStroke(btn)
        if s then
            s.Color = active and T.NEON_CYAN or T.BORDER
            s.Thickness = active and 1.5 or 1
        end
    end
    if R.cpBtns[idx] and R.cpScroll then
        task.defer(function()
            local cellW  = 38+3
            local padLR  = 8
            local cols   = math.max(math.floor((R.cpScroll.AbsoluteSize.X-padLR)/cellW),1)
            local cellH  = 26+3
            local row    = math.floor((idx-1)/cols)
            R.cpScroll.CanvasPosition = Vector2.new(0, math.max(0,4+(row-1)*cellH))
        end)
    end
end

-- Pinch zoom (AbsoluteSize center — no drift)
function GUI.setupPinch(container)
    local base=container.Size
    local touches,pinching,initDist,initScale={},false,0,1
    local MIN_S,MAX_S=0.5,2.5
    local function count() local n=0; for _ in pairs(touches) do n=n+1 end; return n end
    local function list()  local t={}; for _,v in pairs(touches) do table.insert(t,v) end; return t end
    UIS.TouchStarted:Connect(function(t,g)  if not g then touches[t]=t.Position end end)
    UIS.TouchMoved:Connect(function(t,g)
        if g then return end
        touches[t]=t.Position
        local pts=list()
        if #pts==2 then
            local d=(pts[1]-pts[2]).Magnitude
            if not pinching then
                pinching=true; initDist=d; initScale=state.guiScale
            elseif initDist>10 then
                local ns=math.clamp(initScale*(d/initDist),MIN_S,MAX_S)
                state.guiScale=ns
                local cx=container.Position.X.Offset+container.AbsoluteSize.X/2
                local cy=container.Position.Y.Offset+container.AbsoluteSize.Y/2
                local nw,nh=base.X.Offset*ns, base.Y.Offset*ns
                TweenService:Create(container, TweenInfo.new(0.06),{
                    Size=UDim2.new(0,nw,0,nh),
                    Position=UDim2.new(0,cx-nw/2,0,cy-nh/2),
                }):Play()
            end
        end
    end)
    UIS.TouchEnded:Connect(function(t,g)
        if not g then touches[t]=nil end
        if count()<2 then pinching=false; initDist=0 end
    end)
    UIS.TouchCancelled:Connect(function(t,g)
        if not g then touches[t]=nil end
        if count()<2 then pinching=false; initDist=0 end
    end)
end

-- ─────────────────────────────────────────────────────────────
-- GUI.build  —  CYBER FUTURISTIC LAYOUT
-- ─────────────────────────────────────────────────────────────
function GUI.build()
    -- ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name="ZihanNavigator"; sg.ResetOnSpawn=false
    sg.DisplayOrder=9999; sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    sg.Parent=player.PlayerGui; R.sg=sg

    -- Outer container (pinch target)
    local container = Instance.new("Frame")
    container.Name="Container"
    container.Size=UDim2.new(0,282,0,440)
    container.Position=UDim2.new(0.5,-141,0.5,-220)
    container.BackgroundTransparency=1
    container.ZIndex=10; container.Parent=sg
    R.container=container

    -- ── PANEL ──────────────────────────────────────────────────
    local panel = el("Frame",{
        Size=UDim2.new(1,0,1,0),
        BackgroundColor3=T.BG_PANEL,
        Active=true, Draggable=true, ZIndex=11,
        Corner=UDim.new(0,10),
        Stroke={Color=T.BORDER, Thickness=1},
    })
    panel.Parent=container; R.panel=panel

    -- Scanline texture (cyber retro feel)
    addScanlines(panel, 18, T.NEON_CYAN, 0.95, 11)

    -- Left accent bar
    el("Frame",{
        Size=UDim2.new(0,2,0.65,0), Position=UDim2.new(0,0,0.175,0),
        BackgroundColor3=T.NEON_CYAN, ZIndex=16, Corner=UDim.new(0,1),
    }).Parent=panel
    el("Frame",{   -- glow
        Size=UDim2.new(0,14,0.65,0), Position=UDim2.new(0,-6,0.175,0),
        BackgroundColor3=T.NEON_CYAN, BackgroundTransparency=0.87,
        ZIndex=15, Corner=UDim.new(0,7),
    }).Parent=panel

    -- Top neon accent bar
    el("Frame",{
        Size=UDim2.new(0.6,0,0,2), Position=UDim2.new(0.2,0,0,0),
        BackgroundColor3=T.NEON_CYAN, ZIndex=16, Corner=UDim.new(0,1),
    }).Parent=panel
    el("Frame",{   -- glow
        Size=UDim2.new(0.6,14,0,10), Position=UDim2.new(0.2,-7,0,-4),
        BackgroundColor3=T.NEON_CYAN, BackgroundTransparency=0.84,
        ZIndex=15, Corner=UDim.new(0,5),
    }).Parent=panel

    -- Corner bracket decorators (iconic sci-fi UI element)
    addBrackets(panel, T.NEON_CYAN, 20, 14, 2, 6)

    -- ── TITLE BAR ──────────────────────────────────────────────
    local tb = el("Frame",{
        Size=UDim2.new(1,0,0,40), Position=UDim2.new(0,0,0,2),
        BackgroundTransparency=1, ZIndex=12,
    })
    tb.Parent=panel

    -- Icon pulse (small colored square)
    R.titleDot = el("Frame",{
        Size=UDim2.new(0,7,0,7), Position=UDim2.new(0,14,0.5,-4),
        BackgroundColor3=T.NEON_CYAN, ZIndex=14, Corner=UDim.new(0,1),
    })
    R.titleDot.Parent=tb
    el("Frame",{  -- glow
        Size=UDim2.new(0,16,0,16), Position=UDim2.new(0,9,0.5,-8),
        BackgroundColor3=T.NEON_CYAN, BackgroundTransparency=0.82,
        ZIndex=13, Corner=UDim.new(1,0),
    }).Parent=tb

    el("TextLabel",{
        Size=UDim2.new(0,140,0,14), Position=UDim2.new(0,26,0.5,-13),
        BackgroundTransparency=1, Text="YUHU NAVIGATOR",
        TextColor3=T.TXT_PRI, Font=Enum.Font.GothamBold,
        TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=14,
    }).Parent=tb
    el("TextLabel",{
        Size=UDim2.new(0,140,0,10), Position=UDim2.new(0,27,0.5,3),
        BackgroundTransparency=1, Text="CYBER EDITION  //  v7",
        TextColor3=T.TXT_DIM, Font=Enum.Font.Code,
        TextSize=7, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=14,
    }).Parent=tb

    -- Live CP count label
    R.cpCount = el("TextLabel",{
        Size=UDim2.new(0,80,0,12), Position=UDim2.new(1,-118,0.5,-12),
        BackgroundTransparency=1,
        Text=string.format("[%03d CP LOADED]",#CP),
        TextColor3=T.NEON_CYAN, Font=Enum.Font.Code,
        TextSize=7, TextXAlignment=Enum.TextXAlignment.Right, ZIndex=14,
    })
    R.cpCount.Parent=tb

    -- Close button — plain ASCII "X", large tap target for mobile
    local xb = el("TextButton",{
        Size=UDim2.new(0,34,0,34), Position=UDim2.new(1,-40,0.5,-17),
        BackgroundColor3=T.BG_INPUT,
        Text="X", TextColor3=T.TXT_MID,
        Font=Enum.Font.GothamBold, TextSize=15,
        AutoButtonColor=false, ZIndex=15,
        Corner=6, Stroke={Color=T.BORDER, Thickness=1},
    })
    xb.Parent=tb
    xb.MouseEnter:Connect(function()
        xb.TextColor3=T.NEON_RED
        TweenService:Create(xb,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(28,8,14)}):Play()
        local s=getStroke(xb); if s then s.Color=T.NEON_RED end
    end)
    xb.MouseLeave:Connect(function()
        xb.TextColor3=T.TXT_MID
        TweenService:Create(xb,TweenInfo.new(0.1),{BackgroundColor3=T.BG_INPUT}):Play()
        local s=getStroke(xb); if s then s.Color=T.BORDER end
    end)
    xb.MouseButton1Click:Connect(function()
        TweenService:Create(panel,TweenInfo.new(0.15),
            {Size=UDim2.new(0,0,0,0),BackgroundTransparency=1}):Play()
        task.delay(0.16,function() sg:Destroy() end)
    end)

    -- Separator below title
    el("Frame",{
        Size=UDim2.new(1,-20,0,1), Position=UDim2.new(0,10,0,43),
        BackgroundColor3=T.BORDER, ZIndex=12,
    }).Parent=panel
    el("Frame",{  -- neon glow on separator
        Size=UDim2.new(0.4,0,0,1), Position=UDim2.new(0.1,0,0,43),
        BackgroundColor3=T.NEON_CYAN, BackgroundTransparency=0.7, ZIndex=13,
    }).Parent=panel

    -- ── STATUS BAR ─────────────────────────────────────────────
    sectionHdr(panel, "SYSTEM STATUS", 48, T.NEON_CYAN)

    local sf = el("Frame",{
        Size=UDim2.new(1,-20,0,26), Position=UDim2.new(0,10,0,62),
        BackgroundColor3=T.BG_CARD, ZIndex=12,
        Corner=4, Stroke={Color=T.BORDER, Thickness=1},
    })
    sf.Parent=panel

    R.svLine = el("Frame",{   -- left colored accent on status
        Size=UDim2.new(0,3,0.7,0), Position=UDim2.new(0,0,0.15,0),
        BackgroundColor3=T.NEON_GREEN, ZIndex=13, Corner=UDim.new(0,1),
    })
    R.svLine.Parent=sf

    R.svDot = el("Frame",{
        Size=UDim2.new(0,7,0,7), Position=UDim2.new(0,10,0.5,-3.5),
        BackgroundColor3=T.NEON_GREEN, ZIndex=14, Corner=UDim.new(1,0),
    })
    R.svDot.Parent=sf

    R.svGlow = el("Frame",{
        Size=UDim2.new(0,18,0,18), Position=UDim2.new(0,5,0.5,-9),
        BackgroundColor3=T.NEON_GREEN, BackgroundTransparency=0.8,
        ZIndex=13, Corner=UDim.new(1,0),
    })
    R.svGlow.Parent=sf

    R.svTxt = el("TextLabel",{
        Size=UDim2.new(1,-30,1,0), Position=UDim2.new(0,24,0,0),
        BackgroundTransparency=1, Text="SYSTEM READY",
        TextColor3=T.NEON_GREEN, Font=Enum.Font.GothamBold,
        TextSize=9, TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd, ZIndex=14,
    })
    R.svTxt.Parent=sf

    -- Animate status dot (blink)
    task.spawn(function()
        while sg and sg.Parent do
            if R.svDot then
                TweenService:Create(R.svDot, TweenInfo.new(0.7,Enum.EasingStyle.Sine),
                    {BackgroundTransparency=0.55}):Play()
                task.wait(0.7)
                TweenService:Create(R.svDot, TweenInfo.new(0.7,Enum.EasingStyle.Sine),
                    {BackgroundTransparency=0}):Play()
                task.wait(0.7)
            else task.wait(0.5) end
        end
    end)

    -- ── PROGRESS BAR ───────────────────────────────────────────
    local pBg = el("Frame",{
        Size=UDim2.new(1,-20,0,16), Position=UDim2.new(0,10,0,92),
        BackgroundColor3=T.BG_VOID, ZIndex=12,
        Corner=UDim.new(0,8), Stroke={Color=T.BORDER, Thickness=1},
    })
    pBg.Parent=panel

    R.pGlow = el("Frame",{
        Size=UDim2.new(0,0,1,6), Position=UDim2.new(0,0,0,-3),
        BackgroundColor3=T.NEON_CYAN, BackgroundTransparency=0.65,
        ZIndex=12, Corner=UDim.new(0,8),
    })
    R.pGlow.Parent=pBg

    R.pFill = el("Frame",{
        Size=UDim2.new(0,0,1,0),
        BackgroundColor3=T.NEON_CYAN, ZIndex=13, Corner=UDim.new(0,8),
    })
    R.pFill.Parent=pBg

    -- Tick marks on progress bar
    for i=1,9 do
        el("Frame",{
            Size=UDim2.new(0,1,0.5,0), Position=UDim2.new(i*0.1,0,0.25,0),
            BackgroundColor3=T.BG_DEEP, BackgroundTransparency=0.3, ZIndex=14,
        }).Parent=pBg
    end

    R.pTxt = el("TextLabel",{
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        Text=string.format("00 / %02d",#CP), TextColor3=T.TXT_DIM,
        Font=Enum.Font.Code, TextSize=8, ZIndex=15,
    })
    R.pTxt.Parent=pBg

    -- Scan info
    el("TextLabel",{
        Size=UDim2.new(1,-22,0,12), Position=UDim2.new(0,12,0,112),
        BackgroundTransparency=1,
        Text="R: 50 > 100 > 200    TIMEOUT: 5.0s    MODE: ADAPTIVE",
        TextColor3=T.TXT_DIM, Font=Enum.Font.Code, TextSize=7,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=12,
    }).Parent=panel

    -- ── CP GRID ────────────────────────────────────────────────
    sectionHdr(panel, "CHECKPOINTS", 127, T.NEON_PURP)

    R.cpScroll = el("ScrollingFrame",{
        Size=UDim2.new(1,-20,0,140), Position=UDim2.new(0,10,0,141),
        BackgroundColor3=T.BG_VOID,
        ScrollBarThickness=2, ScrollBarImageColor3=T.BORDER_HI,
        CanvasSize=UDim2.new(0,0,0,0),
        ZIndex=12, Corner=5, Stroke={Color=T.BORDER, Thickness=1},
    })
    R.cpScroll.Parent=panel

    local grid = Instance.new("UIGridLayout")
    grid.CellSize=UDim2.new(0,38,0,26); grid.CellPadding=UDim2.new(0,3,0,3)
    grid.SortOrder=Enum.SortOrder.LayoutOrder; grid.Parent=R.cpScroll

    do
        local pad=Instance.new("UIPadding")
        pad.PaddingLeft=UDim.new(0,4); pad.PaddingRight=UDim.new(0,4)
        pad.PaddingTop=UDim.new(0,4);  pad.PaddingBottom=UDim.new(0,4)
        pad.Parent=R.cpScroll
    end

    grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        R.cpScroll.CanvasSize = UDim2.new(0,0,0, grid.AbsoluteContentSize.Y+8)
    end)

    -- ── CP INPUT ───────────────────────────────────────────────
    local IY = 287
    sectionHdr(panel, "ADD CHECKPOINT", IY, T.NEON_GREEN)

    local inputRow = el("Frame",{
        Size=UDim2.new(1,-20,0,28), Position=UDim2.new(0,10,0,IY+14),
        BackgroundTransparency=1, ZIndex=12,
    })
    inputRow.Parent=panel

    local function makeInput(placeholder, xpos)
        local tb = el("TextBox",{
            Size=UDim2.new(0,76,1,0), Position=UDim2.new(0,xpos,0,0),
            BackgroundColor3=T.BG_INPUT,
            Text="", PlaceholderText=placeholder,
            TextColor3=T.TXT_CODE, PlaceholderColor3=T.TXT_DIM,
            Font=Enum.Font.Code, TextSize=9,
            ClearTextOnFocus=false, ZIndex=13,
            Corner=4, Stroke={Color=T.BORDER, Thickness=1},
        })
        -- Focus glow effect
        tb.Focused:Connect(function()
            TweenService:Create(tb,TweenInfo.new(0.1),{BackgroundColor3=T.BG_CARD}):Play()
            local s=getStroke(tb); if s then s.Color=T.NEON_CYAN; s.Thickness=1.5 end
        end)
        tb.FocusLost:Connect(function()
            TweenService:Create(tb,TweenInfo.new(0.1),{BackgroundColor3=T.BG_INPUT}):Play()
            local s=getStroke(tb); if s then s.Color=T.BORDER; s.Thickness=1 end
        end)
        return tb
    end

    local xIn = makeInput("X", 0); xIn.Parent=inputRow
    local yIn = makeInput("Y",81); yIn.Parent=inputRow
    local zIn = makeInput("Z",162); zIn.Parent=inputRow

    -- ADD / DEL buttons
    local btnRow = el("Frame",{
        Size=UDim2.new(1,-20,0,24), Position=UDim2.new(0,10,0,IY+44),
        BackgroundTransparency=1, ZIndex=12,
    })
    btnRow.Parent=panel

    local addCpBtn = el("TextButton",{
        Size=UDim2.new(0,119,1,0), Position=UDim2.new(0,0,0,0),
        BackgroundColor3=Color3.fromRGB(6,20,10),
        Text="+ ADD CP", TextColor3=T.NEON_GREEN,
        Font=Enum.Font.GothamBold, TextSize=8,
        AutoButtonColor=false, ZIndex=13,
        Corner=5, Stroke={Color=T.NEON_GREEN, Transparency=0.55, Thickness=1},
    })
    addCpBtn.Parent=btnRow

    local delCpBtn = el("TextButton",{
        Size=UDim2.new(0,119,1,0), Position=UDim2.new(0,123,0,0),
        BackgroundColor3=Color3.fromRGB(20,6,10),
        Text="- DEL LAST", TextColor3=T.NEON_RED,
        Font=Enum.Font.GothamBold, TextSize=8,
        AutoButtonColor=false, ZIndex=13,
        Corner=5, Stroke={Color=T.NEON_RED, Transparency=0.55, Thickness=1},
    })
    delCpBtn.Parent=btnRow

    -- Hover effects on input buttons
    for _, btn in ipairs({addCpBtn, delCpBtn}) do
        local accentCol = btn.TextColor3
        btn.MouseEnter:Connect(function()
            local s=getStroke(btn); if s then s.Transparency=0.2 end
        end)
        btn.MouseLeave:Connect(function()
            local s=getStroke(btn); if s then s.Transparency=0.55 end
        end)
    end

    R.cpCount = el("TextLabel",{
        Size=UDim2.new(1,-20,0,12), Position=UDim2.new(0,10,0,IY+70),
        BackgroundTransparency=1,
        Text=string.format("[%03d CP LOADED]",#CP),
        TextColor3=T.TXT_DIM, Font=Enum.Font.Code, TextSize=7,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=12,
    })
    R.cpCount.Parent=panel

    addCpBtn.MouseButton1Click:Connect(function()
        local x=tonumber(xIn.Text); local y=tonumber(yIn.Text); local z=tonumber(zIn.Text)
        if x and y and z then
            table.insert(CP, Vector3.new(x,y,z))
            xIn.Text=""; yIn.Text=""; zIn.Text=""
            GUI.refreshCPGrid()
            GUI.setStatus("CP"..#CP.." ADDED", "done")
        else
            GUI.setStatus("INVALID COORDS — 3 numbers required", "err")
        end
    end)

    delCpBtn.MouseButton1Click:Connect(function()
        if #CP>0 then
            local removed=#CP; table.remove(CP)
            if state.pausedAt >= removed then state.pausedAt=0 end
            GUI.refreshCPGrid()
            GUI.setStatus("CP"..removed.." REMOVED","err")
        else
            GUI.setStatus("NO CP TO REMOVE","idle")
        end
    end)

    -- ── SEPARATOR ──────────────────────────────────────────────
    local SEP_Y = IY + 84
    el("Frame",{
        Size=UDim2.new(1,-20,0,1), Position=UDim2.new(0,10,0,SEP_Y),
        BackgroundColor3=T.BORDER, ZIndex=12,
    }).Parent=panel
    el("Frame",{  -- partial neon glow
        Size=UDim2.new(0.35,0,0,1), Position=UDim2.new(0.65,0,0,SEP_Y),
        BackgroundColor3=T.NEON_GREEN, BackgroundTransparency=0.65, ZIndex=13,
    }).Parent=panel

    -- ── ANTI-LAG ───────────────────────────────────────────────
    local alRow = el("Frame",{
        Size=UDim2.new(1,-20,0,24), Position=UDim2.new(0,10,0,SEP_Y+6),
        BackgroundColor3=T.BG_CARD, ZIndex=12,
        Corner=4, Stroke={Color=T.BORDER, Thickness=1},
    })
    alRow.Parent=panel

    el("TextLabel",{
        Size=UDim2.new(0.6,0,1,0), Position=UDim2.new(0,10,0,0),
        BackgroundTransparency=1, Text="// ANTI-LAG SYSTEM",
        TextColor3=T.TXT_MID, Font=Enum.Font.Code, TextSize=8,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13,
    }).Parent=alRow

    local alBtn = el("TextButton",{
        Size=UDim2.new(0,44,0,18), Position=UDim2.new(1,-50,0.5,-9),
        BackgroundColor3=Color3.fromRGB(5,20,12),
        Text="ON", TextColor3=T.NEON_GREEN,
        Font=Enum.Font.GothamBold, TextSize=8,
        AutoButtonColor=false, ZIndex=13,
        Corner=3, Stroke={Color=T.NEON_GREEN, Transparency=0.4, Thickness=1},
    })
    alBtn.Parent=alRow

    local alOn=true
    alBtn.MouseButton1Click:Connect(function()
        alOn=not alOn
        if alOn then
            alBtn.Text="ON"; alBtn.TextColor3=T.NEON_GREEN
            alBtn.BackgroundColor3=Color3.fromRGB(5,20,12)
            local s=getStroke(alBtn); if s then s.Color=T.NEON_GREEN; s.Transparency=0.4 end
            AntiLag.apply()
        else
            alBtn.Text="OFF"; alBtn.TextColor3=T.TXT_DIM
            alBtn.BackgroundColor3=T.BG_INPUT
            local s=getStroke(alBtn); if s then s.Color=T.BORDER; s.Transparency=0 end
            AntiLag.restore()
        end
    end)

    -- ── ACTION BUTTONS ─────────────────────────────────────────
    local BY = SEP_Y + 36
    local BH = 36

    -- Helper: add a thin top-edge accent line on a button (cyber indicator)
    local function addBtnAccent(btn, color)
        el("Frame",{
            Size=UDim2.new(0.6,0,0,2), Position=UDim2.new(0.2,0,0,0),
            BackgroundColor3=color, BackgroundTransparency=0.4,
            ZIndex=14, Corner=UDim.new(0,1),
        }).Parent=btn
    end

    -- STOP
    local stopBtn = el("TextButton",{
        Size=UDim2.new(0,62,0,BH), Position=UDim2.new(0,10,0,BY),
        BackgroundColor3=Color3.fromRGB(26,6,12),
        Text="STOP", TextColor3=T.NEON_RED,
        Font=Enum.Font.GothamBold, TextSize=9,
        AutoButtonColor=false, ZIndex=13,
        Corner=6, Stroke={Color=Color3.fromRGB(80,20,30), Thickness=1},
    })
    stopBtn.Parent=panel
    addBtnAccent(stopBtn, T.NEON_RED)
    stopBtn.MouseEnter:Connect(function()
        TweenService:Create(stopBtn,TweenInfo.new(0.1),
            {BackgroundColor3=Color3.fromRGB(40,8,16)}):Play()
        local s=getStroke(stopBtn); if s then s.Color=T.NEON_RED; s.Transparency=0.3 end
    end)
    stopBtn.MouseLeave:Connect(function()
        TweenService:Create(stopBtn,TweenInfo.new(0.1),
            {BackgroundColor3=Color3.fromRGB(26,6,12)}):Play()
        local s=getStroke(stopBtn); if s then s.Color=Color3.fromRGB(80,20,30); s.Transparency=0 end
    end)
    stopBtn.MouseButton1Click:Connect(function()
        state.stopped=true
        stopBtn.Text="OK"; stopBtn.TextColor3=T.NEON_YELL
        task.delay(1.2,function()
            stopBtn.Text="STOP"; stopBtn.TextColor3=T.NEON_RED
        end)
    end)

    -- CLAIM (scan at current HRP position — no TP)
    local claimBtn = el("TextButton",{
        Size=UDim2.new(0,80,0,BH), Position=UDim2.new(0,78,0,BY),
        BackgroundColor3=Color3.fromRGB(6,14,30),
        Text="CLAIM", TextColor3=T.NEON_CYAN,
        Font=Enum.Font.GothamBold, TextSize=9,
        AutoButtonColor=false, ZIndex=13,
        Corner=6, Stroke={Color=Color3.fromRGB(18,55,95), Thickness=1},
    })
    claimBtn.Parent=panel
    addBtnAccent(claimBtn, T.NEON_CYAN)
    claimBtn.MouseEnter:Connect(function()
        TweenService:Create(claimBtn,TweenInfo.new(0.1),
            {BackgroundColor3=Color3.fromRGB(10,22,46)}):Play()
        local s=getStroke(claimBtn); if s then s.Color=T.NEON_CYAN; s.Transparency=0.3 end
    end)
    claimBtn.MouseLeave:Connect(function()
        TweenService:Create(claimBtn,TweenInfo.new(0.1),
            {BackgroundColor3=Color3.fromRGB(6,14,30)}):Play()
        local s=getStroke(claimBtn); if s then s.Color=Color3.fromRGB(18,55,95); s.Transparency=0 end
    end)
    claimBtn.MouseButton1Click:Connect(function()
        if state.running then return end
        state.running=true; state.stopped=false
        claimBtn.Text="..."; claimBtn.TextColor3=T.NEON_YELL
        task.spawn(function()
            local _,hrp,hum=Nav.getChar()
            if not hrp then
                GUI.setStatus("NO CHARACTER","err"); state.running=false
            else
                if hum then hum.WalkSpeed=0 end
                GUI.setStatus("CLAIM - SCANNING","wait")
                local pos=hrp.Position
                local results=Scanner.adaptiveScanMulti(pos, function(e)
                    GUI.setStatus(string.format("CLAIM - %.1fs",e),"wait")
                end)
                if #results>0 then
                    local fired=Nav.firePrompts(results)
                    if fired>0 then
                        GUI.setStatus("CLAIMED "..fired.." TARGET(s)","done")
                        notify("Yuhu Navigator","Claimed "..fired.." target(s)!")
                    else
                        GUI.setStatus("CLAIM - FIRE FAILED","err")
                    end
                else
                    GUI.setStatus("CLAIM - NO TARGET FOUND","idle")
                end
                if hum then hum.WalkSpeed=16 end
                state.running=false
            end
            task.wait(0.2)
            claimBtn.Text="CLAIM"; claimBtn.TextColor3=T.NEON_CYAN
        end)
    end)

    -- AUTO CP / RESUME
    local autoBtn = el("TextButton",{
        Size=UDim2.new(0,104,0,BH), Position=UDim2.new(0,164,0,BY),
        BackgroundColor3=T.BG_CARD,
        Text="AUTO CP", TextColor3=T.NEON_CYAN,
        Font=Enum.Font.GothamBold, TextSize=9,
        AutoButtonColor=false, ZIndex=13,
        Corner=6, Stroke={Color=T.NEON_CYAN, Transparency=0.3, Thickness=1},
    })
    autoBtn.Parent=panel
    addBtnAccent(autoBtn, T.NEON_CYAN)

    local function refreshAutoBtn()
        if state.pausedAt>0 and state.pausedAt<#CP then
            autoBtn.Text       = "RESUME "..string.format("%02d",state.pausedAt+1)
            autoBtn.TextColor3 = T.NEON_YELL
            local s=getStroke(autoBtn); if s then s.Color=T.NEON_YELL end
        else
            autoBtn.Text       = "AUTO CP"
            autoBtn.TextColor3 = T.NEON_CYAN
            local s=getStroke(autoBtn); if s then s.Color=T.NEON_CYAN end
        end
    end

    -- Pulsing stroke animation
    local pulsing=true
    task.spawn(function()
        while sg and sg.Parent do
            local s=getStroke(autoBtn)
            if pulsing and s then
                TweenService:Create(s,TweenInfo.new(1.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),
                    {Transparency=0.82}):Play()
                task.wait(1.2)
                if pulsing then
                    TweenService:Create(s,TweenInfo.new(1.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),
                        {Transparency=0.1}):Play()
                    task.wait(1.2)
                end
            else task.wait(0.3) end
        end
    end)

    autoBtn.MouseEnter:Connect(function()
        TweenService:Create(autoBtn,TweenInfo.new(0.1),{BackgroundColor3=T.BG_HOVER}):Play()
    end)
    autoBtn.MouseLeave:Connect(function()
        TweenService:Create(autoBtn,TweenInfo.new(0.1),{BackgroundColor3=T.BG_CARD}):Play()
    end)

    autoBtn.MouseButton1Click:Connect(function()
        if state.running then return end
        if #CP==0 then GUI.setStatus("NO CHECKPOINTS LOADED","err"); return end
        local startFrom
        if state.pausedAt>0 and state.pausedAt<#CP then
            startFrom=state.pausedAt+1
        else
            startFrom=1; state.pausedAt=0
        end
        pulsing=false
        local s=getStroke(autoBtn)
        if s then s.Transparency=0; s.Color=T.NEON_YELL end
        autoBtn.Text="RUNNING..."; autoBtn.TextColor3=T.NEON_YELL

        Nav.runAuto(startFrom, GUI.setStatus, GUI.setProgress, GUI.highlightCP,
            function(claimed, _)
                pulsing=true; refreshAutoBtn()
            end
        )
        task.spawn(function()
            while state.running do task.wait(0.1) end
            task.wait(0.3); pulsing=true; refreshAutoBtn()
        end)
    end)

    -- ── PINCH ZOOM & F9 TOGGLE ─────────────────────────────────
    GUI.setupPinch(container)
    UIS.InputBegan:Connect(function(inp,gpe)
        if gpe then return end
        if inp.KeyCode==Enum.KeyCode.F9 then
            panel.Visible=not panel.Visible
        end
    end)

    -- Build initial grid
    GUI.refreshCPGrid()
end

-- ════════════════════════════════════════════════════════════
-- INIT
-- ════════════════════════════════════════════════════════════

GUI.build()
task.spawn(function()
    task.wait(0.5)
    AntiLag.apply()
end)

print("Yuhu Navigator v7 | Cyber Edition | "..#CP.." CP | F9 Toggle | ADD CP via GUI")
