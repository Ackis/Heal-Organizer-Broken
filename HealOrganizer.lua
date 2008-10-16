local L = AceLibrary("AceLocale-2.2"):new("HealOrganizer")

local options = {
	type = 'group',
	args = {
		dialog = {
			type = 'execute',
			name = 'Show/Hide Dialog',
			desc = L["SHOW_DIALOG"],
			func = function() HealOrganizer:Dialog() end,
		},
		raid = {
			type = 'execute',
			name = 'Broadcast Raid',
			desc = L["BROADCAST_RAID"],
			func = function() HealOrganizer:BroadcastRaid() end,
		},
		chan = {
			type = 'execute',
			name = 'Broadcast Channel',
			desc = L["BROADCAST_CHAN"],
			func = function() HealOrganizer:BroadcastChan() end,
		},
		autosort = {
			type = 'toggle',
			name = 'Autosort',
			desc = L["AUTOSORT_DESC"],
			get = function() return HealOrganizer.db.char.autosort end,
			set = function() HealOrganizer.db.char.autosort = not HealOrganizer.db.char.autosort end,
		},
	}
}
-- units
-- healer["name"] = "Rest"
-- Werte: Rest, 1, 2, 3, 4, 5, 6, 7, 8, 9
local healer = {
}
-- name2unitid
local unitids = {
}
local position = {
}
local overrideSort = false
local lastAction = {
	name = {},
	position = {},
	group = {},
}

local einteilung = {
	Rest = {},
	[1] = {},
	[2] = {},
	[3] = {},
	[4] = {},
	[5] = {},
	[6] = {},
	[7] = {},
	[8] = {},
	[9] = {},
}
local stats = {
	DRUID = 0,
	PRIEST = 0,
	PALADIN = 0,
	SHAMAN = 0,
}

local current_set = L["SET_DEFAULT"]

local grouplabels = {
	Rest = "GROUP_LOCALE_REMAINS",
	[1] = "GROUP_LOCALE_1",
	[2] = "GROUP_LOCALE_2",
	[3] = "GROUP_LOCALE_3",
	[4] = "GROUP_LOCALE_4",
	[5] = "GROUP_LOCALE_5",
	[6] = "GROUP_LOCALE_6",
	[7] = "GROUP_LOCALE_7",
	[8] = "GROUP_LOCALE_8",
	[9] = "GROUP_LOCALE_9",
}
-- nil, DRUID, PRIEST, PALADIN, SHAMAN
local groupclasses = {
	[1] = {},
	[2] = {},
	[3] = {},
	[4] = {},
	[5] = {},
	[6] = {},
	[7] = {},
	[8] = {},
	[9] = {},
}

local change_id = 0

-- button level speichern
local level_of_button = -1;

-- saves the healer-setup of other templates
--[[
-- tempsetup[setname] = healer-array
--]]
local tempsetup = {}

-- key bindings
BINDING_HEADER_HEALORGANIZER = "Heal Organizer"
BINDING_NAME_SHOWHEALORGANIZER = L["SHOW_DIALOG"]

HealOrganizer = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceDB-2.0", "AceEvent-2.0")
HealOrganizer:RegisterChatCommand( "/healorganizer", "/hlorg", "/ho", options)
HealOrganizer:RegisterDB("HealOrganizerDB", "HealOrganizerDBPerChar")
HealOrganizer:RegisterDefaults('char', {
	chan = "",
	autosort = true,
})
--[[
self.db.account.sets = {
	"Name" = {
		Name = "Name",
		Beschriftungen = {
			Rest = "Rest",
			[1] = "%MT1%",
			...
			[8] = "%MT8%",
			[9] = "Dispellen",
		},
		Restaktion = "ffa",
		Klassengruppen = {
			[1] = {
				[1] = "PALADIN",
				[2] = "PALADIN",
				[3] = "PRIEST",
			},
			[2] = {},
			...
			[9] = {
				[2] = "DRUID",
			},
		},		
	},
	"Name3" = {
		...
	},
}
--]]
HealOrganizer:RegisterDefaults('account', {
	sets = {
		[L["SET_DEFAULT"]] = {
			Name = L["SET_DEFAULT"],
			Beschriftungen = {
				[1] = "%MT1%",
				[2] = "%MT2%",
				[3] = "%MT3%",
				[4] = "%MT4%",
				[5] = "%MT5%",
				[6] = "%MT6%",
				[7] = "%MT7%",
				[8] = "%MT8%",
				[9] = L["DISPEL"],
			},
			Restaktion = "ffa",
			Klassengruppen = {
				[1] = {},
				[2] = {},
				[3] = {},
				[4] = {},
				[5] = {},
				[6] = {},
				[7] = {},
				[8] = {},
				[9] = {},
			}
		},
	}
})

HealOrganizer.CONST = {}
HealOrganizer.CONST.NUM_GROUPS = 9
HealOrganizer.CONST.NUM_SLOTS = 4

