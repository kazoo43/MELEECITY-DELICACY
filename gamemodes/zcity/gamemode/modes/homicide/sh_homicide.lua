local MODE = MODE
MODE.name = "hmcd"
MODE.PrintName = "Homicide"

--\\
MODE.TraitorExpectedAmtBits = 13
--//

--\\Sub Roles
MODE.ConVarName_SubRole_Traitor_SOE = "hmcd_subrole_traitor_soe"
MODE.ConVarName_SubRole_Traitor = "hmcd_subrole_traitor"

if(CLIENT)then
	MODE.ConVar_SubRole_Traitor_SOE = CreateClientConVar(MODE.ConVarName_SubRole_Traitor_SOE, "traitor_default_soe", true, true, "Выбор роли трейтора в режиме SOE хомисайда")
	MODE.ConVar_SubRole_Traitor = CreateClientConVar(MODE.ConVarName_SubRole_Traitor, "traitor_default", true, true, "Выбор роли трейтора в стандартном режиме хомисайда")
	CreateClientConVar("hmcd_traitor_loadout", "", true, true, "Traitor loadout data")

	hook.Add("Initialize", "HMCD_InitLoadout", function()
		local savedData = file.Read("meleecity_traitor_loadout.txt", "DATA")
		if savedData then
			local cv = GetConVar("hmcd_traitor_loadout")
			if cv then cv:SetString(savedData) end
		end
	end)
end

local TraitorItems = {
	["weapon_zoraki"] = 5,
	["weapon_buck200knife"] = 3,
	["weapon_sogknife"] = 3,
	["weapon_fiberwire"] = 3,
	["weapon_hg_rgd_tpik"] = 6,
	["weapon_adrenaline"] = 4,
	["weapon_hg_shuriken"] = 2,
	["weapon_hg_smokenade_tpik"] = 3,
	["weapon_traitor_ied"] = 6,
	["weapon_traitor_poison1"] = 3,
	["weapon_traitor_poison2"] = 4,
	["weapon_traitor_poison3"] = 5,
	["weapon_traitor_poison4"] = 3,
	["weapon_traitor_suit"] = 8,
	["weapon_hg_jam"] = 3,
	["weapon_p22"] = 8,
	["weapon_walkie_talkie"] = 2,
	["weapon_taser"] = 8,
}
local TraitorAddons = {
	["weapon_p22_extra_mag"] = {cost = 2, parent = "weapon_p22"},
	["weapon_p22_silencer"] = {cost = 2, parent = "weapon_p22"},
}

local Skillsets = {
	["infiltrator"] = {cost = 10, name = "Infiltrator", desc = "Can break necks, disguise as ragdolls. Max 220 stamina."},
	["assassin"] = {cost = 12, name = "Assassin", desc = "Disarm people quickly, proficient in shooting, +80 stamina."},
	["chemist"] = {cost = 8, name = "Chemist", desc = "Resistant to chemicals, detects chemical agents in air."},
	["none"] = {cost = 0, name = "None", desc = "No special skillset."}
}

local maxLoadoutPoints = 30
local WeaponExclusions = {
	["weapon_buck200knife"] = {
		["weapon_sogknife"] = true
	},
	["weapon_sogknife"] = {
		["weapon_buck200knife"] = true
	},
	["weapon_p22"] = {
		["weapon_taser"] = true
	},
	["weapon_taser"] = {
		["weapon_p22"] = true
	}
}

local function HasWeaponConflict(selectedWeapons, weaponId)
	local exclusions = WeaponExclusions[weaponId]
	if exclusions then
		for _, selectedId in ipairs(selectedWeapons) do
			if selectedId ~= weaponId and exclusions[selectedId] then
				return true
			end
		end
	end

	for _, selectedId in ipairs(selectedWeapons) do
		if selectedId ~= weaponId then
			local selectedExclusions = WeaponExclusions[selectedId]
			if selectedExclusions and selectedExclusions[weaponId] then
				return true
			end
		end
	end

	return false
end

