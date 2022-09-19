local function GetOutfitSourcesFromCurrentEquipment(selectedSlotsOnly)
	local sources = { };
	local mainHandEnchant, offHandEnchant;
	local hadInvalidSources = false;
	for _, slotInfo in ipairs(TRANSMOG_SLOTS) do
		local slot = GetInventorySlotInfo(slotInfo.slot);
		local _, _, appliedSourceID, _, pendingSourceID, _, hasPendingUndo = C_Transmog.GetSlotVisualInfo(slot, slotInfo.transmogType);
		local sourceID = WardrobeOutfitMixin:GetSlotSourceID(slotInfo.slot, slotInfo.transmogType);
		if sourceID ~= NO_TRANSMOG_SOURCE_ID and (not selectedSlotsOnly or appliedSourceID ~= 0 or pendingSourceID ~= 0 or hasPendingUndo) then
			if slotInfo.transmogType == LE_TRANSMOG_TYPE_APPEARANCE then
				if C_TransmogCollection.PlayerKnowsSource(sourceID) then
					sources[slot] = sourceID;
				else
					hadInvalidSources = true;
				end
			elseif slotInfo.transmogType == LE_TRANSMOG_TYPE_ILLUSION then
				if slotInfo.slot == "MAINHANDSLOT" then
					mainHandEnchant = sourceID;
				else
					offHandEnchant = sourceID;
				end
			end
		end
	end
	return sources, mainHandEnchant, offHandEnchant;
end

local function GetOutfitSourcesFromOutfitAndPending(outfitID)
	local sources, mainHandEnchant, offHandEnchant = C_TransmogCollection.GetOutfitSources(outfitID);
	local hadInvalidSources = false;
	for _, slotInfo in ipairs(TRANSMOG_SLOTS) do
		local slot = GetInventorySlotInfo(slotInfo.slot);
		local _, _, appliedSourceID, _, pendingSourceID, _, hasPendingUndo = C_Transmog.GetSlotVisualInfo(slot, slotInfo.transmogType);
		local sourceID = WardrobeOutfitMixin:GetSlotSourceID(slotInfo.slot, slotInfo.transmogType);
		if pendingSourceID ~= 0 or hasPendingUndo then
			if slotInfo.transmogType == LE_TRANSMOG_TYPE_APPEARANCE then
				if C_TransmogCollection.PlayerKnowsSource(sourceID) then
					sources[slot] = sourceID;
				else
					hadInvalidSources = true;
				end
			elseif slotInfo.transmogType == LE_TRANSMOG_TYPE_ILLUSION then
				if slotInfo.slot == "MAINHANDSLOT" then
					mainHandEnchant = sourceID;
				else
					offHandEnchant = sourceID;
				end
			end
		end
	end
	return sources, mainHandEnchant, offHandEnchant;
end

--===================================================================================================================================
WardrobeOutfitDropDownMixin = { };

function WardrobeOutfitDropDownTemplate_OnLoad(self)
	Mixin(self, WardrobeOutfitDropDownMixin);
	local button = _G[self:GetName().."Button"];
	button:SetScript("OnClick", function(self)
						PlaySound("igMainMenuOptionCheckBoxOn");
						WardrobeOutfitFrame:Toggle(self:GetParent());
						end
					);
	UIDropDownMenu_JustifyText(self, "LEFT");
	if ( self.width ) then
		UIDropDownMenu_SetWidth(self, self.width);
	end

	Mixin(self.SaveButton, SetEnabledMixin);
end

function WardrobeOutfitDropDownTemplate_OnShow(self)
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
	ezCollections:RegisterEvent(self, "TRANSMOG_OUTFITS_CHANGED");
	ezCollections:RegisterEvent(self, "TRANSMOGRIFY_UPDATE");
	self:SelectOutfit(self:GetLastOutfitID(), true);
end

function WardrobeOutfitDropDownTemplate_OnHide(self)
	self:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
	ezCollections:UnregisterEvent(self, "TRANSMOG_OUTFITS_CHANGED");
	ezCollections:UnregisterEvent(self, "TRANSMOGRIFY_UPDATE");
	WardrobeOutfitFrame:ClosePopups(self);
	if ( WardrobeOutfitFrame.dropDown == self ) then
		WardrobeOutfitFrame:Hide();
	end
