--[[
  ═══════════════════════════════════════════════════════════════════════
  ZIHAN NAVIGATOR v6 — ADVANCED CP NAVIGATOR + ADAPTIVE GOPAY SCANNER
  CREATED BY ALFIAN
  
  • Streaming-aware multi-radius scanning
  • Adaptive wait system (no fixed delay)
  • Cyber futuristic responsive UI (PC + Mobile)
  • Comprehensive error handling
  ═══════════════════════════════════════════════════════════════════════
]]

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ═══════════════════════════════════════════════════════════════
local CONFIG = {
    Title = "ZIHAN NAVIGATOR",
    Subtitle = "Created by Alfian",
    TermsText = "Terms & Service Apply",
    
    Scan = {
        Keywords = {"claim", "voucher", "gopay", "redemption", "klaim", "reward"},
        KnownObjects = {
            "RedemptionPointBasepart", "Gopay", "GopayPoint", "Primary",
            "VoucherPoint", "ClaimPoint", "Part"
        },
        Radii = {50, 100, 200},
        Interval = 0.2,
        Timeout = 4.5,
        TimePerRadius = 1.5,
    },
    
    Teleport = {
        Retries = 3,
        RetryDelay = 0.2,
        OffsetY = 5,
    },
    
    Prompt = {
        MaxAttempts = 3,
        AttemptDelay = 0.1,
        SafeDistance = 7,
        MaxTargets = 5,
    },
    
    Theme = {
        Bg = Color3.fromRGB(8, 8, 12),
        Panel = Color3.fromRGB(12, 12, 18),
        PanelAlt = Color3.fromRGB(18, 18, 26),
        Border = Color3.fromRGB(30, 30, 45),
        BorderHi = Color3.fromRGB(45, 45, 65),
        Cyan = Color3.fromRGB(0, 220, 255),
        Blue = Color3.fromRGB(50, 120, 255),
        Purple = Color3.fromRGB(140, 80, 255),
        Pink = Color3.fromRGB(255, 50, 150),
        Txt = Color3.fromRGB(210, 210, 225),
        TxtDim = Color3.fromRGB(110, 110, 140),
        TxtMute = Color3.fromRGB(60, 60, 80),
        Ok = Color3.fromRGB(0, 255, 150),
        Err = Color3.fromRGB(255, 55, 75),
        Warn = Color3.fromRGB(255, 195, 45),
        StopBg = Color3.fromRGB(35, 8, 12),
        StopBd = Color3.fromRGB(75, 18, 25),
    },
}

-- ═══════════════════════════════════════════════════════════════
-- CHECKPOINT DATA — ADD MORE CPs HERE
-- ═══════════════════════════════════════════════════════════════
local CHECKPOINTS = {
    Vector3.new(-312.329, 654.005, -952.673),
    Vector3.new(4356.271, 2238.856, -9533.901),
    -- Vector3.new(x, y, z),  ← add more here
}

