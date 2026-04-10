--[[
  AUTO CLAIM GSK CODE
  THEME: CYBERPUNK PROFESSIONAL
  RE-DESIGNED BY GEMINI (HURUHARA)
]]

local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local TweenSvc = game:GetService("TweenService")
local player   = Players.LocalPlayer

-- Check for existing GUI
pcall(function()
    for _,g in ipairs(player.PlayerGui:GetChildren()) do
        if g.Name=="SakahayangAlfian" then g:Destroy() end
    end
end)

-- Original Data Positions
local LOCATIONS = {
    [1] = {
        TARGET = Vector3.new(-312.329, 654.005, -952.673),
        NEAR   = Vector3.new(-307.023, 653.096, -957.354)
    },
    [2] = {
        TARGET = Vector3.new(4356.271, 2238.856, -9533.901),
        NEAR   = Vector3.new(4353.229, 2237.096, -9544.040)
    }
}

local CURRENT_TARGET = LOCATIONS[2].TARGET
local CURRENT_NEAR   = LOCATIONS[2].NEAR
local running = false

-- Cyberpunk Color Palette
local PINK  = Color3.fromRGB(255, 0, 153)
local BLUE  = Color3.fromRGB(0, 255, 255)
local BG    = Color3.fromRGB(10, 10, 15)
local CARD  = Color3.fromRGB(20, 20, 28)
local LINE  = Color3.fromRGB(40, 40, 55)
local WHITE = Color3.fromRGB(240, 240, 240)
local GRAY  = Color3.fromRGB(120, 120, 130)

-- Existing Logic (Unchanged)
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

local SVl, SDot, ALBtn
local function setStatus(msg, col)
    if not SVl then return end
    SVl.Text = "» " .. msg
    local c = (col == "done" and BLUE) or (col == "err" and PINK) or (col == "wait" and Color3.fromRGB(255, 200, 0)) or WHITE
    SVl.TextColor3 = c
    if SDot then SDot.BackgroundColor3 = c end
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
                if pos and (pos-CURRENT_TARGET).Magnitude<120 then return v,par end
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

local function runSequence()
    if running then return end
    running=true
    task.spawn(function()
        setStatus("CONNECTING...","wait"); task.wait(0.15)
        local char=player.Character or player.CharacterAdded:Wait()
        local hrp=char:WaitForChild("HumanoidRootPart",5)
        if not hrp then setStatus("ERROR: NO HRP","err");running=false;return end
        local hum=char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed=0 end

        setStatus("WARP TO SECTOR","wait")
        hrp.CFrame=CFrame.new(CURRENT_NEAR+Vector3.new(0,5,0)); task.wait(0.3)

        setStatus("SCANNING OBJECT","wait")
        local pr,obj=findPrompt()
        if obj then
            local pos=getObjPos(obj)
            if pos then
                local off=(CURRENT_NEAR-pos)
                off=off.Magnitude>0.1 and off.Unit*7 or Vector3.new(0,0,7)
                hrp.CFrame=CFrame.new(pos+off+Vector3.new(0,3,0)); task.wait(0.25)
            end
        end

        if hum then hum.WalkSpeed=16 end
        setStatus("INJECTING PROMPT","wait"); task.wait(0.12)

        local fired=false
        if pr then
            for _=1,3 do
                local ok=pcall(function() fireproximityprompt(pr) end)
                if ok then fired=true;break end
                task.wait(0.08)
            end
        end
        
        setStatus("ARRIVED — MANUAL CLAIM","done")
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title="SYSTEM NOTIFICATION",
                Text="Target reached. Proceed to manual claim.",
                Duration=3
            })
        end)
        running=false
    end)
end

-- ══════════════════════════════
-- NEW CYBERPUNK GUI DESIGN
-- ══════════════════════════════
local sg = Instance.new("ScreenGui")
sg.Name = "SakahayangAlfian"; sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true; sg.Parent = player.PlayerGui

local Main = Instance.new("Frame", sg)
Main.Size = UDim2.new(0, 260, 0, 420)
Main.Position = UDim2.new(0, 30, 0.5, -210)
Main.BackgroundColor3 = BG; Main.BorderSizePixel = 0
Main.Active = true; Main.Draggable = true

-- Glow Effect / Stroke
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = LINE; MainStroke.Thickness = 1.5

local TopBar = Instance.new("Frame", Main)
TopBar.Size = UDim2.new(1, 0, 0, 35)
TopBar.BackgroundColor3 = CARD; TopBar.BorderSizePixel = 0

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.Text = "AUTO CLAIM GSK CODE"
Title.Font = Enum.Font.GothamBold; Title.TextSize = 13
Title.TextColor3 = BLUE; Title.TextXAlignment = Enum.TextXAlignment.Left; Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -35, 0, 0)
CloseBtn.Text = "X"; CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextColor3 = PINK; CloseBtn.BackgroundTransparency = 1; CloseBtn.TextSize = 16
CloseBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

-- Helper Divider
local function addDivider(yp)
    local d = Instance.new("Frame", Main)
    d.Size = UDim2.new(1, -20, 0, 1)
    d.Position = UDim2.new(0, 10, 0, yp)
    d.BackgroundColor3 = LINE; d.BorderSizePixel = 0
end

-- SYSTEM ACTIVE TEXT
local sysLabel = Instance.new("TextLabel", Main)
sysLabel.Size = UDim2.new(1, 0, 0, 30)
sysLabel.Position = UDim2.new(0, 0, 0, 40)
sysLabel.Text = "[ SYSTEM ACTIVE ]"
sysLabel.Font = Enum.Font.GothamBold; sysLabel.TextSize = 10
sysLabel.TextColor3 = PINK; sysLabel.BackgroundTransparency = 1

