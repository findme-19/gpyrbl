--[[
  MOUNT ZIHAN v6 — PRODUCTION NAVIGATOR
  BY ALFIAN

  Architecture:
  - Multi-radius progressive scanning (50→100→200)
  - Adaptive wait system (no fixed delays)
  - Streaming-aware design
  - Multi-pass filtering with early exit
  - Mobile + PC friendly GUI
  - Full error handling
]]

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURATION (EASILY EDITABLE)
-- ═══════════════════════════════════════════════════════════════

local CONFIG = {
    -- Title
    TITLE = "YUHU Navigator",
    SUBTITLE = "BY YUHU · AUTO SCAN GOPAY",

    -- Scanning
    SCAN_RADII = {50, 100, 200},
    SCAN_INTERVAL = 0.2,
    SCAN_TIMEOUT = 4,

    -- Navigation
    TP_RETRY_COUNT = 3,
    TP_RETRY_DELAY = 0.15,
    TP_OFFSET_Y = 5,
    SAFE_DISTANCE = 7,

    -- Claim
    MAX_CLAIM_CANDIDATES = 3,
    CLAIM_RETRY_COUNT = 3,
    CLAIM_RETRY_DELAY = 0.1,

    -- Anti-Lag
    MAX_FPS = 15,

    -- Status Messages
    MSG_READY = "READY",
    MSG_TELEPORTING = "TELEPORTING",
    MSG_SCANNING = "SCANNING",
    MSG_FOUND = "GOPAY FOUND",
    MSG_CLAIMING = "CLAIMING",
    MSG_CLAIMED = "CLAIMED",
    MSG_NOT_FOUND = "NO GOPAY",
    MSG_STOPPED = "STOPPED",
    MSG_ERROR = "ERROR",
    MSG_COMPLETE = "ALL CP CHECKED",
    MSG_FINAL = "FINAL CLAIM",

    -- Colors (CYBER FUTURISTIC)
    COLORS = {
        BACKGROUND = Color3.fromRGB(10, 10, 16),
        PANEL = Color3.fromRGB(14, 14, 22),
        HEADER = Color3.fromRGB(8, 8, 14),
        CARD = Color3.fromRGB(18, 18, 28),
        BORDER = Color3.fromRGB(30, 35, 50),
        BORDER_LIGHT = Color3.fromRGB(45, 50, 70),
        ACCENT = Color3.fromRGB(0, 170, 255),
        ACCENT_DIM = Color3.fromRGB(0, 90, 150),
        ACCENT_GLOW = Color3.fromRGB(0, 220, 255),
        SUCCESS = Color3.fromRGB(0, 255, 140),
        ERROR = Color3.fromRGB(255, 65, 65),
        WARNING = Color3.fromRGB(255, 195, 45),
        TEXT_PRIMARY = Color3.fromRGB(215, 220, 235),
        TEXT_SECONDARY = Color3.fromRGB(115, 120, 145),
        TEXT_DIM = Color3.fromRGB(65, 70, 90),
        BTN_STOP_BG = Color3.fromRGB(38, 10, 10),
        BTN_STOP_BORDER = Color3.fromRGB(75, 22, 22),
        BTN_STOP_HOVER = Color3.fromRGB(55, 16, 16),
        BTN_CLAIM_BG = Color3.fromRGB(8, 28, 48),
        BTN_CLAIM_BORDER = Color3.fromRGB(18, 65, 115),
        BTN_CLAIM_HOVER = Color3.fromRGB(12, 38, 62),
        BTN_START_BG = Color3.fromRGB(0, 130, 210),
        BTN_START_HOVER = Color3.fromRGB(0, 155, 245),
        BTN_START_RUNNING = Color3.fromRGB(0, 80, 130),
        CP_ACTIVE_BG = Color3.fromRGB(22, 32, 52),
        CP_ACTIVE_BORDER = Color3.fromRGB(0, 110, 180),
        CP_INACTIVE_BG = Color3.fromRGB(16, 16, 26),
        CP_HOVER_BG = Color3.fromRGB(24, 24, 38),
    },

    -- GUI Sizing
    GUI_WIDTH = 276,
    GUI_HEIGHT = 330,
}

-- ═══════════════════════════════════════════════════════════════
-- REQUIRED CONSTANTS (DO NOT REMOVE)
-- ═══════════════════════════════════════════════════════════════

local KEYWORDS = {"claim", "voucher", "gopay", "redemption", "klaim", "reward"}

local KNOWN_OBJ = {
    "RedemptionPointBasepart",
    "Gopay",
    "GopayPoint",
    "Primary",
    "VoucherPoint",
    "ClaimPoint",
    "Part",
}

-- ═══════════════════════════════════════════════════════════════
-- CHECKPOINT DATA (EDIT THIS FOR DIFFERENT MAPS)
-- ═══════════════════════════════════════════════════════════════

local CP_LIST = {
    Vector3.new(-312.329, 654.005, -952.673),
    Vector3.new(4356.271, 2238.856, -9533.901),
}

local CLAIM_POINT = nil -- Set to Vector3 for final claim, or nil to skip

-- ═══════════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════
-- STATE MANAGEMENT
-- ═══════════════════════════════════════════════════════════════

local State = {
    running = false,
    stopped = false,
    currentCP = 0,
    guiElements = {},
    cpButtons = {},
    pulsing = true,
    antiLagOn = false,
    screenGui = nil,
}

-- ═══════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

local function hasKeyword(text)
    if type(text) ~= "string" or text == "" then
        return false
    end
    local lower = text:lower()
    for _, kw in ipairs(KEYWORDS) do
        if lower:find(kw, 1, true) then
            return true
        end
    end
    return false
end

local function isKnownObject(name)
    if type(name) ~= "string" or name == "" then
        return false
    end
    local lower = name:lower()
    for _, known in ipairs(KNOWN_OBJ) do
        if lower == known:lower() then
            return true
        end
    end
    -- Partial match for variations
    return lower:find("redemption")
        or lower:find("gopay")
        or lower:find("voucher")
        or lower:find("claim")
end

