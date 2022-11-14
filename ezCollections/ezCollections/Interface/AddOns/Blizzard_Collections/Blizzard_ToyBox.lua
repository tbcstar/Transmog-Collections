local TOYS_PER_PAGE = 18;

function ToyBox_OnLoad(self)
	Mixin(self, SetShownMixin);
	Mixin(self.SubscriptionStatus, SetShownMixin);
	self.firstCollectedToyID = 0; -- used to track which toy gets the favorite helpbox
	self.mostRecentCollectedToyID = UIParent.mostRecentCollectedToyID or nil;
	self.newToys = UIParent.newToys or {};

	ToyBox_UpdatePages();
	ToyBox_UpdateProgressBar(self);

	ezCollections:UIDropDownMenu_Initialize(self.toyOptionsMenu, ToyBoxOptionsMenu_Init, "MENU");

	ezCollections:RegisterEvent(self, "TOYS_UPDATED");

	self.OnPageChanged = function(userAction)
		PlaySound("igAbiliityPageTurn");
		CloseDropDownMenus();
		ToyBox_UpdateButtons();
	end
end

function ToyBox_OnEvent(self, event, itemID, new)
	if ( event == "TOYS_UPDATED" ) then
		if (new) then
			self.mostRecentCollectedToyID = itemID;
			if ( not CollectionsJournal:IsShown() ) then
				CollectionsJournal_SetTab(CollectionsJournal, 3);
			end
			self.newToys[itemID] = true;
		end

		C_ToyBox.RefreshToys();
		ToyBox_UpdatePages();
		ToyBox_UpdateProgressBar(self);
		ToyBox_UpdateButtons();

		if (new) then
			self.newToys[itemID] = true;
		end
	end
end

function ToyBox_OnShow(self)
	ezCollections:SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_TOYBOX, true);

	if(C_ToyBox.HasFavorites()) then 
		ezCollections:SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_TOYBOX_FAVORITE, true);
		self.favoriteHelpBox:Hide();
	end

	SetPortraitToTexture(CollectionsJournalPortrait, [[Interface\AddOns\ezCollections\Interface\Icons\Trade_Archaeology_ChestofTinyGlassAnimals]]);
	C_ToyBox.ForceToyRefilter();

	C_ToyBox.RefreshToys();
	ToyBox_UpdatePages();	
	ToyBox_UpdateProgressBar(self);
	ToyBox_UpdateButtons();
	ToyBoxResetFiltersButton_UpdateVisibility();
end

function ToyBox_FindPageForToyID(toyID)
	for i = 1, C_ToyBox.GetNumFilteredToys() do
		if C_ToyBox.GetToyFromIndex(i) == toyID then
			return math.floor((i - 1) / TOYS_PER_PAGE) + 1;
		end
	end

	return nil;
end

function ToyBox_OnMouseWheel(self, value)
	ezCollections:SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_TOYBOX_MOUSEWHEEL_PAGING, true);
	self.mousewheelPagingHelpBox:Hide();
	ToyBox.PagingFrame:OnMouseWheel(value);
end

