local MODE = MODE

util.AddNetworkString("HMCD_BeingVictimOfNeckBreak")	--; А тут я значит рещил без скобок да крутой кодинг стиль вопросы?
util.AddNetworkString("HMCD_BreakingOtherNeck")
util.AddNetworkString("HMCD_BeingVictimOfDisarmament")
util.AddNetworkString("HMCD_DisarmingOther")
util.AddNetworkString("HMCD_UpdateChemicalResistance")

--\\Chemical resistance
	function MODE.NetworkChemicalResistanceOfPlayer(ply)
		ply.PassiveAbility_ChemicalAccumulation = ply.PassiveAbility_ChemicalAccumulation or {}
		
		net.Start("HMCD_UpdateChemicalResistance")
		
		for chemical_name, amt in pairs(ply.PassiveAbility_ChemicalAccumulation) do
			net.WriteString(chemical_name)
			net.WriteUInt(math.Round(amt), MODE.NetSize_ChemicalResistanceBits)
		end
		
		net.WriteString("")
		net.Send(ply)
	end
--//

hook.Add("PlayerPostThink", "HMCD_SubRoles_Abilities", function(ply)
	if(MODE.RoleChooseRoundTypes[MODE.Type])then
		if(ply:Alive() and ply.organism and not ply.organism.otrub)then
			local can_break_neck = (ply.SubRole == "traitor_infiltrator" or ply.SubRole == "traitor_infiltrator_soe" or ply.SubRole == "traitor_martial_artist")
			local can_disarm = (ply.SubRole == "traitor_assasin" or ply.SubRole == "traitor_assasin_soe" or ply.SubRole == "traitor_martial_artist")
			local is_martial_artist = ply.SubRole == "traitor_martial_artist"
			local neck_break_key = (ply.SubRole == "traitor_martial_artist") and IN_RELOAD or IN_USE
			local neck_break_allow = true
			local neck_break_down = false
			if(is_martial_artist)then
				local walk_down = hg.KeyDown(ply, IN_WALK)
				local reload_down = hg.KeyDown(ply, IN_RELOAD)
				neck_break_down = walk_down and reload_down
			else
				neck_break_allow = hg.KeyDown(ply, IN_WALK)
				neck_break_down = hg.KeyDown(ply, neck_break_key)
			end
			local neck_break_prev = ply.Ability_NeckBreak_KeyDownPrev == true

			if(can_break_neck)then
				if(neck_break_allow)then
					if((ply.SubRole == "traitor_infiltrator" or ply.SubRole == "traitor_infiltrator_soe") and ply:KeyPressed(IN_RELOAD))then
						local aim_ent, other_ply = hg.eyeTrace(ply,85).Entity
						other_ply = hg.RagdollOwner(aim_ent) or aim_ent
						
						if(IsValid(aim_ent) and aim_ent:IsRagdoll())then	--; REDO
							local other_appearance = aim_ent.CurAppearance
							local your_appearance = ply.CurAppearance

							local aMdl1,aMdl2 = your_appearance.AModel,other_appearance.AModel
							
							other_appearance.AModel = aMdl1
							your_appearance.AModel = aMdl2

							local aFace1,aFace2 = your_appearance.AFacemaps,other_appearance.AFacemaps

							other_appearance.AFacemaps = aFace1
							your_appearance.AFacemaps = aFace2

							hg.Appearance.ForceApplyAppearance(ply, other_appearance, true)
							local char = hg.GetCurrentCharacter(ply)
							if char:IsRagdoll() then
								hg.Appearance.ForceApplyAppearance(char, other_appearance, true)
							end
							ply:EmitSound("snd_jack_hmcd_disguise.wav",35,math.random(90,110),0.5)

							--local duplicator_data = duplicator.CopyEntTable(ply)
							--duplicator.DoGeneric(aim_ent, duplicator_data)
							aim_ent.CurAppearance = your_appearance

							hg.Appearance.ForceApplyAppearance(aim_ent, your_appearance, true)
							
							if other_ply:IsPlayer() and other_ply:Alive() then
								hg.Appearance.ForceApplyAppearance(other_ply, your_appearance, true)
							end
						end
					end
					
					if(can_break_neck and neck_break_down)then
						if(ply.Ability_NeckBreak)then
							MODE.ContinueBreakingOtherNeck(ply)
						else
							local aim_ent, other_ply = MODE.GetPlayerTraceToOther(ply)
							
							if(IsValid(aim_ent))then
								if(other_ply and MODE.CanPlayerBreakOtherNeck(ply, aim_ent))then
									MODE.StartBreakingOtherNeck(ply, other_ply)
								end
							end
						end
					end

					if(can_break_neck and neck_break_prev and not neck_break_down)then
						MODE.StopBreakingOtherNeck(ply)
					end
				else
					MODE.StopBreakingOtherNeck(ply)
				end
			end

			ply.Ability_NeckBreak_KeyDownPrev = neck_break_allow and neck_break_down or false
			
			if(can_disarm)then
				if(ply:KeyDown(IN_WALK))then
					if(ply:KeyPressed(IN_USE) and not ply.Ability_DisarmNeedRelease and not ply.Ability_Disarm)then
						local aim_ent, other_ply, trace = MODE.GetPlayerTraceToOther(ply, nil, MODE.DisarmReach)
						
						if(IsValid(aim_ent))then
							if(other_ply and MODE.CanPlayerDisarmOther(ply, aim_ent, MODE.DisarmReach) and MODE.CanPlayerDisarmOtherPly(ply, other_ply, MODE.DisarmReach))then
								MODE.StartDisarmingOther(ply, other_ply)
							end
						end
					elseif(ply:KeyDown(IN_USE))then
						if(ply.Ability_Disarm)then
							MODE.ContinueDisarmingOther(ply)
						end
					end
					
					if(ply:KeyReleased(IN_USE))then
						MODE.StopDisarmingOther(ply)
						ply.Ability_DisarmNeedRelease = nil
					end
				else
					MODE.StopDisarmingOther(ply)
				end
			end
			
			if(ply.SubRole == "traitor_zombie")then
				if(ply:KeyDown(IN_WALK))then
					
				end
			end

			if(ply.SubRole == "traitor_chemist")then
				MODE.DegradeChemicalsOfPlayer(ply)
				
				if(!ply.PassiveAbility_ChemicalAccumulation_NextNetworkTime or ply.PassiveAbility_ChemicalAccumulation_NextNetworkTime <= CurTime())then
					MODE.NetworkChemicalResistanceOfPlayer(ply)

					ply.PassiveAbility_ChemicalAccumulation_NextNetworkTime = CurTime() + 1
				end
			end
		end
	end
end)
