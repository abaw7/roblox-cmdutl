local PreviousTool = nil
local SelectedTool = nil

local ToolSelection = {}	-- used with OnSelectionChanged

local MenuList = {}		-- a list of menu names
local Menus = {}		-- menu name -> menu data
local Variables = {}	-- tool name -> menu variables

--[[
AddMenu (name, data)
	Adds a new menu
	`name`: name of the menu
	`data`: a table containing menu data

Menu Data
	["Variables"]
		a table containing key/value pairs of variables to appear in the menu
		each value specifies the variable's default value, and the variable's type
	["VariableList"]
		controls the order of variables in the menu
		each entry is a table. In each table,
			entry [1] is the key as it appears in the Variables table
			entry [2] is an alternate name to display for the variable; if omitted, the key will be used
	["Color"]
		a Color3 that specifies the menu color
]]
local function AddMenu(name,data)
	table.insert(MenuList,name)
	Menus[name] = data
	data.Tools = {}
	return name
end

--[[
AddTool (menu, tool)
	Adds a tool to a menu
	`menu`: name of the menu
	`tool`: name of the tool; must be unique from ALL tools
]]

local function AddTool(menu,tool)
	table.insert(Menus[menu].Tools,tool)
	Variables[tool] = Menus[menu].Variables
	return tool
end

local OnToolSelect = {}			-- [tool_name] = function; called when a tool is selected
local OnSelectionChanged = {}	-- [tool_name] = function; called when the selection changes
local OnToolDeselect = {}		-- [tool_name] = function; called when the tool is deselected

local ToolSelectCallback = {}		-- an interface for GUI
local SelectionChangedCallback = {}	-- an interface for GUI
local ToolDeselectCallback = {}		-- an interface for GUI

Selection.Changed:connect(function()
	if SelectedTool then
		local callback = SelectionChangedCallback[SelectedTool]
		if callback then callback() end
		local func = OnSelectionChanged[SelectedTool]
		if func then func(SelectedTool,Variables[SelectedTool]) end
	end
end)

local function DeselectTool(tool)
	if tool then
		local callback = ToolDeselectCallback[tool]
		if callback then callback() end
		local func = OnToolDeselect[tool]
		if func then func(tool,Variables[tool]) end
		SelectedTool = nil
	end
end

local function SelectTool(tool)
	if tool then
		if SelectedTool then
			local prev = SelectedTool
			PreviousTool = prev
			DeselectTool(prev)
			if prev == tool then
				PreviousTool = nil
				return
			end
		end
		SelectedTool = tool
		local callback = ToolSelectCallback[tool]
		if callback then callback() end
		local func = OnToolSelect[tool]
		if func then func(tool,Variables[tool]) end

		local callback = SelectionChangedCallback[tool]
		if callback then callback() end
		local func = OnSelectionChanged[tool]
		if func then func(tool,Variables[tool]) end
	end
end

local function SelectPreviousTool()
	if SelectedTool then
		DeselectTool(SelectedTool)
	end
	SelectTool(PreviousTool)
end
