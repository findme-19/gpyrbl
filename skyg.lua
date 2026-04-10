
--[[
  AUTO CLAIM GSK CODE
  THEME: CYBERPUNK PROFESSIONAL
  CREATED BY: HURUHARA
]]

local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local TweenSvc = game:GetService("TweenService")
local player   = Players.LocalPlayer

-- Clean up existing GUI
pcall(function()
    for _,g in ipairs(player.PlayerGui:GetChildren()) do
        if g.Name=="SakahayangAlfian" then g:Destroy() end
    end
end)

-- ════════════════════════════════════════════════
-- CORE FUNCTIONS (UNTOUCHED)
-- ════════════════════════════════════════════════
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
            if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or
               v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or
               v:IsA("DepthOfFieldEffect") then v.Enabled=false end
        end
    end)
    pcall(function()
        for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Fire") or
               v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("Beam") then v.Enabled=false end
            if v:IsA("Decal") or v:IsA("Texture") then v.Transparency=1 end
        end
    end)
end

local function findPrompt()
    for _,v in ipairs(workspace:GetDescendants()) do
        if v.Name=="ProxyAttachment" then
            local pr=v:FindFirstChildOfClass("ProximityPrompt")
            if pr then return pr,v end
            if v.Parent then
                local pr2=v.Parent:FindFirstChildOfClass("ProximityPrompt")
                if pr2 then return pr2,v.Parent end
            end
        end
    end
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local at=(v.ActionText or ""):lower()
            local pn=(v.Parent and v.Parent.Name or ""):lower()
            if at:match("ambil") or at:match("hadiah") or
               at:match("claim") or at:match("voucher") or
               pn:match("proxy") or pn:match("attachment") then
                return v,v.Parent
            end
        end
    end
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local par=v.Parent
            if par then
                local pos
                if par:IsA("BasePart") then pos=par.Position
                elseif par:IsA("Model") then
                    local pp=par.PrimaryPart or par:FindFirstChildWhichIsA("BasePart")
                    pos=pp and pp.Position
                end
                if pos then return v,par end
            end
        end
    end
    return nil,nil
end

