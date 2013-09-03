-- for local dedicated servers or something

if CLIENT then
	concommand.Add("lua_openscript_sh", function(ply)

	end, function(str)

	end)

	concommand.Add("__cl_lua_openscript_sh", function(ply, _, args)
		if ply:IsSuperAdmin() then
			local path = args[1]

			if file.Exists(path, true) then
				include(path)
			end
			RunConsoleCommand("__sv_lua_openscript_sh", script)
		end
	end)
end

if SERVER then
	concommand.Add("__sv_lua_openscript_sh", function(ply, _, args)
		if ply:IsSuperAdmin() then
			local path = args[1]

			if file.Exists(path, true) then
				include(path)
			end
		end
	end)
end