if CLIENT then
    local active = false
    local startTime = 0
    local suicideSound = nil
    
    net.Receive("HG_SuicideCutscene", function()
        local start = net.ReadBool()
        active = start
        if start then
            startTime = CurTime()
            if suicideSound then suicideSound:Stop() end
            suicideSound = CreateSound(LocalPlayer(), "notaweaponanoption.mp3")
            suicideSound:Play()
            suicideSound:ChangeVolume(1, 0)
            
            local ply = LocalPlayer()
            local wep = ply:GetActiveWeapon()
            if IsValid(wep) then
                -- Trigger inspect (set inspect time to future)
                wep.inspect = CurTime() + 7 -- Extended inspect time to match 8s sequence
            end
        else
            if suicideSound then
                suicideSound:Stop()
                suicideSound = nil
            end
        end
    end)
    
    local color_blue = Color(0, 50, 100, 255) -- Dark sky blue ish
    
    surface.CreateFont("SuicideFont",{
        font = "Arno Pro",
        size = ScreenScale(20), -- Significantly bigger
        weight = 1000,
        antialias = true
    })

    hook.Add("StartCommand", "HG_SuicideCutsceneInput", function(ply, cmd)
        if active then
            cmd:ClearMovement()
            -- cmd:SetViewAngles(ply:EyeAngles()) -- Removed to allow looking around
        end
    end)

    hook.Add("AdjustMouseSensitivity", "HG_SuicideCutsceneSens", function()
        if active then
            return 0.01
        end
    end)

    hook.Add("PostDrawTranslucentRenderables", "HG_SuicideCutsceneOverlay", function()
        if not active then return end
        
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        
        -- Calculate fade in
        local elapsed = CurTime() - startTime
        local alpha = math.Clamp(elapsed * 510, 0, 255) -- Fade in over 0.5s
        
        color_blue.a = alpha
        
        render.SetStencilWriteMask( 0xFF )
        render.SetStencilTestMask( 0xFF )
        render.SetStencilReferenceValue( 0 )
        render.SetStencilCompareFunction( STENCIL_ALWAYS )
        render.SetStencilPassOperation( STENCIL_KEEP )
        render.SetStencilFailOperation( STENCIL_KEEP )
        render.SetStencilZFailOperation( STENCIL_KEEP )
        render.ClearStencil()

        render.SetStencilEnable( true )
        render.SetStencilReferenceValue( 1 )
        render.SetStencilCompareFunction( STENCIL_ALWAYS )
        render.SetStencilPassOperation( STENCIL_REPLACE )
        
        -- Draw Body/Weapon (Mask) to Stencil Buffer (Invisible)
        render.SetBlend(0)
        
        local ent = ply.FakeRagdoll
        if IsValid(ent) then
            ent:DrawModel()
        else
            ply:DrawModel()
        end
        
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) then
            wep:DrawModel()
        end
        
        render.SetBlend(1)
        
        -- Draw Overlay
        render.SetStencilReferenceValue( 1 )
        render.SetStencilCompareFunction( STENCIL_NOTEQUAL ) -- Draw where Stencil != 1
        
        cam.Start2D()
            surface.SetDrawColor(color_blue)
            surface.DrawRect(0, 0, ScrW(), ScrH())
        cam.End2D()
        
        render.SetStencilEnable( false )

        -- Handle Sound Fade Out
        -- Fade out starting at 6s, ending at 8s
        if suicideSound and elapsed > 6.0 then
             local fadeProgress = (elapsed - 6.0) / 2.0 -- 0 to 1 over 2 seconds
             local vol = math.Clamp(1 - fadeProgress, 0, 1)
             suicideSound:ChangeVolume(vol, 0.1)
        end
    end)
    
    hook.Add("HUDShouldDraw", "HG_HideHUDSuicide", function(name)
        if active then
            return false
        end
    end)

    hook.Add("DrawOverlay", "HG_SuicideCutsceneText", function()
        if not active then return end
        
        local elapsed = CurTime() - startTime
        
        -- Text 1: 2.0s "this is not a weapon"
        -- Position: Top right, but not directly in the corner
        if elapsed >= 2.0 then
            local text = "this is not a weapon"
            local textColor = Color(255, 255, 255, 255)
            
            local shakeX, shakeY = 0, 0
            if elapsed < 2.1 then -- Bright flash and shake for 0.1s
                textColor = Color(255, 255, 200, 255)
                shakeX = math.random(-5, 5)
                shakeY = math.random(-5, 5)
            end
            
            surface.SetFont("SuicideFont")
            local w, h = surface.GetTextSize(text)
            
            -- x: Screen width - text width - padding (e.g., 20% of width)
            -- y: Padding from top (e.g., 20% of height)
            local x = ScrW() - w - (ScrW() * 0.2) + shakeX
            local y = ScrH() * 0.2 + shakeY
            
            draw.SimpleText(text, "SuicideFont", x, y, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
        
        -- Text 2: 4.12s "it is an option"
        -- Position: Bottom left, but not directly in the corner
        if elapsed >= 4.12 then
             local text = "it is an option"
             
             local shakeX, shakeY = 0, 0
             if elapsed < 4.22 then -- Shake for 0.1s
                 shakeX = math.random(-5, 5)
                 shakeY = math.random(-5, 5)
             end
             
             -- x: Padding from left (e.g., 20% of width)
             -- y: Screen height - text height - padding (e.g., 20% of height)
             local x = ScrW() * 0.2 + shakeX
             local y = ScrH() * 0.8 + shakeY
             
             draw.SimpleText(text, "SuicideFont", x, y, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
    end)
end
