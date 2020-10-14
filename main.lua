-- Chat handlers --
function DialogKey:AddMouseFocus()				-- Adds the button under the cursor to the list of additional buttons to click
	local frame = GetMouseFocus()
	if not frame or frame:GetObjectType() ~= "Button" then
		DialogKey:Print("|cffff3333The cursor must be over a button to track it|r")
		return
	end
	
	local name = frame:GetName()
	if not name then
		name = DialogKey:FindPathTo(frame)
		if not name then
			DialogKey:Print("|cffff3333The button cannot be tracked|r")
			return
		end
	end
	
	DialogKey:WatchFrame(name)
end

function DialogKey:FindPathTo(frame)			-- Returns a path to the frame in the form of NamedFrame.child[.child ...]
	local i = 1
	local path = {}
	
	local function path_to(frame)
		-- Failsafe, just in case
		if i > 30 then return false end
		
		local parent = frame:GetParent()
		for k,v in pairs(parent) do
			if v == frame then
				table.insert(path, 1, k)
				
				if parent:GetName() then
					-- This level's parent has a name, so add it to the path and return it
					table.insert(path, 1, parent:GetName())
					return path
				else
					-- This frame doesn't have a name either, so search another level up
					return path_to(parent, path, i+1)
				end
			end
		end
		
		-- This parent has no pointer to the child frame, and since we haven't found a parent with a name yet,
		-- the original frame cannot be located via a Named -> child [-> child...] path
		return false
	end
	
	path = path_to(frame)
	if not path then return end
	
	return table.concat(path, ".")
end

function DialogKey:GetFrameByName(name)			-- Returns a frame object by global name or path returned from DialogKey:FindPathTo()
	if name:find("%.") then
		local parts = DialogKey:split(name, ".")
		local tbl=_G[parts[1]]
		
		if not tbl then return false end -- happens in cases like binding to a frame from an unloaded addon/UI element (like shipyard)
		
		for i=2,#parts do
			tbl = tbl[parts[i]]
		end
		return tbl
	else
		return _G[name]
	end
end

function DialogKey:RemoveMouseFocus()			-- Removes the button under the cursor from the list of additional buttons to click
	local frame = GetMouseFocus()
	if not frame or frame:GetObjectType() ~= "Button" then
		DialogKey:Print("|cffff3333The cursor must be over a button to untrack it|r")
		return
	end
	
	local name = frame:GetName()
	if not name then
		name = DialogKey:FindPathTo(frame)
		if not name then
			DialogKey:Print("|cffff3333That button is not being tracked|r")
			return
		end
	end
	
	DialogKey:UnwatchFrame(name)
end

function DialogKey:WatchFrame(name)				-- Add given frame to the watch list
	for k,frameName in pairs(self.db.global.additionalButtons) do
		if frameName == name then
			DialogKey:Print("|cffff3333Already tracking |cffffd700"..name.."|r")
			return
		end
	end
	
	tinsert(self.db.global.additionalButtons, name)
	DialogKey:Print("Started tracking |cffffd700" .. name .. "|r")
	
	local frame = DialogKey:GetFrameByName(name)
	if frame and frame:IsVisible() then
		DialogKey:Glow(frame, "add")
	end
	
	DialogKey:UpdateAdditionalFrames()
end

function DialogKey:UnwatchFrame(name)			-- Remove given frame from the watch list
	local removed = false
	for i,watchedframe in pairs(self.db.global.additionalButtons) do
		if watchedframe == name then
			removed = true
			tremove(self.db.global.additionalButtons, i)
		end
	end
	
	if removed then
		DialogKey:Print("Stopped tracking |cffffd700" .. name .. "|r")
	else
		DialogKey:Print("|cffff3333Not tracking |cffffd700" .. name .. "|r")
	end
	
	local frame = DialogKey:GetFrameByName(name)
	if frame and frame:IsVisible() then
		DialogKey:Glow(frame, "remove")
	end
	
	DialogKey:UpdateAdditionalFrames()
end

