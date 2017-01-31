local function VecToString(str, a)
	return str.."=(" .. math.Round(a.p or a.x) .. ", " .. math.Round(a.y) .. ", " .. math.Round(a.r or a.z) .. ")"
end

local function NormalizeAngle(a)
	a.p = math.NormalizeAngle(a.p)
	a.y = math.NormalizeAngle(a.y)
	a.r = math.NormalizeAngle(a.r)

	if a.p < 0 then
		a.p = math.abs(a.p) + 180
	end

	if a.y < 0 then
		a.p = math.abs(a.y) + 180
	end

	if a.r < 0 then
		a.r = math.abs(a.r) + 180
	end

	return a
end

local function AngleDifference(a,b)
	return Angle(
		math.AngleDifference(a.p, b.p),
		math.AngleDifference(a.y, b.y),
		math.AngleDifference(a.r, b.r)
	)
end

local meta = FindMetaTable("Entity")

function meta:SmoothMove(pos, ang, mult)
	if self:IsValid() then
		mult = mult or 1

		local phys = self:GetPhysicsObject()
		if phys:IsValid() then

			phys:EnableGravity(false)
			phys:Wake()

			if pos then
				local dir = pos - self:GetPos()
				local length = dir:Length()
				local normal = dir:Normalize()

				phys:AddVelocity(normal * (length ^ 2.5))
				phys:AddVelocity(phys:GetVelocity() * -0.4)
			end

			if ang then
				-- normalize the angles so it goes properly from -180 to 180
				ang = NormalizeAngle(ang)
				local physang = NormalizeAngle(phys:GetAngles())

				-- the velocity direction
				local _dir = NormalizeAngle(ang - physang)

				--re arrange it to suit AddAngleVelocity
				local dir = Vector(_dir.r,_dir.p,_dir.y)

				-- calculate how smooth it should go (temporarily just *100)
				local vel = dir * 100

				-- insane values will make the physics break
				vel.x = math.Clamp(vel.x, -5000, 5000)
				vel.y = math.Clamp(vel.y, -5000, 5000)
				vel.z = math.Clamp(vel.z, -5000, 5000)


				-- add the velocity
				phys:AddAngleVelocity(vel)
				phys:AddAngleVelocity(phys:GetAngleVelocity() * -0.4)

				--debug print some vars
				debugutils.Print(self, phys:GetPos(), physang, ang, vel)
			end

			timer.Create(tostring(self) .. "callback_smooth_move", 0.1, 1, function()
				if phys:IsValid() then
					phys:EnableGravity(true)
				end
			end)
		end
	end
end