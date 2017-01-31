local t = 0

local smooth_offset = Vector(0,0,0)
local smooth_noise = Vector(0,0,0)
local noise = vector_origin

local cvar_fov = GetConVar("fov_desired")

local walking
local ducking
local crashed
local function CalcView(ply, pos, ang, fov)
	if ply:ShouldDrawLocalPlayer() or crashed then return end

	local wep =  ply:GetActiveWeapon()

	if wep:IsValid() and (not wep.GetIronsights or not wep:GetIronsights()) and math.ceil(fov) == math.ceil(cvar_fov:GetFloat()) and not wep:GetNWBool("IronSights") then

		local delta = math.Clamp(FrameTime(), 0.001, 0.5)

		if math.random() > 0.8 then
			noise = noise + VectorRand() * 0.1

			noise.x = math.Clamp(noise.x, -1, 1)
			noise.y = math.Clamp(noise.y, -1, 1)
			noise.z = math.Clamp(noise.z, -1, 1)
		end

		local params = GAMEMODE:CalcView(ply, pos, ang, fov)

		local vel = ply:GetVelocity()
		vel.z = -ply:GetVelocity().z

		vel = vel * 0.01

		vel.x = math.Clamp(-vel.x, -8, 8)
		vel.y = math.Clamp(vel.y, -8, 8)
		vel.z = math.Clamp(vel.z, -8, 8)

		local offset = vel * 1
		local mult = vel:Length() * 5
		
		if walking then
			mult = mult * 1.75
		end
		
		if ducking then
			mult = mult * 2
			if walking then
				mult = mult * 0.75
			end
		end

		if ply:IsOnGround() then
			local x = math.sin(t)
			local y = math.cos(t)
			local z = math.abs(math.cos(t))

			offset = offset + (Vector(x, y, z) * 3)

			t = t + (mult * delta)
		end

		smooth_noise = smooth_noise + ((noise - smooth_noise) * delta * 0.25 )

		--offset = LocalToWorld(offset, vector_origin, pos, vector_origin)

		offset.x = math.Clamp(offset.x, -4, 4)
		offset.y = math.Clamp(offset.y, -4, 4)
		offset.z = math.Clamp(offset.z, -4, 4)

		offset = (offset * 0.2) + (smooth_noise * math.min(mult, 2))

		params.vm_origin = (params.vm_origin or pos) + (offset/2)
		--params.vm_angles = (params.vm_angles or ang) + Angle(vel.x, vel.y, vel.z)

		return params
	end
end
hook.Add("CalcView", "footsteps", CalcView)

--This is not perfect, but good enough
local function PlayerStepSoundTime(ply)
	local running = ply:KeyDown(IN_SPEED)
	walking = ply:KeyDown(IN_WALK)
	ducking = ply:KeyDown(IN_DUCK)
	local sideways = ply:KeyDown(IN_MOVELEFT) or ply:KeyDown(IN_MOVERIGHT)
	local forward = ply:KeyDown(IN_FORWARD)
	local back = ply:KeyDown(IN_BACK)

	local time = 240

	if running then
		time = 140
		if sideways then
			time = 200
		end
	end
	if walking then
		time = 285
		if forward then
			time = 390
		end
		if back then
			time = 330
		end
	end
	if sideways and not forward then
		time = time * 0.75
	end

	if not walking and not running and back then
		time = 200
	end

	return time
end
hook.Add("PlayerStepSoundTime", "footsteps", PlayerStepSoundTime)

hook.Add('CrashTick', "footstepsdisable", function(crash)
	crashed = crash
end)