local att, ent, oldEntView
follow = follow or nil
local vecZero, vecFull, angZero = Vector(0, 0, 0), Vector(1, 1, 1), Angle(0, 0, 0)
local vecPochtiZero = Vector(0.1, 0.1, 0.1)
local view = {}
local math_Clamp = math.Clamp
local ang
local att_Ang, ot
local angEye = Angle(0, 0, 0)
local firstPerson

local deathLocalAng = Angle(0, 0, 0)

local angle

local lean_camera = 0

hook.Add("InputMouseApply", "fakeCameraAngles", function(cmd, x, y, angle)
	local tbl = {}

	tbl.cmd = cmd
	tbl.x = x
	tbl.y = y
	tbl.angle = angle
	
	hook.Run("HG.InputMouseApply", tbl)

	if !lply:Alive() then
		tbl.angle.r = 0
	end
	
	cmd = tbl.cmd
	x = tbl.x
	y = tbl.y
	angle = tbl.angle

	if not tbl.override_angle then
		angle.pitch = math.Clamp(angle.pitch + y / 50, -89, 89)
		angle.yaw = angle.yaw - x / 50
	end
	
	cmd:SetViewAngles(angle)

	return true
end)

local turned = false
local lastRagAng
local ctime
hook.Add("HG.InputMouseApply", "fakeCameraAngles2", function(tbl)
	if not IsValid(LocalPlayer()) or not LocalPlayer():Alive() then return end

	if IsValid(follow) and ctime != CurTime() then
		ctime = CurTime()

		hook.Run("ViewpunchThink", tbl)
	end

	local cmd = tbl.cmd
	local x = tbl.x
	local y = tbl.y
	local angle = tbl.angle
	
	local wep = lply:GetActiveWeapon()

	local consmul = 1 - hg.CalculateConsciousnessMul()

	if (wep.weight or wep.visualweight) and ((wep.weight and wep.weight > 0 or wep.visualweight and wep.visualweight > 0) or lply.organism.larmamputated or consmul > 0.3) then
		ViewPunch3(Angle(-y / 50 / 16, x / 50 / 16, 0) * math.min(((wep.visualweight ~= nil and wep.visualweight > 0) and wep.visualweight) or wep.weight, 10) / 3 / (1 - consmul * 0.5) * (lply.organism.larmamputated and 4 or 1) * (lply.organism.rarmamputated and 2 or 1))
	end

	ViewPunch4(Angle(y / 50 / 16, -x / 50 / 16, -x / 50 / 1) * 0.1)

	local left = hg.KeyDown(LocalPlayer(), IN_ALT2) and not hg.KeyDown(LocalPlayer(), IN_ALT1)
	local right = hg.KeyDown(LocalPlayer(), IN_ALT1) and not hg.KeyDown(LocalPlayer(), IN_ALT2)
	lean_camera = Lerp(0.1, lean_camera, (left and 1.3 or 0) + (right and -1.3 or 0))

	if LocalPlayer().lean and math.abs(LocalPlayer().lean) < 0.01 then
		oldlean = 0
		lean_lerp = 0
		lean_camera = 0
	end
	
	if LocalPlayer():InVehicle() and not IsValid(follow) then
		tbl.override_angle = true
		tbl.angle = angle_zero
		lastRagAng = nil
		return true
	end

	if not IsValid(follow) then
		angle.roll = (turned and 180 or 0) + lean_camera * 10
		tbl.angle = angle
		lastRagAng = nil
		return
	end

	local q = Quaternion():SetAngle(angle)
	local q_pitch = Quaternion():SetAngleAxis(y / 50, Vector(0, 1, 0))
	local q_yaw = Quaternion():SetAngleAxis(-x / 50, Vector(0, 0, 1))

	local hg_ragdollcombat_cvar = GetConVar("hg_ragdollcombat")
	local ragdollcombat = hg_ragdollcombat_cvar and hg_ragdollcombat_cvar:GetBool() or false
	local canmovehead = (lply:KeyDown(IN_USE) or (ishgweapon(wep) and lply:KeyDown(IN_ATTACK2)) or (wep.ismelee and (lply:KeyDown(IN_ATTACK2) or lply:KeyDown(IN_ATTACK)))) or lply:InVehicle() or ragdollcombat

	if canmovehead then
		local q_roll = Quaternion():SetAngleAxis(lean_camera * 0.5, Vector(1, 0, 0))
		q = q * q_pitch * q_yaw * q_roll
	else
		q = q * q_pitch * q_yaw
		turned = false
	end

	local newAng = q:Angle()

	lply.fakeangles = angle

	if IsValid(follow) then
		local bone = follow:LookupBone("ValveBiped.Bip01_Head1") --delta time 
		local phys = bone and follow:GetPhysicsObjectNum(follow:TranslateBoneToPhysBone(bone))

		if IsValid(phys) then
			local angVel = phys:GetAngleVelocity()
			angVel = -angVel

			local len = angVel:Length()
			if len > 1 then
				local q_phys = Quaternion():SetAngleAxis(len * FrameTime(), angVel:GetNormalized())
				local q_current = Quaternion():SetAngle(newAng)
				local q_final = q_phys * q_current
				newAng = q_final:Angle()
			end
		elseif bone then
			local m = follow:GetBoneMatrix(bone)
			if m then
				local currentRagAng = m:GetAngles()
				if lastRagAng then
					local q_old = Quaternion():SetAngle(lastRagAng)
					local q_new = Quaternion():SetAngle(currentRagAng)
					local q_diff = q_new * q_old:Inverted()
					
					local ang_diff = q_diff:Angle()
					local speed = follow:GetVelocity():Length()
					local lim = speed < 100
					local yawFactor = lim and 0.25 or 1
					local pirolfac = lim and 0.25 or 1
					
					ang_diff.y = ang_diff.y * yawFactor
					ang_diff.p = ang_diff.p * pirolfac
					ang_diff.r = 0
					
					q_diff:SetAngle(ang_diff)
					
					local q_current = Quaternion():SetAngle(newAng)
					local q_final = q_diff * q_current
					newAng = q_final:Angle()
				end
				lastRagAng = currentRagAng
			end
		end
	end

	angle.pitch = newAng.p
	angle.yaw = newAng.y
	angle.roll = newAng.r

	if wep.IsResting and wep:IsResting() then
		angle.roll = math.Clamp(angle.roll, -15, 15)
	end

	if lply:InVehicle() then
		angle.roll = math.Clamp(angle.roll, -15, 15)
	end
	
	tbl.override_angle = true
	tbl.angle = angle
end)

