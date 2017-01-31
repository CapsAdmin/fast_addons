local aowl = requirex("aowl")

local function is_dancing(ply)
	return ply:GetNWBool("dancing")
end

local function set_dancing(ply, b)
	ply:SetNWBool("dancing", b)
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
			local bpm = (ply:GetNWBool("dance_bpm") or 120) / 94
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
		ply:SetNWBool("dance_bpm", tonumber(args[1]))
	end)

	aowl.AddCommand("dance", function(ply)
		if not is_dancing(ply) then
			aowl.Message(ply, "Dance mode enabled. Tap space to the beat!")
			set_dancing(ply, true)
		else
			aowl.Message(ply, "Dance mode disabled.")
			set_dancing(ply, false)
		end
	end)

	hook.Add("PlayerDeath", "DancingDeath", function(ply)
		if is_dancing(ply) then
			set_dancing(ply, false)
		end
	end)
end