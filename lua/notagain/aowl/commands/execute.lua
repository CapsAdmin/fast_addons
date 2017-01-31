TRANSFER_ID=TRANSFER_ID or 0
aowl.AddCommand("getfile",function(pl,line,target,name)
	if not GetNetChannel then return end
	name=name:Trim()
	if file.Exists(name,'GAME') then return false,"File already exists on server" end
	local ent = easylua.FindEntity(target)

	if ent:IsValid() and ent:IsPlayer() then
		local chan = GetNetChannel(ent)
		if chan then
			TRANSFER_ID=TRANSFER_ID+1
			chan:RequestFile(name,TRANSFER_ID)
			return
		end
	end

	return false, aowl.TargetNotFound(target)
end,"developers")

aowl.AddCommand("sendfile",function(pl,line,target,name)
	if not GetNetChannel then return end
	name=name:Trim()
	if not file.Exists(name,'GAME') then return false,"File does not exist" end

	if target=="#all" or target == "@" then
		for k,v in next,player.GetHumans() do
			TRANSFER_ID=TRANSFER_ID+1
			local chan=GetNetChannel(v)
			chan:SendFile(name,TRANSFER_ID)
			chan:SetFileTransmissionMode(false)
		end
		return
	end

	local ent = easylua.FindEntity(target)

	if ent:IsValid() and ent:IsPlayer() then
		local chan = GetNetChannel(ent)
		if chan then
			TRANSFER_ID=TRANSFER_ID+1
			chan:SendFile(name,TRANSFER_ID)
			chan:SetFileTransmissionMode(false)
			return
		end

	end

	return false, aowl.TargetNotFound(target)
end,"developers")

aowl.AddCommand("rcon", function(ply, line)
	line = line or ""

	if false and ply:IsUserGroup("developers") then
		for key, value in pairs(rcon_whitelist) do
			if not str:find(value, nil, 0) then
				return false, "cmd not in whitelist"
			end
		end

		for key, value in pairs(rcon_blacklist) do
			if str:find(value, nil, 0) then
				return false, "cmd is in blacklist"
			end
		end
	end

	game.ConsoleCommand(line .. "\n")

end, "developers")

aowl.AddCommand("cvar",function(pl,line,a,b)

	if b then
		local var = GetConVar(a)
		if var then
			local cur = var:GetString()
			RunConsoleCommand(a,b)
			timer.Simple(0.1,function()
				local new = var:GetString()
				pl:ChatPrint("ConVar: "..a..' '..cur..' -> '..new)
			end)
			return
		else
			return false,"ConVar "..a..' not found!'
		end
	end

	pcall(require,'cvar3')

	if not cvars.GetAllConVars then
		local var = GetConVar(a)
		if var then
			local val = var:GetString()
			if not tonumber(val) then val=string.format('%q',val) end

			pl:ChatPrint("ConVar: "..a..' '..tostring(val))
		else
			return false,"ConVar "..a..' not found!'
		end
	end
end,"developers")

aowl.AddCommand("cexec", function(ply, line, target, str,extra)
	local ent = easylua.FindEntity(target)

	if extra then return false,"too many parameters" end

	if ent:IsPlayer() then
		ent:SendLua(string.format("LocalPlayer():ConCommand(%q,true)", str))
		Msg("[cexec] ") print("from ",ply," to ",ent) print(string.format("LocalPlayer():ConCommand(%q,true)", str))
		hook.Run("AowlTargetCommand", ply, "cexec", ent, str)
		return
	end

	return false, aowl.TargetNotFound(target)
end, "developers")

aowl.AddCommand({"retry", "rejoin"}, function(ply, line, target)
	target = target and easylua.FindEntity(target) or nil

	if not IsValid(target) or not target:IsPlayer() then
		target = ply
	end

	target:SendLua("LocalPlayer():ConCommand('retry')")
end)


aowl.AddCommand("god",function(player, line)
	local newdmgmode = tonumber(line) or (player:GetInfoNum("cl_dmg_mode", 0) == 1 and 3 or 1)
	newdmgmode = math.floor(math.Clamp(newdmgmode, 1, 4))
	player:SendLua([[
		pcall(include, "autorun/translation.lua") local L = translation and translation.L or function(s) return s end
		LocalPlayer():ConCommand('cl_dmg_mode '.."]]..newdmgmode..[[")
		if (]]..newdmgmode..[[) == 1 then
			chat.AddText(L"God mode enabled.")
		elseif (]]..newdmgmode..[[) == 3 then
			chat.AddText(L"God mode disabled.")
		else
			chat.AddText(string.format(L"Damage mode set to ".."%d.", (]]..newdmgmode..[[)))
		end
	]])
end, "players", true)