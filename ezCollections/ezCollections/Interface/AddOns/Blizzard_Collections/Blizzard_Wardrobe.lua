-- C_TransmogCollection.GetItemInfo(itemID, [itemModID]/itemLink/itemName) = appearanceID, sourceID
-- C_TransmogCollection.GetAllAppearanceSources(appearanceID) = { sourceID } This is cross-class, but no guarantee a source is actually attainable
-- C_TransmogCollection.GetSourceInfo(sourceID) = { data }
-- 15th return of GetItemInfo is expansionID
-- new events: TRANSMOG_COLLECTION_SOURCE_ADDED and TRANSMOG_COLLECTION_SOURCE_REMOVED, parameter is sourceID, can be cross-class (wand unlocked from ensemble while on warrior)

local REMOVE_TRANSMOG_ID = 0;

-- ************************************************************************************************************************************************************
-- **** MAIN **********************************************************************************************************************************************
-- ************************************************************************************************************************************************************

function WardrobeFrame_OnLoad(self)
	Mixin(self, SetShownMixin);
	SetPortraitToTexture(WardrobeFramePortrait, [[Interface\AddOns\ezCollections\Interface\Icons\INV_Arcane_Orb]]);
	WardrobeFrameTitleText:SetText(TRANSMOGRIFY);
	WardrobeFrameTab4.isDisabled = true;
	PanelTemplates_SetNumTabs(self, 6);
	PanelTemplates_SetTab(self, 6);
end

function WardrobeFrame_IsAtTransmogrifier()
	return C_Transmog.IsAtTransmogNPC();
end

-- Taint avoidance
local function UIDropDownMenu_Initialize(frame, initFunction, displayMode, level, menuList)
	ezCollections:UIDropDownMenu_Initialize(frame, initFunction, displayMode, level, menuList);
end

-- ************************************************************************************************************************************************************
-- **** TRANSMOG **********************************************************************************************************************************************
-- ************************************************************************************************************************************************************

function WardrobeTransmogFrame_OnLoad(self)
	self.Model.SlotButtons =
	{
		self.Model.HeadButton,
		self.Model.ShoulderButton,
		self.Model.BackButton,
		self.Model.ChestButton,
		self.Model.ShirtButton,
		self.Model.TabardButton,
		self.Model.WristButton,
		self.Model.HandsButton,
		self.Model.WaistButton,
		self.Model.LegsButton,
		self.Model.FeetButton,
		self.Model.MainHandButton,
		self.Model.SecondaryHandButton,
		self.Model.MainHandEnchantButton,
		self.Model.SecondaryHandEnchantButton,
		self.Model.RangedButton,
	};
	self.SlotButtons = self.Model.SlotButtons;
	for i, button in pairs(self.Model.SlotButtons) do
		Mixin(button, SetEnabledMixin, SetShownMixin);
	end
	Mixin(self.Model.ClearAllPendingButton, SetShownMixin);
	Mixin(self.Inset.BG, SetAtlasMixin);

	local race, fileName = UnitRace("player");
	local atlas = "transmog-background-race-"..fileName;
	self.Inset.BG:SetAtlas(atlas);
	self.Inset.Bg:Hide();

	ezCollections:RegisterEvent(self, "TRANSMOGRIFY_UPDATE");
	ezCollections:RegisterEvent(self, "TRANSMOGRIFY_ITEM_UPDATE");
	ezCollections:RegisterEvent(self, "TRANSMOGRIFY_SUCCESS");
	Mixin(self.ApplyButton, SetEnabledMixin);
	local oTryOn = self.Model.TryOn;
	function self.Model:TryOn(appearanceSourceID, slot, illusionSourceID)
		local enchant = ezCollections:GetEnchantFromScroll(illusionSourceID);
		if enchant then
			oTryOn(self, "|Hitem:"..appearanceSourceID..":"..enchant..":0:0:0:0:0:0:0");
		else
			oTryOn(self, appearanceSourceID);
		end
	end
	function self.Model:UndressSlot(slotID) end
	function self.Model:GetSlotTransmogSources(slotID)
		return self.existingAppearanceSourceID, self.existingIllustionSourceID;
	end
	function self.Model:SetSheathed(state) end
end

function WardrobeTransmogFrame_OnEvent(self, event, ...)
	if ( event == "TRANSMOGRIFY_UPDATE" or event == "TRANSMOGRIFY_ITEM_UPDATE" ) then
		local slotID, transmogType = ...;
		-- play sound?
		local slotButton = WardrobeTransmogFrame_GetSlotButton(slotID, transmogType);
		if ( slotButton ) then
			local isTransmogrified, hasPending, isPendingCollected, canTransmogrify, cannotTransmogrifyReason, hasUndo = C_Transmog.GetSlotInfo(slotID, slotButton.transmogType);
			if ( hasUndo ) then
				PlaySoundFile([[Interface\AddOns\ezCollections\Sounds\UI_VoidStorage_Undo.wav]]);
			elseif ( not hasPending ) then
				if ( slotButton.hadUndo ) then
					PlaySoundFile([[Interface\AddOns\ezCollections\Sounds\UI_VoidStorage_Redo.wav]]);
					slotButton.hadUndo = nil;
				end
			end
			-- specs button tutorial
			if ( hasPending and not hasUndo ) then
				if ( not ezCollections:GetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_TRANSMOG_SPECS_BUTTON) ) and ezCollections.Config.Wardrobe.OutfitsSelectLastUsed then
					self.SpecHelpBox:Show();
				end
			end
		end
		if ( event == "TRANSMOGRIFY_UPDATE" ) then
			StaticPopup_Hide("TRANSMOG_APPLY_WARNING");
		elseif ( event == "TRANSMOGRIFY_ITEM_UPDATE" and self.redoApply ) then
			WardrobeTransmogFrame_ApplyPending(0);
		end
		self.dirty = true;
	elseif ( event == "PLAYER_EQUIPMENT_CHANGED" ) then
		C_TransmogCollection.WipeSearchResults(LE_TRANSMOG_SEARCH_TYPE_ITEMS);
		C_Transmog.ValidateAllPending(true);
	elseif ( event == "TRANSMOGRIFY_SUCCESS" ) then
		local slotID, transmogType = ...;
		local slotButton = WardrobeTransmogFrame_GetSlotButton(slotID, transmogType);
		if ( slotButton ) then
			WardrobeTransmogFrame_AnimateSlotButton(slotButton);
			WardrobeTransmogFrame_UpdateSlotButton(slotButton);
			-- transmogging a weapon might allow/disallow enchants
			if ( slotButton.slot == "MAINHANDSLOT" ) then
				WardrobeTransmogFrame_UpdateSlotButton(WardrobeTransmogFrame.Model.MainHandEnchantButton);
			elseif ( slotButton.slot == "SECONDARYHANDSLOT" ) then
				WardrobeTransmogFrame_UpdateSlotButton(WardrobeTransmogFrame.Model.SecondaryHandEnchantButton);
			end
			WardrobeTransmogFrame_UpdateApplyButton();
		end
	elseif ( event == "UNIT_MODEL_CHANGED" ) then
		local unit = ...;
		if ( unit == "player" and WardrobeTransmogFrame.Model:CanSetUnit("player") ) then
			local hasAlternateForm, inAlternateForm = HasAlternateForm();
			if ( self.inAlternateForm ~= inAlternateForm ) then
				self.inAlternateForm = inAlternateForm;
				WardrobeTransmogFrame.Model:SetUnit("player");
				WardrobeTransmogFrame_Update(self);
			end
		end
	end
end

function WardrobeTransmogFrame_OnShow(self)
	ezCollections:SetCVar("petJournalTab", 6);
	WardrobeFramePortraitButton:UpdateVisibility();
	CollectionsMicroButtonAlert:Hide();
	ezCollectionsMinimapHelpBox:Hide();
	ezCollections:SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_EZCOLLECTIONS_MICRO_BUTTON, true);
	HideUIPanel(CollectionsJournal);
	WardrobeCollectionFrame_SetContainer(WardrobeFrame);

	if ezCollections.Config.Wardrobe.EtherealWindowSound then
		PlaySoundFile([[Interface\AddOns\ezCollections\Sounds\UI_EtherealWindow_Open.wav]]);
	else
		PlaySound("igCharacterInfoOpen");
	end
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
	local hasAlternateForm, inAlternateForm = HasAlternateForm();
	if ( hasAlternateForm ) then
		self:RegisterUnitEvent("UNIT_MODEL_CHANGED", "player");
		self.inAlternateForm = inAlternateForm;
	end
	WardrobeTransmogFrame.Model:SetUnit("player");
	Model_Reset(WardrobeTransmogFrame.Model);

	WardrobeTransmogFrame_Update(self);
	UpdateMicroButtons();
end

function WardrobeTransmogFrame_OnHide(self)
	if ezCollections.Config.Wardrobe.EtherealWindowSound then
		PlaySoundFile([[Interface\AddOns\ezCollections\Sounds\UI_EtherealWindow_Close.wav]]);
	else
		PlaySound("igCharacterInfoClose");
	end
	StaticPopup_Hide("TRANSMOG_APPLY_WARNING");
	self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED");
	self:UnregisterEvent("UNIT_MODEL_CHANGED");
	C_Transmog.Close();
	self.OutfitHelpBox:Hide();
	self.SpecHelpBox:Hide();

	UpdateMicroButtons();
	WardrobeTransmogFrame.Model:SetPosition(0, 0, 0);
	WardrobeTransmogFrame.Model:SetFacing(0);
end

function WardrobeTransmogFrame_OnUpdate(self)
	if ( self.dirty ) then
		self.dirty = nil;
		WardrobeTransmogFrame_Update(self);
	end
end

function WardrobeTransmogFrame_Update()
	WardrobeCollectionFrame.DualWieldResetter:Dress();
	WardrobeTransmogFrame.Model:Undress();
	for i = 1, #WardrobeTransmogFrame.Model.SlotButtons do
		WardrobeTransmogFrame_UpdateSlotButton(WardrobeTransmogFrame.Model.SlotButtons[i]);
	end
	local slot = WardrobeTransmogFrame.selectedSlotButton and WardrobeTransmogFrame.selectedSlotButton.slot;
	if slot == "MAINHANDSLOT" or slot == "SECONDARYHANDSLOT" then
		local mh = select(3, WardrobeCollectionFrame_GetInfoForEquippedSlot("MAINHANDSLOT", LE_TRANSMOG_TYPE_APPEARANCE));
		local oh = select(3, WardrobeCollectionFrame_GetInfoForEquippedSlot("SECONDARYHANDSLOT", LE_TRANSMOG_TYPE_APPEARANCE));
		if ezCollections:AreWeaponsImpossibleToDisplayInPlayerModel(mh, oh) then
			WardrobeTransmogFrame_UpdateWeaponModel(slot);
			WardrobeTransmogFrame.Model.WeaponHandWarning:Show();
		else
			local mhInvType = mh and mh ~= 0 and ezCollections:GetInvType(mh);
			local ohInvType = oh and oh ~= 0 and ezCollections:GetInvType(oh);
			if (mhInvType == 17 or mhInvType == 21) and not ezCollections:CanEquipItemIntoSlot(mh, 17) then
				if ohInvType == 13 then
					-- Workaround a bug with mainhand weapon overwriting offhand
					WardrobeTransmogFrame_UpdateWeaponModel("SECONDARYHANDSLOT");
				end
				-- Workaround a bug with fist weapons in mainhand being overwritten by 2H offhand when with Titan's Grip
				WardrobeTransmogFrame_UpdateWeaponModel("SECONDARYHANDSLOT");
				WardrobeTransmogFrame_UpdateWeaponModel("SECONDARYHANDSLOT");
				WardrobeTransmogFrame_UpdateWeaponModel("MAINHANDSLOT");
			else
				if mhInvType == 13 and oh then
					-- Workaround a bug with first weapon after undress not alternating weapon slot
					WardrobeTransmogFrame_UpdateWeaponModel("MAINHANDSLOT");
				end
				WardrobeTransmogFrame_UpdateWeaponModel("MAINHANDSLOT");
				WardrobeTransmogFrame_UpdateWeaponModel("SECONDARYHANDSLOT");
			end
		end
	elseif slot == "RANGEDSLOT" then
		WardrobeTransmogFrame_UpdateWeaponModel(slot);
	end
	WardrobeTransmogFrame_UpdateApplyButton();
	WardrobeTransmogFrame.OutfitDropDown:UpdateSaveButton();
	
	if ( not WardrobeTransmogFrame.selectedSlotButton or not (WardrobeTransmogFrame.selectedSlotButton:IsEnabled() == 1) ) then
		-- select first valid slot or clear selection
		local validButton;
		for i = 1, #WardrobeTransmogFrame.Model.SlotButtons do
			local button = WardrobeTransmogFrame.Model.SlotButtons[i];
			if ( button:IsEnabled() == 1 and button.transmogType == LE_TRANSMOG_TYPE_APPEARANCE ) then
				validButton = WardrobeTransmogFrame.Model.SlotButtons[i];
				break;
			end
		end
		WardrobeTransmogButton_Select(validButton, false, true);
	else
		WardrobeTransmogButton_Select(WardrobeTransmogFrame.selectedSlotButton, false, true);
	end
end

function WardrobeTransmogFrame_UpdateSlotButton(slotButton)
	local slotID, defaultTexture = GetInventorySlotInfo(slotButton.slot);
	local isTransmogrified, hasPending, isPendingCollected, canTransmogrify, cannotTransmogrifyReason, hasUndo, isHideVisual, texture = C_Transmog.GetSlotInfo(slotID, slotButton.transmogType);
	local hasChange = (hasPending and canTransmogrify) or hasUndo;

	local slotFailReason = C_Transmog.GetSlotFailReason(slotID, slotButton.transmogType);

	if ( slotButton.transmogType == LE_TRANSMOG_TYPE_APPEARANCE ) then
		if ( canTransmogrify or hasChange ) then
			slotButton.Icon:SetTexture(texture);
			slotButton.NoItemTexture:Hide();
		else
			local tag = TRANSMOG_INVALID_CODES[cannotTransmogrifyReason];
			if ( tag  == "NO_ITEM" ) then
				slotButton.Icon:SetTexture(defaultTexture);
			else
				slotButton.Icon:SetTexture(texture);
			end
			slotButton.NoItemTexture:Show();
		end
	else
		-- check for weapons lacking visual attachments
		local correspondingWeaponButton = WardrobeTransmogFrame_GetSlotButton(slotButton.slotID, LE_TRANSMOG_TYPE_APPEARANCE);
		local sourceID = WardrobeTransmogFrame_GetDisplayedSource(correspondingWeaponButton);
		if ( sourceID ~= NO_TRANSMOG_SOURCE_ID and not WardrobeCollectionFrame_CanEnchantSource(sourceID) ) then
			if ( hasPending or hasUndo ) then
				-- clear anything in the enchant slot, otherwise cost and Apply button state will still reflect anything pending
				--C_Transmog.ClearPending(slotButton.slotID, slotButton.transmogType);
			end
			if not isTransmogrified and not hasPending and not hasUndo then
				isTransmogrified = false;	-- handle legacy, this weapon could have had an illusion applied previously
				canTransmogrify = false;
			end
			slotButton.invalidWeapon = true;
		else
			slotButton.invalidWeapon = false;
		end

		if ( hasPending or hasUndo or canTransmogrify ) and not slotButton.invalidWeapon then
			slotButton.Icon:SetTexture(texture or ENCHANT_EMPTY_SLOT_FILEDATAID);
			slotButton.NoItemTexture:Hide();
		else
			slotButton.Icon:SetTexture(0, 0, 0);
			slotButton.NoItemTexture:Show();
		end
	end
	slotButton:SetEnabled(canTransmogrify or hasUndo);
	if slotButton.slot == "RANGEDSLOT" then
		if UnitHasRelicSlot("player") then
			slotButton:Hide();
		else
			slotButton:Show();
		end
	end

	-- show transmogged border if the item is transmogrified and doesn't have a pending transmogrification or is animating
	slotButton.failed = false;
	if ( hasPending ) then
		if ( hasUndo or (isPendingCollected and canTransmogrify and not slotFailReason and not slotButton.invalidWeapon) ) then
			WardrobeTransmogButton_SetStatusBorder(slotButton, "PINK");
		else
			WardrobeTransmogButton_SetStatusBorder(slotButton, "RED");
			slotButton.failed = true;
		end
	else
		if ( isTransmogrified and not hasChange and not slotButton.AnimFrame:IsShown() ) then
			WardrobeTransmogButton_SetStatusBorder(slotButton, "PINK");
		else
			WardrobeTransmogButton_SetStatusBorder(slotButton, "NONE");
		end
	end

	-- show ants frame is the item has a pending transmogrification and is not animating
	if ( hasChange and (hasUndo or isPendingCollected and not slotButton.invalidWeapon) and not slotButton.AnimFrame:IsShown() ) then
		slotButton.PendingFrame:Show();
		if slotFailReason then
			slotButton.PendingFrame.Glow:SetVertexColor(1, 0, 0);
			slotButton.PendingFrame.Ants:SetTexture([[Interface\AddOns\ezCollections\Textures\RedIconAlertAnts]]);
			slotButton.failed = true;
		else
			slotButton.PendingFrame.Glow:SetVertexColor(1, 1, 1);
			slotButton.PendingFrame.Ants:SetTexture([[Interface\AddOns\ezCollections\Interface\Transmogrify\PurpleIconAlertAnts]]);
		end
		if ( hasUndo ) then
			slotButton.PendingFrame.Undo:Show();
		else
			slotButton.PendingFrame.Undo:Hide();
		end
	else
		slotButton.PendingFrame:Hide();
	end

	if ( isHideVisual and not hasUndo and not slotButton.invalidWeapon ) then
		if ( slotButton.HiddenVisualIcon ) then
			slotButton.HiddenVisualCover:Show();
			slotButton.HiddenVisualIcon:Show();
		end
		local baseTexture;
		if slotButton.transmogType == LE_TRANSMOG_TYPE_APPEARANCE then
			baseTexture = (ezCollectionsGetInventoryItemTexture or GetInventoryItemTexture)("player", slotID);
		else
			baseTexture = ENCHANT_EMPTY_SLOT_FILEDATAID;
		end
		slotButton.Icon:SetTexture(baseTexture);
	else
		if ( slotButton.HiddenVisualIcon ) then
			slotButton.HiddenVisualCover:Hide();
			slotButton.HiddenVisualIcon:Hide();
		end
	end

	local showModel = (slotButton.transmogType == LE_TRANSMOG_TYPE_APPEARANCE);
	if ( slotButton.slot == "MAINHANDSLOT" or slotButton.slot == "SECONDARYHANDSLOT" or slotButton.slot == "RANGEDSLOT" ) then
		-- weapons get done in WardrobeTransmogFrame_UpdateWeaponModel to package item and enchant together
		showModel = false;
	end
	if ( showModel ) then
		local sourceID = WardrobeTransmogFrame_GetDisplayedSource(slotButton);
		if ( sourceID == NO_TRANSMOG_SOURCE_ID ) then
			WardrobeTransmogFrame.Model:UndressSlot(slotID);			
		else
			if slotButton.failed and WardrobeTransmogFrame.hideFailedSlots then
				local baseSourceID, _, appliedSourceID = C_Transmog.GetSlotVisualInfo(GetInventorySlotInfo(slotButton.slot), slotButton.transmogType);
				sourceID = appliedSourceID ~= 0 and appliedSourceID or baseSourceID;
			end
			-- only update if different
			local existingAppearanceSourceID = WardrobeTransmogFrame.Model:GetSlotTransmogSources(slotID);
			if ( existingAppearanceSourceID ~= sourceID ) then
				WardrobeTransmogFrame.Model:TryOn(sourceID);
			end
		end
	end
end

function WardrobeTransmogFrame_UpdateWeaponModel(slot)
	local weaponSlotButton, enchantSlotButton;
	if ( slot == "MAINHANDSLOT" ) then
		weaponSlotButton = WardrobeTransmogFrame.Model.MainHandButton;
		enchantSlotButton = WardrobeTransmogFrame.Model.MainHandEnchantButton;
	elseif slot == "SECONDARYHANDSLOT" then
		weaponSlotButton = WardrobeTransmogFrame.Model.SecondaryHandButton;
		enchantSlotButton = WardrobeTransmogFrame.Model.SecondaryHandEnchantButton;
	elseif slot == "RANGEDSLOT" then
		weaponSlotButton = WardrobeTransmogFrame.Model.RangedButton;
	end
	local slotID = GetInventorySlotInfo(slot);
	local appearanceSourceID = WardrobeTransmogFrame_GetDisplayedSource(weaponSlotButton);
	if ( appearanceSourceID ~= NO_TRANSMOG_SOURCE_ID ) then
		local illusionSourceID = enchantSlotButton and WardrobeTransmogFrame_GetDisplayedSource(enchantSlotButton);
		if WardrobeTransmogFrame.hideFailedSlots then
			if weaponSlotButton.failed then
				local baseSourceID, _, appliedSourceID = C_Transmog.GetSlotVisualInfo(GetInventorySlotInfo(weaponSlotButton.slot), weaponSlotButton.transmogType);
				appearanceSourceID = appliedSourceID ~= 0 and appliedSourceID or baseSourceID;
			end
			if enchantSlotButton and enchantSlotButton.failed then
				local baseSourceID, _, appliedSourceID = C_Transmog.GetSlotVisualInfo(GetInventorySlotInfo(enchantSlotButton.slot), enchantSlotButton.transmogType);
				illusionSourceID = appliedSourceID ~= 0 and appliedSourceID or baseSourceID;
			end
			if appearanceSourceID == NO_TRANSMOG_SOURCE_ID then
				return;
			end
		end
		local categoryID = C_TransmogCollection.GetAppearanceSourceInfo(appearanceSourceID);
		-- don't specify a slot for ranged weapons
		if ( WardrobeUtils_IsCategoryRanged(categoryID) ) then
			slot = nil;
		end
		-- check existing equipped on model. we don't want to update it if the same because the hand will open/close.
		local existingAppearanceSourceID, existingIllustionSourceID = WardrobeTransmogFrame.Model:GetSlotTransmogSources(slotID);
		--if ( existingAppearanceSourceID ~= appearanceSourceID or existingIllustionSourceID ~= illusionSourceID ) then
			WardrobeTransmogFrame.Model:TryOn(appearanceSourceID, slot, illusionSourceID);
		--end
	end	
end

function WardrobeTransmogFrame_GetDisplayedSource(slotButton)
	local baseSourceID, baseVisualID, appliedSourceID, appliedVisualID, pendingSourceID, pendingVisualID, hasPendingUndo = C_Transmog.GetSlotVisualInfo(GetInventorySlotInfo(slotButton.slot), slotButton.transmogType);
	if ( pendingSourceID ~= REMOVE_TRANSMOG_ID ) then
		return pendingSourceID;
	elseif ( hasPendingUndo or appliedSourceID == NO_TRANSMOG_SOURCE_ID ) then
		return baseSourceID;
	else
		return appliedSourceID;
	end	
end

function WardrobeTransmogFrame_AnimateSlotButton(slotButton)
	-- don't do anything if this button is already animating;
	if ( slotButton.AnimFrame:IsShown() ) then
		return;
	end
	local isTransmogrified = C_Transmog.GetSlotInfo(slotButton.slotID, slotButton.transmogType);
	if ( isTransmogrified ) then
		slotButton.AnimFrame.Transition:Show();
	else
		slotButton.AnimFrame.Transition:Hide();
	end
	slotButton.AnimFrame:Show();
	slotButton.AnimFrame.Anim:Play();
	slotButton.AnimFrame.Glow.Anim:Play();
	slotButton.AnimFrame.Transition.Anim:Play();
	slotButton.AnimFrame.OuterGlow.Anim:Play();
end

function WardrobeTransmogFrame_UpdateApplyButton()
	local cost, numChanges, tokens = C_Transmog.GetCost();
	WardrobeTransmogTokenFrame:Hide();
	if not cost and not tokens then
		local old = WardrobeTransmogMoneyFrame.info.showSmallerCoins;
		WardrobeTransmogMoneyFrame.info.showSmallerCoins = nil;
		MoneyFrame_Update("WardrobeTransmogMoneyFrame", 0, false);
		WardrobeTransmogMoneyFrame.info.showSmallerCoins = old;
		WardrobeTransmogFrame.ApplyButton:Disable();
		WardrobeTransmogFrame.Model.ClearAllPendingButton:SetShown(numChanges > 0);
		return;
	end
	WardrobeTransmogMoneyFrame.info.showSmallerCoins = cost == 0 and "Backpack" or nil;
	local canApply;
	if ( cost > GetMoney() ) then
		SetMoneyFrameColor("WardrobeTransmogMoneyFrame", "red");
	else
		SetMoneyFrameColor("WardrobeTransmogMoneyFrame");
		if (numChanges > 0 ) then
			canApply = true;
		end
	end
	if ( StaticPopup_FindVisible("TRANSMOG_APPLY_WARNING") ) then
		canApply = false;
	end
	MoneyFrame_Update("WardrobeTransmogMoneyFrame", cost, true);	-- always show 0 copper
	if tokens and tokens > 0 and ezCollections.Token then
		AltCurrencyFrame_Update("WardrobeTransmogTokenFrame", select(10, GetItemInfo(ezCollections.Token)), tokens);
		WardrobeTransmogTokenFrame:Show();
		if tokens > GetItemCount(ezCollections.Token) then
			WardrobeTransmogTokenFrame:SetNormalFontObject(NumberFontNormalRightRed);
			if numChanges > 0 then
				canApply = false;
			end
		else
			WardrobeTransmogTokenFrame:SetNormalFontObject(NumberFontNormalRight);
		end
	end
	WardrobeTransmogFrame.ApplyButton:SetEnabled(canApply);
	WardrobeTransmogFrame.Model.ClearAllPendingButton:SetShown(numChanges > 0);
end

function WardrobeTransmogFrame_GetSlotButton(slotID, transmogType)
	for i = 1, #WardrobeTransmogFrame.Model.SlotButtons do
		local slotButton = WardrobeTransmogFrame.Model.SlotButtons[i];
		if ( slotButton.slotID == slotID and slotButton.transmogType == transmogType ) then
			return slotButton;
		end
	end
end

