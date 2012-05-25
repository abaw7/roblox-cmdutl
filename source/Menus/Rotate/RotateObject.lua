local Tool = AddTool("Rotate","RotateObject")

local min_size = Vector3.new(4,4,4)

OnToolSelect[Tool] = function(tool,vars)
	local OverlayArcHandles = Overlay:Adornment('ArcHandles',{
		Color = BrickColor.new("Br. yellowish green");
	})

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
		local a = Vector3.FromAxis(axis)*math.rad(rdis)
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
	local selection = Selection:GetFiltered("BasePart")
	ToolSelection = selection
	Overlay:Wrap(selection[1],min_size)
end

OnToolDeselect[Tool] = function(tool,vars)
	Event[tool] = nil
	Overlay:Clear()
end
