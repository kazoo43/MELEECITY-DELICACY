AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel(self.WorldModel)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	self:SetUseType(USE_TOGGLE)
	self:DrawShadow(true)
	self:SetModelScale(self.modelscale or 1)
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetMass(2)
		phys:Wake()
		phys:EnableMotion(true)
	end
	self.created = CurTime()

	timer.Simple(0, function()
		if not IsValid(self) then return end

		self:SetModelScale(self.modelscale or 1)
	end)

	timer.Simple(0.5,function()
		if not IsValid(self) then return end
		
		self:SetOwner()
	end)
end

function ENT:Think()
	if not IsValid(self:GetPhysicsObject()) then return end
	local speed = self:GetPhysicsObject():GetVelocity():LengthSqr()
	if self.constrained then return end
	if self.AeroDrag then
		AeroDrag(self, self:GetAngles():Forward(), 10)
	end
	self:SetCollisionGroup(speed < 220000 and COLLISION_GROUP_WEAPON or COLLISION_GROUP_NONE)
end

function ENT:PhysicsCollide(data, phys)
	if data.Speed < 100 then return end 
	if self.removed then return end
	
	local hitent = data.HitEntity
	if not IsValid(hitent) then hitent = Entity(0) end

	-- Improve trace accuracy by backtracing from the hit position
	local velDir = data.OurOldVelocity:GetNormalized()
	local tr = {}
	tr.start = data.HitPos - velDir * 16
	tr.endpos = data.HitPos + velDir * 16
	tr.filter = self
	local traceResult = util.TraceLine(tr)
	
	if not traceResult.Hit then
		tr.start = self:GetPos()
		tr.endpos = self:GetPos() + data.OurOldVelocity
		traceResult = util.TraceLine(tr)
	end
	if not IsValid(hitent) or hitent == Entity(0) then
		if IsValid(traceResult.Entity) then
			hitent = traceResult.Entity
		end
	end

	local canDamage = true
	if IsValid(hitent) and (hitent:IsPlayer() or hitent:IsRagdoll() or hitent.organism) then
		self.hitCooldowns = self.hitCooldowns or {}
		local key = hitent:EntIndex()
		local nextTime = self.hitCooldowns[key] or 0
		if CurTime() < nextTime then
			canDamage = false
		else
			self.hitCooldowns[key] = CurTime() + 1
		end
	end

	self.Penetration = self.penetration or 1
	local hitSoundPlayed = false
	if canDamage then
		local dmginfo = DamageInfo()
		dmginfo:SetAttacker(self.owner)
		dmginfo:SetInflictor(self)
		dmginfo:SetDamage((self.damage or 20) * math.Clamp((data.Speed / self.MaxSpeed), 0, 1))
		dmginfo:SetDamageForce(data.OurOldVelocity)
		dmginfo:SetDamageType(self.DamageType or DMG_SLASH)
		dmginfo:SetDamagePosition(data.HitPos)
		hitent:TakeDamageInfo(dmginfo)
		if IsValid(hitent) then
			if hitent.organism or hitent:IsRagdoll() or hitent:IsPlayer() then
				self:EmitSound(self.AttackHitFlesh, 65)
				if self.HitFleshExtra and #self.HitFleshExtra > 0 then
					local snd = table.Random(self.HitFleshExtra)
					self:EmitSound(snd, 75, self.HitFleshExtraPitch and (istable(self.HitFleshExtraPitch) and math.random(self.HitFleshExtraPitch[1], self.HitFleshExtraPitch[2]) or self.HitFleshExtraPitch) or 100)
				end
				hitSoundPlayed = true
			else
				self:EmitSound(self.AttackHit, 65)
				hitSoundPlayed = true
			end
		end
	end
	if self.noStuck then return end

	-- Chance-based lodging: 40% base chance to stick, plus speed factor?
	-- For now, just a flat chance to reduce lodging frequency as requested
	local lodgeChance = 0.4 
	
	-- If it's a person/ragdoll, check chance
	local shouldLodge = false
	if (hitent.organism or hitent:IsRagdoll()) and ((self.DamageType or DMG_SLASH) == DMG_SLASH) and !self.shouldntlodge then
		shouldLodge = math.random() < lodgeChance
		if not hitSoundPlayed then 
			self:EmitSound(self.AttackHitFlesh, 65) 
			if self.HitFleshExtra and #self.HitFleshExtra > 0 then
				local snd = table.Random(self.HitFleshExtra)
				self:EmitSound(snd, 75, self.HitFleshExtraPitch and (istable(self.HitFleshExtraPitch) and math.random(self.HitFleshExtraPitch[1], self.HitFleshExtraPitch[2]) or self.HitFleshExtraPitch) or 100)
			end
		end
	elseif data.TheirSurfaceProps != 76 then
		local wallChance = self.wallLodgeChance
		if wallChance == nil then wallChance = 0.7 end
		shouldLodge = math.random() < wallChance
		if not hitSoundPlayed then self:EmitSound(self.AttackHit, 65) end
	end

	if not shouldLodge then
		-- If not lodging, let it bounce (physics handles this naturally)
		-- We just ensure we don't weld it
		return
	end

	local function smoothLodge(targetPos, targetAng, finish)
		local startPos = self:GetPos()
		local startAng = self:GetAngles()
		local startTime = CurTime()
		local duration = 0.08
		local timerName = "hg_throwable_lodge_" .. self:EntIndex()
		timer.Remove(timerName)
		timer.Create(timerName, 0.01, 0, function()
			if not IsValid(self) then timer.Remove(timerName) return end
			local t = (CurTime() - startTime) / duration
			if t >= 1 then
				self:SetPos(targetPos)
				self:SetAngles(targetAng)
				timer.Remove(timerName)
				if finish then finish() end
				return
			end
			self:SetPos(LerpVector(t, startPos, targetPos))
			self:SetAngles(LerpAngle(t, startAng, targetAng))
		end)
	end

	-- Lodging Logic
	if (hitent.organism or hitent:IsRagdoll()) then
		local bone = traceResult.PhysicsBone
		if not bone or bone < 0 then
			bone = hitent:TranslateBoneToPhysBone(hitent:GetNearestBone(data.HitPos))
		end

		local physBoneID = hitent:TranslatePhysBoneToBone(bone)
		local boneMat = hitent:GetBoneMatrix(physBoneID)
		
		if boneMat then
			-- Calculate local offset
			local hitPos = traceResult.HitPos
			if not traceResult.Hit then hitPos = data.HitPos end

			-- Check if the hit is "behind" the target relative to velocity
			-- If the hit normal is roughly in same direction as velocity, we hit the back side? 
			-- Or if hitpos is too deep.
			-- Let's just trust the traceResult.HitPos which is the surface.
			
			local lPos, lAng = WorldToLocal(hitPos, self:GetAngles(), boneMat:GetTranslation(), boneMat:GetAngles())
			
			timer.Simple(0, function()
				if not IsValid(hitent) then return end
				if not IsValid(self) then return end
				
				local target = IsValid(hitent.FakeRagdoll) and hitent.FakeRagdoll or IsValid(hitent:GetNWEntity("RagdollDeath")) and hitent:GetNWEntity("RagdollDeath") or hitent
				
				local targetBone = bone
				if target != hitent then
					if not target:TranslatePhysBoneToBone(bone) then
						targetBone = 0
					end
				end

				local targetPhysBoneID = target:TranslatePhysBoneToBone(targetBone)
				local targetBoneMat = target:GetBoneMatrix(targetPhysBoneID)
				
				if targetBoneMat then
					local newPos, newAng = LocalToWorld(lPos, lAng, targetBoneMat:GetTranslation(), targetBoneMat:GetAngles())
					
					-- Reduced depth offset to prevent it poking out the other side
					-- Clamp penetration to avoid "behind" issues on thin limbs
					local penetrationDepth = math.Clamp(self.uglublenie or 1, 0.5, 2)
					local targetPos = newPos + newAng:Forward() * penetrationDepth
					smoothLodge(targetPos, newAng, function()
						if not IsValid(self) then return end
						if not IsValid(target) then return end
						local weld = constraint.Weld(self, target, 0, targetBone, 0, true)
						if not IsValid(weld) then
							local physObj = self:GetPhysicsObject()
							if IsValid(physObj) then physObj:EnableMotion(true) end
							return
						end
						self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE) 
					end)
				end
			end)
		end
		
	elseif data.TheirSurfaceProps != 76 then
		-- Wall lodging
		local hitPos = traceResult.HitPos
		if not traceResult.Hit then hitPos = data.HitPos end
		local hitAng = self:GetAngles()
		
		timer.Simple(0, function()
			if !IsValid(self) then return end
			if self.noStuck then self:SetCollisionGroup(COLLISION_GROUP_NONE) return end
			local penetrationDepth = math.Clamp(self.uglublenie or 1, 0.5, 3)
			local targetPos = hitPos + hitAng:Forward() * penetrationDepth
			local physObj = self:GetPhysicsObject()
			if IsValid(physObj) then physObj:EnableMotion(false) end
			smoothLodge(targetPos, hitAng, function()
				if not IsValid(self) then return end
				if self.noStuck then self:SetCollisionGroup(COLLISION_GROUP_NONE) return end
				constraint.Weld(data.HitEntity,self,0,0,0,true)
				if data.HitEntity == Entity(0) then
					self:SetMoveType(MOVETYPE_NONE)
					if self.hitworldfunc then
						self.hitworldfunc(self)
					end
				end
				self.constrained = true
				self:SetCollisionGroup(COLLISION_GROUP_NONE)
			end)
		end)
	end
