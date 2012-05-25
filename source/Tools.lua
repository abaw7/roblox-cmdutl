local PreviousTool = nil
local SelectedTool = nil

local ToolSelection = {}

local MenuList = {}
local Menus = {}
local Variables = {}

local OnToolSelect = {}
local OnSelectionChanged = {}
local OnToolDeselect = {}

local ToolSelectCallback = {}
local SelectionChangedCallback = {}
local ToolDeselectCallback = {}

Selection.SelectionChanged:connect(function()
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
		OnToolSelect[tool](tool,Variables[tool])

		local callback = SelectionChangedCallback[tool]
		if callback then callback() end
		local func = OnSelectionChanged[tool]
		if func then func(tool,vars) end
	end
end

local function SelectPreviousTool()
	if SelectedTool then
		DeselectTool(SelectedTool)
	end
	SelectTool(PreviousTool)
end
