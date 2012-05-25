local ALT_KEYS = {
	["\51"] = true;
	["\52"] = true;
}
local Mouse_Alt_Active = false

local CTRL_KEYS = {
	["\47"] = true;
	["\48"] = true;
	["\49"] = true;
	["\50"] = true;
}
local Mouse_Ctrl_Active = false

local ModelScope = Workspace

local function GetTop(object,scope)
	if not object then return nil end
	if object.Locked then return nil end
	if not object:IsDescendantOf(scope) then return nil end
	local top = object
	repeat
		top = top.Parent
		if top == nil then return object end
	until top.Parent == scope
	return top
end

local function DoubleClick(Mouse)
	local Target = GetTop(Mouse.Target,ModelScope)
	if Target then
		if Target:IsA"Model" then
			SelectionSet{}
			ModelScope = Target
			DisplayInfo("Scope into:",ModelScope:GetFullName())
		end
	elseif ModelScope:IsDescendantOf(Workspace) then
		SelectionSet{ModelScope}
		ModelScope = ModelScope.Parent
		DisplayInfo("Scope out to:",ModelScope:GetFullName())
	end
end

local LastTarget = nil
local function Click(Mouse,first,remove)
	local Target = GetTop(Mouse.Target,ModelScope)
	if first then
		LastTarget = Target
		if Target then
			if Mouse_Ctrl_Active then
				if InSelection(Target) then
					SelectionRemove(Target)
					return true
				else
					SelectionAdd(Target)
					return false
				end
			else
				SelectionSet{Target}
			end
		else
			SelectionSet{}
		end
	else
		if Target ~= LastTarget then
			LastTarget = Target
			if Mouse_Ctrl_Active then
				if Target then
					if remove then
						SelectionRemove(Target)
					else
						SelectionAdd(Target)
					end
				end
			else
				SelectionSet{Target}
			end
		end
	end
end

local Mouse_Active = false

local function ActivateMouse()
	Mouse_Active = true
	Plugin:Activate(true)
	ActivateMouseButton:SetActive(true)
	
	local Mouse = Plugin:GetMouse()
	
	ModelScope = Workspace

	local Down = false
	
	local select_hold = true
	local click_stamp = 0
	
	Event.Mouse.Down = Mouse.Button1Down:connect(function()
		Down = true
		if not Mouse_Alt_Active then
			local stamp = tick()
			if stamp-click_stamp < 0.3 then
				DoubleClick(Mouse)
			else
				local remove = Click(Mouse,true)
				if select_hold then
					Event.Mouse.SelectHold = Mouse.Move:connect(function()
						Click(Mouse,false,remove)
					end)
				end
			end
			click_stamp = stamp
		end
	end)
	Event.Mouse.Up = Mouse.Button1Up:connect(function()
		Down = false
		Event.Mouse.SelectHold = nil
	end)
	Event.Mouse.Move = Mouse.Move:connect(function()
		click_stamp = 0
		if Mouse.Target then
			Mouse.Icon = "rbxasset://textures/DragCursor.png"
		else
			Mouse.Icon = "rbxasset://textures/ArrowCursor.png"
		end
	end)
	Event.Mouse.KeyDown = Mouse.KeyDown:connect(function(key)
		if CTRL_KEYS[key] then
			Mouse_Ctrl_Active = true
		elseif ALT_KEYS[key] then
			Mouse_Alt_Active = true
		end
	end)
	Event.Mouse.KeyUp = Mouse.KeyUp:connect(function(key)
		if CTRL_KEYS[key] then
			Mouse_Ctrl_Active = false
		elseif ALT_KEYS[key] then
			Mouse_Alt_Active = false
		end
	end)
end

local function DeactivateMouse()
	Event.Mouse = nil
	ActivateMouseButton:SetActive(false)
	Mouse_Active = false
end

if ActivateMouseButton then
	ActivateMouseButton.Click:connect(function()
		if Mouse_Active then
			DeactivateMouse()
		else
			ActivateMouse()
		end
	end)
	Plugin.Deactivation:connect(DeactivateMouse)
end
