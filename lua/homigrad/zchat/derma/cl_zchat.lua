--faggots

local maxLength = GetConVar("zchat_maxmessagelength")

local NoDrop = CreateClientConVar("zchat_dropcharacters", 1, true, false, "Play the character dropping animation when erasing text", 0, 1)
local ShowTextBoxInactive = CreateClientConVar("zchat_showtextboxinactive", 1, true, false, "Showing your text in textbox while chat is turned off", 0, 1)
local ChatPosX = CreateClientConVar("zchat_pos_x", -1, true, false)
local ChatPosY = CreateClientConVar("zchat_pos_y", -1, true, false)
local ChatSizeW = CreateClientConVar("zchat_size_w", 0, true, false)
local ChatSizeH = CreateClientConVar("zchat_size_h", 0, true, false)

local function CallbackBind(self, callback)
	return function(_, ...)
		return callback(self, ...)
	end
end

local function PaintMarkupOverride(text, font, x, y, color, alignX, alignY, alpha)
	alpha = alpha or 255

	surface.SetTextPos(x + 1, y + 1)
	surface.SetTextColor(0, 0, 0, alpha)
	surface.SetFont(font)
	surface.DrawText(text)

	surface.SetTextPos(x, y)
	surface.SetTextColor(color.r, color.g, color.b, alpha)
	surface.SetFont(font)
	surface.DrawText(text)
end

local PANEL = {}

function PANEL:Init()
	self.text = ""
	self.alpha = 0
	self.fadeDelay = 15
	self.fadeDuration = 5
	self.yAnimDuration = 1

	self.yAnim = 5
end

function PANEL:SetMarkup(text)
	self.text = text

	self.markup = hg.markup.Parse(self.text, self:GetWide())
	self.markup.onDrawText = PaintMarkupOverride

	self:SetTall(self.markup:GetHeight())

	timer.Simple(self.fadeDelay, function()
		if (!IsValid(self)) then
			return
		end

		self:CreateAnimation(self.fadeDuration, {
			index = 3,
			target = {alpha = 0}
		})
	end)

	self:CreateAnimation(self.yAnimDuration, {
		index = 4,
		target = {yAnim = 0},
		easing = "outQuint"
	})

	self:CreateAnimation(0.5, {
		index = 3,
		target = {alpha = 255},
	})
end

function PANEL:PerformLayout(width, height)
	self.markup = hg.markup.Parse(self.text, width)
	self.markup.onDrawText = PaintMarkupOverride

	self:SetTall(self.markup:GetHeight())
end

function PANEL:Paint(width, height)
	local newAlpha

	if (hg.chat:GetActive()) then
		newAlpha = math.max(hg.chat.alpha, self.alpha)
	else
		newAlpha = self.alpha - (255 - hg.chat.realAlpha)
	end

	DisableClipping(true)
		local chatboxX, chatboxY = hg.chat:GetPos()
		local wide, tall = hg.chat:GetSize()

		render.SetScissorRect(chatboxX, chatboxY, chatboxX + wide, chatboxY + tall, true)
			self.markup:draw(0, self.yAnim, nil, nil, newAlpha)
		render.SetScissorRect(0, 0, 0, 0, false)
	DisableClipping(false)
end

vgui.Register("zChatMessage", PANEL, "Panel")

PANEL = {}

DEFINE_BASECLASS("DTextEntry")

function PANEL:Init()
	self:SetFont("zChatFont")
	self:SetUpdateOnType(true)
	self:SetHistoryEnabled(true)

	self.History = hg.chat.messageHistory
	self.droppedCharacters = {}

	self.prevText = ""

	self:SetTextColor(color_white)

	self:SetPaintBackground(false)

	self.m_bLoseFocusOnClickAway = false
end

function PANEL:AllowInput(newCharacter)
	local text = self:GetText()
	local maxLen = maxLength:GetInt()

	-- we can't check for the proper length using utf-8 since AllowInput is called for single bytes instead of full characters
	if (string.len(text .. newCharacter) > maxLen) then
		surface.PlaySound("common/talk.wav")
		return true
	end
end

function PANEL:Think()
	local text = self:GetText()
	local maxLen = maxLength:GetInt()

	if (text:utf8len() > maxLen) then
		local newText = text:utf8sub(0, maxLen)

		self:SetText(newText)
		self:SetCaretPos(newText:utf8len())
	end
end

local gradient_l = Material("vgui/gradient-l")