-- Primary functions --
function DialogKey:HandleKey(key)				-- Run for every key hit ever; runs ClickButtons() if it's the bound one
	if DialogKey.keybindMode then
		DialogKey:HandleKeybind(key)
		return
	end
	
	if GetCurrentKeyBoardFocus() then return end -- Don't handle key if we're typing into something
	
	if key:find("^%d$") and GossipFrameGreetingPanel:IsVisible() and DialogKey.db.global.numKeysForGossip then
		local num = 1
		local keynum = tonumber(key)
		for i=1,9 do
			local frame = GossipFrame.buttons[i]
			
			-- If the frame isn't blank (blank frames are used to separate gossip and quests)
			if frame and frame:IsVisible() and frame:GetText() then
				if num == keynum then
					DialogKey:ClickFrame(frame)
					self:SetPropagateKeyboardInput(false)
					return
				end
				
				num = num+1
			end
		end
	elseif key:find("^%d$") and QuestFrameGreetingPanel:IsVisible() and DialogKey.db.global.numKeysForGossip then
		local frames = DialogKey:GetQuestButtons()

		for _, entry in pairs(frames) do
			framename = entry.name
			frame_matches = framename:find("^"..key..".")
			if frame_matches then
				DialogKey:ClickFrame(entry.frame)
			end
		end
		
		-- TODO: check if above line works? surely sometimes it puts accepted quests above available quests?
		
		--[[
		if keynum <= GetNumActiveQuests() then
			SelectActiveQuest(keynum)
			DialogKey.frame:SetPropagateKeyboardInput(false)
			PlaySound(SOUNDKIT.IG_QUEST_LIST_SELECT)
			DialogKey:GlowQuestIndex(keynum)
			return
		elseif keynum <= GetNumActiveQuests()+GetNumAvailableQuests() then
			SelectAvailableQuest(keynum - GetNumActiveQuests())
			DialogKey.frame:SetPropagateKeyboardInput(false)
			PlaySound(SOUNDKIT.IG_QUEST_LIST_SELECT)
			DialogKey:GlowQuestIndex(keynum)
			return
		else
			return
		end
		]]
		
		--[[
		local num = 1
		for i=1,9 do
			local frame = _G["GossipTitleButton"..i]
			
			-- Try QuestTitleButton* instead if Gossip buttons aren't shown
			if not frame:IsVisible() then
				frame = _G["QuestTitleButton"..i]
			end
			
			-- If the frame isn't blank (blank frames are used to separate gossip and quests)
			if frame:IsVisible() and frame:GetText() then
				if num == keynum then
					DialogKey:ClickFrame(frame)
					self:SetPropagateKeyboardInput(false)
					return
				end
				
				num = num+1
			end
		end
		]]
	
	-- If 1-9 was pressed, 'select quest rewards' option is enabled, quest rewards are visible, and the quest is ready to complete
	elseif key:find("^%d$") and QuestInfoRewardsFrameQuestInfoItem1:IsVisible() and QuestFrameCompleteQuestButton:IsVisible() and DialogKey.db.global.numKeysForQuestRewards then
		local frame = _G["QuestInfoRewardsFrameQuestInfoItem"..key]
		
		if frame and frame:IsVisible() and frame.type == "choice" then -- All buttons return true for IsVisible(), actually visible visible ones are type 'choice' (others are type 'reward') ()
			if not GetCurrentKeyBoardFocus() then
				DialogKey:ClickFrame(frame)
				self:SetPropagateKeyboardInput(false)
				
				GameTooltip:SetOwner(frame, "ANCHOR_NONE")
				GameTooltip:SetQuestItem("choice", tonumber(key))
				GameTooltip:SetPoint("TOPLEFT", frame, "BOTTOMLEFT")
				GameTooltip_ShowCompareItem()
				GameTooltip:Show()
				ShoppingTooltip1:Show()
				
				return
			end
		end
	end
	
	-- If the dialog key was pressed (default space), try to hit a bound button and if one was found, don't propagate it
	if key == DialogKey.db.global.keys[1] or key == DialogKey.db.global.keys[2] then
		if DialogKey:ClickButtons() then		-- If we did hit a watched button, suppress keys for a second and don't propagate the keypress (e.g. don't jump)
			if DialogKey.db.global.keyCooldown > 0 then
				DialogKey.recentlyPressed = true
				DialogKey:ScheduleTimer(function() DialogKey.recentlyPressed = false end, DialogKey.db.global.keyCooldown)
			end
			
			self:SetPropagateKeyboardInput(false)
		elseif DialogKey.recentlyPressed then	-- If we didn't hit a button and the suppress timer is active, don't propagate the keypress (e.g. don't jump)
			self:SetPropagateKeyboardInput(false)
		else									-- If we didn't hit a button and the suppress timer isn't running, allow the keypress (e.g. jump)
			self:SetPropagateKeyboardInput(true)
		end
	else										-- If the pressed button wasn't even bound to DialogKey, allow the keypress (don't handle it)
		self:SetPropagateKeyboardInput(true)
	end
end

