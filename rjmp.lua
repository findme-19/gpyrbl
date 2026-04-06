--[[
  RAJA AMPAT SCRIPT
  BY ALFIAN
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

pcall(function()
    for _, g in ipairs(player.PlayerGui:GetChildren()) do
        if g.Name == "RajaAmpat" then g:Destroy() end
    end
end)

-- ══════════════════════════════
-- ANTI-LAG
-- ══════════════════════════════
local function applyAntiLag()
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    pcall(function() settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01 end)
    pcall(function() workspace.GlobalShadows = false end)
    pcall(function()
        settings().Rendering.FrameRateManager = 2
        settings().Rendering.MaxFrameRate = 15
    end)
    pcall(function()
        local L = game:GetService("Lighting")
        L.GlobalShadows = false
        L.Brightness = 1
        L.EnvironmentDiffuseScale = 0
        L.EnvironmentSpecularScale = 0
        for _, v in ipairs(L:GetChildren()) do
            if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or
               v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or
               v:IsA("DepthOfFieldEffect") then
                v.Enabled = false
            end
        end
    end)
    pcall(function()
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Fire") or
               v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("Beam") then
                v.Enabled = false
            end
            if v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            end
        end
    end)
end

-- ══════════════════════════════
-- KOORDINAT DARI MOTION LOG
-- ══════════════════════════════
-- Titik summit (posisi terakhir sebelum prompt "Ke Basecamp")
local SUMMIT_POS  = Vector3.new(-658.5, 609.1, -2879.3)
-- Titik basecamp (setelah prompt fired)
local BASECAMP_POS = Vector3.new(-1627.0, 65.1, -1355.8)

-- ══════════════════════════════
-- CORE
-- ══════════════════════════════
local running  = false
local statusCB = nil
local antilagOn = false

local function notif(t, m)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = t, Text = m, Duration = 3
        })
    end)
end

local function setStatus(msg, col)
    if statusCB then statusCB(msg, col) end
end

local function getHRP()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart", 5)
end

local function teleportTo(pos)
    local hrp = getHRP()
    if not hrp then return false end
    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
    return true
end

-- Find SummitPart prompt
local function findSummitPrompt()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local pName = (v.Parent and v.Parent.Name or ""):lower()
            local aText = (v.ActionText or ""):lower()
            if pName:match("summit") or aText:match("basecamp") or
               aText:match("base") or aText:match("kembali") then
                return v
            end
        end
    end
    -- fallback: scan all prompts near summit pos
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local par = v.Parent
            if par and par:IsA("BasePart") then
                local dist = (par.Position - SUMMIT_POS).Magnitude
                if dist < 100 then return v end
            end
        end
    end
    return nil
end

-- MAIN SEQUENCE
local function runSequence()
    if running then return end
    running = true

    task.spawn(function()

        -- STEP 1: Teleport ke summit
        setStatus("MENUJU SUMMIT", "wait")
        task.wait(0.5)
        local ok = teleportTo(SUMMIT_POS)
        if not ok then
            setStatus("CHARACTER NOT FOUND", "err")
            running = false
            return
        end
        task.wait(1.0)

        -- STEP 2: Cari dan fire prompt "Ke Basecamp"
        setStatus("MENCARI PROMPT SUMMIT", "wait")
        task.wait(0.5)

        local prompt = findSummitPrompt()
        if prompt then
            -- Teleport tepat ke posisi prompt object
            local par = prompt.Parent
            if par and par:IsA("BasePart") then
                teleportTo(par.Position)
                task.wait(0.6)
            end
            -- Fire prompt
            pcall(function() fireproximityprompt(prompt) end)
            setStatus("PROMPT FIRED", "wait")
            task.wait(1.2)
        else
            -- Fallback: langsung teleport ke basecamp manual
            setStatus("PROMPT NOT FOUND — DIRECT TP", "wait")
            task.wait(0.5)
        end

        -- STEP 3: Teleport ke basecamp
        setStatus("MENUJU BASECAMP", "wait")
        task.wait(0.5)
        teleportTo(BASECAMP_POS)
        task.wait(0.8)

        -- Done
        setStatus("TIBA DI BASECAMP — CLAIM MANUAL", "done")
        notif("Raja Ampat", "Sudah di basecamp. Claim voucher sekarang!")
        running = false
    end)
end

-- ══════════════════════════════
-- GUI
-- ══════════════════════════════
local C1 = Color3.fromRGB(8,   8,   8)
local C2 = Color3.fromRGB(14,  14,  14)
local C3 = Color3.fromRGB(22,  22,  22)
local C4 = Color3.fromRGB(35,  35,  35)
local C5 = Color3.fromRGB(55,  55,  55)
local W1 = Color3.fromRGB(220, 220, 220)
local W2 = Color3.fromRGB(140, 140, 140)
local W3 = Color3.fromRGB(55,  55,  55)
local GR = Color3.fromRGB(150, 255, 170)
local RD = Color3.fromRGB(255, 100, 100)
local YL = Color3.fromRGB(230, 200, 100)

