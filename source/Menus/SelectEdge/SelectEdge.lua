local Tool = "SelectEdge"

table.insert(Menus[Menu].Tools,Tool)
Variables[Tool] = Menus[Menu].Variables

OnToolSelect[Tool] = function(tool,vars)
	local Mouse = Plugin:GetMouse()
	if not Mouse_Active then
		ActivateMouse()
	end
	Event.SelectEdge.Deactivate = Plugin.Deactivation:connect(function()
		DeselectTool(tool)
	end)

	local Down = false
	local SelectEdgeVisible = false
	
	local select_hold = true
	local click_stamp = 0
	
	OverlayGUIParent(nil)
	OverlayArcHandles.Color = BrickColor.new("Bright yellow")
	OverlaySelectionBox.Color = BrickColor.new("Bright yellow")
	
	local function select_edge()
		OverlayArcHandles.Visible = false
		OverlaySelectionBox.Visible = true
		Overlay.Size = Vector3.new(1,1,1)
		local Target = FilterTarget(Mouse.Target)
		if Target then
			OverlayGUIParent(CoreGui)
			local pos = Target.CFrame:toObjectSpace(Mouse.Hit).p
			local JointCenter = CFrame.new(GetRelativeEdge(pos,Target.Size/2,vars.EdgeSnap))
			Overlay.CFrame = Target.CFrame * JointCenter
			SelectEdgeVisible = true
		else
			SelectEdgeVisible = false
			OverlayArcHandles.Visible = false
			OverlayGUIParent(nil)
		end
	end
	
	Event.SelectEdge.Down = Mouse.Button1Down:connect(function()
		Down = true
		if Mouse_Alt_Active then
			select_edge()
		end
	end)
	Event.SelectEdge.Up = Mouse.Button1Up:connect(function()
		OverlayArcHandles.Visible = true
		OverlaySelectionBox.Visible = false
		Overlay.Size = Vector3.new(4,4,4)
		Down = false
		
		Event.SelectEdge.SelectHold = nil
	end)
	Event.SelectEdge.Move = Mouse.Move:connect(function()
		click_stamp = 0
		if Down then
			if Mouse_Alt_Active then
				select_edge()
			else
				OverlayArcHandles.Visible = true
				OverlaySelectionBox.Visible = false
				Overlay.Size = Vector3.new(4,4,4)
			end
		end
	end)
	
	local inc = 0
	local ocf = CFrame.new()
	local origin = {}
	local corigin = CFrame.new()
	Event.SelectEdge.Arc.Down = OverlayArcHandles.MouseButton1Down:connect(function(axis)
		if SelectEdgeVisible then
			inc = vars.RotIncrement
			corigin = Overlay.CFrame
			for k in pairs(origin) do
				origin[k] = nil
			end
			for _,part in pairs(ToolSelection) do
				origin[part] = corigin:toObjectSpace(part.CFrame)
			end
			ocf = corigin:toObjectSpace(Overlay.CFrame)
			DisplayInfo("Rotate:",0)
		end
	end)
	Event.SelectEdge.Arc.Drag = OverlayArcHandles.MouseDrag:connect(function(axis,angle)
		local rdis = Snap(math.deg(angle),inc)
		local a = Vector3FromAxis(axis)*math.rad(rdis)
		local new = corigin * CFrame.Angles(a.x,a.y,a.z)
		for part,cframe in pairs(origin) do
			Anchor(part)
			part.CFrame = new:toWorldSpace(cframe)
			Anchor(part,true)
		end
		Overlay.CFrame = new:toWorldSpace(ocf)
		DisplayInfo("Rotate:",rdis)
	end)
end

OnSelectionChanged[Tool] = function(tool,vars)
	ToolSelection = GetFilteredSelection("BasePart")
end

OnToolDeselect[Tool] = function(tool,vars)
	SelectEdgeVisible = false
	Event.SelectEdge = nil
	OverlayGUIParent(nil)
	OverlaySelectionBox.Visible = false
	OverlayArcHandles.Visible = false
end
