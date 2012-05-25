local Tool = AddTool("Clipboard","Paste")

OnToolSelect[Tool] = function(tool)
	if #ClipboardContents == 0 then
		DisplayInfo("Clipboard was empty")
		SelectPreviousTool()
		return
	end
	local copy = {}
	local copy_parent = {}
	for i,v in pairs(ClipboardContents) do
		local o = v:Clone()
		copy[i] = o
		copy_parent[o] = ClipboardContentParent[v]
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

	DisplayInfo("Pasted from clipboard")
	SelectPreviousTool()
end
