local Tool = "Cut"

table.insert(Menus[Menu].Tools,Tool)
Variables[Tool] = Menus[Menu].Variables

OnToolSelect[Tool] = function(tool)
	local selection = Selection:Get()
	if #selection == 0 then
		DisplayInfo("Selection was empty")
		SelectPreviousTool()
		return
	end
	
	for i in pairs(ClipboardContents) do
		ClipboardContents[i] = nil
	end
	for k in pairs(ClipboardContentParent) do
		ClipboardContentParent[k] = nil
	end
	for i = 1,#selection do
		local object = selection[i]:Clone()
		ClipboardContents[#ClipboardContents + 1] = object
		ClipboardContentParent[object] = object.Parent
		selection[i]:Destroy()
	end
	Selection:Set{}
	DisplayInfo("Cut selection to clipboard")
	SelectPreviousTool()
end