-- ═══════════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════════
local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui   = game:GetService("StarterGui")
local player       = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════
-- CLEANUP PREVIOUS INSTANCE
-- ═══════════════════════════════════════════════════════════════
pcall(function()
    for _, g in player.PlayerGui:GetChildren() do
        if g.Name == "ZihanNavigatorV6" then g:Destroy() end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════
local State = {
    Running  = false,
    Stopped  = false,
    CurCP    = 0,
    AntiLag  = false,
}

-- ═══════════════════════════════════════════════════════════════
-- UI REFERENCES (populated during build)
-- ═══════════════════════════════════════════════════════════════
local UI = {
    Root       = nil,
    Main       = nil,
    StatusLbl  = nil,
    StatusDot  = nil,
    ProgFill   = nil,
    ProgLbl    = nil,
    ScanLbl    = nil,
    StartBtn   = nil,
    StopBtn    = nil,
    ClaimBtn   = nil,
    CPBtns     = {},
    CPGlow     = nil,
}

-- ═══════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════
local function KW(t)
    if type(t) ~= "string" or t == "" then return false end
    local l = t:lower()
    for _, k in ipairs(CONFIG.Scan.Keywords) do
        if l:find(k, 1, true) then return true end
    end
    return false
end

local function KnownObj(n)
    if type(n) ~= "string" or n == "" then return false end
    local l = n:lower()
    for _, o in ipairs(CONFIG.Scan.KnownObjects) do
        if l == o:lower() then return true end
    end
    return l:find("redemption") or l:find("gopay") or l:find("voucher") or l:find("claim")
end

local function ObjPos(o)
    if o:IsA("BasePart") then return o.Position end
    if o:IsA("Model") then
        local p = o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart")
        return p and p.Position or nil
    end
    return nil
end

local function GetChar()
    local c = player.Character
    if not c then return nil, nil end
    local h = c:FindFirstChild("HumanoidRootPart")
    if not h or not h:IsA("BasePart") then return nil, nil end
    return h, c:FindFirstChildOfClass("Humanoid")
end

local function SafeTP(hrp, pos, tries)
    tries = tries or CONFIG.Teleport.Retries
    local off = Vector3.new(0, CONFIG.Teleport.OffsetY, 0)
    for i = 1, tries do
        pcall(function() hrp.CFrame = CFrame.new(pos + off) end)
        task.wait(CONFIG.Teleport.RetryDelay)
        if pcall(function() return (hrp.Position - pos).Magnitude < 25 end) then
            return true
        end
        if i < tries then off = Vector3.new(0, 3, 0) end
    end
    return pcall(function() return (hrp.Position - pos).Magnitude < 60 end)
end

local function Notify(t, m, d)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = t, Text = m, Duration = d or 5})
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI-LAG
-- ═══════════════════════════════════════════════════════════════
local function ApplyAntiLag()
    if State.AntiLag then return end
    local ok = pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
        workspace.GlobalShadows = false
        settings().Rendering.MaxFrameRate = 30
        local L = game:GetService("Lighting")
        L.GlobalShadows = false
        L.Brightness = 1
        L.EnvironmentDiffuseScale = 0
        L.EnvironmentSpecularScale = 0
        for _, v in L:GetChildren() do
            if v:IsA("PostEffect") then v.Enabled = false end
        end
        for _, v in workspace:GetDescendants() do
            if v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("Beam") then
                v.Enabled = false
            end
            if v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1 end
        end
    end)
    if ok then State.AntiLag = true end
end

-- ═══════════════════════════════════════════════════════════════
-- SCAN ENGINE
-- ═══════════════════════════════════════════════════════════════

--- Multi-pass filter on a single part list. Returns ALL targets from first hit pass.
local function FilterParts(parts, center)
    local seen = {}
    
    -- PASS 1 — ProximityPrompt text match
    local pass1 = {}
    for _, p in ipairs(parts) do
        if not p:IsA("BasePart") then continue end
        local pr = p:FindFirstChildOfClass("ProximityPrompt")
        if pr and not seen[pr] then
            if KW(pr.ActionText or "") or KW(pr.ObjectText or "") or KW(p.Name) then
                seen[pr] = true
                table.insert(pass1, {prompt = pr, pos = p.Position, label = (pr.ActionText ~= "" and pr.ActionText) or p.Name, dist = (p.Position - center).Magnitude, pass = 1})
            end
        end
    end
    if #pass1 > 0 then
        table.sort(pass1, function(a, b) return a.dist < b.dist end)
        return pass1
    end
    
    -- PASS 2 — Object name match
    local pass2 = {}
    for _, p in ipairs(parts) do
        if not p:IsA("BasePart") then continue end
        if KnownObj(p.Name) then
            local pr = p:FindFirstChildOfClass("ProximityPrompt")
            if pr and not seen[pr] then
                seen[pr] = true
                table.insert(pass2, {prompt = pr, pos = p.Position, label = p.Name, dist = (p.Position - center).Magnitude, pass = 2})
            end
        end
    end
    if #pass2 > 0 then
        table.sort(pass2, function(a, b) return a.dist < b.dist end)
        return pass2
    end
    
    -- PASS 3 — GUI text match (BillboardGui / SurfaceGui)
    local pass3 = {}
    for _, p in ipairs(parts) do
        if not p:IsA("BasePart") then continue end
        local found = false
        for _, g in p:GetChildren() do
            if found then break end
            if g:IsA("BillboardGui") or g:IsA("SurfaceGui") then
                for _, c in g:GetDescendants() do
                    if (c:IsA("TextLabel") or c:IsA("TextButton")) and KW(c.Text) then
                        local pr = p:FindFirstChildOfClass("ProximityPrompt")
                        if pr and not seen[pr] then
                            seen[pr] = true
                            table.insert(pass3, {prompt = pr, pos = p.Position, label = c.Text, dist = (p.Position - center).Magnitude, pass = 3})
                            found = true
                        end
                        break
                    end
                end
            end
        end
    end
    if #pass3 > 0 then
        table.sort(pass3, function(a, b) return a.dist < b.dist end)
        return pass3
    end
    
    return {}
end