fakeTimer = fakeTimer or nil
-- local hg_cshs_fake = ConVarExists("hg_cshs_fake") and GetConVar("hg_cshs_fake") or CreateConVar("hg_cshs_fake", 0, FCVAR_ARCHIVE, "fake from cshs", 0, 1)
local hg_firstperson_death = ConVarExists("hg_firstperson_death") and GetConVar("hg_firstperson_death") or CreateClientConVar("hg_firstperson_death", "0", "first person death", true, false, 0, 1)
local hg_fov = ConVarExists("hg_fov") and GetConVar("hg_fov") or CreateClientConVar("hg_fov", "70", true, false, "changes fov to value", 75, 100)
local hg_gopro = ConVarExists("hg_gopro") and GetConVar("hg_gopro") or CreateClientConVar("hg_gopro", "0", true, false, "gopro camera", 0, 1)
local hg_ragdollcombat = ConVarExists("hg_ragdollcombat") and GetConVar("hg_ragdollcombat") or CreateConVar("hg_ragdollcombat", 0, FCVAR_REPLICATED, "ragdoll combat", 0, 1)

local k = 0
local wepPosLerp = Vector(0,0,0)
local CalcView
local angleZero = Angle(0,0,0)

local deathlerp = 0
local tblfollow = {}
local lerpasad = 0
CalcView = function(ply, origin, angles, fov, znear, zfar)
	if GetViewEntity() ~= (ply or LocalPlayer()) then return end
	local oldorigin = -(-origin)
	local oldangles = -(-angles)
	fov = hg_fov:GetInt()
	lerpfovadd2 = LerpFT(0.1, lerpfovadd2, zooming and -25 or 0)
	
	if not lply:Alive() then
		fakeTimer = fakeTimer or CurTime() + 6
	end
	
	if not lply:Alive() and follow and ((fakeTimer < CurTime()) or lply:KeyPressed(IN_RELOAD)) then
		follow = nil

		return
	end
	
	if not lply:Alive() and not follow then
		return hook.Run("HG_CalcView", ply, origin, angles, fov, znear, zfar)
	end

	if lply.lean and math.abs(lply.lean) < 0.01 then
		oldlean = 0
		lean_lerp = 0
	end

	--angles.roll = (turned and 180 or 0) + lean_lerp * 10

	if ply:InVehicle() then
		local ex = ply:GetAimVector():AngleEx(ply:GetVehicle():GetUp())
		ex[3] = 0
		angles = ex

		if ply:GetVehicle():GetParent().MovePlayerView then
			ply.lockcamera = false
			ply:GetVehicle():GetParent().MovePlayerView = function() end
		end
	end

	
	if not lply:Alive() and hg.DeathCam and hg.DeathCamAvailable(ply) then return hg.DeathCam(ply,origin,angles,fov,znear,zfar) end

	if not IsValid(ply) then return end
	if not IsValid(follow) then return end
	if not follow:LookupBone("ValveBiped.Bip01_Head1") then return end

	local vpang = GetViewPunchAngles2() + GetViewPunchAngles3()
	vpang[3] = 0
	
	view.fov = GetConVar("hg_fov"):GetInt()
	firstPerson = GetViewEntity() == lply
	
	if not firstPerson then return end

	att = follow:GetAttachment(follow:LookupAttachment("eyes"))
	if not att or not istable(att) then return end
	ang = angles
	ang:Normalize()
	
	att_Ang = att.Ang
	att_Ang:Normalize()
	
	local _, ot = WorldToLocal(vector_origin, ang, vector_origin, att_Ang)
	ot:Normalize()

	ot[2] = math.Clamp(ot[2], -90, 90)
	ot[1] = math.Clamp(ot[1], -90, 90)

	local _, angEye = LocalToWorld(vector_origin, ot, vector_origin, att_Ang)
	angEye:Normalize()
	
	angEye[3] = ang[3]
	--angEye = ang
	--angEye = att_Ang

	if ply:InVehicle() then
		angEye = angles
	end

	if ply.organism and ply.organism.otrub then
		angEye = att_Ang
	end

	local cshs_fake = true
	
	if IsValid(ply.OldRagdoll) then DrawPlayerRagdoll(follow, ply) end

	local pos = hg.eye(ply, 10, follow, att_Ang)

	--local dot = ang:Forward():Dot((pos - att.Pos):GetNormalized())
	

	if cshs_fake then
		deathlerp = LerpFT(0.1,deathlerp,not ply.bGetUp and 1 or 0)
		att_Ang:Normalize()
	else
		deathlerp = LerpFT( 0.1, deathlerp, 0 )
	end

	local angdeath = LerpAngle(deathlerp, angEye, att_Ang)
	angEye = angdeath

	view.angles = angEye

	if ply:Alive() then
		deathLocalAng:Set(view.angles)
	end

	hg.cam_things(ply, view, angleZero)
	
	if hg_ragdollcombat:GetBool() or (fakeTimer and fakeTimer > CurTime()) then
		if hg_firstperson_death:GetBool() then
			deathlerp = LerpFT(0.05,deathlerp,1)
			local angdeath = LerpAngle(deathlerp,deathLocalAng,att_Ang)

			if not follow:GetManipulateBoneScale(follow:LookupBone("ValveBiped.Bip01_Head1")):IsEqualTol(vecZero,0.001) then
				follow:ManipulateBoneScale(follow:LookupBone("ValveBiped.Bip01_Head1"), firstPerson and vecPochtiZero or vecFull )
			end

			view.origin = pos
			view.angles = att_Ang
		else
			if not follow:GetManipulateBoneScale(follow:LookupBone("ValveBiped.Bip01_Head1")):IsEqualTol(vecZero,0.001) then
				follow:ManipulateBoneScale(follow:LookupBone("ValveBiped.Bip01_Head1"),lerpasad > 0.9 and vecFull or vecPochtiZero)
			end

			lerpasad = Lerp(0.1, lerpasad, (IsAimingNoScope(ply) and 0 or 1))

			local ang = ply:EyeAngles()
			local tr = {}
			tr.start = pos
			tr.endpos = pos - ang:Forward() * 60 * lerpasad + ang:Right() * 15 * lerpasad
			tr.filter = {ply,follow}
			tr.mask = MASK_SOLID

			view.origin = util.TraceLine(tr).HitPos + ((tr.endpos - tr.start):GetNormalized() * -5)
			view.angles = ang
		end
	else
		view.origin = pos
	end

	view.angles:Add(ply:GetViewPunchAngles())
	//view.origin, view.angles = HGAddView(lply, view.origin, view.angles, 0)
	view.angles:Add(-vpang)
	view.angles[3] = view.angles[3] + GetViewPunchAngles4()[3]
	view.angles:RotateAroundAxis(view.angles:Up(),-LookX)
	view.angles:RotateAroundAxis(view.angles:Right(),-LookY)
	view.fov = math.Clamp(hg_fov:GetFloat(),75,100) + lerpfovadd + lerpfovadd2
	view.znear = 1

	if ply.gettingup and (ply.gettingup + 1 - CurTime()) > 0 then
		local k = 1 - (ply.gettingup + 1 - CurTime())
		local k2 = math.max(k - 0.5, 0) * 2
		//view.origin = LerpVector(k2, view.origin, oldorigin)
		view.angles = LerpAngle(k2, view.angles, oldangles)
	end
	//view.angles = angles

	view = hook.Run("Camera", ply, view.origin, view.angles, view, vector_origin) or view

	local wep = ply:GetActiveWeapon()

	k = Lerp(0.1, k, ply:KeyDown(IN_JUMP) and 1 or 0)
	--[[if wep.GetMuzzleAtt then
		wep:WorldModel_Transform()
		wep:DrawAttachments()
	end--]]

	if ply.organism and ply.organism.otrub then view.angles = att_Ang end

	if hg_gopro:GetBool() then
		return SpecCam(follow, origin, angles, fov, znear, zfar)
	end
	hook.Run("PostHGCalcView", ply, view)
	return view