function HealOrganizer:OnInitialize() -- {{{
	-- Called when the addon is loaded
	self:RegisterEvent("CHAT_MSG_WHISPER")
	StaticPopupDialogs["HEALORGANIZER_EDITLABEL"] = { --{{{
		text = L["EDIT_LABEL"],
		button1 = TEXT(SAVE),
		button2 = TEXT(CANCEL),
		OnAccept = function(a,b,c)
			-- button gedrueckt, auf GetName/GetParent achten
			self:SaveNewLabel(change_id, getglobal(this:GetParent():GetName().."EditBox"):GetText())
		end,
		OnHide = function()
			getglobal(this:GetName().."EditBox"):SetText("")
		end,
		OnShow = function()
			if grouplabels[change_id] ~= nil then
				getglobal(this:GetName().."EditBox"):SetText(grouplabels[change_id])
			end
		end,
	EditBoxOnEnterPressed = function()
			self:SaveNewLabel(change_id, this:GetText())
			this:GetParent():Hide()
		end,
		EditBoxOnEscapePressed = function()
			this:GetParent():Hide();
		end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
		hasEditBox = 1,
	}; --}}}
	StaticPopupDialogs["HEALORGANIZER_SETSAVEAS"] = { --{{{
		text = L["SET_SAVEAS"],
		button1 = TEXT(SAVE),
		button2 = TEXT(CANCEL),
		OnAccept = function()
			-- button gedrueckt, auf GetName/GetParent achten
			self:SetSaveAs(getglobal(this:GetParent():GetName().."EditBox"):GetText())
		end,
		OnHide = function()
			getglobal(this:GetName().."EditBox"):SetText("")
		end,
		OnShow = function()
		end,
	EditBoxOnEnterPressed = function()
			self:SetSaveAs(getglobal(this:GetParent():GetName().."EditBox"):GetText())
			this:GetParent():Hide()
		end,
		EditBoxOnEscapePressed = function()
			this:GetParent():Hide();
		end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
		hasEditBox = 1,
	}; --}}}
	current_set = L["SET_DEFAULT"]

	-- dialog labels aus locale einstellen {{{

	HealOrganizerDialogEinteilungTitle:SetText(L["ARRANGEMENT"])
	--
	--HealOrganizerDialogEinteilungHealerpoolLabel:SetText(L["REMAINS"])
	for i=1, 20 do
		getglobal("HealOrganizerDialogEinteilungHealerpoolSlot"..i.."Label"):SetText(L["FREE"])
	end
	HealOrganizerDialogEinteilungOptionenTitle:SetText(L["OPTIONS"])
	HealOrganizerDialogEinteilungOptionenAutofill:SetText(L["AUTOFILL"])
	HealOrganizerDialogEinteilungStatsTitle:SetText(L["STATS"])
	HealOrganizerDialogEinteilungStatsPriests:SetText(L["PRIESTS"]..": "..5)
	HealOrganizerDialogEinteilungStatsPriests:SetTextColor(RAID_CLASS_COLORS["PRIEST"].r,
														   RAID_CLASS_COLORS["PRIEST"].g,
														   RAID_CLASS_COLORS["PRIEST"].b)
	HealOrganizerDialogEinteilungStatsDruids:SetText(L["DRUIDS"]..": "..6)
	HealOrganizerDialogEinteilungStatsDruids:SetTextColor(RAID_CLASS_COLORS["DRUID"].r,
														  RAID_CLASS_COLORS["DRUID"].g,
														  RAID_CLASS_COLORS["DRUID"].b)
	HealOrganizerDialogEinteilungStatsPaladin:SetText(L["PALADINS"]..": "..5)
	HealOrganizerDialogEinteilungStatsPaladin:SetTextColor(RAID_CLASS_COLORS["PALADIN"].r,
														  RAID_CLASS_COLORS["PALADIN"].g,
														  RAID_CLASS_COLORS["PALADIN"].b)
	HealOrganizerDialogEinteilungStatsShaman:SetText(L["SHAMANS"]..": "..5)
	HealOrganizerDialogEinteilungStatsShaman:SetTextColor(RAID_CLASS_COLORS["SHAMAN"].r,
														  RAID_CLASS_COLORS["SHAMAN"].g,
														  RAID_CLASS_COLORS["SHAMAN"].b)
	HealOrganizerDialogEinteilungRest:SetText(L["REMAINS"])
	HealOrganizerDialogEinteilungSetsTitle:SetText(L["LABELS"])
	HealOrganizerDialogEinteilungSetsSave:SetText(TEXT(SAVE))
	HealOrganizerDialogEinteilungSetsSaveAs:SetText(L["SAVEAS"])
	HealOrganizerDialogEinteilungSetsDelete:SetText(TEXT(DELETE))
	HealOrganizerDialogBroadcastTitle:SetText(L["BROADCAST"])
	HealOrganizerDialogBroadcastChannel:SetText(L["CHANNEL"])
	HealOrganizerDialogBroadcastRaid:SetText(L["RAID"])
	HealOrganizerDialogBroadcastWhisperText:SetText(L["WHISPER"]) -- api changed?
	HealOrganizerDialogClose:SetText(L["CLOSE"])
	HealOrganizerDialogReset:SetText(L["RESET"])
	-- }}}
	-- standard fuer dropdown setzen
	UIDropDownMenu_SetSelectedValue(HealOrganizerDialogEinteilungSetsDropDown, L["SET_DEFAULT"], L["SET_DEFAULT"]); 
	self:LoadCurrentLabels()
	self:UpdateDialogValues()
end -- }}}

function HealOrganizer:OnEnable() -- {{{
	-- Called when the addon is enabled
end -- }}}

function HealOrganizer:OnDisable() -- {{{
	-- Called when the addon is disabled
end -- }}}

