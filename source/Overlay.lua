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
