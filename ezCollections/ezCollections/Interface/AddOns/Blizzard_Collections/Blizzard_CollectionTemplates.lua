function CollectionsSpellButton_OnLoad(self, updateFunction)
	self:RegisterForDrag("LeftButton");
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp");

	self.updateFunction = updateFunction;
end

function CollectionsButton_OnEvent(self, event, ...)
	if GameTooltip:GetOwner() == self then
		self:GetScript("OnEnter")(self);
	end

	self.updateFunction(self);
end

function CollectionsSpellButton_OnShow(self)
	self:RegisterEvent("SPELLS_CHANGED");
	self:RegisterEvent("SPELL_UPDATE_COOLDOWN");
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM");

	self.updateFunction(self);
end

function CollectionsSpellButton_OnHide(self)
	self:UnregisterEvent("SPELLS_CHANGED");
	self:UnregisterEvent("SPELL_UPDATE_COOLDOWN");
	self:UnregisterEvent("UPDATE_SHAPESHIFT_FORM");
end

function CollectionsSpellButton_UpdateCooldown(self)
	if (self.itemID == -1 or self.itemID == nil) then
		return;
	end

	local cooldown = self.cooldown;
	local start, duration, enable = ezCollections:GetItemCooldown(self.itemID);
	if (cooldown and start and duration) then
		if (enable) then
			cooldown:Hide();
		else
			cooldown:Show();
		end
		CooldownFrame_SetTimer(cooldown, start, duration, enable);
	else
		cooldown:Hide();
	end
end

function CollectionsWrappedModelFrame_OnEnter(self)
	self:SetLight(true, false, 0, 0, 0, self.highlightIntensity, 1.0, 1.0, 1.0);
end

function CollectionsWrappedModelFrame_OnLeave(self)
	self:SetLight(true, false, 0, 0, 0, self.normalIntensity, 1.0, 1.0, 1.0);
end

CollectionsPagingMixin = { };

function CollectionsPagingMixin:OnLoad()
	self.currentPage = 1;
	self.maxPages = 1;
	self:Update();
end

function CollectionsPagingMixin:SetMaxPages(maxPages)
	maxPages = math.max(maxPages, 1);
	if ( self.maxPages == maxPages ) then
		return;
	end
	self.maxPages= maxPages;
	if ( self.maxPages < self.currentPage ) then
		self.currentPage = self.maxPages;
	end
	self:Update();
end

function CollectionsPagingMixin:GetMaxPages()
	return self.maxPages;
end

function CollectionsPagingMixin:SetCurrentPage(page, userAction)
	page = Clamp(page, 1, self.maxPages);
	if ( self.currentPage ~= page ) then
		self.currentPage = page;
		self:Update();
		if ( self:GetParent().OnPageChanged ) then
			self:GetParent():OnPageChanged(userAction);
		end
	end
end

function CollectionsPagingMixin:GetCurrentPage()
	return self.currentPage;
end

function CollectionsPagingMixin:NextPage()
	self:SetCurrentPage(self.currentPage + 1, true);
end

function CollectionsPagingMixin:PreviousPage()
	self:SetCurrentPage(self.currentPage - 1, true);
end

function CollectionsPagingMixin:OnMouseWheel(delta)
	if ( delta > 0 ) then
		self:PreviousPage();
	else
		self:NextPage();
	end
end

function CollectionsPagingMixin:Update()
	self.PageText:SetFormattedText(COLLECTION_PAGE_NUMBER, self.currentPage, self.maxPages);
	if ( self.currentPage <= 1 ) then
		self.PrevPageButton:Disable();
	else
		self.PrevPageButton:Enable();
	end
	if ( self.currentPage >= self.maxPages ) then
		self.NextPageButton:Disable();
	else
		self.NextPageButton:Enable();
	end
end