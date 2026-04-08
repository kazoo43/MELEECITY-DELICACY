if SERVER then
	AddCSLuaFile()
	return
end

hg = hg or {}
hg.MouseMinigame = hg.MouseMinigame or {}

local MouseMinigame = hg.MouseMinigame
local math_abs = math.abs
local math_Clamp = math.Clamp
local math_deg = math.deg
local math_atan = math.atan
local CurTime = CurTime
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRect = surface.DrawTexturedRect
local draw_SimpleText = draw.SimpleText
local draw_RoundedBox = draw.RoundedBox
local cam_Start2D = cam.Start2D
local cam_End2D = cam.End2D

MouseMinigame.MaterialSets = MouseMinigame.MaterialSets or {}
local function IsMatError(mat)
	if not mat then return true end
	if isfunction(mat.IsError) then
		return mat:IsError()
	end
	return false
end

local function LoadMinigameMaterial(path)
	local mat = Material(path, "smooth")
	if IsMatError(mat) and string.EndsWith(path, ".png") then
		mat = Material(string.StripExtension(path), "smooth")
	end
	return mat
end

MouseMinigame.MaterialSets.circle = MouseMinigame.MaterialSets.circle or {
	LoadMinigameMaterial("mouseminigame/pc_mouse_circle_1.png"),
	LoadMinigameMaterial("mouseminigame/pc_mouse_circle_2.png"),
	LoadMinigameMaterial("mouseminigame/pc_mouse_circle_3.png"),
	LoadMinigameMaterial("mouseminigame/pc_mouse_circle_4.png"),
	LoadMinigameMaterial("mouseminigame/pc_mouse_circle_5.png"),
}
local bandageCircleClasses = {
	["weapon_bandage_sh"] = true,
	["weapon_bigbandage_sh"] = true,
}
local bandageNetDone = "hg_bandage_circle_done"
local bandageLMBDown = false
local bandageRMBDown = false
MouseMinigame.BlockStartLMB = MouseMinigame.BlockStartLMB or false
MouseMinigame.BlockStartRMB = MouseMinigame.BlockStartRMB or false
MouseMinigame.RawMouseDX = MouseMinigame.RawMouseDX or 0
MouseMinigame.RawMouseDY = MouseMinigame.RawMouseDY or 0

local function NormalizeAngleDelta(delta)
	if delta > 180 then
		return delta - 360
	end
	if delta < -180 then
		return delta + 360
	end
	return delta
end

local function AngleFromDelta(dx, dy)
	if dx == 0 and dy == 0 then return 0 end
	if dx == 0 then
		return dy > 0 and 90 or 270
	end

	local ang = math_deg(math_atan(dy / dx))
	if dx < 0 then
		ang = ang + 180
	elseif dy < 0 then
		ang = ang + 360
	end

	return ang
end

local function GetDefaultSession(config)
	local size = config.size or 140
	local topMargin = config.topMargin or 110
	local leftMargin = config.leftMargin or 95
	local centerX = leftMargin + size * 0.5
	local centerY = topMargin + size * 0.5
	local radius = size * 0.42
	local ringTolerance = size * 0.72

	return {
		id = config.id or "default",
		mode = config.mode or "circle",
		title = config.title or "",
		requiredLoops = math.max(1, math.floor(config.requiredLoops or 1)),
		completedLoops = 0,
		accumulatedAngle = 0,
		lastAngle = nil,
		startedAt = CurTime(),
		openedAt = CurTime(),
		attackWasDown = true,
		cancelMouseDown = true,
		requiredDirection = config.requiredDirection or 1,
		startAngle = config.startAngle or 0,
		startTolerance = config.startTolerance or 55,
		armed = true,
		weapon = config.weapon,
		weaponClass = config.weaponClass,
		lockedAngles = config.lockedAngles and Angle(config.lockedAngles.p, config.lockedAngles.y, config.lockedAngles.r) or nil,
		onSuccess = config.onSuccess,
		onCancel = config.onCancel,
		allowMovement = config.allowMovement ~= false,
		size = size,
		topMargin = topMargin,
		leftMargin = leftMargin,
		centerX = centerX,
		centerY = centerY,
		radius = radius,
		ringTolerance = ringTolerance,
		cursorX = centerX + radius,
		cursorY = centerY,
		cursorClamp = radius * 4.6,
		mouseScale = config.mouseScale or 1,
		angleInputScale = config.angleInputScale or 12,
		useScreenCursor = config.useScreenCursor == true,
		lastMouseX = nil,
		lastMouseY = nil,
		loopFlashAt = 0,
		frameInterval = config.frameInterval or 0.09,
		frameIndex = 1,
		nextFrameTime = 0,
		materials = config.materials or MouseMinigame.MaterialSets.circle,
	}
