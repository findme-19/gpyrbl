--[[
  MOUNT SAKAHAYANG SCRIPT v2 (Dual Target)
  BY ALFIAN
]]

local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local TweenSvc = game:GetService("TweenService")
local player   = Players.LocalPlayer

-- Clean up existing UI
pcall(function()
    for _,g in ipairs(player.PlayerGui:GetChildren()) do
        if g.Name=="SakahayangAlfian" then g:Destroy() end
    end
end)

-- Multi-Target Configuration
local TARGETS = {
    [1] = {
        NAME   = "CHECKPOINT 1",
        TARGET = Vector3.new(-313.5, 653.1, -945.6),
        NEAR   = Vector3.new(-313.5, 653.1, -940.6)
    },
    [2] = {
        NAME   = "CHECKPOINT 2",
        TARGET = Vector3.new(4362.3, 2237.0, -9538.8),
        NEAR   = Vector3.new(4362.3, 2237.0, -9530.8)
    }
}

local running = false

-- Color Palette
local GR =Color3.fromRGB(150,255,170)
local RD2=Color3.fromRGB(255,90,90)
local YL =Color3.fromRGB(230,200,100)
local WHT=Color3.fromRGB(230,230,230)
local DIM=Color3.fromRGB(100,100,110)
local PNL=Color3.fromRGB(12,12,16)
local MID=Color3.fromRGB(18,18,24)
local SRF=Color3.fromRGB(24,24,32)
local BRD=Color3.fromRGB(36,36,48)
local BRD2=Color3.fromRGB(55,55,72)
local SIL=Color3.fromRGB(140,140,155)
local DEEP=Color3.fromRGB(7,7,10)
local GD =Color3.fromRGB(180,150,80)

local SVl, SDot

local function setStatus(msg,col)
    if not SVl then return end
    SVl.Text=msg
    local c=col=="done" and GR or col=="err" and RD2 or col=="wait" and YL or WHT
    SVl.TextColor3=c
    if SDot then SDot.BackgroundColor3=c end
end

local function applyAntiLag()
    pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Level01 end)
    pcall(function() workspace.GlobalShadows=false end)
    pcall(function()
        local L=game:GetService("Lighting")
        L.GlobalShadows=false; L.Brightness=1
        for _,v in ipairs(L:GetChildren()) do
            if v:IsA("PostProcessEffect") then v.Enabled=false end
        end
    end)
    pcall(function()
        for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Decal") or v:IsA("Texture") then v.Transparency=1 end
            if v:IsA("ParticleEmitter") then v.Enabled=false end
        end
    end)
end

local function findPrompt(targetPos)
    local bestPrompt, bestObj = nil, nil
    local minDistance = 120 -- Radius pencarian

    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local p = v.Parent
            if p then
                local pos = p:IsA("BasePart") and p.Position or (p:IsA("Model") and p:GetPivot().Position)
                if pos then
                    local dist = (pos - targetPos).Magnitude
                    if dist < minDistance then
                        minDistance = dist
                        bestPrompt = v
                        bestObj = p
                    end
                end
            end
        end
    end
    return bestPrompt, bestObj
end

local function runSequence(id)
    if running then return end
    running = true
    
    local data = TARGETS[id]
    task.spawn(function()
        setStatus("CONNECTING...","wait")
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if not hrp then setStatus("ERROR HRP","err"); running=false; return end
        
        setStatus("TELEPORTING "..id,"wait")
        hrp.CFrame = CFrame.new(data.NEAR + Vector3.new(0, 3, 0))
        task.wait(0.3)

        setStatus("SEARCHING PROMPT","wait")
        local pr, obj = findPrompt(data.TARGET)
        
        if pr then
            setStatus("AUTO CLAIMING","wait")
            for i = 1, 5 do -- Mencoba klaim 5 kali
                fireproximityprompt(pr)
                task.wait(0.1)
            end
            setStatus("SUCCESS CP "..id,"done")
        else
            setStatus("PROMPT NOT FOUND","err")
        end
        
        task.delay(2, function() setStatus("READY","done") end)
        running = false
    end)
end