end

function WardrobeOutfitDropDownTemplate_OnEvent(self, event)
	if event == "ACTIVE_TALENT_GROUP_CHANGED" then
		self:Hide();
		self:Show();
	end
	if ( event == "TRANSMOG_OUTFITS_CHANGED" ) then
		if WardrobeOutfitFrame.pendingOutfitSave then
			for _, outfit in ipairs(C_TransmogCollection.GetOutfits()) do
				if outfit.name == WardrobeOutfitFrame.pendingOutfitSave then
					self.selectedOutfitID = outfit.outfitID;
					self:OnOutfitSaved(outfit.outfitID);
				end
			end
			WardrobeOutfitFrame.pendingOutfitSave = nil;
		end
		-- try to reselect the same outfit to update the name
		-- if it changed or clear the name if it got deleted
		self:SelectOutfit(self.selectedOutfitID);
		if ( WardrobeOutfitFrame:IsShown() ) then
			WardrobeOutfitFrame:Update();
		end
	end
	-- don't need to do anything for "TRANSMOGRIFY_UPDATE" beyond updating the save button
	self:UpdateSaveButton();
end

function WardrobeOutfitDropDownMixin:UpdateSaveButton()
	if ( self.selectedOutfitID ) then
		--self.SaveButton:SetEnabled(not self:IsOutfitDressed());
		self.SaveButton:SetEnabled(true);
	else
		self.SaveButton:SetEnabled(false);
	end
end

function WardrobeOutfitDropDownMixin:OnOutfitSaved(outfitID)
end

function WardrobeOutfitDropDownMixin:SelectOutfit(outfitID, loadOutfit)
	local name;
	if ( outfitID ) then
		name = C_TransmogCollection.GetOutfitName(outfitID);
	end
	if ( name ) then
		UIDropDownMenu_SetText(self, name);
	else
		outfitID = nil;
		UIDropDownMenu_SetText(self, GRAY_FONT_COLOR_CODE..TRANSMOG_OUTFIT_NONE..FONT_COLOR_CODE_CLOSE);
	end
	self.selectedOutfitID = outfitID;
	if ( loadOutfit ) then
		self:LoadOutfit(outfitID);
	end
	self:UpdateSaveButton();
	self:OnSelectOutfit(outfitID);
end

function WardrobeOutfitDropDownMixin:OnSelectOutfit(outfitID)
	-- nothing to see here
end

function WardrobeOutfitDropDownMixin:GetLastOutfitID()
	return nil;
end

local function IsSourceArtifact(sourceID)
	local link = select(6, C_TransmogCollection.GetAppearanceSourceInfo(sourceID));
	local _, _, quality = GetItemInfo(link);
	return quality == LE_ITEM_QUALITY_ARTIFACT;
end

function WardrobeOutfitDropDownMixin:IsOutfitDressed()
	if ( not self.selectedOutfitID ) then
		return true;
	end
	local appearanceSources, mainHandEnchant, offHandEnchant = C_TransmogCollection.GetOutfitSources(self.selectedOutfitID);
	if ( not appearanceSources ) then
		return true;
	end
	for i = 1, #TRANSMOG_SLOTS do
		if ( TRANSMOG_SLOTS[i].transmogType == LE_TRANSMOG_TYPE_APPEARANCE ) then
			local sourceID = self:GetSlotSourceID(TRANSMOG_SLOTS[i].slot, LE_TRANSMOG_TYPE_APPEARANCE);
			local slotID = GetInventorySlotInfo(TRANSMOG_SLOTS[i].slot);
			if appearanceSources[slotID] and ( sourceID ~= NO_TRANSMOG_SOURCE_ID and sourceID ~= appearanceSources[slotID] ) then
				-- No artifacts in outfits, their sourceID is overriden to NO_TRANSMOG_SOURCE_ID
				if (not IsSourceArtifact(sourceID) or appearanceSources[slotID] ~= NO_TRANSMOG_SOURCE_ID ) then
					return false;
				end
			end
		end
	end
	local mainHandSourceID = self:GetSlotSourceID("MAINHANDSLOT", LE_TRANSMOG_TYPE_ILLUSION);
	if mainHandEnchant and ( mainHandSourceID ~= mainHandEnchant ) then
		return false;
	end
	local offHandSourceID = self:GetSlotSourceID("SECONDARYHANDSLOT", LE_TRANSMOG_TYPE_ILLUSION);
	if offHandEnchant and ( offHandSourceID ~= offHandEnchant ) then
		return false;
	end
	return true;
