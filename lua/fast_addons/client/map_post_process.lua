local MAPNAME = game.GetMap():lower()

if MAPNAME == "gm_endlessocean" or MAPNAME == "harbor2ocean_betav1" or MAPNAME == "rp_mountainvillage_night" or MAPNAME == "md_venetianredux_b2fix" then
	local emitter = ParticleEmitter(EyePos())

	hook.Add("RenderScreenspaceEffects", "hm", function()
	  --  DrawToyTown( 20, 1000)

		local tbl = {}
			tbl[ "$pp_colour_addr" ] = 0.08
			tbl[ "$pp_colour_addg" ] = 0.05
			tbl[ "$pp_colour_addb" ] = 0.13
			tbl[ "$pp_colour_brightness" ] = MAPNAME == "rp_mountainvillage_night" and -0.065 or -0.09
			tbl[ "$pp_colour_contrast" ] = 0.9
			tbl[ "$pp_colour_colour" ] = 0.5
			tbl[ "$pp_colour_mulr" ] = 0
			tbl[ "$pp_colour_mulg" ] = 0
			tbl[ "$pp_colour_mulb" ] = 0
		DrawColorModify( tbl )

		for i=1, 5 do
			local particle = emitter:Add("particle/Particle_Glow_05", LocalPlayer():EyePos() + VectorRand() * 500)
			if particle then
				local col = HSVToColor(math.random()*30, 0.1, 1)
				particle:SetColor(col.r, col.g, col.b, 266)

				particle:SetVelocity(VectorRand() )

				particle:SetDieTime((math.random()+4)*3)
				particle:SetLifeTime(0)

				local size = 1

				particle:SetAngles(AngleRand())
				particle:SetStartSize((math.random()+1)*2)
				particle:SetEndSize(0)

				particle:SetStartAlpha(0)
				particle:SetEndAlpha(255)

				--particle:SetRollDelta(math.Rand(-1,1)*20)
				particle:SetAirResistance(500)
				particle:SetGravity(VectorRand() * 10)
			end
		end
	end)
end