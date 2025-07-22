Qpocalypse15.Panel = ISPanelJoypad:derive("Qpocalypse15.Panel")
Qpocalypse15.Panel.instance = {}

local FADE_SECONDS = 1
local FASTFORWARD_MIN_REMAINING = 3 / 60

local PADDING_MEDIUM = 8
local PADDING_SMALL = 2

local BUTTON_WIDTH = 250
local BUTTON_HEIGHT = 40
local BUTTON_GROUP_OFFSET = (BUTTON_HEIGHT * 4) + (PADDING_MEDIUM * 3) + 85

local DIALOG_WIDTH = 380
local DIALOG_HEIGHT = 120

local TEXT_Y_OFFSET = 150

local FONT_LARGE_HEIGHT = getTextManager():getFontHeight(UIFont.Large)

local dialogConfirm = function(self, text, onClick)
	local x = getPlayerScreenLeft(self.playerNum) + (getPlayerScreenWidth(self.playerNum) - DIALOG_WIDTH) / 2
	local y = getPlayerScreenTop(self.playerNum) + (getPlayerScreenHeight(self.playerNum) - DIALOG_HEIGHT) / 2

	local modal = ISModalDialog:new(x, y, DIALOG_WIDTH, DIALOG_HEIGHT, text, true, self, onClick, self.playerNum)
	modal:initialise()
	modal:addToUIManager()
	modal:bringToTop()

	if JoypadState.players[self.playerNum + 1] then
		modal.prevFocus = JoypadState.players[self.playerNum + 1].focus
		setJoypadFocus(self.playerNum, modal)
	end

	return modal
end

local addButton = function(self, y, title, onClick)
	local button = ISButton:new(0, y, BUTTON_WIDTH, BUTTON_HEIGHT, title, self, onClick)
	button.anchorLeft = false
	button.anchorTop = false
	button.backgroundColor.a = 0.8
	button.borderColor.a = 0.3

	self:addChild(button)
	return button
end

local drawCenterText = function(panel, text, y)
	local width = getTextManager():MeasureStringX(UIFont.Large, text) + (PADDING_MEDIUM * 2)

	local x = panel.screenX + ((panel.screenWidth - width) / 2)

	panel:drawRect(x - panel:getAbsoluteX(), y - panel:getAbsoluteY(), width, FONT_LARGE_HEIGHT, 0.5, 0, 0, 0)
	getTextManager():DrawString(UIFont.Large, x + PADDING_MEDIUM, y, text, 1, 1, 1, 1)

	return y + FONT_LARGE_HEIGHT
end

local getTimeUnit = function(output, units, singular, plural)
	if units ~= 0 then
		if #output > 0 then output = output .. ", " end
		output = output .. units .. " " .. getText(units > 1 and plural or singular)
	end

	return output
end

local getTimeRemainingText = function(player, value)
	local total = value or 0
	if total <= 0 then return end

	local timeUnits = ""
	timeUnits = getTimeUnit(timeUnits, math.floor(total / 24), "IGUI_Gametime_day", "IGUI_Gametime_days")

	local remaining = total % 24
	timeUnits = getTimeUnit(timeUnits, math.floor(remaining), "IGUI_Gametime_hour", "IGUI_Gametime_hours")
	timeUnits = getTimeUnit(timeUnits, math.floor((remaining * 60) % 60), "IGUI_Gametime_minute", "IGUI_Gametime_minutes")
	if #timeUnits == 0 then timeUnits = getTimeUnit(timeUnits, math.floor((remaining * 3600) % 60), "IGUI_Gametime_second", "IGUI_Gametime_secondes") end

	return string.format(getText(Qpocalypse15.Incapacitation.canRecoveryUnassisted(player) and "UI_Qpocalypse15_WillRecover" or "UI_Qpocalypse15_WillDie"), timeUnits)
end

Qpocalypse15.Panel.createChildren = function(self)
	self:setWidth(BUTTON_WIDTH)
	self:setHeight(BUTTON_GROUP_OFFSET)
	self:setX(self.screenX + (self.screenWidth - BUTTON_WIDTH) / 2)
	self:setY(self.screenY + (self.screenHeight - BUTTON_GROUP_OFFSET))

	local buttonY = 0

	self.buttonToggleFastForward = addButton(self, buttonY, "", self.onToggleFastForward)
	buttonY = buttonY + BUTTON_HEIGHT + PADDING_MEDIUM

	self.buttonGiveUp = addButton(self, buttonY, getText("UI_Qpocalypse15_GiveUp"), self.onGiveUp)
	buttonY = buttonY + BUTTON_HEIGHT + PADDING_MEDIUM

	self.buttonQuitMenu = addButton(self, buttonY, getText("IGUI_PostDeath_Exit"), self.onQuitMenu)
	buttonY = buttonY + BUTTON_HEIGHT + PADDING_MEDIUM

	self.buttonQuitDesktop = addButton(self, buttonY, getText("IGUI_PostDeath_Quit"), self.onQuitDesktop)
