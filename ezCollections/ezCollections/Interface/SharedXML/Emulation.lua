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
	ezCollections:SetPendingTooltipInfo(hasPendingUndo, pendingSourceID, hasPendingIllusionUndo, pendingIllusionID);
	self:SetInventoryItem("player", slotID);
	ezCollections:SetPendingTooltipInfo();
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