function PANEL:Paint(w, h)
	surface.SetDrawColor(43, 31, 31, 100)
	surface.DrawRect(0, 0, w, h)

	-- surface.SetDrawColor(137, 137, 137, 150)
	-- surface.SetMaterial(gradient_l)
	-- surface.DrawTexturedRect(0, 0, w * 0.9, h)

	for k, v in ipairs(self.droppedCharacters) do
		local text = v.text

		v.velocityY = v.velocityY + (5 * FrameTime())
		v.y = v.y + v.velocityY

		v.x = v.x + v.velocityX

		v.alpha = v.alpha - FrameTime() * 750

		DisableClipping(true)
			surface.SetTextColor(150, 150, 150, v.alpha)
			surface.SetTextPos(v.x, v.y)
			surface.SetFont("zChatFont")
			surface.DrawText(text)
		DisableClipping(false)

		if v.alpha <= 0 then
			table.remove(self.droppedCharacters, k)
		end
	end

	if ShowTextBoxInactive:GetBool() and !hg.chat:GetActive() and self.prevText != "" then
		DisableClipping(true)
		surface.SetAlphaMultiplier(1)
			surface.SetTextColor(150, 150, 150, 55)
			surface.SetTextPos(0, 0)
			surface.SetFont("zChatFont")
			surface.DrawText(self.prevText)
		surface.SetAlphaMultiplier(0)
		DisableClipping(false)
	end

	BaseClass.Paint(self, w, h)
end

function PANEL:OnValueChange(text)
	local prevText = self.prevText

	if NoDrop:GetBool() then
		local len1, len2 = string.utf8len(prevText), string.utf8len(text)

		if len1 > len2 then
			local droppedText = string.utf8sub(prevText, self:GetCaretPos() + 1, self:GetCaretPos() + (len1 - len2))

			local droppedChars = string.Explode(utf8.charpattern, droppedText)
			for k, v in ipairs(droppedChars) do
				local data = {}
				data.text = v

				surface.SetFont("zChatFont")
				-- local tw1 = surface.GetTextSize(text)
				local tw2 = surface.GetTextSize(v)

				data.x = tw2 * (self:GetCaretPos())

				-- local panelWide = self:GetWide()

				-- if data.x > panelWide then
				-- 	data.x = data.x - (data.x - panelWide)
				-- end

				data.y = 8

				data.velocityX = math.Rand(-0.1, 0.1)
				data.velocityY = -1

				data.alpha = 255

				table.insert(self.droppedCharacters, data)
			end
		end
	end

	local parent = self:GetParent()
	local chatbox = IsValid(parent) and parent:GetParent() or nil
	if IsValid(chatbox) and chatbox.OnEntryTextChanged then
		chatbox:OnEntryTextChanged(prevText, text)
	end

	self.prevText = text
end

vgui.Register("zChatboxEntry", PANEL, "DTextEntry")

PANEL = {}

AccessorFunc(PANEL, "bActive", "Active", FORCE_BOOL)
AccessorFunc(PANEL, "realAlpha", "RealAlpha", FORCE_BOOL)