local function getObjectPosition(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then
        return obj.Position
    end
    if obj:IsA("Model") then
        local pp = obj.PrimaryPart
        if pp then return pp.Position end
        local part = obj:FindFirstChildWhichIsA("BasePart")
        if part then return part.Position end
    end
    if obj:IsA("Attachment") then
        return obj.WorldPosition
    end
    return nil
end

local function safeFirePrompt(prompt)
    if not prompt or not prompt.Parent then
        return false
    end
    local ok, err = pcall(function()
        fireproximityprompt(prompt)
    end)
    return ok
end

local function sendNotification(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "Zihan",
            Text = text or "",
            Duration = duration or 4,
        })
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI-LAG MODULE
-- ═══════════════════════════════════════════════════════════════

local AntiLag = {}

function AntiLag.apply()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
    pcall(function()
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
    end)
    pcall(function()
        workspace.GlobalShadows = false
    end)
    pcall(function()
        settings().Rendering.MaxFrameRate = CONFIG.MAX_FPS
    end)
    pcall(function()
        local lighting = game:GetService("Lighting")
        lighting.GlobalShadows = false
        lighting.Brightness = 1
        lighting.EnvironmentDiffuseScale = 0
        lighting.EnvironmentSpecularScale = 0
        lighting.FogEnd = 100000

        for _, child in ipairs(lighting:GetChildren()) do
            if child:IsA("PostEffect") then
                child.Enabled = false
            end
        end
    end)
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Fire")
                or obj:IsA("Smoke") or obj:IsA("Sparkles")
                or obj:IsA("Beam") then
                obj.Enabled = false
            end
            if obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = 1
            end
        end
    end)
    State.antiLagOn = true
end

function AntiLag.remove()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
    end)
    pcall(function()
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Automatic
    end)
    pcall(function()
        settings().Rendering.MaxFrameRate = 999
    end)
    State.antiLagOn = false
end

function AntiLag.toggle()
    if State.antiLagOn then
        AntiLag.remove()
    else
        AntiLag.apply()
    end
    return State.antiLagOn
end

-- ═══════════════════════════════════════════════════════════════
-- SCANNER MODULE (MULTI-RADIUS + MULTI-PASS + FALLBACK)
-- ═══════════════════════════════════════════════════════════════

local Scanner = {}

--- Extract prompt info from a single BasePart
---@param part BasePart
---@param centerPos Vector3
---@param seen table
---@return table|nil
local function extractPromptFromPart(part, centerPos, seen)
    local pos = part.Position
    local dist = (pos - centerPos).Magnitude

    -- Check the part itself for ProximityPrompt
    local prompt = part:FindFirstChildOfClass("ProximityPrompt")
    if prompt and not seen[prompt] then
        local actionText = prompt.ActionText or ""
        local objectText = prompt.ObjectText or ""
        local parentName = part.Parent and part.Parent.Name or ""

        if hasKeyword(actionText) or hasKeyword(objectText)
            or hasKeyword(parentName) or isKnownObject(parentName) then
            seen[prompt] = true
            return {
                prompt = prompt,
                position = pos,
                label = actionText ~= "" and actionText or parentName,
                distance = dist,
                source = "prompt_direct",
            }
        end
    end

    -- Check children for ProximityPrompt
    for _, child in ipairs(part:GetChildren()) do
        if child:IsA("ProximityPrompt") and not seen[child] then
            local actionText = child.ActionText or ""
            local objectText = child.ObjectText or ""

            if hasKeyword(actionText) or hasKeyword(objectText) then
                seen[child] = true
                return {
                    prompt = child,
                    position = pos,
                    label = actionText ~= "" and actionText or part.Name,
                    distance = dist,
                    source = "prompt_child",
                }
            end
        end
    end

    return nil
end

--- Multi-pass filter on a set of BaseParts
---@param parts table<BasePart>
---@param centerPos Vector3
---@return table
function Scanner.filterParts(parts, centerPos)
    local seen = {}
    local results = {}

    -- ═══ PASS 1: Direct ProximityPrompt detection (HIGHEST PRIORITY) ═══
    for _, part in ipairs(parts) do
        if not part:IsA("BasePart") then continue end
        local result = extractPromptFromPart(part, centerPos, seen)
        if result then
            table.insert(results, result)
        end
    end

    if #results > 0 then
        table.sort(results, function(a, b) return a.distance < b.distance end)
        return results
    end

    -- ═══ PASS 2: Known object names ═══
    for _, part in ipairs(parts) do
        if not part:IsA("BasePart") then continue end

        -- Check part name
        if isKnownObject(part.Name) then
            local prompt = part:FindFirstChildOfClass("ProximityPrompt")
            if prompt and not seen[prompt] then
                seen[prompt] = true
                table.insert(results, {
                    prompt = prompt,
                    position = part.Position,
                    label = part.Name,
                    distance = (part.Position - centerPos).Magnitude,
                    source = "name_part",
                })
            end
        end

        -- Check parent model name
        local parent = part.Parent
        if parent and parent:IsA("Model") and isKnownObject(parent.Name) then
            local prompt = part:FindFirstChildOfClass("ProximityPrompt")
            if prompt and not seen[prompt] then
                seen[prompt] = true
                table.insert(results, {
                    prompt = prompt,
                    position = part.Position,
                    label = parent.Name,
                    distance = (part.Position - centerPos).Magnitude,
                    source = "name_model",
                })
            end
        end
    end

    if #results > 0 then
        table.sort(results, function(a, b) return a.distance < b.distance end)
        return results
    end

    -- ═══ PASS 3: GUI text (BillboardGui / SurfaceGui) ═══
    for _, part in ipairs(parts) do
        if not part:IsA("BasePart") then continue end

        for _, guiChild in ipairs(part:GetChildren()) do
            if guiChild:IsA("BillboardGui") or guiChild:IsA("SurfaceGui") then
                local found = false
                for _, textElem in ipairs(guiChild:GetDescendants()) do
                    if (textElem:IsA("TextLabel") or textElem:IsA("TextButton"))
                        and hasKeyword(textElem.Text) then
                        local prompt = part:FindFirstChildOfClass("ProximityPrompt")
                        if prompt and not seen[prompt] then
                            seen[prompt] = true
                            table.insert(results, {
                                prompt = prompt,
                                position = part.Position,
                                label = textElem.Text,
                                distance = (part.Position - centerPos).Magnitude,
                                source = "gui_text",
                            })
                        end
                        found = true
                        break
                    end
                end
                if found then break end
            end
        end
    end

    if #results > 0 then
        table.sort(results, function(a, b) return a.distance < b.distance end)
    end

    return results