local function GetRandomizedWeaponIds()
	local ids = {}
	for id in pairs(TraitorItems) do
		table.insert(ids, id)
	end
	for i = #ids, 2, -1 do
		local j = math.random(i)
		ids[i], ids[j] = ids[j], ids[i]
	end
	return ids
end

local function GetPreferredKnifeId()
	if TraitorItems["weapon_buck200knife"] then
		return "weapon_buck200knife"
	end
	if TraitorItems["weapon_sogknife"] then
		return "weapon_sogknife"
	end
	return nil
end

local function BuildRandomLoadout()
	local bestLoadout = {weapons = {}, skillset = "none"}
	local bestPoints = 0
	local skillsetIds = {}
	local knifeId = GetPreferredKnifeId()
	for id in pairs(Skillsets) do
		table.insert(skillsetIds, id)
	end

	for _ = 1, 96 do
		local candidate = {weapons = {}, skillset = "none"}
		local candidatePoints = 0

		if #skillsetIds > 0 then
			local randomSkillset = skillsetIds[math.random(#skillsetIds)]
			candidate.skillset = randomSkillset
			candidatePoints = Skillsets[randomSkillset].cost
		end

		if knifeId and candidatePoints + TraitorItems[knifeId] <= maxLoadoutPoints then
			table.insert(candidate.weapons, knifeId)
			candidatePoints = candidatePoints + TraitorItems[knifeId]
		end

		for _, weaponId in ipairs(GetRandomizedWeaponIds()) do
			if weaponId ~= knifeId then
			local weaponCost = TraitorItems[weaponId]
			if candidatePoints + weaponCost <= maxLoadoutPoints and math.random() < 0.7 and not HasWeaponConflict(candidate.weapons, weaponId) then
				table.insert(candidate.weapons, weaponId)
				candidatePoints = candidatePoints + weaponCost
			end
			end
		end

		if candidatePoints > bestPoints then
			bestPoints = candidatePoints
			bestLoadout = candidate
			if bestPoints == maxLoadoutPoints then
				break
			end
		end
	end

	if bestPoints <= 0 then
		local fallbackWeaponId = knifeId
		if not fallbackWeaponId then
			local fallbackWeapons = GetRandomizedWeaponIds()
			if #fallbackWeapons > 0 then
				fallbackWeaponId = fallbackWeapons[1]
			end
		end
		if fallbackWeaponId then
			bestLoadout.weapons = {fallbackWeaponId}
			bestLoadout.skillset = "none"
		end
	end

	return bestLoadout
end

local function SanitizeLoadout(rawLoadout, fillRandomIfEmpty)
	local normalizedLoadout = {weapons = {}, skillset = "none"}
	if type(rawLoadout) ~= "table" then
		rawLoadout = {}
	end

	if type(rawLoadout.skillset) == "string" and Skillsets[rawLoadout.skillset] then
		normalizedLoadout.skillset = rawLoadout.skillset
	end

	local points = Skillsets[normalizedLoadout.skillset].cost
	local usedWeapons = {}
	local rawWeaponIds = {}
	if type(rawLoadout.weapons) == "table" then
		for k, v in pairs(rawLoadout.weapons) do
			local weaponId
			if type(v) == "string" then
				weaponId = v
			elseif type(k) == "string" and v == true then
				weaponId = k
			end

			if weaponId and not usedWeapons[weaponId] and (TraitorItems[weaponId] or TraitorAddons[weaponId]) then
				usedWeapons[weaponId] = true
				table.insert(rawWeaponIds, weaponId)
			end
		end
	end

	usedWeapons = {}
	for _, weaponId in ipairs(rawWeaponIds) do
		local weaponCost = TraitorItems[weaponId]
		if weaponCost and not usedWeapons[weaponId] and not HasWeaponConflict(normalizedLoadout.weapons, weaponId) then
			if points + weaponCost <= maxLoadoutPoints then
				usedWeapons[weaponId] = true
				table.insert(normalizedLoadout.weapons, weaponId)
				points = points + weaponCost
			end
		end
	end

	for _, weaponId in ipairs(rawWeaponIds) do
		local addonInfo = TraitorAddons[weaponId]
		if addonInfo and not usedWeapons[weaponId] and usedWeapons[addonInfo.parent] then
			local weaponCost = addonInfo.cost
			if points + weaponCost <= maxLoadoutPoints then
				usedWeapons[weaponId] = true
				table.insert(normalizedLoadout.weapons, weaponId)
				points = points + weaponCost
			end
		end
	end

	if fillRandomIfEmpty and normalizedLoadout.skillset == "none" and #normalizedLoadout.weapons == 0 then
		normalizedLoadout = BuildRandomLoadout()
	end

	return normalizedLoadout
end

local function ApplyLoadout(ply)
	local loadoutStr = ply:GetInfo("hmcd_traitor_loadout")
	local data = {}
	if loadoutStr and loadoutStr ~= "" then
		data = util.JSONToTable(loadoutStr) or {}
	end

	local normalizedLoadout = SanitizeLoadout(data, true)
	local weapons = normalizedLoadout.weapons
	local skillset = normalizedLoadout.skillset
	local hasP22ExtraMag = table.HasValue(weapons, "weapon_p22_extra_mag")
	local hasP22Silencer = table.HasValue(weapons, "weapon_p22_silencer")
	local p22Weapon

	for _, wep in pairs(weapons) do
		if not TraitorAddons[wep] then
			local wepent = ply:Give(wep)
			if wep == "weapon_p22" and IsValid(wepent) then
				p22Weapon = wepent
			elseif wep == "weapon_zoraki" and IsValid(wepent) then
				timer.Simple(1, function() if IsValid(wepent) then wepent:ApplyAmmoChanges(2) end end)
			elseif wep == "weapon_taser" and IsValid(wepent) then
				ply:GiveAmmo(wepent:GetMaxClip1() * 3, wepent:GetPrimaryAmmoType(), true)
			end
		end
	end

	if hasP22ExtraMag or hasP22Silencer then
		local function applyP22Addons(wep)
			if not IsValid(wep) then return end
			if hasP22ExtraMag then
				ply:GiveAmmo(wep:GetMaxClip1(), wep:GetPrimaryAmmoType(), true)
			end
			if hasP22Silencer then
				hg.AddAttachmentForce(ply, wep, "supressor4")
			end
		end

		applyP22Addons(p22Weapon)

		if hasP22Silencer or not IsValid(p22Weapon) then
			timer.Simple(0, function()
				if not IsValid(ply) then return end
				applyP22Addons(ply:GetWeapon("weapon_p22"))
			end)
		end
	end

	local inv = ply:GetNetVar("Inventory", {})
	inv["Weapons"] = inv["Weapons"] or {}
	inv["Weapons"]["hg_flashlight"] = true

	if skillset == "infiltrator" then
		ply.organism.stamina.max = 220
		ply.SubRole = "traitor_infiltrator"
	elseif skillset == "assassin" then
		ply.organism.recoilmul = 0.4
		ply.organism.stamina.max = 300
		ply.SubRole = "traitor_assasin"
	elseif skillset == "chemist" then
		ply.organism.stamina.max = 220
		ply.SubRole = "traitor_chemist"
	else
		ply.organism.stamina.max = 220
		ply.SubRole = "traitor_default"
	end

	net.Start("HMCD(SetSubRole)")
	net.WriteString(ply.SubRole)
	net.Send(ply)

	ply:SetNetVar("Inventory", inv)
end

MODE.SubRoles = {
	["traitor_default"] = {
		Name = "Legacy",
		Description = "Custom Loadout. You are equipped with whatever you bought.",
		Objective = "You're geared up. Murder everyone here.",
		SpawnFunction = function(ply)
			ApplyLoadout(ply)
		end,
	},
	["traitor_default_soe"] = {
		Name = "Legacy",
		Description = "Custom Loadout. You are equipped with whatever you bought.",
		Objective = "You're geared up. Murder everyone here.",
		SpawnFunction = function(ply)
			ApplyLoadout(ply)
		end,
	},
	--==//
	
	--==\\
	["traitor_infiltrator"] = {
		Name = "Infiltrator",
		Description = [[Can break people's necks from behind.
Can completely disguise as other players if they're in ragdoll.
Has no weapons or tools except knife, epipen and smoke grenade.
For people who like to play chess.]],
		Objective = "You're an expert in diversion. Be discreet and kill one by one",
		SpawnFunction = function(ply)
			ply:Give("weapon_sogknife")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_hg_smokenade_tpik")
			
			ply.organism.stamina.max = 220
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_flashlight"] = true
			
			ply:SetNetVar("Inventory", inv)
		end,
	},
	["traitor_infiltrator_soe"] = {
		Name = "Infiltrator",
		Description = [[Can break people's necks from behind.
Can completely disguise as other players if they're in ragdoll.
Has smoke grenade, walkie-talkie, knife, taser with 2 additional shooting heads and epipen.
For people who like to play chess.]],
		Objective = "You're an expert in diversion. Be discreet and kill one by one",
		SpawnFunction = function(ply)
			local taser = ply:Give("weapon_taser")
			
			ply:GiveAmmo(taser:GetMaxClip1() * 2, taser:GetPrimaryAmmoType(), true)
			ply:Give("weapon_sogknife")
			-- ply:Give("weapon_hg_rgd_tpik")
			-- ply:Give("weapon_walkie_talkie")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_hg_smokenade_tpik")
			
			ply.organism.recoilmul = 1
			ply.organism.stamina.max = 220
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_flashlight"] = true
			
			ply:SetNetVar("Inventory", inv)
		end,
	},
	--==//
	
	--==\\
	--; СДЕЛАТЬ ЕМУ ЛУТ ДРУГИХ ИГРОКОВ ДАЖЕ ПОКА У НИХ НЕТ ПУШКИ В РУКАХ
	--; Сделать ему вырубание по вагус нерву
	["traitor_assasin"] = {
		Name = "Assasin",
		Description = [[Can quickly disarm people from any angle.
Disarms faster from behind.
Disarms faster from front if the victim is in ragdoll.
Proficient in shooting from guns.
Has additional stamina (+ 80 units compared to other traitors).
Equipped with walkie-talkie.
For people who like to play checkers.]],
		Objective = "You're an expert in guns and in disarmament. Disarm gunman and use his weapon against others",
		SpawnFunction = function(ply)
			-- ply:Give("weapon_sogknife")	
			-- ply:Give("weapon_adrenaline")
			-- ply:Give("weapon_hg_smokenade_tpik")
			-- ply:Give("weapon_hg_shuriken")
			
			ply.organism.recoilmul = 0.8
			ply.organism.stamina.max = 300
			-- local inv = ply:GetNetVar("Inventory", {})
			-- inv["Weapons"]["hg_flashlight"] = true
			
			ply:SetNetVar("Inventory", inv)
		end,
	},
	["traitor_assasin_soe"] = {
		Name = "Assasin",
		Description = [[Can quickly disarm people from any angle.
Disarms faster from behind.
Disarms faster from front if the victim is in ragdoll.
Proficient in shooting from guns.
Has additional stamina (+ 80 units compared to other traitors).
Equipped with walkie-talkie, knife, epipen and flashlight.
For people who like to play checkers.]],
		Objective = "You're an expert in guns and in disarmament. Disarm gunman and use his weapon against others",
		SpawnFunction = function(ply)
			ply:Give("weapon_sogknife")	
			ply:Give("weapon_adrenaline")
			-- ply:Give("weapon_walkie_talkie")
			-- ply:Give("weapon_hg_smokenade_tpik")
			-- ply:Give("weapon_hg_shuriken")
			
			ply.organism.recoilmul = 0.4
			ply.organism.stamina.max = 300
			--local inv = ply:GetNetVar("Inventory", {})
			--inv["Weapons"]["hg_flashlight"] = true
			
			ply:SetNetVar("Inventory", inv)
		end,
	},
	--==//
	
	--==\\
	["traitor_chemist"] = {
		Name = "Chemist",
		Description = [[Has multiple chemical agents and epipen and knife.
Resistant to a certain degree to all chemical agents mentioned.
Can detect presence and potency of chemical agents in the air.]],
		Objective = "You're a chemist who decided to use his knowledge to hurt others. Poison everything.",
		SpawnFunction = function(ply)
			ply:Give("weapon_sogknife")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_traitor_poison1")
			ply:Give("weapon_traitor_poison2")
			ply:Give("weapon_traitor_poison3")
			ply:Give("weapon_traitor_poison4")
			ply:Give("weapon_traitor_poison_consumable")
			
			ply.organism.stamina.max = 220
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_flashlight"] = true
			
			ply:SetNetVar("Inventory", inv)
			MODE.CleanChemicalsOfPlayer(ply)
		end,
	},
	--==//
	-- ["traitor_demoman"] = {
		-- Name = "Demoman",
		-- Description = [[Has many explosives.
-- Can rig certain items with bombs
-- (Radio, certain consumables, etc.)]],
		-- Objective = "You're the ultimate chemist who decided to use knowledge to hurt others.",
		-- SpawnFunction = function(ply)
			-- ply:Give("weapon_sogknife")
			-- ply:Give("weapon_adrenaline")
			-- ply:Give("weapon_hg_rgd_tpik")
			-- ply:Give("weapon_hg_pipebomb_tpik")
			-- ply:Give("weapon_hg_smokenade_tpik")
			-- ply:Give("weapon_traitor_ied")
			-- ply:Give("weapon_walkie_talkie")
			
			-- ply.organism.stamina.max = 220
			-- local inv = ply:GetNetVar("Inventory", {})
			-- inv["Weapons"]["hg_flashlight"] = true
			
			-- ply:SetNetVar("Inventory", inv)
		-- end,
	-- },
	["traitor_zombie"] = {
		Name = "Zombie",
		Description = [[Can infect other players silently.
Infected players can be cured by a doctor.
If all players are cured zombie will lose.
Instead of dying will be randomly transported to another infected player's body.
Has no weapons or any tools.
Despite being zombie, still bears appearance of a normal human.]],
		Objective = "You're the zombie. Infect everyone to win. Avoid doctor.",
		SpawnFunction = function(ply)
			-- ply:Give("weapon_sogknife")	
			-- ply:Give("weapon_adrenaline")
			
			-- ply.organism.stamina.max = 220
			-- local inv = ply:GetNetVar("Inventory", {})
			-- inv["Weapons"]["hg_flashlight"] = true
			
			-- ply:SetNetVar("Inventory", inv)
		end,
	},
	--=//
}
--//

--\\Professions
MODE.ProfessionsRoundTypes = {
	["standard"] = true,
	["soe"] = true,
}

MODE.Professions = {
	["doctor"] = {
		Name = "Doctor",
		SpawnFunction = function(ply)	--; TODO MAKE IT WORK
			--; It's a bad practice to give professions any weapons or tools
		end,
	},
	["huntsman"] = {
		Name = "Huntsman",
		SpawnFunction = function(ply)
			--; It's a bad practice to give professions any weapons or tools
		end,
	},
	["engineer"] = {
		Name = "Engineer",
		SpawnFunction = function(ply)
			--; It's a bad practice to give professions any weapons or tools
		end,
	},
	["cook"] = {
		Name = "Cook",
		SpawnFunction = function(ply)
			--; It's a bad practice to give professions any weapons or tools
		end,
	},
	["builder"] = {
		Name = "Builder",
		SpawnFunction = function(ply)
			--; It's a bad practice to give professions any weapons or tools
		end,
	},
}
--//

--\\
--; Названия перменных чуть чуть конченные получились, нужно будет подумать как улучшить
--; ужас
MODE.FadeScreenTime = 1.5
MODE.DefaultRoundStartTime = 6
MODE.RoleChooseRoundStartTime = 10

MODE.RoleChooseRoundTypes = {
	["standard"] = {
		TraitorDefaultRole = "traitor_default",
		Traitor = {
			["traitor_default"] = true,
			["traitor_infiltrator"] = true,
			["traitor_chemist"] = true,
			["traitor_assasin"] = true,
			--; ОБЪЕДЕНИТЬ ХИМИКА И ДИВЕРСАНТА!!! наверное
			-- ["traitor_demoman"] = true,
		},
		Professions = {
			["doctor"] = {
				Chance = 1,
			},
			["huntsman"] = {
				Chance = 1,
			},
			["engineer"] = {
				Chance = 1,
			},
			["cook"] = {
				Chance = 1,
			},
			["builder"] = {
				Chance = 1,
			},
		},
	},
	["soe"] = {
		TraitorDefaultRole = "traitor_default_soe",
		Traitor = {
			["traitor_default_soe"] = true,
			["traitor_infiltrator_soe"] = true,
			-- ["traitor_chemist_soe"] = true,
			["traitor_assasin_soe"] = true,
			-- ["traitor_demoman_soe"] = true,
		},
		Professions = {
			["doctor"] = {
				Chance = 1,
			},
			["huntsman"] = {
				Chance = 1,
			},
			["engineer"] = {
				Chance = 1,
			},
			["cook"] = {
				Chance = 1,
			},
		},
	},
}
--//

MODE.Roles = {}
MODE.Roles.soe = {
	traitor = {
		name = "Traitor",
		color = Color(190,0,0)
	},

	gunner = {
		name = "Innocent",
		color = Color(158,0,190)
	},

	innocent = {
		name = "Innocent",
		color = Color(0,120,190)
	},
}

MODE.Roles.standard = {
	traitor = {
		objective = "You've been preparing for this for a long time. Kill everyone.",
		name = "Murderer",
		color = Color(190,0,0)
	},

	gunner = {
		name = "Bystander",
		color = Color(158,0,190)
	},

	innocent = {
		name = "Bystander",
		color = Color(0,120,190)
	},
}

MODE.Roles.wildwest = {
	traitor = {
		objective = "You've been preparing for this for a long time. Kill everyone.",
		name = "Murderer",
		color = Color(190,0,0)
	},

	gunner = {
		name = "Bystander",
		color = Color(159,85,0)
	},

	innocent = {
		name = "Bystander",
		color = Color(159,85,0)
	},
}

MODE.Roles.gunfreezone = {
	traitor = {
		name = "Murderer",
		color = Color(190,0,0)
	},

	gunner = {
		name = "Innocent",
		color = Color(0,120,190)
	},

	innocent = {
		name = "Innocent",
		color = Color(0,120,190)
	},
}

MODE.Roles.supermario = {
	traitor = {
		objective = "You're the evil Mario! Jump around and take down everyone.",
		name = "Traitor Mario",
		color = Color(190,0,0)
	},

	gunner = {
		objective = "You're the hero Mario! Use your jumping ability to stop the traitor.",
		name = "Hero Mario",
		color = Color(158,0,190)
	},

	innocent = {
		objective = "You're a bystander Mario, survive and avoid the traitor's traps!",
		name = "Innocent Mario",
		color = Color(0,120,190)
	},
}

function MODE.GetPlayerTraceToOther(ply, aim_vector, dist)
	local trace = hg.eyeTrace(ply, dist, nil, aim_vector)
	
	if(trace)then
		local aim_ent = trace.Entity
		local other_ply = nil
		
		if(IsValid(aim_ent))then
			if(aim_ent:IsPlayer())then
				other_ply = aim_ent
			elseif(aim_ent:IsRagdoll())then
				if(IsValid(aim_ent.ply))then
					other_ply = aim_ent.ply
				end
			end
		end
		
		return aim_ent, other_ply, trace
	else
		return nil
	end
end
