
local PANEL = {}

local red_select = Color(200,200,200)


local THEME = {
    bg_dark = Color(8, 8, 12, 245),
    bg_panel = Color(12, 12, 18, 230),
    bg_card = Color(18, 18, 25, 200),
    border = Color(60, 60, 75, 120),
    border_bright = Color(100, 100, 120, 180),
    text_primary = Color(235, 235, 240),
    text_secondary = Color(160, 160, 175),
    text_dim = Color(120, 120, 135),
    accent_red = Color(200, 50, 50),
    accent_red_glow = Color(255, 70, 70, 80),
    accent_white = Color(255, 255, 255),
    hover_bg = Color(255, 255, 255, 25),
    hover_border = Color(255, 255, 255, 100),
    selected_bg = Color(200, 50, 50, 60),
    selected_border = Color(200, 50, 50, 150),
    gradient_top = Color(25, 25, 35, 200),
    gradient_bottom = Color(10, 10, 15, 220),
    progress_bg = Color(30, 30, 40, 180),
    progress_fill = Color(200, 50, 50, 180),
    slider_fill = Color(200, 50, 50, 200),
    slider_bg = Color(20, 20, 30, 200),
    scrollbar_bg = Color(0, 0, 0, 100),
    scrollbar_grip = Color(80, 80, 100, 180),
    scrollbar_grip_hover = Color(120, 120, 140, 220),
}

local Selects = {
    {Title = "return", Func = function(luaMenu) luaMenu:Close() end},
    {Title = "settings", Func = function(luaMenu) luaMenu:SwitchToSettings() end},
    {Title = "traitor menu", GamemodeOnly = true, Func = function(luaMenu) luaMenu:SwitchToTraitorMenu() end},
    {Title = "discord", Func = function(luaMenu) luaMenu:Close() gui.OpenURL("https://discord.gg/ZXUCAwuke2")  end},
    {Title = "achievements", Func = function(luaMenu) luaMenu:SwitchToAchievements() end},
    {Title = "appearance", Func = function(luaMenu) luaMenu:SwitchToAppearance() end},
    {Title = "main menu", Func = function(luaMenu) gui.ActivateGameUI() luaMenu:Close() end},
    {Title = "disconnect", Func = function(luaMenu)
        if IsValid(ZCityMainMenuMusic) then ZCityMainMenuMusic:SetVolume(0) end
        if IsValid(ZCityAppearanceMusic) then ZCityAppearanceMusic:SetVolume(0) end

        local fade = vgui.Create("DPanel")
        fade:SetSize(ScrW(), ScrH())
        fade:SetPos(0, 0)
        fade:SetDrawOnTop(true)
        fade:SetAlpha(0)
        fade.Paint = function(s, w, h)
            surface.SetDrawColor(255, 0, 0, 255)
            surface.DrawRect(0, 0, w, h)
        end
        fade:AlphaTo(255, 0.3)

        local lbl = vgui.Create("DLabel", fade)
        lbl:SetText("goodbye.")
        lbl:SetFont("ZC_MM_Title")
        lbl:SetTextColor(Color(255, 255, 255))
        lbl:SizeToContents()
        lbl:Center()
        local cx, cy = lbl:GetPos()
        lbl.Think = function(s)
            s:SetPos(cx + math.random(-2, 2), cy + math.random(-2, 2))
        end

        for i = 1, 3 do
            sound.PlayFile("sound/goodbye.mp3", "noblock", function(station)
                if IsValid(station) then
                    station:SetPlaybackRate(0.9)
                    station:SetVolume(1)
                    station:Play()
                end
            end)
        end

        timer.Simple(2.5, function()
            RunConsoleCommand("disconnect")
        end)
    end},
}

surface.CreateFont("ZCity_Veteran", {
    font = "Veteran Typewriter",
    size = ScreenScaleH(18),
    weight = 500,
    antialias = true
})

surface.CreateFont("ZC_MM_Title", {
    font = "JMH Typewriter",
    size = ScreenScaleH(40),
    weight = 800,
    antialias = true
})
-- local Title = markup.Parse("error")

local Pluv = Material("pluv/pluvkid.jpg")
local LogoMat = Material("vgui/logo.png")
local BgMat = Material("vgui/background.png")
local EyeMat = Material("vgui/eye.png")
local BgMat2 = Material("vgui/background2.png")
local BgMat3 = Material("vgui/background6.png")
local BgMat4 = Material("vgui/pickman.png")
local BgMat4Overlay = Material("vgui/background4.png")
local NoiseMat = Material("vgui/noisevhs")
if NoiseMat:IsError() then
    NoiseMat = Material("vgui/white")
end

local SettingsSelects = {
    -- {Title = "Master Volume", Type = "Slider", Min = 0, Max = 1, CVar = "volume"}, -- Blocked
    -- {Title = "Music Volume", Type = "Slider", Min = 0, Max = 1, CVar = "snd_musicvolume"}, -- Blocked
    -- {Title = "Sensitivity", Type = "Slider", Min = 0.1, Max = 20, CVar = "sensitivity"}, -- Blocked
    {Title = "return", Func = function(luaMenu) luaMenu:SwitchToMain() end}
}

function PANEL:InitializeMarkup()
	local mapname = game.GetMap()
	local prefix = string.find(mapname, "_")
	if prefix then
		mapname = string.sub(mapname, prefix + 1)
	end
	local gm = string.lower(gmod.GetGamemode().Name .. " | " .. string.NiceName(zb ~= nil and zb.GetRoundName or mapname))

    if hg.PluvTown.Active then
        local text = "<font=ZC_MM_Title>meleecity</font>\n<font=ZCity_Small>" .. gm .. "</font>"

        self.SelectedPluv = table.Random(hg.PluvTown.PluvMats)

        return markup.Parse(text)
    end

    local text = "<font=ZC_MM_Title>meleecity</font>\n<font=ZCity_Small>" .. gm .. "</font>"
    return markup.Parse(text)
end

local color_red = Color(90,90,95,120)
local clr_gray = Color(255,255,255,25)
local clr_verygray = Color(10,10,19,235)

-- Helper: draw rounded box with border
local function DrawRoundedBoxWithBorder(x, y, w, h, radius, bgColor, borderColor, borderWidth)
    borderWidth = borderWidth or 1
    if borderColor then
        surface.SetDrawColor(borderColor)
        draw.RoundedBox(radius, x, y, w, h, borderColor)
    end
    draw.RoundedBox(radius, x + borderWidth, y + borderWidth, w - borderWidth * 2, h - borderWidth * 2, bgColor)
end

-- Helper: lerp color
local function LerpColor(t, from, to)
    return Color(
        Lerp(t, from.r, to.r),
        Lerp(t, from.g, to.g),
        Lerp(t, from.b, to.b),
        Lerp(t, from.a or 255, to.a or 255)
    )
end
-- Global variable to persist music across menu opens
ZCityMainMenuMusic = ZCityMainMenuMusic or nil
ZCityAppearanceMusic = ZCityAppearanceMusic or nil
ZCityIntroMusic = ZCityIntroMusic or nil
ZCityHasSeenIntro = ZCityHasSeenIntro or false
ZCityMenuMusicState = ZCityMenuMusicState or {
    mainTime = 0,
    appearanceTime = 0,
    introTime = 0,
    lastRoundState = nil,
    pendingResume = false,
    pendingResumeTime = 0
}

local function ZCityCaptureMenuMusicTimes()
    if IsValid(ZCityMainMenuMusic) then
        local t = ZCityMainMenuMusic:GetTime()
        if isnumber(t) and t >= 0 then
            ZCityMenuMusicState.mainTime = t
        end
    end

    if IsValid(ZCityAppearanceMusic) then
        local t = ZCityAppearanceMusic:GetTime()
        if isnumber(t) and t >= 0 then
            ZCityMenuMusicState.appearanceTime = t
        end
    end

    if IsValid(ZCityIntroMusic) then
        local t = ZCityIntroMusic:GetTime()
        if isnumber(t) and t >= 0 then
            ZCityMenuMusicState.introTime = t
        end
    end
end

local function ZCityResumeMainMusic()
    local seekTime = ZCityMenuMusicState.mainTime or 0

    if IsValid(ZCityMainMenuMusic) then
        ZCityMainMenuMusic:Play()
        if seekTime > 0 then
            ZCityMainMenuMusic:SetTime(seekTime)
        end
        ZCityMainMenuMusic:SetVolume(0.5)
        return
    end

    sound.PlayFile("sound/mainmenu.mp3", "noblock", function(station)
        if not IsValid(station) then return end
        station:EnableLooping(true)
        station:SetVolume(0.5)
        station:Play()
        if seekTime > 0 then
            station:SetTime(seekTime)
        end
        ZCityMainMenuMusic = station
    end)
end

local function ZCityResumeAppearanceMusic()
    local seekTime = ZCityMenuMusicState.appearanceTime or 0

    if IsValid(ZCityAppearanceMusic) then
        ZCityAppearanceMusic:Play()
        if seekTime > 0 then
            ZCityAppearanceMusic:SetTime(seekTime)
        end
        ZCityAppearanceMusic:SetVolume(1)
        return
    end

    sound.PlayFile("sound/sexualdeviants.mp3", "noblock", function(station)
        if not IsValid(station) then return end
        station:EnableLooping(true)
        station:SetVolume(1)
        station:Play()
        if seekTime > 0 then
            station:SetTime(seekTime)
        end
        ZCityAppearanceMusic = station
    end)
end

local function ZCityResumeIntroMusic()
    local seekTime = ZCityMenuMusicState.introTime or 0

    if IsValid(ZCityIntroMusic) then
        ZCityIntroMusic:Play()
        if seekTime > 0 then
            ZCityIntroMusic:SetTime(seekTime)
        end
        return
    end

    sound.PlayFile("sound/itbegins.mp3", "noblock", function(station)
        if not IsValid(station) then return end
        station:Play()
        if seekTime > 0 then
            station:SetTime(seekTime)
        end
        ZCityIntroMusic = station
    end)
end

local function ZCityResumeActiveMenuMusic()
    if not IsValid(MainMenu) then return end

    if MainMenu.IsIntro and MainMenu.IntroSequenceActive then
        ZCityResumeIntroMusic()
        return
    end

    if MainMenu.CurrentState == "Appearance" or MainMenu.TargetState == "Appearance" then
        ZCityResumeAppearanceMusic()
        return
    end

    ZCityResumeMainMusic()
end

hook.Add("Think", "ZCityMenuMusicRoundSync", function()
    ZCityCaptureMenuMusicTimes()

    local roundState = zb and zb.ROUND_STATE
    if not isnumber(roundState) then return end

    if ZCityMenuMusicState.lastRoundState ~= roundState then
        if roundState == 1 then
            ZCityMenuMusicState.pendingResume = true
            ZCityMenuMusicState.pendingResumeTime = CurTime() + 0.1
        end
        ZCityMenuMusicState.lastRoundState = roundState
    end

    if ZCityMenuMusicState.pendingResume and CurTime() >= ZCityMenuMusicState.pendingResumeTime then
        ZCityMenuMusicState.pendingResume = false
        ZCityResumeActiveMenuMusic()
    end
end)

function PANEL:Init()
    self:SetAlpha( 0 )
    self:SetSize( ScrW(), ScrH() )
    -- self:Center()
    self:SetTitle( "" )
    self:SetDraggable( false )
    self:SetBorder( false )
    self:SetColorBG(clr_verygray)
    self:SetDraggable( false )
    self:ShowCloseButton( false )
    
    -- Check for Intro Mode
    if not ZCityHasSeenIntro then
        self.IsIntro = true
    end
    
    self.CurrentState = "Main"
    self.TargetState = "Main"
    self.TransitionProgress = 1 -- Start in stable state

    -- self.Title, self.TitleShadow = self:InitializeMarkup()

    timer.Simple(0,function()
        if self.First then
            self:First()
        end
    end)

    if LogoMat and LogoMat.IsError and LogoMat:IsError() then
        LogoMat = Material("vgui/logo")
    end

    self.LogoX = ScreenScaleH(20)
    self.LogoY = ScreenScaleH(20)
    
    surface.SetFont("ZC_MM_Title")
    local _, th = surface.GetTextSize("meleecity: delicacy")
    self.LogoH = th

    self.MenuTop = self.LogoY + self.LogoH + ScreenScaleH(60)
    
    surface.SetFont("ZCity_Veteran")
    local widest = 0
    for _, v in ipairs(Selects) do
        if v.GamemodeOnly and engine.ActiveGamemode() != "zcity" then continue end
        local w = surface.GetTextSize(v.Title)
        if w > widest then
            widest = w
        end
    end
    self.MenuW = math.max(ScreenScaleH(260), widest + ScreenScaleH(40))
    self.MenuX = self.LogoX -- Align with logo

    self.lDock = vgui.Create("DPanel",self)
    local lDock = self.lDock
    lDock:SetSize(0, 0)
    lDock:SetVisible(false)

    if LocalPlayer and IsValid(LocalPlayer()) then
        LocalPlayer():SetDSP(31) -- Muffled/Underwater effect
    end
    
    -- Play Background Music (Persistent)
    if IsValid(ZCityMainMenuMusic) then
        ZCityMainMenuMusic:Play()
        ZCityMainMenuMusic:SetVolume(0.5) -- Lower volume
    else
        sound.PlayFile("sound/mainmenu.mp3", "noblock", function(station, errCode, errStr)
            if IsValid(station) then
                station:EnableLooping(true)
                station:SetVolume(0.5) -- Lower volume
                station:Play()
                ZCityMainMenuMusic = station
            else
                print("Error playing menu music:", errCode, errStr)
            end
        end)
    end

    self.Buttons = {}
    self.menuList = vgui.Create("DScrollPanel", self)
    self.menuList:SetPos(self.MenuX, self.MenuTop)
    local maxMenuHeight = math.min(ScrH() - self.MenuTop - ScreenScaleH(40), ScrH() * 0.8)
    self.menuList:SetSize(math.min(self.MenuW, ScrW() * 0.9), maxMenuHeight)
    self.menuList.ButtonHeight = ScreenScaleH(22)
    self.menuList.Spacing = ScreenScaleH(10)
    self.menuList.PushStrong = ScreenScaleH(6)
    self.menuList.PushWeak = ScreenScaleH(3)
    
    -- Custom scrollbar styling
    local sbar = self.menuList:GetVBar()
    sbar:SetWide(ScreenScaleH(6))
    sbar.Paint = function(s, w, h)
        surface.SetDrawColor(THEME.scrollbar_bg)
        surface.DrawRect(0, 0, w, h)
    end
    sbar.btnGrip.Paint = function(s, w, h)
        local col = s:IsHovered() and THEME.scrollbar_grip_hover or THEME.scrollbar_grip
        surface.SetDrawColor(col)
        draw.RoundedBox(2, 0, 0, w, h, col)
    end
    sbar:SetHideButtons(true)
    
    if self.IsIntro then
        self.menuList:SetVisible(false)
    end
    
    for k,v in ipairs(Selects) do
        if v.GamemodeOnly and engine.ActiveGamemode() != "zcity" then continue end
        self:AddSelect( self.menuList, v.Title, v )
    end
    self.menuList.PerformLayout = function(panel)
        local y = 0
        local w = panel:GetWide()
        for i, btn in ipairs(self.Buttons) do
            if IsValid(btn) then
                -- btn:SetSize(w, panel.ButtonHeight) -- Don't force width, use content size
                btn:SizeToContents()
                btn:SetWide(btn:GetWide() + ScreenScaleH(8))
                btn:SetTall(math.max(panel.ButtonHeight, btn:GetTall())) -- Use max height
                btn.BaseY = y
                y = y + btn:GetTall() + panel.Spacing
            end
        end
        local canvas = panel:GetCanvas()
        if IsValid(canvas) then
            canvas:SetTall(y)
        end
    end
    self.menuList.Think = function(panel)
        local transitionShake = self.TransitionShakeStrength or 0
        local waveAmp = 0.35 + transitionShake * 1.25
        local baseOffsetX = (self.TransitionShakeX or 0) * 0.22
        local baseOffsetY = (self.TransitionShakeY or 0) * 0.22
        local t = CurTime()
        for i, btn in ipairs(self.Buttons) do
            if IsValid(btn) and btn.BaseY then
                local waveX = math.sin(t * 28 + i * 0.75) * waveAmp
                local waveY = math.cos(t * 24 + i * 0.65) * waveAmp * 0.85
                btn:SetPos(math.Round(baseOffsetX + waveX), btn.BaseY + math.Round(baseOffsetY + waveY))
            end
        end
    end
    self.menuList:InvalidateLayout(true)

    self.rDock = vgui.Create("DPanel",self)
    local rDock = self.rDock
    rDock:SetSize(0, 0)
    rDock:SetVisible(false)
    
    -- Flashing Images Logic
    self.FlashImages = {
        Material("vgui/numerals.png"),
        Material("vgui/pills.png"),
        Material("vgui/knifedark.png")
    }
    self.NextFlashTime = CurTime() + math.random(5, 10)
    self.CurrentFlashImage = nil
    self.FlashState = "Idle" -- Idle, In, Stay, Out
    self.FlashAlpha = 0
    self.FlashStartTime = 0
    self.FlashDurationIn = 1
    self.FlashDurationStay = 3
    self.FlashDurationOut = 2
end

