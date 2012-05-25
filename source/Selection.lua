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
