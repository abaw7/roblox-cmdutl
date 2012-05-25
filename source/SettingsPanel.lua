----SETTINGS PANEL
Activator('Settings',ActivateSettingsButton)

local SettingsScreen

function Initialize.Settings()
	if not _G.gloo then
		error(PROJECT_NAME.." needs the gloo library to load the GUI.",0)
	end
	local gloo = _G.gloo
	if not Initialized.GUI then
		Initialize.GUI()
	end

	local GlobalStylist = gloo.Stylist({
		Font = "ArialBold";
		FontSize = "Size14";
		TextColor3 = Color3.new(1,1,1);
	})

	local TextAlias = {
		TextColor3 = 'BackgroundColor3';
		TextTransparency = 'BackgroundTransparency';
	}

	local PanelStylist = gloo.Stylist{
		BackgroundTransparency = 0.3;
		BorderSizePixel = 0;
		BackgroundColor3 = Color3.new(0,0,0);
	}
	GlobalStylist.AddStylist(PanelStylist)

	local TitleStylist = gloo.Stylist{
		FontSize = "Size18";
		TextXAlignment = "Left";
		BackgroundTransparency = 1;
	}
	GlobalStylist.AddStylist(TitleStylist)

	local Screen = Instance.new('ScreenGui')
	SettingsScreen = Screen
	Screen.Name = PROJECT_NAME.."SettingsGUI";
	Screen.Parent = CoreGui
	-- fix size delay
	while Screen.AbsoluteSize.magnitude == 0 do
		Screen.Changed:wait()
	end

	local Shield = Create'Frame'{
		Active = true;
		Size = UDim2.new(1.5,0,1.5,0);
		Position = UDim2.new(-0.25,0,-0.25,0);
		BackgroundTransparency = 0.5;
		BorderSizePixel = 0;
		BackgroundColor3 = Color3.new(0,0,0);
		Parent = Screen;
	}

	local SettingsPanel = Create'Frame'{
		Size = UDim2.new(0.5,0,0.5,0);
		Position = UDim2.new(0.25,0,0.25,0);
		Parent = Screen;
	}
	PanelStylist.AddObject(SettingsPanel)

	local SettingsFrame = Create'Frame'{
		Size = UDim2.new(1,-16,1,-16);
		Position = UDim2.new(0,8,0,8);
		BackgroundTransparency = 1;
		Parent = SettingsPanel;
		Create'TextLabel'{
			Size = UDim2.new(1,0,0,18);
			Text = PROJECT_NAME.." Settings";
			Create'Frame'{
				BorderSizePixel = 0;
				Size = UDim2.new(1,0,0,1);
				Position = UDim2.new(0,0,1,0);
			};
		};
		Create'ImageButton'{
			Size = UDim2.new(0, 12, 0, 12);
			BackgroundTransparency = 0.5;
			BorderColor3 = Color3.new(1, 1, 1);
			Name = "CloseButton";
			Position = UDim2.new(1, -12, 0, -1);
			BackgroundColor3 = Color3.new(0, 0, 0);
		};
	}
	local CloseButton = SettingsFrame.CloseButton
	do
		local graphic = gloo.Graphic("cross",Vector2.new(12,12))
		graphic.GUI.Parent = CloseButton
		GlobalStylist.AddStylist(graphic.Stylist,{TextColor3 = "BackgroundColor3", TextTransparency = "BackgroundTransparency"})
	end
	CloseButton.MouseButton1Click:connect(function()
		Deactivate['Settings']()
	end)


--	gloo.AutoSizeLabel(SettingsFrame.TextLabel)
	TitleStylist.AddObject(SettingsFrame.TextLabel)
	GlobalStylist.AddObject(SettingsFrame.TextLabel.Frame,TextAlias)

	local TabContainerClass,TabContainerFrame = gloo.TabContainer(nil,22,18)
	do
		local t = {
			FontSize = gloo.NULL;
			Font = gloo.NULL;
			TextColor3 = gloo.NULL;
		--	BackgroundTransparency = 0;
		}
		TabContainerClass.TabStylist.SetProperties(t)
		TabContainerClass.SelectedTabStylist.SetProperties(t)
	end
	GlobalStylist.AddStylist(TabContainerClass.TabStylist)
	GlobalStylist.AddStylist(TabContainerClass.SelectedTabStylist)

	Modify(TabContainerFrame){
		Size = UDim2.new(1,0,1,-22);
		Position = UDim2.new(0,0,0,22);
		Parent = SettingsFrame;
	}

