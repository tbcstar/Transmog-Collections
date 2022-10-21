local COMPANION_BUTTON_HEIGHT = 46;
local SUMMON_RANDOM_FAVORITE_PET_SPELL = 243819;

function GetPetTypeTexture(petType)
	if PET_TYPE_SUFFIX[petType] then
		return [[Interface\AddOns\ezCollections\Interface\PetBattles\PetIcon-]]..PET_TYPE_SUFFIX[petType];
	else
		return [[Interface\AddOns\ezCollections\Interface\PetBattles\PetIcon-NO_TYPE]];
	end
end

function PetJournal_OnLoad(self)
	Mixin(self, SetShownMixin);
	Mixin(self.SummonButton, SetEnabledMixin);
	Mixin(self.SubscriptionStatus, SetShownMixin);
	self.TypeInfo = self.PetDisplay.TypeInfo;

	self:RegisterEvent("COMPANION_LEARNED");
	self:RegisterEvent("COMPANION_UNLEARNED");
	self:RegisterEvent("COMPANION_UPDATE");
	ezCollections:RegisterEvent(self, "PET_JOURNAL_SEARCH_UPDATED");
	self.ListScrollFrame.update = PetJournal_UpdatePetList;
	self.ListScrollFrame.scrollBar.doNotHide = true;
	HybridScrollFrame_CreateButtons(self.ListScrollFrame, "PetListButtonTemplate", 44, 0);
	ezCollections:UIDropDownMenu_Initialize(self.petOptionsMenu, PetOptionsMenu_Init, "MENU");
end

function PetJournal_OnEvent(self, event, ...)
	if ( event == "COMPANION_LEARNED" or event == "COMPANION_UNLEARNED" or event == "COMPANION_UPDATE" ) then
		local companionType = ...;
		if ( not companionType or companionType == "CRITTER" ) then
			if (self:IsVisible()) then
				if not self.deferredUpdate then
					self.deferredUpdate = true;
					C_Timer.After(0.1, function()
						self.deferredUpdate = false;
						C_PetJournal.RefreshPets();
						PetJournal_UpdatePetList();
						PetJournal_UpdatePetDisplay();
					end);
				end
			end
		end
	elseif ( event == "PET_JOURNAL_SEARCH_UPDATED" ) then
		if (self:IsVisible()) then
			self.deferredUpdate = false;
			C_PetJournal.RefreshPets();
			PetJournal_UpdatePetList();
			PetJournal_UpdatePetDisplay();
		end
	end
end

function PetJournal_OnShow(self)
	C_PetJournal.RefreshPets();
	PetJournal_UpdatePetList();
	if (not PetJournal.selectedSpellID) then
		PetJournal_Select(1);
	end
	PetJournal_UpdatePetDisplay();
	SetPortraitToTexture(CollectionsJournalPortrait, [[Interface\Icons\INV_Misc_Rabbit]]);
	PetJournalResetFiltersButton_UpdateVisibility();
	-- Fix frame levels
	self.LeftInset:SetFrameLevel(self:GetFrameLevel() + 1);
	self.RightInset:SetFrameLevel(self:GetFrameLevel() + 1);
	self.searchBox:SetFrameLevel(self:GetFrameLevel() + 2);
	PetJournalFilterButton:SetFrameLevel(self:GetFrameLevel() + 2);
	self.PetDisplay:SetFrameLevel(self:GetFrameLevel() + 2);
	self.ListScrollFrame:SetFrameLevel(self:GetFrameLevel() + 2);
end

function PetJournal_OnHide(self)
	C_PetJournal.ClearRecentFanfares();
end

