
aowl.AddCommand("owner", function (ply, line, target)
	if not banni then return false,"no info" end

	local id = easylua.FindEntity(target)
	if not IsValid(id) then return false,"not found" end

	ply:ChatPrint(tostring(id)..' owned by '..tostring(id:CPPIGetOwner() or "no one"))

end, "players", true)

aowl.AddCommand("weldlag",function(pl,line,minresult)
	if minresult == 0 then return false,"minimum result cant be zero" end
	local t={}
	for k,v in pairs(ents.GetAll()) do
		local count=v:GetPhysicsObjectCount()
		if count==0 or count>1 then continue end
		local p=v:GetPhysicsObject()

		if not p:IsValid() then continue end
		if p:IsAsleep() then continue end
		if not p:IsMotionEnabled() then
			--if constraint.FindConstraint(v,"Weld") then -- Well only count welds since those matter the most, most often
				t[v]=true
			--end
		end
	end
	local lags={}
	for ent,_ in pairs(t) do
		local found
		for lagger,group in pairs(lags) do
			if ent==lagger or group[ent] then
				found=true
				break
			end
		end
		if not found then
			lags[ent]=constraint.GetAllConstrainedEntities(ent) or {}
		end
	end
	for c,cents in pairs(lags) do
		local count,lagc=1,t[k] and 1 or 0
		local owner
		for k,v in pairs(cents) do
			count=count+1
			if t[k] then
				lagc=lagc+1
			end
			if not owner and IsValid(k:CPPIGetOwner()) then
				owner=k:CPPIGetOwner()
			end
		end

		if count>(tonumber(minresult) or 5) then
			pl:PrintMessage(3,"Found lagging contraption with "..lagc..'/'..count.." lagging ents (Owner: "..tostring(owner)..")")
		end
	end
end)

aowl.AddCommand( "invisible", function( ply, _, target, on )
	if target then
		if target:Trim() == "true" or target:Trim() == "false" then
			on = target:Trim()
			target = ply
		else
			target = easylua.FindEntity( target )
			if not target then
				return false, "Target not found!"
			end
			if on then on = on:Trim() end
		end

		if on == "true" then
			on = true
		elseif on == "false" then
			on = false
		else
			on = not target._aowl_invisible
		end
	else
		target = ply
		on = not ply._aowl_invisible
	end

	target._aowl_invisible = on
	target:SetNoDraw( on )
	target:SetNotSolid( on )
	pac.TogglePartDrawing( target, not on )

	target:ChatPrint( ( "You are now %svisible." ):format(
		on and "in" or ""
	) )
	if target ~= ply then
		ply:ChatPrint( ( "%s is now %svisible." ):format(
			target:Nick(), on and "in" or ""
		) )
	end
end, "developers" )

aowl.AddCommand({"penetrating", "pen"}, function(ply,line)
	for k,ent in pairs(ents.GetAll()) do
		for i=0,ent:GetPhysicsObjectCount()-1 do
			local pobj = ent:GetPhysicsObjectNum(i)
			if pobj and pobj:IsPenetrating() then
				Msg"[Aowl] "print("Penetrating object: ",ent,"Owner: ",ent:CPPIGetOwner())
				if line and line:find"stop" then
					pobj:EnableMotion(false)
				end
				continue
			end
		end
	end
end,"developers")

do
	local function sleepall()
		for k,ent in pairs(ents.GetAll()) do
			for i=0,ent:GetPhysicsObjectCount()-1 do
				local pobj = ent:GetPhysicsObjectNum(i)
				if pobj and not pobj:IsAsleep() then
					pobj:Sleep()
				end
			end
		end
	end
	aowl.AddCommand("sleep",function()
		sleepall()
		timer.Simple(0,sleepall)
	end,"developers")
end

do
	local Tag="aowl_physenv"
	if SERVER then
		util.AddNetworkString(Tag)

		aowl.AddCommand("physenv",function(pl)
			net.Start(Tag)
				net.WriteTable(physenv.GetPerformanceSettings())
			net.Send(pl)
		end)
	end

	net.Receive(Tag,function(len,who) -- SHARED

		if SERVER and !who:IsAdmin() then return end
		local t=net.ReadTable()


		if SERVER then
			local old=physenv.GetPerformanceSettings()
			for k,v in pairs(t) do
				Msg"[EEK] "print("Changing "..tostring(k)..': ',old[k] or "???","->",v)
				PrintMessage(3,"[PHYSENV] "..k.." changed from "..tostring(old[k] or "UNKNOWN").." to "..tostring(v))
			end
			physenv.SetPerformanceSettings(t)
			return
		end

		local v=vgui.Create'DFrame'
		v:SetSizable(true)
		v:ShowCloseButton(true)
		v:SetSize(512,512)
		local w=vgui.Create("DListView",v)
		w:Dock(FILL)
		local Col1 = w:AddColumn( "Key" )
		local Col2 = w:AddColumn( "Value" )

		local idkey={}
		for k,v in pairs(t) do
			idkey[#idkey+1]=k
			local l=w:AddLine(tostring(k),tostring(v))
			l.Columns[2]:Remove()
			local dt=vgui.Create('DTextEntry',l)
			dt:SetNumeric(true)
			dt:SetKeyBoardInputEnabled(true)
			dt:SetMouseInputEnabled(true)
			l.Columns[2]=dt
			dt:Dock(RIGHT)
			dt:SetText(v)
			dt.OnEnter=function(dt)
				local val=dt:GetValue()
				print("Wunna change",k,"to",tonumber(val))
				net.Start(Tag)
					net.WriteTable{[k]=tonumber(val)}
				net.SendToServer()
			end
		end
		v:Center()
		v:MakePopup()

	end)
end