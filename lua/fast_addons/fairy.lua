local ENT = {}

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.ClassName = "fairy"

ENT.Size = 1
ENT.Visibility = 0

if CLIENT then

	local function VectorRandSphere()
		return Angle(math.Rand(-180,180), math.Rand(-180,180), math.Rand(-180,180)):Up()
	end

	function ENT:SetFairyHue(hue)
		self.Color = HSVToColor(hue, 0.4, 1)
	end
	
	function ENT:SetFairyColor(color)
		self.Color = color
	end

	do -- sounds
		ENT.next_sound = 0
	
		function ENT:CalcSoundQueue(play_next_now)
			if #self.SoundQueue > 0 and (play_next_now or self.next_sound < CurTime()) then
				
				-- stop any previous sounds
				if self.current_sound then
					self.current_sound:Stop()
				end
							
				-- remove and get the first sound from the queue
				local data = table.remove(self.SoundQueue, 1)
			
				if data.snd and data.pitch then
					data.snd:PlayEx(100, data.pitch)			
					
					-- pulse the fairy a bit so it looks like it's talking
					self:PulseSize(1.3, 1.8)
					
					-- store the sound so we can stop it before we play the next sound
					self.current_sound = data.snd
				end
				
				-- store when to play the next sound
				self.next_sound = CurTime() + data.duration
			end
		end
				
		function ENT:AddToSoundQueue(path, pitch, play_now)
			
			-- if play_now is true don't add to the old queue
			local queue = play_now and {} or self.SoundQueue
			
			if path == "." then
				table.insert(
					queue,
					{
						duration = 0.5,
					}
				)
			else	
				table.insert(
					queue,
					{
						snd = CreateSound(self, path),
						pitch = pitch,
						
						-- get the sound length of the sound and scale it with the pitch above
						-- the sounds have a little empty space at the end so subtract 0.05 seconds from their time
						duration = SoundDuration(path) * (pitch / 100) - 0.05,
					}
				)
			end

			self.SoundQueue = queue
			
			if play_now then
				self:CalcSoundQueue(true)
			end
		end
		
		-- makes the fairy talk without using a real language
		-- it's using sounds from a zelda game which does the same thing
		function ENT:PlayPhrase(text)
			text = text:lower()
			text = text .. " "
			
			local queue = {}
			local total_duration = 0
			
			-- split the sentence up in chunks
			for chunk in (" "..text.." "):gsub("%p", "%1 "):gmatch("(.-)[%s]") do
				if chunk:Trim() ~= "" then
					if chunk == "." then
						self:AddToSoundQueue(chunk) 
					else
						-- this will use each chunk as random seed to make sure it picks the same sound for each chunk every time
						local path = "alan/midna/speech"..tostring(math.max(tonumber(util.CRC(chunk))%47, 1))..".wav"
						
						-- randomize pitch a little, makes it sound less static
						local pitch = math.random(120,125)
						
						self:AddToSoundQueue(path, pitch)
					end
				end
			end
		end
		
		function ENT:Laugh()
			local path = "alan/nymph/NymphGiggle_0"..math.random(9)..".wav"
			local pitch = math.random(95,105)
			
			self:AddToSoundQueue(path, pitch, true)

			self.Laughing = true
		end
		
		function ENT:Ouch()
			local path = "alan/nymph/NymphHit_0"..math.random(4)..".wav"
			local pitch = math.random(95,105)
			
			self:AddToSoundQueue(path, pitch, true)
			
			-- make the fairy hurt for about 1-2 seconds
			self.Hurting = true
			
			timer.Simple(math.Rand(1,2), function() 
				if self:IsValid() then 
					self.Hurting = false 
				end 
			end)
		end
		
		-- this doesn't need to use the sound queue
		function ENT:Bounce()
			local csp = CreateSound(self, "alan/bonk.wav")
			csp:PlayEx(100, math.random(150, 220))
			csp:FadeOut(math.random()*0.75)
		end
	end

	local wing_mdl = Model("models/python1320/wing.mdl")
	local wing_mat = Material("alan/wing")

	ENT.WingSpeed = 6.3
	ENT.FlapLength = 30
	ENT.WingSize = 0.4

	ENT.SizePulse = 1

	local function CreateEntity(mdl) 	
		local ent = ents.CreateClientProp()

		ent:SetModel("error.mdl") 
		
		function ent:RenderOverride()
			if not ENT.ObjWing then return end
						
			local matrix = Matrix()
		
			matrix:SetAngles(self:GetAngles())
			matrix:SetTranslation(self:GetPos())
			matrix:Scale(self.scale)
				
			render.SetMaterial(wing_mat)
						
			cam.PushModelMatrix(matrix)
				render.CullMode(1)
				ENT.ObjWing:Draw()
				render.CullMode(0)
				ENT.ObjWing:Draw()
			cam.PopModelMatrix()
		end
		
		return ent 
	end

	function ENT:Initialize()	
		if pac and pac.urlobj then
			pac.urlobj.GetObjFromURL("http://dl.dropbox.com/u/244444/wing.obj", function(meshes)
				if self:IsValid() then
					ENT.ObjWing = select(2, next(meshes))
				end
			end)
		end
	
		self.SoundQueue = {}
		
		self.Emitter = ParticleEmitter(vector_origin)
		self.Emitter:SetNoDraw(true)

		self:InitWings()

		self.light = DynamicLight(self:EntIndex())

		self.flap = CreateSound(self, "alan/flap.wav")
        self.float = CreateSound(self, "alan/float.wav")

        self.flap:Play()
        self.float:Play()

        self.flap:ChangeVolume(0.2)

		-- randomize the fairy hue
		self:SetFairyHue(tonumber(util.CRC(self:EntIndex()))%360)
		
		-- random size
		self.Size = (tonumber(util.CRC(self:EntIndex()))%100/100) + 0.5
		
		self.pixvis = util.GetPixelVisibleHandle()
	end
	
	function ENT:InitWings()
		self.leftwing = CreateEntity(wing_mdl)
		self.rightwing = CreateEntity(wing_mdl)
		self.bleftwing = CreateEntity(wing_mdl)
		self.brightwing = CreateEntity(wing_mdl)

		self.leftwing:SetNoDraw(true)
		self.rightwing:SetNoDraw(true)
		self.bleftwing:SetNoDraw(true)
		self.brightwing:SetNoDraw(true)

		self.leftwing:SetMaterial(wing_mat)
		self.rightwing:SetMaterial(wing_mat)
		self.bleftwing:SetMaterial(wing_mat)
		self.brightwing:SetMaterial(wing_mat)
	end

	-- draw after transparent stuff
	ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

	function ENT:DrawTranslucent()
		self:CalcAngles()

		self:DrawParticles()
		self:DrawWings(0)
		self:DrawSprites()
	end
	
	function ENT:Draw()
		self:DrawTranslucent()
	end

	function ENT:Think()
		self:CalcSounds()
		self:CalcLight()
		self:CalcPulse()
		self:CalcSentence()

		self:NextThink(CurTime())
		return true
	end
	
	function ENT:PulseSize(min, max)
		self.SizePulse = math.Rand(min or 1.3, max or 1.8)
	end
	
	function ENT:CalcPulse()
		self.SizePulse = math.Clamp(self.SizePulse + ((1 - self.SizePulse) * FrameTime() * 5), 1, 3)
	end

	function ENT:CalcAngles()
		if self.Hurting then return end

		local vel = self:GetVelocity()
		if vel:Length() > 10 then
			local ang = vel:Angle()
			self:SetAngles(ang)
			self:SetRenderAngles(ang)
			self.last_ang = ang
		elseif self.last_ang then
			self:SetAngles(self.last_ang)
		end
	end
	
	local letters = {
		a = "ᗩ",
		b = "ᕊ",
		c = "ᑕ",
		d = "ᖱ",
		e = "ᙓ",
		f = "ℱ",
		g = "ᘐ",
		h = "ᖺ",
		i = "ᓰ",
		j = "ᒎ",
		k = "Ḱ",
		l = "ᒪ",
		m = "ᙢ",
		n = "ﬡ",
		o = "ᗝ",
		p = "ᖰ",
		q = "ᕴ",
		r = "ᖇ",
		s = "ᔕ",
		t = "♈",
		u = "ᘎ",
		v = "Ⅴ",
		w = "ᙡ",
		x = "ჯ",
		y = "Ꭹ",
		z = "ᔓ",
	}

	-- this kind of mimics player chat
	function ENT:Say(txt)
		if LocalPlayer():EyePos():Distance(self:GetPos()) > 2000 then return end
				
		if self.say_txt then
			self:SayChat(self.say_txt)
		end
				
		self.sentence_i = nil
		self.say_txt = txt
	end
	
	function ENT:SayChat(txt)
		self:PlayPhrase(txt)
				
		local tbl = {}

		if self.is_dead then
			table.insert( tbl, Color( 255, 30, 40 ) )
			table.insert( tbl, "*DEAD* " )
		end

		local time = os.date("*t")

		table.insert(tbl, self.Color)
		table.insert(tbl, "Alan")
		table.insert(tbl, color_white)
		table.insert(tbl, ": " .. txt)

		if chat.AddTimeStamp then chat.AddTimeStamp(tbl) end
		
		chat.AddText(unpack(tbl))
	end
	
	function ENT:Ponder()
		self.pondering = true
	end
	
	function ENT:CalcSentence()
		if self.pondering then
			self.draw_text = ("."):rep( math.floor(CurTime() * 2) % 4 )
		end
	
		if not self.say_txt then return end

		self.pondering = false
		
		if not self.sentence_i then
			self.sentence_i = 0
			self.sentence_max = #self.say_txt
			self.sentence_tbl = {}
			self.sentence_next_char = 0
			self.draw_text = ""
			
			for char in self.say_txt:gmatch("(.)") do			
				table.insert(self.sentence_tbl, 1, char)
			end
		else
			if self.sentence_next_char > CurTime() then return end
			
			local char = table.remove(self.sentence_tbl)
			if char then
				self.draw_text = (self.draw_text or "") .. (letters[char:lower()] or char)
				self.sentence_i = self.sentence_i + 1
				self.sentence_next_char = CurTime() + (math.random() * 0.15)
			else
				self.sentence_clear = self.sentence_clear or CurTime() + 0.5
				if self.sentence_clear < CurTime() then
					self:SayChat(self.say_txt)
					
					self.say_txt = nil
					self.draw_text = nil
					self.sentence_max = nil
					self.sentence_i = nil
					self.sentence_tbl = nil
					self.sentence_next_char = nil
					self.sentence_clear = nil
				end
			end
		end
	end

	function ENT:CalcSounds()
		local own = self:GetOwner()
		
		if own:IsValid() and own.VoiceVolume then
			self.SizePulse = (own:VoiceVolume() * 10) ^ 0.5
		end
	
		if self.Hurting then
			self.flap:Stop()
		else
			self.flap:Play()
			self.flap:ChangeVolume(0.2)
		end

	    local length = self:GetVelocity():Length()

        self.float:ChangePitch(length/50+100)
        self.float:ChangeVolume(length/100)

        self.flap:ChangePitch((length/50+100) + self.SizePulse * 20)
		self.flap:ChangeVolume(0.1+(length/100))
		
		self:CalcSoundQueue()
	end

	function ENT:CalcLight()
		if self.light then
			self.light.Pos = self:GetPos()

			self.light.r = self.Color.r
			self.light.g = self.Color.g
			self.light.b = self.Color.b

			self.light.Brightness = self.Size * 1
			self.light.Size = math.Clamp(self.Size * 512, 0, 1000)
			self.light.Decay = self.Size * 32 * 5
			self.light.DieTime = CurTime() + 1
		end
	end

	local glow = Material("sprites/light_glow02_add")
	local warp = Material("particle/warp2_warp")
	local mouth = Material("icon16/add.png")
	local blur = Material("sprites/heatwave")
	
	local eye_hurt = Material("sprites/key_12")
	local eye_idle = Material("icon16/tick.png")
	local eye_happy = Material("icon16/error.png")
	local eye_heart = Material("icon16/heart.png")

	ENT.Blink = math.huge

	function ENT:DrawSprites()
		local pos = self:GetPos()
		local pulse = math.sin(CurTime()*2) * 0.5

		render.SetMaterial(warp)
			render.DrawSprite(
				pos, 12 * self.Size + pulse,
				12 * self.Size + pulse,
				Color(self.Color.r, self.Color.g, self.Color.b, 100)
			)

		render.SetMaterial(blur)
			render.DrawSprite(
				pos, (1-self.SizePulse) * 20,
				(1-self.SizePulse) * 20,
				Color(10,10,10, 1)
			)

		render.SetMaterial(glow)
			render.DrawSprite(
				pos,
				50 * self.Size,
				50 * self.Size,
				Color(self.Color.r, self.Color.g, self.Color.b, 150)
			)
			render.DrawSprite(
				pos,
				30 * self.Size,
				30 * self.Size,
				self.Color
			)

		local fade_mult = math.Clamp(-self:GetForward():Dot((self:GetPos() - LocalPlayer():EyePos()):Normalize()), 0, 1)

		if fade_mult ~= 0 then
		
			if self.Hurting then
				render.SetMaterial(eye_hurt)
			else
				render.SetMaterial(eye_heart)
			end
			
			if self.Blink > CurTime() then
				for i = 0, 1 do
					render.DrawSprite(
						pos + (self:GetRight() * (i == 0 and 0.8 or -0.8) + self:GetUp() * 0.7) * self.Size,

						0.5 * fade_mult * self.Size,
						0.5 * fade_mult * self.Size,

						Color(10,10,10,200 * fade_mult)
					)
				end
			else
				self.Blink = math.random() < 0.99 and CurTime()-0.2 or math.huge
			end
			
			render.SetMaterial(mouth)
			
			render.DrawSprite(
				pos + (self:GetRight() * -0.05 -self:GetUp() * 0.7) * self.Size,

				0.6 * fade_mult * self.Size * self.SizePulse ^ 1.5,
				0.6 * fade_mult * self.Size * self.SizePulse,

				Color(10,10,10,200*fade_mult)
			)

		end
	end

	function ENT:DrawSunbeams(pos, mult, siz)
		local ply = LocalPlayer()
		local eye = EyePos()
		
		self.Visibility = util.PixelVisible(self:GetPos(), self.Size * 4, self.pixvis)
		
		if self.Visibility > 0 then
			local spos = pos:ToScreen()
			DrawSunbeams(
				0.25, 
				math.Clamp(mult * (math.Clamp(ply:GetAimVector():DotProduct((pos - eye):Normalize()) - 0.5, 0, 1) * 2) ^ 5, 0, 1), 
				siz, 
				spos.x / ScrW(), 
				spos.y / ScrH()
			)
		end
	end

	function ENT:DrawParticles()
		local particle = self.Emitter:Add("particle/fire", self:GetPos() + (VectorRandSphere() * self.Size * 4 * math.random()))
		local mult = math.Clamp((self:GetVelocity():Length() * 0.1), 0, 1)

		particle:SetDieTime(math.Rand(0.5, 2)*self.SizePulse*5)
		particle:SetColor(self.Color.r, self.Color.g, self.Color.b)


		if self.Hurting then
			particle:SetGravity(physenv.GetGravity())
			particle:SetVelocity((self:GetVelocity() * 0.1) + (VectorRandSphere() * math.random(20, 30)))
			particle:SetAirResistance(math.Rand(1,3))
		else
			particle:SetAirResistance(math.Rand(5,15)*10)
			particle:SetVelocity((self:GetVelocity() * 0.1) + (VectorRandSphere() * math.random(2, 5))*(self.SizePulse^5))
			particle:SetGravity(VectorRand() + physenv.GetGravity():Normalize() * (math.random() > 0.9 and 10 or 1))
		end

		particle:SetStartAlpha(0)
		particle:SetEndAlpha(255)

		--particle:SetEndLength(self.Size * 3)
		particle:SetStartSize(math.Rand(1, self.Size*8)/3)
		particle:SetEndSize(0)

		particle:SetCollide(true)
		particle:SetRoll(math.random())
		particle:SetBounce(0.8)
		
		self.Emitter:Draw()
	end
	

	function ENT:DrawWings(offset)		
		if not self.leftwing:IsValid() then 
			self:InitWings()
		return end
		
		local size = self.Size * self.WingSize * 0.75
		local ang = self:GetAngles()
				
		offset = offset or 0
		self.WingSpeed = 6.3 * (self.Hurting and 0 or 1)
						
		local leftposition, leftangles = LocalToWorld(Vector(0, 0, 0), Angle(0,TimedSin(self.WingSpeed,self.FlapLength,0,offset), 0), self:GetPos(), ang)
		local rightposition, rightangles = LocalToWorld(Vector(0, 0, 0), Angle(0, -TimedSin(self.WingSpeed,self.FlapLength,0,offset), 0), self:GetPos(), ang)
		
		
		self.leftwing:SetPos(leftposition)
		self.rightwing:SetPos(rightposition)

		self.leftwing:SetAngles(leftangles)
		self.rightwing:SetAngles(rightangles)

		local bleftposition, bleftangles = LocalToWorld(Vector(0, 0, -0.5), Angle(-40, TimedSin(self.WingSpeed,self.FlapLength,0,offset+math.pi)/2, 0), self:GetPos(), ang)
		local brightposition, brightangles = LocalToWorld(Vector(0, 0, -0.5), Angle(-40, -TimedSin(self.WingSpeed,self.FlapLength,0,offset+math.pi)/2, 0), self:GetPos(), ang)

		self.bleftwing:SetPos(bleftposition)
		self.brightwing:SetPos(brightposition)

		self.bleftwing:SetAngles(bleftangles)
		self.brightwing:SetAngles(brightangles)

		render.SuppressEngineLighting(true)
		render.SetColorModulation(self.Color.r/200, self.Color.g/200, self.Color.b/200)
					
		self.leftwing.scale = Vector(0.75,1.25,1)*size
		self.rightwing.scale = Vector(0.75,1.25,1)*size
		
		self.bleftwing.scale = Vector(0.5,1,1)*size
		self.brightwing.scale = Vector(0.5,1,1)*size
						
		self.leftwing:SetupBones()
		self.rightwing:SetupBones()
		self.bleftwing:SetupBones()
		self.brightwing:SetupBones()
		
		self.leftwing:DrawModel()
		self.rightwing:DrawModel()
		self.bleftwing:DrawModel()
		self.brightwing:DrawModel()

		render.SetColorModulation(0,0,0)
		render.SuppressEngineLighting(false)
	end

	function ENT:OnRemove()
        SafeRemoveEntity(self.leftwing)
        SafeRemoveEntity(self.rightwing)
        SafeRemoveEntity(self.bleftwing)
        SafeRemoveEntity(self.brightwing)

		self.flap:Stop()
		self.float:Stop()
	end
	
	local B = 1
	
	local Sw = 8
	local Sh = 4
	
	local fairy_font = "fairy_font"
	surface.CreateFont(
		fairy_font, 
		{
			font = "arial",
			size = 25,
			antialias = true,
			weight = 4,
		}
	)
	
	local eyepos = Vector()
	
	hook.Add("RenderScene", "fairy_eyepos", function(pos) eyepos = pos end)
	
	hook.Add("HUDPaint", "fairy_chatboxes", function()
		for key, ent in pairs(ents.FindByClass("fairy")) do
			if ent.Visibility > 0 and ent.draw_text then
				local pos = ent:GetPos():ToScreen()
				
				local offset = (ent.Size / eyepos:Distance(ent:GetPos())) * 6000
				
				local x = pos.x + offset
				local y = pos.y - offset
				
				surface.SetFont(fairy_font)
				local W, H = surface.GetTextSize(ent.draw_text)
				surface.SetTextPos(x, y - H/2)
												
				draw.RoundedBoxEx(8, 
					x-Sw, 
					y-Sh - H/2, 
					W+Sw*2, 
					H+Sh*2, 
				ent.Color, true, true, false, true)
				draw.RoundedBoxEx(8, 
					x-Sw + B, 
					y-Sh + B - H/2, 
					W+Sw*2 - B*2, 
					H+Sh*2 - B*2, 
				color_black, true, true, false, true)
				
				surface.SetTextColor(color_white)
				surface.DrawText(ent.draw_text)
			end
		end
	end)
	
	hook.Add("RenderScreenspaceEffects", "fairy_sunbeams", function()
		if not render.SupportsPixelShaders_2_0() then 
			hook.Remove("RenderScreenspaceEffects", "fairy_sunbeams")
			return
		end
		
		local ents = ents.FindByClass("fairy")
		local count = #ents
		for key, ent in pairs(ents) do
			ent:DrawSunbeams(ent:GetPos(), 0.05/count, 0.025)
		end
	end)

	usermessage.Hook("fairy_func_call", function(umr)
		local ent = umr:ReadEntity()
		local func = umr:ReadString()
		local args = glon.decode(umr:ReadString())

		if ent:IsValid() then
			ent[func](ent, unpack(args))
		end
	end)
