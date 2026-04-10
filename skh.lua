--[[
  ZIHAN NAVIGATOR v6 — CYBER EDITION
  STREAMING-AWARE · PROXIMITY-FIRST · MULTI-PASS SCANNER
]]

-- ════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ════════════════════════════════════════════════════════════

local CP = {
    Vector3.new(-312.329, 654.005, -952.673),
    Vector3.new(4356.271, 2238.856, -9533.901),
}

local KEYWORDS = {"claim", "voucher", "gopay", "redemption", "klaim", "reward"}

local KNOWN_OBJ = {
    "RedemptionPointBasepart", "Gopay", "GopayPoint", "Primary",
    "VoucherPoint", "ClaimPoint", "Part"
}

local SCAN_RADII    = {50, 100, 200}
local SCAN_INTERVAL = 0.2
local SCAN_TIMEOUT  = 5
local PROMPT_RETRIES = 3
local TP_RETRIES     = 3

-- ════════════════════════════════════════════════════════════
-- THEME
-- ════════════════════════════════════════════════════════════

local T = {
    BG_DEEP     = Color3.fromRGB(6, 6, 14),
    BG_PANEL    = Color3.fromRGB(10, 10, 22),
    BG_CARD     = Color3.fromRGB(16, 16, 36),
    BG_INPUT    = Color3.fromRGB(18, 18, 40),
    BORDER      = Color3.fromRGB(28, 28, 60),
    BORDER_HI   = Color3.fromRGB(45, 45, 90),
    NEON_CYAN   = Color3.fromRGB(0, 229, 255),
    NEON_BLUE   = Color3.fromRGB(41, 121, 255),
    NEON_PURP   = Color3.fromRGB(124, 77, 255),
    NEON_GREEN  = Color3.fromRGB(0, 255, 136),
    NEON_RED    = Color3.fromRGB(255, 50, 80),
    NEON_YELLOW = Color3.fromRGB(255, 200, 0),
    TXT_PRI     = Color3.fromRGB(220, 220, 240),
    TXT_DIM     = Color3.fromRGB(70, 70, 110),
    TXT_MID     = Color3.fromRGB(130, 130, 165),
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
    return lo:find("redemption", 1, true)
        or lo:find("gopay", 1, true)
        or lo:find("voucher", 1, true)
        or lo:find("claim", 1, true)
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
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title, Text = text, Duration = 4,
        })
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
        L.GlobalShadows = false
        L.Brightness = 1.5
        L.EnvironmentDiffuseScale = 0.3
        L.EnvironmentSpecularScale = 0.2
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
-- SCANNER — PROXIMITY-FIRST · MULTI-PASS · STREAMING-AWARE
-- ════════════════════════════════════════════════════════════

local Scanner = {}

--- Acquire parts near center using primary radius scan
function Scanner.acquireParts(center, radius)
    local ok, parts = pcall(function()
        return workspace:GetPartBoundsInRadius(center, radius)
    end)
    if ok and parts and #parts > 0 then
        return parts
    end
    -- FALLBACK: GetDescendants (optimized, early exit not possible here
    -- but we only call this when primary fails which is rare)
    local results = {}
    local fok = pcall(function()
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and (v.Position - center).Magnitude <= radius then
                table.insert(results, v)
            end
        end
    end)
    return fok and results or {}
end

--- Build a result entry from a prompt + position
local function makeResult(prompt, pos, label, dist, passNum)
    return {
        prompt = prompt,
        pos    = pos,
        label  = label,
        dist   = dist,
        pass   = passNum,
    }
end

--- PASS 1 — ProximityPrompt (highest priority)
--- Checks each returned part and its children for ProximityPrompt
--- with keyword-matching ActionText / ObjectText / Parent.Name
local function pass1_prompt(parts, center, radius, seen)
    for _, part in ipairs(parts) do
        local candidates = {part}
        for _, ch in ipairs(part:GetChildren()) do
            if ch:IsA("ProximityPrompt") then
                table.insert(candidates, ch)
            end
        end
        for _, pr in ipairs(candidates) do
            if pr:IsA("ProximityPrompt") and not seen[pr] then
                local at = pr.ActionText or ""
                local ot = pr.ObjectText or ""
                local pn = pr.Parent and pr.Parent.Name or ""
                if hasKeyword(at) or hasKeyword(ot) or hasKeyword(pn) or isKnownObj(pn) then
                    local par = pr.Parent
                    local pos = getObjPos(par)
                    if pos and (pos - center).Magnitude <= radius then
                        seen[pr] = true
                        return makeResult(pr, pos, at ~= "" and at or pn,
                            (pos - center).Magnitude, 1)
                    end
                end
            end
        end
    end
    return nil
end

