function Warning(msg, func)
	local delpnl = vgui.Create("DFrame")
	delpnl:SetSize(150, 100)
	delpnl:SetPos( (ScrW()/2) - 75, (ScrH()/2) - 50 )
	delpnl:SetTitle(msg)
	local yesbtn = vgui.Create("DButton", delpnl)
	yesbtn:SetText("Yes")
	yesbtn:SetSize(50, 25)
	yesbtn:SetPos(25, 50)
	yesbtn.DoClick = function(btn)
		func()
		delpnl:Close()
	end
	local nobtn = vgui.Create("DButton", delpnl)
	nobtn:SetText("No")
	nobtn:SetSize(50, 25)
	nobtn:SetPos(75, 50)
	nobtn.DoClick = function(btn)
		delpnl:Close()
	end
	delpnl:MakePopup()
	delpnl:ShowCloseButton( true )
	delpnl:SetVisible( true )
end

gui.OSOpenURL=gui.OpenURL


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
	
do
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
end

local Panel=FindMetaTable"Panel"
local CutX,CutY
CutX = function (x,yes,rev)
	
	if rev then
		render.SetScissorRect(x,0,ScrW(),ScrH(),yes)
	else
		render.SetScissorRect(0,0,x,ScrH(),yes)
	end
	
	
end

CutY = function (y,yes,rev)
	
	if rev then
		render.SetScissorRect(0,y,ScrW(),ScrH(),yes)
	else
		render.SetScissorRect(0,0,ScrW(),y,yes)
	end
	
end

render.CutX=CutX
render.CutY=CutY

function Panel:CutX(pos,yes,rev)
	local x,y=self:LocalToScreen(pos,0)
	render.CutX(x,yes,rev)
end

function Panel:CutY(pos,yes,rev)
	local x,y=self:LocalToScreen(0,pos)
	render.CutY(y,yes,rev)
end

