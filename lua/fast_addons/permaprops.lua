local function HOOK(name) hook.Add(name, "permaprops", permaprops[name]) end

permaprops = {}
permaprops.ClientsideModels = {}
permaprops.FadeDist = 10000
permaprops.DefaultClass = "prop_dynamic"
permaprops.ConvertClass =
{
	prop_physics = "prop_dynamic",
	prop_effect = function(ent)
		return ent.AttachedEntity
	end,
}

permaprops.SpecialProps =
{
	["models/props/de_tides/tides_streetlight.mdl"] = function(ent)

	end,

	["models/props/de_inferno/light_streetlight.mdl"] = function(ent)
		if SERVER then
			local light = ents.Create("gmod_light")
			light:Spawn()
			light:Activate()
			light:SetParent(ent)
			light:SetPos(Vector(0,0,152))
			light:GetPhysicsObject():EnableMotion(false)

			light:SetLightColor(255, 180, 50)
			light:SetBrightness(2)
			light:SetLightSize(550)
			if permaprops.FadeDist > 0 then
				light:SetKeyValue("fademaxdist", permaprops.FadeDist)
			end
		end
	end,
}

function permaprops.InitPostEntity()
	if aowl then
		aowl.AddCommand("loadmap", function(player, line)
				aowl.CountDown(line, "LOADING PERMAPROPS", function()
					permaprops.LoadMap(nil, true)
				end)
		end, "moderators")
	end
end

HOOK("InitPostEntity")

do -- orientation

	local position
	local parent = NULL

	function permaprops.SetParent(ent)
		ent = ent or NULL
		if ent:IsValid() then
			for k, v in ipairs(ents.GetAll()) do
				if v:IsPermaProp() then
					v:SetParent(ent)
				end
			end
			parent = ent
		end
	end

	function permaprops.GetParent()
		return parent
	end

end

