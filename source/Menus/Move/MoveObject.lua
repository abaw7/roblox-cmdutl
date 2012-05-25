local Tool = "MoveObject"

table.insert(Menus[Menu].Tools,Tool)
Variables[Tool] = Menus[Menu].Variables

OnToolSelect[Tool] = function(tool,vars)
	OverlayHandles.Color = BrickColor.new("Bright orange")
	OverlayHandles.Style = "Resize"
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
		local cf = CFrame.new(Vector3FromNormalId(face)*rdis)
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
	local selection = GetFilteredSelection("BasePart")
	ToolSelection = selection
	WrapOverlay(selection[1])
end

OnToolDeselect[Tool] = function(tool,vars)
	Event[tool] = nil
	OverlayHandles.Visible = false
end
