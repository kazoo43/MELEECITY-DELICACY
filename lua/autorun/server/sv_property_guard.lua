if SERVER then
    hook.Add("CanProperty", "mcity_block_motioncontrol_ragdoll", function(ply, property, ent)
        if property ~= "motioncontrol_ragdoll" then return end
        if not IsValid(ply) or not (ply:IsAdmin() or ply:IsSuperAdmin()) then return false end
        ply._mcity_last_motionprop = ply._mcity_last_motionprop or 0
        if ply._mcity_last_motionprop > CurTime() then return false end
        ply._mcity_last_motionprop = CurTime() + 1
    end)

    timer.Simple(0, function()
        local recv = net.Receivers and net.Receivers["properties"]
        if not recv then return end
        net.Receivers["properties"] = function(len, ply)
            if not IsValid(ply) then return end
            local now = CurTime()
            ply._mcity_prop_window = ply._mcity_prop_window or now
            ply._mcity_prop_count = (ply._mcity_prop_count or 0) + 1
            if now - ply._mcity_prop_window >= 1 then
                ply._mcity_prop_window = now
                ply._mcity_prop_count = 1
            end
            if ply._mcity_prop_count > 30 then return end
            return recv(len, ply)
        end
    end)
end