end

Qpocalypse15.Panel.prerender = function(self)
	local screenWidth = getPlayerScreenWidth(self.playerNum)
	local sceenHeight = getPlayerScreenHeight(self.playerNum)

	if self.screenWidth ~= screenWidth or self.screenHeight ~= sceenHeight then
		self.screenX = getPlayerScreenLeft(self.playerNum)
		self.screenY = getPlayerScreenTop(self.playerNum)
		self.screenWidth = screenWidth
		self.screenHeight = sceenHeight

		self:setX(self.screenX + (self.screenWidth - self.width) / 2)
		self:setY(self.screenY + (self.screenHeight - self.height))
	end

	if not self.fadeComplete then self.fadeComplete = getTimestamp() >= self.fadeStart + FADE_SECONDS end

	self.lines = {}
	table.insert(self.lines, getText("UI_Qpocalypse15_IsIncapacitated"))

	local player = getSpecificPlayer(self.playerNum)

	local timeRemainingText = getTimeRemainingText(player, self.timeRemaining)
	if timeRemainingText then table.insert(self.lines, timeRemainingText) end

	self.fastForwarding = player:isAsleep() and self.timeRemaining > FASTFORWARD_MIN_REMAINING
	self.buttonToggleFastForward:setTitle(getText(self.fastForwarding and "UI_Qpocalypse15_StayAwake" or "UI_Qpocalypse15_Sleep"))

	self.buttonToggleFastForward:setVisible(self.fadeComplete and (not isClient() or getServerOptions():getBoolean("SleepAllowed")))
	self.buttonGiveUp:setVisible(self.fadeComplete)
	self.buttonQuitDesktop:setVisible(self.fadeComplete)
	self.buttonQuitMenu:setVisible(self.fadeComplete)

	ISPanelJoypad.prerender(self)

	self:setStencilRect(self.screenX - self.x, self.screenY - self.y, self.screenWidth, self.screenHeight)
end

Qpocalypse15.Panel.render = function(self)
	ISPanelJoypad.render(self)

	if not (self.dialogQuitConfirm and self.dialogQuitConfirm:isReallyVisible()) and not (self.dialogGiveUpConfirm and self.dialogGiveUpConfirm:isReallyVisible()) then
		if self.fadeComplete then
			local y = self.screenY + self.textY
			for _, line in ipairs(self.lines) do y = drawCenterText(self, line, y) + PADDING_SMALL end

			drawCenterText(self, self.deathDetails, y)
		end
	end

	self:clearStencilRect()
end

Qpocalypse15.Panel.onToggleFastForward = function(self)
	if MainScreen.instance:isReallyVisible() then return end

	self.fastForwarding = not self.fastForwarding
end

Qpocalypse15.Panel.onGiveUp = function(self)
	if MainScreen.instance:isReallyVisible() then return end

	if self.dialogGiveUpConfirm then self.dialogGiveUpConfirm:destroy() end
	self.dialogGiveUpConfirm = dialogConfirm(self, getText("UI_Qpocalypse15_GiveUpConfirm"), self.onGiveUpConfirm)
end

Qpocalypse15.Panel.onGiveUpConfirm = function(self, button)
	self.dialogGiveUpConfirm = nil

	if button.internal == "YES" then
		if MainScreen.instance:isReallyVisible() then return end

		Qpocalypse15.Incapacitation.kill(getSpecificPlayer(self.playerNum))
	end
end

Qpocalypse15.Panel.onQuitMenu = function(self)
	if MainScreen.instance:isReallyVisible() then return end

	self:removeFromUIManager()
	getCore():exitToMenu()
end

Qpocalypse15.Panel.onQuitDesktop = function(self)
	if MainScreen.instance:isReallyVisible() then return end

	if self.dialogQuitConfirm then self.dialogQuitConfirm:destroy() end
	self.dialogQuitConfirm = dialogConfirm(self, getText("IGUI_ConfirmQuitToDesktop"), self.onQuitDesktopConfirm)
