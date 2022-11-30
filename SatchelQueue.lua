local SatchelQueue = LibStub("AceAddon-3.0"):NewAddon("SatchelQueue", "AceEvent-3.0", "AceHook-3.0")
_G.SatchelQueue = SatchelQueue -- debug

local soundFile = "Sound\\Spells\\Clearcasting_Impact_Chest.wav"
local media = LibStub("LibSharedMedia-3.0", true)
if media then
	media:Register("sound", "SatchelQueue Alert", soundFile)
end

local db
local defaults = {
	profile = {
		icon = true,
		requeue = false,
		flash_enable = false,
		sound_enable = true,
		sound_force = false,
		sound_file = "SatchelQueue Alert",
	}
}

local SATCHEL_ID = 122607
local SATCHELQUEUE = "SatchelQueue"
local BUTTON_CANCEL = "Stop Looking"
local TIME_WAITING = "Time Waiting: %s"

-- GLOBALS: LibStub UIParent EquipmentFlyoutFrame AuctionFrame QueueStatusFrame MailFrame GameTooltip QueueStatusButton
-- GLOBALS: LFDQueueFrameRoleButtonDPS LFDQueueFrameRoleButtonHealer LFDQueueFrameRoleButtonTank
-- GLOBALS: UIDropDownMenu_CreateInfo UIDropDownMenu_AddButton InterfaceOptionsFrame_OpenToCategory C_PetBattles C_Timer
-- GLOBALS: LFDQueueFrame_GetRoles StaticPopup_Show StaticPopup_Hide StaticPopup_Visible
-- GLOBALS: NUM_LE_LFG_CATEGORYS MAX_WORLD_PVP_QUEUES LFG_SUBTYPEID_RAID LE_LFG_CATEGORY_LFD NUM_BAG_SLOTS LOOT_SLOT_MONEY LFD_NUM_ROLES
-- GLOBALS: LESS_THAN_ONE_MINUTE LEAVE_QUEUE SETTINGS LFD_STATISTIC_CHANGE_TIME LFG_ROLE_SHORTAGE_RARE LFG_CALL_TO_ARMS
-- GLOBALS: SlashCmdList SLASH_SATCHELQUEUE1 SLASH_SATCHELQUEUE2 SLASH_SATCHELQUEUE3 SLASH_SATCHELQUEUE4

StaticPopupDialogs["SATCHEL_QUEUE"] = {
	text = LFG_CALL_TO_ARMS,
	button1 = ACCEPT,
	button2 = DECLINE,
	OnAccept = function(self)
		SetLFGDungeon(LE_LFG_CATEGORY_LFD, self.data)
		JoinLFG(LE_LFG_CATEGORY_LFD)
	end,
	hideOnEscape = 1,
	whileDead = 1,
	preferredIndex = STATICPOPUP_NUMDIALOGS,
}


local SetSound, ResetSound
do
	local volume, sfxChanged, enableChanged, bgChanged = nil, nil, nil, nil

	function SetSound()
		if not db.sound_force then return end
		if not GetCVarBool("Sound_EnableAllSound") then
			enableChanged = true
			SetCVar("Sound_EnableAllSound", 1)
		end
		if not GetCVarBool("Sound_EnableSoundWhenGameIsInBG") then
			bgChanged = true
			SetCVar("Sound_EnableSoundWhenGameIsInBG", 1)
		end
		if not GetCVarBool("Sound_EnableSFX") then
			sfxChanged = true
			SetCVar("Sound_EnableSFX", 1)
		end
		volume = GetCVar("Sound_MasterVolume")
		SetCVar("Sound_MasterVolume", 1)
	end

	function ResetSound()
		if volume then
			SetCVar("Sound_MasterVolume", volume)
		end
		if sfxChanged then
			SetCVar("Sound_EnableSFX", 0)
		end
		if bgChanged then
			SetCVar("Sound_EnableSoundWhenGameIsInBG", 0)
		end
		if enableChanged then
			SetCVar("Sound_EnableAllSound", 0)
		end
		volume = nil
		sfxChanged = nil
		enableChanged = nil
		bgChanged = nil
	end