function ToyBoxOptionsMenu_Init(self, level)
	local info = UIDropDownMenu_CreateInfo();
	info.notCheckable = true;
	info.disabled = nil;

	local isFavorite = ToyBox.menuItemID and C_ToyBox.GetIsFavorite(ToyBox.menuItemID);

	if (isFavorite) then
		info.text = BATTLE_PET_UNFAVORITE;
		info.func = function() 
			C_ToyBox.SetIsFavorite(ToyBox.menuItemID, false);
		end
	else
		info.text = BATTLE_PET_FAVORITE;
		info.func = function() 
			C_ToyBox.SetIsFavorite(ToyBox.menuItemID, true);
			ezCollections:SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_TOYBOX_FAVORITE, true);
			ToyBox.favoriteHelpBox:Hide();
		end
	end

	UIDropDownMenu_AddButton(info, level);
	info.disabled = nil;
	
	info.text = CANCEL;
	info.func = nil;
	UIDropDownMenu_AddButton(info, level);

	if ezCollections.Developer then
		local toyID = ezCollections:GetToyIDByItem(ToyBox.menuItemID) or 0;

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
		info.text = ezCollections:HasToy(toyID) and "Lock" or "Unlock";
		info.notCheckable = true;
		info.func = function() ezCollections:SendAddonMessage(format("DEV:%sLOCKTOY:%d", ezCollections:HasToy(toyID) and "" or "UN", toyID)); end;
		UIDropDownMenu_AddButton(info);

		info = UIDropDownMenu_CreateInfo();
		info.text = "Add Item";
		info.notCheckable = true;
		info.func = function() ezCollections:SendAddonCommand(format(".additem %d", ToyBox.menuItemID)); end;
		UIDropDownMenu_AddButton(info);

		info = UIDropDownMenu_CreateInfo();
		info.text = "Delete Item";
		info.notCheckable = true;
		info.func = function() ezCollections:SendAddonCommand(format(".additem %d -1", ToyBox.menuItemID)); end;
		UIDropDownMenu_AddButton(info);

		info = UIDropDownMenu_CreateInfo();
		info.text = "Clear Cooldown";
		info.notCheckable = true;
		info.func = function() table.wipe(ezCollections.ItemCooldowns); SendChatMessage(".cooldown", "SAY"); end;
		UIDropDownMenu_AddButton(info);
	end
end

function ToyBox_ShowToyDropdown(itemID, anchorTo, offsetX, offsetY)	
	ToyBox.menuItemID = itemID;
	CloseDropDownMenus();
	ToggleDropDownMenu(1, nil, ToyBox.toyOptionsMenu, anchorTo, offsetX, offsetY);
	PlaySound("igMainMenuOptionCheckBoxOn");
end

function ToyBox_HideToyDropdown()
	if (UIDropDownMenu_GetCurrentDropDown() == ToyBox.toyOptionsMenu) then
		HideDropDownMenu(1);
	end
end

function ToySpellButton_OnShow(self)
	ezCollections:RegisterEvent(self, "TOYS_UPDATED");

	CollectionsSpellButton_OnShow(self);
end

function ToySpellButton_OnHide(self)
	CollectionsSpellButton_OnHide(self);

	ezCollections:UnregisterEvent(self, "TOYS_UPDATED");	
end

function ToySpellButton_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	if ( GameTooltip:SetToyByItemID(self.itemID) ) then
		self.UpdateTooltip = ToySpellButton_OnEnter;
	else
		self.UpdateTooltip = nil;
	end

	if(ToyBox.newToys[self.itemID] ~= nil) then
		ToyBox.newToys[self.itemID] = nil;
		ToySpellButton_UpdateButton(self);
	end
end

function ToySpellButton_OnClick(self, button)
	if ( button ~= "LeftButton" ) then
		if (PlayerHasToy(self.itemID)) or ezCollections.Developer then
			ToyBox_ShowToyDropdown(self.itemID, self, 0, 0);
		end
	else
		if GetCursorInfo() then
			return;
		end
		UseToy(self.itemID);
	end
end

function ToySpellButton_OnModifiedClick(self, button) 
	if ( IsModifiedClick("CHATLINK") ) then
		local itemLink = C_ToyBox.GetToyLink(self.itemID);
		if ( itemLink ) then
			ChatEdit_InsertLink(itemLink);
		end
	end
end

function ToySpellButton_OnDrag(self) 	
	C_ToyBox.PickupToyBoxItem(self.itemID);
end