function HealOrganizer:RefreshTables() --{{{
	stats = {
		DRUID = 0,
		PRIEST = 0,
		PALADIN = 0,
		SHAMAN = 0,
	}
	local gruppen = {
		Rest = 0,
		[1] = 0,
		[2] = 0,
		[3] = 0,
		[4] = 0,
		[5] = 0,
		[6] = 0,
		[7] = 0,
		[8] = 0,
		[9] = 0,
	}
	-- heiler suchen
	for i=1, MAX_RAID_MEMBERS do
		if not UnitExists("raid"..i) then
			-- kein mitglied, also auch kein heiler
		else
			-- pr?? ob er ein heiler ist
			local class,engClass = UnitClass("raid"..i)
			local unitname = UnitName("raid"..i)
			if engClass == "DRUID" or engClass == "PRIEST" or
					engClass == "PALADIN" or engClass == "SHAMAN" then
				-- ist ein heiler, aber schon eingeteilt?
				if healer[unitname] then
					-- schon eingeteilt, nichts machen
					if healer[unitname] ~= "Rest" then
						if gruppen[healer[unitname]] >= self.CONST.NUM_SLOTS then
							-- schon zu viele, mach ihm zum rest
							healer[unitname] = "Rest"
						end
					end
				else
					-- nicht eingeteilt, neu, "rest"
					healer[unitname] = "Rest"
					position[unitname] = 0
				end
				gruppen[healer[unitname]] = gruppen[healer[unitname]] + 1
				stats[engClass] = stats[engClass] + 1				
			else
				-- ist kein heiler, nil
				healer[unitname] = nil
			end
		end
	end
	-- healer[...] -> einteilungsarray
	-- einteilung resetten
	einteilung = {
		Rest = {},
		[1] = {},
		[2] = {},
		[3] = {},
		[4] = {},
		[5] = {},
		[6] = {},
		[7] = {},
		[8] = {},
		[9] = {},
	}
	for name, ort in pairs(healer) do
		table.insert(einteilung[ort], name)	
	end
	-- einteilungstabelle sortieren (Klasse, Name)
	local function SortEinteilung(a, b) --{{{
		if (self.db.char.autosort or overrideSort) then
			--[[
			-- Priester,
			-- Druiden,
			-- Paladine,
			-- Schamanen,
			--	NameA,
			--	NameZ
			--]]
			local unitIDa = self:GetUnitByName(a)
			local unitIDb = self:GetUnitByName(b)
			local classA, engClassA = UnitClass(unitIDa)
			local classB, engClassB = UnitClass(unitIDb)
			if engClassA ~= engClassB then
					-- unterscheidung an der Klasse
					-- ecken abfangen
					if engClassA == "PRIEST" then -- (Priest, *)
							return true
					end
					if engClassB == "PRIEST" then -- (*, Priest)
							return false
					end
					if engClassB == "SHAMAN" then -- (*, Shaman)
							return true
					end
					if engClassA == "SHAMAN" then -- (Shaman, *)
							return false
					end
					-- inneren zwei
					if engClassA == "DRUID" then -- (Druid, *)
							return true
					end
					if engClassB == "DRUID" then -- (*, Druid)
							return false
					end
					if engClassB == "PALADIN" then -- (*, Paladin)
							return true
					end
					if engClassA == "PALADIN" then -- (Paladin, *)
							return false
					end
			else
					-- klassen sind gleich, nach namen sortieren
					return a<b
			end
			return true
	else 
			if (position[a] and position[b]) then
				if position[a] == position[b] and lastAction["position"] then
					if lastAction["position"] == 0 then
						if a == lastAction["name"] then -- Spieler a wurde verschoben
							return true
						elseif b == lastAction["name"] then -- Spieler b wurde verschoben
							return false
						end
						return true
					end
					--Sonderfall - kann nur eintreten wenn ein Spieler AUF einen anderen gezogen wurde - also hier in die Richtung verschieben aus der der alte Spieler kommt
					--lastAction ist die letzte Aktion die ausgefuehrt wurde + Position von der bewegt wurde
					if a == lastAction["name"] then -- Spieler a wurde verschoben
						if lastAction["position"] > position[a] then-- kommt von Unten
							return true
						else
							return false
						end
					elseif b == lastAction["name"] then -- Spieler b wurde verschoben
						if lastAction["position"] > position[b] then-- kommt von Unten
							return false
						else
							return true
						end
					end
				end
				return position[a] < position[b] 
			end
			return true
		end
	end --}}}
	for key, tab in pairs(einteilung) do
		if key == "Rest" then --Nicht zugeordnete Heiler werden immer sortiert
				overrideSort = true
		end
		table.sort(einteilung[key], SortEinteilung)
		--Positionen entsprechend dem Index updaten 
		for index, name in pairs(einteilung[key]) do
				position[name] = index
		end
		overrideSort = false
	end
end -- }}}

function HealOrganizer:Dialog() -- {{{
	-- bei einem leeren raid die heilerzuteilung loeschen
	if GetNumRaidMembers() == 0 then
		self:ResetData()
	end
	self:UpdateDialogValues()
	if HealOrganizerDialog:IsShown() then
		HealOrganizerDialog:Hide()
	else
		HealOrganizerDialog:Show()
	end
end -- }}}

