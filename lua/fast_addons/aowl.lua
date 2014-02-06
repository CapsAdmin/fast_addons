assert(FAST_ADDON_EASYLUA, "aowl requires easylua!")
assert(FAST_ADDON_LUADATA, "aowl requires luadata!")
pcall(include, "autorun/translation.lua") local L = translation and translation.L or function(s) return s end

aowl = aowl or {} local s = aowl

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

local function compare(a, b)

	if a == b then return true end
	if a:find(b, nil, true) then return true end
	if a:lower() == b:lower() then return true end
	if a:lower():find(b:lower(), nil, true) then return true end

	return false
end

do -- goto locations --
	aowl.GotoLocations = aowl.GotoLocations or {}

	aowl.GotoLocations["spawn"] = function(p) p:Spawn() end

	-- gm_construct_flatgrass

	aowl.GotoLocations["colorroom@gm_construct_flatgrass"] = Vector(8715.5224609375, 2555.8327636719, -511.96875)
	aowl.GotoLocations["controlroom@gm_construct_flatgrass"] = Vector(-5312.5810546875, 8344.3154296875, -1007.96875)
	aowl.GotoLocations["flatgrass@gm_construct_flatgrass"] = Vector(-2886.7067871094, -3076.2197265625, 32.031253814697)
	aowl.GotoLocations["mirror@gm_construct_flatgrass"] = Vector(8895.765625, 3703.7534179688, -623.96875)
	aowl.GotoLocations["orange@gm_construct_flatgrass"] = Vector(11413.28125, 4391.462890625, -887.96875)
	aowl.GotoLocations["pool@gm_construct_flatgrass"] = Vector(11210.390625, -2581.1203613281, -399.96875)
	aowl.GotoLocations["sky@gm_construct_flatgrass"] = Vector(-3036.8767089844, -3089.6533203125, 8320.03125)
	aowl.GotoLocations["station@gm_construct_flatgrass"] = Vector(-9255.388671875, 8885.408203125, -927.96875)
	aowl.GotoLocations["trainyard@gm_construct_flatgrass"] = Vector(-593.68011474609, 3478.9331054688, -399.96875)
	aowl.GotoLocations["water@gm_construct_flatgrass"] = Vector(13869.692382812, -7203.4404296875, 0.03125)
end