function WardrobeTransmogFrame_ApplyPending(lastAcceptedWarningIndex)
	if ( lastAcceptedWarningIndex == 0 or not WardrobeTransmogFrame.applyWarningsTable ) then
		WardrobeTransmogFrame.applyWarningsTable = C_Transmog.GetApplyWarnings();
	end
	WardrobeTransmogFrame.redoApply = nil;
	if ( WardrobeTransmogFrame.applyWarningsTable and lastAcceptedWarningIndex < #WardrobeTransmogFrame.applyWarningsTable ) then
		lastAcceptedWarningIndex = lastAcceptedWarningIndex + 1;
		local data = {
			["link"] = WardrobeTransmogFrame.applyWarningsTable[lastAcceptedWarningIndex].itemLink,
			["useLinkForItemInfo"] = true,
			["warningIndex"] = lastAcceptedWarningIndex;
		};
		StaticPopup_Show("TRANSMOG_APPLY_WARNING", WardrobeTransmogFrame.applyWarningsTable[lastAcceptedWarningIndex].text, nil, data);
		WardrobeTransmogFrame_UpdateApplyButton();
		-- return true to keep static popup open when chaining warnings
		return true;
	else
		local success = C_Transmog.ApplyAllPending(ezCollections:GetCVarBool("transmogCurrentSpecOnly"));
		if ( success ) then
			WardrobeTransmogFrame.applyWarningsTable = nil;
			-- outfit tutorial
			if ( not ezCollections:GetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_TRANSMOG_OUTFIT_DROPDOWN) ) then
				local outfits = C_TransmogCollection.GetOutfits();
				if ( #outfits == 0 ) then
					WardrobeTransmogFrame.OutfitHelpBox:Show();
				end
			end
		else
			-- it's retrieving item info
			WardrobeTransmogFrame.redoApply = true;
		end
		return false;
	end
end

function WardrobeTransmogFrame_OnTransmogApplied()
	PlaySoundFile([[Interface\AddOns\ezCollections\Sounds\UI_Transmogrify_Apply.wav]]);
	if WardrobeOutfitDropDown.selectedOutfitID and WardrobeOutfitDropDown:IsOutfitDressed() then
		WardrobeTransmogFrame.OutfitDropDown:OnOutfitApplied(WardrobeOutfitDropDown.selectedOutfitID);
	end
end

WardrobeOutfitMixin = { };

function WardrobeOutfitMixin:OnOutfitApplied(outfitID)
	local value = outfitID or "";
	if ezCollections:GetCVarBool("transmogCurrentSpecOnly") then
		local specIndex = GetSpecialization();
		ezCollections:SetCVar("lastTransmogOutfitIDSpec"..specIndex, value);
	else
		for specIndex = 1, GetNumSpecializations() do
			ezCollections:SetCVar("lastTransmogOutfitIDSpec"..specIndex, value);
		end
	end
end

function WardrobeOutfitMixin:LoadOutfit(outfitID)
	if ( not outfitID ) then
		return;
	end
	C_Transmog.LoadOutfit(outfitID);
end

function WardrobeOutfitMixin:GetSlotSourceID(slot, transmogType)
	local slotID = GetInventorySlotInfo(slot);
	local isTransmogrified, hasPending, isPendingCollected, canTransmogrify, cannotTransmogrifyReason, hasUndo = C_Transmog.GetSlotInfo(slotID, transmogType);
	if ( not canTransmogrify and not hasUndo ) then
		return NO_TRANSMOG_SOURCE_ID;
	end

	local _, _, sourceID = WardrobeCollectionFrame_GetInfoForEquippedSlot(slot, transmogType);
	return sourceID;
end

function WardrobeOutfitMixin:OnOutfitSaved(outfitID)
	local cost, numChanges = C_Transmog.GetCost();
	if numChanges == 0 then
		self:OnOutfitApplied(outfitID);
	end
end

function WardrobeOutfitMixin:OnSelectOutfit(outfitID)
	-- outfitID can be 0, so use empty string for none
	local value = outfitID or "";
	for specIndex = 1, GetNumSpecializations() do
		if ezCollections:GetCVar("lastTransmogOutfitIDSpec"..specIndex) == "" then
			ezCollections:SetCVar("lastTransmogOutfitIDSpec"..specIndex, value);
		end
	end
end

function WardrobeOutfitMixin:GetLastOutfitID()
	if not ezCollections.Config.Wardrobe.OutfitsSelectLastUsed then return; end
	local specIndex = GetSpecialization();
	return tonumber(ezCollections:GetCVar("lastTransmogOutfitIDSpec"..specIndex));
end

-- ***** BUTTONS

function WardrobeTransmogButton_OnLoad(self)
	Mixin(self.StatusBorder, SetAtlasMixin);
	self.transmogType = self:GetName():find("Enchant") and LE_TRANSMOG_TYPE_ILLUSION or LE_TRANSMOG_TYPE_APPEARANCE;
	self.slot = self:GetName():gsub("WardrobeTransmogFrameModel", ""):gsub("Button", ""):gsub("Enchant", ""):upper().."SLOT";
	local slotID, textureName = GetInventorySlotInfo(self.slot);
	self.slotID = slotID;
	if ( self.transmogType == LE_TRANSMOG_TYPE_APPEARANCE ) then
		self.Icon:SetTexture(textureName);
	else
		self.Icon:SetTexture(ENCHANT_EMPTY_SLOT_FILEDATAID);
	end
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
end

function WardrobeTransmogButton_OnClick(self, button)
	local slotID = GetInventorySlotInfo(self.slot);
	local isTransmogrified, hasPending, isPendingCollected, canTransmogrify, cannotTransmogrifyReason, hasUndo = C_Transmog.GetSlotInfo(slotID, self.transmogType);
	-- save for sound to play on TRANSMOGRIFY_UPDATE event
	self.hadUndo = hasUndo;
	if ( button == "RightButton" ) then
		if ( hasPending or hasUndo ) then
			PlaySoundFile([[Interface\AddOns\ezCollections\Sounds\UI_Reforging_Restore.wav]]);
			C_Transmog.ClearPending(slotID, self.transmogType);
		elseif ( isTransmogrified ) then
			PlaySoundFile([[Interface\AddOns\ezCollections\Sounds\UI_Reforging_Restore.wav]]);
			C_Transmog.SetPending(slotID, self.transmogType, 0);
			WardrobeTransmogButton_Select(self, true);
		end
	else
		PlaySound("igSpellBookSpellIconPickup");
		WardrobeTransmogButton_Select(self, true);
	end
	if ( self.UndoButton ) then
		self.UndoButton:Hide();
	end
	WardrobeTransmogButton_OnEnter(self);
end

function WardrobeTransmogButton_OnEnter(self)
	local slotID = GetInventorySlotInfo(self.slot);
	local isTransmogrified, hasPending, isPendingCollected, canTransmogrify, cannotTransmogrifyReason, hasUndo = C_Transmog.GetSlotInfo(slotID, self.transmogType);

	local slotFailReason = C_Transmog.GetSlotFailReason(slotID, self.transmogType);

	local anchor, x, y;
	if self.slot == "HEADSLOT" or self.slot == "SHOULDERSLOT" or self.slot == "BACKSLOT" or self.slot == "CHESTSLOT" or self.slot == "TABARDSLOT" or self.slot == "SHIRTSLOT" or self.slot == "WRISTSLOT" then
		anchor, x, y = "ANCHOR_LEFT", -14, 0;
	elseif self.slot == "HANDSSLOT" or self.slot == "WAISTSLOT" or self.slot == "LEGSSLOT" or self.slot == "FEETSLOT" then
		anchor, x, y = "ANCHOR_RIGHT", 14, 0;
	elseif self.slot == "MAINHANDSLOT" then
		anchor, x, y = "ANCHOR_BOTTOMLEFT", -14, 0;
	elseif self.slot == "SECONDARYHANDSLOT" or self.slot == "RANGEDSLOT" then
		anchor, x, y = "ANCHOR_BOTTOMRIGHT", 14, 0;
	end
	if WardrobeFrame:GetAttribute("UIPanelLayout-enabled") then
		-- No space with standard layout, fallback to (semi-)blizzlike behavior
		if anchor == "ANCHOR_LEFT" then
			anchor, x, y = "ANCHOR_RIGHT", 14, 0;
		elseif anchor == "ANCHOR_BOTTOMLEFT" then
			anchor, x, y = "ANCHOR_BOTTOMRIGHT", 14, 0;
		end
	end

	if ( self.transmogType == LE_TRANSMOG_TYPE_ILLUSION ) then
		GameTooltip:SetOwner(self, anchor, 0, 0);
		GameTooltip:SetText(WEAPON_ENCHANTMENT);
		local baseSourceID, baseVisualID, appliedSourceID, appliedVisualID, pendingSourceID, pendingVisualID, hasPendingUndo = C_Transmog.GetSlotVisualInfo(slotID, LE_TRANSMOG_TYPE_ILLUSION);
		if ( self.invalidWeapon ) then
			GameTooltip:AddLine(TRANSMOGRIFY_ILLUSION_INVALID_ITEM, TRANSMOGRIFY_FONT_COLOR.r, TRANSMOGRIFY_FONT_COLOR.g, TRANSMOGRIFY_FONT_COLOR.b, true);
		elseif slotFailReason then
			local _, name = C_TransmogCollection.GetIllusionSourceInfo(pendingSourceID);
			GameTooltip:AddLine(name, TRANSMOGRIFY_FONT_COLOR.r, TRANSMOGRIFY_FONT_COLOR.g, TRANSMOGRIFY_FONT_COLOR.b);
			GameTooltip:AddLine(slotFailReason, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true);
			GameTooltip:Show();
		elseif ( hasPending or hasUndo or canTransmogrify ) then
			if ( baseSourceID > 0 ) then
				local _, name = C_TransmogCollection.GetIllusionSourceInfo(baseSourceID);
				GameTooltip:AddLine(name, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);
			end
			if ( hasUndo ) then
				GameTooltip:AddLine(TRANSMOGRIFY_TOOLTIP_REVERT, TRANSMOGRIFY_FONT_COLOR.r, TRANSMOGRIFY_FONT_COLOR.g, TRANSMOGRIFY_FONT_COLOR.b);
			elseif ( pendingSourceID > 0 ) then
				GameTooltip:AddLine(WILL_BE_TRANSMOGRIFIED_HEADER, TRANSMOGRIFY_FONT_COLOR.r, TRANSMOGRIFY_FONT_COLOR.g, TRANSMOGRIFY_FONT_COLOR.b);
				local _, name = C_TransmogCollection.GetIllusionSourceInfo(pendingSourceID);
				GameTooltip:AddLine(name, TRANSMOGRIFY_FONT_COLOR.r, TRANSMOGRIFY_FONT_COLOR.g, TRANSMOGRIFY_FONT_COLOR.b);
			elseif ( appliedSourceID > 0 ) then
				GameTooltip:AddLine(TRANSMOGRIFIED_HEADER, TRANSMOGRIFY_FONT_COLOR.r, TRANSMOGRIFY_FONT_COLOR.g, TRANSMOGRIFY_FONT_COLOR.b);
				local _, name = C_TransmogCollection.GetIllusionSourceInfo(appliedSourceID);
				GameTooltip:AddLine(name, TRANSMOGRIFY_FONT_COLOR.r, TRANSMOGRIFY_FONT_COLOR.g, TRANSMOGRIFY_FONT_COLOR.b);
			end
		else
			local itemBaseSourceID = C_Transmog.GetSlotVisualInfo(slotID, LE_TRANSMOG_TYPE_APPEARANCE);
			if ( itemBaseSourceID == NO_TRANSMOG_SOURCE_ID ) then
				GameTooltip:AddLine(TRANSMOGRIFY_INVALID_NO_ITEM, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true);
			else
				GameTooltip:AddLine(TRANSMOGRIFY_ILLUSION_INVALID_ITEM, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true);
			end
		end
		GameTooltip:Show();
	else
		if ( self.UndoButton and isTransmogrified and not ( hasPending or hasUndo ) ) then
			self.UndoButton:Show();
		end
		GameTooltip:SetOwner(self, anchor, x, y);
		if ( hasPending and not hasUndo and not isPendingCollected ) then
			GameTooltip:SetText(_G[self.slot]);
			GameTooltip:AddLine(TRANSMOGRIFY_STYLE_UNCOLLECTED, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true);
			GameTooltip:Show();
		elseif ( not canTransmogrify and not hasUndo ) then
			GameTooltip:SetText(_G[self.slot]);
			local tag = TRANSMOG_INVALID_CODES[cannotTransmogrifyReason];
			local errorMsg;
			if ( tag == "CANNOT_USE" ) then
				local errorCode, errorString = C_Transmog.GetSlotUseError(slotID, self.transmogType);
				errorMsg = errorString;
			else
				errorMsg = tag and _G["TRANSMOGRIFY_INVALID_"..tag];
			end
			if ( errorMsg ) then
				GameTooltip:AddLine(errorMsg, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true);
			end
			GameTooltip:Show();
		elseif slotFailReason then
			local baseSourceID, baseVisualID, appliedSourceID, appliedVisualID, pendingSourceID, pendingVisualID, hasPendingUndo = C_Transmog.GetSlotVisualInfo(slotID, self.transmogType);
			local name, _, quality = GetItemInfo(pendingSourceID);
			if name and quality then
				local r, g, b = GetItemQualityColor(quality);
				GameTooltip:SetText(name, r, g, b);
			else
				GameTooltip:SetText(RETRIEVING_ITEM_INFO, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
			end
			GameTooltip:AddLine(slotFailReason, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true);
			GameTooltip:Show();
		elseif ( hasPending or hasUndo ) then
			GameTooltip:SetTransmogrifyItem(slotID);
		elseif self.transmogType == LE_TRANSMOG_TYPE_APPEARANCE and select(2, C_Transmog.GetSlotInfo(slotID, LE_TRANSMOG_TYPE_ILLUSION)) then
			GameTooltip:SetTransmogrifyItem(slotID);
		else
			GameTooltip:SetInventoryItem("player", slotID);
		end
	end
	WardrobeTransmogFrame.Model.controlFrame:Show();
end

function WardrobeTransmogButton_OnLeave(self)
	if ( self.UndoButton and not self.UndoButton:IsMouseOver() ) then
		self.UndoButton:Hide();
	end
	WardrobeTransmogFrame.Model.controlFrame:Hide();
	GameTooltip:Hide();
	WardrobeCollectionFrame:EnableKeyboard(false);
end

function WardrobeTransmogButton_Select(button, fromOnClick, noUpdate)
	local oldSlot = WardrobeTransmogFrame.selectedSlotButton and WardrobeTransmogFrame.selectedSlotButton.slot;
	if ( WardrobeTransmogFrame.selectedSlotButton ) then
		WardrobeTransmogFrame.selectedSlotButton.SelectedTexture:Hide();
	end
	WardrobeTransmogFrame.selectedSlotButton = button;
	if ( button ) then
		button.SelectedTexture:Show();
		if (fromOnClick and WardrobeCollectionFrame.activeFrame ~= WardrobeCollectionFrame.ItemsCollectionFrame) then
			WardrobeCollectionFrame_ClickTab(WardrobeCollectionFrame.ItemsTab);
		end
		if ( WardrobeCollectionFrame.activeFrame == WardrobeCollectionFrame.ItemsCollectionFrame ) then
			local _, _, selectedSourceID = WardrobeCollectionFrame_GetInfoForEquippedSlot(button.slot, button.transmogType);
			local forceGo = (button.transmogType == LE_TRANSMOG_TYPE_ILLUSION);
			WardrobeCollectionFrame.ItemsCollectionFrame:GoToSourceID(selectedSourceID, button.slot, button.transmogType, forceGo);
			WardrobeCollectionFrame.ItemsCollectionFrame:SetTransmogrifierAppearancesShown(true);
		end
	else
		WardrobeCollectionFrame.ItemsCollectionFrame:SetTransmogrifierAppearancesShown(false);
	end

	if not noUpdate and (button.slot == "MAINHANDSLOT" or button.slot == "SECONDARYHANDSLOT" or button.slot == "RANGEDSLOT" or oldSlot == "MAINHANDSLOT" or oldSlot == "SECONDARYHANDSLOT" or oldSlot == "RANGEDSLOT") then
		WardrobeTransmogFrame_Update();
	end
end

function WardrobeTransmogButton_SetStatusBorder(self, status)
	local atlas;
	if ( status == "RED" ) then
		if ( self.transmogType == LE_TRANSMOG_TYPE_APPEARANCE ) then
			atlas = "transmog-frame-red";
		else
			atlas = "transmog-frame-small-red";
		end
	elseif ( status == "PINK" ) then
		if ( self.transmogType == LE_TRANSMOG_TYPE_APPEARANCE ) then
			atlas = "transmog-frame-pink";
		else
			atlas = "transmog-frame-small-pink";
		end	
	end
	if ( atlas ) then
		self.StatusBorder:Show();
		self.StatusBorder:SetAtlas(atlas, true);
	else
		self.StatusBorder:Hide();
	end
end

-- ************************************************************************************************************************************************************
-- **** COLLECTION ********************************************************************************************************************************************
-- ************************************************************************************************************************************************************

local CURRENT_PAGE = 1;
local WARDROBE_NUM_ROWS = 3;
local WARDROBE_NUM_COLS = 6;
local WARDROBE_PAGE_SIZE = WARDROBE_NUM_ROWS * WARDROBE_NUM_COLS;
local MAIN_HAND_INV_TYPE = 21;
local OFF_HAND_INV_TYPE = 22;
local RANGED_INV_TYPE = 15;
local TAB_ITEMS = 1;
local TAB_SETS = 2;
local TABS_MAX_WIDTH = 185;

local WARDROBE_MODEL_SETUP = {
	["HEADSLOT"] 		= { useTransmogSkin = false, slots = { CHESTSLOT = true,  HANDSSLOT = false, LEGSSLOT = false, FEETSLOT = false, HEADSLOT = false } },
	["SHOULDERSLOT"]	= { useTransmogSkin = true,  slots = { CHESTSLOT = false, HANDSSLOT = false, LEGSSLOT = false, FEETSLOT = false, HEADSLOT = true } },
	["BACKSLOT"]		= { useTransmogSkin = true,  slots = { CHESTSLOT = false, HANDSSLOT = false, LEGSSLOT = false, FEETSLOT = false, HEADSLOT = true } },
	["CHESTSLOT"]		= { useTransmogSkin = true,  slots = { CHESTSLOT = false, HANDSSLOT = false, LEGSSLOT = false, FEETSLOT = false, HEADSLOT = true } },
	["TABARDSLOT"]		= { useTransmogSkin = true,  slots = { CHESTSLOT = false, HANDSSLOT = false, LEGSSLOT = false, FEETSLOT = false, HEADSLOT = true } },
	["SHIRTSLOT"]		= { useTransmogSkin = true,  slots = { CHESTSLOT = false, HANDSSLOT = false, LEGSSLOT = false, FEETSLOT = false, HEADSLOT = true } },
	["WRISTSLOT"]		= { useTransmogSkin = true,  slots = { CHESTSLOT = false, HANDSSLOT = false, LEGSSLOT = false, FEETSLOT = false, HEADSLOT = true } },
	["HANDSSLOT"]		= { useTransmogSkin = false, slots = { CHESTSLOT = true,  HANDSSLOT = false, LEGSSLOT = true,  FEETSLOT = true, HEADSLOT = true } },
	["WAISTSLOT"]		= { useTransmogSkin = true,  slots = { CHESTSLOT = false, HANDSSLOT = false, LEGSSLOT = false, FEETSLOT = false, HEADSLOT = true } },
	["LEGSSLOT"]		= { useTransmogSkin = true,  slots = { CHESTSLOT = false, HANDSSLOT = false, LEGSSLOT = false, FEETSLOT = false, HEADSLOT = true } },
	["FEETSLOT"]		= { useTransmogSkin = false, slots = { CHESTSLOT = true, HANDSSLOT = true, LEGSSLOT = true,  FEETSLOT = false, HEADSLOT = true } },	
}

local WARDROBE_MODEL_SETUP_GEAR = {
	["CHESTSLOT"] = 78420,
	["LEGSSLOT"] = 78425,
	["FEETSLOT"] = 78427,
	["HANDSSLOT"] = 78426,
	["HEADSLOT"] = 78416,
}

function WardrobeCollectionFrame_SetContainer(parent)
	local collectionFrame = WardrobeCollectionFrame;
	collectionFrame:SetParent(parent);
	collectionFrame:ClearAllPoints();
	if ( parent == CollectionsJournal ) then
		collectionFrame:SetPoint("TOPLEFT", CollectionsJournal);
		collectionFrame:SetPoint("BOTTOMRIGHT", CollectionsJournal);
		collectionFrame.ItemsCollectionFrame.ModelR1C1:SetPoint("TOP", -238.5, -85);
		collectionFrame.ItemsCollectionFrame.SlotsFrame:Show();
		collectionFrame.ItemsCollectionFrame.BGCornerTopLeft:Hide();
		collectionFrame.ItemsCollectionFrame.BGCornerTopRight:Hide();
		collectionFrame.ItemsCollectionFrame.WeaponDropDown:SetPoint("TOPRIGHT", -6, -22);
		collectionFrame.ItemsCollectionFrame.NoValidItemsLabel:Hide();
		--collectionFrame.FilterButton:SetText(FILTER);
		collectionFrame.ItemsTab:SetPoint("TOPLEFT", 58, -28);
		WardrobeCollectionFrame_SetTab(collectionFrame.selectedCollectionTab);
	elseif ( parent == WardrobeFrame ) then
		collectionFrame:SetPoint("TOPRIGHT", 0, 0);
		collectionFrame:SetSize(662, 606);
		collectionFrame.ItemsCollectionFrame.ModelR1C1:SetPoint("TOP", -235, -71);
		collectionFrame.ItemsCollectionFrame.SlotsFrame:Hide();
		collectionFrame.ItemsCollectionFrame.BGCornerTopLeft:Show();
		collectionFrame.ItemsCollectionFrame.BGCornerTopRight:Show();
		collectionFrame.ItemsCollectionFrame.WeaponDropDown:SetPoint("TOPRIGHT", -32, -25);
		--collectionFrame.FilterButton:SetText(SOURCES);
		collectionFrame.ItemsTab:SetPoint("TOPLEFT", 8, -28);
		WardrobeCollectionFrame_SetTab(collectionFrame.selectedTransmogTab);
	end
	-- changing the parent of a frame resets frame stratas and levels of all children
	collectionFrame.ItemsCollectionFrame.HelpBox:SetFrameStrata("DIALOG");
	collectionFrame:Show();
end

function WardrobeCollectionFrame_ClickTab(tab)
	WardrobeCollectionFrame_SetTab(tab:GetID());
	PanelTemplates_ResizeTabsToFit(WardrobeCollectionFrame, TABS_MAX_WIDTH);
	PlaySound("igMainMenuOptionCheckBoxOn");
end

function WardrobeCollectionFrame_SetTab(tabID)
	CloseMenus();
	PanelTemplates_SetTab(WardrobeCollectionFrame, tabID);
	local atTransmogrifier = WardrobeFrame_IsAtTransmogrifier();
	if ( atTransmogrifier ) then
		WardrobeCollectionFrame.selectedTransmogTab = tabID;
	else
		WardrobeCollectionFrame.selectedCollectionTab = tabID;
	end
	if ( tabID == TAB_ITEMS ) then
		WardrobeCollectionFrame.activeFrame = WardrobeCollectionFrame.ItemsCollectionFrame;
		WardrobeCollectionFrame.ItemsCollectionFrame:Show();
		WardrobeCollectionFrame.SetsCollectionFrame:Hide();
		WardrobeCollectionFrame.SetsTransmogFrame:Hide();
		WardrobeCollectionFrame.searchBox:ClearAllPoints();
		WardrobeCollectionFrame.searchBox:SetPoint("TOPRIGHT", -107, -35);
		WardrobeCollectionFrame.searchBox:SetWidth(115);
		WardrobeCollectionFrame.searchBox:SetEnabled(true);
		WardrobeCollectionFrame.searchBox:SetFrameLevel(WardrobeCollectionFrame:GetFrameLevel() + 1);
		WardrobeCollectionFrame.FilterButton:Show();
		WardrobeCollectionFrame.FilterButton:SetEnabled(true);
		--WardrobeCollectionFrame.FilterButton:SetText(atTransmogrifier and SOURCES or FILTER);
		WardrobeCollectionFrame.FilterButton:SetFrameLevel(WardrobeCollectionFrame:GetFrameLevel() + 1);
	elseif ( tabID == TAB_SETS ) then
		WardrobeCollectionFrame.ItemsCollectionFrame:Hide();
		WardrobeCollectionFrame.searchBox:ClearAllPoints();
		if ( atTransmogrifier )  then
			WardrobeCollectionFrame.activeFrame = WardrobeCollectionFrame.SetsTransmogFrame;
			WardrobeCollectionFrame.searchBox:SetPoint("TOPRIGHT", -107, -35);
			WardrobeCollectionFrame.searchBox:SetWidth(115);
			WardrobeCollectionFrame.searchBox:SetFrameLevel(WardrobeCollectionFrame:GetFrameLevel() + 1);
			WardrobeCollectionFrame.FilterButton:Show();
			WardrobeCollectionFrame.FilterButton:SetEnabled(true);
			--WardrobeCollectionFrame.FilterButton:SetText(FILTER);
			WardrobeCollectionFrame.FilterButton:SetFrameLevel(WardrobeCollectionFrame:GetFrameLevel() + 1);
		else
			WardrobeCollectionFrame.activeFrame = WardrobeCollectionFrame.SetsCollectionFrame;
			WardrobeCollectionFrame.searchBox:SetPoint("TOPLEFT", 19, -69);
			WardrobeCollectionFrame.searchBox:SetWidth(145);
			WardrobeCollectionFrame.searchBox:SetFrameLevel(WardrobeCollectionFrame.SetsCollectionFrame.LeftInset:GetFrameLevel() + 1);
			WardrobeCollectionFrame.FilterButton:Show();
			WardrobeCollectionFrame.FilterButton:SetEnabled(true);
			--WardrobeCollectionFrame.FilterButton:SetText(FILTER);
			WardrobeCollectionFrame.FilterButton:SetFrameLevel(WardrobeCollectionFrame.SetsCollectionFrame.LeftInset:GetFrameLevel() + 1);
		end
		WardrobeCollectionFrame.searchBox:SetEnabled(true);
		WardrobeCollectionFrame.SetsCollectionFrame:SetShown(not atTransmogrifier);
		WardrobeCollectionFrame.SetsTransmogFrame:SetShown(atTransmogrifier);
	end
	WardrobeResetFiltersButton_UpdateVisibility();
end

function WardrobeCollectionFrame_OnLoad(self)
	self.Tabs =
	{
		self.ItemsTab,
		self.SetsTab,
	};
	self.ContentFrames =
	{
		self.ItemsCollectionFrame,
		self.SetsTransmogFrame,
	};
	Mixin(self.FilterButton, SetEnabledMixin);

	PanelTemplates_SetNumTabs(self, 2);
	PanelTemplates_SetTab(self, TAB_ITEMS);
	PanelTemplates_ResizeTabsToFit(self, TABS_MAX_WIDTH);
	self.selectedCollectionTab = TAB_ITEMS;
	self.selectedTransmogTab = TAB_ITEMS;

	SetPortraitToTexture(CollectionsJournalPortrait, "Interface\\Icons\\inv_misc_enggizmos_19");
	self:EnableKeyboard(false);
end

WardrobeItemsCollectionMixin = { };

function WardrobeItemsCollectionMixin:CreateSlotButtons()
	local slots = { "head", "shoulder", "back", "chest", "shirt", "tabard", "wrist", 12, "hands", "waist", "legs", "feet", 12, "mainhand", 12, "secondaryhand", 12, "ranged" };
	local parentFrame = self.SlotsFrame;
	parentFrame.Buttons = { };
	local lastButton;	
	local xOffset = 2;
	local mainHandButton, secondaryHandButton;
	for i = 1, #slots do
		local value = tonumber(slots[i]);
		if ( value ) then
			-- this is a spacer
			xOffset = value;
		else
			local button = CreateFrame("BUTTON", nil, parentFrame, "WardrobeSlotButtonTemplate");
			Mixin(button.NormalTexture, SetAtlasMixin);
			button.NormalTexture:SetAtlas("transmog-nav-slot-"..slots[i], true);
			if ( lastButton ) then
				button:SetPoint("LEFT", lastButton, "RIGHT", xOffset, 0);
			else
				button:SetPoint("TOPLEFT");
			end
			button.slot = string.upper(slots[i]).."SLOT";
			xOffset = 1;
			lastButton = button;
			if ( slots[i] == "mainhand" ) then
				mainHandButton = button;
			elseif ( slots[i] == "secondaryhand" ) then
				secondaryHandButton = button;
			end
			Mixin(button.SelectedTexture, SetShownMixin);
			table.insert(parentFrame.Buttons, button);
		end
	end
	-- enchant buttons
	local mainHandEnchantButton = CreateFrame("BUTTON", nil, parentFrame, "WardrobeEnchantButtonTemplate");
	mainHandEnchantButton:SetPoint("BOTTOMRIGHT", mainHandButton, "TOPRIGHT", 16, -15);
	mainHandEnchantButton.slot = mainHandButton.slot;
	Mixin(mainHandEnchantButton.SelectedTexture, SetShownMixin);
	table.insert(parentFrame.Buttons, mainHandEnchantButton);
	local secondaryHandEnchantButton = CreateFrame("BUTTON", nil, parentFrame, "WardrobeEnchantButtonTemplate");
	secondaryHandEnchantButton:SetPoint("BOTTOMRIGHT", secondaryHandButton, "TOPRIGHT", 16, -15);
	secondaryHandEnchantButton.slot = secondaryHandButton.slot;
	Mixin(secondaryHandEnchantButton.SelectedTexture, SetShownMixin);
	table.insert(parentFrame.Buttons, secondaryHandEnchantButton);
	parentFrame.EnchantButtons = { mainHandEnchantButton, secondaryHandEnchantButton };
end

function WardrobeItemsCollectionMixin:OnEvent(event, ...)
	if ( event == "TRANSMOGRIFY_UPDATE" or event == "TRANSMOGRIFY_SUCCESS" or event == "PLAYER_EQUIPMENT_CHANGED" ) then
		local slotID = ...;
		if ( slotID and self.transmogType == LE_TRANSMOG_TYPE_APPEARANCE ) then
			if ( slotID == GetInventorySlotInfo(self.activeSlot) ) then
				if not self.deferredUpdate then
					self.deferredUpdate = true;
					C_Timer.After(0.1, function() self:RefreshVisualsList(); self:UpdateItems(); self.deferredUpdate = nil; end);
				end
			end
		else
			-- generic update
			if not self.deferredUpdate then
				self.deferredUpdate = true;
				C_Timer.After(0.1, function() self:RefreshVisualsList(); self:UpdateItems(); self.deferredUpdate = nil; end);
			end
		end
	elseif ( event == "TRANSMOG_COLLECTION_UPDATED") then
		self:CheckLatestAppearance(true);
		self:ValidateChosenVisualSources();
		if ( self:IsVisible() ) then
			self:RefreshVisualsList();
			self:UpdateItems();
		end
		WardrobeCollectionFrame_UpdateTabButtons();
	end
end

function WardrobeCollectionFrame_OnEvent(self, event, ...)
	if ( event == "TRANSMOG_COLLECTION_ITEM_UPDATE" ) then
		if ( self.tooltipContentFrame ) then
			self.tooltipContentFrame:RefreshAppearanceTooltip();
		end
		if ( self.ItemsCollectionFrame:IsShown() ) then
			self.ItemsCollectionFrame:ValidateChosenVisualSources();
		end
	elseif ( event == "UNIT_MODEL_CHANGED" ) then
		if ... ~= "player" then return; end
		self.activeFrame:OnUnitModelChangedEvent();
		local hasAlternateForm, inAlternateForm = HasAlternateForm();
		if ( (self.inAlternateForm ~= inAlternateForm or self.updateOnModelChanged) and self.ItemsCollectionFrame.Models[1]:CanSetUnit("player") ) then
			if ( self.activeFrame:OnUnitModelChangedEvent() ) then
				self.inAlternateForm = inAlternateForm;
				self.updateOnModelChanged = nil;
			end
		end
	elseif ( event == "PLAYER_LEVEL_UP" or event == "SKILL_LINES_CHANGED" or event == "UPDATE_FACTION" or event == "SPELLS_CHANGED" ) then
		WardrobeCollectionFrame_UpdateUsableAppearances();
	elseif ( event == "TRANSMOG_SEARCH_UPDATED" ) then
		local searchType, arg1 = ...;
		if ( searchType == self.activeFrame.searchType ) then
			self.activeFrame:OnSearchUpdate(arg1);
		end
	elseif ( event == "SEARCH_DB_LOADED" ) then
		WardrobeCollectionFrame_RestartSearchTracking();
	elseif ( event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" or event == "TRANSMOG_COLLECTION_CAMERA_UPDATE" ) then
		WardrobeCollectionFrame_RefreshCameras();
	end
end

function WardrobeCollectionFrame_UpdateUsableAppearances()
	if ( not WardrobeCollectionFrame.updateUsableAppearances ) then
		WardrobeCollectionFrame.updateUsableAppearances = true;
		C_Timer.After(0, function() WardrobeCollectionFrame.updateUsableAppearances = nil; C_TransmogCollection.UpdateUsableAppearances(); end);
	end
end

function WardrobeCollectionFrame_RefreshCameras()
	for i, frame in ipairs(WardrobeCollectionFrame.ContentFrames) do
		frame:RefreshCameras();
	end
end

function WardrobeItemsCollectionMixin:CheckLatestAppearance(changeTab)
	local latestAppearanceID, latestAppearanceCategoryID = C_TransmogCollection.GetLatestAppearance();
	if ( self.latestAppearanceID ~= latestAppearanceID ) then
		self.latestAppearanceID = latestAppearanceID;
		self.jumpToLatestAppearanceID = latestAppearanceID;
		self.jumpToLatestCategoryID = latestAppearanceCategoryID;

		if ( changeTab and not CollectionsJournal:IsShown() ) then
			CollectionsJournal_SetTab(CollectionsJournal, 5);
		end
	end
end

function WardrobeItemsCollectionMixin:OnLoad()
	self.Models =
	{
		self.ModelR1C1,
		self.ModelR1C2,
		self.ModelR1C3,
		self.ModelR1C4,
		self.ModelR1C5,
		self.ModelR1C6,
		self.ModelR2C1,
		self.ModelR2C2,
		self.ModelR2C3,
		self.ModelR2C4,
		self.ModelR2C5,
		self.ModelR2C6,
		self.ModelR3C1,
		self.ModelR3C2,
		self.ModelR3C3,
		self.ModelR3C4,
		self.ModelR3C5,
		self.ModelR3C6,
	};

	self:CreateSlotButtons();
	self.BGCornerTopLeft:Hide();
	self.BGCornerTopRight:Hide();
	self.HiddenModel:SetKeepModelOnHide(true);
	function self.HiddenModel:SetItemAppearance() end
	function self.HiddenModel:HasAttachmentPoints() return true; end

	self.chosenVisualSources = { };

	self.NUM_ROWS = 3;
	self.NUM_COLS = 6;
	self.PAGE_SIZE = self.NUM_ROWS * self.NUM_COLS;

	UIDropDownMenu_Initialize(self.RightClickDropDown, nil, "MENU");
	self.RightClickDropDown.initialize = WardrobeCollectionFrameRightClickDropDown_Init;

	ezCollections:RegisterEvent(self, "TRANSMOG_COLLECTION_UPDATED");

	self:CheckLatestAppearance();
end

function WardrobeItemsCollectionMixin:ShouldShowSetsHelpTip()
	if (WardrobeFrame_IsAtTransmogrifier()) then
		if (ezCollections:GetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_TRANSMOG_SETS_VENDOR_TAB)) then
			return false;
		end

		if (not ezCollections:GetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_TRANSMOG_SPECS_BUTTON)) then
			return false;
		end

		if (not ezCollections:GetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_TRANSMOG_OUTFIT_DROPDOWN)) then
			return false;
		end

		local sets = C_TransmogSets.GetAllSets();
		local hasCollected = false;
		if (sets) then
			for i = 1, #sets do
				if (sets[i].collected) then
					hasCollected = true;
					break;
				end
			end
		end
		if (not hasCollected) then
			return false;
		end

		self:GetParent().SetsTabHelpBox.BigText:SetText(TRANSMOG_SETS_VENDOR_TUTORIAL);
		self:GetParent().SetsTabHelpBox:SetHeight(self:GetParent().SetsTabHelpBox.BigText:GetHeight() + HELPTIP_HEIGHT_PADDING);
		return true;
	else
		if (ezCollections:GetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_TRANSMOG_SETS_TAB)) then
			return false;
		end

		if (not ezCollections:GetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_TRANSMOG_MODEL_CLICK)) then
			return false;
		end

		self:GetParent().SetsTabHelpBox.BigText:SetText(TRANSMOG_SETS_TAB_TUTORIAL);
		self:GetParent().SetsTabHelpBox:SetHeight(self:GetParent().SetsTabHelpBox.BigText:GetHeight() + HELPTIP_HEIGHT_PADDING);
		return true;
	end
