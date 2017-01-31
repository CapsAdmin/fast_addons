local aowl = {}
_G.aowl = aowl

local luadata = requirex("luadata")
local easylua = requirex("easylua")

local USERSFILE = "aowl/users.txt"

timer.Simple(1, function() hook.Run("AowlInitialized") end)
CreateConVar("aowl_hide_ranks", "1", FCVAR_REPLICATED)

aowl.Prefix			= "[!|/|%.]" -- a pattern
aowl.StringPattern	= "[\"|']" -- another pattern
aowl.ArgSepPattern	= "[,]" -- would you imagine that yet another one
aowl.EscapePattern	= "[\\]" -- holy shit another one! holy shit again they are all teh same length! Unintentional! I promise!!1
team.SetUp(1, "default", Color(68, 112, 146))

function aowlMsg(cmd, line)
	if hook.Run("AowlMessage", cmd, line) ~= false then
		MsgC(Color(51,255,204), "[aowl]"..(cmd and ' '..tostring(cmd) or "")..' ')
		MsgN(line)
	end
end

function player.GetDevelopers()
	local developers = {}
	for id, ply in pairs(player.GetAll()) do
		if ply:IsAdmin() and not ply:IsBot() then
			table.insert(developers, ply)
		end
	end
	return developers
end


do -- goto locations --
	aowl.GotoLocations = aowl.GotoLocations or {}

	aowl.GotoLocations["spawn"] = function(p) p:Spawn() end
	aowl.GotoLocations["respawn"] = aowl.GotoLocations["spawn"]
end

do -- commands
	function aowl.CallCommand(ply, cmd, line, args)
		if ply.IsBanned and ply:IsBanned() and not ply:IsAdmin() then return end

		local steamid

		if type(ply) == "string" and ply:find("STEAM_") then
			steamid = ply
		end

		local ok, msg = pcall(function()
			cmd = aowl.cmds[cmd]
			if cmd and (steamid and aowl.CheckUserGroupFromSteamID(steamid, cmd.group) or (not ply:IsValid() or ply:CheckUserGroupLevel(cmd.group))) then

				if steamid then ply = NULL end

				local tstart = SysTime()
				local allowed, reason = hook.Call("AowlCommand", GAMEMODE, cmd, ply, line, unpack(args))

				if allowed ~= false then
					easylua.Start(ply)
					local isok
					isok, allowed, reason = xpcall(cmd.callback,debug.traceback,ply, line, unpack(args))
					local tstop = SysTime()
					easylua.End()
					local d  = tstop-tstart

					if d<0 or d>0.2 then
						Msg"[Aowl] "print(ply,"command",cmd.cmd,"took",math.Round(d*1000) .. ' ms')
					end

					if not isok then
						ErrorNoHalt("Aowl cmd "..tostring(cmd and cmd.cmd).." failed:\n    "..tostring(allowed)..'\n')
						reason = "INTERNAL ERROR"
						allowed = false
					end
				end

				if ply:IsValid() then
					if reason then
						aowl.Message(ply, reason, allowed==false and 'error' or 'generic')
					end

					if allowed==false then
						ply:EmitSound("buttons/button8.wav", 100, 120)
					end
				end
			end
		end)
		if not ok then
			ErrorNoHalt(msg)
			return msg
		end
	end

	function aowl.ConsoleCommand(ply, _, args, line)
		if aowl.cmds[args[1]] then
			local cmd = args[1]
			table.remove(args, 1)
			_G.COMMAND = true
				aowl.CallCommand(ply, cmd, table.concat(args, " "), args)
			_G.COMMAND = nil
		end
	end

	function aowl.SayCommand(ply, txt)
		if string.find(string.sub(txt, 1, 1), aowl.Prefix) then
			local cmd = string.match(txt, aowl.Prefix .. "(.-) ") or
						string.match(txt, aowl.Prefix .. "(.+)") or ""
			local line = string.match(txt, aowl.Prefix .. ".- (.+)")

			cmd = string.lower(cmd)

			-- execute command
			local aowlcmd = aowl.cmds[cmd]
			if aowlcmd then
				_G.CHAT = true
					aowl.CallCommand(ply, cmd, line, line and aowl.ParseArgs(line) or {})
				_G.CHAT = nil

				if aowlcmd.hidechat then return "" end
			end
		end
	end

	if SERVER then
		concommand.Add("aowl", aowl.ConsoleCommand)

		hook.Add("PlayerSay", "aowl_say_cmd", aowl.SayCommand)
	end

	function aowl.AddCommand(cmd, callback, group, hidechat)
		if istable(cmd) then
			for k,v in pairs(cmd) do
				aowl.AddCommand(v,callback,group,hidechat)
			end
			return
		end
		aowl.cmds = aowl.cmds or {}
		aowl.cmds[cmd] = {callback = callback, group = group or "players", cmd = cmd, hidechat = hidechat }

		hook.Run("AowlCommandAdded", cmd, callback, group, hidechat)
	end

	function aowl.TargetNotFound(target)
		return string.format("could not find: %q", target or "<no target>")
	end