--[[do -- teams
	timer.Simple(0, function()
		local META = FindMetaTable("Player")
		luadata.AccessorFunc(META, "AowlTeamName", "aowl_team_color", true, "default")
		luadata.AccessorFunc(META, "AowlTeamColor", "aowl_team_name", true, Color(68, 112, 146))

		local cache = {}

		function META:GetAowlTeamUID()
			local name = self:GetAowlTeamName()
			local c = self:GetAowlTeamColor()

			local crc = util.CRC(name..c.r..c.g..c.b)

			return crc
		end

		function aowl.UpdateTeamColors()
			for key, ply in pairs(player.GetAll()) do
				local id = ply:GetAowlTeamUID()%10000
				team.SetUp(id, ply:GetAowlTeamName(), ply:GetAowlTeamColor(), true)
				if SERVER then
					ply:SetTeam(id)
				end
			end
		end

		--timer.Create("setup_aowl_teams", 1, 0, aowl.UpdateTeamColors)
	end)
end]]

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
	
	function aowl.SteamIDToCommunityID(id)
		if id == "BOT" or id == "NULL" or id == "STEAM_ID_PENDING" or id == "UNKNOWN" then
			return 0
		end

		local parts = id:Split(":")
		local a, b = parts[2], parts[3]

		return tostring("7656119" .. 7960265728 + a + (b*2))
	end

	function aowl.CommunityIDToSteamID(id)
		local s = "76561197960"
		if id:sub(1, #s) ~= s then
			return "UNKNOWN"
		end

		local c = tonumber( id )
		local a = id % 2 == 0 and 0 or 1
		local b = (c - 76561197960265728 - a) / 2

		return "STEAM_0:" .. a .. ":" .. (b+2)
	end
	
	function aowl.AvatarForSteamID(steamid, callback)
		local commid = aowl.SteamIDToCommunityID(steamid)
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

				local allowed, reason = hook.Call("AowlCommand", GAMEMODE, cmd, ply, line, unpack(args))

				if allowed ~= false then
					easylua.Start(ply)
					allowed, reason = cmd.callback(ply, line, unpack(args))
					easylua.End()
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

	function aowl.CMDInternal(ply, _, args, line)
		if aowl.cmds[args[1]] then
			local cmd = args[1]
			table.remove(args, 1)
			_G.COMMAND = true
				aowl.CallCommand(ply, cmd, table.concat(args, " "), args)
			_G.COMMAND = nil
		end
	end

	function aowl.SayCommand(ply, txt)
		if txt:sub(1, 1):find(aowl.Prefix) then
			local cmd = txt:match(aowl.Prefix.."(.-) ") or txt:match(aowl.Prefix.."(.+)") or ""
			local line = txt:match(aowl.Prefix..".- (.+)")

			cmd = cmd:lower()

			if aowl.cmds[cmd] then
				_G.CHAT = true
					aowl.CallCommand(ply, cmd, line, line and aowl.ParseArgs(line) or {})
				_G.CHAT = nil
			end
		end
	end

	if SERVER then
		concommand.Add("aowl", aowl.CMDInternal)

		hook.Add("PlayerSay", "aowl_say_cmd", aowl.SayCommand)
	end

	function aowl.AddCommand(cmd, callback, group)
		if istable(cmd) then
			for k,v in pairs(cmd) do
				aowl.AddCommand(v,callback,group)
			end
			return
		end
		aowl.cmds = aowl.cmds or {}
		aowl.cmds[cmd] = {callback = callback, group = group or "players", cmd = cmd}
	end
end

do -- added commands
	function aowl.TargetNotFound(target)
		return string.format("could not find: %q", target or "<no target>")
	end
	
	do -- kill cmd
		if CLIENT then
			usermessage.Hook("aowl_kill", function(umr)
				local ply = umr:ReadEntity()
				local vel = umr:ReadLong()
				local angvel = umr:ReadLong()
								
				if ply:IsValid() then
					local id = "find_rag_" .. ply:EntIndex()
					
					timer.Create(id, 0, 100, function()
						if not ply:IsValid() then return end
						local rag = ply:GetRagdollEntity() or NULL
						if rag:IsValid() then
							local phys = rag:GetPhysicsObject() or NULL
							if phys:IsValid() then
								local vel = ply:GetAimVector() * vel
								local angvel = VectorRand() * angvel
								for i = 0, rag:GetPhysicsObjectCount()-1 do
									local phys = rag:GetPhysicsObjectNum(i)	or NULL
									if phys:IsValid() then
										phys:SetVelocity(vel)
										phys:AddAngleVelocity(angvel)
									end
								end
								phys:SetVelocity(vel)
								phys:AddAngleVelocity(angvel)
								timer.Remove(id)
							end
						end
					end)
				end
			end)
		end

		if SERVER then
			aowl.AddCommand({"suicide", "die", "kill", "wrist"},function(ply, line, vel, angvel)
				if ply.last_rip and CurTime() - ply.last_rip < 0.05 then
					return
				end

				ply.last_rip = CurTime()

				vel = tonumber(vel)
				angvel = tonumber(angvel)

				ply:Kill()
				
				if vel then
					umsg.Start("aowl_kill")
						umsg.Entity(ply)
						umsg.Long(vel)
						umsg.Long(angvel or 0)
					umsg.End()
				end
			end)
		end
	end
	
	if SERVER then
		do -- move
			aowl.AddCommand("message", function(_,_, msg, duration, type)
				if not msg then
					return false, "no message"
				end

				type = type or "generic"
				duration = duration or 15

				aowl.Message(nil, msg, "generic", duration)
				all:EmitSound("buttons/button15.wav")

			end, "developers")
	

			local t = {start=nil,endpos=nil,mask=MASK_PLAYERSOLID,filter=nil}
			local function IsStuck(ply)

				t.start = ply:GetPos()
				t.endpos = t.start
				t.filter = ply
				
				return util.TraceEntity(t,ply).StartSolid
				
			end
						
			-- helper
			local function SendPlayer( from, to )
				if not to:IsInWorld() then
					return false
				end
				
				local times=16
				
				local anginc=360/times
				
				
				local ang=to:GetVelocity():Length2D()<1 and (to:IsPlayer() and to:GetAimVector() or to:GetForward()) or -to:GetVelocity()
				ang.z=0
				ang:Normalize()
				ang=ang:Angle()
				
				local pos=to:GetPos()
				local frompos=from:GetPos()
				
				local origy=ang.y
				
				for i=0,times do
					ang.y=origy+(-1)^i*(i/times)*180
					
					from:SetPos(pos+ang:Forward()*64+Vector(0,0,10))
					if not IsStuck(from) then return true end
				end
				
				from:SetPos(frompos)
				return false
				
			end

			local function Goto(ply,line,target)
				if not ply:Alive() then ply:Spawn() end
				if not line then return end
				local x,y,z = line:match("(%-?%d+%.*%d*)[,%s]%s-(%-?%d+%.*%d*)[,%s]%s-(%-?%d+%.*%d*)")

				if x and y and z and ply:CheckUserGroupLevel("moderators") then
					ply:SetPos(Vector(tonumber(x),tonumber(y),tonumber(z)))
					return
				end

				for k,v in pairs(aowl.GotoLocations) do
					local loc, map = k:match("(.*)@(.*)")
					if target == k or (target and map and loc:lower():Trim():find(target) and string.find(game.GetMap(), "^" .. map)) then
						if type(v) == "Vector" then
							if ply:InVehicle() then
								ply:ExitVehicle()
							end
							ply:SetPos(v)
							return
						else
							return v(ply)
						end
					end
				end

				local ent = easylua.FindEntity(target)

				if IsValid(ent) and ent:GetClass() == "coin" then
					return false, "nope"
				end
							
				if ent:IsValid() and ent ~= ply and (ply:CheckUserGroupLevel("developers") or not ent.GotoDisallowed) then
					-- shameless hack
					if (ent.in_rpland or ent.died_in_rpland) and !ply.Unrestricted and !ply:IsAdmin() then
						return false,"Target is in RP Area, cannot goto"
					end
					
					local dir = ent:GetAngles(); dir.p = 0; dir.r = 0; dir = (dir:Forward() * -100)
					
					local oldpos = ply:GetPos()+Vector(0,0,32)
					sound.Play("npc/dog/dog_footstep"..math.random(1,4)..".wav",oldpos)
					
					if not SendPlayer(ply,ent) then
						if ply:InVehicle() then
							ply:ExitVehicle()
						end
						ply:SetPos(ent:GetPos() + dir)
						ply:DropToFloor()
					end
					
					aowlMsg("goto", tostring(ply) .." -> ".. tostring(ent))
					
					if ply.UnStuck then
						timer.Simple(1,function()
							if IsValid(ply) then
								ply:UnStuck()
							end
						end)
					end
					
					ply:SetEyeAngles((ent:EyePos() - ply:EyePos()):Angle())
					ply:EmitSound("buttons/button15.wav")
					--ply:EmitSound("npc/dog/dog_footstep_run"..math.random(1,8)..".wav")
					ply:SetVelocity(-ply:GetVelocity())
					
					hook.Run("AowlTargetCommand", ply, "goto", ent)
					return
				end

				return false, aowl.TargetNotFound(target)
			end


			local function aowl_goto(ply, line, target)
				if ply.IsBanned and ply:IsBanned() then return false, "access denied" end
				ply.aowl_tpprevious = ply:GetPos()
				return Goto(ply,line,target)
			end
			aowl.AddCommand({"goto","warp","go"}, aowl_goto)
	
-- todo: rate limit?
			aowl.AddCommand("tp", function(pl,line,target,...)
				if target and #target>1 then
					return aowl_goto(pl,line,target,...)
				end
				-- shameless hack
				if pl.in_rpland and not pl.Unrestricted and not pl:IsAdmin() then
					return false,"No teleporting in RP!"
				end
				
				local start = pl:GetPos()+Vector(0,0,1)
				local pltr=pl:GetEyeTrace()

				local endpos = pltr.HitPos
				local wasinworld=util.IsInWorld(start)

				local diff=start-endpos
				local len=diff:Length()
				len=len>100 and 100 or len
				diff:Normalize()
				diff=diff*len
				--start=endpos+diff

				if not wasinworld and util.IsInWorld(endpos-pltr.HitNormal*120) then
					pltr.HitNormal=-pltr.HitNormal
				end
				start=endpos+pltr.HitNormal*120

				if math.abs(endpos.z-start.z)<2 then
					endpos.z=start.z
					--print"spooky match?"
				end
						
				local tracedata = {start=start,endpos=endpos}
						
				tracedata.filter = pl
				tracedata.mins = Vector( -16, -16, 0 )
				tracedata.maxs = Vector( 16, 16, 72 )
				tracedata.mask = MASK_SHOT_HULL
				local tr = util.TraceHull( tracedata )

				if tr.StartSolid or (wasinworld and not util.IsInWorld(tr.HitPos)) then
					tr = util.TraceHull( tracedata )
					tracedata.start=endpos+pltr.HitNormal*3
					
				end
				if tr.StartSolid or (wasinworld and not util.IsInWorld(tr.HitPos)) then
					tr = util.TraceHull( tracedata )
					tracedata.start=pl:GetPos()+Vector(0,0,1)
					
				end
				if tr.StartSolid or (wasinworld and not util.IsInWorld(tr.HitPos)) then
					tr = util.TraceHull( tracedata )
					tracedata.start=endpos+diff
					
				end
				if tr.StartSolid then return false,"unable to perform teleportation without getting stuck" end
				if not util.IsInWorld(tr.HitPos) and wasinworld then return false,"couldnt teleport there" end

				if pl:GetVelocity():Length() > 10 * math.sqrt(GetConVarNumber("sv_gravity")) then
					pl:EmitSound("physics/concrete/boulder_impact_hard".. math.random(1, 4) ..".wav")
					pl:SetVelocity(-pl:GetVelocity())
				end

				pl.aowl_tpprevious = pl:GetPos()
				pl:SetPos(tr.HitPos)
				pl:EmitSound"ui/freeze_cam.wav"
			end)
	
	
			aowl.AddCommand("send", function(ply, line, who,where)
				local who = easylua.FindEntity(who)

				if who:IsPlayer() then
					who.aowl_tpprevious = who:GetPos()
					return Goto(who,"",where)
				end

				return false, aowl.TargetNotFound(target)
				
			end,"developers")
			
	
			aowl.AddCommand("uptime",function()
				PrintMessage(3,"Server uptime: "..string.NiceTime(SysTime())..' | Map uptime: '..string.NiceTime(CurTime()))
			end)
					
			local function sleepall()
				for k,ent in pairs(ents.GetAll()) do
					for i=0,ent:GetPhysicsObjectCount()-1 do
						local pobj = ent:GetPhysicsObjectNum(i)
						if pobj and not pobj:IsAsleep() then
							pobj:Sleep()
						end
					end
				end
			end

			aowl.AddCommand("sleep",function()
				sleepall()
				timer.Simple(0,sleepall)
			end,"developers")

			aowl.AddCommand({"penetrating", "pen"}, function(ply,line)
				for k,ent in pairs(ents.GetAll()) do
					for i=0,ent:GetPhysicsObjectCount()-1 do
						local pobj = ent:GetPhysicsObjectNum(i)
						if pobj and pobj:IsPenetrating() then
							Msg"[Aowl] "print("Penetrating object: ",ent,"Owner: ",ent:CPPIGetOwner())
							if line and line:find"stop" then
								pobj:EnableMotion(false)
							end
							continue
						end
					end
				end
			end,"developers")
			
			aowl.AddCommand("togglegoto", function(ply, line) -- This doesn't do what it says. Lol.
				if not ply.GotoDisallowed then
					ply.GotoDisallowed = true
					aowlMsg("togglegoto", tostring(ply) .." has disabled !goto")
				else
					ply.GotoDisallowed = false
					aowlMsg("togglegoto", tostring(ply) .." has re-enabled !goto")
				end
			end, "developers")

			aowl.AddCommand("gotoid", function(ply, line, target)
				if not target or string.Trim(target)=='' then return false end
				local function loading(s)
					ply:SendLua(string.format("local l=notification l.Kill'aowl_gotoid'l.AddProgress('aowl_gotoid',%q)",s))
				end
				local function kill(s,typ)
					if not IsValid(ply) then return false end
					ply:SendLua[[notification.Kill'aowl_gotoid']]
					if s then aowl.Message(ply,s,typ or 'error') end
				end
				
				local url
				local function gotoip(str)
					if not ply:IsValid() then return end
					local ip = str:match[[In%-Game.-Garry's Mod.-steam://connect/([0-9]+%.[0-9]+%.[0-9]+%.[0-9]+%:[0-9]+).-Join]]
					if ip then
						kill(string.format("found %q from %q", ip, target),"generic")
						aowl.Message(ply,'connecting in 5 seconds.. press jump to abort','generic')

						local uid = tostring(ply) .. "_aowl_gotoid"
						timer.Create(uid,5,1,function()
							hook.Remove('KeyPress',uid)
							if not IsValid(ply) then return end
							
							kill'connecting!'
							ply:Cexec("connect " .. ip)
						end)

						hook.Add("KeyPress", uid, function(_ply, key)
							if key == IN_JUMP and _ply == ply then
								timer.Remove(uid)
								kill'aborted gotoid!'

								hook.Remove('KeyPress',uid)
							end
						end)
					else
						kill(string.format('could not fetch the server ip from %q',target))
					end
				end
				local function gotoid()
					if not ply:IsValid() then return end

					loading'looking up steamid ...'

					http.Fetch(url, function(str)
						gotoip(str)
					end,function(err)
						kill(string.format('load error: %q',err or ''))
					end)
				end

				if tonumber(target) then
					url = ("http://steamcommunity.com/profiles/%s/?xml=1"):format(target)
					gotoid()
				elseif target:find("STEAM") then
					url = ("http://steamcommunity.com/profiles/%s/?xml=1"):format(aowl.SteamIDToCommunityID(target))
					gotoid()
				else
					loading'looking up player ...'

					http.Post(string.format("http://steamcommunity.com/actions/Search?T=Account&K=%q", target:gsub("%p", function(char) return "%" .. ("%X"):format(char:byte()) end)), "", function(str)
						gotoip(str)
					end,function(err)
						kill(string.format('load error: %q',err or ''))
					end)
				end
			end)
			
			aowl.AddCommand("back", function(ply, line, target)
				local ent = ply:CheckUserGroupLevel("developers") and target and easylua.FindEntity(target) or ply
				
				if not IsValid(ent) then
					return false, "Invalid player"
				end
				if not ent.aowl_tpprevious or not type( ent.aowl_tpprevious ) == "Vector" then
					return false, "Nowhere to send you"
				end
				local prev = ent.aowl_tpprevious
				ent.aowl_tpprevious = ent:GetPos()
				ent:SetPos( prev )
				hook.Run("AowlTargetCommand", ply, "back", ent)
			end )

			aowl.AddCommand("bring", function(ply, line, target, yes)
				
				local ent = easylua.FindEntity(target)
			
				if ent:IsValid() and ent ~= ply then
					if ply:CheckUserGroupLevel("developers") or (ply.IsBanned and ply:IsBanned()) then
					
						if ent:IsPlayer() and not ent:Alive() then ent:Spawn() end
						ent = (ent.GetVehicle and ent:GetVehicle():IsValid()) and ent:GetVehicle() or ent
						if ent:IsPlayer() and ent:InVehicle() then
							ent:ExitVehicle()
						end
						
						ent.aowl_tpprevious = ent:GetPos()
						ent:SetPos(ply:GetEyeTrace().HitPos + (ent:IsVehicle() and Vector(0, 0, ent:BoundingRadius()) or Vector(0, 0, 0)))
						ent[ent:IsPlayer() and "SetEyeAngles" or "SetAngles"](ent, (ply:EyePos() - ent:EyePos()):Angle())
						
						aowlMsg("bring", tostring(ply) .." <- ".. tostring(ent))
					end
					return
				end

				if CrossLua and yes then
					local sane = target:gsub(".", function(a) return "\\" .. a:byte() end )
					local ME = ply:UniqueID()

					CrossLua([[return easylua.FindEntity("]] .. sane .. [["):IsPlayer()]], function(ok)
						if not ok then
							-- oh nope
						elseif ply:CheckUserGroupLevel("developers") then
							CrossLua([=[local ply = easylua.FindEntity("]=] .. sane .. [=[")
								ply:ChatPrint[[Teleporting Thee upon player's request]]
								timer.Simple(3, function()
									ply:SendLua([[LocalPlayer():ConCommand("connect ]=] .. GetConVarString"ip" .. ":" .. GetConVarString"hostport" .. [=[")]])
								end)

								return ply:UniqueID()
							]=], function(uid)
								hook.Add("PlayerInitialSpawn", "crossserverbring_"..uid, function(p)
									if p:UniqueID() == uid then
										ply:ConCommand("aowl goto " .. ME)

										hook.Remove("PlayerInitialSpawn", "crossserverbring_"..uid)
									end
								end)

								timer.Simple(180, function()
									hook.Remove("PlayerInitialSpawn", "crossserverbring_"..uid)
								end)
							end)

							-- oh found
						end
					end)

					return false, aowl.TargetNotFound(target) .. ", looking on another servers"
				elseif CrossLua and not yes then
					return false, aowl.TargetNotFound(target) .. ", try CrossServer Bring?? !bring <name>,yes"
				else
					return false, aowl.TargetNotFound(target)
				end
			end)
			
			aowl.AddCommand("fullupdate",function(pl) 
				PrintMessage(HUD_PRINTTALK,pl:Name()..' fixed his unable to move after join/weapons not showing after join bug')
				pl:SendLua[[LocalPlayer():ConCommand("record removeme",true)RunConsoleCommand'stop']]
			end)
			
			do -- weapon ban
				local META = FindMetaTable("Player")
				luadata.AccessorFunc(META, "WeaponRestricted", "weapon_restricted", false, false)

				local white_list =
				{
					weapon_physgun = true,
					gmod_tool = true,
					none = true,
					hands = true,
					gmod_camera = true,
				}

				timer.Create("weapon_restrictions", 0.5, 0, function()
					for _, ply in pairs(player.GetAll()) do
						if ply:GetWeaponRestricted()  then
							for key, wep in pairs(ply:GetWeapons()) do
								if not white_list[wep:GetClass()] then
									wep:Remove()
								end
							end
						end
					end
				end)

				aowl.AddCommand("banweapons", function(ply, line, target)
					local ent = easylua.FindEntity(target)

					if ent:IsValid() and ent:IsPlayer() then
						ent:SetWeaponRestricted(true)
						return
					end

					return false, aowl.TargetNotFound(target)
				end, "developers")
				
				aowl.AddCommand("unbanweapons", function(ply, line, target)
					local ent = easylua.FindEntity(target)

					if ent:IsValid() and ent:IsPlayer() then
						ent:SetWeaponRestricted(false)
						return
					end

					return false, aowl.TargetNotFound(target)
				end, "developers")
			end
			
			aowl.AddCommand("spawn", function(ply, line, target)
				local ent = ply:CheckUserGroupLevel("developers") and target and easylua.FindEntity(target) or ply

				if ent:IsValid() then
					ent.aowl_tpprevious = ent:GetPos()
					ent:Spawn()
					aowlMsg("spawn", tostring(ply).." spawned ".. (ent==ply and "self" or tostring(ent)))
				end
			end)
						
			aowl.AddCommand("drop",function(ply)
				if ply:GetActiveWeapon():IsValid() then
					ply:DropWeapon(ply:GetActiveWeapon())
				end
			end)

			do -- give weapon
				local prefixes = {
					"",
					"weapon_",
					"weapon_mare_",
				}

				aowl.AddCommand("give", function(ply, line, target, weapon, ammo1, ammo2)
					local ent = easylua.FindEntity(target)
					if not ent:IsPlayer() then return false, aowl.TargetNotFound(target) end
					if not isstring(weapon) or weapon == "#wep" then
						local wep = ply:GetActiveWeapon()
						if IsValid(wep) then
							weapon = wep:GetClass()
						else
							return false,"Invalid weapon"
						end
					end
					ammo1 = tonumber(ammo1) or 0
					ammo2 = tonumber(ammo2) or 0
					for _,prefix in ipairs(prefixes) do
						local class = prefix .. weapon
						if ent:HasWeapon(class) then ent:StripWeapon(class) end
						local wep = ent:Give(class)
						if IsValid(wep) then
							wep.Owner = wep.Owner or ent
							ent:SelectWeapon(class)
							if wep.GetPrimaryAmmoType then
								ent:GiveAmmo(ammo1,wep:GetPrimaryAmmoType())
							end
							if wep.GetSecondaryAmmoType then
								ent:GiveAmmo(ammo2,wep:GetSecondaryAmmoType())
							end
							return
						end
					end
					return false, "Couldn't find " .. weapon
				end, "developers")
			end

			aowl.AddCommand({"resurrect", "respawn", "revive"}, function(ply, line, target)
				-- shameless hack
				if ply.died_in_rpland and not ply.Unrestricted and not ply:IsAdmin() then
					return false,"Just respawn and !goto rp, sigh!"
				end
				
				local ent = ply:CheckUserGroupLevel("developers") and target and easylua.FindEntity(target) or ply
				if ent:IsValid() and ent:IsPlayer() and not ent:Alive() then
					local pos,ang = ent:GetPos(),ent:EyeAngles()
					ent:Spawn()
					ent:SetPos(pos) ent:SetEyeAngles(ang)
				end
			end)
		end

		do -- cheats


			aowl.AddCommand("cheats",function(pl,line, target, yesno)
				if not GetNetChannel and not NetChannel and not CNetChan then 
					pcall(require,'cvar3')
				end
				local targets = not yesno and pl or easylua.FindEntity(target)
				if not targets or not IsValid(targets) then return false,"no target found" end
		
				local cheats=(not line or line=="") or util.tobool(yesno or target)
				
				if pl.SetConVar then
					targets:SetConVar("sv_cheats",cheats and "1" or "0")
				elseif pl.ReplicateData then
					targets:ReplicateData("sv_cheats",cheats and "1" or "0")
				else
					return false,"Cannot set cheats (module cvar3 not found)"
				end
			end,"developers")

			aowl.AddCommand("leavemealone", function()
				easylua.StartEntity("lua_npc_wander")

					function ENT:Initialize()
						self:Remove()
					end

				easylua.EndEntity(true, true)

				return false, "Cheat activated"
			end, "developers")

		end
		do -- restrictions
			aowl.AddCommand({"restrictions"},function(pl,line, target, yesno)
				local ent = easylua.FindEntity(target)
				local restrictions=true
				if yesno or target then
					restrictions = util.tobool(yesno or target)
				end
				pl=yesno and ent or pl
				if not IsValid(pl) then return false,"nope" end
				local unrestricted  = not restrictions
				if unrestricted  then
					ErrorNoHalt(
[[................./´¯/) 
...............,/¯../ 
............../..../ 
......../´¯/'...'/´¯¯`·¸  
...../'/.../..../......./¨¯\ Bitch Mode
...('(...´...´.... ¯~/'...')  Enabled
....\.................'...../ For
.....''...\.......... _.·´ 
.......\..............(  ]]..tostring(pl)..
[[

.........\.............\...]])
				end
				pl.Unrestricted = unrestricted
			end,"developers")

		end
		
		do -- administrate

			aowl.AddCommand("administrate",function(pl,line, yesno)
				local administrate=util.tobool(yesno)
				if administrate then
					pl.hideadmins=nil
				elseif pl:IsAdmin() then
					pl.hideadmins=true
				end
			end)

		end
		
		do -- admin
			aowl.AddCommand("exit", function(ply, line, target, reason)
				local ent = easylua.FindEntity(target)

				if ent:IsPlayer() then
					hook.Run("AowlTargetCommand", ply, "exit", ent)
					return ent:SendLua("LocalPlayer():ConCommand('exit')")
				end

				return false, aowl.TargetNotFound(target)
			end, "developers")
			
			aowl.AddCommand("bot",function(pl,cmd,what)
				if not what or what=="" then
					game.ConsoleCommand"bot\n"
				elseif what=="kick" then
					for k,v in pairs(player.GetBots()) do
						v:Kick"bot kick"
					end
				elseif what=="zombie" then
					game.ConsoleCommand("bot_zombie 1\n")
				elseif what=="zombie 0" or what=="nozombie" then
					game.ConsoleCommand("bot_zombie 0\n")
				elseif what=="follow" or what=="mimic" then
					game.ConsoleCommand("bot_mimic "..pl:EntIndex().."\n")
				elseif what=="nofollow" or what=="nomimic" or what=="follow 0" or what=="mimic 0" then
					game.ConsoleCommand("bot_mimic 0\n")
				end
			end,"developers")
			
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

			
			local ok={d=true,m=true,y=true,s=true,h=true}
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
					local ispl=id:IsPlayer()
					if not ispl then	
						if not banni.ValidSteamID(target) then
							return false,"invalid steamid"
						end
					end
					
					local banID = ispl and id:SteamID() or target
					local banName = ispl and id:Name() or target
					
					local banner = IsValid(ply) and ply:SteamID() or "Console"
					reason = reason or "Banned by admin"
					
					banni.Ban(	banID,
								banName,
								banner,
								reason,
								whenunban)
								
					hook.Run("AowlTargetCommand", ply, "ban", banName, banID, length, reason)
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

			aowl.AddCommand({"whyban", "baninfo"}, function(ply, line, target)
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
				
			end)


			aowl.AddCommand("getfile",function(pl,line,target,name)
				if not GetNetChannel then return end
				name=name:Trim()
				if file.Exists(name,'GAME') then return false,"File already exists on server" end
				local ent = easylua.FindEntity(target)

				if ent:IsValid() and ent:IsPlayer() then
					local chan = GetNetChannel(ent)
					if chan then
						chan:RequestFile(name,math.random(1024,2048))
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
						GetNetChannel(v):SendFile(name,1024+1)
					end
					return
				end
				
				local ent = easylua.FindEntity(target)

				if ent:IsValid() and ent:IsPlayer() then
					local chan = GetNetChannel(ent)
					if chan then
						chan:SendFile(name,math.random(1024,2048))
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
						timer.Simple(0,function() timer.Simple(0,function()
							local new = var:GetString()
							pl:ChatPrint("ConVar: "..a..' '..cur..' -> '..new)
						end)end)
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

			aowl.AddCommand("cexec", function(ply, line, target, ...)
				local ent = easylua.FindEntity(target)

				if ent:IsPlayer() then
					local str = table.concat({...}, " ")
					ent:SendLua(string.format("LocalPlayer():ConCommand(%q)", str))
					hook.Run("AowlTargetCommand", ply, "cexec", ent, str)
				end

				return false, aowl.TargetNotFound(target)
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
				
				local ent = easylua.FindEntity(target)
				if ent:IsPlayer() then
					if cleanup and cleanup.CC_Cleanup then
						cleanup.CC_Cleanup(ent,"gmod_cleanup",{})
					end
					hook.Run("AowlTargetCommand", player, "cleanup", ent)
					return
				end

				return false, aowl.TargetNotFound(target)
			end, "developers")

			aowl.AddCommand({"tidy", "clearcrap", "clearorphan", "garbagecollect", "gc", "cleanupdisconnected"}, function()
				prop_owner.ResonanceCascade()
			end,"developers")
						
			aowl.AddCommand("owner", function (ply, line, target)
				if not banni then return false,"no info" end
				
				local id = easylua.FindEntity(target)
				if not IsValid(id) then return false,"not found" end
					
				ply:ChatPrint(tostring(id)..' owned by '..tostring(id:CPPIGetOwner() or "no one"))
				
			end )
			
			
			
			aowl.AddCommand({"abort", "stop"}, function(player, line)
				aowl.AbortCountDown()
			end, "developers")

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
			end, "players")
			
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
			

			aowl.AddCommand({"retry", "rejoin"}, function(player, line)
				player:SendLua("LocalPlayer():ConCommand(\"retry\")")
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
			end)

			aowl.AddCommand({"name","nick","setnick","setname","nickname"}, function(player, line)
				if line then
					line=line:Trim()
					if(line=="") or line:gsub(" ","")=="" then
						line = nil
					end
					if line and #line>40 then
						if not line.ulen or line:ulen()>40 then
							return false,"my god what are you doing"
						end
					end
				end
				timer.Create("setnick"..player:UserID(),1,1,function()
					if IsValid(player) then
						player:SetNick(line)
					end
				end)
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
						game.ConsoleCommand("exit\n")
						game.ConsoleCommand("shutdown\n")
					end)
				end)
			end, "developers")

			aowl.AddCommand("rank", function(player, line, target, rank)
				local ent = easylua.FindEntity(target)

				if ent:IsPlayer() and rank then
					rank = rank:lower():Trim()
					ent:SetUserGroup(rank, true) -- rank == "players") -- shouldn't it force-save no matter what?
					hook.Run("AowlTargetCommand", player, "rank", ent, rank)
				end
			end, "owners")

			--[[
			aowl.AddCommand("jointeam", function(ply, line, name, r,g,b)

				local ent = easylua.FindEntity(name)

				if not (r and g and b) and ent:IsPlayer() then
					ply:SetAowlTeamName(ent:GetAowlTeamName())
					ply:SetAowlTeamColor(ent:GetAowlTeamColor())
				else
					if name and #name > 220 then
						return false, "team name is too long"
					end

					if not name then
						name = ply:GetAowlTeamName()
					end

					r = tonumber(r)
					g = tonumber(g)
					b = tonumber(b)

					if not r and g == nil and b == nil then
						local c = ply:GetAowlTeamColor()
						r = c.r
						g = c.g
						b = c.b
					end

					ply:SetAowlTeamName(name)

					if r and g == nil and b == nil then
						ply:SetAowlTeamColor(HSVToColor(r, 0.53333336114883, 0.57254904508591))
					else
						ply:SetAowlTeamColor(Color(r,g,b))
					end
				end

				aowl.UpdateTeamColors()

				timer.Simple(0.1, function()
					umsg.Start("aowl_join_team")
						umsg.Entity(ply)
					umsg.End()
				end)
			end)]]
		end
	end

	aowl.AddCommand("decals",function() all:ConCommand('r_cleardecals') end,"developers")
	
	do -- fakedie
		local Tag="fakedie"
		if SERVER then
			util.AddNetworkString(Tag)
			aowl.AddCommand("fakedie", function(pl, cmd, killer, icon, swap)
				
				local victim=pl:Name()
				local killer=killer or ""
				local icon=icon or ""
				local killer_team=-1
				local victim_team=pl:Team()
				if swap and #swap>0 then
					victim,killer=killer,victim
					victim_team,killer_team=killer_team,victim_team
				end
				net.Start(Tag)
					net.WriteString(victim or "")
					net.WriteString(killer or "")
					net.WriteString(icon or "")
					net.WriteFloat(killer_team or -1)
					net.WriteFloat(victim_team or -1)
				net.Broadcast()
			end,"developers")
		else
			net.Receive(Tag,function(len)
				local victim=net.ReadString()
				local killer=net.ReadString()
				local icon=net.ReadString()
				local killer_team=net.ReadFloat()
				local victim_team=net.ReadFloat()
				GAMEMODE:AddDeathNotice( killer, killer_team, icon, victim, victim_team )
			end)
		end
	end

	do -- weldlag
		aowl.AddCommand("weldlag",function(pl,line,minresult)
			local t={}
			for k,v in pairs(ents.GetAll()) do
				local count=v:GetPhysicsObjectCount()
				if count==0 or count>1 then continue end
				local p=v:GetPhysicsObject()
				
				if not p:IsValid() then continue end
				if p:IsAsleep() then continue end
				if not p:IsMotionEnabled() then
					--if constraint.FindConstraint(v,"Weld") then -- Well only count welds since those matter the most, most often
						t[v]=true
					--end
				end
			end
			local lags={}
			for ent,_ in pairs(t) do
				local found
				for lagger,group in pairs(lags) do
					if ent==lagger or group[ent] then
						found=true
						break
					end
				end
				if not found then
					lags[ent]=constraint.GetAllConstrainedEntities(ent) or {}
				end
			end
			for c,cents in pairs(lags) do
				local count,lagc=1,t[k] and 1 or 0
				local owner
				for k,v in pairs(cents) do
					count=count+1
					if t[k] then
						lagc=lagc+1
					end
					if not owner and IsValid(k:CPPIGetOwner()) then
						owner=k:CPPIGetOwner()
					end
				end
			
				if count>(tonumber(minresult) or 5) then
					for k,all in pairs(player.GetHumans()) do
						PrintMessage(3,"Found lagging contraption with "..lagc..'/'..count.." lagging ents (Owner: "..tostring(owner)..")")
					end
				end
			end
		end)
	
	end
		
	do -- physenv
		local Tag="aowl_physenv"
		if SERVER then
			util.AddNetworkString(Tag)
			
			aowl.AddCommand("physenv",function(pl)
				net.Start(Tag)
					net.WriteTable(physenv.GetPerformanceSettings())
				net.Send(pl)
			end)
		end

		net.Receive(Tag,function(len,who) -- SHARED
		
			if SERVER and !who:IsAdmin() then return end
			local t=net.ReadTable()

			
			if SERVER then
				local old=physenv.GetPerformanceSettings()
				for k,v in pairs(t) do
					Msg"[EEK] "print("Changing "..tostring(k)..': ',old[k] or "???","->",v)
					PrintMessage(3,"[PHYSENV] "..k.." changed from "..tostring(old[k] or "UNKNOWN").." to "..tostring(v))
				end
				physenv.SetPerformanceSettings(t)
				return
			end
			
			local v=vgui.Create'DFrame'
			v:SetSizable(true)
			v:ShowCloseButton(true)
			v:SetSize(512,512)
			local w=vgui.Create("DListView",v)
			w:Dock(FILL)
			local Col1 = w:AddColumn( "Key" )
			local Col2 = w:AddColumn( "Value" )
			
			local idkey={}
			for k,v in pairs(t) do
				idkey[#idkey+1]=k
				local l=w:AddLine(tostring(k),tostring(v))
				l.Columns[2]:Remove()
				local dt=vgui.Create('DTextEntry',l)
				dt:SetNumeric(true)
				dt:SetKeyBoardInputEnabled(true)
				dt:SetMouseInputEnabled(true)
				l.Columns[2]=dt
				dt:Dock(RIGHT)
				dt:SetText(v)
				dt.OnEnter=function(dt)
					local val=dt:GetValue()
					print("Wunna change",k,"to",tonumber(val))
					net.Start(Tag)
						net.WriteTable{[k]=tonumber(val)}
					net.SendToServer()
				end
			end
			v:Center()
			v:MakePopup()
			
		end)
		
	end
	
	do -- restart
		if SERVER then

			local function Shake()
				for k,v in pairs(player.GetAll()) do
					util.ScreenShake(v:GetPos(), math.Rand(1,10), math.Rand(1,5), 2, 500)
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
			
			local function DrawWarning()
				surface.SetFont("aowl_restart")
				local messageWidth = surface.GetTextSize(L(CONFIG.Warning))

				surface.SetDrawColor(255, 50, 50, 100 + (math.sin(CurTime() * 3) * 80))
				surface.DrawRect(0, 0, ScrW(), ScrH())

				-- Countdown bar
				surface.SetDrawColor(Color(0,255,0,255))
				surface.DrawRect((ScrW() - messageWidth)/2, 175, messageWidth * math.max(0, (CONFIG.TargetTime-CurTime())/(CONFIG.TargetTime-CONFIG.StartedCount) ), 20)
				surface.SetDrawColor(color_black)
				surface.DrawOutlinedRect((ScrW() - messageWidth)/2, 175, messageWidth, 20)

				-- Countdown message
				surface.SetFont("aowl_restart")
				surface.SetTextColor(Color(50, 50, 50, 255))

				local y = 200
				for _, messageLine in ipairs(string.Split(L(CONFIG.Warning), "\n")) do
					local w, h = surface.GetTextSize(messageLine)
					w = w or 56
					surface.SetTextPos((ScrW() / 2) - w / 2, y)
					surface.DrawText(messageLine)
					y = y + h
				end

				-- Countdown timer
				local Count = string.format("%.3f",(CONFIG.TargetTime - CurTime()))
				local w = surface.GetTextSize(Count)

				surface.SetTextPos((ScrW() / 2) - w / 2, y)
				surface.DrawText(Count)

				surface.SetTextColor(255, 255, 255, 255)
				if(CurTime() - CONFIG.LastPopup > 0.5) then
					for i = 1, 3 do
						CONFIG.PopupText[i] = L(table.Random(CONFIG.Popups))
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
end

do -- groups

	do -- team setup
		function team.GetIDByName(name)
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
		developers = 2, -- 3,
		owners = math.huge,
	}

	local alias =
	{
		[":D"] = "players",
		user = "players",
		default = "players",
		admin = "developers",
		sandals = "developers",
		moderators = "developers",
		guests = "developers",
		gays = "owners",
		superadmin = "owners",
		superadmins = "owners",
		administrator = "developers",
	}

	local META = FindMetaTable("Player")

	function META:CheckUserGroupLevel(name)

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
		if self:ShouldHideAdmins() then
			return false
		end
		return self:CheckUserGroupLevel("developers")
	end

	function META:IsSuperAdmin()
		if self:ShouldHideAdmins() then
			return false
		end
		return self:CheckUserGroupLevel("developers")
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

			self:SetTeam(team.GetIDByName("players"))
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
						ply:SetUserGroup(name, false)
					end
				end
			end
		end)

		hook.Add("InitPostEntity", "LoadNoLimits", function() -- Required, gamemode loads after addons (?)
			-- this won't work well with hooks because in some cases
			-- you need to dissallow moderators+ to spawn props.
			-- it will make them spawn things in the lobby and or
			-- while in the pac editor

			-- so instead we need to override the gamemode hooks
			-- which will take care of spawn limits
			--[[
			local SpawnTypes = {
			--	"Object", -- this is normally true
				"Prop",
				"SENT",
				"SWEP",
				"NPC",
				"Vehicle",
				"Effect",
				"Ragdoll",
			}

			for k,v in pairs(SpawnTypes) do
				if type(GAMEMODE["OldPlayerSpawn"..v]) ~= "function" then GAMEMODE["OldPlayerSpawn"..v] = GAMEMODE["PlayerSpawn"..v] end -- Broke often during testing.
				GAMEMODE["PlayerSpawn"..v] = function(self, ply, ...)
					if ply:CheckUserGroupLevel("developers") then
						return true
					end
					return GAMEMODE["OldPlayerSpawn"..v](self, ply, ...)
				end
			end
			]]
			local META = FindMetaTable("Player")
			local _R_Player_GetCount = META.GetCount
			function META.GetCount(self,limit,minus)
				if(self.Unrestricted) then
					return -1
				else
					return _R_Player_GetCount(self,limit,minus)
				end
			end
		end)
	end
end
