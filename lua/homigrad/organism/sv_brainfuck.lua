local CurTime, IsValid = CurTime, IsValid
local math_min, math_max, math_clamp, math_rand, math_random, math_sin, math_abs, math_approach = math.min, math.max, math.Clamp, math.Rand, math.random, math.sin, math.abs, math.Approach
local VectorRand = VectorRand
local Angle = Angle

local CHANCE, FORCE, VIBRATION = 0.35, 1200, 150
local posturingDur, rigorDur, seizureDur = {5, 10}, {8, 14}, {10, 20}
local RIGOR_DAMP = 8
local INSTANT_KO_WINDOW = 0.35
local INSTANT_KO_COOLDOWN = 2

local spasmTypes = {{"posturing", 65}, {"rigor", 20}, {"seizure", 15}} --;; Че хотите добавляйте изменяйте

local handBones = {5, 7}

local coreBones = {
	"ValveBiped.Bip01_Pelvis", "ValveBiped.Bip01_Spine", "ValveBiped.Bip01_Spine1", "ValveBiped.Bip01_Spine2",
}

local rigorBones = {
	"ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_L_Hand",
	"ValveBiped.Bip01_R_Foot", "ValveBiped.Bip01_L_Foot",
	"ValveBiped.Bip01_R_Forearm", "ValveBiped.Bip01_L_Forearm",
	"ValveBiped.Bip01_R_Calf", "ValveBiped.Bip01_L_Calf",
	"ValveBiped.Bip01_R_UpperArm", "ValveBiped.Bip01_L_UpperArm",
	"ValveBiped.Bip01_R_Thigh", "ValveBiped.Bip01_L_Thigh",
	"ValveBiped.Bip01_Head1", "ValveBiped.Bip01_Spine", "ValveBiped.Bip01_Spine1", "ValveBiped.Bip01_Spine2",
}

local postureBones = {
	"ValveBiped.Bip01_Pelvis", "ValveBiped.Bip01_Spine", "ValveBiped.Bip01_Spine1", "ValveBiped.Bip01_Spine2",
	"ValveBiped.Bip01_Head1",
	"ValveBiped.Bip01_R_UpperArm", "ValveBiped.Bip01_L_UpperArm",
	"ValveBiped.Bip01_R_Forearm", "ValveBiped.Bip01_L_Forearm",
	"ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_L_Hand",
	"ValveBiped.Bip01_R_Thigh", "ValveBiped.Bip01_L_Thigh",
	"ValveBiped.Bip01_R_Calf", "ValveBiped.Bip01_L_Calf",
	"ValveBiped.Bip01_R_Foot", "ValveBiped.Bip01_L_Foot",
}

local straightBonesAll = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14}
local straightBonesLegs = {0, 1, 8, 9, 10, 11, 12, 13, 14}
local shadowControl = hg.ShadowControl
local vector_zero = Vector(0, 0, 0)
local vector_up = Vector(0, 0, 1)



local fencingArmBones = {
	{"ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_R_UpperArm", 1.0},     
	{"ValveBiped.Bip01_L_Hand", "ValveBiped.Bip01_L_UpperArm", 1.0},
	{"ValveBiped.Bip01_R_Forearm", "ValveBiped.Bip01_Spine2", 0.8},       
	{"ValveBiped.Bip01_L_Forearm", "ValveBiped.Bip01_Spine2", 0.8},
	{"ValveBiped.Bip01_R_UpperArm", "ValveBiped.Bip01_Spine2", 0.5},      
	{"ValveBiped.Bip01_L_UpperArm", "ValveBiped.Bip01_Spine2", 0.5},
}
local fencingLegBones = {
	{"ValveBiped.Bip01_R_Foot", "ValveBiped.Bip01_R_Thigh", 0.6},         
	{"ValveBiped.Bip01_R_Calf", "ValveBiped.Bip01_R_Thigh", 0.4},         
}

