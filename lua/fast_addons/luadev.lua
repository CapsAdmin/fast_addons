--add callback system for fetching errors from other clients
--add http loading

local function IsValid(var)
	return IsEntity(var) and var:IsPlayer()
end

luadev = {}

-- make me preprocess include when i'm not tired
function luadev.include(path, base)
	return file.Read("lua/" .. path, "GAME")
end

function luadev.IsPlayerAllowed(ply, script)
	return hook.Run("LuaDevIsPlayerAllowed", ply, script or "")
end

local function GetNick(id)
	local ply = player.GetByUniqueID(id)

	if ply:IsPlayer() then
		return ply:Nick()
	end

	return id
end

function luadev.GetEnvName(info)
	if IsEntity(info.ply) then
		if info.ply:IsPlayer() then
			return info.ply:Nick()
		else
			return "Console"
		end
	end

	return "?????"
end

function luadev.Run(script, info)
	if CLIENT and not IsValid(info.ply) then
		info.ply = LocalPlayer()
	end

	if hook.Call("PreLuaDevRun", GAMEMODE, script, info) ~= false then

		if #script:Split("\n") > 1 then
			local who = luadev.GetEnvName(info) or "self"
			easylua.Print("Running script from " .. tostring(who))
		end

		local data = easylua.RunLua(info.ply, hook.Call("LuaDevPreProcess", GAMEMODE, script) or script)

		if data.error then
			ErrorNoHalt(string.format("a script from %q errored: %s\n", luadev.GetEnvName(info), data.error))
		end

		if #data.args > 0 then
			me = info.ply
			easylua.Print(unpack(data.args))
			me = nil
		end

		if SERVER and #script > 50 then
		
			local filename=string.format(
					"luadev/%s.txt",
					util.CRC(script) -- Saves only one version of identical script even if one exists. We're only interested in who ran it last?
				)

			local extra = string.format("--[==[ %s %s ran this script at %s ]==] ",
							tostring(data.env_name),
							tostring(info.id or "<NoSteamID>"),
							os.date"%x %X")
			
			file.CreateDir("luadev", "DATA")
			file.Write(filename, extra..script, "DATA")
		end

		hook.Call("PostLuaDevRun", GAMEMODE, script, info)

	end
end

function luadev.RunOnServer(script, info, ply)
	info = type(info) == "table" and info or {}
	info.target = "server"
	info.ply = CLIENT and LocalPlayer() or ply
	luadev.RunInternal(script, info)
end

function luadev.RunOnClients(script, info, ply)
	info = type(info) == "table" and info or {}
	info.target = "clients"
	info.ply = CLIENT and LocalPlayer() or ply
	luadev.RunInternal(script, info)
end

function luadev.RunOnClient(script, info, target, ply)
	if not IsValid(target) or (IsValid(target) and not target:IsPlayer()) then return end
	info = type(info) == "table" and info or {}
	info.target = "clients"
	info.ply = CLIENT and LocalPlayer() or ply
	luadev.RunInternal(script, info, target)
end

function luadev.RunOnShared(script, info, ply)
	info = type(info) == "table" and info or {}
	info.target = "shared"
	info.ply = CLIENT and LocalPlayer() or ply
	luadev.RunInternal(script, info)
end

function luadev.RunOnSelf(script, info, ply)
	info = type(info) == "table" and info or {}
	info.target = "self"
	info.ply = CLIENT and LocalPlayer() or ply
	luadev.Run(script, info)
end

