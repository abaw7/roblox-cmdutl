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