-- ══════════════════════════════
-- GUI IMPLEMENTATION
-- ══════════════════════════════
local sg = Instance.new("ScreenGui", player.PlayerGui)
sg.Name = "SakahayangAlfian"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true

local F = Instance.new("Frame", sg)
F.Size = UDim2.new(0, 260, 0, 480)
F.Position = UDim2.new(0, 20, 0, 60)
F.BackgroundColor3 = PNL; F.BorderSizePixel = 0; F.Active = true; F.Draggable = true
Instance.new("UICorner", F).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", F).Color = BRD

-- Header (Mirip desain kamu sebelumnya)
local TB = Instance.new("Frame", F)
TB.Size = UDim2.new(1, 0, 0, 44); TB.BackgroundColor3 = DEEP; TB.BorderSizePixel = 0
Instance.new("UICorner", TB).CornerRadius = UDim.new(0, 10)

local TTitle = Instance.new("TextLabel", TB)
TTitle.Text = "🏔  MOUNT SAKAHAYANG"; TTitle.TextColor3 = WHT; TTitle.Font = Enum.Font.GothamBold
TTitle.TextSize = 10; TTitle.Size = UDim2.new(1, -40, 0, 44); TTitle.Position = UDim2.new(0, 15, 0, 0); TTitle.TextXAlignment = "Left"

-- Status Card
local sc = Instance.new("Frame", F)
sc.Size = UDim2.new(1, -24, 0, 30); sc.Position = UDim2.new(0, 12, 0, 55); sc.BackgroundColor3 = MID
Instance.new("UICorner", sc).CornerRadius = UDim.new(0, 6)
SVl = Instance.new("TextLabel", sc)
SVl.Size = UDim2.new(1, -30, 1, 0); SVl.Position = UDim2.new(0, 25, 0, 0); SVl.Text = "READY"; SVl.TextColor3 = GR
SVl.Font = Enum.Font.GothamBold; SVl.TextSize = 9; SVl.TextXAlignment = "Left"; SVl.BackgroundTransparency = 1
SDot = Instance.new("Frame", sc)
SDot.Size = UDim2.new(0, 6, 0, 6); SDot.Position = UDim2.new(0, 10, 0.5, -3); SDot.BackgroundColor3 = GR
Instance.new("UICorner", SDot).CornerRadius = UDim.new(1, 0)

-- Container for Dual Buttons
local btnContainer = Instance.new("Frame", F)
btnContainer.Size = UDim2.new(1, -24, 0, 40); btnContainer.Position = UDim2.new(0, 12, 0, 95); btnContainer.BackgroundTransparency = 1

local function createRunBtn(id, xPos)
    local b = Instance.new("TextButton", btnContainer)
    b.Size = UDim2.new(0.48, 0, 1, 0); b.Position = UDim2.new(xPos, 0, 0, 0)
    b.BackgroundColor3 = WHT; b.Text = "RUN CP "..id; b.Font = Enum.Font.GothamBold; b.TextSize = 10
    b.TextColor3 = DEEP; b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    
    b.MouseButton1Click:Connect(function()
        if not running then runSequence(id) end
    end)
    return b
end

local btn1 = createRunBtn(1, 0)
local btn2 = createRunBtn(2, 0.52)

-- Separator & Info
local sep = Instance.new("Frame", F)
sep.Size = UDim2.new(1, 0, 0, 1); sep.Position = UDim2.new(0, 0, 0, 150); sep.BackgroundColor3 = BRD; sep.BorderSizePixel = 0

-- Author & Info Section (Sama seperti sebelumnya)
local authLab = Instance.new("TextLabel", F)
authLab.Text = "OFFICIAL AUTHOR: ALFIAN"; authLab.Size = UDim2.new(1, 0, 0, 20); authLab.Position = UDim2.new(0, 0, 0, 160)
authLab.TextColor3 = GD; authLab.Font = Enum.Font.GothamBold; authLab.TextSize = 8; authLab.BackgroundTransparency = 1

-- F9 Toggle
UIS.InputBegan:Connect(function(inp, gpe)
    if not gpe and inp.KeyCode == Enum.KeyCode.F9 then F.Visible = not F.Visible end
end)

applyAntiLag()
print("Mount Sakahayang Loaded | Dual Target | F9 to Toggle")