function PANEL:Think()
    if LocalPlayer and IsValid(LocalPlayer()) then
        -- Enforce DSP every frame to prevent decay/override
        LocalPlayer():SetDSP(31, false)
    end
    
    -- Flash Image State Machine
    if self.CurrentState == "Settings" or self.TargetState == "Settings" then
        local ct = CurTime()
        if self.FlashState == "Idle" then
            if ct >= self.NextFlashTime then
                self.FlashState = "In"
                self.CurrentFlashImage = table.Random(self.FlashImages)
                self.FlashStartTime = ct
                self.FlashAlpha = 0
            end
        elseif self.FlashState == "In" then
            local progress = (ct - self.FlashStartTime) / self.FlashDurationIn
            self.FlashAlpha = math.Clamp(progress, 0, 1) * 255
            if progress >= 1 then
                self.FlashState = "Stay"
                self.FlashStartTime = ct
            end
        elseif self.FlashState == "Stay" then
            self.FlashAlpha = 255
            if ct - self.FlashStartTime >= self.FlashDurationStay then
                self.FlashState = "Out"
                self.FlashStartTime = ct
            end
        elseif self.FlashState == "Out" then
            local progress = (ct - self.FlashStartTime) / self.FlashDurationOut
            self.FlashAlpha = math.Clamp(1 - progress, 0, 1) * 255
            if progress >= 1 then
                self.FlashState = "Idle"
                self.NextFlashTime = ct + math.random(5, 15) -- Random interval
                self.CurrentFlashImage = nil
            end
        end
    else
        -- Reset if not in settings
        self.FlashState = "Idle"
        self.CurrentFlashImage = nil
        self.NextFlashTime = CurTime() + math.random(2, 5) -- Shorter delay when returning
    end
    
    if self.IsIntro and not self.IntroSequenceActive then
        if input.IsKeyDown(KEY_ENTER) then
            self.IntroSequenceActive = true
            self.IntroStartTime = CurTime()
            -- Play "itbegins" sound
            sound.PlayFile("sound/itbegins.mp3", "noblock", function(station, errCode, errStr)
                if IsValid(station) then
                    ZCityIntroMusic = station
                    station:Play()
                else
                    print("Error playing intro sound:", errCode, errStr)
                end
            end)
            
            -- Fade out background music if playing
            if IsValid(ZCityMainMenuMusic) then
                local music = ZCityMainMenuMusic
                local duration = 3
                local startTime = CurTime()
                local startVol = music:GetVolume()
                
                local id = "ZCityMusicFadeOut"
                hook.Add("Think", id, function()
                    if not IsValid(music) then hook.Remove("Think", id) return end
                    
                    local elapsed = CurTime() - startTime
                    local progress = elapsed / duration
                    
                    if progress >= 1 then
                        music:SetVolume(0)
                        music:Pause()
                        hook.Remove("Think", id)
                    else
                        music:SetVolume(startVol * (1 - progress))
                    end
                end)
            end
        end
    end
    
    -- Transition Logic
    self.TransitionProgress = math.min(self.TransitionProgress + FrameTime() * 2, 1) -- 0.5 sec duration

    -- If we are switching between Traitor menus, we force the state update instantly but animate the alpha
    if (self.TargetState == "TraitorMenu" and self.CurrentState == "TraitorPresets") or (self.TargetState == "TraitorPresets" and self.CurrentState == "TraitorMenu") then
        if self.TransitionProgress >= 1 then
            self.CurrentState = self.TargetState
        end
    elseif self.TransitionProgress >= 1 and self.CurrentState ~= self.TargetState then
        self.CurrentState = self.TargetState
        
        -- Finalize transition visibility
        if self.CurrentState == "Settings" then
            if IsValid(self.menuList) then self.menuList:SetVisible(false) end
            if IsValid(self.SettingsList) then self.SettingsList:SetVisible(true) end
            if IsValid(self.AppearancePanel) then self.AppearancePanel:SetVisible(false) end
            if IsValid(self.AchievementsPanel) then self.AchievementsPanel:SetVisible(false) end
            if IsValid(self.TraitorMenuPanel) then self.TraitorMenuPanel:SetVisible(false) end
            if IsValid(self.TraitorPresetsPanel) then self.TraitorPresetsPanel:SetVisible(false) end
        elseif self.CurrentState == "Main" then
            if IsValid(self.menuList) then 
                if not self.IsIntro then
                    self.menuList:SetVisible(true) 
                else
                    self.menuList:SetVisible(false)
                end
            end
            if IsValid(self.SettingsList) then self.SettingsList:SetVisible(false) end
            if IsValid(self.AppearancePanel) then self.AppearancePanel:SetVisible(false) end
            if IsValid(self.AchievementsPanel) then self.AchievementsPanel:SetVisible(false) end
            if IsValid(self.TraitorMenuPanel) then self.TraitorMenuPanel:SetVisible(false) end
            if IsValid(self.TraitorPresetsPanel) then self.TraitorPresetsPanel:SetVisible(false) end
        elseif self.CurrentState == "Appearance" then
            if IsValid(self.menuList) then self.menuList:SetVisible(false) end
            if IsValid(self.SettingsList) then self.SettingsList:SetVisible(false) end
            if IsValid(self.AppearancePanel) then self.AppearancePanel:SetVisible(true) end
            if IsValid(self.AchievementsPanel) then self.AchievementsPanel:SetVisible(false) end
            if IsValid(self.TraitorMenuPanel) then self.TraitorMenuPanel:SetVisible(false) end
        elseif self.CurrentState == "Achievements" then
            if IsValid(self.menuList) then self.menuList:SetVisible(false) end
            if IsValid(self.SettingsList) then self.SettingsList:SetVisible(false) end
            if IsValid(self.AppearancePanel) then self.AppearancePanel:SetVisible(false) end
            if IsValid(self.AchievementsPanel) then self.AchievementsPanel:SetVisible(true) end
            if IsValid(self.TraitorMenuPanel) then self.TraitorMenuPanel:SetVisible(false) end
        elseif self.CurrentState == "TraitorMenu" then
            if IsValid(self.menuList) then self.menuList:SetVisible(false) end
            if IsValid(self.SettingsList) then self.SettingsList:SetVisible(false) end
            if IsValid(self.AppearancePanel) then self.AppearancePanel:SetVisible(false) end
            if IsValid(self.AchievementsPanel) then self.AchievementsPanel:SetVisible(false) end
            if IsValid(self.TraitorMenuPanel) then 
                self.TraitorMenuPanel:SetVisible(true) 
                self.TraitorMenuPanel:SetMouseInputEnabled(true)
            end
            if IsValid(self.TraitorPresetsPanel) then 
                -- Keep visible if we are transitioning to presets
                if self.TargetState ~= "TraitorPresets" then
                    self.TraitorPresetsPanel:SetVisible(false) 
                    self.TraitorPresetsPanel:SetMouseInputEnabled(false)
                end
            end
        elseif self.CurrentState == "TraitorPresets" then
            if IsValid(self.menuList) then self.menuList:SetVisible(false) end
            if IsValid(self.SettingsList) then self.SettingsList:SetVisible(false) end
            if IsValid(self.AppearancePanel) then self.AppearancePanel:SetVisible(false) end
            if IsValid(self.AchievementsPanel) then self.AchievementsPanel:SetVisible(false) end
            if IsValid(self.TraitorMenuPanel) then 
                -- Keep visible if we are transitioning to loadout
                if self.TargetState ~= "TraitorMenu" then
                    self.TraitorMenuPanel:SetVisible(false) 
                    self.TraitorMenuPanel:SetMouseInputEnabled(false)
                end
            end
            if IsValid(self.TraitorPresetsPanel) then 
                self.TraitorPresetsPanel:SetVisible(true) 
                self.TraitorPresetsPanel:SetMouseInputEnabled(true)
            end
        end
    end
    
    -- Calculate Visual T (0 = Main, 1 = Target)
    -- This logic assumes we only transition from Main <-> Something.
    -- If we go Settings <-> Appearance directly, it might be weird, but for now we assume Main is the hub.
    local visual_t = 0
    if self.TargetState == "Settings" or self.TargetState == "Appearance" or self.TargetState == "Achievements" or self.TargetState == "TraitorMenu" or self.TargetState == "TraitorPresets" then
        if (self.TargetState == "TraitorMenu" and self.CurrentState == "TraitorPresets") or (self.TargetState == "TraitorPresets" and self.CurrentState == "TraitorMenu") then
            visual_t = self.TransitionProgress
        else
            visual_t = self.TransitionProgress
        end
    elseif self.TargetState == "Main" then
        visual_t = 1 - self.TransitionProgress
    end
    local eased_t = visual_t * visual_t * (3 - 2 * visual_t)

    local transitionShakeStrength = 0
    if self.CurrentState ~= self.TargetState or self.TransitionProgress < 1 then
        transitionShakeStrength = math.Clamp(1 - math.abs(visual_t - 0.5) * 2, 0, 1)
    end
    self.TransitionShakeStrength = transitionShakeStrength
    local transitionShakeAmount = 4.2 * transitionShakeStrength
    if not self.NextTransitionShakeSample or CurTime() >= self.NextTransitionShakeSample then
        self.NextTransitionShakeSample = CurTime() + 0.035
        self.TargetTransitionShakeX = math.Rand(-transitionShakeAmount, transitionShakeAmount)
        self.TargetTransitionShakeY = math.Rand(-transitionShakeAmount * 0.55, transitionShakeAmount * 0.55)
        self.TargetTransitionImageShakeX = math.Rand(-transitionShakeAmount * 0.8, transitionShakeAmount * 0.8)
        self.TargetTransitionImageShakeY = math.Rand(-transitionShakeAmount * 0.65, transitionShakeAmount * 0.65)
    end
    local shakeLerp = math.Clamp(FrameTime() * 22, 0, 1)
    self.TransitionShakeX = Lerp(shakeLerp, self.TransitionShakeX or 0, self.TargetTransitionShakeX or 0)
    self.TransitionShakeY = Lerp(shakeLerp, self.TransitionShakeY or 0, self.TargetTransitionShakeY or 0)
    self.TransitionImageShakeX = Lerp(shakeLerp, self.TransitionImageShakeX or 0, self.TargetTransitionImageShakeX or 0)
    self.TransitionImageShakeY = Lerp(shakeLerp, self.TransitionImageShakeY or 0, self.TargetTransitionImageShakeY or 0)
    
    -- Alpha handling for buttons during transition
    if IsValid(self.menuList) then
        if self.IsIntro then
            self.menuList:SetVisible(false)
        else
            if self.TargetState == "Settings" or self.TargetState == "Appearance" or self.TargetState == "Achievements" or self.TargetState == "TraitorMenu" or self.TargetState == "TraitorPresets" then
                if self.CurrentState ~= "Main" then
                    self.menuList:SetAlpha(255)
                    self.menuList:SetVisible(false)
                else
                    self.menuList:SetAlpha(255)
                    -- Don't hide it, let it move offscreen
                end
            elseif self.TargetState == "Main" then
                self.menuList:SetVisible(true)
                self.menuList:SetAlpha(255)
            end
        end
    end
    
    if IsValid(self.SettingsList) then
        if self.TargetState == "Settings" then
            self.SettingsList:SetVisible(true)
            self.SettingsList:SetAlpha(255 * visual_t)
            if IsValid(self.SettingsReturnBtn) then
                self.SettingsReturnBtn:SetVisible(true)
                self.SettingsReturnBtn:SetAlpha(255 * visual_t)
            end
        elseif self.TargetState == "Main" and self.CurrentState == "Settings" then
             -- Fade out quickly
             local alpha = math.Clamp(1 - ((1 - visual_t) * 3), 0, 1) * 255
             self.SettingsList:SetAlpha(alpha)
             if alpha <= 0 then self.SettingsList:SetVisible(false) end
             
             if IsValid(self.SettingsReturnBtn) then
                self.SettingsReturnBtn:SetAlpha(alpha)
                if alpha <= 0 then self.SettingsReturnBtn:SetVisible(false) end
             end
        end
    end

    if IsValid(self.AppearancePanel) then
        if self.TargetState == "Appearance" then
            self.AppearancePanel:SetVisible(true)
            self.AppearancePanel:SetAlpha(255 * visual_t)
        elseif self.TargetState == "Main" and self.CurrentState == "Appearance" then
             -- Fade out quickly
             local alpha = math.Clamp(1 - ((1 - visual_t) * 3), 0, 1) * 255
             self.AppearancePanel:SetAlpha(alpha)
             if alpha <= 0 then self.AppearancePanel:SetVisible(false) end
        end
    end

    if IsValid(self.AchievementsPanel) then
        if self.TargetState == "Achievements" then
            self.AchievementsPanel:SetVisible(true)
            self.AchievementsPanel:SetAlpha(255 * visual_t)
        elseif self.TargetState == "Main" and self.CurrentState == "Achievements" then
            local alpha = math.Clamp(1 - ((1 - visual_t) * 3), 0, 1) * 255
            self.AchievementsPanel:SetAlpha(alpha)
            if alpha <= 0 then self.AchievementsPanel:SetVisible(false) end
        end
    end

    if IsValid(self.TraitorMenuPanel) then
        if self.TargetState == "TraitorMenu" or self.TargetState == "TraitorPresets" or (self.TargetState == "Main" and (self.CurrentState == "TraitorMenu" or self.CurrentState == "TraitorPresets")) then
            self.TraitorMenuPanel:SetVisible(true)
        else
            self.TraitorMenuPanel:SetVisible(false)
        end
    end

    if IsValid(self.TraitorPresetsPanel) then
        if self.TargetState == "TraitorMenu" or self.TargetState == "TraitorPresets" or (self.TargetState == "Main" and (self.CurrentState == "TraitorMenu" or self.CurrentState == "TraitorPresets")) then
            self.TraitorPresetsPanel:SetVisible(true)
        else
            self.TraitorPresetsPanel:SetVisible(false)
        end
    end

    if IsValid(self.menuList) then
        local y = self.MenuTop
        local x = self.MenuX
        if self.CurrentState ~= "Main" and self.TargetState ~= "Main" then
            if (self.CurrentState == "TraitorMenu" or self.CurrentState == "TraitorPresets") and (self.TargetState == "TraitorMenu" or self.TargetState == "TraitorPresets") then
                y = self.MenuTop + ScrH()
                self.menuList:SetVisible(false)
            else
                y = self.MenuTop - ScrH()
                if self.CurrentState == "Achievements" or self.TargetState == "Achievements" then
                    x = self.MenuX + ScrW()
                    y = self.MenuTop
                end
            end
        else
            if self.TargetState == "Appearance" or (self.TargetState == "Main" and self.CurrentState == "Appearance") then
                y = self.MenuTop - ScrH() * eased_t
            elseif self.TargetState == "Settings" or (self.TargetState == "Main" and self.CurrentState == "Settings") then
                x = self.MenuX - ScrW() * eased_t
            elseif self.TargetState == "Achievements" or (self.TargetState == "Main" and self.CurrentState == "Achievements") then
                x = self.MenuX + ScrW() * eased_t
            elseif self.TargetState == "TraitorMenu" or (self.TargetState == "Main" and self.CurrentState == "TraitorMenu") or self.TargetState == "TraitorPresets" or (self.TargetState == "Main" and self.CurrentState == "TraitorPresets") then
                y = self.MenuTop + ScrH() * eased_t
            end
        end
        self.menuList:SetPos(x + (self.TransitionShakeX or 0), y + (self.TransitionShakeY or 0))
    end

    if IsValid(self.AppearancePanel) then
        if self.TargetState == "Appearance" or (self.TargetState == "Main" and self.CurrentState == "Appearance") then
            self.AppearancePanel:SetPos(self.TransitionShakeX or 0, ScrH() * (1 - eased_t) + (self.TransitionShakeY or 0))
        else
            self.AppearancePanel:SetPos(0 + (self.TransitionShakeX or 0), 0 + (self.TransitionShakeY or 0))
        end
    end

    if IsValid(self.SettingsList) then
        if self.TargetState == "Settings" or (self.TargetState == "Main" and self.CurrentState == "Settings") then
            self.SettingsList:SetPos(self.MenuX + ScrW() * (1 - eased_t) + (self.TransitionShakeX or 0), self.MenuTop + (self.TransitionShakeY or 0))
        else
            self.SettingsList:SetPos(self.MenuX + (self.TransitionShakeX or 0), self.MenuTop + (self.TransitionShakeY or 0))
        end
    end

    if IsValid(self.SettingsReturnBtn) then
        local baseX = self.SettingsReturnBtn.BaseX or ScreenScale(20)
        local baseY = self.SettingsReturnBtn.BaseY or (ScrH() - ScreenScale(40))
        if self.TargetState == "Settings" or (self.TargetState == "Main" and self.CurrentState == "Settings") then
            self.SettingsReturnBtn:SetPos(baseX + ScrW() * (1 - eased_t) + (self.TransitionShakeX or 0), baseY + (self.TransitionShakeY or 0))
        else
            self.SettingsReturnBtn:SetPos(baseX + (self.TransitionShakeX or 0), baseY + (self.TransitionShakeY or 0))
        end
    end

    if IsValid(self.AchievementsPanel) then
        if self.TargetState == "Achievements" or (self.TargetState == "Main" and self.CurrentState == "Achievements") then
            self.AchievementsPanel:SetPos(-ScrW() * (1 - eased_t) + (self.TransitionShakeX or 0), 0 + (self.TransitionShakeY or 0))
        else
            self.AchievementsPanel:SetPos(0 + (self.TransitionShakeX or 0), 0 + (self.TransitionShakeY or 0))
        end
    end

    if IsValid(self.TraitorMenuPanel) then
        if self.TargetState == "TraitorMenu" then
            if self.CurrentState == "TraitorPresets" then
                self.TraitorMenuPanel:SetAlpha(255 * visual_t)
                self.TraitorMenuPanel:SetPos(0, 0)
                self.TraitorMenuPanel:SetMouseInputEnabled(true)
            else
                self.TraitorMenuPanel:SetAlpha(255 * visual_t)
                self.TraitorMenuPanel:SetPos(0, -ScrH() * (1 - visual_t))
                self.TraitorMenuPanel:SetMouseInputEnabled(true)
            end
            self.TraitorMenuPanel:SetVisible(true)
        elseif self.TargetState == "Main" and self.CurrentState == "TraitorMenu" then
            self.TraitorMenuPanel:SetAlpha(255)
            self.TraitorMenuPanel:SetPos(0, -ScrH() * (1 - visual_t))
            self.TraitorMenuPanel:SetMouseInputEnabled(false)
        elseif self.TargetState == "TraitorPresets" and self.CurrentState == "TraitorMenu" then
            self.TraitorMenuPanel:SetAlpha(255 * (1 - visual_t))
            self.TraitorMenuPanel:SetPos(0, 0)
            self.TraitorMenuPanel:SetMouseInputEnabled(false)
            self.TraitorMenuPanel:SetVisible(true)
        else
            if self.CurrentState ~= "TraitorMenu" then
                self.TraitorMenuPanel:SetAlpha(0)
                self.TraitorMenuPanel:SetPos(0, 0)
                self.TraitorMenuPanel:SetVisible(false)
            end
        end
    end

    if IsValid(self.TraitorPresetsPanel) then
        if self.TargetState == "TraitorPresets" then
            if self.CurrentState == "TraitorMenu" then
                self.TraitorPresetsPanel:SetAlpha(255 * visual_t)
                self.TraitorPresetsPanel:SetPos(0, 0)
                self.TraitorPresetsPanel:SetMouseInputEnabled(false)
            else
                self.TraitorPresetsPanel:SetAlpha(255 * visual_t)
                self.TraitorPresetsPanel:SetPos(0, -ScrH() * (1 - visual_t))
                self.TraitorPresetsPanel:SetMouseInputEnabled(true)
            end
            self.TraitorPresetsPanel:SetVisible(true)
        elseif self.TargetState == "Main" and self.CurrentState == "TraitorPresets" then
            self.TraitorPresetsPanel:SetAlpha(255)
            self.TraitorPresetsPanel:SetPos(0, -ScrH() * (1 - visual_t))
            self.TraitorPresetsPanel:SetMouseInputEnabled(false)
        elseif self.TargetState == "TraitorMenu" and self.CurrentState == "TraitorPresets" then
            self.TraitorPresetsPanel:SetAlpha(255 * (1 - visual_t))
            self.TraitorPresetsPanel:SetPos(0, 0)
            self.TraitorPresetsPanel:SetMouseInputEnabled(false)
            self.TraitorPresetsPanel:SetVisible(true)
        else
            if self.CurrentState ~= "TraitorPresets" then
                self.TraitorPresetsPanel:SetAlpha(0)
                self.TraitorPresetsPanel:SetPos(0, 0)
                self.TraitorPresetsPanel:SetVisible(false)
            end
        end
    end
