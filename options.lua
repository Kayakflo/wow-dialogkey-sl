function DialogKey:CreateOptionsFrame()		-- Constructs the options frame
	self.options = CreateFrame("Frame")
	
	-- scroll frame
	local scrollFrame = CreateFrame("ScrollFrame", nil, self.options)
	scrollFrame:SetPoint("TOPLEFT", 5, -5)
	scrollFrame:SetPoint("BOTTOMRIGHT", -25, 5)
	scrollFrame:EnableMouse(true)
	scrollFrame:EnableMouseWheel(true)
	
	scrollFrame:SetScript("OnMouseWheel", function(self, delta)
		local current = self.scrollBar:GetValue()
		local minV, maxV = self.scrollBar:GetMinMaxValues()
			
		if delta < 0 and current >= minV then
			self.scrollBar:SetValue(math.min(maxV, current+30))
		elseif delta > 0 and current <= maxV then
			self.scrollBar:SetValue(math.max(minV, current-30))
		end
	end)
	
	-- scroll frame's slider
	local scrollBar = CreateFrame("slider", nil, scrollFrame, "UIPanelScrollBarTemplate")
	scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16)
	scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16)
	scrollBar:SetMinMaxValues(1,315)
	scrollBar:SetValueStep(1)
	scrollBar.scrollStep = 1
	scrollBar:SetValue(0)
	scrollBar:SetWidth(16)
	scrollFrame.scrollBar = scrollBar
	
	-- slider texture
	local scrollbg = scrollBar:CreateTexture(nil, "BACKGROUND") 
	scrollbg:SetAllPoints(scrollBar) 
	scrollbg:SetTexture(0, 0, 0, 0.4) 
	self.options.scrollBar = scrollBar
	
	-- options frame
	local optionsContent = CreateFrame("Frame", nil, scrollFrame)
	optionsContent:SetSize(128, 128)
	self.options.content = optionsContent
	scrollFrame:SetScrollChild(optionsContent)
	
	local title = optionsContent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetFont("Fonts\\FRIZQT__.TTF", 16)
	title:SetText("DialogKey")
	title:SetPoint("TOPLEFT", 16, -16)
	
	local subtitle = optionsContent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	subtitle:SetFont("Fonts\\FRIZQT__.TTF", 10)
	subtitle:SetText("Version " .. GetAddOnMetadata("DialogKey","Version"))
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 4, -8)
	
	optionsContent.keybindButtons = {}
	
	local button1 = CreateFrame("Button", nil, optionsContent, "UIPanelButtonTemplate")
	button1:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 4,-64)
	button1:SetWidth(120)
	button1:SetHeight(26)
	button1:SetText(GetBindingText(self.db.global.keys[1]))
	button1:RegisterForClicks("LeftButtonDown", "RightButtonDown")
	
	button1:SetScript("OnClick", function(self, button)
		if button == "LeftButton" then
			DialogKey:EnableKeybindMode(1)
		else
			DialogKey:ClearBind(1)
		end
	end)
	
	button1:SetScript("OnHide", DialogKey.DisableKeybindMode)
	optionsContent.keybindButtons[1] = button1
	
	local button2 = CreateFrame("Button", nil, optionsContent, "UIPanelButtonTemplate")
	button2:SetPoint("LEFT", button1, "RIGHT", 30,0)
	button2:SetWidth(120)
	button2:SetHeight(26)
	button2:SetText(GetBindingText(DialogKey.db.global.keys[2]))
	button2:RegisterForClicks("LeftButtonDown", "RightButtonDown")
	
	button2:SetScript("OnClick", function(self, button)
		if button == "LeftButton" then
			DialogKey:EnableKeybindMode(2)
		else
			DialogKey:ClearBind(2)
		end
	end)
	
	button2:SetScript("OnHide", DialogKey.DisableKeybindMode)
	optionsContent.keybindButtons[2] = button2
	
	local keybindOr = optionsContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	keybindOr:SetFont("Fonts\\FRIZQT__.TTF", 12)
	keybindOr:SetTextColor(1,1,1,1)
	keybindOr:SetText("or")
	keybindOr:SetPoint("LEFT", button1, "RIGHT", 0, 2)
	keybindOr:SetPoint("RIGHT", button2, "LEFT", 0, 2)
	
	local keybindTitle = optionsContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	keybindTitle:SetFont("Fonts\\FRIZQT__.TTF", 12)
	keybindTitle:SetTextColor(1,1,1,1)
	keybindTitle:SetJustifyH("LEFT")
	keybindTitle:SetWidth(500)
	keybindTitle:SetWordWrap(true)
	keybindTitle:SetText("Click the button to set the key used to accept quests, confirm dialogs, etc. Right-click a button to unbind a key. The key will perform its usual action if there's nothing to accept or confirm.")
	keybindTitle:SetPoint("BOTTOMLEFT", button1, "TOPLEFT", 0, 4)
	
	local keybindReminder = optionsContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	keybindReminder:SetFont("Fonts\\FRIZQT__.TTF", 10)
	keybindReminder:SetTextColor(1,1,1,1)
	keybindReminder:SetText("Press any key...")
	keybindReminder:SetPoint("LEFT", button2, "RIGHT", 4, 0)
	keybindReminder:Hide()
	optionsContent.keybindReminder = keybindReminder
	
	-- NOTE: a lot of these are reversed (option = not self:GetChecked()) because the options were originally "don't <action>" instead of "<action>"
	-- and it's just easier to rename them and reverse than try to convert users' settings
	
	-- Don't click greyed-out buttons
	local ignoreCheckbox = CreateFrame("CheckButton", "DialogKeyOptIgnore", optionsContent, "UICheckButtonTemplate")
	ignoreCheckbox:SetPoint("TOPLEFT", button1, "BOTTOMLEFT", -3, -20)
	_G["DialogKeyOptIgnoreText"]:SetText("Don't try to click on greyed-out buttons")
	ignoreCheckbox:SetScript("OnShow", function(self) self:SetChecked(DialogKey.db.global.ignoreDisabledButtons) end)
	ignoreCheckbox:SetScript("OnClick", function(self) DialogKey.db.global.ignoreDisabledButtons = self:GetChecked() end)
	ignoreCheckbox:SetChecked(DialogKey.db.global.ignoreDisabledButtons)
	
	-- Glow buttons
	local glowCheckbox = CreateFrame("CheckButton", "DialogKeyOptGlow", optionsContent, "UICheckButtonTemplate")
	glowCheckbox:SetPoint("TOPLEFT", ignoreCheckbox, "TOPLEFT", 300, 0)
	_G["DialogKeyOptGlowText"]:SetText("Make buttons clicked by DialogKey glow")
	glowCheckbox:SetScript("OnShow", function(self) self:SetChecked(DialogKey.db.global.showGlow) end)
	glowCheckbox:SetScript("OnClick", function(self) DialogKey.db.global.showGlow = self:GetChecked() end)
	glowCheckbox:SetChecked(DialogKey.db.global.showGlow)
	
	-- Select gossip
	local numGossipCheckbox = CreateFrame("CheckButton", "DialogKeyOptNumGossip", optionsContent, "UICheckButtonTemplate")
	numGossipCheckbox:SetPoint("TOPLEFT", ignoreCheckbox, "BOTTOMLEFT", 0, 0)
	_G["DialogKeyOptNumGossipText"]:SetText("1-9 keys select conversations/quests")
	numGossipCheckbox:SetScript("OnShow", function(self) self:SetChecked(DialogKey.db.global.numKeysForGossip) end)
	numGossipCheckbox:SetScript("OnClick", function(self) DialogKey.db.global.numKeysForGossip = self:GetChecked() end)
	numGossipCheckbox:SetChecked(DialogKey.db.global.numKeysForGossip)
	
	-- Select quest rewards
	local numQuestRewardsCheckbox = CreateFrame("CheckButton", "DialogKeyOptNumQuestRewards", optionsContent, "UICheckButtonTemplate")
	numQuestRewardsCheckbox:SetPoint("TOPLEFT", numGossipCheckbox, "TOPLEFT", 300, 0)
	_G["DialogKeyOptNumQuestRewardsText"]:SetText("1-6 keys select quest rewards")
	numQuestRewardsCheckbox:SetScript("OnShow", function(self) self:SetChecked(DialogKey.db.global.numKeysForQuestRewards) end)
	numQuestRewardsCheckbox:SetScript("OnClick", function(self) DialogKey.db.global.numKeysForQuestRewards = self:GetChecked() end)
	numQuestRewardsCheckbox:SetChecked(DialogKey.db.global.numKeysForQuestRewards)
	
	-- Scroll quests
	local scrollQuestsCheckbox = CreateFrame("CheckButton", "DialogKeyOptScrollQuests", optionsContent, "UICheckButtonTemplate")
	scrollQuestsCheckbox:SetPoint("TOPLEFT", numGossipCheckbox, "BOTTOMLEFT", 0, 0)
	_G["DialogKeyOptScrollQuestsText"]:SetText("Mouse wheel always scrolls quest dialogs regardless of cursor position")
	scrollQuestsCheckbox:SetScript("OnShow", function(self) self:SetChecked(DialogKey.db.global.scrollQuests) end)
	scrollQuestsCheckbox:SetScript("OnClick", function(self) DialogKey.db.global.scrollQuests = self:GetChecked() end)
	scrollQuestsCheckbox:SetChecked(DialogKey.db.global.scrollQuests)
	
	-- Don't accept summons
	local dontClickSummonsCheckbox = CreateFrame("CheckButton", "DialogKeyOptDontClickSummons", optionsContent, "UICheckButtonTemplate")
	dontClickSummonsCheckbox:SetPoint("TOPLEFT", scrollQuestsCheckbox, "BOTTOMLEFT", 0, 0)
	_G["DialogKeyOptDontClickSummonsText"]:SetText("Accept summon requests")
	dontClickSummonsCheckbox:SetScript("OnShow", function(self) self:SetChecked(not DialogKey.db.global.dontClickSummons) end)
	dontClickSummonsCheckbox:SetScript("OnClick", function(self) DialogKey.db.global.dontClickSummons = not self:GetChecked() end)
	dontClickSummonsCheckbox:SetChecked(not DialogKey.db.global.dontClickSummons)
	
	-- Don't accept duels
	local dontClickDuelsCheckbox = CreateFrame("CheckButton", "DialogKeyOptDontClickDuels", optionsContent, "UICheckButtonTemplate")
	dontClickDuelsCheckbox:SetPoint("TOPLEFT", dontClickSummonsCheckbox, "TOPLEFT", 300, 0)
	_G["DialogKeyOptDontClickDuelsText"]:SetText("Accept duel requests")
	dontClickDuelsCheckbox:SetScript("OnShow", function(self) self:SetChecked(not DialogKey.db.global.dontClickDuels) end)
	dontClickDuelsCheckbox:SetScript("OnClick", function(self) DialogKey.db.global.dontClickDuels = not self:GetChecked() end)
	dontClickDuelsCheckbox:SetChecked(not DialogKey.db.global.dontClickDuels)
	
	-- Don't accept revives
	local dontClickRevivesCheckbox = CreateFrame("CheckButton", "DialogKeyOptDontClickRevives", optionsContent, "UICheckButtonTemplate")
	dontClickRevivesCheckbox:SetPoint("TOPLEFT", dontClickSummonsCheckbox, "BOTTOMLEFT", 0, 0)
	_G["DialogKeyOptDontClickRevivesText"]:SetText("Accept revives")
	dontClickRevivesCheckbox:SetScript("OnShow", function(self) self:SetChecked(not DialogKey.db.global.dontClickRevives) end)
	dontClickRevivesCheckbox:SetScript("OnClick", function(self) DialogKey.db.global.dontClickRevives = not self:GetChecked() end)
	dontClickRevivesCheckbox:SetChecked(not DialogKey.db.global.dontClickRevives)
	
	-- Don't accept releases
	local dontClickReleasesCheckbox = CreateFrame("CheckButton", "DialogKeyOptDontClickReleases", optionsContent, "UICheckButtonTemplate")
	dontClickReleasesCheckbox:SetPoint("TOPLEFT", dontClickRevivesCheckbox, "TOPLEFT", 300, 0)
	_G["DialogKeyOptDontClickReleasesText"]:SetText("Accept spirit releases")
	dontClickReleasesCheckbox:SetScript("OnShow", function(self) self:SetChecked(not DialogKey.db.global.dontClickReleases) end)
	dontClickReleasesCheckbox:SetScript("OnClick", function(self) DialogKey.db.global.dontClickReleases = not self:GetChecked() end)
	dontClickReleasesCheckbox:SetChecked(not DialogKey.db.global.dontClickReleases)
	
	-- Use soulstone rezzes instead
	local soulstoneRezCheckbox = CreateFrame("CheckButton", "DialogKeyOptSoulstoneRez", optionsContent, "UICheckButtonTemplate")
	soulstoneRezCheckbox:SetPoint("TOPLEFT", dontClickReleasesCheckbox, "BOTTOMLEFT", 0, 0)
	_G["DialogKeyOptSoulstoneRezText"]:SetText("Use soulstone resurrect when possible")
	soulstoneRezCheckbox:SetScript("OnShow", function(self) self:SetChecked(DialogKey.db.global.soulstoneRez) end)
	soulstoneRezCheckbox:SetScript("OnClick", function(self) DialogKey.db.global.soulstoneRez = self:GetChecked() end)
	soulstoneRezCheckbox:SetChecked(DialogKey.db.global.soulstoneRez)
	
	-- Additional buttons to click
	local additionalScroll = CreateFrame("ScrollFrame", "DialogKeyScrollFrame", optionsContent, "InputScrollFrameTemplate")
	additionalScroll:SetSize(300,150)
	additionalScroll:SetPoint("TOPLEFT", dontClickRevivesCheckbox, "BOTTOMLEFT", 9, -80)
	additionalScroll.CharCount:Hide()
	optionsContent.additionalScroll = additionalScroll
	
	-- to scroll the options frame if we're hovered over this scrollbox and scroll the mouse wheel
	additionalScroll:EnableMouseWheel(true)
	additionalScroll:SetScript("OnMouseWheel", function(self, delta)
		local scrollBar = self:GetParent():GetParent().scrollBar
		
		local current = scrollBar:GetValue()
		local minV, maxV = scrollBar:GetMinMaxValues()
			
		if delta < 0 and current >= minV then
			scrollBar:SetValue(math.min(maxV, current+30))
		elseif delta > 0 and current <= maxV then
			scrollBar:SetValue(math.max(minV, current-30))
		end
	end)
	
	local newvalue = table.concat(self.db.global.additionalButtons, "\n")
	additionalScroll.EditBox.previousText = newvalue
	additionalScroll.EditBox:SetText(newvalue)
	additionalScroll.EditBox:SetMaxLetters(0)
	additionalScroll.EditBox:SetWidth(additionalScroll:GetWidth())
	additionalScroll.EditBox:Enable()
	additionalScroll.EditBox:SetFont("Fonts\\ARIALN.TTF", 16)
	
	additionalScroll.EditBox:SetScript("OnEnterPressed", nil)
	
	additionalScroll.EditBox:SetScript("OnTextChanged", function(self)
		if self.previousText ~= self:GetText() then
			DialogKey.options.content.additionalSave:Show()
		end
		
		self.previousText = self:GetText()
	end)
	
	local additionalSave = CreateFrame("Button", nil, optionsContent, "UIPanelButtonTemplate")
	additionalSave:SetPoint("BOTTOMRIGHT", optionsContent.additionalScroll, "TOPRIGHT", 7,4)
	additionalSave:SetWidth(50)
	additionalSave:SetHeight(20)
	additionalSave:SetText("Save")
	additionalSave:SetScript("OnClick", DialogKey.SaveAdditionalButtons)
	additionalSave:Hide()
	optionsContent.additionalSave = additionalSave
	
	local additionalTitle = optionsContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	additionalTitle:SetFont("Fonts\\FRIZQT__.TTF", 12)
	additionalTitle:SetTextColor(1,1,1,1)
	additionalTitle:SetJustifyH("LEFT")
	additionalTitle:SetText("Additional buttons to click")
	additionalTitle:SetPoint("BOTTOMLEFT", optionsContent.additionalScroll, "TOPLEFT", -4, 6)
	
	local additionalExplanation = optionsContent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	additionalExplanation:SetFont("Fonts\\FRIZQT__.TTF", 10)
	additionalExplanation:SetTextColor(1,1,1,1)
	additionalExplanation:SetJustifyH("LEFT")
	additionalExplanation:SetWordWrap(true)
	additionalExplanation:SetWidth(240)
	additionalExplanation:SetText("Type a button's name here to track it. DialogKey will attempt to click on any tracked buttons when you hit the bound key. Note: not all buttons can be tracked.\n\nTo track a new button, hover over it and type \n|cffffff00/dialogkey add|r\nTo untrack a button, hover over it and type \n|cffffff00/dialogkey remove|r")
	additionalExplanation:SetPoint("TOPLEFT", optionsContent.additionalScroll, "TOPRIGHT", 15, 0)
	
	
	-- Dialog blacklist
	local blacklistScroll = CreateFrame("ScrollFrame", "DialogKeyScrollFrame", optionsContent, "InputScrollFrameTemplate")
	blacklistScroll:SetSize(300,150)
	blacklistScroll:SetPoint("TOPLEFT", additionalScroll, "BOTTOMLEFT", 0, -40)
	blacklistScroll.CharCount:Hide()
	optionsContent.blacklistScroll = blacklistScroll
	
	-- to scroll the options frame if we're hovered over this scrollbox and scroll the mouse wheel
	blacklistScroll:EnableMouseWheel(true)
	blacklistScroll:SetScript("OnMouseWheel", function(self, delta)
		local scrollBar = self:GetParent():GetParent().scrollBar
		
		local current = scrollBar:GetValue()
		local minV, maxV = scrollBar:GetMinMaxValues()
			
		if delta < 0 and current >= minV then
			scrollBar:SetValue(math.min(maxV, current+30))
		elseif delta > 0 and current <= maxV then
			scrollBar:SetValue(math.max(minV, current-30))
		end
	end)
	
	local blacklistValue = table.concat(self.db.global.dialogBlacklist, "\n")
	blacklistScroll.EditBox.previousText = blacklistValue
	blacklistScroll.EditBox:SetText(blacklistValue)
	blacklistScroll.EditBox:SetMaxLetters(0)
	blacklistScroll.EditBox:SetWidth(blacklistScroll:GetWidth())
	blacklistScroll.EditBox:Enable()
	blacklistScroll.EditBox:SetFont("Fonts\\ARIALN.TTF", 16)
	
	blacklistScroll.EditBox:SetScript("OnEnterPressed", nil)
	
	blacklistScroll.EditBox:SetScript("OnTextChanged", function(self)
		if self.previousText ~= self:GetText() then
			DialogKey.options.content.blacklistSave:Show()
		end
		
		self.previousText = self:GetText()
	end)
	
	local blacklistSave = CreateFrame("Button", nil, optionsContent, "UIPanelButtonTemplate")
	blacklistSave:SetPoint("BOTTOMRIGHT", optionsContent.blacklistScroll, "TOPRIGHT", 7,4)
	blacklistSave:SetWidth(50)
	blacklistSave:SetHeight(20)
	blacklistSave:SetText("Save")
	blacklistSave:SetScript("OnClick", DialogKey.SaveBlacklist)
	blacklistSave:Hide()
	optionsContent.blacklistSave = blacklistSave
	
	-- Blacklist title
	local blacklistTitle = optionsContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	blacklistTitle:SetFont("Fonts\\FRIZQT__.TTF", 12)
	blacklistTitle:SetTextColor(1,1,1,1)
	blacklistTitle:SetJustifyH("LEFT")
	blacklistTitle:SetText("Confirmation dialog blacklist")
	blacklistTitle:SetPoint("BOTTOMLEFT", optionsContent.blacklistScroll, "TOPLEFT", -4, 6)
	
	-- Blacklist description
	local blacklistExplanation = optionsContent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	blacklistExplanation:SetFont("Fonts\\FRIZQT__.TTF", 10)
	blacklistExplanation:SetTextColor(1,1,1,1)
	blacklistExplanation:SetJustifyH("LEFT")
	blacklistExplanation:SetWordWrap(true)
	blacklistExplanation:SetWidth(240)
	blacklistExplanation:SetText("Type strings of text here, one per line, to blacklist any confirmation dialog containing the text. If a dialog is blacklisted, DialogKey won't attempt to click any button in it. For example, enter\n\n|cffffff00invites you to a group|r\n\nand DialogKey won't accept group invites.")
	blacklistExplanation:SetPoint("TOPLEFT", optionsContent.blacklistScroll, "TOPRIGHT", 15, 0)
	
	-- Key cooldown title
	local cooldownTitle = optionsContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	cooldownTitle:SetFont("Fonts\\FRIZQT__.TTF", 14)
	cooldownTitle:SetTextColor(1,.75,0,1)
	cooldownTitle:SetJustifyH("LEFT")
	cooldownTitle:SetText("Keypress cooldown")
	cooldownTitle:SetPoint("TOPLEFT", blacklistScroll, "BOTTOMLEFT", -4, -20)
	
	-- Key cooldown description
	local cooldownDesc = optionsContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	cooldownDesc:SetFont("Fonts\\FRIZQT__.TTF", 11)
	cooldownDesc:SetTextColor(1,1,1,1)
	cooldownDesc:SetJustifyH("LEFT")
	cooldownDesc:SetText("How long to block normal input after a dialog button has been pressed by the bound key,\nto avoid jumping after spamming the dialog key (e.g. picking up quests).\nOnly suppresses game input (like jumping), not dialog key presses.")
	cooldownDesc:SetPoint("TOPLEFT", cooldownTitle, "BOTTOMLEFT", 0, -6)
	
	-- Key cooldown slider
	local cooldownSlider = CreateFrame("Slider", "DialogKeyCooldownSlider", optionsContent, "OptionsSliderTemplate")
	cooldownSlider:SetWidth(100)
	cooldownSlider:SetHeight(20)
	cooldownSlider:SetPoint("TOPLEFT", cooldownDesc, "BOTTOMLEFT", 9, -24)
	cooldownSlider:SetOrientation('HORIZONTAL')
	DialogKeyCooldownSliderLow:SetText("0s")
	DialogKeyCooldownSliderHigh:SetText("1s")
	cooldownSlider:SetMinMaxValues(0,1)
	cooldownSlider:SetValueStep(0.05)
	cooldownSlider:SetStepsPerPage(0.2)
	cooldownSlider:SetValue(DialogKey.db.global.keyCooldown)
	
	DialogKeyCooldownSliderText:SetText(DialogKey:ValueToString(DialogKey.db.global.keyCooldown))
	
	cooldownSlider:SetScript("OnValueChanged", function(self,value)
		-- Fix for slider:SetValueStep not actually working; do a SetValue to properly snap values
		if not self._onsetting then
			self._onsetting = true
			self:SetValue(self:GetValue())
			value = self:GetValue()
			self._onsetting = false
		else return end
		
		value = DialogKey:round(value*20,0)/20
		DialogKeyCooldownSliderText:SetText(DialogKey:ValueToString(value))
		DialogKey.db.global.keyCooldown = value
	end)
	
	self.options.name = "DialogKey"
	InterfaceOptions_AddCategory(self.options)
