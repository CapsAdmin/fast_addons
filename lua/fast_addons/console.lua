console = console or {}

__OLDMSG = __OLDMSG or Msg
__OLDMSGN = __OLDMSGN or MsgN
__OLDPRINT = __OLDPRINT or print

local result = ""

function console.StartCapture()
	result = ""

	Msg = function(...)
		for key, value in pairs({...}) do
			result = result .. tostring(value)
		end
	end

	print = function(...)
		for key, value in pairs({...}) do
			result = result .. tostring(value)
		end

		result = result .. "\n"
	end

	MsgN = print
end

function console.EndCapture()
	Msg = __OLDMSG
	MsgN = __OLDMSGN
	print = __OLDPRINT
	return result
end

function console.Capture(func)
	console.StartCapture()
		func()
	return console.EndCapture()
end

function console.Clear()
	RunConsoleCommand("clear")
end

function console.Exec(cfg)
	checkstring(cfg)

	local content = file.Read("cfg/"  .. cfg .. ".cfg", true)

	if content then
		console.RunString(content)
		return true
	end

	return false
end

function console.RunString(content)
	checkstring(content)

	if #content > 0 then
		if CLIENT then
			LocalPlayer():ConCommand(content)
		elseif SERVER then
			game.ConsoleCommand(content)
		end
	end
end

if file.Exists("lua/bin/gm"..(SERVER and "sv" or "cl").."_enginespew_win32.dll",'GAME') and pcall(require,"enginespew") then
	local blacklist = {
		"Couldn't find scene",
		"invert rot matrix",
		"DataTable warning",
		"Bad pstudiohdr",
		"do_constraint_system",
		"Error Vertex File for",
		"Couldn't find scene ",
		"Unable to find actor named",
	}

	function console.AddToBlackList(str)
		checkstring(str)

		return table.insert(blacklist, str)
	end

	function console.RemoveFromBlackList(id)
		checknumber(id)

		blacklist[id] = nil
	end

	function console.GetBlackList()
		return blacklist
	end

	function console.ClearBlackList()
		blacklist = {}
	end

	local cvar = CreateConVar("con_filter", "normal", FCVAR_ARCHIVE)

	function console.IsLineAllowed(line)
		if cvar:GetString() == "normal" then
			for _, value in pairs(blacklist) do
				if line:find(value, nil, true) then
					return false
				end
			end
		elseif cvar:GetString() == "pattern" then
			for _, value in pairs(blacklist) do
				if line:find(value) then
					return false
				end
			end
		end

		return true
	end

	hook.Add("InitPostEntity", "console_filter", function()
		local in_it=false
		hook.Add("EngineSpew", "console_filter", function(_, line)
			if in_it then return end in_it = true
			if not console.IsLineAllowed(line) then
				in_it=false
				return false
			else
				hook.Call("ConsoleOutput", GAMEMODE, line)
			end
			in_it=false
		end)

		hook.Remove("InitPostEntity", "console_filter")
	end)
end