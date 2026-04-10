--[[
    SAKAHAYANG_OS [ULTRA REFACTOR]
    VERSION: 6.0 (NEURAL LINK)
    AUTHOR: HURUHARA
    
    FEATURES: 
    - Spatial Query Scanning (High Performance)
    - Adaptive Wait Protocol
    - Cyber-Futuristic Responsive GUI
    - Android Multi-Touch (Pinch Zoom) Support
]]

local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local TweenSvc = game:GetService("TweenService")
local RunSvc   = game:GetService("RunService")
local player   = Players.LocalPlayer

-- CLEANUP
pcall(function()
    for _,g in ipairs(player.PlayerGui:GetChildren()) do
        if g.Name == "CyberZihanOS" then g:Destroy() end
    end
end)

-- CONFIGURATION & DATA
local CP_LIST = {
    Vector3.new(-312.329, 654.005, -952.673),
    Vector3.new(4356.271, 2238.856, -9533.901),
    -- Tambahkan koordinat baru di sini
}

local KEYWORDS  = {"claim","voucher","gopay","redemption","klaim","reward"}
local KNOWN_OBJ = {"RedemptionPointBasepart", "Gopay", "GopayPoint", "Primary", "VoucherPoint", "ClaimPoint", "Part"}

local STATE = {
    Running = false,
    Stopped = false,
    CurrentIndex = 1,
    UIScale = 1,
}

-- THEME COLORS
local NEON_BLUE   = Color3.fromRGB(0, 240, 255)
local NEON_PINK   = Color3.fromRGB(255, 0, 180)
local NEON_YELLOW = Color3.fromRGB(255, 220, 0)
local DARK_BG     = Color3.fromRGB(8, 9, 12)
local SURFACE_BG  = Color3.fromRGB(15, 17, 24)
local TEXT_DIM    = Color3.fromRGB(120, 130, 150)

-- UTILS
local function create(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    return obj
end

local function applyAntiLag()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        workspace.GlobalShadows = false
        for _, v in ipairs(game:GetService("Lighting"):GetChildren()) do
            if v:IsA("PostProcessEffect") then v.Enabled = false end
        end
    end)
end

-- DETECTION LOGIC (SPATIAL QUERY)
local function getPromptFromObject(obj)
    if not obj then return nil end
    local p = obj:FindFirstChildWhichIsA("ProximityPrompt")
    if p then return p end
    if obj.Parent then return obj.Parent:FindFirstChildWhichIsA("ProximityPrompt") end
    return nil
end

local function scanArea(center)
    local foundCandidates = {}
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    
    -- Multi-Radius Scan (50, 100, 200)
    for _, radius in ipairs({50, 100, 200}) do
        local parts = workspace:GetPartBoundsInRadius(center, radius, params)
        
        for _, part in ipairs(parts) do
            local name = part.Name:lower()
            local isMatch = false
            
            -- Pass 1 & 2: Name & Prompt
            for _, kw in ipairs(KEYWORDS) do if name:match(kw) then isMatch = true break end end
            for _, kn in ipairs(KNOWN_OBJ) do if name == kn:lower() then isMatch = true break end end
            
            local prompt = getPromptFromObject(part)
            if prompt or isMatch then
                table.insert(foundCandidates, {prompt = prompt, part = part, dist = (part.Position - center).Magnitude})
            end
        end
        
        if #foundCandidates > 0 then break end -- Early exit if found in smaller radius
    end
    
    -- Pass 3: Fallback GetDescendants (Only if Spatial Query fails)
    if #foundCandidates == 0 then
        for _, v in ipairs(workspace:GetDescendants()) do
            if (v:IsA("ProximityPrompt")) and (v.Parent:IsA("BasePart")) then
                local d = (v.Parent.Position - center).Magnitude
                if d <= 200 then
                    table.insert(foundCandidates, {prompt = v, part = v.Parent, dist = d})
                end
            end
        end
    end
    
    table.sort(foundCandidates, function(a, b) return a.dist < b.dist end)
    return foundCandidates
end

-- ADAPTIVE INTERACTION
local function executeClaim(targetPart, prompt)
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    
    -- Move to safe offset
    local offset = (hrp.Position - targetPart.Position).Unit * 5
    hrp.CFrame = CFrame.new(targetPart.Position + offset + Vector3.new(0, 3, 0))
    task.wait(0.2)
    
    local success = false
    for _ = 1, 3 do
        fireproximityprompt(prompt)
        task.wait(0.1)
        -- Check if still exists or UI changed (simple check)
        if not prompt.Parent then success = true break end
    end
    
    -- Reposition Fallback
    if not success then
        hrp.CFrame = CFrame.new(targetPart.Position)
        task.wait(0.1)
        fireproximityprompt(prompt)
    end
end

-- UI SYSTEM
local SG = create("ScreenGui", {Name = "CyberZihanOS", ResetOnSpawn = false, Parent = player.PlayerGui})
local UScale = create("UIScale", {Parent = SG})

local Main = create("Frame", {
    Size = UDim2.new(0, 320, 0, 400),
    Position = UDim2.new(0.5, -160, 0.5, -200),
    BackgroundColor3 = DARK_BG,
    BorderSizePixel = 0,
    Active = true,
    Draggable = true,
    Parent = SG
})
create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = Main})
create("UIStroke", {Color = NEON_BLUE, Thickness = 1.5, Parent = Main})

