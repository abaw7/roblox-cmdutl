local DeactivateAll

local Initialized = {}
local Active = {}
local Initialize = setmetatable({},{
	__newindex = function(t,name,func)
		if Initialized[name] ~= nil then
			rawset(t,name,function(...)
				func(...)
				Initialized[name] = true
			end)
		end
	end;
})
local Activate = setmetatable({},{
	__newindex = function(t,name,func)
		if Initialized[name] ~= nil then
			rawset(t,name,function(...)
				if Initialized[name] then
					DeactivateAll(name)
					func(...)
					Active[name] = true
				end
			end)
		end
	end;
})
local Deactivate = setmetatable({},{
	__newindex = function(t,name,func)
		if Initialized[name] ~= nil then
			rawset(t,name,function(...)
				if Initialized[name] then
					Active[name] = false
					func(...)
				end
			end)
		end
	end;
})

function DeactivateAll(n)
	for name,func in pairs(Deactivate) do
		if name ~= n and Active[name] == true then
			func()
		end
	end
end

local function Activator(name,button)
	if name and button then
		Initialized[name] = false
		Active[name] = false
		if button then
			button.Click:connect(function()
				if Initialized[name] then
					if Active[name] then
						Deactivate[name]()
					else
						Activate[name]()
					end
				else
					Initialize[name]()
					Activate[name]()
				end
			end)
		end
	end
end
