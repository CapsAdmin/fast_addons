aowl.AddCommand("map", function(ply, line, map, time)
	if map and file.Exists("maps/"..map..".bsp", "GAME") then
		time = tonumber(time) or 10
		aowl.CountDown(time, "CHANGING MAP TO " .. map, function()
			game.ConsoleCommand("changelevel " .. map .. "\n")
		end)
	else
		return false, "map not found"
	end
end, "developers")

aowl.AddCommand("nextmap", function(ply, line, map)
	ply:ChatPrint("The next map is "..game.NextMap())
end, "players", true)

aowl.AddCommand("setnextmap", function(ply, line, map)
	if map and file.Exists("maps/"..map..".bsp", "GAME") then
		game.SetNextMap(map)
		ply:ChatPrint("The next map is now "..game.NextMap())
	else
		return false, "map not found"
	end
end, "developers")

aowl.AddCommand("maprand", function(player, line, map, time)
	time = tonumber(time) or 10
	local maps = file.Find("maps/*.bsp", "GAME")
	local candidates = {}

	for k, v in ipairs(maps) do
		if (not map or map=='') or v:find(map) then
			table.insert(candidates, v:match("^(.*)%.bsp$"):lower())
		end
	end

	if #candidates == 0 then
		return false, "map not found"
	end

	local map = table.Random(candidates)

	aowl.CountDown(tonumber(time), "CHANGING MAP TO " .. map, function()
		game.ConsoleCommand("changelevel " .. map .. "\n")
	end)
end, "developers")

aowl.AddCommand("maps", function(ply, line)
	local files = file.Find("maps/" .. (line or ""):gsub("[^%w_]", "") .. "*.bsp", "GAME")
	for _, fn in pairs( files ) do
		ply:ChatPrint(fn)
	end

	local msg="Total maps found: "..#files

	ply:ChatPrint(("="):rep(msg:len()))
	ply:ChatPrint(msg)
end, "developers")

aowl.AddCommand("resetall", function(player, line)
	aowl.CountDown(line, "RESETING SERVER", function()
		game.CleanUpMap()
		for k, v in ipairs(_G.player.GetAll()) do v:Spawn() end
	end)
end, "developers")

aowl.AddCommand({"clearserver", "cleanupserver", "serverclear", "cleanserver", "resetmap"}, function(player, line,time)
	if(tonumber(time) or not time) then
		aowl.CountDown(tonumber(time) or 5, "CLEANING UP SERVER", function()
			game.CleanUpMap()
		end)
	end
end,"developers")

aowl.AddCommand("cleanup", function(player, line,target)
	if target=="disconnected"  or target=="#disconnected"  then
		prop_owner.ResonanceCascade()
		return
	end

	local targetent = easylua.FindEntity(target)

	if not player:IsAdmin() then
		if targetent == player then
			if cleanup and cleanup.CC_Cleanup then
				cleanup.CC_Cleanup(player, "gmod_cleanup", {})
			end
			hook.Run("AowlTargetCommand", player, "cleanup", player)
			return
		end

		return false, "You cannot cleanup anyone but yourself!"
	end

	if targetent:IsPlayer() then
		if cleanup and cleanup.CC_Cleanup then
			cleanup.CC_Cleanup(targetent, "gmod_cleanup", {})
		end
		hook.Run("AowlTargetCommand", player, "cleanup", targetent)
		return
	end

	if not line or line == "" then
		aowl.CallCommand(player, "cleanupserver", "", {})
		return
	end

	return false, aowl.TargetNotFound(target)
end)

aowl.AddCommand("restart", function(player, line, seconds, reason)
	local time = math.max(tonumber(seconds) or 20, 1)

	aowl.CountDown(time, "RESTARTING SERVER" .. (reason and reason ~= "" and Format(" (%s)", reason) or ""), function()
		game.ConsoleCommand("changelevel " .. game.GetMap() .. "\n")
	end)
end, "developers")

aowl.AddCommand("reboot", function(player, line, target)
	local time = math.max(tonumber(line) or 20, 1)

	aowl.CountDown(time, "SERVER IS REBOOTING", function()
		BroadcastLua("LocalPlayer():ConCommand(\"disconnect; snd_restart; retry\")")

		timer.Simple(0.5, function()
			game.ConsoleCommand("shutdown\n")
			game.ConsoleCommand("_restart\n")
		end)
	end)
end, "developers")

aowl.AddCommand("uptime",function()
	PrintMessage(3,"Server uptime: "..string.NiceTime(SysTime())..' | Map uptime: '..string.NiceTime(CurTime()))
end)
