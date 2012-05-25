--[==[
Lua Make
	Combines together multiple files and outputs the result to one or more files.

	When run, it attempts to run a file called "makefile.lua" in the current working directory.
	This file is used to process the files.

Functions:
	makefile.lua is run in an environment which can access the following functions:

	read ( string `path` ) ( string `var` )
		This function returns a function, such that "read()()" is valid syntax.
		Reads an input file to a variable.
		When called, `path` is opened and its contents are read.
		Then, the contents are appended to the variable `var` (created if it doesn't exist).
		`path` and/or `var` may be a table instead, containing a list of strings.
		
	write ( string `var` ) ( string `path` )
		This function returns a function, such that "write()()" is valid syntax.
		Writes variable `var` to `path`.
		`var` and/or `path` may be a table instead, containing a list of strings.
		
	clear ( )
		clears all variables in the environment.
	
	option ( name, value )
		Sets an option that changes the behavior of the program.
		If `value` is not specified, the current value of `name` will be returned.

	data ( string `path` )
		Returns a table of data parsed from the contents of `path`.

Options:
	write_path [string]
		If set to a non-empty string, the path of the input file will be added to the top of the file's contents in the output file.
		The string is used to format the path. It follows the conventions of string.format, with the first parameter being the path.
		Default value: "" (an empty string)
		Example: "--[[%s]]" (translates to "--[[(path here)]]")
	show_messages [bool]
		Sets whether normal messages will be written to output. Warnings are displayed regardless.
		Default value: true
	cmd_friendly [bool]
		Sets whether the program will pause for input when the program ends
		Default value: false

Data:
	The content of a file loaded via the `data` function must satisfy the following pattern:

		%s*(.-)%s*=%s*(.-)%s*;%s*

	Example:

		key1 = value1;
		key2 = value2;

Notes:
	Variables created by `read` are stored in the current environment.

	Paths may contain command environment variables, escaped between two "%" characters.
	These variables are equivalent to values returned by os.getenv.

	Strings can be concatenated with the "/" operator for slick path combining.
	Equivalent to (string).."/"..(string)

General notes about Lua's syntax sugar:
	When a function is called with 1 argument that is a string or table:
		foo"string"		--> foo("string")
		foo{"table"}	--> foo({"table"})

	When functions return functions:
		function foo(s)
			return function(t) print(s,t) end
		end

		foo()()			-- valid syntax
		foo"s"{1}		-- combinable with syntax sugar
		foo "s"		{1}	-- white-space is okay

		foo "s"
		{1}				-- line-breaks: also okay

		foo "s"
		({1})			-- line-breaks + parentheses = NOT okay!

Examples:
---- Two inputs to one output:

read [[C:/folder/input1.txt]]	'output'
read [[C:/folder/input2.txt]]	'output'
write 'output'					[[C:/folder/output.txt]]

---- Inputs as a table:

read {
	[[C:/folder/input1.txt]];
	[[C:/folder/input2.txt]];
}	'output'
write 'output' [[C:/folder/output.txt]]
		
---- One input to two outputs (as a table):

read [[C:/folder/input.txt]]	{'output1', 'output2'}
write 'output1'					[[C:/folder/output1.txt]]
write 'output2'					[[C:/folder/output2.txt]]
		
---- Env variables, Concatentation

folder = [[%APPDATA%/folder]]
read (folder/[[input.txt]])	'output'
write 'output'				(folder/[[output.txt]])

]==]

local makefile_name = "makefile.lua"
local options = {
	cmd_friendly	= {true;	'boolean';	true};
	show_messages	= {true;	'boolean';	true};
	write_path		= {"";		'string';	true};
}

local oprint = print
local warning_count = 0
local function print(message,warn)
	if warn or options.show_messages[1] then
		oprint(message)
	end
	if warn then
		warning_count = warning_count + 1
	end
end

local function pause()
	if options.cmd_friendly[1] then
		io.read()
	end
end

local function expand_path(path)
	return path:gsub("%%(.-)%%",os.getenv)
end

--------------------------------
--------------------------------
local env = {}
function option(name,value)
	if options[name] then
		local option = options[name]
		if value == nil then
			return option[1]
		elseif option[3] then
			if type(value) == option[2] then
				option[1] = value
			else
				print("WARNING: option: `"..name.."` expects a "..option[2].." (got a "..type(value)..")")
			end
		else
			print("WARNING: option: `"..name.."` cannot be modified")
		end
	else
		print("WARNING: option: `"..name.."` is not a valid option")
	end
end

function read(paths)
	if type(paths) == 'string' then paths = {paths} end
	if type(paths) ~= 'table' then
		print("WARNING: read: 1st argument must be a string or table",true)
		return
	end
	return function(vars)
		if type(vars) == 'string' then vars = {vars} end
		if type(vars) ~= 'table' then
			print("WARNING: read: 2nd argument must be a string or table",true)
			return
		end
		for i = 1,#paths do
			local path = paths[i]
			if type(path) == 'string' then
				path = expand_path(path)
				local file = io.open(path)
				if file then
					local content = file:read('*a')
					if #options.write_path[1] > 0 then
						content = options.write_path[1]:format(path).."\n" .. content
					end
					file:close()
					print("Read "..path)
					for o = 1,#vars do
						local var = vars[o]
						if type(var) == 'string' then
							if not env[var] then
								env[var] = ""
							end
							env[var] = env[var] .. content .. "\n"
							print("\tAppended to "..var)
						else
							print("\tWARNING: read: var["..o.."] is not a string",true)
						end
					end
				else
					print("WARNING: read: could not open `"..path.."`",true)
				end
			else
				print("WARNING: read: path["..i.."] is not a string",true)
			end
		end
	end
end

function write(vars)
	if type(vars) == 'string' then vars = {vars} end
	if type(vars) ~= 'table' then
		print("WARNING: write: 1st argument must be a string or table",true)
		return
	end
	return function(paths)
		if type(paths) == 'string' then paths = {paths} end
		if type(paths) ~= 'table' then
			print("WARNING: write: 2nd argument must be a string or table",true)
			return
		end
		for i = 1,#vars do
			local var = vars[i]
			if type(var) == 'string' then
				local content = env[var]
				if type(content) == 'string' then
					print("Writing "..var..":")
					for o = 1,#paths do
						local path = paths[o]
						if type(path) == 'string' then
							path = expand_path(path)
							local file = io.open(path,'w')
							if file then
								file:write(content)
								file:flush()
								file:close()
								print("\tWrote to "..path)
							else
								print("\tWARNING: write: could not open `"..path.."`",true)
							end
						else
							print("\tWARNING: write: path["..o.."] is not a string",true)
						end
					end
				else
					print("WARNING: write: `"..var.."` is not a valid variable",true)
				end
			else
				print("WARNING: write: var["..i.."] is not a string",true)
			end
		end
	end
end

function clear()
	for k in pairs(env) do
		env[k] = nil
	end
end

function data(path)
	if type(path) ~= 'string' then
		print("WARNING: data: 1st argument must be a string",true)
		return
	end
	local file = io.open(path)
	if file then
		local out = {}
		local content = file:read('*a')
		file:close()
		for k,v in content:gmatch("%s*(.-)%s*=%s*(.-)%s*;%s*") do
			out[k] = v
		end
		return out
	else
		print("WARNING: data: could not open `"..path.."`",true)
	end
end

setmetatable(env,{__index = _G})
--------------------------------
--------------------------------

local MakeFile,load_err = loadfile(makefile_name)
if not MakeFile then
	print("ERROR:"..load_err)
	pause()
	return
end

getmetatable("").__div = function(a,b)
	return tostring(a).."/"..tostring(b)
end

MakeFile()

print("Done ("..warning_count.." warnings)",true)
pause()
return