local function getRandomSpasm()
	local total = 0
	for i = 1, #spasmTypes do total = total + spasmTypes[i][2] end
	local roll, cur = math_random(1, total), 0
	for i = 1, #spasmTypes do
		cur = cur + spasmTypes[i][2]
		if roll <= cur then return spasmTypes[i][1] end
	end
	return "posturing"
end

hg.getRandomSpasm = getRandomSpasm

local function getBrainFactor(org)
	local brain = org and org.brain or 0
	local skull = org and org.skull or 0
	return math_clamp((brain * 1.2) + (skull * 0.9), 0, 1)
end

local function applySpasm(rag, stype, useFencing)
	if not IsValid(rag) then return end
	local dur = stype == "posturing" and posturingDur or stype == "seizure" and seizureDur or rigorDur
	dur = math_rand(dur[1], dur[2])
	local org = rag.organism
	local brainFactor = getBrainFactor(org)
	rag.spasmStiffness = brainFactor
	rag.spasmWear = 0
	dur = dur * (1 + brainFactor * 0.4)
	if stype == "posturing" or stype == "seizure" then
		rag.spasmBreathAt = CurTime() + math_rand(2, 3)
		rag.spasmBreathPlayed = false
	end
	
	rag.spasm, rag.spasmType, rag.spasmDur, rag.spasmForce = true, stype, dur, FORCE
	rag.spasmEnd, rag.spasmStart = CurTime() + dur, CurTime()
	rag.spasmFencing = useFencing and true or nil
	
	if stype == "rigor" then
		rag.rigorActive = true
	end
	--rag:EmitSound("physics/body/body_medium_break" .. math_random(2, 4) .. ".wav", 60, math_random(70, 90), 0.4)
end

hg.applySpasm = applySpasm

local function applyCoreDamping(rag)
	for i = 1, #coreBones do
		local bone = rag:LookupBone(coreBones[i])
		if not bone then continue end
		local phys = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(bone))
		if IsValid(phys) then phys:SetDamping(0.5, 12) end
	end
end

local function getSpasmScale(rag)
	local wear = rag.spasmWear or 0
	local elapsed = CurTime() - (rag.spasmStart or CurTime())
	local dur = rag.spasmDur or 1
	local timeScale = math_clamp(1 - (elapsed / dur) * 0.7, 0.25, 1)
	local wearScale = math_clamp(1 - wear, 0.25, 1)
	return math_clamp(timeScale * wearScale, 0.2, 1)
end

local function getStiffnessScale(rag)
	local base = math_clamp(rag.spasmStiffness or 0, 0.15, 1)
	local pos = rag:GetPos()
	local tr = {}
	tr.start = pos
	tr.endpos = pos - vector_up * 20
	tr.filter = rag
	local hit = util.TraceLine(tr).Hit
	local airScale = hit and 1 or 0.35
	return math_clamp(base * airScale, 0.08, 1)
end

local function applySpasmDamage(rag, dmg, isHead)
	if not IsValid(rag) or not rag.spasm then return end
	local inc = math_clamp((dmg or 0) * 0.003, 0.01, 0.08)
	rag.spasmWear = math_clamp((rag.spasmWear or 0) + inc, 0, 0.9)
	local shorten = math_clamp((dmg or 0) * 0.04, 0.1, 1.2)
	if rag.spasmEnd then
		rag.spasmEnd = math_max(rag.spasmEnd - shorten, CurTime() + 0.2)
	end
	if rag.spasmStart and rag.spasmEnd then
		rag.spasmDur = math_max(rag.spasmEnd - rag.spasmStart, 0.2)
	end
end

local function applyFingerCurl(rag, blend)
	local ang = Angle(0, -55 * blend, 0)
	for i = 1, 4 do
		local lbone = rag:LookupBone("ValveBiped.Bip01_L_Finger" .. tostring(i) .. "1")
		if lbone then rag:ManipulateBoneAngles(lbone, ang) end
		local rbone = rag:LookupBone("ValveBiped.Bip01_R_Finger" .. tostring(i) .. "1")
		if rbone then rag:ManipulateBoneAngles(rbone, ang) end
	end
