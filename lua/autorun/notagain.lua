AddCSLuaFile()
notagain = {}
notagain = notagain or {}
notagain.loaded_libraries = notagain.loaded_libraries or {}
notagain.directories = notagain.directories or {}

local root_dir = "notagain"

do
	local addon_tries = {
		"libraries/%s.lua",
		"libraries/client/%s.lua",
		"libraries/server/%s.lua",

		"autorun/%s.lua",
		"autorun/client/%s.lua",
		"autorun/server/%s.lua",

		"%s.lua",
	}

	local other_tries = {
		"/%s.lua",
		function(name) return _G[name] end,
		function(name) return require(name) end,
	}

	local function load_path(path)
		local lua = file.Read(path, "LUA")

		if not lua then
			return nil, "unable to find " .. path
		end

		local var = CompileString(lua, path, false)

		if type(var) ~= "string" then
			return var
		end

		return nil, var
	end

	local function try(tries, name, dir)
		local func
		local errors = ""

		for _, try in ipairs(tries) do
			local err

			if type(try) == "function" then
				local res, ret = pcall(try, name)

				if res == true then
					if ret then
						return ret
					else
						err = ""
					end
				else
					err = ret
				end
			else
				res, err = load_path(dir .. try:format(name))

				if res then
					return res
				end
			end

			errors = errors .. err .. "\n"
		end

		return func, errors
	end

	function notagain.GetLibrary(name, ...)
		if notagain.loaded_libraries[name] then
			return notagain.loaded_libraries[name]
		end

		local func
		local errors = ""

		if not func then
			for _, addon_dir in ipairs(notagain.directories) do
				local found, err = try(addon_tries, name, addon_dir .. "/")

				if found then
					func = found
				else
					errors = errors .. err
				end
			end
		end

		if not func then
			local res, msg = load_path(root_dir .. "/" .. name .. "/init.lua")
			if res then
				func = res
			else
				errors = errors .. msg
			end
		end

		if not func then
			local found, err = try(other_tries, name, "")

			if found then
				func = found
			else
				errors = errors .. err
			end
		end

		if func == nil then
			return nil, errors
		end

		local ok, ret = pcall(func, ...)

		if ok == false then
			return nil, ret
		end

		local lib = ret

		notagain.loaded_libraries[name] = lib

		return lib
	end
end

function notagain.UnloadLibrary(name)
	notagain.loaded_libraries[name] = nil
end

function notagain.Load()
	do
		local _, dirs = file.Find(root_dir .. "/*", "LUA")

		for i, addon_dir in ipairs(dirs) do
			dirs[i] = root_dir .. "/" .. addon_dir
		end

		notagain.directories = dirs
	end

	for _, addon_dir in ipairs(notagain.directories) do
		do -- autorun
			local dir = addon_dir .. "/autorun/"

			for _, name in pairs((file.Find(dir .. "*.lua", "LUA"))) do
				local path = dir .. name
				include(path)
				if SERVER then
					AddCSLuaFile(path)
				end
			end

			for _, name in pairs((file.Find(dir .. "client/*.lua", "LUA"))) do
				local path = dir .. "client/" .. name

				if CLIENT then
					include(path)
				end

				if SERVER then
					AddCSLuaFile(path)
				end
			end

			if SERVER then
				for _, name in pairs((file.Find(dir .. "server/*.lua", "LUA"))) do
					include(dir .. "server/" .. name)
				end
			end
		end

		if SERVER then -- libraries
			local dir = addon_dir .. "/libraries/"

			for _, name in pairs((file.Find(dir .. "*.lua", "LUA"))) do
				AddCSLuaFile(dir .. name)
			end

			for _, name in pairs((file.Find(dir .. "client/*.lua", "LUA"))) do
				AddCSLuaFile(dir .. "client/" .. name)
			end
		end
	end
end


function _G.requirex(name, ...)
	local res, err = notagain.GetLibrary(name, ...)
	if res == nil then error(err, 2) end
	return res
end

notagain.Load()