end


do -- util
	function aowl.ParseArgs(str)
		local ret={}
		local InString=false
		local strchar=""
		local chr=""
		local escaped=false
		for i=1,#str do
			local char=str[i]
			if(escaped) then chr=chr..char escaped=false continue end
			if(char:find(aowl.StringPattern) and not InString and not escaped) then
				InString=true
				strchar=char
			elseif(char:find(aowl.EscapePattern)) then
				escaped=true
				continue
			elseif(InString and char==strchar) then
				table.insert(ret,chr:Trim())
				chr=""
				InString=false
			elseif(char:find(aowl.ArgSepPattern) and not InString) then
				if(chr~="") then
				    table.insert(ret,chr)
				    chr=""
				end
			else
					chr=chr..char
				end
		end
		if(chr:Trim():len()~=0) then table.insert(ret,chr) end

		return ret
	end

	function aowl.AvatarForSteamID(steamid, callback)
		local commid = util.SteamIDTo64(steamid)
		http.Fetch("http://steamcommunity.com/profiles/" .. commid .. "?xml=1", function(content, size)
			local ret = content:match("<avatarIcon><!%[CDATA%[(.-)%]%]></avatarIcon>")
			callback(ret)
		end)
	end

	local NOTIFY = {
		GENERIC	= 0,
		ERROR	= 1,
		UNDO	= 2,
		HINT	= 3,
		CLEANUP	= 4,
	}
	function aowl.Message(ply, msg, type, duration)
		ply = ply or all
		duration = duration or 5
		ply:SendLua(string.format(
			"local s=%q notification.AddLegacy(s,%u,%s) MsgN(s)",
			"aowl: " .. msg,
			NOTIFY[(type and type:upper())] or NOTIFY.GENERIC,
			duration
		))
	end

	aowl.AddCommand("message", function(_,_, msg, duration, type)
		if not msg then
			return false, "no message"
		end

		type = type or "generic"
		duration = duration or 15

		aowl.Message(nil, msg, "generic", duration)
		all:EmitSound("buttons/button15.wav")

	end, "developers")
end


