local maps = {}
local time = 0
local votes = {}
local blacklistedMaps = {}
local winmap = ""
local rtvStarted = false
local rtvEnded = false
local activeRTVMenu

local VoteCD = 0
local maxChoices = 8
local placeholderIconA = Material("vgui/wii_moves")
local placeholderIconB = Material("vgui/wii_moves.png")

local function GetPlaceholderIcon()
    if placeholderIconA and not placeholderIconA:IsError() then
        return placeholderIconA
    end
    if placeholderIconB and not placeholderIconB:IsError() then
        return placeholderIconB
    end
    return Material("icon64/tool.png")
end

local function FormatMapName(mapName)
    if mapName == "random" then
        return "Random Map"
    end

    local parts = string.Explode("_", tostring(mapName))
    if #parts > 1 then
        table.remove(parts, 1)
    end

    if #parts == 0 then
        parts = {tostring(mapName)}
    end

    for i = 1, #parts do
        local part = parts[i]
        if part and part ~= "" then
            parts[i] = string.upper(string.Left(part, 1)) .. string.sub(part, 2)
        end
    end

    return table.concat(parts, " ")
end

function zb.RTVMenu()
    system.FlashWindow()

    if IsValid(activeRTVMenu) then
        activeRTVMenu:Remove()
    end

    local RTVMenu = vgui.Create("ZB_RTVMenu")
    RTVMenu:SetSize(ScrW(), ScrH())
    RTVMenu:SetPos(0, 0)
    RTVMenu:SetTitle("")
    RTVMenu:SetBackgroundBlur(false)
    RTVMenu:ShowCloseButton(false)
    RTVMenu:SetDraggable(false)
    RTVMenu:MakePopup()
    RTVMenu:SetKeyboardInputEnabled(true)
    RTVMenu:SetAlpha(0)
    RTVMenu:AlphaTo(255, 0.25, 0)
    activeRTVMenu = RTVMenu

    local sidePanel = vgui.Create("DPanel", RTVMenu)
    sidePanel:SetSize(ScrW() * 0.27, ScrH() * 0.67)
    sidePanel:SetPos(ScrW() * 0.06, ScrH() * 0.2)
    sidePanel.Paint = function(_, w, h)
        surface.SetDrawColor(8, 8, 8, 210)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(48, 48, 48, 190)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end

    local function PickFontForWidth(text, maxWidth, fontA, fontB)
        surface.SetFont(fontA)
        if surface.GetTextSize(text) <= maxWidth then
            return fontA
        end
        return fontB
    end

    local sideTitle = vgui.Create("DPanel", sidePanel)
    sideTitle:Dock(TOP)
    sideTitle:DockMargin(16, 18, 16, 6)
    sideTitle:SetTall(36)
    sideTitle.Paint = function(_, w, h)
        local txt = "VOTE CONTROL"
        local font = PickFontForWidth(txt, w - 2, "ZCity_Veteran", "ZCity_Small")
        surface.SetFont(font)
        surface.SetTextColor(212, 212, 212, 255)
        local _, th = surface.GetTextSize(txt)
        surface.SetTextPos(0, math.floor((h - th) * 0.5))
        surface.DrawText(txt)
    end

    local timerLabel = vgui.Create("DPanel", sidePanel)
    timerLabel:Dock(TOP)
    timerLabel:DockMargin(16, 0, 16, 12)
    timerLabel:SetTall(30)
    timerLabel.Paint = function(_, w, h)
        local left = math.max(0, math.ceil(time - CurTime()))
        local txt = "TIME LEFT: " .. left .. "s"
        local font = "ZCity_Veteran"
        surface.SetFont(font)
        if surface.GetTextSize(txt) > (w - 2) then
            txt = "TIME: " .. left .. "s"
            font = PickFontForWidth(txt, w - 2, "ZCity_Veteran", "ZCity_Small")
        end
        surface.SetFont(font)
        surface.SetTextColor(170, 170, 170, 255)
        local _, th = surface.GetTextSize(txt)
        surface.SetTextPos(0, math.floor((h - th) * 0.5))
        surface.DrawText(txt)
    end

    local previewName = "Hover a map"
    local previewIcon = GetPlaceholderIcon()
    local previewMap = ""

    local function WrapPreviewText(text, font, maxWidth, maxLines)
        text = tostring(text or "")
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
                    local trim = lines[#lines] ~= "" and lines[#lines] or word
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

    local showcase = vgui.Create("DPanel", sidePanel)
    showcase:Dock(FILL)
    showcase:DockMargin(16, 8, 16, 12)
    showcase.Paint = function(_, w, h)
        surface.SetDrawColor(12, 12, 12, 220)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(55, 55, 55, 200)
        surface.DrawOutlinedRect(0, 0, w, h, 2)

        if previewIcon and not previewIcon:IsError() then
            local imgW = w - 20
            local imgH = math.floor(h * 0.62)
            surface.SetDrawColor(255, 255, 255, 240)
            surface.SetMaterial(previewIcon)
            surface.DrawTexturedRect(10, 10, imgW, imgH)
            surface.SetDrawColor(0, 0, 0, 85)
            surface.DrawRect(10, 10 + imgH - 30, imgW, 30)
        end

        local titleFont = "ZCity_Veteran"
        local titleMaxW = w - 28
        local titleLines = WrapPreviewText(previewName, titleFont, titleMaxW, 3)
        surface.SetFont(titleFont)
        local _, titleH = surface.GetTextSize("A")
        local textY = math.floor(h * 0.68)

        surface.SetTextColor(220, 220, 220, 250)
        for i = 1, #titleLines do
            local line = titleLines[i] or ""
            if line ~= "" then
                surface.SetTextPos(14, textY + (i - 1) * (titleH + 2))
                surface.DrawText(line)
            end
        end

        if previewMap ~= "" then
            local mapFont = "ZCity_Tiny"
            surface.SetTextColor(155, 155, 155, 220)
            local mapLine = string.upper(previewMap)
            local mapLines = WrapPreviewText(mapLine, mapFont, w - 28, 2)
            surface.SetFont(mapFont)
            local _, mapH = surface.GetTextSize("A")
            local mapY = textY + (#titleLines * (titleH + 2)) + 6
            for i = 1, #mapLines do
                local line = mapLines[i] or ""
                if line ~= "" then
                    surface.SetTextPos(14, mapY + (i - 1) * (mapH + 1))
                    surface.DrawText(line)
                end
            end
        end
    end

    local function SetPreview(mapName, displayName, mapIcon)
        previewName = displayName or mapName or "Unknown"
        previewMap = mapName or ""
        if mapIcon and not mapIcon:IsError() then
            previewIcon = mapIcon
        else
            previewIcon = GetPlaceholderIcon()
        end
    end

    local closeBtn = vgui.Create("DButton", sidePanel)
    closeBtn:Dock(BOTTOM)
    closeBtn:DockMargin(16, 12, 16, 16)
    closeBtn:SetTall(36)
    closeBtn:SetText("EXIT")
    closeBtn:SetFont("ZCity_Veteran")
    closeBtn:SetTextColor(Color(215, 215, 215))
    closeBtn.Paint = function(self, w, h)
        local hovered = self:IsHovered()
        surface.SetDrawColor(16, 16, 16, hovered and 235 or 215)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(75, 75, 75, hovered and 230 or 185)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end
    closeBtn.DoClick = function()
        if IsValid(RTVMenu) then
            RTVMenu:Remove()
        end
    end

    local mapsHost = vgui.Create("DPanel", RTVMenu)
    mapsHost:SetSize(ScrW() * 0.59, ScrH() * 0.67)
    mapsHost:SetPos(ScrW() * 0.35, ScrH() * 0.2)
    mapsHost.Paint = function(_, w, h)
        surface.SetDrawColor(8, 8, 8, 185)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(45, 45, 45, 160)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end

    local mapsPanel = vgui.Create("DScrollPanel", mapsHost)
    mapsPanel:Dock(FILL)
    mapsPanel:DockMargin(12, 12, 12, 12)
    mapsPanel:GetVBar():SetWide(7)
    mapsPanel:GetVBar().Paint = function(_, w, h)
        surface.SetDrawColor(15, 15, 15, 190)
        surface.DrawRect(0, 0, w, h)
    end
    mapsPanel:GetVBar().btnUp.Paint = function() end
    mapsPanel:GetVBar().btnDown.Paint = function() end
    mapsPanel:GetVBar().btnGrip.Paint = function(_, w, h)
        surface.SetDrawColor(82, 82, 82, 215)
        surface.DrawRect(0, 0, w, h)
    end

    local mapGrid = vgui.Create("DIconLayout", mapsPanel)
    mapGrid:Dock(TOP)
    mapGrid:SetSpaceX(10)
    mapGrid:SetSpaceY(10)

    if not istable(maps) then
        maps = {}
    end

    local displayMaps = {}
    for _, mapName in ipairs(maps) do
        if #displayMaps >= maxChoices then break end
        table.insert(displayMaps, mapName)
    end

    local mapAreaWidth = mapsHost:GetWide() - 24 - mapsPanel:GetVBar():GetWide()
    local columns = mapAreaWidth >= 980 and 3 or (mapAreaWidth >= 560 and 2 or 1)
    local mapCardWidth = math.floor((mapAreaWidth - ((columns - 1) * 10)) / columns)
    local mapCardHeight = math.max(82, ScrH() * 0.12)
    local didSetPreview = false

    for _, v in ipairs(displayMaps) do
        local MapButton = vgui.Create("ZB_RTVButton", mapGrid)
        MapButton:SetSize(mapCardWidth, mapCardHeight)
        MapButton:SetFont("ZCity_Veteran")
        MapButton:SetText("")
        mapGrid:Add(MapButton)
        
        if v == "random" then
            MapButton.DisplayName = "Random Map"
            MapButton.Map = "random"
            MapButton.MapIcon = Material("icon64/random.png")
            if MapButton.MapIcon:IsError() then
                MapButton.MapIcon = GetPlaceholderIcon()
            end
        else
            MapButton.DisplayName = FormatMapName(v)
            MapButton.Map = v
            MapButton.MapIcon = Material("maps/thumb/" .. MapButton.Map .. ".png")
            if MapButton.MapIcon:IsError() then
                MapButton.MapIcon = GetPlaceholderIcon()
            end
        end

        if not didSetPreview then
            SetPreview(MapButton.Map, MapButton.DisplayName, MapButton.MapIcon)
            didSetPreview = true
        end

        MapButton.Blacklisted = (MapButton.Map ~= "random" and blacklistedMaps[MapButton.Map]) or false
        MapButton:Disabled(MapButton.Blacklisted)

        MapButton.OnPreviewHover = function(self)
            SetPreview(self.Map, self.DisplayName, self.MapIcon)
        end

        function MapButton:Think()
            self.Votes = votes[self.Map] or 0
            if self.Map ~= "random" and self.Map == winmap then 
                self.Win = true 
            else 
                self.Win = false 
            end
        end

        function MapButton:DoClick()
            if VoteCD > CurTime() then return end
            if self.Blacklisted then return end
            SetPreview(self.Map, self.DisplayName, self.MapIcon)
            net.Start("ZB_RockTheVote_vote")
                net.WriteString(self.Map)
            net.SendToServer()
            VoteCD = CurTime() + 1
        end
    end

    mapGrid:SizeToChildren(false, true)

    if #displayMaps == 0 then
        local empty = vgui.Create("DLabel", mapGrid)
        empty:SetSize(mapsHost:GetWide() - 24, 48)
        empty:Dock(TOP)
        empty:SetFont("ZCity_Veteran")
        empty:SetTextColor(Color(165, 165, 165))
        empty:SetText("No maps available right now.")
        empty:SetContentAlignment(5)
    end
end

function zb.StartRTV()
    local incomingMaps = net.ReadTable()
    if istable(incomingMaps) then
        maps = {}
        for i = 1, math.min(#incomingMaps, maxChoices) do
            maps[i] = incomingMaps[i]
        end
    else
        maps = {}
    end
    time = net.ReadFloat()
    local incomingBlacklist = net.ReadTable()
    blacklistedMaps = istable(incomingBlacklist) and incomingBlacklist or {}
    votes = {}
    winmap = ""
    rtvEnded = false
    zb.RTVMenu()
    rtvStarted = true
end

net.Receive("RTVMenu", function()
    local hasData = net.ReadBool()
    if hasData then
        local incomingMaps = net.ReadTable()
        if istable(incomingMaps) then
            maps = {}
            for i = 1, math.min(#incomingMaps, maxChoices) do
                maps[i] = incomingMaps[i]
            end
        end
        time = net.ReadFloat()
        local incomingBlacklist = net.ReadTable()
        blacklistedMaps = istable(incomingBlacklist) and incomingBlacklist or blacklistedMaps
    end
    zb.RTVMenu()
end)

function zb.RTVregVote()
    votes = net.ReadTable()
end

function zb.EndRTV()
    winmap = net.ReadString()
    rtvEnded = true
end

net.Receive("ZB_RockTheVote_start", zb.StartRTV)
net.Receive("ZB_RockTheVote_voteCLreg", zb.RTVregVote)
net.Receive("ZB_RockTheVote_end", zb.EndRTV)
