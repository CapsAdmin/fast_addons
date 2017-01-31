if CLIENT then
    local tbl
    local A = function(v) table.insert(tbl, v) end
    usermessage.Hook("google_say", function(umr)
		local str = umr:ReadString()

		local t = {}
		tbl = t

		A(Color(1, 64, 202)) A("G")
		A(Color(221, 24, 18)) A("o")
		A(Color(252, 202, 3)) A("o")
		A(Color(1, 64, 202))  A("g")
		A(Color(22, 166, 30)) A("l")
		A(Color(221, 24, 18)) A("e")
		A(color_white) A(": ")
		A(str)

		if chat.AddTimeStamp then chat.AddTimeStamp(tbl) end

		chat.AddText(unpack(tbl))
    end)
end

if SERVER then
    local function GoogleSay(msg)
		umsg.Start("google_say")
			umsg.String(msg)
		umsg.End()
    end

    hook.Add("PlayerSay", "google", function(ply, question)
		question = question:lower()
		if question:find("google",1,true) then
			question = question:match("google.-(%a.+)?")

			if not question then return end

			local _q = question
			question = question:gsub("(%A)", function(char) return "%"..("%x"):format(char:byte()) end)
			--print("QUESTION: ", question)
			http.Fetch(
				"http://suggestqueries.google.com/complete/search?client=firefox&q=" .. question .. "%20",
				function(str)
				str = str
				:Replace("[[", "")
				:Replace("]]", "")
				:Replace('"', "")
				:gsub("[^%a, ]", "")
				:Replace(_q:lower() .. " ", "")
				local tbl = str:Split(',')
				table.remove(tbl, 1)

				GoogleSay(table.Random(tbl))
				end
			)
		end
    end)
end