local Tool = "Duplicate"

table.insert(Menus[Menu].Tools,Tool)
Variables[Tool] = Menus[Menu].Variables

OnToolSelect[Tool] = function(tool)
	local copy = {}
	local copy_parent = {}
	local selection = Selection:Get()
	if #selection == 0 then
		DisplayInfo("Selection was empty")
		SelectPreviousTool()
		return
	end

	for i = 1,#selection do
		local object = selection[i]:Clone()
		copy[#copy + 1] = object
		copy_parent[object] = object.Parent
	end

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

	DisplayInfo("Duplicated selection")
	SelectPreviousTool()
end
