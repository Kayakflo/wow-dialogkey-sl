DialogKey = LibStub("AceAddon-3.0"):NewAddon("DialogKey", "AceConsole-3.0", "AceTimer-3.0", "AceEvent-3.0")

--[[
		Raimond Mildenhall
		
		? Free the Farmhands
		? Fetching Wrex
		! The Bee Team
		! Wendigo Away
		
		\AddOns\DialogKey\main.lua line 638: attempt to index local 'a' (a nil value)
		if a.top > b.top then return 1 end
]]


--[[
	GossipFrame with quests: nethergarde keep, 2 quests to free spirits and kill bonepickers, do spirit quest - makes second quest the one we want to hit first
	
	* fixed keybinding mode
	* added cooldown option
	* fixed issues with QuestFrames (some quest givers use QuestFrame, some use GossipFrame)
	<< requires a game restart >>
]]

local defaults = {								-- Default settings
	global = {
		keys = {
			"SPACE",
		},
		ignoreDisabledButtons = true,
		showGlow = true,
		shownBindWarning = false,
		additionalButtons = {},
		dialogBlacklist = {},
		numKeysForGossip = true,
		numKeysForQuestRewards = true,
		scrollQuests = false,
		dontClickSummons = false,
		dontClickDuels = false,
		dontClickRevives = false,
		dontClickReleases = false,
		soulstoneRez = true,
		keyCooldown = 0.5
	}
}

DialogKey.buttons = {							-- List of buttons to try and click
	"StaticPopup1Button1",
	"QuestFrameCompleteButton",
	"QuestFrameCompleteQuestButton",
	"QuestFrameAcceptButton",
	"GossipTitleButton1",
	"QuestTitleButton1"
}

DialogKey.scrollFrames = {						-- List of quest frames to try and scroll
	QuestDetailScrollFrame,
	QuestLogPopupDetailFrameScrollFrame,
	QuestMapDetailsScrollFrame,
	ClassicQuestLogDetailScrollFrame
}

DialogKey.builtinDialogBlacklist = {			-- If a confirmation dialog contains one of these strings, don't accept it
	"Are you sure you want to go back to Shal'Aran?", -- Seems to bug out and not work if an AddOn clicks the confirm button?
}

function DialogKey:OnInitialize()				-- Runs on addon initialization
	self.db = LibStub("AceDB-3.0"):New("DialogKeyDB", defaults, true)
	
	self.keybindMode = false
	self.keybindIndex = 0
	self.recentlyPressed = false
	
	self:RegisterChatCommand("dk", "ChatCommand")
	self:RegisterChatCommand("dkey", "ChatCommand")
	self:RegisterChatCommand("dialogkey", "ChatCommand")
	
	self:RegisterEvent("GOSSIP_SHOW",		  function() self:ScheduleTimer(self.EnumerateGossips_Gossip, 0.01) end)
	self:RegisterEvent("QUEST_GREETING",	  function() self:ScheduleTimer(self.EnumerateGossips_Quest, 0.01) end)
	self:RegisterEvent("PLAYER_REGEN_ENABLED",function() self:ScheduleTimer(self.DisableQuestScrolling, 0.1) end) -- Since scrolling can't be disabled on closing a scrollframe in combat, wait til the end of combat to try disabling
	
	QuestInfoRewardsFrameQuestInfoItem1:HookScript("OnHide", function() GameTooltip:Hide() end) -- Hide GameTooltip when the quest is finished
	
	for i,frame in pairs(DialogKey.scrollFrames) do
		frame:HookScript("OnShow", function() self:ScheduleTimer(self.EnableQuestScrolling, 0.01) end)
		frame:HookScript("OnHide", function() self:ScheduleTimer(self.DisableQuestScrolling, 0.1) end)
	end
	
	UIParent:HookScript("OnMouseWheel", self.HandleScroll)
	UIParent:EnableMouseWheel(false) -- Required since it's enabled upon hooking OnMouseWheel
	
	self.frame = CreateFrame("Frame", "DialogKeyFrame", UIParent)
	self.frame:EnableKeyboard(true)
	self.frame:SetPropagateKeyboardInput(true)
	self.frame:SetFrameStrata("TOOLTIP") -- Ensure we receive keyboard events first
	self.frame:SetScript("OnKeyDown", DialogKey.HandleKey)
	
	self.glowFrame = CreateFrame("Frame", "DialogKeyGlow", UIParent)
	self.glowFrame:SetPoint("CENTER", 0, 0)
	self.glowFrame:SetFrameStrata("TOOLTIP")
	self.glowFrame:SetSize(50,50)
	self.glowFrame:SetScript("OnUpdate", DialogKey.GlowFrameUpdate)
	self.glowFrame:Hide()
	self.glowFrame.tex = self.glowFrame:CreateTexture()
	self.glowFrame.tex:SetAllPoints()
	self.glowFrame.tex:SetColorTexture(1,1,0,0.5)
	
	self:ShowOldKeybindWarning()
	self:CreateOptionsFrame()