end

-- move you over to the left
LFDQueueFrameFindGroupButton:ClearAllPoints()
LFDQueueFrameFindGroupButton:SetPoint("BOTTOMLEFT", 0, 4)

local button = CreateFrame("Button", "SatchelQueueButton", LFDQueueFrame, "MagicButtonTemplate")
button:SetWidth(135)
button:SetText(SATCHELQUEUE)
button:SetPoint("BOTTOMRIGHT", -3, 4)
button:SetScript("OnClick", function(self, button) SatchelQueue:Toggle() end)
button:Show()

local flash = CreateFrame("Frame")
flash:SetFrameStrata("FULLSCREEN_DIALOG")
flash:SetAllPoints()
flash.texture = flash:CreateTexture(nil, "BACKGROUND")
flash.texture:SetAllPoints()
flash.texture:SetTexture("Interface\\FullScreenTextures\\LowHealth")
flash.texture:SetBlendMode("ADD")
flash:Hide()

local dropdown = CreateFrame("Frame", "SatchelQueueDropDown", QueueStatusButton, "UIDropDownMenuTemplate")
UIDropDownMenu_Initialize(dropdown, function(frame, level)
	local info = UIDropDownMenu_CreateInfo()
	wipe(info)

	info.text = SATCHELQUEUE
	info.isTitle = 1
	info.notCheckable = 1
	UIDropDownMenu_AddButton(info)

	info.disabled = nil
	info.isTitle = nil
	info.leftPadding = 10

	info.text = LEAVE_QUEUE
	info.func = function() SatchelQueue:Stop() end
	UIDropDownMenu_AddButton(info)

	info.text = SETTINGS
	info.func = function()
		InterfaceOptionsFrame_OpenToCategory("SatchelQueue")
		InterfaceOptionsFrame_OpenToCategory("SatchelQueue")
	end
	UIDropDownMenu_AddButton(info)

end, "MENU")


local jackieFrame = CreateFrame("Button", "SatchelQueueJackieButton")
jackieFrame:SetNormalTexture([[Interface\AddOns\SatchelQueue\status]])
jackieFrame:SetPoint("CENTER", QueueStatusButton, "CENTER")
jackieFrame:SetSize(32, 32)
jackieFrame:EnableMouse(true)
jackieFrame:RegisterForClicks("LeftButtonDown", "RightButtonDown")
jackieFrame:Hide()

jackieFrame:SetScript("OnClick", function(self, button)
	if SatchelQueue.running then -- and GetLFGMode(LE_LFG_CATEGORY_LFD)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
		ToggleDropDownMenu(1, nil, dropdown, jackieFrame, 0, 0)
	end
end)

local statusFrame = CreateFrame("Frame", "SatchelQueueStatusFrame", UIParent, "TooltipBorderedFrameTemplate")
statusFrame:SetPoint("TOPRIGHT", QueueStatusButton, "TOPLEFT", 0, 0)
statusFrame:SetSize(275, 55)
statusFrame:SetFrameStrata("TOOLTIP")
statusFrame:SetClampedToScreen(true)
statusFrame:Hide()

local entry = CreateFrame("Frame", "SatchelQueueStatusEntry", statusFrame, "QueueStatusEntryTemplate")
entry:SetPoint("TOP")
entry:SetHeight(55)
entry.Title:SetText(SATCHELQUEUE)
entry.Status:Hide()
entry.TanksFound:Hide()
entry.HealersFound:Hide()
entry.DamagersFound:Hide()
entry.EntrySeparator:Hide()
entry.TimeInQueue:SetPoint("TOPLEFT", entry, "TOPLEFT", 10, -30)
entry:SetScript("OnUpdate", function(self, elapsed)
	self.total = (self.total or 0) + elapsed
	if self.total > 0.1 then
		self.total = 0
		local elapsed = SatchelQueue.queuedTime and (GetTime() - SatchelQueue.queuedTime) or 0
		self.TimeInQueue:SetFormattedText(TIME_WAITING, (elapsed >= 60) and SecondsToTime(elapsed) or LESS_THAN_ONE_MINUTE)
		self.TimeInQueue:Show()
	end
end)
entry:Show()