--- PASS 2 — Object name matching
--- Checks part name and parent name against KNOWN_OBJ / KEYWORDS
local function pass2_name(parts, center, radius, seen)
    for _, part in ipairs(parts) do
        -- Check part's parent (likely a Model)
        local par = part.Parent
        if par then
            if isKnownObj(par.Name) then
                local pos = getObjPos(par)
                if pos and (pos - center).Magnitude <= radius then
                    for _, ch in ipairs(par:GetDescendants()) do
                        if ch:IsA("ProximityPrompt") and not seen[ch] then
                            seen[ch] = true
                            return makeResult(ch, pos, par.Name,
                                (pos - center).Magnitude, 2)
                        end
                    end
                end
            end
        end
        -- Check part name directly
        if isKnownObj(part.Name) then
            local pos = part.Position
            if (pos - center).Magnitude <= radius then
                for _, ch in ipairs(part:GetChildren()) do
                    if ch:IsA("ProximityPrompt") and not seen[ch] then
                        seen[ch] = true
                        return makeResult(ch, pos, part.Name,
                            (pos - center).Magnitude, 2)
                    end
                end
            end
        end
    end
    return nil
end

--- PASS 3 — GUI text (BillboardGui / SurfaceGui)
--- Scans GUI children for keyword-matching text, then finds associated prompt
local function pass3_gui(parts, center, radius, seen)
    for _, part in ipairs(parts) do
        local par = part.Parent
        if not par then continue end
        local pos = getObjPos(par)
        if not pos or (pos - center).Magnitude > radius then continue end

        for _, gui in ipairs(par:GetChildren()) do
            if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
                for _, tc in ipairs(gui:GetDescendants()) do
                    if (tc:IsA("TextLabel") or tc:IsA("TextButton"))
                        and hasKeyword(tc.Text) then
                        -- Find ANY prompt in the parent hierarchy
                        for _, dc in ipairs(par:GetDescendants()) do
                            if dc:IsA("ProximityPrompt") and not seen[dc] then
                                seen[dc] = true
                                return makeResult(dc, pos, tc.Text,
                                    (pos - center).Magnitude, 3)
                            end
                        end
                        break
                    end
                end
            end
        end
    end
    return nil
end

--- Single-radius scan with all 3 passes (early exit per pass)
function Scanner.scanRadius(center, radius)
    local parts = Scanner.acquireParts(center, radius)
    if not parts or #parts == 0 then return nil end
    local seen = {}

    local r = pass1_prompt(parts, center, radius, seen)
    if r then return r end

    r = pass2_name(parts, center, radius, seen)
    if r then return r end

    r = pass3_gui(parts, center, radius, seen)
    return r
end

--- Multi-radius scan: 50 → 100 → 200 (early exit per radius)
function Scanner.scanAll(center)
    for _, radius in ipairs(SCAN_RADII) do
        local r = Scanner.scanRadius(center, radius)
        if r then return r end
    end
    return nil
end

--- Collect ALL targets across all radii and all passes (for multi-target firing)
function Scanner.scanAllTargets(center)
    local all, seen = {}, {}
    for _, radius in ipairs(SCAN_RADII) do
        local parts = Scanner.acquireParts(center, radius)
        if parts and #parts > 0 then
            -- Pass 1 collect
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
                            local par = pr.Parent
                            local pos = getObjPos(par)
                            if pos and (pos - center).Magnitude <= radius then
                                seen[pr] = true
                                table.insert(all, makeResult(pr, pos,
                                    at ~= "" and at or pn, (pos - center).Magnitude, 1))
                            end
                        end
                    end
                end
            end
            -- Pass 2 collect
            for _, part in ipairs(parts) do
                local par = part.Parent
                if par and isKnownObj(par.Name) then
                    local pos = getObjPos(par)
                    if pos and (pos - center).Magnitude <= radius then
                        for _, ch in ipairs(par:GetDescendants()) do
                            if ch:IsA("ProximityPrompt") and not seen[ch] then
                                seen[ch] = true
                                table.insert(all, makeResult(ch, pos, par.Name,
                                    (pos - center).Magnitude, 2))
                            end
                        end
                    end
                end
                if isKnownObj(part.Name) then
                    local pos = part.Position
                    if (pos - center).Magnitude <= radius then
                        for _, ch in ipairs(part:GetChildren()) do
                            if ch:IsA("ProximityPrompt") and not seen[ch] then
                                seen[ch] = true
                                table.insert(all, makeResult(ch, pos, part.Name,
                                    (pos - center).Magnitude, 2))
                            end
                        end
                    end
                end
            end
            -- Pass 3 collect
            for _, part in ipairs(parts) do
                local par = part.Parent
                if not par then continue end
                local pos = getObjPos(par)
                if not pos or (pos - center).Magnitude > radius then continue end
                for _, gui in ipairs(par:GetChildren()) do
                    if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
                        for _, tc in ipairs(gui:GetDescendants()) do
                            if (tc:IsA("TextLabel") or tc:IsA("TextButton"))
                                and hasKeyword(tc.Text) then
                                for _, dc in ipairs(par:GetDescendants()) do
                                    if dc:IsA("ProximityPrompt") and not seen[dc] then
                                        seen[dc] = true
                                        table.insert(all, makeResult(dc, pos, tc.Text,
                                            (pos - center).Magnitude, 3))
                                    end
                                end
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    table.sort(all, function(a, b) return a.dist < b.dist end)
    return all
