hg.organism.module.concussion = {}
local module = hg.organism.module.concussion

module[1] = function(org)
    org.concussion = 0
end

module[2] = function(ply, org, timeValue)
    if org.concussion > 0 then
        org.concussion = math.max(org.concussion - timeValue, 0)
        
        -- Drain consciousness (0.05 * concussion per second)
		if org.consciousness then
			org.consciousness = math.max(org.consciousness - (org.concussion * 0.032) * timeValue, 0)
		end

        if org.concussion > 2.5 then
             org.needfake = true
             -- Apply disorientation (set to 2)
             org.disorientation = math.max(org.disorientation or 0, 2)
        end
    end
end
