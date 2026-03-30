EFFECT.Material = Material("particle/water/waterdrop_001a_refract")
EFFECT.Color = Color(255, 255, 255)
EFFECT.Width = 4

local BulletsMinDistance = 5
local SmokeMaterial = Material("particle/particle_smokegrenade")
local CoreMaterial = Material("effects/laser_tracer")
local WhiteSmoke = Color(205, 205, 205)
local WhiteCore = Color(195, 192, 186)
local math_Clamp = math.Clamp
local CurTime = CurTime
local max = math.max

local tracer = {
	TracerBody = Material("particle/fire"),
	TracerTail = Material("effects/laser_tracer"),
	TracerHeadSize = 1,
	TracerLength = 150,
	TracerWidth = 1.5,
	TracerColor = Color(255, 215, 155),
	TracerTPoint1 = 0.25,
	TracerTPoint2 = 1,
	TracerSpeed = 25000
}

function EFFECT:Init(data)
    local gun = data:GetEntity()
    self.gun = gun
    local ammotype = string.lower( string.Replace( gun.Primary and gun.Primary.Ammo or "nil"," ", "") )
    self.bullet = (hg.ammotypes[ammotype] and hg.ammotypes[ammotype].TracerSetings) or tracer
    self.Speed = self.bullet.TracerSpeed or 25000
    
    self.EndPos = data:GetOrigin()

    self.magnitude = data:GetMagnitude()
    local fireinthehole = IsValid(gun) and (math.Round(self.magnitude) == 1)
    
    local trace = gun.GetTrace and gun:GetTrace(true, nil, nil, true)
    --if not (fireinthehole and gun.GetTrace and trace) then return end
    
    local mpos = ((fireinthehole and gun.GetTrace) and trace) or data:GetStart()
    
    if !mpos then self:Remove() return end

    self.TrueLength = (mpos - self.EndPos):Length()
    self.StartPos = mpos + ((self.EndPos - mpos):GetNormalized() * BulletsMinDistance)

    if self.TrueLength <= BulletsMinDistance then
        self.DieTime = 0
    end

    self.SpawnTime = CurTime()
    self.Length = (self.StartPos - self.EndPos):Length()
    self.TravelEndTime = self.SpawnTime + (self.Length / self.Speed)
    self.SmokeFadeTime = math_Clamp(self.Length / self.Speed * 1.2, 0.045, 0.095)
    self.DieTime = self.TravelEndTime + self.SmokeFadeTime
    self:SetRenderBoundsWS(self.StartPos, self.EndPos)

    local bullet = self.bullet
    
    local dlight = DynamicLight(self:EntIndex())
    if dlight then
		dlight.pos = self.StartPos
		dlight.r = 225
		dlight.g = 220
		dlight.b = 210
		dlight.brightness = 1
		dlight.Decay = 1
		dlight.Size = max(bullet.TracerHeadSize, 1)
		dlight.DieTime = self.DieTime
    end
    
    self.dlight = dlight
end

function EFFECT:Think()
    return (self.DieTime or 0) > CurTime()
end

function EFFECT:Render()
    local bullet = self.bullet
    local fireinthehole = IsValid(self.gun) and (math.Round(self.magnitude) == 1)
    if fireinthehole and self.gun.GetMuzzleAtt then self.StartPos = (self.gun.GetTrace and select(2, self.gun:GetTrace(nil, nil, nil, true))) or self.StartPos end
    if not self.SpawnTime or not self.DieTime then return end
    local now = CurTime()
    local travelDur = max((self.TravelEndTime or self.DieTime) - self.SpawnTime, 0.0001)
    local totalDur = max(self.DieTime - self.SpawnTime, 0.0001)
    local delta = math_Clamp((now - self.SpawnTime) / travelDur, 0, 1)
    local fade = 1 - math_Clamp((now - self.SpawnTime) / totalDur, 0, 1)
    local smokeFade = 1 - math_Clamp((now - (self.TravelEndTime or self.DieTime)) / max(self.SmokeFadeTime or 0.05, 0.0001), 0, 1)
    if now <= (self.TravelEndTime or self.DieTime) then
        smokeFade = 1
    end
    fade = fade * fade * (3 - 2 * fade)
    local startbeampos = Lerp(delta, self.StartPos, self.EndPos)
    local endbeampos = Lerp(math_Clamp(delta + (bullet.TracerLength / max(self.Length, 1) / 2), 0, 1), self.StartPos, self.EndPos)
    
    local width = bullet.TracerWidth
    local headsize = bullet.TracerHeadSize

    WhiteSmoke.a = 90 * fade * smokeFade
    WhiteCore.a = 65 * fade

    if WhiteSmoke.a > 0 then
        render.SetMaterial(SmokeMaterial)
        render.DrawBeam(startbeampos, endbeampos, width * 3.75, 0, 1, WhiteSmoke)
        render.DrawSprite(endbeampos, headsize * 3.2, headsize * 3.2, WhiteSmoke)
    end

    if WhiteCore.a > 0 then
        render.SetMaterial(CoreMaterial)
        render.DrawBeam(startbeampos, endbeampos, width * 1.1, bullet.TracerTPoint2, bullet.TracerTPoint1, WhiteCore)
    end
    if self.dlight then
        self.dlight.pos = endbeampos
    end
end
