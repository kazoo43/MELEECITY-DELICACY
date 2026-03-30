local healthModel
local blinkModel
local whiteMat = Material("models/debug/debugwhite")
local gradientMat = Material("gui/center_gradient")

local IND_SIZE_BASE = 120
local IND_SIZE_MAX = 170
local GRADIENT_OFFSET_X = -30
local GRADIENT_OFFSET_Y = 20
local STAMINA_OFFSET_X = -30
local STAMINA_OFFSET_Y = 13
local PULSE_DURATION = 8
local BLINK_SCALE = Vector(1.05, 1.05, 1.05)
local BLINK_DURATION = 5
local FRACTURE_BLINK_SPEED = 10
local POS_VISIBLE_X = 0
local POS_HIDDEN_X = -400

local currentX = nil
local pulseStartTime = 0
local limbStates = {}
local boneCache = {}
local lastLifeState = nil

local limbBones = {
    lleg = "ValveBiped.Bip01_L_Thigh",
    rleg = "ValveBiped.Bip01_R_Thigh",
    larm = "ValveBiped.Bip01_L_UpperArm",
    rarm = "ValveBiped.Bip01_R_UpperArm"
}

local amputationBones = {
    lleg = "ValveBiped.Bip01_L_Calf",
    rleg = "ValveBiped.Bip01_R_Calf",
    larm = "ValveBiped.Bip01_L_Forearm",
    rarm = "ValveBiped.Bip01_R_Forearm"
}

local function ScreenScaleFixed(size)
    return size * (ScrH() / 480)
end

local function SetBoneScaleRecursive(ent, boneName, scale)
    local boneID = ent:LookupBone(boneName)
    if not boneID then return end
    
    ent:ManipulateBoneScale(boneID, scale)
    
    local children = ent:GetChildBones(boneID)
    for _, childID in pairs(children) do
        ent:ManipulateBoneScale(childID, scale)
    end
end

local function ScaleBoneAndChildren(ent, boneID, scale)
    ent:ManipulateBoneScale(boneID, scale)
    local children = ent:GetChildBones(boneID)
    for _, child in ipairs(children) do
        ScaleBoneAndChildren(ent, child, scale)
    end
end

local function InitBlinkModel(ent)
    ent:SetupBones()
    for i = 0, ent:GetBoneCount() - 1 do
        ent:ManipulateBoneScale(i, Vector(0, 0, 0))
    end
end

local function ResetModels(ply)
    if IsValid(healthModel) then
        if healthModel.accessories then
            for _, v in pairs(healthModel.accessories) do
                if IsValid(v) then v:Remove() end
            end
        end
        healthModel:Remove()
    end
    if IsValid(blinkModel) then
        blinkModel:Remove()
    end
    healthModel = nil
    blinkModel = nil
    limbStates = {}
    pulseStartTime = 0
end

local function DrawHealthAccessories(healthModel, ply)
    local accessories = ply:GetNetVar("Accessories")
    if not accessories then 
        if healthModel.accessories then
            for k, v in pairs(healthModel.accessories) do
                if IsValid(v) then v:Remove() end
            end
            healthModel.accessories = nil
        end
        return 
    end
    
    healthModel.accessories = healthModel.accessories or {}
    local accList = istable(accessories) and accessories or {accessories}
    local currentAccs = {}
    
    for _, accName in pairs(accList) do
        currentAccs[accName] = true
        local accessData = hg.Accessories[accName]
        if not accessData then continue end
        if accessData.norender then continue end
        
        local model = healthModel.accessories[accName]
        local isFemale = false
        if hg.Appearance.FuckYouModels and hg.Appearance.FuckYouModels[2][healthModel:GetModel()] then
            isFemale = true
        end
        
        if not IsValid(model) then
            local modelPath = isFemale and accessData.femmodel or accessData.model
            if not modelPath then continue end
            
            model = ClientsideModel(modelPath, RENDERGROUP_OTHER)
            model:SetNoDraw(true)
            model:SetModelScale(accessData[isFemale and "fempos" or "malepos"][3])
            
            local skin = accessData.skin
            if isfunction(skin) then skin = skin(healthModel) end
            model:SetSkin(skin or 0)
            
            model:SetBodyGroups(accessData.bodygroups or "")
            
            if accessData.bonemerge then
                model:AddEffects(EF_BONEMERGE)
            end
            
            if accessData.bSetColor then
                local col = ply:GetPlayerColor() or Vector(1,1,1)
                model:SetColor(col:ToColor())
            end
            
            if accessData.SubMat then
                model:SetSubMaterial(0, accessData.SubMat)
            end
            
            healthModel.accessories[accName] = model
        end
        
        local boneName = accessData.bone
        local bone = healthModel:LookupBone(boneName)
        
        if bone then
            local matrix = healthModel:GetBoneMatrix(bone)
            if matrix then
                local bonePos, boneAng = matrix:GetTranslation(), matrix:GetAngles()
                local posData = accessData[isFemale and "fempos" or "malepos"]
                local localPos, localAng = posData[1], posData[2]
                
                local pos, ang = LocalToWorld(localPos, localAng, bonePos, boneAng)
                
                model:SetRenderOrigin(pos)
                model:SetRenderAngles(ang)
                
                if model:GetParent() ~= healthModel then
                    model:SetParent(healthModel, bone)
                end
                
                model:DrawModel()
            end
        end
    end
    
    for name, model in pairs(healthModel.accessories) do
        if not currentAccs[name] then
            if IsValid(model) then model:Remove() end
            healthModel.accessories[name] = nil
        end
    end