jackieFrame:SetScript("OnLeave", function() statusFrame:Hide() end)
jackieFrame:SetScript("OnEnter", function()
	if not SatchelQueue.running or not SatchelQueue.queuedTime then return end

	local showMinimapButton
	for i=1, NUM_LE_LFG_CATEGORYS do
		local mode = GetLFGMode(i)
		if mode then
			showMinimapButton = true
			break
		end
	end

	--local mode = GetLFGMode(LE_LFG_CATEGORY_LFD)
	statusFrame:ClearAllPoints()
	if showMinimapButton then
		statusFrame:SetPoint("BOTTOM", QueueStatusFrame, "TOP")
	else
		QueueStatusFrame:Hide()
		statusFrame:SetPoint("RIGHT", QueueStatusButton, "LEFT", 0, 28)
	end

	local nextRoleIcon = 1
	if LFDQueueFrameRoleButtonDPS.checkButton:GetChecked() then
		local icon = entry["RoleIcon"..nextRoleIcon]
		icon:SetTexCoord(GetTexCoordsForRole("DAMAGER"))
		icon:Show()
		nextRoleIcon = nextRoleIcon + 1
	end
	if LFDQueueFrameRoleButtonHealer.checkButton:GetChecked() then
		local icon = entry["RoleIcon"..nextRoleIcon]
		icon:SetTexCoord(GetTexCoordsForRole("HEALER"))
		icon:Show();
		nextRoleIcon = nextRoleIcon + 1
	end
	if LFDQueueFrameRoleButtonTank.checkButton:GetChecked() then
		local icon = entry["RoleIcon"..nextRoleIcon]
		icon:SetTexCoord(GetTexCoordsForRole("TANK"))
		icon:Show()
		nextRoleIcon = nextRoleIcon + 1
	end
	for i = nextRoleIcon, LFD_NUM_ROLES do
		entry["RoleIcon"..i]:Hide()
	end

	statusFrame:Show()
end)

