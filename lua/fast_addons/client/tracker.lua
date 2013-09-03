choons = {}

choons.PreDefined =
{
    ["P:"] = "PITCH:",
    ["S:"] = "SAMPLE:",
    ["L:"] = "LENGTH:",
    ["V:"] = "VOLUME:",
    ["D:"] = "DSP:",
    ["SMPL_ONCE"] = "1",
	["SMPL_RESTART"] = "2",
	["SMPL_LEGATO"] = "3",

    NULL = "0",
}

function choons.PreProcess(str)
    for key, value in pairs(choons.PreDefined) do
        str = str:gsub(key, value)
    end

    local replace = {}

    for key, line in pairs(str:Split("\n")) do
        local key, value = line:match("#define%s+(.+)%s+(.+)")

        if key and value then
            str = str:gsub(line, "")
            table.insert(replace, {key = key:Trim(), value = value:Trim()})
        end
    end

    str = str:Trim("\n")

    for i = -#replace, -1 do
        local data = replace[-i]
        str = str:gsub(data.key, data.value)
    end

    return str
end

function choons.Tokenize(str)
    str = choons.PreProcess(str)


    local tbl = {}

    for key, line in pairs(str:Split(";")) do
        line = line:Trim()
        if #line > 0 then
            local cmd = line:match("(%a+):")
            if cmd then
                table.insert(tbl, {cmd = cmd, args = line:gsub(cmd .. ":", ""):Trim():Split(",")})
            end
        end
    end

    local new = {}
    local i = 0

    for _, data in ipairs(tbl) do
        local cmd = data.cmd
        if cmd == "SAMPLE" then
            i = i + 1
            new[i] = {cmd = cmd, path = data.args[2]:gsub([[\]], "/"), type = data.args[1]}
        else
            new[i][cmd:lower()] = data.args
        end
    end

    return new
end

if CLIENT then
choons.Player = LocalPlayer()
end

function choons.Execute(speed, ...)
	speed = speed ^ 0.5
	local sounds = {}
	local channels = {}
	for key, str in pairs({...}) do
		local tbl = choons.Tokenize(str)

		local function Play(self, frame)
			if self.time > frame-1 then return end

			local i = math.floor(self.index)

			local data = tbl[i]

			if not data then
				return "STOP"
			end

			data.pitch = data.pitch or {100}
			data.length = data.length or {1}
			data.volume = data.volume or {100}
			data.dsp = data.dsp or {1}

			local path = file.Exists("sound/" .. data.path, true) and data.path or chatsounds.GetSound(data.path).path
			local length = tonumber(data.length[1] or 1) / speed
			local pitch = tonumber(data.pitch[1] or 100) * (speed^2)
			local volume = tonumber(data.volume[1] or 100)
			local dsp = tonumber(data.dsp[1] or 23)
			local type = data.type

			LocalPlayer():SetDSP(dsp)

			if type == "1" then
				choons.Player:EmitSound(path, volume, pitch)
				length = 0
			end

			if type == "2" then
				sounds[path] = sounds[path] or CreateSound(choons.Player, path)
				sounds[path]:Stop()
				sounds[path]:PlayEx(volume/100, pitch)
				sounds[path]:ChangePitch(pitch)
				sounds[path]:ChangeVolume(volume/100)
			end

			if type == "3" then
				sounds[path] = sounds[path] or CreateSound(choons.Player, path)
				--sounds[path]:Stop()
				sounds[path]:PlayEx(volume/100, pitch)
				sounds[path]:ChangePitch(pitch)
				sounds[path]:ChangeVolume(volume/100)
			end

			self.time = self.time + length
			self.index = self.index + 1
		end

		table.insert(channels, {
			Play = Play,
			index = 1,
			time = 0,
		})
	end

	local frame = 0
	local tag = "choons_player_" .. tostring(choons.Player)
	hook.Add("RenderScene", tag, function()
		local all_done = 0
		for key, channel in pairs(channels) do
			if channel:Play(frame) == "STOP" then
				all_done = all_done + 1
			end
		end

		if #channels == all_done then
			for key, csp in pairs(sounds) do
				csp:Stop()
			end
			LocalPlayer():SetDSP(0)
			hook.Remove("RenderScene", tag)
			return
		end

		frame = frame + (FrameTime() * speed)
	end)
end
