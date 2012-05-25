--[[FILE: METADATA]]
PROJECT_NAME = "CmdUtl";
PROJECT_TYPE = "Plugin";
PROJECT_VERSION = "5.1.0";

--[[FILE: source/Header.lua]]
if _G.RegisterPlugin and not _G.RegisterPlugin(PROJECT_NAME) then return end

local Plugin = PluginManager():CreatePlugin()
local Toolbar = Plugin:CreateToolbar(PROJECT_NAME)
local ActivateGUIButton = Toolbar:CreateButton("",""..PROJECT_NAME.." Panel","application_go.png")
local ActivateMouseButton = Toolbar:CreateButton("","Selector","cursor.png")
local ActivateSettingsButton = Toolbar:CreateButton("","Settings","application_edit.png")
local ActivateHelpButton = Toolbar:CreateButton("","Help","help.png")

local CoreGui = game:GetService("CoreGui")

--[[FILE: source/RbxUtility.lua]]
--[[
local RbxUtility = LoadLibrary('RbxUtility')
--[=[]]
local RbxUtility = {}

---------------------------------------
---- INSERT: JSON Encoder & Decoder

 do
	 --JSON Encoder and Parser for Lua 5.1
	 --
	 --Copyright 2007 Shaun Brown  (http://www.chipmunkav.com)
	 --All Rights Reserved.
	 
	 --Permission is hereby granted, free of charge, to any person 
	 --obtaining a copy of this software to deal in the Software without 
	 --restriction, including without limitation the rights to use, 
	 --copy, modify, merge, publish, distribute, sublicense, and/or 
	 --sell copies of the Software, and to permit persons to whom the 
	 --Software is furnished to do so, subject to the following conditions:
	 
	 --The above copyright notice and this permission notice shall be 
	 --included in all copies or substantial portions of the Software.
	 --If you find this software useful please give www.chipmunkav.com a mention.

	 --THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
	 --EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
	 --OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
	 --IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR 
	 --ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
	 --CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
	 --CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

	local string = string
	local math = math
	local table = table
	local error = error
	local tonumber = tonumber
	local tostring = tostring
	local type = type
	local setmetatable = setmetatable
	local pairs = pairs
	local ipairs = ipairs
	local assert = assert
	local Chipmunk = Chipmunk

	local function Null()
		return Null
	end

	local StringBuilder = {
		buffer = {}
	}

	function StringBuilder:New()
		local o = {}
		setmetatable(o, self)
		self.__index = self
		o.buffer = {}
		return o
	end

	function StringBuilder:Append(s)
		self.buffer[#self.buffer+1] = s
	end

	function StringBuilder:ToString()
		return table.concat(self.buffer)
	end

	local JsonWriter = {
		backslashes = {
			['\b'] = "\\b",
			['\t'] = "\\t",	
			['\n'] = "\\n", 
			['\f'] = "\\f",
			['\r'] = "\\r", 
			['"']  = "\\\"", 
			['\\'] = "\\\\", 
			['/']  = "\\/"
		}
	}

	function JsonWriter:New()
		local o = {}
		o.writer = StringBuilder:New()
		setmetatable(o, self)
		self.__index = self
		return o
	end

	function JsonWriter:Append(s)
		self.writer:Append(s)
	end

	function JsonWriter:ToString()
		return self.writer:ToString()
	end

	function JsonWriter:Write(o)
		local t = type(o)
		if t == "nil" then
			self:WriteNil()
		elseif t == "boolean" then
			self:WriteString(o)
		elseif t == "number" then
			self:WriteString(o)
		elseif t == "string" then
			self:ParseString(o)
		elseif t == "table" then
			self:WriteTable(o)
		elseif t == "function" then
			self:WriteFunction(o)
		elseif t == "thread" then
			self:WriteError(o)
		elseif t == "userdata" then
			self:WriteError(o)
		end
	end

	function JsonWriter:WriteNil()
		self:Append("null")
	end

	function JsonWriter:WriteString(o)
		self:Append(tostring(o))
	end

	function JsonWriter:ParseString(s)
		self:Append('"')
		self:Append(string.gsub(s, "[%z%c\\\"/]", function(n)
			local c = self.backslashes[n]
			if c then return c end
			return string.format("\\u%.4X", string.byte(n))
		end))
		self:Append('"')
	end

	function JsonWriter:IsArray(t)
		local count = 0
		local isindex = function(k) 
			if type(k) == "number" and k > 0 then
				if math.floor(k) == k then
					return true
				end
			end
			return false
		end
		for k,v in pairs(t) do
			if not isindex(k) then
				return false, '{', '}'
			else
				count = math.max(count, k)
			end
		end
		return true, '[', ']', count
	end

	function JsonWriter:WriteTable(t)
		local ba, st, et, n = self:IsArray(t)
		self:Append(st)	
		if ba then		
			for i = 1, n do
				self:Write(t[i])
				if i < n then
					self:Append(',')
				end
			end
		else
			local first = true;
			for k, v in pairs(t) do
				if not first then
					self:Append(',')
				end
				first = false;			
				self:ParseString(k)
				self:Append(':')
				self:Write(v)			
			end
		end
		self:Append(et)
	end

	function JsonWriter:WriteError(o)
		error(string.format(
			"Encoding of %s unsupported", 
			tostring(o)))
	end

	function JsonWriter:WriteFunction(o)
		if o == Null then 
			self:WriteNil()
		else
			self:WriteError(o)
		end
	end

	local StringReader = {
		s = "",
		i = 0
	}

	function StringReader:New(s)
		local o = {}
		setmetatable(o, self)
		self.__index = self
		o.s = s or o.s
		return o	
	end

	function StringReader:Peek()
		local i = self.i + 1
		if i <= #self.s then
			return string.sub(self.s, i, i)
		end
		return nil
	end

	function StringReader:Next()
		self.i = self.i+1
		if self.i <= #self.s then
			return string.sub(self.s, self.i, self.i)
		end
		return nil
	end

	function StringReader:All()
		return self.s
	end

	local JsonReader = {
		escapes = {
			['t'] = '\t',
			['n'] = '\n',
			['f'] = '\f',
			['r'] = '\r',
			['b'] = '\b',
		}
	}

	function JsonReader:New(s)
		local o = {}
		o.reader = StringReader:New(s)
		setmetatable(o, self)
		self.__index = self
		return o;
	end

	function JsonReader:Read()
		self:SkipWhiteSpace()
		local peek = self:Peek()
		if peek == nil then
			error(string.format(
				"Nil string: '%s'", 
				self:All()))
		elseif peek == '{' then
			return self:ReadObject()
		elseif peek == '[' then
			return self:ReadArray()
		elseif peek == '"' then
			return self:ReadString()
		elseif string.find(peek, "[%+%-%d]") then
			return self:ReadNumber()
		elseif peek == 't' then
			return self:ReadTrue()
		elseif peek == 'f' then
			return self:ReadFalse()
		elseif peek == 'n' then
			return self:ReadNull()
		elseif peek == '/' then
			self:ReadComment()
			return self:Read()
		else
			return nil
		end
	end
			
	function JsonReader:ReadTrue()
		self:TestReservedWord{'t','r','u','e'}
		return true
	end

	function JsonReader:ReadFalse()
		self:TestReservedWord{'f','a','l','s','e'}
		return false
	end

	function JsonReader:ReadNull()
		self:TestReservedWord{'n','u','l','l'}
		return nil
	end

	function JsonReader:TestReservedWord(t)
		for i, v in ipairs(t) do
			if self:Next() ~= v then
				 error(string.format(
					"Error reading '%s': %s", 
					table.concat(t), 
					self:All()))
			end
		end
	end

	function JsonReader:ReadNumber()
	        local result = self:Next()
	        local peek = self:Peek()
	        while peek ~= nil and string.find(
			peek, 
			"[%+%-%d%.eE]") do
	            result = result .. self:Next()
	            peek = self:Peek()
		end
		result = tonumber(result)
		if result == nil then
		        error(string.format(
				"Invalid number: '%s'", 
				result))
		else
			return result
		end
	end

	function JsonReader:ReadString()
		local result = ""
		assert(self:Next() == '"')
	        while self:Peek() ~= '"' do
			local ch = self:Next()
			if ch == '\\' then
				ch = self:Next()
				if self.escapes[ch] then
					ch = self.escapes[ch]
				end
			end
	                result = result .. ch
		end
	        assert(self:Next() == '"')
		local fromunicode = function(m)
			return string.char(tonumber(m, 16))
		end
		return string.gsub(
			result, 
			"u%x%x(%x%x)", 
			fromunicode)
	end

	function JsonReader:ReadComment()
	        assert(self:Next() == '/')
	        local second = self:Next()
	        if second == '/' then
	            self:ReadSingleLineComment()
	        elseif second == '*' then
	            self:ReadBlockComment()
	        else
	            error(string.format(
			"Invalid comment: %s", 
			self:All()))
		end
	end

	function JsonReader:ReadBlockComment()
		local done = false
		while not done do
			local ch = self:Next()		
			if ch == '*' and self:Peek() == '/' then
				done = true
	                end
			if not done and 
				ch == '/' and 
				self:Peek() == "*" then
	                    error(string.format(
				"Invalid comment: %s, '/*' illegal.",  
				self:All()))
			end
		end
		self:Next()
	end

	function JsonReader:ReadSingleLineComment()
		local ch = self:Next()
		while ch ~= '\r' and ch ~= '\n' do
			ch = self:Next()
		end
	end

	function JsonReader:ReadArray()
		local result = {}
		assert(self:Next() == '[')
		local done = false
		if self:Peek() == ']' then
			done = true;
		end
		while not done do
			local item = self:Read()
			result[#result+1] = item
			self:SkipWhiteSpace()
			if self:Peek() == ']' then
				done = true
			end
			if not done then
				local ch = self:Next()
				if ch ~= ',' then
					error(string.format(
						"Invalid array: '%s' due to: '%s'", 
						self:All(), ch))
				end
			end
		end
		assert(']' == self:Next())
		return result
	end

	function JsonReader:ReadObject()
		local result = {}
		assert(self:Next() == '{')
		local done = false
		if self:Peek() == '}' then
			done = true
		end
		while not done do
			local key = self:Read()
			if type(key) ~= "string" then
				error(string.format(
					"Invalid non-string object key: %s", 
					key))
			end
			self:SkipWhiteSpace()
			local ch = self:Next()
			if ch ~= ':' then
				error(string.format(
					"Invalid object: '%s' due to: '%s'", 
					self:All(), 
					ch))
			end
			self:SkipWhiteSpace()
			local val = self:Read()
			result[key] = val
			self:SkipWhiteSpace()
			if self:Peek() == '}' then
				done = true
			end
			if not done then
				ch = self:Next()
	                	if ch ~= ',' then
					error(string.format(
						"Invalid array: '%s' near: '%s'", 
						self:All(), 
						ch))
				end
			end
		end
		assert(self:Next() == "}")
		return result
	end

	function JsonReader:SkipWhiteSpace()
		local p = self:Peek()
		while p ~= nil and string.find(p, "[%s/]") do
			if p == '/' then
				self:ReadComment()
			else
				self:Next()
			end
			p = self:Peek()
		end
	end

	function JsonReader:Peek()
		return self.reader:Peek()
	end

	function JsonReader:Next()
		return self.reader:Next()
	end

	function JsonReader:All()
		return self.reader:All()
	end

	RbxUtility.EncodeJSON = function(o)
		local writer = JsonWriter:New()
		writer:Write(o)
		return writer:ToString()
	end

	RbxUtility.DecodeJSON = function(s)
		local reader = JsonReader:New(s)
		return reader:Read()
	end

	RbxUtility.JSON_NULL = Null
end
---- END INSERT: JSON Encoder & Decoder
-------------------------------------------
--]=]

--[[FILE: source/Utility.lua]]
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

--[[FILE: source/Activator.lua]]
local DeactivateAll

local Initialized = {}
local Active = {}
local Initialize = setmetatable({},{
	__newindex = function(t,name,func)
		if Initialized[name] ~= nil then
			rawset(t,name,function(...)
				func(...)
				Initialized[name] = true
			end)
		end
	end;
})
local Activate = setmetatable({},{
	__newindex = function(t,name,func)
		if Initialized[name] ~= nil then
			rawset(t,name,function(...)
				if Initialized[name] then
					DeactivateAll(name)
					func(...)
					Active[name] = true
				end
			end)
		end
	end;
})
local Deactivate = setmetatable({},{
	__newindex = function(t,name,func)
		if Initialized[name] ~= nil then
			rawset(t,name,function(...)
				if Initialized[name] then
					Active[name] = false
					func(...)
				end
			end)
		end
	end;
})

function DeactivateAll(n)
	for name,func in pairs(Deactivate) do
		if name ~= n and Active[name] == true then
			func()
		end
	end
end

local function Activator(name,button)
	if name and button then
		Initialized[name] = false
		Active[name] = false
		if button then
			button.Click:connect(function()
				if Initialized[name] then
					if Active[name] then
						Deactivate[name]()
					else
						Activate[name]()
					end
				else
					Initialize[name]()
					Activate[name]()
				end
			end)
		end
	end
end

--[[FILE: source/Overlay.lua]]
CreateOverlay = class'Overlay'(function(def)
	local adornmentSet = {}
	local overlayPart = Create 'Part' {
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

	function def:Adornment(class,props)
		local properties = {
			Name		= "Overlay"..class;
			Adornee		= overlayPart;
			Archivable	= false;
		}
		for k,v in pairs(props) do
			properties[k] = v
		end
		local adornment = Create(class)(properties)
		adornmentSet[adornment] = true
		return adornment
	end

	function def:SetParent(parent)
		for adornment in pairs(adornmentSet) do
			adornment.Parent = parent
		end
	end

	function def:Clear()
		for adornment in pairs(adornmentSet) do
			adornmentSet[adornment] = nil
			adornment:Destroy()
		end
	end

	function def:SetSize(size)
		local cf = overlayPart.CFrame
		overlayPart.Size = size
		overlayPart.CFrame = cf
	end

	function def:Wrap(object,min_size)
		if type(object) == "table" then
			if #object > 0 then
				local size,pos,parts = GetBoundingBox(object,true)
				if min_size and size.magnitude < min_size.magnitude then
					overlayPart.Size = min_size
				else
					overlayPart.Size = size
				end
				overlayPart.CFrame = CFrame.new(pos)
				self:SetParent(CoreGui)
				return size,pos,parts
			else
				self:SetParent(nil)
			end
		elseif object == nil then
			self:SetParent(nil)
		elseif object:IsA"BasePart" then
			local size,pos = object.Size,object.CFrame
			if min_size and size.magnitude < min_size.magnitude then
				overlayPart.Size = min_size
			else
				overlayPart.Size = size
			end
			overlayPart.CFrame = pos
			self:SetParent(CoreGui)
			return size,pos
		end
	end

	setmetatable(def,{
		__index = overlayPart;
		__newindex = overlayPart;
	})
end)

local Overlay = CreateOverlay()

--[[FILE: source/Selection.lua]]
local Selection = class'Selection'(function(def)
	local Selection = Game:GetService("Selection")
	function def:Add(object)
		local objects = Selection:Get()
		objects[#objects+1] = object
		Selection:Set(objects)
	end

	function def:Remove(object)
		local objects = Selection:Get()
		for i,v in pairs(objects) do
			if v == object then
				table.remove(objects,i)
				break
			end
		end
		Selection:Set(objects)
	end

	function def:Contains(object)
		local objects = Selection:Get()
		for i,v in pairs(objects) do
			if v == object then
				return true
			end
		end
		return false
	end

	function def:GetFiltered(class)
		local out = {}
		for _,object in pairs(Selection:Get()) do
			RecurseFilter(object,class,out)
		end
		return out
	end

	function def:Set(...)
		Selection:Set(...)
	end

	function def:Get()
		return Selection:Get()
	end

	def.Changed = Selection.SelectionChanged
end)()

--[[FILE: source/Mouse.lua]]
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
			Selection:Set{}
			ModelScope = Target
			DisplayInfo("Scope into:",ModelScope:GetFullName())
		end
	elseif ModelScope:IsDescendantOf(Workspace) then
		Selection:Set{ModelScope}
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
				if Selection:Contains(Target) then
					SelectionRemove(Target)
					return true
				else
					Selection:Add(Target)
					return false
				end
			else
				Selection:Set{Target}
			end
		else
			Selection:Set{}
		end
	else
		if Target ~= LastTarget then
			LastTarget = Target
			if Mouse_Ctrl_Active then
				if Target then
					if remove then
						Selection:Remove(Target)
					else
						Selection:Add(Target)
					end
				end
			else
				Selection:Set{Target}
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

	local mouse_down = false
	local select_hold = true
	local click_stamp = 0
	
	Event.Mouse.Down = Mouse.Button1Down:connect(function()
		mouse_down = true
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
		mouse_down = false
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

--[[FILE: source/Tools.lua]]
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

--[[FILE: source/Menus.lua]]
AddMenu("Move",{
	Variables = {
		Increment = 1;
	};
	VariableList = {
		{"Increment","Move Increment"};
	};
	Color = Color3.new(0.854902, 0.521569, 0.254902);
})

AddMenu("Rotate",{
	Variables = {
		Increment = 45;
	};
	VariableList = {
		{"Increment","Rotation Increment"};
	};
	Color = Color3.new(0.643137, 0.741176, 0.278431);
})

AddMenu("Resize",{
	Variables = {
		Increment = 1;
	};
	VariableList = {
		{"Increment","Resize Increment"};
	};
	Color = Color3.new(0.0156863, 0.686275, 0.92549);
})

AddMenu("Clipboard",{
	Color = Color3.new(1,1,1);
})

AddMenu("SelectEdge",{
	Variables = {
		EdgeSnap = 0.5;
		RotIncrement = 45;
	};
	VariableList = {
		{"RotIncrement","Rotation Increment"};
		{"EdgeSnap","Edge Snap"};
	};
	Color = Color3.new(0.960784, 0.803922, 0.188235);
})

--[[FILE: source/Settings.lua]]
local SettingsData = {
	-- settings related to GUI layout
	Layout = {
		-- settings version
		version = 1;
		-- a table of the saved layouts of dockable items
		dockables = {
			DisplayInfoGUI = {				-- the Name to associate with an object in the dock container
				docked_side = 1;			-- the side that the object is docked on (gloo::DockedSide)
				docked_to_screen = true;	-- whether the object is docked to the screen edge
				position = {0,0,0,0};		-- the object's position (UDim2)
			};
			MenuPanelFrame = {
				docked_side = 1;
				docked_to_screen = true;
				position = {0,0,0,24};
			};
		};
		-- data related to menus in the main panel (default data is generated automatically)
		menu = {
			order = {};		-- order in which menus appear on the panel
			expanded = {};	-- whether a menu is expanded or collapsed
			visible = {};	-- whther a menu is visible in the panel (changed in settings)
			variables = {};	-- values for variables in each menu
		};
	};
}

do	-- generate default settings data from menus
	local visible_by_default = {
		Move = true;
		Rotate = true;
		Resize = true;
	}
	local menu = SettingsData.Layout.menu
	for i,menu_name in pairs(MenuList) do
		menu.order[i] = menu_name
		menu.expanded[menu_name] = true
		if visible_by_default[menu_name] then
			menu.visible[menu_name] = true
		else
			menu.visible[menu_name] = false
		end
		local menu_data = Menus[menu_name]
		if menu_data and menu_data.Variables then
			local vars = {}
			menu.variables[menu_name] = vars
			for name,value in pairs(menu_data.Variables) do
				vars[name] = value
			end
		end
	end
end

local Settings = settings()
local DeleteValueNames = {}	-- list of added value names for optional key deletion
local EncodeSettings = RbxUtility.EncodeJSON
local DecodeSettings = RbxUtility.DecodeJSON

local SaveSettingsData

----LOAD AND DECODE
do
	-- combine `b` into `a`; if entries in `a` are nil, they are replaced by the corresponding entry in `b`
	local function combine_table(a,b)
		for k,v in pairs(b) do
			if type(v) == "table" then
				if a[k] == nil or type(a[k]) ~= "table" then
					a[k] = {}
				end
				combine_table(a[k],v)
			else
				a[k] = v
			end
		end
	end
	
	local VALUE_NAME_FORMAT = '%s:%s.%s'	-- Type:Project.Key
	local SettingsValue = {}
	for setting_key,data in pairs(SettingsData) do
		local name = (VALUE_NAME_FORMAT):format(PROJECT_TYPE,PROJECT_NAME,setting_key)
		DeleteValueNames[#DeleteValueNames+1] = name
		local Value = Settings:FindFirstChild(name)
		if not Value then
			Value = Create'StringValue'{
				Name = name;
			}
			Value.Parent = Settings
		end
		if #Value.Value == 0 then
			Value.Value = "[]"
		end
		SettingsValue[setting_key] = Value
		local success,loaded = pcall(DecodeSettings,Value.Value)
		if success then
			combine_table(data,loaded)
		else
			LogWarning("bad JSON syntax in `"..setting_key.."` setting data")
		end
	end

	----ENCODE AND SAVE

	-- Saves data with the key of `key` (if nil, saves all data)
	SaveSettingsData = function(key)
		if key == nil then
			for setting_key,data in pairs(SettingsData) do
				SettingsValue[setting_key].Value = EncodeSettings(data)
			end
		elseif SettingsData[key] and SettingsValue[key] then
			SettingsValue[key].Value = EncodeSettings(SettingsData[key])
		end
	end
end

SaveSettingsData()

--[[FILE: source/Menus/Move.lua]]

--[[FILE: source/Menus/Move/MoveAxis.lua]]
local Tool = AddTool("Move","MoveAxis")

OnToolSelect[Tool] = function(tool,vars)
	local OverlayHandles = Overlay:Adornment('Handles',{
		Color = BrickColor.new("Bright orange");
		Style = "Movement";
	})

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
		local pos = Vector3.FromNormalId(face)*rdis
		for part,cframe in pairs(origin) do
			Anchor(part)
			part.CFrame = cframe + pos
			Anchor(part,true)
		end
		Overlay.CFrame = ocf + pos
		DisplayInfo("Move:",rdis)
	end)
end

OnSelectionChanged[Tool] = function(tool,vars)
	local selection = Selection:GetFiltered("BasePart")
	ToolSelection = selection
	Overlay:Wrap(selection)
end

OnToolDeselect[Tool] = function(tool,vars)
	Event[tool] = nil
	Overlay:Clear()
end

--[[FILE: source/Menus/Move/MoveFirst.lua]]
local Tool = AddTool("Move","MoveFirst")

OnToolSelect[Tool] = function(tool,vars)
	local OverlayHandles = Overlay:Adornment('Handles',{
		Color = BrickColor.new("Bright orange");
	})

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
		local cf = corigin * CFrame.new(Vector3.FromNormalId(face)*rdis)
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
	local selection = Selection:GetFiltered("BasePart")
	ToolSelection = selection
	Overlay:Wrap(selection[1])
end

OnToolDeselect[Tool] = function(tool,vars)
	Event[tool] = nil
	Overlay:Clear()
end

--[[FILE: source/Menus/Move/MoveObject.lua]]
local Tool = AddTool("Move","MoveObject")

OnToolSelect[Tool] = function(tool,vars)
	local OverlayHandles = Overlay:Adornment('Handles',{
		Color = BrickColor.new("Bright orange");
	})

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
		local cf = CFrame.new(Vector3.FromNormalId(face)*rdis)
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
	local selection = Selection:GetFiltered("BasePart")
	ToolSelection = selection
	Overlay:Wrap(selection[1])
end

OnToolDeselect[Tool] = function(tool,vars)
	Event[tool] = nil
	Overlay:Clear()
end

--[[FILE: source/Menus/Rotate.lua]]

--[[FILE: source/Menus/Rotate/RotatePivot.lua]]
local Tool = AddTool("Rotate","RotatePivot")

local min_size = Vector3.new(4,4,4)

OnToolSelect[Tool] = function(tool,vars)
	local OverlayArcHandles = Overlay:Adornment('ArcHandles',{
		Color = BrickColor.new("Br. yellowish green");
	})

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
		local a = Vector3.FromAxis(axis)*math.rad(rdis)
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
	local selection = Selection:GetFiltered("BasePart")
	ToolSelection = selection
	Overlay:Wrap(selection[1],min_size)
end

OnToolDeselect[Tool] = function(tool,vars)
	Event[tool] = nil
	Overlay:Clear()
end

--[[FILE: source/Menus/Rotate/RotateGroup.lua]]
local Tool = AddTool("Rotate","RotateGroup")

local min_size = Vector3.new(4,4,4)

OnToolSelect[Tool] = function(tool,vars)
	local OverlayArcHandles = Overlay:Adornment('ArcHandles',{
		Color = BrickColor.new("Br. yellowish green");
	})

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
		local a = Vector3.FromAxis(axis)*math.rad(rdis)
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
	local selection = Selection:GetFiltered("BasePart")
	ToolSelection = selection
	Overlay:Wrap(ToolSelection,min_size)
end

OnToolDeselect[Tool] = function(tool,vars)
	Event[tool] = nil
	Overlay:Clear()
end

--[[FILE: source/Menus/Rotate/RotateObject.lua]]
local Tool = AddTool("Rotate","RotateObject")

local min_size = Vector3.new(4,4,4)

OnToolSelect[Tool] = function(tool,vars)
	local OverlayArcHandles = Overlay:Adornment('ArcHandles',{
		Color = BrickColor.new("Br. yellowish green");
	})

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
		local a = Vector3.FromAxis(axis)*math.rad(rdis)
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
	local selection = Selection:GetFiltered("BasePart")
	ToolSelection = selection
	Overlay:Wrap(selection[1],min_size)
end

OnToolDeselect[Tool] = function(tool,vars)
	Event[tool] = nil
	Overlay:Clear()
end

--[[FILE: source/Menus/Resize.lua]]
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

--[[FILE: source/Menus/Resize/ResizeObject.lua]]
local Tool = AddTool("Resize","ResizeObject")

OnToolSelect[Tool] = function(tool,vars)
	local OverlayHandles = Overlay:Adornment('Handles',{
		Color = BrickColor.new("Cyan");
	})

	local origin = {}
	local first
	local face_mult,face_size,face_vec
	local cinc
	local inc
	Event[tool].Down = OverlayHandles.MouseButton1Down:connect(function(face)
		face_mult,face_size,face_vec = FACE_MULTIPLIER[face],FACE_COMPONENT[face],Vector3.FromNormalId(face)
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
		Overlay.Size = first.Size
		Overlay.CFrame = first.CFrame
	end)
end

OnSelectionChanged[Tool] = function(tool,vars)
	local selection = Selection:GetFiltered("BasePart")
	ToolSelection = selection
	Overlay:Wrap(selection[1])
end

OnToolDeselect[Tool] = function(tool,vars)
	Event[tool] = nil
	Overlay:Clear()
end

--[[FILE: source/Menus/Resize/ResizeCenter.lua]]
local Tool = AddTool("Resize","ResizeCenter")

OnToolSelect[Tool] = function(tool,vars)
	local OverlayHandles = Overlay:Adornment('Handles',{
		Color = BrickColor.new("Cyan");
	})

	local origin = {}
	local first
	local face_mult,face_size,face_vec
	local cinc
	local inc
	Event[tool].Down = OverlayHandles.MouseButton1Down:connect(function(face)
		face_mult,face_size,face_vec = FACE_MULTIPLIER[face],FACE_COMPONENT[face],Vector3.FromNormalId(face)
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
		Overlay.Size = first.Size
		Overlay.CFrame = first.CFrame
	end)
end

OnSelectionChanged[Tool] = function(tool,vars)
	local selection = Selection:GetFiltered("BasePart")
	ToolSelection = selection
	Overlay:Wrap(selection[1])
end

OnToolDeselect[Tool] = function(tool,vars)
	Event[tool] = nil
	Overlay:Clear()
end

--[[FILE: source/Menus/Clipboard.lua]]
local ClipboardContents = {}
local ClipboardContentParent = {}

--[[FILE: source/Menus/Clipboard/Cut.lua]]
local Tool = AddTool("Clipboard","Cut")

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

--[[FILE: source/Menus/Clipboard/Copy.lua]]
local Tool = AddTool("Clipboard","Copy")

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

--[[FILE: source/Menus/Clipboard/Paste.lua]]
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

--[[FILE: source/Menus/Clipboard/Duplicate.lua]]
local Tool = AddTool("Clipboard","Duplicate")

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

--[[FILE: source/Menus/SelectEdge.lua]]
-- normalize a number; return 0 if 0
local function NumNormal(n)
	return n == 0 and 0 or n/math.abs(n)
end

-- return the nearest edge of a part from a point on the part's surface
local function GetNearestEdge(part,hit,inc)
	local p = part.CFrame:pointToObjectSpace(hit)
	local s = part.Size/2
	local ax,ay,az = math.abs(p.x/s.x),math.abs(p.y/s.y),math.abs(p.z/s.z)
	return Vector3.new(
		NumNormal(p.x)*((ax > ay or ax > az) and s.x or Snap(math.abs(p.x),inc)),
		NumNormal(p.y)*((ay > ax or ay > az) and s.y or Snap(math.abs(p.y),inc)),
		NumNormal(p.z)*((az > ax or az > ay) and s.z or Snap(math.abs(p.z),inc))
	)
end

--[[FILE: source/Menus/SelectEdge/SelectEdge.lua]]
local Tool = AddTool("SelectEdge","SelectEdge")

local function FilterTarget(target)
	if target then
		if not target.Locked then
			return target
		end
	end
	return nil
end

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
	
	local OverlayArcHandles = Overlay:Adornment('ArcHandles',{
		Color = BrickColor.new("Bright yellow");
	})
	local OverlaySelectionBox = Overlay:Adornment('SelectionBox',{
		Color = BrickColor.new("Bright yellow");
	})
	
	local function select_edge()
		OverlayArcHandles.Visible = false
		OverlaySelectionBox.Visible = true
		Overlay.Size = Vector3.new(1,1,1)
		local Target = FilterTarget(Mouse.Target)
		if Target then
			Overlay:SetParent(CoreGui)
			local JointCenter = CFrame.new(GetNearestEdge(Target,Mouse.Hit.p,vars.EdgeSnap))
			Overlay.CFrame = Target.CFrame * JointCenter
			SelectEdgeVisible = true
		else
			SelectEdgeVisible = false
			OverlayArcHandles.Visible = false
			Overlay:SetParent(nil)
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
		local a = Vector3.FromAxis(axis)*math.rad(rdis)
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
	ToolSelection = Selection:GetFiltered("BasePart")
end

OnToolDeselect[Tool] = function(tool,vars)
	SelectEdgeVisible = false
	Event.SelectEdge = nil
	Overlay:Clear()
end

--[[FILE: source/GUI.lua]]
Activator('GUI',ActivateGUIButton)

local Screen
local MenuPanelClass
local menuNameFromFrame = {}
local menuFrameFromName = {}
local menuNameFromTool = {}

local ExpandPanel
local CollapsePanel

local DockClass
local CancelMenuDrag

local function toUDim2(t)
	return UDim2.new(unpack(t))
end

local function fromUDim2(u)
	return {u.X.Scale,u.X.Offset,u.Y.Scale,u.Y.Offset}
end

function Initialize.GUI()
	if not _G.gloo then
		error(PROJECT_NAME.." needs the gloo library to load the GUI.",0)
	end
	local gloo = _G.gloo
	local DockedSide = gloo.DockedSide

	local Layout = SettingsData.Layout

	local draggingMenu = false
	local hoverEnabled = true
	
	local GlobalStylist = gloo.Stylist{
		Font = "ArialBold";
		FontSize = "Size14";
		TextColor3 = Color3.new(1,1,1);
		BackgroundTransparency = 0.5;
		BackgroundColor3 = Color3.new(0,0,0);
		BorderColor3 = Color3.new(1,1,1);
	}

	local MenuStylist = gloo.Stylist{}
	GlobalStylist.AddStylist(MenuStylist)

	local ButtonStylist = gloo.Stylist{
		Size = UDim2.new(0,100,0,20);
		Style = "RobloxButton";
		Selected = false;
	}
	GlobalStylist.AddStylist(ButtonStylist)

	local SelectedButtonStylist = gloo.Stylist{
		Selected = true;
	}
	ButtonStylist.AddStylist(SelectedButtonStylist)

	local MenuNodeStylist = gloo.Stylist{
		BackgroundTransparency = 0.5;
		BorderSizePixel = 0;
		Size = UDim2.new(0,100,0,8);
	}

	local HoverNameStylist = gloo.Stylist{
		AutoButtonColor = false;
		BackgroundTransparency = 1;
		TextStrokeColor3 = Color3.new(0,0,0);
		TextStrokeTransparency = 0;
	}
	GlobalStylist.AddStylist(HoverNameStylist)

	Screen = Instance.new("ScreenGui")
	Screen.Name = PROJECT_NAME.."GUI"
	Screen.Parent = CoreGui
	-- fix size delay
	while Screen.AbsoluteSize.magnitude == 0 do
		Screen.Changed:wait()
	end

	local _,DockFrame = gloo.DockContainer(Instance.new("Frame"))
	DockClass = _
	DockFrame.Name = "DockContainer"
	DockFrame.Transparency = 1
	DockFrame.Size = UDim2.new(1,0,1,0)
	DockFrame.Parent = Screen

	DisplayInfoGUI = Create'TextButton'{
		Name = "DisplayInfoGUI";
		Text = "";
	}
	DisplayInfoGUI.Parent = DockFrame;
	HoverNameStylist.AddObject(DisplayInfoGUI)
	local InfoClass = gloo.AutoSizeLabel(DisplayInfoGUI)
	InfoClass.LockAxis(nil,24)
	InfoClass.SetPadding(4)
	local info_layout = Layout.dockables.DisplayInfoGUI

	local _,MenuPanelFrame = gloo.StackingFrame(Instance.new("ImageButton"))
	MenuPanelClass = _
	MenuPanelClass.SetPadding(4,8)
	Modify(MenuPanelFrame){
		AutoButtonColor = false;
		Name = "MenuPanelFrame";
		BorderSizePixel = 0;
		BackgroundColor3 = Color3.new(0,0,0);
		BackgroundTransparency = 0.3;
	}
	MenuPanelFrame.Parent = DockFrame
	local panel_layout = Layout.dockables.MenuPanelFrame

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

	local PanelHoverFrame = Create'Frame'{
		Name = "PanelHoverFrame";
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
		if _VERSION == "Lua 5.2" then
			local f = load('return '..s,nil,nil,env)
			if f then
				local s,o = pcall(f)
				if s then return o end
			end
		else
			local f = loadstring("return "..str)
			if f then
				setfenv(f,env)
				local s,o = pcall(f)
				if s then return o end
			end
		end
		return nil
	end
--[[
	local function GetPosIndex(list,pos,size)
		list = MenuPanelClass.List
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
--]]
	local function GetPosIndex(list,pos)
		if #list > 1 then
			local yMax = pos.y
			local index = #list

			for i = 1,#list do
				if list[i] and list[i].y > yMax then
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
		if draggingMenu then return end
		draggingMenu = true

		local orderSet = {}
		do
			local list = MenuPanelClass.List
			for i = 1,#list do
				local menu_frame = list[i]
				if menu_frame.Visible then
					orderSet[i] = menu_frame.AbsolutePosition + menu_frame.AbsoluteSize
				else
					orderSet[i] = false
				end
			end
		end

		local mouse_pos = offset + MenuFrame.AbsolutePosition
		Placeholder.Size = MenuFrame.Size
		local index = MenuPanelClass.GetIndex(MenuFrame)
		MenuPanelClass.RemoveObject(MenuFrame)
		MenuPanelClass.AddObject(Placeholder,index)
		MenuFrame.Parent = Screen

		local drag_con
		local up_con

		local do_toggle = true
		local zIndex = MenuFrame.ZIndex
		local function mouse_up()
			CancelMenuDrag = nil
			MouseDrag.Parent = nil
			drag_con:disconnect(); drag_con = nil
			up_con:disconnect(); drag = nil
			gloo.SetZIndex(MenuFrame,zIndex)
			MenuPanelClass.RemoveObject(Placeholder)
			MenuPanelClass.AddObject(MenuFrame,index)
			draggingMenu = false
			if do_toggle then
				fToggle()
			else
				-- update save state
				local list = MenuPanelClass.List
				local menu_order = Layout.menu.order
				for i = 1,#menu_order do
					menu_order[i] = nil
				end
				for i = 1,#list do
					local name = menuNameFromFrame[list[i]]
					menu_order[i] = name
				end
				SaveSettingsData('Layout')
			end
		end
		CancelMenuDrag = mouse_up

		local function mouse_drag(x,y)
			local mouse_pos = Vector2.new(x,y)
			local pos = mouse_pos - offset
			local x,y = pos.x,pos.y
			local cPos = MenuPanelFrame.AbsolutePosition + Vector2.new(8,8)
			local max = cPos + MenuPanelFrame.AbsoluteSize - Vector2.new(16,16)

			if y > max.y then
				y = max.y
			elseif y < cPos.y then
				y = cPos.y
			end

			MenuFrame.Position = UDim2.new(0,cPos.x,0,y)
			index = GetPosIndex(orderSet,mouse_pos) or index
		--	index = GetPosIndex(orderSet,MenuFrame.AbsolutePosition + MenuFrame.AbsoluteSize/2,MenuFrame.AbsoluteSize/2) or index
			MenuPanelClass.MoveObject(Placeholder,index)
		end

		drag_con = MouseDrag.MouseMoved:connect(function(...)
			do_toggle = false
			mouse_drag(...)
		end)
		up_con = MouseDrag.MouseButton1Up:connect(mouse_up)
		gloo.SetZIndex(MenuFrame,zIndex + 1)
		MouseDrag.Parent = Screen
		mouse_drag(mouse_pos.x,mouse_pos.y)
	end

---- GENERATE MENUS
	local menu_visible = Layout.menu.visible
	local menu_expanded = Layout.menu.expanded
	for i,menu_name in pairs(MenuList) do
		local menu = Menus[menu_name]
		local MenuClass,MenuFrame = gloo.StackingFrame()
		MenuClass.SetPadding()
		MenuStylist.AddObject(MenuFrame)
		menuNameFromFrame[MenuFrame] = menu_name
		menuFrameFromName[menu_name] = MenuFrame
		MenuPanelClass.AddObject(MenuFrame)

		MenuFrame.Name = menu_name.."Menu"
		MenuFrame.Visible = menu_visible[menu_name]
		local expanded = menu_expanded[menu_name]

		do	-- MENU HANDLE
			local Node = Instance.new("ImageButton")
			Node.Name = "MenuHandle"
			if menu.Color then
				Node.BackgroundColor3 = menu.Color
			else
				Node.BackgroundColor3 = Color3.new(1,1,1)
			end
			MenuNodeStylist.AddObject(Node)
			MenuClass.AddObject(Node)
			local label = Instance.new('TextLabel')
			local labelClass = gloo.AutoSizeLabel(label)
			labelClass.LockAxis(nil,8)
			labelClass.SetPadding(4)
			HoverNameStylist.AddObject(label)
			label.Visible = false
			label.Text = menu_name .. " Menu"
			label.Parent = Node
			Node.MouseEnter:connect(function()
				if not draggingMenu then
					if Node.AbsolutePosition.x + Node.AbsoluteSize.x + label.AbsoluteSize.x > Screen.AbsoluteSize.x then
						label.Position = UDim2.new(0,-label.AbsoluteSize.x,0,0)
					else
						label.Position = UDim2.new(1,0,0,0)
					end
					label.Visible = true
				end
			end)
			Node.MouseLeave:connect(function() label.Visible = false end)

			local function toggle_menu()
				if menuNameFromTool[SelectedTool] == menu_name then
					DeselectTool(SelectedTool)
				end
				menu_expanded[menu_name] = not menu_expanded[menu_name]
				for i,button in pairs(MenuClass.List) do
					if button ~= Node then
						button.Visible = menu_expanded[menu_name]
					end
				end
				SaveSettingsData('Layout')
			end

			Node.MouseButton1Down:connect(function(x,y)
				label.Visible = false
				InvokeMenuDrag(MenuFrame,Vector2.new(x,y) - MenuFrame.AbsolutePosition,toggle_menu)
			end)
		end

		---- MENU VARIABLES
		if menu.Variables and menu.VariableList then
			local vars = menu.Variables
			local menu_vars = Layout.menu.variables[menu_name]
			for i,var in pairs(menu.VariableList) do
				local name = var[1]
				local field
				vars[name] = menu_vars[name]
				if type(vars[name]) == 'number' then
					field = Instance.new("TextBox")
					ButtonStylist.AddObject(field)
					MenuClass.AddObject(field)
					field.Text = menu_vars[name] or vars[name]
					field.FocusLost:connect(function(enter)
						local num = tonumber(eval(field.Text,vars[name]))
						if num then
							vars[name] = num
							field.Text = num
							menu_vars[name] = num
							SaveSettingsData('Layout')
						else
							field.Text = vars[name]
						end
					end)
				end
				if field then
					field.Name = name.."Field"
					field.Visible = expanded
					local label = Instance.new('TextLabel',field)
					local labelClass = gloo.AutoSizeLabel(label)
					labelClass.LockAxis(nil,20)
					labelClass.SetPadding(4)
					HoverNameStylist.AddObject(label)
					label.Visible = false
					label.Text = var[2] or var[1]
					field.MouseEnter:connect(function()
						if not draggingMenu then
							if field.AbsolutePosition.x + field.AbsoluteSize.x + label.AbsoluteSize.x > Screen.AbsoluteSize.x then
								label.Position = UDim2.new(0,-label.AbsoluteSize.x,0,0)
							else
								label.Position = UDim2.new(1,0,0,0)
							end
							label.Visible = true
						end
					end)
					field.MouseLeave:connect(function() label.Visible = false end)
				end
			end
		end

		---- MENU TOOLS
		for i,tool in pairs(menu.Tools) do
			local button = Instance.new("TextButton")
			ButtonStylist.AddObject(button)
			button.Name = tool .. "Button"
			button.Text = tool
			button.Visible = expanded
			MenuClass.AddObject(button)
			menuNameFromTool[tool] = menu_name
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

	do	-- order menus from save
		local menu_order = Layout.menu.order
		local list = MenuPanelClass.List
		local new = {}
		for menuFrame,menu_name in pairs(menuNameFromFrame) do
			local index = GetIndex(menu_order,menu_name)
			if index then
				list[index] = menuFrame
			else
				new[#new+1] = menuFrame
			end
		end
		for i = 1,#new do
			table.insert(list,new[i])
		end
		MenuPanelClass.Update()
	end

	local function tweenPanel(position,dir,notween)
		if notween == true then
			MenuPanelFrame.Position = position
		else
			MenuPanelFrame:TweenPosition(position,dir,"Quad",0.25,true)
		end
	end

	function ExpandPanel(notween)
		if hoverEnabled then
			if panel_layout.docked_to_screen then
				local position = toUDim2(panel_layout.position)
				local side = panel_layout.docked_side
				if side == DockedSide.Bottom then
					local size = MenuPanelFrame.Size
					position = UDim2.new(position.X.Scale,position.X.Offset,1-size.Y.Scale,-size.Y.Offset)
					tweenPanel(position,"Out",notween)
				elseif side == DockedSide.Top then
					tweenPanel(UDim2.new(position.X.Scale,position.X.Offset,0,0),"Out",notween)
				elseif side == DockedSide.Right then
					local size = MenuPanelFrame.Size
					position = UDim2.new(1-size.X.Scale,-size.X.Offset,position.Y.Scale,position.Y.Offset)
					tweenPanel(position,"Out",notween)
				elseif side == DockedSide.Left then
					tweenPanel(UDim2.new(0,0,position.Y.Scale,position.Y.Offset),"Out",notween)
				end
			end
		end
	end

	function CollapsePanel(notween)
		if hoverEnabled and not SelectedTool and not draggingMenu then
			if panel_layout.docked_to_screen then
				local position = toUDim2(panel_layout.position)
				local side = panel_layout.docked_side
				if side == DockedSide.Bottom then
					tweenPanel(UDim2.new(position.X.Scale,position.X.Offset,1,0),"In",notween)
				elseif side == DockedSide.Top then
					tweenPanel(UDim2.new(position.X.Scale,position.X.Offset,0,-MenuPanelFrame.AbsoluteSize.y),"In",notween)
				elseif side == DockedSide.Right then
					tweenPanel(UDim2.new(1,0,position.Y.Scale,position.Y.Offset),"In",notween)
				elseif side == DockedSide.Left then
					tweenPanel(UDim2.new(0,-MenuPanelFrame.AbsoluteSize.x,position.Y.Scale,position.Y.Offset),"In",notween)
				end
			end
		end
	end

	PanelHoverFrame.MouseEnter:connect(ExpandPanel)
	PanelHoverFrame.MouseLeave:connect(CollapsePanel)
--[[
	local function computeAlignedPos(object,side)
		if side == DockedSide.Outer then
			local size = object.Size
			local pos = object.Position
			if side == DockedSide.YAxis then
				object.Position = UDim2.new(pos.X.Scale,pos.X.Offset,1-size.Y.Scale,-size.Y.Offset)
			else
				object.Position = UDim2.new(1-size.X.Scale,-size.X.Offset,pos.Y.Scale,pos.Y.Offset)
			end
		end
	end
--]]

	-- if object is docked to right or bottom of screen, right/bottom align it so it sticks
	local function getRightAlign(layout,s,p)
		if layout.docked_to_screen then
			if layout.docked_side == DockedSide.Right then
				return UDim2.new(1-s.X.Scale,-s.X.Offset,p.Y.Scale,p.Y.Offset)
			elseif layout.docked_side == DockedSide.Bottom then
				return UDim2.new(p.X.Scale,p.X.Offset,1-s.Y.Scale,-s.Y.Offset)
			end
		end
	end

	local function rightAlignDockable(object,layout,size,update)
		if size then object.Size = size end
		local s = object.Size
		local p = toUDim2(layout.position)
		local new = getRightAlign(layout,s,p)
		if new then
			object.Position = new
		elseif update then
			object.Position = p
		end
	end

	local layout_dockables = Layout.dockables
	DockClass.DragBeginCallback = function(dragged)
		hoverEnabled = false	-- disable PanelHoverFrame when dragging
	end

	DockClass.DragCallback = function(dragged)
		local layout = layout_dockables[dragged.Name]
		if layout then
			-- before the drag starts, reset dock values
			layout.docked_side = DockedSide.None
			layout.docked_to_screen = false
		end
	end

	DockClass.DockCallback = function(dragged,docked,side)
		if docked == PanelHoverFrame then	-- if an object is trying to dock with the PanelHoverFrame
			return false					-- cancel the dock
		end
	end

	DockClass.ObjectDocked:connect(function(dragged,docked,side)
		local layout = layout_dockables[dragged.Name]
		if layout then
			layout.docked_side = side	-- when an object docks, save the side it docked on
			if docked == DockFrame then
				layout.docked_to_screen = true
			end
		end
	end)

	DockClass.DragStopped:connect(function(dragged)
		local layout = layout_dockables[dragged.Name]
		if layout then
			layout.position = fromUDim2(dragged.Position)	-- whe the drag stops, save the object's position
			rightAlignDockable(dragged,layout)
		end
		if dragged == MenuPanelFrame then	-- if the dragged was the panel frame
			rightAlignDockable(PanelHoverFrame,layout,MenuPanelFrame.Size,true)	-- update the PanelHoverFrame
		end
		hoverEnabled = true	-- enable PanelHoverFrame
		SaveSettingsData('Layout')
	end)

	-- update objects to reflect saved layout
	for name,layout in pairs(Layout.dockables) do
		local frame = DockFrame:FindFirstChild(name)
		if frame then
			frame.Position = toUDim2(layout.position)
			frame.Changed:connect(function(p)
				if p == "AbsoluteSize" then
					rightAlignDockable(frame,layout)
				end
			end)
			rightAlignDockable(frame,layout)
		end
	end
	MenuPanelFrame.Changed:connect(function(p)
		if p == "AbsoluteSize" then
			if hoverEnabled then
				rightAlignDockable(PanelHoverFrame,panel_layout,MenuPanelFrame.Size,true)
			end
		end
	end)
	rightAlignDockable(PanelHoverFrame,panel_layout,MenuPanelFrame.Size,true)

---- Roblox HUD docking
	local RobloxGui = CoreGui:FindFirstChild("RobloxGui")
	if RobloxGui then
		local findObjects = {
			MouseLockLabel = function(object)
				return object.Visible
			end;
			SettingsButton = true;
			CameraTiltDown = true;
			CameraTiltUp = true;
			CameraZoomIn = true;
			CameraZoomOut = true;
			BackpackButton = true;
		}

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
			frame.Parent = DockFrame
		end

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
	DisplayInfo("Loaded GUI")
	Screen.Parent = nil
end

function Activate.GUI()
	ExpandPanel(true)
	Screen.Parent = CoreGui
end

function Deactivate.GUI()
	DeselectTool(SelectedTool)
	DockClass.StopDrag()
	if CancelMenuDrag then CancelMenuDrag() end
	Screen.Parent = nil
	CollapsePanel(true)
end

--[[FILE: source/SettingsPanel.lua]]
----SETTINGS PANEL
Activator('Settings',ActivateSettingsButton)

local SettingsScreen

function Initialize.Settings()
	if not _G.gloo then
		error(PROJECT_NAME.." needs the gloo library to load the GUI.",0)
	end
	local gloo = _G.gloo
	if not Initialized.GUI then
		Initialize.GUI()
	end

	local GlobalStylist = gloo.Stylist({
		Font = "ArialBold";
		FontSize = "Size14";
		TextColor3 = Color3.new(1,1,1);
	})

	local TextAlias = {
		TextColor3 = 'BackgroundColor3';
		TextTransparency = 'BackgroundTransparency';
	}

	local PanelStylist = gloo.Stylist{
		BackgroundTransparency = 0.3;
		BorderSizePixel = 0;
		BackgroundColor3 = Color3.new(0,0,0);
	}
	GlobalStylist.AddStylist(PanelStylist)

	local TitleStylist = gloo.Stylist{
		FontSize = "Size18";
		TextXAlignment = "Left";
		BackgroundTransparency = 1;
	}
	GlobalStylist.AddStylist(TitleStylist)

	local Screen = Instance.new('ScreenGui')
	SettingsScreen = Screen
	Screen.Name = PROJECT_NAME.."SettingsGUI";
	Screen.Parent = CoreGui
	-- fix size delay
	while Screen.AbsoluteSize.magnitude == 0 do
		Screen.Changed:wait()
	end

	local Shield = Create'Frame'{
		Active = true;
		Size = UDim2.new(1.5,0,1.5,0);
		Position = UDim2.new(-0.25,0,-0.25,0);
		BackgroundTransparency = 0.5;
		BorderSizePixel = 0;
		BackgroundColor3 = Color3.new(0,0,0);
		Parent = Screen;
	}

	local SettingsPanel = Create'Frame'{
		Size = UDim2.new(0.5,0,0.5,0);
		Position = UDim2.new(0.25,0,0.25,0);
		Parent = Screen;
	}
	PanelStylist.AddObject(SettingsPanel)

	local SettingsFrame = Create'Frame'{
		Size = UDim2.new(1,-16,1,-16);
		Position = UDim2.new(0,8,0,8);
		BackgroundTransparency = 1;
		Parent = SettingsPanel;
		Create'TextLabel'{
			Size = UDim2.new(1,0,0,18);
			Text = PROJECT_NAME.." Settings";
			Create'Frame'{
				BorderSizePixel = 0;
				Size = UDim2.new(1,0,0,1);
				Position = UDim2.new(0,0,1,0);
			};
		};
		Create'ImageButton'{
			Size = UDim2.new(0, 12, 0, 12);
			BackgroundTransparency = 0.5;
			BorderColor3 = Color3.new(1, 1, 1);
			Name = "CloseButton";
			Position = UDim2.new(1, -12, 0, -1);
			BackgroundColor3 = Color3.new(0, 0, 0);
		};
	}
	local CloseButton = SettingsFrame.CloseButton
	do
		local graphic = gloo.Graphic("cross",Vector2.new(12,12))
		graphic.GUI.Parent = CloseButton
		GlobalStylist.AddStylist(graphic.Stylist,{TextColor3 = "BackgroundColor3", TextTransparency = "BackgroundTransparency"})
	end
	CloseButton.MouseButton1Click:connect(function()
		Deactivate['Settings']()
	end)


--	gloo.AutoSizeLabel(SettingsFrame.TextLabel)
	TitleStylist.AddObject(SettingsFrame.TextLabel)
	GlobalStylist.AddObject(SettingsFrame.TextLabel.Frame,TextAlias)

	local TabContainerClass,TabContainerFrame = gloo.TabContainer(nil,22,18)
	do
		local t = {
			FontSize = gloo.NULL;
			Font = gloo.NULL;
			TextColor3 = gloo.NULL;
		--	BackgroundTransparency = 0;
		}
		TabContainerClass.TabStylist.SetProperties(t)
		TabContainerClass.SelectedTabStylist.SetProperties(t)
	end
	GlobalStylist.AddStylist(TabContainerClass.TabStylist)
	GlobalStylist.AddStylist(TabContainerClass.SelectedTabStylist)

	Modify(TabContainerFrame){
		Size = UDim2.new(1,0,1,-22);
		Position = UDim2.new(0,0,0,22);
		Parent = SettingsFrame;
	}

---- MENUS TAB
	local Options = SettingsData.Options
	-- checklist of menus to display in the panel
	do
		local menu_order = SettingsData.Layout.menu.order
		local menu_visible = SettingsData.Layout.menu.visible
		local menuListData = {}
		for i,menu_name in pairs(MenuList) do
			local visible = menu_visible[menu_name]
			menuListData[#menuListData+1] = {visible,menu_name}
		end

		local function checkCallback(data,class)
			local checked = not data[1]
			local menu_name = data[2]
			if menuNameFromTool[SelectedTool] == menu_name then
				DeselectTool(SelectedTool)
			end
			if checked then
				local frame = menuFrameFromName[menu_name]
				frame.Visible = true
				menu_visible[menu_name] = true
				MenuPanelClass.MoveObject(frame)
			else
				local index = GetIndex(MenuList,data[2])
				if index then
					menuFrameFromName[menu_name].Visible = false
					menu_visible[menu_name] = false
				end
			end
			SaveSettingsData('Layout')
			return true
		end

		local MenuListClass,MenuListFrame = gloo.DetailedList(menuListData,{
			{type='check-box', name="", width=UDim.new(0,17), checked={'check-mark',Vector2.new(17,17)}, callback=checkCallback };
			{type='text', name="Menus", width=UDim.new(1,-17), style={TextXAlignment="Left"} };
		})
		MenuListFrame.Size = UDim2.new(1,-8,1,-8)
		MenuListFrame.Position = UDim2.new(0,4,0,4)
		MenuListFrame.Name = "Menus"

		MenuListClass.Stylist.Global.ClearProperties()
		GlobalStylist.AddStylist(MenuListClass.Stylist.Global)

		TabContainerClass.AddTab(MenuListFrame)
	end
---- OPTIONS TAB
	-- list of various options (key/value DetailedList wrapper)
---- STYLE TAB
	-- more tabs, listing various stylists (key/value DetailedList wrapper)
---- DATA TAB
	-- message about saved data and a button to delete saved data
	do
		local DataFrame = Create'Frame'{
			Size = UDim2.new(1, 0, 1, 0);
			Name = "Data";
			BackgroundTransparency = 1;
			Create'TextLabel'{
				Text = "This plugin has save data that is stored with your Roblox settings. Clicking the button below will remove all of this plugin's save data.";
				Size = UDim2.new(1, -8, 0, 56);
				Position = UDim2.new(0, 4, 0, 4);
				BackgroundTransparency = 1;
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Top;
				TextWrap = true;
				Create'TextButton'{
					Name = "DeleteButton";
					Text = "Delete Plugin Data";
					BackgroundTransparency = 1;
					Position = UDim2.new(0.5, -65, 1, 4);
					Size = UDim2.new(0, 130, 0, 24);
					Style = Enum.ButtonStyle.RobloxButton;
				}
			}
		}
		local DeleteButton = DataFrame.TextLabel.DeleteButton
		GlobalStylist.AddObjects{
			DataFrame;
			DataFrame.TextLabel;
			DeleteButton;
		}
		local con;con = DeleteButton.MouseButton1Click:connect(function()
			if _G.gloo and _G.gloo.dialog then
				if not _G.gloo.dialog.Confirm(Screen,"Are you sure you want to delete this plugin's save data?") then
					return
				end
			end
			if DeleteValueNames then
				con:disconnect()
				local Settings = settings()
				for i,name in pairs(DeleteValueNames) do
					local data = Settings:FindFirstChild(name)
					if data then data:Destroy() end
				end
				local Settings = UserSettings()
				for i,name in pairs(DeleteValueNames) do
					local data = Settings:FindFirstChild(name)
					if data then data:Destroy() end
				end
				DeleteButton.Style = Enum.ButtonStyle.Custom
				DeleteButton.Text = "Plugin data has been deleted"
			end
		end)

		TabContainerClass.AddTab(DataFrame)
	end
end

function Activate.Settings()
	SettingsScreen.Parent = CoreGui
end

function Deactivate.Settings()
	SettingsScreen.Parent = nil
end

--[[FILE: source/Footer.lua]]
print(("Loaded %s plugin (v%s)"):format(PROJECT_NAME, PROJECT_VERSION))

