local level = 4

local function __check(var, method, ...)
	local name = debug.getinfo(level, "n").name
	local func = debug.getinfo(level, "f").func
	local types = {...}
	local allowed = ""
	local typ = method(var)

	local matched = false

	for key, value in ipairs(types) do
		if #types ~= key then
			allowed = allowed .. value .. " or "
		else
			allowed = allowed .. value
		end

		if typ == value then
			matched = true
		end
	end

	local arg = "???"

	for i=1, math.huge do
		local key, value = debug.getlocal(2, i)
		-- I'm not sure what to do about this part with vars that have no refference
		if value == var then
			arg = i
		break end
	end

	if not matched then
		error(("bad argument #%s to '%s' (%s expected, got %s)"):format(arg, name, allowed, typ), level+1)
	end
end

function check(var, ...)
	__check(var, _G.type, ...)
end

function checkclass(var, ...)
	__check(var, function(var)
		return IsEntity(var) and var:GetClass() or type(var)
	end, ...)
end

checktype = check

-- TODO: more types

local types = {
	"number",
	"string",
	"table",

	"Vector",
	"Angle",

	"Entity",
	"Player",
	"NPC",
	"PhysObj"
}

for _, type in pairs(types) do
	_G["check" .. type:lower()] = function(var, ...)
		check(var, type, ...)
	end
end



-- entity_check extensions
do -- ents
	function ents.IsEntityValid(var)
		return IsEntity(var) and var:IsValid()
	end
end

do -- NULL
	local META = getmetatable(NULL)

	-- returns nil
	--function META:GetClass() return nil end
	function META:IsClass() return false end
	function META:GetType() return nil end
	function META:IsPhysics() return false end
end

do -- entity
	local META = FindMetaTable("Entity")

	function META:IsClass(types)
		check(types, "string", "table")

		return self:GetClass() == types or table.HasValue(types, self:GetClass())
	end

	function META:IsPhysics()
		return type(self) == "PhysObj" and self:IsValid()
	end

	function META:GetType()
		return type(self)
	end
end
