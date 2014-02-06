local handle_path = function(path, plain)
	file.CreateDir("stdlua") -- hhh
	
	path = "stdlua/" .. path
	
	if not plain then
		path = (path):gsub("%.", "_") .. ".txt"
	end
	
	return path
end

do -- _G
	function loadstring(str, env)
		local var = CompileString(str, env or "loadstring", false)
		if type(var) == "string" then
			return nil, var, 2
		end
		return setfenv(var, getfenv(1))
	end

	function loadfile(str)
		if not file.Exists(handle_path(str, true), "DATA") then
			return nil, str .. ": No such file", 2
		end
		local lua = file.Read(handle_path(str, true), "DATA")
		return loadstring(lua, str)
	end

	function dofile(filename)
		local f = assert(loadfile(filename))
      	return f()
	end
end

do -- os
	os = os or {}

	function os.getenv(var)
		var = tostring(var):lower()

		if var == "path" then
			return (util.RelativePathToFull("lua/includes/init.lua"):gsub("\\", "/"):gsub("lua/includes/init.lua", ""))
		end

		if var == "username" then
			return SERVER and "server" or LocalPlayer():Nick()
		end
	end

	function os.setlocale(...)
		print("os.setlocale: ", ...)
	end

	function os.execute(...)
		print("os.execute: ", ...)
	end

	function os.exit(...)
		print("os.exit: ", ...)
	end

	function os.remove(filename)
		if file.Exists(handle_path(filename), "DATA") then
			file.Delete(handle_path(filename), "DATA")
			return true
		end

		return nil, "data/" .. filename .. ": No such file or directory", 2
	end

	function os.rename(a, b)
		if file.Exists(handle_path(filename), "DATA") then
			local str = file.Read(handle_path(a), "DATA")
			file.Delete(handle_path(b), "DATA")
			file.Write(handle_path(b), str, "DATA")
			return true
		end

		return nil, "data/" .. a .. ": No such file or directory", 2
	end

	function os.tmpname()
		return "data/temp/" .. util.CRC(RealTime()) .. ".txt"
	end
end

