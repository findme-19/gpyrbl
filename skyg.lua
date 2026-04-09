--[[ SAKAHAYANG STEALTH MODE — EVENT DRIVEN ]]

local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local PPS     = game:GetService("ProximityPromptService")

local player  = Players.LocalPlayer

-- ================= CONFIG =================
local CHECKPOINTS = {
	Vector3.new(-313.5,653.1,-945.6),
	Vector3.new(4357.5,2237.1,-9544.7)
}

local running = false
local activePrompt = nil

-- ================= STATUS =================
local statusLabel
local function setStatus(t)
	if statusLabel then statusLabel.Text = t end
	print(t)
end

-- ================= HUMAN TP =================
local function humanTP(hrp, pos)
	local offset = Vector3.new(
		math.random(-3,3),
		3,
		math.random(-3,3)
	)

	hrp.CFrame = CFrame.new(pos + offset)

	-- random delay (anti pattern)
	task.wait(math.random(30,60)/100)
end

-- ================= PROMPT DETECTION =================
local KEYWORDS = {"claim","ambil","reward","hadiah","redeem"}

local function validPrompt(prompt)
	local t1 = (prompt.ActionText or ""):lower()
	local t2 = (prompt.ObjectText or ""):lower()

	for _,k in ipairs(KEYWORDS) do
		if t1:match(k) or t2:match(k) then
			return true
		end
	end
	return false
end

-- listen event (INI KUNCI STEALTH)
PPS.PromptShown:Connect(function(prompt)
	if not running then return end
	if validPrompt(prompt) then
		activePrompt = prompt
	end
end)

-- ================= CLAIM =================
local function tryClaim(hrp)
	if not activePrompt then return false end

	local parent = activePrompt.Parent
	if not parent or not parent:IsA("BasePart") then return false end

	-- pastikan dekat
	local dist = (parent.Position - hrp.Position).Magnitude
	if dist > 15 then return false end

	-- positioning halus
	hrp.CFrame = CFrame.new(parent.Position + Vector3.new(0,2,0))

	task.wait(math.random(20,40)/100)

	pcall(function()
		fireproximityprompt(activePrompt)
	end)

	setStatus("✅ CLAIMED")
	return true
end

-- ================= RUN =================
local function runAll()
	if running then return end
	running = true

	local char = player.Character or player.CharacterAdded:Wait()
	local hrp  = char:WaitForChild("HumanoidRootPart",5)
	if not hrp then return end

	for i,pos in ipairs(CHECKPOINTS) do
		if not running then break end

		activePrompt = nil
		setStatus("➡️ CP "..i)

		humanTP(hrp, pos)

		-- tunggu prompt muncul (event-based)
		local t = 0
		repeat
			task.wait(0.1)
			t += 0.1
		until (activePrompt or t > 3)

		if activePrompt then
			tryClaim(hrp)
		else
			setStatus("❌ no prompt")
		end

		task.wait(math.random(80,120)/100)
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
sg.Name = "StealthMode"

local frame = Instance.new("Frame", sg)
frame.Size = UDim2.new(0,220,0,140)
frame.Position = UDim2.new(0,20,0,60)
frame.BackgroundColor3 = Color3.fromRGB(18,18,22)
frame.Active = true
frame.Draggable = true
Instance.new("UICorner",frame)

local title = Instance.new("TextLabel",frame)
title.Size = UDim2.new(1,0,0,25)
title.Text = "STEALTH MODE"
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 11

statusLabel = Instance.new("TextLabel",frame)
statusLabel.Size = UDim2.new(1,0,0,20)
statusLabel.Position = UDim2.new(0,0,0,25)
statusLabel.Text = "READY"
statusLabel.TextColor3 = Color3.fromRGB(150,255,150)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 10

local runBtn = Instance.new("TextButton",frame)
runBtn.Size = UDim2.new(1,-40,0,30)
runBtn.Position = UDim2.new(0,20,0,55)
runBtn.Text = "RUN"
runBtn.BackgroundColor3 = Color3.fromRGB(200,200,200)
runBtn.TextColor3 = Color3.new(0,0,0)
Instance.new("UICorner",runBtn)

runBtn.MouseButton1Click:Connect(runAll)

local stopBtn = Instance.new("TextButton",frame)
stopBtn.Size = UDim2.new(1,-40,0,30)
stopBtn.Position = UDim2.new(0,20,0,95)
stopBtn.Text = "STOP"
stopBtn.BackgroundColor3 = Color3.fromRGB(120,50,50)
stopBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner",stopBtn)

stopBtn.MouseButton1Click:Connect(stopRun)

UIS.InputBegan:Connect(function(inp,gpe)
	if gpe then return end
	if inp.KeyCode == Enum.KeyCode.F9 then
		frame.Visible = not frame.Visible
	end
end)