function PetJournal_UpdatePetList()
	local scrollFrame = PetJournal.ListScrollFrame;
	local offset = HybridScrollFrame_GetOffset(scrollFrame);
	local buttons = scrollFrame.buttons;

	local numPets, numOwned = C_PetJournal.GetNumPets();

	local showPets = true;
	if  ( numPets < 1 ) then
		-- display the no pets message on the right hand side
		PetJournal.PetDisplay.NoPets:Show();
		showPets = false;
	else
		PetJournal.PetDisplay.NoPets:Hide();
	end

	local numDisplayedPets = C_PetJournal.GetNumDisplayedPets();
	for i=1, #buttons do
		local button = buttons[i];
		local displayIndex = i + offset;
		if ( displayIndex <= numDisplayedPets and showPets ) then
			local index = displayIndex;
			local petID, _, isCollected, _, _, isFavorite, _, creatureName, icon, petType = C_PetJournal.GetPetInfoByIndex(index);
			local spellID = petID;
			local active = C_PetJournal.GetSummonedPetGUID() == petID;
			local isUsable = C_PetJournal.PetIsUsable(petID);
			local needsFanFare = C_PetJournal.PetNeedsFanfare(petID);

			button.name:SetText(creatureName);
			button.icon:SetTexture(--[[needsFanFare and COLLECTIONS_FANFARE_ICON or]] icon);
			button.new:SetShown(needsFanFare);
			button.newGlow:SetShown(needsFanFare);
			button.petTypeIcon:SetTexture(GetPetTypeTexture(petType));
			button.SubscriptionOverlay:SetShown(ezCollections:IsActivePetSubscriptionPet(petID));

			button.index = index;
			button.spellID = spellID;

			button.active = active;
			if (active) then
				button.DragButton.ActiveTexture:Show();
			else
				button.DragButton.ActiveTexture:Hide();
			end
			button:Show();

			if ( PetJournal.selectedSpellID == spellID ) then
				button.selected = true;
				button.selectedTexture:Show();
			else
				button.selected = false;
				button.selectedTexture:Hide();
			end
			button:SetEnabled(true);
			button.unusable:Hide();
			button.iconBorder:Hide();
			button.background:SetVertexColor(1, 1, 1, 1);
			if (isUsable --[[or needsFanFare]]) then
				button.DragButton:SetEnabled(true);
				button.additionalText = nil;
				button.icon:SetDesaturated(false);
				button.icon:SetAlpha(1.0);
				button.name:SetFontObject("GameFontNormal");
				button.petTypeIcon:Show();
				button.petTypeIcon:SetDesaturated(false);
			else
				if (isCollected) then
					button.unusable:Show();
					button.DragButton:SetEnabled(true);
					button.name:SetFontObject("GameFontNormal");
					button.icon:SetAlpha(0.75);
					button.additionalText = nil;
					button.background:SetVertexColor(1, 0, 0, 1);
					button.petTypeIcon:Show();
					button.petTypeIcon:SetDesaturated(false);
				else
					button.icon:SetDesaturated(true);
					button.DragButton:SetEnabled(false);
					button.icon:SetAlpha(0.25);
					button.additionalText = nil;
					button.name:SetFontObject("GameFontDisable");
					button.petTypeIcon:Show();
					button.petTypeIcon:SetDesaturated(true);
				end
			end

			if ( isFavorite ) then
				button.favorite:Show();
			else
				button.favorite:Hide();
			end

			if ( button.showingTooltip ) then
				PetJournalSummonButton_UpdateTooltip(button);
			end
		else
			button.name:SetText("");
			button.icon:SetTexture([[Interface\AddOns\ezCollections\Interface\PetBattles\MountJournalEmptyIcon]]);
			button.new:Hide();
			button.newGlow:Hide();
			button.SubscriptionOverlay:Hide();
			button.index = nil;
			button.spellID = 0;
			button.selected = false;
			button.unusable:Hide();
			button.DragButton.ActiveTexture:Hide();
			button.selectedTexture:Hide();
			button:SetEnabled(false);
			button.DragButton:SetEnabled(false);
			button.icon:SetDesaturated(true);
			button.icon:SetAlpha(0.5);
			button.favorite:Hide();
			button.background:SetVertexColor(1, 1, 1, 1);
			button.iconBorder:Hide();
			button.petTypeIcon:Hide();
		end
	end

	local totalHeight = numDisplayedPets * COMPANION_BUTTON_HEIGHT;
	HybridScrollFrame_Update(scrollFrame, totalHeight, scrollFrame:GetHeight());
	PetJournal.PetCount.Count:SetText(numOwned);
	if ( not showPets ) then
		PetJournal.selectedSpellID = nil;
		PetJournal.selectedPetID = nil;
		PetJournal_UpdatePetDisplay();
		PetJournal.PetCount.Count:SetText(0);
	end

	PetJournal.SubscriptionStatus.SubscriptionInfo:SetShown(ezCollections:IsActivePetSubscription());
	PetJournal.SubscriptionStatus:SetShown(PetJournal.SubscriptionStatus.SubscriptionInfo:IsShown());
end

