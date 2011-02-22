﻿--[[
************************************************************************
devel-enUS.lua
These are localization strings used for the testing of Heal Organizer.
Manually add entries here and then proceed to update the localization
application located here:
	http://www.wowace.com/addons/heal-organizer/localization/
************************************************************************
File date: @file-date-iso@ 
File revision: @file-revision@ 
Project revision: @project-revision@
Project version: @project-version@
************************************************************************
Translation credits: http://www.wowace.com/addons/heal-organizer/localization/translators/

Please update http://www.wowace.com/addons/heal-organizer/localization/enUS/ for any translation
additions or changes.

The translations will be auto-generated by the localization application.
************************************************************************
Please see http://www.wowace.com/addons/heal-organizer/ for more information.
************************************************************************
These translations are released under the Public Domain.
************************************************************************
]]--

local MODNAME	= "HealOrganizer"

local L = LibStub("AceLocale-3.0"):NewLocale(MODNAME, "enUS", true)

if not L then return end 

L["ARRANGEMENT"] = "Arrangement"
L["ARRANGEMENT_FOR"] = "Your arrangement: %s"
L["AUTOFILL"] = "Autofill"
L["AUTOFILL_LOCALE"] = "Autofill"
L["AUTOSORT_DESC"] = "Autosort for groups"
L["BROADCAST"] = "Broadcast"
L["BROADCAST_CHAN"] = "Broadcast assignments to the channel."
L["BROADCAST_RAID"] = "Broadcast assignments to the raid."
L["CHANNEL"] = "Channel"
L["CLOSE"] = "Close"
L["DECURSE"] = "Decurse"
L["DISPEL"] = "Dispel"
L["DRUID"] = "Druid"
L["DRUIDS"] = "Druids"
L["EDIT_LABEL"] = "New label for group %u"
L["FFA"] = "ffa"
L["FREE"] = "Empty"
L["HEAL"] = "Heal"
L["HEALARRANGEMENT"] = "Healing arrangement"
L["LABELS"] = "Labels"
L["MSG_HEAL_FOR_ARRANGEMENT"] = "Whisper 'heal' for your assignment."
L["MT"] = "MT"
L["NOT_IN_RAID"] = "You are not in a raid"
L["NO_CHANNEL"] = "You must join channel %q before broadcasting the healing arrangement to it"
L["OPTIONS"] = "Options"
L["PALADIN"] = "Paladin"
L["PALADINS"] = "Paladins"
L["PRIEST"] = "Priest"
L["PRIESTS"] = "Priests"
L["RAID"] = "Raid"
L["REMAINS"] = "Remaining"
L["REPLY_ARRANGEMENT_FOR"] = "You are assigned to %s."
L["REPLY_NO_ARRANGEMENT"] = "You weren't assigned."
L["RESET"] = "Reset"
L["SAVEAS"] = "Save as"
L["SET_ALREADY_EXISTS"] = "The set %q already exists"
L["SET_CANNOT_DELETE_DEFAULT"] = "You cannot delete the default set"
L["SET_CANNOT_SAVE_DEFAULT"] = "You cannot overwrite the default set"
L["SET_DEFAULT"] = "Default"
L["SET_SAVEAS"] = "Enter a name for the new set"
L["SET_TO_MANY_SETS"] = "You cannot have more than 32 sets"
L["SHAMAN"] = "Shaman"
L["SHAMANS"] = "Shamans"
L["SHOW_DIALOG"] = "Show/Hide the dialog"
L["STATS"] = "Statistics"
L["WHISPER"] = "Whisper healers their assignment."