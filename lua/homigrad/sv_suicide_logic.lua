if SERVER then
    resource.AddFile("resource/fonts/arnopro.ttf")
    util.AddNetworkString("HG_SuicideCutscene")
    return

    concommand.Add("suicide", function(ply)
        if not IsValid(ply) or not ply:Alive() then return end
        if ply:GetNWBool("suiciding") or ply.suiciding then return end -- Already suiciding
        if ply.suicideCutscene then return end -- Cutscene playing

        local wep = ply:GetActiveWeapon()
        -- Only for HG weapons (guns), exclude melee
        if not IsValid(wep) or not wep.ishgweapon or wep.ismelee or wep.ismelee2 then 
            ply:ChatPrint("You must be holding a gun to do this.")
            return 
        end
        
        -- Check if weapon has ammo
        if wep:Clip1() <= 0 then
            ply:ChatPrint("You don't have ammo!")
            return
        end
        
        -- Start cutscene
        ply.suicideCutscene = true
        ply.suicideCutsceneWep = wep -- Track the weapon
        
        net.Start("HG_SuicideCutscene")
        net.WriteBool(true)
        net.Send(ply)
        
        -- TIMELINE:
        -- T+0: Cutscene starts, input blocked (handled by client/hooks)
        -- T+4: Animation starts (suiciding = true)
        -- T+7: Gun fires
        -- T+8: Cutscene ends / Cleanup
        
        -- STAGE 1: T+4s - Start Animation
        timer.Simple(4.0, function()
            if IsValid(ply) and ply:Alive() and ply.suicideCutscene then
                local activeWep = ply:GetActiveWeapon()
                if IsValid(ply.suicideCutsceneWep) and activeWep == ply.suicideCutsceneWep then
                    -- Trigger animation
                    ply:SetNWBool("suiciding", true)
                    ply.suiciding = true
                    -- Set startsuicide to ensure bullet logic works correctly (willsuicidereal check)
                    ply.startsuicide = CurTime()
                else
                     -- Weapon changed, abort
                    ply.suicideCutscene = false
                    ply.suicideCutsceneWep = nil
                    net.Start("HG_SuicideCutscene")
                    net.WriteBool(false)
                    net.Send(ply)
                end
            end
        end)

        -- STAGE 2: T+7s - Fire Gun
        timer.Simple(7.0, function()
            if IsValid(ply) and ply:Alive() and ply.suicideCutscene and ply.suiciding then
                local activeWep = ply:GetActiveWeapon()
                if IsValid(ply.suicideCutsceneWep) and activeWep == ply.suicideCutsceneWep then
                    -- Trigger fire (override checks)
                    if activeWep.Shoot then
                        activeWep:Shoot(true)
                    else
                        activeWep:PrimaryAttack()
                    end
                end
            end
        end)

        -- STAGE 3: T+8s - Cleanup
        timer.Simple(8.0, function()
             if IsValid(ply) then
                -- Only reset if we are still in the cutscene (player might be dead by now, which is fine)
                -- If player died, HG_ResetSuicideCutscene hook handles it.
                -- If player survived (e.g. empty mag), we reset here.
                if ply.suicideCutscene then
                    ply.suicideCutscene = false
                    ply.suicideCutsceneWep = nil
                    ply:SetNWBool("suiciding", false)
                    ply.suiciding = false
                    ply.startsuicide = nil
                    net.Start("HG_SuicideCutscene")
                    net.WriteBool(false)
                    net.Send(ply)
                end
            end
        end)
    end)
    
    hook.Add("PlayerDeath", "HG_ResetSuicideCutscene", function(ply)
        if ply.suicideCutscene then
            ply.suicideCutscene = false
            ply.suicideCutsceneWep = nil
            net.Start("HG_SuicideCutscene")
            net.WriteBool(false)
            net.Send(ply)
        end
        ply:SetNWBool("suiciding", false)
        ply.suiciding = false
        ply.startsuicide = nil
    end)
    
    hook.Add("PlayerSpawn", "HG_ResetSuicideCutsceneSpawn", function(ply)
        ply:SetNWBool("suiciding", false)
        ply.suiciding = false
        ply.startsuicide = nil
        ply.suicideCutscene = false
        ply.suicideCutsceneWep = nil
        net.Start("HG_SuicideCutscene")
        net.WriteBool(false)
        net.Send(ply)
    end)

    -- Prevent weapon switching during cutscene
    hook.Add("PlayerSwitchWeapon", "HG_SuicideCutscene_NoSwitch", function(ply, oldWep, newWep)
        if ply.suicideCutscene then
            return true -- Block switching
        end
    end)
end
