hook.Add("HUDShouldDraw", "hide_hud", function(element)
	if  
		( element == "CHudHealth" and ( not LocalPlayer():IsValid() or LocalPlayer():Health() == 100 ) ) or 
		--element == "CHudAmmo" or
		--element == "CHudSecondaryAmmo" or
		element == "CHudSuitPower" or
		( element == "CHudBattery" and ( not LocalPlayer():IsValid() or LocalPlayer():Armor() == 0 ) )
	then
		return false
	end

end)