end

function MouseMinigame:IsActive(id)
	if not self.ActiveSession then return false end
	if not id then return true end
	return self.ActiveSession.id == id
end

function MouseMinigame:Cancel(reason)
	local session = self.ActiveSession
	if not session then return end
	if session.enabledScreenClicker then
		gui.EnableScreenClicker(false)
	end
	self.ActiveSession = nil
	session.closing = true
	session.closeReason = reason or "cancelled"
	session.closeStartedAt = CurTime()
	session.closeDuration = 0.22
	self.RenderSession = session
	if isfunction(session.onCancel) then
		session.onCancel(reason or "cancelled", session)
	end
end

function MouseMinigame:Complete()
	local session = self.ActiveSession
	if not session then return end
	if session.enabledScreenClicker then
		gui.EnableScreenClicker(false)
	end
	self.ActiveSession = nil
	self.RenderSession = nil
	if isfunction(session.onSuccess) then
		session.onSuccess(session)
	end
end

function MouseMinigame:Start(config)
	config = config or {}
	if self.ActiveSession then
		self:Cancel("replaced")
	end

	self.ActiveSession = GetDefaultSession(config)
	self.RenderSession = self.ActiveSession
	local session = self.ActiveSession
	if session.useScreenCursor and not vgui.CursorVisible() then
		gui.EnableScreenClicker(true)
		session.enabledScreenClicker = true
	end
	if session.useScreenCursor then
		local mouseX, mouseY = gui.MouseX(), gui.MouseY()
		if mouseX <= 0 and mouseY <= 0 and input.SetCursorPos then
			input.SetCursorPos(math.floor(session.centerX), math.floor(session.centerY))
			mouseX, mouseY = gui.MouseX(), gui.MouseY()
		end
		session.lastMouseX = mouseX
		session.lastMouseY = mouseY
	end
end

local function GetBandageLoops(wep)
	local mode = wep.mode or 1
	local amount = wep.modeValues and wep.modeValues[mode] or 0
	if not isnumber(amount) or amount <= 0 then return 1 end
	return math.Clamp(math.ceil(amount / 30), 1, 8)
end

local function ResolveBandageTarget(wep, attackType)
	local owner = wep:GetOwner()
	if not IsValid(owner) then return nil end
	if attackType ~= 2 then return owner end

	local trace = hg.eyeTrace(owner)
	if trace and IsValid(trace.Entity) then
		return trace.Entity
	end

	return nil
end