end

if SERVER then

	function ENT:Initialize()
		self:SetModel("models/dav0r/hoverball.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:PhysWake()

		self:StartMotionController()

		self:GetPhysicsObject():EnableGravity(false)
		
		self.cookie_id = math.random()
		
		alan.Ask(self.cookie_id, "hi", "Alan", function(answer, uniqueid)
			if not self:IsValid() then return end
			print(answer) 
			alan.Ask(self.cookie_id, "my username is eliashogstvedt@gmail.com", "Alan", function(answer, uniqueid) 
				if not self:IsValid() then return end
				print(answer)
				alan.Ask(self.cookie_id, "my password is IAMMETASTRUCT", "Alan", function(answer, uniqueid) 
					if not self:IsValid() then return end
					print(answer)
					self.ready_to_talk = true

					--[[alan.Ask(self.cookie_id, "can i speak to my hal personality?", "Alan", function(answer, uniqueid) 
						print(answer)
						alan.Ask(self.cookie_id, "ok", "Alan", function(answer, uniqueid) 
							print(answer)
							
							self.ready_to_talk = true
						end)
					end)]]
				end)
			end)
		end)
		
		
		
		
	end

	function ENT:MoveTo(pos)
		self.MovePos = pos
	end

	function ENT:HasReachedTarget()
		return self.MovePos and self:GetPos():Distance(self.MovePos) < 50
	end

	function ENT:PhysicsSimulate(phys)
		if self.GravityOn then return end

		if self.MovePos and not self:HasReachedTarget() then
			phys:AddVelocity(self.MovePos - phys:GetPos())
			phys:AddVelocity(self:GetVelocity() * -0.4)
			self.MovePos = nil
		else
			phys:AddVelocity(math.random() > 0.995 and VectorRand() * 100 or (phys:GetVelocity()*0.01))
			phys:AddVelocity(self:GetVelocity() * -0.05)
		end
	end
	
	function ENT:Think()
		self:PhysWake()
		self:CalcMove()
	end

	function ENT:EnableGravity(time)
		local phys = self:GetPhysicsObject()
		phys:EnableGravity(true)
		self.GravityOn = true

		timer.Simple(time, function()
			if self:IsValid() and phys:IsValid() then
				phys:EnableGravity(false)
				self.GravityOn = false
			end
		end)
	end

	function ENT:CallClientFunction(func, ...)
		umsg.Start("fairy_func_call")
			umsg.Entity(self)
			umsg.String(func)
			umsg.String(glon.encode({...})) -- lol
		umsg.End()
	end

	function ENT:ValidateQuestion(str, ply)
		if str == self.last_question then return end
		
		str = str:gsub("NOTHING", "")
		str = str:gsub("fairy", "alan")
		
		if IsValid(ply) then
			local ent = ply:GetEyeTrace().Entity
			
			if ent:IsValid() then
				str = str:gsub("this", ent:GetModel():match(".+/(.+)%.mdl"))
			end
			
			if str:find("follow me") then
				
			end
		end
		
		self.last_question = str
		
		return str
	end
	
	local hurt_list = 
	{
		"is hurting you", 
		"hates you",
	}
	
	function ENT:Smite(ply)
		self:EmitSound("vo/trainyard/female01/cit_hit0"..math.random(1, 3)..".wav", 100, 150)
		
		self.LastSound = CurTime()
		
		timer.Simple(1, function()
			if ply:IsValid() then
				if not ply.Alive or ply:Alive() then 
					self:EmitSound("ambient/explosions/explode_2.wav")
					
					if ply.Kill then ply:Kill() end
					
					local ent = ply:GetRagdollEntity()
					if ent:IsValid() then
						ent = ply
					end
					
					timer.Simple(0.2, function()
						if not ent:IsValid() then return end
						
						ent:SetName("dissolvemenow" .. tostring(ent:EntIndex()))
						
						local e = ents.Create("env_entity_dissolver")
							e:SetKeyValue("target", "dissolvemenow"..tostring(ent:EntIndex()))
							e:SetKeyValue("dissolvetype", "1")
							e:Spawn()
							e:Activate()
							e:Fire("Dissolve", ent:GetName(), 0)
						SafeRemoveEntityDelayed(e,0.1)
					end)
				end
			end
		end)
	end
	
	function ENT:OnTakeDamage(dmg)
		self:EnableGravity(math.Rand(1,2))
		self:CallClientFunction("Ouch")
		
		local phys = self:GetPhysicsObject()
		phys:AddVelocity(dmg:GetDamageForce())

		local ply = dmg:GetAttacker()
		if ply:IsPlayer() and (not ply.alan_last_hurt or ply.alan_last_hurt < CurTime()) then
			self:PlayerSay(ply, ply:Nick() .. table.Random(hurt_list))
			ply.alan_last_hurt = CurTime() + 1
			self:Smite(ply)
		end
	end

	function ENT:PhysicsCollide(data, phys)
	
		if not self.last_collide  or self.last_collide < CurTime() then
			local ent = data.HitEntity
			if ent:IsValid() and not ent:IsPlayer() and ent:GetModel() then
				self:WorldSay("let's talk about " .. ent:GetModel():match(".+/(.+)%.mdl"))
				self.last_collide = CurTime() + 1
			end
		end
	
		if data.Speed > 50 and data.DeltaTime > 0.2 then
			self:EnableGravity(math.Rand(0.5,1))
			self:CallClientFunction("Ouch")
			self:CallClientFunction("Bounce")
			self.follow_ent = NULL
		end

		self:LaughAtMe()

		phys:SetVelocity(phys:GetVelocity():Normalize() * data.OurOldVelocity:Length() * 0.99)
	end

	function ENT:LaughAtMe()
		local fairies = ents.FindByClass("fairy")
		for	key, ent in pairs(fairies) do
			if ent ~= self and math.random() < 1 / #fairies then
				ent:CallClientFunction("Laugh")
			end
		end
	end
	
	function ENT:WorldSay(str)
		if not self.ready_to_talk then return end
		
		str = self:ValidateQuestion(str)
		if not str then return end
		alan.Ask(self.cookie_id, str, "Alan", function(answer, uniqueid)
			if self:IsValid() then
				hook.Run("AlanSay", answer)
				
				answer = answer:gsub("PLAYERNAME", "everyone")
				answer = answer:gsub("you", "someone")
				
				self:CallClientFunction("Say", answer)
			end
		end)
	end
	
	function ENT:PlayerSay(ply, str)
		if not self.ready_to_talk then return end
		
		str = self:ValidateQuestion(str, ply)
		if not str then return end
		
		if 
			self.focused_player == ply or 
			str:lower():find("alan") or 
			str:lower():find("fairy") or 
			self:GetPos():Distance(ply:EyePos()) < 300 and 
			ply:GetAimVector():Dot((self:GetPos() - ply:EyePos()):Normalize()) > 0.8 
		then
			self.focused_player = ply
			alan.Ask(self.cookie_id, str, "Alan", function(answer, uniqueid)
				if self:IsValid() and ply:IsValid() then
					hook.Run("AlanSay", answer)
					
					answer = answer:gsub("PLAYERNAME", ply:Nick())
					self:CallClientFunction("Say", ply:Nick() .. ", " .. answer)
				end
			end)
		end
	end
	
	hook.Add("PlayerSay", "fairy", function(ply, str)
		for key, ent in pairs(ents.FindByClass("fairy")) do
			ent:PlayerSay(ply, str)
		end
	end)
	
	ENT.follow_ent = NULL
	
	function ENT:CalcMove()
		if math.random() > 0.99 then
			for _, ent in RandomPairs(ents.FindInSphere(self:GetPos(), 500)) do
				if 
					ent ~= self and
					ent:GetPhysicsObject():IsValid() and
					ent:GetModel() and
					ent:BoundingRadius() > 10 and
					util.TraceHull({start = self:EyePos(), endpos = ent:EyePos(), filter = {ent, self}}).Fraction == 1
				then	
					self.follow_ent = ent
					
					if ent:IsPlayer() then
						if ent.IsAFK and ent:IsAFK() then
							self:WorldSay("did you know that " .. ent:Nick() .. " is currently not here?")
						end
					end
					
					break
				end
			end
		end
		
		if self.follow_ent:IsValid() then
			self:MoveTo(self.follow_ent:EyePos() + physenv.GetGravity():GetNormalized() * 30)
		end
	end
	
	local function GetRandomFairyFromSeed(seed, self)
		local fairies = ents.FindByClass("fairy")
		local id = tonumber(util.CRC(seed))%#fairies
		
		for key, ent in pairs(fairies) do
			if key == id then
				return ent
			end
		end
		
		return select(2, next(fairies))
	end
end

scripted_ents.Register(ENT, ENT.ClassName, true)

if me then
	for key, ent in pairs(ents.FindByClass("fairy")) do
		ent:SetTable(table.Copy(ENT))
		ent:Initialize()
	end
end