function HealOrganizer:UpdateDialogValues() -- {{{
	self:RefreshTables()
	-- stats aktuallisieren {{{
	HealOrganizerDialogEinteilungStatsPriests:SetText(L["PRIESTS"]..": "..stats["PRIEST"])
	HealOrganizerDialogEinteilungStatsPriests:SetTextColor(RAID_CLASS_COLORS["PRIEST"].r,
														   RAID_CLASS_COLORS["PRIEST"].g,
														   RAID_CLASS_COLORS["PRIEST"].b)
	HealOrganizerDialogEinteilungStatsDruids:SetText(L["DRUIDS"]..": "..stats["DRUID"])
	HealOrganizerDialogEinteilungStatsDruids:SetTextColor(RAID_CLASS_COLORS["DRUID"].r,
														  RAID_CLASS_COLORS["DRUID"].g,
														  RAID_CLASS_COLORS["DRUID"].b)
	HealOrganizerDialogEinteilungStatsPaladin:SetText(L["PALADINS"]..": "..stats["PALADIN"])
	HealOrganizerDialogEinteilungStatsPaladin:SetTextColor(RAID_CLASS_COLORS["PALADIN"].r,
														  RAID_CLASS_COLORS["PALADIN"].g,
														  RAID_CLASS_COLORS["PALADIN"].b)
	HealOrganizerDialogEinteilungStatsShaman:SetText(L["SHAMANS"]..": "..stats["SHAMAN"])
	HealOrganizerDialogEinteilungStatsShaman:SetTextColor(RAID_CLASS_COLORS["SHAMAN"].r,
														  RAID_CLASS_COLORS["SHAMAN"].g,
														  RAID_CLASS_COLORS["SHAMAN"].b)
	-- }}}
	-- slot-lables aktuallisieren {{{
	for j=1, self.CONST.NUM_GROUPS do
		for i=1, self.CONST.NUM_SLOTS do
			local slotlabel = getglobal("HealOrganizerDialogEinteilungHealGroup"..j.."Slot"..i.."Label")
			local slotbutton = getglobal("HealOrganizerDialogEinteilungHealGroup"..j.."Slot"..i.."Color")
			slotlabel:SetText(self:GetLabelByClass(groupclasses[j][i]))
			local color = RAID_CLASS_COLORS[groupclasses[j][i]];
			if color then
				slotbutton:SetTexture(color.r/1.5, color.g/1.5, color.b/1.5, 0.5)
			else
				slotbutton:SetTexture(0.1, 0.1, 0.1) 
			end
		end
	end
	-- }}}
	-- {{{ gruppen-labels aktuallisieren
	HealOrganizerDialogEinteilungHealerpoolLabel:SetText(grouplabels["Rest"])
	for i=1,self.CONST.NUM_GROUPS do
		getglobal("HealOrganizerDialogEinteilungHealGroup"..i.."Label"):SetText(self:ReplaceTokens(grouplabels[i]))
	end
	-- }}}
	-- gruppen-klassen aktuallisieren {{{
	for i=1, self.CONST.NUM_GROUPS do
		for j=1, self.CONST.NUM_GROUPS do
		end
	end
	-- }}}
	HealOrganizerDialogBroadcastChannelEditbox:SetText(self.db.char.chan)
	-- einteilungen aktuallisieren -- {{{
	-- alle buttons verstecken
	for i=1, 20 do
		getglobal("HealOrganizerDialogButton"..i):ClearAllPoints()
		getglobal("HealOrganizerDialogButton"..i):Hide()
	end
	local zaehler = 1
	-- Rest {{{
	for i=1, table.getn(einteilung.Rest) do
		-- max 20 durchl?e
		if zaehler > 20 then
			-- zu viel, abbrechen
			break
		end
		local button = getglobal("HealOrganizerDialogButton"..zaehler)
		local buttonlabel = getglobal(button:GetName().."Label")
		local buttoncolor = getglobal(button:GetName().."Color")
		-- habe den Button an sich, das Label und die Farbe, einstellen
		buttonlabel:SetText(einteilung.Rest[i])
		local class, engClass = UnitClass(self:GetUnitByName(einteilung.Rest[i]))
		local color = RAID_CLASS_COLORS[engClass];
		if color then
			buttoncolor:SetTexture(color.r, color.g, color.b)
		end
		-- ancher und position einstellen
		button:SetPoint("TOP", "HealOrganizerDialogEinteilungHealerpoolSlot"..i)
		button:Show()
		-- username im button speichern
		button.username = einteilung.Rest[i]
		zaehler = zaehler + 1
	end
	-- }}}
	-- MTs {{{
	for j=1, self.CONST.NUM_GROUPS do
		for i=1, table.getn(einteilung[j]) do
			-- max 20 durchl?e
			if zaehler > 20 then
				-- zu viel, abbrechen
				break
			end
			local button = getglobal("HealOrganizerDialogButton"..zaehler)
			local buttonlabel = getglobal(button:GetName().."Label")
			local buttoncolor = getglobal(button:GetName().."Color")
			-- habe den Button an sich, das Label und die Farbe, einstellen
			buttonlabel:SetText(einteilung[j][i])
			local class, engClass = UnitClass(self:GetUnitByName(einteilung[j][i]))
			local color = RAID_CLASS_COLORS[engClass];
			if color then
				buttoncolor:SetTexture(color.r, color.g, color.b)
			end
			-- ancher und position einstellen
			button:SetPoint("TOP", "HealOrganizerDialogEinteilungHealGroup"..j.."Slot"..i)
			button:Show()
			-- username im button speichern
			button.username = einteilung[j][i]
			zaehler = zaehler + 1
		end
	end
	-- }}}
	-- }}}
	-- {{{ Sets aktuallisieren 
	local function HealOrganizer_changeSet(set)
		UIDropDownMenu_SetSelectedValue(HealOrganizerDialogEinteilungSetsDropDown, set, set)
		-- healer temp save
		tempsetup[current_set] = {} -- komplett neu bzw. ueberschreiben
		for name, einteilung in pairs(healer) do
			tempsetup[current_set][name] = einteilung
		end
		current_set = set
		self:LoadCurrentLabels()
		self:UpdateDialogValues()
	end

	local function HealOrganizerDropDown_Initialize() 

		   local selectedValue = UIDropDownMenu_GetSelectedValue(HealOrganizerDialogEinteilungSetsDropDown)  
		   local info



		   local sorted
		   sorted = {}
		   for n in pairs(self.db.account.sets) do table.insert(sorted, n) end 
		   table.sort(sorted) 
		   -- aus DB fuellen
		   for key, value in ipairs(sorted) do
			   info = {}
			   info.text = value
			   info.value = value
			   info.func = HealOrganizer_changeSet
			   info.arg1 = value
			   if ( info.value == selectedValue ) then 
				   info.checked = 1; 
			   end
			   UIDropDownMenu_AddButton(info);
		   end
	end
	-- }}} 
	-- dropdown initialisieren
	UIDropDownMenu_Initialize(HealOrganizerDialogEinteilungSetsDropDown, HealOrganizerDropDown_Initialize); 
	UIDropDownMenu_Refresh(HealOrganizerDialogEinteilungSetsDropDown)
	UIDropDownMenu_SetWidth(150, HealOrganizerDialogEinteilungSetsDropDown); 
end -- }}}