function luadev.AddSendCMD(func_name, func)
	func_name = "ld_send_" .. func_name
	concommand.Add(func_name, function(ply, cmd, args)
		print(ply, cmd, args)
		if luadev.IsPlayerAllowed(ply) then
			local path = args[1]
			local persist = args[2]

			local script = file.Read("lua/" .. path, "GAME")
			if script then
				luadev[func](script, {path = path, persist = persist}, ply)
			else
				MsgN(string.format("[ld_send_%s] script %q not found", name, path))
			end
		end
	end,
	function(_, args)
		local name = args:Split(" ")
		name = name[#name] or ""

		local path = name:GetPathFromFilename()




		local scripts = table.Merge(file.Find("lua/"..(name or "") .. "*","GAME"))







		

		for i,_ in pairs(scripts) do
			scripts[i] = func_name .. " " .. path .. scripts[i]
		end

		return scripts
	end)
end

function luadev.AddRunCMD(name, func)
	concommand.Add("ld_run_" .. name, function(ply, cmd, args)
		if luadev.IsPlayerAllowed(ply) then
			local script = table.concat(args, "")

			local err = CompileString(script, luadev.GetEnvName(ply), false)
			if type(err) == "string" then
				MsgN(string.format("[ld_run_%s] error: %q", name, err))
			end

			luadev[func](script, ply, {path = path})
		end
	end)
end

function luadev.AddCMD(name, func)
	luadev.AddSendCMD(name, func)
--	luadev.AddRunCMD(name, func)
end

luadev.AddCMD("sv", "RunOnServer")
luadev.AddCMD("cl", "RunOnClients")
luadev.AddCMD("sh", "RunOnShared")
luadev.AddCMD("self", "RunOnSelf")

if CLIENT then
	function luadev.RunInternal(script, info, target)
		if luadev.IsPlayerAllowed(LocalPlayer(), script) then
			info.ply = LocalPlayer()
			info.targetply = target

			local data = {script = script, info = info}
			if hook.Call("PreLuaDevSend", GAMEMODE, data) ~= false then
				net.Start("luadev")
					net.WriteTable(data)
				net.SendToServer()
			end
		end
	end

	function luadev.NetHook()
		local decoded = net.ReadTable()
		luadev.Run(decoded.script, decoded.info)
	end

	net.Receive("luadev", luadev.NetHook)

	luadev.ReceiveScript = luadev.Run
end

if SERVER then
	util.AddNetworkString("luadev")

	luadev.PersistentScripts = {}

	function luadev.RunInternal(script, info, ply)
		if info.target == "server" or info.target == "shared" then
			luadev.Run(script, info)
		end
		if info.target == "clients" or info.target == "shared" then
			local data = {script = script, info = info}
			if hook.Call("PreLuaDevSend", GAMEMODE, data) ~= false then
				net.Start("luadev")
					net.WriteTable(data)
				if ply then net.Send(ply) else net.Broadcast() end
			end

			if info.persist then
				info.persist = nil
				luadev.PersistentScripts[info.path] = {script = script, info = info}
			end
		end
	end

	hook.Add("PlayerInitialSpawn", "luadev", function(ply)
		local nick = ply:Nick()
		timer.Simple(1, function()
			if not ply:IsValid() or not ply:IsPlayer() then return end

			for path, data in pairs(luadev.PersistentScripts) do
				luadev.RunInternal(data.script, data.info, ply)
				print(Format("sending persistent luadev script %q to %s", path, nick))
			end
		end)
	end)

  function luadev.NetHook(len, ply)
		if !ply or !luadev.IsPlayerAllowed(ply,'') then Msg'[luadev]' print(ply,'not allowed to use NetHook.') return end -- UH OH
		local decoded = net.ReadTable()
		decoded.info.id = ply:SteamID()
		if decoded.info.target == "clients" and decoded.info.targetply then
			luadev.RunInternal(decoded.script, decoded.info, decoded.info.targetply)
		else
			luadev.RunInternal(decoded.script, decoded.info)
		end
	end

	net.Receive("luadev", luadev.NetHook)

	luadev.ReceiveScript = luadev.RunInternal
	
	hook.Add("AowlInitialized", "luadev_aowl_commands", function()
		aowl.AddCommand("l", function(ply, line, target)
			if not line or line=="" then return end
			timer.Simple(0,function()luadev.RunOnServer(line, nil, ply)end)
		end, "developers")

		aowl.AddCommand("ls", function(ply, line, target)
			if not line or line=="" then return end
			timer.Simple(0,function()luadev.RunOnShared(line, nil, ply)end)
		end, "developers")

		aowl.AddCommand("lc", function(ply, line, target)
			if not line or line=="" then return end
			timer.Simple(0,function()luadev.RunOnClients(line, nil, ply)end)
		end, "developers")
	
		aowl.AddCommand("lm", function(ply, line, target)
			if not line or line=="" then return end
			luadev.RunOnClient(line, nil, ply, ply)
		end)
		
		aowl.AddCommand("lb", function(ply, line, target)
			if not line or line=="" then return end
			luadev.RunOnClient(line, nil, ply, ply)
			timer.Simple(0,function()luadev.RunOnServer(line, nil, ply)end)
		end, "developers")
		
		aowl.AddCommand("print", function(ply, line, target)
			if not line or line=="" then return end
			timer.Simple(0,function()luadev.RunOnServer("print(" .. line .. ")", nil, ply)end)
		end, "developers")

		aowl.AddCommand("table", function(ply, line, target)
			if not line or line=="" then return end
			timer.Simple(0,function()luadev.RunOnServer("PrintTable(" .. line .. ")", nil, ply) end)
		end, "developers")
		
		aowl.AddCommand("keys", function(ply, line, target)
			if not line or line=="" then return end
			luadev.RunOnServer("for k, v in pairs(" .. line .. ") do print(k) end", nil, ply)
		end, "developers")

		aowl.AddCommand("printc", function(ply, line, target)
			if not line or line=="" then return end
			luadev.RunOnClients("easylua.PrintOnServer(" .. line .. ")", nil, ply)
		end, "developers")
		
		aowl.AddCommand("printm", function(ply, line, target)
			if not line or line=="" then return end
			luadev.RunOnClient("easylua.PrintOnServer(" .. line .. ")", nil, ply)
		end, "developers")
		
		aowl.AddCommand("printb", function(ply, line, target)
			if not line or line=="" then return end
			luadev.RunOnClient("easylua.PrintOnServer(" .. line .. ")", nil, ply, ply)
			timer.Simple(0,function()
				luadev.RunOnServer("print(" .. line .. ")", nil, ply)
			end)
		end, "developers")

		aowl.AddCommand("say", function(player, line)
			if not line or line=="" then return end
			timer.Simple(0,function()luadev.RunOnClients("Say(" .. line .. ")") end)
		end, "developers")
	end)
end


hook.Add("LuaDevIsPlayerAllowed", "luadev", function(ply, script)
	if ply.CheckUserGroupLevel then
		if ply:CheckUserGroupLevel("developers") then return true end
	elseif ply:IsSuperAdmin() then
		return true
	end
end)

do -- uploader

	local function printf(fmt, ...) print(fmt:format(...)) end

	if SERVER then
		local folder = "addons/fast_addons/lua/fast_addons"
		local choices =
		{
			folder .. "/server",
			folder .. "/client",
			folder .. "/",
		}

		function luadev.WriteToServer(choice, name, code, ply)
			if not hIO then
				require("hio")
				if not hIO then return end
			end

			hIO.Write(string.format("%s/%s.lua", choices[choice], name), code)

			if ply then
				printf("[luadev] Saved lua script by %s in '%s/%s.lua'", ply:Name(), choices[choice], name)
			end
		end
     net.Receive("luadev_upload",function(len, ply)
        local choice = math.Clamp(net.ReadByte(), 1, #choices)
        local filename = net.ReadString()
        local code = net.ReadString()

        if luadev.IsPlayerAllowed(ply, code) then
           luadev.WriteToServer(choice, filename, code, ply)
        end
     end)
	end

	if CLIENT then
		hook.Add("Initialize", "luadev_upload_thing", function()
			local choices =
			{
				"Fast Addon - Server",
				"Fast Addon - Client",
				"Fast Addon - Shared"
			}

			local frame = vgui.Create("DFrame")
			frame:SetTitle("Upload?")
			frame:SetVisible(true)

			function frame:Paint()
				draw.RoundedBox(4,0,0,frame:GetWide(),frame:GetTall(),Color(103,166,166,255))
			end

			function frame:SetCode(code)
				self.code = code
			end

			surface.SetFont("Default")

			for idx, str in pairs(choices) do
				local width = surface.GetTextSize(str)

				local rad = vgui.Create("RadioButton", frame)
					rad:SetText("")
					rad:SetPos(5, idx * 20)
					rad:SizeToContents()
					rad:SetFGColorEx(255, 255, 0, 255)

				local lbl = vgui.Create("DButton", frame)
					lbl:SetPos(20, idx * 20 + 4)
					lbl:SetText(str)
					lbl:SizeToContents()

				-- here come the hacks
				lbl.Paint = function() end

				choices[idx] = rad

				if idx == 1 then
					rad.selected = true
				end

				function lbl:DoClick()
					for idx2, rad in pairs(choices) do
						rad.selected = false
						if idx2 == idx then
							rad:PostMessage("PressButton", "f", 0)
							rad.selected = true
						end
					end
				end
			end

			local upload = vgui.Create("DButton", frame)
			upload:SetText("Upload!")
			upload:Dock(RIGHT)

			local function doupload(name)
				local selected = 1
				for idx, str in pairs(choices) do
					if str.selected then
						selected = idx
						break
					end

					printf("[luadev] Uploading %s.lua to server..", name)

					-- whenever it is added why wait to fix this
						net.Start("luadev_upload")
							net.WriteByte(selected)
							net.WriteString(name)
							net.WriteString(self.code)
						net.SendToServer()
				end
			end

			function upload:DoClick()
				frame:SetVisible(false)
				Derma_StringRequest("What filename?", "What filename to upload as? (leave out .lua)", "testing", doupload)
			end

			function upload:Paint(w, h)
				draw.RoundedBox(6, 0, 0, w or upload:GetWide(), h or upload:GetTall(), upload.Hovered and (upload.Depressed and Color(247,140,120) or Color(207,110,90)) or Color(190,90,50))
			end

			frame:SetSize(200, #choices * 20 + 20)
			frame:Center()
			frame:SetDeleteOnClose(false)
			frame:SetVisible(false)

			function luadev.ShowUploadMenu(code)
				frame:MakePopup()
				frame:SetVisible(true)
				frame:Center()
				frame:SetCode(code)
			end
		end)
	end
end