function PANEL:Init()
	hg.chat = self

	self.entries = {}
	self.messageHistory = {}
	self.Dragging = {0, 0}
	self.Sizing = nil
	self.m_iMinWidth = 340
	self.m_iMinHeight = 180

	self.alpha = 255
	self.realAlpha = 255
	self.outlinePulse = 0
	self.outlinePulseTarget = 0

	local defaultW = math.max(self.m_iMinWidth, math.floor(ScrW() * 0.36))
	local defaultH = math.max(self.m_iMinHeight, math.floor(ScrH() * 0.26))
	local w = ChatSizeW:GetInt()
	local h = ChatSizeH:GetInt()
	if w <= 0 then w = defaultW end
	if h <= 0 then h = defaultH end
	w = math.Clamp(w, self.m_iMinWidth, ScrW())
	h = math.Clamp(h, self.m_iMinHeight, ScrH())
	self:SetSize(w, h)

	local x = ChatPosX:GetInt()
	local y = ChatPosY:GetInt()
	if x < 0 then x = math.floor(ScrW() * 0.02) end
	if y < 0 then y = math.floor(ScrH() * 0.62) end
	x = math.Clamp(x, 0, ScrW() - w)
	y = math.Clamp(y, 0, ScrH() - h)
	self:SetPos(x, y)

	self.topBar = self:Add("Panel")
	self.topBar:SetTall(24)
	self.topBar:Dock(TOP)

	self.settingsButton = self.topBar:Add("DImageButton")
	self.settingsButton:Dock(RIGHT)
	self.settingsButton:DockMargin(0, 4, 4, 4)
	self.settingsButton:SetWide(16)
	self.settingsButton:SetImage("icon16/cog.png")
	self.settingsButton:SetTooltip("zChat settings")
	self.settingsButton.DoClick = CallbackBind(self, self.ToggleSettingsPanel)
	self.topBar.OnMousePressed = CallbackBind(self, self.OnMousePressed)
	self.topBar.OnMouseReleased = CallbackBind(self, self.OnMouseReleased)

	local entryPanel = self:Add("Panel")
	entryPanel:SetZPos(1)
	entryPanel:Dock(BOTTOM)
	entryPanel:DockMargin(4, 0, 4, 4)

	self.entry = entryPanel:Add("zChatboxEntry")
	self.entry:Dock(FILL)
	-- self.entry.OnValueChange = ix.util.Bind(self, self.OnTextChanged)
	-- self.entry.OnKeyCodeTyped = ix.util.Bind(self, self.OnKeyCodeTyped)
	self.entry.OnEnter = CallbackBind(self, self.OnMessageSent)

	self.history = self:Add("DScrollPanel")
	self.history:Dock(FILL)
	self.history:DockMargin(4, 2, 4, 4)

	ChatPosX:SetInt(x)
	ChatPosY:SetInt(y)
	ChatSizeW:SetInt(w)
	ChatSizeH:SetInt(h)

	self:SetActive(false)
end

local gray = Color(255, 255, 255, 100)
local black = Color(0, 0, 0, 200)

function PANEL:Paint(w, h)
	surface.SetDrawColor(0, 0, 0, 230)
	surface.DrawRect(0, 0, w, h)

	local pulse = self.outlinePulse or 0
	surface.SetDrawColor(92, 92, 92, 140)
	surface.DrawOutlinedRect(0, 0, w, h, 1)
	if pulse > 0.001 then
		surface.SetDrawColor(175, 175, 175, 35 + (pulse * 170))
		surface.DrawOutlinedRect(1, 1, w - 2, h - 2, 1)
	end

	surface.SetAlphaMultiplier(1)
		self.history:PaintManual()
		local bar = self.history:GetVBar()
		bar:SetAlpha(self:GetAlpha())
	surface.SetAlphaMultiplier(self:GetAlpha() / 255)

	DisableClipping(true)
		draw.SimpleText("Hold left ALT and press ENTER to whisper", "zChatFontSmall", 5, h * 1.01 + 1, black)
		draw.SimpleText("Hold left ALT and press ENTER to whisper", "zChatFontSmall", 4, h * 1.01, gray)

		local lply = LocalPlayer()
		if IsValid(lply) and lply.organism and lply.organism.otrub then
			draw.SimpleText("Your messages are currently not visible to anyone.", "zChatFontSmall", w - 3, h * 1.01 + 1, black, TEXT_ALIGN_RIGHT)
			draw.SimpleText("Your messages are currently not visible to anyone.", "zChatFontSmall", w - 4, h * 1.01, gray, TEXT_ALIGN_RIGHT)
		end
	DisableClipping(false)

	if self.bActive then
		self:SetAlpha(self.alpha - (255 - self.realAlpha))
	end
end

function PANEL:PulseOutline(strength)
	self.outlinePulseTarget = math.min(1, math.max(self.outlinePulseTarget or 0, strength or 1))
end

function PANEL:OnEntryTextChanged(prevText, newText)
	local prevLen = prevText:utf8len()
	local newLen = newText:utf8len()

	if newLen > prevLen then
		self:PulseOutline(1)
	end
end

function PANEL:SetActive(bActive, bRemovePrev)
	if (bActive) then
		self:SetAlpha(255)
		self:MakePopup()
		self.entry:RequestFocus()

		input.SetCursorPos(self:LocalToScreen(10, self:GetTall() + 10))

		hook.Run("StartChat")
	else
		self:SetAlpha(0)
		self:SetMouseInputEnabled(false)
		self:SetKeyboardInputEnabled(false)

		if bRemovePrev then
			self.entry:SetText("")
			self.entry.prevText = ""
		end

		gui.EnableScreenClicker(false)

		hook.Run("FinishChat")
	end

	self.bActive = bActive

	local bar = self.history:GetVBar()
	bar:SetScroll(bar.CanvasSize)
