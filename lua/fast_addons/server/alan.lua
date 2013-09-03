local sessions = {}

local request

function request(id, question, name, callback, gender)

	id = id or "none"
	question = question or "hello!"
	name = name or "none"
	callback = callback or PrintTable
	gender = gender or "transgender"
	
	local session = sessions[id]
	
	if not session or (not session.cookie and not session.getting_cookie) then
		
		session = 
		{
			cookie, 
			getting_cookie = true
		}
		
		local socket = luasocket.Client("tcp")
		
		socket:Connect("www.a-i.com", 80)
		socket:Send("GET /alan1/webface1.asp HTTP/1.1\n")
		socket:Send("Host: www.a-i.com\n")
		socket:Send("User-Agent: GMod10\n")
		socket:Send("Connection: Close\n")
		socket:Send("\n")
		
		socket.OnReceive = function(self, str)
			local header = str:match("(.-\10\13)")
			header = luasocket.HeaderToTable(header)
			
			session.cookie = header["Set-Cookie"]			
			request(id, question, name, callback, gender)
			
			session.getting_cookie = nil
		end
			
		sessions[id] = session
	else			
		local socket = luasocket.Client("tcp")
		
		socket:Connect("www.a-i.com", 80)
		socket:Send("GET http://www.a-i.com/alan1/webface1_ctrl.asp?gender=" .. gender .."&name=" .. luasocket.EscapeURL(name) .. "&question=" .. luasocket.EscapeURL(question) .. " HTTP/1.1\n")
		socket:Send("Host: www.a-i.com\n")
		socket:Send("User-Agent: GMod10\n")
		socket:Send("Cookie: "..session.cookie.."\n")
		socket:Send("Connection: Close\n")
		socket:Send("\n")
		
		socket.OnReceive = function(self, str)
			for answer in string.gmatch(str, "<option>answer = ([^\n]*)") do
				local worked, res = pcall(callback, answer, id, session)
				
				if not worked then
					ErrorNoHalt(string.format("Callback for answer %q failed: %q!", answer, res))
				end
			end
		end
	end	
end

alan = {Ask = request}