Activator('GUI',ActivateGUIButton)

local Screen
local MenuPanelClass
local menuNameFromFrame = {}
local menuFrameFromName = {}
local menuNameFromTool = {}

local ExpandPanel
local CollapsePanel

local DockClass
local CancelMenuDrag

local function toUDim2(t)
	return UDim2.new(unpack(t))
end

local function fromUDim2(u)
	return {u.X.Scale,u.X.Offset,u.Y.Scale,u.Y.Offset}
end

function Initialize.GUI()
	if not _G.gloo then
		error(PROJECT_NAME.." needs the gloo library to load the GUI.",0)
	end
	local gloo = _G.gloo
	local DockedSide = gloo.DockedSide

	local Layout = SettingsData.Layout

	local draggingMenu = false
	local hoverEnabled = true
	
	local GlobalStylist = gloo.Stylist{
		Font = "ArialBold";
		FontSize = "Size14";
		TextColor3 = Color3.new(1,1,1);
		BackgroundTransparency = 0.5;
		BackgroundColor3 = Color3.new(0,0,0);
		BorderColor3 = Color3.new(1,1,1);
	}

	local MenuStylist = gloo.Stylist{}
	GlobalStylist.AddStylist(MenuStylist)

	local ButtonStylist = gloo.Stylist{
		Size = UDim2.new(0,100,0,20);
		Style = "RobloxButton";
		Selected = false;
	}
	GlobalStylist.AddStylist(ButtonStylist)

	local SelectedButtonStylist = gloo.Stylist{
		Selected = true;
	}
	ButtonStylist.AddStylist(SelectedButtonStylist)

	local MenuNodeStylist = gloo.Stylist{
		BackgroundTransparency = 0.5;
		BorderSizePixel = 0;
		Size = UDim2.new(0,100,0,8);
	}

	local HoverNameStylist = gloo.Stylist{
		AutoButtonColor = false;
		BackgroundTransparency = 1;
		TextStrokeColor3 = Color3.new(0,0,0);
		TextStrokeTransparency = 0;
	}
	GlobalStylist.AddStylist(HoverNameStylist)

	Screen = Instance.new("ScreenGui")
	Screen.Name = PROJECT_NAME.."GUI"
	Screen.Parent = CoreGui
	-- fix size delay
	while Screen.AbsoluteSize.magnitude == 0 do
		Screen.Changed:wait()
	end

	local _,DockFrame = gloo.DockContainer(Instance.new("Frame"))
	DockClass = _
	DockFrame.Name = "DockContainer"
	DockFrame.Transparency = 1
	DockFrame.Size = UDim2.new(1,0,1,0)
	DockFrame.Parent = Screen

	DisplayInfoGUI = Create'TextButton'{
		Name = "DisplayInfoGUI";
		Text = "";
	}
	DisplayInfoGUI.Parent = DockFrame;
	HoverNameStylist.AddObject(DisplayInfoGUI)
	local InfoClass = gloo.AutoSizeLabel(DisplayInfoGUI)
	InfoClass.LockAxis(nil,24)
	InfoClass.SetPadding(4)
	local info_layout = Layout.dockables.DisplayInfoGUI

	local _,MenuPanelFrame = gloo.StackingFrame(Instance.new("ImageButton"))
	MenuPanelClass = _
	MenuPanelClass.SetPadding(4,8)
	Modify(MenuPanelFrame){
		AutoButtonColor = false;
		Name = "MenuPanelFrame";
		BorderSizePixel = 0;
		BackgroundColor3 = Color3.new(0,0,0);
		BackgroundTransparency = 0.3;
	}
	MenuPanelFrame.Parent = DockFrame
	local panel_layout = Layout.dockables.MenuPanelFrame

	local Placeholder = Create'Frame'{
		Name = "Placeholder";
		BackgroundTransparency = 1;
	}
	
	local MouseDrag = Create'ImageButton'{
		Active = false;
		Size = UDim2.new(1.5, 0, 1.5, 0);
		AutoButtonColor = false;
		BackgroundTransparency = 1;
		Name = "MouseDrag";
		Position = UDim2.new(-0.25, 0, -0.25, 0);
		ZIndex = 10;
	}

	local PanelHoverFrame = Create'Frame'{
		Name = "PanelHoverFrame";
		BackgroundTransparency = 1;
		Parent = Screen;
	}

	local math_env = {
		abs = math.abs; acos = math.acos; asin = math.asin; atan = math.atan; atan2 = math.atan2;
		ceil = math.ceil; cos = math.cos; cosh = math.cosh; deg = math.deg;
		exp = math.exp; floor = math.floor; fmod = math.fmod; frexp = math.frexp;
		huge = math.huge; ldexp = math.ldexp; log = math.log; log10 = math.log10;
		max = math.max; min = math.min; modf = math.modf; pi = math.pi;
		pow = math.pow; rad = math.rad; random = math.random; sin = math.sin;
		sinh = math.sinh; sqrt = math.sqrt; tan = math.tan; tanh = math.tanh;
	}
	
	local function eval(str,prev)
		local env = {}
		for k,v in pairs(math_env) do
			env[k] = v
		end
		env.x = prev
		env.n = prev
		if _VERSION == "Lua 5.2" then
			local f = load('return '..s,nil,nil,env)
			if f then
				local s,o = pcall(f)
				if s then return o end
			end
		else
			local f = loadstring("return "..str)
			if f then
				setfenv(f,env)
				local s,o = pcall(f)
				if s then return o end
			end
		end
		return nil
	end
