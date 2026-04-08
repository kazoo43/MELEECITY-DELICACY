local min, max, Clamp = math.min, math.max, math.Clamp
if hg and hg.despair_server_builtin then return end

local function get_despair_org(ent)
	if not IsValid(ent) then return nil end
	if ent:IsPlayer() then return ent.organism end
	if hg.RagdollOwner then
		local owner = hg.RagdollOwner(ent)
		if IsValid(owner) and owner:IsPlayer() then
			return owner.organism
		end
	end
end

local function is_corpse_ragdoll(ent)
	if not IsValid(ent) or not ent:IsRagdoll() then return false end
	if hg.RagdollOwner then
		local owner = hg.RagdollOwner(ent)
		if IsValid(owner) and owner:Alive() then
			return false
		end
	end
	return true
end

hook.Add("Org Clear", "hg_despair_init", function(org)
	org.despair = 0
	org._despairLastAdrenaline = 0
	org._despairNextCorpseCheck = 0
end)

hook.Add("HomigradDamage", "hg_despair_damage_gain", function(ply, dmgInfo)
	local org = get_despair_org(ply)
	if not org then return end
	if org.otrub then return end

	local dmg = (dmgInfo and dmgInfo.GetDamage and dmgInfo:GetDamage()) or 0
	if dmg <= 0 then return end

	local add = Clamp(dmg / 240, 0.01, 0.12)
	if dmgInfo and dmgInfo.IsDamageType and dmgInfo:IsDamageType(DMG_BULLET + DMG_BUCKSHOT + DMG_BLAST + DMG_BURN + DMG_SLASH + DMG_CLUB) then
		add = add * 1.2
	end

	org.despair = min((org.despair or 0) + add, 1)
end)

hook.Add("Org Think", "hg_despair_think", function(owner, org, timeValue)
	if not IsValid(owner) or not owner:IsPlayer() or not owner:Alive() then return end

	org.despair = Clamp(org.despair or 0, 0, 1)
	org.despair = math.Approach(org.despair, 0, timeValue / 120)

	local add = 0
	local adrenaline = org.adrenaline or 0
	local adrenalineAdd = org.adrenalineAdd or 0
	local prevAdrenaline = org._despairLastAdrenaline or adrenaline
	local adrenalineDelta = max(adrenaline - prevAdrenaline, 0)
	org._despairLastAdrenaline = adrenaline

	if adrenaline > 3 then
		add = add + (adrenaline - 3) * timeValue * 0.045
	end

	if adrenalineAdd > 0.35 then
		add = add + min(adrenalineAdd, 2) * timeValue * 0.03
	end

	if adrenalineDelta > 0 then
		add = add + min(adrenalineDelta * 0.25, 0.08)
	end

	if (org.fear or 0) > 0 then
		add = add + Clamp(org.fear, 0, 2) * timeValue * 0.028
	end

	if (org.pain or 0) > 45 then
		add = add + Clamp((org.pain - 45) / 85, 0, 1) * timeValue * 0.055
	end

	if (org.shock or 0) > 20 then
		add = add + Clamp((org.shock - 20) / 50, 0, 1) * timeValue * 0.04
	end

	if (org.bleed or 0) > 2 then
		add = add + Clamp((org.bleed - 2) / 14, 0, 1) * timeValue * 0.045
	end

	if (org.blood or 5000) < 3200 then
		add = add + Clamp((3200 - org.blood) / 2200, 0, 1) * timeValue * 0.06
	end

	if (org.consciousness or 1) < 0.7 then
		add = add + Clamp((0.7 - org.consciousness) / 0.7, 0, 1) * timeValue * 0.05
	end

	if (org.hungry or 0) > 55 then
		add = add + Clamp((org.hungry - 55) / 45, 0, 1) * timeValue * 0.02
	end

	if org.o2 and org.o2[1] then
		local o2 = org.o2[1]
		if o2 < 14 then
			add = add + Clamp((14 - o2) / 14, 0, 1) * timeValue * 0.17
		end

		local curregen = org.o2.curregen or 0
		local losing = org.losing_oxy or 0
		if curregen < losing then
			add = add + Clamp(losing - curregen, 0, 2) * timeValue * 0.038
		end
	end

	local time = CurTime()
	if (org._despairNextCorpseCheck or 0) <= time then
		org._despairNextCorpseCheck = time + 0.25

		local eyePos = owner:EyePos()
		local aim = owner:GetAimVector()
		local corpsesSeen = 0
		local rag = owner.FakeRagdoll
		local traceFilter = IsValid(rag) and {owner, rag} or owner

		for _, ent in ipairs(ents.FindInCone(eyePos, aim, 1024, math.cos(math.rad(26)))) do
			if ent == owner or ent == rag then continue end
			if not is_corpse_ragdoll(ent) then continue end

			local tr = util.TraceLine({
				start = eyePos,
				endpos = ent:WorldSpaceCenter(),
				filter = traceFilter
			})

			if tr.Entity == ent or not tr.Hit then
				corpsesSeen = corpsesSeen + 1
			end

			if corpsesSeen >= 3 then break end
		end

		if corpsesSeen > 0 then
			add = add + timeValue * 0.12 * corpsesSeen
		end
	end

	if add > 0 then
		org.despair = min(org.despair + add, 1)
	end

	if org.despair >= 0.8 then
		org.disorientation = max(org.disorientation or 0, 1)
	end
end)
