aowl.AddCommand("kick", function(ply, line, target, reason)
	local ent = easylua.FindEntity(target)

	if ent:IsPlayer() then


		-- clean them up at least this well...
		if cleanup and cleanup.CC_Cleanup then
			cleanup.CC_Cleanup(ent,"gmod_cleanup",{})
		end

		local rsn = reason or "byebye!!"

		aowlMsg("kick", tostring(ply).. " kicked " .. tostring(ent) .. " for " .. rsn)
		hook.Run("AowlTargetCommand", ply, "kick", ent, rsn)

		return ent:Kick(rsn or "byebye!!")

	end

	return false, aowl.TargetNotFound(target)
end, "developers")

local ok={d=true,m=true,y=true,s=true,h=true,w=true}
local function parselength_en(line) -- no months. There has to be a ready made version of this.

	local res={}

	line=line:Trim():lower()
	if tonumber(line)~=nil then
		res.m=tonumber(line)
	elseif #line>1 then
		line=line:gsub("%s","")
		for dat,what in line:gmatch'([%d]+)(.)' do

			if res[what] then return false,"bad format" end
			if not ok[what] then return false,("bad type: "..what) end
			res[what]=tonumber(dat) or -1

		end
	else
		return false,"empty string"
	end

	local len = 0
	local d=res
	local ok
	if d.y then	ok=true len = len + d.y*31556926 end
	if d.w then ok=true len = len + d.w*604800 end
	if d.d then	ok=true len = len + d.d*86400 end
	if d.h then	ok=true len = len + d.h*3600 end
	if d.m then	ok=true len = len + d.m*60 end
	if d.s then	ok=true len = len + d.s*1 end

	if not ok then return false,"nothing specified" end
	return len

end

aowl.AddCommand("ban", function(ply, line, target, length, reason)
	local id = easylua.FindEntity(target)
	local ip

	if banni then
		if not length then
			length = 60*10
		else
			local len,err = parselength_en(length)

			if not len then return false,"Invalid ban length: "..tostring(err) end

			length = len

		end

		if length==0 then return false,"invalid ban length" end

		local whenunban = banni.UnixTime()+length
		local ispl=id:IsPlayer() and not id:IsBot()
		if not ispl then
			if not banni.ValidSteamID(target) then
				return false,"invalid steamid"
			end
		end

		local banID = ispl and id:SteamID() or target
		local banName = ispl and id:Name() or target

		local banner = IsValid(ply) and ply:SteamID() or "Console"

		if IsValid(ply) and length >= 172800 then -- >= 2 days
			if not isstring(reason) or reason:len() < 10 then
				return false,"ban time over 2 days, specify a longer, descriptive ban reason"
			end
		end

		reason = reason or "Banned by admin"

		banni.Ban(	banID,
					banName,
					banner,
					reason,
					whenunban)

		hook.Run("AowlTargetCommand", ply, "ban", id, banName, banID, length, reason)
		return
	end


	if id:IsPlayer() then

		if id.SetRestricted then
			id:ChatPrint("You have been banned for " .. (reason or "being fucking annoying") .. ". Welcome to the ban bubble.")
			id:SetRestricted(true)
			return
		else
			ip = id:IPAddress():match("(.-):")
			id = id:SteamID()
		end
	else
		id = target
	end

	local t={"banid", tostring(length or 0), id}
	game.ConsoleCommand(table.concat(t," ")..'\n')

	--if ip then RunConsoleCommand("addip", length or 0, ip) end -- unban ip??
	timer.Simple(0.1, function()
		local t={"kickid",id, tostring(reason or "no reason")}
		game.ConsoleCommand(table.concat(t," ")..'\n')
		game.ConsoleCommand("writeid\n")
	end)
end, "developers")