--[[
	local function GetPosIndex(list,pos,size)
		list = MenuPanelClass.List
		if #list > 1 then
			local yMax = pos.y
			local index

			for i = 1,#list do
				local menu = list[i]
				if menu.AbsolutePosition.y + menu.AbsoluteSize.y/2 > yMax - size.y
				and menu.AbsolutePosition.y + size.y > yMax - size.y then
					index = i
					break
				end
			end
			return index
		else
			return 1
		end
	end
--]]
	local function GetPosIndex(list,pos)
		if #list > 1 then
			local yMax = pos.y
			local index = #list

			for i = 1,#list do
				if list[i] and list[i].y > yMax then
					index = i
					break
				end
			end
			return index
		else
			return 1
		end
	end

	local function InvokeMenuDrag(MenuFrame,offset,fToggle)
		if draggingMenu then return end
		draggingMenu = true

		local orderSet = {}
		do
			local list = MenuPanelClass.List
			for i = 1,#list do
				local menu_frame = list[i]
				if menu_frame.Visible then
					orderSet[i] = menu_frame.AbsolutePosition + menu_frame.AbsoluteSize
				else
					orderSet[i] = false
				end
			end
		end

		local mouse_pos = offset + MenuFrame.AbsolutePosition
		Placeholder.Size = MenuFrame.Size
		local index = MenuPanelClass.GetIndex(MenuFrame)
		MenuPanelClass.RemoveObject(MenuFrame)
		MenuPanelClass.AddObject(Placeholder,index)
		MenuFrame.Parent = Screen

		local drag_con
		local up_con

		local do_toggle = true
		local zIndex = MenuFrame.ZIndex
		local function mouse_up()
			CancelMenuDrag = nil
			MouseDrag.Parent = nil
			drag_con:disconnect(); drag_con = nil
			up_con:disconnect(); drag = nil
			gloo.SetZIndex(MenuFrame,zIndex)
			MenuPanelClass.RemoveObject(Placeholder)
			MenuPanelClass.AddObject(MenuFrame,index)
			draggingMenu = false
			if do_toggle then
				fToggle()
			else
				-- update save state
				local list = MenuPanelClass.List
				local menu_order = Layout.menu.order
				for i = 1,#menu_order do
					menu_order[i] = nil
				end
				for i = 1,#list do
					local name = menuNameFromFrame[list[i]]
					menu_order[i] = name
				end
				SaveSettingsData('Layout')
			end
		end
		CancelMenuDrag = mouse_up

		local function mouse_drag(x,y)
			local mouse_pos = Vector2.new(x,y)
			local pos = mouse_pos - offset
			local x,y = pos.x,pos.y
			local cPos = MenuPanelFrame.AbsolutePosition + Vector2.new(8,8)
			local max = cPos + MenuPanelFrame.AbsoluteSize - Vector2.new(16,16)

			if y > max.y then
				y = max.y
			elseif y < cPos.y then
				y = cPos.y
			end

			MenuFrame.Position = UDim2.new(0,cPos.x,0,y)
			index = GetPosIndex(orderSet,mouse_pos) or index
		--	index = GetPosIndex(orderSet,MenuFrame.AbsolutePosition + MenuFrame.AbsoluteSize/2,MenuFrame.AbsoluteSize/2) or index
			MenuPanelClass.MoveObject(Placeholder,index)
		end

		drag_con = MouseDrag.MouseMoved:connect(function(...)
			do_toggle = false
			mouse_drag(...)
		end)
		up_con = MouseDrag.MouseButton1Up:connect(mouse_up)
		gloo.SetZIndex(MenuFrame,zIndex + 1)
		MouseDrag.Parent = Screen
		mouse_drag(mouse_pos.x,mouse_pos.y)
	end

