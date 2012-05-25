local Tool = "ResizeCenter"

table.insert(Menus[Menu].Tools,Tool)
Variables[Tool] = Menus[Menu].Variables

OnToolSelect[Tool] = function(tool,vars)
	OverlayHandles.Color = BrickColor.new("Cyan")
	OverlayHandles.Style = "Resize"
	OverlayHandles.Visible = true

	local origin = {}
	local first
	local face_mult,face_size,face_vec
	local cinc
	local inc
	Event[tool].Down = OverlayHandles.MouseButton1Down:connect(function(face)
		face_mult,face_size,face_vec = FACE_MULTIPLIER[face],FACE_COMPONENT[face],Vector3FromNormalId(face)
		first = ToolSelection[1]
		for k in pairs(origin) do
			origin[k] = nil
		end
		for _,part in pairs(ToolSelection) do
			local ff = GetFormFactor(part)
			origin[part] = {part.CFrame,part.Size,ff,FORMFACTOR_MULTIPLIER[face][ff]}
		end
		cinc = vars.Increment
		inc = Snap(cinc,1)
		if inc == 0 then
			inc = 1
		end
		DisplayInfo("Resize:",0)
	end)
	Event[tool].Drag = OverlayHandles.MouseDrag:connect(function(face,distance)
		local dis = distance*2*face_mult
		for part,info in pairs(origin) do
			local sz,ff,ffm = info[2],info[3],info[4]
			local mult
			if ff == FF_CUSTOM then
				mult = Snap(dis,cinc)
			else
				mult = Snap(dis,inc*ffm)
			end
			local mod = face_vec*mult
			local fsize = sz[face_size]
			mod = fsize + mult*face_mult < ffm and face_vec*((ffm-fsize)*face_mult) or mod
			Anchor(part)
			part.Size = sz + mod
			part.CFrame = info[1]
			Anchor(part,true)
			if part == first then DisplayInfo("Resize:",mod.magnitude) end
		end
		SetOverlay(first.Size,first.CFrame)
	end)
end

OnSelectionChanged[Tool] = function(tool,vars)
	local selection = GetFilteredSelection("BasePart")
	ToolSelection = selection
	WrapOverlay(selection[1],false)
end

OnToolDeselect[Tool] = function(tool,vars)
	Event[tool] = nil
	OverlayHandles.Visible = false
end
