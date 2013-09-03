local function is_dancing(ply)
	return ply:GetNetData("dancing")
end
	
if CLIENT then
	local bpm = CreateClientConVar("dance_bpm", 120, true, true)	
		
	hook.Add("ShouldDrawLocalPlayer", "dance", function(ply)
		if is_dancing(ply) then
			return true	
		end
	end)
	
	hook.Add("CalcView", "dance", function(ply, pos)
		if not is_dancing(ply) then return end
		
		local pos = pos + ply:GetAimVector() * -100
		local ang = (ply:EyePos() - pos):Angle()
		
		return {
			origin = pos,
			angles = ang,
		}
	end)

	local beats = {}
	local suppress = false
	local last
	
	hook.Add("CreateMove", "dance", function(cmd)
		if is_dancing(LocalPlayer()) then
			if cmd:KeyDown(IN_JUMP) then
				if not suppress then
					local time = RealTime()
					last = last or time
					table.insert(beats, time - last)
					last = time
					
					local temp = 0
					for k,v in pairs(beats) do temp = temp + v end									
					temp = temp / #beats
					temp = 1 / temp
					
					if #beats > 5 then
						table.remove(beats, 1)	
					end
					
					RunConsoleCommand("dance_bpm", (temp * 60))
					RunConsoleCommand("dance_setrate", bpm:GetInt())
						
					suppress = true
				end
			else
				suppress = false
			end
			cmd:SetButtons(0)
		end
	end)

	hook.Add("CalcMainActivity", "dance", function(ply)
		if is_dancing(ply) then
			local bpm = (ply:GetNetData("dance_bpm") or 120) / 94
			local time = (RealTime() / 10) * bpm
			time = time%2
			if time > 1 then
				time = -time + 2
			end
			
			time = time * 0.8
			time = time + 0.11
			
			ply:SetCycle(time)
		
			return 0, ply:LookupSequence("taunt_dance")
		end
	end)
end

if SERVER then
	concommand.Add("dance_setrate", function(ply, _, args)
		ply:SetNetData("dance_bpm", tonumber(args[1]))
	end)
	
	local function addcmd()		
		aowl.AddCommand("dance2", function(ply)		
			if not ply:GetNetData("dancing") then
				aowl.Message(ply, "Dance mode enabled!")
				aowl.Message(ply, "Tap space to the beat!")
				ply:SetNetData("dancing", true) 
			else
				aowl.Message(ply, "Dance mode disabled.")			
				ply:SetNetData("dancing", false)
			end
		end)
	end
	
	if aowl then
		addcmd()
	else	
		hook.Add("AowlInitialized", "dance2", function()
			addcmd()
			hook.Remove("AowlInitialized", "dance2")
		end)
	end
end