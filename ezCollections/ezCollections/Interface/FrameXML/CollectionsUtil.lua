CollectionWardrobeUtil = CollectionWardrobeUtil or {};

local NO_TRANSMOG_SOURCE_ID = 0;

function CollectionWardrobeUtil.GetDefaultSourceIndex(sources, primarySourceID)
	local collectedSourceIndex;
	local unusableSourceIndex;
	local uncollectedSourceIndex;
	-- default sourceIndex is, in order of preference:
	-- 1. primarySourceID, if collected and usable
	-- 2. collected and usable
	-- 3. unusable primarySourceID
	-- 4. unusable
	-- 5. uncollected primarySourceID
	-- 6. uncollected
	for i, sourceInfo in ipairs(sources) do
		if ( sourceInfo.isCollected ) then
			if sourceInfo.useError then
				if not unusableSourceIndex or primarySourceID == sourceInfo.sourceID then
					unusableSourceIndex = i;
				end
			else
				if primarySourceID == sourceInfo.sourceID then
					-- found #1
					collectedSourceIndex = i;
					break;
				elseif not collectedSourceIndex then
					collectedSourceIndex = i;
					if primarySourceID == NO_TRANSMOG_SOURCE_ID then
						-- done
						break;
					end
				end
			end
		else
			if not uncollectedSourceIndex or primarySourceID == sourceInfo.sourceID then
				uncollectedSourceIndex = i;
			end
		end
	end
	return collectedSourceIndex or unusableSourceIndex or uncollectedSourceIndex or 1;
end

function CollectionWardrobeUtil.SortSources(sources, primaryVisualID, primarySourceID)
	local comparison = function(source1, source2)
		-- if a primary visual is given, sources for that are grouped by themselves above all others
		if ( primaryVisualID and source1.visualID ~= source2.visualID ) then
			return source1.visualID == primaryVisualID;
		end

		if source1.isCollected ~= source2.isCollected then
			return source1.isCollected;
		end

		if primarySourceID then
			local source1IsPrimary = (source1.sourceID == primarySourceID);
			local source2IsPrimary = (source2.sourceID == primarySourceID);
			if source1IsPrimary ~= source2IsPrimary then
				return source1IsPrimary;
			end
		end

		if source1.quality and source2.quality then
			if source1.quality ~= source2.quality then
				return source1.quality > source2.quality;
			end
		else
			return source1.quality;
		end

		return source1.sourceID > source2.sourceID;
	end
	table.sort(sources, comparison);
	return sources;
end

function CollectionWardrobeUtil.GetSortedAppearanceSources(visualID, category)
	local sources = C_TransmogCollection.GetAppearanceSources(visualID, category);
	return CollectionWardrobeUtil.SortSources(sources);
end

function CollectionWardrobeUtil.GetSlotFromCategoryID(categoryID)
	local slot;
	for key, transmogSlot in pairs(TRANSMOG_SLOTS) do
		if categoryID == transmogSlot.armorCategoryID then
			slot = transmogSlot.slot;
			break;
		end
	end
	if not slot then
		local name, isWeapon, canEnchant, canMainHand, canOffHand, canRanged = C_TransmogCollection.GetCategoryInfo(categoryID);
		if canMainHand then
			slot = "MAINHANDSLOT";
		elseif canOffHand then
			slot = "SECONDARYHANDSLOT";
		elseif canRanged then
			slot = "RANGEDSLOT";
		end
	end
	return slot;
end

function CollectionWardrobeUtil.GetValidIndexForNumSources(index, numSources)
	index = index - 1;
	if index < 0 then
		index = numSources + index;
	end
	return mod(index, numSources) + 1;
end

function CollectionWardrobeUtil.GetAppearanceNameTextAndColor(appearanceInfo, inLegionArtifactCategory)
	local text, color;
	if C_TransmogCollection.IsAppearanceHiddenVisual(appearanceInfo.sourceID) then
		text = appearanceInfo.name;
		color = NORMAL_FONT_COLOR;
	elseif appearanceInfo.name then
		text = appearanceInfo.name;
		color = ITEM_QUALITY_COLORS[appearanceInfo.quality];
		if not color then
			local r, g, b = GetItemQualityColor(appearanceInfo.quality);
			color = { r = r, g = g, b = b };
		end
	else
		ezCollections:QueryItem(appearanceInfo.sourceID);
		text = RETRIEVING_ITEM_INFO;
		color = RED_FONT_COLOR;
	end
	if inLegionArtifactCategory then
		local artifactName = C_TransmogCollection.GetArtifactAppearanceStrings(appearanceInfo.sourceID);
		if artifactName then
			text = artifactName;
		end
	end
	return text, color;
