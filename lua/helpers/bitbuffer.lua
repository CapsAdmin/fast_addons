-- code has been taken from overvs unlimited usermessage script for gmod

bitbuffer = {}

do -- write
	local META = {}

	function META:__index(key)
		if META[key] then
			return META[key]
		end

		return bitbuffer.Types[key]
	end

	META.Size = 0
	META.Buffer = {}

	function META:WriteChar(c)
		self.Size = self.Size + 1
		table.insert(self.Buffer, c)
	end

	function META:WriteFloat(f)
		f = f or 0

		local neg = f < 0
		f = math.abs(f)

		-- Extract significant digits and exponent
		local e = 0
		if (f >= 1) then
			while f >= 1 do
				f = f / 10
				e = e + 1
			end
		else
			while f < 0.1 do
				f = f * 10
				e = e - 1
			end
		end

		-- Discard digits
		local s = tonumber(string.sub(f, 3, 9))

		-- Negate if the original number was negative
		if (neg) then s = -s end

		-- Convert to unsigned
		s = s + 8388608

		-- Send significant digits as 3 byte number

		local a = math.modf(s / 65536) s = s - a * 65536
		local b = math.modf(s / 256) s = s - b * 256
		local c = s

		self:WriteChar(a - 128)
		self:WriteChar(b - 128)
		self:WriteChar(c - 128)

		-- Send exponent
		self:WriteChar(e)
	end

	function META:WriteLong(l)
		-- Convert to unsigned
		l = l + 2147483648

		local a = math.modf(l / 16777216) l = l - a * 16777216
		local b = math.modf(l / 65536) l = l - b * 65536
		local c = math.modf(l / 256) l = l - c * 256
		local d = l

		self:WriteChar(a - 128)
		self:WriteChar(b - 128)
		self:WriteChar(c - 128)
		self:WriteChar(d - 128)
	end

	function META:WriteAngle(a)
		self:WriteFloat(a.p)
		self:WriteFloat(a.y)
		self:WriteFloat(a.r)
	end

	function META:WriteBool(b)
		if b then
			self:WriteChar(1)
		else
			self:WriteChar(0)
		end
	end

	function META:WriteEntity(e)
		self:WriteShort(e:EntIndex())
	end

	function META:WriteShort(s)
		-- Convert to unsigned
		s = (s or 0) + 32768

		local a = math.modf(s / 256)

		self:WriteChar(a - 128)
		self:WriteChar(s - a * 256 - 128)
	end

	function META:WriteString(s)
		for char in s:gmatch("(.)") do
			self:WriteChar(char:byte())
		end
		self:WriteChar(0)
	end

	function META:WriteVector(v)
		self:WriteFloat(v.x)
		self:WriteFloat(v.y)
		self:WriteFloat(v.z)
	end

	function META:ToString()
		local str = ""

		for key, value in pairs(self.Buffer) do
			local num = tostring(value)

			if #num == 2 then num = "0" .. num end
			if #num == 1 then num = "00" .. num end

			str = str .. num
		end

		return str
	end

	function bitbuffer.Writer()
		return setmetatable({}, META)
	end

	bitbuffer.WriterMeta = META
end

do -- read
	local META = {}
	META.__index = META

	META.Index = 0
	META.Buffer = {}

	function META:ReadChar()
		self.Index = self.Index + 1
		return self.Buffer[self.Index]
	end

	function META:ReadAngle()
		return Angle(self:ReadFloat(), self:ReadFloat(), self:ReadFloat())
	end

	function META:ReadBool()
		return self:ReadChar() == 1
	end

	function META:ReadEntity()
		return Entity(self:ReadShort())
	end

	function META:ReadFloat()
		local a, b, c = self:ReadChar() + 128, self:ReadChar() + 128, self:ReadChar() + 128
		local e = self:ReadChar()

		local s = a * 65536 + b * 256 + c - 8388608

		if s > 0 then
			return tonumber("0." .. s) * 10^e
		else
			return tonumber("-0." .. math.abs(s)) * 10^e
		end
	end

	function META:ReadLong()
		local a, b, c, d = self:ReadChar() + 128, self:ReadChar() + 128, self:ReadChar() + 128, self:ReadChar() + 128
		return a * 16777216 + b * 65536 + c * 256 + d - 2147483648
	end

	function META:ReadShort()
		return (self:ReadChar() + 128) * 256 + self:ReadChar() + 128 - 32768
	end

	function META:ReadString()
		local s, b = "", self:ReadChar()

		while b and b ~= 0 do
			s = s .. string.char(b)
			b = self:ReadChar()
		end

		return s
	end

	function META:ReadVector()
		return Vector(self:ReadFloat(), self:ReadFloat(), self:ReadFloat())
	end

	function META:ToString()
		return self.Buffer
	end

	function bitbuffer.Reader(str)
		local obj = setmetatable({}, META)

		local buffer = {}
		for char in str:gmatch("(%d%d%d)") do
			table.insert(buffer, tonumber(char))
		end

		obj.Buffer = buffer
		return obj
	end

	bitbuffer.ReaderMeta = META
end