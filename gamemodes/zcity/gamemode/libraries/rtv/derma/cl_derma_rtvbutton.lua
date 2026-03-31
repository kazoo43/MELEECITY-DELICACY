local PANEL = {}

local blurMat = Material("pp/blurscreen")
local Dynamic = 0

BlurBackground = BlurBackground or hg.DrawBlur

local function WrapTextLimited(text, font, maxWidth, maxLines)
    text = tostring(text or "")
    if text == "" then
        return {""}
    end

    surface.SetFont(font)
    local words = string.Explode(" ", text)
    local lines = {""}

    for _, word in ipairs(words) do
        local line = lines[#lines]
        local candidate = line == "" and word or (line .. " " .. word)
        local cw = surface.GetTextSize(candidate)
        if cw <= maxWidth then
            lines[#lines] = candidate
        else
            if #lines < maxLines then
                lines[#lines + 1] = word
            else
                local trim = lines[#lines]
                if trim == "" then
                    trim = word
                end
                while #trim > 0 and surface.GetTextSize(trim) > maxWidth do
                    trim = string.sub(trim, 1, -2)
                end
                lines[#lines] = trim
                break
            end
        end
    end

    return lines
end

function PANEL:Init()
    self.Map = ""
    self.Votes = 0
    self.lerp = 0
    self.BipCD = 0
    
    self.hovered = false
    self.alpha = 0
    self.setalpha = 0
    self:SetFont("ZCity_Veteran")
	self:SetPaintBackground(false)
	self:SetContentAlignment(5)
    self:SetTextColor(color_white)

    self.disabled = false
    self.selected = false
end


function PANEL:Paint(w, h)
    if self.MapIcon then
        surface.SetDrawColor(255, 255, 255, 40)
        surface.SetMaterial(self.MapIcon)
        surface.DrawTexturedRect(-12, -12, w + 24, h + 24)
    end

    surface.SetDrawColor(10, 10, 10, 220)
    surface.DrawRect(0, 0, w, h)

    surface.SetDrawColor(2, 2, 2, 120)
    surface.DrawRect(0, h * 0.5, w, h * 0.5)

    local outlineR = self.hovered and 235 or 170
    local outlineA = self.hovered and 220 or 165
    surface.SetDrawColor(outlineR, outlineR, outlineR, outlineA)
    surface.DrawOutlinedRect(0, 0, w, h, 2)

    local plyCount = math.max(player.GetCount(), 1)
    self.lerp = Lerp(FrameTime() * 7, self.lerp, w * math.Clamp(self.Votes / plyCount, 0, 1))

    surface.SetDrawColor(225, 225, 225, 95)
    surface.DrawRect(0, 0, self.lerp, h)

    if self.Win and self.BipCD < CurTime() then
        self.alpha = 255
        surface.PlaySound("buttons/blip1.wav")
        self.BipCD = CurTime() + 1
        self:CreateAnimation(0.5, {
            index = 1,
            target = {
                alpha = 0
            },
            easing = "inExpo",
            bIgnoreConfig = true
        })
    end

    surface.SetDrawColor(255, 255, 255, self.alpha)
    surface.DrawRect(0, 0, w, h)
    
    local mapText = self.DisplayName or self.Map or ""
    local font = "ZCity_Veteran"
    local textMaxW = math.max(70, w - 28)
    local lines = WrapTextLimited(mapText, font, textMaxW, 3)
    if #lines >= 3 then
        local firstW = surface.GetTextSize(lines[1] or "")
        local secondW = surface.GetTextSize(lines[2] or "")
        local thirdW = surface.GetTextSize(lines[3] or "")
        if firstW > textMaxW or secondW > textMaxW or thirdW > textMaxW then
            font = "ZCity_Tiny"
            lines = WrapTextLimited(mapText, font, textMaxW, 3)
        end
    end
    surface.SetFont(font)
    local _, lineH = surface.GetTextSize("A")
    local linesCount = math.max(#lines, 1)
    local totalH = lineH * linesCount + (linesCount - 1) * 2
    local textY = math.max(8, (h - totalH) * 0.5 - 6)

    surface.SetTextColor(220, 220, 220, 245)
    for i = 1, linesCount do
        local line = lines[i] or ""
        if line ~= "" then
            surface.SetTextPos(14, textY + (i - 1) * (lineH + 2))
            surface.DrawText(line)
        end
    end

    local voteText = tostring(self.Votes) .. " votes"
    surface.SetFont("ZCity_Tiny")
    local voteW, voteH = surface.GetTextSize(voteText)
    surface.SetTextColor(185, 185, 185, 230)
    surface.SetTextPos(w - voteW - 10, h - voteH - 8)
    surface.DrawText(voteText)

    if self.Blacklisted then
        surface.SetDrawColor(0, 0, 0, 160)
        surface.DrawRect(0, 0, w, h)
        local msg = "Map is blacklisted"
        surface.SetFont("ZCity_Small")
        local mw, mh = surface.GetTextSize(msg)
        surface.SetTextColor(255, 255, 255, 245)
        surface.SetTextPos((w - mw) * 0.5, (h - mh) * 0.5)
        surface.DrawText(msg)
    end
end

function PANEL:OnCursorEntered()
    if self.disabled then return end
    self:CreateAnimation(0.1, {
        index = 1,
        target = {
            alpha = 155
        },
        easing = "inExpo",
        bIgnoreConfig = true
    })
    self.hovered = true
    if isfunction(self.OnPreviewHover) then
        self:OnPreviewHover()
    end
end

function PANEL:OnCursorExited()
    if self.selected then return end

    self:CreateAnimation(0.3, {
        index = 1,
        target = {
            alpha = self.setalpha
        },
        easing = "outExpo",
        bIgnoreConfig = true
    })
    self.hovered = false
end

function PANEL:SetSelected(value)
    self.selected = value
    if value then self:OnCursorEntered()
    else self:OnCursorExited() end
end

function PANEL:Disabled(bool)
    self.disabled = bool
    if bool then
        self:SetTextColor(Color(255, 255, 255, 50))
        self:SetCursor("arrow")
    else
        self:SetTextColor(color_white)
        self:SetCursor("hand")
    end
end

vgui.Register("ZB_RTVButton", PANEL, "DButton")