end

--[[
function WardrobeOutfitDropDownMixin:CheckOutfitForSave(name)
	local sources = { };
	local mainHandEnchant, offHandEnchant;
	local pendingSources = { };
	local hadInvalidSources = false;

	for i = 1, #TRANSMOG_SLOTS do
		local sourceID = self:GetSlotSourceID(TRANSMOG_SLOTS[i].slot, TRANSMOG_SLOTS[i].transmogType);
		if ( sourceID ~= NO_TRANSMOG_SOURCE_ID ) then
			if ( TRANSMOG_SLOTS[i].transmogType == LE_TRANSMOG_TYPE_APPEARANCE ) then
				local slotID = GetInventorySlotInfo(TRANSMOG_SLOTS[i].slot);
				local isValidSource = C_TransmogCollection.PlayerKnowsSource(sourceID);
				if ( not isValidSource ) then
					local isInfoReady, canCollect = C_TransmogCollection.PlayerCanCollectSource(sourceID);
					if ( isInfoReady ) then
						if ( canCollect ) then
							isValidSource = true;
						else
							-- hack: ignore artifacts
							if (not IsSourceArtifact(sourceID)) then
								hadInvalidSources = true;
							end
						end
					else
						-- saving the "slot" for the sourceID
						pendingSources[sourceID] = slotID;
					end
				end
				if ( isValidSource ) then
					-- No artifacts in outfits, their sourceID is overriden to NO_TRANSMOG_SOURCE_ID
					if ( IsSourceArtifact(sourceID) ) then
						sources[slotID] = NO_TRANSMOG_SOURCE_ID;
					else
						sources[slotID] = sourceID;
					end
				end
			elseif ( TRANSMOG_SLOTS[i].transmogType == LE_TRANSMOG_TYPE_ILLUSION ) then
				if ( TRANSMOG_SLOTS[i].slot == "MAINHANDSLOT" ) then
					mainHandEnchant = sourceID;
				else
					offHandEnchant = sourceID;
				end
			end
		end
	end

	-- store the state for this save
	WardrobeOutfitFrame.sources = sources;
	WardrobeOutfitFrame.mainHandEnchant = mainHandEnchant;
	WardrobeOutfitFrame.offHandEnchant = offHandEnchant;
	WardrobeOutfitFrame.pendingSources = pendingSources;
	WardrobeOutfitFrame.hadInvalidSources = hadInvalidSources;
	WardrobeOutfitFrame.name = name;
	-- save the dropdown
	WardrobeOutfitFrame.popupDropDown = self;

	WardrobeOutfitFrame:EvaluateSaveState();
end
]]
function WardrobeOutfitDropDownMixin:CheckOutfitForSave(outfitID)
	local selectedSources, selectedMainHandEnchant, selectedOffHandEnchant;
	if outfitID then
		selectedSources, selectedMainHandEnchant, selectedOffHandEnchant = GetOutfitSourcesFromOutfitAndPending(outfitID);
	else
		selectedSources, selectedMainHandEnchant, selectedOffHandEnchant = GetOutfitSourcesFromCurrentEquipment(true);
	end
	WardrobeOutfitFrame:ShowPopup(WardrobeOutfitSaveFrame);
	WardrobeOutfitSlotsSelectionFrame:Hide();
	WardrobeOutfitSlotsSelectionFrame:SetParent(WardrobeOutfitSaveFrame.SlotsContainer);
	WardrobeOutfitSlotsSelectionFrame:ClearAllPoints();
	WardrobeOutfitSlotsSelectionFrame:SetPoint("TOPLEFT", WardrobeOutfitSaveFrame.SlotsContainer, "TOPLEFT", 12, -12);
	WardrobeOutfitSlotsSelectionFrame:SetPoint("BOTTOMRIGHT", WardrobeOutfitSaveFrame.SlotsContainer, "BOTTOMRIGHT", -12, 12);
	WardrobeOutfitSlotsSelectionFrame:Show();
	WardrobeOutfitSlotsSelectionFrame:SetSlots(selectedSources, selectedMainHandEnchant, selectedOffHandEnchant, GetOutfitSourcesFromCurrentEquipment());
	WardrobeOutfitSaveFrame.editedOutfitID = outfitID;
	WardrobeOutfitSaveFrame:SetHeight(80 + 8 + WardrobeOutfitSaveFrame.SlotsContainer:GetHeight() + 8 + 8 + 20 + 64);
	WardrobeOutfitSaveFrame.EditBox:SetText(outfitID and C_TransmogCollection.GetOutfitName(outfitID) or "");
	WardrobeOutfitSaveFrame.EditBox:SetFocus();
	WardrobeOutfitSaveFrame.Prepaid:SetChecked(C_TransmogCollection.GetOutfitPrepaid(outfitID));
	WardrobeOutfitSaveFrame.Prepaid:SetEnabled(not C_TransmogCollection.GetOutfitPrepaid(outfitID));
	WardrobeOutfitSaveFrame:QueryInfo();