---- MENUS TAB
	local Options = SettingsData.Options
	-- checklist of menus to display in the panel
	do
		local menu_order = SettingsData.Layout.menu.order
		local menu_visible = SettingsData.Layout.menu.visible
		local menuListData = {}
		for i,menu_name in pairs(MenuList) do
			local visible = menu_visible[menu_name]
			menuListData[#menuListData+1] = {visible,menu_name}
		end

		local function checkCallback(data,class)
			local checked = not data[1]
			local menu_name = data[2]
			if menuNameFromTool[SelectedTool] == menu_name then
				DeselectTool(SelectedTool)
			end
			if checked then
				local frame = menuFrameFromName[menu_name]
				frame.Visible = true
				menu_visible[menu_name] = true
				MenuPanelClass.MoveObject(frame)
			else
				local index = GetIndex(MenuList,data[2])
				if index then
					menuFrameFromName[menu_name].Visible = false
					menu_visible[menu_name] = false
				end
			end
			SaveSettingsData('Layout')
			return true
		end

		local MenuListClass,MenuListFrame = gloo.DetailedList(menuListData,{
			{type='check-box', name="", width=UDim.new(0,17), checked={'check-mark',Vector2.new(17,17)}, callback=checkCallback };
			{type='text', name="Menus", width=UDim.new(1,-17), style={TextXAlignment="Left"} };
		})
		MenuListFrame.Size = UDim2.new(1,-8,1,-8)
		MenuListFrame.Position = UDim2.new(0,4,0,4)
		MenuListFrame.Name = "Menus"

		MenuListClass.Stylist.Global.ClearProperties()
		GlobalStylist.AddStylist(MenuListClass.Stylist.Global)

		TabContainerClass.AddTab(MenuListFrame)
	end
---- OPTIONS TAB
	-- list of various options (key/value DetailedList wrapper)
---- STYLE TAB
	-- more tabs, listing various stylists (key/value DetailedList wrapper)
---- DATA TAB
	-- message about saved data and a button to delete saved data
	do
		local DataFrame = Create'Frame'{
			Size = UDim2.new(1, 0, 1, 0);
			Name = "Data";
			BackgroundTransparency = 1;
			Create'TextLabel'{
				Text = "This plugin has save data that is stored with your Roblox settings. Clicking the button below will remove all of this plugin's save data.";
				Size = UDim2.new(1, -8, 0, 56);
				Position = UDim2.new(0, 4, 0, 4);
				BackgroundTransparency = 1;
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Top;
				TextWrap = true;
				Create'TextButton'{
					Name = "DeleteButton";
					Text = "Delete Plugin Data";
					BackgroundTransparency = 1;
					Position = UDim2.new(0.5, -65, 1, 4);
					Size = UDim2.new(0, 130, 0, 24);
					Style = Enum.ButtonStyle.RobloxButton;
				}
			}
		}
		local DeleteButton = DataFrame.TextLabel.DeleteButton
		GlobalStylist.AddObjects{
			DataFrame;
			DataFrame.TextLabel;
			DeleteButton;
		}
		local con;con = DeleteButton.MouseButton1Click:connect(function()
			if _G.gloo and _G.gloo.dialog then
				if not _G.gloo.dialog.Confirm(Screen,"Are you sure you want to delete this plugin's save data?") then
					return
				end
			end
			if DeleteValueNames then
				con:disconnect()
				local Settings = settings()
				for i,name in pairs(DeleteValueNames) do
					local data = Settings:FindFirstChild(name)
					if data then data:Destroy() end
				end
				local Settings = UserSettings()
				for i,name in pairs(DeleteValueNames) do
					local data = Settings:FindFirstChild(name)
					if data then data:Destroy() end
				end
				DeleteButton.Style = Enum.ButtonStyle.Custom
				DeleteButton.Text = "Plugin data has been deleted"
			end
		end)

		TabContainerClass.AddTab(DataFrame)
	end
end

function Activate.Settings()
	SettingsScreen.Parent = CoreGui
end

function Deactivate.Settings()
	SettingsScreen.Parent = nil
end
