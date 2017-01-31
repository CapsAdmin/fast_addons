local default = 1.5

do
	local META = FindMetaTable("Player")

	function META:SetSuperJumpMultiplier(mult, dont_update_client)
		self.super_jump_multiplier = mult

		if SERVER and not dont_update_client then
			umsg.Start("bhop", self)
				umsg.Float(mult)
			umsg.End()
		end

		self:SetDuckSpeed(0.05)
		self:SetUnDuckSpeed(0.05)
	end

	function META:GetSuperJumpMultiplier()
		return self.super_jump_multiplier or default
	end
end

local function calc_wall(ply, data)
	local velocity = data:GetVelocity()
	local normalized = velocity:GetNormalized()

	local params = {}
		params.start = ply:GetPos()+Vector(0,0,36)
		params.endpos = params.start+(normalized*math.max(velocity:Length()/20, 50))
		params.filter = ply
		params.mins = ply:OBBMins()
		params.maxs = ply:OBBMaxs()
	local res = util.TraceHull(params)

	if not ply:IsOnGround() and res.Hit and math.abs(res.HitNormal.z) < 0.7 then
		local direction = velocity - 2 * (res.HitNormal:DotProduct(velocity) * res.HitNormal)

		local fraction = math.min(velocity:Length() / GetConVarNumber("sv_maxvelocity"), 1)

		ply:SetGroundEntity(NULL)
		data:SetVelocity(direction*1.25)--*(fraction*2+(0.5)))

		if SERVER then

			local fraction = data:GetVelocity():Length() / (GetConVarNumber("sv_maxvelocity") / 4)
			sound.Play(("weapons/fx/rics/ric%s.wav"):format(math.random(5)), data:GetOrigin(), math.Clamp(300*fraction, 20, 150), math.Clamp(fraction*255+70, 70, 150))
			sound.Play(("weapons/crossbow/fire1.wav"):format(math.random(5)), data:GetOrigin(), 100, math.Clamp(fraction*255+120, 70, 255))

		end
	end
end

local function Move(ply, data)
	local mult = ply:GetSuperJumpMultiplier()

	if ply:KeyPressed(IN_JUMP) and ply:GetMoveType() == MOVETYPE_WALK then
		if mult ~= 1 and ply:IsOnGround() then
			data:SetVelocity(data:GetVelocity() * mult)

			local eye = math.Clamp(ply:EyeAngles().p/89, 0, 1) ^ 3
			if eye > 0.3 then

				if SERVER then
					local fraction = data:GetVelocity():Length() / (GetConVarNumber("sv_maxvelocity") / 4)
					sound.Play(("weapons/fx/rics/ric%s.wav"):format(math.random(5)), data:GetOrigin(), math.Clamp(300*fraction, 20, 150), math.Clamp(fraction*255+70, 70, 150))
					sound.Play(("physics/plastic/plastic_barrel_impact_bullet3.wav"):format(math.random(5)), data:GetOrigin(), 100, math.Clamp(fraction*255+40, 70, 255))

					local ef = EffectData()
						ef:SetOrigin(data:GetOrigin())
						ef:SetScale(10)
					timer.Simple(0, function() util.Effect("StunstickImpact", ef) end)
				end

				data:SetVelocity(LerpVector(eye, data:GetVelocity(), Vector(0.5, 0.5, 1) * data:GetVelocity() + Vector(0,0,data:GetVelocity():Length()*0.3)))
			end

		end

		calc_wall(ply, data)
	end
end

if SERVER then
	hook.Add("SetupMove", "bhop", Move)

	hook.Add("GetFallDamage", "bhop", function(ply, speed)
		if ply:KeyDown(IN_JUMP) then
			return 0
		end
	end)
end

if CLIENT then
	hook.Add("Move", "bhop", Move)

	usermessage.Hook("bhop", function(u)
		LocalPlayer():SetSuperJumpMultiplier(u:ReadFloat())
	end)
end

if SERVER then
	RunConsoleCommand("sv_airaccelerate", "1000000")
	RunConsoleCommand("sv_maxvelocity", "20000")
end