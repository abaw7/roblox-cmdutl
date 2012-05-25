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
