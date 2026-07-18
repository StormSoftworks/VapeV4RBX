local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/StormSoftworks/VapeV4RBX/refs/heads/main/library/central"))()
local UILib = lib

local win = UILib:Window({WindowTitle = "VAPE", Keybind = Enum.KeyCode.RightShift})
local tab1 = win:Tab({TabTitle = "Modules", isDefault = true})
local friendsTab = win:FriendsTab({TabTitle = "Friends"})

local combatSection = tab1:Section({SectionTitle = "Combat", SectionIcon = "rbxassetid://16095745259", Default = true})
local visualSection = tab1:Section({SectionTitle = "Visuals", SectionIcon = "rbxassetid://16095745259", Default = false})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Aimbot = {
	Enabled = false,
	TeamCheck = false,
	WallCheck = false
}

local ESP = {
	Enabled = false,
	TeamCheck = false,
	Color = Color3.fromRGB(255, 255, 255),
	Containers = {}
}

local function isVisible(targetPart)
	if not Aimbot.WallCheck then return true end
	local origin = Camera.CFrame.Position
	local direction = targetPart.Position - origin
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
	raycastParams.IgnoreWater = true

	local result = workspace:Raycast(origin, direction, raycastParams)
	return result == nil
end

local function getClosestPlayer()
	local closestPlayer = nil
	local shortestDistance = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local character = player.Character
			local humanRoot = character:FindFirstChild("HumanoidRootPart")
			local humanoid = character:FindFirstChildOfClass("Humanoid")

			if humanRoot and humanoid and humanoid.Health > 0 then
				if Aimbot.TeamCheck and player.Team == LocalPlayer.Team then
					continue
				end

				local screenPos, onScreen = Camera:WorldToViewportPoint(humanRoot.Position)
				if onScreen and isVisible(humanRoot) then
					local mousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
					local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

					if distance < shortestDistance then
						closestPlayer = player
						shortestDistance = distance
					end
				end
			end
		end
	end
	return closestPlayer
end

local function createEspLines()
	local lines = {}
	for i = 1, 12 do
		local line = Drawing.new("Line")
		line.Thickness = 1
		line.Transparency = 1
		line.Visible = false
		lines[i] = line
	end
	return lines
end

local function removeEsp(player)
	if ESP.Containers[player] then
		for _, line in ipairs(ESP.Containers[player]) do
			line:Remove()
		end
		ESP.Containers[player] = nil
	end
end

local function updateEsp()
	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end

		if not ESP.Enabled or not player.Character then
			removeEsp(player)
			continue
		end

		local character = player.Character
		local humanRoot = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if not humanRoot or not humanoid or humanoid.Health <= 0 then
			removeEsp(player)
			continue
		end

		if ESP.TeamCheck and player.Team == LocalPlayer.Team then
			removeEsp(player)
			continue
		end

		if not ESP.Containers[player] then
			ESP.Containers[player] = createEspLines()
		end

		local lines = ESP.Containers[player]
		local cframe, size = character:GetBoundingBox()

		local corners = {
			cframe * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2).Position,
			cframe * CFrame.new(size.X/2, -size.Y/2, -size.Z/2).Position,
			cframe * CFrame.new(size.X/2, -size.Y/2, size.Z/2).Position,
			cframe * CFrame.new(-size.X/2, -size.Y/2, size.Z/2).Position,
			cframe * CFrame.new(-size.X/2, size.Y/2, -size.Z/2).Position,
			cframe * CFrame.new(size.X/2, size.Y/2, -size.Z/2).Position,
			cframe * CFrame.new(size.X/2, size.Y/2, size.Z/2).Position,
			cframe * CFrame.new(-size.X/2, size.Y/2, size.Z/2).Position
		}

		local screenCorners = {}
		local allOnScreen = true

		for i, corner in ipairs(corners) do
			local screenPos, onScreen = Camera:WorldToViewportPoint(corner)
			if not onScreen then
				allOnScreen = false
				break
			end
			screenCorners[i] = Vector2.new(screenPos.X, screenPos.Y)
		end

		if allOnScreen then
			local indices = {
				{1, 2}, {2, 3}, {3, 4}, {4, 1},
				{5, 6}, {6, 7}, {7, 8}, {8, 5},
				{1, 5}, {2, 6}, {3, 7}, {4, 8}
			}

			for i, connection in ipairs(indices) do
				local line = lines[i]
				line.From = screenCorners[connection[1]]
				line.To = screenCorners[connection[2]]
				line.Color = ESP.Color
				line.Visible = true
			end
		else
			for _, line in ipairs(lines) do
				line.Visible = false
			end
		end
	end
end

local AimbotModule = combatSection:Module({
	ModuleTitle = "Aimbot", 
	ModuleDescription = "Aims at a player",
	callback = function(state)
		Aimbot.Enabled = state
	end
})

AimbotModule:Toggle({
	ToggleTitle = "Team Check",
	val = false,
	callback = function(v)
		Aimbot.TeamCheck = v
	end
})

AimbotModule:Toggle({
	ToggleTitle = "Wall Check",
	val = false,
	callback = function(v)
		Aimbot.WallCheck = v
	end
})

local ESPModule = visualSection:Module({
	ModuleTitle = "ESP 3D",
	ModuleDescription = "Draws 3D bounding boxes around players",
	callback = function(state)
		ESP.Enabled = state
		if not state then
			for player in pairs(ESP.Containers) do
				removeEsp(player)
			end
		end
	end
})

ESPModule:Toggle({
	ToggleTitle = "Team Check",
	val = false,
	callback = function(v)
		ESP.TeamCheck = v
		if v then
			for player in pairs(ESP.Containers) do
				if player.Team == LocalPlayer.Team then
					removeEsp(player)
				end
			end
		end
	end
})

Players.PlayerRemoving:Connect(removeEsp)

RunService.RenderStepped:Connect(function()
	if Aimbot.Enabled then
		local target = getClosestPlayer()
		if target and target.Character then
			local targetPart = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
			if targetPart then
				Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
			end
		end
	end

	updateEsp()
end)

task.spawn(function()
	win:Notify({
		Title = "Vape V4",
		Text = "Press RightShift to open.",
		Duration = 3,
	})
end)
