AddCSLuaFile()

local Tag="fakedie"
if SERVER then
	util.AddNetworkString(Tag)
	aowl.AddCommand("fakedie", function(pl, cmd, killer, icon, swap)

		local victim=pl:Name()
		local killer=killer or ""
		local icon=icon or ""
		local killer_team=-1
		local victim_team=pl:Team()
		if swap and #swap>0 then
			victim,killer=killer,victim
			victim_team,killer_team=killer_team,victim_team
		end
		net.Start(Tag)
			net.WriteString(victim or "")
			net.WriteString(killer or "")
			net.WriteString(icon or "")
			net.WriteFloat(killer_team or -1)
			net.WriteFloat(victim_team or -1)
		net.Broadcast()
	end,"developers")
else
	net.Receive(Tag,function(len)
		local victim=net.ReadString()
		local killer=net.ReadString()
		local icon=net.ReadString()
		local killer_team=net.ReadFloat()
		local victim_team=net.ReadFloat()
		GAMEMODE:AddDeathNotice( killer, killer_team, icon, victim, victim_team )
	end)
end