local Tool = AddTool("Rotate","RotateGroup")

local min_size = Vector3.new(4,4,4)

OnToolSelect[Tool] = function(tool,vars)
	Overlay:NewAdorn("Handles",'ArcHandles',{
		Color = BrickColor.new("Br. yellowish green");
	})

	local origin = {}
	local corigin = Overlay.CFrame
	local inc = vars.Increment
	Event[tool].Down = Overlay.Adorn.Handles.MouseButton1Down:connect(function(axis)
		inc = vars.Increment
		corigin = Overlay.CFrame
		for k in pairs(origin) do
			origin[k] = nil
		end
		for _,part in pairs(ToolSelection) do
			origin[part] = corigin:toObjectSpace(part.CFrame)
		end
		DisplayInfo("Rotate:",0)
	end)
	Event[tool].Drag = Overlay.Adorn.Handles.MouseDrag:connect(function(axis,angle)
		local rdis = Snap(math.deg(angle),inc)
		local a = Vector3.FromAxis(axis)*math.rad(rdis)
		local new = corigin * CFrame.Angles(a.x,a.y,a.z)
		for part,cframe in pairs(origin) do
			Anchor(part)
			part.CFrame = new:toWorldSpace(cframe)
			Anchor(part,true)
		end
		Overlay.CFrame = new
		DisplayInfo("Rotate:",rdis)
	end)
end

OnSelectionChanged[Tool] = function(tool,vars)
	local selection = Selection:GetFiltered("BasePart")
	ToolSelection = selection
	Overlay:Wrap(ToolSelection,min_size)
end

OnToolDeselect[Tool] = function(tool,vars)
	Event[tool] = nil
	Overlay:Clear()
end