local function GetOrganismInjuryScore(org)
	if not org then return 0 end
	local score = 0

	if istable(org.wounds) then
		score = score + #org.wounds
	end
	if istable(org.arterialwounds) then
		score = score + (#org.arterialwounds * 2)
	end
	if isnumber(org.bleed) then
		score = score + math.Clamp(math.floor(org.bleed / 35), 0, 6)
	end
	if isnumber(org.skull) and org.skull >= 0.6 then
		score = score + 2
	end
	if org.chest == 1 then score = score + 1 end
	if org.lleg == 1 and not org.llegamputated then score = score + 1 end
	if org.rleg == 1 and not org.rlegamputated then score = score + 1 end
	if org.larm == 1 and not org.larmamputated then score = score + 1 end
	if org.rarm == 1 and not org.rarmamputated then score = score + 1 end

	return score
end

local function GetNetInjuryScore(ent)
	if not IsValid(ent) or not ent.GetNetVar then return 0 end
	local score = 0

	local bleed = tonumber(ent:GetNetVar("bleed", 0) or 0) or 0
	if bleed > 0 then
		score = score + math.Clamp(math.floor(bleed / 35), 1, 6)
	end

	local wounds = ent:GetNetVar("wounds", nil)
	if istable(wounds) then
		for i = 1, #wounds do
			local wound = wounds[i]
			if istable(wound) and tonumber(wound[1] or 0) > 0 then
				score = score + 1
			end
		end
	end

	local arterial = ent:GetNetVar("arterialwounds", nil)
	if istable(arterial) then
		score = score + (#arterial * 2)
	end

	return score
end

local function GetEntityInjuryScore(target)
	if not IsValid(target) then return 0 end
	local org = target.organism
	local score = GetOrganismInjuryScore(org)
	if score > 0 then return score end
	score = GetNetInjuryScore(target)
	if score > 0 then return score end
	if hg and hg.GetCurrentCharacter then
		local chr = hg.GetCurrentCharacter(target)
		if IsValid(chr) and chr ~= target then
			score = GetOrganismInjuryScore(chr.organism)
			if score > 0 then return score end
			score = GetNetInjuryScore(chr)
			if score > 0 then return score end
		end
	end
	return 0
end

local function HasBandageMinigameNeed(target)
	if not IsValid(target) then return false end
	local org = target.organism
	if org then
		local bleed = tonumber(org.bleed) or 0
		if bleed > 0 then return true end
		if istable(org.arterialwounds) and #org.arterialwounds > 0 then return true end
		if istable(org.wounds) and #org.wounds > 0 then
			for i = 1, #org.wounds do
				local wound = org.wounds[i]
				if istable(wound) and tonumber(wound[1] or 0) > 0 then
					return true
				end
			end
		end
	end
	if target.GetNetVar then
		local bleed = tonumber(target:GetNetVar("bleed", 0) or 0) or 0
		if bleed > 0 then return true end
		local arterial = target:GetNetVar("arterialwounds", nil)
		if istable(arterial) and #arterial > 0 then return true end
		local wounds = target:GetNetVar("wounds", nil)
		if istable(wounds) then
			for i = 1, #wounds do
				local wound = wounds[i]
				if istable(wound) and tonumber(wound[1] or 0) > 0 then
					return true
				end
			end
		end
	end
	if hg and hg.GetCurrentCharacter then
		local chr = hg.GetCurrentCharacter(target)
		if IsValid(chr) and chr ~= target then
			return HasBandageMinigameNeed(chr)
		end
	end
	return false
end

local function HasAnyBandageData(target)
	if not IsValid(target) then return false end
	if target.organism then return true end
	if not target.GetNetVar then return false end
	if target:GetNetVar("bleed", nil) ~= nil then return true end
	if target:GetNetVar("wounds", nil) ~= nil then return true end
	if target:GetNetVar("arterialwounds", nil) ~= nil then return true end
	return false
end

local function ShouldAllowBandageMinigame(target, owner)
	if HasBandageMinigameNeed(target) then return true end

	if IsValid(owner) and hg and hg.GetCurrentCharacter then
		local chr = hg.GetCurrentCharacter(owner)
		if IsValid(chr) and chr ~= target then
			if HasBandageMinigameNeed(chr) then return true end
			if not HasAnyBandageData(chr) then return true end
		end
	end

	if not HasAnyBandageData(target) then return true end
	return false
end

local function GetBandageLoopsWithInjuries(wep, attackType)
	local loops = GetBandageLoops(wep)
	local target = ResolveBandageTarget(wep, attackType)
	if not IsValid(target) then return loops end

	if not HasBandageMinigameNeed(target) then return loops end
	local score = GetEntityInjuryScore(target)
	return math.Clamp(loops + math.ceil(score * 0.1), 1, 8)
end

function MouseMinigame:TryStartBandageSession(wep, attackType)
	local isRightClick = attackType == 2
	if isRightClick then
		if self.BlockStartRMB then
			if input.IsMouseDown(MOUSE_RIGHT) then return false end
			self.BlockStartRMB = false
		end
	else
		if self.BlockStartLMB then
			if input.IsMouseDown(MOUSE_LEFT) then return false end
			self.BlockStartLMB = false
		end
	end

	if not IsValid(wep) then return false end
	if not bandageCircleClasses[wep:GetClass()] then return false end
	local owner = wep:GetOwner()
	if not IsValid(owner) or owner ~= LocalPlayer() then return false end
	if owner:GetActiveWeapon() ~= wep then return false end
	local target = ResolveBandageTarget(wep, attackType)
	if not IsValid(target) then return false end
	if not ShouldAllowBandageMinigame(target, owner) then return false end

	local sessionId = "bandage_" .. wep:EntIndex()
	if self:IsActive(sessionId) then
		return true
	end
	if self:IsActive() then return false end

	self:Start({
		id = sessionId,
		mode = "circle",
		requiredLoops = GetBandageLoopsWithInjuries(wep, attackType),
		requiredDirection = 1,
		startAngle = 0,
		startTolerance = 60,
		weapon = wep,
		weaponClass = wep:GetClass(),
		useScreenCursor = true,
		lockedAngles = owner:EyeAngles(),
		onSuccess = function()
			if not IsValid(wep) then return end
			net.Start(bandageNetDone)
			net.WriteEntity(wep)
			net.WriteUInt(attackType or 1, 2)
			net.SendToServer()
		end
	})

	return true
end

hook.Add("Think", "hg_mouse_minigame_bandage_input", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	local wep = ply:GetActiveWeapon()
	local activeSession = MouseMinigame.ActiveSession
	if activeSession and activeSession.weaponClass and (not IsValid(wep) or wep:GetClass() ~= activeSession.weaponClass) then
		MouseMinigame:Cancel("dropped")
		return
	end

	if not IsValid(wep) then return end
	if not bandageCircleClasses[wep:GetClass()] then
		bandageLMBDown = false
		bandageRMBDown = false
		return
	end

	local lmbDown = input.IsMouseDown(MOUSE_LEFT)
	if not lmbDown then
		MouseMinigame.BlockStartLMB = false
	end
	if lmbDown and not bandageLMBDown and MouseMinigame:IsActive("bandage_" .. wep:EntIndex()) then
		local session = MouseMinigame.ActiveSession
		if session and CurTime() > ((session.startedAt or 0) + 0.2) then
			MouseMinigame:Cancel("manual_cancel")
			MouseMinigame.BlockStartLMB = true
		end
	end
	bandageLMBDown = lmbDown

	local rmbDown = input.IsMouseDown(MOUSE_RIGHT)
	if not rmbDown then
		MouseMinigame.BlockStartRMB = false
	end
	if rmbDown and not bandageRMBDown and MouseMinigame:IsActive("bandage_" .. wep:EntIndex()) then
		local session = MouseMinigame.ActiveSession
		if session and CurTime() > ((session.startedAt or 0) + 0.2) then
			MouseMinigame:Cancel("manual_cancel")
			MouseMinigame.BlockStartRMB = true
		end
	end
	bandageRMBDown = rmbDown
end)

hook.Add("PlayerBindPress", "hg_mouse_minigame_bandage_bindpress", function(ply, bind, pressed)
	if not pressed then return end
	if not IsValid(ply) or ply ~= LocalPlayer() then return end
	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) then return end
	if not bandageCircleClasses[wep:GetClass()] then return end

	bind = string.lower(bind or "")
	if string.find(bind, "+attack2", 1, true) then
		if MouseMinigame:IsActive("bandage_" .. wep:EntIndex()) then
			local session = MouseMinigame.ActiveSession
			if session and CurTime() > ((session.startedAt or 0) + 0.2) then
				MouseMinigame:Cancel("manual_cancel")
				MouseMinigame.BlockStartRMB = true
			end
		else
			MouseMinigame:TryStartBandageSession(wep, 2)
		end
	elseif string.find(bind, "+attack", 1, true) then
		if MouseMinigame:IsActive("bandage_" .. wep:EntIndex()) then
			local session = MouseMinigame.ActiveSession
			if session and CurTime() > ((session.startedAt or 0) + 0.2) then
				MouseMinigame:Cancel("manual_cancel")
				MouseMinigame.BlockStartLMB = true
			end
		else
			MouseMinigame:TryStartBandageSession(wep, 1)
		end
	end
end)

hook.Add("InputMouseApply", "hg_mouse_minigame_capture_raw", function(cmd, x, y, ang)
	local session = MouseMinigame.ActiveSession
	if not session then return end
	MouseMinigame.RawMouseDX = (MouseMinigame.RawMouseDX or 0) + x
	MouseMinigame.RawMouseDY = (MouseMinigame.RawMouseDY or 0) + y
end)

hook.Add("CreateMove", "hg_mouse_minigame_basemove", function(cmd)
	local session = MouseMinigame.ActiveSession
	if not session then return end

	local ply = LocalPlayer()
	if not IsValid(ply) then
		MouseMinigame:Cancel("no_player")
		return
	end
	if not ply:Alive() then
		MouseMinigame:Cancel("dead")
		return
	end
	if session.weaponClass and not ply:HasWeapon(session.weaponClass) then
		MouseMinigame:Cancel("dropped")
		return
	end

	local activeWeapon = ply:GetActiveWeapon()
	if IsValid(activeWeapon) and (not session.weaponClass or activeWeapon:GetClass() == session.weaponClass) then
		session.weapon = activeWeapon
	end

	if not session.lockedAngles then
		local currentAngles = cmd:GetViewAngles()
		session.lockedAngles = Angle(currentAngles.p, currentAngles.y, currentAngles.r)
	end

	local currentAngles = cmd:GetViewAngles()

	local mx, my = MouseMinigame.RawMouseDX or 0, MouseMinigame.RawMouseDY or 0
	MouseMinigame.RawMouseDX = 0
	MouseMinigame.RawMouseDY = 0
	if mx == 0 and my == 0 then
		mx, my = cmd:GetMouseX(), cmd:GetMouseY()
	end
	if mx == 0 and my == 0 then
		local yawDelta = NormalizeAngleDelta(currentAngles.y - session.lockedAngles.y)
		local pitchDelta = NormalizeAngleDelta(currentAngles.p - session.lockedAngles.p)
		mx = yawDelta * session.angleInputScale
		my = -pitchDelta * session.angleInputScale
	end
	if session.useScreenCursor then
		local curX, curY = gui.MouseX(), gui.MouseY()
		if not session.lastMouseX then
			session.lastMouseX = curX
			session.lastMouseY = curY
		end
		mx = curX - session.lastMouseX
		my = curY - session.lastMouseY
		session.lastMouseX = curX
		session.lastMouseY = curY
	end
	if mx ~= 0 or my ~= 0 then
		session.cursorX = math_Clamp(session.cursorX + mx * session.mouseScale, session.centerX - session.cursorClamp, session.centerX + session.cursorClamp)
		session.cursorY = math_Clamp(session.cursorY + my * session.mouseScale, session.centerY - session.cursorClamp, session.centerY + session.cursorClamp)

		local dx = session.cursorX - session.centerX
		local dy = session.cursorY - session.centerY
		local dist = math.sqrt(dx * dx + dy * dy)
		local minDist = session.radius - session.ringTolerance
		local maxDist = session.radius + session.ringTolerance

		local currentAngle = AngleFromDelta(dx, dy)
		local nearRing = dist >= (minDist - session.ringTolerance * 2.1) and dist <= (maxDist + session.ringTolerance * 2.6)

		if session.lastAngle then
			local delta = NormalizeAngleDelta(currentAngle - session.lastAngle)
			delta = math_Clamp(delta, -28, 28)
			local ringFactor = math_Clamp(1 - math_abs(dist - session.radius) / (session.ringTolerance * 4.2), 0.65, 1)
			local directionalStep = delta * session.requiredDirection
			if ringFactor > 0.01 and directionalStep > 0 then
				session.accumulatedAngle = session.accumulatedAngle + (directionalStep * ringFactor)
			elseif directionalStep < 0 then
				session.accumulatedAngle = math.max(session.accumulatedAngle + directionalStep * 0.06, 0)
			end

			if session.accumulatedAngle >= 360 then
				session.accumulatedAngle = session.accumulatedAngle - 360
				session.completedLoops = session.completedLoops + 1
				session.loopFlashAt = CurTime()
				if session.completedLoops >= session.requiredLoops then
					MouseMinigame:Complete()
					return
				end
			end
		else
			if nearRing then
				session.lastAngle = currentAngle
			else
				session.accumulatedAngle = math.max(session.accumulatedAngle - 0.8, 0)
			end
		end

		if nearRing then
			session.lastAngle = currentAngle
		else
			session.lastAngle = currentAngle
			session.accumulatedAngle = math.max(session.accumulatedAngle - 0.1, 0)
		end
	end

	cmd:SetViewAngles(session.lockedAngles)
	if not session.allowMovement then
		cmd:ClearMovement()
	end
end)

hook.Add("HUDPaint", "hg_mouse_minigame_basehud", function()
	local session = MouseMinigame.ActiveSession or MouseMinigame.RenderSession
	if not session then return end
	if not session.materials or #session.materials == 0 then return end

	if session.closing then
		local closeFrac = math.Clamp((CurTime() - (session.closeStartedAt or CurTime())) / (session.closeDuration or 0.22), 0, 1)
		if closeFrac >= 1 then
			if MouseMinigame.RenderSession == session then
				MouseMinigame.RenderSession = nil
			end
			return
		end
	end

	if session.nextFrameTime <= CurTime() then
		session.frameIndex = session.frameIndex + 1
		if session.frameIndex > #session.materials then
			session.frameIndex = 1
		end
		session.nextFrameTime = CurTime() + session.frameInterval
	end

	local mat = session.materials[session.frameIndex]
	local hasValidMaterial = mat and not IsMatError(mat)
	local openAlpha = math.Clamp((CurTime() - (session.openedAt or CurTime())) / 0.18, 0, 1)
	local closeAlpha = 1
	if session.closing then
		closeAlpha = 1 - math.Clamp((CurTime() - (session.closeStartedAt or CurTime())) / (session.closeDuration or 0.22), 0, 1)
	end
	local visualAlpha = openAlpha * closeAlpha
	if visualAlpha <= 0 then return end
	local standbyMul = Lerp(openAlpha, 1, 0.2)
	local shakeAmp = ((1.6 + (1 - openAlpha) * 2.4) * standbyMul) * closeAlpha
	local shakeX = math.sin(CurTime() * 75) * shakeAmp + math.cos(CurTime() * 43) * (shakeAmp * 0.65)
	local shakeY = math.cos(CurTime() * 79) * shakeAmp + math.sin(CurTime() * 39) * (shakeAmp * 0.5)
	local drawX = session.leftMargin + shakeX
	local drawY = session.topMargin + shakeY
	local bgAlpha = math.floor(155 * visualAlpha)
	local textAlpha = math.floor(255 * visualAlpha)
	local loopPulse = math.Clamp(1 - ((CurTime() - (session.loopFlashAt or 0)) / 0.45), 0, 1)
	local txtR = math.floor(255)
	local txtG = math.floor(255 - (175 * loopPulse))
	local txtB = math.floor(255 - (175 * loopPulse))

	cam_Start2D()
		draw_RoundedBox(6, drawX - 10, drawY - 10, session.size + 20, session.size + 20, Color(0, 0, 0, bgAlpha))
		if hasValidMaterial then
			surface_SetDrawColor(255, 255, 255, textAlpha)
			surface_SetMaterial(mat)
			surface_DrawTexturedRect(drawX, drawY, session.size, session.size)
		else
			draw_RoundedBox(4, drawX, drawY, session.size, session.size, Color(25, 25, 25, math.floor(240 * visualAlpha)))
			draw_SimpleText("CIRCLE", "ZCity_Veteran", drawX + session.size * 0.5, drawY + session.size * 0.5, Color(255, 255, 255, textAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		draw_SimpleText(session.completedLoops .. "/" .. session.requiredLoops, "ZCity_Veteran", drawX + session.size * 0.5, drawY + session.size + 10, Color(txtR, txtG, txtB, textAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	cam_End2D()
end)
