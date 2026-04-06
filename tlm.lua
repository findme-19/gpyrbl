--[[
  GOPAY SCRIPT TALAMAU
  BY ALFIAN
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

pcall(function()
    for _, g in ipairs(player.PlayerGui:GetChildren()) do
        if g.Name == "GPAlfian" then g:Destroy() end
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
-- KOORDINAT
-- Offset 8 stud dari objek supaya
-- ProximityPrompt range terpenuhi
-- tapi tidak nempel persis
-- ══════════════════════════════
local TARGET = Vector3.new(-527.5, 1062.0, 333.4)
-- offset: mundur 8 stud di Z agar tidak overlap objek
local TARGET_NEAR = Vector3.new(-527.5, 1062.0, 341.4)

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

-- ══════════════════════════════
-- FIND REDEMPTION OBJECT
-- ══════════════════════════════
local function findRedemption()
    -- exact name first
    for _, v in ipairs(workspace:GetDescendants()) do
        if v.Name == "RedemptionPointBasepart" then return v end
    end
    -- pattern scan
    for _, v in ipairs(workspace:GetDescendants()) do
        local n = v.Name:lower()
        if n:match("redemption") or n:match("gopay") or
           n:match("voucher") or n:match("claim") then
            if v:IsA("BasePart") or v:IsA("Model") then return v end
        end
    end
    -- scan billboard/surface gui text
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BillboardGui") or v:IsA("SurfaceGui") then
            for _, c in ipairs(v:GetDescendants()) do
                if c:IsA("TextLabel") or c:IsA("TextButton") then
                    local t = c.Text:lower()
                    if t:match("gopay") or t:match("claim") or t:match("voucher") then
                        local par = v.Parent
                        if par and (par:IsA("BasePart") or par:IsA("Model")) then
                            return par
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function getObjPos(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local p = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        return p and p.Position
    end
end

-- ══════════════════════════════
-- FIRE PROXIMITY PROMPT
-- dengan retry loop agar tidak
-- perlu tap berkali-kali manual
-- ══════════════════════════════
local function fireAllPrompts(obj)
    local fired = 0

    -- kumpulkan semua prompt kandidat
    local candidates = {}

    -- dari objek itu sendiri
    if obj then
        for _, v in ipairs(obj:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                table.insert(candidates, v)
            end
        end
        if obj:IsA("ProximityPrompt") then
            table.insert(candidates, obj)
        end
    end

    -- scan workspace untuk prompt claim/gopay/voucher
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local n  = (v.ActionText or ""):lower()
            local pn = (v.Parent and v.Parent.Name or ""):lower()
            if n:match("claim") or n:match("voucher") or n:match("gopay") or
               pn:match("redemption") or pn:match("gopay") or pn:match("claim") then
                table.insert(candidates, v)
            end
        end
    end

    -- deduplicate
    local seen = {}
    local unique = {}
    for _, p in ipairs(candidates) do
        if not seen[p] then
            seen[p] = true
            table.insert(unique, p)
        end
    end

    -- fire setiap prompt dengan retry 3x
    for _, prompt in ipairs(unique) do
        for attempt = 1, 3 do
            local ok = pcall(function()
                fireproximityprompt(prompt)
            end)
            if ok then
                fired = fired + 1
                break
            end
            task.wait(0.1)
        end
    end

    return fired, #unique
end

-- ══════════════════════════════
-- MAIN TELEPORT SEQUENCE
-- ══════════════════════════════
local function runTeleport()
    if running then return end
    running = true

    task.spawn(function()

        -- STEP 1: ambil karakter
        setStatus("CONNECTING", "wait")
        task.wait(0.2)

        local char = player.Character or player.CharacterAdded:Wait()
        local hrp  = char:WaitForChild("HumanoidRootPart", 5)
        if not hrp then
            setStatus("CHARACTER NOT FOUND", "err")
            running = false
            return
        end

        -- nonaktifkan physics sebentar biar TP mulus
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 0 end

        -- STEP 2: TP ke titik dekat (offset 8 stud)
        setStatus("FAST TRAVEL", "wait")
        hrp.CFrame = CFrame.new(TARGET_NEAR + Vector3.new(0, 5, 0))
        task.wait(0.3) -- singkat, speed run

        -- STEP 3: scan objek
        setStatus("LOCATING POINT", "wait")
        local obj = findRedemption()
        local finalPos = TARGET_NEAR

        if obj then
            local pos = getObjPos(obj)
            if pos then
                -- offset 8 stud dari objek (bukan nempel persis)
                local offset = (TARGET_NEAR - pos)
                if offset.Magnitude > 0 then
                    offset = offset.Unit * 8
                else
                    offset = Vector3.new(0, 0, 8)
                end
                finalPos = pos + offset
                hrp.CFrame = CFrame.new(finalPos + Vector3.new(0, 3, 0))
                task.wait(0.2)
            end
        end

        -- STEP 4: pastikan dalam range prompt lalu fire
        setStatus("FIRING PROMPT", "wait")
        task.wait(0.15)

        -- walk speed normal supaya proximity prompt detect player
        if hum then hum.WalkSpeed = 16 end

        -- fire dengan retry loop (fix: tap berkali-kali jadi 1x otomatis)
        local fired, total = fireAllPrompts(obj)

        -- jika belum fired, coba gerak sedikit ke arah objek lalu retry
        if fired == 0 and obj then
            local pos = getObjPos(obj)
            if pos then
                -- nudge 2 stud lebih dekat
                local dir = (pos - hrp.Position)
                if dir.Magnitude > 0 then
                    hrp.CFrame = CFrame.new(hrp.Position + dir.Unit * 2)
                end
                task.wait(0.15)
                fired, total = fireAllPrompts(obj)
            end
        end

        -- STEP 5: selesai
        if fired > 0 then
            setStatus("ARRIVED  —  CLAIM MANUAL", "done")
            notif("GoPay Talamau", "Sudah tiba. Claim voucher sekarang.")
        else
            -- tetap tiba, prompt mungkin sudah handle di client
            setStatus("ARRIVED  —  CLAIM MANUAL", "done")
            notif("GoPay Talamau", "Sudah tiba. Tap Claim Voucher.")
        end

        running = false
    end)
end

-- ══════════════════════════════
-- GUI
-- ══════════════════════════════
local C1c = Color3.fromRGB(8,   8,   8)
local C2c = Color3.fromRGB(14,  14,  14)
local C3c = Color3.fromRGB(22,  22,  22)
local C4c = Color3.fromRGB(35,  35,  35)
local C5c = Color3.fromRGB(55,  55,  55)
local W1c = Color3.fromRGB(220, 220, 220)
local W2c = Color3.fromRGB(140, 140, 140)
local W3c = Color3.fromRGB(55,  55,  55)
local GRc = Color3.fromRGB(150, 255, 170)
local RDc = Color3.fromRGB(255, 100, 100)
local YLc = Color3.fromRGB(230, 200, 100)

local function cr(p, r)
    local u = Instance.new("UICorner", p)
    u.CornerRadius = UDim.new(0, r or 6)
end
local function sk(p, c, t)
    local s = Instance.new("UIStroke", p)
    s.Color = c or C4c
    s.Thickness = t or 1
    return s
end

local sg = Instance.new("ScreenGui")
sg.Name           = "GPAlfian"
sg.ResetOnSpawn   = false
sg.DisplayOrder   = 9999
sg.IgnoreGuiInset = true
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent         = player.PlayerGui

local F = Instance.new("Frame", sg)
F.Size             = UDim2.new(0, 240, 0, 370)
F.Position         = UDim2.new(0.5, -120, 0.5, -185)
F.BackgroundColor3 = C1c
F.BorderSizePixel  = 0
F.Active           = true
F.Draggable        = true
F.ZIndex           = 10
cr(F, 10)
sk(F, C4c, 1)

local Accent = Instance.new("Frame", F)
Accent.Size             = UDim2.new(1, -2, 0, 1)
Accent.Position         = UDim2.new(0, 1, 0, 1)
Accent.BackgroundColor3 = W1c
Accent.BorderSizePixel  = 0
Accent.ZIndex           = 14
cr(Accent, 1)

-- TOPBAR
local TB = Instance.new("Frame", F)
TB.Size             = UDim2.new(1, 0, 0, 44)
TB.Position         = UDim2.new(0, 0, 0, 0)
TB.BackgroundColor3 = C2c
TB.BorderSizePixel  = 0
TB.ZIndex           = 11
cr(TB, 10)
local TBFix = Instance.new("Frame", TB)
TBFix.Size             = UDim2.new(1, 0, 0, 10)
TBFix.Position         = UDim2.new(0, 0, 1, -10)
TBFix.BackgroundColor3 = C2c
TBFix.BorderSizePixel  = 0
TBFix.ZIndex           = 11

local TTitle = Instance.new("TextLabel", TB)
TTitle.Size               = UDim2.new(1, -46, 0, 16)
TTitle.Position           = UDim2.new(0, 14, 0, 8)
TTitle.BackgroundTransparency = 1
TTitle.Text               = "GOPAY SCRIPT TALAMAU"
TTitle.TextColor3         = W1c
TTitle.Font               = Enum.Font.GothamBold
TTitle.TextSize           = 11
TTitle.TextXAlignment     = Enum.TextXAlignment.Left
TTitle.ZIndex             = 13

local TBy = Instance.new("TextLabel", TB)
TBy.Size               = UDim2.new(1, -46, 0, 12)
TBy.Position           = UDim2.new(0, 14, 0, 26)
TBy.BackgroundTransparency = 1
TBy.Text               = "BY ALFIAN"
TBy.TextColor3         = W3c
TBy.Font               = Enum.Font.GothamBold
TBy.TextSize           = 8
TBy.TextXAlignment     = Enum.TextXAlignment.Left
TBy.ZIndex             = 13

local XBtn = Instance.new("TextButton", TB)
XBtn.Size             = UDim2.new(0, 24, 0, 24)
XBtn.Position         = UDim2.new(1, -32, 0.5, -12)
XBtn.BackgroundColor3 = C3c
XBtn.Text             = "X"
XBtn.TextColor3       = W3c
XBtn.Font             = Enum.Font.GothamBold
XBtn.TextSize         = 10
XBtn.BorderSizePixel  = 0
XBtn.ZIndex           = 14
cr(XBtn, 6)
sk(XBtn, C5c, 1)
XBtn.MouseEnter:Connect(function() XBtn.TextColor3 = W1c end)
XBtn.MouseLeave:Connect(function() XBtn.TextColor3 = W3c end)
XBtn.MouseButton1Click:Connect(function()
    TweenService:Create(F, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
        Size = UDim2.new(0, 240, 0, 0),
        BackgroundTransparency = 1
    }):Play()
    task.delay(0.25, function() sg:Destroy() end)
end)

local Sep = Instance.new("Frame", F)
Sep.Size             = UDim2.new(1, -28, 0, 1)
Sep.Position         = UDim2.new(0, 14, 0, 44)
Sep.BackgroundColor3 = C4c
Sep.BorderSizePixel  = 0
Sep.ZIndex           = 11

-- BODY
local Body = Instance.new("Frame", F)
Body.Size             = UDim2.new(1, -28, 1, -58)
Body.Position         = UDim2.new(0, 14, 0, 52)
Body.BackgroundTransparency = 1
Body.ZIndex           = 11

local BL = Instance.new("UIListLayout", Body)
BL.SortOrder = Enum.SortOrder.LayoutOrder
BL.Padding   = UDim.new(0, 6)

local function hl(order)
    local l = Instance.new("Frame", Body)
    l.LayoutOrder = order
    l.Size = UDim2.new(1, 0, 0, 1)
    l.BackgroundColor3 = C4c
    l.BorderSizePixel  = 0
    l.ZIndex = 12
end

local function seclbl(order, txt)
    local l = Instance.new("TextLabel", Body)
    l.LayoutOrder = order
    l.Size = UDim2.new(1, 0, 0, 12)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextColor3 = W3c
    l.Font = Enum.Font.GothamBold
    l.TextSize = 8
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 12
end

seclbl(1, "CARA PAKAI")

local steps = {
    "1.  Anti-Lag aktif otomatis saat load",
    "2.  Tekan START — teleport otomatis",
    "3.  Tunggu status ARRIVED muncul",
    "4.  Klik Claim Voucher 1x saja",
    "5.  Salin kode voucher yang muncul",
}
for i, step in ipairs(steps) do
    local row = Instance.new("Frame", Body)
    row.LayoutOrder = 1 + i
    row.Size = UDim2.new(1, 0, 0, 15)
    row.BackgroundTransparency = 1
    row.ZIndex = 12

    local t = Instance.new("TextLabel", row)
    t.Size = UDim2.new(1, 0, 1, 0)
    t.BackgroundTransparency = 1
    t.Text = step
    t.TextColor3 = W2c
    t.Font = Enum.Font.Gotham
    t.TextSize = 9
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.ZIndex = 13
end

hl(8)

-- STATUS CARD
local StatCard = Instance.new("Frame", Body)
StatCard.LayoutOrder = 9
StatCard.Size = UDim2.new(1, 0, 0, 30)
StatCard.BackgroundColor3 = C2c
StatCard.BorderSizePixel  = 0
StatCard.ZIndex = 12
cr(StatCard, 6)
sk(StatCard, C4c, 1)

local StatKey = Instance.new("TextLabel", StatCard)
StatKey.Size = UDim2.new(0, 58, 1, 0)
StatKey.Position = UDim2.new(0, 10, 0, 0)
StatKey.BackgroundTransparency = 1
StatKey.Text = "STATUS"
StatKey.TextColor3 = W3c
StatKey.Font = Enum.Font.GothamBold
StatKey.TextSize = 8
StatKey.TextXAlignment = Enum.TextXAlignment.Left
StatKey.ZIndex = 13

local StatDot = Instance.new("Frame", StatCard)
StatDot.Size = UDim2.new(0, 5, 0, 5)
StatDot.Position = UDim2.new(0, 72, 0.5, -2)
StatDot.BackgroundColor3 = GRc
StatDot.BorderSizePixel  = 0
StatDot.ZIndex = 13
cr(StatDot, 5)

local StatVal = Instance.new("TextLabel", StatCard)
StatVal.Size = UDim2.new(1, -86, 1, 0)
StatVal.Position = UDim2.new(0, 84, 0, 0)
StatVal.BackgroundTransparency = 1
StatVal.Text = "READY"
StatVal.TextColor3 = GRc
StatVal.Font = Enum.Font.GothamBold
StatVal.TextSize = 9
StatVal.TextXAlignment = Enum.TextXAlignment.Left
StatVal.TextTruncate = Enum.TextTruncate.AtEnd
StatVal.ZIndex = 13

statusCB = function(msg, col)
    StatVal.Text = msg
    if col == "done" then
        StatVal.TextColor3 = GRc
        StatDot.BackgroundColor3 = GRc
    elseif col == "err" then
        StatVal.TextColor3 = RDc
        StatDot.BackgroundColor3 = RDc
    elseif col == "wait" then
        StatVal.TextColor3 = YLc
        StatDot.BackgroundColor3 = YLc
    else
        StatVal.TextColor3 = W1c
        StatDot.BackgroundColor3 = W1c
    end
end

-- ANTI-LAG CARD
local ALCard = Instance.new("Frame", Body)
ALCard.LayoutOrder = 10
ALCard.Size = UDim2.new(1, 0, 0, 30)
ALCard.BackgroundColor3 = C2c
ALCard.BorderSizePixel  = 0
ALCard.ZIndex = 12
cr(ALCard, 6)
sk(ALCard, C4c, 1)

local ALLbl = Instance.new("TextLabel", ALCard)
ALLbl.Size = UDim2.new(0.65, 0, 1, 0)
ALLbl.Position = UDim2.new(0, 10, 0, 0)
ALLbl.BackgroundTransparency = 1
ALLbl.Text = "ANTI-LAG / LOW GRAPHICS"
ALLbl.TextColor3 = W3c
ALLbl.Font = Enum.Font.GothamBold
ALLbl.TextSize = 8
ALLbl.TextXAlignment = Enum.TextXAlignment.Left
ALLbl.ZIndex = 13

local ALBtn = Instance.new("TextButton", ALCard)
ALBtn.Size = UDim2.new(0, 40, 0, 18)
ALBtn.Position = UDim2.new(1, -46, 0.5, -9)
ALBtn.BackgroundColor3 = C3c
ALBtn.Text = "OFF"
ALBtn.TextColor3 = W3c
ALBtn.Font = Enum.Font.GothamBold
ALBtn.TextSize = 9
ALBtn.BorderSizePixel  = 0
ALBtn.ZIndex = 13
cr(ALBtn, 5)
local ALStroke = sk(ALBtn, C5c, 1)

ALBtn.MouseButton1Click:Connect(function()
    antilagOn = not antilagOn
    if antilagOn then
        applyAntiLag()
        ALBtn.Text = "ON"
        ALBtn.TextColor3 = W1c
        ALStroke.Color = W2c
    else
        ALBtn.Text = "OFF"
        ALBtn.TextColor3 = W3c
        ALStroke.Color = C5c
    end
end)

-- START BUTTON
local StartBtn = Instance.new("TextButton", Body)
StartBtn.LayoutOrder = 11
StartBtn.Size = UDim2.new(1, 0, 0, 38)
StartBtn.BackgroundColor3 = C3c
StartBtn.Text = "START"
StartBtn.TextColor3 = W1c
StartBtn.Font = Enum.Font.GothamBold
StartBtn.TextSize = 13
StartBtn.BorderSizePixel = 0
StartBtn.ZIndex = 12
cr(StartBtn, 8)
sk(StartBtn, C5c, 1)

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
                    BackgroundColor3 = C3c
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
        BackgroundColor3 = C3c
    }):Play()
    StartBtn.Text       = "TELEPORTING"
    StartBtn.TextColor3 = YLc

    runTeleport()

    task.spawn(function()
        while running do task.wait(0.1) end
        task.wait(0.3)
        StartBtn.Text       = "START"
        StartBtn.TextColor3 = W1c
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
    ALBtn.TextColor3 = W1c
    ALStroke.Color = W2c
end)

print("GoPay Script Talamau | By Alfian | F9 toggle")