-- LFD Actions
do
	local timerFrame = CreateFrame("Frame")

	local function UpdateMapIcon()
		if not db.icon then return end

		local showMinimapButton = nil

		-- All LFG types
		for i=1, NUM_LE_LFG_CATEGORYS do
			local mode, submode = GetLFGMode(i);
			if mode then --  and submode ~= "noteleport"
				showMinimapButton = true
				break
			end
		end

		-- LFGList
		if C_LFGList.HasActiveEntryInfo() then
			showMinimapButton = true
		end

		local apps = C_LFGList.GetApplications()
		for i=1, #apps do
			local _, appStatus = C_LFGList.GetApplicationInfo(apps[i])
			if appStatus == "applied" then
				showMinimapButton = true
				break
			end
		end

		-- PvP
		local inProgress, _, _, _, _, isBattleground = GetLFGRoleUpdate()
		if inProgress and isBattleground then
			showMinimapButton = true
		end

		for i=1, GetMaxBattlefieldID() do
			local status, mapName, teamSize, registeredMatch = GetBattlefieldStatus(i)
			if status and status ~= "none" then
				showMinimapButton = true
				break
			end
		end

		for i=1, GetMaxBattlefieldID() do
			local status = GetBattlefieldStatus(i)
			if status and status ~= "none" then
				showMinimapButton = true
				break
			end
		end

		-- World PvP
		for i=1, MAX_WORLD_PVP_QUEUES do
			local status = GetWorldPVPQueueStatus(i)
			if status and status ~= "none" then
				showMinimapButton = true
				break
			end
		end

		-- World PvP areas we're currently in
		if CanHearthAndResurrectFromArea() then
			showMinimapButton = true
		end

		-- Pet Battle PvP Queue
		if C_PetBattles.GetPVPMatchmakingInfo() then
			showMinimapButton = true
		end

		-- no blizzard icon shown, so show our fake one
		SatchelQueueJackieButton:SetShown(not showMinimapButton and timerFrame:IsShown())
	end

	local total = 0
	timerFrame:Hide()
	timerFrame:SetScript("OnUpdate", function(self, elapsed)
		total = total + elapsed
		if total < LFD_STATISTIC_CHANGE_TIME then return end
		total = 0
		RequestLFDPlayerLockInfo()
	end)

	timerFrame:SetScript("OnShow", function(self)
		total = 0
		button:SetText(BUTTON_CANCEL)
		SatchelQueue:RegisterEvent("LFG_UPDATE_RANDOM_INFO")
		SatchelQueue:RegisterEvent("LFG_PROPOSAL_SHOW")
		SatchelQueue:RegisterEvent("GROUP_ROSTER_UPDATE")
		RequestLFDPlayerLockInfo()
		SatchelQueue.running = true
		SatchelQueue.queuedTime = GetTime()
		SatchelQueue:SecureHook(QueueStatusFrame, "Update", UpdateMapIcon)
	end)

	timerFrame:SetScript("OnHide", function(self)
		SatchelQueue:UnregisterEvent("LFG_UPDATE_RANDOM_INFO")
		SatchelQueue:UnregisterEvent("LFG_PROPOSAL_SHOW")
		SatchelQueue:UnregisterEvent("GROUP_ROSTER_UPDATE")
		button:SetText(SATCHELQUEUE)
		ResetSound()
		SatchelQueue.running = nil
		SatchelQueue.queuedTime = nil
		SatchelQueue:Unhook(QueueStatusFrame, "Update")
	end)

	function SatchelQueue:GROUP_ROSTER_UPDATE()
		if GetNumGroupMembers() > 0 then
			self:Stop()
		end
	end

	function SatchelQueue:Delay(t)
		total = -t
	end

	function SatchelQueue:Stop()
		timerFrame:Hide()
		UpdateMapIcon()
	end

	function SatchelQueue:Toggle()
		if timerFrame:IsShown() then
			timerFrame:Hide()
		else
			timerFrame:Show()
		end
		UpdateMapIcon()
	end
end


-- LFG_PROPOSAL_SHOW / LFG_UPDATE_RANDOM_INFO
do
	local function CheckQueuePopReward(dungeonID, role)
		local eligible, forTank, forHealer, forDamage, itemCount = GetLFGRoleShortageRewards(dungeonID, LFG_ROLE_SHORTAGE_RARE)
		return eligible and itemCount > 0 and ((role == "TANK" and forTank) or (role == "HEALER" and forHealer) or (role == "DAMAGER" and forDamage))
	end

	local function CheckQueueReward(dungeonID)
		local leaderChecked, tankChecked, healerChecked, damageChecked = LFDQueueFrame_GetRoles()
		local eligible, forTank, forHealer, forDamage, itemCount = GetLFGRoleShortageRewards(dungeonID, LFG_ROLE_SHORTAGE_RARE)
		return eligible and itemCount > 0 and ((tankChecked and forTank) or (healerChecked and forHealer) or (damageChecked and forDamage))
	end

	function SatchelQueue:LFG_PROPOSAL_SHOW()
		local _, dungeonID, typeID, subtypeID, name, _, role = GetLFGProposal()
		if subtypeID == LFG_SUBTYPEID_RAID then return end

		if CheckQueuePopReward(dungeonID, role) then
			if db.sound_enable then
				SetSound()
				PlaySoundFile(media and media:Fetch("sound", db.sound_file) or soundFile, "Master")
			end

			if db.flash_enable then
				UIFrameFlash(flash, 0.5, 0.5, 10.0, nil, 0.0, 0.0)
			end

			-- set a grace period for accepting the queue so if we lose the shortage in the meantime it's not auto declined
			SatchelQueue:Delay(10)
		elseif not IsInGroup() then
			print("|cff33ff99SatchelQueue|r: Declining queue because it has no satchel reward!")
			RejectProposal(LE_LFG_CATEGORY_LFD)
		end
	end

	function SatchelQueue:LFG_UPDATE_RANDOM_INFO()
		if not SatchelQueue.running then return end

		ResetSound()

		for i=1, NUM_LE_LFG_CATEGORYS do
			local mode = GetLFGMode(i)
			if i == LE_LFG_CATEGORY_LFD then
				if not mode then
					if not SatchelQueue.queuedTime then
						SatchelQueue.queuedTime = GetTime()
					end

					for i = GetNumRandomDungeons(), 1, -1 do
						local id, name, _, diff = GetLFGRandomDungeonInfo(i)
						if IsLFGDungeonJoinable(id) and diff == 2 and CheckQueueReward(id) then
							if not StaticPopup_Visible("SATCHEL_QUEUE") then
								StaticPopup_Show("SATCHEL_QUEUE", ("\n" .. name), nil, id)
							end
							return
						end
					end
					StaticPopup_Hide("SATCHEL_QUEUE")
				elseif mode == "lfgparty" then
					SatchelQueue.queuedTime = nil -- nil out the time to hide the status frame
					if not db.requeue then
						SatchelQueue:Stop()
					end
				end

			elseif mode == "lfgparty" then
				-- queued for something else and are in that
				SatchelQueue:Stop()

			end
		end --for
	end --func
