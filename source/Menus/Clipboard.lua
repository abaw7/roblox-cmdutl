local Menu = "Clipboard"
table.insert(MenuList,Menu)
Menus[Menu] = {
	Tools = {};
	Variables = {};
	VariableList = {};
	Color = Color3.new(1,1,1);
}

local ClipboardContents = {}
local ClipboardContentParent = {}