function PetJournalSummonButton_UpdateTooltip(self)
	GameTooltip:SetHyperlink("spell:"..self.spellID);
end

function PetJournal_UpdatePetDisplay()
	if ( PetJournal.selectedPetID ) then
		local creatureName, icon, petType, creatureDisplayID, sourceText, descriptionText = C_PetJournal.GetPetInfoBySpeciesID(PetJournal.selectedPetID);
		local spellID = PetJournal.selectedPetID;
		local active = C_PetJournal.GetSummonedPetGUID() == PetJournal.selectedPetID;
		local isUsable = C_PetJournal.PetIsUsable(PetJournal.selectedPetID);
		if creatureName and ( PetJournal.PetDisplay.lastDisplayed ~= spellID ) then
			local needsFanFare = C_PetJournal.PetNeedsFanfare(PetJournal.selectedPetID);

			PetJournal.PetDisplay.InfoButton.Name:SetText(creatureName);

			if needsFanFare then
				PetJournal.PetDisplay.InfoButton.New:Show();
				PetJournal.PetDisplay.InfoButton.NewGlow:Show();

				local offsetX = math.min(PetJournal.PetDisplay.InfoButton.Name:GetStringWidth(), PetJournal.PetDisplay.InfoButton.Name:GetWidth());
				PetJournal.PetDisplay.InfoButton.New:SetPoint("LEFT", PetJournal.PetDisplay.InfoButton.Name, "LEFT", offsetX + 8, 0);

				--PetJournal.PetDisplay.InfoButton.Icon:SetTexture(COLLECTIONS_FANFARE_ICON);
				PetJournal.PetDisplay.InfoButton.Icon:SetTexture(icon);
			else
				PetJournal.PetDisplay.InfoButton.New:Hide();
				PetJournal.PetDisplay.InfoButton.NewGlow:Hide();

				PetJournal.PetDisplay.InfoButton.Icon:SetTexture(icon);
			end

			PetJournal.PetDisplay.InfoButton.SubscriptionInfo:SetText(ezCollections:IsActivePetSubscriptionPet(PetJournal.selectedPetID) and ezCollections.L["Pet.Subscription.Details.Info"] or "");
			PetJournal.PetDisplay.InfoButton.Source:SetText(sourceText);
			PetJournal.PetDisplay.InfoButton.Lore:SetText(descriptionText)

			PetJournal.PetDisplay.lastDisplayed = spellID;

			if creatureDisplayID == 0 then
				--[[
				local raceID = UnitRace("player");
				local gender = UnitSex("player");
				PetJournal.PetDisplay.ModelFrame:SetCustomRace(raceID, gender);
				]]
			else
				PetJournal.PetDisplay.ModelFrame:Hide();
				PetJournal.PetDisplay.ModelFrame:SetPosition(0, 0, 0);
				PetJournal.PetDisplay.ModelFrame.zoomLevel = 0;
				PetJournal.PetDisplay.ModelFrame:Show();
				PetJournal.PetDisplay.ModelFrame:SetCreature(creatureDisplayID);
			end

			--[[
			if needsFanFare then
				PetJournal.PetDisplay.WrappedModelFrame:Show();
				if not PetJournal.PetDisplay.UnwrapAnim:IsPlaying() then
					PetJournal.PetDisplay.ModelFrame:SetAlpha(0);
					PetJournal.PetDisplay.WrappedModelFrame:SetAnimation(0);
					PetJournal.PetDisplay.WrappedModelFrame:SetAlpha(1);
				end
			else
				PetJournal.PetDisplay.WrappedModelFrame:Hide();
				if not PetJournal.PetDisplay.UnwrapAnim:IsPlaying() then
					PetJournal.PetDisplay.ModelFrame:SetAlpha(1);
				end
			end
			]]
		end

		PetJournal.PetDisplay.ModelFrame:Show();
		PetJournal.PetDisplay.YesPetsTex:Show();
		PetJournal.PetDisplay.InfoButton:Show();
		PetJournal.PetDisplay.NoPetsTex:Hide();
		PetJournal.PetDisplay.NoPets:Hide();

		--[[
		if (C_PetJournal.PetNeedsFanfare(PetJournal.selectedPetID) ) then
			PetJournal.SummonButton:SetText(UNWRAP)
			PetJournal.SummonButton:Enable();
		else]]if ( active ) then
			PetJournal.SummonButton:SetText(PET_DISMISS);
			PetJournal.SummonButton:SetEnabled(isUsable);
		else
			PetJournal.SummonButton:SetText(BATTLE_PET_SUMMON);
			PetJournal.SummonButton:SetEnabled(isUsable);
		end

		PetJournal.TypeInfo:Show();

		PetJournal.TypeInfo.type:SetText(_G["BATTLE_PET_NAME_"..petType]);
		PetJournal.TypeInfo.typeIcon:SetTexture([[Interface\AddOns\ezCollections\Interface\PetBattles\PetIcon-]]..PET_TYPE_SUFFIX[petType]);
		PetJournal.TypeInfo.petID = PetJournal.selectedPetID;
		PetJournal.TypeInfo.speciesID = PetJournal.TypeInfo.petID;
	else
		PetJournal.PetDisplay.InfoButton:Hide();
		PetJournal.PetDisplay.ModelFrame:Hide();
		PetJournal.PetDisplay.YesPetsTex:Hide();
		PetJournal.PetDisplay.NoPetsTex:Show();
		PetJournal.PetDisplay.NoPets:Show();
		PetJournal.SummonButton:SetEnabled(false);

		PetJournal.TypeInfo:Hide();
	end
