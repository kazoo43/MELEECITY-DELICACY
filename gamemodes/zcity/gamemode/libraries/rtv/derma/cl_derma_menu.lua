local PANEL = {}

BlurBackground = hg.DrawBlur

local pickmanA = Material("vgui/pickman.png", "noclamp smooth")
local pickmanB = Material("vgui/pickman", "noclamp smooth")
local pickmanTextureID = surface.GetTextureID("vgui/pickman")

function PANEL:Init()
    self.OpenTime = CurTime()
    self.FadeTime = 0.35
    self.ShakeSeed = math.Rand(0, 512)
end

function PANEL:GetPickmanMaterial()
    if pickmanA and not pickmanA:IsError() then
        return pickmanA
    end
    if pickmanB and not pickmanB:IsError() then
        return pickmanB
    end
    return nil
end

function PANEL:Paint(w, h)
    local t = math.Clamp((CurTime() - self.OpenTime) / self.FadeTime, 0, 1)
    local a = 120 * t

    local shakeX = math.sin((CurTime() * 4.8) + self.ShakeSeed) * 2
    local shakeY = math.cos((CurTime() * 5.3) + self.ShakeSeed) * 2

    surface.SetDrawColor(0, 0, 0, a)
    surface.DrawRect(0, 0, w, h)

    local bgMat = self:GetPickmanMaterial()
    if bgMat then
        surface.SetMaterial(bgMat)
        surface.SetDrawColor(255, 255, 255, 255 * t)
        surface.DrawTexturedRect(shakeX - 32, shakeY - 32, w + 64, h + 64)
    elseif pickmanTextureID and pickmanTextureID > 0 then
        surface.SetTexture(pickmanTextureID)
        surface.SetDrawColor(255, 255, 255, 255 * t)
        surface.DrawTexturedRect(shakeX - 32, shakeY - 32, w + 64, h + 64)
    end

    surface.SetDrawColor(4, 4, 4, 46 * t)
    surface.DrawRect(0, 0, w, h)

    surface.SetDrawColor(0, 0, 0, 24 * t)
    surface.DrawRect(0, 0, w, h)

    surface.SetDrawColor(70, 70, 70, 160 * t)
    surface.DrawRect(0, 0, w, 2)
    surface.DrawRect(0, h - 2, w, 2)
    surface.DrawRect(0, 0, 2, h)
    surface.DrawRect(w - 2, 0, 2, h)

    local title = "ROCK THE VOTE"
    surface.SetFont("ZC_MM_Title")
    surface.SetTextColor(220, 220, 220, 255 * t)
    local tw, th = surface.GetTextSize(title)
    surface.SetTextPos((w - tw) * 0.5, h * 0.055)
    surface.DrawText(title)

    local subtitle = "SELECT THE NEXT MAP"
    surface.SetFont("ZCity_Veteran")
    surface.SetTextColor(140, 140, 140, 210 * t)
    local sw, _ = surface.GetTextSize(subtitle)
    surface.SetTextPos((w - sw) * 0.5, h * 0.055 + th + 4)
    surface.DrawText(subtitle)
end

vgui.Register("ZB_RTVMenu", PANEL, "ZFrame")
