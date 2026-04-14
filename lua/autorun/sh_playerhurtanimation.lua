local netName = "PlayerHurtAnimation_XN"

if SERVER then

util.AddNetworkString(netName)

CreateConVar("XN_PlayerHurtAnimation", 1, FCVAR_ARCHIVE)
CreateConVar("XN_HurtAnimation_MinimumInterval", 1, FCVAR_ARCHIVE)
CreateConVar("XN_HurtAnimation_MaximumInterval", 3, FCVAR_ARCHIVE)

local AddonEnabled = GetConVarNumber("XN_PlayerHurtAnimation") == 1
local minInterval = math.max(GetConVarNumber("XN_HurtAnimation_MinimumInterval"), 0)
local maxInterval = math.max(GetConVarNumber("XN_HurtAnimation_MinimumInterval"), minInterval)

local Alive = Alive
local CurTime = CurTime
local GetDamageType = GetDamageType
local IsPlayer = IsPlayer
local IsBulletDamage = IsBulletDamage
local math_Rand = math.Rand

local TargetDmgType = {
	[DMG_BLAST] = true,
	[DMG_CLUB] = true,
	[DMG_SLASH] = true,
	[DMG_CRUSH] = true,
	[DMG_PREVENT_PHYSICS_FORCE] = true,
	[DMG_ACID] = true,
	[DMG_MISSILEDEFENSE] = true,
	[DMG_GENERIC] = true,
	[DMG_ENERGYBEAM] = true,
	[DMG_DISSOLVE] = true,
	[67112960] = true
}

local function PlayerGetHurt(ply,dmginfo)
	if AddonEnabled and ply:IsPlayer() and ply:Alive() then
		local NextAnimTime = ply.NextHurtAnimation_XN or 0
		if NextAnimTime < CurTime() and (dmginfo:IsBulletDamage() or TargetDmgType[dmginfo:GetDamageType()]) then
			ply.NextHurtAnimation_XN = CurTime() + math_Rand(minInterval, maxInterval)
			net.Start(netName)
			net.WritePlayer(ply)
			net.WriteInt(ply:LastHitGroup(), 5)
			net.Broadcast()
		end
	end
end
hook.Add("EntityTakeDamage", "SendPlayerHitgroup_XN", PlayerGetHurt)

local function ConvarsManager()
	AddonEnabled = GetConVarNumber("XN_PlayerHurtAnimation") == 1
	minInterval = math.max(GetConVarNumber("XN_HurtAnimation_MinimumInterval"), 0)
	maxInterval = math.max(GetConVarNumber("XN_HurtAnimation_MaximumInterval"), minInterval)
end
cvars.AddChangeCallback("XN_PlayerHurtAnimation", ConvarsManager)
cvars.AddChangeCallback("XN_HurtAnimation_MinimumInterval", ConvarsManager)
cvars.AddChangeCallback("XN_HurtAnimation_MaximumInterval", ConvarsManager)

end

--------------------------------------------------- 分割线 ---------------------------------------------------

if CLIENT then

local HitgroupToSeq = {
	[HITGROUP_HEAD] = { name = "flinch_head_0", num = 2 },
	[HITGROUP_CHEST] = { name = "flinch_phys_0", num = 2 },
	[HITGROUP_STOMACH] = { name = "flinch_stomach_0", num = 2 },
	[HITGROUP_LEFTARM] = { name = "flinch_shoulder_l" },
	[HITGROUP_RIGHTARM] = { name = "flinch_shoulder_r" }
}

local OtherSeq = {
	[1] = "flinch_01",
	[2] = "flinch_02",
	[3] = "flinch_back_01"
}

net.Receive(netName, function()
	local ply = net.ReadPlayer()
	if IsValid(ply) and ply:Alive() then
		local SeqID = -1
		local seq = HitgroupToSeq[net.ReadInt(5)]
		if seq then
			if seq.num then
				SeqID = ply:LookupSequence(seq.name .. math.random(1,seq.num))
			else
				SeqID = ply:LookupSequence(seq.name)
			end
		else
			SeqID = ply:LookupSequence(OtherSeq[math.random(1,3)])
		end
		
		if SeqID != -1 then
			ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_FLINCH, SeqID, 0, true)
		end
	end
end)

end