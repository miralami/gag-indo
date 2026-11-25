--!strict
-- Place the repeated props of the kantor polisi area in Roblox Studio.
--
-- How to use (once per place):
--   1. Import kantor_polisi_area.fbx with the 3D Importer. Leave its parts where they land.
--   2. Import every asset FBX in assets/kantor_polisi/assets/ once: kp_police_car.fbx, kp_police_motor.fbx, kp_small_palm.fbx, kp_agave.fbx, kp_cactus.fbx, kp_shrub.fbx, kp_potted_plant.fbx.
--      Each import gives a Model (or a single MeshPart) named after the file. Do not rotate or scale them.
--   3. Paste this whole file into the Command Bar (View > Command Bar) and press Enter.
--
-- The props are cloned into Workspace.KantorPolisi_Props, positioned relative to the area mesh "KP_Bldg_WallCream",
-- so the area can sit anywhere in the place. Run it again to rebuild the folder.
-- Generated from kantor_polisi.blend; 1 Blender unit = 1 stud, Roblox = (x, z, -y).

local OUT_FOLDER = "KantorPolisi_Props"
local ANCHOR = "KP_Bldg_WallCream"
local ANCHOR_CENTER = Vector3.new(-22, 7.1, -16.3)

type AssetInfo = { model: string, offset: Vector3 }
local ASSETS: { [string]: AssetInfo } = {
	Agave = { model = "kp_agave", offset = Vector3.new(0, 0, 0) },
	Cactus = { model = "kp_cactus", offset = Vector3.new(0, 0, 0) },
	PoliceCar = { model = "kp_police_car", offset = Vector3.new(0, 0, 0) },
	PoliceMotor = { model = "kp_police_motor", offset = Vector3.new(0, 0, 0) },
	PottedPlant = { model = "kp_potted_plant", offset = Vector3.new(0, 0, 0) },
	Shrub = { model = "kp_shrub", offset = Vector3.new(0, 0, 0) },
	SmallPalm = { model = "kp_small_palm", offset = Vector3.new(0, 0, 0) },
}

-- Each row: asset, x, y, z, rotation about up (degrees), scale x, y, z (Blender coordinates)
local PLACEMENTS = {
	{ "Cactus", -37.5, 7.718, 0.55, 246.69, 1.037, 1.037, 1.037 },
	{ "Agave", -35.5, 8.899, 0.55, 66.86, 0.946, 0.946, 0.946 },
	{ "Cactus", -33, 7.494, 0.55, 81.06, 1.047, 1.047, 1.047 },
	{ "Agave", -30.5, 7.46, 0.55, 191.27, 0.943, 0.943, 0.943 },
	{ "Shrub", -29, 7.789, 0.55, 155.37, 1.068, 1.068, 1.068 },
	{ "PottedPlant", -36.5, 9.8, 0.55, 0, 1, 1, 1 },
	{ "Agave", -9.5, 8.417, 0.55, 5.2, 1, 1, 1 },
	{ "Shrub", -7, 7.752, 0.55, 52.82, 1, 1, 1 },
	{ "Agave", -4.5, 8.943, 0.55, 291.51, 1, 1, 1 },
	{ "Cactus", -3, 8.812, 0.55, 297.49, 1, 1, 1 },
	{ "SmallPalm", -2, 30.1, 0.55, 268.11, 1, 1, 1 },
	{ "Agave", 2, 30.1, 0.55, 341.76, 1, 1, 1 },
	{ "Shrub", 5, 30.1, 0.55, 285.76, 1, 1, 1 },
	{ "SmallPalm", 8.5, 30.1, 0.55, 92.41, 1, 1, 1 },
	{ "Agave", 12, 30.1, 0.55, 305.98, 1, 1, 1 },
	{ "PottedPlant", 15, 30.1, 0.55, 175.24, 1, 1, 1 },
	{ "Shrub", 18, 30.1, 0.55, 271.8, 1, 1, 1 },
	{ "Agave", 21, 30.1, 0.55, 203.09, 1, 1, 1 },
	{ "SmallPalm", 23.9, 24, 0.55, 154.65, 1, 1, 1 },
	{ "Shrub", 23.9, 19, 0.55, 131.11, 1, 1, 1 },
	{ "Agave", 23.9, 14, 0.55, 154.74, 1, 1, 1 },
	{ "SmallPalm", 23.9, 8, 0.55, 112.95, 1, 1, 1 },
	{ "Shrub", 23.9, 2, 0.55, 42.25, 1, 1, 1 },
	{ "Agave", 23.9, -1.5, 0.55, 295.07, 1, 1, 1 },
	{ "SmallPalm", -8, -13.5, 0.2, 20, 1, 1, 1 },
	{ "PottedPlant", -27.5, 2, 0.2, 0, 1, 1, 1 },
	{ "PottedPlant", -10.5, 2, 0.2, 0, 1, 1, 1 },
	{ "PoliceCar", 13, 20, 0.2, -90, 1, 1, 1 },
	{ "PoliceMotor", 7, 21, 0.2, -90, 1, 1, 1 },
	{ "PoliceMotor", 19, 20.5, 0.2, -90, 1, 1, 1 },
	{ "PoliceMotor", -15, -16, 0.2, 100, 1, 1, 1 },
	{ "PoliceMotor", -12.5, -16, 0.2, 95, 1, 1, 1 },
	{ "PoliceMotor", 19, -15, 0.2, -80, 1, 1, 1 },
}