do -- save/load
	function permaprops.CalcCRC(ent)
		local pos = ent:GetPos()
		local ang = ent:GetAngles()
		local mdl = ent:GetModel():lower():Replace("\\", "/")
		local hpos = Vector(math.Round(pos.x/10), math.Round(pos.y/10), math.Round(pos.z/10))
		local hang = Angle(math.Round(ang.p/10), math.Round(ang.y/10), math.Round(ang.r/10))

		local crc = hpos.x .. hpos.y .. hpos.z .. hang.p .. hang.y .. hang.r .. mdl

		return util.CRC(crc)
	end

	function permaprops.ConvertEntity(ent, _spawn)
		local mdl = ent:GetModel()
		if not mdl then return end
		mdl = mdl:lower():Replace("\\", "/")
		local special = permaprops.SpecialProps[mdl:lower()]

		if special then
			special(ent)
		end

		if SERVER then
			ent:SetHealth(99999999999999999)

			ent:SetKeyValue("solid", 6)
			ent:SetKeyValue("disableshadows", 1)
			--ent:SetKeyValue("spawnflags", 64)
			if permaprops.FadeDist > 0 then
				ent:SetKeyValue("fademaxdist", permaprops.FadeDist)
			end

			if _spawn then ent:Spawn() end

			ent:SetMoveType(MOVETYPE_NONE)
			ent:SetSolid(SOLID_VPHYSICS)

			if ent.CollisionRulesChanged then
				ent:CollisionRulesChanged()
			end

			local phys = ent:GetPhysicsObject()

			if phys:IsValid() then
				phys:Sleep()
				phys:EnableMotion(false)

				local a = ent.permaprop_data and ent.permaprop_data.ang or Angle(0)
				phys:SetAngle(Angle(math.Round(a.p, 1), math.Round(a.y, 1), math.Round(a.r, 1)))

			else
				ErrorNoHalt(Format("invalid physics for permaprop Entity(%i) with the model %q", ent:EntIndex(), ent:GetModel()))
			end
		end
	end

	function permaprops.CreateEntity(class)
		if CLIENT then
			local ent = ClientsideModel("error.mdl")
			table.Merge(ent:GetTable(), permaprops.ClientMeta)

			return ent
		end
		if SERVER then
			return ents.Create(class or permaprops.DefaultClass)
		end
	end

	permaprops.SpawnOffset = Vector(0,0,0)
	
	function permaprops.SpawnPermaProp(data)

		-- this isn't working
		if CLIENT then return end

		local ent = permaprops.CreateEntity(data.class ~= "" and data.class)

		ent:SetModel(data.mdl)
		ent:SetMaterial(data.mat or "")
		ent:SetPos(data.pos + permaprops.SpawnOffset)
		ent:SetAngles(data.ang or Angle(0))
		ent.permaprop_data = data
		
		print(ent)

		if data.col.r and data.a then
			ent:SetColor(data.col)
		end

		permaprops.ConvertEntity(ent, true)

		ent:SetPermaProp(true, true)

		if CLIENT then
			table.insert(permaprops.ClientsideModels, ent)
		end

		return ent
	end

	function permaprops.CanSaveEntity(ent, udata)
		if ent:IsPermaProp() then return false end
		if ent:IsWorld() then return false end
		if ent:IsWeapon() then return false end
		if ent:IsPlayer() then return false end
		if ent:IsVehicle() then return false end

		local custom = hook.Call("PermaPropsCanSaveEntity", GAMEMODE, ent, udata)
		if custom == false then return false end

		if not ent:GetModel() then return false end
		if not ent:GetModel():find("%.mdl") then return false end

		return true
	end

	function permaprops.SaveEntity(ent, udata)
		local class = permaprops.ConvertClass[ent:GetClass():lower()]
		if type(class) == "function" then
			ent = class(ent)

		end
		if class == nil then
			class = ent:GetClass()
		end

		if permaprops.CanSaveEntity(ent, udata) == false then return end
		if hook.Call("PermaPropsSaveEntity", GAMEMODE, ent, udata) ~= false then
			local pos = ent:GetPos()
			local ang = ent:GetAngles()
			local mdl = ent:GetModel():lower():Replace("\\", "/")

			local hpos = Vector(math.Round(pos.x/10), math.Round(pos.y/10), math.Round(pos.z/10))
			local hang = Angle(math.Round(ang.p/10), math.Round(ang.y/10), math.Round(ang.r/10))

			local hash = permaprops.CalcCRC(ent)

			-- so it's easier to find stuff you need want to delete something
			hash = (mdl:match(".+/(.+)%.mdl") or mdl:gsub("%p", "_")) .. "_" .. hash
			local path = Format("permaprops/%s/%s.txt", game.GetMap(), hash)

			luadata.WriteFile(path,
				{
					class = class ~= permaprops.DefaultClass and class or "",
					mdl = mdl,
					pos = pos,
					ang = ang,
					mat = ent:GetMaterial() or "",
					col = {ent:GetColor()},
				}
			)

			ent.permaprops_file = path
		end
	end

	function permaprops.SaveMap()
		for key, ent in pairs(ents.GetAll()) do
			permaprops.SaveEntity(ent)
		end
	end

	function permaprops.LoadMap(map, default)
		map = map or game.GetMap():lower()
		permaprops.CleanUp()
		local path = "permaprops/" .. map .. "/"

		if default or hook.Call("PermaPropsLoadMap", GAMEMODE, map) ~= false then
			local files, i = file.Find(path .. "*.txt", _G.net and "DATA" or nil), 1
			timer.Create("permaprops_fileiterator", 0.02, #files, function()
				local name = files[i]

				if not name then timer.Destroy("permaprops_fileiterator") return end

				local data = luadata.ReadFile(path .. name)
				local ent = permaprops.SpawnPermaProp(data)

				ent.permaprops_file = path .. name

				i = i + 1
			end)
		end
	end

	function permaprops.CleanUp()
		if CLIENT then
			for key, ent in pairs(permaprops.ClientsideModels) do
				SafeRemoveEntity(ent)
			end

			permaprops.ClientsideModels = {}
		end
		if SERVER then
			for k, v in ipairs(ents.GetAll()) do
				if v:IsPermaProp() then
					v:Remove()
				end
			end
		end
	end
end

