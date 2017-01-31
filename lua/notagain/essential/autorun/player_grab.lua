do -- meta
	local PLAYER = FindMetaTable("Player")

	function PLAYER:IsBeingPhysgunned()
		local pl = self._is_being_physgunned
		if pl then
			if isentity(pl) and not IsValid(pl) then
				return false
			end
			return true
		end
	end

	function PLAYER:SetPhysgunImmune(bool)
		self._physgun_immune = bool
	end

	function PLAYER:IsPhysgunImmune()
		return self._physgun_immune == true
	end
end
if CLIENT then
	CreateClientConVar("physgun_dont_touch_me","0",true,true)
end

hook.Add("PhysgunPickup", "player_grab", function(ply, ent)
	local canphysgun = ent:IsPlayer() and not ent:IsPhysgunImmune() and not ent:IsBeingPhysgunned()
	if not canphysgun then return end

	if ent.IsFriend then
		canphysgun = ent:IsFriend(ply) and ent:GetInfoNum("physgun_dont_touch_me",0)==0 and ply:GetInfoNum("physgun_dont_touch_me",0)==0
	else
		canphysgun = ply:IsAdmin()
	end
	canphysgun = canphysgun or ent:IsBot()
	canphysgun = canphysgun or ( ent.IsBanned and ent:IsBanned())
	if not canphysgun then return end

	if IsValid(ent._is_being_physgunned) then
		if ent._is_being_physgunned~=ply then return end
	end

	ent._is_being_physgunned = ply

	ent:SetMoveType(MOVETYPE_NONE)
	ent:SetOwner(ply)

	return true
end)

hook.Add("PhysgunDrop", "player_grab", function(ply, ent)
	if ent:IsPlayer() and ent._is_being_physgunned==ply then
		ent._pos_velocity = {}
		ent._is_being_physgunned = false

		ent:SetMoveType(ply:KeyDown(IN_ATTACK2) and ply:CheckUserGroupLevel("moderators") and MOVETYPE_NOCLIP or MOVETYPE_WALK)
		ent:SetOwner()

		-- do we need to?
		return true
	end
end)

do -- throw
	local function GetAverage(tbl)
		if #tbl == 1 then return tbl[1] end

		local average = vector_origin

		for key, vec in pairs(tbl) do
			average = average + vec
		end

		return average / #tbl
	end

	local function CalcVelocity(self, pos)
		self._pos_velocity = self._pos_velocity or {}

		if #self._pos_velocity > 10 then
			table.remove(self._pos_velocity, 1)
		end

		table.insert(self._pos_velocity, pos)

		return GetAverage(self._pos_velocity)
	end

	hook.Add("Move", "player_grab", function(ply, data)

		if ply:IsBeingPhysgunned() then
			local vel = CalcVelocity(ply, data:GetOrigin())
			if vel:Length() > 10 then
				data:SetVelocity((data:GetOrigin() - vel) * 8)
			end

			local owner = ply:GetOwner()

			if owner:IsPlayer() then
				if owner:KeyDown(IN_USE) then
					local ang = ply:GetAngles()
					ply:SetEyeAngles(Angle(ang.p, ang.y, 0))
				end
			end
		end

	end)
end

hook.Add("CanPlayerSuicide", "player_grabbed_nosuicide", function(ply) -- attempt to stop suicides during physgun
	if ply:IsBeingPhysgunned() then return false end
end)

hook.Add("PlayerDeath", "player_grabbed_nodeath", function(ply)
	if ply:IsBeingPhysgunned() then return false end -- attempt to stop suicides during physgun
end)

hook.Add("PlayerNoClip", "player_grabbed_nonoclip", function(ply)
	if ply:IsBeingPhysgunned() then return false end
end)