function HealOrganizer:ResetData() -- {{{
	-- einfach alle heiler l??en und neu bauen
	healer = {}
	current_set = L["SET_DEFAULT"]
	self:LoadCurrentLabels()
	groupclasses = {}
	for i=1, self.CONST.NUM_GROUPS do
		groupclasses[i] = {}
	end
	self:UpdateDialogValues()
end -- }}}

function HealOrganizer:BroadcastChan() --{{{
	-- bin ich im chan?
	if GetNumRaidMembers() == 0 then
		self:ErrorMessage(L["NOT_IN_RAID"])
		return;
	end
	local id, name = GetChannelName(self.db.char.chan)
	if id == 0 then
		-- nein, nicht drin
		self:Print(L["NO_CHANNEL"], self.db.char.chan)
		return;
	end
	local messages = self:BuildMessages()
	for _, message in pairs(messages) do
		ChatThrottleLib:SendChatMessage("NORMAL", nil, message, "CHANNEL", nil, id)
	end
	self:SendToHealers()
end -- }}}

function HealOrganizer:BroadcastRaid() -- {{{
	if GetNumRaidMembers() == 0 then
		self:CustomPrint(1, 0.2, 0.2, self.printFrame, nil, " ", L["NOT_IN_RAID"])
		return;
	end
	local messages = self:BuildMessages()
	for _, message in pairs(messages) do
		ChatThrottleLib:SendChatMessage("NORMAL", nil, message, "RAID")
	end
	self:SendToHealers()
end -- }}}

function HealOrganizer:BuildMessages() -- {{{
	local messages = {}
	table.insert(messages, L["HEALARRANGEMENT"]..":")
	-- 1-5, rest
	-- {{{ gruppen
	for i=1, self.CONST.NUM_GROUPS do
		local header = getglobal("HealOrganizerDialogEinteilungHealGroup"..i.."Label"):GetText()
		if getn(einteilung[i]) ~= 0 then
			local names={}
			for _, name in pairs(einteilung[i]) do
				if UnitExists(self:GetUnitByName(name)) then
					table.insert(names, name)
				end
			end
			table.insert(messages, getglobal("HealOrganizerDialogEinteilungHealGroup"..i.."Label"):GetText()..": "..table.concat(names, ", "))
		end
	end
	-- }}}
	-- {{{ Rest
	local action = self:ReplaceTokens(HealOrganizerDialogEinteilungRestAction:GetText())
	if "" == action then
		action = L["FFA"]
	end
	table.insert(messages, L["REMAINS"]..": "..action)
	-- }}}
	table.insert(messages, L["MSG_HEAL_FOR_ARRANGEMENT"])
	return messages
end -- }}}

function HealOrganizer:SendToHealers() -- {{{
	-- {{{ gruppen
	local whisper = HealOrganizerDialogBroadcastWhisper:GetChecked()
	if whisper then
		for i=1, self.CONST.NUM_GROUPS do
			local header = getglobal("HealOrganizerDialogEinteilungHealGroup"..i.."Label"):GetText()
			if getn(einteilung[i]) ~= 0 then
				for _, name in pairs(einteilung[i]) do
					if UnitExists(self:GetUnitByName(name)) then
						ChatThrottleLib:SendChatMessage("NORMAL", nil, string.format(L["ARRANGEMENT_FOR"], header), "WHISPER", nil, name)
					end
				end
			end
		end
	end
	-- }}}
end -- }}}

