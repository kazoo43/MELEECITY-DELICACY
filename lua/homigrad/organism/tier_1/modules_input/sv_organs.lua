--local Organism = hg.organism
-- Brain Chunks Logic (Ported from actually_brain_chunks_rework_check_desc_3673949172)
local GORE_CVARS = {
    scale = 0.9,
    life_span = 60,
    cleanup = true,
    visuals = true
}

local GORE_DECAL_REGISTRY = {}
local GORE_DECAL_PATH = "effects/droplets/"

for i = 2, 13 do
    local base = "drop" .. i
    local function register(name)
        if file.Exists("materials/" .. GORE_DECAL_PATH .. name .. ".vmt", "GAME") then
            local id = "Meat_" .. name
            game.AddDecal(id, GORE_DECAL_PATH .. name)
            table.insert(GORE_DECAL_REGISTRY, id)
        end
    end

    register(base)
    for j = 1, 5 do register(base .. "_" .. j) end
end

local CHUNKS_IN_WORLD = {}
local nextGoreThink = 0

local function CreateBrainChunk(origin, direction)
    if #CHUNKS_IN_WORLD >= 30 then return end

    local piece = ents.Create("prop_physics")
    if not IsValid(piece) then return end

    piece:SetModel("models/props_junk/watermelon01_chunk02c.mdl")
    piece:SetPos(origin)
    piece:SetAngles(AngleRand())
    piece:SetMaterial("models/flesh")
    piece:SetColor(Color(120, 0, 0))
    piece:DrawShadow(false)
    
    local baseScale = GORE_CVARS.scale
    piece:SetModelScale(math.Rand(baseScale * 0.9, baseScale * 1.35), 0)
    piece:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    piece:Spawn()

    piece:EmitSound("physics/flesh/flesh_squishy_impact_hard"..math.random(1,4)..".wav", 60, math.random(200, 255))

    piece.GoreState = {
        Sticking = false,
        SlideSpeed = 1,
        GravityMod = math.Rand(0.04, 0.07),
        Friction = math.Rand(0.00005, 0.00015)
    }

    local phys = piece:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetMaterial("flesh")
        phys:SetVelocity(direction * 50 + VectorRand() * 20)
    end

    if GORE_CVARS.cleanup then 
        SafeRemoveEntityDelayed(piece, GORE_CVARS.life_span) 
    end
    table.insert(CHUNKS_IN_WORLD, piece)
end

hook.Add("Think", "BrainChunks_GoreSimProcessor", function()
    local curTime = CurTime()
    if curTime < nextGoreThink then return end
    nextGoreThink = curTime + 0.02
    local perfStart = HGPerf and HGPerf:Begin() or nil
    for i = #CHUNKS_IN_WORLD, 1, -1 do
        local ent = CHUNKS_IN_WORLD[i]
        if not IsValid(ent) then table.remove(CHUNKS_IN_WORLD, i) continue end

        local state = ent.GoreState
        if not state.Sticking then
            local trace = util.TraceLine({
                start = ent:GetPos(),
                endpos = ent:GetPos() + (ent:GetVelocity() * FrameTime() * 1.5),
                filter = ent
            })

            if trace.Hit and trace.HitWorld and not trace.HitSky then
                state.Sticking = true
                ent:SetMoveType(MOVETYPE_NONE)
                ent:SetPos(trace.HitPos + trace.HitNormal * 0.1)
                
                local phys = ent:GetPhysicsObject()
                if IsValid(phys) then 
                    state.ImpactDir = phys:GetVelocity():GetNormalized()
                    phys:EnableCollisions(false) 
                end

                if GORE_CVARS.visuals and #GORE_DECAL_REGISTRY > 0 then
                    util.Decal(table.Random(GORE_DECAL_REGISTRY), trace.HitPos + trace.HitNormal, trace.HitPos - trace.HitNormal, ent)
                end
            end
        else
            local moved, attached = false, true
            
            if state.GravityMod > 0.001 then
                local downPos = ent:GetPos() + Vector(0, 0, -state.GravityMod)
                if bit.band(util.PointContents(downPos), CONTENTS_SOLID) != CONTENTS_SOLID then
                    ent:SetPos(downPos)
                    moved = true
                else
                    attached = false
                end
                state.GravityMod = state.GravityMod - (state.Friction or 0)
            end

            if not attached and state.ImpactDir and state.SlideSpeed > 0.01 then
                local driftPos = ent:GetPos() + Vector(state.ImpactDir.x, state.ImpactDir.y, 0) * state.SlideSpeed
                if bit.band(util.PointContents(driftPos), CONTENTS_SOLID) != CONTENTS_SOLID then
                    ent:SetPos(driftPos)
                    moved = true
                end
                state.SlideSpeed = state.SlideSpeed - 0.02
            end

            if moved and GORE_CVARS.visuals and #GORE_DECAL_REGISTRY > 0 and (ent.NextDrip or 0) < curTime then
                util.Decal(table.Random(GORE_DECAL_REGISTRY), ent:GetPos() + Vector(0,0,2), ent:GetPos() - Vector(0,0,5), ent)
                ent.NextDrip = curTime + math.Rand(0.03, 0.08)
            end
        end
    end
    if HGPerf and perfStart then HGPerf:End("organs.brainchunks.think", perfStart) end
end)