end

local function updateFingerCurl(rag, target, dt)
	local cur = rag.spasmFingerBlend or 0
	local next = math_approach(cur, target, (dt or 0.02) * 6)
	rag.spasmFingerBlend = next
	applyFingerCurl(rag, next)
end

local function processSeizure(rag, fade)
	applyCoreDamping(rag)
	local scale = getSpasmScale(rag)
	local stiff = getStiffnessScale(rag)
	local force = 350 * scale * stiff * fade
	
	for i = 0, rag:GetPhysicsObjectCount() - 1 do
		local phys = rag:GetPhysicsObjectNum(i)
		if IsValid(phys) then
			phys:ApplyForceCenter(VectorRand(-1, 1) * force)
			phys:SetDamping(0.5, 4)
		end
	end
	
	applyFingerCurl(rag, math_sin(CurTime() * 15) * 0.5 + 0.5)
end

local function processPosturing(rag, fade)
	if not IsValid(rag) or not rag.organism then return end
	local spine2 = rag:LookupBone("ValveBiped.Bip01_Spine2")
	if not spine2 then return end
	local phys = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(spine2))
	if not IsValid(phys) then return end
	local ang = phys:GetAngles()
	ang:Add(AngleRand(-5, 5))
	ang:RotateAroundAxis(ang:Up(), 180)
	local mul = 1000 * rag.organism.pulse / 70
	local damp = 50
	local ss = 0.001
	shadowControl(rag, 3, ss, ang, mul, damp, vector_zero, 0, 0)
	shadowControl(rag, 4, ss, ang, mul, damp, vector_zero, 0, 0)
	shadowControl(rag, 5, ss, ang, mul, damp, vector_zero, 0, 0)
	shadowControl(rag, 2, ss, ang, mul, damp, vector_zero, 0, 0)
	if not rag.spasmFencing then
		shadowControl(rag, 6, ss, ang, mul, damp, vector_zero, 0, 0)
		shadowControl(rag, 7, ss, ang, mul, damp, vector_zero, 0, 0)
	end
	shadowControl(rag, 8, ss, ang, mul, damp, vector_zero, 0, 0)
	shadowControl(rag, 9, ss, ang, mul, damp, vector_zero, 0, 0)
	shadowControl(rag, 11, ss, ang, mul, damp, vector_zero, 0, 0)
	shadowControl(rag, 12, ss, ang, mul, damp, vector_zero, 0, 0)
end

local function processRigor(rag, fade)
	if not rag.rigorActive then return end
	local scale = getSpasmScale(rag)
	local stiff = getStiffnessScale(rag)
	local damp = RIGOR_DAMP * fade + 0.5
	
	for i = 1, #rigorBones do
		local bone = rag:LookupBone(rigorBones[i])
		if not bone then continue end
		local phys = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(bone))
		if not IsValid(phys) then continue end
		--phys:SetDamping(damp, damp * 2)
		if fade > 0.3 then phys:ApplyForceCenter(VectorRand(-45, 45) * fade * scale * stiff) end
	end
end

--;; when furfag
local function applyFencingToPlayer(ply, org)
	if not IsValid(ply) or not ply:Alive() then return end
	if org.fencing and org.fencingEnd and CurTime() < org.fencingEnd then
		local extra = math_rand(2.5, 4.5)
		org.fencingEnd = org.fencingEnd + extra
		org.fencingDur = (org.fencingDur or 0) + extra
		if ply.FakeRagdoll and IsValid(ply.FakeRagdoll) then
			local rag = ply.FakeRagdoll
			rag.fencing = true
			rag.fencingEnd = org.fencingEnd
			rag.fencingDur = org.fencingDur
		end
		return
	end
	
	local dur = math_rand(6, 12) 
	org.fencing = true
	org.fencingEnd = CurTime() + dur
	org.fencingDur = dur
	

	if ply.FakeRagdoll and IsValid(ply.FakeRagdoll) then
		local rag = ply.FakeRagdoll
		rag.fencing = true
		rag.fencingEnd = org.fencingEnd
		rag.fencingDur = dur
	end