end

function PANEL:SwitchToSettings()
    self.TargetState = "Settings"
    self.TransitionProgress = 0
    self:CreateSettingsPanel()
end

function PANEL:FadeMusic(channel, targetVolume, duration, onComplete)
    if not IsValid(channel) then return end
    
    local startVolume = channel:GetVolume()
    local startTime = CurTime()
    local id = "ZCityMusicFade_" .. tostring(channel)
    
    hook.Add("Think", id, function()
        if not IsValid(channel) then hook.Remove("Think", id) return end
        
        local elapsed = CurTime() - startTime
        local progress = math.Clamp(elapsed / duration, 0, 1)
        
        channel:SetVolume(Lerp(progress, startVolume, targetVolume))
        
        if progress >= 1 then
            hook.Remove("Think", id)
            if onComplete then onComplete() end
        end
    end)
end

function PANEL:SwitchToAppearance()
    self.TargetState = "Appearance"
    self.TransitionProgress = 0
    self:CreateAppearancePanel()
    
    -- Music Transition
    if IsValid(ZCityMainMenuMusic) then
        self:FadeMusic(ZCityMainMenuMusic, 0, 1, function()
            if IsValid(ZCityMainMenuMusic) then ZCityMainMenuMusic:Pause() end
        end)
    end
    
    if IsValid(ZCityAppearanceMusic) then
        ZCityAppearanceMusic:Play()
        ZCityAppearanceMusic:SetVolume(0)
        self:FadeMusic(ZCityAppearanceMusic, 1, 1)
    else
        sound.PlayFile("sound/sexualdeviants.mp3", "noblock", function(station, errCode, errStr)
            if IsValid(station) then
                station:EnableLooping(true)
                station:SetVolume(0)
                station:Play()
                self:FadeMusic(station, 1, 1)
                ZCityAppearanceMusic = station
            else
                print("Error playing appearance music (sound/sexualdeviants.mp3):", errCode, errStr)
                -- Try without sound/ prefix just in case
                sound.PlayFile("sexualdeviants.mp3", "noblock", function(station2, errCode2, errStr2)
                    if IsValid(station2) then
                        station2:EnableLooping(true)
                        station2:SetVolume(0)
                        station2:Play()
                        self:FadeMusic(station2, 1, 1)
                        ZCityAppearanceMusic = station2
                    else
                         print("Error playing appearance music fallback (sexualdeviants.mp3):", errCode2, errStr2)
                    end
                end)
            end
        end)
    end
end

function PANEL:SwitchToTraitorMenu()
    if self.CurrentState == "TraitorPresets" then
        self.TargetState = "TraitorMenu"
        self.TransitionProgress = 0
    else
        self.TargetState = "TraitorMenu"
        self.TransitionProgress = 0
    end
    self:CreateTraitorMenuPanel()
end

function PANEL:SwitchToTraitorPresets()
    if self.CurrentState == "TraitorMenu" then
        self.TargetState = "TraitorPresets"
        self.TransitionProgress = 0
    else
        self.TargetState = "TraitorPresets"
        self.TransitionProgress = 0
    end
    self:CreateTraitorMenuPanel()
end

function PANEL:SwitchToAchievements()
    self.TargetState = "Achievements"
    self.TransitionProgress = 0
    self:CreateAchievementsPanel()
    if hg and hg.achievements and hg.achievements.LoadAchievements then
        hg.achievements.LoadAchievements()
    end
end

function PANEL:SwitchToMain()
    self.TargetState = "Main"
    self.TransitionProgress = 0
    
    -- Music Transition
    if IsValid(ZCityAppearanceMusic) then
        self:FadeMusic(ZCityAppearanceMusic, 0, 1, function()
            if IsValid(ZCityAppearanceMusic) then ZCityAppearanceMusic:Stop() end
        end)
    end
    
    if IsValid(ZCityMainMenuMusic) then
        ZCityMainMenuMusic:Play()
        self:FadeMusic(ZCityMainMenuMusic, 0.5, 1) -- Return to 0.5 as per Init
    end
end

