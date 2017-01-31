local META = FindMetaTable("Player")
META.Old_IsMuted = META.Old_IsMuted or META.IsMuted
META.Old_SetMuted = META.Old_SetMuted or META.SetMuted

function META:IsMuted()
	return self:GetPData("perma_voice_mute", self:Old_IsMuted() and 1 or 0)
end

function META:SetMuted(b)
	self:SetPData("perma_voice_mute", b and 1 or 0)
end