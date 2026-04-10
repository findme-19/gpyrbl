--[[
  AUTO CLAIM GSK CODE - CYBERPUNK EDITION
  CREATED BY HURUHARA
]]

local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local TweenSvc = game:GetService("TweenService")
local player   = Players.LocalPlayer

-- Data Koordinat
local DATA = {
    [1] = {
        TARGET = Vector3.new(-312.329, 654.005, -952.673),
        NEAR   = Vector3.new(-307.023, 653.096, -957.354)
    },
    [2] = {
        TARGET = Vector3.new(4356.271, 2238.856, -9533.901),
        NEAR   = Vector3.new(4353.229, 2237.096, -9544.040)
    }
}

pcall(function()
    for _,g in ipairs(player.PlayerGui:GetChildren()) do
        if g.Name=="SakahayangAlfian" then g:Destroy() end
    end
end)

local function applyAntiLag()
    pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Level01 end)
    pcall(function() workspace.GlobalShadows=false end)
    pcall(function()
        local L=game:GetService("Lighting")
        for _,v in ipairs(L:GetChildren()) do
            if v:IsA("PostProcessEffect") or v:IsA("BlurEffect") then v.Enabled=false end
        end
    end)
end

local running = false
local SVl, SDot, ALBtn

-- Warna Cyberpunk
local NEON_BLUE = Color3.fromRGB(0, 255, 255)
local NEON_PINK = Color3.fromRGB(255, 0, 150)
local NEON_GREEN = Color3.fromRGB(50, 255, 100)
local DARK_BG = Color3.fromRGB(10, 10, 15)
local CARD_BG = Color3.fromRGB(20, 20, 28)
local GRID_LINE = Color3.fromRGB(40, 40, 60)
local TEXT_MAIN = Color3.fromRGB(220, 220, 230)

local function setStatus(msg, col)
    if not SVl then return end
    SVl.Text = "» " .. msg
    local c = col == "done" and NEON_GREEN or col == "err" and NEON_PINK or NEON_BLUE
    SVl.TextColor3 = c
    if SDot then SDot.BackgroundColor3 = c end
end

local function findPrompt(targetPos)
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local p = v.Parent
            local pos = (p:IsA("BasePart") and p.Position) or (p:IsA("Model") and p.PrimaryPart and p.PrimaryPart.Position)
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
    local config = DATA[index]
    
    task.spawn(function()
        setStatus("INITIATING CP"..index, "wait")
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if not hrp then setStatus("FAILURE", "err"); running = false; return end
        
        hrp.CFrame = CFrame.new(config.NEAR + Vector3.new(0, 3, 0))
        task.wait(0.5)
        
        setStatus("SCANNING OBJECT", "wait")
        local pr, _ = findPrompt(config.TARGET)
        
        if pr then
            fireproximityprompt(pr)
            setStatus("CP"..index.." CLAIMED", "done")
        else
            setStatus("MANUAL CLAIM READY", "done")
        end
        running = false
    end)
end

-- GUI SETUP
local sg = Instance.new("ScreenGui", player.PlayerGui)
sg.Name = "SakahayangAlfian"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true

local F = Instance.new("Frame", sg)
F.Size = UDim2.new(0, 260, 0, 420)
F.Position = UDim2.new(0, 20, 0, 100)
F.BackgroundColor3 = DARK_BG; F.BorderSizePixel = 0; F.Active = true; F.Draggable = true
Instance.new("UICorner", F).CornerRadius = UDim.new(0, 4)
local border = Instance.new("UIStroke", F)
border.Color = GRID_LINE; border.Thickness = 2

-- UI HELPERS
local function mkL(par, txt, col, sz, font, xa)
    local l = Instance.new("TextLabel", par)
    l.BackgroundTransparency = 1; l.Text = txt; l.TextColor3 = col or TEXT_MAIN
    l.Font = font or Enum.Font.Code; l.TextSize = sz or 10
    l.TextXAlignment = xa or Enum.TextXAlignment.Left
    return l
end

local function mkLine(yp)
    local l = Instance.new("Frame", F)
    l.Size = UDim2.new(1, -20, 0, 1); l.Position = UDim2.new(0, 10, 0, yp)
    l.BackgroundColor3 = GRID_LINE; l.BorderSizePixel = 0
end

-- HEADER
local head = Instance.new("Frame", F)
head.Size = UDim2.new(1, 0, 0, 40); head.BackgroundColor3 = CARD_BG; head.BorderSizePixel = 0
mkL(head, " [ AUTO CLAIM GSK CODE ]", NEON_BLUE, 11, Enum.Font.RobotoMono).Position = UDim2.new(0, 10, 0, 0)

