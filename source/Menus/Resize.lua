local Menu = "Resize"
table.insert(MenuList,Menu)
Menus[Menu] = {
	Tools = {};
	Variables = {
		Increment = 1;
	};
	VariableList = {
		{"Increment","Resize Increment"};
	};
	Color = Color3.new(0.0156863, 0.686275, 0.92549);
}

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