end

--- Fallback scanner using GetDescendants (ONLY when primary fails)
---@param centerPos Vector3
---@param maxRadius number
---@return table
function Scanner.fallbackScan(centerPos, maxRadius)
    local seen = {}
    local results = {}

    local descendants
    local ok = pcall(function()
        descendants = workspace:GetDescendants()
    end)
    if not ok or not descendants then
        return results
    end

    for _, obj in ipairs(descendants) do
        local pos = getObjectPosition(obj)
        if not pos then continue end

        local dist = (pos - centerPos).Magnitude
        if dist > maxRadius then continue end

        -- PASS 1: Direct ProximityPrompt on any object
        if obj:IsA("ProximityPrompt") and not seen[obj] then
            local actionText = obj.ActionText or ""
            local objectText = obj.ObjectText or ""
            local parentName = obj.Parent and obj.Parent.Name or ""

            if hasKeyword(actionText) or hasKeyword(objectText)
                or hasKeyword(parentName) or isKnownObject(parentName) then
                seen[obj] = true
                table.insert(results, {
                    prompt = obj,
                    position = pos,
                    label = actionText ~= "" and actionText or parentName,
                    distance = dist,
                    source = "fallback_prompt",
                })
                continue
            end
        end

        -- PASS 2: Known objects (BasePart or Model)
        if (obj:IsA("BasePart") or obj:IsA("Model")) and isKnownObject(obj.Name) then
            local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
            if prompt and not seen[prompt] then
                seen[prompt] = true
                table.insert(results, {
                    prompt = prompt,
                    position = pos,
                    label = obj.Name,
                    distance = dist,
                    source = "fallback_name",
                })
            end
            continue
        end

        -- PASS 3: GUI text
        if obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
            local parent = obj.Parent
            if parent then
                for _, textElem in ipairs(obj:GetDescendants()) do
                    if (textElem:IsA("TextLabel") or textElem:IsA("TextButton"))
                        and hasKeyword(textElem.Text) then
                        local prompt = parent:FindFirstChildOfClass("ProximityPrompt")
                        if prompt and not seen[prompt] then
                            seen[prompt] = true
                            local pPos = getObjectPosition(parent)
                            table.insert(results, {
                                prompt = prompt,
                                position = pPos or pos,
                                label = textElem.Text,
                                distance = pPos and (pPos - centerPos).Magnitude or dist,
                                source = "fallback_gui",
                            })
                        end
                        break
                    end
                end
            end
        end
    end

    table.sort(results, function(a, b) return a.distance < b.distance end)
    return results
end