end

--- Adaptive wait scan (streaming-aware)
--- Loops every 0.2s, max 5s timeout, exits early when found
function Scanner.adaptiveScan(center, onTick)
    local elapsed = 0
    while elapsed < SCAN_TIMEOUT do
        if state.stopped then return nil end
        if onTick then onTick(elapsed) end
        local r = Scanner.scanAll(center)
        if r then return r end
        task.wait(SCAN_INTERVAL)
        elapsed = elapsed + SCAN_INTERVAL
    end
    return nil
end

--- Adaptive wait scan — multi-target variant
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
    if not char then return nil, nil, nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then hrp = char:WaitForChild("HumanoidRootPart", 5) end
    if not hrp then return char, nil, nil end
    return char, hrp, char:FindFirstChildOfClass("Humanoid")
end

function Nav.tpTo(pos)
    local _, hrp = Nav.getChar()
    if not hrp then return false end
    for _ = 1, TP_RETRIES do
        if state.stopped then return false end
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
        task.wait(0.2)
        if (hrp.Position - pos).Magnitude < 25 then return true end
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
        task.wait(0.15)
    end
    return (hrp.Position - pos).Magnitude < 50
end

--- Fire prompts with multi-target + retry support
--- Does NOT blindly break on first result
function Nav.firePrompts(results, onAttempt)
    if not results or #results == 0 then return 0 end
    local _, hrp, hum = Nav.getChar()
    if not hrp then return 0 end
    if hum then hum.WalkSpeed = 16 end

    local fired = 0
    for _, r in ipairs(results) do
        if state.stopped then break end
        -- Position character near prompt (7 stud away + elevated)
        local dir = hrp.Position - r.pos
        local offset = dir.Magnitude > 0.1 and dir.Unit * 7 or Vector3.new(0, 0, 7)
        hrp.CFrame = CFrame.new(r.pos + offset + Vector3.new(0, 3, 0))
        task.wait(0.15)

        for retry = 1, PROMPT_RETRIES do
            if state.stopped then break end
            if onAttempt then onAttempt(r, retry) end
            if safeFire(r.prompt) then
                fired = fired + 1
                break
            end
            task.wait(0.08)
        end
        -- Small gap between targets
        if fired > 0 then task.wait(0.1) end
    end
    return fired
end

