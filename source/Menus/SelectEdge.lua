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