end

function PANEL:AnimateAlpha(newAlpha)
	self:CreateAnimation(1, {
		index = 1,
		target = {alpha = newAlpha},
	})
end

function PANEL:AnimateRealAlpha(newAlpha)
	self:CreateAnimation(1, {
		index = 2,
		target = {realAlpha = newAlpha},
	})
end

function PANEL:SetRealAlpha(alpha)
	self.realAlpha = alpha
end

function PANEL:ToggleSettingsPanel()
	if IsValid(self.settingsFrame) then
		self.settingsFrame:SetVisible(not self.settingsFrame:IsVisible())
		if self.settingsFrame:IsVisible() then
			self.settingsFrame:MakePopup()
		end
		return
	end

	local minWidth = self.m_iMinWidth or 340
	local minHeight = self.m_iMinHeight or 180

	local frame = vgui.Create("DFrame")
	frame:SetSize(320, 210)
	frame:SetTitle("Chat Settings")
	frame:SetDeleteOnClose(false)
	frame:MakePopup()
	local x, y = self:LocalToScreen(self:GetWide() + 8, 0)
	frame:SetPos(math.Clamp(x, 0, ScrW() - frame:GetWide()), math.Clamp(y, 0, ScrH() - frame:GetTall()))

	local settingsList = frame:Add("DScrollPanel")
	settingsList:Dock(FILL)
	settingsList:DockMargin(4, 4, 4, 4)

	local sizeSlider = settingsList:Add("DNumSlider")
	sizeSlider:Dock(TOP)
	sizeSlider:SetText("Font Size")
	sizeSlider:SetMinMax(4, 30)
	sizeSlider:SetDecimals(1)
	sizeSlider:SetConVar("zchat_fontsize")

	local weightSlider = settingsList:Add("DNumSlider")
	weightSlider:Dock(TOP)
	weightSlider:SetText("Font Weight")
	weightSlider:SetMinMax(200, 1000)
	weightSlider:SetDecimals(0)
	weightSlider:SetConVar("zchat_fontweight")

	local aaCheck = settingsList:Add("DCheckBoxLabel")
	aaCheck:Dock(TOP)
	aaCheck:SetText("Font Anti-Aliasing")
	aaCheck:SetConVar("zchat_fontaa")
	aaCheck:SizeToContents()
	aaCheck:DockMargin(8, 6, 0, 0)

	local inactiveCheck = settingsList:Add("DCheckBoxLabel")
	inactiveCheck:Dock(TOP)
	inactiveCheck:SetText("Show Text While Inactive")
	inactiveCheck:SetConVar("zchat_showtextboxinactive")
	inactiveCheck:SizeToContents()
	inactiveCheck:DockMargin(8, 4, 0, 0)

	local dropCheck = settingsList:Add("DCheckBoxLabel")
	dropCheck:Dock(TOP)
	dropCheck:SetText("Drop Deleted Characters")
	dropCheck:SetConVar("zchat_dropcharacters")
	dropCheck:SizeToContents()
	dropCheck:DockMargin(8, 4, 0, 0)

	local resetButton = settingsList:Add("DButton")
	resetButton:Dock(TOP)
	resetButton:SetText("Reset Chat Position and Size")
	resetButton:DockMargin(0, 8, 0, 0)
	resetButton.DoClick = function()
		local w = math.max(minWidth, math.floor(ScrW() * 0.36))
		local h = math.max(minHeight, math.floor(ScrH() * 0.26))
		local xReset = math.floor(ScrW() * 0.02)
		local yReset = math.floor(ScrH() * 0.62)
		self:SetSize(w, h)
		self:SetPos(xReset, yReset)
		ChatPosX:SetInt(xReset)
		ChatPosY:SetInt(yReset)
		ChatSizeW:SetInt(w)
		ChatSizeH:SetInt(h)
	end

	self.settingsFrame = frame
end

function PANEL:OnMousePressed()
	local mouseX = gui.MouseX()
	local mouseY = gui.MouseY()
	local x, y = self:GetPos()
	local w, h = self:GetSize()

	if mouseX > (x + w - 16) and mouseY > (y + h - 16) then
		self.Sizing = {mouseX - w, mouseY - h}
		self:MouseCapture(true)
		return
	end

	if mouseY < y + self.topBar:GetTall() then
		self.Dragging[1] = mouseX - x
		self.Dragging[2] = mouseY - y
		self:MouseCapture(true)
	end
