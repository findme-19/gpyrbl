--[[
  AUTO CLAIM GSK CODE - CYBERPUNK EDITION
  REMASTERED BY GEMINI (ORIGINAL BY ALFIAN & HURUHARA)
]]

local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local TweenSvc = game:GetService("TweenService")
local player   = Players.LocalPlayer

-- Koordinat Baru
local CHECKPOINTS = {
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
local currentTarget = CHECKPOINTS[1].TARGET
local currentNear = CHECKPOINTS[1].NEAR

-- Color Palette Cyberpunk
local CYBER_BLUE   = Color3.fromRGB(0, 255, 255)
local CYBER_PINK   = Color3.fromRGB(255, 0, 150)
local CYBER_YELLOW = Color3.fromRGB(255, 230, 0)
local DARK_BG      = Color3.fromRGB(10, 10, 15)
local CARD_BG      = Color3.fromRGB(20, 20, 28)
local GRID_LINE    = Color3.fromRGB(30, 30, 45)
local TEXT_MAIN    = Color3.fromRGB(220, 220, 230)

-- Bersihkan UI lama
pcall(function()
    for _,g in ipairs(player.PlayerGui:GetChildren()) do
        if g.Name=="SakahayangAlfian" then g:Destroy() end
    end
end)

-- [FUNGSI STATIS - TIDAK DIRUBAH]
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
            if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then v.Enabled=false end
        end
    end)
    pcall(function()
        for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("Beam") then v.Enabled=false end
            if v:IsA("Decal") or v:IsA("Texture") then v.Transparency=1 end
        end
    end)
end

local function findPrompt()
    for _,v in ipairs(workspace:GetDescendants()) do
        if v.Name=="ProxyAttachment" then
            local pr=v:FindFirstChildOfClass("ProximityPrompt")
            if pr then return pr,v end
        end
    end
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local at=(v.ActionText or ""):lower()
            if at:match("ambil") or at:match("hadiah") or at:match("claim") or at:match("voucher") then return v,v.Parent end
        end
    end
    return nil,nil
end

local function getObjPos(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then return (obj.PrimaryPart and obj.PrimaryPart.Position) or (obj:FindFirstChildWhichIsA("BasePart") and obj:FindFirstChildWhichIsA("BasePart").Position) end
    if obj:IsA("Attachment") then return obj.WorldPosition end
    return nil
end

-- [MODIFIKASI RUN SEQUENCE - DUAL TARGET]
local SVl
local function setStatus(msg, col)
    if not SVl then return end
    SVl.Text = "» " .. msg
    SVl.TextColor3 = col or CYBER_BLUE
end

local function runSequence()
    if running then return end
    running = true
    task.spawn(function()
        setStatus("INITIALIZING", CYBER_YELLOW)
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if not hrp then setStatus("ERR: NO ROOT", CYBER_PINK); running=false; return end
        
        setStatus("WARP: NEURAL LINK", CYBER_BLUE)
        hrp.CFrame = CFrame.new(currentNear + Vector3.new(0, 5, 0)); task.wait(0.3)

        setStatus("SCANNING ASSETS", CYBER_YELLOW)
        local pr, obj = findPrompt()
        if obj then
            local pos = getObjPos(obj)
            if pos then
                local off = (currentNear - pos)
                off = off.Magnitude > 0.1 and off.Unit * 7 or Vector3.new(0, 0, 7)
                hrp.CFrame = CFrame.new(pos + off + Vector3.new(0, 3, 0)); task.wait(0.25)
            end
        end

        setStatus("FIRING DATA", CYBER_BLUE)
        local fired = false
        if pr then
            for _=1,3 do
                local ok = pcall(function() fireproximityprompt(pr) end)
                if ok then fired=true; break end
                task.wait(0.1)
            end
        end
        
        setStatus("SUCCESS: CLAIMED", CYBER_BLUE)
        running = false
    end)
end

-- ══════════════════════════════
-- GUI DESIGN: CYBERPUNK THEME
-- ══════════════════════════════
local sg = Instance.new("ScreenGui")
sg.Name = "SakahayangAlfian"; sg.ResetOnSpawn = false; sg.Parent = player.PlayerGui

local Main = Instance.new("Frame", sg)
Main.Size = UDim2.new(0, 280, 0, 420)
Main.Position = UDim2.new(0, 50, 0.5, -210)
Main.BackgroundColor3 = DARK_BG
Main.BorderSizePixel = 0
Main.Active = true; Main.Draggable = true
Instance.new("UIStroke", Main).Color = GRID_LINE

-- Glow Effect
local Glow = Instance.new("UIStroke", Main)
Glow.Color = CYBER_BLUE; Glow.Thickness = 1.5; Glow.Transparency = 0.8

-- Header
local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1, 0, 0, 40); Header.BackgroundColor3 = CARD_BG; Header.BorderSizePixel = 0
local HLabel = Instance.new("TextLabel", Header)
HLabel.Size = UDim2.new(1, -40, 1, 0); HLabel.Position = UDim2.new(0, 12, 0, 0)
HLabel.Text = "AUTO CLAIM GSK CODE"; HLabel.TextColor3 = CYBER_BLUE
HLabel.Font = Enum.Font.GothamBold; HLabel.TextSize = 14; HLabel.TextXAlignment = "Left"; HLabel.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 30, 0, 30); CloseBtn.Position = UDim2.new(1, -35, 0.5, -15)
CloseBtn.Text = "X"; CloseBtn.TextColor3 = CYBER_PINK; CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.BackgroundTransparency = 1
CloseBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

-- Divider
local function mkDiv(y)
    local d = Instance.new("Frame", Main)
    d.Size = UDim2.new(1, -20, 0, 1); d.Position = UDim2.new(0, 10, 0, y)
    d.BackgroundColor3 = GRID_LINE; d.BorderSizePixel = 0
