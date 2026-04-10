--[[
  AUTO CLAIM GSK CODE - CYBERPUNK EDITION
  CREATED BY HURUHARA
]]

local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local TweenSvc = game:GetService("TweenService")
local player   = Players.LocalPlayer

-- Clean up previous GUI
pcall(function()
    for _,g in ipairs(player.PlayerGui:GetChildren()) do
        if g.Name=="SakahayangAlfian" then g:Destroy() end
    end
end)

-- CONFIG DATA
local COORDS = {
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

-- CYBERPUNK PALETTE
local CYAN   = Color3.fromRGB(0, 255, 255)
local NEON_P = Color3.fromRGB(255, 0, 150)
local GOLD   = Color3.fromRGB(255, 200, 0)
local BG_MAIN = Color3.fromRGB(10, 10, 15)
local BG_CARD = Color3.fromRGB(20, 20, 28)
local LINE   = Color3.fromRGB(40, 40, 55)
local TEXT_S = Color3.fromRGB(150, 150, 165)
local WHITE  = Color3.fromRGB(240, 240, 240)

-- FUNCTIONALITIES (ANTI-LAG)
local function applyAntiLag()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        workspace.GlobalShadows = false
        local L = game:GetService("Lighting")
        L.Brightness = 1
        for _, v in ipairs(L:GetChildren()) do
            if v:IsA("PostProcessEffect") then v.Enabled = false end
        end
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1 end
            if v:IsA("ParticleEmitter") then v.Enabled = false end
        end
    end)
end

-- STATUS HANDLER
local SVl, SDot
local function setStatus(msg, col)
    if not SVl then return end
    SVl.Text = "» " .. msg
    SVl.TextColor3 = col or CYAN
    if SDot then SDot.BackgroundColor3 = col or CYAN end
end

-- PROXIMITY LOGIC
local function findPrompt(targetPos)
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local p = v.Parent
            local pos = p:IsA("BasePart") and p.Position or (p:IsA("Model") and p.PrimaryPart and p.PrimaryPart.Position)
            if pos and (pos - targetPos).Magnitude < 100 then
                return v, p
            end
        end
    end
    return nil, nil
end

local function runSequence(index)
    if running then return end
    running = true
    local data = COORDS[index]
    
    task.spawn(function()
        setStatus("INITIALIZING...", GOLD)
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if not hrp then setStatus("ERROR: NO HRP", NEON_P); running = false; return end
        
        setStatus("WARPING TO CP " .. index, CYAN)
        hrp.CFrame = CFrame.new(data.NEAR + Vector3.new(0, 5, 0))
        task.wait(0.5)

        setStatus("SCANNING OBJECT", GOLD)
        local pr, obj = findPrompt(data.TARGET)
        
        if pr then
            setStatus("EXECUTING CLAIM", CYAN)
            fireproximityprompt(pr)
            task.wait(0.2)
            setStatus("ARRIVED & CLAIMED", Color3.fromRGB(0, 255, 100))
        else
            setStatus("CP " .. index .. " READY", WHITE)
        end
        
        running = false
    end)
end

-- GUI CONSTRUCTION
local sg = Instance.new("ScreenGui", player.PlayerGui)
sg.Name = "SakahayangAlfian"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true

local F = Instance.new("Frame", sg)
F.Size = UDim2.new(0, 280, 0, 400)
F.Position = UDim2.new(0, 30, 0.5, -200)
F.BackgroundColor3 = BG_MAIN
F.BorderSizePixel = 0
F.Active = true; F.Draggable = true
Instance.new("UICorner", F).CornerRadius = UDim.new(0, 4)
local MainStroke = Instance.new("UIStroke", F)
MainStroke.Color = LINE; MainStroke.Thickness = 1.5

-- Decor Line
local DecoLine = Instance.new("Frame", F)
DecoLine.Size = UDim2.new(1, 0, 0, 2); DecoLine.BackgroundColor3 = CYAN; DecoLine.BorderSizePixel = 0

-- UI HELPERS
local function mkDivider(yp)
    local d = Instance.new("Frame", F)
    d.Size = UDim2.new(1, -30, 0, 1); d.Position = UDim2.new(0, 15, 0, yp)
    d.BackgroundColor3 = LINE; d.BorderSizePixel = 0
end

local function mkLabel(txt, sz, font, col, pos, par)
    local l = Instance.new("TextLabel", par or F)
    l.Text = txt; l.TextSize = sz; l.Font = font; l.TextColor3 = col
    l.Position = pos; l.BackgroundTransparency = 1; l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end