local function isCrush(dmgInfo)
	return not dmgInfo:IsDamageType(DMG_BULLET + DMG_BUCKSHOT + DMG_SLASH + DMG_BLAST)
end

local function damageOrgan(org, dmg, dmgInfo, key)
	local prot = math.max(0.3 - org[key],0)
	local oldval = org[key]
	org[key] = math.Round(math.min(org[key] + dmg * (isCrush(dmgInfo) and 1 or 3), 1), 3)
	
	//local damage = org[key] - oldval
	//dmgInfo:SetDamage(dmgInfo:GetDamage() + (damage * 5))

	dmgInfo:ScaleDamage(0.8)

	return 0//isCrush(dmgInfo) and 0 or prot
end

local input_list = hg.organism.input_list
input_list.heart = function(org, bone, dmg, dmgInfo)
	local oldDmg = org.heart

	local result = damageOrgan(org, dmg * 0.3, dmgInfo, "heart")

	hg.AddHarmToAttacker(dmgInfo, (org.heart - oldDmg) * 10, "Heart damage harm")
	
	org.shock = org.shock + dmg * 20
	org.internalBleed = org.internalBleed + (org.heart - oldDmg) * 10

	return result
end

input_list.liver = function(org, bone, dmg, dmgInfo)
	local oldDmg = org.liver
	local prot = math.max(0.3 - org.liver,0)
	
	hg.AddHarmToAttacker(dmgInfo, (org.liver - oldDmg) * 3, "Liver damage harm")
	
	org.shock = org.shock + dmg * 20
	org.painadd = org.painadd + dmg * 35
	
	org.liver = math.min(org.liver + dmg, 1)
	local harmed = (org.liver - oldDmg)
	if org.analgesia < 0.4 and harmed >= 0.2 then
		timer.Simple(0, function()
			if harmed > 0 then -- wtf? whatever
				hg.StunPlayer(org.owner,2)
			else
				hg.LightStunPlayer(org.owner,2)
			end
		end)
	end

	org.internalBleed = org.internalBleed + harmed * 4
	
	dmgInfo:ScaleDamage(0.8)

	return 0
end

input_list.stomach = function(org, bone, dmg, dmgInfo)
	local oldDmg = org.stomach

	local result = damageOrgan(org, dmg, dmgInfo, "stomach")

	hg.AddHarmToAttacker(dmgInfo, (org.stomach - oldDmg) * 2, "Stomach damage harm")
	
	org.internalBleed = org.internalBleed + (org.stomach - oldDmg) * 2
	return result
end

input_list.intestines = function(org, bone, dmg, dmgInfo)
	local oldDmg = org.intestines

	local result = damageOrgan(org, dmg, dmgInfo, "intestines")

	hg.AddHarmToAttacker(dmgInfo, (org.intestines - oldDmg) * 2, "Intestines damage harm")

	org.internalBleed = org.internalBleed + (org.intestines - oldDmg) * 2
	return result
end

