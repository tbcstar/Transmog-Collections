SetEnabledMixin = { };
function SetEnabledMixin:SetEnabled(enabled)
	if enabled then
		self:Enable();
	else
		self:Disable();
	end
end

SetShownMixin = { };
function SetShownMixin:SetShown(shown)
	if shown then
		self:Show();
	else
		self:Hide();
	end
end

IsTruncatedMixin = { };
function IsTruncatedMixin:IsTruncated()
	local oldWidth = self:GetWidth();
	self:SetWidth(100000);
	local isTruncated = oldWidth < self:GetStringWidth();
	self:SetWidth(oldWidth);
	return isTruncated;
end

SetAtlasMixin = { };
function SetAtlasMixin:SetAtlas(atlasName, useAtlasSize)
	local atlasMember = ezCollections.AtlasMember[atlasName:lower()];
	if atlasMember then
		local atlasID, left, right, top, bottom = unpack(atlasMember);
		local atlas = ezCollections.Atlas[atlasID];
		if atlas then
			local file, width, height = unpack(atlas);
			self:SetTexture(file);
			self:SetTexCoord(left / width, right / width, top / height, bottom / height);
			if useAtlasSize then
				self:SetSize(right - left, bottom - top);
			end
			return;
		end
	end
	self:SetTexture(nil);
end

function GameTooltip:SetTransmogrifyItem(slotID)
	local _, _, _, _, pendingSourceID, _, hasPendingUndo = C_Transmog.GetSlotVisualInfo(slotID, LE_TRANSMOG_TYPE_APPEARANCE);
	local _, _, _, _, pendingIllusionID, _, hasPendingIllusionUndo = C_Transmog.GetSlotVisualInfo(slotID, LE_TRANSMOG_TYPE_ILLUSION);
	ezCollections:SetPendingTooltipInfo("SetTransmogrifyItem", hasPendingUndo, pendingSourceID, hasPendingIllusionUndo, pendingIllusionID);
	self:SetInventoryItem("player", slotID);
	ezCollections:ClearPendingTooltipInfo("SetTransmogrifyItem");
end