local function getObjPos(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local pp=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        return pp and pp.Position
    end
    if obj:IsA("Attachment") then return obj.WorldPosition end
    return nil
end

-- ════════════════════════════════════════════════
-- CONFIG & STATE
-- ════════════════════════════════════════════════
local CP_DATA = {
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
local SVl, SDot, ALBtn

-- Cyberpunk Colors
local BG_MAIN = Color3.fromRGB(10, 10, 15)
local ACCENT  = Color3.fromRGB(0, 255, 255) -- Cyan
local SECOND  = Color3.fromRGB(255, 0, 150) -- Hot Pink
local TEXT_C  = Color3.fromRGB(200, 200, 220)
local LINE_C  = Color3.fromRGB(40, 40, 60)

local function setStatus(msg, col)
    if not SVl then return end
    SVl.Text = "> " .. msg
    local c = (col == "done" and Color3.fromRGB(0, 255, 150)) or (col == "err" and SECOND) or (col == "wait" and Color3.fromRGB(255, 200, 0)) or TEXT_C
    SVl.TextColor3 = c
    if SDot then SDot.BackgroundColor3 = c end
end

local function runSequence(index)
    if running then return end
    running = true
    local data = CP_DATA[index]
    
    task.spawn(function()
        setStatus("INITIALIZING CP"..index, "wait")
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if not hrp then setStatus("FAILURE: HRP", "err"); running = false; return end
        
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 0 end

        setStatus("TELEPORTING...", "wait")
        hrp.CFrame = CFrame.new(data.NEAR + Vector3.new(0, 5, 0))
        task.wait(0.4)

        setStatus("SCANNING AREA", "wait")
        local pr, obj = findPrompt()
        if obj then
            local pos = getObjPos(obj)
            if pos then
                local off = (data.NEAR - pos)
                off = off.Magnitude > 0.1 and off.Unit * 7 or Vector3.new(0, 0, 7)
                hrp.CFrame = CFrame.new(pos + off + Vector3.new(0, 3, 0))
                task.wait(0.3)
            end
        end

        if hum then hum.WalkSpeed = 16 end
        setStatus("CLAIMING...", "wait")

        local fired = false
        if pr then
            for _=1,3 do
                pcall(function() fireproximityprompt(pr) end)
                task.wait(0.1)
                fired = true
            end
        end

        setStatus("CP"..index.." COMPLETE", "done")
        running = false
    end)
end

-- ════════════════════════════════════════════════
-- UI CONSTRUCTION
-- ════════════════════════════════════════════════
local sg = Instance.new("ScreenGui")
sg.Name = "SakahayangAlfian"; sg.ResetOnSpawn = false
sg.Parent = player.PlayerGui

local F = Instance.new("Frame", sg)
F.Size = UDim2.new(0, 240, 0, 380)
F.Position = UDim2.new(0.5, -120, 0.4, -190)
F.BackgroundColor3 = BG_MAIN
F.BorderSizePixel = 0
F.Active = true
F.Draggable = true
do
    Instance.new("UICorner", F).CornerRadius = UDim.new(0, 4)
    local s = Instance.new("UIStroke", F)
    s.Color = LINE_C
    s.Thickness = 2
end

-- Header Section
local Header = Instance.new("Frame", F)
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
Header.BorderSizePixel = 0
do
    local c = Instance.new("UICorner", Header)
    c.CornerRadius = UDim.new(0, 4)
    local b = Instance.new("Frame", Header)
    b.Size = UDim2.new(1, 0, 0, 1)
    b.Position = UDim2.new(0, 0, 1, 0)
    b.BackgroundColor3 = ACCENT
    b.BorderSizePixel = 0
end

local Title = Instance.new("TextLabel", Header)
Title.Text = "AUTO CLAIM GSK CODE"
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.Font = Enum.Font.GothamBold
Title.TextColor3 = ACCENT
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Text = "X"
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0.5, -15)
CloseBtn.BackgroundTransparency = 1
CloseBtn.TextColor3 = SECOND
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

-- Helper: Divider
local function addDivider(yp)
    local d = Instance.new("Frame", F)
    d.Size = UDim2.new(1, -24, 0, 1)
    d.Position = UDim2.new(0, 12, 0, yp)
    d.BackgroundColor3 = LINE_C
    d.BorderSizePixel = 0
end

-- Body Text: System Active
local sysActive = Instance.new("TextLabel", F)
sysActive.Text = "SYSTEM ACTIVE"
sysActive.Size = UDim2.new(1, 0, 0, 30)
sysActive.Position = UDim2.new(0, 0, 0, 50)
sysActive.Font = Enum.Font.GothamBold
sysActive.TextColor3 = SECOND
sysActive.TextSize = 10
sysActive.BackgroundTransparency = 1

-- Status Box
local statusBox = Instance.new("Frame", F)
statusBox.Size = UDim2.new(1, -24, 0, 40)
statusBox.Position = UDim2.new(0, 12, 0, 85)
statusBox.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
statusBox.BorderSizePixel = 0
do Instance.new("UICorner", statusBox) end

SDot = Instance.new("Frame", statusBox)
SDot.Size = UDim2.new(0, 4, 0, 12)
SDot.Position = UDim2.new(0, 10, 0.5, -6)
SDot.BackgroundColor3 = ACCENT
SDot.BorderSizePixel = 0

SVl = Instance.new("TextLabel", statusBox)
SVl.Text = "> READY"
SVl.Size = UDim2.new(1, -30, 1, 0)
SVl.Position = UDim2.new(0, 20, 0, 0)
SVl.Font = Enum.Font.Code
SVl.TextColor3 = ACCENT
SVl.TextSize = 11
SVl.TextXAlignment = Enum.TextXAlignment.Left
SVl.BackgroundTransparency = 1

addDivider(135)

-- Low Graphics Row
local LGFrame = Instance.new("Frame", F)
LGFrame.Size = UDim2.new(1, -24, 0, 40)
LGFrame.Position = UDim2.new(0, 12, 0, 145)
LGFrame.BackgroundTransparency = 1

local LGTxt = Instance.new("TextLabel", LGFrame)
LGTxt.Text = "LOW GRAPHICS"
LGTxt.Size = UDim2.new(0.6, 0, 1, 0)
LGTxt.Font = Enum.Font.GothamBold
LGTxt.TextColor3 = TEXT_C
LGTxt.TextSize = 10
LGTxt.TextXAlignment = Enum.TextXAlignment.Left
LGTxt.BackgroundTransparency = 1

ALBtn = Instance.new("TextButton", LGFrame)
ALBtn.Size = UDim2.new(0, 50, 0, 22)
ALBtn.Position = UDim2.new(1, -50, 0.5, -11)
ALBtn.BackgroundColor3 = SECOND
ALBtn.Text = "ON"
ALBtn.Font = Enum.Font.GothamBold
ALBtn.TextSize = 10
ALBtn.TextColor3 = Color3.new(1,1,1)
do Instance.new("UICorner", ALBtn) end

local alState = true
ALBtn.MouseButton1Click:Connect(function()
    alState = not alState
    ALBtn.Text = alState and "ON" or "OFF"
    ALBtn.BackgroundColor3 = alState and SECOND or LINE_C
    if alState then applyAntiLag() end
end)

addDivider(195)

-- CP Buttons
local function mkCPBtn(name, pos, index)
    local btn = Instance.new("TextButton", F)
    btn.Name = name
    btn.Size = UDim2.new(0.5, -16, 0, 45)
    btn.Position = pos
    btn.BackgroundColor3 = BG_MAIN
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = ACCENT
    btn.TextSize = 12
    do
        Instance.new("UICorner", btn)
        local s = Instance.new("UIStroke", btn)
        s.Color = ACCENT
    end
    btn.MouseButton1Click:Connect(function()
        runSequence(index)
    end)
    return btn
end

mkCPBtn("CHECKPOINT 1", UDim2.new(0, 12, 0, 210), 1)
mkCPBtn("CHECKPOINT 2", UDim2.new(0.5, 4, 0, 210), 2)

-- Footer Section
addDivider(275)

local footerMsg = Instance.new("TextLabel", F)
footerMsg.Text = "Neon lights don't hide the truth in the code."
footerMsg.Size = UDim2.new(1, -24, 0, 40)
footerMsg.Position = UDim2.new(0, 12, 0, 285)
footerMsg.Font = Enum.Font.GothamItalic
footerMsg.TextColor3 = Color3.fromRGB(100, 100, 120)
footerMsg.TextSize = 9
footerMsg.TextWrapped = true
footerMsg.BackgroundTransparency = 1

local creator = Instance.new("TextLabel", F)
creator.Text = "CREATED BY HURUHARA"
creator.Size = UDim2.new(1, 0, 0, 20)
creator.Position = UDim2.new(0, 0, 1, -30)
creator.Font = Enum.Font.GothamBold
creator.TextColor3 = ACCENT
creator.TextSize = 9
creator.BackgroundTransparency = 1

local endTxt = Instance.new("TextLabel", F)
endTxt.Text = "END TRANSMISSION"
endTxt.Size = UDim2.new(1, 0, 0, 20)
endTxt.Position = UDim2.new(0, 0, 1, -15)
endTxt.Font = Enum.Font.Code
endTxt.TextColor3 = LINE_C
endTxt.TextSize = 8
endTxt.BackgroundTransparency = 1

-- Initial Anti Lag
task.spawn(function() task.wait(0.5); applyAntiLag() end)

-- Toggle Visibility
UIS.InputBegan:Connect(function(inp, gpe)
    if not gpe and inp.KeyCode == Enum.KeyCode.F9 then
        F.Visible = not F.Visible
    end
end)

print("Cyberpunk GUI Loaded | Developed by Huruhara")