local function cr(p, r)
    local u = Instance.new("UICorner", p)
    u.CornerRadius = UDim.new(0, r or 6)
end
local function sk(p, c, t)
    local s = Instance.new("UIStroke", p)
    s.Color = c or C4
    s.Thickness = t or 1
    return s
end

local sg = Instance.new("ScreenGui")
sg.Name           = "RajaAmpat"
sg.ResetOnSpawn   = false
sg.DisplayOrder   = 9999
sg.IgnoreGuiInset = true
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent         = player.PlayerGui

-- MAIN FRAME
local F = Instance.new("Frame", sg)
F.Size             = UDim2.new(0, 240, 0, 400)
F.Position         = UDim2.new(0.5, -120, 0.5, -200)
F.BackgroundColor3 = C1
F.BorderSizePixel  = 0
F.Active           = true
F.Draggable        = true
F.ZIndex           = 10
cr(F, 10)
sk(F, C4, 1)

-- top accent
local Accent = Instance.new("Frame", F)
Accent.Size             = UDim2.new(1, -2, 0, 1)
Accent.Position         = UDim2.new(0, 1, 0, 1)
Accent.BackgroundColor3 = W1
Accent.BorderSizePixel  = 0
Accent.ZIndex           = 14
cr(Accent, 1)

-- TOPBAR
local TB = Instance.new("Frame", F)
TB.Size             = UDim2.new(1, 0, 0, 46)
TB.Position         = UDim2.new(0, 0, 0, 0)
TB.BackgroundColor3 = C2
TB.BorderSizePixel  = 0
TB.ZIndex           = 11
cr(TB, 10)
local TBFix = Instance.new("Frame", TB)
TBFix.Size             = UDim2.new(1, 0, 0, 10)
TBFix.Position         = UDim2.new(0, 0, 1, -10)
TBFix.BackgroundColor3 = C2
TBFix.BorderSizePixel  = 0
TBFix.ZIndex           = 11

local TTitle = Instance.new("TextLabel", TB)
TTitle.Size               = UDim2.new(1, -46, 0, 16)
TTitle.Position           = UDim2.new(0, 14, 0, 8)
TTitle.BackgroundTransparency = 1
TTitle.Text               = "RAJA AMPAT SCRIPT"
TTitle.TextColor3         = W1
TTitle.Font               = Enum.Font.GothamBold
TTitle.TextSize           = 12
TTitle.TextXAlignment     = Enum.TextXAlignment.Left
TTitle.ZIndex             = 13

local TBy = Instance.new("TextLabel", TB)
TBy.Size               = UDim2.new(1, -46, 0, 12)
TBy.Position           = UDim2.new(0, 14, 0, 27)
TBy.BackgroundTransparency = 1
TBy.Text               = "BY ALFIAN"
TBy.TextColor3         = W3
TBy.Font               = Enum.Font.GothamBold
TBy.TextSize           = 8
TBy.TextXAlignment     = Enum.TextXAlignment.Left
TBy.ZIndex             = 13

local XBtn = Instance.new("TextButton", TB)
XBtn.Size             = UDim2.new(0, 24, 0, 24)
XBtn.Position         = UDim2.new(1, -32, 0.5, -12)
XBtn.BackgroundColor3 = C3
XBtn.Text             = "X"
XBtn.TextColor3       = W3
XBtn.Font             = Enum.Font.GothamBold
XBtn.TextSize         = 10
XBtn.BorderSizePixel  = 0
XBtn.ZIndex           = 14
cr(XBtn, 6)
sk(XBtn, C5, 1)
XBtn.MouseEnter:Connect(function() XBtn.TextColor3 = W1 end)
XBtn.MouseLeave:Connect(function() XBtn.TextColor3 = W3 end)
XBtn.MouseButton1Click:Connect(function()
    TweenService:Create(F, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
        Size = UDim2.new(0, 240, 0, 0),
        BackgroundTransparency = 1
    }):Play()
    task.delay(0.25, function() sg:Destroy() end)
end)

-- separator
local Sep = Instance.new("Frame", F)
Sep.Size             = UDim2.new(1, -28, 0, 1)
Sep.Position         = UDim2.new(0, 14, 0, 46)
Sep.BackgroundColor3 = C4
Sep.BorderSizePixel  = 0
Sep.ZIndex           = 11

-- BODY
local Body = Instance.new("Frame", F)
Body.Size             = UDim2.new(1, -28, 1, -60)
Body.Position         = UDim2.new(0, 14, 0, 54)
Body.BackgroundTransparency = 1
Body.ZIndex           = 11