input_list.brain = function(org, bone, dmg, dmgInfo)
	if dmgInfo:IsDamageType(DMG_BLAST) then dmg = dmg / 50 end
	local oldDmg = org.brain
	local result = damageOrgan(org, dmg * 1, dmgInfo, "brain")
	local brainDelta = org.brain - oldDmg

	hg.AddHarmToAttacker(dmgInfo, brainDelta * 15, "Brain damage harm")

	if brainDelta > 0 then
		local time = CurTime()
		if not org.brainBurstWindowStart or (time - org.brainBurstWindowStart) > 1.2 then
			org.brainBurstWindowStart = time
			org.brainBurstDamage = 0
		end
		org.brainBurstLast = time
		org.brainBurstDamage = (org.brainBurstDamage or 0) + brainDelta
	end

	if brainDelta > 0 then
		local soundFile = (math.random(2) == 1) and "hits/headshot1.wav" or "hits/headshot2.wav"
		org.owner:EmitSound(soundFile, 60, math.random(90, 120))
	end

	-- Brain chunks logic
	if org.skull and org.skull >= 1 and org.brain > 0.55 then
		local multiplier = 0
		if dmgInfo:IsDamageType(DMG_CLUB) then
			multiplier = 0.45
		elseif dmgInfo:IsDamageType(DMG_BUCKSHOT) then
			multiplier = 1.1
		elseif dmgInfo:IsDamageType(DMG_BULLET) then
			multiplier = 1
		end

		if multiplier > 0 then
			local base_chunks = 3
			local count = math.floor(base_chunks * multiplier)
			for i=1, count do
				CreateBrainChunk(dmgInfo:GetDamagePosition(), dmgInfo:GetDamageForce():GetNormalized() + VectorRand() * 0.5)
			end
		end
	end

	local headshotEffect = dmgInfo:IsDamageType(DMG_BULLET + DMG_BUCKSHOT) and org.skull and org.skull >= 1
	if dmg > 0 then
		local effectEnt = hg.GetCurrentCharacter(org.owner)
		if not IsValid(effectEnt) then effectEnt = org.owner end
		net.Start("hg_brainmist")
		net.WriteEntity(effectEnt)
		net.WriteVector(dmgInfo:GetDamagePosition())
		net.WriteAngle(dmgInfo:GetDamageForce():GetNormalized():Angle())
		net.WriteBool(headshotEffect)
		net.WriteBool(dmgInfo:IsDamageType(DMG_CLUB))
		net.WriteBool(true)
		net.Broadcast()
	end

	if org.brain >= 0.01 and brainDelta > 0.01 and math.random(3) == 1 then
		--hg.applyFencingToPlayer(org.owner, org)
		org.shock = 70

		timer.Simple(0.1, function()
			local rag = hg.GetCurrentCharacter(org.owner)

			if rag:IsRagdoll() then
				local stype = hg.getRandomSpasm()
				hg.applySpasm(rag, stype)
				if rag.organism then rag.organism.spasm, rag.organism.spasmType = true, stype end
			end
		end)
	end

	org.consciousness = math.Approach(org.consciousness, 0, dmg * 3)
	
	org.disorientation = org.disorientation + dmg * 1
	org.shock = org.shock + dmg * 3
	org.painadd = org.painadd + dmg * 10
	return result
end

local angZero = Angle(0, 0, 0)
local vecZero = Vector(0, 0, 0)
local function getlocalshit(ent, bone, dmgInfo, dir, hit)
	if IsValid(ent) and bone then
		local ent = IsValid(ent.FakeRagdoll) and ent.FakeRagdoll or ent
		local bonePos, boneAng = ent:GetBonePosition(bone)
		local dmgPos = not isbool(hit) and hit or bonePos
		
		local localPos, localAng = WorldToLocal(dmgPos, angZero, bonePos, boneAng)
		local _, dir2 = WorldToLocal(vecZero, dir:Angle(), vecZero, boneAng)
		dir2 = dir2:Forward()
		return localPos, localAng, dir2
	end
end

local arterySize = {
	["arteria"] = 14,
	["rarmartery"] = 6,
	["larmartery"] = 6,
	["rlegartery"] = 9,
	["llegartery"] = 9,
	["spineartery"] = 10,
}

local arteryMessages ={
	"I can feel blood rushing from my neck...",
	"My neck.. it's... pumping out blood.",
	"I'm bleeding out of my neck!"
}

local function hitArtery(artery, org, dmg, dmgInfo, boneindex, dir, hit)
	if isCrush(dmgInfo) then return 1 end
	if dmgInfo:IsDamageType(DMG_BLAST) then return 1 end
	
	local wep = dmgInfo:GetInflictor()
	local chance = (IsValid(wep) and wep.ArteryChance) or 0
	if dmgInfo:IsDamageType(DMG_SLASH) then
		local baseChance = (dmg < 2) and 0.2 or 1.0
		local totalChance = baseChance + chance
		if totalChance < 1 and math.random() > totalChance then return end
	end
	
	org.painadd = org.painadd + dmg * 1
	if org[artery] == 1 then return 0 end
	if org[string.Replace(artery, "artery", "").."amputated"] then return end
	local owner = org.owner

	if artery ~= "arteria" then
		hg.AddHarmToAttacker(dmgInfo, 4, "Random artery punctured harm")//((1 - org[artery]) - math.max((1 - org[artery]) - dmg,0)) / 4
	else
		if org.isPly and not org.otrub then
			org.owner:Notify(table.Random(arteryMessages), true, "arteria", 0)
		end
		
		hg.AddHarmToAttacker(dmgInfo, 15, "Carotid artery punctured harm")
		org.neckslit = true
		org.needfake = true
		
		local ent = hg.GetCurrentCharacter(owner)
		if IsValid(ent) and not org.otrub and not org.needotrub and (owner:IsPlayer() and owner:Alive() or not owner:IsPlayer()) then
			ent:EmitSound("neckslit.ogg", 70, 100, 1, CHAN_AUTO)
		end
		
		local snd = (ThatPlyIsFemale and ThatPlyIsFemale(owner)) and "femaleneck.mp3" or "maleneck.mp3"
		timer.Simple(0, function()
			if IsValid(owner) then
				if owner:IsPlayer() and owner:Alive() then
					hg.Fake(owner, nil, true, true)
				end
				local rag = hg.GetCurrentCharacter(owner)
				if IsValid(rag) and not org.otrub and not org.needotrub and (owner:IsPlayer() and owner:Alive() or not owner:IsPlayer()) then
					rag:EmitSound(snd, 70, 100, 1, CHAN_VOICE)
					org.neckslitSoundName = snd
					org.neckslitSoundEnt = rag
				end
			end
		end)
	end

	org[artery] = math.min(org[artery] + 1, 1)

	local bonea = owner:LookupBone(boneindex)
	local localPos, localAng, dir2 = getlocalshit(owner, bonea, dmgInfo, dir, hit)
	table.insert(org.arterialwounds, {arterySize[artery], localPos, localAng, boneindex, CurTime(), dir2 * 100, artery})
	owner:SetNetVar("arterialwounds", org.arterialwounds)
	--if IsValid(owner:GetNWEntity("RagdollDeath")) then owner:GetNWEntity("RagdollDeath"):SetNetVar("wounds",org.arterialwounds) end
	return 0
