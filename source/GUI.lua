local Screen

local GUI_Initialized = false
local GUI_Active = false

local ExpandPanel
local CollapsePanel

local function InitializeGUI()
	if not _G.gloo then
		error(PROJECT_NAME.." needs the gloo library to load the GUI.",0)
	end

	local draggingMenu = false
	local infoRight = false
	local hoverEnabled = true
	local panelPosition
	local collapseAxis = "x"
	local collapseDirection = -1
	
	local GlobalStylist = _G.gloo.Stylist{
		Font = "ArialBold";
		FontSize = "Size14";
		TextColor3 = Color3.new(1,1,1);
	}

	local MenuStylist = _G.gloo.Stylist{
		BackgroundTransparency = 0.5;
		BackgroundColor3 = Color3.new(0,0,0);
		BorderColor3 = Color3.new(1,1,1);
	}

	local ButtonStylist = _G.gloo.Stylist{
		BackgroundTransparency = 0.5;
		BackgroundColor3 = Color3.new(0,0,0);
		BorderColor3 = Color3.new(1,1,1);
		Size = UDim2.new(0,100,0,20);
		Style = "RobloxButton";
		Selected = false;
	}
	GlobalStylist.AddStylist(ButtonStylist)

	local SelectedButtonStylist = _G.gloo.Stylist{
		BackgroundTransparency = 0.5;
		BackgroundColor3 = Color3.new(0,0,0);
		BorderColor3 = Color3.new(1,1,1);
		Size = UDim2.new(0,100,0,20);
		Style = "RobloxButton";
		Selected = true;
	}
	GlobalStylist.AddStylist(SelectedButtonStylist)

	local MenuNodeStylist = _G.gloo.Stylist{
		BackgroundTransparency = 0.5;
		BorderSizePixel = 0;
		Size = UDim2.new(0,100,0,8);
	}

	local HoverNameStylist = _G.gloo.Stylist{
		AutoButtonColor = false;
		BackgroundTransparency = 1;
		TextStrokeColor3 = Color3.new(0,0,0);
		TextStrokeTransparency = 0;
	}
	GlobalStylist.AddStylist(HoverNameStylist)

	local DockClass = _G.gloo.DockContainer()
	Screen = DockClass.GUI
	Screen.Name = PROJECT_NAME.."GUI"

	DisplayInfoGUI = Create'TextButton'{
		Name = "DisplayInfoGUI";
		Text = "";
		Parent = Screen;
	}
	HoverNameStylist.AddObject(DisplayInfoGUI)
	local InfoClass = _G.gloo.AutoSizeLabel(DisplayInfoGUI)
	InfoClass.LockAxis(nil,24)
	InfoClass.SetPadding(4)

	local MenuContainerClass,MenuContainerFrame = _G.gloo.StackingFrame(Instance.new("ImageButton"))
	MenuContainerClass.SetPadding(4,8)
	Modify(MenuContainerFrame){
		AutoButtonColor = false;
		Name = "MenuContainer";
		BorderSizePixel = 0;
		BackgroundColor3 = Color3.new(0,0,0);
		BackgroundTransparency = 0.3;
		Position = UDim2.new(0,0,0,24);
		Parent = Screen;
	}
	panelPosition = MenuContainerFrame.Position

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

	local MouseOverFrame = Create'Frame'{
		Name = "MouseOver";
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
		local f = loadstring("return "..str)
		if f then
			setfenv(f,env)
			local s,o = pcall(f)
			if s then
				return o
			end
		end
		return nil
	end

	local function GetPosIndex(list,pos,size)
		list = MenuContainerClass.List
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

	local function InvokeMenuDrag(MenuFrame,offset,fToggle)
		draggingMenu = true

		local orderSet = {}
		do
			local list = MenuContainerClass.List
			for i = 1,#list do
				orderSet[i] = list[i].AbsolutePosition + list[i].AbsoluteSize/2
			end
		end

		local mouse_pos = offset + MenuFrame.AbsolutePosition
		Placeholder.Size = MenuFrame.Size
		local index = MenuContainerClass.GetIndex(MenuFrame)
		MenuContainerClass.RemoveObject(MenuFrame)
		MenuContainerClass.AddObject(Placeholder,index)
		MenuFrame.Parent = Screen

		local drag_con
		local up_con

		local doToggle = true
		local zIndex = MenuFrame.ZIndex
		local function mouse_up()
			MouseDrag.Parent = nil
			drag_con:disconnect(); drag_con = nil
			up_con:disconnect(); drag = nil
			_G.gloo.SetZIndex(MenuFrame,zIndex)
			MenuContainerClass.RemoveObject(Placeholder)
			MenuContainerClass.AddObject(MenuFrame,index)
			draggingMenu = false
			if doToggle then
				fToggle()
			end
		end

		local function mouse_drag(x,y)
			local pos = Vector2.new(x,y) - offset
			local x,y = pos.x,pos.y
			local cPos = MenuContainerFrame.AbsolutePosition + Vector2.new(8,8)
			local max = cPos + MenuContainerFrame.AbsoluteSize - Vector2.new(16,16)

			if y > max.y then
				y = max.y
			elseif y < cPos.y then
				y = cPos.y
			end

			MenuFrame.Position = UDim2.new(0,cPos.x,0,y)
			index = GetPosIndex(orderSet,MenuFrame.AbsolutePosition + MenuFrame.AbsoluteSize/2,MenuFrame.AbsoluteSize/2) or index
			MenuContainerClass.MoveObject(Placeholder,index)
		end

		drag_con = MouseDrag.MouseMoved:connect(function(...)
			doToggle = false
			mouse_drag(...)
		end)
		up_con = MouseDrag.MouseButton1Up:connect(mouse_up)
		_G.gloo.SetZIndex(MenuFrame,zIndex + 1)
		MouseDrag.Parent = Screen
		mouse_drag(mouse_pos.x,mouse_pos.y)
	end

	for i,menu_name in pairs(MenuList) do
		local menu = Menus[menu_name]
		local MenuClass,MenuFrame = _G.gloo.StackingFrame()
		MenuClass.SetPadding()
		MenuStylist.AddObject(MenuFrame)
		MenuContainerClass.AddObject(MenuFrame)

		do
			local Node = Instance.new("ImageButton")
			if menu.Color then
				Node.BackgroundColor3 = menu.Color
			else
				Node.BackgroundColor3 = Color3.new(1,1,1)
			end
			MenuNodeStylist.AddObject(Node)
			MenuClass.AddObject(Node)
			local label = Instance.new('TextLabel')
			local labelClass = _G.gloo.AutoSizeLabel(label)
			labelClass.LockAxis(nil,8)
			labelClass.SetPadding(4)
			HoverNameStylist.AddObject(label)
			label.Visible = false
			label.Text = menu_name .. " Menu"
			label.Parent = Node
			Node.MouseEnter:connect(function()
				if Node.AbsolutePosition.x + Node.AbsoluteSize.x + label.AbsoluteSize.x > Screen.AbsoluteSize.x then
					label.Position = UDim2.new(0,-label.AbsoluteSize.x,0,0)
				else
					label.Position = UDim2.new(1,0,0,0)
				end
				label.Visible = true
			end)
			Node.MouseLeave:connect(function() label.Visible = false end)

			local visible = true
			local function toggle_menu()
				visible = not visible
				for i,button in pairs(MenuClass.List) do
					if button ~= Node then
						button.Visible = visible
					end
				end
			end

			Node.MouseButton1Down:connect(function(x,y)
				label.Visible = false
				InvokeMenuDrag(MenuFrame,Vector2.new(x,y) - MenuFrame.AbsolutePosition,toggle_menu)
			end)
		end
		local vars = menu.Variables
		for i,var in pairs(menu.VariableList) do
			local name = var[1]
			local field
			if type(vars[name]) == 'number' then
				field = Instance.new("TextBox")
				ButtonStylist.AddObject(field)
				MenuClass.AddObject(field)
				field.Text = vars[name]
				field.FocusLost:connect(function(enter)
					local num = tonumber(eval(field.Text,vars[name]))
					if num then
						vars[name] = num
						field.Text = num
					else
						field.Text = vars[name]
					end
				end)
			end
			if field then
				local label = Instance.new('TextLabel',field)
				local labelClass = _G.gloo.AutoSizeLabel(label)
				labelClass.LockAxis(nil,20)
				labelClass.SetPadding(4)
				HoverNameStylist.AddObject(label)
				label.Visible = false
				label.Text = var[2]
				field.MouseEnter:connect(function()
					if field.AbsolutePosition.x + field.AbsoluteSize.x + label.AbsoluteSize.x > Screen.AbsoluteSize.x then
						label.Position = UDim2.new(0,-label.AbsoluteSize.x,0,0)
					else
						label.Position = UDim2.new(1,0,0,0)
					end
					label.Visible = true
				end)
				field.MouseLeave:connect(function() label.Visible = false end)
			end
		end

		for i,tool in pairs(menu.Tools) do
			local button = Instance.new("TextButton")
			ButtonStylist.AddObject(button)
			button.Name = tool .. "Button"
			button.Text = tool
			MenuClass.AddObject(button)
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

	local function tweenPanel(position,dir,notween)
		if notween == true then
			MenuContainerFrame.Position = position
		else
			MenuContainerFrame:TweenPosition(position,dir,"Quad",0.25,true)
		end
	end

	function ExpandPanel(notween)
		if hoverEnabled and collapseDirection ~= 0 then
			DisplayInfoGUI.Visible = true
			if collapseAxis == "y" then
				if collapseDirection == 1 then
					tweenPanel(panelPosition,"Out",notween)
				else
					tweenPanel(UDim2.new(panelPosition.X.Scale,panelPosition.X.Offset,0,0),"Out",notween)
				end
			else
				if collapseDirection == 1 then
					tweenPanel(panelPosition,"Out",notween)
				else
					tweenPanel(UDim2.new(0,0,panelPosition.Y.Scale,panelPosition.Y.Offset),"Out",notween)
				end
			end
		end
	end


	function CollapsePanel(notween)
		if hoverEnabled and collapseDirection ~= 0 and not SelectedTool and not draggingMenu then
			DisplayInfoGUI.Visible = false
			if collapseAxis == "y" then
				if collapseDirection == 1 then
					tweenPanel(UDim2.new(panelPosition.X.Scale,panelPosition.X.Offset,1,0),"In",notween)
				else
					tweenPanel(UDim2.new(panelPosition.X.Scale,panelPosition.X.Offset,0,-MenuContainerFrame.AbsoluteSize.y),"In",notween)
				end
			else
				if collapseDirection == 1 then
					tweenPanel(UDim2.new(1,0,panelPosition.Y.Scale,panelPosition.Y.Offset),"In",notween)
				else
					tweenPanel(UDim2.new(0,-MenuContainerFrame.AbsoluteSize.x,panelPosition.Y.Scale,panelPosition.Y.Offset),"In",notween)
				end
			end
		end
	end

	MouseOverFrame.MouseEnter:connect(ExpandPanel)
	MouseOverFrame.MouseLeave:connect(CollapsePanel)

	MenuContainerFrame.Changed:connect(function(p)
		if hoverEnabled and p == "AbsoluteSize" then
			MouseOverFrame.Size = MenuContainerFrame.Size
		end
	end)
	MouseOverFrame.Size = MenuContainerFrame.Size
	MouseOverFrame.Position = MenuContainerFrame.Position

	DisplayInfoGUI.Changed:connect(function(p)
		if infoRight and p == "AbsoluteSize" then
			local pos = DisplayInfoGUI.Position
			DisplayInfoGUI.Position = UDim2.new(1,-DisplayInfoGUI.AbsoluteSize.x,pos.Y.Scale,pos.Y.Offset)
		end
	end)

	DockClass.DragBeginCallback = function(dragged)
		if dragged == MenuContainerFrame then
			hoverEnabled = false
		end
	end

	DockClass.DragCallback = function(dragged)
		if dragged == MenuContainerFrame then
			collapseAxis = "x"
			collapseDirection = 0
		elseif dragged == DisplayInfoGUI then
			infoRight = false
		end
	end

	DockClass.DockCallback = function(dragged,docked,axis,side)
		if dragged == MenuContainerFrame then
			collapseAxis = axis
			collapseDirection = side*2-1
		elseif dragged == DisplayInfoGUI then
			if docked == Screen and axis == "x" and side == 1 then
				infoRight = true
			end
		end
	end

	DockClass.DragStopCallback = function(dragged)
		if dragged == MenuContainerFrame then
			panelPosition = MenuContainerFrame.Position
			MouseOverFrame.Position = panelPosition
			hoverEnabled = true
		end
	end

---- Roblox HUD docking
	local RobloxGui = CoreGui:FindFirstChild("RobloxGui")
	if RobloxGui then
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
			frame.Parent = Screen
		end

		local findObjects = {
			MouseLockLabel = function(object)
				return object.Active
			end;
			SettingsButton = true;
			CameraTiltDown = true;
			CameraTiltUp = true;
			CameraZoomIn = true;
			CameraZoomOut = true;
			BackpackButton = true;
		}

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

	GUI_Initialized = true
end

local function ActivateGUI()
	if GUI_Initialized then
		ExpandPanel(true)
		Screen.Parent = CoreGui
		GUI_Active = true
	end
end

local function DeactivateGUI()
	if GUI_Initialized then
		GUI_Active = false
		DeselectTool(SelectedTool)
		Screen.Parent = nil
		CollapsePanel(true)
	end
end

if ActivateGUIButton then
	ActivateGUIButton.Click:connect(function()
		if GUI_Initialized then
			if GUI_Active then
				DeactivateGUI()
			else
				ActivateGUI()
			end
		else
			InitializeGUI()
			ActivateGUI()
		end
	end)
end