end

-- Binding mode --
function DialogKey:EnableKeybindMode(index)	-- Enables keybinding mode in the options frame
	self.options.content.additionalScroll.EditBox:ClearFocus()
	
	if self.keybindMode then
		return
	end
	
	-- Disable all other keybind buttons
	for i,button in pairs(self.options.content.keybindButtons) do
		if i ~= index then
			button:Disable()
		end
	end
	
	self.keybindMode = true
	self.keybindIndex = index
	self.options.content.keybindReminder:Show()
	self.frame:SetPropagateKeyboardInput(false)
end

function DialogKey:DisableKeybindMode()		-- Disables keybinding mode in the options frame
	DialogKey.keybindMode = false
	DialogKey.options.content.keybindReminder:Hide()
	
	-- Enable all keybind buttons
	for i,button in pairs(DialogKey.options.content.keybindButtons) do
		button:Enable()
	end
	
	DialogKey.timer = DialogKey:ScheduleTimer(function()
		DialogKey.frame:SetPropagateKeyboardInput(true)
	end, 0.1)
end

function DialogKey:HandleKeybind(key)		-- Run for a keypress during binding mode; saves that key as the bound one
	self.options.content.keybindButtons[self.keybindIndex]:SetText(GetBindingText(key))
	self.db.global.keys[self.keybindIndex] = key
	DialogKey:DisableKeybindMode()
	
	-- Clear this assignment from other options so you don't have both options set to SPACE or whatever; not necessary, but clean
	for i,thiskey in pairs(self.db.global.keys) do
		if i ~= self.keybindIndex and thiskey == key then
			self.db.global.keys[i] = nil
			self.options.content.keybindButtons[i]:SetText("")
		end
	end
