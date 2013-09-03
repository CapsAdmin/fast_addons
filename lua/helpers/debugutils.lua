debugutils = debugutils or {} local s = debugutils

do
	local META = {}
	META.__index = META

	function META:__index(key)
		return rawget(s.SliderVars, key) or 0
	end

	function META:__newindex(key, value)

		if CLIENT then
			value = tonumber(value)
			if value then
				RunConsoleCommand("dbgutl_slider_vars", key, value)
			end
		end

		if SERVER then
			value = tonumber(value)
			if value then
				umsg.Start("dbgutl_slider_vars")
					umsg.String(key)
					umsg.Float(value)
				umsg.End()
			end
		end

		(SERVER and print or epoe.Print)(key.. " = ".. value .. " ".. (SERVER and "SERVER" or "CLIENT") .. "\n")
	end

	debugutils.SliderVarsMeta = META
	debugutils.SliderVars = setmetatable({}, META)

	if CLIENT then
		function debugutils.ReceiveSliderVar(umr)
			local key = umr:ReadString()
			local value = umr:ReadFloat()

			rawset(debugutils.SliderVars, key, value)
		end

		usermessage.Hook("dbgutl_slider_vars", debugutils.ReceiveSliderVar)
	end

	if SERVER then
		function debugutils.ReceiveSliderVar(ply, _, args)
			if true or ply:IsAdmin() then
				local key = args[1]
				local value = args[2]

				rawset(s.SliderVars, key, tonumber(value))
			end
		end

		concommand.Add("dbgutl_slider_vars", debugutils.ReceiveSliderVar)
	end
end

if CLIENT then
	debugutils.PrintQueue = {}

	function debugutils.ArgsToString(...)
		local str = ""
		for _, arg in pairs({...}) do
			local type = type(arg)

			if type == "Vector" then
				str = str .. ("Vector(%s, %s, %s)"):format(math.Round(arg.x, 2), math.Round(arg.y, 2), math.Round(arg.z, 2)) .. "\n"
			elseif type == "Angle" then
				str = str .. ("Angle(%s, %s, %s)"):format(math.Round(arg.p, 2), math.Round(arg.y, 2), math.Round(arg.r, 2)) .. "\n"
			elseif type == "string" or type == "number" then
				str = str .. arg .. "\n"
			else
				str = str .. tostring(arg) .. "\n"
			end
		end

		return str
	end

	function debugutils.GarbageCollect()
		for id, data in pairs(s.PrintQueue) do
			if data.time < CurTime() then
				s.PrintQueue[id] = nil
			end
		end
	end

	function debugutils.Print(id, pos, ...)
		debugutils.GarbageCollect()

		local str = s.ArgsToString(...)
		s.PrintQueue[id] = {
			is_entity = IsEntity(pos),
			pos3d = pos,
			lines = str:Split("\n"),
			args = {...},
			time = CurTime() + 0.1,
		}

		timer.Create("debugutils_gc", 10, 0, debugutils.GarbageCollect)
	end

	local box_x, box_y = 0, 0
	local box_width, box_height = 0, 0

	function debugutils.HUDPaint()
		for id, data in pairs(s.PrintQueue) do
			local pos
			if data.is_entity and data.pos3d:IsValid() then
				pos = data.pos3d:GetPos():ToScreen()
			else
				pos = data.pos3d:ToScreen()
			end

			box_x = pos.x
			box_y = pos.x

			surface.SetFont("default")
			surface.SetTextColor(color_white)

			for i, line in pairs(data.lines) do
				local width, height = surface.GetTextSize(line)
				height = height * (i-1)
				surface.SetTextPos(pos.x, pos.y + height)
				surface.DrawText(line)

				box_height = height
				box_width = width > box_width and width or box_width
			end

			data.box_height = box_height
			data.box_width = box_width
		end
	end
	hook.Add("HUDPaint", "debugutils_HUDPaint", debugutils.HUDPaint)

	timer.Create("debugutils_gc", 10, 0, debugutils.GarbageCollect)

	function debugutils.ReceiveServerMessage(umr)
		local id = umr:ReadString()
		local is_entity = umr:ReadBool()
		local pos

		if is_entity then
			pos = umr:ReadEntity()
		else
			pos = umr:ReadVector()
		end

		local args = glon.decode(umr:ReadString())

		s.Print(id, pos, unpack(args))
	end
	usermessage.Hook("debugutils", debugutils.ReceiveServerMessage)
end

if SERVER then
	function debugutils.Print(id, pos, ...)
		local is_entity = false

		if IsEntity(pos) then
			is_entity = true
		end

		umsg.Start("debugutils")
			umsg.String(tostring(id))
			umsg.Bool(is_entity)

			if is_entity then
				umsg.Entity(pos)
			else
				umsg.Vector(pos)
			end

			umsg.String(glon.encode({...}))
		umsg.End()
	end
end