end

hook.Add("HUDPaint", "HG_HealthIndicator", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local alive = ply:Alive()
    if lastLifeState ~= alive then
        ResetModels(ply)
        lastLifeState = alive
    end
    
    if not alive then return end
    if gui.IsGameUIVisible() then return end
    
    if not IsValid(healthModel) then
        healthModel = ClientsideModel(ply:GetModel(), RENDERGROUP_OTHER)
        healthModel:SetNoDraw(true)
        healthModel:SetIK(false)
        local seq = healthModel:LookupSequence("idle_suitcase")
        if seq then
            healthModel:SetSequence(seq)
            healthModel:SetCycle(0)
        end
    end
    
    if not IsValid(blinkModel) then
        blinkModel = ClientsideModel(ply:GetModel(), RENDERGROUP_OTHER)
        blinkModel:SetNoDraw(true)
        blinkModel:SetIK(false)
        local seq = blinkModel:LookupSequence("idle_suitcase")
        if seq then
            blinkModel:SetSequence(seq)
            blinkModel:SetCycle(0)
        end
        InitBlinkModel(blinkModel)
    end

    if healthModel:GetModel() ~= ply:GetModel() then
        healthModel:SetModel(ply:GetModel())
        blinkModel:SetModel(ply:GetModel())
        
        local seq = healthModel:LookupSequence("idle_suitcase")
        if seq then
            healthModel:SetSequence(seq)
            healthModel:SetCycle(0)
        end
        local seq2 = blinkModel:LookupSequence("idle_suitcase")
        if seq2 then
            blinkModel:SetSequence(seq2)
            blinkModel:SetCycle(0)
        end

        InitBlinkModel(blinkModel)
        limbStates = {}
        
        if healthModel.accessories then
            for _, v in pairs(healthModel.accessories) do
                if IsValid(v) then v:Remove() end
            end
            healthModel.accessories = nil
        end
    end

    local consciousness = 1
    local otrub = false
    local org = ply.organism
    
    if org then
        if org.consciousness then consciousness = org.consciousness end
        if org.otrub then otrub = org.otrub end
    end
    
    local targetX = otrub and POS_HIDDEN_X or POS_VISIBLE_X
    local targetXScaled = ScreenScaleFixed(targetX)
    
    if not currentX then currentX = ScreenScaleFixed(POS_HIDDEN_X) end
    currentX = Lerp(FrameTime() * 2, currentX, targetXScaled)
    
    local time = CurTime()
    if org then
        for limb, boneName in pairs(limbBones) do
            local isAmputated = org[limb.."amputated"]
            local isBroken = (org[limb] and org[limb] >= 1)
            local isDislocated = org[limb.."dislocation"]
            
            if not limbStates[limb] then
                limbStates[limb] = { 
                    amputated = false, 
                    blinking = false, 
                    blinkEnd = 0,
                    fractured = false
                }
            end
            
            local state = limbStates[limb]
            local ampBoneName = amputationBones[limb] or boneName
            
            if state.amputated and not isAmputated then
                state.amputated = false
                state.blinking = false
                local boneID = healthModel:LookupBone(ampBoneName)
                if boneID then ScaleBoneAndChildren(healthModel, boneID, Vector(1, 1, 1)) end
                local blinkBoneID = blinkModel:LookupBone(ampBoneName)
                if blinkBoneID then ScaleBoneAndChildren(blinkModel, blinkBoneID, Vector(0, 0, 0)) end
            end
            
            if state.fractured and not (isBroken or isDislocated) then
                state.fractured = false
                if not state.amputated then
                    local blinkBoneID = blinkModel:LookupBone(boneName)
                    if blinkBoneID then ScaleBoneAndChildren(blinkModel, blinkBoneID, Vector(0, 0, 0)) end
                    
                    local boneID = healthModel:LookupBone(boneName)
                    if boneID then ScaleBoneAndChildren(healthModel, boneID, Vector(1, 1, 1)) end
                end
            end

            if isAmputated then
                if state.fractured then
                     state.fractured = false
                     local blinkBoneID = blinkModel:LookupBone(boneName)
                     if blinkBoneID then ScaleBoneAndChildren(blinkModel, blinkBoneID, Vector(0, 0, 0)) end
                     
                     local boneID = healthModel:LookupBone(boneName)
                     if boneID then ScaleBoneAndChildren(healthModel, boneID, Vector(1, 1, 1)) end
                end

                if not state.amputated then
                    state.amputated = true
                    state.blinking = true
                    state.blinkEnd = time + BLINK_DURATION
                    pulseStartTime = time
                    
                    local boneID = healthModel:LookupBone(ampBoneName)
                    if boneID then ScaleBoneAndChildren(healthModel, boneID, Vector(0, 0, 0)) end
                    
                    local blinkBoneID = blinkModel:LookupBone(ampBoneName)
                    if blinkBoneID then ScaleBoneAndChildren(blinkModel, blinkBoneID, BLINK_SCALE) end
                end
                
                if state.blinking and time > state.blinkEnd then
                    state.blinking = false
                    local blinkBoneID = blinkModel:LookupBone(ampBoneName)
                    if blinkBoneID then ScaleBoneAndChildren(blinkModel, blinkBoneID, Vector(0, 0, 0)) end
                end
                
            elseif (isBroken or isDislocated) then
                if not state.fractured then
                    state.fractured = true
                    pulseStartTime = time
                    local blinkBoneID = blinkModel:LookupBone(boneName)
                    if blinkBoneID then ScaleBoneAndChildren(blinkModel, blinkBoneID, BLINK_SCALE) end
                    
                    local boneID = healthModel:LookupBone(boneName)
                    if boneID then ScaleBoneAndChildren(healthModel, boneID, Vector(0, 0, 0)) end
                end
            end
        end
    end

    local size = IND_SIZE_BASE
    
    local w, h = ScreenScaleFixed(size), ScreenScaleFixed(size)
    local y = ScrH() - h - ScreenScaleFixed(20)
    
    local camPos = Vector(95, 0, 65) 
    local lookAng = Angle(11, 180, 0)
    
    local renderX = currentX
    
    local SILHOUETTE_OFFSET_X = -15
    local SILHOUETTE_OFFSET_Y = 15
    
    local viewX = renderX + ScreenScaleFixed(SILHOUETTE_OFFSET_X)
    local viewY = y + ScreenScaleFixed(SILHOUETTE_OFFSET_Y)
    
    local modelOffset = Vector(0, 0, 0)
    
    surface.SetMaterial(gradientMat)
    local gCol = math.Clamp(consciousness, 0, 1) * 255
    surface.SetDrawColor(gCol, gCol, gCol, 25)
    
    local gradX = currentX + ScreenScaleFixed(GRADIENT_OFFSET_X)
    local gradY = y + ScreenScaleFixed(GRADIENT_OFFSET_Y)
    local gradW = w * 1.2 
    local gradH = h
    
    surface.DrawTexturedRect(gradX, gradY, gradW, gradH)
    
    local camRenderX = viewX
    if camRenderX < 0 then
        local dist = camPos.x
        local fov = 50
        local visibleHeight = 2 * dist * math.tan(math.rad(fov) / 2)
        local unitsPerPixel = visibleHeight / h
        
        local pixelShift = camRenderX 
        local unitShift = pixelShift * unitsPerPixel 
        
        modelOffset = Vector(0, unitShift, 0)
        camRenderX = 0
    end
    
    cam.Start3D(camPos, lookAng, 50, camRenderX, viewY, w, h)
        render.SuppressEngineLighting(true)
        render.MaterialOverride(whiteMat)
        
        local col = math.Clamp(consciousness, 0, 1)
        render.SetColorModulation(col, col, col)
        
        healthModel:SetPos(modelOffset)
        healthModel:SetAngles(Angle(0, 0, 0))
        
        for i = 0, ply:GetNumBodyGroups() - 1 do
            healthModel:SetBodygroup(i, ply:GetBodygroup(i))
        end
        healthModel:SetSkin(ply:GetSkin())
        
        healthModel:SetupBones()
        healthModel:DrawModel()
        
        DrawHealthAccessories(healthModel, ply)
        
        local hasAmputationBlink = false
        local hasFractureBlink = false
        
        for _, state in pairs(limbStates) do
            if state.blinking then hasAmputationBlink = true end
            if state.fractured then hasFractureBlink = true end
        end
        
        if hasAmputationBlink then
            local val = (math.sin(time * 10) + 1) / 2
            render.SetColorModulation(val, 0, 0)
            
            if hasFractureBlink then
                for l, s in pairs(limbStates) do
                    if s.fractured then
                        local bID = blinkModel:LookupBone(limbBones[l])
                        if bID then ScaleBoneAndChildren(blinkModel, bID, Vector(0,0,0)) end
                    end
                end
            end
            
            blinkModel:SetPos(modelOffset)
            blinkModel:SetAngles(Angle(0, 0, 0))
            blinkModel:SetupBones()
            blinkModel:DrawModel()
            
            if hasFractureBlink then
                for l, s in pairs(limbStates) do
                    if s.fractured then
                        local bID = blinkModel:LookupBone(limbBones[l])
                        if bID then ScaleBoneAndChildren(blinkModel, bID, BLINK_SCALE) end
                    end
                end
            end
        end
        
        if hasFractureBlink then
            local val = (math.sin(time * FRACTURE_BLINK_SPEED) + 1) / 2
            render.SetColorModulation(val, 0, 0)
            
            if hasAmputationBlink then
                for l, s in pairs(limbStates) do
                    if s.blinking then
                        local ampBoneName = amputationBones[l] or limbBones[l]
                        local bID = blinkModel:LookupBone(ampBoneName)
                        if bID then ScaleBoneAndChildren(blinkModel, bID, Vector(0,0,0)) end
                    end
                end
            end
            
            blinkModel:SetPos(modelOffset)
            blinkModel:SetAngles(Angle(0, 0, 0))
            blinkModel:SetupBones()
            blinkModel:DrawModel()
            
            if hasAmputationBlink then
                for l, s in pairs(limbStates) do
                    if s.blinking then
                        local ampBoneName = amputationBones[l] or limbBones[l]
                        local bID = blinkModel:LookupBone(ampBoneName)
                        if bID then ScaleBoneAndChildren(blinkModel, bID, BLINK_SCALE) end
                    end
                end
            end
        end
        
        render.MaterialOverride(nil)
        render.SetColorModulation(1, 1, 1)
        render.SuppressEngineLighting(false)
    cam.End3D()
    
    if org and org.stamina then
        local st = org.stamina
        local val = (type(st) == "table") and st[1] or st
        if type(val) == "table" then val = val[1] or 0 end
        if type(val) ~= "number" then val = 0 end
        
        local max = (type(st) == "table") and st.max or 100
        if type(max) ~= "number" then max = 100 end
        max = math.max(max, 1)
        
        local barW = ScreenScaleFixed(6)
        local barH = h * 0.8
        local barX = viewX + w + ScreenScaleFixed(STAMINA_OFFSET_X)
        local barY = viewY + (h - barH) / 2 + ScreenScaleFixed(STAMINA_OFFSET_Y)
        
        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawRect(barX, barY, barW, barH)
        
        local fillH = barH * math.Clamp(val / max, 0, 1)
        surface.SetDrawColor(0, 50, 100, 255)
        surface.DrawRect(barX + 1, barY + barH - fillH + 1, barW - 2, fillH - 2)
    end
end)

hook.Add("OnRemove", "HG_CleanupHealthIndicator", function()
    if IsValid(healthModel) then healthModel:Remove() end
    if IsValid(blinkModel) then blinkModel:Remove() end
end)