local BL = Instance.new("UIListLayout", Body)
BL.SortOrder = Enum.SortOrder.LayoutOrder
BL.Padding   = UDim.new(0, 6)

local function hl(order)
    local l = Instance.new("Frame", Body)
    l.LayoutOrder = order
    l.Size = UDim2.new(1, 0, 0, 1)
    l.BackgroundColor3 = C4
    l.BorderSizePixel  = 0
    l.ZIndex = 12
end

local function seclbl(order, txt)
    local l = Instance.new("TextLabel", Body)
    l.LayoutOrder = order
    l.Size = UDim2.new(1, 0, 0, 12)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextColor3 = W3
    l.Font = Enum.Font.GothamBold
    l.TextSize = 8
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 12
end

-- CARA PAKAI
seclbl(1, "CARA PAKAI")

local steps = {
    "1.  Aktifkan Anti-Lag",
    "2.  Tekan START",
    "3.  Script teleport ke titik summit",
    "4.  Prompt Ke Basecamp otomatis di-fire",
    "5.  Teleport ke basecamp",
    "6.  Claim voucher secara manual",
}
for i, step in ipairs(steps) do
    local row = Instance.new("Frame", Body)
    row.LayoutOrder = 1 + i
    row.Size = UDim2.new(1, 0, 0, 14)
    row.BackgroundTransparency = 1
    row.ZIndex = 12

    local t = Instance.new("TextLabel", row)
    t.Size = UDim2.new(1, 0, 1, 0)
    t.BackgroundTransparency = 1
    t.Text = step
    t.TextColor3 = W2
    t.Font = Enum.Font.Gotham
    t.TextSize = 9
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.ZIndex = 13
end

hl(9)

-- KOORDINAT INFO
seclbl(10, "KOORDINAT")

local coords = {
    {"SUMMIT",   string.format("%.1f  %.1f  %.1f", SUMMIT_POS.X,   SUMMIT_POS.Y,   SUMMIT_POS.Z)},
    {"BASECAMP", string.format("%.1f  %.1f  %.1f", BASECAMP_POS.X, BASECAMP_POS.Y, BASECAMP_POS.Z)},
}
for i, c in ipairs(coords) do
    local row = Instance.new("Frame", Body)
    row.LayoutOrder = 10 + i
    row.Size = UDim2.new(1, 0, 0, 22)
    row.BackgroundColor3 = C2
    row.BorderSizePixel  = 0
    row.ZIndex = 12
    cr(row, 5)
    sk(row, C4, 1)

    local key = Instance.new("TextLabel", row)
    key.Size = UDim2.new(0, 62, 1, 0)
    key.Position = UDim2.new(0, 8, 0, 0)
    key.BackgroundTransparency = 1
    key.Text = c[1]
    key.TextColor3 = W3
    key.Font = Enum.Font.GothamBold
    key.TextSize = 8
    key.TextXAlignment = Enum.TextXAlignment.Left
    key.ZIndex = 13

    local val = Instance.new("TextLabel", row)
    val.Size = UDim2.new(1, -70, 1, 0)
    val.Position = UDim2.new(0, 70, 0, 0)
    val.BackgroundTransparency = 1
    val.Text = c[2]
    val.TextColor3 = W2
    val.Font = Enum.Font.Code
    val.TextSize = 9
    val.TextXAlignment = Enum.TextXAlignment.Left
    val.ZIndex = 13
end

hl(13)

-- STATUS
local StatCard = Instance.new("Frame", Body)
StatCard.LayoutOrder = 14
StatCard.Size = UDim2.new(1, 0, 0, 30)
StatCard.BackgroundColor3 = C2
StatCard.BorderSizePixel  = 0
StatCard.ZIndex = 12
cr(StatCard, 6)
sk(StatCard, C4, 1)

local StatKey = Instance.new("TextLabel", StatCard)
StatKey.Size = UDim2.new(0, 58, 1, 0)
StatKey.Position = UDim2.new(0, 10, 0, 0)
StatKey.BackgroundTransparency = 1
StatKey.Text = "STATUS"
StatKey.TextColor3 = W3
StatKey.Font = Enum.Font.GothamBold
StatKey.TextSize = 8
StatKey.TextXAlignment = Enum.TextXAlignment.Left
StatKey.ZIndex = 13

local StatDot = Instance.new("Frame", StatCard)
StatDot.Size = UDim2.new(0, 5, 0, 5)
StatDot.Position = UDim2.new(0, 72, 0.5, -2)
StatDot.BackgroundColor3 = GR
StatDot.BorderSizePixel  = 0
StatDot.ZIndex = 13
cr(StatDot, 5)

