
hg.achievements = hg.achievements or {}
hg.achievements.achievements_data = hg.achievements.achievements_data or {}
hg.achievements.achievements_data.player_achievements = hg.achievements.achievements_data.player_achievements or {}
hg.achievements.achievements_data.created_achevements = {}

concommand.Add("hg_achievements",function()
    if not IsValid(MainMenu) then
        MainMenu = vgui.Create("ZMainMenu")
        MainMenu:MakePopup()
    end
    if IsValid(MainMenu) and MainMenu.SwitchToAchievements then
        MainMenu:SwitchToAchievements()
    end
end)

local time_wait = 0
function hg.achievements.LoadAchievements()
    if time_wait > CurTime() then return end
    time_wait = CurTime() + 2

    net.Start("req_ach")
    net.SendToServer()
end

function hg.achievements.GetLocalAchievements()
    return hg.achievements.achievements_data.player_achievements[tostring(LocalPlayer():SteamID())]
end

net.Receive("req_ach",function()
    hg.achievements.achievements_data.created_achevements = net.ReadTable()
    hg.achievements.achievements_data.player_achievements[tostring(LocalPlayer():SteamID())] = net.ReadTable()
    
    if IsValid(MainMenu) and MainMenu.UpdateAchievementsList then
        MainMenu:UpdateAchievementsList()
    end
end)
hg.achievements.NewAchievements = hg.achievements.NewAchievements or {}
local AchTable = hg.achievements.NewAchievements 
net.Receive("hg_NewAchievement",function()
    local Ach = {time = CurTime() + 7.5,name = net.ReadString(),img = net.ReadString()}
    table.insert(AchTable,1,Ach)
	surface.PlaySound("homigrad/vgui/achievement_earned.wav")
    --sound.PlayURL("https://www.myinstants.com/media/sounds/achievement_earned.mp3","noblock",function(station)
    --    if IsValid(station) then
    --        station:Play()
    --    end 
    --end)
end)

-- AchTable[1] = {time = CurTime() + 991,name = "Hello Everyone",img = "achievements/marksman"}
-- AchTable[2] = {time = CurTime() + 992,name = "John 'Alabama' Slasher",img = "achievements/bloodysouvenir"}
-- AchTable[3] = {time = CurTime() + 993,name = "Nab",img = "achievements/toxicfumes"}
-- AchTable[4] = {time = CurTime() + 994,name = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis pulvinar, elit in eleifend euismod, massa metus eleifend massa",img = "achievements/bunny"}
-- AchTable[5] = {time = CurTime() + 995,name = "Hello Everyone",img = "homigrad/vgui/models/star.png"}
local gradient_u = Material("vgui/gradient-u")
local ach_clr1 , ach_clr2 = Color(200,25,25), Color(100,25,25)
hook.Add("HUDPaint","hg_NewAchievement", function()
    local frametime = FrameTime() * 10
    for i = 1, #AchTable do
        local ach = AchTable[i]
        if not ach then continue end
        local txt = "Achievement! "..ach.name
        ach.img = isstring(ach.img) and Material(ach.img) or ach.img
        local wt, _ = surface.GetTextSize(txt)

        ach.Lerp = Lerp( frametime, ach.Lerp or 0, math.min( ach.time - CurTime(), 1 ) * i )
        WSize, HSize = (ScrW() * 0.1) + (wt), ScrH() * 0.05
        local HPos = ScrH() - ( HSize * ach.Lerp )
        draw.RoundedBox( 0, 2, HPos + 2, WSize - 4, HSize - 4, ach_clr2 )
		
		surface.SetDrawColor(155, 0, 0, 255)
		surface.SetMaterial(gradient_u)
		surface.DrawTexturedRect( 0, HPos, WSize, HSize )
	
		surface.SetDrawColor( 150, 0, 0, 255)
		surface.DrawOutlinedRect( 0, HPos, WSize, HSize, 2.5 )

        surface.SetFont("HomigradFontMedium")
        surface.SetTextColor(255,255,255)
        surface.SetTextPos(HSize*1.25,(HPos + ( HSize/2 ) - ( HSize/4 )) )
        surface.DrawText(txt)
        surface.SetDrawColor(255,255,255)
        surface.SetMaterial(ach.img)
        surface.DrawTexturedRect(2,HPos+2,HSize-4,HSize-4)
        if ach.time < CurTime() then 
            table.remove(AchTable,i)
            --PrintTable(AchTable)
        end
    end
end)
