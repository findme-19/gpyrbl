--[[ SAKAHAYANG STEALTH UI — BALANCED VERSION ]]

local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local PPS     = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer

-- ================= CONFIG =================
local CP = {
	Vector3.new(-313.5,653.1,-945.6),
	Vector3.new(4357.5,2237.1,-9544.7)
}

local running = false
local mode = "SIMPLE" -- SIMPLE / FLEX
local activePrompt = nil
local currentCP = 0

-- ================= STATUS =================
local statusLbl
local function setStatus(t)
	if statusLbl then statusLbl.Text = t end
	print(t)
end

-- ================= HUMAN TP =================
local function humanTP(hrp, pos)
	local offset = Vector3.new(math.random(-3,3),3,math.random(-3,3))
	hrp.CFrame = CFrame.new(pos + offset)
	task.wait(math.random(30,60)/100)
end

-- ================= PROMPT FILTER =================
local KEYWORDS = {"claim","ambil","reward","hadiah","redeem"}

local function validPrompt(p)
	local t1 = (p.ActionText or ""):lower()
	local t2 = (p.ObjectText or ""):lower()
	for _,k in ipairs(KEYWORDS) do
		if t1:match(k) or t2:match(k) then
			return true
		end
	end
	return false
end

-- ================= EVENT =================
PPS.PromptShown:Connect(function(prompt)
	if running and validPrompt(prompt) then
		activePrompt = prompt
	end
end)

-- ================= CLAIM =================
local function tryClaim(hrp)
	if not activePrompt then return false end

	local part = activePrompt.Parent
	if not part or not part:IsA("BasePart") then return false end

	local dist = (part.Position - hrp.Position).Magnitude
	if dist > 15 then return false end

	hrp.CFrame = CFrame.new(part.Position + Vector3.new(0,2,0))
	task.wait(math.random(20,40)/100)

	pcall(function()
		fireproximityprompt(activePrompt)
	end)

	return true
end

-- ================= RUN CP =================
local function runCP(index)
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp  = char:WaitForChild("HumanoidRootPart",5)
	if not hrp then return end

	currentCP = index
	activePrompt = nil

	setStatus("➡️ CP "..index)

	humanTP(hrp, CP[index])

	local t = 0
	repeat
		task.wait(0.1)
		t += 0.1
	until (activePrompt or t > 3)

	if activePrompt then
		local ok = tryClaim(hrp)
		if ok then
			setStatus("✅ CLAIM CP "..index)
		else
			setStatus("⚠️ FAIL CP "..index)
		end
	else
		setStatus("❌ NO PROMPT CP "..index)
	end
end

-- ================= AUTO =================
local function runAll()
	if running then return end
	running = true

	for i=1,#CP do
		if not running then break end
		runCP(i)
		task.wait(1)
	end

	running = false
	setStatus("🎯 DONE")
end

local function stopRun()
	running = false
	setStatus("⛔ STOP")
end

-- ================= GUI =================
local sg = Instance.new("ScreenGui", player.PlayerGui)
sg.Name = "StealthUI"

local F = Instance.new("Frame", sg)
F.Size = UDim2.new(0,260,0,260)
F.Position = UDim2.new(0.5,-130,0.5,-130)
F.BackgroundColor3 = Color3.fromRGB(20,20,25)
F.Active = true
F.Draggable = true
Instance.new("UICorner",F)

-- TITLE
local title = Instance.new("TextLabel",F)
title.Size = UDim2.new(1,0,0,30)
title.Text = "STEALTH SAKAHAYANG"
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 12

-- STATUS
statusLbl = Instance.new("TextLabel",F)
statusLbl.Size = UDim2.new(1,0,0,20)
statusLbl.Position = UDim2.new(0,0,0,30)
statusLbl.Text = "READY"
statusLbl.TextColor3 = Color3.fromRGB(150,255,150)
statusLbl.BackgroundTransparency = 1
statusLbl.Font = Enum.Font.GothamBold
statusLbl.TextSize = 10

-- MODE BUTTON
local modeBtn = Instance.new("TextButton",F)
modeBtn.Size = UDim2.new(1,-40,0,25)
modeBtn.Position = UDim2.new(0,20,0,55)
modeBtn.Text = "MODE: SIMPLE"
modeBtn.BackgroundColor3 = Color3.fromRGB(80,80,120)
modeBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner",modeBtn)

modeBtn.MouseButton1Click:Connect(function()
	if mode == "SIMPLE" then
		mode = "FLEX"
		modeBtn.Text = "MODE: FLEX"
	else
		mode = "SIMPLE"
		modeBtn.Text = "MODE: SIMPLE"
	end
end)

-- CP BUTTONS
local cpBtns = {}

for i=1,#CP do
	local b = Instance.new("TextButton",F)
	b.Size = UDim2.new(0.4,0,0,30)
	b.Position = UDim2.new((i-1)*0.45+0.05,0,0,90)
	b.Text = "CP "..i
	b.BackgroundColor3 = Color3.fromRGB(40,40,40)
	b.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner",b)

	cpBtns[i] = b

	b.MouseButton1Click:Connect(function()
		if running or mode ~= "FLEX" then return end
		runCP(i)
	end)
end

-- RUN BUTTON
local runBtn = Instance.new("TextButton",F)
runBtn.Size = UDim2.new(1,-40,0,30)
runBtn.Position = UDim2.new(0,20,0,140)
runBtn.Text = "RUN AUTO"
runBtn.BackgroundColor3 = Color3.fromRGB(200,200,200)
runBtn.TextColor3 = Color3.new(0,0,0)
Instance.new("UICorner",runBtn)

runBtn.MouseButton1Click:Connect(function()
	if mode == "SIMPLE" then
		runAll()
	end
end)

-- STOP BUTTON
local stopBtn = Instance.new("TextButton",F)
stopBtn.Size = UDim2.new(1,-40,0,30)
stopBtn.Position = UDim2.new(0,20,0,180)
stopBtn.Text = "STOP"
stopBtn.BackgroundColor3 = Color3.fromRGB(120,50,50)
stopBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner",stopBtn)

stopBtn.MouseButton1Click:Connect(stopRun)

-- CLOSE
local closeBtn = Instance.new("TextButton",F)
closeBtn.Size = UDim2.new(0,25,0,25)
closeBtn.Position = UDim2.new(1,-30,0,5)
closeBtn.Text = "X"
closeBtn.BackgroundColor3 = Color3.fromRGB(80,30,30)
closeBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner",closeBtn)

closeBtn.MouseButton1Click:Connect(function()
	F:Destroy()
end)

-- TOGGLE
UIS.InputBegan:Connect(function(inp,gpe)
	if gpe then return end
	if inp.KeyCode == Enum.KeyCode.F9 then
		F.Visible = not F.Visible
	end
end)