end

hg.applyFencingToPlayer = applyFencingToPlayer

local function processFencing(rag, fade)
	local org = rag.organism
	local ct = CurTime()
	rag.fencingPhase = rag.fencingPhase or math_rand(0, 6.28)
	local phase = rag.fencingPhase
	local osc = math_sin(ct * 7 + phase) * 0.35 + math_sin(ct * 13 + phase * 0.65) * 0.2
	local pulse = 0.8 + osc
	local force = (280 + 200 * math_abs(osc)) * fade
	local jitterMul = (0.35 + math_abs(math_sin(ct * 9 + phase)) * 0.75) * fade

	if org.spine2 < hg.organism.fake_spine2 and org.spine3 < hg.organism.fake_spine3 then
		for i = 1, #fencingArmBones do
			local d = fencingArmBones[i]
			local bone, targetBone = rag:LookupBone(d[1]), rag:LookupBone(d[2])
			if not bone or not targetBone then continue end
			local phys = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(bone))
			if not IsValid(phys) then continue end
			local bonePos, targetPos = rag:GetBonePosition(bone), rag:GetBonePosition(targetBone)
			local dir = (targetPos - bonePos):GetNormalized()
			phys:ApplyForceCenter((dir * force * d[3] * pulse) + VectorRand(-18, 18) * jitterMul)
		end
	end
	
	if org.spine2 < hg.organism.fake_spine2 and org.spine3 < hg.organism.fake_spine3 and org.spine1 < hg.organism.fake_spine1 then
		for i = 1, #fencingLegBones do
			local d = fencingLegBones[i]
			local bone, targetBone = rag:LookupBone(d[1]), rag:LookupBone(d[2])
			if not bone or not targetBone then continue end
			local phys = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(bone))
			if not IsValid(phys) then continue end
			local bonePos, targetPos = rag:GetBonePosition(bone), rag:GetBonePosition(targetBone)
			local dir = (targetPos - bonePos):GetNormalized()
			phys:ApplyForceCenter((dir * force * d[3] * pulse) + VectorRand(-12, 12) * (jitterMul * 0.8 + 0.1))
		end
	end
end

local function clearFencing(rag)
	rag.fencing, rag.fencingEnd, rag.fencingDur, rag.fencingPhase = nil, nil, nil, nil
end

local function clearSpasm(rag)
	if rag.spasmType == "rigor" and rag.rigorActive then
		for i = 1, #rigorBones do
			local bone = rag:LookupBone(rigorBones[i])
			if not bone then continue end
			local phys = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(bone))
			if IsValid(phys) then phys:SetDamping(0.5, 1) end
		end
	end
	for i = 1, #postureBones do
		local bone = rag:LookupBone(postureBones[i])
		if not bone then continue end
		local phys = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(bone))
		if IsValid(phys) then phys:SetDamping(0.5, 1) end
	end
	applyFingerCurl(rag, 0)
	rag.spasm, rag.spasmEnd, rag.spasmStart, rag.spasmDur, rag.spasmForce, rag.spasmType, rag.rigorActive, rag.spasmStiffness, rag.spasmFingerBlend, rag.spasmWear, rag.spasmBreathAt, rag.spasmBreathPlayed, rag.spasmFencing = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
end

hook.Add("Should Fake Up", "BrainfuckFencing", function(ply)
	local org = ply.organism
	if org and org.fencing and org.fencingEnd and CurTime() < org.fencingEnd then
		return false
	end
	local rag = ply.FakeRagdoll
	if IsValid(rag) and rag.fencing and rag.fencingEnd and CurTime() < rag.fencingEnd then
		return false
	end
end)