local function toRoblox(x: number, y: number, z: number): Vector3
	return Vector3.new(x, z, -y)
end

local function findByName(name: string): Instance?
	local lower = string.lower(name)
	local out = workspace:FindFirstChild(OUT_FOLDER)
	for _, d in workspace:GetDescendants() do
		if string.lower(d.Name) == lower and (d:IsA("Model") or d:IsA("BasePart")) then
			if not (out and d:IsDescendantOf(out)) then
				return d
			end
		end
	end
	return nil
end

local function bottomOf(inst: Instance): Vector3
	local cf: CFrame, size: Vector3
	if inst:IsA("Model") then
		cf, size = inst:GetBoundingBox()
	else
		local part = inst :: BasePart
		cf, size = part.CFrame, part.Size
	end
	return cf.Position - Vector3.new(0, size.Y / 2, 0)
end

local anchor = findByName(ANCHOR)
assert(
	anchor and anchor:IsA("BasePart"),
	"Import kantor_polisi_area.fbx first: mesh '" .. ANCHOR .. "' was not found in Workspace"
)
local origin = (anchor :: BasePart).Position - ANCHOR_CENTER

local templates: { [string]: Instance } = {}
local missing = {}
for key, info in ASSETS do
	local t = findByName(info.model)
	if t then
		templates[key] = t
	else
		table.insert(missing, info.model)
	end
end

local old = workspace:FindFirstChild(OUT_FOLDER)
if old then
	old:Destroy()
end
local folder = Instance.new("Folder")
folder.Name = OUT_FOLDER

local placed, skipped = 0, 0
for _, p in PLACEMENTS do
	local key = p[1] :: string
	local template = templates[key]
	if not template then
		skipped += 1
		continue
	end
	local info = ASSETS[key]
	local scale = Vector3.new(p[6] :: number, p[8] :: number, p[7] :: number)
	local rot = CFrame.Angles(0, math.rad(p[5] :: number), 0)
	local target = origin
		+ toRoblox(p[2] :: number, p[3] :: number, p[4] :: number)
		+ rot:VectorToWorldSpace(info.offset * scale)
	local base = bottomOf(template)

	local clone = template:Clone()
	local parts: { BasePart } = {}
	if clone:IsA("BasePart") then
		table.insert(parts, clone)
	end
	for _, d in clone:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, d)
		end
	end
	for _, part in parts do
		local rel = (part.Position - base) * scale
		local spin = part.CFrame - part.Position
		part.Size = part.Size * scale
		part.CFrame = CFrame.new(target) * rot * CFrame.new(rel) * spin
		part.Anchored = true
	end
	clone.Parent = folder
	placed += 1
end
folder.Parent = workspace

print(string.format("[%s] placed %d props, skipped %d", OUT_FOLDER, placed, skipped))
if #missing > 0 then
	warn("[" .. OUT_FOLDER .. "] import these assets first: " .. table.concat(missing, ", "))
end