function GameTooltip:SetToyByItemID(itemID)
	ezCollections:SetPendingTooltipInfo("SetToyByItemID");
	self:SetHyperlink("item:"..itemID);
	if self:IsShown() then
		local toyID = ezCollections:GetToyIDByItem(itemID);
		local _, flags, _, _, sourceText, holiday = ezCollections:GetToyInfo(toyID or 0);
		local lines = { };
		local reqs = { };
		local footer = { };
		local foundCooldown = false;
		local onEquipTriggers = { };
		for i = 1, 20 do
			local line = _G[self:GetName().."TextLeft"..i];
			if line and line:IsShown() and line:GetText() and line:GetText() ~= "" and line:GetText() ~= " " then
				local text = line:GetText();
				local r, g, b = line:GetTextColor();
				if i == 1 then
					table.insert(lines, { text, r, g, b, 0 });
					table.insert(lines, { TOY, 0x88/0xFF, 0xAA/0xFF, 1, 0 });
				elseif ezCollections.IsSameColor(r, g, b, 0, 1, 0) and text:find(ITEM_SPELL_TRIGGER_ONUSE) == 1 then -- Spell
					table.insert(lines, { text, r, g, b, 1 });
					if onEquipTriggers then
						for _, line in ipairs(onEquipTriggers) do
							tDeleteItem(lines, line);
						end
						onEquipTriggers = nil;
					end
				elseif ezCollections.IsSameColor(r, g, b, 0, 1, 0) and text:find(ITEM_SPELL_TRIGGER_ONEQUIP) == 1 and onEquipTriggers then -- Spell
					table.insert(lines, { text:gsub(ITEM_SPELL_TRIGGER_ONEQUIP, ITEM_SPELL_TRIGGER_ONUSE), r, g, b, 1 });
					table.insert(onEquipTriggers, lines[#lines]);
				elseif text:match(ezCollections.FormatToPattern(ITEM_COOLDOWN_TIME)) then
					table.insert(lines, { text, r, g, b, 0 }); foundCooldown = true;
				elseif ezCollections.IsSameColor(r, g, b, 1, 0.8235, 0) and text:sub(1, 1) == "\"" then -- Description
					table.insert(footer, { text, r, g, b, 1 });
				elseif ezCollections.IsSameColor(r, g, b, 1, 0.125, 0.125) then -- Failed requirements
					table.insert(reqs, { text, r, g, b, 0 });
				elseif text:match(ezCollections.FormatToPattern(ITEM_MIN_LEVEL))
					or text:match(ezCollections.FormatToPattern(ITEM_MIN_SKILL))
					or text:match(ezCollections.FormatToPattern(ITEM_LEVEL_RANGE))
					or text:match(ezCollections.FormatToPattern(ITEM_LEVEL_RANGE_CURRENT))
					or text:match(ezCollections.FormatToPattern(ITEM_REQ_REPUTATION))
					or text:match(ezCollections.FormatToPattern(ITEM_REQ_SKILL)) then
					local wrap = 1;
					if holiday and text == format(ITEM_REQ_SKILL, ezCollections.Holidays[holiday] or "") and not ezCollections:IsHolidayActive(holiday) then
						r, g, b, wrap = 1, 0.125, 0.125, 0;
					end
					table.insert(reqs, { text, r, g, b, wrap });
				end
			end
		end
		self:ClearLines();
		for _, line in ipairs(lines) do
			self:AddLine(unpack(line));
		end
		if not foundCooldown then
			local start, duration, enable = ezCollections:GetItemCooldown(itemID);
			local now = GetTime();
			if start + duration >= now then
				local text = ezCollections:FormatItemCooldown(math.floor((start + duration - now) * 1000));
				if text then
					self:AddLine(format(ITEM_COOLDOWN_TIME, text), 1, 1, 1, 0);
				end
			end
		end
		for _, line in ipairs(reqs) do
			self:AddLine(unpack(line));
		end
		if bit.band(flags or 0, 0x100) ~= 0 then
			if UnitFactionGroup("player") == "Horde" then
				self:AddLine(ITEM_REQ_HORDE, 1, 1, 1);
			else
				self:AddLine(ITEM_REQ_HORDE, 1, 0.125, 0.125);
			end
		end
		if bit.band(flags or 0, 0x200) ~= 0 then
			if UnitFactionGroup("player") == "Alliance" then
				self:AddLine(ITEM_REQ_ALLIANCE, 1, 1, 1);
			else
				self:AddLine(ITEM_REQ_ALLIANCE, 1, 0.125, 0.125);
			end
		end
		for _, line in ipairs(footer) do
			self:AddLine(unpack(line));
		end

		local hasToy = ezCollections:HasToy(toyID);
		if not hasToy and ezCollections:IsActiveToySubscriptionToy(toyID) then
			self:AddLine(" ");
			self:AddLine(ezCollections.L["Toy.Subscription.Details.Info"], HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1);
		end
		if not hasToy or ezCollections.Config.Wardrobe.ShowCollectedToySourceText then
			if sourceText ~= "" then
				self:AddLine(" ");
				self:AddLine(sourceText, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1);
			end
		end

		if ezCollections.Developer then
			self:AddLine("Toy ID: "..toyID, 0.5, 0.5, 0.5);
			self:AddLine("Item ID: "..itemID, 0.5, 0.5, 0.5);
		end

		self:Show();
	end
	ezCollections:ClearPendingTooltipInfo("SetToyByItemID");
	return self:IsShown();
end

local _EJ_GetInvTypeSortOrderData = { nil, 10, 11, 12, 14.33, 14, 17, 18, 19, 15, 16, 20, 21, 4, 6, 5, 13, 1, nil, 14.66, 14, 2, 3, 7, nil, 8, 5, nil, 9 };
function EJ_GetInvTypeSortOrder(invType)
	return _EJ_GetInvTypeSortOrderData[invType];
end

function IsOnGlueScreen()
	return false;
end

function GetSpecialization()
	return GetActiveTalentGroup();
end

function GetSpecializationInfo(index)
	local description = nil;
	local role = nil;
	local cache = { };
	TalentFrame_UpdateSpecInfoCache(cache, false, false, index);
	if cache.primaryTabIndex ~= 0 then
		return index, cache[cache.primaryTabIndex].name, description, cache[cache.primaryTabIndex].icon, role;
	else
		return index, "", description, TALENT_HYBRID_ICON, role;
	end
end

function GetNumSpecializations()
	return GetNumTalentGroups();
end

function HasAlternateForm()
	return false, false;
end

function GetNumExpansions()
	return 3;
end