hook.Add("RagdollDeath", "BrainfuckStart", function(ply, rag)
	timer.Simple(0.1, function()
		if not IsValid(ply) or not IsValid(rag) then return end
		local org = ply.organism
		if not org then return end
		
		local hadBrainDamage = org.brain and org.brain > 0
		local hadSkullDamage = org.skull and org.skull > 0
		local hadHeadDamage = org.dmgstack and org.dmgstack[HITGROUP_HEAD] and (org.dmgstack[HITGROUP_HEAD][1] or 0) > 0
		local recentHeadshot = org.lastHeadshot and (CurTime() - org.lastHeadshot) < 1.5
		local recentClubHit = org.lastClubHit and (CurTime() - org.lastClubHit) < 1.5
		local recentBulletHit = org.lastBulletHit and (CurTime() - org.lastBulletHit) < 1.5
		local forceFencingPosturing = recentClubHit or recentBulletHit
		local headshot = hadBrainDamage or hadSkullDamage or hadHeadDamage or recentHeadshot
		local brainFactor = getBrainFactor(org)
		local chance = math_clamp(CHANCE + brainFactor * 0.6, 0, 1)
		if not headshot and not forceFencingPosturing and (rag.noHead or org.noHead or ply.noHead) then return end
		
		if (headshot and (recentHeadshot or hadHeadDamage or math_random() < chance)) or forceFencingPosturing then
			local stype = forceFencingPosturing and "posturing" or getRandomSpasm()
			applySpasm(rag, stype, forceFencingPosturing)
			if rag.organism then rag.organism.spasm, rag.organism.spasmType = true, stype end
		end
	end)
end)