do -- meta
	do -- parachute meta (CLEAN IT UP)

		local ENT = {}

		ENT.ClassName = "parachute"
		ENT.Type = "anim"
		ENT.Base = "base_anim"

		ENT.Model = "models/props_interiors/radiator01a.mdl"

		ENT.PartFence =
		{
			mdl = "models/props_citizen_tech/windmill_blade004b.mdl",
			pos = Vector(-35, -4.2, 6),
			ang = Angle(0, -90, 0),
		}

		ENT.PartPropeller =
		{
			mdl = "models/props_citizen_tech/windmill_blade004a.mdl",
			pos = Vector(-5, 0, 2.55),
			ang = Angle(-90, 0, 0),
		}
		ENT.PartPropellerBase =
		{
			mdl = "models/props_junk/PopCan01a.mdl",
			pos = Vector(-70, 0, 25),
			ang = Angle(-90, 0, 0),
		}

		ENT.Parts = {}
		ENT.Owner = NULL

		function ENT:AttachPart(data)
			local ent = _G.net and ents.CreateClientProp() or ents.Create("prop_physics")
			local pos, ang = LocalToWorld(data.pos, data.ang, self:GetPos(), self:GetAngles())

			ent:SetPos(pos)
			ent:SetAngles(ang)

			ent:SetModel(data.mdl)

			if SERVER then
				ent:PhysicsInit(SOLID_VPHYSICS)
				ent:SetSolid(SOLID_VPHYSICS)
			end

			if CLIENT then
				ent:SetParent(self)
			else
				constraint.Weld(ent, self)
			end

			return ent
		end

		if CLIENT then
			function ENT:Initialize()
				self:OnRemove()

				self.Fence = self:AttachPart(self.PartFence)

				self.Propeller = self:AttachPart(self.PartPropellerBase)
				self.RealPropeller = self.AttachPart(self.Propeller, self.PartPropeller)
			end

			function ENT:OnRemove()
				SafeRemoveEntity(self.Fence)
				SafeRemoveEntity(self.Propeller)
				SafeRemoveEntity(self.RealPropeller)
			end

			ENT.Rotation = 0

			function ENT:Think()
				local prp = self.Propeller
				if prp:IsValid() then
					local vel = WorldToLocal(self:GetVelocity(), Angle(0,0,90), Vector(0), prp:GetAngles())
					local ang = prp:LocalToWorldAngles(Angle(0, (vel.z * FrameTime() * 5), 0))
					prp:SetAngles(ang)
				end
				self:NextThink()
				return true
			end
		end

		if SERVER then
			ENT.Seat = NULL
			ENT.Driver = NULL

			function ENT:Initialize()
				self:SetModel(self.Model)

				self:PhysicsInit(SOLID_VPHYSICS)
				self:SetSolid(SOLID_VPHYSICS)
				self:GetPhysicsObject():SetMass(1000)
				self:SetColor(Color(60,55,55,255))

				self:StartMotionController()

				local seat = ents.Create("vehicle_weapon_seat")
				seat:SetModel("models/Nova/airboat_seat.mdl")
				seat:SetPos(self:GetPos())
				seat:SetAngles(self:GetAngles() + Angle(180,-90,90))
				seat:Spawn()
				seat:SetParent(self)
				seat:SetColor(Color(0,0,0,0))
				self.Seat = seat

				local base = self:AttachPart(self.PartPropellerBase)
					base:GetPhysicsObject():SetMass(100)
					base:SetNoDraw(true)
				self.Propeller = base
			end

			function ENT:OnRemove()
				SafeRemoveEntity(self.Seat)
				SafeRemoveEntity(self.Propeller)
			end

			function ENT:SetDriver(ply)
				if IsValid(ply.Parachute) then
					ply.Parachute:DropDriver()
				end
				self:SetOwner(ply)
				self.Driver = ply
				ply.Parachute = self
				self.Seat:Enter(ply)
			end

			function ENT:GetDriver()
				return self.Seat:IsValid() and self.Seat:GetDriver() or NULL
			end

			function ENT:DropDriver()
				if self.Seat:IsValid() then
					self.Seat:Drop()
				end
			end

			function ENT:GetBase()
				return self.Propeller or NULL
			end

			function ENT:PhysicsSimulate(phys)
				if self:WaterLevel() == 3 then
					self:Remove()
				end

				-- base er en popcan som sitter i midten på toppen
				local base = self:GetBase()
				if base:IsValid() then
					local basephys = base:GetPhysicsObject()

					if basephys:IsValid() then
						local ply = self:GetDriver()
						if ply:IsPlayer() then
							basephys:AddVelocity(basephys:GetVelocity() * -0.5)

							phys:AddVelocity(self:GetForward() * -phys:GetVelocity():Dot(self:GetForward()) * 0.1)

							local ang = ply:EyeAngles()
							phys:AddAngleVelocity(Vector((-ang.y+90) * 0.4, 0, 0))
							ang.p = math.Clamp(ang.p, -30, 30)
							basephys:AddVelocity(self:LocalToWorldAngles(ang):Up() * -100)

							phys:AddAngleVelocity(phys:GetAngleVelocity() * -0.5)

						else
							self:Remove()
						end
					end
				end

				self:NextThink(CurTime())
				return true
			end
		end

		scripted_ents.Register(ENT, ENT.ClassName, true)
	end
	-- weapon
	do
		local SWEP = {Primary = {}, Secondary = {}}

		SWEP.Base = "weapon_base"

		SWEP.ClassName = "permaprop_tool"
		SWEP.PrintName = "PermaProp Maker"
		SWEP.Instructions = "primary attack to make and secondary to unmake"

		SWEP.HoldType = "pistol"

		SWEP.Primary.Automatic = false
		SWEP.Secondary.Automatic = false

		SWEP.Primary.TakeAmmo  = 0
		SWEP.Secondary.TakeAmmo  = 0

		if CLIENT then
			function SWEP.CommandEffect(ent, bool, udata)
				if IsEntity(udata) and udata:IsPlayer() then
					if bool then
						notification.AddLegacy(udata:Nick() .. " permapropped " .. ent:GetModel():match(".+/(.+)%.mdl"), NOTIFY_GENERIC, 2)
					else
						notification.AddLegacy(udata:Nick() .. " unpermapropped " .. ent:GetModel():match(".+/(.+)%.mdl"),1, 2)
					end
				end
			end
			hook.Add("OnPermaPropSet", "permaprop_command", SWEP.CommandEffect)

			local mat = Material("models/shiny")
						
			function SWEP:DrawOverlay()
				local tr = self.Owner:GetEyeTrace()
				local ent = tr.Entity

				if ent:IsValid() and not ent:IsWorld() then
					local m = (self.Owner == LocalPlayer() and 1 or 0.4)

					render.SetBlend(0.6 * m)
						render.MaterialOverride(mat)
							if ent:IsPermaProp() then
								render.SetColorModulation(0.4 * m, 0.4 * m, 6 * m)
							else
								render.SetColorModulation(6 * m, 0.4 * m, 0.4 * m)
							end

								ent:DrawModel()

							render.SetColorModulation(1, 1, 1)
						render.MaterialOverride()
					render.SetBlend(1)
				end
			end

			hook.Add("PostDrawTranslucentRenderables", "FindPermaprops", function()
				for key, ply in pairs(player.GetAll()) do
					local wep = ply:GetActiveWeapon()
					if wep:IsWeapon() and wep:GetClass() == SWEP.ClassName then
						wep:DrawOverlay()
					end
				end
			end)

			SWEP.PrimaryAttack = function() end
			SWEP.SecondaryAttack = function() end
		end

		if SERVER then

			function SWEP:Initialize()
			end

			function SWEP:SetPerma(bool)
				local trace = self.Owner:GetEyeTrace()
				local ent = trace.Entity

				if ent:IsValid() and (not ent.CPPIGetOwner or ((ent:CPPIGetOwner() == self.Owner) or self.Owner:CheckUserGroupLevel("moderators"))) then
					if bool then
						if permaprops.CanSaveEntity(ent) then
							ent:SetPermaProp(true, nil, self.Owner)
							ent:EmitSound("buttons/button9.wav", 70, bool and 100 or 80 )
						else
							ent:EmitSound("buttons/button10.wav", 70, 70)
						end
					else
						if ent:IsPermaProp() then
							ent:SetPermaProp(false, nil, self.Owner)
							ent:EmitSound("buttons/button10.wav", 70)
						end
					end
				end
			end

			function SWEP:PrimaryAttack()
				self:SetPerma(true)
			end

			function SWEP:SecondaryAttack()
				self:SetPerma(false)
			end
		end

		weapons.Register(SWEP, SWEP.ClassName, true)
	end

	do -- server
		local META = FindMetaTable("Entity")

		function META:IsPermaProp()
			return self:GetNWBool("permaprops")
		end

		function META:SetPermaProp(bool, skip_save, udata)
			if self.CollisionRulesChanged then
				self:CollisionRulesChanged()
			end

			if SERVER then
				if bool then
					permaprops.ConvertEntity(self)
				end

				if not skip_save then
					if bool then
						permaprops.SaveEntity(self, udata)
					else
						if hook.Call("PermaPropsDeleteEntity", GAMEMODE, self, udata) ~= false then
							if self.permaprops_file then
								file.Delete(self.permaprops_file, _G.net and "DATA" or nil)
							end
						end
					end
				end

				udata = udata or NULL
				udata = glon.encode(udata)

				umsg.Start("permaprops")
					umsg.Entity(self)
					umsg.Bool(bool)
					umsg.String(udata)
				umsg.End()

				self:SetNWBool("permaprops", bool)
			end

			if CLIENT and udata and #udata ~= 0 then
				udata = glon.decode(udata)
			end

			hook.Call("OnPermaPropSet", GAMEMODE, self, bool, udata)
		end

		if CLIENT then
			function permaprops.PermaPropMessage(umr)
				local ent = umr:ReadEntity()
				local bool = umr:ReadBool()
				local udata = umr:ReadString()

				if ent:IsValid() and not ent:IsPlayer() then
					ent:SetPermaProp(bool, nil, udata)
				end
			end

			usermessage.Hook("permaprops", permaprops.PermaPropMessage)
		end
	end
