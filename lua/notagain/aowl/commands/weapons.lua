aowl.AddCommand("drop",function(ply)

	-- Admins not allowed either, this is added for gamemodes and stuff

	local ok = hook.Run("CanDropWeapon", ply)
	if (ok == false) then
		return false
	end
	if GAMEMODE.DropWeapon then
		GAMEMODE:DropWeapon(ply)
	else
		if ply:GetActiveWeapon():IsValid() then
			ply:DropWeapon(ply:GetActiveWeapon())
		end
	end
end, "players", true)

do -- give weapon
	local prefixes = {
		"",
		"weapon_",
		"weapon_fwp_",
		"weapon_cs_",
		"tf_weapon_",
	}

	local weapons_engine = {
		weapon_357 = true,
		weapon_ar2 = true,
		weapon_bugbait = true,
		weapon_crossbow = true,
		weapon_crowbar = true,
		weapon_frag = true,
		weapon_physcannon = true,
		weapon_pistol = true,
		weapon_rpg = true,
		weapon_shotgun = true,
		weapon_slam = true,
		weapon_smg1 = true,
		weapon_stunstick = true,
		weapon_physgun = true
	}

	aowl.AddCommand("give", function(ply, line, target, weapon, ammo1, ammo2)
		local ent = easylua.FindEntity(target)
		if not ent:IsPlayer() then return false, aowl.TargetNotFound(target) end
		if not isstring(weapon) or weapon == "#wep" then
			local wep = ply:GetActiveWeapon()
			if IsValid(wep) then
				weapon = wep:GetClass()
			else
				return false,"Invalid weapon"
			end
		end
		ammo1 = tonumber(ammo1) or 0
		ammo2 = tonumber(ammo2) or 0
		for _,prefix in ipairs(prefixes) do
			local class = prefix .. weapon
			if weapons.GetStored(class) == nil and not weapons_engine[class] then continue end
			if ent:HasWeapon(class) then ent:StripWeapon(class) end
			local wep = ent:Give(class)
			if IsValid(wep) then
				wep.Owner = wep.Owner or ent
				ent:SelectWeapon(class)
				if wep.GetPrimaryAmmoType then
					ent:GiveAmmo(ammo1,wep:GetPrimaryAmmoType())
				end
				if wep.GetSecondaryAmmoType then
					ent:GiveAmmo(ammo2,wep:GetSecondaryAmmoType())
				end
				return
			end
		end
		return false, "Couldn't find " .. weapon
	end, "developers")
end

aowl.AddCommand("giveammo",function(ply, line,ammo,ammotype)
	if !ply:Alive() and !IsValid(ply:GetActiveWeapon()) then return end
	local amt = tonumber(ammo) or 500
	local wep = ply:GetActiveWeapon()
	if not ammotype or ammotype:len() <= 0 then
		if wep.GetPrimaryAmmoType and wep:GetPrimaryAmmoType() != none then
			ply:GiveAmmo(amt,wep:GetPrimaryAmmoType())
		end
	else
		ply:GiveAmmo(amt,ammotype)
	end
end, "players")