local Tool = "Brick"

table.insert(Menus[Menu].Tools,Tool)
Variables[Tool] = Menus[Menu].Variables

OnToolSelect[Tool] = function(tool)
	local copy = {}
	local copy_parent = {}
	local selection = Selection:Get()
	if #selection == 0 then
		local Part = Instance.new("Part", Workspace)
		Part.Size = Vector3.new(4, 1.2, 2)
		copy[1] = Part
		CameraLookAt(CFrame.new(Part.Position.x, Part.Position.y, Part.Position.z))
		DisplayInfo("Added Part")
		Selection:Set(copy)
		SelectPreviousTool()
		return
	end

		local object = Instance.new("Part")
		copy[1] = object
		copy_parent[object] = object.Parent

	local cSize,cPos,cParts = GetBoundingBox(copy,true)

	local selection = Selection:Get()
	local sSize,sPos
	if #selection > 0 then
		sSize,sPos = GetBoundingBox(selection)
	else
		sSize,sPos = cSize,cPos
	end

	local center = CFrame.new(cPos)
	local new = CFrame.new(sPos + Vector3.new(0,sSize.y/2 + cSize.y/2,0))

	for i,part in pairs(cParts) do
		part.CFrame = new:toWorldSpace(center:toObjectSpace(part.CFrame))
	end

	for i,v in pairs(copy) do
		v.Parent = copy_parent[v] or ModelScope
	end

	CameraLookAt(new)

	Selection:Set(copy)

	SelectPreviousTool()
end