function ToySpellButton_UpdateButton(self)
	local itemIndex = (ToyBox.PagingFrame:GetCurrentPage() - 1) * TOYS_PER_PAGE + self:GetID();
	self.itemID = C_ToyBox.GetToyFromIndex(itemIndex);

	local toyString = self.name;
	local toyNewString = self.new;
	local toyNewGlow = self.newGlow;
	local iconTexture = self.iconTexture;
	local iconTextureUncollected = self.iconTextureUncollected;
	local slotFrameCollected = self.slotFrameCollected;
	local slotFrameUncollected = self.slotFrameUncollected;
	local slotFrameUncollectedInnerGlow = self.slotFrameUncollectedInnerGlow;
	local iconFavoriteTexture = self.cooldownWrapper.slotFavorite; 

	if (self.itemID == -1) then	
		self:Hide();		
		return;
	end

	self:Show();

	local itemID, toyName, icon = C_ToyBox.GetToyInfo(self.itemID);

	if (itemID == nil or toyName == nil) then
		return;
	end

	if string.len(toyName) == 0 then
		toyName = itemID;
	end

	iconTexture:SetTexture(icon);
	iconTextureUncollected:SetTexture(icon);
	iconTextureUncollected:SetDesaturated(true);
	toyString:SetText(toyName);	
	toyString:Show();

	if (ToyBox.newToys[self.itemID] ~= nil) then
		toyNewString:Show();
		toyNewGlow:Show();
	else
		toyNewString:Hide();
		toyNewGlow:Hide();
	end

	if (C_ToyBox.GetIsFavorite(itemID)) then
		iconFavoriteTexture:Show();
	else
		iconFavoriteTexture:Hide();
	end

	if (PlayerHasToy(self.itemID)) then
		iconTexture:Show();
		iconTextureUncollected:Hide();
		toyString:SetTextColor(1, 0.82, 0, 1);
		toyString:SetShadowColor(0, 0, 0, 1);
		slotFrameCollected:Show();
		slotFrameUncollected:Hide();
		slotFrameUncollectedInnerGlow:Hide();

		if(ToyBox.firstCollectedToyID == 0) then
			ToyBox.firstCollectedToyID = self.itemID;
		end

		if (ToyBox.firstCollectedToyID == self.itemID and not ToyBox.favoriteHelpBox:IsVisible() and not ezCollections:GetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_TOYBOX_FAVORITE)) then
			ToyBox.favoriteHelpBox:Show();
			ToyBox.favoriteHelpBox:SetPoint("TOPLEFT", self, "BOTTOMLEFT", -5, -20);
		end

		local toyID = ezCollections:GetToyIDByItem(self.itemID) or 0;
		self.SubscriptionOverlay:SetShown(not ezCollections:HasToy(toyID) and ezCollections:IsActiveToySubscriptionToy(toyID));
	else
		iconTexture:Hide();
		iconTextureUncollected:Show();
		toyString:SetTextColor(0.33, 0.27, 0.20, 1);
		toyString:SetShadowColor(0, 0, 0, 0.33);
		slotFrameCollected:Hide();
		slotFrameUncollected:Show();		
		slotFrameUncollectedInnerGlow:Show();
		self.SubscriptionOverlay:Hide();
	end

	CollectionsSpellButton_UpdateCooldown(self);

	self.active:SetShown(ezCollections.ActiveToys[self.itemID]);
end

function ToyBox_UpdateButtons()
	ToyBox.favoriteHelpBox:Hide();
	for i = 1, TOYS_PER_PAGE do
	    local button = ToyBox.iconsFrame["spellButton"..i];
		ToySpellButton_UpdateButton(button);
	end	

	ToyBox.SubscriptionStatus.SubscriptionInfo:SetShown(ezCollections:IsActiveToySubscription());
	ToyBox.SubscriptionStatus:SetShown(ToyBox.SubscriptionStatus.SubscriptionInfo:IsShown());
end