end

function PetJournal_Select(index)
	local petID = C_PetJournal.GetPetInfoByIndex(index);
	local spellID = petID;
	PetJournal.selectedSpellID = spellID;
	PetJournal.selectedPetID = petID;
	PetJournal_HidePetDropdown();
	PetJournal_UpdatePetList();
	PetJournal_UpdatePetDisplay();
end

function PetJournal_CollectAvailableFilters()
	PetJournal.baseFilterTypes = {};
	local numSources = C_PetJournal.GetNumPetSources();

	for i = 1, numSources do
		PetJournal.baseFilterTypes[i] = false
	end
	for _, petID in ipairs(C_PetJournal.GetPetIDs()) do
		local sourceType = select(6, ezCollections:GetPetInfo(petID));
		PetJournal.baseFilterTypes[sourceType and sourceType + 1 or 12] = true;
	end
end

function PetJournalSummonButton_UsePet(petID)
	if ( C_PetJournal.GetSummonedPetGUID() == petID ) then
		C_PetJournal.DismissPet();
	--[[
	elseif ( C_PetJournal.PetNeedsFanfare(petID) ) then
		if PetJournal.PetDisplay.UnwrapAnim:IsPlaying() then
			return;
		end

		PetJournal.PetDisplay.WrappedModelFrame:SetAnimation(148);
		PetJournal.PetDisplay.UnwrapAnim:Play();
		PlaySound("UI_Store_Unwrap");
		C_Timer.After(.8, function()
			PetJournal.PetDisplay.ModelFrame:ApplySpellVisualKit(73393, true);
		end)
		C_Timer.After(1.6, function()
			C_PetJournal.ClearFanfare(petID);
			PetJournal_HidePetDropdown();
			PetJournal_UpdatePetList();
			PetJournal_UpdatePetDisplay();
		end)
	--]]
	else
		C_PetJournal.ClearFanfare(petID);
		C_PetJournal.SummonPetByGUID(petID);
	end
end

function PetJournalSummonButton_OnClick(self)
	if PetJournal.selectedPetID then
		PetJournalSummonButton_UsePet(PetJournal.selectedPetID);
	end
end

function PetListDragButton_OnClick(self, button)
	local parent = self:GetParent();
	if ( button ~= "LeftButton" ) then
		local _, _, isCollected = C_PetJournal.GetPetInfoByIndex(parent.index);
		if isCollected then
			PetJournal_ShowPetDropdown(parent.index, self, 0, 0);
		end
	elseif ( IsModifiedClick("CHATLINK") ) then
		local id = parent.spellID;
		if ( MacroFrame and MacroFrame:IsShown() ) then
			local spellName = GetSpellInfo(id);
			ChatEdit_InsertLink(spellName);
		else
			local spellLink = GetSpellLink(id)
			ChatEdit_InsertLink(spellLink);
		end
	else
		C_PetJournal.PickupPet(parent.index);
	end
end

function PetListDragButton_OnDoubleClick(self, button)
	ClearCursor();
	local parent = self:GetParent();
	if button == "LeftButton" and ezCollections.Config.Wardrobe.PetsDoubleClickIcon then
		PetJournalSummonButton_UsePet(parent.spellID);
	end