end

Qpocalypse15.Panel.onQuitDesktopConfirm = function(self, button)
	self.dialogConfirmQuit = nil

	if button.internal == "YES" then
		setGameSpeed(1)
		pauseSoundAndMusic()
		setShowPausedMessage(true)
		getCore():quitToDesktop()
	end
end

Qpocalypse15.Panel.onMouseDown = function(_, _, _) return false end

Qpocalypse15.Panel.onMouseUp = function(_, _, _) return false end

Qpocalypse15.Panel.onMouseMove = function(_, _, _) return false end

Qpocalypse15.Panel.onMouseWheel = function(_, _) return false end

Qpocalypse15.Panel.onGainJoypadFocus = function(self, _)
	self:setISButtonForA(self.buttonToggleFastForward)
	self:setISButtonForB(self.buttonQuitMenu)
	self:setISButtonForY(self.buttonQuitDesktop)
	self:setISButtonForX(self.buttonGiveUp)
end

Qpocalypse15.Panel.onJoypadBeforeDeactivate = function(self, _)
	self.buttonToggleFastForward:clearJoypadButton()
	self.buttonQuitMenu:clearJoypadButton()
	self.buttonQuitDesktop:clearJoypadButton()
	self.buttonGiveUp:clearJoypadButton()
end

Qpocalypse15.Panel.onJoypadReactivate = function(self, _)
	self:setISButtonForA(self.buttonToggleFastForward)
	self:setISButtonForB(self.buttonQuitMenu)
	self:setISButtonForY(self.buttonQuitDesktop)
	self:setISButtonForX(self.buttonGiveUp)
end

Qpocalypse15.Panel.new = function(self, player)
	local playerNum = player:getPlayerNum()

	local x = getPlayerScreenLeft(playerNum)
	local y = getPlayerScreenTop(playerNum)
	local width = getPlayerScreenWidth(playerNum)
	local height = getPlayerScreenHeight(playerNum)
	local instance = ISPanelJoypad:new(x, y, width, height)

	setmetatable(instance, self)
	self.__index = self

	instance:setAnchorLeft(false)
	instance:setAnchorTop(false)
	instance.background = false
	instance.screenX = x
	instance.screenY = y
	instance.screenWidth = width
	instance.screenHeight = height
	instance.playerNum = playerNum
	instance.textY = (height / 2) + TEXT_Y_OFFSET

	instance:instantiate()
	instance:setAlwaysOnTop(true)
	instance.javaObject:setIgnoreLossControl(true)
	Qpocalypse15.Panel.instance[playerNum] = instance

	return instance
end

Qpocalypse15.Panel.show = function(player)
	local playerNum = player:getPlayerNum()
	if Qpocalypse15.Panel.instance[playerNum] then
		Qpocalypse15.Panel.instance[playerNum]:setVisible(true)
		return
	end

	local panel = Qpocalypse15.Panel:new(player)

	panel.fadeStart = getTimestamp()
	panel.deathDetails = getGameTime():getDeathString(player)
	local zombiesKilled = getGameTime():getZombieKilledText(player)
	if zombiesKilled then panel.deathDetails = panel.deathDetails .. " " .. zombiesKilled end

	panel:addToUIManager()

	if MainScreen.instance:isVisible() then
		table.insert(ISUIHandler.visibleUI, panel.javaObject:toString())
		panel:setVisible(false)
		if JoypadState.players[playerNum + 1] and JoypadState.saveFocus then JoypadState.saveFocus[playerNum + 1] = panel end
	else
		if JoypadState.players[playerNum + 1] then JoypadState.players[playerNum + 1].focus = panel end
	end
end

Qpocalypse15.Panel.destroy = function(player)
	local playerNum = player:getPlayerNum()

	if not Qpocalypse15.Panel.instance[playerNum] then return end

	Qpocalypse15.Panel.instance[playerNum]:removeFromUIManager()
	Qpocalypse15.Panel.instance[playerNum] = nil
end

Qpocalypse15.Panel.isFastForwarding = function(player)
	local playerNum = player:getPlayerNum()
	if not Qpocalypse15.Panel.instance[playerNum] then return false end

	return Qpocalypse15.Panel.instance[playerNum].fastForwarding or false
end

Qpocalypse15.Panel.setTimeRemaining = function(player, value)
	local playerNum = player:getPlayerNum()
	if not Qpocalypse15.Panel.instance[playerNum] then return end

	Qpocalypse15.Panel.instance[playerNum].timeRemaining = value
end