--- Scan a single radius. Primary = GetPartBoundsInRadius, Fallback = GetDescendants.
local function ScanRadius(center, radius)
    -- PRIMARY
    local ok, parts = pcall(function()
        return workspace:GetPartBoundsInRadius(center, radius)
    end)
    if ok and parts and #parts > 0 then
        local r = FilterParts(parts, center)
        if #r > 0 then return r end
    end
    
    -- FALLBACK (only if primary returned nothing useful)
    local collected = {}
    local fok = pcall(function()
        for _, o in workspace:GetDescendants() do
            if o:IsA("BasePart") and (o.Position - center).Magnitude <= radius then
                table.insert(collected, o)
            end
        end
    end)
    if fok and #collected > 0 then
        return FilterParts(collected, center)
    end
    
    return {}
end

--- Adaptive multi-radius scan with loop & timeout.
local function AdaptiveScan(center, statusCb)
    local cfg = CONFIG.Scan
    
    for ri, radius in ipairs(cfg.Radii) do
        if State.Stopped then return {} end
        
        if statusCb then
            statusCb("Scanning (r:" .. radius .. ")...")
        end
        
        local t0 = tick()
        while (tick() - t0) < cfg.TimePerRadius do
            if State.Stopped then return {} end
            
            local targets = ScanRadius(center, radius)
            if #targets > 0 then
                return targets
            end
            
            task.wait(cfg.Interval)
        end
    end
    
    return {}
end

-- ═══════════════════════════════════════════════════════════════
-- PROMPT FIRING
-- ═══════════════════════════════════════════════════════════════
local function FireSafe(pr)
    for _ = 1, CONFIG.Prompt.MaxAttempts do
        if pcall(function() fireproximityprompt(pr) end) then return true end
        task.wait(CONFIG.Prompt.AttemptDelay)
    end
    return false
end

local function ClaimTarget(t, hrp)
    if not t or not t.prompt then return false end
    
    local dir = hrp.Position - t.pos
    local safe = t.pos + (dir.Magnitude > 0.1 and dir.Unit * CONFIG.Prompt.SafeDistance or Vector3.new(0, 0, CONFIG.Prompt.SafeDistance))
    
    pcall(function() hrp.CFrame = CFrame.new(safe + Vector3.new(0, 3, 0)) end)
    task.wait(0.2)
    
    if FireSafe(t.prompt) then return true end
    
    -- Retry from alternate angle
    local d2 = t.pos - hrp.Position
    if d2.Magnitude > 0 then
        pcall(function() hrp.CFrame = CFrame.new(hrp.Position + d2.Unit * 3) end)
        task.wait(0.15)
        return FireSafe(t.prompt)
    end
    return false
end

--- Try all targets until one succeeds.
local function ClaimMultiple(targets, hrp, max)
    max = max or CONFIG.Prompt.MaxTargets
    for i = 1, math.min(#targets, max) do
        if State.Stopped then return false end
        if ClaimTarget(targets[i], hrp) then
            return true
        end
    end
    return false
end

-- ═══════════════════════════════════════════════════════════════
-- UI STATUS HELPERS
-- ═══════════════════════════════════════════════════════════════
local COL_MAP = {
    ready       = CONFIG.Theme.Ok,
    teleporting = CONFIG.Theme.Blue,
    scanning    = CONFIG.Theme.Cyan,
    claiming    = CONFIG.Theme.Purple,
    done        = CONFIG.Theme.Ok,
    error       = CONFIG.Theme.Err,
    warning     = CONFIG.Theme.Warn,
    stopped     = CONFIG.Theme.Err,
    default     = CONFIG.Theme.Txt,
}

local function SetStatus(txt, key)
    if not UI.StatusLbl then return end
    local c = COL_MAP[key] or COL_MAP.default
    UI.StatusLbl.Text = txt
    UI.StatusLbl.TextColor3 = c
    if UI.StatusDot then UI.StatusDot.BackgroundColor3 = c end
end

local function SetProg(cur, total)
    if not UI.ProgFill or not UI.ProgLbl then return end
    local p = math.clamp(cur / total, 0, 1)
    TweenService:Create(UI.ProgFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(p, 0, 1, 0)
    }):Play()
    UI.ProgLbl.Text = cur .. " / " .. total
    UI.ProgLbl.TextColor3 = p >= 1 and CONFIG.Theme.Ok or p > 0.5 and CONFIG.Theme.Cyan or CONFIG.Theme.TxtMute
end