function ToyBox_UpdatePages()
	local maxPages = 1 + math.floor( math.max((C_ToyBox.GetNumFilteredToys() - 1), 0) / TOYS_PER_PAGE);
	ToyBox.PagingFrame:SetMaxPages(maxPages)
	if ToyBox.mostRecentCollectedToyID then
		local toyPage = ToyBox_FindPageForToyID(ToyBox.mostRecentCollectedToyID);
		if toyPage then
			ToyBox.PagingFrame:SetCurrentPage(toyPage);
		end
		ToyBox.mostRecentCollectedToyID = nil;
	end
end

function ToyBox_UpdateProgressBar(self)
	local maxProgress = C_ToyBox.GetNumTotalDisplayedToys();
	local currentProgress = C_ToyBox.GetNumLearnedDisplayedToys();

	self.progressBar:SetMinMaxValues(0, maxProgress);
	self.progressBar:SetValue(currentProgress);

	self.progressBar.text:SetFormattedText(TOY_PROGRESS_FORMAT, currentProgress, maxProgress);
end

function ToyBox_OnSearchTextChanged(self)
	SearchBoxTemplate_OnTextChanged(self);
	local oldText = ToyBox.searchString;
	ToyBox.searchString = self:GetText();

	if ( oldText ~= ToyBox.searchString ) then		
		ToyBox.firstCollectedToyID = 0;
		C_ToyBox.SetFilterString(ToyBox.searchString);
		C_ToyBox.RefreshToys();
		ToyBox_UpdatePages();
		ToyBox_UpdateButtons();
	end
end

function ToyBox_CollectAvailableFilters()
	ToyBox.baseFilterTypes = { };
	for i = 1, C_PetJournal.GetNumPetSources() do
		ToyBox.baseFilterTypes[i] = false;
	end
	for _, itemID in ipairs(C_ToyBox.GetToys()) do
		local sourceType = select(4, ezCollections:GetToyInfoByItem(itemID));
		ToyBox.baseFilterTypes[sourceType and sourceType + 1 or 12] = true;
	end
end

function ToyBoxFilterDropDown_OnLoad(self)
	ezCollections:UIDropDownMenu_Initialize(self, ToyBoxFilterDropDown_Initialize, "MENU");
end

function ToyBoxUpdateFilteredInformation()
	ToyBox.firstCollectedToyID = 0;
	C_ToyBox.RefreshToys();
	ToyBox_UpdatePages();
	ToyBox_UpdateButtons();
	ToyBoxResetFiltersButton_UpdateVisibility();
end

function ToyBoxFilterDropDown_ResetFilters()
	C_ToyBox.SetDefaultFilters();
	ToyBoxFilterButton.ResetButton:Hide();
	ToyBoxUpdateFilteredInformation();
end

function ToyBoxResetFiltersButton_UpdateVisibility()
	ToyBoxFilterButton.ResetButton:SetShown(not C_ToyBox.IsUsingDefaultFilters());
end

