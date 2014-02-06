local AbitraryPrecision={}

-- should we expose AP?
_G.AbitraryPrecision=_G.AbitraryPrecision or AbitraryPrecision

function AbitraryPrecision.__MakeTable(v)
	local v = tostring(v)
	local t = {}
	for k=1,v:len() do
		t[k] = v:sub(k,k)
	end
	return t
end
function AbitraryPrecision.__MakeString(v)
	local len = #v
	local str = ""
	while(len > 0) do
		str = str..v[len]
		len = len - 1
	end
	return str
end
function AbitraryPrecision.Add(a,b)
	local A = AbitraryPrecision.__MakeTable(a)
	local B = AbitraryPrecision.__MakeTable(b)

	local pos1 = #A
	local pos2 = #B
	local pos3 = 1
	local C = {}
	local overflow = 0
	while(pos1 > 0 or pos2 > 0) do
		local digit = (A[pos1] or 0) + (B[pos2] or 0) + overflow
		overflow = 0
		if(digit > 9) then
			overflow = 1
			digit = digit - 10
		end
		C[pos3] = digit
		pos1 = pos1 - 1
		pos2 = pos2 - 1
		pos3 = pos3 + 1
	end
	if(overflow == 1) then
		C[pos3] = 1
	end

	return AbitraryPrecision.__MakeString(C)
end
function AbitraryPrecision.Sub(a,b)
	local A = AbitraryPrecision.__MakeTable(a)
	local B = AbitraryPrecision.__MakeTable(b)

	local pos1 = #A
	local pos2 = #B
	local pos3 = 1
	local C = {}
	local overflow = 0
	while(pos1 > 0 or pos2 > 0) do
		local digit = (A[pos1] or 0) - (B[pos2] or 0) - overflow
		overflow = 0
		if(digit < 0) then
			overflow = 1
			digit = digit + 10
		end
		C[pos3] = digit
		pos1 = pos1 - 1
		pos2 = pos2 - 1
		pos3 = pos3 + 1
	end
	if(overflow == 1) then
		C[pos3] = 1
	end

	return AbitraryPrecision.__MakeString(C)
end


local OFFSET = "76561197960265728"
local steamid_cache={}
SteamID64 = SteamID64 or function(steamid)
	local cached = steamid_cache[steamid]
	if cached then return cached end
	
	local data = string.Explode(":",steamid)

	if !data[3] or !data[2] then return false end

	local ret = AbitraryPrecision.Add(data[2] + 2*data[3],OFFSET) --  A + 2*B + OFFSET
	steamid_cache[steamid]=ret
	return ret
end
util.SteamID64=util.SteamID64 or SteamID64
local SteamID64=SteamID64

SteamID64ToSteamID =  SteamID64ToSteamID or function(steamid64)
	if type(steamid64) ~= "string" then return false end

	local id = AbitraryPrecision.Sub(steamid64,OFFSET) --  A + 2*B
	local A = (id % 2)
	local B = (id - A)/2

	return "STEAM_0:"..A..":"..B
end
util.SteamID64ToSteamID=util.SteamID64ToSteamID or SteamID64ToSteamID

-- TODO
tosteamid = SteamID64ToSteamID

local Player=FindMetaTable"Player"


Player.SteamID64 = Player.SteamID64 or function(self)
	return SteamID64(self:SteamID())
end

Player.CommunityID=Player.SteamID64

-- return community profile url
Player.Steam=Player.Steam or function(p,a,b) if a==true then b=true a=false end return "http://steamcommunity.com/profiles/"..(p:SteamID64() or 0)..(a and a:len()>0 and "/"..a or "")..(b and "?xml=true" or "") end