end

function ENT:Use(ply)
	if self.created + 0.5 > CurTime() then return end
	if self.removed then return end
	if self.wep then
		local wep = ents.Create(self.wep)
		wep:Spawn()
		wep:SetPos(self:GetPos())
		wep:SetAngles(self:GetAngles())
		wep.poisoned2 = self.poisoned2
		self:Remove()

		if constraint.FindConstraint( self, "Weld" ) then
			local tbl = constraint.FindConstraint( self, "Weld" )
			if tbl.Ent2:IsPlayer() or tbl.Ent2:IsRagdoll() then
				local dmginfo = DamageInfo()
				dmginfo:SetAttacker(self.owner)
				dmginfo:SetInflictor(self)
				dmginfo:SetDamage(self.returndamage or 10)
				dmginfo:SetDamagePosition(self:GetPos())
				dmginfo:SetDamageType(DMG_SLASH)
				self.PainMultiplier = 0.5
				tbl.Ent2:TakeDamageInfo(dmginfo)
				hg.organism.AddWoundManual(tbl.Ent2,self.returnblood or 10,vector_origin,angle_zero,tbl["Bone2"] or 0,CurTime())
			end
		end

		if not hook.Run("PlayerCanPickupWeapon",ply,wep) then wep.IsSpawned = true wep.init = true return end

		ply:PickupWeapon(wep)
	end
end