do -- io
	io = io or {}

	local META = {}
	META.__index = META

	function META:__tostring()
		return ("file (%p)"):format(self)
	end

	function META:write(...)

		local str = ""

		for i = 1, select("#", ...) do
			str = str .. tostring(select(i, ...))
		end

		self.__data = str

		if self.__path:sub(0, 5) == "data/" then
			file.Write(handle_path(self.__path:sub(6)), self.__data, "DATA")
		else
			file.Write(handle_path(self.__path), self.__data, "DATA")
		end
	end

	local function read(self, format)
		format = format or "*line"

		self.__seekpos = self.__seekpos or 0

		if type(format) == "number" then
			return self.__data:sub(0, format)
		elseif format:sub(1, 2) == "*a" then
			return self.__data:sub(self.__seekpos)
		elseif format:sub(1, 2) == "*l" then
			if not self.__data:find("\n", nil, true) then
				if self.__data == "" then return nil end

				local str = self.__data
				self.__data = ""

				return str
			else
				local val = self.__data:match("(.-)\n")
				self.__data = self.__data:match(".-\n(.+)")

				return val
			end
		elseif format:sub(1, 2) == "*n" then
			local str = read("*line")
			if str then
				local numbers = {}
				str:gsub("(%S+)", function(str) table.insert(numbers, tonumber(str)) end)
				return unpack(numbers)
			end
		end
	end

	function META:read(...)
		local args = {...}

		for k, v in pairs(args) do
			args[k] = read(self, v) or nil
		end

		return unpack(args) or nil
	end

	function META:close()

	end

	function META:flush()

	end

	function META:seek(whence, offset)
		whence = whence or "cur"
		offset = offset or 0

		self.__seekpos = self.__seekpos or 0

		if whence == "set" then
			self.__seekpos = offset
		elseif whence == "end" then
			self.__seekpos = #self.__data
		elseif whence == "cur" then
			self.__seekpos = self.__seekpos + offset
		end

		return math.Clamp(self.__seekpos, 0, #self.__data)
	end

	function META:lines()
		return self.__data:gmatch("(.-)\n")
	end

	function META:setvbuf()

	end

	function io.open(filename, mode)
		mode = mode or "r"
		
		if not file.Exists(handle_path(filename), "DATA") and mode == "w" then
			error("No such file or directory", 2)
		end

		local self = setmetatable({}, META)

		self.__data = file.Read(handle_path(filename), "DATA")
		self.__path = filename
		self.__mode = mode

		return self
	end

	io.stdin = setmetatable({}, META)
	io.stdin.__data = ""

	io.stdout = setmetatable({}, META)
	io.stdout.__data = ""

	local current_file = io.stdin

	function io.input(var)
		if io.type(var) == "file" then
			current_file = var
		else
			current_file = io.open(var)
		end

		return current_file
	end

	function io.type(var)
		if getmetatable(var) == META then
			return file
		end

		return nil
	end

	function io.read(...) return current_file:read(...) end

	function io.lines(...) return current_file:lines(...) end

	function io.flush(...) return current_file:flush(...) end

	function io.popen(...) print("io.popen: ", ...) end

	function io.close(...) return current_file:close(...) end

	function io.tmpfile(...) return current_file:flush(...)  end
end

do -- require
	local stdlibs =
	{
		table = table,
		math = math,
		string = string,
		debug = debug,
		io = io,
		table = table,
		os = os,
	}

	old_gmod_require = old_gmod_require or require

	function require(str, ...)
		local args = {old_gmod_require(str, ...)}

		if args[1] == nil then
			return stdlibs[str]
		end

		return unpack(args)
	end
end

do -- std lua env
	local _G = {}
	_G._G = _G
	_G._VERSION = _VERSION

	_G.assert = assert
	_G.collectgarbage = collectgarbage
	_G.dofile = dofile
	_G.error = error
	_G.getfenv = getfenv
	_G.getmetatable = getmetatable
	_G.ipairs = ipairs
	_G.load = load
	_G.loadfile = loadfile
	_G.loadstring = loadstring
	_G.module = module
	_G.next = next
	_G.pairs = pairs
	_G.pcall = pcall
	_G.print = print
	_G.rawequal = rawequal
	_G.rawget = rawget
	_G.rawset = rawset
	_G.require = require
	_G.select = select
	_G.setfenv = setfenv
	_G.setmetatable = setmetatable
	_G.tonumber = tonumber
	_G.tostring = tostring
	_G.type = type
	_G.unpack = unpack
	_G.xpcall = xpcall

	_G.coroutine = {}
	_G.coroutine.create = coroutine.create
	_G.coroutine.resume = coroutine.resume
	_G.coroutine.running = coroutine.running
	_G.coroutine.status = coroutine.status
	_G.coroutine.wrap = coroutine.wrap
	_G.coroutine.yield = coroutine.yield

	_G.debug = {}
	_G.debug.debug = debug.debug
	_G.debug.getfenv = debug.getfenv
	_G.debug.gethook = debug.gethook
	_G.debug.getinfo = debug.getinfo
	_G.debug.getlocal = debug.getlocal
	_G.debug.getmetatable = debug.getmetatable
	_G.debug.getregistry = debug.getregistry
	_G.debug.getupvalue = debug.getupvalue
	_G.debug.setfenv = debug.setfenv
	_G.debug.sethook = debug.sethook
	_G.debug.setlocal = debug.setlocal
	_G.debug.setmetatable = debug.setmetatable
	_G.debug.setupvalue = debug.setupvalue
	_G.debug.traceback = debug.traceback

	_G.io = {}
	_G.io.close = io.close
	_G.io.flush = io.flush
	_G.io.input = io.input
	_G.io.lines = io.lines
	_G.io.open = io.open
	_G.io.output = io.output
	_G.io.popen = io.popen
	_G.io.read = io.read
	_G.io.tmpfile = io.tmpfile
	_G.io.type = io.type
	_G.io.write = io.write

	_G.math = {}
	_G.math.abs = math.abs
	_G.math.acos = math.acos
	_G.math.asin = math.asin
	_G.math.atan = math.atan
	_G.math.atan2 = math.atan2
	_G.math.ceil = math.ceil
	_G.math.cos = math.cos
	_G.math.cosh = math.cosh
	_G.math.deg = math.deg
	_G.math.exp = math.exp
	_G.math.floor = math.floor
	_G.math.fmod = math.fmod
	_G.math.frexp = math.frexp
	_G.math.huge = math.huge
	_G.math.ldexp = math.ldexp
	_G.math.log = math.log
	_G.math.log10 = math.log10
	_G.math.max = math.max
	_G.math.min = math.min
	_G.math.modf = math.modf
	_G.math.pi = math.pi
	_G.math.pow = math.pow
	_G.math.rad = math.rad
	_G.math.random = math.random
	_G.math.randomseed = math.randomseed
	_G.math.sin = math.sin
	_G.math.sinh = math.sinh
	_G.math.sqrt = math.sqrt
	_G.math.tan = math.tan
	_G.math.tanh = math.tanh

	_G.os = {}
	_G.os.clock = os.clock
	_G.os.date = os.date
	_G.os.difftime = os.difftime
	_G.os.execute = os.execute
	_G.os.exit = os.exit
	_G.os.getenv = os.getenv
	_G.os.remove = os.remove
	_G.os.rename = os.rename
	_G.os.setlocale = os.setlocale
	_G.os.time = os.time
	_G.os.tmpname = os.tmpname

	_G.package = {}
	_G.package.cpath = package.cpath
	_G.package.loaded = package.loaded
	_G.package.loaders = package.loaders
	_G.package.loadlib = package.loadlib
	_G.package.path = package.path
	_G.package.preload = package.preload
	_G.package.seeall = package.seeall

	_G.string = {}
	_G.string.byte = string.byte
	_G.string.char = string.char
	_G.string.dump = string.dump
	_G.string.find = string.find
	_G.string.format = string.format
	_G.string.gmatch = string.gmatch
	_G.string.gsub = string.gsub
	_G.string.len = string.len
	_G.string.lower = string.lower
	_G.string.match = string.match
	_G.string.rep = string.rep
	_G.string.reverse = string.reverse
	_G.string.sub = string.sub
	_G.string.upper = string.upper

	_G.table = {}
	_G.table.concat = table.concat
	_G.table.insert = table.insert
	_G.table.maxn = table.maxn
	_G.table.remove = table.remove
	_G.table.sort = table.sort

	function setstdenv(func)
		return setfenv(func, _G)
	end
end