end

--===================================================================================================================================
WardrobeOutfitFrameMixin = { };

WardrobeOutfitFrameMixin.popups = {
	"NAME_TRANSMOG_OUTFIT",
	"CONFIRM_DELETE_TRANSMOG_OUTFIT",
	"CONFIRM_SAVE_TRANSMOG_OUTFIT",
	"CONFIRM_OVERWRITE_TRANSMOG_OUTFIT",
	"TRANSMOG_OUTFIT_CHECKING_APPEARANCES",
	"TRANSMOG_OUTFIT_SOME_INVALID_APPEARANCES",
	"TRANSMOG_OUTFIT_ALL_INVALID_APPEARANCES",
};

local OUTFIT_FRAME_MIN_STRING_WIDTH = 152;
local OUTFIT_FRAME_MAX_STRING_WIDTH = 216;
local OUTFIT_FRAME_ADDED_PIXELS = 90;	-- pixels added to string width

local GOLD_SHEEN_PHASE = 0;
local function FormatGoldSheen(button, index)
	local orig = button.originalText;
	local text = "";
	local p = index * 0.5 - GOLD_SHEEN_PHASE * 3;
	local i = 0;
	local len = orig:utf8len();
	while i < len do
		i = i + 1;
		local cc = orig:utf8sub(i, i + 1);
		if cc == "|c" then
			i = i + 10;
		elseif cc == "|r" or cc == "|n" then
			i = i + 2;
		end
		local c = orig:utf8sub(i, i);
		if not c or c == "" then break; end
		local a = math.abs(math.sin(p));
		local r = 0xFF;
		local g = 0xD2 + (0xFF - 0xD2) * a;
		local b = 0x00 + (0xFF - 0x00) * a * 0.9;
		p = p + 0.2;
		text = text .. format("|cFF%02X%02X%02X%s|r", r, g, b, c);
	end
	return text;
end

function WardrobeOutfitFrame_OnHide(self)
	self.timer = nil;
end

function WardrobeOutfitFrameMixin:Toggle(dropDown)
	if ( self.dropDown == dropDown and self:IsShown() ) then
		WardrobeOutfitFrame:Hide();
	else
		CloseDropDownMenus();
		self.dropDown = dropDown;
		self:Show();
		self:SetPoint("TOPLEFT", self.dropDown, "BOTTOMLEFT", 8, -3);
		self:Update();
	end
end

