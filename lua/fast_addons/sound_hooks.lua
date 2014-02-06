local ENTITY = FindMetaTable("Entity")

old_hook_emit_sound = old_hook_emit_sound or ENTITY.EmitSound

function ENTITY:EmitSound(...)
	local ent, path, volume, pitch = hook.Call("EmitSound", nil, self, ...)

	if IsEntity(ent) and ent:IsValid() then
		if volume >= 105 then volume = 100 end
		return old_hook_emit_sound(ent, path, volume, pitch)
	end

	return old_hook_emit_sound(self, ... )
end