function HealOrganizer:ChangeChan() -- {{{
	self.db.char.chan = HealOrganizerDialogBroadcastChannelEditbox:GetText()
end -- }}}

function HealOrganizer:HealerOnClick(a) -- {{{

end -- }}}

function HealOrganizer:HealerOnDragStart() -- {{{
	local cursorX, cursorY = GetCursorPosition()
	this:ClearAllPoints();
	--this:SetPoint("CENTER", nil, "BOTTOMLEFT", cursorX*GetScreenWidthScale(), cursorY*GetScreenHeightScale());
	--this:SetPoint("CENTER", nil, "BOTTOMLEFT");
	this:StartMoving()
	level_of_button = this:GetFrameLevel();
	this:SetFrameLevel(this:GetFrameLevel()+30) -- sehr hoch
end -- }}}

function HealOrganizer:HealerOnDragStop() -- {{{
	this:SetFrameLevel(level_of_button)
	this:StopMovingOrSizing()
	-- gucken wo ich bin?
	local pools = {
		"HealOrganizerDialogEinteilungHealerpool",
		"HealOrganizerDialogEinteilungHealGroup1Slot1",
		"HealOrganizerDialogEinteilungHealGroup1Slot2",
		"HealOrganizerDialogEinteilungHealGroup1Slot3",
		"HealOrganizerDialogEinteilungHealGroup1Slot4",
		"HealOrganizerDialogEinteilungHealGroup2Slot1",
		"HealOrganizerDialogEinteilungHealGroup2Slot2",
		"HealOrganizerDialogEinteilungHealGroup2Slot3",
		"HealOrganizerDialogEinteilungHealGroup2Slot4",
		"HealOrganizerDialogEinteilungHealGroup3Slot1",
		"HealOrganizerDialogEinteilungHealGroup3Slot2",
		"HealOrganizerDialogEinteilungHealGroup3Slot3",
		"HealOrganizerDialogEinteilungHealGroup3Slot4",
		"HealOrganizerDialogEinteilungHealGroup4Slot1",
		"HealOrganizerDialogEinteilungHealGroup4Slot2",
		"HealOrganizerDialogEinteilungHealGroup4Slot3",
		"HealOrganizerDialogEinteilungHealGroup4Slot4",
		"HealOrganizerDialogEinteilungHealGroup5Slot1",
		"HealOrganizerDialogEinteilungHealGroup5Slot2",
		"HealOrganizerDialogEinteilungHealGroup5Slot3",
		"HealOrganizerDialogEinteilungHealGroup5Slot4",
		"HealOrganizerDialogEinteilungHealGroup6Slot1",
		"HealOrganizerDialogEinteilungHealGroup6Slot2",
		"HealOrganizerDialogEinteilungHealGroup6Slot3",
		"HealOrganizerDialogEinteilungHealGroup6Slot4",
		"HealOrganizerDialogEinteilungHealGroup7Slot1",
		"HealOrganizerDialogEinteilungHealGroup7Slot2",
		"HealOrganizerDialogEinteilungHealGroup7Slot3",
		"HealOrganizerDialogEinteilungHealGroup7Slot4",
		"HealOrganizerDialogEinteilungHealGroup8Slot1",
		"HealOrganizerDialogEinteilungHealGroup8Slot2",
		"HealOrganizerDialogEinteilungHealGroup8Slot3",
		"HealOrganizerDialogEinteilungHealGroup8Slot4",
		"HealOrganizerDialogEinteilungHealGroup9Slot1",
		"HealOrganizerDialogEinteilungHealGroup9Slot2",
		"HealOrganizerDialogEinteilungHealGroup9Slot3",
		"HealOrganizerDialogEinteilungHealGroup9Slot4",
	}
	for _, pool in pairs(pools) do
		poolframe = getglobal(pool)
		if MouseIsOver(poolframe) then
			local _,_,group,slot = string.find(poolframe:GetName(), "HealOrganizerDialogEinteilungHealGroup(%d+)Slot(%d+)")
			group,slot = tonumber(group),tonumber(slot)
			-- den heiler da zuordnen
			if "HealOrganizerDialogEinteilungHealerpool" == pool then
				healer[this.username] = "Rest"
		position[this.username] = 0
			else
				if group >= 1 and group <= self.CONST.NUM_GROUPS then
						lastAction["group"] = healer[this.username]
						healer[this.username] = group
				end
				if slot >= 1 and slot <= self.CONST.NUM_SLOTS then
						lastAction["name"] = this.username
						--Nur setzen wenn innerhalb einer Gruppe verschoben wird, 0 = Kommt von ausserhalb und wird an der position eingefuegt und Gruppe nach unten verschoben
						if lastAction["group"] == group then
								lastAction["position"] = position[this.username]
						else
								lastAction["position"] = 0
						end
						--neue Position
						position[this.username] = slot
				end
			end
			break
		end
	end
	-- positionen aktuallisieren
	self:UpdateDialogValues()
end -- }}}

function HealOrganizer:HealerOnLoad() -- {{{
	-- 0 = pool, MT1-M5
	-- 1 = slots
	-- 2 = passt ;)
	this:SetFrameLevel(this:GetFrameLevel() + 2)
	this:RegisterForDrag("LeftButton")
end -- }}}