end

function PetListItem_OnClick(self, button)
	if not self.spellID or self.spellID == 0 then
		return;
	end

	if ( button ~= "LeftButton" ) then
		local _, _, isCollected = C_PetJournal.GetPetInfoByIndex(self.index);
		if isCollected then
			PlaySound("igMainMenuOptionCheckBoxOn");
			PetJournal_ShowPetDropdown(self.index, self, 0, 0);
		end
	elseif ( IsModifiedClick("CHATLINK") ) then
		local id = self.spellID;
		if ( MacroFrame and MacroFrame:IsShown() ) then
			local spellName = GetSpellInfo(id);
			ChatEdit_InsertLink(spellName);
		else
			local spellLink = GetSpellLink(id)
			ChatEdit_InsertLink(spellLink);
		end
	elseif ( self.spellID ~= PetJournal.selectedSpellID ) then
		PlaySound("igMainMenuOptionCheckBoxOn");
		PetJournal_Select(self.index);
	end
end

function PetListItem_OnDoubleClick(self, button)
	if button == "LeftButton" and ezCollections.Config.Wardrobe.PetsDoubleClickName then
		PetJournalSummonButton_UsePet(self.spellID);
	end
end

function PetJournal_OnSearchTextChanged(self)
	SearchBoxTemplate_OnTextChanged(self);
	C_PetJournal.SetSearchFilter(self:GetText());
end

function PetJournal_ClearSearch()
	PetJournal.searchBox:SetText("");
end

function PetJournalFilterDropDown_OnLoad(self)
	ezCollections:UIDropDownMenu_Initialize(self, PetJournalFilterDropDown_Initialize, "MENU");
end

function PetJournalFilterDropDown_ResetFilters()
	C_PetJournal.SetDefaultFilters();
	PetJournalFilterButton.ResetButton:Hide();
end

function PetJournalResetFiltersButton_UpdateVisibility()
	PetJournalFilterButton.ResetButton:SetShown(not C_PetJournal.IsUsingDefaultFilters());
end

