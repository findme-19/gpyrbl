--[[ MOUNT SAKAHAYANG PREMIUM — LIGHT ROBUST VERSION ]]

local Players = game:GetService("Players")
local player  = Players.LocalPlayer

-- ================= CONFIG =================
local CHECKPOINTS = {
	["CP 1"] = {
		POS = Vector3.new(-313.5,653.1,-945.6)
	},
	["CP 2"] = {
		POS = Vector3.new(4357.5,2237.1,-9544.7)
	}
}

local CP_ORDER = {"CP 1","CP 2"}
local SCAN_RADIUS = 120

local running = false

-- ================= CACHE PROMPTS =================
local cachedPrompts = {}

local function buildCache()
	cachedPrompts = {}
	for _,v in ipairs(workspace:GetDescendants()) do
		if v:IsA("ProximityPrompt") then
			table.insert(cachedPrompts, v)
		end
	end
end

-- ================= SAFE TP =================
local function safeTP(hrp, pos)
	local offset = Vector3.new(
		math.random(-2,2),
		3,
		math.random(-2,2)
	)

	hrp.CFrame = CFrame.new(pos + offset)
	task.wait(0.3)

	-- validasi
	if (hrp.Position - pos).Magnitude > 25 then
		hrp.CFrame = CFrame.new(pos + Vector3.new(0,5,0))
	end
end

-- ================= SCAN =================
local KEYWORDS = {
	"claim",
	"ambil",
	"reward",
	"hadiah",
	"redeem"
}

local function hasKeyword(text)
	if not text then return false end
	text = text:lower()

	for _,k in ipairs(KEYWORDS) do
		if text:match(k) then
			return true
		end
	end
	return false
end

local function scanNearby(hrp)
	local results = {}

	for _,p in ipairs(cachedPrompts) do
		if p.Parent then
			local part = p.Parent
			if part:IsA("BasePart") then
				local dist = (part.Position - hrp.Position).Magnitude

				if dist <= SCAN_RADIUS then
					if hasKeyword(p.ActionText) or hasKeyword(p.ObjectText) then
						table.insert(results, {
							prompt = p,
							pos = part.Position,
							dist = dist
						})
					end
				end
			end
		end
	end

	table.sort(results, function(a,b)
		return a.dist < b.dist
	end)

	return results
end

-- ================= FIRE =================
local function firePrompt(prompt)
	for i=1,3 do
		local ok = pcall(function()
			fireproximityprompt(prompt)
		end)

		if ok then return true end
		task.wait(0.1)
	end

	return false
end

-- ================= RUN CP =================
local function runCP(name)
	local cp = CHECKPOINTS[name]
	if not cp then return false end

	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart",5)
	if not hrp then return false end

	print("➡️ ", name)

	safeTP(hrp, cp.POS)

	-- tunggu load (dynamic, bukan fixed)
	local t = 0
	local results = {}

	repeat
		task.wait(0.2)
		t += 0.2
		results = scanNearby(hrp)
	until (#results > 0 or t > 2)

	if #results == 0 then
		print("❌ No prompt:", name)
		return false
	end

	local target = results[1]

	-- positioning
	hrp.CFrame = CFrame.new(target.pos + Vector3.new(0,3,0))
	task.wait(0.2)

	local success = firePrompt(target.prompt)

	if success then
		print("✅ Claimed:", name)
		return true
	else
		print("⚠️ Failed fire:", name)
		return false
	end
end

-- ================= MAIN =================
local function runAll()
	if running then return end
	running = true

	buildCache()

	for i,name in ipairs(CP_ORDER) do
		print("CP "..i.."/"..#CP_ORDER)

		local ok = runCP(name)

		if not ok then
			print("Skip:", name)
		end

		task.wait(1)
	end

	running = false
	print("🎯 DONE ALL CP")
end

-- ================= START =================
runAll()