aowl.AddCommand("unban", function(ply, line, target,reason)
	local id = easylua.FindEntity(target)

	if id:IsPlayer() then
		if banni then
			banni.UnBan(id:SteamID(),IsValid(ply) and ply:SteamID() or "Console",reason or "Admin unban")
			return
		end

		if id.SetRestricted then
			id:SetRestricted(false)
			return
		else
			id = id:SteamID()
		end
	else
		id = target

		if banni then

			local unbanned = banni.UnBan(target,IsValid(ply) and ply:SteamID() or "Console",reason or "Quick unban by steamid")
			if not unbanned then
				local extra=""
				if not banni.ValidSteamID(target) then
					extra="(invalid steamid?)"
				end
				return false,"unable to unban "..tostring(id)..extra
			end
			return
		end

	end

	local t={"removeid",id}
	game.ConsoleCommand(table.concat(t," ")..'\n')
	game.ConsoleCommand("writeid\n")
end, "developers")

aowl.AddCommand("baninfo", function(ply, line, target)
	if not banni then return false,"no banni" end

	local id = easylua.FindEntity(target)
	local ip

	local steamid
	if id:IsPlayer() then
		steamid=id:SteamID()
	else
		steamid=target
	end

	local d = banni.ReadBanData(steamid)
	if not d then return false,"no ban data found" end

	local t={
	["whenunban"] = 1365779132,
	["unbanreason"] = "Quick unban ingame",
	["banreason"] = "Quick ban ingame",
	["sid"] = "STEAM_0:1:33124674",
	["numbans"] = 1,
	["bannersid"] = "STEAM_0:0:13073749",
	["whenunbanned"] = 1365779016,
	["b"] = false,
	["whenbanned"] = 1365779012,
	["name"] = "β?μηζε ®",
	["unbannersid"] = "STEAM_0:0:13073749",
	}
	ply:ChatPrint("Ban info: "..tostring(d.name)..' ('..tostring(d.sid)..')')

	ply:ChatPrint("Ban:   "..(d.b and "YES" or "unbanned")..
		(d.numbans and ' (ban count: '..tostring(d.numbans)..')' or "")
			)

	if not d.b then
		ply:ChatPrint("UnBan reason: "..tostring(d.unbanreason))
		ply:ChatPrint("UnBan by "..tostring(d.unbannersid).." ( http://steamcommunity.com/profiles/"..tostring(util.SteamID64(d.unbannersid))..' )')
	end

	ply:ChatPrint("Ban reason: "..tostring(d.banreason))
	ply:ChatPrint("Ban by "..tostring(d.bannersid).." ( http://steamcommunity.com/profiles/"..tostring(util.SteamID64(d.bannersid))..' )')

	local time = d.whenbanned and banni.DateString(d.whenbanned)
	if time then
	ply:ChatPrint("Ban start:   "..tostring(time))
	end

	local time = d.whenunban and banni.DateString(d.whenunban)
	if time then
	ply:ChatPrint("Ban end:   "..tostring(time))
	end

	local time = d.whenunban and d.whenbanned and d.whenunban-d.whenbanned
	if time then
	ply:ChatPrint("Ban length: "..string.NiceTime(time))
	end

	local time = d.b and d.whenunban and d.whenunban-os.time()
	if time then
	ply:ChatPrint("Remaining: "..string.NiceTime(time))
	end

	local time = d.whenunbanned and banni.DateString(d.whenunbanned)
	if time then
	ply:ChatPrint("Unbanned: "..tostring(time))
	end

end, "players", true)

aowl.AddCommand("exit", function(ply, line, target, reason)
	local ent = easylua.FindEntity(target)

	if not ply:IsAdmin() and ply ~= ent then
		return false, "Since you are not an admin, you can only !exit yourself!"
	end

	if ent:IsPlayer() then
		hook.Run("AowlTargetCommand", ply, "exit", ent, reason)

		ent:SendLua([[RunConsoleCommand("gamemenucommand","quitnoconfirm")]])
		timer.Simple(0.09+(ent:Ping()*0.001), function()
			if not IsValid(ent) then return end
			ent:Kick("Exit: "..(reason and string.Left(reason, 128) or "Leaving"))
		end)

		return
	end

	return false, aowl.TargetNotFound(target)
end, "players")