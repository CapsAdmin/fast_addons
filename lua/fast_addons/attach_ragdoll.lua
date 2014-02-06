local meta = FindMetaTable("Player")

function meta:GetAttachedRagdoll()
	return self:GetNWEntity("attach_rag", NULL)
end

if SERVER then
	function meta:SetAttachRagdoll(bool)
		local ent = self:GetAttachedRagdoll()

		if ent:IsValid() then
			ent:Remove()
			if not bool then
				return
			end
		 end

		local ent = ents.Create("prop_physics")
		 
		ent:SetModel(self:GetModel())

		ent:PhysicsInit(SOLID_VPHYSICS)
		ent:SetMoveType(MOVETYPE_VPHYSICS)
		ent:SetSolid(SOLID_VPHYSICS)

		ent:Spawn()

		ent:SetOwner(self)
		ent:SetPos(self:GetPos())

		self:SetNWEntity("attach_rag", ent)
	end
end

if CLIENT then
	hook.Add("RenderScene", "attach_ragdoll_think", function()
		for key, ply in pairs(player.GetAll()) do
			local ent = ply:GetAttachedRagdoll()

			if ent:IsValid() then
				if not ent.attached_rag then
					ent.ragdoll = ent:BecomeRagdollOnClient()
					ent.ragdoll:SetOwner(ply)

					ent.RenderOverride = function() end

					function ent.ragdoll:RenderOverride()
						if self.dead then return end

						local ply = self:GetOwner()

						if ply:IsPlayer() then
							local ent = ply:GetAttachedRagdoll()
							if ent.ragdoll ~= self then
								timer.Simple(0.1, function() self:Remove() end)
								self.dead = true
							end

							hook.Call("PreAttachedRagdollDraw",GAMEMODE,ply,self)

							local wep = ply:GetActiveWeapon()

							if wep:IsWeapon() then
								wep:SetPos(ply:EyePos())
								wep:SetRenderOrigin(ply:EyePos())
								wep:SetRenderAngles(ply:EyeAngles())
								wep:SetAngles(ply:EyeAngles())
								wep:SetupBones()
								wep:DrawModel()
							end

							self:DrawModel()
							hook.Call("PostAttachedRagdollDraw",GAMEMODE,ply,self)
						else
							timer.Simple(0.1, function() self:Remove() end)
							self.dead = true
						end
					end

					ent.attached_rag = true
				end

				if ent.ragdoll and IsEntity(ent.ragdoll) then
					hook.Call("OnAttachedRagdollUpdate", GAMEMODE, ply, ent.ragdoll)
				end
			end
		end
	end)
end

-- examples

if CLIENT then

	local bones =
	{
		[0] = "ValveBiped.Bip01_Pelvis",

		[1] = "ValveBiped.Bip01_Spine4",

		[2] = "ValveBiped.Bip01_R_UpperArm",
		[3] = "ValveBiped.Bip01_L_UpperArm",

		[4] = "ValveBiped.Bip01_L_Forearm",
		[5] = "ValveBiped.Bip01_L_Hand",

		[6] = "ValveBiped.Bip01_R_Forearm",
		[7] = "ValveBiped.Bip01_R_Hand",

		[8] = "ValveBiped.Bip01_R_Thigh",
		[9] = "ValveBiped.Bip01_R_Calf",

		[10] = "ValveBiped.Bip01_Head1",

		[11] = "ValveBiped.Bip01_L_Thigh",
		[12] = "ValveBiped.Bip01_L_Calf",

		[13] = "ValveBiped.Bip01_L_Foot",
		[14] = "ValveBiped.Bip01_R_Foot",
	}

	local data = {}
	data.secondstoarrive = 0.1
	data.dampfactor = 0.5

	data.teleportdistance = 0

	data.maxangular = 100000
	data.maxangulardamp = 100000
	data.maxspeed = 100000
	data.maxspeeddamp = 100000

	local function n(a)
		return Vector(math.NormalizeAngle(a.p), math.NormalizeAngle(a.y), math.NormalizeAngle(a.r))
	end
	
	local function s(a, b)
		return Vector(math.AngleDifference(a.p, b.p), math.AngleDifference(a.y, b.y), math.AngleDifference(a.r, b.r))
	end
	
	local function ComputeShadow(phys, pos, ang)
		phys:AddAngleVelocity((s(phys:GetAngles(), ang)))
		do return end
		data.pos = pos
		data.angle = ang
		phys:ComputeShadowControl(data)
	end


	hook.Add("OnAttachedRagdollUpdate", "he's dead", function(ply, rag)
		if not ply:OnGround() then
			phys = rag:GetPhysicsObjectNum(10) -- head

			if IsValid(phys) then
				local vel = (ply:EyePos() - phys:GetPos()):Normalize() * (phys:GetPos():Distance(ply:EyePos()) ^ 1.8)
				phys:AddVelocity(vel + (phys:GetVelocity() * -0.5))

				if not ply.ragattach_jump then
					local phys = rag:GetPhysicsObject()
					if IsValid(phys) then
						phys:AddAngleVelocity(VectorRand()*10000)
						phys:AddVelocity(VectorRand()*100)
						ply.ragattach_jump = true
					end
				end
			end

		else
			ply.ragattach_jump = false
			for rag_bone_index, ply_bone_name in pairs(bones) do
				local pos, ang = ply:GetBonePosition(ply:LookupBone(ply_bone_name))
				local phys = rag:GetPhysicsObjectNum(rag_bone_index)

				if IsValid(phys) then
					phys:EnableGravity( false )
					phys:Wake()
					rag:PhysWake()

					rag:SetSolid(SOLID_VPHYSICS)

					ComputeShadow(phys, pos, ang)
				end
			end
		end
	end)
end