function ToyBoxFilterDropDown_Initialize(self, level)
	local info = UIDropDownMenu_CreateInfo();
	info.keepShownOnClick = true;	

	if level == 1 then
		info.text = COLLECTED;
		info.func = function(_, _, _, value)
						C_ToyBox.SetCollectedShown(value);
						ToyBoxUpdateFilteredInformation(); 
					end 
		info.checked = C_ToyBox.GetCollectedShown();
		info.isNotRadio = true;
		UIDropDownMenu_AddButton(info, level);

		info.text = NOT_COLLECTED;
		info.func = function(_, _, _, value)
						C_ToyBox.SetUncollectedShown(value);
						ToyBoxUpdateFilteredInformation(); 
					end 
		info.checked = C_ToyBox.GetUncollectedShown();
		info.isNotRadio = true;
		UIDropDownMenu_AddButton(info, level);

		if ezCollections:IsActiveToySubscription() then
			info.text = ezCollections.L["Toy.Filter.Subscription"];
			info.func = function(_, _, _, value)
							C_ToyBox.SetSubscriptionShown(value);
							ToyBoxUpdateFilteredInformation();
						end
			info.checked = C_ToyBox.GetSubscriptionShown();
			info.isNotRadio = true;
			UIDropDownMenu_AddButton(info, level);
		end
		
		info.text = PET_JOURNAL_FILTER_USABLE_ONLY;
		info.func = function(_, _, _, value)
						C_ToyBox.SetUnusableShown(not value);
						ToyBoxUpdateFilteredInformation(); 
					end
		info.checked = not C_ToyBox.GetUnusableShown();
		info.isNotRadio = true;
		UIDropDownMenu_AddButton(info, level);
		
		info.checked = nil;
		info.isNotRadio = nil;
		info.func = function(self) _G[self:GetName().."Check"]:Hide(); end;
		info.hasArrow = true;
		info.notCheckable = true;
		
		info.text = SOURCES;
		info.value = 1;
		UIDropDownMenu_AddButton(info, level);
		
		info.text = EXPANSION_FILTER_TEXT;
		info.value = 2;
		UIDropDownMenu_AddButton(info, level);
	else
		if UIDROPDOWNMENU_MENU_VALUE == 1 then
			info.hasArrow = false;
			info.isNotRadio = true;
			info.notCheckable = true;				
		
			info.text = CHECK_ALL;
			info.func = function()
							C_ToyBox.SetAllSourceTypeFilters(true);
							UIDropDownMenu_Refresh2(ToyBoxFilterDropDown, 1, 2);
							ToyBoxUpdateFilteredInformation();
						end
			UIDropDownMenu_AddButton(info, level);
			
			info.text = UNCHECK_ALL;
			info.func = function()
							C_ToyBox.SetAllSourceTypeFilters(false);
							UIDropDownMenu_Refresh2(ToyBoxFilterDropDown, 1, 2);
							ToyBoxUpdateFilteredInformation();
						end
			UIDropDownMenu_AddButton(info, level);
		
			info.notCheckable = false;
			ToyBox_CollectAvailableFilters();
			local numSources = C_PetJournal.GetNumPetSources();
			for i=1,numSources do
				if ToyBox.baseFilterTypes[i] then
					info.text = _G["BATTLE_PET_SOURCE_"..i];
					info.func = function(_, _, _, value)
								C_ToyBox.SetSourceTypeFilter(i, value);
								ToyBoxUpdateFilteredInformation();
							end
					info.checked = function() return not C_ToyBox.IsSourceTypeFilterChecked(i) end;
					UIDropDownMenu_AddButton(info, level);
				end
			end
		end
		if UIDROPDOWNMENU_MENU_VALUE == 2 then
			info.hasArrow = false;
			info.isNotRadio = true;
			info.notCheckable = true;				
		
			info.text = CHECK_ALL;
			info.func = function()
							C_ToyBox.SetAllExpansionTypeFilters(true);
							UIDropDownMenu_Refresh2(ToyBoxFilterDropDown, 1, 2);
							ToyBoxUpdateFilteredInformation();
						end
			UIDropDownMenu_AddButton(info, level);
			
			info.text = UNCHECK_ALL;
			info.func = function()
							C_ToyBox.SetAllExpansionTypeFilters(false);
							UIDropDownMenu_Refresh2(ToyBoxFilterDropDown, 1, 2);
							ToyBoxUpdateFilteredInformation();
						end
			UIDropDownMenu_AddButton(info, level);
	
			info.notCheckable = false;
			local numExpansions = GetNumExpansions();
			for i=1,numExpansions do
				info.text = _G["EXPANSION_NAME"..i-1]; --Since the global strings for expansion are 0 - Max Expansion
				info.func = function(_, _, _, value)
							C_ToyBox.SetExpansionTypeFilter(i, value);
							ToyBoxUpdateFilteredInformation();
						end
				info.checked = function() return not C_ToyBox.IsExpansionTypeFilterChecked(i) end;
				UIDropDownMenu_AddButton(info, level);
			end
		end
	end
end
