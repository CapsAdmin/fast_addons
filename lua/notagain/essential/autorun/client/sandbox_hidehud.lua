hook.Add("HUDShouldDraw", "hide_hud", function(element)
	local ply = LocalPlayer()
	if not ply:IsValid() then return end
	if (element == "CHudHealth" and ply:Health() == 100) or (element == "CHudBattery" and ply:Armor() == 100) then
		return false
	end
end)