-- HEADER
local Head = mkLabel("AUTO CLAIM GSK CODE", 14, Enum.Font.GothamBold, WHITE, UDim2.new(0, 15, 0, 20))
local CloseBtn = Instance.new("TextButton", F)
CloseBtn.Size = UDim2.new(0, 25, 0, 25); CloseBtn.Position = UDim2.new(1, -35, 0, 10)
CloseBtn.Text = "X"; CloseBtn.TextColor3 = TEXT_S; CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.BackgroundTransparency = 1
CloseBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

mkDivider(50)

-- BODY
mkLabel("SYSTEM ACTIVE", 10, Enum.Font.GothamBold, CYAN, UDim2.new(0, 15, 0, 65))

-- Status Card
local StatCard = Instance.new("Frame", F)
StatCard.Size = UDim2.new(1, -30, 0, 35); StatCard.Position = UDim2.new(0, 15, 0, 85)
StatCard.BackgroundColor3 = BG_CARD; StatCard.BorderSizePixel = 0
Instance.new("UICorner", StatCard).CornerRadius = UDim.new(0, 4)

SDot = Instance.new("Frame", StatCard)
SDot.Size = UDim2.new(0, 4, 0, 15); SDot.Position = UDim2.new(0, 10, 0.5, -7.5)
SDot.BackgroundColor3 = CYAN; SDot.BorderSizePixel = 0

SVl = mkLabel("» STANDBY", 11, Enum.Font.Code, WHITE, UDim2.new(0, 22, 0, 0), StatCard)
SVl.Size = UDim2.new(1, -30, 1, 0)

mkDivider(135)

-- Low Graphics
mkLabel("ENVIRONMENT OPTIMIZATION", 9, Enum.Font.GothamBold, TEXT_S, UDim2.new(0, 15, 0, 150))
local LGBtn = Instance.new("TextButton", F)
LGBtn.Size = UDim2.new(0, 60, 0, 24); LGBtn.Position = UDim2.new(1, -75, 0, 145)
LGBtn.BackgroundColor3 = BG_CARD; LGBtn.Text = "ON"; LGBtn.TextColor3 = CYAN
LGBtn.Font = Enum.Font.GothamBold; LGBtn.TextSize = 10
Instance.new("UICorner", LGBtn).CornerRadius = UDim.new(0, 4)
local lgState = true
LGBtn.MouseButton1Click:Connect(function()
    lgState = not lgState
    LGBtn.Text = lgState and "ON" or "OFF"
    LGBtn.TextColor3 = lgState and CYAN or TEXT_S
    if lgState then applyAntiLag() end
end)

mkDivider(185)

-- BUTTONS CP
mkLabel("TELEPORT PROTOCOL", 9, Enum.Font.GothamBold, TEXT_S, UDim2.new(0, 15, 0, 200))

local function mkCPBtn(name, index, pos)
    local b = Instance.new("TextButton", F)
    b.Size = UDim2.new(0, 120, 0, 40); b.Position = pos
    b.BackgroundColor3 = BG_CARD; b.Text = name; b.TextColor3 = WHITE
    b.Font = Enum.Font.GothamBold; b.TextSize = 11
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    local s = Instance.new("UIStroke", b); s.Color = LINE
    
    b.MouseButton1Click:Connect(function()
        runSequence(index)
    end)
    
    b.MouseEnter:Connect(function() s.Color = CYAN end)
    b.MouseLeave:Connect(function() s.Color = LINE end)
end

mkCPBtn("CHECKPOINT 1", 1, UDim2.new(0, 15, 0, 220))
mkCPBtn("CHECKPOINT 2", 2, UDim2.new(0, 145, 0, 220))

mkDivider(280)

-- FOOTER
mkLabel("TRANSMISSION", 9, Enum.Font.GothamBold, NEON_P, UDim2.new(0, 15, 0, 295))
local msg = mkLabel("The world is a stage, but the play is badly cast. Stay glitchy.", 9, Enum.Font.GothamItalic, TEXT_S, UDim2.new(0, 15, 0, 315))
msg.Size = UDim2.new(1, -30, 0, 30); msg.TextWrapped = true; msg.TextYAlignment = Enum.TextYAlignment.Top

mkDivider(355)

local Creator = mkLabel("CREATED BY HURUHARA", 10, Enum.Font.Code, CYAN, UDim2.new(0, 0, 0, 370))
Creator.Size = UDim2.new(1, 0, 0, 20); Creator.TextXAlignment = Enum.TextXAlignment.Center

-- Toggle F9
UIS.InputBegan:Connect(function(io, gpe)
    if not gpe and io.KeyCode == Enum.KeyCode.F9 then F.Visible = not F.Visible end
end)

applyAntiLag()
print("GSK CODE LOADED | BY HURUHARA")