hook.Add("HG_OnOtrub", "BrainfuckInstantKoFencingPosturing", function(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	local org = ply.organism
	if not org then return end
	if not org.lasthit or (CurTime() - org.lasthit) > INSTANT_KO_WINDOW then return end
	if org.lastInstantKoBrainfuck and CurTime() < org.lastInstantKoBrainfuck + INSTANT_KO_COOLDOWN then return end
	org.lastInstantKoBrainfuck = CurTime()
	applyFencingToPlayer(ply, org)
	timer.Simple(0.05, function()
		if not IsValid(ply) then return end
		local rag = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or (hg.GetCurrentCharacter and hg.GetCurrentCharacter(ply))
		if not IsValid(rag) or not rag:IsRagdoll() then return end
		applySpasm(rag, "posturing", true)
		if rag.organism then rag.organism.spasm, rag.organism.spasmType = true, "posturing" end
	end)
end)

hook.Add("Org Think", "BrainfuckThink", function(owner, org, timeValue)
	if not IsValid(owner) then return end
	local org = org or owner.organism or owner
	
	if org.fencing and org.fencingEnd then
		local rag = owner.FakeRagdoll
		if IsValid(rag) then
			if CurTime() > org.fencingEnd then
				clearFencing(rag)
				org.fencing, org.fencingEnd, org.fencingDur = nil, nil, nil
			else
				local fade = math_clamp((org.fencingEnd - CurTime()) / (org.fencingDur or 5), 0.1, 1)
				processFencing(rag, fade)
			end
		end
	end
	
	local deathRag = owner.FakeRagdoll
	if not IsValid(deathRag) and owner:IsRagdoll() then
		deathRag = owner
	end
	if IsValid(deathRag) and deathRag.spasm and deathRag.spasmEnd then
		if CurTime() > deathRag.spasmEnd then
			clearSpasm(deathRag)
		else
			local fade = math_clamp((deathRag.spasmEnd - CurTime()) / (deathRag.spasmDur or 5), 0.1, 1)
			local fadeIn = math_clamp((CurTime() - (deathRag.spasmStart or CurTime())) / 4, 0, 1)
			local stype = deathRag.spasmType or "posturing"
			if stype == "posturing" then
				local slowFadeIn = math_clamp((CurTime() - (deathRag.spasmStart or CurTime())) / 7, 0, 1)
				fade = fade * slowFadeIn * slowFadeIn
			elseif stype == "seizure" then
				fade = fade * fadeIn
			end
			if (stype == "posturing" or stype == "seizure") and deathRag.spasmBreathAt and not deathRag.spasmBreathPlayed and CurTime() >= deathRag.spasmBreathAt then
				deathRag.spasmBreathPlayed = true
				if not (deathRag.noHead or (org and org.noHead) or (owner and owner.noHead)) and math_random() > 0.5 then
					local isAlive = true
					if IsValid(owner) and owner:IsPlayer() and not owner:Alive() then
						isAlive = false
					end
					
					if isAlive then
						local head = deathRag:LookupBone("ValveBiped.Bip01_Head1")
						local pos = head and deathRag:GetBonePosition(head) or deathRag:GetPos()
						local pitch = math_random(95, 110)
						local snd = (ThatPlyIsFemale and ThatPlyIsFemale(deathRag)) and "femalegroan.mp3" or "malegroan.mp3"
						sound.Play(snd, pos, 80, pitch, 1)
					end
				end
			end

			if stype == "posturing" then
				if deathRag.spasmFencing then processFencing(deathRag, fade) end
				processPosturing(deathRag, fade)
			elseif stype == "seizure" then processSeizure(deathRag, fade)
			elseif stype == "rigor" then processRigor(deathRag, fade)
			end
			local target = (stype == "posturing") and 1 or 0
			if stype == "seizure" then target = 0 end -- seizure handles its own finger curling
			if stype ~= "seizure" then updateFingerCurl(deathRag, target, timeValue) end
		end
	end
end)

hook.Add("Org Clear", "BrainfuckClear", function(org)
	if not org or not org.owner then return end
	if IsValid(org.owner) then 
		clearSpasm(org.owner)
		clearFencing(org.owner)
	end
	org.fencing, org.fencingEnd = nil, nil
end)

hook.Add("HomigradDamage", "BrainfuckHeadshotMark", function(ply, dmgInfo, hitgroup)
	if not IsValid(ply) then return end
	local org = ply.organism
	if org and dmgInfo and dmgInfo.IsDamageType and dmgInfo:IsDamageType(DMG_CLUB) then
		org.lastClubHit = CurTime()
	end
	if org and dmgInfo and dmgInfo.IsDamageType and dmgInfo:IsDamageType(DMG_BULLET) then
		org.lastBulletHit = CurTime()
	end
	if hitgroup == HITGROUP_HEAD then
		if org then
			org.lastHeadshot = CurTime()
		end
		local rag = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply:GetNWEntity("RagdollDeath")
		if not IsValid(rag) and ply:IsRagdoll() then
			rag = ply
		end
		if IsValid(rag) and rag.spasm then
			local dmg = dmgInfo and dmgInfo.GetDamage and dmgInfo:GetDamage() or 0
			applySpasmDamage(rag, dmg, true)
		end
	end
end)

hook.Add("EntityTakeDamage", "BrainfuckRagdollDamage", function(ent, dmgInfo)
	if not IsValid(ent) or not ent:IsRagdoll() then return end
	if not ent.spasm then return end
	local dmg = dmgInfo and dmgInfo.GetDamage and dmgInfo:GetDamage() or 0
	if dmg <= 0 then return end
	local head = ent:LookupBone("ValveBiped.Bip01_Head1")
	if not head then
		applySpasmDamage(ent, dmg, false)
		return
	end
	local headPos = ent:GetBonePosition(head)
	local pos = dmgInfo and dmgInfo.GetDamagePosition and dmgInfo:GetDamagePosition() or ent:GetPos()
	local isHead = headPos and pos and pos:DistToSqr(headPos) <= 324
	applySpasmDamage(ent, dmg, isHead)
end)