local XB = Instance.new("TextButton", head)
XB.Size = UDim2.new(0, 30, 0, 30); XB.Position = UDim2.new(1, -35, 0.5, -15)
XB.BackgroundTransparency = 1; XB.Text = "[X]"; XB.TextColor3 = NEON_PINK
XB.Font = Enum.Font.Code; XB.TextSize = 14
XB.MouseButton1Click:Connect(function() sg:Destroy() end)

mkLine(40)

-- BODY
mkL(F, "SYSTEM STATUS:", TEXT_MAIN, 9).Position = UDim2.new(0, 15, 0, 55)
local sysActive = mkL(F, "ONLINE", NEON_GREEN, 9, Enum.Font.CodeBold)
sysActive.Position = UDim2.new(0, 100, 0, 55)

-- Status Bar
local sc = Instance.new("Frame", F)
sc.Size = UDim2.new(1, -30, 0, 30); sc.Position = UDim2.new(0, 15, 0, 75)
sc.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Instance.new("UIStroke", sc).Color = GRID_LINE
SVl = mkL(sc, "» STANDBY", NEON_BLUE, 10); SVl.Size = UDim2.new(1, -10, 1, 0); SVl.Position = UDim2.new(0, 10, 0, 0)

mkLine(120)

-- Low Graphics Toggle
local lgFrame = Instance.new("Frame", F)
lgFrame.Size = UDim2.new(1, -30, 0, 30); lgFrame.Position = UDim2.new(0, 15, 0, 135)
lgFrame.BackgroundTransparency = 1
mkL(lgFrame, "OPTIMIZATION MODE", TEXT_MAIN, 9).Position = UDim2.new(0, 0, 0.5, -5)

ALBtn = Instance.new("TextButton", lgFrame)
ALBtn.Size = UDim2.new(0, 60, 0, 20); ALBtn.Position = UDim2.new(1, -60, 0.5, -10)
ALBtn.BackgroundColor3 = CARD_BG; ALBtn.Text = "OFF"; ALBtn.TextColor3 = NEON_PINK
ALBtn.Font = Enum.Font.CodeBold; ALBtn.TextSize = 10
Instance.new("UIStroke", ALBtn).Color = GRID_LINE

local lagState = false
ALBtn.MouseButton1Click:Connect(function()
    lagState = not lagState
    ALBtn.Text = lagState and "ON" or "OFF"
    ALBtn.TextColor3 = lagState and NEON_GREEN or NEON_PINK
    if lagState then applyAntiLag() end
end)

mkLine(180)

-- CP BUTTONS
local btnContainer = Instance.new("Frame", F)
btnContainer.Size = UDim2.new(1, -30, 0, 50); btnContainer.Position = UDim2.new(0, 15, 0, 200)
btnContainer.BackgroundTransparency = 1

local function mkCPBtn(idx, xPos)
    local b = Instance.new("TextButton", btnContainer)
    b.Size = UDim2.new(0.48, 0, 1, 0); b.Position = UDim2.new(xPos, 0, 0, 0)
    b.BackgroundColor3 = CARD_BG; b.Text = "EXECUTE CP" .. idx
    b.TextColor3 = NEON_BLUE; b.Font = Enum.Font.CodeBold; b.TextSize = 10
    local str = Instance.new("UIStroke", b); str.Color = NEON_BLUE; str.Thickness = 1
    
    b.MouseButton1Click:Connect(function() runSequence(idx) end)
    
    b.MouseEnter:Connect(function() b.BackgroundColor3 = NEON_BLUE; b.TextColor3 = DARK_BG end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = CARD_BG; b.TextColor3 = NEON_BLUE end)
end

mkCPBtn(1, 0)
mkCPBtn(2, 0.52)

mkLine(270)

-- FOOTER
local footer = Instance.new("Frame", F)
footer.Size = UDim2.new(1, 0, 0, 100); footer.Position = UDim2.new(0, 0, 0, 280)
footer.BackgroundTransparency = 1

local quote = mkL(footer, "Reality is a code waiting to be rewritten. Don't let the firewall stop you.", Color3.fromRGB(100, 100, 120), 8, Enum.Font.Code, Enum.TextXAlignment.Center)
quote.Size = UDim2.new(1, -40, 0, 40); quote.Position = UDim2.new(0, 20, 0, 10); quote.TextWrapped = true

mkLine(380)

local credits = mkL(F, "CREATED BY HURUHARA", NEON_PINK, 8, Enum.Font.CodeBold, Enum.TextXAlignment.Center)
credits.Size = UDim2.new(1, 0, 0, 20); credits.Position = UDim2.new(0, 0, 1, -25)

-- Toggle F9
UIS.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.F9 then F.Visible = not F.Visible end
end)

print("Cyberpunk Script Loaded | Creator: Huruhara")