-- STATUS BOX
local statusBox = Instance.new("Frame", Main)
statusBox.Size = UDim2.new(1, -24, 0, 40)
statusBox.Position = UDim2.new(0, 12, 0, 75)
statusBox.BackgroundColor3 = CARD; statusBox.BorderSizePixel = 0
Instance.new("UICorner", statusBox).CornerRadius = UDim.new(0, 4)

SDot = Instance.new("Frame", statusBox)
SDot.Size = UDim2.new(0, 4, 0, 20)
SDot.Position = UDim2.new(0, 8, 0.5, -10)
SDot.BackgroundColor3 = BLUE; SDot.BorderSizePixel = 0

SVl = Instance.new("TextLabel", statusBox)
SVl.Size = UDim2.new(1, -25, 1, 0)
SVl.Position = UDim2.new(0, 20, 0, 0)
SVl.Text = "» READY"
SVl.Font = Enum.Font.Code; SVl.TextSize = 11
SVl.TextColor3 = WHITE; SVl.TextXAlignment = Enum.TextXAlignment.Left; SVl.BackgroundTransparency = 1

addDivider(125)

-- LOW GRAPHICS TOGGLE
local lgFrame = Instance.new("Frame", Main)
lgFrame.Size = UDim2.new(1, -24, 0, 35)
lgFrame.Position = UDim2.new(0, 12, 0, 135)
lgFrame.BackgroundTransparency = 1

local lgTxt = Instance.new("TextLabel", lgFrame)
lgTxt.Size = UDim2.new(0.6, 0, 1, 0)
lgTxt.Text = "⚡ LOW GRAPHICS"
lgTxt.Font = Enum.Font.GothamBold; lgTxt.TextSize = 10
lgTxt.TextColor3 = GRAY; lgTxt.TextXAlignment = Enum.TextXAlignment.Left; lgTxt.BackgroundTransparency = 1

ALBtn = Instance.new("TextButton", lgFrame)
ALBtn.Size = UDim2.new(0, 50, 0, 22)
ALBtn.Position = UDim2.new(1, -50, 0.5, -11)
ALBtn.BackgroundColor3 = PINK; ALBtn.Text = "ON"
ALBtn.Font = Enum.Font.GothamBold; ALBtn.TextSize = 10; ALBtn.TextColor3 = BG
Instance.new("UICorner", ALBtn).CornerRadius = UDim.new(0, 4)

local alState = true
ALBtn.MouseButton1Click:Connect(function()
    alState = not alState
    ALBtn.Text = alState and "ON" or "OFF"
    ALBtn.BackgroundColor3 = alState and PINK or LINE
    ALBtn.TextColor3 = alState and BG or GRAY
    if alState then applyAntiLag() end
end)

addDivider(180)

-- CHECKPOINT BUTTONS
local function mkBtn(name, pos, xPos)
    local btn = Instance.new("TextButton", Main)
    btn.Size = UDim2.new(0, 110, 0, 40)
    btn.Position = UDim2.new(0, xPos, 0, 200)
    btn.BackgroundColor3 = BG; btn.Text = name
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 11
    btn.TextColor3 = BLUE; btn.BorderSizePixel = 0
    Instance.new("UIStroke", btn).Color = BLUE
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    btn.MouseButton1Click:Connect(function()
        if running then return end
        CURRENT_TARGET = LOCATIONS[pos].TARGET
        CURRENT_NEAR   = LOCATIONS[pos].NEAR
        runSequence()
    end)
end

mkBtn("▣ CP-1 (SEC1)", 1, 12)
mkBtn("▣ CP-2 (SEC2)", 2, 138)

addDivider(260)

-- FOOTER INFO
local footerTxt = Instance.new("TextLabel", Main)
footerTxt.Size = UDim2.new(1, -24, 0, 60)
footerTxt.Position = UDim2.new(0, 12, 0, 270)
footerTxt.Text = "Protocol initiated. Ghost in the shell detected. Stay in the shadows, samurai."
footerTxt.Font = Enum.Font.Gotham; footerTxt.TextSize = 10
footerTxt.TextColor3 = GRAY; footerTxt.TextWrapped = true; footerTxt.TextXAlignment = Enum.TextXAlignment.Left; footerTxt.BackgroundTransparency = 1

addDivider(340)

-- CREATOR TAG
local creator = Instance.new("TextLabel", Main)
creator.Size = UDim2.new(1, 0, 0, 30)
creator.Position = UDim2.new(0, 0, 0, 350)
creator.Text = "CREATED BY HURUHARA"
creator.Font = Enum.Font.Code; creator.TextSize = 10
creator.TextColor3 = GRAY; creator.BackgroundTransparency = 1

local endTag = Instance.new("TextLabel", Main)
endTag.Size = UDim2.new(1, 0, 0, 20)
endTag.Position = UDim2.new(0, 0, 0, 380)
endTag.Text = "— END OF LINE —"
endTag.Font = Enum.Font.GothamBold; endTag.TextSize = 9
endTag.TextColor3 = LINE; endTag.BackgroundTransparency = 1

-- F9 Toggle
UIS.InputBegan:Connect(function(inp, gpe)
    if not gpe and inp.KeyCode == Enum.KeyCode.F9 then Main.Visible = not Main.Visible end
end)

task.spawn(function() task.wait(0.5); applyAntiLag() end)
print("Auto Claim GSK | Theme: Cyberpunk | By Huruhara")
