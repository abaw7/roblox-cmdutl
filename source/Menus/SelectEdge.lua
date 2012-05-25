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