--- Process a single CP: teleport → adaptive scan → fire
function Nav.processCP(idx, setStatus, setProgress)
    if not CP[idx] then return false, false end
    local pt = CP[idx]
    state.currentCP = idx

    setStatus("CP " .. idx .. "/" .. #CP .. " — TELEPORTING", "wait")
    setProgress(idx, #CP)

    if not Nav.tpTo(pt) then
        setStatus("CP " .. idx .. " — TP FAILED", "err")
        return false, false
    end

    -- Adaptive scan (streaming-aware, no fixed delay)
    local results = Scanner.adaptiveScanMulti(pt, function(elapsed)
        setStatus("CP " .. idx .. " — SCANNING " .. string.format("%.1f", elapsed) .. "s", "wait")
    end)

    if state.stopped then return false, false end

    if #results == 0 then
        setStatus("CP " .. idx .. " — NO TARGET", "idle")
        return true, false
    end

    setStatus("⚡ " .. #results .. " TARGET(s) AT CP" .. idx, "found")

    local fired = Nav.firePrompts(results, function(r, retry)
        setStatus("CP " .. idx .. " — FIRE [" .. retry .. "/" .. PROMPT_RETRIES .. "]", "found")
    end)

    if fired > 0 then
        setStatus("✓ CLAIMED " .. fired .. " AT CP" .. idx, "done")
        notify("Zihan Navigator", "Claimed " .. fired .. " at CP" .. idx)
        return true, true
    end

    setStatus("CP " .. idx .. " — FIRE FAILED", "err")
    return true, false
end

--- Auto: CP1 → CP2 → ... → Last CP → STOP
function Nav.runAuto(fromCP, setStatus, setProgress, onCP, onDone)
    if state.running then return end
    state.running = true
    state.stopped = false

    task.spawn(function()
        local _, _, hum = Nav.getChar()
        if not hum then
            setStatus("ERROR — NO CHARACTER", "err")
            state.running = false
            return
        end
        hum.WalkSpeed = 0

        local from = math.clamp(fromCP or 1, 1, #CP)

        for i = from, #CP do
            if state.stopped then
                setStatus("■ STOPPED AT CP" .. i, "err")
                state.running = false
                if onDone then onDone(false) end
                return
            end

            if onCP then onCP(i) end

            local ok, found = Nav.processCP(i, setStatus, setProgress)
            if not ok then
                state.running = false
                if onDone then onDone(false) end
                return
            end
            if found then
                state.running = false
                if onDone then onDone(true) end
                return
            end
            -- No target → continue to next CP
        end

        -- All CP scanned, stop automatically
        setStatus("✓ ALL " .. #CP .. " CP SCANNED — DONE", "done")
        notify("Zihan Navigator", "All " .. #CP .. " checkpoints scanned.")
        state.running = false
        if onDone then onDone(false) end
    end)
end

--- Manual: teleport to specific CP + scan
function Nav.runManual(idx, setStatus, setProgress, onCP)
    if state.running then return end
    state.running = true
    state.stopped = false

    task.spawn(function()
        local _, _, hum = Nav.getChar()
        if not hum then
            setStatus("ERROR — NO CHARACTER", "err")
            state.running = false
            return
        end
        hum.WalkSpeed = 0

        if onCP then onCP(idx) end
        local ok, found = Nav.processCP(idx, setStatus, setProgress)
        if not found and ok then
            setStatus("CP " .. idx .. " — NO TARGET", "idle")
        end

        hum.WalkSpeed = 16
        state.running = false
    end)
end

--- Claim: scan at last CP position
function Nav.runClaim(setStatus, setProgress)
    if state.running then return end
    state.running = true
    state.stopped = false

    task.spawn(function()
        local _, hrp, hum = Nav.getChar()
        if not hrp then
            setStatus("ERROR — NO CHARACTER", "err")
            state.running = false
            return
        end
        if hum then hum.WalkSpeed = 0 end

        local targetPos = #CP > 0 and CP[#CP] or hrp.Position
        setStatus("CLAIM — TELEPORTING TO LAST CP", "wait")
        setProgress(#CP, #CP)

        Nav.tpTo(targetPos)
        task.wait(0.3)

        if state.stopped then
            state.running = false
            return
        end

        setStatus("CLAIM — SCANNING", "wait")
        local results = Scanner.adaptiveScanMulti(targetPos, function(elapsed)
            setStatus("CLAIM — SCANNING " .. string.format("%.1f", elapsed) .. "s", "wait")
        end)

        if #results > 0 then
            setStatus("⚡ " .. #results .. " TARGET(s) FOUND", "found")
            local fired = Nav.firePrompts(results)
            if fired > 0 then
                setStatus("✓ CLAIMED " .. fired, "done")
                notify("Zihan Navigator", "Claimed " .. fired .. " target(s)!")
            else
                setStatus("CLAIM — FIRE FAILED", "err")
            end
        else
            setStatus("CLAIM — NO TARGET FOUND", "idle")
        end

        if hum then hum.WalkSpeed = 16 end
        state.running = false
    end)
end

-- ════════════════════════════════════════════════════════════
-- GUI — CYBER FUTURISTIC
-- ════════════════════════════════════════════════════════════

local GUI = {}
local R = {} -- refs

--- Helper: create element with stroke + corner in one call
local function el(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Corner" and k ~= "Stroke" and k ~= "Children" then
            pcall(function() inst[k] = v end)
        end
    end
    if props.Corner then
        local c = Instance.new("UICorner")
        c.CornerRadius = type(props.Corner) == "UDim" and props.Corner or UDim.new(0, props.Corner)
        c.Parent = inst
    end
    if props.Stroke then
        local s = Instance.new("UIStroke")
        if type(props.Stroke) == "table" then
            for k, v in pairs(props.Stroke) do s[k] = v end
        else
            s.Color = props.Stroke
        end
        s.Parent = inst
    end
    if props.Children then
        for _, ch in ipairs(props.Children) do ch.Parent = inst end
    end
    return inst
end

--- Status colors map
local STATUS_COL = {
    done  = T.NEON_GREEN,
    err   = T.NEON_RED,
    wait  = T.NEON_YELLOW,
    found = T.NEON_CYAN,
    idle  = T.TXT_MID,
}

function GUI.setStatus(msg, typ)
    if not R.svTxt then return end
    local c = STATUS_COL[typ] or T.TXT_PRI
    R.svTxt.Text = msg
    R.svTxt.TextColor3 = c
    R.svDot.BackgroundColor3 = c
    R.svGlow.BackgroundColor3 = c
end

function GUI.setProgress(cur, total)
    if not R.pFill then return end
    local pct = math.clamp(cur / math.max(total, 1), 0, 1)
    TweenService:Create(R.pFill, TweenInfo.new(0.2), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
    TweenService:Create(R.pGlow, TweenInfo.new(0.2), {Size = UDim2.new(pct, 0, 1, 5)}):Play()
    R.pTxt.Text = cur .. " / " .. total
    R.pTxt.TextColor3 = pct >= 1 and T.NEON_GREEN or pct > 0.5 and T.NEON_YELLOW or T.TXT_DIM
end

function GUI.highlightCP(idx)
    for i, btn in ipairs(R.cpBtns or {}) do
        local active = i == idx
        btn.BackgroundColor3 = active and T.BG_CARD or T.BG_INPUT
        btn.TextColor3 = active and T.NEON_CYAN or T.TXT_DIM
        local s = btn:FindFirstChildOfClass("UIStroke")
        if s then s.Color = active and T.NEON_CYAN or T.BORDER end
    end
    -- Auto-scroll to active CP
    if R.cpBtns[idx] and R.cpScroll then
        task.defer(function()
            local cols = math.floor((R.cpScroll.AbsoluteSize.X - 8) / 41)
            cols = math.max(cols, 1)
            local row = math.floor((idx - 1) / cols)
            local rowH = 29
            R.cpScroll.CanvasPosition = Vector2.new(0, math.max(0, (row - 1) * rowH))
        end)
    end
end

function GUI.setupPinch(container)
    local base = container.Size
    local touches = {}
    local pinching = false
    local initDist, initScale = 0, 1
    local MIN_S, MAX_S = 0.5, 2.5

    local function count() local n = 0; for _ in pairs(touches) do n = n + 1 end; return n end
    local function list() local t = {}; for _, v in pairs(touches) do table.insert(t, v) end; return t end

    UIS.TouchStarted:Connect(function(t, g) if not g then touches[t] = t.Position end end)
    UIS.TouchMoved:Connect(function(t, g)
        if g then return end
        touches[t] = t.Position
        local pts = list()
        if #pts == 2 then
            local d = (pts[1] - pts[2]).Magnitude
            if not pinching then
                pinching = true; initDist = d; initScale = state.guiScale
            elseif initDist > 10 then
                local ns = math.clamp(initScale * (d / initDist), MIN_S, MAX_S)
                state.guiScale = ns
                local nw, nh = base.X.Offset * ns, base.Y.Offset * ns
                local cx = container.Position.X.Offset + container.Size.X.Offset / 2
                local cy = container.Position.Y.Offset + container.Size.Y.Offset / 2
                TweenService:Create(container, TweenInfo.new(0.06), {
                    Size = UDim2.new(0, nw, 0, nh),
                    Position = UDim2.new(0, cx - nw / 2, 0, cy - nh / 2),
                }):Play()
            end
        end
    end)
    UIS.TouchEnded:Connect(function(t, g)
        if not g then touches[t] = nil end
        if count() < 2 then pinching = false; initDist = 0 end
    end)
    UIS.TouchCancelled:Connect(function(t, g)
        if not g then touches[t] = nil end
        if count() < 2 then pinching = false; initDist = 0 end
    end)
end

function GUI.build()
    local sg = Instance.new("ScreenGui")
    sg.Name = "ZihanNavigator"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 9999
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = player.PlayerGui
    R.sg = sg

    -- Outer container (for pinch scaling)
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0, 280, 0, 358)
    container.Position = UDim2.new(0.5, -140, 0.5, -179)
    container.BackgroundTransparency = 1
    container.ZIndex = 10
    container.Parent = sg
    R.container = container

    -- Panel (draggable)
    local panel = el("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = T.BG_PANEL,
        Active = true, Draggable = true, ZIndex = 11,
        Corner = UDim.new(0, 10),
        Stroke = {Color = T.BORDER, Thickness = 1},
    })
    panel.Parent = container
    R.panel = panel

    -- ─── NEON TOP ACCENT ───
    el("Frame", {
        Size = UDim2.new(0.55, 0, 0, 2),
        Position = UDim2.new(0.225, 0, 0, 0),
        BackgroundColor3 = T.NEON_CYAN,
        ZIndex = 15,
        Corner = UDim.new(0, 1),
    }).Parent = panel

    -- Accent glow
    el("Frame", {
        Size = UDim2.new(0.55, 10, 0, 8),
        Position = UDim2.new(0.225, -5, 0, -3),
        BackgroundColor3 = T.NEON_CYAN,
        BackgroundTransparency = 0.82,
        ZIndex = 14,
        Corner = UDim.new(0, 4),
    }).Parent = panel

    -- ─── TITLE BAR ───
    local tb = el("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        Position = UDim2.new(0, 0, 0, 3),
        BackgroundTransparency = 1, ZIndex = 12,
    })
    tb.Parent = panel

    el("TextLabel", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(0, 10, 0.5, -8),
        BackgroundTransparency = 1,
        Text = "◈", TextColor3 = T.NEON_CYAN,
        Font = Enum.Font.GothamBold, TextSize = 11, ZIndex = 13,
    }).Parent = tb

    el("TextLabel", {
        Size = UDim2.new(1, -58, 0, 13),
        Position = UDim2.new(0, 26, 0.5, -8),
        BackgroundTransparency = 1,
        Text = "ZIHAN NAVIGATOR", TextColor3 = T.TXT_PRI,
        Font = Enum.Font.GothamBold, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 13,
    }).Parent = tb

    el("TextLabel", {
        Size = UDim2.new(1, -58, 0, 10),
        Position = UDim2.new(0, 26, 0.5, 5),
        BackgroundTransparency = 1,
        Text = "CYBER EDITION  ·  STREAMING-AWARE",
        TextColor3 = T.TXT_DIM,
        Font = Enum.Font.Gotham, TextSize = 7,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 13,
    }).Parent = tb

    -- Close button
    local xb = el("TextButton", {
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -28, 0.5, -11),
        BackgroundColor3 = T.BG_INPUT,
        Text = "✕", TextColor3 = T.TXT_DIM,
        Font = Enum.Font.GothamBold, TextSize = 9,
        AutoButtonColor = false, ZIndex = 14,
        Corner = 5,
        Stroke = {Color = T.BORDER},
    })
    xb.Parent = tb
    xb.MouseEnter:Connect(function()
        xb.TextColor3 = T.NEON_RED
        xb.UIStroke.Color = T.NEON_RED
    end)
    xb.MouseLeave:Connect(function()
        xb.TextColor3 = T.TXT_DIM
        xb.UIStroke.Color = T.BORDER
    end)
    xb.MouseButton1Click:Connect(function()
        TweenService:Create(panel, TweenInfo.new(0.15), {
            Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1,
        }):Play()
        task.delay(0.16, function() sg:Destroy() end)
    end)

    -- ─── STATUS BAR ───
    local sf = el("Frame", {
        Size = UDim2.new(1, -20, 0, 24),
        Position = UDim2.new(0, 10, 0, 40),
        BackgroundColor3 = T.BG_INPUT, ZIndex = 12,
        Corner = 5, Stroke = {Color = T.BORDER},
    })
    sf.Parent = panel

    R.svDot = el("Frame", {
        Size = UDim2.new(0, 6, 0, 6),
        Position = UDim2.new(0, 8, 0.5, -3),
        BackgroundColor3 = T.NEON_GREEN,
        ZIndex = 13, Corner = UDim.new(1, 0),
    })
    R.svDot.Parent = sf

    R.svGlow = el("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 3, 0.5, -8),
        BackgroundColor3 = T.NEON_GREEN,
        BackgroundTransparency = 0.78,
        ZIndex = 12, Corner = UDim.new(1, 0),
    })
    R.svGlow.Parent = sf

    R.svTxt = el("TextLabel", {
        Size = UDim2.new(1, -24, 1, 0),
        Position = UDim2.new(0, 20, 0, 0),
        BackgroundTransparency = 1,
        Text = "READY", TextColor3 = T.NEON_GREEN,
        Font = Enum.Font.GothamBold, TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 13,
    })
    R.svTxt.Parent = sf

    -- ─── PROGRESS BAR ───
    local pf = el("Frame", {
        Size = UDim2.new(1, -20, 0, 14),
        Position = UDim2.new(0, 10, 0, 68),
        BackgroundColor3 = T.BG_DEEP, ZIndex = 12,
        Corner = UDim.new(0, 7), Stroke = {Color = T.BORDER},
    })
    pf.Parent = panel

    R.pGlow = el("Frame", {
        Size = UDim2.new(0, 0, 1, 5),
        Position = UDim2.new(0, 0, 0, -2),
        BackgroundColor3 = T.NEON_CYAN,
        BackgroundTransparency = 0.65,
        ZIndex = 12, Corner = UDim.new(0, 7),
    })
    R.pGlow.Parent = pf

    R.pFill = el("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = T.NEON_CYAN, ZIndex = 13,
        Corner = UDim.new(0, 7),
    })
    R.pFill.Parent = pf

    R.pTxt = el("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "0 / " .. #CP, TextColor3 = T.TXT_DIM,
        Font = Enum.Font.GothamBold, TextSize = 8, ZIndex = 14,
    })
    R.pTxt.Parent = pf

    -- ─── SCAN INFO ───
    el("TextLabel", {
        Size = UDim2.new(1, -20, 0, 14),
        Position = UDim2.new(0, 10, 0, 86),
        BackgroundTransparency = 1,
        Text = "🔍 Radius: 50→100→200  ·  Timeout: 5s  ·  Adaptive",
        TextColor3 = T.TXT_DIM,
        Font = Enum.Font.Gotham, TextSize = 7,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12,
    }).Parent = panel

    -- ─── CP GRID (scrollable) ───
    R.cpScroll = el("ScrollingFrame", {
        Size = UDim2.new(1, -20, 0, 164),
        Position = UDim2.new(0, 10, 0, 104),
        BackgroundColor3 = T.BG_DEEP,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = T.BORDER_HI,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ZIndex = 12, Corner = 6, Stroke = {Color = T.BORDER},
    })
    R.cpScroll.Parent = panel

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0, 38, 0, 26)
    grid.CellPadding = UDim2.new(0, 3, 0, 3)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.Parent = R.cpScroll

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 4)
    pad.PaddingRight = UDim.new(0, 4)
    pad.PaddingTop = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 4)
    pad.Parent = R.cpScroll

    R.cpBtns = {}
    for i = 1, #CP do
        local btn = el("TextButton", {
            Size = UDim2.new(0, 38, 0, 26),
            BackgroundColor3 = T.BG_INPUT,
            Text = "CP" .. i, TextColor3 = T.TXT_DIM,
            Font = Enum.Font.GothamBold, TextSize = 8,
            AutoButtonColor = false, ZIndex = 13,
            Corner = 4, Stroke = {Color = T.BORDER},
        })
        btn.LayoutOrder = i
        btn.Parent = R.cpScroll
        table.insert(R.cpBtns, btn)

        local ci = i
        btn.MouseButton1Click:Connect(function()
            if state.running then return end
            Nav.runManual(ci, GUI.setStatus, GUI.setProgress, GUI.highlightCP)
        end)
        btn.MouseEnter:Connect(function()
            if state.currentCP ~= ci then
                btn.BackgroundColor3 = T.BG_CARD
                btn.UIStroke.Color = T.BORDER_HI
            end
        end)
        btn.MouseLeave:Connect(function()
            if state.currentCP ~= ci then
                btn.BackgroundColor3 = T.BG_INPUT
                btn.UIStroke.Color = T.BORDER
            end
        end)
    end

    grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        R.cpScroll.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 8)
    end)

    -- ─── SEPARATOR ───
    el("Frame", {
        Size = UDim2.new(1, -20, 0, 1),
        Position = UDim2.new(0, 10, 0, 274),
        BackgroundColor3 = T.BORDER, ZIndex = 12,
    }).Parent = panel

    -- ─── ANTI-LAG ROW ───
    local alRow = el("Frame", {
        Size = UDim2.new(1, -20, 0, 22),
        Position = UDim2.new(0, 10, 0, 280),
        BackgroundColor3 = T.BG_INPUT, ZIndex = 12,
        Corner = 5, Stroke = {Color = T.BORDER},
    })
    alRow.Parent = panel

    el("TextLabel", {
        Size = UDim2.new(0.65, 0, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = "◇ ANTI-LAG", TextColor3 = T.TXT_DIM,
        Font = Enum.Font.GothamBold, TextSize = 8,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 13,
    }).Parent = alRow

    local alBtn = el("TextButton", {
        Size = UDim2.new(0, 36, 0, 16),
        Position = UDim2.new(1, -42, 0.5, -8),
        BackgroundColor3 = T.BG_CARD,
        Text = "ON", TextColor3 = T.NEON_GREEN,
        Font = Enum.Font.GothamBold, TextSize = 8,
        AutoButtonColor = false, ZIndex = 13,
        Corner = 4,
        Stroke = {Color = T.NEON_GREEN, Transparency = 0.5},
    })
    alBtn.Parent = alRow

    local alOn = true
    alBtn.MouseButton1Click:Connect(function()
        alOn = not alOn
        if alOn then
            alBtn.Text = "ON"
            alBtn.TextColor3 = T.NEON_GREEN
            alBtn.UIStroke.Color = T.NEON_GREEN
            alBtn.UIStroke.Transparency = 0.5
            AntiLag.apply()
        else
            alBtn.Text = "OFF"
            alBtn.TextColor3 = T.TXT_DIM
            alBtn.UIStroke.Color = T.BORDER
            alBtn.UIStroke.Transparency = 0
            AntiLag.restore()
        end
    end)

    -- ─── ACTION BUTTONS ───
    local BY = 308
    local BH = 34

    -- STOP
    local stopBtn = el("TextButton", {
        Size = UDim2.new(0, 60, 0, BH),
        Position = UDim2.new(0, 10, 0, BY),
        BackgroundColor3 = Color3.fromRGB(28, 8, 14),
        Text = "■ STOP", TextColor3 = T.NEON_RED,
        Font = Enum.Font.GothamBold, TextSize = 9,
        AutoButtonColor = false, ZIndex = 12,
        Corner = 6,
        Stroke = {Color = Color3.fromRGB(80, 20, 30)},
    })
    stopBtn.Parent = panel

    stopBtn.MouseEnter:Connect(function()
        stopBtn.UIStroke.Color = T.NEON_RED
        stopBtn.UIStroke.Transparency = 0.4
    end)
    stopBtn.MouseLeave:Connect(function()
        stopBtn.UIStroke.Color = Color3.fromRGB(80, 20, 30)
        stopBtn.UIStroke.Transparency = 0
    end)
    stopBtn.MouseButton1Click:Connect(function()
        state.stopped = true
        stopBtn.Text = "✓"
        stopBtn.TextColor3 = T.NEON_YELLOW
        task.delay(1.2, function()
            stopBtn.Text = "■ STOP"
            stopBtn.TextColor3 = T.NEON_RED
        end)
    end)

    -- CLAIM
    local claimBtn = el("TextButton", {
        Size = UDim2.new(0, 78, 0, BH),
        Position = UDim2.new(0, 76, 0, BY),
        BackgroundColor3 = Color3.fromRGB(8, 18, 38),
        Text = "⚡ CLAIM", TextColor3 = T.NEON_CYAN,
        Font = Enum.Font.GothamBold, TextSize = 9,
        AutoButtonColor = false, ZIndex = 12,
        Corner = 6,
        Stroke = {Color = Color3.fromRGB(20, 60, 100)},
    })
    claimBtn.Parent = panel

    claimBtn.MouseEnter:Connect(function()
        claimBtn.UIStroke.Color = T.NEON_CYAN
        claimBtn.UIStroke.Transparency = 0.4
    end)
    claimBtn.MouseLeave:Connect(function()
        claimBtn.UIStroke.Color = Color3.fromRGB(20, 60, 100)
        claimBtn.UIStroke.Transparency = 0
    end)
    claimBtn.MouseButton1Click:Connect(function()
        if state.running then return end
        claimBtn.Text = "⏳..."
        claimBtn.TextColor3 = T.NEON_YELLOW
        Nav.runClaim(GUI.setStatus, GUI.setProgress)
        task.spawn(function()
            while state.running do task.wait(0.1) end
            task.wait(0.3)
            claimBtn.Text = "⚡ CLAIM"
            claimBtn.TextColor3 = T.NEON_CYAN
        end)
    end)

    -- AUTO CP
    local autoBtn = el("TextButton", {
        Size = UDim2.new(0, 106, 0, BH),
        Position = UDim2.new(0, 160, 0, BY),
        BackgroundColor3 = T.BG_CARD,
        Text = "▶ AUTO CP", TextColor3 = T.NEON_CYAN,
        Font = Enum.Font.GothamBold, TextSize = 9,
        AutoButtonColor = false, ZIndex = 12,
        Corner = 6,
        Stroke = {Color = T.NEON_CYAN, Transparency = 0.3},
    })
    autoBtn.Parent = panel

    -- Pulsing animation on stroke
    local pulsing = true
    task.spawn(function()
        while sg and sg.Parent do
            if pulsing then
                TweenService:Create(autoBtn.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Transparency = 0.8,
                }):Play()
                task.wait(1)
                if pulsing then
                    TweenService:Create(autoBtn.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                        Transparency = 0.15,
                    }):Play()
                    task.wait(1)
                end
            else
                task.wait(0.3)
            end
        end
    end)

    autoBtn.MouseButton1Click:Connect(function()
        if state.running then return end
        pulsing = false
        autoBtn.UIStroke.Transparency = 0
        autoBtn.UIStroke.Color = T.NEON_YELLOW
        autoBtn.Text = "▶ RUNNING"
        autoBtn.TextColor3 = T.NEON_YELLOW

        Nav.runAuto(1, GUI.setStatus, GUI.setProgress, GUI.highlightCP, function()
            pulsing = true
        end)

        task.spawn(function()
            while state.running do task.wait(0.1) end
            task.wait(0.3)
            pulsing = true
            autoBtn.UIStroke.Color = T.NEON_CYAN
            autoBtn.Text = "▶ AUTO CP"
            autoBtn.TextColor3 = T.NEON_CYAN
        end)
    end)

    -- ─── PINCH ZOOM ───
    GUI.setupPinch(container)

    -- ─── F9 TOGGLE ───
    UIS.InputBegan:Connect(function(inp, gpe)
        if gpe then return end
        if inp.KeyCode == Enum.KeyCode.F9 then
            panel.Visible = not panel.Visible
        end
    end)
end

-- ════════════════════════════════════════════════════════════
-- INIT
-- ════════════════════════════════════════════════════════════

GUI.build()
task.spawn(function()
    task.wait(0.5)
    AntiLag.apply()
end)

print("Zihan Navigator v6 | Cyber Edition | " .. #CP .. " CP | F9 Toggle")
