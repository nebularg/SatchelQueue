std = "lua51"
max_line_length = false
codes = true
exclude_files = {
	".luacheckrc",
	"**/Libs",
}
ignore = {
	"LibStub",
	"SLASH_SATCHELQUEUE1", "SLASH_SATCHELQUEUE2", "SLASH_SATCHELQUEUE3","SLASH_SATCHELQUEUE4",
	"SlashCmdList", "StaticPopupDialogs",
	"UIParent", "EquipmentFlyoutFrame", "AuctionFrame", "QueueStatusFrame", "MailFrame", "GameTooltip", "QueueStatusButton",
	"LFDQueueFrameRoleButtonDPS", "LFDQueueFrameRoleButtonHealer", "LFDQueueFrameRoleButtonTank",
	"UIDropDownMenu_CreateInfo", "UIDropDownMenu_AddButton", "InterfaceOptionsFrame_OpenToCategory",
	"LFDQueueFrame_GetRoles", "StaticPopup_Show", "StaticPopup_Hide", "StaticPopup_Visible",
	"C_PetBattles", "C_Timer", "SetLFGDungeon", "JoinLFG", "GetCVarBool", "GetCVar", "SetCVar"
	"NUM_LE_LFG_CATEGORYS", "MAX_WORLD_PVP_QUEUES", "LFG_SUBTYPEID_RAID", "LE_LFG_CATEGORY_LFD", "NUM_BAG_SLOTS", "STATICPOPUP_NUMDIALOGS",
	"LOOT_SLOT_MONEY", "LFD_NUM_ROLES",
	"LESS_THAN_ONE_MINUTE", "LEAVE_QUEUE", "SETTINGS", "LFD_STATISTIC_CHANGE_TIME", "LFG_ROLE_SHORTAGE_RARE", "LFG_CALL_TO_ARMS",
	"ACCEPT", "DECLINE",
}
