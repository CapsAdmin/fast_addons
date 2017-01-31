aowl.AddCommand("fov",function(pl,_,fov,delay)
	fov=tonumber(fov) or 90
	fov=math.Clamp(fov,1,350)
	pl:SetFOV(fov,tonumber(delay) or 0.3)
end)

aowl.AddCommand({"name","nick","setnick","setname","nickname"}, function(player, line)
	if line then
		line=line:Trim()
		if(line=="") or line:gsub(" ","")=="" then
			line = nil
		end
		if line and #line>40 then
			if not line.ulen or line:ulen()>40 then
				return false,"my god what are you doing"
			end
		end
	end
	timer.Create("setnick"..player:UserID(),1,1,function()
		if IsValid(player) then
			player:SetNick(line)
		end
	end)
end, "players", true)

aowl.AddCommand("bot",function(pl,cmd,what,name)
	if not what or what=="" or what=="create" or what==' ' then

		game.ConsoleCommand"bot\n"
		hook.Add("OnEntityCreated","botbring",function(bot)
			if not bot:IsPlayer() or not bot:IsBot() then return end
			hook.Remove("OnEntityCreated","botbring")
			timer.Simple(0,function()
				local x='_'..bot:EntIndex()
				aowl.CallCommand(pl, "bring", x, {x})
				if name and name~="" and bot.SetNick then
					bot:SetNick(name)
				end
			end)
		end)

	elseif what=="kick" then
		for k,v in pairs(player.GetBots()) do
			v:Kick"bot kick"
		end
	elseif what=="zombie" then
		game.ConsoleCommand("bot_zombie 1\n")
	elseif what=="zombie 0" or what=="nozombie" then
		game.ConsoleCommand("bot_zombie 0\n")
	elseif what=="follow" or what=="mimic" then
		game.ConsoleCommand("bot_mimic "..pl:EntIndex().."\n")
	elseif what=="nofollow" or what=="nomimic" or what=="follow 0" or what=="mimic 0" then
		game.ConsoleCommand("bot_mimic 0\n")
	end
end,"developers")

aowl.AddCommand("nextbot",function(pl,cmd,name)
	local bot=player.CreateNextBot(name or "nextbot")

	local x='_'..bot:EntIndex()
	aowl.CallCommand(me, "bring", x, {x})
end,"developers")