function WardrobeOutfitFrame_OnUpdate(self, elapsed)
	GOLD_SHEEN_PHASE = (GOLD_SHEEN_PHASE + elapsed) % 1;
	local mouseFocus = GetMouseFocus();
	for i = 1, #self.Buttons do
		local button = self.Buttons[i];
		if ( button == mouseFocus or button:IsMouseOver() ) then
			if ( button.outfitID ) then
				button.EditButton:Show();
			else
				button.EditButton:Hide();
			end
			button.Highlight:Show();
		else
			button.EditButton:Hide();
			button.Highlight:Hide();
		end
		if button:IsShown() and button.outfitID and button.prepaid and button.originalText then
			button.Text:SetText(FormatGoldSheen(button, i));
		end
	end
	if DropDownList1 and DropDownList1:IsShown() then
		self:Hide();
	end
	if ( self.timer ) then
		self.timer = self.timer - elapsed;
		if ( self.timer < 0 ) then
			self:Hide();
		end
	end
end

function WardrobeOutfitFrameMixin:StartHideCountDown()
	self.timer = UIDROPDOWNMENU_SHOW_TIME;
end

function WardrobeOutfitFrameMixin:StopHideCountDown()
	self.timer = nil;
end

function WardrobeOutfitFrameMixin:Update()
	local outfits = C_TransmogCollection.GetOutfits();
	local sort = ezCollections.Config.Wardrobe.OutfitsSort;
	table.sort(outfits, function(a, b)
		if sort == 2 and a.name ~= b.name then
			return a.name < b.name;
		end
		return a.outfitID < b.outfitID;
	end);
	local buttons = self.Buttons;
	local numButtons = 0;
	local stringWidth = 0;
	local minStringWidth = self.dropDown.minMenuStringWidth or OUTFIT_FRAME_MIN_STRING_WIDTH;
	local maxStringWidth = self.dropDown.maxMenuStringWidth or OUTFIT_FRAME_MAX_STRING_WIDTH;
	self:SetWidth(maxStringWidth + OUTFIT_FRAME_ADDED_PIXELS);
	for i = 1, C_TransmogCollection.GetNumMaxOutfits() do
		local newOutfitButton = (i == (#outfits + 1));
		if ( outfits[i] or newOutfitButton ) then
			local button = buttons[i];
			if ( not button ) then
				button = CreateFrame("BUTTON", nil, self, "WardrobeOutfitButtonTemplate");
				table.insert(buttons, button);
				button:SetPoint("TOPLEFT", buttons[i-1], "BOTTOMLEFT", 0, 0);
				button:SetPoint("TOPRIGHT", buttons[i-1], "BOTTOMRIGHT", 0, 0);
			end
			button:Show();
			if ( newOutfitButton ) then
				button:SetText(GREEN_FONT_COLOR_CODE..TRANSMOG_OUTFIT_NEW..FONT_COLOR_CODE_CLOSE);
				button.Icon:SetTexture([[Interface\AddOns\ezCollections\Interface\PaperDollInfoFrame\Character-Plus]]);
				button.outfitID = nil;
				button.Check:Hide();
				button.Selection:Hide();
			else
				if ( outfits[i].outfitID == self.dropDown.selectedOutfitID ) then
					button.Check:Show();
					button.Selection:Show();
				else
					button.Selection:Hide();
					button.Check:Hide();
				end
				button.Text:SetWidth(0);
				button.prepaid = outfits[i].prepaid;
				button.Prepaid:SetShown(button.prepaid);
				button.Prepaid:SetWidth(button.Prepaid:IsShown() and button.Prepaid:GetHeight() or 0.00001);
				if button.prepaid and ezCollections.Config.Wardrobe.OutfitsPrepaidSheen then
					button.originalText = outfits[i].name;
					button.Text:SetText(FormatGoldSheen(button, i));
				else
					button.originalText = nil;
					button.Text:SetText(outfits[i].name);
					button.Text:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
				end
				button.Icon:SetTexture(outfits[i].icon);
				button.outfitID = outfits[i].outfitID;
			end
			stringWidth = max(stringWidth, button.Text:GetStringWidth());
			if ( button.Text:GetStringWidth() > maxStringWidth) then
				button.Text:SetWidth(maxStringWidth);
			end
			numButtons = numButtons + 1;
		else
			if ( buttons[i] ) then
				buttons[i]:Hide();
			end
		end
	end
	stringWidth = max(stringWidth, minStringWidth);
	stringWidth = min(stringWidth, maxStringWidth);
	self:SetWidth(stringWidth + OUTFIT_FRAME_ADDED_PIXELS + (ezCollections.PrepaidOutfitsEnabled and 14 or 0));
	self:SetHeight(30 + numButtons * 20);
end

function WardrobeOutfitFrameMixin:SaveOutfit(name)
--[[
	local icon;
	for i = 1, #TRANSMOG_SLOTS do
		if ( TRANSMOG_SLOTS[i].transmogType == LE_TRANSMOG_TYPE_APPEARANCE ) then
			local slotID = GetInventorySlotInfo(TRANSMOG_SLOTS[i].slot);
			local sourceID = self.sources[slotID];
			if ( sourceID ) then
				icon = select(4, C_TransmogCollection.GetAppearanceSourceInfo(sourceID));
				if ( icon ) then
					break;
				end
			end
		end
	end
		
	local outfitID = C_TransmogCollection.SaveOutfit(name, self.sources, self.mainHandEnchant, self.offHandEnchant, icon);
	if ( self.popupDropDown ) then
		self.popupDropDown:SelectOutfit(outfitID);
		self.popupDropDown:OnOutfitSaved(outfitID);
	end
]]
	self.pendingOutfitSave = name;
	C_TransmogCollection.SaveOutfit(name, GetOutfitSourcesFromCurrentEquipment());
end

function WardrobeOutfitFrameMixin:DeleteOutfit(outfitID)
	C_TransmogCollection.DeleteOutfit(outfitID);
end

function WardrobeOutfitFrameMixin:NameOutfit(newName, outfitID)
	local outfits = C_TransmogCollection.GetOutfits();
	for i = 1, #outfits do
		if ( outfits[i].name == newName ) then
			if ( outfitID ) then
				UIErrorsFrame:AddMessage(TRANSMOG_OUTFIT_ALREADY_EXISTS, 1.0, 0.1, 0.1, 1.0);
			else
				WardrobeOutfitFrame:ShowPopup("CONFIRM_OVERWRITE_TRANSMOG_OUTFIT", newName, nil, newName);
			end
			return;
		end
	end
	if ( outfitID ) then
		-- this is a rename
		C_TransmogCollection.ModifyOutfit(outfitID, newName);
	else
		-- this is a new outfit
		self:SaveOutfit(newName);
	end
end

function WardrobeOutfitFrameMixin:ShowPopup(popup, ...)
	-- close all other popups
	for _, listPopup in pairs(self.popups) do
		if ( listPopup ~= popup ) then
			StaticPopup_Hide(listPopup);
		end
	end
	if ( popup ~= WardrobeOutfitEditFrame ) then
		StaticPopupSpecial_Hide(WardrobeOutfitEditFrame);
	end
	if popup ~= WardrobeOutfitSaveFrame then
		StaticPopupSpecial_Hide(WardrobeOutfitSaveFrame);
	end

	self.popupDropDown = self.dropDown;
	if ( popup == WardrobeOutfitEditFrame ) then
		StaticPopupSpecial_Show(WardrobeOutfitEditFrame);
	elseif popup == WardrobeOutfitSaveFrame then
		StaticPopupSpecial_Show(WardrobeOutfitSaveFrame);
	else
		StaticPopupInserted_Show(popup, ...);
	end
end

function WardrobeOutfitFrameMixin:ClosePopups(requestingDropDown)
	if ( requestingDropDown and requestingDropDown ~= self.popupDropDown ) then
		return;
	end
	for _, popup in pairs(self.popups) do
		StaticPopup_Hide(popup);
	end
	StaticPopupSpecial_Hide(WardrobeOutfitEditFrame);

	-- clean up
	self.sources = nil;
	self.mainHandEnchant = nil;
	self.offHandEnchant = nil;
	self.pendingSources = nil;
	self.hadInvalidSources = nil;
	self.name = nil;
	self.popupDropDown = nil;
end

--[[
function WardrobeOutfitFrameMixin:EvaluateSaveState()
	if ( next(self.pendingSources) ) then
		-- wait
		if ( not StaticPopup_Visible("TRANSMOG_OUTFIT_CHECKING_APPEARANCES") ) then
			WardrobeOutfitFrame:ShowPopup("TRANSMOG_OUTFIT_CHECKING_APPEARANCES", nil, nil, nil, WardrobeOutfitCheckAppearancesFrame);
		end
	elseif ( self.hadInvalidSources ) then
		if ( next(self.sources) ) then
			-- warn
			WardrobeOutfitFrame:ShowPopup("TRANSMOG_OUTFIT_SOME_INVALID_APPEARANCES");
		else
			-- stop
			WardrobeOutfitFrame:ShowPopup("TRANSMOG_OUTFIT_ALL_INVALID_APPEARANCES");
		end
	else
		WardrobeOutfitFrame:ContinueWithSave();
	end
end

function WardrobeOutfitFrameMixin:ContinueWithSave()
	if ( self.name ) then
		WardrobeOutfitFrame:SaveOutfit(self.name);
		WardrobeOutfitFrame:ClosePopups();
	else
		WardrobeOutfitFrame:ShowPopup("NAME_TRANSMOG_OUTFIT");
	end
end
]]

--===================================================================================================================================
WardrobeOutfitButtonMixin = { };

function WardrobeOutfitButtonTemplate_OnClick(self)
	PlaySound("igMainMenuOptionCheckBoxOn");
	WardrobeOutfitFrame:Hide();
	if ( self.outfitID ) then
		WardrobeOutfitFrame.dropDown:SelectOutfit(self.outfitID, true);
	else
		if ( WardrobeTransmogFrame and WardrobeTransmogFrame.OutfitHelpBox:IsShown() ) then
			WardrobeTransmogFrame.OutfitHelpBox:Hide();
			ezCollections:SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_TRANSMOG_OUTFIT_DROPDOWN, true);
		end
		WardrobeOutfitFrame.dropDown:CheckOutfitForSave();
	end
end

--===================================================================================================================================
WardrobeOutfitEditFrameMixin = { };

function WardrobeOutfitEditFrameMixin:ShowForOutfit(outfitID)
	WardrobeOutfitFrame:Hide();
	WardrobeOutfitFrame:ShowPopup(self);
	self.outfitID = outfitID;
	self.EditBox:SetText(C_TransmogCollection.GetOutfitName(outfitID));
end

function WardrobeOutfitEditFrameMixin:OnDelete()
	WardrobeOutfitFrame:Hide();
	local name = C_TransmogCollection.GetOutfitName(self.outfitID);
	WardrobeOutfitFrame:ShowPopup("CONFIRM_DELETE_TRANSMOG_OUTFIT", name, nil,  self.outfitID);
end

function WardrobeOutfitEditFrameMixin:OnAccept()
	if ( not (self.AcceptButton:IsEnabled() == 1) ) then
		return;
	end
	StaticPopupSpecial_Hide(self);
	WardrobeOutfitFrame:NameOutfit(self.EditBox:GetText(), self.outfitID);
end

--===================================================================================================================================
WardrobeOutfitCheckAppearancesMixin = { };

function WardrobeOutfitCheckAppearancesFrame_OnLoad(self)
	Mixin(self, WardrobeOutfitCheckAppearancesMixin);
	self.AnimFrame.Anim:Play();
end

function WardrobeOutfitCheckAppearancesFrame_OnShow(self)
	--ezCollections:RegisterEvent(self, "TRANSMOG_SOURCE_COLLECTABILITY_UPDATE");
end

function WardrobeOutfitCheckAppearancesFrame_OnHide(self)
	--ezCollections:UnregisterEvent(self, "TRANSMOG_SOURCE_COLLECTABILITY_UPDATE");
end

function WardrobeOutfitCheckAppearancesFrame_OnEvent(self, event, sourceID, canCollect)
--[[
	if ( WardrobeOutfitFrame.pendingSources[sourceID] ) then
		if ( canCollect ) then
			local slotID = WardrobeOutfitFrame.pendingSources[sourceID];
			WardrobeOutfitFrame.sources[slotID] = sourceID;
		else
			WardrobeOutfitFrame.hadInvalidSources = true;
		end
		WardrobeOutfitFrame.pendingSources[sourceID] = nil;
		WardrobeOutfitFrame:EvaluateSaveState();
	end
]]
end