end --do


-- Options
local function GetOptions()
	local sounds = media and media:List("sound") or { "SatchelQueue Alert" }
	local options = {
		name = "SatchelQueue",
		type = "group",
		set = function(info, val) db[info[#info]] = val end,
		get = function(info) return db[info[#info]] end,
		args = {
			icon = {
				type = "toggle",
				name = "Enable status icon",
				desc = "Show the LFG icon while waiting for a queue.",
				width = "full",
				order = 1,
			},
			requeue = {
				type = "toggle",
				name = "Requeue",
				desc = "Automatically start looking for a satchel queue after completing a dungeon.",
				width = "full",
				order = 2,
			},
			flash_enable = {
				type = "toggle",
				name = "Screen flash",
				desc = "Show a fullscreen flash on a queue alert.",
				width = "full",
				order = 3,
			},
			sound_enable = {
				type = "toggle",
				name = "Extra sound",
				desc = "Play a sound file on a queue alert.",
				width = "full",
				order = 4,
			},
			sound_force = {
				type = "toggle",
				name = "Force sound",
				desc = "Unmute and enable sound in background and increase the volume to 100% when the queue alert sound plays.",
				width = "full",
				order = 5,
			},
			sound_file = {
				type = "select",
				name = "Sound",
				desc = "Sound to play with the queue alert.",
				itemControl = media and "DDI-Sound",
				values = sounds,
				get = function()
					for i, v in next, sounds do
						if v == db.sound_file then return i end
					end
				end,
				set = function(_, value)
					db.sound_file = sounds[value]
				end,
				disabled = function() return not db.sound_enable end,
				order = 6,
			},
		},
	}
	return options
end


-- Addon

function SatchelQueue:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("SatchelQueueDB", defaults)
	db = self.db.profile

	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("SatchelQueue", GetOptions)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SatchelQueue", "SatchelQueue")

	SlashCmdList.SATCHELQUEUE = function(input)
		InterfaceOptionsFrame_OpenToCategory("SatchelQueue")
		InterfaceOptionsFrame_OpenToCategory("SatchelQueue")
	end
	SLASH_SATCHELQUEUE1 = "/satchel"
	SLASH_SATCHELQUEUE2 = "/satchelqueue"
end

function SatchelQueue:OnEnable()
	SatchelQueueButton:Show()
end

function SatchelQueue:OnDisable()
	self:Stop()
	SatchelQueueButton:Hide()
end