end

function DialogKey:ChatCommand(input)			-- Chat command handler
	local args = {strsplit(" ", input:trim())}
	
	if args[1] == "v" or args[1] == "ver" or args[1] == "version" then
		DialogKey:Print(GAME_VERSION_LABEL..": |cffffd700"..GetAddOnMetadata("DialogKey","Version").."|r")
	elseif args[1] == "add" or args[1] == "a" or args[1] == "watch" then
		if args[2] then
			DialogKey:WatchFrame(args[2])
		else
			DialogKey:AddMouseFocus()
		end
	elseif args[1] == "remove" or args[1] == "r" or args[1] == "unwatch" then
		if args[2] then
			DialogKey:UnwatchFrame(args[2])
		else
			DialogKey:RemoveMouseFocus()
		end
	elseif args[1] == "d" or args[1] == "dbg" or args[1] == "debug" then
		DialogKey:ClickButtonsDebug()
	else
		-- Twice, since the first call only succeeds in opening the options panel itself; the second call opens the correct category
		InterfaceOptionsFrame_OpenToCategory(self.options)
		InterfaceOptionsFrame_OpenToCategory(self.options)
	end
end

function DialogKey:Print(message,msgType)		-- Prefixed print function
	DEFAULT_CHAT_FRAME:AddMessage("|cffd2b48c[DialogKey]|r "..message.."|r")
end

function DialogKey:ShowOldKeybindWarning()		-- Shows a popup warning the user that they've got old VEK binds
	if not self.db.global.shownBindWarning then
		self.db.global.shownBindWarning = true
		
		local key1 = GetBindingKey("ACCEPTDIALOG")
		local key2 = GetBindingKey("ACCEPTDIALOG_CHAT")
		
		-- Treat only having the second key bound as only having the first key bound for simplicity
		if key2 and not key1 then
			key1 = key2
			key2 = nil
		end
		
		local str
		if key1 then
			if key2 then
				str = "DialogKey is a replacement of Versatile Enter Key, which is now obsolete.\n\nYour '" .. GetBindingText(key1) .. "' and '" .. GetBindingText(key2) .. "' keys are still bound to Versatile Enter Key actions. You should rebind them to their original actions if they were originally bound to something important!"
			else
				str = "DialogKey is a replacement of Versatile Enter Key, which is now obsolete.\n\nYour '" .. GetBindingText(key1) .. "' key is still bound to a Versatile Enter Key action. You should rebind it to its original action if it was originally bound to something important!"
			end
		end
		
		if str then
			StaticPopupDialogs["DIALOGKEY_OLDBINDWARNING"] = {
				text = str,
				button1 = "Open Keybinds",
				button2 = OKAY,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				
				OnAccept = function()
					KeyBindingFrame_LoadUI()
					ShowUIPanel(KeyBindingFrame)
				end
			}
			StaticPopup_Show("DIALOGKEY_OLDBINDWARNING")
		end
	end
end

-- Misc. Lua functions --
function DialogKey:print_r ( t )				-- Recursively print a table
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    sub_print_r(t,"  ")
end

function DialogKey:split(str, sep)				-- Splits str along sep
	local sep, fields = sep or ":", {}
	local pattern = string.format("([^%s]+)", sep)
	string.gsub(str, pattern, function(c) fields[#fields+1] = c end)
	return fields
end

function DialogKey:round(num, numDecimalPlaces)	-- Round a number to x decimal places
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end
