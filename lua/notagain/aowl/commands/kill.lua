AddCSLuaFile()

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

		local ok = hook.Run("CanPlayerSuicide", ply)
		if (ok == false) then
			return
		end

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