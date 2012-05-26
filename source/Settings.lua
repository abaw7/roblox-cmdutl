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
	-- arrays: if a value in `b` does not exist in `a`, then add it to `a`
	local function combine_table(a,b)
		if IsArray(a) and IsArray(b) then
			for i = 1,#b do
				local v = b[i]
				local null = true
				for n = 1,#a do
					if a[n] == v then null = false break end
				end
				if null then table.insert(a,v) end
			end
		else
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
