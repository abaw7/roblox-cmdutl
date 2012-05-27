local Tool = AddTool("Move","MoveObject")

OnToolSelect[Tool] = function(tool,vars)
	Overlay:NewAdorn("Handles",'Handles',{
		Color = BrickColor.new("Bright orange");
	})

	local origin = {}
	local ocf = Overlay.CFrame
	local inc = vars.Increment
	Event[tool].Down = Overlay.Adorn.Handles.MouseButton1Down:connect(function(face)
		inc = vars.Increment
		for k in pairs(origin) do
			origin[k] = nil
		end
		for _,part in pairs(ToolSelection) do
			origin[part] = part.CFrame
		end
		ocf = Overlay.CFrame
		DisplayInfo("Move:",0)
	end)
	Event[tool].Drag = Overlay.Adorn.Handles.MouseDrag:connect(function(face,distance)
		local rdis = Snap(distance,inc)
		local cf = CFrame.new(Vector3.FromNormalId(face)*rdis)
		for part,cframe in pairs(origin) do
			Anchor(part)
			part.CFrame = cframe * cf
			Anchor(part,true)
		end
		Overlay.CFrame = ocf*cf
		DisplayInfo("Move:",rdis)
	end)
end

OnSelectionChanged[Tool] = function(tool,vars)
	local selection = Selection:GetFiltered("BasePart")
	ToolSelection = selection
	Overlay:Wrap(selection[1])
end

OnToolDeselect[Tool] = function(tool,vars)
	Event[tool] = nil
	Overlay:Clear()
end
