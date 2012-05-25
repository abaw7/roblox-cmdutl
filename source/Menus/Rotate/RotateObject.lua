local Tool = "RotateObject"

table.insert(Menus["Rotate"].Tools,Tool)
Variables[Tool] = Menus["Rotate"].Variables

local min_size = Vector3.new(4,4,4)

OnToolSelect[Tool] = function(tool,vars)
	OverlayArcHandles.Color = BrickColor.new("Br. yellowish green")
	OverlayArcHandles.Visible = true

	local origin = {}
	local ocf = Overlay.CFrame
	local inc = vars.Increment
	Event[tool].Down = OverlayArcHandles.MouseButton1Down:connect(function(axis)
		inc = vars.Increment
		for k in pairs(origin) do
			origin[k] = nil
		end
		for _,part in pairs(ToolSelection) do
			origin[part] = part.CFrame
		end
		ocf = Overlay.CFrame
		DisplayInfo("Rotate:",0)
	end)
	Event[tool].Drag = OverlayArcHandles.MouseDrag:connect(function(axis,angle)
		local rdis = Snap(math.deg(angle),inc)
		local a = Vector3FromAxis(axis)*math.rad(rdis)
		local new = CFrame.Angles(a.x,a.y,a.z)
		for part,cframe in pairs(origin) do
			Anchor(part)
			part.CFrame = cframe * new
			Anchor(part,true)
		end
		Overlay.CFrame = ocf * new
		DisplayInfo("Rotate:",rdis)
	end)
end

OnSelectionChanged[Tool] = function(tool,vars)
	local selection = GetFilteredSelection("BasePart")
	ToolSelection = selection
	WrapOverlay(selection[1],false,min_size)
end

OnToolDeselect[Tool] = function(tool,vars)
	Event[tool] = nil
	OverlayArcHandles.Visible = false
end
