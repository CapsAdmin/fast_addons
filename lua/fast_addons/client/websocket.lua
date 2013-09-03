websocket_panel = websocket_panel or NULL
if websocket_panel:IsValid() then websocket_panel:Remove() end

local i = 0
local sockets = {}

local function create_html_panel()
	local pnl = vgui.Create("DHTML")
	websocket_panel = pnl
	
	pnl:AddFunction("websocket", "Event", function(id, event, val)
		if id == 0 then
			if event == "error" then
				ErrorNoHalt(val .. "\n")
				return
			end
		end
		
		print(i, id, event, val)
	
		local socket = sockets[id] or NULL
		if socket:IsValid() and socket[event] then
			socket[event](socket, val)
		end
	end)
	pnl:SetSize(50, 50)
	pnl:SetPos(50, 50)
	
	pnl:QueueJavascript([[
	var sockets = []
	var i = 0
		
	function SocketEvent(id, event, val)
	{
		try
		{
			var socket = sockets[id]
			if (val)
			{
				if (event == "send")
				{
					socket.send(val)
				}
				else if (event == "close")
				{
					socket.close()
				}
			}
		}
		catch(err)
		{
			websocket.Event(0, "error", err.message)
		}
	}
		
	function CreateSocket(url, protocol)
	{
		try
		{
			i++
		
			var id = i
		
			var socket = new WebSocket(url, protocol)
			sockets[id] = socket
			
			socket.onmessage = function(event) { websocket.Event(id, "OnMessage", event.data) }
			socket.onopen = function(event) { websocket.Event(id, "OnOpen") }
			socket.onclose = function() { websocket.Event(id, "OnClose") }
			socket.onerror = function() { websocket.Event(id, "OnError") }
			
			websocket.Event("OnCreated", id)
		}
		catch(err)
		{
			websocket.Event(0, "error", err.message)
		}
	}
	]])
end

local META = {}
META.__index = META

function META:__tostring()
	return string.format("websocket[%i]", self.id)
end

function META:IsValid()
	return true
end

function META:Send(data)
	websocket_panel:QueueJavascript(("SocketEvent(%i, %q, %q)"):format(self.id, "send", data))
end

function META:Remove()
	sockets[self.id] = nil
	websocket_panel:QueueJavascript(("SocketEvent(%i, %q)"):format(self.id, "close"))
	setmetatable(self, getmetatable(NULL))
	
	if table.Count(sockets) == 0 then
		websocket_panel:Remove()
	end
end

function WebSocket(url, protocol)
	protocol = protocol or ""
	
	if not websocket_panel:IsValid() then 
		create_html_panel()
	end
	
	i = i + 1
	
	websocket_panel:QueueJavascript(("CreateSocket(%q, %q)"):format(url, protocol))
	
	local socket = setmetatable({id = i}, META)
	sockets[i] = socket
	
	return socket
end

function GetAllWebSockets()
	local out = {}
	for key, val in pairs(sockets) do
		table.insert(out, val)
	end
	return out
end

-- !lm test = WebSocket("ws://node.remysharp.com:8001") test.OnMessage = Say
-- !lm test:Send("hello world")