function HealOrganizer:EditGroupLabel(group) -- {{{
	if group:GetID() == 0 then
		return -- Rest nicht bearbeiten
	end
	change_id = group:GetID()
	StaticPopup_Show("HEALORGANIZER_EDITLABEL", group:GetID())	
end -- }}}

function HealOrganizer:SaveNewLabel(id, text) -- {{{
	if id == 0 then
		return
	end
	if text == "" then
		return
	end
	if grouplabels[id] ~= nil then
		grouplabels[id] = text
		self:UpdateDialogValues()
	end
end -- }}}

function HealOrganizer:LoadLabelsFromSet(set) -- {{{
	if not set then
		return nil
	end
	if self.db.account.sets[set] then
		grouplabels.Rest = L["REMAINS"]
		groupclasses = {}
		for i=1, self.CONST.NUM_GROUPS do
			grouplabels[i] = self.db.account.sets[set].Beschriftungen[i]
			groupclasses[i] = {}
			for j=1, self.CONST.NUM_SLOTS do
				groupclasses[i][j] = self.db.account.sets[set].Klassengruppen[i][j]
			end
		end
		HealOrganizerDialogEinteilungRestAction:SetText(self.db.account.sets[set].Restaktion)
		if tempsetup[set] then
			-- laden
			healer = {} -- reset
			for name, einteilung in pairs(tempsetup[set]) do
				if UnitName(self:GetUnitByName(name)) == name then
					healer[name] = einteilung
				end
			end
		end
		return true
	end
	return nil
end -- }}}

function HealOrganizer:LoadCurrentLabels() -- {{{
	if not self:LoadLabelsFromSet(current_set) then
		self:LoadLabelsFromSet(L["SET_DEFAULT"])
	end
end -- }}}

function HealOrganizer:SetSave() -- {{{
	if current_set == L["SET_DEFAULT"] then
		self:ErrorMessage(L["SET_CANNOT_SAVE_DEFAULT"])
		return
	end
	self.db.account.sets[current_set].Beschriftungen = {}
	self.db.account.sets[current_set].Klassengruppen = {}
	for i=1, self.CONST.NUM_GROUPS do
		self.db.account.sets[current_set].Beschriftungen[i] = grouplabels[i]
		self.db.account.sets[current_set].Klassengruppen[i] = {}
		for j=1, self.CONST.NUM_SLOTS do
			self.db.account.sets[current_set].Klassengruppen[i][j] = groupclasses[i][j]
		end
	end
	self.db.account.sets[current_set].Restaktion = HealOrganizerDialogEinteilungRestAction:GetText()
end -- }}}

function HealOrganizer:SetSaveAs(name) -- {{{
	if not name then
		return
	end
	if name == "" then
		return
	end
	if name == L["SET_DEFAULT"] then
		self:ErrorMessage(L["SET_CANNOT_SAVE_DEFAULT"])
		return
	end
	local count = 0
	for a,b in pairs(self.db.account.sets) do
		count = count+1
	end
	if count >= 32 then
		self:ErrorMessage(L["SET_TO_MANY_SETS"])
		return
	end
	if self.db.account.sets[name] then
		self:ErrorMessage(string.format(L["SET_ALREADY_EXISTS"], name))
		return
	end
	-- anlegen
	self.db.account.sets[name] = {}
	self.db.account.sets[name].Name = name
	self.db.account.sets[name].Beschriftungen = {}
	self.db.account.sets[name].Klassengruppen = {}
	for i=1, self.CONST.NUM_GROUPS do
		self.db.account.sets[name].Beschriftungen[i] = grouplabels[i]
		self.db.account.sets[name].Klassengruppen[i] = {}
		for j=1, self.CONST.NUM_SLOTS do
			self.db.account.sets[name].Klassengruppen[i][j] = groupclasses[i][j]
		end
	end
	self.db.account.sets[name].Restaktion = HealOrganizerDialogEinteilungRestAction:GetText()
	current_set = name
	self:LoadCurrentLabels()
	UIDropDownMenu_SetSelectedValue(HealOrganizerDialogEinteilungSetsDropDown, current_set)
	UIDropDownMenu_Refresh(HealOrganizerDialogEinteilungSetsDropDown)
	self:UpdateDialogValues()
end -- }}}

function HealOrganizer:SetDelete() -- {{{
	if current_set == L["SET_DEFAULT"] then
		self:ErrorMessage(L["SET_CANNOT_DELETE_DEFAULT"])
		return
	end
	if not self.db.account.sets[current_set] then
		return
	end
	self.db.account.sets[current_set] = nil
	current_set = L["SET_DEFAULT"]
	UIDropDownMenu_SetSelectedValue(HealOrganizerDialogEinteilungSetsDropDown, current_set)
	self:LoadCurrentLabels()
	self:UpdateDialogValues()
end -- }}}

function HealOrganizer:ErrorMessage(str) -- {{{
	if not str then
		return
	end
	if str == "" then
		return
	end
	self:CustomPrint(1, 0.2, 0.2, self.printFrame, nil, " ", str)
end -- }}}

function HealOrganizer:BuildUnitIDs() -- {{{
	unitids = {}
	for i=1, MAX_RAID_MEMBERS do
		if UnitExists("raid"..i) then
			unitids[UnitName("raid"..i)] = "raid"..i
		end
	end
end -- }}}

