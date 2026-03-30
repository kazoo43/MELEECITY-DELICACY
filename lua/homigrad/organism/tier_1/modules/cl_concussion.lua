local hg = hg or {}

if CLIENT then
	print("Concussion module loaded.")
end

local concussion_smooth = 0
local last_concussion = 0
local concussion_sound = nil

hook.Add("RenderScreenspaceEffects", "hg_concussion_effects", function()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() then 
		concussion_smooth = 0
		if concussion_sound then
			concussion_sound:Stop()
			concussion_sound = nil
		end
		return 
	end

	local org = ply.organism
	if not org then 
		concussion_smooth = 0
		if concussion_sound then
			concussion_sound:Stop()
			concussion_sound = nil
		end
		return 
	end

	local concussion = org.concussion or 0
	
	-- Smoothly interpolate the concussion value to avoid stepping
	concussion_smooth = math.Approach(concussion_smooth, concussion, FrameTime() * 2)

	-- Handle end of concussion or otrub
	if (concussion <= 0 and concussion_smooth <= 0.01) or org.otrub then 
		concussion_smooth = 0
		if ply.hg_concussion_dsp then
			ply:SetDSP(0, false) -- Reset sound
			ply.hg_concussion_dsp = nil
		end
		if concussion_sound then
			concussion_sound:FadeOut(1)
			concussion_sound = nil
		end
		return 
	end
	
	-- Sound Logic (Shellshock)
	if concussion_smooth > 0 then
		if not concussion_sound then
			-- Pick one of the 3 sounds randomly
			local soundPath = "shellshock/" .. math.random(1, 3) .. ".mp3"
			concussion_sound = CreateSound(ply, soundPath)
			concussion_sound:Play()
		end

		if concussion_sound then
			-- Volume scales with intensity (0 to 1)
			-- Using 0.1 fade time for smooth volume changes
			local vol = math.Clamp(concussion_smooth / 5, 0, 1) -- Max volume at 5 concussion
			concussion_sound:ChangeVolume(vol, 0.1)
		end
	end

	-- Sound muffling (DSP) when concussion > 1
	if concussion_smooth > 1 then
		if ply.hg_concussion_dsp != 14 then
			ply:SetDSP(14, false)
			ply.hg_concussion_dsp = 14
		end
	else
		if ply.hg_concussion_dsp == 14 then
			ply:SetDSP(0, false)
			ply.hg_concussion_dsp = nil
		end
	end

	if concussion_smooth <= 0 then return end

	-- Visual Effects
	local intensity = math.Clamp(concussion_smooth / 10, 0, 1)
	local horizontal_blur = 20 + (intensity * 30)

	local darken = 0.15 * intensity
	local multiply = 2.88 * intensity
	local color_mul = 0.50 
	
	DrawBloom(darken, multiply, horizontal_blur, 0, 1, color_mul, 134/255, 210/255, 240/255)
end)
