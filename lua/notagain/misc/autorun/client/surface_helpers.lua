local white = surface.GetTextureID("vgui/white")

function surface.DrawLineEx(x1,y1, x2,y2, w, skip_tex)
	w = w or 1
	if not skip_tex then surface.SetTexture(white) end

	local dx,dy = x1-x2, y1-y2
	local ang = math.atan2(dx, dy)
	local dst = math.sqrt((dx * dx) + (dy * dy))

	x1 = x1 - dx * 0.5
	y1 = y1 - dy * 0.5

	surface.DrawTexturedRectRotated(x1, y1, w, dst, math.deg(ang))
end

function surface.DrawCircleEx(x, y, rad, color, res, ...)
	res = res or 16

	surface.SetDrawColor(color)

	local spacing = (res/rad) - 0.1

	for i = 0, res do
		local i1 = ((i+0) / res) * math.pi * 2
		local i2 = ((i+1 + spacing) / res) * math.pi * 2

		surface.DrawLineEx(
			x + math.sin(i1) * rad,
			y + math.cos(i1) * rad,

			x + math.sin(i2) * rad,
			y + math.cos(i2) * rad,
			...
		)
	end
end