end

function WardrobeItemsCollectionMixin:OnShow()
	ezCollections:RegisterEvent(self, "TRANSMOGRIFY_UPDATE");
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
	ezCollections:RegisterEvent(self, "TRANSMOGRIFY_SUCCESS");

	local needsUpdate = false;	-- we don't need to update if we call WardrobeCollectionFrame_SetActiveSlot as that will do an update
	if ( self.jumpToLatestCategoryID and self.jumpToLatestCategoryID ~= self.activeCategory ) then
		local slot = CollectionWardrobeUtil.GetSlotFromCategoryID(self.jumpToLatestCategoryID);
		self:SetActiveSlot(slot, LE_TRANSMOG_TYPE_APPEARANCE, self.jumpToLatestCategoryID);
		self.jumpToLatestCategoryID = nil;
	elseif ( self.activeSlot ) then
		-- redo the model for the active slot
		self:ChangeModelsSlot(nil, self.activeSlot);
		needsUpdate = true;
	else
		self:SetActiveSlot("HEADSLOT", LE_TRANSMOG_TYPE_APPEARANCE);
	end

	if ( needsUpdate ) then
		self:RefreshVisualsList();
		self:UpdateItems();
		self:UpdateWeaponDropDown();
	end

	-- tab tutorial
	ezCollections:SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_TRANSMOG_JOURNAL_TAB, true);
	if self:ShouldShowSetsHelpTip() then
		self:GetParent().SetsTabHelpBox:Show();
	else
		self:GetParent().SetsTabHelpBox:Hide();
	end
end

function WardrobeItemsCollectionMixin:OnHide()
	ezCollections:UnregisterEvent(self, "TRANSMOGRIFY_UPDATE");
	self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED");
	ezCollections:UnregisterEvent(self, "TRANSMOGRIFY_SUCCESS");

	StaticPopup_Hide("TRANSMOG_FAVORITE_WARNING");

	WardrobeCollectionFrame_ClearSearch(LE_TRANSMOG_SEARCH_TYPE_ITEMS);

	for i = 1, #self.Models do
		self.Models[i]:SetKeepModelOnHide(false);
	end

	self.visualsList = nil;
	self.filteredVisualsList = nil;
end

function WardrobeCollectionFrame_OnShow(self)
	SetPortraitToTexture(CollectionsJournalPortrait, "Interface\\Icons\\inv_chest_cloth_17");

	ezCollections:RegisterEvent(self, "TRANSMOG_COLLECTION_ITEM_UPDATE");
	self:RegisterEvent("UNIT_MODEL_CHANGED");
	ezCollections:RegisterEvent(self, "TRANSMOG_SEARCH_UPDATED");
	ezCollections:RegisterEvent(self, "SEARCH_DB_LOADED");
	self:RegisterEvent("PLAYER_LEVEL_UP");
	self:RegisterEvent("SKILL_LINES_CHANGED");
	self:RegisterEvent("UPDATE_FACTION");
	self:RegisterEvent("SPELLS_CHANGED");
	self:RegisterEvent("UI_SCALE_CHANGED");
	self:RegisterEvent("DISPLAY_SIZE_CHANGED");
	ezCollections:RegisterEvent(self, "TRANSMOG_COLLECTION_CAMERA_UPDATE");

	local hasAlternateForm, inAlternateForm = HasAlternateForm();
	self.inAlternateForm = inAlternateForm;

	-- Workaround for a bug that causes hands to alternate if player has Dual Wield or Titan's Grip
	self.DualWieldResetter:SetUnit("player");
	-- Fix for animations not adapting to UI scale
	for _, frame in ipairs({ self.ItemsCollectionFrame, self.SetsTransmogFrame }) do
		for i = 1, 12 do
			local wisp = frame.PendingTransmogFrame["Wisp"..i];
			for _, anim in ipairs({ "TransmogSelectedAnim", "TransmogSelectedAnim3" }) do
				local translation = wisp and wisp[anim] and wisp[anim].Translation;
				if translation then
					if not translation.x or not translation.y then
						translation.x, translation.y = translation:GetOffset();
					end
					translation:SetOffset(translation.x * frame.PendingTransmogFrame:GetEffectiveScale() , translation.y * frame.PendingTransmogFrame:GetEffectiveScale());
				end
			end
		end
	end

	--WardrobeCollectionFrame_UpdateUsableAppearances();

	if ( WardrobeFrame_IsAtTransmogrifier() ) then
		WardrobeCollectionFrame_SetTab(self.selectedTransmogTab);
	else
		WardrobeCollectionFrame_SetTab(self.selectedCollectionTab);
	end
	WardrobeCollectionFrame_UpdateTabButtons();
end

function WardrobeCollectionFrame_OnHide(self)
	ezCollections:UnregisterEvent(self, "TRANSMOG_COLLECTION_ITEM_UPDATE");
	self:UnregisterEvent("UNIT_MODEL_CHANGED");
	ezCollections:UnregisterEvent(self, "TRANSMOG_SEARCH_UPDATED");
	ezCollections:UnregisterEvent(self, "SEARCH_DB_LOADED");
	self:UnregisterEvent("PLAYER_LEVEL_UP");
	self:UnregisterEvent("SKILL_LINES_CHANGED");
	self:UnregisterEvent("UPDATE_FACTION");
	self:UnregisterEvent("SPELLS_CHANGED");
	self:UnregisterEvent("UI_SCALE_CHANGED");
	self:UnregisterEvent("DISPLAY_SIZE_CHANGED");
	ezCollections:UnregisterEvent(self, "TRANSMOG_COLLECTION_CAMERA_UPDATE");
	C_TransmogCollection.EndSearch();
	self.jumpToVisualID = nil;
end

function WardrobeCollectionFrame_UpdateTabButtons()
	-- sets tab
	if C_TransmogSets.GetLatestSource() ~= NO_TRANSMOG_SOURCE_ID and not WardrobeFrame_IsAtTransmogrifier() then
		WardrobeCollectionFrame.SetsTab.FlashFrame:Show();
	else
		WardrobeCollectionFrame.SetsTab.FlashFrame:Hide();
	end
end

function WardrobeItemsCollectionMixin:OnMouseWheel(delta)
	self.PagingFrame:OnMouseWheel(delta);
end

function WardrobeItemsCollectionMixin:CanHandleKey(key)
	if ( WardrobeFrame_IsAtTransmogrifier() and (key == WARDROBE_PREV_VISUAL_KEY or key == WARDROBE_NEXT_VISUAL_KEY or key == WARDROBE_UP_VISUAL_KEY or key == WARDROBE_DOWN_VISUAL_KEY) ) then
		return true;
	end
	return false;
end

function WardrobeItemsCollectionMixin:HandleKey(key)
	local _, _, _, selectedVisualID = self:GetActiveSlotInfo();
	local visualIndex;
	local visualsList = self:GetFilteredVisualsList();
	for i = 1, #visualsList do
		if ( visualsList[i].visualID == selectedVisualID ) then
			visualIndex = i;
			break;
		end
	end
	if ( visualIndex ) then
		visualIndex = WardrobeUtils_GetAdjustedDisplayIndexFromKeyPress(self, visualIndex, #visualsList, key);
		self:SelectVisual(visualsList[visualIndex].visualID);
		self.jumpToVisualID = visualsList[visualIndex].visualID;
		self:ResetPage();
	end
end

function WardrobeCollectionFrame_OnKeyDown(self, key)
	if ( self.tooltipCycle and key == WARDROBE_CYCLE_KEY ) then
		if ( IsShiftKeyDown() ) then
			self.tooltipSourceIndex = self.tooltipSourceIndex - 1;
		else
			self.tooltipSourceIndex = self.tooltipSourceIndex + 1;
		end
		self.tooltipContentFrame:RefreshAppearanceTooltip(true);
	elseif ( key == WARDROBE_PREV_VISUAL_KEY or key == WARDROBE_NEXT_VISUAL_KEY or key == WARDROBE_UP_VISUAL_KEY or key == WARDROBE_DOWN_VISUAL_KEY ) then
		if ( self.activeFrame:CanHandleKey(key) ) then
			self.activeFrame:HandleKey(key);
		end
	else
		if tContains({ GetBindingKey("OPENCHAT") }, key) then
			ChatFrame_OpenChat("");
		end
	end
end

function WardrobeItemsCollectionMixin:ChangeModelsSlot(oldSlot, newSlot)
	WardrobeCollectionFrame.updateOnModelChanged = nil;

	local undressSlot, reloadModel;
	local newSlotIsArmor = WardrobeUtils_GetArmorCategoryIDFromSlot(newSlot);
	if ( newSlotIsArmor ) then
		local oldSlotIsArmor = oldSlot and WardrobeUtils_GetArmorCategoryIDFromSlot(oldSlot);
		if ( oldSlotIsArmor ) then
			if ( WARDROBE_MODEL_SETUP[oldSlot].useTransmogSkin ~= WARDROBE_MODEL_SETUP[newSlot].useTransmogSkin ) then
				reloadModel = true;
			else
				undressSlot = true;
			end
		else
			reloadModel = true;
		end
	end

	if ( reloadModel and not self.Models[1]:CanSetUnit("player") ) then
		WardrobeCollectionFrame.updateOnModelChanged = true;
		for i = 1, #self.Models do
			self.Models[i]:ClearModel();
		end
		return;
	end

	for i = 1, #self.Models do
		local model = self.Models[i];
		if ( undressSlot ) then
			local changedOldSlot = false;
			-- dress/undress setup gear
			for slot, equip in pairs(WARDROBE_MODEL_SETUP[newSlot].slots) do
				if ( equip ~= WARDROBE_MODEL_SETUP[oldSlot].slots[slot] ) then
					if ( equip ) then
						model:TryOn(WARDROBE_MODEL_SETUP_GEAR[slot]);
					else
						model:UndressSlot(GetInventorySlotInfo(slot));
					end
					if ( slot == oldSlot ) then
						changedOldSlot = true;
					end
				end
			end
			-- undress old slot
			if ( not changedOldSlot ) then
				local slotID = GetInventorySlotInfo(oldSlot);
				model:UndressSlot(slotID);
			end
		elseif ( reloadModel ) then
			model:Reload(newSlot);
		end
		model.visualInfo = nil;
	end
	self.illusionWeaponVisualID = nil;
end

function WardrobeItemsCollectionMixin:RefreshCameras()
	if ( self:IsShown() ) then
		for i, model in ipairs(self.Models) do
			model:RefreshCamera();
			if ( model.cameraID ) then
				Model_ApplyUICamera(model, model.cameraID);
			end
		end
	end
end

function WardrobeItemsCollectionMixin:OnUnitModelChangedEvent()
	if ( self.Models[1]:CanSetUnit("player") ) then
		self:ChangeModelsSlot(nil, self:GetActiveSlot());
		self:UpdateItems();
		return true;
	else
		return false;
	end
end

function WardrobeUtils_IsCategoryRanged(category)
	return (category == LE_TRANSMOG_COLLECTION_TYPE_BOW) or (category == LE_TRANSMOG_COLLECTION_TYPE_GUN) or (category == LE_TRANSMOG_COLLECTION_TYPE_CROSSBOW);
end

function WardrobeUtils_GetArmorCategoryIDFromSlot(slot)
	for i = 1, #TRANSMOG_SLOTS do
		if ( TRANSMOG_SLOTS[i].slot == slot ) then
			return TRANSMOG_SLOTS[i].armorCategoryID;
		end
	end
end

local function GetPage(entryIndex, pageSize)
	return floor((entryIndex-1) / pageSize) + 1;
end

function WardrobeUtils_GetAdjustedDisplayIndexFromKeyPress(contentFrame, index, numEntries, key)
	if ( key == WARDROBE_PREV_VISUAL_KEY ) then
		index = index - 1;
		if ( index < 1 ) then
			index = numEntries;
		end
	elseif ( key == WARDROBE_NEXT_VISUAL_KEY ) then
		index = index + 1;
		if ( index > numEntries ) then
			index = 1;
		end
	elseif ( key == WARDROBE_DOWN_VISUAL_KEY ) then
		local newIndex = index + contentFrame.NUM_COLS;
		if ( newIndex > numEntries ) then
			-- If you're at the last entry, wrap back around; otherwise go to the last entry.
			index = index == numEntries and 1 or numEntries;
		else
			index = newIndex;
		end
	elseif ( key == WARDROBE_UP_VISUAL_KEY ) then
		local newIndex = index - contentFrame.NUM_COLS;
		if ( newIndex < 1 ) then
			-- If you're at the first entry, wrap back around; otherwise go to the first entry.
			index = index == 1 and numEntries or 1;
		else
			index = newIndex;
		end
	end
	return index;
end

function WardrobeItemsCollectionMixin:GetActiveSlot()
	return self.activeSlot;
end

function WardrobeItemsCollectionMixin:GetActiveCategory()
	return self.activeCategory;
end

function WardrobeItemsCollectionMixin:IsValidWeaponCategoryForSlot(categoryID, slot)
	local name, isWeapon, canEnchant, canMainHand, canOffHand, canRanged = C_TransmogCollection.GetCategoryInfo(categoryID);
	if ( name and isWeapon ) then
		if ( (slot == "MAINHANDSLOT" and canMainHand) or (slot == "SECONDARYHANDSLOT" and canOffHand) ) or slot == "RANGEDSLOT" and canRanged then
			if ( WardrobeFrame_IsAtTransmogrifier() ) then
				local equippedItemID = GetInventoryItemID("player", GetInventorySlotInfo(slot));
				return C_TransmogCollection.IsCategoryValidForItem(categoryID, equippedItemID);
			else
				return true;
			end
		end
	end
	return false;
end

function WardrobeItemsCollectionMixin:SetActiveSlot(slot, transmogType, category)
	local previousSlot = self.activeSlot;
	self.activeSlot = slot;
	self.transmogType = transmogType;

	-- figure out a category
	if ( not category ) then
		if ( transmogType == LE_TRANSMOG_TYPE_ILLUSION ) then
			category = nil;
		elseif ( transmogType == LE_TRANSMOG_TYPE_APPEARANCE ) then
			local useLastWeaponCategory = (slot == "MAINHANDSLOT" or slot == "SECONDARYHANDSLOT" or slot == "RANGEDSLOT") and
										 self.lastWeaponCategory and
										 self:IsValidWeaponCategoryForSlot(self.lastWeaponCategory, slot);
			if ( useLastWeaponCategory ) then
				category = self.lastWeaponCategory;
			else
				local appliedSourceID, appliedVisualID, selectedSourceID, selectedVisualID = self:GetActiveSlotInfo();
				if ( selectedSourceID ~= NO_TRANSMOG_SOURCE_ID ) then
					category = C_TransmogCollection.GetAppearanceSourceInfo(selectedSourceID);
					if category and not self:IsValidWeaponCategoryForSlot(category, slot) then
						category = nil;
					end
				end
			end
			if ( not category ) then
				if ( slot == "MAINHANDSLOT" or slot == "SECONDARYHANDSLOT" or slot == "RANGEDSLOT" ) then
					-- find the first valid weapon category
					for categoryID = FIRST_TRANSMOG_COLLECTION_WEAPON_TYPE, LAST_TRANSMOG_COLLECTION_WEAPON_TYPE do
						if ( self:IsValidWeaponCategoryForSlot(categoryID, slot) ) then
							category = categoryID;
							break;
						end
					end
				else
					category = WardrobeUtils_GetArmorCategoryIDFromSlot(slot);
				end
			end
		end
	end

	if ( previousSlot ~= slot ) then
		self:ChangeModelsSlot(previousSlot, slot);
	end
	-- set only if category is different or slot is different
	if ( category ~= self.activeCategory or slot ~= previousSlot ) then
		CloseDropDownMenus();
		self:SetActiveCategory(category);
	end
end

function WardrobeItemsCollectionMixin:SetTransmogrifierAppearancesShown(hasAnyValidSlots)
	self.NoValidItemsLabel:SetShown(not hasAnyValidSlots);
	--C_TransmogCollection.SetCollectedShown(hasAnyValidSlots);
end

function WardrobeItemsCollectionMixin:UpdateWeaponDropDown()
	local dropdown = self.WeaponDropDown;
	local name, isWeapon;
	if ( self.transmogType == LE_TRANSMOG_TYPE_APPEARANCE ) then
		name, isWeapon = C_TransmogCollection.GetCategoryInfo(self.activeCategory);
	end
	if ( not isWeapon ) then
		if ( WardrobeFrame_IsAtTransmogrifier() ) then
			dropdown:Hide();
		else
			dropdown:Show();
			UIDropDownMenu_DisableDropDown(dropdown);
			UIDropDownMenu_SetText(dropdown, "");
		end
	else
		dropdown:Show();
		UIDropDownMenu_SetSelectedValue(dropdown, self.activeCategory);
		UIDropDownMenu_SetText(dropdown, name);
		local validCategories = WardrobeCollectionFrameWeaponDropDown_Init(dropdown);
		if ( validCategories > 1 ) then
			UIDropDownMenu_EnableDropDown(dropdown);
		else
			UIDropDownMenu_DisableDropDown(dropdown);
		end
	end
end

function WardrobeItemsCollectionMixin:SetActiveCategory(category)
	self.activeCategory = category;
	C_TransmogCollection.SetSearchAndFilterCategory(category);
	if ( self.transmogType == LE_TRANSMOG_TYPE_APPEARANCE ) then
		local name, isWeapon = C_TransmogCollection.GetCategoryInfo(category);
		if ( isWeapon ) then
			self.lastWeaponCategory = category;
		end
	end
	self:RefreshVisualsList();
	self:UpdateWeaponDropDown();

	local slotButtons = self.SlotsFrame.Buttons;
	for i = 1, #slotButtons do
		local button = slotButtons[i];
		button.SelectedTexture:SetShown(button.slot == self.activeSlot and button.transmogType == self.transmogType);
	end

	if ( WardrobeFrame_IsAtTransmogrifier() ) then
		self.jumpToVisualID = select(4, self:GetActiveSlotInfo());
	end
	self:ResetPage();
	WardrobeCollectionFrame_SwitchSearchCategory();
end

function WardrobeItemsCollectionMixin:ResetPage()
	local page = 1;
	local selectedVisualID = NO_TRANSMOG_VISUAL_ID;
	if ( C_TransmogCollection.IsSearchInProgress(WardrobeCollectionFrame.activeFrame.searchType) ) then
		self.resetPageOnSearchUpdated = true;
	else
		if ( self.jumpToVisualID ) then
			selectedVisualID = self.jumpToVisualID;
			self.jumpToVisualID = nil;
		elseif ( self.jumpToLatestAppearanceID ) then
			selectedVisualID = self.jumpToLatestAppearanceID;
			self.jumpToLatestAppearanceID = nil;
		end
	end
	if ( selectedVisualID and selectedVisualID ~= NO_TRANSMOG_VISUAL_ID ) then
		local visualsList = self:GetFilteredVisualsList();
		for i = 1, #visualsList do
			if ( visualsList[i].visualID == selectedVisualID ) then
				page = GetPage(i, self.PAGE_SIZE);
				break;
			end
		end
	end
	self.PagingFrame:SetCurrentPage(page);
	self:UpdateItems();
end

function WardrobeItemsCollectionMixin:FilterVisuals()
	local missing = false;
	local showClaimable = ezCollections:GetCVarBool("transmogrifyShowClaimable");
	local showPurchasable = ezCollections:GetCVarBool("transmogrifyShowPurchasable");
	local showObtainable = not ezCollections.Developer or ezCollections:GetCVarBool("transmogrifyShowObtainable");
	local showUnobtainable = ezCollections.Developer and ezCollections:GetCVarBool("transmogrifyShowUnobtainable");
	local isAtTransmogrifier = WardrobeFrame_IsAtTransmogrifier();
	local visualsList = self.visualsList;
	local filteredVisualsList = { };
	for i = 1, #visualsList do
		if ( isAtTransmogrifier ) then
			if ( visualsList[i].isUsable and visualsList[i].isCollected ) then
				tinsert(filteredVisualsList, visualsList[i]);
			elseif not visualsList[i].isCollected and showClaimable and ezCollections:CanClaimSkin(visualsList[i].visualID) then
				tinsert(filteredVisualsList, visualsList[i]);
			elseif not visualsList[i].isCollected and showPurchasable and (visualsList[i].isStoreSource or visualsList[i].isSubscriptionSource) then
				tinsert(filteredVisualsList, visualsList[i]);
			elseif visualsList[i].isCollected and not GetItemInfo(visualsList[i].visualID) then
				missing = true;
				ezCollections:QueryItem(visualsList[i].visualID);
				if not WardrobeCollectionFrame.visualListCacheRefreshTimer then
					WardrobeCollectionFrame.visualListCacheRefreshTimer = ezCollections.AceAddon:ScheduleRepeatingTimer(function()
						local missing = false;
						if WardrobeCollectionFrame:IsVisible() then
							missing = not self:RefreshVisualsList();
							self:UpdateItems();
						end

						if not missing then
							ezCollections.AceAddon:CancelTimer(WardrobeCollectionFrame.visualListCacheRefreshTimer);
							WardrobeCollectionFrame.visualListCacheRefreshTimer = nil;
						end
					end, 0.1);
				end
			end
		else
			local hide;
			if ezCollections.Developer then
				local info = ezCollections:GetSkinInfo(visualsList[i].visualID);
				if info then
					if info.Unobtainable then
						hide = not showUnobtainable;
					else
						hide = not showObtainable;
					end
				end
			end
			if ( not visualsList[i].isHideVisual ) and not hide then
				tinsert(filteredVisualsList, visualsList[i]);
			end
		end
	end
	self.filteredVisualsList = filteredVisualsList;
	return not missing;
end

function WardrobeItemsCollectionMixin:SortVisuals()
	local comparison = function(source1, source2)
		if ( source1.isCollected ~= source2.isCollected ) then
			return source1.isCollected;
		end
		if ( source1.isUsable ~= source2.isUsable ) then
			return source1.isUsable;
		end
		if ( source1.isFavorite ~= source2.isFavorite ) then
			return source1.isFavorite;
		end
		if ( source1.isHideVisual ~= source2.isHideVisual ) then
			return source1.isHideVisual;
		end
		if ( source1.hasActiveRequiredHoliday ~= source2.hasActiveRequiredHoliday ) then
			return source1.hasActiveRequiredHoliday;
		end
		if ( source1.uiOrder and source2.uiOrder ) then
			return source1.uiOrder > source2.uiOrder;
		end
		return source1.sourceID > source2.sourceID;
	end

	table.sort(self.filteredVisualsList, comparison);
end

function WardrobeItemsCollectionMixin:GetActiveSlotInfo()
	return WardrobeCollectionFrame_GetInfoForEquippedSlot(self.activeSlot, self.transmogType);
end

function WardrobeCollectionFrame_GetInfoForEquippedSlot(slot, transmogType)
	local baseSourceID, baseVisualID, appliedSourceID, appliedVisualID, pendingSourceID, pendingVisualID, hasPendingUndo = C_Transmog.GetSlotVisualInfo(GetInventorySlotInfo(slot), transmogType);
	if ( appliedSourceID == NO_TRANSMOG_SOURCE_ID ) then
		appliedSourceID = baseSourceID;
		appliedVisualID = baseVisualID;
	end
	local selectedSourceID, selectedVisualID;
	if ( pendingSourceID ~= REMOVE_TRANSMOG_ID ) then
		selectedSourceID = pendingSourceID;
		selectedVisualID = pendingVisualID;
	elseif ( hasPendingUndo ) then
		selectedSourceID = baseSourceID;
		selectedVisualID = baseVisualID;
	else
		selectedSourceID = appliedSourceID;
		selectedVisualID = appliedVisualID;
	end
	return appliedSourceID, appliedVisualID, selectedSourceID, selectedVisualID;
end

function WardrobeCollectionFrame_GetWeaponInfoForEnchant(slot)
	if ( not WardrobeFrame_IsAtTransmogrifier() and DressUpFrame:IsShown() and DressUpModel.GetSlotTransmogSources ) then
		local appearanceSourceID = DressUpModel:GetSlotTransmogSources(GetInventorySlotInfo(slot));
		local _, appearanceVisualID, canEnchant = C_TransmogCollection.GetAppearanceSourceInfo(appearanceSourceID);
		if ( WardrobeCollectionFrame_CanEnchantSource(appearanceSourceID) ) then
			local _, appearanceVisualID = C_TransmogCollection.GetAppearanceSourceInfo(appearanceSourceID);
			return appearanceSourceID, appearanceVisualID;
		end
	end

	local appliedSourceID, appliedVisualID, selectedSourceID, selectedVisualID = WardrobeCollectionFrame_GetInfoForEquippedSlot(slot, LE_TRANSMOG_TYPE_APPEARANCE);
	if ( WardrobeCollectionFrame_CanEnchantSource(selectedSourceID) ) then
		return selectedSourceID, selectedVisualID;
	else
		local appearanceSourceID = C_TransmogCollection.GetIllusionFallbackWeaponSource();
		local _, appearanceVisualID = C_TransmogCollection.GetAppearanceSourceInfo(appearanceSourceID);
		return appearanceSourceID, appearanceVisualID;
	end
end

function WardrobeCollectionFrame_CanEnchantSource(sourceID)
	local _, visualID, canEnchant = C_TransmogCollection.GetAppearanceSourceInfo(sourceID);
	if ( canEnchant ) then
		WardrobeCollectionFrame.ItemsCollectionFrame.HiddenModel:SetItemAppearance(visualID);
		return WardrobeCollectionFrame.ItemsCollectionFrame.HiddenModel:HasAttachmentPoints();
	end
	return false;
end

function WardrobeItemsCollectionMixin:UpdateItems()
	local isArmor;
	local cameraID;
	local appearanceVisualID;	-- for weapon when looking at enchants
	local changeModel = false;
	local isAtTransmogrifier = WardrobeFrame_IsAtTransmogrifier();

	if C_TransmogCollection.IsSearchInProgress(self.searchType) then
		self.Loading:Show();
		self.Loading.AnimFrame.Anim:Play();
	else
		self.Loading:Hide();
	end

	if ( self.transmogType == LE_TRANSMOG_TYPE_ILLUSION ) then
		-- for enchants we need to get the visual of the item in that slot
		local appearanceSourceID;
		appearanceSourceID, appearanceVisualID = WardrobeCollectionFrame_GetWeaponInfoForEnchant(self.activeSlot);
		cameraID = C_TransmogCollection.GetAppearanceCameraIDBySource(appearanceSourceID, self.activeCategory);
		if ( appearanceVisualID ~= self.illusionWeaponVisualID ) then
			self.illusionWeaponVisualID = appearanceVisualID;
			changeModel = true;
		end
	else
		local _, isWeapon = C_TransmogCollection.GetCategoryInfo(self.activeCategory);
		isArmor = not isWeapon;
	end

	local tutorialAnchorFrame;
	local checkTutorialFrame = (self.transmogType == LE_TRANSMOG_TYPE_APPEARANCE) and not WardrobeFrame_IsAtTransmogrifier()
								and not ezCollections:GetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_TRANSMOG_MODEL_CLICK);

	local baseSourceID, baseVisualID, appliedSourceID, appliedVisualID, pendingSourceID, pendingVisualID, hasPendingUndo;
	local showUndoIcon;
	if ( isAtTransmogrifier ) then
		baseSourceID, baseVisualID, appliedSourceID, appliedVisualID, pendingSourceID, pendingVisualID, hasPendingUndo = C_Transmog.GetSlotVisualInfo(GetInventorySlotInfo(self.activeSlot), self.transmogType);
		if ( appliedVisualID ~= NO_TRANSMOG_VISUAL_ID ) then
			if ( hasPendingUndo ) then
				pendingVisualID = baseVisualID;
				showUndoIcon = true;
			end
			-- current border (yellow) should only show on untransmogrified items
			baseVisualID = nil;
		end	
		-- hide current border (yellow) or current-transmogged border (purple) if there's something pending
		if ( pendingVisualID ~= NO_TRANSMOG_VISUAL_ID ) then
			baseVisualID = nil;
			appliedVisualID = nil;
		end
	end

	local pendingTransmogModelFrame = nil;
	local indexOffset = (self.PagingFrame:GetCurrentPage() - 1) * self.PAGE_SIZE;
	for i = 1, self.PAGE_SIZE do
		local model = self.Models[i];
		local index = i + indexOffset;
		local visualInfo = self.filteredVisualsList[index];
		if ( visualInfo ) then
			local needsDressing = ( visualInfo ~= model.visualInfo and (not visualInfo or not model.visualInfo or visualInfo.visualID ~= model.visualInfo.visualID) or changeModel ) or model.awaitingItemCache;
			local hasItemData = GetItemInfo(visualInfo.visualID);
			if not hasItemData then
				ezCollections:QueryItem(visualInfo.visualID);
			end
			if self.transmogType == LE_TRANSMOG_TYPE_ILLUSION then
				local appearanceSourceID = WardrobeCollectionFrame_GetWeaponInfoForEnchant(self.activeSlot);
				local invType = select(9, GetItemInfo(appearanceSourceID));
				local isOffHand = invType == "INVTYPE_WEAPONOFFHAND" or invType == "INVTYPE_HOLDABLE" or invType == "INVTYPE_RANGED";
				if needsDressing then
					WardrobeCollectionFrame.DualWieldResetter:Dress();
				end
				model:SetModelScale(1);
				model:SetType(isOffHand and "off" or "main");
			else
				local invType = select(9, GetItemInfo(visualInfo.visualID));
				local isOffHand = invType == "INVTYPE_WEAPONOFFHAND" or invType == "INVTYPE_HOLDABLE" or invType == "INVTYPE_RANGED";
				if needsDressing and not isArmor then
					WardrobeCollectionFrame.DualWieldResetter:Dress();
				end
				model:SetModelScale(isArmor and 10 or 1);
				model:SetType(isArmor and "player" or isOffHand and "off" or "main");
			end
			model:Show();

			-- camera
			if ( self.transmogType == LE_TRANSMOG_TYPE_APPEARANCE ) then
				cameraID = C_TransmogCollection.GetAppearanceCameraID(visualInfo.visualID, WardrobeCollectionFrame.ItemsCollectionFrame:GetActiveCategory());
			end
			--if ( model.cameraID ~= cameraID ) then
				Model_ApplyUICamera(model, cameraID);
				model.cameraID = cameraID;
			--end

			--if ( visualInfo ~= model.visualInfo or changeModel ) then
			if needsDressing then
				model:Undress();
				if ( isArmor ) then
					local sourceID = self:GetAnAppearanceSourceFromVisual(visualInfo.visualID);
					if hasItemData then
						model:TryOn(sourceID);
					end
				elseif ( appearanceVisualID ) then
					-- appearanceVisualID is only set when looking at enchants
					model:SetItemAppearance(appearanceVisualID, visualInfo.visualID);
				else
					model:SetItemAppearance(visualInfo.visualID);
				end
			end
			model.visualInfo = visualInfo;

			-- state at the transmogrifier
			local transmogStateAtlas;
			if ( visualInfo.visualID == appliedVisualID ) then
				transmogStateAtlas = "transmog-wardrobe-border-current-transmogged";
			elseif ( visualInfo.visualID == baseVisualID ) then
				transmogStateAtlas = "transmog-wardrobe-border-current";
			elseif ( visualInfo.visualID == pendingVisualID ) then
				transmogStateAtlas = "transmog-wardrobe-border-selected";
				pendingTransmogModelFrame = model;
			end
			if ( transmogStateAtlas ) then
				model.TransmogStateTexture:SetAtlas(transmogStateAtlas, true);
				model.TransmogStateTexture:Show();
			else
				model.TransmogStateTexture:Hide();
			end

			-- border
			if ( not visualInfo.isCollected ) then
				model.Border:SetAtlas("transmog-wardrobe-border-uncollected");
			elseif ( not visualInfo.isUsable ) then
				model.Border:SetAtlas("transmog-wardrobe-border-unusable");
			else
				model.Border:SetAtlas("transmog-wardrobe-border-collected");
			end

			if ( C_TransmogCollection.IsNewAppearance(visualInfo.visualID) ) then
				model.NewString:Show();
				model.NewGlow:Show();
			else
				model.NewString:Hide();
				model.NewGlow:Hide();
			end
			-- favorite
			model.Favorite.Icon:SetShown(visualInfo.isFavorite);
			-- hide visual option
			model.HideVisual.Icon:SetShown(isAtTransmogrifier and visualInfo.isHideVisual);
			model.ClaimQuest:SetShown(not visualInfo.isCollected and ezCollections:CanClaimSkin(visualInfo.visualID));
			model.StoreButton:SetShown(not model.ClaimQuest:IsShown() and not visualInfo.isCollected and visualInfo.isStoreSource and not visualInfo.isSubscriptionSource);
			model.SubscriptionButton:SetShown(not model.ClaimQuest:IsShown() and not visualInfo.isCollected and not visualInfo.isStoreSource and visualInfo.isSubscriptionSource);
			model.StoreSubscriptionButton:SetShown(not model.ClaimQuest:IsShown() and not visualInfo.isCollected and visualInfo.isStoreSource and visualInfo.isSubscriptionSource);
			model.StoreUnderlay:SetShown(model.StoreButton:IsShown() or model.SubscriptionButton:IsShown() or model.StoreSubscriptionButton:IsShown());
			model.SubscriptionOverlay:SetShown(visualInfo.isCollected and not ezCollections:HasSkin(visualInfo.visualID) and ezCollections:GetActiveSubscriptionForSkin(visualInfo.visualID));
			model.SubscriptionUnderlay:SetShown(model.SubscriptionOverlay:IsShown());
			model.SolidBackground:SetShown(not model.StoreUnderlay:IsShown() and not model.SubscriptionUnderlay:IsShown());

			if ( GameTooltip:GetOwner() == model ) then
				model:OnEnter();
			end
			
			-- find potential tutorial anchor in the 1st row
			if ( checkTutorialFrame ) then
				if ( i < self.NUM_COLS and not WardrobeCollectionFrame.tutorialVisualID and visualInfo.isCollected and not visualInfo.isHideVisual ) then
					tutorialAnchorFrame = model;
				elseif ( WardrobeCollectionFrame.tutorialVisualID and WardrobeCollectionFrame.tutorialVisualID == visualInfo.visualID ) then
					tutorialAnchorFrame = model;
				end
			end

			if hasItemData then
				model.Loading:Hide();
				model.awaitingItemCache = nil;
			else
				model:SetPosition(0, 100, 0);
				model.cameraID = nil;
				model.awaitingItemCache = visualInfo.visualID;
				model.Loading:Show();
				model.Loading.AnimFrame.Anim:Play();
				if not self.itemCacheRefreshTimer then
					self.itemCacheRefreshTimer = ezCollections.AceAddon:ScheduleRepeatingTimer(function()
						local missing = false;
						if self:IsVisible() then
							local refresh = false;
							for i = 1, WARDROBE_PAGE_SIZE do
								local model = self.Models[i];
								if model.awaitingItemCache then
									if GetItemInfo(model.awaitingItemCache) then
										refresh = true;
									else
										missing = true;
									end
								end
							end
							if refresh then
								self:UpdateItems();
							end
						end
						if not missing then
							ezCollections.AceAddon:CancelTimer(self.itemCacheRefreshTimer);
							self.itemCacheRefreshTimer = nil;
						end
					end, 0.1);
				end
			end
		else
			model:Hide();
			model.visualInfo = nil;
			model.Loading:Hide();
			model.awaitingItemCache = nil;
		end
	end
	if ( pendingTransmogModelFrame ) then
		self.PendingTransmogFrame:SetParent(pendingTransmogModelFrame);
		self.PendingTransmogFrame:SetPoint("CENTER");
		self.PendingTransmogFrame:Show();
		if ( self.PendingTransmogFrame.visualID ~= pendingVisualID ) then
			self.PendingTransmogFrame.Wisp1.TransmogSelectedAnim:Stop();
			self.PendingTransmogFrame.Wisp1.TransmogSelectedAnim:Play();
			self.PendingTransmogFrame.Wisp2.TransmogSelectedAnim:Stop();
			self.PendingTransmogFrame.Wisp2.TransmogSelectedAnim:Play();
			self.PendingTransmogFrame.Wisp3.TransmogSelectedAnim:Stop();
			self.PendingTransmogFrame.Wisp3.TransmogSelectedAnim:Play();
			self.PendingTransmogFrame.Wisp4.TransmogSelectedAnim:Stop();
			self.PendingTransmogFrame.Wisp4.TransmogSelectedAnim:Play();
			self.PendingTransmogFrame.Wisp5.TransmogSelectedAnim:Stop();
			self.PendingTransmogFrame.Wisp5.TransmogSelectedAnim:Play();
			self.PendingTransmogFrame.Wisp6.TransmogSelectedAnim:Stop();
			self.PendingTransmogFrame.Wisp6.TransmogSelectedAnim:Play();
			self.PendingTransmogFrame.Wisp7.TransmogSelectedAnim:Stop();
			self.PendingTransmogFrame.Wisp7.TransmogSelectedAnim:Play();
			self.PendingTransmogFrame.Wisp8.TransmogSelectedAnim:Stop();
			self.PendingTransmogFrame.Wisp8.TransmogSelectedAnim:Play();
			self.PendingTransmogFrame.Glowframe.TransmogSelectedAnim2:Stop();
			self.PendingTransmogFrame.Glowframe.TransmogSelectedAnim2:Play();
			self.PendingTransmogFrame.Wisp9.TransmogSelectedAnim3:Stop();
			self.PendingTransmogFrame.Wisp9.TransmogSelectedAnim3:Play();
			self.PendingTransmogFrame.Wisp10.TransmogSelectedAnim3:Stop();
			self.PendingTransmogFrame.Wisp10.TransmogSelectedAnim3:Play();
			self.PendingTransmogFrame.Wisp11.TransmogSelectedAnim3:Stop();
			self.PendingTransmogFrame.Wisp11.TransmogSelectedAnim3:Play();
			self.PendingTransmogFrame.Wisp12.TransmogSelectedAnim3:Stop();
			self.PendingTransmogFrame.Wisp12.TransmogSelectedAnim3:Play();
			self.PendingTransmogFrame.Smoke1.TransmogSelectedAnim4:Stop();
			self.PendingTransmogFrame.Smoke1.TransmogSelectedAnim4:Play();
			self.PendingTransmogFrame.Smoke2.TransmogSelectedAnim4:Stop();
			self.PendingTransmogFrame.Smoke2.TransmogSelectedAnim4:Play();
			self.PendingTransmogFrame.Smoke3.TransmogSelectedAnim5:Stop();
			self.PendingTransmogFrame.Smoke3.TransmogSelectedAnim5:Play();
			self.PendingTransmogFrame.Smoke4.TransmogSelectedAnim5:Stop();
			self.PendingTransmogFrame.Smoke4.TransmogSelectedAnim5:Play();
		end
		self.PendingTransmogFrame.UndoIcon:SetShown(showUndoIcon);
		self.PendingTransmogFrame.visualID = pendingVisualID;

		pendingTransmogModelFrame.Favorite:SetFrameLevel(self.PendingTransmogFrame:GetFrameLevel() + 1);
		pendingTransmogModelFrame.HideVisual:SetFrameLevel(self.PendingTransmogFrame:GetFrameLevel() + 1);
		pendingTransmogModelFrame.ClaimQuest:SetFrameLevel(self.PendingTransmogFrame:GetFrameLevel() + 1);
		pendingTransmogModelFrame.StoreButton:SetFrameLevel(self.PendingTransmogFrame:GetFrameLevel() + 1);
		pendingTransmogModelFrame.SubscriptionButton:SetFrameLevel(self.PendingTransmogFrame:GetFrameLevel() + 1);
		pendingTransmogModelFrame.StoreSubscriptionButton:SetFrameLevel(self.PendingTransmogFrame:GetFrameLevel() + 1);
		pendingTransmogModelFrame.SubscriptionOverlay:SetFrameLevel(self.PendingTransmogFrame:GetFrameLevel() + 1);
	else
		self.PendingTransmogFrame:Hide();
	end
	-- progress bar
	self:UpdateProgressBar();
	-- tutorial
	if ( checkTutorialFrame ) then
		if ( C_TransmogCollection.HasFavorites() ) then
			ezCollections:SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_TRANSMOG_MODEL_CLICK, true);
			tutorialAnchorFrame = nil;
		elseif ( tutorialAnchorFrame ) then
			if ( not WardrobeCollectionFrame.tutorialVisualID ) then
				WardrobeCollectionFrame.tutorialVisualID = tutorialAnchorFrame.visualInfo.visualID;
			end
			if ( WardrobeCollectionFrame.tutorialVisualID ~= tutorialAnchorFrame.visualInfo.visualID ) then
				tutorialAnchorFrame = nil;
			end
		end
	end
	if ( tutorialAnchorFrame ) then
		self.HelpBox:SetPoint("TOP", tutorialAnchorFrame, "BOTTOM", 0, -22);
		self.HelpBox:Show();
	else
		self.HelpBox:Hide();
	end