end

function PANEL:OnMouseReleased()
	self.Dragging = {0, 0}
	self.Sizing = nil
	self:MouseCapture(false)
end

function PANEL:Think()
	local mouseX, mouseY = gui.MousePos()
	local x, y = self:GetPos()
	local w, h = self:GetSize()

	if self.Dragging[1] != 0 then
		local newX = math.Clamp(mouseX - self.Dragging[1], 0, ScrW() - w)
		local newY = math.Clamp(mouseY - self.Dragging[2], 0, ScrH() - h)
		self:SetPos(newX, newY)
		ChatPosX:SetInt(newX)
		ChatPosY:SetInt(newY)
	end

	if self.Sizing then
		local newW = mouseX - self.Sizing[1]
		local newH = mouseY - self.Sizing[2]
		newW = math.Clamp(newW, self.m_iMinWidth, ScrW() - x)
		newH = math.Clamp(newH, self.m_iMinHeight, ScrH() - y)
		self:SetSize(newW, newH)
		ChatSizeW:SetInt(newW)
		ChatSizeH:SetInt(newH)
		self:SetCursor("sizenwse")
		return
	end

	if self:IsHovered() and mouseX > (x + w - 16) and mouseY > (y + h - 16) then
		self:SetCursor("sizenwse")
		return
	end

	if self:IsHovered() and mouseY < y + self.topBar:GetTall() then
		self:SetCursor("sizeall")
		return
	end

	self.outlinePulseTarget = math.max((self.outlinePulseTarget or 0) - FrameTime() * 3.2, 0)
	self.outlinePulse = Lerp(FrameTime() * 12, self.outlinePulse or 0, self.outlinePulseTarget)

	self:SetCursor("arrow")
end

function PANEL:OnMessageSent()
	local text = self.entry:GetText()

	if (text:find("%S")) then
		local lastEntry = hg.chat.messageHistory[#hg.chat.messageHistory]

		-- only add line to textentry history if it isn't the same message
		if (lastEntry != text) then
			if (#hg.chat.messageHistory >= 20) then
				table.remove(hg.chat.messageHistory, 1)
			end

			hg.chat.messageHistory[#hg.chat.messageHistory + 1] = text
		end

		net.Start("zChatMessage")
			net.WriteString(text)
		net.SendToServer()
	end

	self:SetActive(false, true)
end

function PANEL:AddLine(elements)
	local buffer = {
		"<font=zChatFont>"
	}

	buffer = hook.Run("ModifyMessageBuffer", buffer, CHAT_SPEAKER) or buffer

	for _, v in ipairs(elements) do
		if (type(v) == "IMaterial") then
			local texture = v:GetName()

			if (texture) then
				buffer[#buffer + 1] = string.format("<img=%s,%dx%d> ", texture, v:Width(), v:Height())
			end
		elseif (istable(v) and v.r and v.g and v.b) then
			buffer[#buffer + 1] = string.format("<color=%d,%d,%d>", v.r, v.g, v.b)
		elseif (type(v) == "Player") then
			local color = team.GetColor(v:Team())

			buffer[#buffer + 1] = string.format("<color=%d,%d,%d>%s", color.r, color.g, color.b,
				v:GetName():gsub("<", "&lt;"):gsub(">", "&gt;"))
		else
			buffer[#buffer + 1] = tostring(v):gsub("<", "&lt;"):gsub(">", "&gt;")
		end
	end

	local panel = self.history:Add("zChatMessage")
	panel:Dock(TOP)
	panel:InvalidateParent(true)
	panel:SetMarkup(table.concat(buffer))

	if (#self.entries >= 100) then
		local oldPanel = table.remove(self.entries, 1)

		if (IsValid(oldPanel)) then
			oldPanel:Remove()
		end
	end

	local bar = self.history:GetVBar()
	local bScroll = !self:GetActive() or bar.Scroll == bar.CanvasSize -- only scroll when we're not at the bottom/inactive

	if bScroll then
		bar:SetScroll(bar.CanvasSize)
	end

	self.entries[#self.entries + 1] = panel
	return panel
end

function PANEL:AddMessage(...)
	self:AddLine({...})

	chat.PlaySound()
end

vgui.Register("zChatbox", PANEL, "EditablePanel")