function PANEL:CreateSettingsPanel()
    if IsValid(self.SettingsList) then return end
    
    self.SettingsList = vgui.Create("DScrollPanel", self)
    self.SettingsList:SetPos(self.MenuX, self.MenuTop)
    -- Extend width to cover more of the screen (e.g., 75% of screen width)
    local maxSettingsHeight = math.min(ScrH() - self.MenuTop - ScreenScale(60), ScrH() * 0.8)
    self.SettingsList:SetSize(math.min(ScrW() * 0.75, ScrW() * 0.9), maxSettingsHeight)
    self.SettingsList:SetAlpha(0)
    self.SettingsList:SetVisible(false)
    self.SettingsList.ButtonHeight = ScreenScale(18)
    self.SettingsList.Spacing = ScreenScale(8)
    
    -- "hg_settings" Integration
    -- Iterate over hg.settings.tbl categories
    if hg and hg.settings and hg.settings.tbl then
        for categoryName, items in SortedPairs(hg.settings.tbl) do
            -- Category header spacer with text drawn inside (will be clipped by scroll panel)
            local catSpacer = vgui.Create("DPanel", self.SettingsList)
            catSpacer:Dock(TOP)
            catSpacer:SetTall(ScreenScale(32))
            catSpacer:DockMargin(0, ScreenScale(8), 0, ScreenScale(4))
            catSpacer:SetMouseInputEnabled(false)
            catSpacer.CategoryName = string.upper(categoryName)
            catSpacer.Paint = function(s, w, h)
                -- Subtle background
                surface.SetDrawColor(255, 255, 255, 8)
                surface.DrawRect(0, 0, w, h)
                -- Red accent line on left
                surface.SetDrawColor(THEME.accent_red)
                surface.DrawRect(0, 2, 3, h - 4)
                
                -- Draw category name - will be clipped by scroll panel automatically
                surface.SetFont("ZCity_Veteran")
                surface.SetTextColor(THEME.accent_red)
                surface.SetTextPos(ScreenScale(14), ScreenScale(4))
                surface.DrawText(s.CategoryName)
            end
            
            for _, item in SortedPairs(items) do
                local conVarName = item[2]
                local title = item[3]
                local isBool = (GetConVar(conVarName) and GetConVar(conVarName):GetMax() == 1) or false
                local conVar = GetConVar(conVarName)
                
                if not conVar then continue end
                
                local pnl = vgui.Create("DPanel", self.SettingsList)
                pnl:SetTall(ScreenScale(25))
                pnl:Dock(TOP)
                pnl:DockMargin(0, 0, 0, ScreenScale(2))
                pnl.Paint = function() end -- Transparent background
                
                local lbl = vgui.Create("DLabel", pnl)
                lbl:SetText(string.lower(title))
                lbl:SetFont("ZCity_Veteran")
                lbl:SizeToContentsY()
                lbl:Dock(LEFT)
                lbl:SetTextColor(Color(200, 200, 200))
                lbl:SetWide(self.SettingsList:GetWide() * 0.6) -- Dynamic width based on panel size
                lbl:SetWrap(false) -- Ensure it doesn't wrap weirdly, but width should be enough now
                
                pnl:SetTall(math.max(ScreenScale(25), lbl:GetTall() + ScreenScale(4)))
                
                if isBool then
                    -- Container for Off/On buttons with modern toggle design
                    local toggleContainer = vgui.Create("DPanel", pnl)
                    toggleContainer:Dock(RIGHT)
                    toggleContainer:SetWide(ScreenScale(90))
                    toggleContainer:DockMargin(0, ScreenScale(2), 0, 0)
                    toggleContainer.Paint = function(s, w, h)
                        -- Container background
                        surface.SetDrawColor(THEME.bg_panel)
                        draw.RoundedBox(4, 0, 0, w, h, THEME.bg_panel)
                        surface.SetDrawColor(THEME.border)
                        surface.DrawOutlinedRect(0, 0, w, h, 1)
                    end

                    local btnOn = vgui.Create("DButton", toggleContainer)
                    local btnOff = vgui.Create("DButton", toggleContainer)

                    -- Helper to update visuals
                    local function UpdateToggleVisuals()
                        local state = conVar:GetBool()
                        
                        -- Off Button
                        btnOff.Paint = function(s, w, h)
                            if not state then -- Active (OFF is active)
                                surface.SetDrawColor(THEME.accent_red)
                                draw.RoundedBox(3, 1, 1, w - 2, h - 2, THEME.accent_red)
                                s:SetTextColor(Color(255, 255, 255))
                            else -- Inactive
                                s:SetTextColor(THEME.text_secondary)
                            end
                        end

                        -- On Button
                        btnOn.Paint = function(s, w, h)
                            if state then -- Active (ON is active)
                                surface.SetDrawColor(THEME.accent_red)
                                draw.RoundedBox(3, 1, 1, w - 2, h - 2, THEME.accent_red)
                                s:SetTextColor(Color(255, 255, 255))
                            else -- Inactive
                                s:SetTextColor(THEME.text_secondary)
                            end
                        end
                    end

                    -- Setup Off Button
                    btnOff:SetText("off")
                    btnOff:SetFont("ZCity_Veteran")
                    btnOff:Dock(LEFT)
                    btnOff:SetWide(ScreenScale(35))
                    btnOff:DockMargin(0, 0, ScreenScale(4), 0)
                    btnOff.DoClick = function()
                        conVar:SetBool(false)
                        UpdateToggleVisuals()
                        sound.PlayFile("sound/press3.mp3", "noblock", function(station) if IsValid(station) then station:Play() end end)
                    end

                    -- Setup On Button
                    btnOn:SetText("on")
                    btnOn:SetFont("ZCity_Veteran")
                    btnOn:Dock(LEFT) -- Next to Off
                    btnOn:SetWide(ScreenScale(35))
                    btnOn.DoClick = function()
                        conVar:SetBool(true)
                        UpdateToggleVisuals()
                        sound.PlayFile("sound/press3.mp3", "noblock", function(station) if IsValid(station) then station:Play() end end)
                    end

                    UpdateToggleVisuals()
                else
                    -- Slider for non-bools
                    local slider = vgui.Create("DNumSlider", pnl)
                    slider:Dock(RIGHT)
                    slider:SetWide(self.SettingsList:GetWide() * 0.4) -- Use remaining space
                    slider:SetMin(conVar:GetMin() or 0)
                    slider:SetMax(conVar:GetMax() or 100)
                    slider:SetDecimals(item[4] and 2 or 0)
                    slider:SetConVar(conVarName)
                    -- Ensure value is initialized immediately for visual alignment
                    if conVar then slider:SetValue(conVar:GetFloat()) end
                    slider.Label:SetVisible(false) -- Hide default label
                    
                    -- Custom Slider Styling (Enhanced Modern Design)
                    slider.TextArea:SetFont("ZCity_Veteran")
                    local faintWhite = Color(255, 255, 255, 180)
                    slider.TextArea:SetTextColor(faintWhite)
                    slider.TextArea:SetContentAlignment(6) -- Right align
                    slider.TextArea:SetUpdateOnType(true)
                    -- Fix text area to prevent overflow
                    slider.TextArea.Paint = function(s, w, h)
                        -- Background for text area
                        surface.SetDrawColor(THEME.slider_bg)
                        draw.RoundedBox(4, 0, 0, w, h, THEME.slider_bg)
                        surface.SetDrawColor(THEME.border)
                        surface.DrawOutlinedRect(0, 0, w, h, 1)
                        -- Draw text with proper alignment
                        s:DrawTextEntryText(faintWhite, Color(220, 220, 220), faintWhite)
                    end
                    -- Set a fixed wide value to prevent overflow
                    slider.TextArea:SetWide(ScreenScale(50))
                    
                    slider.Slider.Paint = function(s, w, h)
                        local barH = ScreenScale(10)
                        local barY = h/2 - barH/2
                        
                        -- Background
                        surface.SetDrawColor(THEME.slider_bg)
                        draw.RoundedBox(4, 0, barY, w, barH, THEME.slider_bg)
                        surface.SetDrawColor(THEME.border)
                        surface.DrawOutlinedRect(0, barY, w, barH, 1)
                        
                        -- Fill with accent color
                        local fillW = math.Clamp(s.m_fSlideX * (w - 2), 0, w - 2)
                        surface.SetDrawColor(THEME.slider_fill)
                        draw.RoundedBox(4, 1, barY + 1, fillW, barH - 2, THEME.slider_fill)
                    end
                    
                    -- Styled knob
                    slider.Slider.Knob.Paint = function(s, w, h)
                        surface.SetDrawColor(THEME.accent_white)
                        draw.RoundedBox(3, 0, 0, w, h, THEME.accent_white)
                        if s:IsHovered() then
                            surface.SetDrawColor(255, 255, 255, 50)
                            surface.DrawRect(0, 0, w, h)
                        end
                    end
                end
            end
        end
    end
    
    -- Add Think function to update category header positions based on scroll
    self.SettingsList.Think = function(s)
        if self.SettingsCategoryHeaderPanels then
            local scrollOffset = s:GetVBar():GetScroll()
            local listY = self.SettingsList:GetY()
            for _, headerData in ipairs(self.SettingsCategoryHeaderPanels) do
                local spacer = headerData.spacer
                local label = headerData.label
                if IsValid(spacer) and IsValid(label) then
                    local spacerY = spacer:GetY()
                    local headerY = listY + spacerY - scrollOffset
                    label:SetPos(self.SettingsList:GetX() + ScreenScale(14), headerY + ScreenScale(4))
                    -- Hide if outside visible area
                    label:SetVisible(headerY > -50 and headerY < ScrH())
                end
            end
        end
    end
    
    -- Add Return Button at the bottom (Separate from scroll list)
    if not IsValid(self.SettingsReturnBtn) then
        local btn = vgui.Create("DLabel", self)
        self.SettingsReturnBtn = btn
        btn:SetText("return")
        btn:SetMouseInputEnabled(true)
        btn:SetFont("ZCity_Veteran")
        btn:SetTall(ScreenScale(18))
        btn:SizeToContents()
        btn:SetWide(btn:GetWide() + ScreenScale(8))
        btn.BaseX = ScreenScale(20)
        btn.BaseY = ScrH() - ScreenScaleH(40)
        btn:SetPos(btn.BaseX, btn.BaseY)
        btn:SetTextColor(Color(255, 255, 255))
        btn:SetAlpha(0)
        btn:SetVisible(false)
        
        btn.DoClick = function()
            sound.PlayFile("sound/press.mp3", "noblock", function(station) if IsValid(station) then station:Play() end end)
            self:SwitchToMain()
        end
        
        -- Add paint method for hover effect
        btn.Paint = function(self, w, h)
            local font = self:GetFont()
            local text = self:GetText()
            surface.SetFont(font)
            local tw, th = surface.GetTextSize(text)

            if self:IsHovered() then
                if not self.HoveredSoundPlayed then
                    sound.PlayFile("sound/hover.ogg", "noblock", function(station) if IsValid(station) then station:Play() end end)
                    self.HoveredSoundPlayed = true
                end
                
                local alpha = 255
                if math.random() > 0.9 then alpha = math.random(50, 200) end
                
                surface.SetDrawColor(255, 255, 255, alpha)
                surface.DrawRect(0, 0, tw, h)
                self:SetTextColor(Color(0, 0, 0, alpha))
            else
                self.HoveredSoundPlayed = false
                self:SetTextColor(Color(255, 255, 255))
            end
            
            local offX, offY = 0, 0
            if math.random() > 0.9 then
                 offX = math.random(-2, 2)
                 offY = math.random(-2, 2)
            end
            
            draw.SimpleText(text, font, offX, h/2 + offY, self:GetTextColor(), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            
            if self:IsHovered() and math.random() > 0.7 then
                local offsetX = math.random(-5, 5)
                local offsetY = math.random(-2, 2)
                draw.SimpleText(text, font, offsetX, h/2 + offsetY, Color(0, 0, 0, math.random(50, 150)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            return true
        end
    end
end

function PANEL:CreateAchievementButton(parent, ach)
    local button = vgui.Create("DPanel", parent)
    ach.img = isstring(ach.img) and Material(ach.img) or ach.img
    button:SetMouseInputEnabled(true)
    button:SetTall(ScreenScale(45))
    button:Dock(TOP)
    button:DockMargin(0, 0, 0, ScreenScale(6))
    button.Padding = ScreenScale(10)

    -- Hover State
    button.IsHoveredState = false
    button.OnCursorEntered = function(s)
        s.IsHoveredState = true
        sound.PlayFile("sound/hover.ogg", "noblock", function(station) if IsValid(station) then station:Play() end end)
    end
    button.OnCursorExited = function(s)
        s.IsHoveredState = false
    end

    function button:UpdateDesc()
        local width = self:GetWide() - self.Padding * 2
        if width <= 0 then return end
        if self.DescWidth == width then return end
        self.DescWidth = width
        -- Faint gray description
        self.DescMarkup = markup.Parse("<font=ZCity_Small><color=180,180,180>" .. string.lower(ach.description) .. "</color></font>", width)
    end

    function button:PerformLayout()
        self:UpdateDesc()
    end

    function button:Paint(w, h)
        self:UpdateDesc()
        self.lerpcolor = Lerp(FrameTime() * 10, self.lerpcolor or 0, 0)

        local localach = hg.achievements.GetLocalAchievements()
        local val = localach and localach[ach.key] and localach[ach.key].value or ach.start_value
        local progress = math.Clamp(val / ach.needed_value, 0, 1)

        -- Enhanced Background with gradient
        surface.SetDrawColor(THEME.bg_card)
        draw.RoundedBox(4, 0, 0, w, h, THEME.bg_card)
        
        -- Hover Glow
        if self.IsHoveredState then
            surface.SetDrawColor(THEME.accent_red_glow)
            draw.RoundedBox(4, 0, 0, w, h, THEME.accent_red_glow)
        end
        
        -- Border
        surface.SetDrawColor(self.IsHoveredState and THEME.border_bright or THEME.border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        -- Progress Bar (Bottom) - Enhanced
        local barH = ScreenScale(4)
        local barPad = 2
        -- Bar Background
        surface.SetDrawColor(THEME.progress_bg)
        draw.RoundedBox(2, barPad, h - barH - barPad, w - barPad * 2, barH, THEME.progress_bg)
        
        -- Bar Fill with accent color
        surface.SetDrawColor(THEME.progress_fill)
        draw.RoundedBox(2, barPad, h - barH - barPad, math.max((w - barPad * 2) * progress, 4), barH, THEME.progress_fill)

        -- Text Handling
        local nameColor = Color(235, 235, 235)
        local percentText = ach.showpercent and (math.floor(progress * 100) .. "%") or ""
        
        -- Shake effect on hover
        local shakeX, shakeY = 0, 0
        if self.IsHoveredState and math.random() > 0.8 then
            shakeX = math.random(-1, 1)
            shakeY = math.random(-1, 1)
        end

        draw.SimpleText(string.lower(ach.name), "ZCity_Veteran", self.Padding + shakeX, ScreenScale(4) + shakeY, nameColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
        if percentText ~= "" then
            surface.SetFont("ZCity_Veteran")
            local tw = surface.GetTextSize(percentText)
            draw.SimpleText(percentText, "ZCity_Veteran", w - self.Padding - tw + shakeX, ScreenScale(4) + shakeY, nameColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        if self.DescMarkup then
            -- markup:Draw(x, y, alignx, aligny, alpha)
            self.DescMarkup:Draw(self.Padding + shakeX, ScreenScale(22) + shakeY, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 255)
        end
    end

    return button
end

function PANEL:UpdateAchievementsList()
    if not IsValid(self.AchievementsScroll) then return end
    self.AchievementsScroll:Clear()

    for i, ach in pairs(hg.achievements.achievements_data.created_achevements) do
        self.AchievementsScroll:AddItem(self:CreateAchievementButton(self.AchievementsScroll, ach))
    end
end

function PANEL:CreateAchievementsPanel()
    if IsValid(self.AchievementsPanel) then return end

    self.AchievementsPanel = vgui.Create("DPanel", self)
    self.AchievementsPanel:SetSize(ScrW(), ScrH())
    self.AchievementsPanel:SetPos(0, 0)
    self.AchievementsPanel:SetAlpha(0)
    self.AchievementsPanel:SetVisible(false)
    self.AchievementsPanel.Paint = function() end

    local listW = math.max(ScreenScale(320), ScrW() * 0.6)
    local listX = ScreenScale(28)
    local listY = ScreenScaleH(80) -- Moved up since title is gone
    local listH = math.max(ScrH() * 0.5, ScrH() - listY - ScreenScaleH(80))

    self.AchievementsScroll = vgui.Create("DScrollPanel", self.AchievementsPanel)
    self.AchievementsScroll:SetPos(listX, listY)
    self.AchievementsScroll:SetSize(listW, listH)

    local sbar = self.AchievementsScroll:GetVBar()
    sbar:SetHideButtons(true)
    function sbar:Paint(w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 80))
    end
    function sbar.btnGrip:Paint(w, h)
        self.lerpcolor = Lerp(FrameTime() * 10, self.lerpcolor or 0.2, (self:IsHovered() and 0.8 or 0.6))
        draw.RoundedBox(0, 0, 0, w, h, Color(140 * self.lerpcolor, 120 * self.lerpcolor, 90 * self.lerpcolor))
    end

    local btn = vgui.Create("DLabel", self.AchievementsPanel)
    btn:SetText("return")
    btn:SetMouseInputEnabled(true)
    btn:SetFont("ZCity_Veteran")
    btn:SetTall(ScreenScale(18))
    btn:SizeToContents()
    local padding = ScreenScale(4)
    btn:SetWide(btn:GetWide() + padding * 2)
    btn:SetPos(ScreenScale(20), ScrH() - ScreenScaleH(40))
    btn:SetTextColor(Color(255, 255, 255))
    btn.DoClick = function()
        sound.PlayFile("sound/press.mp3", "noblock", function(station) if IsValid(station) then station:Play() end end)
        self:SwitchToMain()
    end

    btn.Paint = function(self, w, h)
        local font = self:GetFont()
        local text = self:GetText()
        surface.SetFont(font)
        local tw, th = surface.GetTextSize(text)

        if self:IsHovered() then
            if not self.HoveredSoundPlayed then
                sound.PlayFile("sound/hover.ogg", "noblock", function(station) if IsValid(station) then station:Play() end end)
                self.HoveredSoundPlayed = true
            end
            
            local alpha = 255
            if math.random() > 0.9 then alpha = math.random(50, 200) end
            
            surface.SetDrawColor(255, 255, 255, alpha)
            surface.DrawRect(padding, 0, tw, h)
            self:SetTextColor(Color(0, 0, 0, alpha))
        else
            self.HoveredSoundPlayed = false
            self:SetTextColor(Color(255, 255, 255))
        end
        
        local offX, offY = 0, 0
        if math.random() > 0.9 then
             offX = math.random(-2, 2)
             offY = math.random(-2, 2)
        end
        
        draw.SimpleText(text, font, padding + offX, h/2 + offY, self:GetTextColor(), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        if self:IsHovered() and math.random() > 0.7 then
            local offsetX = math.random(-5, 5)
            local offsetY = math.random(-2, 2)
            draw.SimpleText(text, font, padding + offsetX, h/2 + offsetY, Color(0, 0, 0, math.random(50, 150)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        return true
    end

    self:UpdateAchievementsList()
end

function PANEL:CreateTraitorMenuPanel()
    if IsValid(self.TraitorMenuPanel) then return end

    self.TraitorMenuPanel = vgui.Create("DPanel", self)
    self.TraitorMenuPanel:SetSize(ScrW(), ScrH())
    self.TraitorMenuPanel:SetPos(0, 0)
    self.TraitorMenuPanel:SetAlpha(0)
    self.TraitorMenuPanel:SetVisible(false)

    self.TraitorMenuPanel.Paint = function(pnl, w, h)
        local progress = self.TransitionProgress
        if self.TargetState == "Main" then
            progress = 1 - self.TransitionProgress
        end
        -- Darker background with subtle gradient
        surface.SetDrawColor(5, 5, 10, 200)
        surface.DrawRect(0, 0, w, h)
        -- Subtle vignette effect
        local grad = surface.GetTextureID("vgui/gradient-d")
        surface.SetTexture(grad)
        surface.SetDrawColor(0, 0, 0, 100)
        surface.DrawTexturedRect(0, 0, w, h)
    end

    local outerMargin = math.max(ScreenScale(15), 15)
    local availableW = math.max(ScrW() - outerMargin * 2, 260)
    local topMargin = math.Clamp(ScreenScaleH(80), 24, ScrH() * 0.2)
    local bottomMargin = math.Clamp(ScreenScaleH(60), 20, ScrH() * 0.15)
    local listH = math.Clamp(ScrH() - topMargin - bottomMargin, 180, math.max(ScrH() - 20, 180))
    local listY = math.max((ScrH() - listH) * 0.5, 10)

    local presetsW = math.Clamp(ScrW() * 0.54, 340, availableW)
    local presetsX = math.max((ScrW() - presetsW) * 0.5, outerMargin)

    local gapW = math.Clamp(ScreenScale(16), 12, 24)
    local desiredInfoW = math.Clamp(ScrW() * 0.32, 240, ScrW() * 0.54)
    local desiredLoadoutW = math.Clamp(ScrW() * 0.5, 340, ScrW() * 0.74)
    local desiredTotalW = desiredInfoW + gapW + desiredLoadoutW
    local infoW = desiredInfoW
    local loadoutW = desiredLoadoutW

    if desiredTotalW > availableW then
        local widthWithoutGap = math.max(availableW - gapW, 320)
        local totalWithoutGap = math.max(desiredInfoW + desiredLoadoutW, 1)
        infoW = math.max(180, math.floor(widthWithoutGap * (desiredInfoW / totalWithoutGap)))
        loadoutW = math.max(140, widthWithoutGap - infoW)
    end

    local traitorTotalW = math.min(infoW + gapW + loadoutW, availableW)
    local traitorX = math.max((ScrW() - traitorTotalW) * 0.5, outerMargin)

    -- Left Panel: Presets (Separate from sliding TraitorMenuPanel)
    self.TraitorPresetsPanel = vgui.Create("DPanel", self)
    self.TraitorPresetsPanel:SetSize(ScrW(), ScrH())
    self.TraitorPresetsPanel:SetPos(0, 0)
    self.TraitorPresetsPanel:SetAlpha(0)
    self.TraitorPresetsPanel:SetVisible(false)
    self.TraitorPresetsPanel.Paint = function(pnl, w, h)
        surface.SetDrawColor(5, 5, 10, 200)
        surface.DrawRect(0, 0, w, h)
    end
    
    local leftPanel = vgui.Create("DPanel", self.TraitorPresetsPanel)
    leftPanel:SetPos(presetsX, listY)
    leftPanel:SetSize(presetsW, listH)
    leftPanel.Paint = function(pnl, w, h)
        -- Enhanced panel with gradient, glow, and decorative elements
        -- Main background
        surface.SetDrawColor(THEME.bg_panel)
        draw.RoundedBox(8, 0, 0, w, h, THEME.bg_panel)
        -- Inner gradient overlay
        surface.SetDrawColor(THEME.gradient_top)
        draw.RoundedBox(8, 0, 0, w, h * 0.3, THEME.gradient_top)
        -- Border with glow
        surface.SetDrawColor(THEME.border_bright)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        -- Top accent line with glow
        surface.SetDrawColor(THEME.accent_red)
        surface.DrawRect(6, 0, w - 12, 3)
        surface.SetDrawColor(THEME.accent_red_glow)
        surface.DrawRect(6, 3, w - 12, 2)
        -- Corner decorations
        local cornerSize = ScreenScale(12)
        surface.SetDrawColor(THEME.accent_red)
        -- Top-left corner
        surface.DrawRect(0, 0, cornerSize, 2)
        surface.DrawRect(0, 0, 2, cornerSize)
        -- Top-right corner
        surface.DrawRect(w - cornerSize, 0, cornerSize, 2)
        surface.DrawRect(w - 2, 0, 2, cornerSize)
        -- Bottom-left corner
        surface.DrawRect(0, h - 2, cornerSize, 2)
        surface.DrawRect(0, h - cornerSize, 2, cornerSize)
        -- Bottom-right corner
        surface.DrawRect(w - cornerSize, h - 2, cornerSize, 2)
        surface.DrawRect(w - 2, h - cornerSize, 2, cornerSize)
    end

    local infoPanel = vgui.Create("DPanel", self.TraitorMenuPanel)
    infoPanel:SetPos(traitorX, listY)
    infoPanel:SetSize(infoW, listH)
    infoPanel.Paint = function(pnl, w, h)
        surface.SetDrawColor(THEME.bg_panel)
        draw.RoundedBox(8, 0, 0, w, h, THEME.bg_panel)
        surface.SetDrawColor(THEME.gradient_top)
        draw.RoundedBox(8, 0, 0, w, h * 0.3, THEME.gradient_top)
        surface.SetDrawColor(THEME.border_bright)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        surface.SetDrawColor(THEME.accent_red)
        surface.DrawRect(6, 0, w - 12, 3)
        surface.SetDrawColor(THEME.accent_red_glow)
        surface.DrawRect(6, 3, w - 12, 2)
        local cornerSize = ScreenScale(12)
        surface.SetDrawColor(THEME.accent_red)
        surface.DrawRect(0, 0, cornerSize, 2)
        surface.DrawRect(0, 0, 2, cornerSize)
        surface.DrawRect(w - cornerSize, 0, cornerSize, 2)
        surface.DrawRect(w - 2, 0, 2, cornerSize)
        surface.DrawRect(0, h - 2, cornerSize, 2)
        surface.DrawRect(0, h - cornerSize, 2, cornerSize)
        surface.DrawRect(w - cornerSize, h - 2, cornerSize, 2)
        surface.DrawRect(w - 2, h - cornerSize, 2, cornerSize)
    end

    local rightPanel = vgui.Create("DPanel", self.TraitorMenuPanel)
    rightPanel:SetPos(traitorX + infoW + gapW, listY)
    rightPanel:SetSize(loadoutW, listH)
    rightPanel.Paint = function(pnl, w, h)
        surface.SetDrawColor(THEME.bg_panel)
        draw.RoundedBox(8, 0, 0, w, h, THEME.bg_panel)
        surface.SetDrawColor(THEME.gradient_top)
        draw.RoundedBox(8, 0, 0, w, h * 0.3, THEME.gradient_top)
        surface.SetDrawColor(THEME.border_bright)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        surface.SetDrawColor(THEME.accent_red)
        surface.DrawRect(6, 0, w - 12, 3)
        surface.SetDrawColor(THEME.accent_red_glow)
        surface.DrawRect(6, 3, w - 12, 2)
        local cornerSize = ScreenScale(12)
        surface.SetDrawColor(THEME.accent_red)
        surface.DrawRect(0, 0, cornerSize, 2)
        surface.DrawRect(0, 0, 2, cornerSize)
        surface.DrawRect(w - cornerSize, 0, cornerSize, 2)
        surface.DrawRect(w - 2, 0, 2, cornerSize)
        surface.DrawRect(0, h - 2, cornerSize, 2)
        surface.DrawRect(0, h - cornerSize, 2, cornerSize)
        surface.DrawRect(w - cornerSize, h - 2, cornerSize, 2)
        surface.DrawRect(w - 2, h - cornerSize, 2, cornerSize)
    end

    -- State
    local savedData = file.Read("meleecity_traitor_loadout.txt", "DATA")
    local parsedLoadout = nil
    if savedData then
        parsedLoadout = util.JSONToTable(savedData)
    end

    local TraitorItems = {
        ["weapon_zoraki"] = {cost = 5, name = "Zoraki Flash Pistol"},
        ["weapon_buck200knife"] = {cost = 3, name = "Buck 200 Knife"},
        ["weapon_sogknife"] = {cost = 3, name = "SOG Knife"},
        ["weapon_fiberwire"] = {cost = 3, name = "Fiber Wire"},
        ["weapon_hg_rgd_tpik"] = {cost = 6, name = "RGD-5 Grenade"},
        ["weapon_adrenaline"] = {cost = 4, name = "Epipen"},
        ["weapon_hg_shuriken"] = {cost = 2, name = "Shuriken"},
        ["weapon_hg_smokenade_tpik"] = {cost = 3, name = "Smoke Grenade"},
        ["weapon_traitor_ied"] = {cost = 6, name = "IED"},
        ["weapon_traitor_poison1"] = {cost = 3, name = "Tetrodotoxin Syringe"},
        ["weapon_traitor_poison2"] = {cost = 2, name = "VX vial"},
        ["weapon_traitor_poison4"] = {cost = 3, name = "Curare vial"},
        ["weapon_traitor_poison3"] = {cost = 6, name = "Cyanide Canister"},
        ["weapon_traitor_suit"] = {cost = 5, name = "Traitor Suit"},
        ["weapon_hg_jam"] = {cost = 1, name = "Door Jam"},
        ["weapon_p22"] = {cost = 8, name = "Walther P22"},
        ["weapon_taser"] = {cost = 8, name = "Taser"},
    }
    local TraitorAddons = {
        ["weapon_p22_extra_mag"] = {cost = 2, name = "P22 Extra Magazine", parent = "weapon_p22"},
        ["weapon_p22_silencer"] = {cost = 2, name = "P22 Silencer", parent = "weapon_p22"},
    }
    local P22AddonOrder = {"weapon_p22_extra_mag", "weapon_p22_silencer"}

    local Skillsets = {
        ["none"] = {cost = 0, name = "None", desc = "No special skillset."},
        ["infiltrator"] = {cost = 10, name = "Infiltrator", desc = "Can break necks, disguise as ragdolls."},
        ["assassin"] = {cost = 12, name = "Assassin", desc = "Disarm people quickly, proficient in shooting."},
        ["chemist"] = {cost = 5, name = "Chemist", desc = "Resistant to chemicals, detects chemical agents in air."}
    }

    local maxPoints = 30
    local currentPoints = 0
    local currentLoadout = {weapons = {}, skillset = "none"}
    local WeaponExclusions = {
        ["weapon_buck200knife"] = {
            ["weapon_sogknife"] = true,
        },
        ["weapon_sogknife"] = {
            ["weapon_buck200knife"] = true,
        },
    }

    local function HasWeaponConflict(selectedWeapons, weaponId)
        local exclusions = WeaponExclusions[weaponId]
        if exclusions then
            for _, selectedId in ipairs(selectedWeapons) do
                if selectedId ~= weaponId and exclusions[selectedId] then
                    return true
                end
            end
        end

        for _, selectedId in ipairs(selectedWeapons) do
            if selectedId ~= weaponId then
                local selectedExclusions = WeaponExclusions[selectedId]
                if selectedExclusions and selectedExclusions[weaponId] then
                    return true
                end
            end
        end

        return false
    end

    local function GetSortedIdsByCost(sourceTable)
        local ids = {}
        for id in pairs(sourceTable) do
            table.insert(ids, id)
        end
        table.sort(ids, function(a, b)
            local aInfo = sourceTable[a]
            local bInfo = sourceTable[b]
            if aInfo.cost == bInfo.cost then
                return aInfo.name < bInfo.name
            end
            return aInfo.cost > bInfo.cost
        end)
        return ids
    end

    local skillsetOrder = GetSortedIdsByCost(Skillsets)
    local itemOrder = GetSortedIdsByCost(TraitorItems)

    local function SanitizeLoadout(rawLoadout)
        local normalizedLoadout = {weapons = {}, skillset = "none"}
        if type(rawLoadout) ~= "table" then
            rawLoadout = {}
        end

        if type(rawLoadout.skillset) == "string" and Skillsets[rawLoadout.skillset] then
            normalizedLoadout.skillset = rawLoadout.skillset
        end

        local totalPoints = Skillsets[normalizedLoadout.skillset].cost
        local usedWeapons = {}
        local rawWeaponIds = {}
        if type(rawLoadout.weapons) == "table" then
            for k, v in pairs(rawLoadout.weapons) do
                local weaponId
                if type(v) == "string" then
                    weaponId = v
                elseif type(k) == "string" and v == true then
                    weaponId = k
                end

                if weaponId and not usedWeapons[weaponId] and (TraitorItems[weaponId] or TraitorAddons[weaponId]) then
                    usedWeapons[weaponId] = true
                    table.insert(rawWeaponIds, weaponId)
                end
            end
        end

        usedWeapons = {}
        for _, weaponId in ipairs(rawWeaponIds) do
            local baseInfo = TraitorItems[weaponId]
            if baseInfo and not usedWeapons[weaponId] and not HasWeaponConflict(normalizedLoadout.weapons, weaponId) then
                local weaponCost = baseInfo.cost
                if totalPoints + weaponCost <= maxPoints then
                    usedWeapons[weaponId] = true
                    table.insert(normalizedLoadout.weapons, weaponId)
                    totalPoints = totalPoints + weaponCost
                end
            end
        end

        for _, weaponId in ipairs(rawWeaponIds) do
            local addonInfo = TraitorAddons[weaponId]
            if addonInfo and not usedWeapons[weaponId] and usedWeapons[addonInfo.parent] then
                local weaponCost = addonInfo.cost
                if totalPoints + weaponCost <= maxPoints then
                    usedWeapons[weaponId] = true
                    table.insert(normalizedLoadout.weapons, weaponId)
                    totalPoints = totalPoints + weaponCost
                end
            end
        end

        return normalizedLoadout
    end

    currentLoadout = SanitizeLoadout(parsedLoadout or {})

    local function SaveLoadout()
        currentLoadout = SanitizeLoadout(currentLoadout)
        local dataStr = util.TableToJSON(currentLoadout)
        file.Write("meleecity_traitor_loadout.txt", dataStr)
        local cv = GetConVar("hmcd_traitor_loadout")
        if cv then cv:SetString(dataStr) end
    end

    local infoContent = vgui.Create("DPanel", infoPanel)
    infoContent:Dock(FILL)
    infoContent:DockMargin(ScreenScale(10), ScreenScale(10), ScreenScale(10), ScreenScale(10))
    infoContent.Paint = function() end

    local lblInfoTitle = vgui.Create("DLabel", infoContent)
    lblInfoTitle:Dock(TOP)
    lblInfoTitle:SetText("SELECTED ITEM")
    lblInfoTitle:SetFont("ZCity_Veteran")
    lblInfoTitle:SetTextColor(THEME.accent_red)
    lblInfoTitle:SetContentAlignment(5)
    lblInfoTitle:SizeToContentsY()
    lblInfoTitle:DockMargin(0, ScreenScale(8), 0, ScreenScale(8))

    local previewIconMat = nil
    local previewImagePanel = vgui.Create("DPanel", infoContent)
    previewImagePanel:Dock(TOP)
    previewImagePanel:SetTall(math.Clamp(listH * 0.36, ScreenScale(120), ScreenScale(220)))
    previewImagePanel:DockMargin(0, 0, 0, ScreenScale(10))
    previewImagePanel.Paint = function(pnl, w, h)
        -- Enhanced preview panel with border and glow
        surface.SetDrawColor(THEME.bg_card)
        draw.RoundedBox(6, 0, 0, w, h, THEME.bg_card)
        surface.SetDrawColor(THEME.border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        -- Inner shadow
        surface.SetDrawColor(0, 0, 0, 50)
        draw.RoundedBox(6, 1, 1, w - 2, h - 2, Color(0, 0, 0, 50))
        if previewIconMat then
            local pad = ScreenScale(8)
            local drawW = w - pad * 2
            local drawH = h - pad * 2
            local matW = math.max(previewIconMat:Width(), 1)
            local matH = math.max(previewIconMat:Height(), 1)
            local iconScale = math.min(drawW / matW, drawH / matH)
            local iconW = matW * iconScale
            local iconH = matH * iconScale
            local iconX = (w - iconW) * 0.5
            local iconY = (h - iconH) * 0.5
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(previewIconMat)
            surface.DrawTexturedRect(iconX, iconY, iconW, iconH)
        else
            draw.SimpleText("?", "ZCity_Veteran", w / 2, h / 2, THEME.text_dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    local lblPreviewName = vgui.Create("DLabel", infoContent)
    lblPreviewName:Dock(TOP)
    lblPreviewName:DockMargin(0, 0, 0, ScreenScale(2))
    lblPreviewName:SetFont("ZCity_Veteran")
    lblPreviewName:SetTextColor(THEME.text_primary)
    lblPreviewName:SetContentAlignment(5)
    lblPreviewName:SetText("None")
    lblPreviewName:SizeToContentsY()

    local lblPreviewCost = vgui.Create("DLabel", infoContent)
    lblPreviewCost:Dock(TOP)
    lblPreviewCost:DockMargin(0, 0, 0, ScreenScale(8))
    lblPreviewCost:SetFont("ZCity_Veteran")
    lblPreviewCost:SetTextColor(THEME.accent_red)
    lblPreviewCost:SetContentAlignment(5)
    lblPreviewCost:SetText("")
    lblPreviewCost:SizeToContentsY()

    local lblPreviewDescTitle = vgui.Create("DLabel", infoContent)
    lblPreviewDescTitle:Dock(TOP)
    lblPreviewDescTitle:DockMargin(0, 0, 0, ScreenScale(4))
    lblPreviewDescTitle:SetFont("ZCity_Veteran")
    lblPreviewDescTitle:SetTextColor(THEME.text_secondary)
    lblPreviewDescTitle:SetContentAlignment(5)
    lblPreviewDescTitle:SetText("DESCRIPTION")
    lblPreviewDescTitle:SizeToContentsY()

    local previewDescScroll = vgui.Create("DScrollPanel", infoContent)
    previewDescScroll:Dock(FILL)
    previewDescScroll:DockMargin(0, 0, 0, 0)
    local dsbar = previewDescScroll:GetVBar()
    dsbar:SetWide(ScreenScale(5))
    dsbar:SetHideButtons(true)
    function dsbar:Paint(w, h)
        surface.SetDrawColor(THEME.scrollbar_bg)
        surface.DrawRect(0, 0, w, h)
    end
    function dsbar.btnGrip:Paint(w, h)
        local col = dsbar.btnGrip:IsHovered() and THEME.scrollbar_grip_hover or THEME.scrollbar_grip
        surface.SetDrawColor(col)
        draw.RoundedBox(2, 0, 0, w, h, col)
    end

    local lblPreviewDesc = vgui.Create("DLabel", previewDescScroll)
    lblPreviewDesc:Dock(TOP)
    lblPreviewDesc:SetFont("ZCity_Veteran")
    lblPreviewDesc:SetTextColor(THEME.text_secondary)
    lblPreviewDesc:SetWrap(true)
    lblPreviewDesc:SetAutoStretchVertical(true)
    lblPreviewDesc:SetText("None")

    local previewWeaponId = nil
    local function ResolvePreviewWeaponId()
        if previewWeaponId and TraitorItems[previewWeaponId] then
            return previewWeaponId
        end
        for _, weaponId in ipairs(currentLoadout.weapons) do
            if TraitorItems[weaponId] then
                return weaponId
            end
        end
        return nil
    end

    local function UpdatePreviewPanel()
        local weaponId = ResolvePreviewWeaponId()
        local itemInfo = weaponId and TraitorItems[weaponId] or nil
        local swep = weaponId and weapons.GetStored(weaponId) or nil
        local iconMat = nil
        local instructions = "None"

        if itemInfo then
            lblPreviewName:SetText(itemInfo.name)
            lblPreviewCost:SetText(itemInfo.cost .. " pts")
            if swep then
                if isstring(swep.Instructions) and swep.Instructions ~= "" then
                    instructions = swep.Instructions
                end
                if swep.WepSelectIcon then
                    if isstring(swep.WepSelectIcon) and swep.WepSelectIcon ~= "" then
                        iconMat = Material(swep.WepSelectIcon)
                    elseif type(swep.WepSelectIcon) == "IMaterial" then
                        iconMat = swep.WepSelectIcon
                    end
                end
                if not iconMat and isstring(swep.IconOverride) and swep.IconOverride ~= "" then
                    iconMat = Material(swep.IconOverride)
                end
            end
        else
            lblPreviewName:SetText("None")
            lblPreviewCost:SetText("")
        end

        lblPreviewName:SizeToContentsY()
        lblPreviewCost:SizeToContentsY()
        lblPreviewDesc:SetText(instructions)
        lblPreviewDesc:SetWide(math.max(previewDescScroll:GetWide() - ScreenScale(20), ScreenScale(120)))
        lblPreviewDesc:InvalidateLayout(true)

        if iconMat and not iconMat:IsError() then
            previewIconMat = iconMat
        else
            previewIconMat = nil
        end
    end

    local RefreshLoadoutUI

    -- === LEFT PANEL: PRESETS ===
    local presetsBottomPanel = vgui.Create("DPanel", leftPanel)
    presetsBottomPanel:Dock(BOTTOM)
    presetsBottomPanel:SetTall(ScreenScale(36))
    presetsBottomPanel:DockMargin(ScreenScale(10), 0, ScreenScale(10), ScreenScale(10))
    presetsBottomPanel.Paint = function(s, w, h)
        surface.SetDrawColor(THEME.border)
        surface.DrawRect(0, 0, w, 1)
    end

    local btnPresetsReturn = vgui.Create("DButton", presetsBottomPanel)
    btnPresetsReturn:Dock(RIGHT)
    btnPresetsReturn:DockMargin(0, ScreenScale(6), ScreenScale(10), ScreenScale(6))
    btnPresetsReturn:SetText("RETURN")
    btnPresetsReturn:SetFont("ZCity_Veteran")
    btnPresetsReturn:SetTextColor(THEME.text_primary)
    btnPresetsReturn:SizeToContentsX()
    btnPresetsReturn:SetWide(btnPresetsReturn:GetWide() + ScreenScale(24))
    btnPresetsReturn.HoverLerp = 0
    btnPresetsReturn.Paint = function(s, w, h)
        s.HoverLerp = Lerp(FrameTime() * 8, s.HoverLerp or 0, s:IsHovered() and 1 or 0)
        local v = s.HoverLerp
        local bgColor = Color(
            Lerp(v, 40, 200),
            Lerp(v, 40, 60),
            Lerp(v, 50, 60),
            Lerp(v, 180, 220)
        )
        draw.RoundedBox(4, 0, 0, w, h, bgColor)
        -- Glow effect on hover
        if v > 0.01 then
            surface.SetDrawColor(THEME.accent_red_glow)
            draw.RoundedBox(4, -v * 2, -v * 2, w + v * 4, h + v * 4, THEME.accent_red_glow)
        end
        -- Shine sweep effect
        if v > 0.01 then
            local sweepX = (CurTime() * 200) % (w + 40) - 20
            surface.SetDrawColor(255, 255, 255, v * 30)
            surface.DrawRect(sweepX, 0, 20, h)
        end
        surface.SetDrawColor(THEME.border_bright)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    btnPresetsReturn.DoClick = function()
        sound.PlayFile("sound/press.mp3", "noblock", function(station) if IsValid(station) then station:Play() end end)
        self:SwitchToMain()
    end

    local btnGoToLoadout = vgui.Create("DButton", presetsBottomPanel)
    btnGoToLoadout:Dock(RIGHT)
    btnGoToLoadout:DockMargin(0, ScreenScale(6), ScreenScale(10), ScreenScale(6))
    btnGoToLoadout:SetText("LOADOUT")
    btnGoToLoadout:SetFont("ZCity_Veteran")
    btnGoToLoadout:SetTextColor(THEME.text_primary)
    btnGoToLoadout:SizeToContentsX()
    btnGoToLoadout:SetWide(btnGoToLoadout:GetWide() + ScreenScale(24))
    btnGoToLoadout.HoverLerp = 0
    btnGoToLoadout.Paint = function(s, w, h)
        s.HoverLerp = Lerp(FrameTime() * 8, s.HoverLerp or 0, s:IsHovered() and 1 or 0)
        local v = s.HoverLerp
        local bgColor = Color(
            Lerp(v, 40, 200),
            Lerp(v, 40, 60),
            Lerp(v, 50, 60),
            Lerp(v, 180, 220)
        )
        draw.RoundedBox(4, 0, 0, w, h, bgColor)
        if v > 0.01 then
            surface.SetDrawColor(THEME.accent_red_glow)
            draw.RoundedBox(4, -v * 2, -v * 2, w + v * 4, h + v * 4, THEME.accent_red_glow)
        end
        if v > 0.01 then
            local sweepX = (CurTime() * 200) % (w + 40) - 20
            surface.SetDrawColor(255, 255, 255, v * 30)
            surface.DrawRect(sweepX, 0, 20, h)
        end
        surface.SetDrawColor(THEME.border_bright)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    btnGoToLoadout.DoClick = function()
        if self.LastSwitchTime and CurTime() - self.LastSwitchTime < 1 then return end
        self.LastSwitchTime = CurTime()
        sound.PlayFile("sound/press.mp3", "noblock", function(station) if IsValid(station) then station:Play() end end)
        self:SwitchToTraitorMenu()
    end

    local lblTitlePresets = vgui.Create("DLabel", leftPanel)
    lblTitlePresets:Dock(TOP)
    lblTitlePresets:SetText("TRAITOR PRESETS")
    lblTitlePresets:SetFont("ZCity_Veteran")
    lblTitlePresets:SetTextColor(THEME.accent_red)
    lblTitlePresets:SetContentAlignment(5)
    lblTitlePresets:SizeToContentsY()
    lblTitlePresets:DockMargin(0, ScreenScale(12), 0, ScreenScale(8))

    local presetsScroll = vgui.Create("DScrollPanel", leftPanel)
    presetsScroll:Dock(FILL)
    presetsScroll:DockMargin(ScreenScale(12), 0, ScreenScale(12), ScreenScale(12))
    local psbar = presetsScroll:GetVBar()
    psbar:SetWide(ScreenScale(5))
    psbar:SetHideButtons(true)
    function psbar:Paint(w, h)
        surface.SetDrawColor(THEME.scrollbar_bg)
        surface.DrawRect(0, 0, w, h)
    end
    function psbar.btnGrip:Paint(w, h)
        local col = psbar.btnGrip:IsHovered() and THEME.scrollbar_grip_hover or THEME.scrollbar_grip
        surface.SetDrawColor(col)
        draw.RoundedBox(2, 0, 0, w, h, col)
    end

    local function LoadPresets()
        local data = file.Read("meleecity_traitor_presets.txt", "DATA")
        if data then return util.JSONToTable(data) or {} end
        return {}
    end
    local function SavePresets(presets)
        file.Write("meleecity_traitor_presets.txt", util.TableToJSON(presets))
    end

    local function RefreshPresetsUI()
        presetsScroll:Clear()
        local presets = LoadPresets()

        local btnCreate = vgui.Create("DButton", presetsScroll)
        btnCreate:Dock(TOP)
        btnCreate:SetTall(ScreenScale(25))
        btnCreate:DockMargin(0, 0, 0, ScreenScale(5))
        btnCreate:SetText("+ CREATE NEW PRESET")
        btnCreate:SetFont("ZCity_Veteran")
        btnCreate:SetTextColor(Color(255, 255, 255))
        btnCreate.HoverLerp = 0
        btnCreate.Paint = function(s, w, h)
            s.HoverLerp = Lerp(FrameTime() * 8, s.HoverLerp or 0, s:IsHovered() and 1 or 0)
            local v = s.HoverLerp
            local bgColor = LerpColor(v, Color(25, 25, 35, 180), Color(60, 60, 70, 200))
            draw.RoundedBox(4, 0, 0, w, h, bgColor)
            if v > 0.01 then
                surface.SetDrawColor(THEME.accent_red, v * 50)
                surface.DrawRect(0, 0, w, h)
                surface.SetDrawColor(THEME.accent_red_glow)
                draw.RoundedBox(4, -v * 1.5, -v * 1.5, w + v * 3, h + v * 3, THEME.accent_red_glow)
                local sweepX = (CurTime() * 200) % (w + 40) - 20
                surface.SetDrawColor(255, 255, 255, v * 25)
                surface.DrawRect(sweepX, 0, 20, h)
            end
            surface.SetDrawColor(THEME.border)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            if v < 0.99 then
                for i = 0, w, 8 do
                    surface.SetDrawColor(255, 255, 255, 30)
                    surface.DrawRect(i, h/2 - 0.5, 4, 1)
                end
            end
        end
        btnCreate.DoClick = function()
            Derma_StringRequest("New Preset", "Enter a name for the new preset:", "Preset " .. (#presets + 1), function(text)
                table.insert(presets, {name = text, loadout = table.Copy(currentLoadout)})
                SavePresets(presets)
                RefreshPresetsUI()
                sound.PlayFile("sound/press.mp3", "noblock", function(station) if IsValid(station) then station:Play() end end)
            end)
        end

        for i, preset in ipairs(presets) do
            local pnl = vgui.Create("DPanel", presetsScroll)
            pnl:Dock(TOP)
            pnl:SetTall(ScreenScale(25))
            pnl:DockMargin(0, 0, 0, ScreenScale(2))
            pnl.Paint = function(s, w, h)
                surface.SetDrawColor(THEME.bg_card)
                draw.RoundedBox(4, 0, 0, w, h, THEME.bg_card)
                if s:IsHovered() then
                    surface.SetDrawColor(THEME.hover_bg)
                    surface.DrawRect(0, 0, w, h)
                end
                surface.SetDrawColor(THEME.border)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end

            local lblName = vgui.Create("DLabel", pnl)
            lblName:Dock(LEFT)
            lblName:DockMargin(ScreenScale(5), 0, 0, 0)
            lblName:SetText(preset.name)
            lblName:SetFont("ZCity_Veteran")
            lblName:SetTextColor(Color(255, 255, 255))
            lblName:SizeToContentsX()

            local btnDelete = vgui.Create("DButton", pnl)
            btnDelete:Dock(RIGHT)
            btnDelete:SetWide(ScreenScale(24))
            btnDelete:SetText("X")
            btnDelete:SetFont("ZCity_Veteran")
            btnDelete:SetTextColor(Color(255, 100, 100))
            btnDelete.HoverLerp = 0
            btnDelete.Paint = function(s, w, h)
                s.HoverLerp = Lerp(FrameTime() * 8, s.HoverLerp or 0, s:IsHovered() and 1 or 0)
                local v = s.HoverLerp
                if v > 0.01 then
                    draw.RoundedBox(3, 0, 0, w, h, Color(255, 0, 0, v * 60))
                    surface.SetDrawColor(255, 50, 50, v * 40)
                    draw.RoundedBox(3, -v, -v, w + v * 2, h + v * 2, Color(255, 50, 50, v * 40))
                end
            end
            btnDelete.DoClick = function()
                table.remove(presets, i)
                SavePresets(presets)
                RefreshPresetsUI()
                sound.PlayFile("sound/press.mp3", "noblock", function(station) if IsValid(station) then station:Play() end end)
            end

            local btnLoad = vgui.Create("DButton", pnl)
            btnLoad:Dock(RIGHT)
            btnLoad:SetText("LOAD")
            btnLoad:SetFont("ZCity_Veteran")
            btnLoad:SetTextColor(Color(200, 255, 200))
            btnLoad:SizeToContentsX()
            btnLoad:SetWide(btnLoad:GetWide() + ScreenScale(10))
            btnLoad.HoverLerp = 0
            btnLoad.Paint = function(s, w, h)
                s.HoverLerp = Lerp(FrameTime() * 8, s.HoverLerp or 0, s:IsHovered() and 1 or 0)
                local v = s.HoverLerp
                if v > 0.01 then
                    draw.RoundedBox(3, 0, 0, w, h, Color(0, 255, 0, v * 50))
                    surface.SetDrawColor(50, 255, 50, v * 30)
                    draw.RoundedBox(3, -v, -v, w + v * 2, h + v * 2, Color(50, 255, 50, v * 30))
                    local sweepX = (CurTime() * 200) % (w + 40) - 20
                    surface.SetDrawColor(255, 255, 255, v * 20)
                    surface.DrawRect(sweepX, 0, 20, h)
                end
            end
            btnLoad.DoClick = function()
                currentLoadout = SanitizeLoadout(table.Copy(preset.loadout or {}))
                previewWeaponId = nil
                SaveLoadout()
                RefreshLoadoutUI()
                sound.PlayFile("sound/press.mp3", "noblock", function(station) if IsValid(station) then station:Play() end end)
            end
        end
    end
    RefreshPresetsUI()

    -- === RIGHT PANEL: LOADOUT ===
    local rightContentContainer = vgui.Create("DPanel", rightPanel)
    rightContentContainer:Dock(FILL)
    rightContentContainer:DockMargin(ScreenScale(10), ScreenScale(10), ScreenScale(10), ScreenScale(10))
    rightContentContainer.Paint = function() end

    local lblTitleLoadout = vgui.Create("DLabel", rightContentContainer)
    lblTitleLoadout:Dock(TOP)
    lblTitleLoadout:SetText("TRAITOR LOADOUT")
    lblTitleLoadout:SetFont("ZCity_Veteran")
    lblTitleLoadout:SetTextColor(THEME.accent_red)
    lblTitleLoadout:SetContentAlignment(5)
    lblTitleLoadout:SizeToContentsY()
    lblTitleLoadout:DockMargin(0, ScreenScale(8), 0, ScreenScale(4))

    local lblPoints = vgui.Create("DLabel", rightContentContainer)
    lblPoints:Dock(TOP)
    lblPoints:SetFont("ZCity_Veteran")
    lblPoints:SetTextColor(THEME.text_secondary)
    lblPoints:SetContentAlignment(5)
    lblPoints:SizeToContentsY()
    lblPoints:DockMargin(0, 0, 0, ScreenScale(8))

    local loadoutScroll = vgui.Create("DScrollPanel", rightContentContainer)
    loadoutScroll:Dock(FILL)
    loadoutScroll:DockMargin(0, 0, 0, 0)
    local lsbar = loadoutScroll:GetVBar()
    lsbar:SetWide(ScreenScale(5))
    lsbar:SetHideButtons(true)
    function lsbar:Paint(w, h)
        surface.SetDrawColor(THEME.scrollbar_bg)
        surface.DrawRect(0, 0, w, h)
    end
    function lsbar.btnGrip:Paint(w, h)
        local col = lsbar.btnGrip:IsHovered() and THEME.scrollbar_grip_hover or THEME.scrollbar_grip
        surface.SetDrawColor(col)
        draw.RoundedBox(2, 0, 0, w, h, col)
    end

    RefreshLoadoutUI = function()
        loadoutScroll:Clear()
        currentLoadout = SanitizeLoadout(currentLoadout)
        UpdatePreviewPanel()

        currentPoints = 0
        for _, wep in pairs(currentLoadout.weapons) do
            if TraitorItems[wep] then
                currentPoints = currentPoints + TraitorItems[wep].cost
            elseif TraitorAddons[wep] then
                currentPoints = currentPoints + TraitorAddons[wep].cost
            end
        end
        if Skillsets[currentLoadout.skillset] then
            currentPoints = currentPoints + Skillsets[currentLoadout.skillset].cost
        end

        lblPoints:SetText("Points: " .. currentPoints .. " / " .. maxPoints)
        if currentPoints > maxPoints then
            lblPoints:SetTextColor(THEME.accent_red)
        else
            lblPoints:SetTextColor(THEME.text_secondary)
        end

        local function AddCategory(title)
            local catContainer = vgui.Create("DPanel", loadoutScroll)
            catContainer:Dock(TOP)
            catContainer:SetTall(ScreenScale(28))
            catContainer:DockMargin(0, ScreenScale(8), 0, ScreenScale(4))
            catContainer.Paint = function(s, w, h)
                surface.SetDrawColor(255, 255, 255, 6)
                surface.DrawRect(0, 0, w, h)
                surface.SetDrawColor(THEME.accent_red)
                surface.DrawRect(0, 2, 3, h - 4)
            end
            local catLbl = vgui.Create("DLabel", catContainer)
            catLbl:SetText(title)
            catLbl:SetFont("ZCity_Veteran")
            catLbl:SetTextColor(THEME.accent_red)
            catLbl:SetPos(ScreenScale(12), ScreenScale(4))
            catLbl:SizeToContents()
        end

        AddCategory("SKILLSETS")
        for _, id in ipairs(skillsetOrder) do
            local info = Skillsets[id]
            local btn = vgui.Create("DButton", loadoutScroll)
            btn:Dock(TOP)
            btn:SetTall(ScreenScale(24))
            btn:DockMargin(0, 0, 0, ScreenScale(3))
            btn:SetText("")
            btn.HoverLerp = 0
            btn.Paint = function(s, w, h)
                s.HoverLerp = Lerp(FrameTime() * 8, s.HoverLerp or 0, (s:IsHovered() and not (currentLoadout.skillset == id)) and 1 or 0)
                local v = s.HoverLerp
                local isSelected = (currentLoadout.skillset == id)
                local bgColor = isSelected and THEME.selected_bg or THEME.bg_card
                if v > 0.01 and not isSelected then
                    bgColor = LerpColor(v, THEME.bg_card, THEME.hover_bg)
                end
                draw.RoundedBox(4, 0, 0, w, h, bgColor)
                -- Hover glow effect
                if v > 0.01 and not isSelected then
                    surface.SetDrawColor(THEME.accent_red_glow)
                    draw.RoundedBox(4, -v * 1.5, -v * 1.5, w + v * 3, h + v * 3, THEME.accent_red_glow)
                    -- Shine sweep
                    local sweepX = (CurTime() * 200) % (w + 40) - 20
                    surface.SetDrawColor(255, 255, 255, v * 20)
                    surface.DrawRect(sweepX, 0, 20, h)
                end
                if isSelected then
                    surface.SetDrawColor(THEME.selected_border)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                    surface.SetDrawColor(THEME.accent_red)
                    surface.DrawRect(0, 2, 3, h - 4)
                else
                    surface.SetDrawColor(THEME.border)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                end
                draw.SimpleText(info.name .. " (" .. info.cost .. " pts)", "ZCity_Veteran", ScreenScale(10), h/2, isSelected and THEME.accent_white or THEME.text_primary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                if isSelected then
                    draw.SimpleText("✓", "ZCity_Veteran", w - ScreenScale(10), h / 2, THEME.accent_red, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end
            end
            btn.DoClick = function()
                local oldSkillset = currentLoadout.skillset
                local costDiff = info.cost - (Skillsets[oldSkillset] and Skillsets[oldSkillset].cost or 0)
                if currentPoints + costDiff > maxPoints then
                    surface.PlaySound("buttons/button10.wav")
                    return
                end
                currentLoadout.skillset = id
                SaveLoadout()
                RefreshLoadoutUI()
                sound.PlayFile("sound/press.mp3", "noblock", function(station) if IsValid(station) then station:Play() end end)
            end
        end

        AddCategory("WEAPONS & ITEMS")
        for _, id in ipairs(itemOrder) do
            local info = TraitorItems[id]
            local btn = vgui.Create("DButton", loadoutScroll)
            btn:Dock(TOP)
            btn:SetTall(ScreenScale(24))
            btn:DockMargin(0, 0, 0, ScreenScale(3))
            btn:SetText("")
            btn.HoverLerp = 0
            btn.Paint = function(s, w, h)
                s.HoverLerp = Lerp(FrameTime() * 8, s.HoverLerp or 0, (s:IsHovered() and not table.HasValue(currentLoadout.weapons, id) and not HasWeaponConflict(currentLoadout.weapons, id)) and 1 or 0)
                local v = s.HoverLerp
                local isSelected = table.HasValue(currentLoadout.weapons, id)
                local isDisabled = not isSelected and HasWeaponConflict(currentLoadout.weapons, id)
                local bgColor = isSelected and THEME.selected_bg or THEME.bg_card
                if v > 0.01 and not isSelected and not isDisabled then
                    bgColor = LerpColor(v, THEME.bg_card, THEME.hover_bg)
                end
                draw.RoundedBox(4, 0, 0, w, h, bgColor)
                -- Hover glow effect
                if v > 0.01 and not isSelected and not isDisabled then
                    surface.SetDrawColor(THEME.accent_red_glow)
                    draw.RoundedBox(4, -v * 1.5, -v * 1.5, w + v * 3, h + v * 3, THEME.accent_red_glow)
                    local sweepX = (CurTime() * 200) % (w + 40) - 20
                    surface.SetDrawColor(255, 255, 255, v * 20)
                    surface.DrawRect(sweepX, 0, 20, h)
                end
                if isDisabled then
                    surface.SetDrawColor(0, 0, 0, 150)
                    draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, 150))
                end
                if isSelected then
                    surface.SetDrawColor(THEME.selected_border)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                    surface.SetDrawColor(THEME.accent_red)
                    surface.DrawRect(0, 2, 3, h - 4)
                else
                    surface.SetDrawColor(THEME.border)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                end
                draw.SimpleText(info.name .. " (" .. info.cost .. " pts)", "ZCity_Veteran", ScreenScale(8), h/2, isDisabled and THEME.text_dim or THEME.text_primary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                if isSelected then
                    draw.SimpleText("✓", "ZCity_Veteran", w - ScreenScale(8), h / 2, THEME.accent_red, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end
            end
            btn.DoRightClick = function()
                previewWeaponId = id
                UpdatePreviewPanel()
                sound.PlayFile("sound/press.mp3", "noblock", function(station) if IsValid(station) then station:Play() end end)
            end
            btn.DoClick = function()
                local isDisabled = not table.HasValue(currentLoadout.weapons, id) and HasWeaponConflict(currentLoadout.weapons, id)
                if isDisabled then
                    surface.PlaySound("buttons/button10.wav")
                    return
                end
                if table.HasValue(currentLoadout.weapons, id) then
                    table.RemoveByValue(currentLoadout.weapons, id)
                    if id == "weapon_p22" then
                        for _, addonId in ipairs(P22AddonOrder) do
                            table.RemoveByValue(currentLoadout.weapons, addonId)
                        end
                    end
                    if previewWeaponId == id then
                        previewWeaponId = nil
                    end
                else
                    if currentPoints + info.cost > maxPoints then
                        surface.PlaySound("buttons/button10.wav")
                        return
                    end
                    table.insert(currentLoadout.weapons, id)
                    previewWeaponId = id
                end
                SaveLoadout()
                RefreshLoadoutUI()
                sound.PlayFile("sound/press.mp3", "noblock", function(station) if IsValid(station) then station:Play() end end)
            end

            if id == "weapon_p22" and table.HasValue(currentLoadout.weapons, "weapon_p22") then
                for _, addonId in ipairs(P22AddonOrder) do
                    local addonInfo = TraitorAddons[addonId]
                    if addonInfo then
                        local addonBtn = vgui.Create("DButton", loadoutScroll)
                        addonBtn:Dock(TOP)
                        addonBtn:SetTall(ScreenScale(18))
                        addonBtn:DockMargin(ScreenScale(10), 0, 0, ScreenScale(2))
                        addonBtn:SetText("")
                        addonBtn.HoverLerp = 0
                        addonBtn.Paint = function(s, w, h)
                            s.HoverLerp = Lerp(FrameTime() * 8, s.HoverLerp or 0, (s:IsHovered() and not table.HasValue(currentLoadout.weapons, addonId)) and 1 or 0)
                            local v = s.HoverLerp
                            local isSelected = table.HasValue(currentLoadout.weapons, addonId)
                            local bgColor = isSelected and THEME.selected_bg or Color(20, 20, 28, 180)
                            if v > 0.01 and not isSelected then
                                bgColor = LerpColor(v, Color(20, 20, 28, 180), THEME.hover_bg)
                            end
                            draw.RoundedBox(4, 0, 0, w, h, bgColor)
                            if v > 0.01 and not isSelected then
                                surface.SetDrawColor(THEME.accent_red_glow)
                                draw.RoundedBox(4, -v, -v, w + v * 2, h + v * 2, THEME.accent_red_glow)
                                local sweepX = (CurTime() * 200) % (w + 40) - 20
                                surface.SetDrawColor(255, 255, 255, v * 15)
                                surface.DrawRect(sweepX, 0, 20, h)
                            end
                            if isSelected then
                                surface.SetDrawColor(THEME.selected_border)
                                surface.DrawOutlinedRect(0, 0, w, h, 1)
                            else
                                surface.SetDrawColor(THEME.border)
                                surface.DrawOutlinedRect(0, 0, w, h, 1)
                            end
                            draw.SimpleText("↳ " .. addonInfo.name .. " (" .. addonInfo.cost .. " pts)", "ZCity_Veteran", ScreenScale(8), h / 2, isSelected and THEME.text_primary or THEME.text_secondary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                            if isSelected then
                                draw.SimpleText("✓", "ZCity_Veteran", w - ScreenScale(8), h / 2, THEME.accent_red, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                            end
                        end
                        addonBtn.DoClick = function()
                            if not table.HasValue(currentLoadout.weapons, "weapon_p22") then
                                surface.PlaySound("buttons/button10.wav")
                                return
                            end
                            if table.HasValue(currentLoadout.weapons, addonId) then
                                table.RemoveByValue(currentLoadout.weapons, addonId)
                            else
                                if currentPoints + addonInfo.cost > maxPoints then
                                    surface.PlaySound("buttons/button10.wav")
                                    return
                                end
                                table.insert(currentLoadout.weapons, addonId)
                            end
                            previewWeaponId = "weapon_p22"
                            SaveLoadout()
                            RefreshLoadoutUI()
                            sound.PlayFile("sound/press.mp3", "noblock", function(station) if IsValid(station) then station:Play() end end)
                        end
                    end
                end
            end
        end
    end
    RefreshLoadoutUI()

    local bottomPanel = vgui.Create("DPanel", rightPanel)
    bottomPanel:Dock(BOTTOM)
    bottomPanel:SetTall(ScreenScale(36))
    bottomPanel:DockMargin(ScreenScale(10), 0, ScreenScale(10), ScreenScale(10))
    bottomPanel.Paint = function(s, w, h)
        surface.SetDrawColor(THEME.border)
        surface.DrawRect(0, 0, w, 1)
    end

    local btnReturn = vgui.Create("DButton", bottomPanel)
    btnReturn:Dock(RIGHT)
    btnReturn:DockMargin(0, ScreenScale(6), ScreenScale(10), ScreenScale(6))
    btnReturn:SetText("RETURN")
    btnReturn:SetFont("ZCity_Veteran")
    btnReturn:SetTextColor(THEME.text_primary)
    btnReturn:SizeToContentsX()
    btnReturn:SetWide(btnReturn:GetWide() + ScreenScale(24))
    btnReturn.HoverLerp = 0
    btnReturn.Paint = function(s, w, h)
        s.HoverLerp = Lerp(FrameTime() * 8, s.HoverLerp or 0, s:IsHovered() and 1 or 0)
        local v = s.HoverLerp
        local bgColor = Color(Lerp(v, 40, 200), Lerp(v, 40, 60), Lerp(v, 50, 60), Lerp(v, 200, 220))
        draw.RoundedBox(4, 0, 0, w, h, bgColor)
        if v > 0.01 then
            surface.SetDrawColor(THEME.accent_red_glow)
            draw.RoundedBox(4, -v * 2, -v * 2, w + v * 4, h + v * 4, THEME.accent_red_glow)
            local sweepX = (CurTime() * 200) % (w + 40) - 20
            surface.SetDrawColor(255, 255, 255, v * 30)
            surface.DrawRect(sweepX, 0, 20, h)
        end
        surface.SetDrawColor(THEME.border_bright)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    btnReturn.DoClick = function()
        sound.PlayFile("sound/press.mp3", "noblock", function(station) if IsValid(station) then station:Play() end end)
        self:SwitchToMain()
    end

    local btnClear = vgui.Create("DButton", bottomPanel)
    btnClear:Dock(RIGHT)
    btnClear:DockMargin(0, ScreenScale(6), ScreenScale(10), ScreenScale(6))
    btnClear:SetText("CLEAR")
    btnClear:SetFont("ZCity_Veteran")
    btnClear:SetTextColor(THEME.accent_red)
    btnClear:SizeToContentsX()
    btnClear:SetWide(btnClear:GetWide() + ScreenScale(24))
    btnClear.HoverLerp = 0
    btnClear.Paint = function(s, w, h)
        s.HoverLerp = Lerp(FrameTime() * 8, s.HoverLerp or 0, s:IsHovered() and 1 or 0)
        local v = s.HoverLerp
        local bgColor = Color(Lerp(v, 50, 220), Lerp(v, 30, 40), Lerp(v, 30, 40), Lerp(v, 200, 220))
        draw.RoundedBox(4, 0, 0, w, h, bgColor)
        if v > 0.01 then
            surface.SetDrawColor(255, 50, 50, v * 60)
            draw.RoundedBox(4, -v * 2, -v * 2, w + v * 4, h + v * 4, Color(255, 50, 50, v * 60))
            local sweepX = (CurTime() * 200) % (w + 40) - 20
            surface.SetDrawColor(255, 100, 100, v * 30)
            surface.DrawRect(sweepX, 0, 20, h)
        end
        surface.SetDrawColor(Color(200, 80, 80, 180))
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    btnClear.DoClick = function()
        currentLoadout.weapons = {}
        currentLoadout.skillset = "none"
        previewWeaponId = nil
        SaveLoadout()
        RefreshLoadoutUI()
        sound.PlayFile("sound/press.mp3", "noblock", function(station) if IsValid(station) then station:Play() end end)
    end

    local btnGoToPresets = vgui.Create("DButton", bottomPanel)
    btnGoToPresets:Dock(RIGHT)
    btnGoToPresets:DockMargin(0, ScreenScale(6), ScreenScale(10), ScreenScale(6))
    btnGoToPresets:SetText("PRESETS")
    btnGoToPresets:SetFont("ZCity_Veteran")
    btnGoToPresets:SetTextColor(THEME.text_primary)
    btnGoToPresets:SizeToContentsX()
    btnGoToPresets:SetWide(btnGoToPresets:GetWide() + ScreenScale(24))
    btnGoToPresets.HoverLerp = 0
    btnGoToPresets.Paint = function(s, w, h)
        s.HoverLerp = Lerp(FrameTime() * 8, s.HoverLerp or 0, s:IsHovered() and 1 or 0)
        local v = s.HoverLerp
        local bgColor = Color(Lerp(v, 40, 200), Lerp(v, 40, 60), Lerp(v, 50, 60), Lerp(v, 200, 220))
        draw.RoundedBox(4, 0, 0, w, h, bgColor)
        if v > 0.01 then
            surface.SetDrawColor(THEME.accent_red_glow)
            draw.RoundedBox(4, -v * 2, -v * 2, w + v * 4, h + v * 4, THEME.accent_red_glow)
            local sweepX = (CurTime() * 200) % (w + 40) - 20
            surface.SetDrawColor(255, 255, 255, v * 30)
            surface.DrawRect(sweepX, 0, 20, h)
        end
        surface.SetDrawColor(THEME.border_bright)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    btnGoToPresets.DoClick = function()
        if self.LastSwitchTime and CurTime() - self.LastSwitchTime < 1 then return end
        self.LastSwitchTime = CurTime()
        sound.PlayFile("sound/press.mp3", "noblock", function(station) if IsValid(station) then station:Play() end end)
        self:SwitchToTraitorPresets()
    end
end

function PANEL:CreateAppearancePanel()
    if IsValid(self.AppearancePanel) then return end

    if hg.Appearance.PrecacheModels then
        hg.Appearance.PrecacheModels()
    end
    
    self.AppearancePanel = vgui.Create("ZAppearance", self)
    self.AppearancePanel:SetSize(ScrW(), ScrH())
    self.AppearancePanel:SetPos(0, 0)
    self.AppearancePanel:SetAlpha(0)
    self.AppearancePanel:SetVisible(false)
    
    -- Custom behavior for embedded panel
    self.AppearancePanel.IsEmbedded = true
    
    -- Override Close to switch back to main
    local oldClose = self.AppearancePanel.Close
    self.AppearancePanel.Close = function(pnl)
        -- Save appearance to file
        local currentAppearance = self.AppearancePanel.AppearanceTable
        if currentAppearance and hg.Appearance then
             local fileName = hg.Appearance.SelectedAppearance and hg.Appearance.SelectedAppearance:GetString() or "main"
             if fileName == "" then fileName = "main" end
             
             hg.Appearance.CreateAppearanceFile(fileName, currentAppearance)

             -- Send to server to apply immediately
             net.Start("Get_Appearance")
                 net.WriteTable(currentAppearance)
                 net.WriteBool(false) -- Not random
             net.SendToServer()
        end

        -- Don't actually remove, just switch state
        self:SwitchToMain()
    end
end

function PANEL:OnRemove()
    if LocalPlayer and IsValid(LocalPlayer()) then
        LocalPlayer():SetDSP(0) -- Reset DSP
    end
    
    if IsValid(ZCityMainMenuMusic) then
        ZCityMainMenuMusic:Pause()
    end
    
    if IsValid(ZCityAppearanceMusic) then
        ZCityAppearanceMusic:Stop()
    end

    if IsValid(ZCityIntroMusic) then
        ZCityIntroMusic:Stop()
    end
end

--[[
["5.42.211.48:24215"]:
		["addr"]	=	5.42.211.48:24215
		["map"]	=	hmcd_metropolis_extended
		["max_players"]	=	20
		["name"]	=	Z-City 1 | Beta | RU
		["players"]	=	20
["5.42.211.48:24217"]:
		["addr"]	=	5.42.211.48:24217
		["map"]	=	hmcd_metropolis_extended
		["max_players"]	=	20
		["name"]	=	Z-City 2 | Beta | RU
		["players"]	=	18
]]
local cardcolor = Color(15,15,25,220)
local green_color = Color(55,225,55)
function PANEL:AddServerCard(serverTbl)
    local main = self
    local card = vgui.Create("DPanel",self.rDock)
    card:Dock(TOP)
    card:SetSize(500,ScreenScaleH(45))
    card:DockMargin(5,5,5,5)
    card:DockPadding(15,5,15,15)
    card.Info = serverTbl
    function card:Paint(w,h)
        draw.RoundedBox( 4, 0, 0, w, h, cardcolor )

        draw.RoundedBox( 0, 0, h-h/5, w, h/5, cardcolor )
        draw.RoundedBox( 0, 2.5, h-h/5 +3, w* (card.Info["players"]/card.Info["max_players"]) - 5 , h/6, color_red )
    end

    local lbl = vgui.Create("DLabel",card)
    lbl:Dock(BOTTOM)
    lbl:SetFont("ZCity_Tiny")
    lbl:SetText(card.Info["players"].."/"..card.Info["max_players"])
    lbl:SizeToContents()
    lbl:SetTall(ScreenScaleH(17))

    local lbl = vgui.Create("DLabel",card)
    lbl:Dock(LEFT)
    lbl:SetFont("ZCity_Small")
    lbl:SetText(string.lower(card.Info["name"]))
    lbl:SizeToContents()
    lbl:SetTall(ScreenScaleH(19))

    local connectButton = vgui.Create("DButton",card)
    connectButton:Dock(RIGHT)
    connectButton:SetFont("ZCity_Small")
    connectButton:SetText("connect")
    connectButton:SizeToContents()
    connectButton:SetTall(ScreenScaleH(19))
    connectButton.HoverLerp = 0
    connectButton.RColor = Color(255,255,255)
    function connectButton:Paint(w,h)
        return false
    end

    function connectButton:Think()
        self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, self:IsHovered() and 1 or 0)
        local v = self.HoverLerp
        self:SetTextColor( self.RColor:Lerp( green_color, v ) )
    end

    function connectButton:DoClick()
        permissions.AskToConnect( card.Info["addr"] )
    end
end

function PANEL:First( ply )
    --self:MoveTo(self:GetX(), self:GetY() - self:GetTall()/2, 0.5, 0, 0.2, function() end)
    self:AlphaTo( 255, 0.1, 0, nil )
end

local gradient_d = surface.GetTextureID("vgui/gradient-d")
local gradient_r = surface.GetTextureID("vgui/gradient-r")
local gradient_l = surface.GetTextureID("vgui/gradient-l")

function PANEL:Paint(w,h)
    -- Black Background Layer (Always behind everything)
    surface.SetDrawColor(0, 0, 0, 255)
    surface.DrawRect(0, 0, w, h)
    
    -- Transition Logic for Backgrounds
    local progress = 0
    if self.TargetState == "Settings" or self.TargetState == "Appearance" or self.TargetState == "Achievements" or self.TargetState == "TraitorMenu" or self.TargetState == "TraitorPresets" then
        progress = self.TransitionProgress
    elseif self.TargetState == "Main" then
        progress = 1 - self.TransitionProgress
    end
    local imageTransitionShakeX = self.TransitionImageShakeX or 0
    local imageTransitionShakeY = self.TransitionImageShakeY or 0
    
    -- Main Background
    if progress < 1 or self.TargetState == "Appearance" or self.TargetState == "TraitorMenu" or self.TargetState == "TraitorPresets" then
        -- Keep drawing if we are going to these menus
        surface.SetDrawColor( 80, 80, 80, 255 )
        if self.TargetState == "Settings" or (self.TargetState == "Main" and self.CurrentState == "Settings") or self.TargetState == "Achievements" or (self.TargetState == "Main" and self.CurrentState == "Achievements") then
             surface.SetDrawColor( 80, 80, 80, 255 * (1 - progress) )
        elseif self.TargetState == "TraitorMenu" or (self.TargetState == "Main" and self.CurrentState == "TraitorMenu") or self.TargetState == "TraitorPresets" or (self.TargetState == "Main" and self.CurrentState == "TraitorPresets") then
             surface.SetDrawColor( 80, 80, 80, 255 )
        end
        
        local mat = BgMat
        if self.IsIntro then mat = EyeMat end

        if not mat:IsError() then
            surface.SetMaterial( mat )
            local scale = 1.1
            local zoomedW, zoomedH = w * scale, h * scale
            local offsetX, offsetY
            if self.TargetState == "Settings" or (self.TargetState == "Main" and self.CurrentState == "Settings") then
                offsetX = (w - zoomedW) / 2 - (w * progress)
                offsetY = (h - zoomedH) / 2
            elseif self.TargetState == "Appearance" or (self.TargetState == "Main" and self.CurrentState == "Appearance") then
                offsetX = (w - zoomedW) / 2
                offsetY = (h - zoomedH) / 2 - (h * progress)
            elseif self.TargetState == "Achievements" or (self.TargetState == "Main" and self.CurrentState == "Achievements") then
                offsetX = (w - zoomedW) / 2 + (w * progress)
                offsetY = (h - zoomedH) / 2
            elseif self.TargetState == "TraitorMenu" or (self.TargetState == "Main" and self.CurrentState == "TraitorMenu") or self.TargetState == "TraitorPresets" or (self.TargetState == "Main" and self.CurrentState == "TraitorPresets") then
                -- Move the main background DOWN as camera moves UP
                offsetX = (w - zoomedW) / 2
                offsetY = (h - zoomedH) / 2 + (h * progress)
            else
                offsetX = (w - zoomedW) / 2
                offsetY = (h - zoomedH) / 2
            end
            
            local shakeX = math.random(-2, 2)
            local shakeY = math.random(-2, 2)
            
            surface.DrawTexturedRect(offsetX + shakeX + imageTransitionShakeX, offsetY + shakeY + imageTransitionShakeY, zoomedW, zoomedH)
        end
    end
    
    -- Background 2 (Settings) - Moves In from Right
    if progress > 0 and (self.TargetState == "Settings" or (self.TargetState == "Main" and self.CurrentState == "Settings")) then
        surface.SetDrawColor( 80, 80, 80, 255 * progress )
        if not BgMat2:IsError() then
            surface.SetMaterial( BgMat2 )
            local scale = 1.1
            local zoomedW, zoomedH = w * scale, h * scale
            local offsetX = (w - zoomedW) / 2 + (w * (1 - progress))
            local offsetY = (h - zoomedH) / 2
            
            local shakeX = math.random(-2, 2)
            local shakeY = math.random(-2, 2)
            
            surface.DrawTexturedRect(offsetX + shakeX + imageTransitionShakeX, offsetY + shakeY + imageTransitionShakeY, zoomedW, zoomedH)
        end
    end

    -- Background 3 (Appearance)
    if progress > 0 and (self.TargetState == "Appearance" or (self.TargetState == "Main" and self.CurrentState == "Appearance")) then
        surface.SetDrawColor( 80, 80, 80, 255 * progress )
        if not BgMat3:IsError() then
            surface.SetMaterial( BgMat3 )
            local scale = 1.1
            local zoomedW, zoomedH = w * scale, h * scale
            local offsetX = (w - zoomedW) / 2
            local sep = h * 0.12
            local offsetY
            if self.TargetState == "Appearance" then
                offsetY = (h - zoomedH) / 2 + sep + (h * (1 - progress))
            else
                offsetY = (h - zoomedH) / 2 + sep + h
            end
            
            local shakeX = math.random(-2, 2)
            local shakeY = math.random(-2, 2)
            
            surface.DrawTexturedRect(offsetX + shakeX + imageTransitionShakeX, offsetY + shakeY + imageTransitionShakeY, zoomedW, zoomedH)
        end
    end

    if progress > 0 and (self.TargetState == "TraitorMenu" or (self.TargetState == "Main" and self.CurrentState == "TraitorMenu") or self.TargetState == "TraitorPresets" or (self.TargetState == "Main" and self.CurrentState == "TraitorPresets")) then
        surface.SetDrawColor( 255, 255, 255, 255 * progress )
        if self.TargetState == "TraitorPresets" and self.CurrentState == "TraitorMenu" then
            surface.SetDrawColor( 255, 255, 255, 255 )
        elseif self.TargetState == "TraitorMenu" and self.CurrentState == "TraitorPresets" then
            surface.SetDrawColor( 255, 255, 255, 255 )
        end

        local bgMat5 = Material("vgui/background5.png")
        if not bgMat5:IsError() then
            surface.SetMaterial( bgMat5 )
            local scale = 1.1
            local zoomedW, zoomedH = w * scale, h * scale
            local offsetX = (w - zoomedW) / 2
            
            -- If viewpoint moves UP, background moves DOWN. 
            -- Starts at -h (above screen) and moves to 0.
            local offsetY = (h - zoomedH) / 2 - h * (1 - progress)
            
            if (self.TargetState == "TraitorPresets" and self.CurrentState == "TraitorMenu") or (self.TargetState == "TraitorMenu" and self.CurrentState == "TraitorPresets") then
                offsetY = (h - zoomedH) / 2
            end

            local shakeX = math.random(-2, 2)
            local shakeY = math.random(-2, 2)
            
            surface.DrawTexturedRect(offsetX + shakeX + imageTransitionShakeX, offsetY + shakeY + imageTransitionShakeY, zoomedW, zoomedH)
        end
    end

    if progress > 0 and (self.TargetState == "Achievements" or (self.TargetState == "Main" and self.CurrentState == "Achievements")) then
        if not BgMat4:IsError() then
            surface.SetMaterial(BgMat4)
            local scale = 1.1
            local zoomedW, zoomedH = w * scale, h * scale
            local offsetX = (w - zoomedW) / 2 - (w * (1 - progress))
            local offsetY = (h - zoomedH) / 2
            local shakeX = math.random(-2, 2)
            local shakeY = math.random(-2, 2)
            surface.SetDrawColor(255, 255, 255, 255 * progress)
            surface.DrawTexturedRect(offsetX + shakeX + imageTransitionShakeX, offsetY + shakeY + imageTransitionShakeY, zoomedW, zoomedH)
        end

        if not BgMat4Overlay:IsError() then
            surface.SetMaterial(BgMat4Overlay)
            local scale = 1.1
            local zoomedW, zoomedH = w * scale, h * scale
            local offsetX = (w - zoomedW) / 2 - (w * (1 - progress))
            local offsetY = (h - zoomedH) / 2
            local shakeX = math.random(-2, 2)
            local shakeY = math.random(-2, 2)
            surface.SetDrawColor(255, 255, 255, 200 * progress)
            surface.DrawTexturedRect(offsetX + shakeX + imageTransitionShakeX, offsetY + shakeY + imageTransitionShakeY, zoomedW, zoomedH)
        end
    end

    
    -- Draw Flashing Image (Bottom Right in Settings) - BEFORE VHS
    if self.CurrentFlashImage and type(self.CurrentFlashImage) == "IMaterial" and not self.CurrentFlashImage:IsError() and self.FlashAlpha > 0 and (self.TargetState == "Settings" or self.CurrentState == "Settings") then
        surface.SetDrawColor(80, 80, 80, self.FlashAlpha) -- Made darker (150 -> 80)
        surface.SetMaterial(self.CurrentFlashImage)
        
        -- Made wider as requested (160 vs 128)
        local imgW = ScreenScale(160) 
        -- Made taller as requested (180 vs 128)
        local imgH = ScreenScale(180)
        
        -- Slide offset to move with Settings background
        local slideOffset = w * (1 - progress)
        
        -- Located directly at bottom right corner (no margin) + slide offset
        local imgX = (w - imgW) + slideOffset
        local imgY = h - imgH
        
        -- Micro Shakes
        local shakeX = math.random(-2, 2)
        local shakeY = math.random(-2, 2)
        
        surface.DrawTexturedRect(imgX + shakeX + imageTransitionShakeX, imgY + shakeY + imageTransitionShakeY, imgW, imgH)
    end

    -- VHS Static Effect (On top of backgrounds AND flashing images)
    surface.SetMaterial(NoiseMat)
    -- Reset to white/transparent to let the material handle the look, slightly transparent
    surface.SetDrawColor(255, 255, 255, 40) 
    local noiseU = math.random()
    local noiseV = math.random()
    surface.DrawTexturedRectUV(0, 0, w, h, noiseU, noiseV, noiseU + (w/256), noiseV + (h/256))
    
    -- Occasional stronger glitch line
    if math.random() > 0.995 then
        surface.SetDrawColor(60, 60, 60, 50)
        surface.DrawRect(0, math.random(0, h), w, math.random(1, 2))
    end
    
    -- Enhanced Title with improved visibility and design
    local text1 = "meleecity: delicacy"
    
    surface.SetFont("ZC_MM_Title")
    local titleW, titleH = surface.GetTextSize(text1)
    
    -- Title alpha and color animation
    local time = CurTime()
    local titleAlpha = 255
    local titleColorR, titleColorG, titleColorB = 255, 255, 255
    
    -- Red pulse effect periodically
    local pulseCycle = math.sin(time * 0.8)
    if pulseCycle > 0.7 then
        local intensity = (pulseCycle - 0.7) / 0.3
        titleColorR = 255
        titleColorG = math.Clamp(255 - intensity * 200, 55, 255)
        titleColorB = math.Clamp(255 - intensity * 200, 55, 255)
    end
    
    -- Title shake effect (subtle)
    local textShakeX = math.sin(time * 1.5) * 0.5
    local textShakeY = math.cos(time * 1.2) * 0.3
    if math.random() > 0.95 then
        textShakeX = textShakeX + math.random(-2, 2)
        textShakeY = textShakeY + math.random(-1, 1)
    end
    
    -- Title position with transition handling
    local titleX = self.LogoX
    local titleY = self.LogoY
    
    -- Ensure title is always visible in main state
    if self.CurrentState == "Main" or self.TargetState == "Main" then
        if self.TargetState == "Appearance" then
            titleY = self.LogoY - ScrH() * progress
            titleAlpha = 255 * (1 - progress)
        elseif self.TargetState == "TraitorMenu" or self.TargetState == "TraitorPresets" then
            titleY = self.LogoY + ScrH() * progress
            titleAlpha = 255 * (1 - progress)
        end
    elseif self.CurrentState ~= "Main" and self.TargetState ~= "Main" then
        if (self.CurrentState == "TraitorMenu" or self.CurrentState == "TraitorPresets") and (self.TargetState == "TraitorMenu" or self.TargetState == "TraitorPresets") then
            titleAlpha = 0 -- Hide title in traitor menu
        elseif self.CurrentState == "Settings" or self.TargetState == "Settings" then
            titleY = self.LogoY
            titleAlpha = 255
        elseif self.CurrentState == "Achievements" or self.TargetState == "Achievements" then
            titleY = self.LogoY
            titleAlpha = 255
        else
            titleAlpha = 0
        end
    end
    
    -- Draw title shadow/glow
    if titleAlpha > 10 then
        -- Glow effect
        surface.SetTextColor(titleColorR, titleColorG, titleColorB, titleAlpha * 0.3)
        surface.SetTextPos(titleX + textShakeX + 2, titleY + textShakeY + 2)
        surface.DrawText(text1)
        surface.SetTextColor(titleColorR, titleColorG, titleColorB, titleAlpha * 0.15)
        surface.SetTextPos(titleX + textShakeX + 4, titleY + textShakeY + 4)
        surface.DrawText(text1)
        
        -- Main title text
        surface.SetTextColor(titleColorR, titleColorG, titleColorB, titleAlpha)
        surface.SetTextPos(titleX + textShakeX, titleY + textShakeY)
        surface.DrawText(text1)
        
        -- Subtitle/gamemode info below title
        local mapname = game.GetMap()
        local prefix = string.find(mapname, "_")
        if prefix then
            mapname = string.sub(mapname, prefix + 1)
        end
        local gm = string.lower(gmod.GetGamemode().Name .. " | " .. string.NiceName(zb ~= nil and zb.GetRoundName or mapname))
        
        surface.SetFont("ZCity_Veteran")
        local subW, subH = surface.GetTextSize(gm)
        surface.SetTextColor(160, 160, 175, titleAlpha * 0.7)
        surface.SetTextPos(titleX + textShakeX, titleY + titleH + ScreenScaleH(8) + textShakeY)
        surface.DrawText(gm)
        
        -- Decorative line under title
        local lineY = titleY + titleH + ScreenScaleH(4)
        surface.SetDrawColor(titleColorR, titleColorG, titleColorB, titleAlpha * 0.4)
        surface.DrawRect(titleX, lineY, titleW, 1)
        surface.SetDrawColor(titleColorR, titleColorG, titleColorB, titleAlpha * 0.15)
        surface.DrawRect(titleX, lineY + 2, titleW * 0.6, 1)
    end
    
    if self.IsIntro then
        local enterText = "press enter"
        surface.SetFont("ZCity_Veteran")
        local tw, th = surface.GetTextSize(enterText)
        local tx = w - tw - ScreenScale(20)
        local ty = h - th - ScreenScale(20)
        
        -- Blink logic
        local blinkSpeed = 2
        local alpha = math.abs(math.sin(CurTime() * blinkSpeed)) * 255
        
        surface.SetTextColor(255, 0, 0, alpha)
        surface.SetTextPos(tx, ty)
        surface.DrawText(enterText)
        
        -- Intro Sequence Fade to Black
        if self.IntroSequenceActive then
            local elapsedTime = CurTime() - self.IntroStartTime
            local duration = 3 -- Fade out duration
            local fadeAlpha = math.Clamp((elapsedTime / duration) * 255, 0, 255)
            
            surface.SetDrawColor(0, 0, 0, fadeAlpha)
            surface.DrawRect(0, 0, w, h)
            
            if elapsedTime >= duration then
                self:Close()
                
                -- Create Fade Out Panel (Black -> Clear)
                local fadePanel = vgui.Create("DPanel")
                fadePanel:SetSize(ScrW(), ScrH())
                fadePanel:MakePopup()
                fadePanel:SetKeyboardInputEnabled(false)
                fadePanel:SetMouseInputEnabled(false)
                fadePanel.StartTime = CurTime()
                fadePanel.Duration = 3
                
                function fadePanel:Paint(pw, ph)
                    local et = CurTime() - self.StartTime
                    local a = 255 - math.Clamp((et / self.Duration) * 255, 0, 255)
                    surface.SetDrawColor(0, 0, 0, a)
                    surface.DrawRect(0, 0, pw, ph)
                    
                    if et >= self.Duration then
                        self:Remove()
                    end
                end
                
                -- Mark intro as seen
                ZCityHasSeenIntro = true
            end
        end
    end
end

function PANEL:AddSelect( pParent, strTitle, tbl )
    local id = #self.Buttons + 1
    self.Buttons[id] = vgui.Create( "DLabel", pParent )
    local btn = self.Buttons[id]
    btn:SetText( strTitle )
    btn:SetMouseInputEnabled( true )
    btn:SetFont( "ZCity_Veteran" )
    btn:SizeToContents()
    btn:SetWide(btn:GetWide() + ScreenScale(8))
    btn:SetTall( math.max(ScreenScale(18), btn:GetTall()) )
    btn:SetPos(0, 0)
    btn:SetContentAlignment(4)
    btn.Func = tbl.Func
    btn.HoveredFunc = tbl.HoveredFunc
    local luaMenu = self 
    if tbl.CreatedFunc then tbl.CreatedFunc(btn, self, luaMenu) end
    
    function btn:DoClick()
        sound.PlayFile("sound/press.mp3", "noblock", function(station) if IsValid(station) then station:Play() end end)
        btn.Func(luaMenu)
    end

    function btn:Think() 
        self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, self:IsHovered() and 1 or 0) 
        if self.HoverLerp < 0.01 then self.HoverLerp = 0 end
        if self.HoverLerp > 0.99 then self.HoverLerp = 1 end

        local v = self.HoverLerp 
        local targetText = self:IsHovered() and string.upper(strTitle) or strTitle 
        local crw = self:GetText() 

        if crw ~= targetText then 
            local ntxt = "" 
            for i = 1, #strTitle do 
                local char = strTitle:sub(i, i) 
                if i <= math.ceil(#strTitle * v) then 
                    ntxt = ntxt .. string.upper(char) 
                else 
                    ntxt = ntxt .. char 
                end 
            end 
            if self:GetText() ~= ntxt then 
                self:SetText(ntxt) 
            end 
        end 
    end

    function btn:Paint(w, h)
        local font = self:GetFont()
        local text = self:GetText()
        surface.SetFont(font)
        local tw, th = surface.GetTextSize(text)
        
        -- Add padding to width for border
        local padding = ScreenScale(6)
        local totalW = tw + padding * 2

        if self:IsHovered() then
            if not self.HoveredSoundPlayed then
                sound.PlayFile("sound/hover.ogg", "noblock", function(station) if IsValid(station) then station:Play() end end)
                self.HoveredSoundPlayed = true
            end
            
            -- Enhanced hover effect with gradient and glow
            surface.SetDrawColor(THEME.hover_bg)
            draw.RoundedBox(3, 0, 0, totalW, h, THEME.hover_bg)
            
            -- Red accent line on left
            surface.SetDrawColor(THEME.accent_red)
            surface.DrawRect(0, 2, 2, h - 4)
            
            -- Subtle glow
            surface.SetDrawColor(THEME.accent_red_glow)
            draw.RoundedBox(3, 0, 0, totalW, h, THEME.accent_red_glow)
            
            self:SetTextColor(THEME.accent_white)
        else
            self.HoveredSoundPlayed = false
            self:SetTextColor(THEME.text_primary)
        end
        
        local offX, offY = 0, 0
        if math.random() > 0.92 then
             offX = math.random(-2, 2)
             offY = math.random(-2, 2)
        end
        
        draw.SimpleText(text, font, padding + offX, h/2 + offY, self:GetTextColor(), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        -- Glitch effect on hover
        if self:IsHovered() and math.random() > 0.85 then
            local offsetX = math.random(-4, 4)
            local offsetY = math.random(-1, 1)
            draw.SimpleText(text, font, padding + offsetX, h/2 + offsetY, Color(200, 50, 50, math.random(40, 100)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        return true
    end
end

function PANEL:Close()
    self:AlphaTo( 0, 0.1, 0, function() self:Remove() end)
    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)
end

vgui.Register( "ZMainMenu", PANEL, "ZFrame")

hook.Add("OnPauseMenuShow","OpenMainMenu",function()
    local run = hook.Run("OnShowZCityPause")
    if run then
        return run
    end

    if MainMenu and IsValid(MainMenu) then
        if MainMenu.IsIntro then
            return false -- Prevent closing intro menu with ESC
        end
        MainMenu:Close()
        MainMenu = nil
        return false
    end

    MainMenu = vgui.Create("ZMainMenu")
    MainMenu:MakePopup()
    return false
end)


hook.Add("InitPostEntity", "ZCityOpenIntroMenu", function()
    -- Use a timer to ensure everything is fully loaded before opening
    timer.Simple(1, function()
        if not ZCityHasSeenIntro then
            -- Open the menu automatically on join
            if MainMenu and IsValid(MainMenu) then MainMenu:Remove() end
            MainMenu = vgui.Create("ZMainMenu")
            MainMenu:MakePopup()
            -- Force intro state
            MainMenu.IsIntro = true
            MainMenu:SetAlpha(255) -- Force visible immediately
        end
    end)
end)

-- Force open on file refresh for testing (if not seen intro)
timer.Simple(0.1, function()
    if not ZCityHasSeenIntro and (not MainMenu or not IsValid(MainMenu)) then
        MainMenu = vgui.Create("ZMainMenu")
        MainMenu:MakePopup()
        MainMenu.IsIntro = true
        MainMenu:SetAlpha(255)
    end
end)
-- Note: Duplicate hooks removed - only one instance of each hook is needed