end

function DialogKey:ClearBind(index)			-- Clears the keybind from the given binding button
	DialogKey.db.global.keys[index] = nil
	DialogKey.options.content.keybindButtons[index]:SetText("")
end

-- Options frame helpers --
function DialogKey:SaveAdditionalButtons()	-- Save the button names in the additional input to the saved settings
	self:Hide()
	local editbox = DialogKey.options.content.additionalScroll.EditBox
	editbox:ClearFocus()
	
	local final = {}
	for i,name in pairs({strsplit("\n",editbox:GetText())}) do
		name = strtrim(name)
		if name:len() > 0 then
			tinsert(final, name)
		end
	end
	
	DialogKey.db.global.additionalButtons = final
end

function DialogKey:UpdateAdditionalFrames()	-- Updates the "Additional buttons" textbox with the latest settings
	local editbox = self.options.content.additionalScroll.EditBox
	local newvalue = table.concat(self.db.global.additionalButtons, "\n")
	editbox.previousText = newvalue
	editbox:SetText(newvalue)
end

function DialogKey:SaveBlacklist()			-- Save the button names in the additional input to the saved settings
	self:Hide()
	local editbox = DialogKey.options.content.blacklistScroll.EditBox
	editbox:ClearFocus()
	
	local final = {}
	for i,name in pairs({strsplit("\n",editbox:GetText())}) do
		name = strtrim(name)
		if name:len() > 0 then
			tinsert(final, name)
		end
	end
	
	DialogKey.db.global.dialogBlacklist = final
end

function DialogKey:UpdateBlacklist()		-- Updates the "Additional buttons" textbox with the latest settings
	local editbox = self.options.content.blacklistScroll.EditBox
	local newvalue = table.concat(self.db.global.dialogBlacklist, "\n")
	editbox.previousText = newvalue
	editbox:SetText(newvalue)
end

function DialogKey:ValueToString(value)		-- Returns 'Disabled' for 0, '1 second' for 1, 'x seconds' for anything else
	if value == 0 then
		return "Disabled"
	elseif value == 1 then
		return value .. " second"
	else
		return value .. " seconds"
	end
end