function DialogKey:ClickButtons()				-- Main function to click on dialog buttons when the bound key is pressed. Return true to mark the keypress as handled and block input (like jumping)
	for i,framename in pairs(DialogKey.buttons) do
		-- Workaround for BFA: we can't select individual gossip frames anymore, so we have to use these functions instead
		if framename == "QuestTitleButton1" and QuestFrame:IsVisible() then
			-- If there's any active quests, click the first completed one
			-- If none are completed, we'll move on to looking at available quests instead
			if GetNumActiveQuests() > 0 then -- If there's any quests to turn in, select the first one
				for i=1,GetNumActiveQuests() do
					local title,complete = GetActiveTitle(i)
					if complete then
						DialogKey:GlowQuestIndex(i)
						SelectActiveQuest(i)
						PlaySound(SOUNDKIT.IG_QUEST_LIST_SELECT)
						return true
					end
				end
			end
			
			-- If there's any available quests, click the first one
			if GetNumAvailableQuests() > 0 then
				DialogKey:GlowQuestIndex(GetNumActiveQuests() + 1)
				SelectAvailableQuest(1)
				PlaySound(SOUNDKIT.IG_QUEST_LIST_SELECT)
				return true
			end
			
			-- SET BACK TO FALSE
			return false -- We're done handling the QuestTitleButton1 frame, so exit the function
		
		-- Workaround for selecting first COMPLETED quest, even if it's not the first gossip option
		elseif framename == "GossipTitleButton1" and GossipFrame:IsVisible() then
			-- Try clicking the first gossip option with a completed quest icon -- also check if it's visible, since frames are reused and it might get stuck trying to click a leftover, invisible active quest button
			for i=1,9 do
				if _G["GossipTitleButton"..i.."GossipIcon"]:IsVisible() and (
					_G["GossipTitleButton"..i.."GossipIcon"]:GetTexture() == "Interface\\GossipFrame\\ActiveQuestIcon" or
					_G["GossipTitleButton"..i.."GossipIcon"]:GetTexture() == "Interface\\GossipFrame\\ActiveLegendaryQuestIcon") then
					return DialogKey:ClickFrameName("GossipTitleButton"..i)
				end
			end
			
			-- If none were found, just click the first one
			return DialogKey:ClickFrameName("GossipTitleButton1")
		
		elseif DialogKey:ClickFrameName(framename) then
			return true
		end
	end
	
	for i,framename in pairs(self.db.global.additionalButtons) do
		if DialogKey:ClickFrameName(framename) then
			return true
		end
	end
	
	if DialogKey.recentlyPressed then
		return true
	end
end