end

function WardrobeItemsCollectionMixin:UpdateProgressBar()
	local collected, total;
	--[[
	if ( self.transmogType == LE_TRANSMOG_TYPE_ILLUSION ) then
		total = #self.visualsList;
		collected = 0;
		for i, illusion in ipairs(self.visualsList) do
			if illusion.isHideVisual then
				total = total - 1;
			elseif ( illusion.isCollected ) then
				collected = collected + 1;
			end
		end
	else
		collected = C_TransmogCollection.GetCategoryCollectedCount(self.activeCategory);
		total = C_TransmogCollection.GetCategoryTotal(self.activeCategory);
	end
	]]
	collected = C_TransmogCollection.GetCategoryCollectedCount(self.activeCategory);
	total = C_TransmogCollection.GetCategoryTotal(self.activeCategory);
	WardrobeCollectionFrame_UpdateProgressBar(collected, total);
end

function WardrobeCollectionFrame_UpdateProgressBar(value, max)
	WardrobeCollectionFrame.progressBar:SetMinMaxValues(0, max);
	WardrobeCollectionFrame.progressBar:SetValue(value);
	WardrobeCollectionFrame.progressBar.text:SetFormattedText(HEIRLOOMS_PROGRESS_FORMAT, value, max);
end

function WardrobeItemsCollectionMixin:RefreshVisualsList()
	if ( self.transmogType == LE_TRANSMOG_TYPE_ILLUSION ) then
		self.visualsList = C_TransmogCollection.GetIllusions();
	else
		self.visualsList = C_TransmogCollection.GetCategoryAppearances(self.activeCategory);
	end
	local allLoaded = self:FilterVisuals();
	self:SortVisuals();
	self.PagingFrame:SetMaxPages(ceil(#self.filteredVisualsList / self.PAGE_SIZE));
	return allLoaded;
end

function WardrobeItemsCollectionMixin:GetFilteredVisualsList()
	return self.filteredVisualsList;
end

function WardrobeItemsCollectionMixin:GetAnAppearanceSourceFromVisual(visualID, mustBeUsable)
	local sourceID = self:GetChosenVisualSource(visualID);
	if ( sourceID == NO_TRANSMOG_SOURCE_ID ) then
		local sources = CollectionWardrobeUtil.GetSortedAppearanceSources(visualID, self.activeCategory);
		for i = 1, #sources do
			-- first 1 if it doesn't have to be usable
			if ( not mustBeUsable or not sources[i].useError ) then
				sourceID = sources[i].sourceID;
				break;
			end
		end
	end
	return sourceID;
end

function WardrobeItemsCollectionMixin:SelectVisual(visualID)
	if ( not WardrobeFrame_IsAtTransmogrifier() ) then
		return;
	end

	local sourceID;
	if ( self.transmogType == LE_TRANSMOG_TYPE_APPEARANCE ) then
		sourceID = self:GetAnAppearanceSourceFromVisual(visualID, true);
	else
		local visualsList = self:GetFilteredVisualsList();
		for i = 1, #visualsList do
			if ( visualsList[i].visualID == visualID ) then
				sourceID = visualsList[i].sourceID;
				break;
			end
		end
	end
	local slotID = GetInventorySlotInfo(self.activeSlot);
	C_Transmog.SetPending(slotID, self.transmogType, sourceID);
	PlaySound("igChatBottom");
end

function WardrobeCollectionFrame_OpenTransmogLink(link, transmogType)
	if ( not CollectionsJournal:IsVisible() or not WardrobeCollectionFrame:IsVisible() ) then
		ToggleCollectionsJournal(5);
	end

	local linkType, id = strsplit(":", link);

	if ( linkType == "transmogappearance" ) then
		local sourceID = tonumber(id);
		WardrobeCollectionFrame_SetTab(TAB_ITEMS);
		WardrobeCollectionFrame.ItemsCollectionFrame:GoToSourceID(sourceID, nil, LE_TRANSMOG_TYPE_APPEARANCE);
	elseif ( linkType == "transmogset") then
		local setID = tonumber(id);
		WardrobeCollectionFrame_SetTab(TAB_SETS);
		WardrobeCollectionFrame.SetsCollectionFrame:SelectSet(setID);
	end
end

function WardrobeItemsCollectionMixin:GoToSourceID(sourceID, slot, transmogType, forceGo)
	local categoryID, visualID;
	if ( transmogType == LE_TRANSMOG_TYPE_APPEARANCE ) then
		categoryID, visualID = C_TransmogCollection.GetAppearanceSourceInfo(sourceID);
		slot = slot or CollectionWardrobeUtil.GetSlotFromCategoryID(categoryID);
	elseif ( transmogType == LE_TRANSMOG_TYPE_ILLUSION ) then
		visualID = C_TransmogCollection.GetIllusionSourceInfo(sourceID);
		slot = slot or "MAINHANDSLOT";
	end
	if ( visualID or forceGo ) then
		self.jumpToVisualID = visualID;
		if ( self.activeCategory ~= categoryID or self.activeSlot ~= slot ) then
			self:SetActiveSlot(slot, transmogType, categoryID);
		else
			self:ResetPage();
		end
	end
end

function WardrobeItemsCollectionMixin:SetAppearanceTooltip(frame)
	GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
	self.tooltipVisualID = frame.visualInfo.visualID;
	self:RefreshAppearanceTooltip();
end

function WardrobeItemsCollectionMixin:RefreshAppearanceTooltip()
	if ( not self.tooltipVisualID ) then
		return;
	end
	local sources = CollectionWardrobeUtil.GetSortedAppearanceSources(self.tooltipVisualID, self.activeCategory);
	local chosenSourceID = self:GetChosenVisualSource(self.tooltipVisualID);
	WardrobeCollectionFrame_SetAppearanceTooltip(self, sources, chosenSourceID, ezCollections.Config.Wardrobe.ShowSetsInAppearances);
end

function WardrobeItemsCollectionMixin:ClearAppearanceTooltip()
	self.tooltipVisualID = nil;
	WardrobeCollectionFrame_HideAppearanceTooltip();
end

-- ***** MODELS

ModelMixin = { };
function ModelMixin:RefreshCamera() end
function ModelMixin:CanSetUnit(unitID) return true; end
function ModelMixin:SetUseTransmogSkin(use) end
function ModelMixin:SetDoBlend(blend) end
function ModelMixin:SetKeepModelOnHide(keep) end
function ModelMixin:UndressSlot(slot) end
function ModelMixin:FreezeAnimation() end
function ModelMixin:SetAutoDress() end
function ModelMixin:TransformCameraSpaceToModelSpace(x, y, z) return x * self:GetModelScale(), y * self:GetModelScale(), z * self:GetModelScale(); end

TransmogModelMixin = { };
do
	local model = CreateFrame("DressUpModel");
	TransmogModelMixin.oSetUnit = model.SetUnit;
	TransmogModelMixin.oTryOn = model.TryOn;
end
function TransmogModelMixin:SetType(type, force)
	if self.type == type and not force then
		return;
	end
	self.type = type;
	self:SetPosition(0, 0, 0);
	self:SetRotation(0);
	self.cameraAnimID = nil;
	if self.type == "player" then
		self.animID = ANIMATION_ARMOR_PREVIEW;
		self:SetUnit("player", false);
	elseif self.type == "main" then
		self.animID = ANIMATION_WEAPON_PREVIEW_MAIN;
		self:SetCreature(ezCollections.CreatureWeaponPreview);
	elseif self.type == "off" then
		self.animID = ANIMATION_WEAPON_PREVIEW_OFF;
		self:SetCreature(ezCollections.CreatureWeaponPreview);
	end
end
function TransmogModelMixin:RefreshType()
	self:SetType(self.type, true);
end
function TransmogModelMixin:SetUnit(...)
	self:SetPosition(0, 0, 0);
	self:SetFacing(0);
	self.cameraAnimID = nil;
	self:oSetUnit(...);
end
function TransmogModelMixin:UndressSlot(slot)
	self:RefreshType();
end
function TransmogModelMixin:TryOn(item, slot, illusion)
	if type(item) == "number" then
		if illusion then
			self:oTryOn("item:"..item..":"..illusion);
		else
			self:oTryOn("item:"..item);
		end
	else
		self:oTryOn(item);
	end
end
function TransmogModelMixin:SetItemAppearance(visualID, enchant)
	if visualID == ezCollections:GetHiddenVisualItem() then
		return;
	end
	enchant = enchant and ezCollections:GetEnchantFromScroll(enchant) or nil;
	if enchant then
		self:TryOn("item:" .. visualID .. ":" .. enchant);
	else
		self:TryOn(visualID);
	end
end

WardrobeItemsModelMixin = { };

function WardrobeItemsModelMixin:OnLoad()
	Mixin(self, ModelMixin, TransmogModelMixin);
	self:SetModelScale(10);
	self:SetType("player");

	self:RegisterEvent("UI_SCALE_CHANGED");
	self:RegisterEvent("DISPLAY_SIZE_CHANGED");
	self:SetAutoDress(false);

	local lightValues = { enabled=1, omni=0, dirX=-1, dirY=1, dirZ=-1, ambIntensity=1.05, ambR=1, ambG=1, ambB=1, dirIntensity=0, dirR=1, dirG=1, dirB=1 };
	self:SetLight(lightValues.enabled, lightValues.omni, 
			lightValues.dirX, lightValues.dirY, lightValues.dirZ,
			lightValues.ambIntensity, lightValues.ambR, lightValues.ambG, lightValues.ambB,
			lightValues.dirIntensity, lightValues.dirR, lightValues.dirG, lightValues.dirB);
end

function WardrobeItemsModelMixin:OnModelLoaded()
	if ( self.cameraID ) then
		Model_ApplyUICamera(self, self.cameraID);
	end
end

function WardrobeItemsModelMixin:OnMouseDown(button)
	local itemsCollectionFrame = self:GetParent();
	local transmogType = self:GetParent().transmogType;
	if ( IsModifiedClick("CHATLINK") ) then
		local link;
		if ( transmogType == LE_TRANSMOG_TYPE_ILLUSION ) then
			local name;
			name, link = C_TransmogCollection.GetIllusionStrings(self.visualInfo.sourceID);
		else
			local sources = CollectionWardrobeUtil.GetSortedAppearanceSources(self.visualInfo.visualID, itemsCollectionFrame:GetActiveCategory());
			if ( WardrobeCollectionFrame.tooltipSourceIndex ) then
				local index = CollectionWardrobeUtil.GetValidIndexForNumSources(WardrobeCollectionFrame.tooltipSourceIndex, #sources);
				link = select(6, C_TransmogCollection.GetAppearanceSourceInfo(sources[index].sourceID));
			end
		end
		if ( link ) then
			HandleModifiedItemClick(link);
		end
		return;
	elseif ( IsModifiedClick("DRESSUP") ) then
		local slot = self:GetParent():GetActiveSlot();
		if ( transmogType == LE_TRANSMOG_TYPE_APPEARANCE ) then
			local sourceID = self:GetParent():GetAnAppearanceSourceFromVisual(self.visualInfo.visualID);
			-- don't specify a slot for ranged weapons
			if ( WardrobeUtils_IsCategoryRanged(self:GetParent():GetActiveCategory()) ) then
				slot = nil;
			end
			DressUpVisual(sourceID, slot);
		elseif ( transmogType == LE_TRANSMOG_TYPE_ILLUSION ) then
			local weaponSourceID = WardrobeCollectionFrame_GetWeaponInfoForEnchant(slot);
			local enchant = ezCollections:GetEnchantFromScroll(self.visualInfo.sourceID);
			if C_TransmogCollection.IsAppearanceHiddenVisual(self.visualInfo.sourceID) then
				enchant = ezCollections:GetHiddenEnchant();
			end
			if enchant then
				DressUpVisual("item:"..weaponSourceID..":"..enchant, slot);
			else
				DressUpVisual("item:"..weaponSourceID, slot);
			end
		end
		return;
	end

	if ( button == "LeftButton" ) then
		CloseDropDownMenus();
		self:GetParent():SelectVisual(self.visualInfo.visualID);
	elseif ( button == "RightButton" ) then
		local dropDown = self:GetParent().RightClickDropDown;
		if ( dropDown.activeFrame ~= self ) then
			CloseDropDownMenus();
		end
		if ( --[[not self.visualInfo.isCollected or]] self.visualInfo.isHideVisual or transmogType == LE_TRANSMOG_TYPE_ILLUSION ) then
			if not ezCollections.Developer then return; end
		end
		dropDown.activeFrame = self;
		ToggleDropDownMenu(1, nil, dropDown, self, -6, -3);
		PlaySound("igMainMenuOptionCheckBoxOn");
	end
end

function WardrobeItemsModelMixin:OnEnter()
	if ( not self.visualInfo ) then
		return;
	end
	if ( C_TransmogCollection.IsNewAppearance(self.visualInfo.visualID) ) then
		C_TransmogCollection.ClearNewAppearance(self.visualInfo.visualID);
		self.NewString:Hide();
		self.NewGlow:Hide();
	end
	if ( self:GetParent().transmogType == LE_TRANSMOG_TYPE_ILLUSION ) then
		local visualID, name = C_TransmogCollection.GetIllusionSourceInfo(self.visualInfo.sourceID);
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(name);

		local sourceText = CollectionWardrobeUtil.GetAppearanceSourceTextWithDrops(self.visualInfo, self.visualInfo.sourceText);
		if ( sourceText ) then
			GameTooltip:AddLine(sourceText, 1, 1, 1, 1);
		end

		local enchant = ezCollections:GetEnchantFromScroll(self.visualInfo.sourceID);
		if enchant then
			local variants = ezCollections:GetScrollVariantsFromEnchant(enchant);
			if variants then
				for _, variant in ipairs(variants) do
					if variant ~= self.visualInfo.sourceID then
						local _, name = C_TransmogCollection.GetIllusionSourceInfo(variant);
						GameTooltip:AddLine(format(ezCollections.L["Tooltip.Transmog.EnchantVariantFormat"], name), GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
					end
				end
			end
		end

		if ezCollections.Developer then
			GameTooltip:AddLine("ID "..self.visualInfo.sourceID.."  ||  "..(ezCollections:GetEnchantFromScroll(self.visualInfo.sourceID) or ezCollections:GetHiddenEnchant()), 0.25, 0.25, 0.25, 1, 1);
		elseif ezCollections.Config.Wardrobe.ShowItemID and not C_TransmogCollection.IsAppearanceHiddenVisual(self.visualInfo.sourceID) then
			GameTooltip:AddLine("ID "..self.visualInfo.sourceID, 0.5, 0.5, 0.5, 1, 1);
		end

		GameTooltip:Show();
	else
		self:GetParent():SetAppearanceTooltip(self);
	end
end

function WardrobeItemsModelMixin:OnLeave()
	ResetCursor();
	self:GetParent():ClearAppearanceTooltip();
end

function WardrobeItemsModelMixin:OnUpdate()
	self:SetSequenceTime(self.cameraAnimID or self.animID, 0);
	if GetMouseFocus() == self then
		if IsModifiedClick("DRESSUP") then
			ShowInspectCursor();
		else
			ResetCursor();
		end
	end
end

function WardrobeItemsModelMixin:Reload(reloadSlot)
	if ( self:IsShown() ) then
		if ( WARDROBE_MODEL_SETUP[reloadSlot] ) then
			self:SetUseTransmogSkin(WARDROBE_MODEL_SETUP[reloadSlot].useTransmogSkin);
			self:RefreshType();
			self:SetDoBlend(false);
			for slot, equip in pairs(WARDROBE_MODEL_SETUP[reloadSlot].slots) do
				if ( equip ) then
					self:TryOn(WARDROBE_MODEL_SETUP_GEAR[slot]);
				end
			end
		end
		self:SetKeepModelOnHide(true);
		self.cameraID = nil;
		self.needsReload = nil;
	else
		self.needsReload = true;
	end
end

function WardrobeItemsModelMixin:OnShow()
	if ( self.needsReload ) then
		self:Reload(self:GetParent():GetActiveSlot());
	end
end

function WardrobeItemsModelMixin:OnHide()
	self:SetPosition(0, 0, 0);
	self:SetFacing(0);
	self.cameraAnimID = nil;
	self.cameraID = nil;
end

WardrobeSetsTransmogModelMixin = { };

function WardrobeSetsTransmogModelMixin:OnLoad()
	Mixin(self, ModelMixin, TransmogModelMixin);
	Mixin(self.Favorite.Icon, SetShownMixin);
	self:RegisterEvent("UI_SCALE_CHANGED");
	self:RegisterEvent("DISPLAY_SIZE_CHANGED");
	self:SetAutoDress(false);
	self:FreezeAnimation(0, 0, 0);
	local x, y, z = self:TransformCameraSpaceToModelSpace(0, 0, -0.25);
	self:SetPosition(x, y, z);
	self:SetLight(1, 0, -1, 1, -1, 1, 1, 1, 1, 0, 1, 1, 1);
end

function WardrobeSetsTransmogModelMixin:OnEvent()
	self:RefreshCamera();
	local x, y, z = self:TransformCameraSpaceToModelSpace(0, 0, -0.25);
	self:SetPosition(x, y, z);
end

function WardrobeSetsTransmogModelMixin:OnMouseDown(button)
	if ( button == "LeftButton" ) then
		self:GetParent():SelectSet(self.setID);
		PlaySound("igChatBottom");
	elseif ( button == "RightButton" ) then
		local dropDown = self:GetParent().RightClickDropDown;
		if ( dropDown.activeFrame ~= self ) then
			CloseDropDownMenus();
		end
		dropDown.activeFrame = self;
		ToggleDropDownMenu(1, nil, dropDown, self, -6, -3);
		PlaySound("igMainMenuOptionCheckBoxOn");
	end
end

function WardrobeSetsTransmogModelMixin:OnEnter()
	self:GetParent().tooltipModel = self;
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	self:RefreshTooltip();
end

function WardrobeSetsTransmogModelMixin:RefreshTooltip()
	local totalQuality = 0;
	local numTotalSlots = 0;
	local waitingOnQuality = false;
	local sourceQualityTable = self:GetParent().sourceQualityTable;
	local sources = C_TransmogSets.GetSetSources(self.setID);
	for sourceID in pairs(sources) do
		numTotalSlots = numTotalSlots + 1;
		if ( sourceQualityTable[sourceID] ) then
			totalQuality = totalQuality + sourceQualityTable[sourceID];
		else
			local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID);
			if ( sourceInfo and sourceInfo.quality ) then
				sourceQualityTable[sourceID] = sourceInfo.quality;
				totalQuality = totalQuality + sourceInfo.quality;
			else
				waitingOnQuality = true;
			end
		end
	end
	if ( waitingOnQuality ) then
		GameTooltip:SetText(RETRIEVING_ITEM_INFO, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
	else
		local setQuality = Round(totalQuality / numTotalSlots);
		local r, g, b = GetItemQualityColor(setQuality);
		local setInfo = C_TransmogSets.GetSetInfo(self.setID);
		GameTooltip:SetText(setInfo.name, r, g, b);
		if ( setInfo.label ) then
			GameTooltip:AddLine(setInfo.label);
		end
		if ezCollections.Config.Wardrobe.ShowSetID then
			GameTooltip:AddLine("ID "..self.setID, 0.5, 0.5, 0.5, 1, 1);
		end

		-- Listing failed slots
		local sources = C_TransmogSets.GetSetSources(self.setID);
		local slotState = { };
		local failedSlots = { };
		for sourceID in pairs(sources) do
			local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID);
			local slot = C_Transmog.GetSlotForInventoryType(sourceInfo.invType);
			slotState[slot] = false;
			failedSlots[slot] = true;
		end
		local usableSources = C_TransmogSets.GetUsableSetSources(self.setID);
		if usableSources then
			for sourceID in pairs(usableSources) do
				local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID);
				local slot = C_Transmog.GetSlotForInventoryType(sourceInfo.invType);
				slotState[slot] = true;
				failedSlots[slot] = nil;
			end
		end
		if next(failedSlots) then
			GameTooltip:AddLine(" ");
			GameTooltip:AddLine(ezCollections.L["Transmog.Sets.MissingSlots"]);
			for _, slot in ipairs({ 1, 3, 15, 5, 19, 4, 9, 10, 6, 7, 8, 16, 17, 18 }) do
				local slotName = ezCollections.TransmogrifiableSlots[slot];
				slotName = slotName and _G[slotName:upper()] or slotName;
				if slotState[slot] ~= nil and slotName then
					local hasCollectedSources = false;
					local hasNotStoreOnlySources = false;
					local slotSources = C_TransmogSets.GetSourcesForSlot(self.setID, slot);
					for _, source in ipairs(slotSources) do
						if not hasCollectedSources and source.isCollected then
							hasCollectedSources = true;
						end
						if not hasNotStoreOnlySources and not ezCollections:IsStoreOrSubscriptionExclusiveItem(source.sourceID) then
							hasNotStoreOnlySources = true;
						end
					end

					if slotState[slot] then
						GameTooltip:AddDoubleLine(slotName, ezCollections.L["Transmog.Sets.MissingSlots.Collected"], 1, 1, 1, 0, 1, 0);
					elseif hasCollectedSources then
						GameTooltip:AddDoubleLine(slotName, ezCollections.L["Transmog.Sets.MissingSlots.Incompatible"], 1, 1, 1, 1, 0, 0);
					elseif hasNotStoreOnlySources then
						GameTooltip:AddDoubleLine(slotName, ezCollections.L["Transmog.Sets.MissingSlots.NotCollected"], 1, 1, 1, 0.5, 0.5, 0.5);
					else
						GameTooltip:AddDoubleLine(slotName, ezCollections.L["Transmog.Sets.MissingSlots.NotCollectedStoreOnly"], 1, 1, 1, 0.5, 0.5, 0.5);
					end
				end
			end
		end
	end
	GameTooltip:Show();
end

function WardrobeSetsTransmogModelMixin:OnLeave()
	GameTooltip:Hide();
	self:GetParent().tooltipModel = nil;
	WardrobeCollectionFrame:EnableKeyboard(false);
end

function WardrobeSetsTransmogModelMixin:OnShow()
	self:SetType("player");
	self:OnModelLoaded();
end

function WardrobeSetsTransmogModelMixin:OnHide()
	self:SetPosition(0, 0, 0);
	self:SetFacing(0);
	self.setID = nil;
end

function WardrobeSetsTransmogModelMixin:OnModelLoaded()
	if ( self.cameraID ) then
		Model_ApplyUICamera(self, self.cameraID);
	end
end

function WardrobeCollectionFrame_HideAppearanceTooltip()
	WardrobeCollectionFrame.tooltipContentFrame = nil;
	WardrobeCollectionFrame.tooltipCycle = nil;
	WardrobeCollectionFrame.tooltipSourceIndex = nil;
	GameTooltip:Hide();
	WardrobeCollectionFrame:EnableKeyboard(false);
end

function WardrobeCollectionFrame_SetAppearanceTooltip(contentFrame, sources, primarySourceID, showSets)
	local self = WardrobeCollectionFrame;

	self.tooltipContentFrame = contentFrame;
	local selectedIndex = self.tooltipSourceIndex;
	local showUseError = true;
	local inLegionArtifactCategory = false;

	if ( not selectedIndex ) then
		if contentFrame and contentFrame.tooltipItemFrame then
			for i = 1, #sources do
				if sources[i].sourceID == contentFrame.tooltipItemFrame.previewedSource then
					selectedIndex = i;
					break;
				end
			end
		end
	end

	self.tooltipSourceIndex, self.tooltipCycle = CollectionWardrobeUtil.SetAppearanceTooltip(GameTooltip, sources, primarySourceID, selectedIndex, showUseError, inLegionArtifactCategory, nil, showSets);

	self:EnableKeyboard(self.tooltipCycle and ezCollections.Config.Wardrobe.TooltipCycleKeyboard);
	if contentFrame.tooltipItemFrame then
		contentFrame.tooltipItemFrame:EnableMouseWheel(ezCollections.Config.Wardrobe.TooltipCycleMouseWheel);
	end
	return sources[self.tooltipSourceIndex];
end

function WardrobeItemsCollectionMixin:GetChosenVisualSource(visualID)
	return self.chosenVisualSources[visualID] or NO_TRANSMOG_SOURCE_ID;
end

function WardrobeItemsCollectionMixin:SetChosenVisualSource(visualID, sourceID)
	self.chosenVisualSources[visualID] = sourceID;
end

function WardrobeItemsCollectionMixin:ValidateChosenVisualSources()
	for visualID, sourceID in pairs(self.chosenVisualSources) do
		if ( sourceID ~= NO_TRANSMOG_SOURCE_ID ) then
			local keep = false;
			local sources = C_TransmogCollection.GetAppearanceSources(visualID, self.activeCategory);
			if ( sources ) then
				for i = 1, #sources do
					if ( sources[i].sourceID == sourceID ) then
						if ( sources[i].isCollected and not sources[i].useError ) then
							keep = true;
						end
						break;
					end
				end
			end
			if ( not keep ) then
				self.chosenVisualSources[visualID] = NO_TRANSMOG_SOURCE_ID;
			end
		end
	end
end

function WardrobeCollectionFrameRightClickDropDown_Init(self, level, menuList)
	local appearanceID = self.activeFrame.visualInfo.visualID;
	local skin = ezCollections:GetSkinInfo(appearanceID);
	local info = UIDropDownMenu_CreateInfo();
	if level ~= 1 then
		if menuList == "Sets" then
			info.notCheckable = true;
			if skin and skin.Sets then
				for _, setID in ipairs(skin.Sets) do
					local set = ezCollections.Cache.Sets[setID];
					info.text = format(ezCollections.L["Transmog.Items.ViewSet.Format"], set.name, set.description);
					info.func = function()
						if not CollectionsJournal:IsVisible() or not WardrobeCollectionFrame:IsVisible() then
							ToggleCollectionsJournal(COLLECTIONS_JOURNAL_TAB_INDEX_APPEARANCES);
						end
						WardrobeCollectionFrame_SetTab(TAB_SETS);
						WardrobeCollectionFrame.SetsCollectionFrame:SelectSet(setID);
						WardrobeCollectionFrame.SetsCollectionFrame:ScrollToSet(C_TransmogSets.GetBaseSetID(setID));
					end;
					UIDropDownMenu_AddButton(info, level);
				end
			end
			return;
		elseif menuList == "SourceMask" then
			for i = 1, C_TransmogCollection.GetNumTransmogSources() do
				if i ~= TRANSMOG_SOURCE_SUBSCRIPTION then
					info.text = _G["TRANSMOG_SOURCE_"..i];
					info.value = i;
					info.checked = bit.band(skin and skin.SourceMask or 0, bit.lshift(1, i - 1)) ~= 0;
					info.keepShownOnClick = true;
					info.func = function(button, _, _, checked)
						local value = skin and skin.SourceMask or 0;
						if checked then
							value = bit.bor(value, bit.lshift(1, i - 1));
						else
							value = bit.band(value, bit.bnot(bit.lshift(1, i - 1)));
						end
						if skin then
							skin.SourceMask = value;
							if skin.SourceMask == 0 then
								skin.SourceMask = nil;
							end
						end
						ezCollections:SendAddonMessage(format("DEV:SETSOURCEMASK:%d:%d", appearanceID, value));
						ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
						for i = 1, UIDROPDOWNMENU_MAXBUTTONS do
							local b = _G["DropDownList1Button"..i];
							if b and b:IsShown() and b.menuList == "SourceMask" then
								b:SetText(format("Sources: |cFF00FF00%s|r", C_TransmogCollection.GetAppearanceSources(appearanceID)[1].sourceText or ""));
							end
							b = _G["DropDownList2Button"..i];
							if b and b:IsShown() and b.value then
								local checkImage = _G["DropDownList2Button"..i.."Check"];
								local checked = skin and bit.band(skin.SourceMask or 0, bit.lshift(1, b.value - 1)) ~= 0;
								if checked then
									b:LockHighlight();
									checkImage:Show();
								else
									b:UnlockHighlight();
									checkImage:Hide();
								end
							end
						end
					end;
					UIDropDownMenu_AddButton(info, level);
				end
			end
			return;
		elseif menuList == "Subscription" then
			local sortedNames = { "- NONE -" };
			local nameToSubscriptionID = { ["- NONE -"] = 0 };
			for id, subscription in pairs(ezCollections.Subscriptions) do
				table.insert(sortedNames, subscription.Name);
				nameToSubscriptionID[subscription.Name] = id;
			end
			table.sort(sortedNames);
			local appearanceSubscriptionID = ezCollections.SubscriptionBySkin[appearanceID] or 0;
			for _, name in ipairs(sortedNames) do
				info.text = name;
				info.value = nameToSubscriptionID[name];
				info.checked = appearanceSubscriptionID == info.value;
				info.keepShownOnClick = true;
				info.func = function(button)
					local subscription = button.value;
					if appearanceSubscriptionID ~= 0 then
						tDeleteItem(ezCollections.Subscriptions[appearanceSubscriptionID].Skins, appearanceID);
						ezCollections.SubscriptionBySkin[appearanceID] = nil;
					end
					if skin then
						skin.SourceMask = bit.band(skin.SourceMask or 0, bit.bnot(bit.lshift(1, TRANSMOG_SOURCE_SUBSCRIPTION - 1)));
						if skin.SourceMask == 0 then
							skin.SourceMask = nil;
						end
					end
					if subscription ~= 0 then
						ezCollections.SubscriptionBySkin[appearanceID] = subscription;
						table.insert(ezCollections.Subscriptions[subscription].Skins, appearanceID);
						if skin then
							skin.SourceMask = bit.bor(skin.SourceMask or 0, bit.lshift(1, TRANSMOG_SOURCE_SUBSCRIPTION - 1));
						end
					end
					ezCollections:SendAddonMessage(format("DEV:SETSUBSCRIPTION:%d:%d", appearanceID, subscription));
					ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
					for i = 1, UIDROPDOWNMENU_MAXBUTTONS do
						local b = _G["DropDownList1Button"..i];
						if b and b:IsShown() and b.menuList == "Subscription" then
							b:SetText(format("Subscription: |cFF00FF00%s|r", subscription ~= 0 and ezCollections.Subscriptions[subscription].Name or "- NONE -"));
						end
						b = _G["DropDownList2Button"..i];
						if b and b:IsShown() and b.value then
							local checkImage = _G["DropDownList2Button"..i.."Check"];
							local checked = b.value == button.value;
							if checked then
								b:LockHighlight();
								checkImage:Show();
							else
								b:UnlockHighlight();
								checkImage:Hide();
							end
						end
					end
				end;
				UIDropDownMenu_AddButton(info, level);
			end
			return;
		elseif menuList == "Camera" then
			local sortedNames = { "- NONE -" };
			local nameToCameraID = { ["- NONE -"] = 0 };
			for id, camera in pairs(ezCollections.Cache.Cameras) do
				local x, y, z, f, anim, name = unpack(camera);
				table.insert(sortedNames, name);
				nameToCameraID[name] = id;
			end
			table.sort(sortedNames);
			local appearanceCameraID = C_TransmogCollection.GetAppearanceCameraID(appearanceID, WardrobeCollectionFrame.ItemsCollectionFrame:GetActiveCategory());
			for _, name in ipairs(sortedNames) do
				info.text = name;
				info.value = nameToCameraID[name];
				info.checked = appearanceCameraID >= 0 and info.value == 0 or appearanceCameraID < 0 and appearanceCameraID == -info.value;
				info.keepShownOnClick = true;
				info.func = function(button)
					local camera = button.value % ezCollections.SexToCameraID[1];
					if skin then
						skin.Camera = camera ~= 0 and camera or nil;
					end
					ezCollections:SendAddonMessage(format("DEV:SETCAMERA:%d:%d", appearanceID, camera));
					ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
					for i = 1, UIDROPDOWNMENU_MAXBUTTONS do
						local b = _G["DropDownList1Button"..i];
						if b and b:IsShown() and b.menuList == "Camera" then
							b:SetText(format("Camera: |cFF00FF00%s|r", camera ~= 0 and select(6, unpack(ezCollections.Cache.Cameras[button.value])) or "- NONE -"));
						end
						b = _G["DropDownList2Button"..i];
						if b and b:IsShown() and b.value then
							local checkImage = _G["DropDownList2Button"..i.."Check"];
							local checked = b.value == button.value;
							if checked then
								b:LockHighlight();
								checkImage:Show();
							else
								b:UnlockHighlight();
								checkImage:Hide();
							end
						end
					end
				end;
				UIDropDownMenu_AddButton(info, level);
			end
			return;
		end
		return;
	end
	-- Set Favorite
	if ( C_TransmogCollection.GetIsAppearanceFavorite(appearanceID) ) then
		info.text = BATTLE_PET_UNFAVORITE;
		info.arg1 = appearanceID;
		info.arg2 = 0;
	else
		info.text = BATTLE_PET_FAVORITE;
		info.arg1 = appearanceID;
		info.arg2 = 1;
		if ( not C_TransmogCollection.CanSetFavoriteInCategory(WardrobeCollectionFrame.ItemsCollectionFrame:GetActiveCategory()) ) then
			info.tooltipWhileDisabled = 1
			info.tooltipTitle = BATTLE_PET_FAVORITE;
			info.tooltipText = TRANSMOG_CATEGORY_FAVORITE_LIMIT;
			info.tooltipOnButton = 1;
			info.disabled = 1;
		end
	end
	info.notCheckable = true;
	info.func = function(_, visualID, value) WardrobeCollectionFrameModelDropDown_SetFavorite(visualID, value); end;
	UIDropDownMenu_AddButton(info);
	-- View Set
	if skin and skin.Sets then
		info = UIDropDownMenu_CreateInfo();
		info.notCheckable = true;
		if #skin.Sets == 1 then
			local setID = skin.Sets[1];
			local set = ezCollections.Cache.Sets[setID];
			info.text = format(ezCollections.L["Transmog.Items.ViewSet.Singular"], set.name, set.description);
			info.func = function()
				if not CollectionsJournal:IsVisible() or not WardrobeCollectionFrame:IsVisible() then
					ToggleCollectionsJournal(COLLECTIONS_JOURNAL_TAB_INDEX_APPEARANCES);
				end
				WardrobeCollectionFrame_SetTab(TAB_SETS);
				WardrobeCollectionFrame.SetsCollectionFrame:SelectSet(setID);
				WardrobeCollectionFrame.SetsCollectionFrame:ScrollToSet(C_TransmogSets.GetBaseSetID(setID));
			end;
		else
			info.text = ezCollections.L["Transmog.Items.ViewSet.Plural"];
			info.hasArrow = true;
			info.menuList = "Sets";
			info.keepShownOnClick = true;
			info.func = function(self) _G[self:GetName().."Check"]:Hide(); end;
		end
		UIDropDownMenu_AddButton(info);
	end
	-- Cancel
	info = UIDropDownMenu_CreateInfo();
	info.notCheckable = true;
	info.text = CANCEL;
	UIDropDownMenu_AddButton(info);

	--[[
	local headerInserted = false;
	local sources = CollectionWardrobeUtil.GetSortedAppearanceSources(appearanceID, WardrobeCollectionFrame.ItemsCollectionFrame:GetActiveCategory());
	local chosenSourceID = WardrobeCollectionFrame.ItemsCollectionFrame:GetChosenVisualSource(appearanceID);
	info.func = WardrobeCollectionFrameModelDropDown_SetSource;
	for i = 1, #sources do
		if ( sources[i].isCollected and not sources[i].useError ) then
			if ( not headerInserted ) then
				headerInserted = true;
				-- space
				info.text = " ";
				info.disabled = true;
				UIDropDownMenu_AddButton(info);
				info.disabled = nil;
				-- header
				info.text = WARDROBE_TRANSMOGRIFY_AS;
				info.isTitle = true;
				info.colorCode = NORMAL_FONT_COLOR_CODE;
				UIDropDownMenu_AddButton(info);
				info.isTitle = nil;
				-- turn off notCheckable
				info.notCheckable = nil;
			end
			if ( sources[i].name ) then
				info.text = sources[i].name;
				info.colorCode = select(4, GetItemQualityColor(sources[i].quality));
			else
				ezCollections:QueryItem(sources[i].sourceID);
				info.text = RETRIEVING_ITEM_INFO;
				info.colorCode = RED_FONT_COLOR_CODE;
			end
			info.disabled = nil;
			info.arg1 = appearanceID;
			info.arg2 = sources[i].sourceID;
			-- choose the 1st valid source if one isn't explicitly chosen
			if ( chosenSourceID == NO_TRANSMOG_SOURCE_ID ) then
				chosenSourceID = sources[i].sourceID;
			end
			info.checked = (chosenSourceID == sources[i].sourceID);
			UIDropDownMenu_AddButton(info);
		end
	end
	]]
	if ezCollections.Developer then
		info = UIDropDownMenu_CreateInfo();
		info.text = " ";
		info.disabled = true;
		UIDropDownMenu_AddButton(info);

		info = UIDropDownMenu_CreateInfo();
		info.text = "Developer";
		info.isTitle = true;
		info.notCheckable = true;
		UIDropDownMenu_AddButton(info);

		info = UIDropDownMenu_CreateInfo();
		info.text = "";
		info.isTitle = true;
		info.notCheckable = true;
		UIDropDownMenu_AddButton(info);

		info = UIDropDownMenu_CreateInfo();
		info.text = format("|T%s:64|t %s", ezCollections:GetSkinIcon(appearanceID), select(2, GetItemInfo(appearanceID)));
		info.isTitle = true;
		info.notCheckable = true;
		UIDropDownMenu_AddButton(info);

		info = UIDropDownMenu_CreateInfo();
		info.text = "";
		info.isTitle = true;
		info.notCheckable = true;
		UIDropDownMenu_AddButton(info);

		info = UIDropDownMenu_CreateInfo();
		info.text = ezCollections:HasSkin(appearanceID) and "Lock" or "Unlock";
		info.notCheckable = true;
		info.func = function() ezCollections:SendAddonMessage(format("DEV:%sLOCKSKIN:%d", ezCollections:HasSkin(appearanceID) and "" or "UN", appearanceID)); end;
		UIDropDownMenu_AddButton(info);

		if WardrobeCollectionFrame.ItemsCollectionFrame.transmogType == LE_TRANSMOG_TYPE_APPEARANCE and not C_TransmogCollection.IsAppearanceHiddenVisual(appearanceID) then
			local cameraID = C_TransmogCollection.GetAppearanceCameraID(appearanceID, WardrobeCollectionFrame.ItemsCollectionFrame:GetActiveCategory());
			local camera = cameraID < 0 and ezCollections.Cache.Cameras[-cameraID];
			local subscription = ezCollections:GetSubscriptionForSkin(appearanceID);

			info = UIDropDownMenu_CreateInfo();
			info.text = format("|cFF%sObtainable|r", skin.Unobtainable and "FF0000" or "FFFFFF");
			info.checked = not skin.Unobtainable;
			info.func = function(_, _, _, checked)
				skin.Unobtainable = checked or nil;
				ezCollections:SendAddonMessage(format("DEV:SETOBTAINABLE:%d:%d", appearanceID, checked and 0 or 1));
			end;
			UIDropDownMenu_AddButton(info);

			info = UIDropDownMenu_CreateInfo();
			info.text = format("Sources: |cFF00FF00%s|r", C_TransmogCollection.GetAppearanceSources(appearanceID)[1].sourceText or "");
			info.notCheckable = true;
			info.hasArrow = true;
			info.menuList = "SourceMask";
			UIDropDownMenu_AddButton(info);

			info = UIDropDownMenu_CreateInfo();
			info.text = format("Subscription: |cFF00FF00%s|r", subscription and subscription.Name or "- NONE -");
			info.notCheckable = true;
			info.hasArrow = true;
			info.menuList = "Subscription";
			UIDropDownMenu_AddButton(info);

			info = UIDropDownMenu_CreateInfo();
			info.text = format("Camera: |cFF00FF00%s|r", camera and select(6, unpack(camera)) or "- NONE -");
			info.notCheckable = true;
			info.hasArrow = true;
			info.menuList = "Camera";
			UIDropDownMenu_AddButton(info);
		end
	end
end

function WardrobeCollectionFrameModelDropDown_SetSource(self, visualID, sourceID)
	WardrobeCollectionFrame.ItemsCollectionFrame:SetChosenVisualSource(visualID, sourceID);
end

function WardrobeCollectionFrameModelDropDown_SetFavorite(visualID, value, confirmed)
	local set = (value == 1);
	if ( set and not confirmed ) then
		local allSourcesConditional = true;
		local sources = C_TransmogCollection.GetAppearanceSources(visualID, WardrobeCollectionFrame.ItemsCollectionFrame:GetActiveCategory());
		for i, sourceInfo in ipairs(sources) do
			local info = C_TransmogCollection.GetAppearanceInfoBySource(sourceInfo.sourceID);
			if ( info.sourceIsCollectedPermanent ) then
				allSourcesConditional = false;
				break;
			end
		end
		if ( allSourcesConditional ) then
			StaticPopup_Show("TRANSMOG_FAVORITE_WARNING", nil, nil, visualID);
			return;
		end
	end
	C_TransmogCollection.SetIsAppearanceFavorite(visualID, set);
	ezCollections:SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_TRANSMOG_MODEL_CLICK, true);
	WardrobeCollectionFrame.ItemsCollectionFrame.HelpBox:Hide();
end

-- ***** WEAPON DROPDOWN

function WardrobeCollectionFrameWeaponDropDown_OnLoad(self)
	UIDropDownMenu_Initialize(self, WardrobeCollectionFrameWeaponDropDown_Init);
	UIDropDownMenu_SetWidth(self, 140);
end

function WardrobeCollectionFrameWeaponDropDown_Init(self)
	if not WardrobeCollectionFrame.ItemsCollectionFrame or not WardrobeCollectionFrame.ItemsCollectionFrame.GetActiveSlot then return; end
	local slot = WardrobeCollectionFrame.ItemsCollectionFrame:GetActiveSlot();
	if ( not slot ) then
		return;
	end

	local selectedValue = UIDropDownMenu_GetSelectedValue(self);
	local info = UIDropDownMenu_CreateInfo();
	info.func = WardrobeCollectionFrameWeaponDropDown_OnClick;

	local equippedItemID = GetInventoryItemID("player", GetInventorySlotInfo(slot));
	local checkCategory = equippedItemID and WardrobeFrame_IsAtTransmogrifier();
	if ( checkCategory ) then
		-- if the equipped item cannot be transmogrified, relax restrictions
		local isTransmogrified, hasPending, isPendingCollected, canTransmogrify, cannotTransmogrifyReason, hasUndo = C_Transmog.GetSlotInfo(GetInventorySlotInfo(slot), LE_TRANSMOG_TYPE_APPEARANCE);
		if ( not canTransmogrify and not hasUndo ) then
			checkCategory = false;
		end
	end
	local buttonsAdded = 0;
	
	for categoryID = FIRST_TRANSMOG_COLLECTION_WEAPON_TYPE, LAST_TRANSMOG_COLLECTION_WEAPON_TYPE do
		local name, isWeapon, canEnchant, canMainHand, canOffHand, canRanged = C_TransmogCollection.GetCategoryInfo(categoryID);
		if ( name and isWeapon ) then
			if ( (slot == "MAINHANDSLOT" and canMainHand) or (slot == "SECONDARYHANDSLOT" and canOffHand) ) or slot == "RANGEDSLOT" and canRanged then
				if ( not checkCategory or C_TransmogCollection.IsCategoryValidForItem(categoryID, equippedItemID) ) then
					info.text = name;
					info.arg1 = categoryID;
					info.value = categoryID;
					if ( info.value == selectedValue ) then
						info.checked = 1;
					else
						info.checked = nil;
					end
					UIDropDownMenu_AddButton(info);
					buttonsAdded = buttonsAdded + 1;
				end
			end
		end
	end
	return buttonsAdded;
end

function WardrobeCollectionFrameWeaponDropDown_OnClick(self, category)
	if ( category and WardrobeCollectionFrame.ItemsCollectionFrame:GetActiveCategory() ~= category ) then
		CloseDropDownMenus();
		WardrobeCollectionFrame.ItemsCollectionFrame:SetActiveCategory(category);
	end	
end

-- ***** NAVIGATION

function WardrobeItemsCollectionMixin:OnPageChanged(userAction)
	PlaySound("igAbiliityPageTurn");
	CloseDropDownMenus();
	if ( userAction ) then
		self:UpdateItems();
	end
end

-- ***** SEARCHING

function WardrobeCollectionFrame_SwitchSearchCategory()
	if ( WardrobeCollectionFrame.searchBox:GetText() ~= "" )  then
		local finished = C_TransmogCollection.SetSearch(WardrobeCollectionFrame.activeFrame.searchType, WardrobeCollectionFrame.searchBox:GetText());
		if ( not finished ) then
			WardrobeCollectionFrame_RestartSearchTracking();
		end
	end
end

function WardrobeItemsCollectionMixin:OnSearchUpdate(category)
	if ( category ~= self.activeCategory ) then
		return;
	end

	self:RefreshVisualsList();
	if ( self.resetPageOnSearchUpdated ) then
		self.resetPageOnSearchUpdated = nil;
		self:ResetPage();
	elseif ( WardrobeFrame_IsAtTransmogrifier() and WardrobeCollectionFrameSearchBox:GetText() == "" ) then
		local _, _, selectedSourceID = WardrobeCollectionFrame_GetInfoForEquippedSlot(self.activeSlot, self.transmogType);
		local categoryID = C_TransmogCollection.GetAppearanceSourceInfo(selectedSourceID);
		if ( categoryID == self:GetActiveCategory() ) then
			WardrobeCollectionFrame.ItemsCollectionFrame:GoToSourceID(selectedSourceID, self.activeSlot, self.transmogType, true);
		else
			self:UpdateItems();
		end
	else
		self:UpdateItems();
	end
end

function WardrobeCollectionFrame_RestartSearchTracking()
	local searchSize = C_TransmogCollection.SearchSize(WardrobeCollectionFrame.activeFrame.searchType);
	local searchProgress = C_TransmogCollection.SearchProgress(WardrobeCollectionFrame.activeFrame.searchType);
	
	WardrobeCollectionFrame.searchProgressFrame:Hide();
	WardrobeCollectionFrame.searchBox.updateDelay = 0;
	if ( not C_TransmogCollection.IsSearchInProgress(WardrobeCollectionFrame.activeFrame.searchType) ) then
		WardrobeCollectionFrame.activeFrame:OnSearchUpdate();
	else
		WardrobeCollectionFrame.searchBox:SetScript("OnUpdate", WardrobeCollectionFrameSearchBox_OnUpdate);
		WardrobeCollectionFrameSearchBox_OnUpdate(WardrobeCollectionFrame.searchBox, 0);
	end
end

function WardrobeCollectionFrame_ClearSearch(searchType)
	WardrobeCollectionFrame.searchBox:SetText("");
	WardrobeCollectionFrame.searchProgressFrame:Hide();
	C_TransmogCollection.ClearSearch(searchType or WardrobeCollectionFrame.activeFrame.searchType);
end

function WardrobeCollectionFrameSearchProgressBar_OnLoad(self)
	self:SetStatusBarColor(0, .6, 0, 1);
	self:SetMinMaxValues(0, 1000);
	self:SetValue(0);
	self:GetStatusBarTexture():SetDrawLayer("BORDER");
end

function WardrobeCollectionFrameSearchProgressBar_OnHide(self)
	self:SetValue(0);
	self:SetScript("OnUpdate", nil);
end

function WardrobeCollectionFrameSearchProgressBar_OnUpdate(self, elapsed)
	local _, maxValue = self:GetMinMaxValues();
	local searchSize = C_TransmogCollection.SearchSize(WardrobeCollectionFrame.activeFrame.searchType);
	local searchProgress = C_TransmogCollection.SearchProgress(WardrobeCollectionFrame.activeFrame.searchType);
	self:SetValue((searchProgress * maxValue) / searchSize);
	
	if ( not C_TransmogCollection.IsSearchInProgress(WardrobeCollectionFrame.activeFrame.searchType) ) then
		WardrobeCollectionFrame.searchProgressFrame:Hide();
	end
end

function WardrobeCollectionFrameSearchBox_OnLoad(self)
	SearchBoxTemplate_OnLoad(self);
	self:SetScript("OnUpdate", nil);
	self.updateDelay = 0;
end

function WardrobeCollectionFrameSearchBox_OnHide(self)
	self:SetScript("OnUpdate", nil);
	self.updateDelay = 0;
	WardrobeCollectionFrame.searchProgressFrame:Hide();
end

function WardrobeCollectionFrameSearchBox_OnKeyDown(self, key, ...)
	if ( key == WARDROBE_CYCLE_KEY ) then
		WardrobeCollectionFrame_OnKeyDown(WardrobeCollectionFrame, key, ...);
	end
end

local WARDROBE_SEARCH_DELAY = 0;--0.6;
function WardrobeCollectionFrameSearchBox_OnUpdate(self, elapsed)
	self.updateDelay = self.updateDelay + elapsed;
	
	if ( not C_TransmogCollection.IsSearchInProgress(WardrobeCollectionFrame.activeFrame.searchType) ) then
		self:SetScript("OnUpdate", nil);
		self.updateDelay = 0;
	elseif ( self.updateDelay >= WARDROBE_SEARCH_DELAY ) then
		self:SetScript("OnUpdate", nil);
		self.updateDelay = 0;
		
		if ( not C_TransmogCollection.IsSearchDBLoading() ) then
			WardrobeCollectionFrame.searchProgressFrame.loading:Hide();
			WardrobeCollectionFrame.searchProgressFrame.searchProgressBar:Show();
			WardrobeCollectionFrame.searchProgressFrame.searchProgressBar:SetScript("OnUpdate", WardrobeCollectionFrameSearchProgressBar_OnUpdate);
		else
			WardrobeCollectionFrame.searchProgressFrame.loading:Show();
			WardrobeCollectionFrame.searchProgressFrame.searchProgressBar:Hide();
		end
		
		WardrobeCollectionFrame.searchProgressFrame:Show();
	end
end

function WardrobeCollectionFrameSearchBox_OnTextChanged(self)
	SearchBoxTemplate_OnTextChanged(self);
	
	local text = self:GetText();
	if text == (self.lastText or "") then return; end
	self.lastText = text;
	if ( text == "" ) then
		C_TransmogCollection.ClearSearch(WardrobeCollectionFrame.activeFrame.searchType);
	elseif not ezCollections:UseServersideTextSearch() then
		C_TransmogCollection.SetSearch(WardrobeCollectionFrame.activeFrame.searchType, text);
	end
	
	WardrobeCollectionFrame_RestartSearchTracking();
end

function WardrobeCollectionFrameSearchBox_OnEnterPressed(self)
	EditBox_ClearFocus(self);

	local text = self:GetText();
	if ( text == "" ) then
		C_TransmogCollection.ClearSearch(WardrobeCollectionFrame.activeFrame.searchType);
	else
		C_TransmogCollection.SetSearch(WardrobeCollectionFrame.activeFrame.searchType, text);
	end
	
	WardrobeCollectionFrame_RestartSearchTracking();
end

-- ***** FILTER

function WardrobeFilterDropDown_OnLoad(self)
	UIDropDownMenu_Initialize(self, WardrobeFilterDropDown_Initialize, "MENU");
end

function WardrobeFilterDropDown_Initialize(self, level)
	if ( not WardrobeCollectionFrame.activeFrame ) then
		return;
	end

	if ( WardrobeCollectionFrame.activeFrame.searchType == LE_TRANSMOG_SEARCH_TYPE_ITEMS ) then
		WardrobeFilterDropDown_InitializeItems(self, level);
	elseif ( WardrobeCollectionFrame.activeFrame.searchType == LE_TRANSMOG_SEARCH_TYPE_BASE_SETS ) then
		WardrobeFilterDropDown_InitializeBaseSets(self, level);
	elseif ( WardrobeCollectionFrame.activeFrame.searchType == LE_TRANSMOG_SEARCH_TYPE_USABLE_SETS ) then
		WardrobeFilterDropDown_InitializeUsableSets(self, level);
	end
end

function WardrobeFilterDropDown_InitializeItems(self, level)
	local info = UIDropDownMenu_CreateInfo();
	info.keepShownOnClick = true;
	local atTransmogrifier = WardrobeFrame_IsAtTransmogrifier();

	if level == 1 then
		info.text = COLLECTED
		info.func = function(_, _, _, value)
						C_TransmogCollection.SetCollectedShown(value);
					end 
		info.checked = C_TransmogCollection.GetCollectedShown();
		info.isNotRadio = true;
		UIDropDownMenu_AddButton(info, level)

		info.text = NOT_COLLECTED
		info.func = function(_, _, _, value)
						C_TransmogCollection.SetUncollectedShown(value);
					end 
		info.checked = C_TransmogCollection.GetUncollectedShown();
		info.isNotRadio = true;
		UIDropDownMenu_AddButton(info, level)

		info.checked = 	nil;
		info.isNotRadio = nil;
		info.func = function(self) _G[self:GetName().."Check"]:Hide(); end;
		info.hasArrow = true;
		info.notCheckable = true;

		info.text = ezCollections.L["Transmog.Sets.Filter.ArmorType"]
		info.value = 2;
		UIDropDownMenu_AddButton(info, level);

		info.text = ezCollections.L["Transmog.Sets.Filter.Classes"]
		info.value = 3;
		UIDropDownMenu_AddButton(info, level);

		info.text = ezCollections.L["Transmog.Sets.Filter.Races"]
		info.value = 4;
		UIDropDownMenu_AddButton(info, level);

		info.text = SOURCES
		info.value = 1;
		UIDropDownMenu_AddButton(info, level)

		info.text = EXPANSION_FILTER_TEXT;
		info.value = 5;
		UIDropDownMenu_AddButton(info, level);

		if atTransmogrifier then
			UIDropDownMenu_AddSeparator(level);

			info.value = nil;
			info.hasArrow = false;
			info.isNotRadio = true;
			info.notCheckable = false;

			if next(ezCollections.UnclaimedQuests) then
				info.text = ezCollections.L["Transmog.Items.Filter.Claimable"];
				info.func = function(_, _, _, value)
					ezCollections:SetCVarBool("transmogrifyShowClaimable", value);
					ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
				end;
				info.checked = function() return ezCollections:GetCVarBool("transmogrifyShowClaimable"); end;
				UIDropDownMenu_AddButton(info, level);
			end

			info.text = ezCollections.L["Transmog.Items.Filter.Purchasable"];
			info.func = function(_, _, _, value)
				ezCollections:SetCVarBool("transmogrifyShowPurchasable", value);
				ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
			end;
			info.checked = function() return ezCollections:GetCVarBool("transmogrifyShowPurchasable"); end;
			UIDropDownMenu_AddButton(info, level);
		end
	else
		if level == 2 and UIDROPDOWNMENU_MENU_VALUE == 2 then
			info.text = CHECK_ALL;
			info.func = function() C_TransmogCollection.SetAllArmorTypeFilters(true); UIDropDownMenu_Refresh2(WardrobeFilterDropDown, 2, level); end
			UIDropDownMenu_AddButton(info, level);

			info.text = UNCHECK_ALL;
			info.func = function() C_TransmogCollection.SetAllArmorTypeFilters(false); UIDropDownMenu_Refresh2(WardrobeFilterDropDown, 2, level); end
			UIDropDownMenu_AddButton(info, level);

			local items =
			{
				{ ezCollections.L["Transmog.Sets.Filter.ArmorType.Cloth"], 2 },
				{ ezCollections.L["Transmog.Sets.Filter.ArmorType.Leather"], 3 },
				{ ezCollections.L["Transmog.Sets.Filter.ArmorType.Mail"], 4 },
				{ ezCollections.L["Transmog.Sets.Filter.ArmorType.Plate"], 5 },
				{ ezCollections.L["Transmog.Sets.Filter.ArmorType.Misc"], 1 },
				{ ezCollections.L["Transmog.Sets.Filter.ArmorType.Any"], 6 },
			};
			for _, data in ipairs(items) do
				local text, filter = unpack(data);
				info.text = text;
				info.func = function(_, _, _, value)
					C_TransmogCollection.SetArmorTypeFilter(filter, value);
				end
				info.checked = function() return C_TransmogCollection.IsArmorTypeFilterChecked(filter) end;
				UIDropDownMenu_AddButton(info, level);
			end
		elseif level == 2 and UIDROPDOWNMENU_MENU_VALUE == 3 then
			info.isNotRadio = true;
			info.hasArrow = false;
			info.notCheckable = true;

			info.text = CHECK_ALL;
			info.func = function() C_TransmogCollection.SetAllClassFilters(true); UIDropDownMenu_Refresh2(WardrobeFilterDropDown, 3, level); end
			UIDropDownMenu_AddButton(info, level);

			info.text = UNCHECK_ALL;
			info.func = function() C_TransmogCollection.SetAllClassFilters(false); UIDropDownMenu_Refresh2(WardrobeFilterDropDown, 3, level); end
			UIDropDownMenu_AddButton(info, level);

			info.notCheckable = false;
			for _, class in ipairs(CLASS_SORT_ORDER) do
				local color = RAID_CLASS_COLORS[class];
				if color then
					local id = ezCollections.ClassNameToID[class];
					info.text = format("|cFF%s%s|r", ezCollections.RGBPercToHex(color.r, color.g, color.b), LOCALIZED_CLASS_NAMES_MALE[class]);
					info.func = function(_, _, _, value) C_TransmogCollection.SetClassFilter(id, value); end
					info.checked = function() return C_TransmogCollection.IsClassFilterChecked(id) end;
					UIDropDownMenu_AddButton(info, level);
				end
			end
			local id = ezCollections.ClassNameToID["ANY"];
			info.text = ezCollections.L["Transmog.Sets.Filter.Classes.Any"];
			info.func = function(_, _, _, value) C_TransmogCollection.SetClassFilter(id, value); end
			info.checked = function() return C_TransmogCollection.IsClassFilterChecked(id) end;
			UIDropDownMenu_AddButton(info, level);
		elseif level == 2 and UIDROPDOWNMENU_MENU_VALUE == 4 then
			info.isNotRadio = true;
			info.hasArrow = false;
			info.notCheckable = true;

			info.text = CHECK_ALL;
			info.func = function() C_TransmogCollection.SetAllRaceFilters(true); UIDropDownMenu_Refresh2(WardrobeFilterDropDown, 4, level); end;
			UIDropDownMenu_AddButton(info, level);

			info.text = UNCHECK_ALL;
			info.func = function() C_TransmogCollection.SetAllRaceFilters(false); UIDropDownMenu_Refresh2(WardrobeFilterDropDown, 4, level); end;
			UIDropDownMenu_AddButton(info, level);

			info.notCheckable = false;
			local lastFaction = nil;
			for _, race in ipairs(ezCollections.RaceSortOrder) do
				local faction = ezCollections.RaceNameToFaction[race];
				if lastFaction ~= faction then
					lastFaction = faction;
					UIDropDownMenu_AddSpace(level);
					info.text = format(ezCollections.L[faction == FACTION_ALLIANCE and "Transmog.Sets.Filter.Races.Alliance" or "Transmog.Sets.Filter.Races.Horde"], faction);
					info.func = function(_, _, _, value) C_TransmogCollection.SetFactionFilters(faction, value); UIDropDownMenu_Refresh2(WardrobeFilterDropDown, 4, level); end;
					info.checked = function() return C_TransmogCollection.IsFactionFilterChecked(faction); end;
					UIDropDownMenu_AddButton(info, level);
				end
				local id = ezCollections.RaceNameToID[race];
				info.text = ezCollections.L["Race."..id];
				info.func = function(_, _, _, value) C_TransmogCollection.SetRaceFilter(id, value); UIDropDownMenu_Refresh2(WardrobeFilterDropDown, 4, level); end;
				info.checked = function() return C_TransmogCollection.IsRaceFilterChecked(id) end;
				UIDropDownMenu_AddButton(info, level);
			end
			UIDropDownMenu_AddSpace(level);
			info.text = ezCollections.L["Transmog.Sets.Filter.Races.Neutral"];
			info.func = function(_, _, _, value) C_TransmogCollection.SetFactionFilters(FACTION_OTHER, value); UIDropDownMenu_Refresh2(WardrobeFilterDropDown, 4, level); end;
			info.checked = function() return C_TransmogCollection.IsFactionFilterChecked(FACTION_OTHER); end;
			UIDropDownMenu_AddButton(info, level);
		elseif level == 2 and UIDROPDOWNMENU_MENU_VALUE == 5 then
			info.isNotRadio = true;
			info.hasArrow = false;
			info.notCheckable = true;

			info.text = CHECK_ALL;
			info.func = function() C_TransmogCollection.SetAllExpansionFilters(true); UIDropDownMenu_Refresh2(WardrobeFilterDropDown, 5, level); end;
			UIDropDownMenu_AddButton(info, level);

			info.text = UNCHECK_ALL;
			info.func = function() C_TransmogCollection.SetAllExpansionFilters(false); UIDropDownMenu_Refresh2(WardrobeFilterDropDown, 5, level); end;
			UIDropDownMenu_AddButton(info, level);

			info.notCheckable = false;
			for i = 1, GetNumExpansions() do
				info.text = _G["EXPANSION_NAME"..i-1];
				info.func = function(_, _, _, value) C_TransmogCollection.SetExpansionFilter(i, value); UIDropDownMenu_Refresh2(WardrobeFilterDropDown, 5, level); end;
				info.checked = function() return C_TransmogCollection.IsExpansionFilterChecked(i) end;
				UIDropDownMenu_AddButton(info, level);
			end
		elseif level == 2 and UIDROPDOWNMENU_MENU_VALUE == 1 then
			info.hasArrow = false;
			info.isNotRadio = true;
			info.notCheckable = true;

			info.text = CHECK_ALL
			info.func = function()
							C_TransmogCollection.SetAllSourceTypeFilters(true);
							UIDropDownMenu_Refresh2(WardrobeFilterDropDown, 1, level);
						end
			UIDropDownMenu_AddButton(info, level)
			
			info.text = UNCHECK_ALL
			info.func = function()
							C_TransmogCollection.SetAllSourceTypeFilters(false);
							UIDropDownMenu_Refresh2(WardrobeFilterDropDown, 1, level);
						end
			UIDropDownMenu_AddButton(info, level)
			info.notCheckable = false;

			local numSources = C_TransmogCollection.GetNumTransmogSources();
			for i = 1, numSources do
				info.text = _G["TRANSMOG_SOURCE_"..i];
				info.func = function(_, _, _, value)
							C_TransmogCollection.SetSourceTypeFilter(i, value);
						end
				info.checked = function() return not C_TransmogCollection.IsSourceTypeFilterChecked(i) end;
				UIDropDownMenu_AddButton(info, level);
			end

			if ezCollections.Developer then
				UIDropDownMenu_AddSeparator(level);
				UIDropDownMenu_AddButton({ notCheckable = true, isTitle = true, text = "Developer" }, level);

				info.text = "Show |cFF00FF00Obtainable|r";
				info.func = function(_, _, _, value)
					ezCollections:SetCVarBool("transmogrifyShowObtainable", value);
					ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
				end;
				info.checked = function() return ezCollections:GetCVarBool("transmogrifyShowObtainable"); end;
				UIDropDownMenu_AddButton(info, level);

				info.text = "Show |cFFFF0000Unobtainable|r";
				info.tooltipTitle = info.text;
				info.tooltipText = "Requires config option Collections.Addon.Dev.SeeUnobtainable to be enabled on the server. For use only on local and test servers."
				info.tooltipOnButton = 1;
				info.func = function(_, _, _, value)
					ezCollections:SetCVarBool("transmogrifyShowUnobtainable", value);
					ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
				end;
				info.checked = function() return ezCollections:GetCVarBool("transmogrifyShowUnobtainable"); end;
				UIDropDownMenu_AddButton(info, level);
			end
		end
	end
end

function WardrobeFilterDropDown_ResetFilters()
	if ( WardrobeCollectionFrame.activeFrame.searchType == LE_TRANSMOG_SEARCH_TYPE_BASE_SETS ) then
		C_TransmogSets.SetDefaultBaseSetsFilters();
	else
		C_TransmogCollection.SetDefaultFilters();
	end
	WardrobeCollectionFrame.FilterButton.ResetButton:Hide();
end

function WardrobeResetFiltersButton_UpdateVisibility()
	if ( WardrobeCollectionFrame.activeFrame.searchType == LE_TRANSMOG_SEARCH_TYPE_BASE_SETS ) then
		WardrobeCollectionFrame.FilterButton.ResetButton:SetShown(not C_TransmogSets.IsUsingDefaultBaseSetsFilters());
	else
		WardrobeCollectionFrame.FilterButton.ResetButton:SetShown(not C_TransmogCollection.IsUsingDefaultFilters());
	end
end

function WardrobeFilterDropDown_InitializeBaseSets(self, level)
	local info = UIDropDownMenu_CreateInfo();
	info.keepShownOnClick = true;
	info.isNotRadio = true;

	--[[
	info.text = COLLECTED;
	info.func = function(_, _, _, value)
					C_TransmogSets.SetBaseSetsFilter(LE_TRANSMOG_SET_FILTER_COLLECTED, value);
				end 
	info.checked = C_TransmogSets.GetBaseSetsFilter(LE_TRANSMOG_SET_FILTER_COLLECTED);
	UIDropDownMenu_AddButton(info, level);

	info.text = NOT_COLLECTED;
	info.func = function(_, _, _, value)
					C_TransmogSets.SetBaseSetsFilter(LE_TRANSMOG_SET_FILTER_UNCOLLECTED, value);
				end 
	info.checked = C_TransmogSets.GetBaseSetsFilter(LE_TRANSMOG_SET_FILTER_UNCOLLECTED);
	UIDropDownMenu_AddButton(info, level);

	UIDropDownMenu_AddSeparator(info);
	-- reset to remove separator
	info = UIDropDownMenu_CreateInfo();
	info.keepShownOnClick = true;
	info.isNotRadio = true;
	
	info.text = TRANSMOG_SET_PVE;
	info.func = function(_, _, _, value)
					C_TransmogSets.SetBaseSetsFilter(LE_TRANSMOG_SET_FILTER_PVE, value);
				end 
	info.checked = C_TransmogSets.GetBaseSetsFilter(LE_TRANSMOG_SET_FILTER_PVE);
	UIDropDownMenu_AddButton(info, level);

	info.text = TRANSMOG_SET_PVP;
	info.func = function(_, _, _, value)
					C_TransmogSets.SetBaseSetsFilter(LE_TRANSMOG_SET_FILTER_PVP, value);
				end 
	info.checked = C_TransmogSets.GetBaseSetsFilter(LE_TRANSMOG_SET_FILTER_PVP);
	UIDropDownMenu_AddButton(info, level);
	]]

	local items =
	{
		{ COLLECTED, LE_TRANSMOG_SET_FILTER_COLLECTED },
		{ NOT_COLLECTED, LE_TRANSMOG_SET_FILTER_UNCOLLECTED },
		{ },
		{ ezCollections.L["Transmog.Sets.Filter.Core"], LE_TRANSMOG_SET_FILTER_CORE },
		{ ezCollections.L["Transmog.Sets.Filter.Wowhead"], LE_TRANSMOG_SET_FILTER_WOWHEAD },
		{ },
		{ ezCollections.L["Transmog.Sets.Filter.ArmorType"], 1,
		{
			{ CHECK_ALL, function() C_TransmogSets.SetAllBaseSetsArmorTypeFilter(true); end },
			{ UNCHECK_ALL, function() C_TransmogSets.SetAllBaseSetsArmorTypeFilter(false); end },
			{ ezCollections.L["Transmog.Sets.Filter.ArmorType.Cloth"], LE_TRANSMOG_SET_FILTER_CLOTH },
			{ ezCollections.L["Transmog.Sets.Filter.ArmorType.Leather"], LE_TRANSMOG_SET_FILTER_LEATHER },
			{ ezCollections.L["Transmog.Sets.Filter.ArmorType.Mail"], LE_TRANSMOG_SET_FILTER_MAIL },
			{ ezCollections.L["Transmog.Sets.Filter.ArmorType.Plate"], LE_TRANSMOG_SET_FILTER_PLATE },
			{ ezCollections.L["Transmog.Sets.Filter.ArmorType.Misc"], LE_TRANSMOG_SET_FILTER_MISC },
		} },
		{ ezCollections.L["Transmog.Sets.Filter.Classes"], 2, function(value, level)
			local info = { };
			info.keepShownOnClick = true;
			info.isNotRadio = true;
			info.hasArrow = false;
			info.notCheckable = true;

			info.text = CHECK_ALL;
			info.func = function() C_TransmogSets.SetAllBaseSetsClassFilter(true); UIDropDownMenu_Refresh2(WardrobeFilterDropDown, value, level); end
			UIDropDownMenu_AddButton(info, level);

			info.text = UNCHECK_ALL;
			info.func = function() C_TransmogSets.SetAllBaseSetsClassFilter(false); UIDropDownMenu_Refresh2(WardrobeFilterDropDown, value, level); end
			UIDropDownMenu_AddButton(info, level);

			info.notCheckable = false;
			for _, class in ipairs(CLASS_SORT_ORDER) do
				local color = RAID_CLASS_COLORS[class];
				if color then
					local id = ezCollections.ClassNameToID[class];
					info.text = format("|cFF%s%s|r", ezCollections.RGBPercToHex(color.r, color.g, color.b), LOCALIZED_CLASS_NAMES_MALE[class]);
					info.func = function(_, _, _, value) C_TransmogSets.SetBaseSetsClassFilter(id, value); end
					info.checked = function() return C_TransmogSets.GetBaseSetsClassFilter(id) end;
					UIDropDownMenu_AddButton(info, level);
				end
			end
			local id = ezCollections.ClassNameToID["ANY"];
			info.text = ezCollections.L["Transmog.Sets.Filter.Classes.Any"];
			info.func = function(_, _, _, value) C_TransmogSets.SetBaseSetsClassFilter(id, value); end
			info.checked = function() return C_TransmogSets.GetBaseSetsClassFilter(id) end;
			UIDropDownMenu_AddButton(info, level);
		end },
		{ ezCollections.L["Transmog.Sets.Filter.Races"], 4, function(value, level)
			local info = { };
			info.keepShownOnClick = true;
			info.isNotRadio = true;
			info.hasArrow = false;
			info.notCheckable = true;

			info.text = CHECK_ALL;
			info.func = function() C_TransmogSets.SetAllBaseSetsRaceFilter(true); UIDropDownMenu_Refresh2(WardrobeFilterDropDown, value, level); end
			UIDropDownMenu_AddButton(info, level);

			info.text = UNCHECK_ALL;
			info.func = function() C_TransmogSets.SetAllBaseSetsRaceFilter(false); UIDropDownMenu_Refresh2(WardrobeFilterDropDown, value, level); end
			UIDropDownMenu_AddButton(info, level);

			info.notCheckable = false;
			local lastFaction = nil;
			for _, race in ipairs(ezCollections.RaceSortOrder) do
				local faction = ezCollections.RaceNameToFaction[race];
				if lastFaction ~= faction then
					lastFaction = faction;
					UIDropDownMenu_AddSpace(level);
					info.text = format(ezCollections.L[faction == FACTION_ALLIANCE and "Transmog.Sets.Filter.Races.Alliance" or "Transmog.Sets.Filter.Races.Horde"], faction);
					info.func = function(_, _, _, value) C_TransmogSets.SetBaseSetsFactionFilter(faction, value); UIDropDownMenu_Refresh2(WardrobeFilterDropDown, value, level); end;
					info.checked = function() return C_TransmogSets.GetBaseSetsFactionFilter(faction); end;
					UIDropDownMenu_AddButton(info, level);
				end
				local id = ezCollections.RaceNameToID[race];
				info.text = ezCollections.L["Race."..id];
				info.func = function(_, _, _, value) C_TransmogSets.SetBaseSetsRaceFilter(id, value); UIDropDownMenu_Refresh2(WardrobeFilterDropDown, value, level); end
				info.checked = function() return C_TransmogSets.GetBaseSetsRaceFilter(id) end;
				UIDropDownMenu_AddButton(info, level);
			end
			UIDropDownMenu_AddSpace(level);
			info.text = ezCollections.L["Transmog.Sets.Filter.Races.Neutral"];
			info.func = function(_, _, _, value) C_TransmogSets.SetBaseSetsFactionFilter(FACTION_OTHER, value); UIDropDownMenu_Refresh2(WardrobeFilterDropDown, value, level); end;
			info.checked = function() return C_TransmogSets.GetBaseSetsFactionFilter(FACTION_OTHER); end;
			UIDropDownMenu_AddButton(info, level);
		end },
		{ SOURCES, 3,
		{
			{ CHECK_ALL, function() C_TransmogSets.SetAllBaseSetsSourcesFilter(true); end },
			{ UNCHECK_ALL, function() C_TransmogSets.SetAllBaseSetsSourcesFilter(false); end },
			{ TRANSMOG_SET_PVE, LE_TRANSMOG_SET_FILTER_PVE },
			{ TRANSMOG_SET_PVP, LE_TRANSMOG_SET_FILTER_PVP },
			{ ezCollections.L["Transmog.Sets.Filter.Store"], LE_TRANSMOG_SET_FILTER_STORE },
		} },
		{ EXPANSION_FILTER_TEXT, 5, function(value, level)
			local info = { };
			info.keepShownOnClick = true;
			info.isNotRadio = true;
			info.hasArrow = false;
			info.notCheckable = true;

			info.text = CHECK_ALL;
			info.func = function() C_TransmogSets.SetAllBaseSetsExpansionFilter(true); UIDropDownMenu_Refresh2(WardrobeFilterDropDown, value, level); end
			UIDropDownMenu_AddButton(info, level);

			info.text = UNCHECK_ALL;
			info.func = function() C_TransmogSets.SetAllBaseSetsExpansionFilter(false); UIDropDownMenu_Refresh2(WardrobeFilterDropDown, value, level); end
			UIDropDownMenu_AddButton(info, level);

			info.notCheckable = false;
			for i = 1, GetNumExpansions() do
				info.text = _G["EXPANSION_NAME"..i-1];
				info.func = function(_, _, _, value) C_TransmogSets.SetBaseSetsExpansionFilter(i, value); end
				info.checked = function() return C_TransmogSets.GetBaseSetsExpansionFilter(i) end;
				UIDropDownMenu_AddButton(info, level);
			end
		end },
		{ },
		{ ezCollections.L["Transmog.Sets.Filter.Group"], LE_TRANSMOG_SET_FILTER_GROUP },
		{ ezCollections.L["Transmog.Sets.Filter.Sort"], LE_TRANSMOG_SET_FILTER_SORT, true },
	};
	local function Process(items, tableLevel, tableValue)
		for _, data in ipairs(items) do
			local text, filter, invert = unpack(data);
			if text and type(filter) == "number" and (type(invert) == "table" or type(invert) == "function") then
				if level == tableLevel then
					UIDropDownMenu_AddButton(
					{
						keepShownOnClick = true,
						func = function(self) _G[self:GetName().."Check"]:Hide(); end,
						hasArrow = true,
						notCheckable = true,
						text = text,
						value = filter,
					}, level);
				end
				if type(invert) == "table" then
					Process(invert, tableLevel + 1, filter);
				elseif type(invert) == "function" and UIDROPDOWNMENU_MENU_VALUE == filter then
					invert(filter, level);
				end
			elseif level == tableLevel and (not tableValue or UIDROPDOWNMENU_MENU_VALUE == tableValue) then
				if text and filter and type(filter) == "function" then
					local info = { };
					UIDropDownMenu_AddButton(
					{
						keepShownOnClick = true,
						notCheckable = true,
						text = text,
						func = function() filter(); UIDropDownMenu_Refresh2(WardrobeFilterDropDown, tableValue, tableLevel); end,
					}, level);
				elseif text and filter then
					info.text = text;
					info.arg1 = invert;
					info.func = function(_, invert, _, value)
						if invert then
							C_TransmogSets.SetBaseSetsFilter(filter, not value);
						else
							C_TransmogSets.SetBaseSetsFilter(filter, value);
						end
					end
					if invert then
						info.checked = function() return not C_TransmogSets.GetBaseSetsFilter(filter); end;
					else
						info.checked = function() return C_TransmogSets.GetBaseSetsFilter(filter); end;
					end
					UIDropDownMenu_AddButton(info, level);
				elseif text then
					UIDropDownMenu_AddButton({ notCheckable = true, isTitle = true, text = text }, level);
				else
					UIDropDownMenu_AddSeparator(level);
				end
			end
		end
	end
	Process(items, 1);
end

function WardrobeFilterDropDown_InitializeUsableSets(self, level)
	self.setsSlotMask = self.setsSlotMask or 0;
	if not self.setsValidSlotNames and next(ezCollections.Cache.Sets) then
		self.setsValidSlotNames = { };
		for _, set in pairs(ezCollections.Cache.Sets) do
			for _, source in ipairs(set.sources) do
				local info = ezCollections:GetSkinInfo(source.id);
				local slot = info and info.InventoryType and C_Transmog.GetSlotForInventoryType(info.InventoryType);
				local slotName = slot and ezCollections.TransmogrifiableSlots[slot];
				if slotName then
					self.setsValidSlotNames[slot] = slotName;
				end
			end
		end
		self.setsValidSlotNames[EQUIPPED_LAST + 1] = ezCollections.L["Transmog.Sets.Filter.Slots.Store"];
	end
	local validSlotNames = self.setsValidSlotNames;

	local info = UIDropDownMenu_CreateInfo();
	info.text = ezCollections.L["Transmog.Sets.Filter.Slots.RequiredSlots"];
	info.isTitle = true;
	info.notCheckable = true;
	UIDropDownMenu_AddButton(info, level);

	info = UIDropDownMenu_CreateInfo();
	info.keepShownOnClick = true;
	info.isNotRadio = true;
	info.notCheckable = true;

	info.text = CHECK_ALL;
	info.func = function()
		self.setsSlotMask = 0;
		UIDropDownMenu_Refresh2(WardrobeFilterDropDown);
	end;
	UIDropDownMenu_AddButton(info, level);

	info.text = UNCHECK_ALL;
	info.func = function()
		for i = EQUIPPED_FIRST, EQUIPPED_LAST + 1 do
			if validSlotNames[i] then
				self.setsSlotMask = bit.bor(self.setsSlotMask, bit.lshift(1, i - 1));
			end
		end
		UIDropDownMenu_Refresh2(WardrobeFilterDropDown);
	end;
	UIDropDownMenu_AddButton(info, level);

	info.notCheckable = false;
	for _, i in ipairs({ 1, 3, 15, 5, 19, 4, 9, 10, 6, 7, 8, 16, 17, 18, EQUIPPED_LAST + 1 }) do
		local slot = validSlotNames[i];
		if slot then
			info.text = _G[slot:upper()] or slot;
			info.func = function(_, _, _, value)
				if value then
					self.setsSlotMask = bit.band(self.setsSlotMask, bit.bnot(bit.lshift(1, i - 1)));
				else
					self.setsSlotMask = bit.bor(self.setsSlotMask, bit.lshift(1, i - 1));
				end
			end;
			info.checked = function() return bit.band(self.setsSlotMask, bit.lshift(1, i - 1)) == 0 end;
			if i == EQUIPPED_LAST + 1 then
				info.tooltipTitle = ezCollections.L["Transmog.Sets.Filter.Slots.Store.Header"];
				info.tooltipText = ezCollections.L["Transmog.Sets.Filter.Slots.Store.Text"];
			else
				info.tooltipTitle = format(ezCollections.L["Transmog.Sets.Filter.Slots.RequiredSlots.Header"], info.text);
				info.tooltipText = format(ezCollections.L["Transmog.Sets.Filter.Slots.RequiredSlots.Text"], info.text);
			end
			UIDropDownMenu_AddButton(info, level);
		end
	end

	UIDropDownMenu_AddSpace(level);

	info = UIDropDownMenu_CreateInfo();
	info.notCheckable = true;
	info.text = APPLY;
	info.func = function()
		local numDisabled = 0;
		for i = EQUIPPED_FIRST, EQUIPPED_LAST --[[+ 1]] do
			if validSlotNames[i] and bit.band(self.setsSlotMask, bit.lshift(1, i - 1)) ~= 0 then
				numDisabled = numDisabled + 1;
			end
		end
		if numDisabled > ezCollections.SearchMaxSetsSlotMask then
			StaticPopup_Show("EZCOLLECTIONS_ERROR", format(ezCollections.L["Popup.Error.MaxSetsSlotMask"], ezCollections.SearchMaxSetsSlotMask));
			return;
		end
		ezCollections:SetCVar("transmogrifySetsSlotMask", self.setsSlotMask);
		ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
	end;
	UIDropDownMenu_AddButton(info, level);

	info.text = CANCEL;
	info.func = nil;
	UIDropDownMenu_AddButton(info, level);
end

-- ***** SPEC DROPDOWN

function WardrobeTransmogFrameSpecDropDown_OnLoad(self)
	UIDropDownMenu_Initialize(self, WardrobeTransmogFrameSpecDropDown_Initialize, "MENU");
end

function WardrobeTransmogFrameSpecDropDown_Initialize()
	local info = UIDropDownMenu_CreateInfo();

	info.text = TRANSMOG_APPLY_TO;
	info.isTitle = true;
	info.notCheckable = true;
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);

	info = UIDropDownMenu_CreateInfo();

	local currentSpecOnly = ezCollections:GetCVarBool("transmogCurrentSpecOnly");

	info.text = TRANSMOG_ALL_SPECIALIZATIONS;
	info.func = WardrobeTransmogFrameSpecDropDown_OnClick;
	info.checked = not currentSpecOnly;
	info.value = 0;
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);

	info.text = TRANSMOG_CURRENT_SPECIALIZATION;
	info.func = WardrobeTransmogFrameSpecDropDown_OnClick;
	info.checked = currentSpecOnly;
	info.value = 1;
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);

	local spec = GetSpecialization();
	local _, name, _, icon = GetSpecializationInfo(spec);
	info.text = format(PARENS_TEMPLATE, name);
	info.leftPadding = 16;
	info.notCheckable = true;
	info.notClickable = true;
	info.checked = false;
	info.text = format([[|TInterface\AddOns\ezCollections\Interface\Common\spacer:1:20:-1:-1|t |T%s:22:22:0:-1|t %s (%s)]], icon, name, GetSpecialization() == 1 and TALENT_SPEC_PRIMARY or TALENT_SPEC_SECONDARY);
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);
end

