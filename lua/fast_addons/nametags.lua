
local META = FindMetaTable("Player")

local Tag = "NameT"


local function ok(nametag)
	if nametag==false then return true end
	if nametag==nil then return true end
	if isstring(nametag) and nametag:len()<1024 then return true end
end

function META:SetCustomTitle(title)
	if title=="" then title=nil end
	if not ok(title) then
		return false
	end
	self:SetNetData(Tag,title)
	return true
end


function META:GetCustomTitle()
	return self:GetNetData(Tag)
end


hook.Add("NetData",Tag,function(pl,k,nametag)
	if k==Tag then
		if ok(nametag) then
			if SERVER then 
				return true 
			else
				local ent = player.UserIDToEntity(pl)
				if IsValid(ent) then
					ent.CustomTitle = nametag or false
				end
				local me = LocalPlayer()
				me=IsValid(me) and me
				if me and pl == me:UserID() then
					Msg"[NameTags] " print("Saved nametag: '"..tostring(nametag or "<empty>").."'")
					file.Write("custom_title.txt", nametag)
				end
			end
			return true
		end
		return false
	end
end)



if CLIENT then
	local font_name = "NameTags"
	local font_scale = 0.1
	
	surface.CreateFont(
		font_name,
		{
			font 		= "Tahoma",
			size 		= 64,
			weight 		= 800,
			antialias 	= true,
			additive 	= true,
		}
	)
	
	local font_name_blur = font_name.."_blur"

	local afk_phrases = {
		"Drinking some tea...",
		"Probably sleeping...",
		"Away...",
		"Ya-a-a-a-wn...",
		"Zzz...",
		"Dreaming of gmod...",
	}
	
	surface.CreateFont(
		font_name_blur,
		{
			font 		= "Tahoma",
			size 		= 64,
			weight 		= 800,
			antialias 	= true,
			additive 	= false,
			blursize 	= 10,
		}
	)

	hook.Add("PopulateToolMenu", "NameTags", function()
		spawnmenu.AddToolMenuOption("Options", "Player", "Custom Title", "Custom Title", "", "", function(panel)
			local entry = vgui.Create('DTextEntry',panel)
			panel:AddItem(entry)
			entry:SetTall(100)
			entry:SetMultiline(true)
			entry:SetEditable(true)
			entry:SetAllowNonAsciiCharacters(true)

			local button = panel:Button("Set Title")
			button:SetText("Set Title")
			button.DoClick = function()
				LocalPlayer():SetCustomTitle(entry:GetValue())
			end
		end)
	end)

	local inited=false
	local localpl = LocalPlayer()
	local function Init()
		if inited then return end
		inited=true
		
		local title = file.Read("custom_title.txt","DATA")
		
		localpl=LocalPlayer()
		localpl:SetCustomTitle(title)
	end
	
	hook.Add("InitPostEntity", "NameTags", Init)
	if localpl:IsValid() then Init() end

	local angles = Angle(0,0,90)
	local cl_shownametags = CreateClientConVar("cl_shownametags", "1", true)
	
	local offset = 20
	local eyepos = Vector()
	local eyeang = Vector()
	local fn=0	
		
	hook.Add("RenderScene", "NameTags", function(pos, ang) 
		eyepos = pos 
		eyeang = ang 
		
		fn = FrameNumber()
	end)

	local function get_head_pos(ent)
		local pos
		local bone = ent:GetAttachment(ent:LookupAttachment("eyes"))
		pos = bone and bone.Pos
		if not pos then
			local bone = ent:LookupBone("ValveBiped.Bip01_Head1")
			
			pos = bone and ent:GetBonePosition(bone) or ent:EyePos()
			
		end
		
		return pos
	end
	
	local function Name(ply,data)
		local name = ply:Name()
		local last = data.__lastcleanname
		
		if name ~= last then
			last = name:gsub("%^%d", "")
			last = last:gsub("<(.-)=(.-)>", "")
			data.__lastcleanname = last
		end
		return last
		
	end
	
	local surface=surface	
	local cam=cam
	local render=render
	local color_bl=Color(0,0,0,255)
	local function draw_text(text, color, x, y)
		surface.SetFont(font_name_blur)
		
		surface.SetTextColor(color_bl)
		
		for i=1, 3 do
			surface.SetTextPos(x,y)
			surface.DrawText(text)
		end
	
		surface.SetFont(font_name)
		surface.SetTextColor(color)
		surface.SetTextPos(x,y)
		surface.DrawText(text)
	end
		
	local hdr_check = true
	local hdr
	local vector_1_1_1=Vector(1,1,1)	
	local spacing = 1.5
	local white = Color(255, 255, 255, 255)
	local afkcol = Color(102, 102, 204,255)
	local PlayerColors = {
		["0"] = Color(0,0,0),
		["1"] = Color(255, 0, 0),
		["2"] = Color(0, 255, 0),
		["3"] = Color(210, 210, 0),
		["4"] = Color(0, 0, 255),
		["5"] = Color(0, 200, 200),
		["6"] = Color(255, 0, 255),
		["7"] = Color(120, 120, 120),
		["r"] = Color(255, 0, 0),
		["g"] = Color(0, 255, 0),
		["b"] = Color(0, 0, 255),
		["w"] = Color(255, 255, 255),
		["c"] = Color(0, 255, 255),
		["m"] = Color(255, 0, 255),
		["y"] = Color(255, 255, 0),
		["k"] = Color(0, 0, 0)
	}

	local function draw_nametag(ply, alpha,data,rag)
		surface.SetFont(font_name)

		local ent = rag or ply
		
		local scale = ply:GetModelScale()
		local zscl = scale
		if scale<1 then
			scale = 0.4+scale*0.6
			zscl = 0.7+scale*0.3
		end
		local head_pos = get_head_pos(ent) + ent:GetUp() * (offset * zscl)
		
		
		--head_pos=ent:GetPos()+Vector(0,0,math.abs(ent:OBBMaxs().z-ent:OBBMins().z))
		
		local text = Name(ply,data)	
		local w, h = surface.GetTextSize(text)
		local size = 0.6 * scale * font_scale
		local name_c
		for col in string.gmatch(ply:Name(),"%^(%d)") do
			name_c = PlayerColors[col]
		end
		for col1,col2,col3 in string.gmatch(ply:Name(),"<hsv=(%d+.?%d*),(%d+.?%d*),(%d+.?%d*)>") do
			name_c = HSVToColor(col1,col2,col3)
		end
		for col1,col2,col3 in string.gmatch(ply:Name(),"<color=(%d+.?%d*),(%d+.?%d*),(%d+.?%d*)>") do
			name_c = Color(col1,col2,col3,255)
		end
		local c = name_c and name_c or team.GetColor(ply:Team())
		

		-- fading
		color_bl.a=alpha
		c.a=alpha
		white.a=alpha
		afkcol.a=alpha
		
		-- DRAW NAME
		cam.Start3D2D(head_pos, angles, size)
			draw_text(text, c, w*(-0.5), 0)
		cam.End3D2D()
		local h_offset = h * spacing
		
		
		-- DRAW TITLE
		local title = data.CustomTitle
		if title==nil then -- hm?
			title = ply:GetCustomTitle()
		end
		if title then
			local w, h = surface.GetTextSize(title)
			cam.Start3D2D(head_pos, angles, 0.4 * scale * font_scale)
				draw_text(title, white, -(w/2), h_offset)
			cam.End3D2D()
			h_offset = h_offset + (h * spacing * (1/scale))
		end
		
		-- DRAW AFK
		if META.IsAFK and ply:IsAFK() then
			local s = afk_phrases[math.floor((CurTime()/4 + ply:EntIndex())%#afk_phrases) + 1]
			
			local w, h = surface.GetTextSize(s)
			
			cam.Start3D2D(head_pos, angles, 0.3 * scale * font_scale)
				draw_text(s, afkcol, -(w/2), -spacing * h / spacing)
			cam.End3D2D()
		end
		
	end
	
	local drawables={}--setmetatable({},{__mode='k'})

	local vdn = Vector(0,0,-1)
	local vup = Vector(0,0,1)
	local lastfn=0
	hook.Add("PostDrawTranslucentRenderables", "NameTags", function()
		--local aaa=SysTime()
		if not cl_shownametags:GetBool() then return end

		--wrong somehow. HOW CAPS?
		--if lastfn==fn then return end
		--lastfn=fn
		
		local tm
		if hdr then
			tm = render.GetToneMappingScaleLinear()
			render.SetToneMappingScaleLinear(vector_1_1_1)
		elseif hdr_check then
			hdr_check = false
			local tm = render.GetToneMappingScaleLinear()
			hdr = tm.x~=1 or tm.y~=1 or tm.z~=1
		end
		
		angles.p = eyeang.p
		angles.y = eyeang.y
		angles.r = eyeang.r
		angles:RotateAroundAxis(angles:Up(), -90)
		angles:RotateAroundAxis(angles:Forward(), 90)
		local cfn = fn-1
		for ply,drawable in next,drawables do
			if not ply:IsValid() then drawables[ply] = nil continue end
			
			local rag = ply:GetRagdollEntity()
			
			if drawable~=cfn and not rag then
				continue
			end
			
			local pleyepos = ply:EyePos()
			if pleyepos:Distance(eyepos)>1024 then continue end
			
			
			local data = ply:GetTable()
			
			local pixvis = data.nametag_pixvis
			if not pixvis then
				pixvis = util.GetPixelVisibleHandle()
				data.nametag_pixvis = pixvis
			end
			
			
			
			local pv = util.PixelVisible(pleyepos, 32, pixvis)
			if pv > 0 then
				
				local a = render.GetLightColor(pleyepos)
				local R,G,B=a.x,a.y,a.z 
				if (R+R+B+G+G+G) < 0.006 
				and render.ComputeDynamicLighting(pleyepos,vdn):Length()==0 
				and render.ComputeDynamicLighting(pleyepos,vup):Length()==0 then
					continue
				end
				
				pv = pv>0.5 and 1 or pv
				draw_nametag(ply,pv*255,data,rag)
			end
		end
		
		
		if tm then
			render.SetToneMappingScaleLinear(tm)
		end
		
		--local bbb=SysTime()
		--print(("|"):rep(math.ceil((bbb-aaa)*20000)))
	end)
	
	-- We can't check for dormancy so this does it for us
	hook.Add("UpdateAnimation", "NameTags", function(pl)
		if pl==localpl and not pl:ShouldDrawLocalPlayer() then return end
		drawables[pl] = fn
	end)
else -- server

	hook.Add("AowlInitialized", "nametags", function()
		
		aowl.AddCommand("title", function(ply, line, target, targetline)
			if not targetline or not ply:CheckUserGroupLevel("developers") then
				ply:SetCustomTitle(line or '')
			else
				local ent = easylua.FindEntity(target)
				if not IsValid(ent) or not ent:IsPlayer() then return false, aowl.TargetNotFound(target) end
				ent:SetCustomTitle(targetline)
			end
		end, "players")
		
		hook.Remove("AowlInitialized", "nametags")
		
	end)
	
end