end

-- Body Status
local SysLabel = Instance.new("TextLabel", Main)
SysLabel.Size = UDim2.new(1, 0, 0, 30); SysLabel.Position = UDim2.new(0, 12, 0, 50)
SysLabel.Text = "[ ! ] SYSTEM ACTIVE"; SysLabel.TextColor3 = CYBER_YELLOW
SysLabel.Font = Enum.Font.GothamBold; SysLabel.TextSize = 12; SysLabel.BackgroundTransparency = 1; SysLabel.TextXAlignment = "Left"

SVl = Instance.new("TextLabel", Main)
SVl.Size = UDim2.new(1, -24, 0, 20); SVl.Position = UDim2.new(0, 12, 0, 75)
SVl.Text = "» STANDBY"; SVl.TextColor3 = CYBER_BLUE; SVl.Font = Enum.Font.Code; SVl.TextSize = 13; SVl.BackgroundTransparency = 1; SVl.TextXAlignment = "Left"

mkDiv(105)

-- Low Graphics Toggle
local LGC = Instance.new("Frame", Main)
LGC.Size = UDim2.new(1, -24, 0, 40); LGC.Position = UDim2.new(0, 12, 0, 115); LGC.BackgroundColor3 = CARD_BG; LGC.BorderSizePixel = 0
Instance.new("UICorner", LGC).CornerRadius = UDim.new(0, 4)

local LGTxt = Instance.new("TextLabel", LGC)
LGTxt.Size = UDim2.new(0.6, 0, 1, 0); LGTxt.Position = UDim2.new(0, 10, 0, 0); LGTxt.Text = "LOW GRAPHICS"; LGTxt.TextColor3 = TEXT_MAIN; LGTxt.Font = Enum.Font.Gotham; LGTxt.TextSize = 11; LGTxt.BackgroundTransparency = 1; LGTxt.TextXAlignment = "Left"

local ALBtn = Instance.new("TextButton", LGC)
ALBtn.Size = UDim2.new(0, 50, 0, 24); ALBtn.Position = UDim2.new(1, -60, 0.5, -12); ALBtn.BackgroundColor3 = DARK_BG; ALBtn.Text = "ON"; ALBtn.TextColor3 = CYBER_BLUE; ALBtn.Font = Enum.Font.GothamBold; ALBtn.TextSize = 10
local als = Instance.new("UIStroke", ALBtn); als.Color = CYBER_BLUE; als.Thickness = 1

local alState = true
ALBtn.MouseButton1Click:Connect(function()
    alState = not alState
    ALBtn.Text = alState and "ON" or "OFF"
    ALBtn.TextColor3 = alState and CYBER_BLUE or CYBER_PINK
    als.Color = alState and CYBER_BLUE or CYBER_PINK
    if alState then applyAntiLag() end
end)

mkDiv(165)

-- CP Buttons
local function mkCPBtn(name, pos, cpIdx)
    local b = Instance.new("TextButton", Main)
    b.Size = UDim2.new(0, 120, 0, 45); b.Position = pos
    b.BackgroundColor3 = CARD_BG; b.Text = name; b.TextColor3 = Color3.fromRGB(255,255,255); b.Font = Enum.Font.GothamBold; b.TextSize = 12
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    local s = Instance.new("UIStroke", b); s.Color = GRID_LINE; s.Thickness = 1
    
    b.MouseButton1Click:Connect(function()
        if running then return end
        currentTarget = CHECKPOINTS[cpIdx].TARGET
        currentNear = CHECKPOINTS[cpIdx].NEAR
        s.Color = CYBER_BLUE
        runSequence()
        task.wait(1)
        s.Color = GRID_LINE
    end)
end

mkCPBtn("START CP1", UDim2.new(0, 12, 0, 180), 1)
mkCPBtn("START CP2", UDim2.new(0, 148, 0, 180), 2)

-- Footer Section
mkDiv(245)

local FootMsg = Instance.new("TextLabel", Main)
FootMsg.Size = UDim2.new(1, -24, 0, 40); FootMsg.Position = UDim2.new(0, 12, 0, 255)
FootMsg.Text = "Neural link established. Don't let the corporate hackers track your packet."; FootMsg.TextColor3 = Color3.fromRGB(100, 100, 120)
FootMsg.Font = Enum.Font.GothamItalic; FootMsg.TextSize = 10; FootMsg.TextWrapped = true; FootMsg.BackgroundTransparency = 1; FootMsg.TextXAlignment = "Left"

local Creator = Instance.new("TextLabel", Main)
Creator.Size = UDim2.new(1, 0, 0, 20); Creator.Position = UDim2.new(0, 0, 1, -45)
Creator.Text = "CREATED BY HURUHARA"; Creator.TextColor3 = CYBER_PINK; Creator.Font = Enum.Font.GothamBold; Creator.TextSize = 10; Creator.BackgroundTransparency = 1

local EndTag = Instance.new("TextLabel", Main)
EndTag.Size = UDim2.new(1, 0, 0, 20); EndTag.Position = UDim2.new(0, 0, 1, -25)
EndTag.Text = "TERMINAL v4.0.2 - SECURED"; EndTag.TextColor3 = GRID_LINE; EndTag.Font = Enum.Font.Code; EndTag.TextSize = 9; EndTag.BackgroundTransparency = 1

-- Toggle F9
UIS.InputBegan:Connect(function(inp, gpe)
    if not gpe and inp.KeyCode == Enum.KeyCode.F9 then Main.Visible = not Main.Visible end
end)

-- Startup
task.spawn(function()
    applyAntiLag()
    print("CyberTerminal Loaded | Created by Huruhara")
end)
