if game.GetMap():find("dm_") then
    hook.Add("InitPostEntity", "dm_*_strip", function()
        for key, ent in pairs(ents.GetAll()) do
            if not ent:GetOwner():IsPlayer() then
                if ent:IsWeapon() or ent:GetClass():find("item",nil,true) then 
                    ent:Remove()
                end      
            end    
        end

        hook.Remove("InitPostEntity", "dm_*_strip")
    end)
end