end

hg.CalcViewFake = CalcView

local MAX_EDICT_BITS = 13

function net.ReadEntity2()

	local i = net.ReadUInt( MAX_EDICT_BITS )
	if ( !i ) then return end

	return Entity( i ), i

end

--hook.Add("EntityNetworkedVarChanged","huhuhuasd",function()
	
--end)

local hook_Run = hook.Run
local indexes = {}
net.Receive("Player Ragdoll", function()
	--local ply, ragdoll_index = net.ReadEntity(), net.ReadInt(32) --,net_ReadTable()
	local ply, ragdoll, ragdoll_index = net.ReadEntity(), net.ReadEntity2() --,net_ReadTable()
	if not ragdoll_index then return end
	local ragdoll = IsValid(ragdoll) and ragdoll
	--print(ragdoll)

	ply.ragdoll_index = ragdoll_index
end)

hook.Add("NetworkEntityCreated", "HG_GiveRenderOverride", function(ragdoll)
	if ragdoll:GetClass() == "prop_ragdoll" then
		if !IsValid(ragdoll:GetNWEntity("ply")) then
			ragdoll.RenderOverride = function(self, flags)
				if not IsValid(self) or self:IsDormant() then return end
				if not self:GetBonePosition(1) or self:GetBonePosition(1):IsEqualTol(self:GetPos(), 0.01) then return end
				if not self:GetNWString("PlayerName") then return end
				local ply = self:GetNWEntity("ply")
				local ply = (IsValid(ply) and ply:IsPlayer() and ply:Alive() and ply.FakeRagdoll == self) and ply or self
				
				hg.renderOverride(ply, self, flags)
			end
		end

		for _, v in ipairs(ents.FindInSphere(ragdoll:GetPos(),16)) do
			if IsValid(v) and v:IsPlayer() and v:GetModel() == ragdoll:GetModel() then
				--ragdoll:SetNWString("PlayerName", v:Name())
				ragdoll:SetNWVector("PlayerColor", v:GetPlayerColor())
				ragdoll.PredictedAccessories = v:GetNetVar("Accessories","none")
				ragdoll.PredictedArmor = v:GetNetVar("Armor",{})
				ragdoll.PredictedHideArmorRender = v:GetNetVar("HideArmorRender", false)

				hook.Run("RagdollPerdiction",ragdoll,v)
				break
			end
		end
	end
end)
--h
hook.Add("RagdollEntityCreated", "RagdollFinder", function(ply, ent, key)
	if not IsValid(ply) then return end
	--print(ply)
	local oldrag = ply.FakeRagdoll
	ply.bGetUp = false
	
	if IsValid(ent) then
		ent.RenderOverride = function(self, flags)
			if not IsValid(self) or self:IsDormant() then return end
			if not self:GetBonePosition(1) or self:GetBonePosition(1):IsEqualTol(self:GetPos(), 0.01) then return end
			local ply = (IsValid(ply) and ply:IsPlayer() and ply:Alive() and ply.FakeRagdoll == self) and ply or self
			
			hg.renderOverride(ply, self, flags)
		end
	end
	
	ply.FakeRagdoll = (key == "FakeRagdoll" and ent or ply.FakeRagdoll)-- or (key == "RagdollDeath" and IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ent)
	
	if key == "RagdollDeath" and ply == LocalPlayer() then
		ply.FakeRagdoll = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ent
	end

	--if key == "RagdollDeath" then ply.FakeRagdoll = nil return end

	--ply:SetNWEntity("FakeRagdoll", ent)
	--if not IsValid(oldrag) then oldrag = ent end
	hook.Run("ServerRagdollTransferDecals", ply, ent)

	 

	local ragdoll = ply.FakeRagdoll
	
	ragdoll = IsValid(ragdoll) and ragdoll
	
	if ply == lply then
		follow = ragdoll

		if follow and hg.IsChanged(follow,1,tblfollow) then
			if IsValid(tblfollow[1]) then
				//tblfollow[1]:ManipulateBoneScale(tblfollow[1]:LookupBone("ValveBiped.Bip01_Head1"),vecFull)
			elseif IsValid(follow) and not follow:GetManipulateBoneScale(follow:LookupBone("ValveBiped.Bip01_Head1")):IsEqualTol(vecZero,0.001) then
				//follow:ManipulateBoneScale(follow:LookupBone("ValveBiped.Bip01_Head1"),vecPochtiZero)
			end

			tblfollow[1] = follow
		end
	end

	if ragdoll then
		--ragdoll:SetPredictable(true)--causes ragdoll to shake bruh lol
		ragdoll.ply = ply
		ragdoll.organism = ply.organism

		hg.ragdolls[#hg.ragdolls + 1] = ragdoll
		
		ragdoll:CallOnRemove("RagdollRemove",function()
			hook.Run("RagdollRemove",ply,ragdoll)
		end)

		//ply.FakeRagdollOld = nil

		ply.FakeRagdoll = ragdoll
		hook_Run("Fake", ply, ragdoll)
	else
		if IsValid(ply.FakeRagdoll) then
			ply.fakecd = CurTime() + 2
		end

		if IsValid(ply) then ply:SetNoDraw(false) end
		ply:SetRenderMode(RENDERMODE_NORMAL)
		
		oldrag.ply = nil
		//ply.FakeRagdollOld = oldrag

		ply.FakeRagdoll = nil

		hook_Run("FakeUp", ply, ragdoll)
	end
	
	--if IsValid(ply) and ply.BoneScaleChange then ply:BoneScaleChange() end

	ply.ragdollindex = nil
end)

local vec123 = Vector(0,0,0)
local entityMeta = FindMetaTable("Entity")

function entityMeta:GetPlayerColor()
	return self:GetNWVector("PlayerColor",vec123)
end

function entityMeta:GetPlayerName()
	return self:GetNWString("PlayerName","")
end

local playerMeta = FindMetaTable("Player")

function playerMeta:GetPlayerViewEntity()
	return (IsValid(self:GetNWEntity("spect")) and self:GetNWEntity("spect")) or (IsValid(self.FakeRagdoll) and self.FakeRagdoll) or self
end

function playerMeta:GetPlayerName()
	return self:GetNWString("PlayerName","")
end

function playerMeta:IsFirstPerson()
	if IsValid(self:GetNWEntity("spect",NULL)) then
		return self:GetNWInt("viewmode",viewmode or 1) == 1
	else
		return (GetViewEntity() == self)
	end
end

local ents_FindByClass = ents.FindByClass
local player_GetAll = player.GetAll
function playerMeta:BoneScaleChange()
	do return end
	local firstPerson = LocalPlayer():IsFirstPerson()
	local viewEnt = LocalPlayer():GetPlayerViewEntity()
	
	for i,ent in ipairs(ents_FindByClass("prop_ragdoll")) do
		if not ent:LookupBone("ValveBiped.Bip01_Head1") then continue end
		if ent:GetManipulateBoneScale(ent:LookupBone("ValveBiped.Bip01_Head1")) == vector_origin then continue end
		--if not hg.RagdollOwner(ent) then continue end
		if ent == viewEnt then
			ent:ManipulateBoneScale(ent:LookupBone("ValveBiped.Bip01_Head1"),firstPerson and vecPochtiZero or vecFull)
		else
			ent:ManipulateBoneScale(ent:LookupBone("ValveBiped.Bip01_Head1"),vecFull)
		end
	end

	for i,ent in ipairs(player_GetAll()) do
		if not ent:LookupBone("ValveBiped.Bip01_Head1") then continue end
		if ent:GetManipulateBoneScale(ent:LookupBone("ValveBiped.Bip01_Head1")) == vector_origin then continue end
		if ent == viewEnt then
			ent:ManipulateBoneScale(ent:LookupBone("ValveBiped.Bip01_Head1"),firstPerson and vecPochtiZero or vecFull)
		else
			ent:ManipulateBoneScale(ent:LookupBone("ValveBiped.Bip01_Head1"),vecFull)
		end
	end
end

hook.Add("PostCleanupMap","wtfdude",function()
	LocalPlayer():BoneScaleChange()
end)

local function funcrag(ply, name, oldval, ragdoll)
	--ragdoll = IsValid(ragdoll) and ragdoll or IsValid(ply:GetNWEntity("FakeRagdoll")) and ply:GetNWEntity("FakeRagdoll") or ply:GetNWEntity("RagdollDeath")
	--if ply.onetime then return end
	--ply.onetime = true
	pcall(hook.Run, "RagdollEntityCreated", ply, ragdoll, name)
	--ply.onetime = false
end

hook.Add("PlayerInitialSpawn","asdfgacke",function(ply)
	ply:SetNWVarProxy("RagdollDeath",funcrag)
	ply:SetNWVarProxy("FakeRagdoll", funcrag)
end)

hook.Add("InitPostEntity","fuckyou",function()
	for i,ply in ipairs(player.GetAll()) do
		ply:SetNWVarProxy("RagdollDeath",funcrag)
		ply:SetNWVarProxy("FakeRagdoll", funcrag)
	end
end)

hook.Add("Player Getup", "Fake", function(ply)
	if ply == lply then
		ply.bGetUp = true
		fakeTimer = nil
	end

	ply:SetNWVarProxy("RagdollDeath", funcrag)
	ply:SetNWVarProxy("FakeRagdoll", funcrag)
end)

function hg.RagdollOwner(ragdoll)
	if not IsValid(ragdoll) then return end
	local ply = ragdoll:GetNWEntity("ply")
	return IsValid(ply) and ply:GetNWEntity("FakeRagdoll") == ragdoll and ply
end

hook.Add("Player_Death", "Fake", function(ply)		
	if ply != lply then return end
	
	fakeTimer = CurTime() + 5

	hg.override[ply] = nil

	-- timer.Simple(0.5 * math.max(ply:Ping() / 30,1),function()
	-- 	//ply:BoneScaleChange()
	-- end)
end)

function hg.GetCurrentCharacter(ply)
	if not IsValid(ply) then return end

	local rag = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or IsValid(ply:GetNWEntity("FakeRagdoll", NULL)) and ply:GetNWEntity("FakeRagdoll", NULL)
	return (IsValid(rag) and rag) or ply
end

hook.Add("Player Spawn", "fuckingremoveragdoll", function(ply)
	local ragdoll = ply:GetNWEntity("FakeRagdoll")
	
	if IsValid(ragdoll) then
		ragdoll:SetNWEntity("ply", NULL)
		ragdoll:ManipulateBoneScale(ragdoll:LookupBone("ValveBiped.Bip01_Head1"), Vector(1, 1, 1))
	end
	--FUCKING SHIT
	if IsValid(ply.FakeRagdoll) then
		ply.FakeRagdoll.ply = nil
		ply.FakeRagdoll = nil
	end
	
	if ply == lply then
		fakeTimer = nil
		follow = nil
	end

	ply:SetNWEntity("FakeRagdoll", NULL)
	ply:SetNWEntity("RagdollDeath", NULL)
end)

local override = {}
hg.override = override
net.Receive("Override Spawn", function() override[net.ReadEntity()] = true end)
hook.Add("Player Spawn", "!Override", function(ply)
	if override[ply] then
		override[ply] = nil
		return false
	end
end)

hook.Add("Player Spawn", "zOverride", function(ply)
	if override[ply] then
		override[ply] = nil
		return false
	end
end)

hook.Add("PlayerFootstep", "CustomFootstep", function(ply) if IsValid(ply.FakeRagdoll) then return true end end)

hook.Add("EntityRemoved", "ragdollmodelsnatchinstance", function(ent)
	if IsValid(ent.ply) then
		ent.ply:SnatchModelInstance(ent)
	end
end)

hook.Add("ServerRagdollTransferDecals","raghuy", function(ent, rag)
    if IsValid(ent) && IsValid(rag) && !rag.DecalTransferDone then
        rag:SnatchModelInstance( ent )
        rag.DecalTransferDone = true
    end
end)


hook.Add("OnEntityCreated", "TryCopyAppearanceNow", function( ent )
	--if not ent:IsRagdoll() then return end
	--for k,ply in ipairs(ents.FindInSphere(ent:GetPos(),15)) do
	--	if ply:IsPlayer() then
	--		ent:SetPlayerColor(ply:GetPlayerColor())
	--		local copy = duplicator.CopyEntTable(ply)
	--		duplicator.DoGeneric(ent,copy)
--
	--		ent:SetNWString("PlayerName",ply:Name())
	--		--ent:SetNWVector("PlayerColor",ply:GetPlayerColor())
	--		ent:SetNetVar("Armor", ply:GetNetVar("Armor",{}))
	--		ent:SetNetVar("Accessories", ply:GetNetVar("Accessories","none"))
	--	end
	--end
end)
local sphereRadius = 12
hook.Add("Move","PushAwayRagdolls",function(ply)
	do return end
	if not ply:Alive() and not hg.GetCurrentCharacter(ply):IsPlayer() then return end
	local playerPos = ply:GetPos()
    local sphereCenter = playerPos
    local entities = ents.FindInSphere(sphereCenter, sphereRadius)
    for _, ent in ipairs(entities) do
		if not ent:IsRagdoll() then continue end
		ent.pushCooldown = ent.pushCooldown or 0
		if ent.pushCooldown < CurTime() then
			if ply:GetVelocity():Length() > 200 then
				ViewPunch(Angle(15,math.random(-1,1),0))
			end
		end
		ent.pushCooldown = CurTime() + 0.1
    end
end)
