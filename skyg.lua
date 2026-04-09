--[[   MOUNT SAKAHAYANG PREMIUM   BY ALFIAN (UPGRADED) ]]

local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local TweenSvc = game:GetService("TweenService")
local player   = Players.LocalPlayer

-- ================= CONFIG =================
local CHECKPOINTS = {
    ["CP 1"] = {
        TARGET = Vector3.new(-313.5,653.1,-945.6),
        NEAR   = Vector3.new(-313.5,653.1,-940.6)
    },
    ["CP 2"] = {
        TARGET = Vector3.new(4357.5,2237.1,-9544.7),
        NEAR   = Vector3.new(4357.5,2237.1,-9536.7)
    }
}

local CP_ORDER = {"CP 1","CP 2"}
local AUTO_MODE = false
local running = false

-- ================= ANTI LAG =================
local function applyAntiLag()
    pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Level01 end)
    pcall(function() workspace.GlobalShadows=false end)
end

-- ================= STATUS =================
local SVl
local function setStatus(msg)
    if SVl then SVl.Text = msg end
end

-- ================= SAFE TELEPORT =================
local function safeTeleport(hrp, pos)
    hrp.CFrame = CFrame.new(pos + Vector3.new(0,5,0))
    task.wait(0.4)
    hrp.Velocity = Vector3.zero
end

-- ================= FIND PROMPT =================
local function findPromptSmart()
    for i=1,3 do
        for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                local txt = (v.ActionText or ""):lower()
                if txt:match("ambil") or txt:match("claim") or txt:match("hadiah") then
                    return v, v.Parent
                end
            end
        end
        task.wait(0.5)
    end
    return nil,nil
end

-- ================= RUN CP =================
local function runCP(name)
    local cp = CHECKPOINTS[name]
    if not cp then return false end

    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart",5)
    if not hrp then return false end

    setStatus("TP "..name)

    safeTeleport(hrp, cp.NEAR)
    task.wait(2)

    setStatus("SCAN "..name)

    local pr = findPromptSmart()

    if pr then
        setStatus("CLAIM "..name)

        for i=1,5 do
            pcall(function()
                fireproximityprompt(pr)
            end)
            task.wait(0.2)
        end

        setStatus("DONE "..name)
        return true
    else
        setStatus("SKIP "..name)
        return false
    end
end

-- ================= AUTO FARM =================
local function autoFarm()
    if AUTO_MODE then return end
    AUTO_MODE = true

    task.spawn(function()
        while AUTO_MODE do
            for _,name in ipairs(CP_ORDER) do
                if not AUTO_MODE then break end

                running = true
                local success = runCP(name)
                running = false

                if success then
                    task.wait(1.5)
                else
                    task.wait(1)
                end
            end
        end
        setStatus("AUTO STOP")
    end)
end

local function stopAuto()
    AUTO_MODE = false
end

-- ================= GUI =================
local sg = Instance.new("ScreenGui", player.PlayerGui)
sg.Name = "SakahayangPremium"

local F = Instance.new("Frame", sg)
F.Size = UDim2.new(0,260,0,200)
F.Position = UDim2.new(0,20,0,60)
F.BackgroundColor3 = Color3.fromRGB(20,20,25)
F.Active = true
F.Draggable = true

Instance.new("UICorner",F)

-- TITLE
local title = Instance.new("TextLabel",F)
title.Size = UDim2.new(1,0,0,30)
title.Text = "MOUNT SAKAHAYANG PREMIUM"
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 12

-- STATUS
SVl = Instance.new("TextLabel",F)
SVl.Size = UDim2.new(1,0,0,20)
SVl.Position = UDim2.new(0,0,0,30)
SVl.Text = "READY"
SVl.TextColor3 = Color3.fromRGB(150,255,150)
SVl.BackgroundTransparency = 1
SVl.Font = Enum.Font.GothamBold
SVl.TextSize = 10

-- START BUTTON
local startBtn = Instance.new("TextButton",F)
startBtn.Size = UDim2.new(1,-40,0,30)
startBtn.Position = UDim2.new(0,20,0,60)
startBtn.Text = "RUN 1x"
startBtn.BackgroundColor3 = Color3.fromRGB(200,200,200)
startBtn.TextColor3 = Color3.new(0,0,0)
Instance.new("UICorner",startBtn)

startBtn.MouseButton1Click:Connect(function()
    if running then return end
    running = true
    runCP("CP 1")
    running = false
end)

-- AUTO BUTTON
local autoBtn = Instance.new("TextButton",F)
autoBtn.Size = UDim2.new(1,-40,0,30)
autoBtn.Position = UDim2.new(0,20,0,100)
autoBtn.Text = "AUTO FARM"
autoBtn.BackgroundColor3 = Color3.fromRGB(200,170,90)
autoBtn.TextColor3 = Color3.new(0,0,0)
Instance.new("UICorner",autoBtn)

autoBtn.MouseButton1Click:Connect(function()
    if AUTO_MODE then
        stopAuto()
        autoBtn.Text = "AUTO FARM"
    else
        autoFarm()
        autoBtn.Text = "STOP AUTO"
    end
end)

-- TOGGLE UI
UIS.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.F9 then
        F.Visible = not F.Visible
    end
end)

-- INIT
task.spawn(function()
    task.wait(0.5)
    applyAntiLag()
end)

print("Premium Script Loaded ✅")
