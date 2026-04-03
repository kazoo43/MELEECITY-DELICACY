if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "SOG SEAL 2000"
SWEP.Instructions = "A serious big knife used by seals (special forces of the US Navy). A good choice for a melee weapon.\n\nLMB to attack.\nR + LMB to change attack mode.\nRMB to block."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/weapons/combatknife/tactical_knife_iw7_wm.mdl"
SWEP.WorldModelReal = "models/weapons/gleb/c_knife_t.mdl"
SWEP.WorldModelExchange = "models/zcity/weapons/w_sog_knife.mdl"
SWEP.DontChangeDropped = true
SWEP.modelscale = 1.4
SWEP.modelscale2 = 1

SWEP.SuicidePos = Vector(16, -1, -3)
SWEP.SuicideAng = Angle(-40, 180, 0)
SWEP.SuicideCutVec = Vector(1, -5, 4)
SWEP.SuicideCutAng = Angle(10, 0, 0)
SWEP.SuicideTime = 0.5
SWEP.CanSuicide = true

SWEP.BleedMultiplier = 1.5
SWEP.PainMultiplier = 1.8

SWEP.DamagePrimary = 25
SWEP.DamageSecondary = 10

SWEP.setlh = false
SWEP.setrh = true
SWEP.TwoHanded = false

SWEP.basebone = 76

SWEP.HoldPos = Vector(-2,-5,-5)
SWEP.HoldAng = Angle(-15,20,-10)

SWEP.AttackPos = Vector(0,0,0)
SWEP.AttackingPos = Vector(0,0,0)

SWEP.weaponPos = Vector(-3.5,0,0)
SWEP.weaponAng = Angle(90,180,0)

SWEP.HoldType = "knife"

--SWEP.InstantPainMul = 0.25

--models/weapons/gleb/c_knife_t.mdl
if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_knife")
	SWEP.IconOverride = "vgui/wep_jack_hmcd_knife.png"
	SWEP.BounceWeaponIcon = false
end

SWEP.BreakBoneMul = 0.5
SWEP.ImmobilizationMul = 0.45
SWEP.StaminaMul = 0.5
SWEP.HadBackBonus = true

SWEP.attack_ang = Angle(0,0,0)
function SWEP:Initialize()
    self.attackanim = 0
    self.sprintanim = 0
    self.animtime = 0
    self.animspeed = 1
    self.reverseanim = false
    self.Initialzed = true
    self:PlayAnim("idle",10,true)

    self:SetHold(self.HoldType)

    self:InitAdd()
end

SWEP.AttackTime = 0.50
SWEP.AnimTime1 = 1.60
SWEP.WaitTime1 = 0.90

SWEP.AnimTime2 = 2
SWEP.WaitTime2 = 2
SWEP.CanHeavyAttack = true -- Set to true to enable
SWEP.NeckBreakChance = 0.01
SWEP.NoReverse = true

SWEP.HeavyAttackDamageMul = 6.0 -- Max damage multiplier at full charge
SWEP.HeavyAttackWaitTime = 1.9 -- Time before you can attack again
SWEP.HeavyAttackAnimTimeBegin = 3.0 -- Duration of the wind-up/start animation
SWEP.HeavyAttackAnimTimeIdle = 3 -- Duration of the idle loop
SWEP.HeavyAttackAnimTimeEnd = 1.90 -- Duration of the attack animation
SWEP.HeavyAttackDelay = 0.5 -- Time delay before the hit actually connects (during attack anim)
SWEP.HeavyAttackTimeLength = 0.4 -- Duration of the active hit window
SWEP.HeavyAttackViewPunch = Angle(9, 0, 0) -- View punch angle on hit
SWEP.HeavyAttackMaxChargeTime = 2.0 -- Time in seconds to reach max damage/shake
SWEP.HeavyAttackSwingAng = -90 -- Custom swing angle for heavy attack
SWEP.HeavyAttackRads = 95 -- Custom radius/arc for heavy attack


SWEP.AnimList = {
    ["idle"] = "idle",
    ["deploy"] = "draw",
    ["attack"] = "stab",
    ["attack2"] = "midslash1",
}

SWEP.BlockTier = 2
SWEP.MeleeMaterial = "metal"
SWEP.BlockImpactSound = "physics/metal/metal_solid_impact_bullet1.wav"

function SWEP:Reload()
    if SERVER then
        if self:GetOwner():KeyPressed(IN_ATTACK) then
            self:SetNetVar("mode", not self:GetNetVar("mode"))
            self:GetOwner():ChatPrint("Changed mode to "..(self:GetNetVar("mode") and "slash." or "stab."))
        end
    end
end

function SWEP:CanPrimaryAttack()
    if self:GetOwner():KeyDown(IN_RELOAD) then return end
    if not self:GetNetVar("mode") then
        return true
    else
        self.allowsec = true
        self:SecondaryAttack(true)
        self.allowsec = nil
        return false
    end
end

function SWEP:CustomBlockAnim(addPosLerp, addAngLerp)
    addPosLerp.z = addPosLerp.z + (self:GetBlocking() and -4 or 0)
    addPosLerp.x = addPosLerp.x + (self:GetBlocking() and 15 or 0)
    addPosLerp.y = addPosLerp.y + (self:GetBlocking() and -7 or 0)
    addAngLerp.r = addAngLerp.r + (self:GetBlocking() and 60 or 0)
    addAngLerp.y = addAngLerp.y + (self:GetBlocking() and 90 or 0)
	addAngLerp.x = addAngLerp.x + (self:GetBlocking() and -60 or 0)
    
    return true
end

function SWEP:CanSecondaryAttack()
    return self.allowsec and true or false
end

SWEP.AttackTimeLength = 0.15
SWEP.Attack2TimeLength = 0.1

SWEP.AttackRads = 35
SWEP.AttackRads2 = 45

SWEP.SwingAng = -90
SWEP.SwingAng2 = 0

SWEP.MultiDmg1 = false
SWEP.MultiDmg2 = true