function HealOrganizer:GetUnitByName(str) -- {{{
	if not str then
		return nil
	end
	if not unitids[str] then
		self:BuildUnitIDs()
	end
	if not unitids[str] then
		-- alter Name, raid schon laengst verlassen.
		return "raid41"
	end
	if str ~= UnitName(unitids[str]) then
		self:BuildUnitIDs()
	end
	return unitids[str]
end -- }}}

function HealOrganizer:ReplaceTokens(str) -- {{{
	-- {{{MTs ersetzen: %MT1% -> MT1(Name) bzw. MT1
	local function GetMainTankLabel(i) -- {{{
		-- MTi(Name) bzw. MTi
		-- CTRaid
		if not i then
			return ""
		end
		if type(i) ~= "number" then
			return ""
		end
		if i < 1 or i > 10 then
			return ""
		end
		local s = L["MT"]..i
		if CT_RATarget then
			if CT_RATarget.MainTanks[i] and
				UnitExists("raid"..CT_RATarget.MainTanks[i][1]) and
				UnitName("raid"..CT_RATarget.MainTanks[i][1]) == CT_RATarget.MainTanks[i][2]
				then
				-- MTi vorhanden
				s = s.."("..CT_RATarget.MainTanks[i][2]..")"	  
			end
		elseif oRA and oRA.maintanktable then
			if oRA.maintanktable[i] and
				UnitExists(self:GetUnitByName(oRA.maintanktable[i])) and
				UnitName(self:GetUnitByName(oRA.maintanktable[i])) == oRA.maintanktable[i]
				then
				s = s.."("..oRA.maintanktable[i]..")"
			end
		end
		return s
	end -- }}}
	for i=1,10 do
		str = string.gsub(str, "%%MT"..i.."%%", GetMainTankLabel(i))
	end
	-- }}}
	return str
end -- }}}

function HealOrganizer:CHAT_MSG_WHISPER(msg, user) -- {{{
	if GetNumRaidMembers() == 0 then
		-- bin nicht im raid, also auch keine zuteilung
		return
	end
	if msg == "heal" then
		local reply = L["REPLY_NO_ARRANGEMENT"]
		if healer[user] then
			-- labels holen
			local text = grouplabels[healer[user]]
			if text == L["REMAINS"] then
				text = HealOrganizerDialogEinteilungRestAction:GetText()
				if text == "" then
					text = L["FFA"]
				end
			end
			reply = string.format(L["REPLY_ARRANGEMENT_FOR"], self:ReplaceTokens(text))
		end
		ChatThrottleLib:SendChatMessage("NORMAL", nil, reply, "WHISPER", nil, user)
	end
end -- }}}

function HealOrganizer:OnMouseWheel(richtung) -- {{{
	if not this then
		return
	end
	local _,_,group,slot = string.find(this:GetName(), "HealOrganizerDialogEinteilungHealGroup(%d+)Slot(%d+)")
	group,slot = tonumber(group),tonumber(slot)
	if not group or not slot then
		return
	end
	if group < 1 or group > self.CONST.NUM_GROUPS or
		slot < 1 or slot > self.CONST.NUM_SLOTS then
		return
	end
	local classdirection
	local faction = UnitFactionGroup("player")
	if faction == "Alliance" then
		classdirection = {"EMPTY", "PRIEST", "DRUID", "PALADIN"}
	else
		classdirection = {"EMPTY", "PRIEST", "DRUID", "SHAMAN"}
	end
	-- position im array suchen
	local pos = 1
	while (pos <= 4) do
		-- nil abfangen
		if groupclasses[group][slot] then
			if classdirection[pos] == groupclasses[group][slot] then
				break
			end
			-- naechster durchlauf
		else
			-- ist 1/nil/EMPTY
			break
		end
		pos = pos + 1
	end
	-- habe die position
	-- modulo, % klappte bei mir local nicht o_O
	pos = pos - richtung -- nach unten: PRIEST -> DRUID -> PALADIN -> nil -> PRIEST
	if 0 == pos then
		pos = 4
	end
	if 5 == pos then
		pos = 1
	end
	if "EMPTY" == classdirection[pos] then
		groupclasses[group][slot] = nil
	else
		groupclasses[group][slot] = classdirection[pos]
	end
	self:UpdateDialogValues()
end -- }}}

function HealOrganizer:GetLabelByClass(class) -- {{{
	if not class then
		return L["FREE"]
	end
	if "DRUID" ~= class and
	   "PRIEST" ~= class and
	   "PALADIN" ~= class and
	   "SHAMAN" ~= class then
	   return L["FREE"]
	end
	return L[class]
end -- }}}

function HealOrganizer:AutoFill() -- {{{
	for group=1, self.CONST.NUM_GROUPS do
		for slot=1, self.CONST.NUM_SLOTS do
			-- gucken ob was auf den slot soll
			if groupclasses[group][slot] then
				-- gucken ob schon was drauf ist
				if not einteilung[group][slot] then
					-- ist platz, also draufpacken
					-- Rest durchlaufen
					for _, name in pairs(einteilung.Rest) do
						-- klasse abfragen
						local class, engClass = UnitClass(self:GetUnitByName(name))
						if engClass == groupclasses[group][slot] then
							-- der spieler passt, einteilen
							healer[name] = group
							-- neu aufbauen (impliziert refresh-tables)
							self:UpdateDialogValues()
							break; -- naechster durchlauf
						else
							-- der spieler passt nicht, naechster
						end
					end
				end
			end
		end
	end
end -- }}}