-- Status Bar
local StatBar = create("Frame", {
    Size = UDim2.new(1, -20, 0, 30),
    Position = UDim2.new(0, 10, 0, 50),
    BackgroundColor3 = SURFACE_BG,
    Parent = Main
})
local StatText = create("TextLabel", {
    Size = UDim2.new(1, -10, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1,
    Text = "SYSTEM_IDLE",
    TextColor3 = NEON_YELLOW,
    Font = Enum.Font.Code,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = StatBar
})

-- Progress Bar
local ProgBack = create("Frame", {
    Size = UDim2.new(1, -20, 0, 4),
    Position = UDim2.new(0, 10, 0, 85),
    BackgroundColor3 = SURFACE_BG,
    Parent = Main
})
local ProgFill = create("Frame", {
    Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = NEON_BLUE,
    BorderSizePixel = 0,
    Parent = ProgBack
})

local function updateUI(status, col, progress)
    StatText.Text = "LOG >> " .. status:upper()
    StatText.TextColor3 = col
    TweenSvc:Create(ProgFill, TweenInfo.new(0.3), {Size = UDim2.new(progress, 0, 1, 0)}):Play()
end

-- CORE LOGIC: GOTO CP
local function navigateToCP(index)
    local target = CP_LIST[index]
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end
    
    STATE.CurrentIndex = index
    updateUI("Warping to CP_" .. index, NEON_PINK, index/#CP_LIST)
    
    hrp.CFrame = CFrame.new(target + Vector3.new(0, 5, 0))
    
    -- Adaptive Wait for StreamingEnabled
    local found = false
    local start = tick()
    while tick() - start < 4 do -- Max 4s timeout
        local candidates = scanArea(target)
        if #candidates > 0 then
            updateUI("Target Detected!", NEON_BLUE, index/#CP_LIST)
            executeClaim(candidates[1].part, candidates[1].prompt)
            found = true
            break
        end
        task.wait(0.2)
        if STATE.Stopped then break end
    end
    
    if not found then
        updateUI("No Target at CP_" .. index, TEXT_DIM, index/#CP_LIST)
    end
end

-- MAIN BUTTONS
local function createBtn(text, pos, size, col, callback)
    local btn = create("TextButton", {
        Size = size,
        Position = pos,
        BackgroundColor3 = SURFACE_BG,
        Text = text,
        TextColor3 = col,
        Font = Enum.Font.Code,
        TextSize = 13,
        Parent = Main
    })
    create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = btn})
    local stroke = create("UIStroke", {Color = col, Thickness = 1, Parent = btn})
    
    btn.MouseButton1Click:Connect(function()
        TweenSvc:Create(btn, TweenInfo.new(0.1), {BackgroundTransparency = 0.5}):Play()
        task.wait(0.1)
        TweenSvc:Create(btn, TweenInfo.new(0.1), {BackgroundTransparency = 0}):Play()
        callback()
    end)
    return btn
end

createBtn("AUTO_START", UDim2.new(0, 10, 0, 340), UDim2.new(0, 145, 0, 45), NEON_BLUE, function()
    if STATE.Running then return end
    STATE.Running = true
    STATE.Stopped = false
    task.spawn(function()
        for i = 1, #CP_LIST do
            if STATE.Stopped then break end
            navigateToCP(i)
            task.wait(0.5)
        end
        updateUI("All Protocols Finished", NEON_YELLOW, 1)
        STATE.Running = false
        game:GetService("StarterGui"):SetCore("SendNotification", {Title = "OS_STATUS", Text = "Sequence Complete."})
    end)
end)

createBtn("STOP_PROC", UDim2.new(1, -155, 0, 340), UDim2.new(0, 145, 0, 45), NEON_PINK, function()
    STATE.Stopped = true
    STATE.Running = false
    updateUI("Manual Override Active", NEON_PINK, 0)
end)

-- ANDROID PINCH ZOOM SUPPORT
local lastDist = 0
UIS.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        local touches = UIS:GetTouches()
        if #touches == 2 then
            local p1 = touches[1].Position
            local p2 = touches[2].Position
            local dist = (p1 - p2).Magnitude
            if lastDist > 0 then
                local delta = (dist - lastDist) * 0.005
                STATE.UIScale = math.clamp(STATE.UIScale + delta, 0.5, 2)
                UScale.Scale = STATE.UIScale
            end
            lastDist = dist
        end
    end
end)
UIS.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then lastDist = 0 end end)

-- MOBILE DRAG SUPPORT (BETTER)
local dragging, dragInput, dragStart, startPos
Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UIS.InputEnded:Connect(function(input) dragging = false end)

-- TITLE & DECOR
local Title = create("TextLabel", {
    Size = UDim2.new(1, -20, 0, 40),
    Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1,
    Text = "SAKAHAYANG_NETWORKS v6.0",
    TextColor3 = WHT,
    Font = Enum.Font.Code,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = Main
})

-- Initialize
task.spawn(applyAntiLag)
updateUI("Ready for Neural Link", NEON_YELLOW, 0)
print("Sakahayang OS v6.0 Initialized | F9 for Debug")
