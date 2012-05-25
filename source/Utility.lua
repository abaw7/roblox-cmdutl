local unpack = unpack
if _VERSION == "Lua 5.2" then
	unpack = table.unpack
end

-- snap `number` to nearest `by`
local function Snap(number,by)
	if by == 0 then
		return number
	else
		return math.floor(number/by + 0.5)*by
	end
end

-- returns the number to a fixed number of decimal places
-- FOR TRUE FIXED SIZE: use string.format with "%.[idp]f" tag, where [idp] is the `idp` argument
local function NumFix(num,idp)
	local mult = 10^(idp or 0)
	return math.floor(num*mult + 0.5)/mult
end

-- returns the index of `value` in `table`, if it exists
local function GetIndex(table,value)
	for i,v in pairs(table) do
		if v == value then
			return i
		end
	end
end

local function class(name)
	local def = {}
	return function(ctor, static)
		local nctor = function(...)
			local this = {}
			if ctor then
				ctor(this, ...)
			end
			return this
		end
		if static then static(def) end
		return nctor,def
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

CreateEventGroup = class'EventGroup'(function(def)
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
do
	local prefix = PROJECT_NAME:upper()

	local function combine(...)
		local out = ""
		for i,msg in pairs{...} do
			out = out .. tostring(msg)
		end
		return out
	end

	function Log(...)
		print(prefix.."_MESSAGE:",combine(...))
	end

	function LogWarning(...)
		print(prefix.."_WARNING:",combine(...))
	end

	function LogError(...)
		print(prefix.."_ERROR:",combine(...))
	end
end

-- recurses through table of `objects`, filtering by `class`, and adds matching objects to `out`
local function RecurseFilter(object,class,out)
	if object:IsA(class) then
		table.insert(out,object)
	end
	for _,child in pairs(object:GetChildren()) do
		RecurseFilter(child,class,out)
	end
end

-- wrapper for RecurseFilter
local function GetFiltered(class,objects)
	local out = {}
	for _,object in pairs(objects) do
		RecurseFilter(object,class,out)
	end
	return out
end

-- returns the bounding box for a group of objects
-- returns Vector3 `size`, Vector3 `position`
-- may also return a list of parts in the bounding box
local GetBoundingBox
do
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

	-- helper for GetBoundingBox
	local function RecurseGetBoundingBox(object,sides,parts)
		if object:IsA"BasePart" then
			local mod = object.Size/2
			local rot = object.CFrame
			for i = 1,#bb_points do
				local point = rot*CFrame.new(mod*bb_points[i]).p
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

	GetBoundingBox = function(objects,return_parts)
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
end

-- DEBUG: attempts to fix erratic behavior of unanchored parts by temporarily anchoring
local Anchor
do
	local anchor_lookup = {}
	Anchor = function(part,reset)
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
end

local DisplayInfoGUI
-- Displays info from tools and whatnot
-- DisplayInfoGUI is reserved for a GuiText, Message, or other object with a "Text" property, on which the info will be displayed
-- if not defined, the info will be printed instead
local function DisplayInfo(...)
	local str = {}
	for i,v in pairs{...} do
		if type(v) == "number" then
			str[#str+1] = tostring(NumFix(math.abs(v),5))
		else
			str[#str+1] = tostring(v)
		end
	end
	if DisplayInfoGUI then
		DisplayInfoGUI.Text = table.concat(str," ")
	else
		print(table.concat(str," "))
	end
end

local Camera = Workspace.CurrentCamera
-- camera remains stationary, but looks at `cf`
local function CameraLookAt(cf)
	Camera.Focus = cf
	Camera.CoordinateFrame = CFrame.new(Camera.CoordinateFrame.p,cf.p)
end
