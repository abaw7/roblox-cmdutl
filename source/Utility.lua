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
