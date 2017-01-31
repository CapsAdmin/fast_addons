local materials = {}

materials.Replaced = {}

function materials.ReplaceTexture(path, to)
	path = path:lower()

	local mat = Material(path)

	if not mat:IsError() then

		local typ = type(to)
		local tex

		if typ == "string" then
			tex = Material(to):GetTexture("$basetexture")
		elseif typ == "ITexture" then
			tex = to
		elseif typ == "Material" then
			tex = to:GetTexture("$basetexture")
		else return false end

		materials.Replaced[path] = materials.Replaced[path] or {}

		materials.Replaced[path].OldTexture = materials.Replaced[path].OldTexture or mat:GetTexture("$basetexture")
		materials.Replaced[path].NewTexture = tex

		mat:SetTexture("$basetexture",tex)

		return true
	end

	return false
end


function materials.SetColor(path, color)
	path = path:lower()

	local mat = Material(path)

	if not mat:IsError() then
		materials.Replaced[path] = materials.Replaced[path] or {}
		materials.Replaced[path].OldColor = materials.Replaced[path].OldColor or mat:GetVector("$color")
		materials.Replaced[path].NewColor = color

		mat:SetVector("$color", color)

		return true
	end

	return false
end

function materials.RestoreAll()
	for name, tbl in pairs(materials.Replaced) do
		if
			not pcall(function()
				if tbl.OldTexture then
					materials.ReplaceTexture(name, tbl.OldTexture)
				end

				if tbl.OldColor then
					materials.SetColor(name, tbl.OldColor)
				end
			end)
		then
			print("Failed to restore: " .. tostring(name))
		end
	end
end
hook.Add("ShutDown", "material_restore", materials.RestoreAll)

return materials