end

input_list.arteria = function(org, bone, dmg, dmgInfo, boneindex, dir, hit)
	return hitArtery("arteria", org, dmg, dmgInfo, "ValveBiped.Bip01_Neck1", dir, hit)
end

input_list.rarmartery = function(org, bone, dmg, dmgInfo, boneindex, dir, hit) return hitArtery("rarmartery", org, dmg, dmgInfo, boneindex, dir, hit) end
input_list.larmartery = function(org, bone, dmg, dmgInfo, boneindex, dir, hit) return hitArtery("larmartery", org, dmg, dmgInfo, boneindex, dir, hit) end
input_list.rlegartery = function(org, bone, dmg, dmgInfo, boneindex, dir, hit) return hitArtery("rlegartery", org, dmg, dmgInfo, boneindex, dir, hit) end
input_list.llegartery = function(org, bone, dmg, dmgInfo, boneindex, dir, hit) return hitArtery("llegartery", org, dmg, dmgInfo, boneindex, dir, hit) end
input_list.spineartery = function(org, bone, dmg, dmgInfo, boneindex, dir, hit) return 0 end--hitArtery("spineartery", org, dmg, dmgInfo, boneindex, dir, hit) end
input_list.lungsL = function(org, bone, dmg, dmgInfo)
	local prot = math.max(0.3 - org.lungsL[1],0)
	local oldval = org.lungsL[1]

	hg.AddHarmToAttacker(dmgInfo, (dmg * 0.25), "Lung left damage harm")

	org.lungsL[1] = math.min(org.lungsL[1] + dmg / 4, 1)
	if (dmgInfo:IsDamageType(DMG_BULLET+DMG_SLASH+DMG_BUCKSHOT)) or (math.random(3) == 1) then org.lungsL[2] = math.min(org.lungsL[2] + dmg * 1, 1) end

	org.internalBleed = org.internalBleed + (org.lungsL[1] - oldval) * 2
	
	dmgInfo:ScaleDamage(0.8)

	return 0//isCrush(dmgInfo) and 1 or prot
end

input_list.lungsR = function(org, bone, dmg, dmgInfo)
	local oldval = org.lungsR[1]

	hg.AddHarmToAttacker(dmgInfo, (dmg * 0.25), "Lung right damage harm")

	org.lungsR[1] = math.min(org.lungsR[1] + dmg / 4, 1)
	if (dmgInfo:IsDamageType(DMG_BULLET+DMG_SLASH+DMG_BUCKSHOT)) or (math.random(3) == 1) then org.lungsR[2] = math.min(org.lungsR[2] + dmg * 1, 1) end

	org.internalBleed = org.internalBleed + (org.lungsR[1] - oldval) * 2

	dmgInfo:ScaleDamage(0.8)

	return 0//isCrush(dmgInfo) and 1 or prot
end

input_list.trachea = function(org, bone, dmg, dmgInfo)
	do return 0 end
	local oldDmg = org.trachea

	if dmgInfo:IsDamageType(DMG_BLAST) then dmg = dmg / 5 end

	local result = damageOrgan(org, dmg * 2, dmgInfo, "trachea")

	hg.AddHarmToAttacker(dmgInfo, (org.trachea - oldDmg) * 8, "Trachea damage harm")

	//org.internalBleed = org.internalBleed + dmg * 2

	return result
end