function WardrobeTransmogFrameSpecDropDown_OnClick(self)
	ezCollections:SetCVarBool("transmogCurrentSpecOnly", self.value == 1);
end

-- ************************************************************************************************************************************************************
-- **** SETS LIST *********************************************************************************************************************************************
-- ************************************************************************************************************************************************************

local BASE_SET_BUTTON_HEIGHT = 46;
local VARIANT_SET_BUTTON_HEIGHT = 20;
local SET_PROGRESS_BAR_MAX_WIDTH = 204;
local IN_PROGRESS_FONT_COLOR = { r = 0.251, g = 0.753, b = 0.251 };
local IN_PROGRESS_FONT_COLOR_CODE = "|cff40c040";

local WardrobeSetsDataProviderMixin = {};

function WardrobeSetsDataProviderMixin:SortSets(sets, reverseUIOrder, variantSort)
	local alphabetically = not C_TransmogSets.GetBaseSetsFilter(LE_TRANSMOG_SET_FILTER_SORT);
	local comparison = variantSort and function(a, b)
		local aOrder = a.description and ezCollections.ItemNameDescriptions[a.description];
		local bOrder = b.description and ezCollections.ItemNameDescriptions[b.description];
		if aOrder ~= bOrder then
			if aOrder and bOrder then
				return aOrder < bOrder;
			else
				return aOrder ~= nil;
			end
		end
		if ( a.uiOrder ~= b.uiOrder ) then
			return a.uiOrder > b.uiOrder;
		end
		return a.setID < b.setID;
	end or function(set1, set2)
		local groupFavorite1 = set1.favoriteSetID and true;
		local groupFavorite2 = set2.favoriteSetID and true;
		if ( groupFavorite1 ~= groupFavorite2 ) then
			return groupFavorite1;
		end
		if ( set1.favorite ~= set2.favorite ) then
			return set1.favorite;
		end
		if alphabetically and set1.name ~= set2.name then return set1.name < set2.name; end
		if ( set1.uiOrder ~= set2.uiOrder ) then
			if ( reverseUIOrder ) then
				return set1.uiOrder < set2.uiOrder;
			else
				return set1.uiOrder > set2.uiOrder;
			end
		end
		return set1.setID > set2.setID;
	end

	table.sort(sets, comparison);
