local PROJECT_NAME = "CmdUtl"

if _G.RegisterPlugin and not _G.RegisterPlugin(PROJECT_NAME) then return end

local Plugin = PluginManager():CreatePlugin()
local Toolbar = Plugin:CreateToolbar(PROJECT_NAME)
local ActivateGUIButton = Toolbar:CreateButton("",""..PROJECT_NAME.." Panel","CmdUtl-icon-RB.png")
local ActivateMouseButton = Toolbar:CreateButton("","Selector","cursor.png")
local SettingsButton = Toolbar:CreateButton("","Settings","application_edit.png")

local VERSION = "5.0.0"

local CoreGui = game:GetService("CoreGui")

local NewCFrame = CFrame.new
local Vector3FromNormalId = Vector3.FromNormalId
local Vector3FromAxis = Vector3.FromAxis

local ceil = math.ceil
local floor = math.floor
local function half(number)
	return floor(number + 0.5)
end

local function Snap(number,by)
	if by == 0 then
		return number
	else
		return floor(number/by + 0.5)*by
	end
end

local function NumNormal(n)
	return n == 0 and 0 or n/math.abs(n)
end

local function NumFix(num,idp)
	local mult = 10^(idp or 0)
	return floor(num*mult + 0.5)/mult
end

local function StrFix(str,size,pad)
	local str_size = #str
	if size > str_size then
		return string.rep(pad or "0",size-str_size) .. str
	elseif size < str_size then
		return str:sub(str_size-size+1)
	else
		return str
	end
end

local function IsPosInt(n)
	return type(n) == "number" and n > 0 and floor(n) == n
end

function IsArray(array)
	local max,n = 0,0
	for k,v in pairs(array) do
		if not IsPosInt(k) then
			return false
		end
		max = math.max(max,k)
		n = n + 1
	end
	return n == max
end

local function IsVarName(name)
	return name:match("^[%a_][%w_]-$") == name
end

local ContentProvider = Game:GetService("ContentProvider")
local BASEURL = ContentProvider.BaseUrl
local function Preload(content)
	ContentProvider:Preload(content)
end

local valid_protocols = {
	["http"] = true;
	["https"] = true;
	["rbxhttp"] = true;
	["rbxasset"] = true;
	["rbxassetid"] = true;
}

local function GetIndex(table,value)
	for i,v in pairs(table) do
		if v == value then
			return i
		end
	end
end

-- checks if the value is a Content string
function IsContentString(link)
	if type(link) == "string" then
		local protocol = link:match("^(.+)://(.+)$")
		return valid_protocols[protocol] or false
	else
		return false
	end
end

local function class(name)
	local def = {}
	getfenv(0)[name] = def
	return function(ctor, static)
		local nctor = function(...)
			local this = {}
			if ctor then
				ctor(this, ...)
			end
			return this
		end
		getfenv(0)['Create'..name] = nctor
		if static then static(def) end
	end
end

local function Create(ty)
	return function(data)
		local obj = Instance.new(ty)
		for k, v in pairs(data) do
			if type(k) == 'number' then
				v.Parent = obj
			else
				obj[k] = v
			end
		end
		return obj
	end
end

local function Modify(obj)
	return function(data)
		for k, v in pairs(data) do
			if type(k) == 'number' then
				v.Parent = obj
			else
				obj[k] = v
			end
		end
		return obj
	end
end