end

do -- hook
	if CLIENT then
		local tab =
		{
			["$pp_colour_mulr"] = 0,
			["$pp_colour_mulg"] = 0,
			["$pp_colour_addr"] = 0,
			["$pp_colour_addg"] = 0,
			["$pp_colour_addb"] = 0,
			["$pp_colour_colour"] = 1,
			["$pp_colour_contrast"] = 1,
			["$pp_colour_brightness"] = 0,
		}

		local mult = 0
		usermessage.Hook("permaprops_parachutespawn", function()
			hook.Add( "RenderScreenspaceEffects", "EEK",  function()
				mult = mult + (FrameTime() * 0.1)

				if mult > 1 then
					hook.Remove( "RenderScreenspaceEffects", "EEK" )
					mult = 0
				else

					tab["$pp_colour_contrast"] = mult,
					DrawColorModify(tab)
				end
			end)
		end)
	end

	if SERVER and game.GetMap():lower():find("endlessocean") then
		function permaprops.AttachPropellerInitialize(ply)
			ply:SetPos(Vector()*16000)
			ply:Kill()
			ply:GetRagdollEntity():Remove()
		end
		
		function permaprops.AttachPropeller(ply)
			if false then
			if IsValid(ply.Parachute) then
				ply.Parachute:Remove()
			end

			local self = ents.Create("parachute")

			self:Spawn()

			self:SetPos(Vector(math.Rand(-1,1) * 300, math.Rand(-1, 1) * 300, 3900))
			self:SetAngles(Angle(0,0,0))
			ply:SetPos(self:GetPos())

			self:GetPhysicsObject():SetVelocity(vector_origin)

			self.Seat.up_offset = 43.5
			self.Seat.right_offset = 1.75
			self.Seat.forward_offset = 0

			self:SetDriver(ply)

			SendUserMessage("permaprops_parachutespawn", ply)
			end
			ply:Give("permaprop_tool")
		end

		hook.Add("PlayerSpawn", "permaprops_parachute", permaprops.AttachPropeller)
		hook.Add("PlayerInitialSpawn", "permaprops_parachute", permaprops.AttachPropellerInitialize)
	end

	local not_allowed =
	{
		colour = 1,
		material = 1,
		ballsocket_ez = 1,
		ballsocket_adv = 1,
		ballsocket = 1,
		motor = 1,
		axis = 1,
		remover = 1,
		weld_ez = 1,
	}

	function permaprops.CanTool(ply, trace, toolmode)
		local ent = trace.Entity

		if ent:IsPermaProp() and not_allowed[toolmode] then
			return false
		end
	end

	function permaprops.PhysgunPickup(ply, ent)
		if ent:IsPermaProp() then
			return false
		else
			ply.permaprop_pickup = ent
		end
	end

	function permaprops.PhysgunDrop(ply, ent)
		ply.permaprop_pickup = NULL
	end

	function permaprops.OnPhysgunFreeze(_,_, ent, ply)
		ply.permaprop_pickup = NULL
	end

	function permaprops.ShouldCollide(a, b)
		if a:IsPermaProp() and b:IsPermaProp() then
			return false
		end
	end

	function permaprops.CanPlayerUnfreeze(_, ent)
		if ent:IsPermaProp() then
			return false
		end
	end

	HOOK("CanTool")
	HOOK("PhysgunPickup")
	HOOK("PhysgunDrop")
	HOOK("OnPhysgunFreeze")
	HOOK("ShouldCollide")
	HOOK("CanPlayerUnfreeze")

	if SERVER then

		function permaprops.HidePropsThink()
			if permaprops.FadeDist > 0 then
				for key, ent in pairs(ents.GetAll()) do
					if ent:IsPermaProp() then
						local not_visible = true
						for key, ply in pairs(player.GetAll()) do
							if ent:GetPos():Distance(ply:EyePos()) < permaprops.FadeDist then
								not_visible = false
							end
						end
						ent:SetNoDraw(not_visible)
					end
				end
			end
		end
		timer.Create("optimize_permaprops", 0.2, 0, permaprops.HidePropsThink)
	end

	HOOK("PostInitEntity")
end