end

function WardrobeSetsDataProviderMixin:GetBaseSets()
	if ( not self.baseSets ) then
		self.baseSets = C_TransmogSets.GetBaseSets();
		self:DetermineFavorites();
		self:SortSets(self.baseSets);
	end
	return self.baseSets;
end

function WardrobeSetsDataProviderMixin:GetBaseSetByID(baseSetID)
	local baseSets = self:GetBaseSets();
	for i = 1, #baseSets do
		if ( baseSets[i].setID == baseSetID ) then
			return baseSets[i], i;
		end
	end
	return nil, nil;
end

function WardrobeSetsDataProviderMixin:GetUsableSets()
	if ( not self.usableSets ) then
		self.usableSets = C_TransmogSets.GetUsableSets();
		self:SortSets(self.usableSets);
		-- group sets by baseSetID, except for favorited sets since those are to remain bucketed to the front
		for i, set in ipairs(self.usableSets) do
			if ( not set.favorite ) then
				local baseSetID = set.baseSetID or set.setID;
				local numRelatedSets = 0;
				for j = i + 1, #self.usableSets do
					if ( self.usableSets[j].baseSetID == baseSetID or self.usableSets[j].setID == baseSetID ) then
						numRelatedSets = numRelatedSets + 1;
						-- no need to do anything if already contiguous
						if ( j ~= i + numRelatedSets ) then
							local relatedSet = self.usableSets[j];
							tremove(self.usableSets, j);
							tinsert(self.usableSets, i + numRelatedSets, relatedSet);
						end
					end
				end
			end
		end
	end
	return self.usableSets;
