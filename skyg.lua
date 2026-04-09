--[[ 
  MOUNT SAKAHAYANG SCRIPT (2 CP VERSION)
  BY ALFIAN (EDITED)
]]

local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local TweenSvc = game:GetService("TweenService")
local player   = Players.LocalPlayer

pcall(function()
	for _,g in ipairs(player.PlayerGui:GetChildren()) do
		if g.Name=="SakahayangAlfian" then g:Destroy() end
	end
end)

-- ================= CP CONFIG =================
local CP = {
	[1] = {
		TARGET = Vector3.new(-313.5,653.1,-945.6),
		NEAR   = Vector3.new(-313.5,653.1,-940.6)
	},
	[2] = {
		TARGET = Vector3.new(4362.3,2237.0,-9538.8),
		NEAR   = Vector3.new(4362.3,2237.0,-9530.8)
	}
}

local currentCP = 2
local running = false

-- ================= COLORS =================
local GR =Color3.fromRGB(150,255,170)
local RD =Color3.fromRGB(220,70,70)
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

local SVl,SDot

local function setStatus(msg,col)
	if not SVl then return end
	SVl.Text=msg
	local c=col=="done" and GR or col=="err" and RD2 or col=="wait" and YL or WHT
	SVl.TextColor3=c
	if SDot then SDot.BackgroundColor3=c end
end

-- ================= TELEPORT =================
local function teleportToCP(idx)
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp  = char:WaitForChild("HumanoidRootPart",5)
	if not hrp then return end

	local cp = CP[idx]
	if not cp then return end

	currentCP = idx
	setStatus("TP CP "..idx,"wait")

	hrp.CFrame = CFrame.new(cp.NEAR + Vector3.new(0,5,0))
end

-- ================= FIND PROMPT =================
local function findPrompt()
	local cp = CP[currentCP]

	for _,v in ipairs(workspace:GetDescendants()) do
		if v:IsA("ProximityPrompt") then
			local par=v.Parent
			if par and par:IsA("BasePart") then
				local pos=par.Position
				if (pos - cp.TARGET).Magnitude < 120 then
					return v,par
				end
			end
		end
	end
	return nil,nil
end

-- ================= RUN =================
local function runSequence()
	if running then return end
	running=true

	task.spawn(function()
		setStatus("CONNECTING","wait")
		task.wait(0.2)

		local char=player.Character or player.CharacterAdded:Wait()
		local hrp=char:WaitForChild("HumanoidRootPart",5)
		if not hrp then setStatus("ERROR","err");running=false;return end

		local cp = CP[currentCP]

		setStatus("FAST TRAVEL CP"..currentCP,"wait")
		hrp.CFrame = CFrame.new(cp.NEAR + Vector3.new(0,5,0))
		task.wait(0.4)

		setStatus("SCAN CP"..currentCP,"wait")
		local pr,obj = findPrompt()

		if obj and obj:IsA("BasePart") then
			local pos = obj.Position
			hrp.CFrame = CFrame.new(pos + Vector3.new(0,3,0))
			task.wait(0.2)
		end

		setStatus("CLAIMING","wait")

		if pr then
			for i=1,3 do
				pcall(function()
					fireproximityprompt(pr)
				end)
				task.wait(0.1)
			end
		end

		setStatus("DONE CP"..currentCP,"done")
		running=false
	end)
end

-- ================= GUI =================
local sg=Instance.new("ScreenGui",player.PlayerGui)
sg.Name="SakahayangAlfian"

local F=Instance.new("Frame",sg)
F.Size=UDim2.new(0,260,0,300)
F.Position=UDim2.new(0,20,0,60)
F.BackgroundColor3=PNL
F.Active=true
F.Draggable=true
Instance.new("UICorner",F)

-- TITLE
local title=Instance.new("TextLabel",F)
title.Size=UDim2.new(1,0,0,30)
title.Text="MOUNT SAKAHAYANG"
title.TextColor3=WHT
title.BackgroundTransparency=1
title.Font=Enum.Font.GothamBold
title.TextSize=12

-- STATUS
SVl=Instance.new("TextLabel",F)
SVl.Size=UDim2.new(1,0,0,20)
SVl.Position=UDim2.new(0,0,0,30)
SVl.Text="READY"
SVl.TextColor3=GR
SVl.BackgroundTransparency=1
SVl.Font=Enum.Font.GothamBold
SVl.TextSize=10

-- START
local startBtn=Instance.new("TextButton",F)
startBtn.Size=UDim2.new(1,-40,0,30)
startBtn.Position=UDim2.new(0,20,0,70)
startBtn.Text="START RUN"
startBtn.BackgroundColor3=WHT
startBtn.TextColor3=DEEP
Instance.new("UICorner",startBtn)

startBtn.MouseButton1Click:Connect(function()
	runSequence()
end)

-- CP BUTTONS
local cp1=Instance.new("TextButton",F)
cp1.Size=UDim2.new(0.4,0,0,30)
cp1.Position=UDim2.new(0.05,0,0,120)
cp1.Text="TP CP1"
cp1.BackgroundColor3=SRF
cp1.TextColor3=WHT
Instance.new("UICorner",cp1)

local cp2=Instance.new("TextButton",F)
cp2.Size=UDim2.new(0.4,0,0,30)
cp2.Position=UDim2.new(0.55,0,0,120)
cp2.Text="TP CP2"
cp2.BackgroundColor3=SRF
cp2.TextColor3=WHT
Instance.new("UICorner",cp2)

cp1.MouseButton1Click:Connect(function()
	if running then return end
	teleportToCP(1)
end)

cp2.MouseButton1Click:Connect(function()
	if running then return end
	teleportToCP(2)
end)

-- TOGGLE UI
UIS.InputBegan:Connect(function(inp,gpe)
	if gpe then return end
	if inp.KeyCode==Enum.KeyCode.F9 then
		F.Visible = not F.Visible
	end
end)

print("Mount Sakahayang 2CP Loaded")
