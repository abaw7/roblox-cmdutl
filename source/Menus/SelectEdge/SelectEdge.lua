local Tool = AddTool("SelectEdge","SelectEdge")

local function FilterTarget(target)
	if target then
		if not target.Locked then
			return target
		end
	end
	return nil
end

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
	
	Overlay:NewAdorn("Handles",'ArcHandles',{
		Color = BrickColor.new("Bright yellow");
	})
	Overlay:NewAdorn("Box",'SelectionBox',{
		Color = BrickColor.new("Bright yellow");
	})
	
	local function select_edge()
		Overlay.Adorn.Handles.Visible = false
		Overlay.Adorn.Box.Visible = true
		Overlay.Size = Vector3.new(1,1,1)
		local Target = FilterTarget(Mouse.Target)
		if Target then
			Overlay:SetParent(CoreGui)
			local JointCenter = CFrame.new(GetNearestEdge(Target,Mouse.Hit.p,vars.EdgeSnap))
			Overlay.CFrame = Target.CFrame * JointCenter
			SelectEdgeVisible = true
		else
			SelectEdgeVisible = false
			Overlay.Adorn.Handles.Visible = false
			Overlay:SetParent(nil)
		end
	end
	
	Event.SelectEdge.Down = Mouse.Button1Down:connect(function()
		Down = true
		if Mouse_Alt_Active then
			select_edge()
		end
	end)
	Event.SelectEdge.Up = Mouse.Button1Up:connect(function()
		Overlay.Adorn.Handles.Visible = true
		Overlay.Adorn.Box.Visible = false
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
				Overlay.Adorn.Handles.Visible = true
				Overlay.Adorn.Box.Visible = false
				Overlay.Size = Vector3.new(4,4,4)
			end
		end
	end)
	
	local inc = 0
	local ocf = CFrame.new()
	local origin = {}
	local corigin = CFrame.new()
	Event.SelectEdge.Arc.Down = Overlay.Adorn.Handles.MouseButton1Down:connect(function(axis)
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
	Event.SelectEdge.Arc.Drag = Overlay.Adorn.Handles.MouseDrag:connect(function(axis,angle)
		local rdis = Snap(math.deg(angle),inc)
		local a = Vector3.FromAxis(axis)*math.rad(rdis)
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
	ToolSelection = Selection:GetFiltered("BasePart")
end

OnToolDeselect[Tool] = function(tool,vars)
	SelectEdgeVisible = false
	Event.SelectEdge = nil
	Overlay:Clear()
end