---- GENERATE MENUS
	local menu_visible = Layout.menu.visible
	local menu_expanded = Layout.menu.expanded
	for i,menu_name in pairs(MenuList) do
		local menu = Menus[menu_name]
		local MenuClass,MenuFrame = gloo.StackingFrame()
		MenuClass.SetPadding()
		MenuStylist.AddObject(MenuFrame)
		menuNameFromFrame[MenuFrame] = menu_name
		menuFrameFromName[menu_name] = MenuFrame
		MenuPanelClass.AddObject(MenuFrame)

		MenuFrame.Name = menu_name.."Menu"
		MenuFrame.Visible = menu_visible[menu_name]
		local expanded = menu_expanded[menu_name]

		do	-- MENU HANDLE
			local Node = Instance.new("ImageButton")
			Node.Name = "MenuHandle"
			if menu.Color then
				Node.BackgroundColor3 = menu.Color
			else
				Node.BackgroundColor3 = Color3.new(1,1,1)
			end
			MenuNodeStylist.AddObject(Node)
			MenuClass.AddObject(Node)
			local label = Instance.new('TextLabel')
			local labelClass = gloo.AutoSizeLabel(label)
			labelClass.LockAxis(nil,8)
			labelClass.SetPadding(4)
			HoverNameStylist.AddObject(label)
			label.Visible = false
			label.Text = menu_name .. " Menu"
			label.Parent = Node
			Node.MouseEnter:connect(function()
				if not draggingMenu then
					if Node.AbsolutePosition.x + Node.AbsoluteSize.x + label.AbsoluteSize.x > Screen.AbsoluteSize.x then
						label.Position = UDim2.new(0,-label.AbsoluteSize.x,0,0)
					else
						label.Position = UDim2.new(1,0,0,0)
					end
					label.Visible = true
				end
			end)
			Node.MouseLeave:connect(function() label.Visible = false end)

			local function toggle_menu()
				if menuNameFromTool[SelectedTool] == menu_name then
					DeselectTool(SelectedTool)
				end
				menu_expanded[menu_name] = not menu_expanded[menu_name]
				for i,button in pairs(MenuClass.List) do
					if button ~= Node then
						button.Visible = menu_expanded[menu_name]
					end
				end
				SaveSettingsData('Layout')
			end

			Node.MouseButton1Down:connect(function(x,y)
				label.Visible = false
				InvokeMenuDrag(MenuFrame,Vector2.new(x,y) - MenuFrame.AbsolutePosition,toggle_menu)
			end)
		end

		---- MENU VARIABLES
		if menu.Variables and menu.VariableList then
			local vars = menu.Variables
			local menu_vars = Layout.menu.variables[menu_name]
			for i,var in pairs(menu.VariableList) do
				local name = var[1]
				local field
				vars[name] = menu_vars[name]
				if type(vars[name]) == 'number' then
					field = Instance.new("TextBox")
					ButtonStylist.AddObject(field)
					MenuClass.AddObject(field)
					field.Text = menu_vars[name] or vars[name]
					field.FocusLost:connect(function(enter)
						local num = tonumber(eval(field.Text,vars[name]))
						if num then
							vars[name] = num
							field.Text = num
							menu_vars[name] = num
							SaveSettingsData('Layout')
						else
							field.Text = vars[name]
						end
					end)
				end
				if field then
					field.Name = name.."Field"
					field.Visible = expanded
					local label = Instance.new('TextLabel',field)
					local labelClass = gloo.AutoSizeLabel(label)
					labelClass.LockAxis(nil,20)
					labelClass.SetPadding(4)
					HoverNameStylist.AddObject(label)
					label.Visible = false
					label.Text = var[2] or var[1]
					field.MouseEnter:connect(function()
						if not draggingMenu then
							if field.AbsolutePosition.x + field.AbsoluteSize.x + label.AbsoluteSize.x > Screen.AbsoluteSize.x then
								label.Position = UDim2.new(0,-label.AbsoluteSize.x,0,0)
							else
								label.Position = UDim2.new(1,0,0,0)
							end
							label.Visible = true
						end
					end)
					field.MouseLeave:connect(function() label.Visible = false end)
				end
			end
		end

		---- MENU TOOLS
		for i,tool in pairs(menu.Tools) do
			local button = Instance.new("TextButton")
			ButtonStylist.AddObject(button)
			button.Name = tool .. "Button"
			button.Text = tool
			button.Visible = expanded
			MenuClass.AddObject(button)
			menuNameFromTool[tool] = menu_name
			ToolSelectCallback[tool] = function()
				ButtonStylist.RemoveObject(button)
				SelectedButtonStylist.AddObject(button)
			end
			ToolDeselectCallback[tool] = function()
				SelectedButtonStylist.RemoveObject(button)
				ButtonStylist.AddObject(button)
			end
			button.MouseButton1Click:connect(function()
				SelectTool(tool)
			end)
		end
	end

	do	-- order menus from save
		local menu_order = Layout.menu.order
		local list = MenuPanelClass.List
		local new = {}
		for menuFrame,menu_name in pairs(menuNameFromFrame) do
			local index = GetIndex(menu_order,menu_name)
			if index then
				list[index] = menuFrame
			else
				new[#new+1] = menuFrame
			end
		end
		for i = 1,#new do
			table.insert(list,new[i])
		end
		MenuPanelClass.Update()
	end

	local function tweenPanel(position,dir,notween)
		if notween == true then
			MenuPanelFrame.Position = position
		else
			MenuPanelFrame:TweenPosition(position,dir,"Quad",0.25,true)
		end
	end

	function ExpandPanel(notween)
		if hoverEnabled then
			if panel_layout.docked_to_screen then
				local position = toUDim2(panel_layout.position)
				local side = panel_layout.docked_side
				if side == DockedSide.Bottom then
					local size = MenuPanelFrame.Size
					position = UDim2.new(position.X.Scale,position.X.Offset,1-size.Y.Scale,-size.Y.Offset)
					tweenPanel(position,"Out",notween)
				elseif side == DockedSide.Top then
					tweenPanel(UDim2.new(position.X.Scale,position.X.Offset,0,0),"Out",notween)
				elseif side == DockedSide.Right then
					local size = MenuPanelFrame.Size
					position = UDim2.new(1-size.X.Scale,-size.X.Offset,position.Y.Scale,position.Y.Offset)
					tweenPanel(position,"Out",notween)
				elseif side == DockedSide.Left then
					tweenPanel(UDim2.new(0,0,position.Y.Scale,position.Y.Offset),"Out",notween)
				end
			end
		end
	end

	function CollapsePanel(notween)
		if hoverEnabled and not SelectedTool and not draggingMenu then
			if panel_layout.docked_to_screen then
				local position = toUDim2(panel_layout.position)
				local side = panel_layout.docked_side
				if side == DockedSide.Bottom then
					tweenPanel(UDim2.new(position.X.Scale,position.X.Offset,1,0),"In",notween)
				elseif side == DockedSide.Top then
					tweenPanel(UDim2.new(position.X.Scale,position.X.Offset,0,-MenuPanelFrame.AbsoluteSize.y),"In",notween)
				elseif side == DockedSide.Right then
					tweenPanel(UDim2.new(1,0,position.Y.Scale,position.Y.Offset),"In",notween)
				elseif side == DockedSide.Left then
					tweenPanel(UDim2.new(0,-MenuPanelFrame.AbsoluteSize.x,position.Y.Scale,position.Y.Offset),"In",notween)
				end
			end
		end
	end

	PanelHoverFrame.MouseEnter:connect(ExpandPanel)
	PanelHoverFrame.MouseLeave:connect(CollapsePanel)
--[[
	local function computeAlignedPos(object,side)
		if side == DockedSide.Outer then
			local size = object.Size
			local pos = object.Position
			if side == DockedSide.YAxis then
				object.Position = UDim2.new(pos.X.Scale,pos.X.Offset,1-size.Y.Scale,-size.Y.Offset)
			else
				object.Position = UDim2.new(1-size.X.Scale,-size.X.Offset,pos.Y.Scale,pos.Y.Offset)
			end
		end
	end
--]]

	-- if object is docked to right or bottom of screen, right/bottom align it so it sticks
	local function getRightAlign(layout,s,p)
		if layout.docked_to_screen then
			if layout.docked_side == DockedSide.Right then
				return UDim2.new(1-s.X.Scale,-s.X.Offset,p.Y.Scale,p.Y.Offset)
			elseif layout.docked_side == DockedSide.Bottom then
				return UDim2.new(p.X.Scale,p.X.Offset,1-s.Y.Scale,-s.Y.Offset)
			end
		end
	end

	local function rightAlignDockable(object,layout,size,update)
		if size then object.Size = size end
		local s = object.Size
		local p = toUDim2(layout.position)
		local new = getRightAlign(layout,s,p)
		if new then
			object.Position = new
		elseif update then
			object.Position = p
		end
	end

	local layout_dockables = Layout.dockables
	DockClass.DragBeginCallback = function(dragged)
		hoverEnabled = false	-- disable PanelHoverFrame when dragging
	end

	DockClass.DragCallback = function(dragged)
		local layout = layout_dockables[dragged.Name]
		if layout then
			-- before the drag starts, reset dock values
			layout.docked_side = DockedSide.None
			layout.docked_to_screen = false
		end
	end

	DockClass.DockCallback = function(dragged,docked,side)
		if docked == PanelHoverFrame then	-- if an object is trying to dock with the PanelHoverFrame
			return false					-- cancel the dock
		end
	end

	DockClass.ObjectDocked:connect(function(dragged,docked,side)
		local layout = layout_dockables[dragged.Name]
		if layout then
			layout.docked_side = side	-- when an object docks, save the side it docked on
			if docked == DockFrame then
				layout.docked_to_screen = true
			end
		end
	end)

	DockClass.DragStopped:connect(function(dragged)
		local layout = layout_dockables[dragged.Name]
		if layout then
			layout.position = fromUDim2(dragged.Position)	-- whe the drag stops, save the object's position
			rightAlignDockable(dragged,layout)
		end
		if dragged == MenuPanelFrame then	-- if the dragged was the panel frame
			rightAlignDockable(PanelHoverFrame,layout,MenuPanelFrame.Size,true)	-- update the PanelHoverFrame
		end
		hoverEnabled = true	-- enable PanelHoverFrame
		SaveSettingsData('Layout')
	end)

	-- update objects to reflect saved layout
	for name,layout in pairs(Layout.dockables) do
		local frame = DockFrame:FindFirstChild(name)
		if frame then
			frame.Position = toUDim2(layout.position)
			frame.Changed:connect(function(p)
				if p == "AbsoluteSize" then
					rightAlignDockable(frame,layout)
				end
			end)
			rightAlignDockable(frame,layout)
		end
	end
	MenuPanelFrame.Changed:connect(function(p)
		if p == "AbsoluteSize" then
			if hoverEnabled then
				rightAlignDockable(PanelHoverFrame,panel_layout,MenuPanelFrame.Size,true)
			end
		end
	end)
	rightAlignDockable(PanelHoverFrame,panel_layout,MenuPanelFrame.Size,true)

---- Roblox HUD docking
	local RobloxGui = CoreGui:FindFirstChild("RobloxGui")
	if RobloxGui then
		local findObjects = {
			MouseLockLabel = function(object)
				return object.Visible
			end;
			SettingsButton = true;
			CameraTiltDown = true;
			CameraTiltUp = true;
			CameraZoomIn = true;
			CameraZoomOut = true;
			BackpackButton = true;
		}

		local function makeDockFrame(object)
			local frame = Create'Frame'{
				Name = object.Name;
				BackgroundTransparency = 1;
				Size = UDim2.new(0,object.AbsoluteSize.x,0,object.AbsoluteSize.y);
				Position = UDim2.new(0,object.AbsolutePosition.x,0,object.AbsolutePosition.y);
			}
			object.Changed:connect(function(p)
				if p == "AbsoluteSize" then
					frame.Size = UDim2.new(0,object.AbsoluteSize.x,0,object.AbsoluteSize.y)
				elseif p == "AbsolutePosition" then
					frame.Position = UDim2.new(0,object.AbsolutePosition.x,0,object.AbsolutePosition.y)
				elseif p == "Visible" then
					frame.Visible = object.Visible
				end
			end)
			frame.Parent = DockFrame
		end

		RobloxGui.DescendantAdded:connect(function(object)
			local find = findObjects[object.Name]
			if find then
				if type(f) == "function" then
					if f(object) then
						makeDockFrame(object)
					end
				else
					makeDockFrame(object)
				end
			end
		end)

		for name,f in pairs(findObjects) do
			if type(f) == "function" then
				local object = RobloxGui:FindFirstChild(name,true)
				if object and f(object) then
					makeDockFrame(object)
				end
			else
				local object = RobloxGui:FindFirstChild(name,true)
				if object then
					makeDockFrame(object)
				end
			end
		end

	end
	DisplayInfo("Loaded GUI")
	Screen.Parent = nil
end

function Activate.GUI()
	ExpandPanel(true)
	Screen.Parent = CoreGui
end

function Deactivate.GUI()
	DeselectTool(SelectedTool)
	DockClass.StopDrag()
	if CancelMenuDrag then CancelMenuDrag() end
	Screen.Parent = nil
	CollapsePanel(true)
end
