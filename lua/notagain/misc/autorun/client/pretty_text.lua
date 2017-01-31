local fonts = {}

-- python1320: heul,
local function create_fonts(font, size, weight, blursize)
	local main = "pretty_text_" .. size .. weight
	local blur = "pretty_text_blur_" .. size .. weight

	surface.CreateFont(
		main,
		{
			font = font,
			size = size,
			weight = weight,
			antialias 	= true,
			additive 	= true,
		}
	)

	surface.CreateFont(
		blur,
		{
			font = font,
			size = size,
			weight = weight,
			antialias 	= true,
			blursize = blursize,
		}
	)

	return
	{
		main = main,
		blur = blur,
	}
end

def_color1 = Color(255, 255, 255, 255)
def_color2 = Color(0, 0, 0, 255)

local surface_SetFont = surface.SetFont
local surface_SetTextColor = surface.SetTextColor
local surface_SetTextPos = surface.SetTextPos
local surface_DrawText = surface.DrawText

function surface.DrawPrettyText(text, x, y, font, size, weight, blursize, color1, color2, x_align, y_align)
	font = font or "Arial"
	size = size or 14
	weight = weight or 0
	blursize = blursize or 1
	color1 = color1 or def_color1
	color2 = color2 or def_color2

	if not fonts[font] then fonts[font] = {} end
	if not fonts[font][size] then fonts[font][size] = {} end
	if not fonts[font][size][weight] then fonts[font][size][weight] = {} end
	if not fonts[font][size][weight][blursize] then fonts[font][size][weight][blursize] = create_fonts(font, size, weight, blursize) end

	if x_align then
		local w = surface.GetPrettyTextSize(text, font, size, weight, blursize)
		x = x + (w * x_align)
	end

	if y_align then
		local _, h = surface.GetPrettyTextSize(text, font, size, weight, blursize)
		y = y + (h * y_align)
	end

	surface_SetFont(fonts[font][size][weight][blursize].blur)
	surface_SetTextColor(color2)

	for i = 1, 5 do
		surface_SetTextPos(x, y) -- this resets for some reason after drawing
		surface_DrawText(text)
	end

	surface_SetFont(fonts[font][size][weight][blursize].main)
	surface_SetTextColor(color1)
	surface_SetTextPos(x, y)
	surface_DrawText(text)
end

function surface.GetPrettyTextSize(text, font, size, weight, blursize)
	font = font or "Arial"
	size = size or 14
	weight = weight or 0
	blursize = blursize or 1

	if not fonts[font] then fonts[font] = {} end
	if not fonts[font][size] then fonts[font][size] = {} end
	if not fonts[font][size][weight] then fonts[font][size][weight] = {} end
	if not fonts[font][size][weight][blursize] then fonts[font][size][weight][blursize] = create_fonts(font, size, weight, blursize) end

	surface.SetFont(fonts[font][size][weight][blursize].blur)
	return surface.GetTextSize(text)
end