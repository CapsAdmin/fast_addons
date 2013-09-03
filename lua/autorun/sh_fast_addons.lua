local function MakeEnum(filename)
	_G["FAST_ADDON_" .. filename:Left(-5):upper()] = true
end


local function load_files(dir)
	for _, luafile in pairs((file.Find(dir .. "/*.lua", "LUA"))) do
		local path = string.format(dir .. "/%s", luafile)

		MakeEnum(luafile)
		include(path)
		
		if SERVER then
			AddCSLuaFile(path)
		end
	end

	for _, luafile in pairs((file.Find(dir .. "/client/*.lua", "LUA"))) do
		local path = string.format(dir .. "/client/%s", luafile)
		
		if CLIENT then 
			MakeEnum(luafile) 
			include(path)
		end

		if SERVER then
			AddCSLuaFile(path)
		end
	end

	if SERVER then
		for _, luafile in pairs((file.Find(dir .. "/server/*.lua", "LUA"))) do
			MakeEnum(luafile)
			include(string.format(dir .. "/server/%s", luafile))
		end
	end
end

load_files("helpers")
load_files("fast_addons")