local function HighlightCP(idx)
    for i, btn in ipairs(UI.CPBtns) do
        local on = (i == idx)
        btn.BackgroundColor3 = on and CONFIG.Theme.PanelAlt or CONFIG.Theme.Panel
        btn.TextColor3 = on and CONFIG.Theme.Cyan or CONFIG.Theme.TxtMute
        local s = btn:FindFirstChildOfClass("UIStroke")
        if s then s.Color = on and CONFIG.Theme.Cyan or CONFIG.Theme.Border end
    end
    -- auto-scroll
    if UI.CPBtns[idx] then
        task.defer(function()
            local sf = UI.CPBtns[idx].Parent
            if sf and sf:IsA("ScrollingFrame") then
                local y = UI.CPBtns[idx].AbsolutePosition.Y - sf.AbsolutePosition.Y
                sf.CanvasPosition = Vector2.new(0, math.max(0, y - 20))
            end
        end)
    end
end

local function AnimateCPGlow(idx)
    if not UI.CPGlow or not UI.CPBtns[idx] then return end
    local btn = UI.CPBtns[idx]
    UI.CPGlow.Visible = true
    UI.CPGlow.Size = UDim2.new(0, btn.AbsoluteSize.X + 10, 0, btn.AbsoluteSize.Y + 10)
    UI.CPGlow.Position = UDim2.new(0, btn.AbsolutePosition.X - 5, 0, btn.AbsolutePosition.Y - 5)
    TweenService:Create(UI.CPGlow, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.6
    }):Play()
    task.delay(0.8, function()
        if UI.CPGlow then
            TweenService:Create(UI.CPGlow, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
            task.delay(0.4, function() if UI.CPGlow then UI.CPGlow.Visible = false end end)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- NAVIGATION LOGIC
-- ═══════════════════════════════════════════════════════════════
local function GotoCP(idx, doScan)
    local hrp, hum = GetChar()
    if not hrp then SetStatus("Error: No character", "error"); return false, false end
    if not CHECKPOINTS[idx] then SetStatus("Error: CP" .. idx .. " missing", "error"); return false, false end
    
    local target = CHECKPOINTS[idx]
    State.CurCP = idx
    HighlightCP(idx)
    AnimateCPGlow(idx)
    
    SetStatus("Teleporting to CP" .. idx .. "...", "teleporting")
    SetProg(idx, #CHECKPOINTS)
    
    if not SafeTP(hrp, target) then
        SetStatus("TP failed, retrying...", "warning")
        SafeTP(hrp, target, 5)
    end
    if State.Stopped then return false, false end
    if not doScan then return true, false end
    
    -- Adaptive scan
    local targets = AdaptiveScan(target, function(s) SetStatus(s, "scanning") end)
    if State.Stopped then return false, false end
    
    if #targets > 0 then
        SetStatus("Claiming at CP" .. idx .. "...", "claiming")
        if hum then hum.WalkSpeed = 16 end
        task.wait(0.05)
        
        if ClaimMultiple(targets, hrp) then
            SetStatus("✓ Claimed at CP" .. idx, "done")
            Notify("Zihan Navigator", "GoPay claimed at CP" .. idx .. "!", 5)
            return true, true
        end
    end
    return true, false
end

local function RunAuto(from)
    if State.Running then return end
    State.Running = true
    State.Stopped = false
    
    task.spawn(function()
        local hrp, hum = GetChar()
        if not hrp then SetStatus("Error: No character", "error"); State.Running = false; return end
        if hum then hum.WalkSpeed = 0 end
        
        local start = math.clamp(from or 1, 1, #CHECKPOINTS)
        
        for i = start, #CHECKPOINTS do
            if State.Stopped then SetStatus("Stopped", "stopped"); break end
            local ok, found = GotoCP(i, true)
            if not ok then break end
            if found then break end
        end
        
        if not State.Stopped and State.CurCP >= #CHECKPOINTS then
            SetProg(#CHECKPOINTS, #CHECKPOINTS)
            SetStatus("All CPs completed", "done")
        end
        
        if hum then hum.WalkSpeed = 16 end
        State.Running = false
    end)
end

local function RunClaim()
    if State.Running then return end
    State.Running = true
    State.Stopped = false
    
    task.spawn(function()
        local hrp, hum = GetChar()
        if not hrp then SetStatus("Error: No character", "error"); State.Running = false; return end
        
        SetStatus("Direct claim...", "claiming")
        local maxR = CONFIG.Scan.Radii[#CONFIG.Scan.Radii]
        local targets = AdaptiveScan(hrp.Position, function(s) SetStatus(s, "scanning") end)
        
        if #targets > 0 and not State.Stopped then
            if ClaimMultiple(targets, hrp) then
                SetStatus("✓ Claimed", "done")
                Notify("Zihan Navigator", "Claim successful!", 3)
            else
                SetStatus("Claim failed", "error")
            end
        elseif not State.Stopped then
            SetStatus("Nothing found", "warning")
        end
        State.Running = false
    end)
end

local function RunManual(idx)
    if State.Running then return end
    State.Running = true
    State.Stopped = false
    
    task.spawn(function()
        local hrp, hum = GetChar()
        if not hrp then SetStatus("Error: No character", "error"); State.Running = false; return end
        if hum then hum.WalkSpeed = 0 end
        
        local _, found = GotoCP(idx, true)
        if not found and not State.Stopped then
            SetStatus("CP" .. idx .. " — No GoPay", "done")
        end
        if hum then hum.WalkSpeed = 16 end
        State.Running = false
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- GUI BUILDER
-- ═══════════════════════════════════════════════════════════════
local function BuildUI()
    local T = CONFIG.Theme
    
    -- ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name = "ZihanNavigatorV6"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 9999
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = player.PlayerGui
    UI.Root = sg
    
    -- Main panel — 260×350 compact card
    local F = Instance.new("Frame")
    F.Size = UDim2.new(0, 260, 0, 350)
    F.Position = UDim2.new(0.5, -130, 0.5, -175)
    F.BackgroundColor3 = T.Bg
    F.BorderSizePixel = 0
    F.Active = true
    F.Draggable = true
    F.ZIndex = 10
    F.Parent = sg
    UI.Main = F
    
    Instance.new("UICorner", F).CornerRadius = UDim.new(0, 10)
    Instance.new("UIStroke", F).Color = T.Border
    
    -- Top neon accent line
    local topGlow = Instance.new("Frame")
    topGlow.Size = UDim2.new(0.5, 0, 0, 2)
    topGlow.Position = UDim2.new(0.25, 0, 0, 0)
    topGlow.BackgroundColor3 = T.Cyan
    topGlow.BorderSizePixel = 0
    topGlow.ZIndex = 15
    topGlow.Parent = F
    Instance.new("UICorner", topGlow).CornerRadius = UDim.new(0, 1)
    
    -- Subtle corner glow (top-left)
    local cornerGlow = Instance.new("ImageLabel")
    cornerGlow.Size = UDim2.new(0, 40, 0, 40)
    cornerGlow.Position = UDim2.new(0, -5, 0, -5)
    cornerGlow.BackgroundTransparency = 1
    cornerGlow.Image = "rbxassetid://7669168585"
    cornerGlow.ImageColor3 = T.Cyan
    cornerGlow.ImageTransparency = 0.7
    cornerGlow.ZIndex = 9
    cornerGlow.Parent = F
    
    -- CP glow overlay
    local cpGlow = Instance.new("Frame")
    cpGlow.Size = UDim2.new(0, 0, 0, 0)
    cpGlow.Position = UDim2.new(0, 0, 0, 0)
    cpGlow.BackgroundColor3 = T.Cyan
    cpGlow.BackgroundTransparency = 1
    cpGlow.BorderSizePixel = 0
    cpGlow.ZIndex = 11
    cpGlow.Visible = false
    cpGlow.Parent = F
    Instance.new("UICorner", cpGlow).CornerRadius = UDim.new(0, 6)
    UI.CPGlow = cpGlow
    
    -- ═══ HEADER ═══
    local hdr = Instance.new("Frame")
    hdr.Size = UDim2.new(1, 0, 0, 54)
    hdr.Position = UDim2.new(0, 0, 0, 4)
    hdr.BackgroundTransparency = 1
    hdr.ZIndex = 11
    hdr.Parent = F
    
    local titleL = Instance.new("TextLabel")
    titleL.Size = UDim2.new(1, -52, 0, 18)
    titleL.Position = UDim2.new(0, 14, 0, 4)
    titleL.BackgroundTransparency = 1
    titleL.Text = CONFIG.Title
    titleL.TextColor3 = T.Cyan
    titleL.Font = Enum.Font.GothamBold
    titleL.TextSize = 13
    titleL.TextXAlignment = Enum.TextXAlignment.Left
    titleL.ZIndex = 12
    titleL.Parent = hdr
    
    local subL = Instance.new("TextLabel")
    subL.Size = UDim2.new(1, -52, 0, 12)
    subL.Position = UDim2.new(0, 14, 0, 22)
    subL.BackgroundTransparency = 1
    subL.Text = CONFIG.Subtitle
    subL.TextColor3 = T.TxtDim
    subL.Font = Enum.Font.Gotham
    subL.TextSize = 9
    subL.TextXAlignment = Enum.TextXAlignment.Left
    subL.ZIndex = 12
    subL.Parent = hdr
    
    local termsL = Instance.new("TextLabel")
    termsL.Size = UDim2.new(1, -52, 0, 10)
    termsL.Position = UDim2.new(0, 14, 0, 36)
    termsL.BackgroundTransparency = 1
    termsL.Text = CONFIG.TermsText
    termsL.TextColor3 = T.TxtMute
    termsL.Font = Enum.Font.Gotham
    termsL.TextSize = 7
    termsL.TextXAlignment = Enum.TextXAlignment.Left
    termsL.ZIndex = 12
    termsL.Parent = hdr
    
    -- Close button (mobile-friendly 30×30)
    local xBtn = Instance.new("TextButton")
    xBtn.Size = UDim2.new(0, 30, 0, 30)
    xBtn.Position = UDim2.new(1, -36, 0, 2)
    xBtn.BackgroundColor3 = T.PanelAlt
    xBtn.Text = "✕"
    xBtn.TextColor3 = T.TxtDim
    xBtn.Font = Enum.Font.GothamBold
    xBtn.TextSize = 13
    xBtn.BorderSizePixel = 0
    xBtn.ZIndex = 14
    xBtn.Parent = F
    Instance.new("UICorner", xBtn).CornerRadius = UDim.new(0, 7)
    local xSt = Instance.new("UIStroke", xBtn)
    xSt.Color = T.Border
    
    xBtn.MouseEnter:Connect(function() xBtn.TextColor3 = T.Err; xSt.Color = T.Err end)
    xBtn.MouseLeave:Connect(function() xBtn.TextColor3 = T.TxtDim; xSt.Color = T.Border end)
    xBtn.MouseButton1Click:Connect(function()
        TweenService:Create(F, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 260, 0, 0), BackgroundTransparency = 1
        }):Play()
        task.delay(0.2, function() sg:Destroy() end)
    end)
    
    -- ═══ STATUS BAR ═══
    local sBar = Instance.new("Frame")
    sBar.Size = UDim2.new(1, -24, 0, 22)
    sBar.Position = UDim2.new(0, 12, 0, 62)
    sBar.BackgroundColor3 = T.Panel
    sBar.BorderSizePixel = 0
    sBar.ZIndex = 12
    sBar.Parent = F
    Instance.new("UICorner", sBar).CornerRadius = UDim.new(0, 5)
    Instance.new("UIStroke", sBar).Color = T.Border
    
    local sDot = Instance.new("Frame")
    sDot.Size = UDim2.new(0, 6, 0, 6)
    sDot.Position = UDim2.new(0, 8, 0.5, -3)
    sDot.BackgroundColor3 = T.Ok
    sDot.BorderSizePixel = 0
    sDot.ZIndex = 13
    sDot.Parent = sBar
    Instance.new("UICorner", sDot).CornerRadius = UDim.new(1, 0)
    UI.StatusDot = sDot
    
    local sLbl = Instance.new("TextLabel")
    sLbl.Size = UDim2.new(1, -22, 1, 0)
    sLbl.Position = UDim2.new(0, 20, 0, 0)
    sLbl.BackgroundTransparency = 1
    sLbl.Text = "Ready"
    sLbl.TextColor3 = T.Ok
    sLbl.Font = Enum.Font.GothamBold
    sLbl.TextSize = 10
    sLbl.TextXAlignment = Enum.TextXAlignment.Left
    sLbl.TextTruncate = Enum.TextTruncate.AtEnd
    sLbl.ZIndex = 13
    sLbl.Parent = sBar
    UI.StatusLbl = sLbl
    
    -- ═══ PROGRESS BAR ═══
    local pCont = Instance.new("Frame")
    pCont.Size = UDim2.new(1, -24, 0, 16)
    pCont.Position = UDim2.new(0, 12, 0, 90)
    pCont.BackgroundColor3 = T.Panel
    pCont.BorderSizePixel = 0
    pCont.ZIndex = 12
    pCont.Parent = F
    Instance.new("UICorner", pCont).CornerRadius = UDim.new(0, 5)
    Instance.new("UIStroke", pCont).Color = T.Border
    
    local pFill = Instance.new("Frame")
    pFill.Size = UDim2.new(0, 0, 1, 0)
    pFill.BackgroundColor3 = T.Cyan
    pFill.BorderSizePixel = 0
    pFill.ZIndex = 13
    pFill.Parent = pCont
    Instance.new("UICorner", pFill).CornerRadius = UDim.new(0, 5)
    UI.ProgFill = pFill
    
    local pLbl = Instance.new("TextLabel")
    pLbl.Size = UDim2.new(1, 0, 1, 0)
    pLbl.BackgroundTransparency = 1
    pLbl.Text = "0 / " .. #CHECKPOINTS
    pLbl.TextColor3 = T.TxtMute
    pLbl.Font = Enum.Font.GothamBold
    pLbl.TextSize = 8
    pLbl.TextXAlignment = Enum.TextXAlignment.Center
    pLbl.ZIndex = 14
    pLbl.Parent = pCont
    UI.ProgLbl = pLbl
    
    -- ═══ SCAN INFO ═══
    local scanL = Instance.new("TextLabel")
    scanL.Size = UDim2.new(1, -24, 0, 14)
    scanL.Position = UDim2.new(0, 12, 0, 110)
    scanL.BackgroundTransparency = 1
    scanL.Text = "Scan: " .. table.concat(CONFIG.Scan.Radii, "→") .. "s | Adaptive wait"
    scanL.TextColor3 = T.TxtMute
    scanL.Font = Enum.Font.Gotham
    scanL.TextSize = 7
    scanL.TextXAlignment = Enum.TextXAlignment.Left
    scanL.ZIndex = 12
    scanL.Parent = F
    UI.ScanLbl = scanL
    
    -- ═══ CP GRID ═══
    local cpSF = Instance.new("ScrollingFrame")
    cpSF.Size = UDim2.new(1, -24, 0, 155)
    cpSF.Position = UDim2.new(0, 12, 0, 126)
    cpSF.BackgroundColor3 = T.Panel
    cpSF.BorderSizePixel = 0
    cpSF.ScrollBarThickness = 2
    cpSF.ScrollBarImageColor3 = T.BorderHi
    cpSF.CanvasSize = UDim2.new(0, 0, 0, 0)
    cpSF.ZIndex = 12
    cpSF.Parent = F
    Instance.new("UICorner", cpSF).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", cpSF).Color = T.Border
    
    local cpGrid = Instance.new("UIGridLayout")
    cpGrid.CellSize = UDim2.new(0, 38, 0, 26)
    cpGrid.CellPadding = UDim2.new(0, 3, 0, 3)
    cpGrid.SortOrder = Enum.SortOrder.LayoutOrder
    cpGrid.Parent = cpSF
    
    local cpPad = Instance.new("UIPadding")
    cpPad.PaddingLeft = UDim.new(0, 4)
    cpPad.PaddingRight = UDim.new(0, 4)
    cpPad.PaddingTop = UDim.new(0, 4)
    cpPad.PaddingBottom = UDim.new(0, 4)
    cpPad.Parent = cpSF
    
    for i = 1, #CHECKPOINTS do
        local b = Instance.new("TextButton")
        b.LayoutOrder = i
        b.BackgroundColor3 = T.Panel
        b.BorderSizePixel = 0
        b.Text = "CP" .. i
        b.TextColor3 = T.TxtMute
        b.Font = Enum.Font.GothamBold
        b.TextSize = 8
        b.ZIndex = 13
        b.AutoButtonColor = false
        b.Parent = cpSF
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
        Instance.new("UIStroke", b).Color = T.Border
        
        table.insert(UI.CPBtns, b)
        
        local ci = i
        b.MouseButton1Click:Connect(function()
            if State.Running then return end
            RunManual(ci)
        end)
        b.MouseEnter:Connect(function()
            if State.CurCP ~= ci then
                b.BackgroundColor3 = T.PanelAlt
                b.TextColor3 = T.TxtDim
            end
        end)
        b.MouseLeave:Connect(function()
            if State.CurCP ~= ci then
                b.BackgroundColor3 = T.Panel
                b.TextColor3 = T.TxtMute
            end
        end)
    end
    
    cpGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        cpSF.CanvasSize = UDim2.new(0, 0, 0, cpGrid.AbsoluteContentSize.Y + 8)
    end)
    
    -- ═══ SEPARATOR ═══
    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(1, -24, 0, 1)
    sep.Position = UDim2.new(0, 12, 0, 285)
    sep.BackgroundColor3 = T.Border
    sep.BorderSizePixel = 0
    sep.ZIndex = 12
    sep.Parent = F
    
    -- ═══ BUTTONS ═══
    local by = 294
    local bh = 38
    
    -- STOP
    local stB = Instance.new("TextButton")
    stB.Size = UDim2.new(0, 62, 0, bh)
    stB.Position = UDim2.new(0, 12, 0, by)
    stB.BackgroundColor3 = T.StopBg
    stB.Text = "■ STOP"
    stB.TextColor3 = T.Err
    stB.Font = Enum.Font.GothamBold
    stB.TextSize = 9
    stB.BorderSizePixel = 0
    stB.ZIndex = 12
    stB.AutoButtonColor = false
    stB.Parent = F
    Instance.new("UICorner", stB).CornerRadius = UDim.new(0, 7)
    Instance.new("UIStroke", stB).Color = T.StopBd
    UI.StopBtn = stB
    
    stB.MouseEnter:Connect(function() stB.BackgroundColor3 = Color3.fromRGB(50, 12, 18) end)
    stB.MouseLeave:Connect(function() stB.BackgroundColor3 = T.StopBg end)
    stB.MouseButton1Click:Connect(function()
        State.Stopped = true
        stB.Text = "✓"
        stB.TextColor3 = T.Warn
        task.delay(1.5, function()
            stB.Text = "■ STOP"
            stB.TextColor3 = T.Err
        end)
    end)
    
    -- CLAIM
    local clB = Instance.new("TextButton")
    clB.Size = UDim2.new(0, 80, 0, bh)
    clB.Position = UDim2.new(0, 78, 0, by)
    clB.BackgroundColor3 = T.PanelAlt
    clB.Text = "⚡ CLAIM"
    clB.TextColor3 = T.Purple
    clB.Font = Enum.Font.GothamBold
    clB.TextSize = 9
    clB.BorderSizePixel = 0
    clB.ZIndex = 12
    clB.AutoButtonColor = false
    clB.Parent = F
    Instance.new("UICorner", clB).CornerRadius = UDim.new(0, 7)
    local clSt = Instance.new("UIStroke", clB)
    clSt.Color = Color3.fromRGB(55, 35, 90)
    UI.ClaimBtn = clB
    
    clB.MouseEnter:Connect(function() clB.BackgroundColor3 = Color3.fromRGB(25, 22, 38); clSt.Color = T.Purple end)
    clB.MouseLeave:Connect(function() clB.BackgroundColor3 = T.PanelAlt; clSt.Color = Color3.fromRGB(55, 35, 90) end)
    clB.MouseButton1Click:Connect(function()
        if State.Running then return end
        clB.Text = "⏳..."
        clB.TextColor3 = T.Warn
        RunClaim()
        task.spawn(function()
            while State.Running do task.wait(0.1) end
            task.wait(0.3)
            clB.Text = "⚡ CLAIM"
            clB.TextColor3 = T.Purple
        end)
    end)
    
    -- START AUTO
    local goB = Instance.new("TextButton")
    goB.Size = UDim2.new(1, -164, 0, bh)
    goB.Position = UDim2.new(1, -152, 0, by)
    goB.BackgroundColor3 = T.Cyan
    goB.Text = "▶ AUTO CP"
    goB.TextColor3 = T.Bg
    goB.Font = Enum.Font.GothamBold
    goB.TextSize = 9
    goB.BorderSizePixel = 0
    goB.ZIndex = 12
    goB.AutoButtonColor = false
    goB.Parent = F
    Instance.new("UICorner", goB).CornerRadius = UDim.new(0, 7)
    UI.StartBtn = goB
    
    -- Pulsing animation
    local pulsing = true
    task.spawn(function()
        while sg and sg.Parent do
            if pulsing then
                TweenService:Create(goB, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    BackgroundColor3 = Color3.fromRGB(0, 175, 200)
                }):Play()
                task.wait(1.4)
                if pulsing then
                    TweenService:Create(goB, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                        BackgroundColor3 = T.Cyan
                    }):Play()
                    task.wait(1.4)
                end
            else
                task.wait(0.3)
            end
        end
    end)
    
    goB.MouseButton1Click:Connect(function()
        if State.Running then return end
        pulsing = false
        goB.BackgroundColor3 = T.PanelAlt
        goB.TextColor3 = T.Warn
        goB.Text = "▶ RUNNING"
        RunAuto(1)
        task.spawn(function()
            while State.Running do task.wait(0.1) end
            task.wait(0.3)
            goB.BackgroundColor3 = T.Cyan
            goB.TextColor3 = T.Bg
            goB.Text = "▶ AUTO CP"
            pulsing = true
        end)
    end)
    
    -- F9 toggle
    UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == Enum.KeyCode.F9 then
            F.Visible = not F.Visible
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════════════════════
task.spawn(function()
    BuildUI()
    task.wait(0.5)
    ApplyAntiLag()
    SetStatus("Ready — " .. #CHECKPOINTS .. " CPs loaded", "ready")
    print("[" .. CONFIG.Title .. "] v6 | " .. #CHECKPOINTS .. " CPs | Multi-radius adaptive scan | F9 toggle")
end)