do -- countdown
	if SERVER then
		aowl.AddCommand({"abort", "stop"}, function(player, line)
			aowl.AbortCountDown()
		end, "developers")


		local function Shake()
			for k,v in pairs(player.GetAll()) do
				util.ScreenShake(v:GetPos(), math.Rand(.1,1.5), math.Rand(1,5), 2, 500)
			end
		end

		function aowl.CountDown(seconds, msg, callback, typ)
			seconds = seconds and tonumber(seconds) or 0

			local function timeout()
				umsg.Start("__countdown__")
					umsg.Short(-1)
				umsg.End()
				if callback then
					aowlMsg("countdown", "'"..tostring(msg).."' finished, calling "..tostring(callback))
					callback()
				else
					if seconds<1 then
						aowlMsg("countdown", "aborted")
					else
						aowlMsg("countdown", "'"..tostring(msg).."' finished. Initated without callback by "..tostring(source))
					end
				end
			end


			if seconds > 0.5 then
				timer.Create("__countdown__", seconds, 1, timeout)
				timer.Create("__countbetween__", 1, math.floor(seconds), Shake)

				umsg.Start("__countdown__")
					umsg.Short(typ or 2)
					umsg.Short(seconds)
					umsg.String(msg)
				umsg.End()
				local date = os.prettydate and os.prettydate(seconds) or seconds.." seconds"
				aowlMsg("countdown", "'"..msg.."' in "..date )
			else
				timer.Remove "__countdown__"
				timer.Remove "__countbetween__"
				timeout()
			end
		end

		aowl.AbortCountDown = aowl.CountDown
	end

	if CLIENT then
		local L = L or function(a) return a end
		local CONFIG = {}

		CONFIG.TargetTime 	= 0
		CONFIG.Counting 	= false
		CONFIG.Warning 		= ""
		CONFIG.PopupText	= {}
		CONFIG.PopupPos		= {0,0}
		CONFIG.LastPopup	= CurTime()
		CONFIG.Popups		= { "HURRY!", "FASTER!", "YOU WON'T MAKE IT!", "QUICKLY!", "GOD YOU'RE SLOW!", "DID YOU GET EVERYTHING?!", "ARE YOU SURE THAT'S EVERYTHING?!", "OH GOD!", "OH MAN!", "YOU FORGOT SOMETHING!", "SAVE SAVE SAVE" }
		CONFIG.StressSounds = { Sound("vo/ravenholm/exit_hurry.wav"), Sound("vo/npc/Barney/ba_hurryup.wav"), Sound("vo/Citadel/al_hurrymossman02.wav"), Sound("vo/Streetwar/Alyx_gate/al_hurry.wav"), Sound("vo/ravenholm/monk_death07.wav"), Sound("vo/coast/odessa/male01/nlo_cubdeath02.wav") }
		CONFIG.NextStress	= CurTime()
		CONFIG.NumberSounds = { Sound("npc/overwatch/radiovoice/one.wav"), Sound("npc/overwatch/radiovoice/two.wav"), Sound("npc/overwatch/radiovoice/three.wav"), Sound("npc/overwatch/radiovoice/four.wav"), Sound("npc/overwatch/radiovoice/five.wav"), Sound("npc/overwatch/radiovoice/six.wav"), Sound("npc/overwatch/radiovoice/seven.wav"), Sound("npc/overwatch/radiovoice/eight.wav"), Sound("npc/overwatch/radiovoice/nine.wav") }
		CONFIG.LastNumber	= CurTime()

		surface.CreateFont(
			"aowl_restart",
			{
				font		= "Roboto Bk",
				size		= 60,
				weight		= 1000,
			}
		)
		-- local gradient_u = Material("vgui/gradient-u.vtf")
		local function DrawWarning()
			if CurTime()-3 > CONFIG.TargetTime then
				CONFIG.Counting = false
				if CONFIG.Sound then
					CONFIG.Sound:FadeOut(2)
				end
				hook.Remove("HUDPaint", "__countdown__")
			end

			surface.SetFont("aowl_restart")
			local messageWidth = surface.GetTextSize(CONFIG.Warning)

			surface.SetDrawColor(255, 50, 50, 100 + (math.sin(CurTime() * 3) * 80))
			surface.DrawRect(0, 0, ScrW(), ScrH())

			-- Countdown bar
			surface.SetDrawColor(Color(0,220,200,255))
			surface.DrawRect((ScrW() - messageWidth)/2, 175, messageWidth * math.max(0, (CONFIG.TargetTime-CurTime())/(CONFIG.TargetTime-CONFIG.StartedCount) ), 20)
			surface.SetDrawColor(Color(0,0,0,30))
			surface.DrawRect((ScrW() - messageWidth)/2, 175+20/2, messageWidth * math.max(0, (CONFIG.TargetTime-CurTime())/(CONFIG.TargetTime-CONFIG.StartedCount) ), 20/2)
			surface.SetDrawColor(color_black)
			surface.DrawOutlinedRect((ScrW() - messageWidth)/2, 175, messageWidth, 20)

			-- Countdown message
			surface.SetFont("aowl_restart")
			surface.SetTextColor(Color(50, 50, 50, 255))

			local y = 200
			for _, messageLine in ipairs(string.Split(CONFIG.Warning, "\n")) do
				local w, h = surface.GetTextSize(messageLine)
				w = w or 56
				surface.SetTextPos((ScrW() / 2) - w / 2, y)
				surface.DrawText(messageLine)
				y = y + h
			end

			-- Countdown timer
			local timeRemaining = CONFIG.TargetTime - CurTime()
			timeRemaining = math.max(timeRemaining, 0)
			local timeRemainingString = string.format("%02d:%02d:%03d",
				math.floor (timeRemaining / 60),
				math.floor (timeRemaining % 60),
				math.floor ((timeRemaining * 1000) % 1000)
			)

			local w = surface.GetTextSize(timeRemainingString)

			surface.SetTextPos((ScrW() / 2) - w / 2, y)
			surface.DrawText(timeRemainingString)

			surface.SetTextColor(255, 255, 255, 255)
			if(CurTime() - CONFIG.LastPopup > 0.5) then
				for i = 1, 3 do
					CONFIG.PopupText[i] = table.Random(CONFIG.Popups)
					local w, h = surface.GetTextSize(CONFIG.PopupText[i])
					CONFIG.PopupPos[i] = {math.random(1, ScrW() - w), math.random(1, ScrH() - h) }
				end
				CONFIG.LastPopup = CurTime()
			end

			if(CurTime() > CONFIG.NextStress) then
				LocalPlayer():EmitSound(CONFIG.StressSounds[math.random(1, #CONFIG.StressSounds)], 80, 100)
				CONFIG.NextStress = CurTime() + math.random(1, 2)
			end

			local num = math.floor(CONFIG.TargetTime - CurTime())
			if(CONFIG.NumberSounds[num] ~= nil and CurTime() - CONFIG.LastNumber > 1) then
				CONFIG.LastNumber = CurTime()
				LocalPlayer():EmitSound(CONFIG.NumberSounds[num], 511, 100)
			end

			for i = 1, 3 do
				surface.SetTextPos(CONFIG.PopupPos[i][1], CONFIG.PopupPos[i][2])
				surface.DrawText(CONFIG.PopupText[i])
			end
		end

		usermessage.Hook("__countdown__", function(um)
			local typ = um:ReadShort()
			local time = um:ReadShort()

			CONFIG.Sound = CONFIG.Sound or CreateSound(LocalPlayer(), Sound("ambient/alarms/siren.wav"))


			if typ  == -1 then
				CONFIG.Counting = false
				CONFIG.Sound:FadeOut(2)
				hook.Remove("HUDPaint", "__countdown__")
				return
			end

			CONFIG.Sound:Play()
			CONFIG.StartedCount = CurTime()
			CONFIG.TargetTime = CurTime() + time
			CONFIG.Counting = true

			hook.Add("HUDPaint", "__countdown__", DrawWarning)

			if typ == 0 then
				CONFIG.Warning = "SERVER IS RESTARTING THE LEVEL\nSAVE YOUR PROPS AND HIDE THE CHILDREN!"
			elseif typ == 1 then
				CONFIG.Warning = string.format("SERVER IS CHANGING LEVEL TO %s\nSAVE YOUR PROPS AND HIDE THE CHILDREN!", um:ReadString():upper())
			elseif typ == 2 then
				CONFIG.Warning = um:ReadString()
			end
		end)
	end
end

do -- groups

	do -- team setup
		function team.GetIDByName(name)
			do return 3003 end

			for id, data in pairs(team.GetAllTeams()) do
				if data.Name == name then
					return id
				end
			end
			return 1
		end
	end

	local list =
	{
		players = 1,
		--moderators = 2,
		emeritus = 2, -- 3
		developers = 3, -- 4,
		owners = math.huge,
	}

	local alias =
	{
		user = "players",
		default = "players",
		admin = "developers",
		moderators = "developers",
		superadmin = "owners",
		superadmins = "owners",
		administrator = "developers",
	}

	local META = FindMetaTable("Player")

	function META:CheckUserGroupLevel(name)

		--Console?
		if not self:IsValid() then return true end


		name = alias[name] or name
		local ugroup=self:GetUserGroup()

		local a = list[ugroup]
		local b = list[name]

		return a and b and a >= b
	end

	function META:ShouldHideAdmins()
		return self.hideadmins or false
	end

	function META:IsAdmin()

		--Console?
		if not self:IsValid() then return true end

		if self:ShouldHideAdmins() then
			return false
		end
		return self:CheckUserGroupLevel("developers")
	end

	function META:IsSuperAdmin()

		--Console?
		if not self:IsValid() then return true end

		if self:ShouldHideAdmins() then
			return false
		end
		return self:CheckUserGroupLevel("developers")
	end

	function META:TeleportingBlocked()
		return hook.Run("CanPlyTeleport",self)==false
	end

	function META:IsUserGroup(name)
		name = alias[name] or name
		name = name:lower()

		local ugroup = self:GetUserGroup()

		return ugroup == name or false
	end

	function META:GetUserGroup()
		if self:ShouldHideAdmins() then
			return "players"
		end
		return self:GetNetworkedString("UserGroup"):lower()
	end

	team.SetUp(1, "players", 		Color(68, 	112, 146))
	--[[
	team.SetUp(2, "developers", 	Color(147, 63,  147))
	team.SetUp(3, "owners", 		Color(207, 110, 90))
	team.SetUp(4, "emeritus", 		Color(98, 107, 192))
	]]
	team.SetUp(3002, "Players", Color(68, 112, 146))

	if SERVER then
		local dont_store =
		{
			"moderators",
			"players",
			"users",
		}

		local function clean_users(users, _steamid)

			for name, group in pairs(users) do
				name = name:lower()
				if not list[name] then
					users[name] = nil
				else
					for steamid in pairs(group) do
						if steamid:lower() == _steamid:lower() then
							group[steamid] = nil
						end
					end
				end
			end

			return users
		end

		local function safe(str)
			return str:gsub("{",""):gsub("}","")
		end

		function META:SetUserGroup(name, force)
			name = name:Trim()
			name = alias[name] or name

			self:SetTeam(9003)
			self:SetNetworkedString("UserGroup", name)
			--[[
			umsg.Start("aowl_join_team")
				umsg.Entity(self)
			umsg.End()
			--]]

			if force == false or #name == 0 then return end

			name = name:lower()

			if force or (not table.HasValue(dont_store, name) and list[name]) then
				local users = luadata.ReadFile(USERSFILE)
					users = clean_users(users, self:SteamID())
					users[name] = users[name] or {}
					users[name][self:SteamID()] = self:Nick():gsub("%A", "") or "???"
				file.CreateDir("aowl")
				luadata.WriteFile(USERSFILE, users)

				aowlMsg("rank", string.format("Changing %s (%s) usergroup to %s",self:Nick(), self:SteamID(), name))
			end
		end

		function aowl.GetUserGroupFromSteamID(id)
			for name, users in pairs(luadata.ReadFile(USERSFILE)) do
				for steamid, nick in pairs(users) do
					if steamid == id then
						return name, nick
					end
				end
			end
		end

		function aowl.CheckUserGroupFromSteamID(id, name)
			local group = aowl.GetUserGroupFromSteamID(id)

			if group then
				name = alias[name] or name

				local a = list[group]
				local b = list[name]

				return a and b and a >= b
			end

			return false
		end

		local users_file_date,users_file_cache=-2,nil
		hook.Add("PlayerSpawn", "PlayerAuthSpawn", function(ply)

			ply:SetUserGroup("players")

			if game.SinglePlayer() or ply:IsListenServerHost() then
				ply:SetUserGroup("owners")
				return
			end

			local timestamp = file.Time(USERSFILE, "DATA")
			timestamp = timestamp and timestamp > 0 and timestamp or 0/0


			if users_file_date ~= timestamp then
				users_file_cache = luadata.ReadFile( USERSFILE ) or {}
				users_file_date = timestamp
			end

			for name, users_file_cache in pairs(users_file_cache) do
				for steamid in pairs(users_file_cache) do
					if ply:SteamID() == steamid or ply:UniqueID() == steamid then
						if ply:ShouldHideAdmins() then
							ply:SetUserGroup("players",false)
						else
							ply:SetUserGroup(name, false)
						end
					end
				end
			end
		end)

		aowl.AddCommand("rank", function(player, line, target, rank)
			local ent = easylua.FindEntity(target)

			if ent:IsPlayer() and rank then
				rank = rank:lower():Trim()
				ent:SetUserGroup(rank, true) -- rank == "players") -- shouldn't it force-save no matter what?
				hook.Run("AowlTargetCommand", player, "rank", ent, rank)
			end
		end, "owners")

		aowl.AddCommand("administrate",function(pl,line, yesno)
			local administrate=util.tobool(yesno)
			if administrate then
				pl.hideadmins=nil
			elseif pl:IsAdmin() then
				pl.hideadmins=true
			end
		end)
	end
end

for _, file_name in ipairs((file.Find("notagain/aowl/commands/*", "LUA"))) do
	include("notagain/aowl/commands/" .. file_name)
end

return aowl