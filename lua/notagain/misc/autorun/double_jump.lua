local default_times = 0
local default_power = 260

do -- meta
	local META = FindMetaTable("Player")

	function META:SetDoubleJumpTimes(times, dont_update_client)
		times = math.Round(times)

		self.double_jump_times = times

		if SERVER and not dont_update_client then
			umsg.Start("doublejump_times", ply)
				umsg.Float(times)
			umsg.End()
		end
	end

	function META:GetDoubleJumpTimes()
		return self.double_jump_times or default_times
	end

	function META:SetDoubleJumpPower(mult, dont_update_client)
		mult = math.Round(mult)

		self.double_jump_multiplier = mult

		if SERVER and not dont_update_client then
			umsg.Start("doublejump_mult", ply)
				umsg.Float(mult)
			umsg.End()
		end
	end

	function META:GetDubleJumpPower()
		return self.super_jump_multiplier or default_power
	end
end

hook.Add("KeyPress", "double_jump", function(ply, key)
	if key == IN_JUMP then
		if
			ply:GetMoveType() == MOVETYPE_WALK and
			ply:GetVelocity().z > -60 and
			(ply.double_jumped or 0) < ply:GetDoubleJumpTimes() and
			ply.double_jump_allowed ~= false and
			not ply:IsOnGround()
		then
			local mult = (1 + ply.double_jumped / ply:GetDoubleJumpTimes())

			if SERVER then
				ply:EmitSound(Format("weapons/crossbow/hitbod%s.wav", math.random(2)), 70, math.random(90,110) * mult )
			end
			ply:SetVelocity(Vector(0,0,default_power))
			ply:ViewPunch(Angle(default_power*0.01,0,0))
			ply.CalcIdeal = ACT_MP_JUMP

			ply:AnimRestartMainSequence()

			ply.double_jump_allowed = false
			ply.double_jumped = (ply.double_jumped or 0) + 1
		return end

		if ply:IsOnGround() then
			ply.double_jump_allowed = true
			ply.double_jumped = 0
		end
	end
end)

hook.Add("KeyRelease", "double_jump", function(ply, key)
	if key == IN_JUMP then
		ply.double_jump_allowed = true
	end
end)

if CLIENT then
	usermessage.Hook("bhop", function(u)
		LocalPlayer():SetSuperJumpMultiplier(u:ReadFloat())
	end)
end