end

function CollectionWardrobeUtil.GetAppearanceSourceTextAndColor(appearanceInfo, forceForCollected)
	local text, color;
	if appearanceInfo.isCollected and not forceForCollected then
		text = ezCollections.L["Tooltip.Transmog.Collected"]; -- TRANSMOG_COLLECTED
		color = GREEN_FONT_COLOR;
	else
		--[[
		if appearanceInfo.sourceType then
			text = _G["TRANSMOG_SOURCE_"..appearanceInfo.sourceType];
		elseif not appearanceInfo.name then
			text = "";
		end
		]]
		text = appearanceInfo.sourceText or _G["TRANSMOG_SOURCE_"..appearanceInfo.sourceType];
		color = HIGHLIGHT_FONT_COLOR;
	end
	return text, color;
end

function CollectionWardrobeUtil.IsAppearanceUsable(appearanceInfo, inLegionArtifactCategory)
	if not appearanceInfo.useErrorType then
		return true;
	end
	--[[
	if appearanceInfo.useErrorType == Enum.TransmogUseErrorType.ArtifactSpec then
		-- artifact appearances don't need to match spec when in normal weapon categories
		return not inLegionArtifactCategory;
	end
	]]
	return false;
end

local SHOW_PLURAL_SETS_HEADER = true;
function CollectionWardrobeUtil.AddSourceSetsToTooltip(tooltip, sourceID)
	local info = ezCollections:GetSkinInfo(sourceID);
	local tooltipSourceSlot = info and info.InventoryType and C_Transmog.GetSlotForInventoryType(info.InventoryType);
	local tooltipSourceSlotCollected = ezCollections:HasAvailableSkin(sourceID);
	if info and info.Sets then
		local color = ezCollections.Config.TooltipSets.Color;
		if ezCollections.Config.TooltipSets.Separator then tooltip:AddLine(" "); end

		if #info.Sets > 1 and SHOW_PLURAL_SETS_HEADER then
			tooltip:AddLine(format(ezCollections.L["Tooltip.Sets.Header.Plural"], #info.Sets), color.r * 0.75, color.g * 0.75, color.b * 0.75, false);
		end

		for _, setID in ipairs(info.Sets) do
			local set = ezCollections.Cache.Sets[setID];

			local slotCollectedFromAnotherSource = false;
			local collectedSlots = 0;
			local totalSlots = 0;
			for source, collected in pairs(C_TransmogSets.GetSetSources(set.setID, true)) do
				totalSlots = totalSlots + 1;
				if collected then
					collectedSlots = collectedSlots + 1;
				end
				if not tooltipSourceSlotCollected and collected then
					local info = ezCollections:GetSkinInfo(source);
					local slot = info and info.InventoryType and C_Transmog.GetSlotForInventoryType(info.InventoryType);
					if slot and slot == tooltipSourceSlot then
						slotCollectedFromAnotherSource = true;
					end
				end
			end

			local state, icon, iconTexture, iconHeight;
			if ezCollections.Config.TooltipSets.SlotStateStyle > 1 then
				if slotCollectedFromAnotherSource then
					state = "KnownFromAnotherSource";
					iconTexture = [[Interface\AddOns\ezCollections\Textures\TooltipIcons\KNOWN_circle]];
				elseif tooltipSourceSlotCollected then
					state = "Known";
					iconTexture = [[Interface\AddOns\ezCollections\Textures\TooltipIcons\KNOWN]];
				else
					state = "Unknown";
					iconTexture = [[Interface\AddOns\ezCollections\Textures\TooltipIcons\UNKNOWN]];
				end

				local line = _G[tooltip:GetName().."TextLeft"..tooltip:NumLines()];
				local oldText = line:GetText();
				line:SetText([[|TInterface\AddOns\ezCollections\Interface\Common\spacer:100:1|t]]);
				local textureSizeMultiplier = 100 / line:GetStringHeight();
				line:SetText(" ");
				iconHeight = line:GetStringHeight() * textureSizeMultiplier;
				line:SetText(oldText);
				if ezCollections.Config.TooltipSets.SlotStateStyle == 2 then
					iconHeight = math.floor(iconHeight);
					icon = format("  |T%s:%g|t", iconTexture, iconHeight);
				end
			end

			totalSlots = math.max(totalSlots, 1);
			local progressColor = WardrobeCollectionFrame.progressBar.progress_colors[collectedSlots/totalSlots];
			tooltip:AddDoubleLine(
				format(ezCollections.L[(#info.Sets == 1 or not SHOW_PLURAL_SETS_HEADER) and "Tooltip.Sets.Header.Singular" or "Tooltip.Sets.Set"],
					format("|cFF%s%s|r",
						ezCollections.RGBPercToHex(color.r, color.g, color.b),
						set.name),
					set.description and format(" - %s", set.description) or ""),
				format("|c%s%d/%d|r%s",
					progressColor,
					collectedSlots,
					totalSlots,
					icon or ""),
				color.r * 0.75, color.g * 0.75, color.b * 0.75,
				GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b, false);

			if ezCollections.Config.TooltipSets.SlotStateStyle == 3 or (ezCollections.Config.TooltipSets.SlotStateStyle == 4 and slotCollectedFromAnotherSource) then
				tooltip:AddDoubleLine(" ", format("|T%s:%g|t %s", iconTexture, iconHeight, ezCollections.L["TooltipSets.SlotState."..state]));
			end
		end
		return true;
	end
end

function CollectionWardrobeUtil.GetAppearanceSourceTextWithDrops(appearanceInfo, sourceText)
	local sourceLocation, sourceDifficulties;

	local appearanceCollected = appearanceInfo.isCollected and not ezCollections.Config.Wardrobe.ShowCollectedVisualSourceText;
	local otherSourceText = sourceText;
	if ( appearanceInfo.sourceType == TRANSMOG_SOURCE_BOSS_DROP and not appearanceCollected ) then
		local drops = appearanceInfo.sourceType == TRANSMOG_SOURCE_BOSS_DROP and C_TransmogCollection.GetAppearanceSourceDrops(appearanceInfo.sourceID);
		if ( drops and #drops > 0 ) then
			local showDifficulty = false;
			if ( #drops == 1 ) then
				sourceLocation = WARDROBE_TOOLTIP_ENCOUNTER_SOURCE:format(drops[1].encounter, drops[1].instance);
				showDifficulty = true;
			else
				-- check if the drops are the same instance
				local sameInstance = true;
				local firstInstance = drops[1].instance;
				for i = 2, #drops do
					if ( drops[i].instance ~= firstInstance ) then
						sameInstance = false;
						break;
					end
				end
				-- ok, if multiple instances check if it's the same tier if the drops have a single tier
				local sameTier = true;
				local firstTier = drops[1].tiers[1];
				if ( not sameInstance and #drops[1].tiers == 1 ) then
					for i = 2, #drops do
						if ( #drops[i].tiers > 1 or drops[i].tiers[1] ~= firstTier ) then
							sameTier = false;
							break;
						end
					end
				end
				-- if same instance or tier, check if we have same difficulties and same instanceType
				local sameDifficulty = false;
				local sameInstanceType = false;
				if ( sameInstance or sameTier ) then
					sameDifficulty = true;
					sameInstanceType = true;
					for i = 2, #drops do
						if ( drops[1].instanceType ~= drops[i].instanceType ) then
							sameInstanceType = false;
						end
						if ( #drops[1].difficulties ~= #drops[i].difficulties ) then
							sameDifficulty = false;
						else
							for j = 1, #drops[1].difficulties do
								if ( drops[1].difficulties[j] ~= drops[i].difficulties[j] ) then
									sameDifficulty = false;
									break;
								end
							end
						end
					end
				end
				-- override sourceText if sameInstance or sameTier
				if ( sameInstance ) then
					sourceLocation = firstInstance;
					showDifficulty = sameDifficulty;
				elseif ( sameTier ) then
					local location = firstTier;
					if ( sameInstanceType ) then
						if ( drops[1].instanceType == INSTANCE_TYPE_DUNGEON ) then
							location = string.format(WARDROBE_TOOLTIP_DUNGEONS, location);
						elseif ( drops[1].instanceType == INSTANCE_TYPE_RAID ) then
							location = string.format(WARDROBE_TOOLTIP_RAIDS, location);
						end
					end
					sourceLocation = location;
					showDifficulty = sameDifficulty;
				end
			end

			if ( showDifficulty ) then
				local drop = drops[1];
				if ( drop.difficulties[1] ) then
					sourceDifficulties = table.concat(drop.difficulties, PLAYER_LIST_DELIMITER);
				end
			end
		end
	end

	if ( not appearanceCollected ) then
		if sourceLocation then
			if sourceDifficulties then
				--sourceText = WARDROBE_TOOLTIP_BOSS_DROP_FORMAT_WITH_DIFFICULTIES:format(sourceLocation, sourceDifficulties);
				sourceText = _G["TRANSMOG_SOURCE_"..TRANSMOG_SOURCE_BOSS_DROP]..": "..sourceLocation.." "..string.format(PARENS_TEMPLATE, sourceDifficulties);
			else
				--sourceText = WARDROBE_TOOLTIP_BOSS_DROP_FORMAT:format(sourceLocation);
				sourceText = _G["TRANSMOG_SOURCE_"..TRANSMOG_SOURCE_BOSS_DROP]..": "..sourceLocation;
			end
		end

		if sourceText and sourceText ~= "" and otherSourceText and otherSourceText ~= "" and sourceText ~= otherSourceText then
			otherSourceText = otherSourceText:gsub(_G["TRANSMOG_SOURCE_1"]..", ", ""):gsub(_G["TRANSMOG_SOURCE_1"], "");
			if otherSourceText ~= "" then
				otherSourceText = otherSourceText..", ";
			end
			sourceText = otherSourceText..sourceText;
		end

		return sourceText;
	end
end

function CollectionWardrobeUtil.SetAppearanceTooltip(tooltip, sources, primarySourceID, selectedIndex, showUseError, inLegionArtifactCategory, subheaderString, showSets)
	local canCycle = false;

	for i = 1, #sources do
		if ( sources[i].isHideVisual ) then
			GameTooltip_SetTitle(tooltip, sources[i].name, NORMAL_FONT_COLOR);
			tooltip:Show();
			return;
		end
	end

	local firstVisualID = sources[1].visualID;
	local passedFirstVisualID = false;

	local headerIndex;
	if ( not selectedIndex ) then
		headerIndex = CollectionWardrobeUtil.GetDefaultSourceIndex(sources, primarySourceID);
	else
		headerIndex = CollectionWardrobeUtil.GetValidIndexForNumSources(selectedIndex, #sources);
	end
	local headerSourceID = sources[headerIndex].sourceID;

	local name, nameColor = CollectionWardrobeUtil.GetAppearanceNameTextAndColor(sources[headerIndex], inLegionArtifactCategory);
	local sourceText, sourceColor = CollectionWardrobeUtil.GetAppearanceSourceTextAndColor(sources[headerIndex], ezCollections.Config.Wardrobe.ShowCollectedVisualSourceText);
	GameTooltip_SetTitle(tooltip, name, nameColor);
	if subheaderString then
		GameTooltip_AddHighlightLine(tooltip, subheaderString);
	end

	local info = ezCollections:GetSkinInfo(headerSourceID);
	if info and info.RaceMask then
		local allianceRaceMask = 0;
		local hordeRaceMask = 0;
		for race, faction in pairs(ezCollections.RaceNameToFaction) do
			if faction == FACTION_ALLIANCE then
				allianceRaceMask = bit.bor(allianceRaceMask, bit.lshift(1, ezCollections.RaceNameToID[race] - 1));
			elseif faction == FACTION_HORDE then
				hordeRaceMask = bit.bor(hordeRaceMask, bit.lshift(1, ezCollections.RaceNameToID[race] - 1));
			end
		end
		if info.RaceMask == allianceRaceMask then
			local color = UnitFactionGroup("player") == "Alliance" and HIGHLIGHT_FONT_COLOR or RED_FONT_COLOR;
			GameTooltip_AddColoredLine(tooltip, ITEM_REQ_ALLIANCE, color);
		elseif info.RaceMask == hordeRaceMask then
			local color = UnitFactionGroup("player") == "Horde" and HIGHLIGHT_FONT_COLOR or RED_FONT_COLOR;
			GameTooltip_AddColoredLine(tooltip, ITEM_REQ_HORDE, color);
		else
			local races = "";
			local match = false;
			for i, name in ipairs(ezCollections.RaceIDToName) do
				if bit.band(info.RaceMask, bit.lshift(1, i - 1)) ~= 0 then
					races = races .. (races ~= "" and ", " or "") .. ezCollections.L["Race."..i];
					if name == strupper(select(2, UnitRace("player")) or "") then
						match = true;
					end
				end
			end
			GameTooltip_AddColoredLine(tooltip, format(match and ITEM_RACES_ALLOWED or (RED_FONT_COLOR_CODE..ITEM_RACES_ALLOWED..FONT_COLOR_CODE_CLOSE), races), HIGHLIGHT_FONT_COLOR);
		end
	end
	if info and info.ClassMask then
		local classes = "";
		local match = false;
		for i, name in ipairs(ezCollections.ClassIDToName) do
			if bit.band(info.ClassMask, bit.lshift(1, i - 1)) ~= 0 then
				classes = classes .. (classes ~= "" and ", " or "") .. LOCALIZED_CLASS_NAMES_MALE[name];
				if name == select(2, UnitClass("player")) then
					match = true;
				end
			end
		end
		GameTooltip_AddColoredLine(tooltip, format(match and ITEM_CLASSES_ALLOWED or (RED_FONT_COLOR_CODE..ITEM_CLASSES_ALLOWED..FONT_COLOR_CODE_CLOSE), classes), HIGHLIGHT_FONT_COLOR);
	end

	sourceText = CollectionWardrobeUtil.GetAppearanceSourceTextWithDrops(sources[headerIndex], sourceText);
	if sourceText then
		GameTooltip_AddColoredLine(tooltip, sourceText, sourceColor, true);
	end

	if ezCollections.Developer then
		GameTooltip_AddColoredLine(tooltip, "ID "..headerSourceID.."  ||  "..(select(9, GetItemInfo(headerSourceID)) or "").."  ||  "..(select(7, GetItemInfo(headerSourceID)) or ""), GRAY_FONT_COLOR, true);
		if info and info.Unobtainable then
			GameTooltip_AddColoredLine(tooltip, "NOT OBTAINABLE", RED_FONT_COLOR);
		end
	elseif ezCollections.Config.Wardrobe.ShowItemID and not C_TransmogCollection.IsAppearanceHiddenVisual(headerSourceID) then
		GameTooltip_AddColoredLine(tooltip, "ID "..headerSourceID, GRAY_FONT_COLOR, true);
	end

	if showSets then
		CollectionWardrobeUtil.AddSourceSetsToTooltip(tooltip, headerSourceID);
	end

	local appearanceCollected = sources[headerIndex].isCollected;

	local useError;
	if ( #sources > 1 and (not appearanceCollected or ezCollections.Config.Wardrobe.ShowCollectedVisualSources) ) then
		-- only add "Other items using this appearance" if we're continuing to the same visualID
		if ( firstVisualID == sources[2].visualID ) then
			GameTooltip_AddBlankLineToTooltip(tooltip);
			GameTooltip_AddNormalLine(tooltip, WARDROBE_OTHER_ITEMS);
		end
		for i = 1, #sources do
			-- first time we transition to a different visualID, add "Other items that unlock this slot"
			if ( not passedFirstVisualID and firstVisualID ~= sources[i].visualID ) then
				passedFirstVisualID = true;
				GameTooltip_AddBlankLineToTooltip(tooltip);
				GameTooltip_AddHighlightLine(tooltip, WARDROBE_ALTERNATE_ITEMS);
			end

			local name, nameColor = CollectionWardrobeUtil.GetAppearanceNameTextAndColor(sources[i], inLegionArtifactCategory);
			local sourceText, sourceColor = CollectionWardrobeUtil.GetAppearanceSourceTextAndColor(sources[i]);
			if ( i == headerIndex ) then
				name = WARDROBE_TOOLTIP_CYCLE_ARROW_ICON..name;
				if showUseError and not CollectionWardrobeUtil.IsAppearanceUsable(sources[i], inLegionArtifactCategory) then
					useError = sources[i].useError;
				end
			else
				name = WARDROBE_TOOLTIP_CYCLE_SPACER_ICON..name;
			end
			GameTooltip_AddColoredDoubleLine(tooltip, name, sourceText, nameColor, sourceColor);
		end
		local text;
		if ezCollections.Config.Wardrobe.TooltipCycleKeyboard and ezCollections.Config.Wardrobe.TooltipCycleMouseWheel then
			text = ezCollections.L["Tooltip.Cycle.KeyboardAndMouseWheel"];
		elseif ezCollections.Config.Wardrobe.TooltipCycleKeyboard then
			text = ezCollections.L["Tooltip.Cycle.Keyboard"];
		elseif ezCollections.Config.Wardrobe.TooltipCycleMouseWheel then
			text = ezCollections.L["Tooltip.Cycle.MouseWheel"];
		end
		if text then
			GameTooltip_AddBlankLineToTooltip(tooltip);
			GameTooltip_AddColoredLine(tooltip, text, GRAY_FONT_COLOR, true);
			canCycle = true;
		end
	else
		if showUseError and not CollectionWardrobeUtil.IsAppearanceUsable(sources[headerIndex], inLegionArtifactCategory) then
			useError = sources[headerIndex].useError;
		end
	end

	if ( appearanceCollected  ) then
		if ( useError ) then
			GameTooltip_AddErrorLine(tooltip, useError);
		elseif ( not C_Transmog.IsAtTransmogNPC() ) then
			--GameTooltip_AddColoredLine(tooltip, WARDROBE_TOOLTIP_TRANSMOGRIFIER, GRAY_FONT_COLOR);
		end
		if ( not useError ) then
			local holidayName = C_TransmogCollection.GetSourceRequiredHoliday(headerSourceID);
			if ( holidayName ) then
				GameTooltip_AddColoredLine(tooltip, TRANSMOG_APPEARANCE_USABLE_HOLIDAY:format(holidayName), LIGHTBLUE_FONT_COLOR);
			end
		end
	end

	tooltip:Show();
	return headerIndex, canCycle;
end

-- if the sourceID is not collectable, this will try to find a collectable one that has the same appearance
-- returns: preferredSourceID, hasAllDataAvailable, canCollect
-- if all data was not available, calling this after TRANSMOG_COLLECTION_ITEM_UPDATE and TRANSMOG_SOURCE_COLLECTABILITY_UPDATE events may result in a better sourceID returned
function CollectionWardrobeUtil.GetPreferredSourceID(initialSourceID, appearanceInfo)
	if not appearanceInfo then
		appearanceInfo = C_TransmogCollection.GetAppearanceInfoBySource(initialSourceID);
	end

	local hasAllData = true;
	if not appearanceInfo then
		-- either uncollected with all sources HiddenUntilCollected or uncollectable
		local hasData, canCollect = C_TransmogCollection.PlayerCanCollectSource(initialSourceID);
		if canCollect then
			return initialSourceID, hasData, canCollect;
		end
		-- the initialSourceID is not collectable, try to find another one
		local category, itemAppearanceID = C_TransmogCollection.GetAppearanceSourceInfo(initialSourceID);
		if itemAppearanceID then
			local sourceIDs = C_TransmogCollection.GetAllAppearanceSources(itemAppearanceID);
			for i, sourceID in pairs(sourceIDs) do
				-- we've already checked initialSourceID
				if sourceID ~= initialSourceID then
					hasData, canCollect = C_TransmogCollection.PlayerCanCollectSource(sourceID);
					if canCollect then
						return sourceID, hasData, canCollect;
					end
					if not hasData then
						hasAllData = false;
					end
				end
			end
		end
		-- couldn't find a valid one for player
		return initialSourceID, hasAllData, false;
	else
		-- if initialSourceID is known and the collection state matches, we're good
		if appearanceInfo.sourceIsKnown and appearanceInfo.appearanceIsCollected == appearanceInfo.sourceIsCollected then
			return initialSourceID, hasAllData, true;
		end
		-- If we're here, there are 2 possibilities:
		-- 1. the initialSourceID is not known (HiddenUntilCollected or not available to player)
		-- 2. the appearance is collected but the initialSourceID is not
		-- In either case, grab the first valid one from the list
		local sourceInfos = CollectionWardrobeUtil.GetSortedAppearanceSources(appearanceInfo.appearanceID);
		for i, sourceInfo in ipairs(sourceInfos) do
			if not sourceInfo.name then
				hasAllData = false;
			end
		end
		return sourceInfos[1].sourceID, hasAllData, true;
	end
end

-- This wraps C_TransmogCollection.PlayerCanCollectSource but calls C_TransmogCollection.GetAppearanceInfoBySource first
-- since that covers the majority of cases and doesn't need sparse
-- returns: hasData, canCollect
function CollectionWardrobeUtil.PlayerCanCollectSource(sourceID)
	local appearanceInfo = C_TransmogCollection.GetAppearanceInfoBySource(sourceID);
	if appearanceInfo then
		return true, true;
	end
	return C_TransmogCollection.PlayerCanCollectSource(sourceID);
end