--- Main scan entry point with multi-radius progression
---@param centerPos Vector3
---@return table results, boolean usedFallback
function Scanner.scan(centerPos)
    -- PRIMARY METHOD: GetPartBoundsInRadius with progressive radii
    for _, radius in ipairs(CONFIG.SCAN_RADII) do
        local parts = {}
        local ok = pcall(function()
            parts = workspace:GetPartBoundsInRadius(centerPos, radius)
        end)

        if ok and parts and #parts > 0 then
            local results = Scanner.filterParts(parts, centerPos)
            if #results > 0 then
                return results, false
            end
        end
    end

    -- FALLBACK METHOD: GetDescendants (only after all radii fail)
    local maxRadius = CONFIG.SCAN_RADII[#CONFIG.SCAN_RADII]
    local results = Scanner.fallbackScan(centerPos, maxRadius)
    return results, true
end

-- ═══════════════════════════════════════════════════════════════
-- CLAIM MODULE
-- ═══════════════════════════════════════════════════════════════

local Claimer = {}

--- Attempt to claim a single target with retries and alternative positioning
---@param target table
---@param hrp BasePart
---@return boolean success
local function claimSingleTarget(target, hrp)
    local targetPos = target.position
    local dir = (hrp.Position - targetPos)
    local dirMag = dir.Magnitude

    -- Calculate safe position (offset from target)
    local offset = dirMag > 0.1
        and dir.Unit * CONFIG.SAFE_DISTANCE
        or Vector3.new(0, 0, CONFIG.SAFE_DISTANCE)
    local safePos = targetPos + offset + Vector3.new(0, CONFIG.TP_OFFSET_Y, 0)

    -- Move to safe position
    hrp.CFrame = CFrame.new(safePos)
    task.wait(0.15)

    -- Retry firing the prompt
    for attempt = 1, CONFIG.CLAIM_RETRY_COUNT do
        if State.stopped then return false end
        if safeFirePrompt(target.prompt) then
            return true
        end
        task.wait(CONFIG.CLAIM_RETRY_DELAY)
    end

    -- Alternative approach: get closer
    local approachDir = (targetPos - hrp.Position)
    if approachDir.Magnitude > 0 then
        hrp.CFrame = CFrame.new(hrp.Position + approachDir.Unit * 3)
        task.wait(0.12)
        if safeFirePrompt(target.prompt) then
            return true
        end
    end

    -- Final attempt: directly at position + small Y offset
    hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
    task.wait(0.1)
    if safeFirePrompt(target.prompt) then
        return true
    end

    return false
end

--- Claim from a list of candidates (tries multiple if needed)
---@param results table
---@param hrp BasePart
---@return number claimedCount
function Claimer.claim(results, hrp)
    if not results or #results == 0 then
        return 0
    end

    local maxCandidates = math.min(#results, CONFIG.MAX_CLAIM_CANDIDATES)
    local claimedCount = 0

    for i = 1, maxCandidates do
        if State.stopped then break end

        local target = results[i]
        if not target.prompt or not target.prompt.Parent then
            continue
        end

        local success = claimSingleTarget(target, hrp)
        if success then
            claimedCount = claimedCount + 1
            -- Found a working target, no need to try more
            break
        end
    end

    return claimedCount
end

-- ═══════════════════════════════════════════════════════════════
-- NAVIGATION MODULE
-- ═══════════════════════════════════════════════════════════════

local Navigator = {}

--- Teleport to a position with retries
---@param targetPos Vector3
---@param hrp BasePart
---@return boolean success
function Navigator.teleportTo(targetPos, hrp)
    for attempt = 1, CONFIG.TP_RETRY_COUNT do
        if State.stopped then return false end

        local offset = Vector3.new(0, CONFIG.TP_OFFSET_Y, 0)
        hrp.CFrame = CFrame.new(targetPos + offset)
        task.wait(CONFIG.TP_RETRY_DELAY)

        if (hrp.Position - targetPos).Magnitude < 25 then
            return true
        end
    end
    return false
end

--- Adaptive scan: poll until found or timeout
---@param centerPos Vector3
---@return table results, boolean usedFallback
function Navigator.adaptiveScan(centerPos)
    local startTime = tick()

    while not State.stopped do
        local elapsed = tick() - startTime
        if elapsed > CONFIG.SCAN_TIMEOUT then
            break
        end

        local results, usedFallback = Scanner.scan(centerPos)
        if results and #results > 0 then
            return results, usedFallback
        end

        task.wait(CONFIG.SCAN_INTERVAL)
    end

    return {}, false
end

--- Process a single checkpoint (teleport + scan + optional claim)
---@param idx number
---@param hrp BasePart
---@param hum Humanoid
---@param withScan boolean
---@return boolean ok, boolean found
function Navigator.processCP(idx, hrp, hum, withScan)
    local cp = CP_LIST[idx]
    if not cp then return false, false end

    State.currentCP = idx
    Navigator.updateHighlight(idx)
    Navigator.updateStatus(CONFIG.MSG_TELEPORTING .. " CP" .. idx .. "/" .. #CP_LIST, "warning")
    Navigator.updateProgress(idx, #CP_LIST)

    -- Teleport
    local tpOk = Navigator.teleportTo(cp, hrp)
    if not tpOk then
        Navigator.updateStatus(CONFIG.MSG_ERROR .. " (TP FAIL)", "error")
        return false, false
    end

    if not withScan then
        return true, false
    end

    if State.stopped then return false, false end

    -- Adaptive scan (replaces fixed delay)
    Navigator.updateStatus(CONFIG.MSG_SCANNING .. " CP" .. idx, "scanning")
    local results = Navigator.adaptiveScan(cp)

    if State.stopped then return false, false end

    if results and #results > 0 then
        local dist = math.floor(results[1].distance)
        Navigator.updateStatus(CONFIG.MSG_FOUND .. " CP" .. idx .. " (" .. dist .. "s)", "found")

        if hum then hum.WalkSpeed = 16 end
        task.wait(0.1)

        Navigator.updateStatus(CONFIG.MSG_CLAIMING .. "...", "claiming")
        local claimed = Claimer.claim(results, hrp)

        if claimed > 0 then
            Navigator.updateStatus(CONFIG.MSG_CLAIMED .. " @ CP" .. idx, "success")
            sendNotification("Yuhu", "GoPay claimed at CP" .. idx .. "!", 5)
            return true, true
        end

        -- Claim failed despite finding target
        Navigator.updateStatus("CLAIM FAIL CP" .. idx, "error")
        task.wait(0.3)
        return true, false
    end

    return true, false
end

--- Run final claim sequence (if CLAIM_POINT is set)
---@param hrp BasePart
---@param hum Humanoid
function Navigator.runFinalClaim(hrp, hum)
    if not CLAIM_POINT then
        Navigator.updateStatus(CONFIG.MSG_COMPLETE, "success")
        sendNotification("Yuhu", "All checkpoints scanned.", 4)
        return
    end

    Navigator.updateStatus(CONFIG.MSG_FINAL, "warning")
    if hum then hum.WalkSpeed = 0 end

    Navigator.teleportTo(CLAIM_POINT, hrp)
    task.wait(0.3)

    if State.stopped then return end

    if hum then hum.WalkSpeed = 16 end
    task.wait(0.1)

    Navigator.updateStatus(CONFIG.MSG_SCANNING, "scanning")
    local results = Navigator.adaptiveScan(CLAIM_POINT)

    if results and #results > 0 then
        Navigator.updateStatus(CONFIG.MSG_CLAIMING, "claiming")
        local claimed = Claimer.claim(results, hrp)
        if claimed > 0 then
            Navigator.updateStatus(CONFIG.MSG_CLAIMED, "success")
            sendNotification("Yuhu", "Final claim successful!", 4)
            return
        end
    end

    -- Jump fallback
    if hum then hum.Jump = true end
    task.wait(0.15)

    local r2 = Navigator.adaptiveScan(CLAIM_POINT)
    if r2 and #r2 > 0 then
        Claimer.claim(r2, hrp)
    end

    Navigator.updateStatus(CONFIG.MSG_COMPLETE, "success")
    sendNotification("Yuhu", "Done! Claim voucher manually if needed.", 4)
end

--- Run auto CP sequence from a starting index
---@param fromIdx number
function Navigator.runAutoCP(fromIdx)
    if State.running then return end
    State.running = true
    State.stopped = false

    task.spawn(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 10)
        if not hrp then
            Navigator.updateStatus(CONFIG.MSG_ERROR .. " (NO HRP)", "error")
            State.running = false
            return
        end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 0 end

        local startIdx = math.clamp(fromIdx or 1, 1, #CP_LIST)

        for i = startIdx, #CP_LIST do
            if State.stopped then
                Navigator.updateStatus(CONFIG.MSG_STOPPED, "error")
                State.running = false
                return
            end

            local ok, found = Navigator.processCP(i, hrp, hum, true)
            if not ok then
                State.running = false
                return
            end
            -- If found, stop entire sequence
            if found then
                State.running = false
                return
            end
            -- Not found at this CP, continue to next
        end

        -- All CPs checked without finding GoPay
        if not State.stopped then
            Navigator.runFinalClaim(hrp, hum)
        end

        State.running = false
    end)
end

--- Run claim-only mode (skip CP scanning)
function Navigator.runClaimOnly()
    if State.running then return end
    State.running = true
    State.stopped = false

    task.spawn(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 10)
        if not hrp then
            Navigator.updateStatus(CONFIG.MSG_ERROR .. " (NO HRP)", "error")
            State.running = false
            return
        end

        local hum = char:FindFirstChildOfClass("Humanoid")
        Navigator.runFinalClaim(hrp, hum)
        State.running = false
    end)
end

--- Go to a specific CP manually
---@param idx number
function Navigator.runGotoCPManual(idx)
    if State.running then return end
    State.running = true
    State.stopped = false

    task.spawn(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 10)
        if not hrp then
            Navigator.updateStatus(CONFIG.MSG_ERROR .. " (NO HRP)", "error")
            State.running = false
            return
        end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 0 end

        local ok, found = Navigator.processCP(idx, hrp, hum, true)

        if not found then
            Navigator.updateStatus("CP" .. idx .. " — " .. CONFIG.MSG_NOT_FOUND, "success")
        end

        if hum then hum.WalkSpeed = 16 end
        State.running = false
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- GUI MODULE (CYBER FUTURISTIC)
-- ═══════════════════════════════════════════════════════════════

local GUI = {}

function GUI.createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = parent
    return corner
end

function GUI.createStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or CONFIG.COLORS.BORDER
    stroke.Thickness = thickness or 1
    stroke.Parent = parent
    return stroke
end

function GUI.createLabel(parent, props)
    local label = Instance.new("TextLabel")
    label.Size = props.size or UDim2.new(1, 0, 0, 14)
    label.Position = props.position or UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = props.text or ""
    label.TextColor3 = props.color or CONFIG.COLORS.TEXT_PRIMARY
    label.Font = props.font or Enum.Font.GothamBold
    label.TextSize = props.fontSize or 10
    label.TextXAlignment = props.xAlign or Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.ZIndex = props.zIndex or 13
    label.Parent = parent
    return label
end

function GUI.tweenProperty(element, property, target, duration)
    if not element or not element.Parent then return nil end
    local tween = TweenService:Create(
        element,
        TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {[property] = target}
    )
    tween:Play()
    return tween
end

--- Update status text and color
function Navigator.updateStatus(msg, statusType)
    local el = State.guiElements
    if not el.statusLabel then return end

    el.statusLabel.Text = msg

    local colorMap = {
        success = CONFIG.COLORS.SUCCESS,
        error = CONFIG.COLORS.ERROR,
        warning = CONFIG.COLORS.WARNING,
        found = CONFIG.COLORS.ACCENT_GLOW,
        scanning = CONFIG.COLORS.ACCENT,
        claiming = CONFIG.COLORS.ACCENT,
        ready = CONFIG.COLORS.SUCCESS,
    }

    local col = colorMap[statusType] or CONFIG.COLORS.TEXT_PRIMARY
    GUI.tweenProperty(el.statusLabel, "TextColor3", col, 0.15)

    if el.statusDot then
        GUI.tweenProperty(el.statusDot, "BackgroundColor3", col, 0.15)
    end
end

--- Update progress bar
function Navigator.updateProgress(current, total)
    local el = State.guiElements
    if not el.progressFill then return end

    local pct = math.clamp(current / total, 0, 1)
    GUI.tweenProperty(el.progressFill, "Size", UDim2.new(pct, 0, 1, 0), 0.25)

    if el.progressText then
        el.progressText.Text = current .. " / " .. total
        local pCol = pct >= 1 and CONFIG.COLORS.SUCCESS
            or pct > 0.5 and CONFIG.COLORS.WARNING
            or CONFIG.COLORS.TEXT_DIM
        GUI.tweenProperty(el.progressText, "TextColor3", pCol, 0.15)
    end
end

--- Highlight active CP in grid
function Navigator.updateHighlight(idx)
    for i, btn in ipairs(State.cpButtons) do
        local active = (i == idx)
        local bgTarget = active and CONFIG.COLORS.CP_ACTIVE_BG or CONFIG.COLORS.CP_INACTIVE_BG
        local txtTarget = active and CONFIG.COLORS.TEXT_PRIMARY or CONFIG.COLORS.TEXT_DIM
        local brdTarget = active and CONFIG.COLORS.CP_ACTIVE_BORDER or CONFIG.COLORS.BORDER

        GUI.tweenProperty(btn, "BackgroundColor3", bgTarget, 0.12)
        GUI.tweenProperty(btn, "TextColor3", txtTarget, 0.12)

        local stroke = btn:FindFirstChildOfClass("UIStroke")
        if stroke then
            GUI.tweenProperty(stroke, "Color", brdTarget, 0.12)
        end
    end

    -- Auto-scroll to active CP button
    if State.cpButtons[idx] then
        task.defer(function()
            local btn = State.cpButtons[idx]
            local scroll = btn.Parent
            if not scroll or not scroll:IsA("ScrollingFrame") then return end

            local btnAbsY = btn.AbsolutePosition.Y
            local scrollAbsY = scroll.AbsolutePosition.Y
            local relativeY = btnAbsY - scrollAbsY
            local viewH = scroll.AbsoluteSize.Y

            if relativeY < 0 or relativeY > viewH - 30 then
                local cellH = 26 + 3
                local cols = math.max(1, math.floor((scroll.AbsoluteSize.X - 8) / (38 + 3)))
                local row = math.floor((idx - 1) / cols)
                scroll.CanvasPosition = Vector2.new(0, math.max(0, (row - 1) * cellH))
            end
        end)
    end
end

--- Build the entire GUI
function GUI.build()
    -- Remove existing
    pcall(function()
        for _, g in ipairs(player.PlayerGui:GetChildren()) do
            if g.Name == "ZihanV6" then g:Destroy() end
        end
    end)

    -- ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ZihanV6"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 9999
    screenGui.IgnoreGuiInset = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = player.PlayerGui
    State.screenGui = screenGui

    -- ═══ MAIN PANEL ═══
    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, CONFIG.GUI_WIDTH, 0, CONFIG.GUI_HEIGHT)
    panel.Position = UDim2.new(0.5, -CONFIG.GUI_WIDTH / 2, 0.5, -CONFIG.GUI_HEIGHT / 2)
    panel.BackgroundColor3 = CONFIG.COLORS.PANEL
    panel.BorderSizePixel = 0
    panel.Active = true
    panel.Draggable = true
    panel.ZIndex = 10
    panel.Parent = screenGui

    GUI.createCorner(panel, 10)
    GUI.createStroke(panel, CONFIG.COLORS.BORDER, 1)

    -- Top accent line
    local accentLine = Instance.new("Frame")
    accentLine.Size = UDim2.new(0.5, 0, 0, 2)
    accentLine.Position = UDim2.new(0.25, 0, 0, 0)
    accentLine.BackgroundColor3 = CONFIG.COLORS.ACCENT
    accentLine.BorderSizePixel = 0
    accentLine.ZIndex = 15
    GUI.createCorner(accentLine, 1)
    accentLine.Parent = panel

    -- ═══ HEADER (h=40) ═══
    local headerH = 40
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, headerH)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = CONFIG.COLORS.HEADER
    header.BorderSizePixel = 0
    header.ZIndex = 11
    GUI.createCorner(header, 10)
    -- Bottom corner fix
    local headerBottom = Instance.new("Frame")
    headerBottom.Size = UDim2.new(1, 0, 0, 6)
    headerBottom.Position = UDim2.new(0, 0, 1, -6)
    headerBottom.BackgroundColor3 = CONFIG.COLORS.HEADER
    headerBottom.BorderSizePixel = 0
    headerBottom.ZIndex = 11
    headerBottom.Parent = header
    -- Separator
    local headerSep = Instance.new("Frame")
    headerSep.Size = UDim2.new(1, 0, 0, 1)
    headerSep.Position = UDim2.new(0, 0, 1, -1)
    headerSep.BackgroundColor3 = CONFIG.COLORS.BORDER
    headerSep.BorderSizePixel = 0
    headerSep.ZIndex = 12
    headerSep.Parent = header

    -- Title
    GUI.createLabel(header, {
        size = UDim2.new(1, -42, 0, 15),
        position = UDim2.new(0, 11, 0, 7),
        text = CONFIG.TITLE,
        color = CONFIG.COLORS.TEXT_PRIMARY,
        fontSize = 11,
        zIndex = 13,
    })

    -- Subtitle
    GUI.createLabel(header, {
        size = UDim2.new(1, -42, 0, 11),
        position = UDim2.new(0, 11, 0, 22),
        text = CONFIG.SUBTITLE,
        color = CONFIG.COLORS.TEXT_DIM,
        font = Enum.Font.Gotham,
        fontSize = 7,
        zIndex = 13,
    })

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Position = UDim2.new(1, -29, 0, 8)
    closeBtn.BackgroundColor3 = CONFIG.COLORS.CARD
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = CONFIG.COLORS.TEXT_DIM
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 10
    closeBtn.BorderSizePixel = 0
    closeBtn.ZIndex = 14
    closeBtn.AutoButtonColor = false
    GUI.createCorner(closeBtn, 5)
    GUI.createStroke(closeBtn, CONFIG.COLORS.BORDER)
    closeBtn.Parent = header

    closeBtn.MouseEnter:Connect(function()
        GUI.tweenProperty(closeBtn, "TextColor3", CONFIG.COLORS.ERROR, 0.1)
        GUI.tweenProperty(closeBtn, "BackgroundColor3", CONFIG.COLORS.BTN_STOP_BG, 0.1)
    end)
    closeBtn.MouseLeave:Connect(function()
        GUI.tweenProperty(closeBtn, "TextColor3", CONFIG.COLORS.TEXT_DIM, 0.1)
        GUI.tweenProperty(closeBtn, "BackgroundColor3", CONFIG.COLORS.CARD, 0.1)
    end)
    closeBtn.MouseButton1Click:Connect(function()
        State.pulsing = false
        TweenService:Create(panel, TweenInfo.new(0.15), {
            Size = UDim2.new(0, CONFIG.GUI_WIDTH, 0, 0),
        }):Play()
        task.delay(0.16, function()
            if screenGui and screenGui.Parent then
                screenGui:Destroy()
            end
        end)
    end)

    -- ═══ STATUS BAR (y=46, h=22) ═══
    local statusY = headerH + 6
    local statusH = 22
    local statusBar = Instance.new("Frame")
    statusBar.Size = UDim2.new(1, -18, 0, statusH)
    statusBar.Position = UDim2.new(0, 9, 0, statusY)
    statusBar.BackgroundColor3 = CONFIG.COLORS.CARD
    statusBar.BorderSizePixel = 0
    statusBar.ZIndex = 12
    GUI.createCorner(statusBar, 5)
    GUI.createStroke(statusBar, CONFIG.COLORS.BORDER)
    statusBar.Parent = panel

    -- Status dot
    local statusDot = Instance.new("Frame")
    statusDot.Size = UDim2.new(0, 6, 0, 6)
    statusDot.Position = UDim2.new(0, 7, 0.5, -3)
    statusDot.BackgroundColor3 = CONFIG.COLORS.SUCCESS
    statusDot.BorderSizePixel = 0
    statusDot.ZIndex = 13
    GUI.createCorner(statusDot, 3)
    statusDot.Parent = statusBar

    -- Status label
    local statusLabel = GUI.createLabel(statusBar, {
        size = UDim2.new(1, -22, 1, 0),
        position = UDim2.new(0, 18, 0, 0),
        text = CONFIG.MSG_READY,
        color = CONFIG.COLORS.SUCCESS,
        fontSize = 9,
        zIndex = 13,
    })
    State.guiElements.statusDot = statusDot
    State.guiElements.statusLabel = statusLabel

    -- ═══ PROGRESS BAR (y=72, h=14) ═══
    local progressY = statusY + statusH + 4
    local progressH = 14
    local progressBg = Instance.new("Frame")
    progressBg.Size = UDim2.new(1, -18, 0, progressH)
    progressBg.Position = UDim2.new(0, 9, 0, progressY)
    progressBg.BackgroundColor3 = CONFIG.COLORS.CARD
    progressBg.BorderSizePixel = 0
    progressBg.ZIndex = 12
    GUI.createCorner(progressBg, 4)
    GUI.createStroke(progressBg, CONFIG.COLORS.BORDER)
    progressBg.Parent = panel

    local progressFill = Instance.new("Frame")
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = CONFIG.COLORS.ACCENT
    progressFill.BorderSizePixel = 0
    progressFill.ZIndex = 13
    GUI.createCorner(progressFill, 3)
    progressFill.Parent = progressBg

    local progressText = Instance.new("TextLabel")
    progressText.Size = UDim2.new(1, 0, 1, 0)
    progressText.BackgroundTransparency = 1
    progressText.Text = "0 / " .. #CP_LIST
    progressText.TextColor3 = CONFIG.COLORS.TEXT_DIM
    progressText.Font = Enum.Font.GothamBold
    progressText.TextSize = 8
    progressText.TextXAlignment = Enum.TextXAlignment.Center
    progressText.ZIndex = 14
    progressText.Parent = progressBg

    State.guiElements.progressFill = progressFill
    State.guiElements.progressText = progressText

    -- ═══ CP GRID (scrollable) ═══
    local gridY = progressY + progressH + 4
    -- Calculate available height: panel height - gridY - bottom section
    local bottomSectionH = 62 -- anti-lag row + buttons + padding
    local gridH = math.max(50, CONFIG.GUI_HEIGHT - gridY - bottomSectionH)

    local cpScroll = Instance.new("ScrollingFrame")
    cpScroll.Size = UDim2.new(1, -18, 0, gridH)
    cpScroll.Position = UDim2.new(0, 9, 0, gridY)
    cpScroll.BackgroundColor3 = CONFIG.COLORS.HEADER
    cpScroll.BorderSizePixel = 0
    cpScroll.ScrollBarThickness = 2
    cpScroll.ScrollBarImageColor3 = CONFIG.COLORS.BORDER_LIGHT
    cpScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    cpScroll.ZIndex = 12
    cpScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    GUI.createCorner(cpScroll, 6)
    GUI.createStroke(cpScroll, CONFIG.COLORS.BORDER)
    cpScroll.Parent = panel

    local cpGrid = Instance.new("UIGridLayout")
    cpGrid.CellSize = UDim2.new(0, 36, 0, 24)
    cpGrid.CellPadding = UDim2.new(0, 3, 0, 3)
    cpGrid.SortOrder = Enum.SortOrder.LayoutOrder
    cpGrid.Parent = cpScroll

    local cpPadding = Instance.new("UIPadding")
    cpPadding.PaddingLeft = UDim.new(0, 4)
    cpPadding.PaddingRight = UDim.new(0, 4)
    cpPadding.PaddingTop = UDim.new(0, 4)
    cpPadding.PaddingBottom = UDim.new(0, 4)
    cpPadding.Parent = cpScroll

    State.cpButtons = {}

    for i = 1, #CP_LIST do
        local btn = Instance.new("TextButton")
        btn.LayoutOrder = i
        btn.BackgroundColor3 = CONFIG.COLORS.CP_INACTIVE_BG
        btn.BorderSizePixel = 0
        btn.Text = "CP" .. i
        btn.TextColor3 = CONFIG.COLORS.TEXT_DIM
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 8
        btn.ZIndex = 13
        btn.AutoButtonColor = false
        GUI.createCorner(btn, 4)
        GUI.createStroke(btn, CONFIG.COLORS.BORDER)
        btn.Parent = cpScroll

        table.insert(State.cpButtons, btn)

        local cpIdx = i
        btn.MouseButton1Click:Connect(function()
            if State.running then return end
            Navigator.runGotoCPManual(cpIdx)
        end)

        btn.MouseEnter:Connect(function()
            if cpIdx ~= State.currentCP then
                GUI.tweenProperty(btn, "BackgroundColor3", CONFIG.COLORS.CP_HOVER_BG, 0.1)
                GUI.tweenProperty(btn, "TextColor3", CONFIG.COLORS.TEXT_SECONDARY, 0.1)
            end
        end)
        btn.MouseLeave:Connect(function()
            if cpIdx ~= State.currentCP then
                GUI.tweenProperty(btn, "BackgroundColor3", CONFIG.COLORS.CP_INACTIVE_BG, 0.1)
                GUI.tweenProperty(btn, "TextColor3", CONFIG.COLORS.TEXT_DIM, 0.1)
            end
        end)
    end

    -- ═══ ANTI-LAG TOGGLE ROW ═══
    local alY = gridY + gridH + 4
    local alH = 20
    local alRow = Instance.new("Frame")
    alRow.Size = UDim2.new(1, -18, 0, alH)
    alRow.Position = UDim2.new(0, 9, 0, alY)
    alRow.BackgroundColor3 = CONFIG.COLORS.CARD
    alRow.BorderSizePixel = 0
    alRow.ZIndex = 12
    GUI.createCorner(alRow, 4)
    GUI.createStroke(alRow, CONFIG.COLORS.BORDER)
    alRow.Parent = panel

    GUI.createLabel(alRow, {
        size = UDim2.new(1, -50, 1, 0),
        position = UDim2.new(0, 8, 0, 0),
        text = "ANTI-LAG",
        color = CONFIG.COLORS.TEXT_DIM,
        font = Enum.Font.GothamBold,
        fontSize = 7,
        zIndex = 13,
    })

    local alBtn = Instance.new("TextButton")
    alBtn.Size = UDim2.new(0, 36, 0, 14)
    alBtn.Position = UDim2.new(1, -42, 0.5, -7)
    alBtn.BackgroundColor3 = CONFIG.COLORS.CARD
    alBtn.Text = "OFF"
    alBtn.TextColor3 = CONFIG.COLORS.TEXT_DIM
    alBtn.Font = Enum.Font.GothamBold
    alBtn.TextSize = 8
    alBtn.BorderSizePixel = 0
    alBtn.ZIndex = 13
    alBtn.AutoButtonColor = false
    GUI.createCorner(alBtn, 3)
    local alStroke = GUI.createStroke(alBtn, CONFIG.COLORS.BORDER)
    alBtn.Parent = alRow

    alBtn.MouseButton1Click:Connect(function()
        local isOn = AntiLag.toggle()
        alBtn.Text = isOn and "ON" or "OFF"
        GUI.tweenProperty(alBtn, "TextColor3", isOn and CONFIG.COLORS.SUCCESS or CONFIG.COLORS.TEXT_DIM, 0.1)
        GUI.tweenProperty(alStroke, "Color", isOn and CONFIG.COLORS.ACCENT_DIM or CONFIG.COLORS.BORDER, 0.1)
    end)

    -- ═══ ACTION BUTTONS (y = alY + alH + 4) ═══
    local btnY = alY + alH + 5
    local btnH = 34
    local btnGap = 5
    local btnPad = 9
    local availW = CONFIG.GUI_WIDTH - (btnPad * 2) - (btnGap * 2)

    local stopW = math.floor(availW * 0.22)
    local claimW = math.floor(availW * 0.30)
    local startW = availW - stopW - claimW

    local bx = btnPad

    -- STOP Button
    local stopBtn = Instance.new("TextButton")
    stopBtn.Size = UDim2.new(0, stopW, 0, btnH)
    stopBtn.Position = UDim2.new(0, bx, 0, btnY)
    stopBtn.BackgroundColor3 = CONFIG.COLORS.BTN_STOP_BG
    stopBtn.Text = "■ STOP"
    stopBtn.TextColor3 = CONFIG.COLORS.ERROR
    stopBtn.Font = Enum.Font.GothamBold
    stopBtn.TextSize = 9
    stopBtn.BorderSizePixel = 0
    stopBtn.ZIndex = 12
    stopBtn.AutoButtonColor = false
    GUI.createCorner(stopBtn, 7)
    GUI.createStroke(stopBtn, CONFIG.COLORS.BTN_STOP_BORDER)
    stopBtn.Parent = panel
    bx = bx + stopW + btnGap

    stopBtn.MouseEnter:Connect(function()
        GUI.tweenProperty(stopBtn, "BackgroundColor3", CONFIG.COLORS.BTN_STOP_HOVER, 0.1)
    end)
    stopBtn.MouseLeave:Connect(function()
        GUI.tweenProperty(stopBtn, "BackgroundColor3", CONFIG.COLORS.BTN_STOP_BG, 0.1)
    end)
    stopBtn.MouseButton1Click:Connect(function()
        State.stopped = true
        GUI.tweenProperty(stopBtn, "TextColor3", CONFIG.COLORS.WARNING, 0.1)
        stopBtn.Text = "✓"
        task.delay(1.5, function()
            stopBtn.Text = "■ STOP"
            GUI.tweenProperty(stopBtn, "TextColor3", CONFIG.COLORS.ERROR, 0.1)
        end)
    end)

    -- CLAIM Button
    local claimBtn = Instance.new("TextButton")
    claimBtn.Size = UDim2.new(0, claimW, 0, btnH)
    claimBtn.Position = UDim2.new(0, bx, 0, btnY)
    claimBtn.BackgroundColor3 = CONFIG.COLORS.BTN_CLAIM_BG
    claimBtn.Text = "⚡ CLAIM"
    claimBtn.TextColor3 = CONFIG.COLORS.ACCENT
    claimBtn.Font = Enum.Font.GothamBold
    claimBtn.TextSize = 9
    claimBtn.BorderSizePixel = 0
    claimBtn.ZIndex = 12
    claimBtn.AutoButtonColor = false
    GUI.createCorner(claimBtn, 7)
    GUI.createStroke(claimBtn, CONFIG.COLORS.BTN_CLAIM_BORDER)
    claimBtn.Parent = panel
    bx = bx + claimW + btnGap

    claimBtn.MouseEnter:Connect(function()
        GUI.tweenProperty(claimBtn, "BackgroundColor3", CONFIG.COLORS.BTN_CLAIM_HOVER, 0.1)
    end)
    claimBtn.MouseLeave:Connect(function()
        GUI.tweenProperty(claimBtn, "BackgroundColor3", CONFIG.COLORS.BTN_CLAIM_BG, 0.1)
    end)
    claimBtn.MouseButton1Click:Connect(function()
        if State.running then return end
        claimBtn.Text = "⏳..."
        GUI.tweenProperty(claimBtn, "TextColor3", CONFIG.COLORS.WARNING, 0.1)

        Navigator.runClaimOnly()

        task.spawn(function()
            while State.running do task.wait(0.1) end
            task.wait(0.3)
            claimBtn.Text = "⚡ CLAIM"
            GUI.tweenProperty(claimBtn, "TextColor3", CONFIG.COLORS.ACCENT, 0.1)
        end)
    end)

    -- START AUTO Button
    local startBtn = Instance.new("TextButton")
    startBtn.Size = UDim2.new(0, startW, 0, btnH)
    startBtn.Position = UDim2.new(0, bx, 0, btnY)
    startBtn.BackgroundColor3 = CONFIG.COLORS.BTN_START_BG
    startBtn.Text = "▶ AUTO CP"
    startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    startBtn.Font = Enum.Font.GothamBold
    startBtn.TextSize = 9
    startBtn.BorderSizePixel = 0
    startBtn.ZIndex = 12
    startBtn.AutoButtonColor = false
    GUI.createCorner(startBtn, 7)
    startBtn.Parent = panel

    -- Pulsing animation for start button
    task.spawn(function()
        while screenGui and screenGui.Parent do
            if State.pulsing then
                TweenService:Create(startBtn, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    BackgroundColor3 = CONFIG.COLORS.BTN_START_HOVER,
                }):Play()
                task.wait(1.4)
                if State.pulsing and screenGui.Parent then
                    TweenService:Create(startBtn, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                        BackgroundColor3 = CONFIG.COLORS.BTN_START_BG,
                    }):Play()
                    task.wait(1.4)
                end
            else
                task.wait(0.3)
            end
        end
    end)

    startBtn.MouseEnter:Connect(function()
        if not State.running then
            State.pulsing = false
            GUI.tweenProperty(startBtn, "BackgroundColor3", CONFIG.COLORS.BTN_START_HOVER, 0.15)
        end
    end)
    startBtn.MouseLeave:Connect(function()
        if not State.running then
            State.pulsing = true
        end
    end)

    startBtn.MouseButton1Click:Connect(function()
        if State.running then return end
        State.pulsing = false
        startBtn.BackgroundColor3 = CONFIG.COLORS.BTN_START_RUNNING
        startBtn.Text = "▶ RUNNING"
        GUI.tweenProperty(startBtn, "TextColor3", CONFIG.COLORS.WARNING, 0.15)

        Navigator.runAutoCP(1)

        task.spawn(function()
            while State.running do task.wait(0.1) end
            task.wait(0.3)
            startBtn.Text = "▶ AUTO CP"
            startBtn.BackgroundColor3 = CONFIG.COLORS.BTN_START_BG
            GUI.tweenProperty(startBtn, "TextColor3", Color3.fromRGB(255, 255, 255), 0.15)
            State.pulsing = true
        end)
    end)

    -- ═══ F9 TOGGLE ═══
    UIS.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.F9 then
            panel.Visible = not panel.Visible
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ═══════════════════════════════════════════════════════════════

GUI.build()

print("[Yuhu] Loaded | " .. #CP_LIST .. " CP | Radius: "
    .. table.concat(CONFIG.SCAN_RADII, ", ") .. "s"
    .. " | Timeout: " .. CONFIG.SCAN_TIMEOUT .. "s"
    .. " | F9 toggle")
