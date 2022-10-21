TransmogSlotOrder = {
	INVSLOT_HEAD,
	INVSLOT_SHOULDER,
	INVSLOT_BACK,
	INVSLOT_CHEST,
	INVSLOT_BODY,
	INVSLOT_TABARD,
	INVSLOT_WRIST,
	INVSLOT_HAND,
	INVSLOT_WAIST,
	INVSLOT_LEGS,
	INVSLOT_FEET,
	INVSLOT_MAINHAND,
	INVSLOT_OFFHAND,
	INVSLOT_RANGED,
};

TransmogUtil = TransmogUtil or { };

-- populated when TRANSMOG_SLOTS transmoglocations are created
local slotIDToName = { };
for _, info in ipairs(TRANSMOG_SLOTS) do
	local slotID = GetInventorySlotInfo(info.slot);
	slotIDToName[slotID] = info.slot;
end

function TransmogUtil.GetSlotID(slotName)
	local slotID = GetInventorySlotInfo(slotName);
	slotIDToName[slotID] = slotName;
	return slotID;
end

function TransmogUtil.GetSlotName(slotID)
	return slotIDToName[slotID];
end

local NUM_OUTFIT_SLASH_COMMAND_VALUES = 16;

-- Outfit slash command sample:
-- /outfit ev1 7019,7017,0,0,7022,0,0,7015,7020,7016,7018,7021,70216,0,0,0,0
-- "ev1" is the ezCollections version so future formats won't break older slash commands
-- The comma-separated values are as follows:
-- 		Head		- appearanceID
--		Shoulder	- appearanceID
-- 		Back		- appearanceID
--		Chest		- appearanceID
--		Body		- appearanceID
--		Tabard		- appearanceID
--		Wrist		- appearanceID
--		Hand		- appearanceID
--		Waist		- appearanceID
--		Legs		- appearanceID
--		Feet		- appearanceID
--		MainHand	- appearanceID
--		MainHand	- illusionID
--		OffHand		- appearanceID
--		OffHand		- illusionID
--		Ranged		- appearanceID

function TransmogUtil.CreateOutfitSlashCommand(sources, mainHandEnchant, offHandEnchant)
	local slashCommand = "/outfit ve1 ";
	for index, slotID in ipairs(TransmogSlotOrder) do
		local source = sources[slotID] or 0;
		if source then
			if index == 1 then
				slashCommand = slashCommand..source;
			else
				slashCommand = slashCommand..","..source;
			end
			-- illusions
			if slotID == INVSLOT_MAINHAND then
				slashCommand = slashCommand..","..(mainHandEnchant or 0);
			end
			if slotID == INVSLOT_OFFHAND then
				slashCommand = slashCommand..","..(offHandEnchant or 0);
			end
		end
	end
	return slashCommand;
end

function TransmogUtil.ParseOutfitSlashCommand(msg)
	-- check version #
	if string.sub(msg, 1, 4) == "ve1 " then
		local readlist = { strsplit(",", string.sub(msg, 4)) };
		if #readlist ~= NUM_OUTFIT_SLASH_COMMAND_VALUES then
			DEFAULT_CHAT_FRAME:AddMessage(TRANSMOG_OUTFIT_LINK_INVALID, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
			return;
		end

		-- accessor for next value
		local readIndex = 0;
		local function GetNextReadValue()
			readIndex = readIndex + 1;
			return tonumber(readlist[readIndex]) or 0;
		end

		-- set the values
		local sources = { };
		local mainHandEnchant = nil;
		local offHandEnchant = nil;
		for _, slotID in ipairs(TransmogSlotOrder) do
			sources[slotID] = GetNextReadValue();
			sources[slotID] = sources[slotID] ~= 0 and sources[slotID] or nil;
			-- illusions
			if slotID == INVSLOT_MAINHAND then
				mainHandEnchant = GetNextReadValue();
				mainHandEnchant = mainHandEnchant ~= 0 and mainHandEnchant or nil;
			end
			if slotID == INVSLOT_OFFHAND then
				offHandEnchant = GetNextReadValue();
				offHandEnchant = offHandEnchant ~= 0 and offHandEnchant or nil;
			end
		end
		return sources, mainHandEnchant, offHandEnchant;
	end
	DEFAULT_CHAT_FRAME:AddMessage(TRANSMOG_OUTFIT_LINK_INVALID, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
	return nil;
end