function PetJournalFilterDropDown_Initialize(self, level)
	local info = UIDropDownMenu_CreateInfo();
	info.keepShownOnClick = true;

	if level == 1 then

		info.text = COLLECTED
		info.func = 	function(_, _, _, value)
							C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_COLLECTED, value);
						end
		info.checked = C_PetJournal.IsFilterChecked(LE_PET_JOURNAL_FILTER_COLLECTED);
		info.isNotRadio = true;
		UIDropDownMenu_AddButton(info, level);

		info.disabled = nil;

		info.text = NOT_COLLECTED;
		info.func = 	function(_, _, _, value)
							C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_NOT_COLLECTED, value);
						end
		info.checked = C_PetJournal.IsFilterChecked(LE_PET_JOURNAL_FILTER_NOT_COLLECTED);
		info.isNotRadio = true;
		UIDropDownMenu_AddButton(info, level);

		if ezCollections:IsActivePetSubscription() then
			info.text = ezCollections.L["Pet.Filter.Subscription"];
			info.func = function(_, _, _, value)
							C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_SUBSCRIPTION, value);
						end
			info.checked = C_PetJournal.IsFilterChecked(LE_PET_JOURNAL_FILTER_SUBSCRIPTION);
			info.isNotRadio = true;
			UIDropDownMenu_AddButton(info, level);
		end

		info.checked = 	nil;
		info.isNotRadio = nil;
		info.func = function(self) _G[self:GetName().."Check"]:Hide(); end;
		info.hasArrow = true;
		info.notCheckable = true;

		info.text = PET_FAMILIES;
		info.value = 1;
		UIDropDownMenu_AddButton(info, level);

		info.text = SOURCES;
		info.value = 2;
		UIDropDownMenu_AddButton(info, level);

		info.text = RAID_FRAME_SORT_LABEL;
		info.value = 3;
		UIDropDownMenu_AddButton(info, level);

	else --if level == 2 then
		if UIDROPDOWNMENU_MENU_VALUE == 1 then
			info.hasArrow = false;
			info.isNotRadio = true;
			info.notCheckable = true;

			info.text = CHECK_ALL;
			info.func = function()
							C_PetJournal.SetAllPetTypesChecked(true);
							UIDropDownMenu_Refresh2(PetJournalFilterDropDown, 1, 2);
						end
			UIDropDownMenu_AddButton(info, level);

			info.text = UNCHECK_ALL;
			info.func = function()
							C_PetJournal.SetAllPetTypesChecked(false);
							UIDropDownMenu_Refresh2(PetJournalFilterDropDown, 1, 2);
						end
			UIDropDownMenu_AddButton(info, level);

			info.notCheckable = false;
			local numTypes = C_PetJournal.GetNumPetTypes();
			for i=1,numTypes do
				info.text = _G["BATTLE_PET_NAME_"..i];
				info.func = function(_, _, _, value)
							C_PetJournal.SetPetTypeFilter(i, value);
						end
				info.checked = function() return C_PetJournal.IsPetTypeChecked(i) end;
				UIDropDownMenu_AddButton(info, level);
			end
		elseif UIDROPDOWNMENU_MENU_VALUE == 2 then
			info.hasArrow = false;
			info.isNotRadio = true;
			info.notCheckable = true;

			info.text = CHECK_ALL;
			info.func = function()
							C_PetJournal.SetAllPetSourcesChecked(true);
							UIDropDownMenu_Refresh2(PetJournalFilterDropDown, 2, 2);
						end
			UIDropDownMenu_AddButton(info, level);

			info.text = UNCHECK_ALL;
			info.func = function()
							C_PetJournal.SetAllPetSourcesChecked(false);
							UIDropDownMenu_Refresh2(PetJournalFilterDropDown, 2, 2);
						end
			UIDropDownMenu_AddButton(info, level);

			info.notCheckable = false;
			PetJournal_CollectAvailableFilters();
			local numSources = C_PetJournal.GetNumPetSources();
			for i=1,numSources do
				if ( PetJournal.baseFilterTypes[i] ) then
					info.text = _G["BATTLE_PET_SOURCE_"..i];
					info.func = function(_, _, _, value)
								C_PetJournal.SetPetSourceChecked(i, value);
							end
					info.checked = function() return C_PetJournal.IsPetSourceChecked(i) end;
					UIDropDownMenu_AddButton(info, level);
				end
			end
		elseif UIDROPDOWNMENU_MENU_VALUE == 3 then
			info.hasArrow = false;
			info.isNotRadio = nil;
			info.notCheckable = nil;
			info.keepShownOnClick = nil;

			info.text = NAME;
			info.func = function()
							C_PetJournal.SetPetSortParameter(LE_SORT_BY_NAME);
							PetJournal_UpdatePetList();
						end
			info.checked = function() return C_PetJournal.GetPetSortParameter() == LE_SORT_BY_NAME end;
			UIDropDownMenu_AddButton(info, level);

			--[[
			info.text = LEVEL;
			info.func = function()
							C_PetJournal.SetPetSortParameter(LE_SORT_BY_LEVEL);
							PetJournal_UpdatePetList();
						end
			info.checked = function() return C_PetJournal.GetPetSortParameter() == LE_SORT_BY_LEVEL end;
			UIDropDownMenu_AddButton(info, level);

			info.text = RARITY;
			info.func = function()
							C_PetJournal.SetPetSortParameter(LE_SORT_BY_RARITY);
							PetJournal_UpdatePetList();
						end
			info.checked = function() return C_PetJournal.GetPetSortParameter() == LE_SORT_BY_RARITY end;
			UIDropDownMenu_AddButton(info, level);
			]]

			info.text = TYPE;
			info.func = function()
							C_PetJournal.SetPetSortParameter(LE_SORT_BY_PETTYPE);
							PetJournal_UpdatePetList();
						end
			info.checked = function() return C_PetJournal.GetPetSortParameter() == LE_SORT_BY_PETTYPE end;
			UIDropDownMenu_AddButton(info, level);
		end
	end
end

function PetJournalSummonRandomFavoritePetButton_OnLoad(self)
	--self.spellID = SUMMON_RANDOM_FAVORITE_PET_SPELL;
	--local spellName, spellSubname, spellIcon = GetSpellInfo(self.spellID);
	--self.texture:SetTexture(spellIcon);
	-- Use the global string instead of the spellName from the db here so that we can have custom newlines in the string
	self.spellname:SetText(PET_JOURNAL_SUMMON_RANDOM_FAVORITE_PET);
	self:RegisterForDrag("LeftButton");

	self:RegisterEvent("UPDATE_MACROS");
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	self:HookScript("OnEvent", function()
		local macro = C_PetJournal.GetFavoriteMacro();
		if macro then
			local _, icon = GetMacroInfo(macro);
			self.texture:SetTexture(icon);
		else
			self.texture:SetTexture([[Interface\Icons\Ability_Hunter_BeastCall]]);
		end
	end);
