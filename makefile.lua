-- CmdUtl Makefile --

-- Options
--option('write_path',"--[[FILE: %s]]")
--option('show_messages',0)

-- Roblox Plugin folder:
	-- Windows 5 (XP)
		rbx_plugins = [[%USERPROFILE%/Local Settings/Application Data/Roblox/plugins]]
	-- Windows 6 (Vista/7)
		--rbx_plugins = [[%USERPROFILE%/AppData/Local/Roblox/plugins]]

-- a list of files to output to
local output_files = {
	-- to main build
	[[build/CmdUtl/CmdUtl.lua]];
	-- directly to roblox plugin
	--rbx_plugins/[[CmdUtl/CmdUtl.lua]];
}

read [[source/Header.lua]]		{'main'}
read [[source/Utility.lua]]		{'main'}
read [[source/Settings.lua]]	{'main'}
read [[source/Overlay.lua]]		{'main'}
read [[source/Selection.lua]]	{'main'}
read [[source/Mouse.lua]]		{'main'}
read [[source/Tools.lua]]		{'main'}

-- Menus
	local menus = [[source/Menus]]

	-- Movement Menu
		local menu = menus/[[Move]]

		read (menus/[[Move.lua]])			{'main'}
		read (menu/[[MoveAxis.lua]])		{'main'}
		read (menu/[[MoveFirst.lua]])		{'main'}
		read (menu/[[MoveObject.lua]])		{'main'}

	-- Insert Menu
		local menu = menus/[[Insert]]

		read (menus/[[Insert.lua]])			{'main'}
		read (menu/[[Brick.lua]])			{'main'}
		read (menu/[[CornerWedge.lua]])		{'main'}
		read (menu/[[TrussPart.lua]])		{'main'}
		read (menu/[[Wedge.lua]])		{'main'}


	-- Rotation Menu
		local menu = menus/[[Rotate]]

		read (menus/[[Rotate.lua]])			{'main'}
		read (menu/[[RotatePivot.lua]])		{'main'}
		read (menu/[[RotateGroup.lua]])		{'main'}
		read (menu/[[RotateObject.lua]])	{'main'}

	-- Resizing Menu
		local menu = menus/[[Resize]]

		read (menus/[[Resize.lua]])			{'main'}
		read (menu/[[ResizeObject.lua]])	{'main'}
		read (menu/[[ResizeCenter.lua]])	{'main'}

	-- Clipboard Menu
		local menu = menus/[[Clipboard]]

		read (menus/[[Clipboard.lua]])		{'main'}
		read (menu/[[Cut.lua]])				{'main'}
		read (menu/[[Copy.lua]])			{'main'}
		read (menu/[[Paste.lua]])			{'main'}
		read (menu/[[Duplicate.lua]])		{'main'}

	-- SelectEdge Menu
		local menu = menus/[[SelectEdge]]

		read (menus/[[SelectEdge.lua]])		{'main'}
		read(menu/[[SelectEdge.lua]])		{'main'}

read [[source/GUI.lua]]				{'main'}
read [[source/Footer.lua]]			{'main'}

write 'main' (output_files)
