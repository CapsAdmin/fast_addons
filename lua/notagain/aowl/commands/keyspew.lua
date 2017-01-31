AddCSLuaFile()

local Tag="keyspew"
if SERVER then
	util.AddNetworkString(Tag)
end

local function findkey(key)
	local file = file.Read("cfg/config.cfg",'GAME')
	local ret = false
	for line in file:gmatch("[^\r\n]+") do
		key=key:lower()
		line=line:Trim():lower()
		if line:find("bind",1,true) then
			--print(line)
			local a,b = line:match 'bind%s+"([^"]+)"%s+"([^"]+)"'
			if a==key and b then
				ret = b

			end
		end
	end
	return ret
end

--print(findkey("w")) do return end

local SHOW_KEY=false
local FIND_BIND=true

local function ShowKey(b)
	local ret = findkey(b) or "KEYNOTFOUND"
	--print("findkey",b,ret)
	net.Start(Tag)
		net.WriteBit(SHOW_KEY)
		net.WriteString(ret)
	net.SendToServer()
end

local function FindBind(b)
	--print("LookupBinding")
	local ret = input.LookupBinding(b) or "BINDNOTFOUND"
	net.Start(Tag)
		net.WriteBit(FIND_BIND)
		net.WriteString(ret)
	net.SendToServer()
end


local function GotReply(pl,a,reply,what)
	--print("REPLY",pl,a==FIND_BIND and "bind" or "key",what,"->",reply)
	local key,binding
	if a==FIND_BIND then
		key,binding = reply,what
	else
		key,binding = what,reply
	end
	PrintMessage(3,("Key '%s' for %s is bound to '%s'"):format(key,pl:Name(),binding))
end

net.Receive(Tag,function(len,pl)
	local a = tobool(net.ReadBit())
	local b = net.ReadString()
	--print("GOT",a,b)

	if SERVER then
		local what = pl._requesting_keybinding

		if not what then return end

		pl._requesting_keybinding = false

		GotReply(pl,a,b,what)

	else
		if a==FIND_BIND then
			FindBind(b)
		elseif a==SHOW_KEY then
			ShowKey(b)
		else
			error"no"
		end
	end
end)

aowl.AddCommand("findkey",function(pl,line,target,binding)
	target = easylua.FindEntity(target)
	if target:IsPlayer() then
		if target._requesting_keybinding then return end
		target._requesting_keybinding = binding
		net.Start(Tag)
			net.WriteBit(FIND_BIND)
			net.WriteString(binding)
		net.Send(target)
		return
	end
	return false,"noon"
end)
aowl.AddCommand("showkey",function(pl,line,target,binding)
	target = easylua.FindEntity(target)
	if target:IsPlayer() then
		if target._requesting_keybinding then return end
		target._requesting_keybinding = binding
		net.Start(Tag)
			net.WriteBit(SHOW_KEY)
			net.WriteString(binding)
		net.Send(target)
		return
	end
	return false,"noon"
end)