end

function PetJournalSummonRandomFavoritePetButton_OnClick(self, button)
	if button == "RightButton" then
		local macro = C_PetJournal.GetFavoriteMacro();
		if macro then
			LoadAddOn("Blizzard_MacroUI");
			MacroFrame_Show();
			if macro <= MAX_ACCOUNT_MACROS then
				MacroFrame_SetAccountMacros();
				PanelTemplates_SetTab(MacroFrame, 1);
			else
				MacroFrame_SetCharacterMacros();
				PanelTemplates_SetTab(MacroFrame, 2);
			end
			MacroFrame_SelectMacro(macro);
			MacroFrame_Update();
		end
		return;
	end
	C_PetJournal.SummonRandomPet();
end

function PetJournalSummonRandomFavoritePetButton_OnDragStart(self)
	C_PetJournal.PickupSummonRandomPet();
end

function PetJournalSummonRandomFavoritePetButton_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	--GameTooltip:SetHyperlink("spell:"..self.spellID);
	GameTooltip:SetText(ezCollections.L["Macro.Pet.Name"], HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddLine(ezCollections.L[C_PetJournal.GetFavoriteMacro() and "Macro.Pet.Desc.Created" or "Macro.Pet.Desc"], NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1);
	GameTooltip:Show();
end

function PetOptionsMenu_Init(self, level)
	if not PetJournal.menuPetIndex then
		return;
	end

	local info = UIDropDownMenu_CreateInfo();
	info.notCheckable = true;

	local needsFanfare = C_PetJournal.PetNeedsFanfare(PetJournal.menuPetID);
	local active = PetJournal.menuPetID and C_PetJournal.GetSummonedPetGUID() == PetJournal.menuPetID;

	--[[
	if (needsFanfare) then
		info.text = UNWRAP;
	else]]if ( active ) then
		info.text = PET_DISMISS;
	else
		info.text = BATTLE_PET_SUMMON;
		info.disabled = not PetJournal.menuIsUsable;
	end

	info.func = function()
		--[[
		if needsFanfare then
			PetJournal_Select(PetJournal.menuPetIndex);
		end
		]]
		PetJournalSummonButton_UsePet(PetJournal.menuPetID);
	end;

	UIDropDownMenu_AddButton(info, level);

	if true--[[not needsFanfare]] then
		info.disabled = nil;

		local canFavorite = false;
		local isFavorite = false;
		if (PetJournal.menuPetIndex) then
			 isFavorite, canFavorite = C_PetJournal.PetIsFavorite(PetJournal.menuPetIndex);
		end

		if (isFavorite) then
			info.text = BATTLE_PET_UNFAVORITE;
			info.func = function()
				C_PetJournal.SetFavorite(PetJournal.menuPetIndex, false);
			end
		else
			info.text = BATTLE_PET_FAVORITE;
			info.func = function()
				C_PetJournal.SetFavorite(PetJournal.menuPetIndex, true);
			end
		end

		if (canFavorite) then
			info.disabled = false;
		else
			info.disabled = true;
		end

		UIDropDownMenu_AddButton(info, level);
	end

	info.disabled = nil;
	info.text = CANCEL
	info.func = nil
	UIDropDownMenu_AddButton(info, level)
end

function PetJournal_ShowPetDropdown(index, anchorTo, offsetX, offsetY)
	if (index) then
		PetJournal.menuPetIndex = index;
		PetJournal.menuPetID = C_PetJournal.GetPetInfoByIndex(PetJournal.menuPetIndex);
		PetJournal.active = C_PetJournal.GetSummonedPetGUID() == PetJournal.menuPetID;
		PetJournal.menuIsUsable = C_PetJournal.PetIsUsable(PetJournal.menuPetID);
	else
		return;
	end
	CloseDropDownMenus();
	ToggleDropDownMenu(1, nil, PetJournal.petOptionsMenu, anchorTo, offsetX, offsetY);
end

function PetJournal_HidePetDropdown()
	if (UIDropDownMenu_GetCurrentDropDown() == PetJournal.petOptionsMenu) then
		HideDropDownMenu(1);
	end
end