end

function WardrobeSetsDataProviderMixin:GetVariantSets(baseSetID)
	if ( not self.variantSets ) then
		self.variantSets = { };
	end

	local variantSets = self.variantSets[baseSetID];
	if ( not variantSets ) then
		variantSets = C_TransmogSets.GetVariantSets(baseSetID);
		self.variantSets[baseSetID] = variantSets;
		if ( #variantSets > 0 ) then
			-- add base to variants and sort
			--local baseSet = self:GetBaseSetByID(baseSetID);
			--if ( baseSet ) then
			--	tinsert(variantSets, baseSet);
			--end
			self:SortSets(variantSets, true, true);
		end
	end
	return variantSets;
end

function WardrobeSetsDataProviderMixin:GetSetSourceData(setID)
	if ( not self.sourceData ) then
		self.sourceData = { };
	end

	local sourceData = self.sourceData[setID];
	if ( not sourceData ) then
		local sources = C_TransmogSets.GetSetSources(setID);
		local numCollected = 0;
		local numTotal = 0;
		for sourceID, collected in pairs(sources) do
			if ( collected ) then
				numCollected = numCollected + 1;
			end
			numTotal = numTotal + 1;
		end
		sourceData = { numCollected = numCollected, numTotal = numTotal, sources = sources };
		self.sourceData[setID] = sourceData;
	end
	return sourceData;
end

function WardrobeSetsDataProviderMixin:GetSetSources(setID)
	return self:GetSetSourceData(setID).sources;
end

function WardrobeSetsDataProviderMixin:GetSetSourceCounts(setID)
	local sourceData = self:GetSetSourceData(setID);
	return sourceData.numCollected, sourceData.numTotal;
end

function WardrobeSetsDataProviderMixin:GetBaseSetData(setID)
	if ( not self.baseSetsData ) then
		self.baseSetsData = { };
	end
	if ( not self.baseSetsData[setID] ) then
		local baseSetID = C_TransmogSets.GetBaseSetID(setID);
		if ( baseSetID ~= setID ) then
			return;
		end
		local topCollected, topTotal = self:GetSetSourceCounts(setID);
		local variantSets = self:GetVariantSets(setID);
		for i = 1, #variantSets do
			local numCollected, numTotal = self:GetSetSourceCounts(variantSets[i].setID);
			if ( numCollected > topCollected ) then
				topCollected = numCollected;
				topTotal = numTotal;
			end
		end
		local setInfo = { topCollected = topCollected, topTotal = topTotal, completed = (topCollected == topTotal) };
		self.baseSetsData[setID] = setInfo;
	end
	return self.baseSetsData[setID];
end

function WardrobeSetsDataProviderMixin:GetSetSourceTopCounts(setID)
	local baseSetData = self:GetBaseSetData(setID);
	if ( baseSetData ) then
		return baseSetData.topCollected, baseSetData.topTotal;
	else
		return self:GetSetSourceCounts(setID);
	end
end

function WardrobeSetsDataProviderMixin:IsBaseSetNew(baseSetID)
	local baseSetData = self:GetBaseSetData(baseSetID)
	if ( not baseSetData.newStatus ) then
		local newStatus = C_TransmogSets.SetHasNewSources(baseSetID);
		if ( not newStatus ) then
			-- check variants
			local variantSets = self:GetVariantSets(baseSetID);
			for i, variantSet in ipairs(variantSets) do
				if ( C_TransmogSets.SetHasNewSources(variantSet.setID) ) then
					newStatus = true;
					break;
				end
			end
		end
		baseSetData.newStatus = newStatus;
	end
	return baseSetData.newStatus;
end

function WardrobeSetsDataProviderMixin:ResetBaseSetNewStatus(baseSetID)
	local baseSetData = self:GetBaseSetData(baseSetID)
	if ( baseSetData ) then
		baseSetData.newStatus = nil;
	end
end

function WardrobeSetsDataProviderMixin:GetSortedSetSources(setID)
	local returnTable = { };
	local sourceData = self:GetSetSourceData(setID);
	for sourceID, collected in pairs(sourceData.sources) do
		local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID);
		if ( sourceInfo ) then
			local sortOrder = EJ_GetInvTypeSortOrder(sourceInfo.invType);
			tinsert(returnTable, { sourceID = sourceID, collected = collected, sortOrder = sortOrder, itemID = sourceInfo.itemID, invType = sourceInfo.invType });
		end
	end

	local comparison = function(entry1, entry2)
		if ( entry1.sortOrder == entry2.sortOrder ) then
			return entry1.itemID < entry2.itemID;
		else
			return entry1.sortOrder < entry2.sortOrder;
		end
	end
	table.sort(returnTable, comparison);
	return returnTable;
end

function WardrobeSetsDataProviderMixin:ClearSets()
	self.baseSets = nil;
	self.baseSetsData = nil;
	self.variantSets = nil;
	self.usableSets = nil;
	self.sourceData = nil;
end

function WardrobeSetsDataProviderMixin:ClearBaseSets()
	self.baseSets = nil;
end

function WardrobeSetsDataProviderMixin:ClearVariantSets()
	self.variantSets = nil;
end

function WardrobeSetsDataProviderMixin:ClearUsableSets()
	self.usableSets = nil;
end

function WardrobeSetsDataProviderMixin:GetIconForSet(setID)
	local sourceData = self:GetSetSourceData(setID);
	local itemID;
	if ( not sourceData.icon ) then
		local sortedSources = self:GetSortedSetSources(setID);
		if ( sortedSources[1] ) then
			itemID = sortedSources[1].itemID;
			sourceData.icon = ezCollections:GetSkinIcon(itemID);
			if not sourceData.icon then
				ezCollections:QueryItem(itemID);
				sourceData.icon = nil;
			end
		else
			sourceData.icon = nil;
		end
	end
	return sourceData.icon or QUESTION_MARK_ICON, itemID;
end

function WardrobeSetsDataProviderMixin:DetermineFavorites()
	-- if a variant is favorited, so is the base set
	-- keep track of which set is favorited
	local baseSets = self:GetBaseSets();
	for i = 1, #baseSets do
		local baseSet = baseSets[i];
		baseSet.favoriteSetID = nil;
		if ( baseSet.favorite ) then
			baseSet.favoriteSetID = baseSet.setID;
		else
			local variantSets = self:GetVariantSets(baseSet.setID);
			for j = 1, #variantSets do
				if ( variantSets[j].favorite ) then
					baseSet.favoriteSetID = variantSets[j].setID;
					break;
				end
			end
		end
	end
end

function WardrobeSetsDataProviderMixin:RefreshFavorites()
	self.baseSets = nil;
	self.variantSets = nil;
	self:DetermineFavorites();
end

local SetsDataProvider = CreateFromMixins(WardrobeSetsDataProviderMixin);

WardrobeSetsCollectionMixin = {};

function WardrobeSetsCollectionMixin:OnLoad()
	self.RightInset.BGCornerTopLeft:Hide();
	self.RightInset.BGCornerTopRight:Hide();

	Mixin(self.DetailsFrame.LabelID, SetShownMixin);
	Mixin(self.DetailsFrame.Wowhead, SetShownMixin);
	Mixin(self.DetailsFrame.Name, ShrinkUntilTruncateFontStringMixin);
	self.DetailsFrame.Name:SetFontObjectsToTry(Fancy24Font, Fancy22Font, Fancy20Font, Fancy18Font, Fancy16Font);
	self.DetailsFrame.itemFramesPool = CreateFramePool("FRAME", self.DetailsFrame, "WardrobeSetsDetailsItemFrameTemplate");

	self.selectedVariantSets = { };

	local function OpenVariantSetsDropDown(self)
		self:GetParent():GetParent():OpenVariantSetsDropDown();
	end
	UIDropDownMenu_Initialize(WardrobeSetsCollectionVariantSetsDropDown, OpenVariantSetsDropDown, "MENU");
end

function WardrobeSetsCollectionMixin:OnShow()
	--ezCollections:RegisterEvent(self, "GET_ITEM_INFO_RECEIVED");
	ezCollections:RegisterEvent(self, "TRANSMOG_COLLECTION_ITEM_UPDATE");
	ezCollections:RegisterEvent(self, "TRANSMOG_COLLECTION_UPDATED");
	-- select the first set if not init
	local baseSets = SetsDataProvider:GetBaseSets();
	if ( not self.init ) then
		self.init = true;
		if ( baseSets and baseSets[1] ) then
			self:SelectSet(self:GetDefaultSetIDForBaseSet(baseSets[1].setID));
		else
			self:Refresh();
		end
	else
		self:Refresh();
	end

	local latestSource = C_TransmogSets.GetLatestSource();
	if ( latestSource ~= NO_TRANSMOG_SOURCE_ID ) then
		local sets = C_TransmogSets.GetSetsContainingSourceID(latestSource);
		local setID = sets and sets[1];
		if ( setID ) then
			self:SelectSet(setID);
			local baseSetID = C_TransmogSets.GetBaseSetID(setID);
			self:ScrollToSet(baseSetID);
		end
		self:ClearLatestSource();
	end

	WardrobeCollectionFrame_UpdateProgressBar(C_TransmogSets.GetBaseSetsCounts());
	self:RefreshCameras();

	if (self:GetParent().SetsTabHelpBox:IsShown()) then
		self:GetParent().SetsTabHelpBox:Hide()
		ezCollections:SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_TRANSMOG_SETS_TAB, true);
	end
	-- Fix frame levels
	for _, tab in ipairs(self:GetParent().Tabs) do
		tab:SetFrameLevel(self:GetFrameLevel() + 2);
	end
	self.LeftInset:SetFrameLevel(self:GetFrameLevel() + 1);
	self.RightInset:SetFrameLevel(self:GetFrameLevel() + 1);
	self.RightInset.OverlayLayer:SetFrameLevel(self:GetFrameLevel() + 4);
	self.ScrollFrame:SetFrameLevel(self:GetFrameLevel() + 2);
	self.Model:SetFrameLevel(self:GetFrameLevel() + 2);
	self.DetailsFrame:SetFrameLevel(self:GetFrameLevel() + 3);
end

function WardrobeSetsCollectionMixin:OnHide()
	ezCollections:UnregisterEvent(self, "GET_ITEM_INFO_RECEIVED");
	ezCollections:UnregisterEvent(self, "TRANSMOG_COLLECTION_ITEM_UPDATE");
	ezCollections:UnregisterEvent(self, "TRANSMOG_COLLECTION_UPDATED");
	SetsDataProvider:ClearSets();
	WardrobeCollectionFrame_ClearSearch(LE_TRANSMOG_SEARCH_TYPE_BASE_SETS);
end

function WardrobeSetsCollectionMixin:OnEvent(event, ...)
	if ( event == "GET_ITEM_INFO_RECEIVED" ) then
		local itemID = ...;
		for itemFrame in self.DetailsFrame.itemFramesPool:EnumerateActive() do
			if ( itemFrame.itemID == itemID ) then
				self:SetItemFrameQuality(itemFrame);
				break;
			end
		end
	elseif ( event == "TRANSMOG_COLLECTION_ITEM_UPDATE" ) then
		for itemFrame in self.DetailsFrame.itemFramesPool:EnumerateActive() do
			self:SetItemFrameQuality(itemFrame);
		end
	elseif ( event == "TRANSMOG_COLLECTION_UPDATED" ) then
		SetsDataProvider:ClearSets();
		self:Refresh();
		WardrobeCollectionFrame_UpdateProgressBar(C_TransmogSets.GetBaseSetsCounts());
		self:ClearLatestSource();
	end
end

function WardrobeSetsCollectionMixin:ClearLatestSource()
	C_TransmogSets.ClearLatestSource();
	WardrobeCollectionFrame_UpdateTabButtons();
end

function WardrobeSetsCollectionMixin:Refresh(listOnly)
	self.ScrollFrame:Update();
	if listOnly then return; end
	self:DisplaySet(self:GetSelectedSetID());
end

