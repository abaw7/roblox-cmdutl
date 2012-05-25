local Tool = AddTool("Move","MoveFirst")

OnToolSelect[Tool] = function(tool,vars)
	local OverlayHandles = Overlay:Adornment('Handles',{
		Color = BrickColor.new("Bright orange");
	})

	local origin = {}
	local corigin
	local ocf = Overlay.CFrame
	local inc = vars.Increment
	Event[tool].Down = OverlayHandles.MouseButton1Down:connect(function(face)
		inc = vars.Increment
		corigin = ToolSelection[1].CFrame
		for k in pairs(origin) do
			origin[k] = nil
		end
		for _,part in pairs(ToolSelection) do
			origin[part] = corigin:toObjectSpace(part.CFrame)
		end
		ocf = corigin:toObjectSpace(Overlay.CFrame)
		DisplayInfo("Move:",0)
	end)
	Event[tool].Drag = OverlayHandles.MouseDrag:connect(function(face,distance)
		local rdis = Snap(distance,inc)
		local cf = corigin * CFrame.new(Vector3.FromNormalId(face)*rdis)
		for part,cframe in pairs(origin) do
			Anchor(part)
			part.CFrame = cf:toWorldSpace(cframe)
			Anchor(part,true)
		end
		Overlay.CFrame = cf:toWorldSpace(ocf)
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
