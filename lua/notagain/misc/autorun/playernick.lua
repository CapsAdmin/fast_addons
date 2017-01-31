playernick = playernick or {}
playernick.old_meta = playernick.old_meta or {} local old = playernick.old_meta

local META = FindMetaTable("Player")

function playernick.TranslateNick(ply, nick)
	return hook.Call("PlayerNick", GAMEMODE, ply, nick) or ply:RealNick()
end

-- enabled

	playernick.cvar = CreateConVar("sh_playernick_enabled", "1")
	playernick.enabled = true

	function playernick.IsEnabled()
		if type(playernick.enabled) == "boolean" then return playernick.enabled end
		return playernick.cvar:GetBool()
	end

	function playernick.Enable()
		if type(playernick.enabled) == "boolean" then playernick.enabled = true end
		RunConsoleCommand("sh_playernick_enabled", "1")
	end

	function playernick.Disable()
		if type(playernick.enabled) == "boolean" then playernick.enabled = false end
		RunConsoleCommand("sh_playernick_enabled", "0")
	end
--

-- persistence

if SERVER then
	function playernick.save(ply, nick)
		if not isstring(nick) or nick == ply:RealNick() then
			ply:RemovePData("PlayerNick")
		else
			ply:SetPData("PlayerNick", nick)
		end
	end

	function playernick.load(ply)
		local nick = ply:GetPData("PlayerNick")
		if isstring(nick) then
			ply:SetNick(nick)
		end
	end

	hook.Add("PlayerInitialSpawn", "PlayerNick", function(ply)
		timer.Simple(1,function()
			if IsValid(ply) then
				playernick.load(ply)
			end
		end)
	end)
end
--

-- player meta functionality

function META:SetNick(nick)
	nick = nick or self:RealNick()
	if #string.Trim((string.gsub(nick,"%^%d",""))) == 0 then
		nick = self:RealNick()
	end
	for k, v in pairs(player.GetAll()) do
		if v:Nick() == nick and v ~= self and not self:IsAdmin() then
			return
		end
	end
	if SERVER and type(nick) == "string" or type(nick) == "nil" then
		--hook.Call("NickChange", nil, self, self:GetNWString("nick_override", self:RealName()), nick)
		self:SetNWString("nick_override", nick)
		playernick.save(self, nick)
	end
	self.nick_override = nick
end


hook.Add("PlayerNick", "playernick_test_hook", function(ply, nick)
	return ply:GetNWString("nick_override", ply:RealNick())

end)
--

-- overrides

old.GetName = old.GetName or META.GetName or META.Nick

function META:GetName(...)
	local ok = playernick and playernick.IsEnabled() and type(self) == "Player" and self.IsValid and self:IsValid()
	return ok and playernick.TranslateNick(self, self:RealNick()) or old.GetName(self, ...) or "Invalid player!?!?"
end

META.Nick = META.GetName
META.Name = META.GetName

META.RealNick = old.GetName
META.RealName = old.GetName
META.GetRealName = old.GetName

--[[if CLIENT then

	old.chat_AddText = old.chat_AddText or chat.AddText

	function chat.AddText(...)
		if playernick.enabled then
			local new = {}
			for key, value in pairs({...}) do
				if type(value) == "Player" then
					table.insert(new, team.GetColor(value:Team()))
					table.insert(new, value:GetName())
					table.insert(new, Color(151,211,255))
				else
					table.insert(new, value)
				end
			end

			return old.chat_AddText(unpack(new))
		end

		return old.chat_AddText(...)
	end

end]]
--