function WardrobeSetsCollectionMixin:DisplaySet(setID)
	local setInfo = (setID and C_TransmogSets.GetSetInfo(setID)) or nil;
	if ( not setInfo ) then
		self.DetailsFrame:Hide();
		self.Model:Hide();
		return;
	else
		self.DetailsFrame:Show();
		self.Model:Show();
	end

	self.DetailsFrame.Name:SetText(setInfo.name);
	if ( self.DetailsFrame.Name:IsTruncated() ) then
		self.DetailsFrame.Name:Hide();
		self.DetailsFrame.LongName:SetText(setInfo.name);
		self.DetailsFrame.LongName:Show();
	else
		self.DetailsFrame.Name:Show();
		self.DetailsFrame.LongName:Hide();
	end
	self.DetailsFrame.Label:SetText(setInfo.label);
	self.DetailsFrame.LabelID:SetText(format("ID "..setInfo.setID));
	self.DetailsFrame.LabelID:SetShown(ezCollections.Config.Wardrobe.ShowSetID);
	self.DetailsFrame.Wowhead:SetShown(ezCollections.Config.Wardrobe.ShowWowheadSetIcon and bit.band(setInfo.flags, 0x1000) ~= 0);

	local newSourceIDs = C_TransmogSets.GetSetNewSources(setID);

	self.DetailsFrame.itemFramesPool:ReleaseAll();
	self.Model:Undress();
	local BUTTON_SPACE = 37;	-- button width + spacing between 2 buttons
	local sortedSources = SetsDataProvider:GetSortedSetSources(setID);
	local xOffset = -floor((#sortedSources - 1) * BUTTON_SPACE / 2);
	for i = 1, #sortedSources do
		local itemFrame = self.DetailsFrame.itemFramesPool:Acquire();
		itemFrame.sourceID = sortedSources[i].sourceID;
		itemFrame.itemID = sortedSources[i].itemID;
		itemFrame.collected = sortedSources[i].collected;
		itemFrame.invType = sortedSources[i].invType;
		self:SetItemFrameQuality(itemFrame);
		if ( sortedSources[i].collected ) then
			itemFrame.Icon:SetDesaturated(false);
			itemFrame.Icon:SetAlpha(1);
			itemFrame.IconBorder:SetDesaturated(false);
			itemFrame.IconBorder:SetAlpha(1);

			local transmogSlot = C_Transmog.GetSlotForInventoryType(itemFrame.invType);
			if ( C_TransmogSets.SetHasNewSourcesForSlot(setID, transmogSlot) ) then
				itemFrame.New:Show();
				itemFrame.New.Anim:Play();
			else
				itemFrame.New:Hide();
				itemFrame.New.Anim:Stop();
			end
		else
			itemFrame.Icon:SetDesaturated(true);
			itemFrame.Icon:SetAlpha(0.3);
			itemFrame.IconBorder:SetDesaturated(true);
			itemFrame.IconBorder:SetAlpha(0.3);
			itemFrame.New:Hide();
		end
		itemFrame:SetPoint("TOP", self.DetailsFrame, "TOP", xOffset + (i - 1) * BUTTON_SPACE, -94);
		itemFrame:Show();
		itemFrame.previewedSource = itemFrame.sourceID;
		self.Model:TryOn(itemFrame.previewedSource);
		local slot = C_Transmog.GetSlotForInventoryType(itemFrame.invType);
		local storeSource = ezCollections:GetStoreSetSource(setID, slot);
		local subscriptionSource = ezCollections:GetSubscriptionForSetSource(setID, slot);
		itemFrame.ClaimQuest:SetShown(not sortedSources[i].collected and ezCollections:CanClaimSetSlotSkin(setID, slot));
		itemFrame.StoreButton:SetShown(not itemFrame.ClaimQuest:IsShown() and not sortedSources[i].collected and storeSource and not subscriptionSource);
		itemFrame.SubscriptionButton:SetShown(not itemFrame.ClaimQuest:IsShown() and not sortedSources[i].collected and not storeSource and subscriptionSource);
		itemFrame.StoreSubscriptionButton:SetShown(not itemFrame.ClaimQuest:IsShown() and not sortedSources[i].collected and storeSource and subscriptionSource);
	end

	-- variant sets
	local baseSetID = C_TransmogSets.GetBaseSetID(setID);
	local variantSets = SetsDataProvider:GetVariantSets(baseSetID);
	if ( #variantSets == 0 )  then
		self.DetailsFrame.VariantSetsButton:Hide();
	else
		self.DetailsFrame.VariantSetsButton:Show();
		self.DetailsFrame.VariantSetsButton:SetText(setInfo.description);
	end
end

function WardrobeSetsCollectionMixin:SetItemFrameQuality(itemFrame)
	local texture = C_TransmogCollection.GetSourceIcon(itemFrame.sourceID);
	itemFrame.Icon:SetTexture(texture);
	if ( itemFrame.collected ) then
		local quality = C_TransmogCollection.GetSourceInfo(itemFrame.sourceID).quality;
		if ( quality == LE_ITEM_QUALITY_COMMON or quality == LE_ITEM_QUALITY_POOR ) then
			itemFrame.IconBorder:SetAtlas("loottab-set-itemborder-white", true);
		elseif ( quality == LE_ITEM_QUALITY_UNCOMMON ) then
			itemFrame.IconBorder:SetAtlas("loottab-set-itemborder-green", true);
		elseif ( quality == LE_ITEM_QUALITY_RARE ) then
			itemFrame.IconBorder:SetAtlas("loottab-set-itemborder-blue", true);
		elseif ( quality == LE_ITEM_QUALITY_EPIC ) then
			itemFrame.IconBorder:SetAtlas("loottab-set-itemborder-purple", true);
		elseif ( quality == LE_ITEM_QUALITY_LEGENDARY ) then
			itemFrame.IconBorder:SetAtlas("loottab-set-itemborder-orange", true);
		elseif ( quality == LE_ITEM_QUALITY_ARTIFACT or quality == LE_ITEM_QUALITY_ARTIFACT ) then
			itemFrame.IconBorder:SetAtlas("loottab-set-itemborder-artifact", true);
		end
	end
end

function WardrobeSetsCollectionMixin:OnSearchUpdate()
	if ( self.init ) then
		SetsDataProvider:ClearBaseSets();
		SetsDataProvider:ClearVariantSets();
		SetsDataProvider:ClearUsableSets();
		self:Refresh(true);
	end
end

function WardrobeSetsCollectionMixin:OnUnitModelChangedEvent()
	if ( self.Model:CanSetUnit("player") ) then
		self.Model:SetPosition(0, 0, 0);
		self.Model:RefreshUnit();
		-- clearing cameraID so it resets zoom/pan
		self.Model.cameraID = nil;
		self.Model:UpdatePanAndZoomModelType();
		self:RefreshCameras();
		self:Refresh();
		return true;
	else
		return false;
	end
end

function WardrobeSetsCollectionMixin:RefreshCameras()
	if ( self:IsShown() ) then
		local detailsCameraID, transmogCameraID = C_TransmogSets.GetCameraIDs();
		local model = self.Model;
		self.Model:RefreshCamera();
		Model_ApplyUICamera(self.Model, detailsCameraID);
		--if ( model.cameraID ~= detailsCameraID ) then
			model.cameraID = detailsCameraID;
			model.defaultPosX, model.defaultPosY, model.defaultPosZ, model.yaw = GetUICameraInfo(detailsCameraID);
			model.defaultRotation = model.yaw;
			model.defaultZoom = model.defaultPosX / model.portraitZoomMultiplier;
			model.zoomLevel = model.defaultZoom;
		--end
	end
end

function WardrobeSetsCollectionMixin:OpenVariantSetsDropDown()
	local selectedSetID = self:GetSelectedSetID();
	if ( not selectedSetID ) then
		return;
	end
	local info = UIDropDownMenu_CreateInfo();
	local baseSetID = C_TransmogSets.GetBaseSetID(selectedSetID);
	local variantSets = SetsDataProvider:GetVariantSets(baseSetID);
	for i = 1, #variantSets do
		local variantSet = variantSets[i];
		local numSourcesCollected, numSourcesTotal = SetsDataProvider:GetSetSourceCounts(variantSet.setID);
		local colorCode = IN_PROGRESS_FONT_COLOR_CODE;
		if ( numSourcesCollected == numSourcesTotal ) then
			colorCode = NORMAL_FONT_COLOR_CODE;
		elseif ( numSourcesCollected == 0 ) then
			colorCode = GRAY_FONT_COLOR_CODE;
		end
		info.text = format(ITEM_SET_NAME, variantSet.description..colorCode, numSourcesCollected, numSourcesTotal);
		info.checked = (variantSet.setID == selectedSetID);
		info.func = function() self:SelectSet(variantSet.setID); end;
		UIDropDownMenu_AddButton(info);
	end

	local baseSet = ezCollections.Cache.Sets[baseSetID];
	if baseSet and baseSet.Variants then
		local numHidden = (#baseSet.Variants + 1) - #variantSets;
		if numHidden > 0 then
			info.text = format(ezCollections.L["Transmog.Sets.VariantsHidden"], numHidden);
			info.disabled = true;
			info.func = nil;
			info.checked = false;
			UIDropDownMenu_AddButton(info);
		end
	end

	UIDropDownMenu_AddSeparator();

	info.disabled = false;
	info.checked = nil;
	info.text = TRANSMOG_OUTFIT_POST_IN_CHAT;
	info.func = function()
		local hyperlink = C_TransmogSets.GetSetHyperlink(selectedSetID);
		if not ChatEdit_InsertLink(hyperlink) then
			ChatFrame_OpenChat(hyperlink);
		end
	end;
	UIDropDownMenu_AddButton(info);
end

function WardrobeSetsCollectionMixin:GetDefaultSetIDForBaseSet(baseSetID, ignoreNew)
	if not C_TransmogSets.GetBaseSetsFilter(LE_TRANSMOG_SET_FILTER_GROUP) then return baseSetID; end

	local variantSets = SetsDataProvider:GetVariantSets(baseSetID);
	local function HasVariantSet(setID)
		for _, set in ipairs(variantSets) do
			if set.setID == setID then
				return true;
			end
		end
	end

	if not ignoreNew and ( SetsDataProvider:IsBaseSetNew(baseSetID) ) then
		if ( C_TransmogSets.SetHasNewSources(baseSetID) ) and HasVariantSet(baseSetID) then
			return baseSetID;
		else
			for i, variantSet in ipairs(variantSets) do
				if ( C_TransmogSets.SetHasNewSources(variantSet.setID) ) then
					return variantSet.setID;
				end
			end
		end
	end

	if ( self.selectedVariantSets[baseSetID] ) then
		-- Only select the last selected variant set if it's still present in filtered list of variant sets
		if #variantSets == 0 then
			return baseSetID;
		end
		if HasVariantSet(self.selectedVariantSets[baseSetID]) then
			return self.selectedVariantSets[baseSetID];
		end
	end

	local baseSet = SetsDataProvider:GetBaseSetByID(baseSetID);
	if ( baseSet.favoriteSetID ) and HasVariantSet(baseSet.favoriteSetID) then
		return baseSet.favoriteSetID;
	end
	-- pick the one with most collected, higher difficulty wins ties
	local highestCount = 0;
	local highestCountSetID;
	for i = 1, #variantSets do
		local variantSetID = variantSets[i].setID;
		local numCollected = SetsDataProvider:GetSetSourceCounts(variantSetID);
		if ( numCollected > 0 and numCollected >= highestCount ) then
			highestCount = numCollected;
			highestCountSetID = variantSetID;
		end
	end
	return highestCountSetID or (variantSets[1] and variantSets[1].setID) or baseSetID;
end

function WardrobeSetsCollectionMixin:SelectSetFromButton(setID)
	CloseDropDownMenus();
	if IsModifiedClick("CHATLINK") then
		if ChatEdit_InsertLink(C_TransmogSets.GetSetHyperlink(self:GetDefaultSetIDForBaseSet(setID, true))) then
			return;
		end
	end
	self:SelectSet(self:GetDefaultSetIDForBaseSet(setID));
end

function WardrobeSetsCollectionMixin:SelectSet(setID)
	self.selectedSetID = setID;

	local baseSetID = C_TransmogSets.GetBaseSetID(setID);
	local variantSets = SetsDataProvider:GetVariantSets(baseSetID);
	if ( #variantSets > 0 ) then
		self.selectedVariantSets[baseSetID] = setID;
	end

	self:Refresh();
end

function WardrobeSetsCollectionMixin:GetSelectedSetID()
	return self.selectedSetID;
end

function WardrobeSetsCollectionMixin:SetAppearanceTooltip(frame)
	GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
	self.tooltipTransmogSlot = C_Transmog.GetSlotForInventoryType(frame.invType);
	self.tooltipPrimarySourceID = frame.sourceID;
	self.tooltipItemFrame = frame;
	self:RefreshAppearanceTooltip();
end

function WardrobeSetsCollectionMixin:RefreshAppearanceTooltip(cycle)
	if ( not self.tooltipTransmogSlot ) then
		return;
	end

	local sources = C_TransmogSets.GetSourcesForSlot(self:GetSelectedSetID(), self.tooltipTransmogSlot);
	if ( #sources == 0 ) then
		-- can happen if a slot only has HiddenUntilCollected sources
		local sourceInfo = C_TransmogCollection.GetSourceInfo(self.tooltipPrimarySourceID);
		tinsert(sources, sourceInfo);
	end
	CollectionWardrobeUtil.SortSources(sources, sources[1].visualID, self.tooltipPrimarySourceID);
	local selectedSource = WardrobeCollectionFrame_SetAppearanceTooltip(self, sources, self.tooltipPrimarySourceID, false);
	if cycle and selectedSource then
		self.tooltipItemFrame.previewedSource = selectedSource.sourceID;
		self.Model:TryOn(self.tooltipItemFrame.previewedSource);
	end
end

function WardrobeSetsCollectionMixin:ClearAppearanceTooltip()
	if self.tooltipItemFrame then
		self.tooltipItemFrame:EnableMouseWheel(false);
	end
	self.tooltipTransmogSlot = nil;
	self.tooltipPrimarySourceID = nil;
	self.tooltipItemFrame = nil;
	WardrobeCollectionFrame_HideAppearanceTooltip();
end

function WardrobeSetsCollectionMixin:CanHandleKey(key)
	if ( key == WARDROBE_UP_VISUAL_KEY or key == WARDROBE_DOWN_VISUAL_KEY ) then
		return true;
	end
	return false;
end

function WardrobeSetsCollectionMixin:HandleKey(key)
	if ( not self:GetSelectedSetID() ) then
		return false;
	end
	local selectedSetID = C_TransmogSets.GetBaseSetID(self:GetSelectedSetID());
	local _, index = SetsDataProvider:GetBaseSetByID(selectedSetID);
	if ( not index ) then
		return;
	end
	if ( key == WARDROBE_DOWN_VISUAL_KEY ) then
		index = index + 1;
	elseif ( key == WARDROBE_UP_VISUAL_KEY ) then
		index = index - 1;
	end
	local sets = SetsDataProvider:GetBaseSets();
	index = Clamp(index, 1, #sets);
	self:SelectSet(self:GetDefaultSetIDForBaseSet(sets[index].setID));
	self:ScrollToSet(sets[index].setID);
end

function WardrobeSetsCollectionMixin:ScrollToSet(setID)
	local totalHeight = 0;
	local scrollFrameHeight = self.ScrollFrame:GetHeight();
	local buttonHeight = self.ScrollFrame.buttonHeight;
	for i, set in ipairs(SetsDataProvider:GetBaseSets()) do
		if ( set.setID == setID ) then
			local offset = self.ScrollFrame.scrollBar:GetValue();
			if ( totalHeight + buttonHeight > offset + scrollFrameHeight ) then
				offset = totalHeight + buttonHeight - scrollFrameHeight;
			elseif ( totalHeight < offset ) then
				offset = totalHeight;
			end
			self.ScrollFrame.scrollBar:SetValue(offset, true);
			break;
		end
		totalHeight = totalHeight + buttonHeight;
	end
end

WardrobeSetsCollectionScrollFrameMixin = { };

local function WardrobeSetsCollectionScrollFrame_FavoriteDropDownInit(self)
	if ( not self.baseSetID ) then
		return;
	end

	local baseSet = SetsDataProvider:GetBaseSetByID(self.baseSetID);
	local variantSets = SetsDataProvider:GetVariantSets(self.baseSetID);
	local useDescription = (#variantSets > 0);

	local info = UIDropDownMenu_CreateInfo();
	info.notCheckable = true;
	info.disabled = nil;

	local isFavorite = baseSet.favoriteSetID;
	local targetSetID = WardrobeCollectionFrame.SetsCollectionFrame:GetDefaultSetIDForBaseSet(self.baseSetID, true);
	if not C_TransmogSets.GetBaseSetsFilter(LE_TRANSMOG_SET_FILTER_GROUP) then isFavorite = baseSet.favorite; end
	if isFavorite then
		if ( useDescription ) then
			local setInfo = C_TransmogSets.GetSetInfo(baseSet.favoriteSetID);
			info.text = format(TRANSMOG_SETS_UNFAVORITE_WITH_DESCRIPTION, setInfo.description);
		else
			info.text = BATTLE_PET_UNFAVORITE;
		end
		info.func = function()
			C_TransmogSets.SetIsFavorite(baseSet.favoriteSetID, false);
		end
	else
		if ( useDescription ) then
			local setInfo = C_TransmogSets.GetSetInfo(targetSetID);
			info.text = format(TRANSMOG_SETS_FAVORITE_WITH_DESCRIPTION, setInfo.description);
		else
			info.text = BATTLE_PET_FAVORITE;
		end
		info.func = function()
			C_TransmogSets.SetIsFavorite(targetSetID, true);
		end
	end

	UIDropDownMenu_AddButton(info);
	info.disabled = nil;

	info.text = TRANSMOG_OUTFIT_POST_IN_CHAT;
	if useDescription then
		local setInfo = C_TransmogSets.GetSetInfo(targetSetID);
		info.text = format("%s (%s)", info.text, setInfo.description);
	end
	info.func = function()
		local hyperlink = C_TransmogSets.GetSetHyperlink(targetSetID);
		if not ChatEdit_InsertLink(hyperlink) then
			ChatFrame_OpenChat(hyperlink);
		end
	end;
	UIDropDownMenu_AddButton(info);

	info.text = CANCEL;
	info.func = nil;
	UIDropDownMenu_AddButton(info);
end

function WardrobeSetsCollectionScrollFrameMixin:OnLoad()
	self.scrollBar.trackBG:Show();
	self.scrollBar.trackBG:SetVertexColor(0, 0, 0, 0.75);
	self.scrollBar.doNotHide = true;
	self.update = function() self:Update(); end
	HybridScrollFrame_CreateButtons(self, "WardrobeSetsScrollFrameButtonTemplate", 44, 0);
	UIDropDownMenu_Initialize(self.FavoriteDropDown, WardrobeSetsCollectionScrollFrame_FavoriteDropDownInit, "MENU");

	for _, button in ipairs(self.buttons) do
		Mixin(button.SelectedTexture, SetShownMixin);
		Mixin(button.Favorite, SetShownMixin);
		Mixin(button.New, SetShownMixin);
		Mixin(button.IconCover, SetShownMixin);
	end
end

function WardrobeSetsCollectionScrollFrameMixin:OnShow()
	ezCollections:RegisterEvent(self, "TRANSMOG_SETS_UPDATE_FAVORITE");
	ezCollections:RegisterEvent(self, "GET_ITEM_INFO_RECEIVED");
end

function WardrobeSetsCollectionScrollFrameMixin:OnHide()
	ezCollections:UnregisterEvent(self, "TRANSMOG_SETS_UPDATE_FAVORITE");
	ezCollections:UnregisterEvent(self, "GET_ITEM_INFO_RECEIVED");
end

function WardrobeSetsCollectionScrollFrameMixin:OnEvent(event, ...)
	if ( event == "TRANSMOG_SETS_UPDATE_FAVORITE" ) then
		SetsDataProvider:RefreshFavorites();
		self:Update();
	elseif event == "GET_ITEM_INFO_RECEIVED" then
		local item = ...;
		for _, button in ipairs(self.buttons) do
			if button:IsShown() and button.iconItemID == item then
				self:Update();
				return;
			end
		end
	end
end

function WardrobeSetsCollectionScrollFrameMixin:Update()
	local offset = HybridScrollFrame_GetOffset(self);
	local buttons = self.buttons;
	local baseSets = SetsDataProvider:GetBaseSets();

	-- show the base set as selected
	local selectedSetID = self:GetParent():GetSelectedSetID();
	local selectedBaseSetID = selectedSetID and C_TransmogSets.GetBaseSetID(selectedSetID);
	local variantSetsContainsSelectedSet = false;
	if selectedBaseSetID then
		local variantSets = SetsDataProvider:GetVariantSets(selectedBaseSetID);
		if #variantSets == 0 then
			variantSetsContainsSelectedSet = true;
		else
			for _, set in ipairs(variantSets) do
				if set.setID == selectedSetID then
					variantSetsContainsSelectedSet = true;
				end
			end
		end
	end

	for i = 1, #buttons do
		local button = buttons[i];
		local setIndex = i + offset;
		if ( setIndex <= #baseSets ) then
			local baseSet = baseSets[setIndex];
			button:Show();
			button.Name:SetText(baseSet.name);
			local topSourcesCollected, topSourcesTotal = SetsDataProvider:GetSetSourceTopCounts(baseSet.setID);
			local setCollected = C_TransmogSets.IsBaseSetCollected(baseSet.setID);
			local color = IN_PROGRESS_FONT_COLOR;
			if ( setCollected ) then
				color = NORMAL_FONT_COLOR;
			elseif ( topSourcesCollected == 0 ) then
				color = GRAY_FONT_COLOR;
			end
			button.Name:SetTextColor(color.r, color.g, color.b);
			button.Label:SetText(baseSet.label);
			local icon, iconItemID = SetsDataProvider:GetIconForSet(baseSet.setID);
			button.Icon:SetTexture(icon);
			button.iconItemID = iconItemID;
			button.Icon:SetDesaturated(topSourcesCollected == 0);
			button.SelectedTexture:SetShown(baseSet.setID == selectedBaseSetID and variantSetsContainsSelectedSet);
			button.Favorite:SetShown(baseSet.favoriteSetID);
			if not C_TransmogSets.GetBaseSetsFilter(LE_TRANSMOG_SET_FILTER_GROUP) then button.Favorite:SetShown(baseSet.favorite); end
			button.New:SetShown(SetsDataProvider:IsBaseSetNew(baseSet.setID));
			button.setID = baseSet.setID;

			if ( topSourcesCollected == 0 or setCollected ) then
				button.ProgressBar:Hide();
			else
				button.ProgressBar:Show();
				button.ProgressBar:SetWidth(SET_PROGRESS_BAR_MAX_WIDTH * topSourcesCollected / topSourcesTotal);
			end
			button.IconCover:SetShown(not setCollected);
		else
			button:Hide();
		end
	end
	
	local extraHeight = (self.largeButtonHeight and self.largeButtonHeight - BASE_SET_BUTTON_HEIGHT) or 0;
	local totalHeight = #baseSets * BASE_SET_BUTTON_HEIGHT + extraHeight;
	HybridScrollFrame_Update(self, totalHeight, self:GetHeight());
end

WardrobeSetsDetailsModelMixin = { };

function WardrobeSetsDetailsModelMixin:OnLoad()
	Mixin(self, ModelMixin, TransmogModelMixin);
	Model_OnLoad(self, MODELFRAME_MAX_PLAYER_ZOOM, 0, 0);
	self:SetAutoDress(false);
	self:UpdatePanAndZoomModelType();
	self:SetLight(1, 0, -1, 0, 0, .7, .7, .7, .7, .6, 1, 1, 1);
end

function WardrobeSetsDetailsModelMixin:UpdatePanAndZoomModelType()
	--[[
	local hasAlternateForm, inAlternateForm = HasAlternateForm();
	if ( not self.panAndZoomModelType or self.inAlternateForm ~= inAlternateForm ) then
		local _, race = UnitRace("player");
		local sex = UnitSex("player");
		if ( inAlternateForm ) then
			self.panAndZoomModelType = race..sex.."Alt";
		else
			self.panAndZoomModelType = race..sex;
		end
		self.inAlternateForm = inAlternateForm;
	end
	]]
end

--[[
function WardrobeSetsDetailsModelMixin:GetPanAndZoomLimits()
	return SET_MODEL_PAN_AND_ZOOM_LIMITS[self.panAndZoomModelType];
end

function WardrobeSetsDetailsModelMixin:OnUpdate(elapsed)
	if ( self.rotating ) then
		local x = GetCursorPosition();
		local diff = (x - self.rotateStartCursorX) * MODELFRAME_DRAG_ROTATION_CONSTANT;
		self.rotateStartCursorX = GetCursorPosition();
		self.yaw = self.yaw + diff;
		if ( self.yaw < 0 ) then
			self.yaw = self.yaw + (2 * PI);
		end
		if ( self.yaw > (2 * PI) ) then
			self.yaw = self.yaw - (2 * PI);
		end
		self:SetRotation(self.yaw, false);
	elseif ( self.panning ) then
		local cursorX, cursorY = GetCursorPosition();
		local modelX = self:GetPosition();
		local panSpeedModifier = 100 * sqrt(1 + modelX - self.defaultPosX);
		local modelY = self.panStartModelY + (cursorX - self.panStartCursorX) / panSpeedModifier;
		local modelZ = self.panStartModelZ + (cursorY - self.panStartCursorY) / panSpeedModifier;
		local limits = self:GetPanAndZoomLimits();
		modelY = Clamp(modelY, limits.panMaxLeft, limits.panMaxRight);
		modelZ = Clamp(modelZ, limits.panMaxBottom, limits.panMaxTop);
		self:SetPosition(modelX, modelY, modelZ);
	end
end

function WardrobeSetsDetailsModelMixin:OnMouseDown(button)
	if ( button == "LeftButton" ) then
		self.rotating = true;
		self.rotateStartCursorX = GetCursorPosition();
	elseif ( button == "RightButton" ) then
		self.panning = true;
		self.panStartCursorX, self.panStartCursorY = GetCursorPosition();
		local modelX, modelY, modelZ = self:GetPosition();
		self.panStartModelY = modelY;
		self.panStartModelZ = modelZ;
	end
end

function WardrobeSetsDetailsModelMixin:OnMouseUp(button)
	if ( button == "LeftButton" ) then
		self.rotating = false;
	elseif ( button == "RightButton" ) then
		self.panning = false;
	end
end

function WardrobeSetsDetailsModelMixin:OnMouseWheel(delta)
	local posX, posY, posZ = self:GetPosition();
	posX = posX + delta * 0.5;
	local limits = self:GetPanAndZoomLimits();
	posX = Clamp(posX, self.defaultPosX, limits.maxZoom);
	self:SetPosition(posX, posY, posZ);
end
]]

function WardrobeSetsDetailsModelMixin:OnModelLoaded()
	if ( self.cameraID ) then
		Model_ApplyUICamera(self, self.cameraID);
	end
end

function WardrobeSetsDetailsModelMixin:OnShow()
	self:SetType("player");
	self:OnModelLoaded();
end

function WardrobeSetsDetailsModelMixin:OnHide()
	self:SetPosition(0, 0, 0);
	self:SetFacing(0);
	self.cameraID = nil;
end

WardrobeSetsDetailsItemMixin = { };

function WardrobeSetsDetailsItemMixin:OnEnter()
	self:GetParent():GetParent():SetAppearanceTooltip(self)

	self:SetScript("OnUpdate", 
		function()
			if IsModifiedClick("DRESSUP") then
				ShowInspectCursor();
			else
				ResetCursor();
			end
		end
	);

	if ( self.New:IsShown() ) then
		local transmogSlot = C_Transmog.GetSlotForInventoryType(self.invType);
		local setID = WardrobeCollectionFrame.SetsCollectionFrame:GetSelectedSetID();
		C_TransmogSets.ClearSetNewSourcesForSlot(setID, transmogSlot);
		local baseSetID = C_TransmogSets.GetBaseSetID(setID);
		SetsDataProvider:ResetBaseSetNewStatus(baseSetID);
		WardrobeCollectionFrame.SetsCollectionFrame:Refresh();
	end
end

function WardrobeSetsDetailsItemMixin:OnLeave()
	self:SetScript("OnUpdate", nil);
	ResetCursor();
	WardrobeCollectionFrame_HideAppearanceTooltip();
end

function WardrobeSetsDetailsItemMixin:OnMouseDown()
	if ( IsModifiedClick("CHATLINK") ) then
		local link = select(6, C_TransmogCollection.GetAppearanceSourceInfo(self.previewedSource or self.sourceID));
		if ( link ) then
			HandleModifiedItemClick(link);
		end
	elseif ( IsModifiedClick("DRESSUP") ) then
		DressUpVisual(self.previewedSource or self.sourceID);
	end
end

WardrobeSetsTransmogMixin = { };

function WardrobeSetsTransmogMixin:OnLoad()
	self.NUM_ROWS = 2;
	self.NUM_COLS = 4;
	self.PAGE_SIZE = self.NUM_ROWS * self.NUM_COLS;
	self.APPLIED_SOURCE_INDEX = 1;
	self.SELECTED_SOURCE_INDEX = 3;

	self.Models =
	{
		self.ModelR1C1,
		self.ModelR1C2,
		self.ModelR1C3,
		self.ModelR1C4,
		self.ModelR2C1,
		self.ModelR2C2,
		self.ModelR2C3,
		self.ModelR2C4,
	};
	Mixin(self.NoValidSetsLabel, SetShownMixin);

	local function OpenRightClickDropDown(self)
		self:GetParent():OpenRightClickDropDown();
	end
	UIDropDownMenu_Initialize(WardrobeSetsTransmogModelRightClickDropDown, OpenRightClickDropDown, "MENU");
end

function WardrobeSetsTransmogMixin:OnShow()
	ezCollections:RegisterEvent(self, "TRANSMOGRIFY_UPDATE");
	ezCollections:RegisterEvent(self, "TRANSMOGRIFY_SUCCESS");
	ezCollections:RegisterEvent(self, "TRANSMOG_COLLECTION_ITEM_UPDATE");
	ezCollections:RegisterEvent(self, "TRANSMOG_COLLECTION_UPDATED");
	ezCollections:RegisterEvent(self, "PLAYER_EQUIPMENT_CHANGED");
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
	ezCollections:RegisterEvent(self, "TRANSMOG_SETS_UPDATE_FAVORITE");
	self:RefreshCameras();
	local RESET_SELECTION = true;
	self:Refresh(RESET_SELECTION);
	WardrobeCollectionFrame_UpdateProgressBar(C_TransmogSets.GetBaseSetsCounts());
	self.sourceQualityTable = { };

	if (self:GetParent().SetsTabHelpBox:IsShown()) then
		self:GetParent().SetsTabHelpBox:Hide();
		ezCollections:SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_TRANSMOG_SETS_VENDOR_TAB, true);
	end
end

function WardrobeSetsTransmogMixin:OnHide()
	ezCollections:UnregisterEvent(self, "TRANSMOGRIFY_UPDATE");
	ezCollections:UnregisterEvent(self, "TRANSMOGRIFY_SUCCESS");
	ezCollections:UnregisterEvent(self, "TRANSMOG_COLLECTION_ITEM_UPDATE");
	ezCollections:UnregisterEvent(self, "TRANSMOG_COLLECTION_UPDATED");
	ezCollections:UnregisterEvent(self, "PLAYER_EQUIPMENT_CHANGED");
	self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED");
	ezCollections:UnregisterEvent(self, "TRANSMOG_SETS_UPDATE_FAVORITE");
	self.loadingSetID = nil;
	SetsDataProvider:ClearSets();
	WardrobeCollectionFrame_ClearSearch(LE_TRANSMOG_SEARCH_TYPE_USABLE_SETS);
	self.sourceQualityTable = nil;
end

function WardrobeSetsTransmogMixin:OnEvent(event, ...)
	if ( event == "TRANSMOGRIFY_UPDATE" and not self.ignoreTransmogrifyUpdateEvent ) then
		if ( not self.transmogrifySuccessUpdate ) then
			self.transmogrifySuccessUpdate = true;
			C_Timer.After(0, function() self.transmogrifySuccessUpdate = nil; self:Refresh(); end);
		end
	elseif ( event == "TRANSMOGRIFY_SUCCESS" )  then
		-- this event fires once per slot so in the case of a set there would be up to 9 of them
		if ( not self.transmogrifySuccessUpdate ) then
			self.transmogrifySuccessUpdate = true;
			C_Timer.After(0, function() self.transmogrifySuccessUpdate = nil; self:Refresh(); end);
		end
	elseif ( event == "TRANSMOG_COLLECTION_UPDATED" or event == "TRANSMOG_SETS_UPDATE_FAVORITE" ) then
		SetsDataProvider:ClearSets();
		self:RefreshCameras();
		self:Refresh();
		WardrobeCollectionFrame_UpdateProgressBar(C_TransmogSets.GetBaseSetsCounts());
	elseif ( event == "TRANSMOG_COLLECTION_ITEM_UPDATE" ) then
		if ( self.loadingSetID ) then
			local setID = self.loadingSetID;
			self.loadingSetID = nil;
			self:LoadSet(setID);
		end
		if ( self.tooltipModel ) then
			self.tooltipModel:RefreshTooltip();
		end
	elseif ( event == "PLAYER_EQUIPMENT_CHANGED" ) then
		if ( self.selectedSetID ) then
			self:LoadSet(self.selectedSetID);
		end
		self:Refresh();
	end
end

function WardrobeSetsTransmogMixin:OnMouseWheel(value)
	self.PagingFrame:OnMouseWheel(value);
end

function WardrobeSetsTransmogMixin:Refresh(resetSelection)
	self.appliedSetID = self:GetFirstMatchingSetID(self.APPLIED_SOURCE_INDEX);
	if ( resetSelection ) then
		self.selectedSetID = self:GetFirstMatchingSetID(self.SELECTED_SOURCE_INDEX);
		self:ResetPage();
	else
		self:UpdateSets();
	end
end

function WardrobeSetsTransmogMixin:UpdateSets()
	if not self:IsShown() then return; end -- UpdateSets can be delayed for one frame (see WardrobeSetsTransmogMixin:OnEvent) leading to it being updated after already being hidden, causing models to bug out
	local usableSets = SetsDataProvider:GetUsableSets();
	self.PagingFrame:SetMaxPages(ceil(#usableSets / self.PAGE_SIZE));
	local pendingTransmogModelFrame = nil;
	local indexOffset = (self.PagingFrame:GetCurrentPage() - 1) * self.PAGE_SIZE;
	for i = 1, self.PAGE_SIZE do
		local model = self.Models[i];
		local index = i + indexOffset;
		local set = usableSets[index];
		if ( set ) then
			if model.setID ~= set.setID then
				model:Hide();
			end
			model:SetPosition(0, 0, 0);
			model:SetFacing(0);
			model:Show();
			if ( model.cameraID ) then
				Model_ApplyUICamera(model, model.cameraID);
			end
			if ( model.setID ~= set.setID ) then
				model:Undress();
				local sourceData = SetsDataProvider:GetSetSourceData(set.setID);
				for sourceID  in pairs(sourceData.sources) do
					model:TryOn(sourceID);
				end
			end
			local transmogStateAtlas;
			if ( set.setID == self.appliedSetID and set.setID == self.selectedSetID ) then
				transmogStateAtlas = "transmog-set-border-current-transmogged";
			elseif ( set.setID == self.selectedSetID ) then
				transmogStateAtlas = "transmog-set-border-selected";
				pendingTransmogModelFrame = model;
			end
			if ( transmogStateAtlas ) then
				model.TransmogStateTexture:SetAtlas(transmogStateAtlas, true);
				model.TransmogStateTexture:Show();
			else
				model.TransmogStateTexture:Hide();
			end
			model.Favorite.Icon:SetShown(set.favorite);
			model.setID = set.setID;
		else
			model:Hide();
		end
	end

	if ( pendingTransmogModelFrame ) then
		self.PendingTransmogFrame:SetParent(pendingTransmogModelFrame);
		self.PendingTransmogFrame:SetPoint("CENTER");
		self.PendingTransmogFrame:Show();
		if ( self.PendingTransmogFrame.setID ~= pendingTransmogModelFrame.setID ) then
			self.PendingTransmogFrame.Wisp1.TransmogSelectedAnim:Stop();
			self.PendingTransmogFrame.Wisp1.TransmogSelectedAnim:Play();
			self.PendingTransmogFrame.Wisp2.TransmogSelectedAnim:Stop();
			self.PendingTransmogFrame.Wisp2.TransmogSelectedAnim:Play();
			self.PendingTransmogFrame.Wisp3.TransmogSelectedAnim:Stop();
			self.PendingTransmogFrame.Wisp3.TransmogSelectedAnim:Play();
			self.PendingTransmogFrame.Wisp4.TransmogSelectedAnim:Stop();
			self.PendingTransmogFrame.Wisp4.TransmogSelectedAnim:Play();
			self.PendingTransmogFrame.Wisp5.TransmogSelectedAnim:Stop();
			self.PendingTransmogFrame.Wisp5.TransmogSelectedAnim:Play();
			self.PendingTransmogFrame.Wisp6.TransmogSelectedAnim:Stop();
			self.PendingTransmogFrame.Wisp6.TransmogSelectedAnim:Play();
			self.PendingTransmogFrame.Wisp7.TransmogSelectedAnim:Stop();
			self.PendingTransmogFrame.Wisp7.TransmogSelectedAnim:Play();
			self.PendingTransmogFrame.Wisp8.TransmogSelectedAnim:Stop();
			self.PendingTransmogFrame.Wisp8.TransmogSelectedAnim:Play();
			self.PendingTransmogFrame.Glowframe.TransmogSelectedAnim2:Stop();
			self.PendingTransmogFrame.Glowframe.TransmogSelectedAnim2:Play();
			self.PendingTransmogFrame.Wisp9.TransmogSelectedAnim3:Stop();
			self.PendingTransmogFrame.Wisp9.TransmogSelectedAnim3:Play();
			self.PendingTransmogFrame.Wisp10.TransmogSelectedAnim3:Stop();
			self.PendingTransmogFrame.Wisp10.TransmogSelectedAnim3:Play();
			self.PendingTransmogFrame.Wisp11.TransmogSelectedAnim3:Stop();
			self.PendingTransmogFrame.Wisp11.TransmogSelectedAnim3:Play();
			self.PendingTransmogFrame.Wisp12.TransmogSelectedAnim3:Stop();
			self.PendingTransmogFrame.Wisp12.TransmogSelectedAnim3:Play();
			self.PendingTransmogFrame.Smoke1.TransmogSelectedAnim4:Stop();
			self.PendingTransmogFrame.Smoke1.TransmogSelectedAnim4:Play();
			self.PendingTransmogFrame.Smoke2.TransmogSelectedAnim4:Stop();
			self.PendingTransmogFrame.Smoke2.TransmogSelectedAnim4:Play();
			self.PendingTransmogFrame.Smoke3.TransmogSelectedAnim5:Stop();
			self.PendingTransmogFrame.Smoke3.TransmogSelectedAnim5:Play();
			self.PendingTransmogFrame.Smoke4.TransmogSelectedAnim5:Stop();
			self.PendingTransmogFrame.Smoke4.TransmogSelectedAnim5:Play();
		end
		self.PendingTransmogFrame.setID = pendingTransmogModelFrame.setID;
	else
		self.PendingTransmogFrame:Hide();
	end

	self.NoValidSetsLabel:SetShown(not C_TransmogSets.HasUsableSets());
end

function WardrobeSetsTransmogMixin:OnPageChanged(userAction)
	PlaySound("igAbiliityPageTurn");
	CloseDropDownMenus();
	if ( userAction ) then
		self:UpdateSets();
	end
end

function WardrobeSetsTransmogMixin:LoadSet(setID)
	local waitingOnData = false;
	local transmogSources = { };
	local sources = C_TransmogSets.GetUsableSetSources(setID);
	if not sources then
		self.loadingSetID = setID;
		return;
	end
	for sourceID in pairs(sources) do
		local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID);
		local slot = C_Transmog.GetSlotForInventoryType(sourceInfo.invType);
		local slotSources = C_TransmogSets.GetSourcesForSlot(setID, slot);
		CollectionWardrobeUtil.SortSources(slotSources, sourceInfo.visualID);
		local index = CollectionWardrobeUtil.GetDefaultSourceIndex(slotSources, sourceID);
		transmogSources[slot] = slotSources[index].sourceID;

		for i, slotSourceInfo in ipairs(slotSources) do
			if ( not slotSourceInfo.name ) then
				waitingOnData = true;
				ezCollections:QueryItem(slotSourceInfo.sourceID);
			end
		end
	end
	if ( waitingOnData ) then
		self.loadingSetID = setID;
	else
		self.loadingSetID = nil;
		-- if we don't ignore the event, clearing will momentarily set the page to the one with the set the user currently has transmogged
		-- if that's a different page from the current one then the models will flicker as we swap the gear to different sets and back
		self.ignoreTransmogrifyUpdateEvent = true;
		C_Transmog.ClearPending();
		self.ignoreTransmogrifyUpdateEvent = false;
		C_Transmog.LoadSources(transmogSources, -1, -1, true);
	end
end

function WardrobeSetsTransmogMixin:GetFirstMatchingSetID(sourceIndex)
	local transmogSourceIDs = { };
	for _, button in ipairs(WardrobeTransmogFrame.Model.SlotButtons) do
		local slotID = GetInventorySlotInfo(button.slot);
		local sourceID = select(sourceIndex, WardrobeCollectionFrame_GetInfoForEquippedSlot(button.slot, LE_TRANSMOG_TYPE_APPEARANCE));
		if ( sourceID ~= NO_TRANSMOG_SOURCE_ID ) then
			transmogSourceIDs[slotID] = sourceID;
		end
	end

	local usableSets = SetsDataProvider:GetUsableSets();
	for _, set in ipairs(usableSets) do
		local setMatched = false;
		for slotID, transmogSourceID in pairs(transmogSourceIDs) do
			local sourceIDs = C_TransmogSets.GetSourceIDsForSlot(set.setID, slotID);
			-- if there are no sources for a slot, that slot is considered matched
			local slotMatched = (#sourceIDs == 0);
			for _, sourceID in ipairs(sourceIDs) do
				if ( transmogSourceID == sourceID ) then
					slotMatched = true;
					break;
				end
			end
			setMatched = slotMatched;
			if ( not setMatched ) then
				break;
			end
		end
		if ( setMatched ) then
			return set.setID;
		end
	end
	return nil;
end

function WardrobeSetsTransmogMixin:OnUnitModelChangedEvent()
	if ( self.Models[1]:CanSetUnit("player") ) then
		for i, model in ipairs(self.Models) do
			model:RefreshUnit();
			model.setID = nil;
		end
		self:RefreshCameras();
		self:UpdateSets();
		return true;
	else
		return false;
	end
end

function WardrobeSetsTransmogMixin:RefreshCameras()
	if ( self:IsShown() ) then
		local detailsCameraID, transmogCameraID = C_TransmogSets.GetCameraIDs();
		for i, model in ipairs(self.Models) do
			model.cameraID = transmogCameraID;
			model:RefreshCamera();
			Model_ApplyUICamera(model, transmogCameraID);
		end
	end
end

function WardrobeSetsTransmogMixin:OnSearchUpdate()
	SetsDataProvider:ClearUsableSets();
	self:UpdateSets();
end

function WardrobeSetsTransmogMixin:SelectSet(setID)
	self.selectedSetID = setID;
	if IsModifiedClick("CHATLINK") then
		if ChatEdit_InsertLink(C_TransmogSets.GetSetHyperlink(setID)) then
			return;
		end
	end
	self:LoadSet(setID);
	self:ResetPage();
end

function WardrobeSetsTransmogMixin:CanHandleKey(key)
	if ( key == WARDROBE_PREV_VISUAL_KEY or key == WARDROBE_NEXT_VISUAL_KEY or key == WARDROBE_UP_VISUAL_KEY or key == WARDROBE_DOWN_VISUAL_KEY ) then
		return true;
	end
	return false;
end

function WardrobeSetsTransmogMixin:HandleKey(key)
	if ( not self.selectedSetID ) then
		return;
	end

	local setIndex;
	local usableSets = SetsDataProvider:GetUsableSets();
	for i = 1, #usableSets do
		if ( usableSets[i].setID == self.selectedSetID ) then
			setIndex = i;
			break;
		end
	end
	
	if ( setIndex ) then
		setIndex = WardrobeUtils_GetAdjustedDisplayIndexFromKeyPress(self, setIndex, #usableSets, key);
		self:SelectSet(usableSets[setIndex].setID);
	end
end

function WardrobeSetsTransmogMixin:ResetPage()
	local page = 1;
	if ( self.selectedSetID ) then
		local usableSets = SetsDataProvider:GetUsableSets();
		self.PagingFrame:SetMaxPages(ceil(#usableSets / self.PAGE_SIZE));
		for i, set in ipairs(usableSets) do
			if ( set.setID == self.selectedSetID ) then
				page = GetPage(i, self.PAGE_SIZE);
				break;
			end
		end
	end
	self.PagingFrame:SetCurrentPage(page);
	self:UpdateSets();
end

function WardrobeSetsTransmogMixin:OpenRightClickDropDown()
	if ( not self.RightClickDropDown.activeFrame ) then
		return;
	end
	local setID = self.RightClickDropDown.activeFrame.setID;
	local info = UIDropDownMenu_CreateInfo();
	if ( C_TransmogSets.GetIsFavorite(setID) ) then
		info.text = BATTLE_PET_UNFAVORITE;
		info.func = function() self:SetFavorite(setID, false); end
	else
		info.text = BATTLE_PET_FAVORITE;
		info.func = function() self:SetFavorite(setID, true); end
	end
	info.notCheckable = true;
	UIDropDownMenu_AddButton(info);

	info.text = ezCollections.L["Transmog.Sets.ViewInCollections"];
	info.func = function()
		if not CollectionsJournal:IsVisible() or not WardrobeCollectionFrame:IsVisible() then
			ToggleCollectionsJournal(COLLECTIONS_JOURNAL_TAB_INDEX_APPEARANCES);
		end
		WardrobeCollectionFrame_SetTab(TAB_SETS);
		WardrobeCollectionFrame.SetsCollectionFrame:SelectSet(setID);
		WardrobeCollectionFrame.SetsCollectionFrame:ScrollToSet(C_TransmogSets.GetBaseSetID(setID));
	end;
	UIDropDownMenu_AddButton(info);

	info.text = TRANSMOG_OUTFIT_POST_IN_CHAT;
	info.func = function()
		local hyperlink = C_TransmogSets.GetSetHyperlink(setID);
		if not ChatEdit_InsertLink(hyperlink) then
			ChatFrame_OpenChat(hyperlink);
		end
	end;
	UIDropDownMenu_AddButton(info);

	-- Cancel
	info = UIDropDownMenu_CreateInfo();
	info.notCheckable = true;
	info.text = CANCEL;
	UIDropDownMenu_AddButton(info);	
end

function WardrobeSetsTransmogMixin:SetFavorite(setID, favorite)
	if ( favorite ) then
		-- remove any existing favorite in this group
		local isFavorite, isGroupFavorite = C_TransmogSets.GetIsFavorite(setID);
		if ( isGroupFavorite ) then
			local baseSetID = C_TransmogSets.GetBaseSetID(setID);
			C_TransmogSets.SetIsFavorite(baseSetID, false);
			local variantSets = C_TransmogSets.GetVariantSets(baseSetID);
			for i, variantSet in ipairs(variantSets) do
				C_TransmogSets.SetIsFavorite(variantSet.setID, false);
			end
		end
		C_TransmogSets.SetIsFavorite(setID, true);
	else
		C_TransmogSets.SetIsFavorite(setID, false);
	end
end