local StatVal = Instance.new("TextLabel", StatCard)
StatVal.Size = UDim2.new(1, -86, 1, 0)
StatVal.Position = UDim2.new(0, 84, 0, 0)
StatVal.BackgroundTransparency = 1
StatVal.Text = "READY"
StatVal.TextColor3 = GR
StatVal.Font = Enum.Font.GothamBold
StatVal.TextSize = 9
StatVal.TextXAlignment = Enum.TextXAlignment.Left
StatVal.TextTruncate = Enum.TextTruncate.AtEnd
StatVal.ZIndex = 13

statusCB = function(msg, col)
    StatVal.Text = msg
    if col == "done" then
        StatVal.TextColor3 = GR
        StatDot.BackgroundColor3 = GR
    elseif col == "err" then
        StatVal.TextColor3 = RD
        StatDot.BackgroundColor3 = RD
    elseif col == "wait" then
        StatVal.TextColor3 = YL
        StatDot.BackgroundColor3 = YL
    else
        StatVal.TextColor3 = W1
        StatDot.BackgroundColor3 = W1
    end
end

-- ANTI-LAG
local ALCard = Instance.new("Frame", Body)
ALCard.LayoutOrder = 15
ALCard.Size = UDim2.new(1, 0, 0, 30)
ALCard.BackgroundColor3 = C2
ALCard.BorderSizePixel  = 0
ALCard.ZIndex = 12
cr(ALCard, 6)
sk(ALCard, C4, 1)

local ALLbl = Instance.new("TextLabel", ALCard)
ALLbl.Size = UDim2.new(0.65, 0, 1, 0)
ALLbl.Position = UDim2.new(0, 10, 0, 0)
ALLbl.BackgroundTransparency = 1
ALLbl.Text = "ANTI-LAG / LOW GRAPHICS"
ALLbl.TextColor3 = W3
ALLbl.Font = Enum.Font.GothamBold
ALLbl.TextSize = 8
ALLbl.TextXAlignment = Enum.TextXAlignment.Left
ALLbl.ZIndex = 13

local ALBtn = Instance.new("TextButton", ALCard)
ALBtn.Size = UDim2.new(0, 40, 0, 18)
ALBtn.Position = UDim2.new(1, -46, 0.5, -9)
ALBtn.BackgroundColor3 = C3
ALBtn.Text = "OFF"
ALBtn.TextColor3 = W3
ALBtn.Font = Enum.Font.GothamBold
ALBtn.TextSize = 9
ALBtn.BorderSizePixel  = 0
ALBtn.ZIndex = 13
cr(ALBtn, 5)
local ALStroke = sk(ALBtn, C5, 1)

ALBtn.MouseButton1Click:Connect(function()
    antilagOn = not antilagOn
    if antilagOn then
        applyAntiLag()
        ALBtn.Text = "ON"
        ALBtn.TextColor3 = W1
        ALStroke.Color = W2
    else
        ALBtn.Text = "OFF"
        ALBtn.TextColor3 = W3
        ALStroke.Color = C5
    end
end)

-- START BUTTON
local StartBtn = Instance.new("TextButton", Body)
StartBtn.LayoutOrder = 16
StartBtn.Size = UDim2.new(1, 0, 0, 38)
StartBtn.BackgroundColor3 = C3
StartBtn.Text = "START"
StartBtn.TextColor3 = W1
StartBtn.Font = Enum.Font.GothamBold
StartBtn.TextSize = 13
StartBtn.BorderSizePixel = 0
StartBtn.ZIndex = 12
cr(StartBtn, 8)
sk(StartBtn, C5, 1)

local pulsing = true
task.spawn(function()
    while true do
        task.wait(0.05)
        if pulsing then
            TweenService:Create(StartBtn, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            }):Play()
            task.wait(1.4)
            if pulsing then
                TweenService:Create(StartBtn, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    BackgroundColor3 = C3
                }):Play()
                task.wait(1.4)
            end
        else
            task.wait(0.2)
        end
    end
end)

StartBtn.MouseButton1Click:Connect(function()
    if running then return end
    pulsing = false
    TweenService:Create(StartBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = C3
    }):Play()
    StartBtn.Text       = "RUNNING"
    StartBtn.TextColor3 = YL
    runSequence()
    task.spawn(function()
        while running do task.wait(0.1) end
        task.wait(0.3)
        StartBtn.Text       = "START"
        StartBtn.TextColor3 = W1
        pulsing = true
    end)
end)

-- F9
UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.F9 then
        F.Visible = not F.Visible
    end
end)

-- auto antilag on load
task.spawn(function()
    task.wait(0.5)
    applyAntiLag()
    antilagOn = true
    ALBtn.Text = "ON"
    ALBtn.TextColor3 = W1
    ALStroke.Color = W2
end)

print("Raja Ampat Script | By Alfian | F9 toggle")
