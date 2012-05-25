local Tool = "MoveAxis"

table.insert(Menus[Menu].Tools,Tool)
Variables[Tool] = Menus[Menu].Variables

OnToolSelect[Tool] = function(tool,vars)
	OverlayHandles.Color = BrickColor.new("Bright orange")
	OverlayHandles.Style = "Movement"
	OverlayHandles.Visible = true

	local origin = {}
	local ocf = Overlay.CFrame
	local inc = vars.Increment
	Event[tool].Down = OverlayHandles.MouseButton1Down:connect(function(face)
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
	Event[tool].Drag = OverlayHandles.MouseDrag:connect(function(face,distance)
		local rdis = Snap(distance,inc)
		local pos = Vector3FromNormalId(face)*rdis
		for part,cframe in pairs(origin) do
			Anchor(part)
			part.CFrame = cframe + pos
			Anchor(part,true)
		end
		Overlay.CFrame = ocf+pos
		DisplayInfo("Move:",rdis)
	end)
end

OnSelectionChanged[Tool] = function(tool,vars)
	local selection = GetFilteredSelection("BasePart")
	ToolSelection = selection
	WrapOverlay(selection,true)
end

OnToolDeselect[Tool] = function(tool,vars)
	Event[tool] = nil
	OverlayHandles.Visible = false
end
