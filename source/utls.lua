local function b(n)
	return tonumber(n,2)
end

-- rounds a number half up
local function half(number)
	return math.floor(number + 0.5)
end

-- return the normal of the surface of a part that a point is on
local function GetSurfaceNormal(part,hit)
	local p = part.CFrame:pointToObjectSpace(hit)
	local s = part.Size/2
	local ax,ay,az = math.abs(p.x/s.x),math.abs(p.y/s.y),math.abs(p.z/s.z)
	return Vector3.new(
		NumNormal(p.x)*((ax > ay and ax > az) and 1 or 0),
		NumNormal(p.y)*((ay > ax and ay > az) and 1 or 0),
		NumNormal(p.z)*((az > ax and az > ay) and 1 or 0)
	)
end

-- returns whether a value is a positive integer
local function IsPosInt(n)
	return type(n) == "number" and n > 0 and math.floor(n) == n
end

-- returns whether a table is a valid array
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

-- fixes an unsequenced array to be sequenced
local function FixArraySeq(array)
	local l,c = 0,0
	for i in pairs(array) do
		c = c + 1
		if i > l then l = i end
	end
	local shift = 0
	for i=1,l do
		if array[i] == nil then
			shift = shift + 1
		else
			array[i - shift] = array[i]
			if i > c then
				array[i] = nil
			end
		end
	end
end

-- returns whether a string is a valid identifer
local function IsIdent(name)
	return name:match("^[%a_][%w_]-$") == name
end

local ContentProvider = Game:GetService("ContentProvider")
local BASEURL = ContentProvider.BaseUrl
local function Preload(content)
	ContentProvider:Preload(content)
end

-- checks if the value is a Content string
local IsContentString
do
	local valid_protocols = {
		["http"] = true;
		["https"] = true;
		["rbxhttp"] = true;
		["rbxasset"] = true;
		["rbxassetid"] = true;
	}

	IsContentString = function(link)
		if type(link) == "string" then
			local protocol = link:match("^(.+)://(.+)$")
			return valid_protocols[protocol] or false
		else
			return false
		end
	end
end

-- universal function for transforming groups of parts
-- `objects` is a table of objects
-- `center` is a CFrame used a the transformation point
-- `new` is the CFrame of `center` after the transformation (where `center` should be)
-- `recurse` indicates whterh to recurse through each object's children
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

-- pad a string with zeros
-- ALT FOR ZEROS: use string.format with "%0[size]s" tag, where [size] is the `size` argument
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