function DialogKey:ClickFrame(frame)			-- Attempts to click a passed frame
	-- If the frame doesn't exist, definitely don't do anything (unless it's QuestTitleButton1, we handle that specially)
	if not frame then
		return false
	end
	
	-- If we're typing into an editbox, don't do anything, except if it's during sending mail
	if StaticPopup1:IsVisible() and GetCurrentKeyBoardFocus() and (GetCurrentKeyBoardFocus():GetName() == "SendMailNameEditBox" or GetCurrentKeyBoardFocus():GetName() == "SendMailSubjectEditBox") then
		GetCurrentKeyBoardFocus():ClearFocus()
		DialogKey:Glow(frame, "click")
		frame:Click()
		return true
	elseif GetCurrentKeyBoardFocus() then
		return false
	end
	
	if frame:IsVisible() and (not self.db.global.ignoreDisabledButtons or (self.db.global.ignoreDisabledButtons and frame:IsEnabled())) then
		-- Don't accept summons/duels/resurrects if the options are enabled
		-- Takes a global string like '%s has challenged you to a duel.' and converts it to a format suitable for string.find
		local summon_match = CONFIRM_SUMMON:gsub("%%s", ".+"):gsub("%%d", ".+")
		if self.db.global.dontClickSummons and StaticPopup1:IsVisible() and StaticPopup1Text:GetText():find(summon_match)   then return end
		
		local duel_match = DUEL_REQUESTED:gsub("%%s",".+")
		if self.db.global.dontClickDuels   and StaticPopup1:IsVisible() and StaticPopup1Text:GetText():find(duel_match)     then return end
		
		-- If resurrect dialog has three buttons, and the option is enabled, use the middle one instead of the first one (soulstone, etc.)
		-- Located before resurrect/release checks/returns so it happens even if you have releases/revives disabled
		-- Also, Check if Button2 is visible instead of Button3 since Recap is always 3; 2 is hidden if you can't soulstone rez
		if StaticPopup1Button1Text:GetText() == DEATH_RELEASE and StaticPopup1Button2:IsVisible() and self.db.global.soulstoneRez then
			StaticPopup1Button2:Click()
			return
		end
		
		local resurrect_match = RESURRECT_REQUEST_NO_SICKNESS:gsub("%%s", ".+")
		if self.db.global.dontClickRevives and StaticPopup1:IsVisible() and (StaticPopup1Text:GetText() == RECOVER_CORPSE or StaticPopup1Text:GetText():find(resurrect_match)) then return end
		
		if self.db.global.dontClickReleases and StaticPopup1Button1:IsVisible() and StaticPopup1Button1Text:GetText() == DEATH_RELEASE then return end
		
		-- Don't click OK if the dialog box's text matches a blacklist line
		for i=1,#self.db.global.dialogBlacklist do
			if StaticPopup1Button1:IsVisible() and StaticPopup1Text:GetText():lower():find(self.db.global.dialogBlacklist[i]:lower()) then return end
		end
		
		-- Don't click OK if the dialog box's text matches a BUILT-IN blacklisted string
		-- (e.g. the Withered Army Training exit dialog - will never work because of taint issues with it casting a teleport spell
		for i=1,#DialogKey.builtinDialogBlacklist do
			if StaticPopup1Button1:IsVisible() and StaticPopup1Text:GetText():lower():find(DialogKey.builtinDialogBlacklist[i]:lower()) then
				DialogKey:Print("|cffff3333This dialog casts a spell and does not work with DialogKey. Sorry!|r")
				return
			end
		end
		
		DialogKey:Glow(frame, "click")
		frame:Click()
		return true
	end
end

function DialogKey:ClickFrameName(framename)	-- Attempts to click a frame by name (or path)
	return DialogKey:ClickFrame(DialogKey:GetFrameByName(framename))
end

function DialogKey:GetQuestButtons()			-- Return sorted list of quest button frames
	-- TODO: fix order being wrong on first load?
	local frames = {}
	for f,unknown in QuestFrameGreetingPanel.titleButtonPool:EnumerateActive() do
		table.insert(frames,{
			top      = f:GetTop(),
			frame    = f,
			name     = f:GetText()
		})
	end
	
	table.sort(frames,function(a,b)
		if a.top > b.top then
			return 1
		elseif a.top < b.top then
			return -1
		end
		
		return 0
	end)
	
	return frames
end

function DialogKey:EnumerateGossips_Gossip()	-- Prefixes 1., 2., etc. to NPC options
	if not DialogKey.db.global.numKeysForGossip then return end
	if not GossipFrameGreetingPanel:IsVisible() and not QuestFrameGreetingPanel:IsVisible() then return end
	
	local num = 1

	availableOptions = GossipFrame.buttons
	for i=1,math.min(9, table.getn(availableOptions)) do
		local frame = availableOptions[i]
		-- print(frame)
		if not frame:GetText():find("^"..num.."\. ") then
			frame:SetText(num .. ". " .. frame:GetText())
		end
		
		num = num+1
	end
end

function DialogKey:EnumerateGossips_Quest()		-- Prefixes 1., 2., etc. to NPC options
	if not DialogKey.db.global.numKeysForGossip then return end
	if not GossipFrameGreetingPanel:IsVisible() and not QuestFrameGreetingPanel:IsVisible() then return end
	
	local frames = DialogKey:GetQuestButtons()
	local num = 1
	for i,f in pairs(frames) do
		local frame = f.frame
		if frame:IsVisible() and frame:GetText() then
			if not frame:GetText():find("^"..num.."\. ") then
				frame:SetText(num .. ". " .. frame:GetText())
			end
			
			num = num+1
		end
	end
	
	--[[
	local num = 1
	for i=1,9 do
		local frame
		if GossipFrame:IsVisible() then
			frame = _G["GossipTitleButton"..i]
		else
			frame = _G["QuestTitleButton"..i]
		end
		
		if frame:IsVisible() and frame:GetText() then
			if not frame:GetText():find("^"..num.."\. ") then
				frame:SetText(num .. ". " .. frame:GetText())
			end
			
			num = num+1
		end
	end
	]]
end

function DialogKey:Glow(frame, mode)			-- Show the glow frame over a frame. Mode is "click", "add", or "remove"
	if mode == "click" then
		if DialogKey.db.global.showGlow then
			self.glowFrame:SetAllPoints(frame)
			self.glowFrame.tex:SetColorTexture(1,1,0,0.5)
			self.glowFrame:Show()
			self.glowFrame:SetAlpha(1)
		end
	elseif mode == "add" then
		self.glowFrame:SetAllPoints(frame)
		self.glowFrame.tex:SetColorTexture(0,1,0,0.5)
		self.glowFrame:Show()
		self.glowFrame:SetAlpha(1)
	elseif mode == "remove" then
		self.glowFrame:SetAllPoints(frame)
		self.glowFrame.tex:SetColorTexture(1,0,0,0.5)
		self.glowFrame:Show()
		self.glowFrame:SetAlpha(1)
	end
end

function DialogKey:GlowQuestIndex(i)			-- Show the glow frame over a specific quest button
	if not DialogKey.db.global.showGlow then return end
	
	local frames = DialogKey:GetQuestButtons()
	
	--DialogKey:print_r(frames)
	
	self.glowFrame:SetAllPoints(frames[i].frame)
	self.glowFrame.tex:SetColorTexture(1,1,0,0.5)
	self.glowFrame:Show()
	self.glowFrame:SetAlpha(1)
end

function DialogKey:GlowFrameUpdate(delta)		-- Fades out the glow frame
	-- Use delta (time since last frame) so animation takes same amount of time regardless of framerate
	self:SetAlpha(self:GetAlpha() - delta*3)
	if self:GetAlpha() <= 0 then self:Hide() end
end

-- Scroll functions --
function DialogKey:EnableQuestScrolling()		-- Traps the mouse wheel input if the option's enabled and the quest details frame can scroll
	if not DialogKey.db.global.scrollQuests then return end
	if InCombatLockdown() == 1 then return end
	
	for i,frame in pairs(DialogKey.scrollFrames) do
		if frame:IsVisible() and frame:GetVerticalScrollRange() > 0 then
			UIParent:EnableMouseWheel(true)
		end
	end
end

function DialogKey:DisableQuestScrolling()		-- Frees up mouse wheel input again when a scroll frame is hidden, or when leaving combat
	local found = false
	
	for i,frame in pairs(DialogKey.scrollFrames) do
		if frame:IsVisible() and frame:GetVerticalScrollRange() > 0 then
			found = true
		end
	end
	
	if not found then
		UIParent:EnableMouseWheel(false)
	end
end

function DialogKey:HandleScroll(delta)			-- Run when the mouse wheel is trapped and the user scrolls it
	if not DialogKey.db.global.scrollQuests then return end
	
	local scrollFrame
	
	for i,frame in pairs(DialogKey.scrollFrames) do
		if frame:IsVisible() and frame:GetVerticalScrollRange() > 0 then
			scrollFrame = frame
			local scrollAmount = frame:GetVerticalScroll()+(-185.5*delta)
			scrollAmount = min(max(scrollAmount, 0), frame:GetVerticalScrollRange())
			frame:SetVerticalScroll(scrollAmount)
			
			if delta > 0 then
				DialogKey:Glow(_G[scrollFrame:GetName().."ScrollBarScrollUpButton"], "click")
			else
				DialogKey:Glow(_G[scrollFrame:GetName().."ScrollBarScrollDownButton"], "click")
			end
		end
	end
end

-- Debug functions --

function DialogKey:debug_dialog(key)			-- Print debug info about currently active quest/gossip window
	print("===== debugging =====")
	key = tostring(key)
	if key:find("^%d$") and (GossipFrameGreetingPanel:IsVisible() or QuestFrameGreetingPanel:IsVisible()) and DialogKey.db.global.numKeysForGossip then
		local num = 1
		for i=1,9 do
			print("i="..i..", num="..num)
			local frame = _G["GossipTitleButton"..i]
			print("GossipTitleButton"..i)
			
			-- Try QuestTitleButton* instead if Gossip buttons aren't shown
			if not frame:IsVisible() then
				print("GossipTitleButton"..i.." not found, trying QuestTitleButton"..i)
				frame = _G["QuestTitleButton"..i]
			end
			
			-- If the frame isn't blank (blank frames are used to separate gossip and quests)
			if frame:IsVisible() and frame:GetText() then
				print(" - frame has text")
				if tostring(num) == key then
					print(" - tostring("..num..") == "..key..", clicking "..frame:GetName())
					print("text is: "..frame:GetText())
					--DialogKey:ClickFrame(frame)
					DialogKeyFrame:SetPropagateKeyboardInput(false)
					return
				else
					print(" - tostring("..num..") != "..key..", skipping")
				end
				
				num = num+1
			else
				print(" - frame has no text, skipping")
			end
			
			print("------------------------")
		end
	else
		print("no dialog found")
	end
end

function DialogKey:debug_gettextures()			-- Print currently visible quest list icon textures
	for i=1,9 do
		print("GossipTitleButton"..i.."GossipIcon" .. ":" .. _G["GossipTitleButton"..i.."GossipIcon"]:GetTexture())
	end
end