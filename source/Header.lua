if _G.RegisterPlugin and not _G.RegisterPlugin(PROJECT_NAME) then return end

local Plugin = PluginManager():CreatePlugin()
local Toolbar = Plugin:CreateToolbar(PROJECT_NAME)
local ActivateGUIButton = Toolbar:CreateButton("",""..PROJECT_NAME.." Panel","application_go.png")
local ActivateMouseButton = Toolbar:CreateButton("","Selector","cursor.png")
local ActivateSettingsButton = Toolbar:CreateButton("","Settings","application_edit.png")
local ActivateHelpButton = Toolbar:CreateButton("","Help","help.png")

local CoreGui = game:GetService("CoreGui")
