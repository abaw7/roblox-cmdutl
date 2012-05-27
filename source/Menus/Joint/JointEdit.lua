local Tool = AddTool("Joint","JointEdit")

do
	local jointOverlays = {}
	local function fix(j)
		local p = j.Part0
		local o = p.CFrame
		p.CFrame = p.CFrame * CFrame.new(0,1,0)
		p.CFrame = o
		local p = j.Part1
		local o = p.CFrame
		p.CFrame = p.CFrame * CFrame.new(0,1,0)
		p.CFrame = o
	end
	local colors = {
		BrickColor.new("Bright red");
		BrickColor.new("Bright blue");
		BrickColor.new("Bright yellow");
		BrickColor.new("Bright green");
		BrickColor.new("Bright orange");
		BrickColor.new("Bright violet");
		BrickColor.new("Black");
		BrickColor.new("White");
		BrickColor.new("Medium stone grey");
		BrickColor.new("Dark stone grey");
	}

	OnSelectionChanged[Tool] = function(tool,vars)
		for overlay in pairs(jointOverlays) do
			jointOverlays[overlay] = nil
			overlay:Destroy()
		end
		local selection = Selection:GetFiltered('BasePart')[1]
		if selection then
			local joints = GetFiltered("JointInstance",selection:GetChildren())
			for i,joint in pairs(joints) do
				local overlay = CreateOverlay()
				jointOverlays[overlay] = true
				local color = BrickColor.Random()
				overlay:NewAdorn("Handles",'Handles',{
					Style = "Movement";
					Color = colors[((i-1) % #colors)+1];--BrickColor.new("Bright blue");
				})
				overlay:NewAdorn("ArcHandles",'ArcHandles',{
					Color = colors[((i-1) % #colors)+1];--BrickColor.new("Bright blue");
				})
				overlay:SetParent(CoreGui)

				local oc0
				local oc1
				local inc = vars.MoveIncrement
				local ainc = vars.RotIncrement
				overlay.Adorn.Handles.MouseButton1Down:connect(function(face)
					oc0 = joint.C0
					oc1 = joint.C1
					inc = vars.MoveIncrement
				end)
				overlay.Adorn.Handles.MouseDrag:connect(function(face,distance)
					local rdis = Snap(distance,inc)
					local cf = CFrame.new(Vector3.FromNormalId(face)*rdis)
					joint.C0 = oc0 * cf
				--	joint.C1 = cf * oc1
				--	fix(joint)
					overlay.CFrame = joint.Part0.CFrame * joint.C0
				end)

				overlay.Adorn.ArcHandles.MouseButton1Down:connect(function(axis)
					oc0 = joint.C0
					oc1 = joint.C1
					ainc = vars.RotIncrement
				end)
				overlay.Adorn.ArcHandles.MouseDrag:connect(function(axis,angle)
					local rdis = Snap(math.deg(angle),ainc)
					local a = Vector3.FromAxis(axis)*math.rad(rdis)
					local cf = CFrame.Angles(a.x,a.y,a.z)
					joint.C0 = oc0 * cf
				--	joint.C1 = cf * oc1
				--	fix(joint)
					overlay.CFrame = joint.Part0.CFrame * joint.C0
				end)
				overlay.Size = Vector3.new(1,1,1)
				overlay.CFrame = joint.Part0.CFrame * joint.C0
			end
		end
	end

	OnToolDeselect[Tool] = function(tool,vars)
		for overlay in pairs(jointOverlays) do
			jointOverlays[overlay] = nil
			overlay:Destroy()
		end
	end
end