--[[----------------------------------------------------------------------------
EventGroup
	Manages event connections. Added events will remain until removal. Removed events are automatically disconnected.
	Subgroups, which are EventGroups, can also be added.

	Adding an event*:
		EventGroup.EventName = (event)
	Removing (and disconnecting) an event:
		EventGroup.EventName = nil

	Adding a new subgroup (and adding event to that group)**:
		EventGroup.NewGroup.EventName = (event)
	Removing a subgroup (and removing all of the group's events):
		EventGroup.NewGroup = nil

	Getting all events:
		EventGroup("GetEvents")
	Getting all subgroups:
		EventGroup("GetGroups")
	Removing all events and subgroups:
		EventGroup("Clear")

	*If an event or group already exists with the same name, it will first be removed.
	**The group does not have to be created beforehand.
]]

class'EventGroup'(function(def)
	local eventContainer = {}
	local groupContainer = {}

	local methods = {
		GetEvents = function(self)
			local copy = {}
			for name,event in pairs(eventContainer) do
				copy[name] = event
			end
			return copy
		end;
		GetGroups = function(self)
			local copy = {}
			for name,group in pairs(groupContainer) do
				copy[name] = group
			end
			return copy
		end;
		Clear = function(self)
			for k in pairs(eventContainer) do
				self[k] = nil
			end
			for k in pairs(groupContainer) do
				self[k] = nil
			end
		end;
	}

	setmetatable(def,{
		__index = function(t,k)
			local event = eventContainer[k]
			if event then
				return event
			else
				local group = groupContainer[k]
				if group == nil then
					group = CreateEventGroup()
					groupContainer[k] = group
				end
				return group
			end
		end;
		__newindex = function(t,k,v)
			local event = eventContainer[k]
			if event ~= nil then
				event:disconnect()
				eventContainer[k] = nil
			else
				local group = groupContainer[k]
				if group ~= nil then
					group("Clear")
					groupContainer[k] = nil
				end
			end
			if v ~= nil then
				eventContainer[k] = v
			end
		end;
		__call = function(self,name,...)
			if methods[name] then
				return methods[name](self,...)
			else
				error("EventGroup: "..tostring(name).." is not a valid method",2)
			end
		end;
	})
end)

local Event = CreateEventGroup()

-- go-to for outputting info
function Log(...)
	local out = ""
	local inp = {...}
	local n = #inp
	for i,msg in pairs(inp) do
		out = out .. tostring(msg)
	end
	----------------
	print("LOG:",out)
end

function LogWarning(...)
	local out = ""
	local inp = {...}
	local n = #inp
	for i,msg in pairs(inp) do
		out = out .. tostring(msg)
	end
	----------------
	print("LOG_WARNING:",out)
end

function LogError(...)
	local out = ""
	local inp = {...}
	local n = #inp
	for i,msg in pairs(inp) do
		out = out .. tostring(msg)
	end
	----------------
	print("LOG_ERROR:",out)
end

local function TransformModel(objects, center, new, recurse)
	for _,object in pairs(objects) do
		if object:IsA("BasePart") then
			object.CFrame = new:toWorldSpace(center:toObjectSpace(object.CFrame))
		end
		if recurse then
			TransformModel(object:GetChildren(), center, new, true)
		end
	end
end

local function RecurseFilter(object,class,out)
	if object:IsA(class) then
		table.insert(out,object)
	end
	for _,child in pairs(object:GetChildren()) do
		RecurseFilter(child,class,out)
	end
end

local function GetFiltered(class,objects)
	local out = {}
	for _,object in pairs(objects) do
		RecurseFilter(object,class,out)
	end
	return out
end;

local bb_points = {
	Vector3.new(-1,-1,-1);
	Vector3.new( 1,-1,-1);
	Vector3.new(-1, 1,-1);
	Vector3.new( 1, 1,-1);
	Vector3.new(-1,-1, 1);
	Vector3.new( 1,-1, 1);
	Vector3.new(-1, 1, 1);
	Vector3.new( 1, 1, 1);
}

-- recursive for GetBoundingBox
local function RecurseGetBoundingBox(object,sides,parts)
	if object:IsA"BasePart" then
		local mod = object.Size/2
		local rot = object.CFrame
		for i = 1,#bb_points do
			local point = rot*NewCFrame(mod*bb_points[i]).p
			if point.x > sides[1] then sides[1] = point.x end
			if point.x < sides[2] then sides[2] = point.x end
			if point.y > sides[3] then sides[3] = point.y end
			if point.y < sides[4] then sides[4] = point.y end
			if point.z > sides[5] then sides[5] = point.z end
			if point.z < sides[6] then sides[6] = point.z end
		end
		if parts then parts[#parts + 1] = object end
	end
	local children = object:GetChildren()
	for i = 1,#children do
		RecurseGetBoundingBox(children[i],sides,parts)
	end
end

local function GetBoundingBox(objects,return_parts)
	local sides = {-math.huge;math.huge;-math.huge;math.huge;-math.huge;math.huge}
	local parts
	if return_parts then
		parts = {}
	end
	for i = 1,#objects do
		RecurseGetBoundingBox(objects[i],sides,parts)
	end
	return
		Vector3.new(sides[1]-sides[2],sides[3]-sides[4],sides[5]-sides[6]),
		Vector3.new((sides[1]+sides[2])/2,(sides[3]+sides[4])/2,(sides[5]+sides[6])/2),
		parts
end

local anchor_lookup = {}
local function Anchor(part,reset)
	if reset then
		local anchored = anchor_lookup[part]
		if anchored ~= nil then
			part.Anchored = anchored
			anchor_lookup[part] = nil
		end
	else
		if anchor_lookup[part] == nil then
			anchor_lookup[part] = part.Anchored
			part.Anchored = true
		end
	end
end


local DisplayInfoGUI
local function DisplayInfo(...)
	if DisplayInfoGUI then
		DisplayInfoGUI.Text = ""
		for i,v in pairs{...} do
			if type(v) == "number" then
				DisplayInfoGUI.Text = DisplayInfoGUI.Text .. tostring(NumFix(math.abs(v),5)) .. " "
			else
				DisplayInfoGUI.Text = DisplayInfoGUI.Text .. tostring(v) .. " "
			end
		end
	end
end

local Camera = Workspace.CurrentCamera
local function CameraLookAt(cf)
	Camera.Focus = cf
	Camera.CoordinateFrame = CFrame.new(Camera.CoordinateFrame.p,cf.p)
end

local SettingsData = {
	Layout = {};
	Options = {};
	Style = {};
}

--SettingsButton

local Overlay = Create 'Part' {
	Name			= "SelectionOverlay";
	Anchored		= true;
	CanCollide		= false;
	Locked			= true;
	FormFactor		= "Custom";
	TopSurface		= 0;
	BottomSurface	= 0;
	Transparency	= 1;
	Archivable		= false;
}

local OverlayHandles = Create 'Handles' {
	Name		= "OverlayHandles";
	Adornee		= Overlay;
	Visible		= false;
	Archivable	= false;
}
local OverlayArcHandles = Create 'ArcHandles' {
	Name		= "OverlayArcHandles";
	Adornee		= Overlay;
	Visible		= false;
	Archivable	= false;
}
local OverlaySelectionBox = Create 'SelectionBox' {
	Name		= "OverlaySelectionBox";
	Adornee		= Overlay;
	Visible		= false;
	Archivable	= false;
}
local OverlaySurfaceSelection = Create 'SurfaceSelection' {
	Name		= "OverlaySurfaceSelection";
	Adornee		= Overlay;
	Visible		= false;
	Archivable	= false;
}
--[[
local OverlayGUI = Create 'ScreenGui' {	-- TODO: find object that doesn't spam output
	Name		= "OverlayGUI";
	Archivable	= false;
	OverlayHandles;
	OverlayArcHandles;
	OverlaySelectionBox;
	OverlaySurfaceSelection;
}
--]]

local function OverlayGUIParent(parent)
	OverlayHandles.Parent = parent
	OverlayArcHandles.Parent = parent
	OverlaySelectionBox.Parent = parent
	OverlaySurfaceSelection.Parent = parent
end

local function WrapOverlay(object,isbb,min_size)
	if type(object) == "table" then
		if #object > 0 then
			local size,pos,parts = GetBoundingBox(object,true)
			if min_size and size.magnitude < min_size.magnitude then
				Overlay.Size = min_size
			else
				Overlay.Size = size
			end
			Overlay.CFrame = CFrame.new(pos)
			OverlayGUIParent(CoreGui)
			return size,pos,parts
		else
			OverlayGUIParent(nil)
		end
	elseif object == nil then
		OverlayGUIParent(nil)
	elseif object:IsA"BasePart" then
		if isbb then
			local size,pos,parts = GetBoundingBox({object},true)
			pos = CFrame.new(pos)
			if min_size and size.magnitude < min_size.magnitude then
				Overlay.Size = min_size
			else
				Overlay.Size = size
			end
			Overlay.CFrame = pos
			OverlayGUIParent(CoreGui)
			return size,pos,parts
		else
			local size,pos = object.Size,object.CFrame
			if min_size and size.magnitude < min_size.magnitude then
				Overlay.Size = min_size
			else
				Overlay.Size = size
			end
			Overlay.CFrame = pos
			OverlayGUIParent(CoreGui)
			return size,pos
		end
	end
end

local function SetOverlaySize(size)
	local cf = Overlay.CFrame
	Overlay.Size = size
	Overlay.CFrame = cf
end

local function SetOverlay(size,cf)
	Overlay.Size = size
	Overlay.CFrame = cf
end

local Selection = game:GetService("Selection")

local function SelectionAdd(object)
		local objects = Selection:Get()
		objects[#objects+1] = object
		Selection:Set(objects)
end

local function SelectionRemove(object)
	local objects = Selection:Get()
	for i,v in pairs(objects) do
		if v == object then
			table.remove(objects,i)
			break
		end
	end
	Selection:Set(objects)
end

local function SelectionSet(objects)
	Selection:Set(objects)
end

local function InSelection(object)
	local objects = Selection:Get()
	for i,v in pairs(objects) do
		if v == object then
			return true
		end
	end
	return false
end

local function GetFilteredSelection(class)
	local out = {}
	for _,object in pairs(Selection:Get()) do
		RecurseFilter(object,class,out)
	end
	return out
end

local ALT_KEYS = {
	["\51"] = true;
	["\52"] = true;
}
local Mouse_Alt_Active = false

local CTRL_KEYS = {
	["\47"] = true;
	["\48"] = true;
	["\49"] = true;
	["\50"] = true;
}
local Mouse_Ctrl_Active = false

local ModelScope = Workspace

local function GetTop(object,scope)
	if not object then return nil end
	if object.Locked then return nil end
	if not object:IsDescendantOf(scope) then return nil end
	local top = object
	repeat
		top = top.Parent
		if top == nil then return object end
	until top.Parent == scope
	return top
end

local function DoubleClick(Mouse)
	local Target = GetTop(Mouse.Target,ModelScope)
	if Target then
		if Target:IsA"Model" then
			SelectionSet{}
			ModelScope = Target
			DisplayInfo("Scope into:",ModelScope:GetFullName())
		end
	elseif ModelScope:IsDescendantOf(Workspace) then
		SelectionSet{ModelScope}
		ModelScope = ModelScope.Parent
		DisplayInfo("Scope out to:",ModelScope:GetFullName())
	end
end

local LastTarget = nil
local function Click(Mouse,first,remove)
	local Target = GetTop(Mouse.Target,ModelScope)
	if first then
		LastTarget = Target
		if Target then
			if Mouse_Ctrl_Active then
				if InSelection(Target) then
					SelectionRemove(Target)
					return true
				else
					SelectionAdd(Target)
					return false
				end
			else
				SelectionSet{Target}
			end
		else
			SelectionSet{}
		end
	else
		if Target ~= LastTarget then
			LastTarget = Target
			if Mouse_Ctrl_Active then
				if Target then
					if remove then
						SelectionRemove(Target)
					else
						SelectionAdd(Target)
					end
				end
			else
				SelectionSet{Target}
			end
		end
	end
end

local Mouse_Active = false

local function ActivateMouse()
	Mouse_Active = true
	Plugin:Activate(true)
	ActivateMouseButton:SetActive(true)
	
	local Mouse = Plugin:GetMouse()
	
	ModelScope = Workspace

	local Down = false
	
	local select_hold = true
	local click_stamp = 0
	
	Event.Mouse.Down = Mouse.Button1Down:connect(function()
		Down = true
		if not Mouse_Alt_Active then
			local stamp = tick()
			if stamp-click_stamp < 0.3 then
				DoubleClick(Mouse)
			else
				local remove = Click(Mouse,true)
				if select_hold then
					Event.Mouse.SelectHold = Mouse.Move:connect(function()
						Click(Mouse,false,remove)
					end)
				end
			end
			click_stamp = stamp
		end
	end)
	Event.Mouse.Up = Mouse.Button1Up:connect(function()
		Down = false
		Event.Mouse.SelectHold = nil
	end)
	Event.Mouse.Move = Mouse.Move:connect(function()
		click_stamp = 0
		if Mouse.Target then
			Mouse.Icon = "rbxasset://textures/DragCursor.png"
		else
			Mouse.Icon = "rbxasset://textures/ArrowCursor.png"
		end
	end)
	Event.Mouse.KeyDown = Mouse.KeyDown:connect(function(key)
		if CTRL_KEYS[key] then
			Mouse_Ctrl_Active = true
		elseif ALT_KEYS[key] then
			Mouse_Alt_Active = true
		end
	end)
	Event.Mouse.KeyUp = Mouse.KeyUp:connect(function(key)
		if CTRL_KEYS[key] then
			Mouse_Ctrl_Active = false
		elseif ALT_KEYS[key] then
			Mouse_Alt_Active = false
		end
	end)
end

local function DeactivateMouse()
	Event.Mouse = nil
	ActivateMouseButton:SetActive(false)
	Mouse_Active = false
end

if ActivateMouseButton then
	ActivateMouseButton.Click:connect(function()
		if Mouse_Active then
			DeactivateMouse()
		else
			ActivateMouse()
		end
	end)
	Plugin.Deactivation:connect(DeactivateMouse)
end

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

local Menu = "Move"
table.insert(MenuList,Menu)
Menus[Menu] = {
	Tools = {};
	Variables = {
		Increment = 1;
	};
	VariableList = {
		{"Increment","Move Increment"};
	};
	Color = Color3.new(0.854902, 0.521569, 0.254902);
}

local Tool = "MoveAxis"

table.insert(Menus[Menu].Tools,Tool)
Variables[Tool] = Menus[Menu].Variables

OnToolSelect[Tool] = function(tool,vars)
	OverlayHandles.Color = BrickColor.new("Bright orange")
	OverlayHandles.Style = "Movement"
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
		local pos = Vector3FromNormalId(face)*rdis
		for part,cframe in pairs(origin) do
			Anchor(part)
			part.CFrame = cframe + pos
			Anchor(part,true)
		end
		Overlay.CFrame = ocf+pos
		DisplayInfo("Move:",rdis)
	end)
end

OnSelectionChanged[Tool] = function(tool,vars)
	local selection = GetFilteredSelection("BasePart")
	ToolSelection = selection
	WrapOverlay(selection,true)
end

OnToolDeselect[Tool] = function(tool,vars)
	Event[tool] = nil
	OverlayHandles.Visible = false
end

local Tool = "MoveFirst"

table.insert(Menus[Menu].Tools,Tool)
Variables[Tool] = Menus[Menu].Variables

OnToolSelect[Tool] = function(tool,vars)
	OverlayHandles.Color = BrickColor.new("Bright orange")
	OverlayHandles.Style = "Resize"
	OverlayHandles.Visible = true

	local origin = {}
	local corigin
	local ocf = Overlay.CFrame
	local inc = vars.Increment
	Event[tool].Down = OverlayHandles.MouseButton1Down:connect(function(face)
		inc = vars.Increment
		corigin = ToolSelection[1].CFrame
		for k in pairs(origin) do
			origin[k] = nil
		end
		for _,part in pairs(ToolSelection) do
			origin[part] = corigin:toObjectSpace(part.CFrame)
		end
		ocf = corigin:toObjectSpace(Overlay.CFrame)
		DisplayInfo("Move:",0)
	end)
	Event[tool].Drag = OverlayHandles.MouseDrag:connect(function(face,distance)
		local rdis = Snap(distance,inc)
		local cf = corigin * CFrame.new(Vector3FromNormalId(face)*rdis)
		for part,cframe in pairs(origin) do
			Anchor(part)
			part.CFrame = cf:toWorldSpace(cframe)
			Anchor(part,true)
		end
		Overlay.CFrame = cf:toWorldSpace(ocf)
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

local Menu = "Rotate"
table.insert(MenuList,Menu)
Menus[Menu] = {
	Tools = {};
	Variables = {
		Increment = 45;
	};
	VariableList = {
		{"Increment","Rotation Increment"};
	};
	Color = Color3.new(0.643137, 0.741176, 0.278431);
}

local Tool = "RotatePivot"

table.insert(Menus["Rotate"].Tools,Tool)
Variables[Tool] = Menus["Rotate"].Variables

local min_size = Vector3.new(4,4,4)

OnToolSelect[Tool] = function(tool,vars)
	OverlayArcHandles.Color = BrickColor.new("Br. yellowish green")
	OverlayArcHandles.Visible = true

	local origin = {}
	local corigin
	local ocf
	local inc = vars.Increment
	Event[tool].Down = OverlayArcHandles.MouseButton1Down:connect(function(axis)
		inc = vars.Increment
		corigin = ToolSelection[1].CFrame
		for k in pairs(origin) do
			origin[k] = nil
		end
		for _,part in pairs(ToolSelection) do
			origin[part] = corigin:toObjectSpace(part.CFrame)
		end
		ocf = corigin:toObjectSpace(Overlay.CFrame)
		DisplayInfo("Rotate:",0)
	end)
	Event[tool].Drag = OverlayArcHandles.MouseDrag:connect(function(axis,angle)
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
	local selection = GetFilteredSelection("BasePart")
	ToolSelection = selection
	WrapOverlay(selection[1],false,min_size)
end

OnToolDeselect[Tool] = function(tool,vars)
	Event[tool] = nil
	OverlayArcHandles.Visible = false
end

local Tool = "RotateGroup"

table.insert(Menus["Rotate"].Tools,Tool)
Variables[Tool] = Menus["Rotate"].Variables

local min_size = Vector3.new(4,4,4)

OnToolSelect[Tool] = function(tool,vars)
	OverlayArcHandles.Color = BrickColor.new("Br. yellowish green")
	OverlayArcHandles.Visible = true

	local origin = {}
	local corigin = Overlay.CFrame
	local inc = vars.Increment
	Event[tool].Down = OverlayArcHandles.MouseButton1Down:connect(function(axis)
		inc = vars.Increment
		corigin = Overlay.CFrame
		for k in pairs(origin) do
			origin[k] = nil
		end
		for _,part in pairs(ToolSelection) do
			origin[part] = corigin:toObjectSpace(part.CFrame)
		end
		DisplayInfo("Rotate:",0)
	end)
	Event[tool].Drag = OverlayArcHandles.MouseDrag:connect(function(axis,angle)
		local rdis = Snap(math.deg(angle),inc)
		local a = Vector3FromAxis(axis)*math.rad(rdis)
		local new = corigin * CFrame.Angles(a.x,a.y,a.z)
		for part,cframe in pairs(origin) do
			Anchor(part)
			part.CFrame = new:toWorldSpace(cframe)
			Anchor(part,true)
		end
		Overlay.CFrame = new
		DisplayInfo("Rotate:",rdis)
	end)
end

OnSelectionChanged[Tool] = function(tool,vars)
	local selection = GetFilteredSelection("BasePart")
	ToolSelection = selection
	WrapOverlay(ToolSelection,true,min_size)
end

OnToolDeselect[Tool] = function(tool,vars)
	Event[tool] = nil
	OverlayArcHandles.Visible = false
end

local Tool = "RotateObject"

table.insert(Menus["Rotate"].Tools,Tool)
Variables[Tool] = Menus["Rotate"].Variables

local min_size = Vector3.new(4,4,4)

OnToolSelect[Tool] = function(tool,vars)
	OverlayArcHandles.Color = BrickColor.new("Br. yellowish green")
	OverlayArcHandles.Visible = true

	local origin = {}
	local ocf = Overlay.CFrame
	local inc = vars.Increment
	Event[tool].Down = OverlayArcHandles.MouseButton1Down:connect(function(axis)
		inc = vars.Increment
		for k in pairs(origin) do
			origin[k] = nil
		end
		for _,part in pairs(ToolSelection) do
			origin[part] = part.CFrame
		end
		ocf = Overlay.CFrame
		DisplayInfo("Rotate:",0)
	end)
	Event[tool].Drag = OverlayArcHandles.MouseDrag:connect(function(axis,angle)
		local rdis = Snap(math.deg(angle),inc)
		local a = Vector3FromAxis(axis)*math.rad(rdis)
		local new = CFrame.Angles(a.x,a.y,a.z)
		for part,cframe in pairs(origin) do
			Anchor(part)
			part.CFrame = cframe * new
			Anchor(part,true)
		end
		Overlay.CFrame = ocf * new
		DisplayInfo("Rotate:",rdis)
	end)
end

OnSelectionChanged[Tool] = function(tool,vars)
	local selection = GetFilteredSelection("BasePart")
	ToolSelection = selection
	WrapOverlay(selection[1],false,min_size)
end

OnToolDeselect[Tool] = function(tool,vars)
	Event[tool] = nil
	OverlayArcHandles.Visible = false
end

local Menu = "Resize"
table.insert(MenuList,Menu)
Menus[Menu] = {
	Tools = {};
	Variables = {
		Increment = 1;
	};
	VariableList = {
		{"Increment","Resize Increment"};
	};
	Color = Color3.new(0.0156863, 0.686275, 0.92549);
}

local FF_CUSTOM = Enum.FormFactor.Custom

-- fixes the resizing direction for a face
local FACE_MULTIPLIER = {
	[Enum.NormalId.Back]	=  1;
	[Enum.NormalId.Bottom]	= -1;
	[Enum.NormalId.Front]	= -1;
	[Enum.NormalId.Left]	= -1;
	[Enum.NormalId.Right]	=  1;
	[Enum.NormalId.Top]		=  1;
}

-- selects a component from face vector
local FACE_COMPONENT = {
	[Enum.NormalId.Back]	= "z";
	[Enum.NormalId.Bottom]	= "y";
	[Enum.NormalId.Front]	= "z";
	[Enum.NormalId.Left]	= "x";
	[Enum.NormalId.Right]	= "x";
	[Enum.NormalId.Top]		= "y";
}

-- form factor size for x and z components
local FORMFACTOR_SNAP_XZ = {
	[Enum.FormFactor.Symmetric]	= 1;
	[Enum.FormFactor.Brick]		= 1;
	[Enum.FormFactor.Plate]		= 1;
	[Enum.FormFactor.Custom]	= 0.2;
	["TrussPart"]				= 2;
}

-- form factor size for y component
local FORMFACTOR_SNAP_Y = {
	[Enum.FormFactor.Symmetric]	= 1;
	[Enum.FormFactor.Brick]		= 1.2;
	[Enum.FormFactor.Plate]		= 0.4;
	[Enum.FormFactor.Custom]	= 0.2;
	["TrussPart"]				= 2;
}

-- maps each face to form factor sizes
local FORMFACTOR_MULTIPLIER = {
	[Enum.NormalId.Back]	= FORMFACTOR_SNAP_XZ;
	[Enum.NormalId.Bottom]	= FORMFACTOR_SNAP_Y;
	[Enum.NormalId.Front]	= FORMFACTOR_SNAP_XZ;
	[Enum.NormalId.Left]	= FORMFACTOR_SNAP_XZ;
	[Enum.NormalId.Right]	= FORMFACTOR_SNAP_XZ;
	[Enum.NormalId.Top]		= FORMFACTOR_SNAP_Y;
}

local function GetFormFactor(object)
	if object:IsA"FormFactorPart" then
		return object.FormFactor
	elseif FORMFACTOR_SNAP_Y[object.ClassName] then
		return object.ClassName
	else
		return Enum.FormFactor.Symmetric
	end
end

local Tool = "ResizeObject"

table.insert(Menus[Menu].Tools,Tool)
Variables[Tool] = Menus[Menu].Variables

OnToolSelect[Tool] = function(tool,vars)
	OverlayHandles.Color = BrickColor.new("Cyan")
	OverlayHandles.Style = "Resize"
	OverlayHandles.Visible = true

	local origin = {}
	local first
	local face_mult,face_size,face_vec
	local cinc
	local inc
	Event[tool].Down = OverlayHandles.MouseButton1Down:connect(function(face)
		face_mult,face_size,face_vec = FACE_MULTIPLIER[face],FACE_COMPONENT[face],Vector3FromNormalId(face)
		first = ToolSelection[1]
		for k in pairs(origin) do
			origin[k] = nil
		end
		for _,part in pairs(ToolSelection) do
			local ff = GetFormFactor(part)
			origin[part] = {part.CFrame,part.Size,ff,FORMFACTOR_MULTIPLIER[face][ff]}
		end
		cinc = vars.Increment
		inc = Snap(cinc,1)
		if inc == 0 then
			inc = 1
		end
		DisplayInfo("Resize:",0)
	end)
	Event[tool].Drag = OverlayHandles.MouseDrag:connect(function(face,distance)
		local dis = distance*face_mult
		for part,info in pairs(origin) do
			local sz,ff,ffm = info[2],info[3],info[4]
			local mult
			if ff == FF_CUSTOM then
				mult = Snap(dis,cinc)
			else
				mult = Snap(dis,inc*ffm)
			end
			local mod = face_vec*mult
			local fsize = sz[face_size]
			mod = fsize + mult*face_mult < ffm and face_vec*((ffm-fsize)*face_mult) or mod
			Anchor(part)
			part.Size = sz + mod
			part.CFrame = info[1] * CFrame.new(mod*face_mult/2)
			Anchor(part,true)
			if part == first then DisplayInfo("Resize:",mod.magnitude) end
		end
		SetOverlay(first.Size,first.CFrame)
	end)
end

OnSelectionChanged[Tool] = function(tool,vars)
	local selection = GetFilteredSelection("BasePart")
	ToolSelection = selection
	WrapOverlay(selection[1],false)
end

OnToolDeselect[Tool] = function(tool,vars)
	Event[tool] = nil
	OverlayHandles.Visible = false
end

local Tool = "ResizeCenter"

table.insert(Menus[Menu].Tools,Tool)
Variables[Tool] = Menus[Menu].Variables

OnToolSelect[Tool] = function(tool,vars)
	OverlayHandles.Color = BrickColor.new("Cyan")
	OverlayHandles.Style = "Resize"
	OverlayHandles.Visible = true

	local origin = {}
	local first
	local face_mult,face_size,face_vec
	local cinc
	local inc
	Event[tool].Down = OverlayHandles.MouseButton1Down:connect(function(face)
		face_mult,face_size,face_vec = FACE_MULTIPLIER[face],FACE_COMPONENT[face],Vector3FromNormalId(face)
		first = ToolSelection[1]
		for k in pairs(origin) do
			origin[k] = nil
		end
		for _,part in pairs(ToolSelection) do
			local ff = GetFormFactor(part)
			origin[part] = {part.CFrame,part.Size,ff,FORMFACTOR_MULTIPLIER[face][ff]}
		end
		cinc = vars.Increment
		inc = Snap(cinc,1)
		if inc == 0 then
			inc = 1
		end
		DisplayInfo("Resize:",0)
	end)
	Event[tool].Drag = OverlayHandles.MouseDrag:connect(function(face,distance)
		local dis = distance*2*face_mult
		for part,info in pairs(origin) do
			local sz,ff,ffm = info[2],info[3],info[4]
			local mult
			if ff == FF_CUSTOM then
				mult = Snap(dis,cinc)
			else
				mult = Snap(dis,inc*ffm)
			end
			local mod = face_vec*mult
			local fsize = sz[face_size]
			mod = fsize + mult*face_mult < ffm and face_vec*((ffm-fsize)*face_mult) or mod
			Anchor(part)
			part.Size = sz + mod
			part.CFrame = info[1]
			Anchor(part,true)
			if part == first then DisplayInfo("Resize:",mod.magnitude) end
		end
		SetOverlay(first.Size,first.CFrame)
	end)
end

OnSelectionChanged[Tool] = function(tool,vars)
	local selection = GetFilteredSelection("BasePart")
	ToolSelection = selection
	WrapOverlay(selection[1],false)
end

OnToolDeselect[Tool] = function(tool,vars)
	Event[tool] = nil
	OverlayHandles.Visible = false
end

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

local Tool = "Copy"

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
	end
	DisplayInfo("Copied selection to clipboard")
	SelectPreviousTool()
end

local Tool = "Paste"

table.insert(Menus[Menu].Tools,Tool)
Variables[Tool] = Menus[Menu].Variables

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

local Menu = "SelectEdge"
table.insert(MenuList,Menu)
Menus[Menu] = {
	Tools = {};
	Variables = {
		EdgeSnap = 0.5;
		RotIncrement = 45;
	};
	VariableList = {
		{"RotIncrement","Rotation Increment"};
		{"EdgeSnap","Edge Snap"};
	};
	Color = Color3.new(0.960784, 0.803922, 0.188235);
}

local function GetRelativeEdge(p,s,inc)
	local ax,ay,az = math.abs(p.x/s.x),math.abs(p.y/s.y),math.abs(p.z/s.z)
	return Vector3.new(NumNormal(p.x),NumNormal(p.y),NumNormal(p.z)) * Vector3.new(
		(ax>ay or ax>az) and s.x or Snap(math.abs(p.x),inc),
		(ay>ax or ay>az) and s.y or Snap(math.abs(p.y),inc),
		(az>ax or az>ay) and s.z or Snap(math.abs(p.z),inc)
	)
end

local function FilterTarget(target)
	if target then
		if not target.Locked then
			return target
		end
	end
	return nil
end

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

local Menu = "Insert"
table.insert(MenuList,Menu)
Menus[Menu] = {
	Tools = {};
	Variables = {
	};
	VariableList = {
	};
	Color = Color3.new(102, 0, 102);
}

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

local Tool = "Wedge"

table.insert(Menus[Menu].Tools,Tool)
Variables[Tool] = Menus[Menu].Variables

OnToolSelect[Tool] = function(tool)
	local copy = {}
	local copy_parent = {}
	local selection = Selection:Get()
	if #selection == 0 then
		local Part = Instance.new("WedgePart", Workspace)
		Part.Size = Vector3.new(4, 1.2, 2)
		copy[1] = Part
		CameraLookAt(CFrame.new(Part.Position.x, Part.Position.y, Part.Position.z))
		DisplayInfo("Added Wedge")
		Selection:Set(copy)
		SelectPreviousTool()
		return
	end

		local object = Instance.new("WedgePart")
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

local Tool = "CornerWedge"

table.insert(Menus[Menu].Tools,Tool)
Variables[Tool] = Menus[Menu].Variables

OnToolSelect[Tool] = function(tool)
	local copy = {}
	local copy_parent = {}
	local selection = Selection:Get()
	if #selection == 0 then
		local Part = Instance.new("CornerWedgePart", Workspace)
		Part.Size = Vector3.new(4, 1.2, 2)
		copy[1] = Part
		CameraLookAt(CFrame.new(Part.Position.x, Part.Position.y, Part.Position.z))
		DisplayInfo("Added CornerWedge")
		Selection:Set(copy)
		SelectPreviousTool()
		return
	end

		local object = Instance.new("CornerWedgePart")
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

local Tool = "TrussPart"

table.insert(Menus[Menu].Tools,Tool)
Variables[Tool] = Menus[Menu].Variables

OnToolSelect[Tool] = function(tool)
	local copy = {}
	local copy_parent = {}
	local selection = Selection:Get()
	if #selection == 0 then
		local Part = Instance.new("TrussPart", Workspace)
		Part.Size = Vector3.new(4, 1.2, 2)
		copy[1] = Part
		CameraLookAt(CFrame.new(Part.Position.x, Part.Position.y, Part.Position.z))
		DisplayInfo("Added Truss")
		Selection:Set(copy)
		SelectPreviousTool()
		return
	end

		local object = Instance.new("TrussPart")
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


local Screen

local GUI_Initialized = false
local GUI_Active = false

local ExpandPanel
local CollapsePanel

local function InitializeGUI()
	if not _G.gloo then
		error(PROJECT_NAME.." needs the gloo library to load the GUI.",0)
	end

	local draggingMenu = false
	local infoRight = false
	local hoverEnabled = true
	local panelPosition
	local collapseAxis = "x"
	local collapseDirection = -1
	
	local GlobalStylist = _G.gloo.Stylist{
		Font = "ArialBold";
		FontSize = "Size14";
		TextColor3 = Color3.new(1,1,1);
	}

	local MenuStylist = _G.gloo.Stylist{
		BackgroundTransparency = 0.5;
		BackgroundColor3 = Color3.new(0,0,0);
		BorderColor3 = Color3.new(1,1,1);
	}

	local ButtonStylist = _G.gloo.Stylist{
		BackgroundTransparency = 0.5;
		BackgroundColor3 = Color3.new(0,0,0);
		BorderColor3 = Color3.new(1,1,1);
		Size = UDim2.new(0,100,0,20);
		Style = "RobloxButton";
		Selected = false;
	}
	GlobalStylist.AddStylist(ButtonStylist)

	local SelectedButtonStylist = _G.gloo.Stylist{
		BackgroundTransparency = 0.5;
		BackgroundColor3 = Color3.new(0,0,0);
		BorderColor3 = Color3.new(1,1,1);
		Size = UDim2.new(0,100,0,20);
		Style = "RobloxButton";
		Selected = true;
	}
	GlobalStylist.AddStylist(SelectedButtonStylist)

	local MenuNodeStylist = _G.gloo.Stylist{
		BackgroundTransparency = 0.5;
		BorderSizePixel = 0;
		Size = UDim2.new(0,100,0,8);
	}

	local HoverNameStylist = _G.gloo.Stylist{
		AutoButtonColor = false;
		BackgroundTransparency = 1;
		TextStrokeColor3 = Color3.new(0,0,0);
		TextStrokeTransparency = 0;
	}
	GlobalStylist.AddStylist(HoverNameStylist)

	local DockClass = _G.gloo.DockContainer()
	Screen = DockClass.GUI
	Screen.Name = PROJECT_NAME.."GUI"

	DisplayInfoGUI = Create'TextButton'{
		Name = "DisplayInfoGUI";
		Text = "";
		Parent = Screen;
	}
	HoverNameStylist.AddObject(DisplayInfoGUI)
	local InfoClass = _G.gloo.AutoSizeLabel(DisplayInfoGUI)
	InfoClass.LockAxis(nil,24)
	InfoClass.SetPadding(4)

	local MenuContainerClass,MenuContainerFrame = _G.gloo.StackingFrame(Instance.new("ImageButton"))
	MenuContainerClass.SetPadding(4,8)
	Modify(MenuContainerFrame){
		AutoButtonColor = false;
		Name = "MenuContainer";
		BorderSizePixel = 0;
		BackgroundColor3 = Color3.new(0,0,0);
		BackgroundTransparency = 0.3;
		Position = UDim2.new(0,0,0,24);
		Parent = Screen;
	}
	panelPosition = MenuContainerFrame.Position

	local Placeholder = Create'Frame'{
		Name = "Placeholder";
		BackgroundTransparency = 1;
	}
	
	local MouseDrag = Create'ImageButton'{
		Active = false;
		Size = UDim2.new(1.5, 0, 1.5, 0);
		AutoButtonColor = false;
		BackgroundTransparency = 1;
		Name = "MouseDrag";
		Position = UDim2.new(-0.25, 0, -0.25, 0);
		ZIndex = 10;
	}

	local MouseOverFrame = Create'Frame'{
		Name = "MouseOver";
		BackgroundTransparency = 1;
		Parent = Screen;
	}

	local math_env = {
		abs = math.abs; acos = math.acos; asin = math.asin; atan = math.atan; atan2 = math.atan2;
		ceil = math.ceil; cos = math.cos; cosh = math.cosh; deg = math.deg;
		exp = math.exp; floor = math.floor; fmod = math.fmod; frexp = math.frexp;
		huge = math.huge; ldexp = math.ldexp; log = math.log; log10 = math.log10;
		max = math.max; min = math.min; modf = math.modf; pi = math.pi;
		pow = math.pow; rad = math.rad; random = math.random; sin = math.sin;
		sinh = math.sinh; sqrt = math.sqrt; tan = math.tan; tanh = math.tanh;
	}
	
	local function eval(str,prev)
		local env = {}
		for k,v in pairs(math_env) do
			env[k] = v
		end
		env.x = prev
		env.n = prev
		local f = loadstring("return "..str)
		if f then
			setfenv(f,env)
			local s,o = pcall(f)
			if s then
				return o
			end
		end
		return nil
	end

	local function GetPosIndex(list,pos,size)
		list = MenuContainerClass.List
		if #list > 1 then
			local yMax = pos.y
			local index

			for i = 1,#list do
				local menu = list[i]
				if menu.AbsolutePosition.y + menu.AbsoluteSize.y/2 > yMax - size.y
				and menu.AbsolutePosition.y + size.y > yMax - size.y then
					index = i
					break
				end
			end
			return index
		else
			return 1
		end
	end

	local function InvokeMenuDrag(MenuFrame,offset,fToggle)
		draggingMenu = true

		local orderSet = {}
		do
			local list = MenuContainerClass.List
			for i = 1,#list do
				orderSet[i] = list[i].AbsolutePosition + list[i].AbsoluteSize/2
			end
		end

		local mouse_pos = offset + MenuFrame.AbsolutePosition
		Placeholder.Size = MenuFrame.Size
		local index = MenuContainerClass.GetIndex(MenuFrame)
		MenuContainerClass.RemoveObject(MenuFrame)
		MenuContainerClass.AddObject(Placeholder,index)
		MenuFrame.Parent = Screen

		local drag_con
		local up_con

		local doToggle = true
		local zIndex = MenuFrame.ZIndex
		local function mouse_up()
			MouseDrag.Parent = nil
			drag_con:disconnect(); drag_con = nil
			up_con:disconnect(); drag = nil
			_G.gloo.SetZIndex(MenuFrame,zIndex)
			MenuContainerClass.RemoveObject(Placeholder)
			MenuContainerClass.AddObject(MenuFrame,index)
			draggingMenu = false
			if doToggle then
				fToggle()
			end
		end

		local function mouse_drag(x,y)
			local pos = Vector2.new(x,y) - offset
			local x,y = pos.x,pos.y
			local cPos = MenuContainerFrame.AbsolutePosition + Vector2.new(8,8)
			local max = cPos + MenuContainerFrame.AbsoluteSize - Vector2.new(16,16)

			if y > max.y then
				y = max.y
			elseif y < cPos.y then
				y = cPos.y
			end

			MenuFrame.Position = UDim2.new(0,cPos.x,0,y)
			index = GetPosIndex(orderSet,MenuFrame.AbsolutePosition + MenuFrame.AbsoluteSize/2,MenuFrame.AbsoluteSize/2) or index
			MenuContainerClass.MoveObject(Placeholder,index)
		end

		drag_con = MouseDrag.MouseMoved:connect(function(...)
			doToggle = false
			mouse_drag(...)
		end)
		up_con = MouseDrag.MouseButton1Up:connect(mouse_up)
		_G.gloo.SetZIndex(MenuFrame,zIndex + 1)
		MouseDrag.Parent = Screen
		mouse_drag(mouse_pos.x,mouse_pos.y)
	end

	for i,menu_name in pairs(MenuList) do
		local menu = Menus[menu_name]
		local MenuClass,MenuFrame = _G.gloo.StackingFrame()
		MenuClass.SetPadding()
		MenuStylist.AddObject(MenuFrame)
		MenuContainerClass.AddObject(MenuFrame)

		do
			local Node = Instance.new("ImageButton")
			if menu.Color then
				Node.BackgroundColor3 = menu.Color
			else
				Node.BackgroundColor3 = Color3.new(1,1,1)
			end
			MenuNodeStylist.AddObject(Node)
			MenuClass.AddObject(Node)
			local label = Instance.new('TextLabel')
			local labelClass = _G.gloo.AutoSizeLabel(label)
			labelClass.LockAxis(nil,8)
			labelClass.SetPadding(4)
			HoverNameStylist.AddObject(label)
			label.Visible = false
			label.Text = menu_name .. " Menu"
			label.Parent = Node
			Node.MouseEnter:connect(function()
				if Node.AbsolutePosition.x + Node.AbsoluteSize.x + label.AbsoluteSize.x > Screen.AbsoluteSize.x then
					label.Position = UDim2.new(0,-label.AbsoluteSize.x,0,0)
				else
					label.Position = UDim2.new(1,0,0,0)
				end
				label.Visible = true
			end)
			Node.MouseLeave:connect(function() label.Visible = false end)

			local visible = true
			local function toggle_menu()
				visible = not visible
				for i,button in pairs(MenuClass.List) do
					if button ~= Node then
						button.Visible = visible
					end
				end
			end

			Node.MouseButton1Down:connect(function(x,y)
				label.Visible = false
				InvokeMenuDrag(MenuFrame,Vector2.new(x,y) - MenuFrame.AbsolutePosition,toggle_menu)
			end)
		end
		local vars = menu.Variables
		for i,var in pairs(menu.VariableList) do
			local name = var[1]
			local field
			if type(vars[name]) == 'number' then
				field = Instance.new("TextBox")
				ButtonStylist.AddObject(field)
				MenuClass.AddObject(field)
				field.Text = vars[name]
				field.FocusLost:connect(function(enter)
					local num = tonumber(eval(field.Text,vars[name]))
					if num then
						vars[name] = num
						field.Text = num
					else
						field.Text = vars[name]
					end
				end)
			end
			if field then
				local label = Instance.new('TextLabel',field)
				local labelClass = _G.gloo.AutoSizeLabel(label)
				labelClass.LockAxis(nil,20)
				labelClass.SetPadding(4)
				HoverNameStylist.AddObject(label)
				label.Visible = false
				label.Text = var[2]
				field.MouseEnter:connect(function()
					if field.AbsolutePosition.x + field.AbsoluteSize.x + label.AbsoluteSize.x > Screen.AbsoluteSize.x then
						label.Position = UDim2.new(0,-label.AbsoluteSize.x,0,0)
					else
						label.Position = UDim2.new(1,0,0,0)
					end
					label.Visible = true
				end)
				field.MouseLeave:connect(function() label.Visible = false end)
			end
		end

		for i,tool in pairs(menu.Tools) do
			local button = Instance.new("TextButton")
			ButtonStylist.AddObject(button)
			button.Name = tool .. "Button"
			button.Text = tool
			MenuClass.AddObject(button)
			ToolSelectCallback[tool] = function()
				ButtonStylist.RemoveObject(button)
				SelectedButtonStylist.AddObject(button)
			end
			ToolDeselectCallback[tool] = function()
				SelectedButtonStylist.RemoveObject(button)
				ButtonStylist.AddObject(button)
			end
			button.MouseButton1Click:connect(function()
				SelectTool(tool)
			end)
		end
	end

	local function tweenPanel(position,dir,notween)
		if notween == true then
			MenuContainerFrame.Position = position
		else
			MenuContainerFrame:TweenPosition(position,dir,"Quad",0.25,true)
		end
	end

	function ExpandPanel(notween)
		if hoverEnabled and collapseDirection ~= 0 then
			DisplayInfoGUI.Visible = true
			if collapseAxis == "y" then
				if collapseDirection == 1 then
					tweenPanel(panelPosition,"Out",notween)
				else
					tweenPanel(UDim2.new(panelPosition.X.Scale,panelPosition.X.Offset,0,0),"Out",notween)
				end
			else
				if collapseDirection == 1 then
					tweenPanel(panelPosition,"Out",notween)
				else
					tweenPanel(UDim2.new(0,0,panelPosition.Y.Scale,panelPosition.Y.Offset),"Out",notween)
				end
			end
		end
	end


	function CollapsePanel(notween)
		if hoverEnabled and collapseDirection ~= 0 and not SelectedTool and not draggingMenu then
			DisplayInfoGUI.Visible = false
			if collapseAxis == "y" then
				if collapseDirection == 1 then
					tweenPanel(UDim2.new(panelPosition.X.Scale,panelPosition.X.Offset,1,0),"In",notween)
				else
					tweenPanel(UDim2.new(panelPosition.X.Scale,panelPosition.X.Offset,0,-MenuContainerFrame.AbsoluteSize.y),"In",notween)
				end
			else
				if collapseDirection == 1 then
					tweenPanel(UDim2.new(1,0,panelPosition.Y.Scale,panelPosition.Y.Offset),"In",notween)
				else
					tweenPanel(UDim2.new(0,-MenuContainerFrame.AbsoluteSize.x,panelPosition.Y.Scale,panelPosition.Y.Offset),"In",notween)
				end
			end
		end
	end

	MouseOverFrame.MouseEnter:connect(ExpandPanel)
	MouseOverFrame.MouseLeave:connect(CollapsePanel)

	MenuContainerFrame.Changed:connect(function(p)
		if hoverEnabled and p == "AbsoluteSize" then
			MouseOverFrame.Size = MenuContainerFrame.Size
		end
	end)
	MouseOverFrame.Size = MenuContainerFrame.Size
	MouseOverFrame.Position = MenuContainerFrame.Position

	DisplayInfoGUI.Changed:connect(function(p)
		if infoRight and p == "AbsoluteSize" then
			local pos = DisplayInfoGUI.Position
			DisplayInfoGUI.Position = UDim2.new(1,-DisplayInfoGUI.AbsoluteSize.x,pos.Y.Scale,pos.Y.Offset)
		end
	end)

	DockClass.DragBeginCallback = function(dragged)
		if dragged == MenuContainerFrame then
			hoverEnabled = false
		end
	end

	DockClass.DragCallback = function(dragged)
		if dragged == MenuContainerFrame then
			collapseAxis = "x"
			collapseDirection = 0
		elseif dragged == DisplayInfoGUI then
			infoRight = false
		end
	end

	DockClass.DockCallback = function(dragged,docked,axis,side)
		if dragged == MenuContainerFrame then
			collapseAxis = axis
			collapseDirection = side*2-1
		elseif dragged == DisplayInfoGUI then
			if docked == Screen and axis == "x" and side == 1 then
				infoRight = true
			end
		end
	end

	DockClass.DragStopCallback = function(dragged)
		if dragged == MenuContainerFrame then
			panelPosition = MenuContainerFrame.Position
			MouseOverFrame.Position = panelPosition
			hoverEnabled = true
		end
	end

---- Roblox HUD docking
	local RobloxGui = CoreGui:FindFirstChild("RobloxGui")
	if RobloxGui then
		local function makeDockFrame(object)
			local frame = Create'Frame'{
				Name = object.Name;
				BackgroundTransparency = 1;
				Size = UDim2.new(0,object.AbsoluteSize.x,0,object.AbsoluteSize.y);
				Position = UDim2.new(0,object.AbsolutePosition.x,0,object.AbsolutePosition.y);
			}
			object.Changed:connect(function(p)
				if p == "AbsoluteSize" then
					frame.Size = UDim2.new(0,object.AbsoluteSize.x,0,object.AbsoluteSize.y)
				elseif p == "AbsolutePosition" then
					frame.Position = UDim2.new(0,object.AbsolutePosition.x,0,object.AbsolutePosition.y)
				elseif p == "Visible" then
					frame.Visible = object.Visible
				end
			end)
			frame.Parent = Screen
		end

		local findObjects = {
			MouseLockLabel = function(object)
				return object.Active
			end;
			SettingsButton = true;
			CameraTiltDown = true;
			CameraTiltUp = true;
			CameraZoomIn = true;
			CameraZoomOut = true;
			BackpackButton = true;
		}

		RobloxGui.DescendantAdded:connect(function(object)
			local find = findObjects[object.Name]
			if find then
				if type(f) == "function" then
					if f(object) then
						makeDockFrame(object)
					end
				else
					makeDockFrame(object)
				end
			end
		end)

		for name,f in pairs(findObjects) do
			if type(f) == "function" then
				local object = RobloxGui:FindFirstChild(name,true)
				if object and f(object) then
					makeDockFrame(object)
				end
			else
				local object = RobloxGui:FindFirstChild(name,true)
				if object then
					makeDockFrame(object)
				end
			end
		end

	end

	GUI_Initialized = true
end

local function ActivateGUI()
	if GUI_Initialized then
		ExpandPanel(true)
		Screen.Parent = CoreGui
		GUI_Active = true
	end
end

local function DeactivateGUI()
	if GUI_Initialized then
		GUI_Active = false
		DeselectTool(SelectedTool)
		Screen.Parent = nil
		CollapsePanel(true)
	end
end

if ActivateGUIButton then
	ActivateGUIButton.Click:connect(function()
		if GUI_Initialized then
			if GUI_Active then
				DeactivateGUI()
			else
				ActivateGUI()
			end
		else
			InitializeGUI()
			ActivateGUI()
		end
	end)
end

print(("Loaded %s plugin (v%s)"):format(PROJECT_NAME, VERSION))

