StaticPopupDialogs["NAME_TRANSMOG_OUTFIT"] = {
	text = TRANSMOG_OUTFIT_NAME,
	button1 = SAVE,
	button2 = CANCEL,
	OnAccept = function(self)
		WardrobeOutfitFrame:NameOutfit(self.editBox:GetText(), self.data);
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	hasEditBox = 1,
	maxLetters = 31,
	OnShow = function(self)
		self.button1:Disable();
		self.button2:Enable();
		self.editBox:SetFocus();
	end,
	OnHide = function(self)
		self.editBox:SetText("");
	end,
	EditBoxOnEnterPressed = function(self)
		if ( self:GetParent().button1:IsEnabled() == 1 ) then
			StaticPopup_OnClick(self:GetParent(), 1);
		end
	end,
	EditBoxOnTextChanged = function (self)
		local parent = self:GetParent();
		if ( parent.editBox:GetText() ~= "" ) then
			parent.button1:Enable();
		else
			parent.button1:Disable();
		end
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
};

StaticPopupDialogs["CONFIRM_OVERWRITE_TRANSMOG_OUTFIT"] = {
	text = TRANSMOG_OUTFIT_CONFIRM_OVERWRITE,
	button1 = YES,
	button2 = NO,
	OnAccept = function (self) WardrobeOutfitFrame:SaveOutfit(self.data) end,
	OnCancel = function (self)
		local name = self.data;
		self:Hide();
		local dialog = StaticPopup_Show("NAME_TRANSMOG_OUTFIT");
		if ( dialog ) then
			self.editBox:SetText(name);
		end
	end,
	hideOnEscape = 1,
	timeout = 0,
	whileDead = 1,
	noCancelOnEscape = 1,
}

StaticPopupDialogs["CONFIRM_DELETE_TRANSMOG_OUTFIT"] = {
	text = TRANSMOG_OUTFIT_CONFIRM_DELETE,
	button1 = YES,
	button2 = NO,
	OnAccept = function (self) WardrobeOutfitFrame:DeleteOutfit(self.data); end,
	OnCancel = function (self) end,
	hideOnEscape = 1,
	timeout = 0,
	whileDead = 1,
}

StaticPopupDialogs["TRANSMOG_OUTFIT_CHECKING_APPEARANCES"] = {
	text = TRANSMOG_OUTFIT_CHECKING_APPEARANCES,
	button1 = CANCEL,
	hideOnEscape = 1,
	timeout = 0,
	whileDead = 1,
}

StaticPopupDialogs["TRANSMOG_OUTFIT_ALL_INVALID_APPEARANCES"] = {
	text = TRANSMOG_OUTFIT_ALL_INVALID_APPEARANCES,
	button1 = OKAY,
	hideOnEscape = 1,
	timeout = 0,
	whileDead = 1,
}

StaticPopupDialogs["TRANSMOG_OUTFIT_SOME_INVALID_APPEARANCES"] = {
	text = TRANSMOG_OUTFIT_SOME_INVALID_APPEARANCES,
	button1 = OKAY,
	button2 = CANCEL,
	OnShow = function(self)
		if ( WardrobeOutfitFrame.name ) then
			self.button1:SetText(SAVE);
		else
			self.button1:SetText(CONTINUE);
		end
	end,
	OnAccept = function(self)
		WardrobeOutfitFrame:ContinueWithSave();
	end,
	hideOnEscape = 1,
	timeout = 0,
	whileDead = 1,
}

StaticPopupDialogs["TRANSMOG_APPLY_WARNING"] = {
	text = "%s",
	button1 = OKAY,
	button2 = CANCEL,
	OnAccept = function(self)
		return WardrobeTransmogFrame_ApplyPending(self.data.warningIndex);
	end,
	OnHide = function()
		WardrobeTransmogFrame_UpdateApplyButton();
	end,
	timeout = 0,
	hideOnEscape = 1,
	hasItemFrame = 1,
}

function StaticPopupInserted_Show(popup, text_arg1, text_arg2, data, insertedFrame)
	local dialog = StaticPopup_Show(popup, text_arg1, text_arg2, data);
	dialog.insertedFrame = insertedFrame;
	if ( insertedFrame ) then
		local text = _G[dialog:GetName().."Text"];
		insertedFrame:SetParent(dialog);
		insertedFrame:ClearAllPoints();
		insertedFrame:SetPoint("TOP", text, "BOTTOM");
		insertedFrame:Show();
		_G[dialog:GetName().."MoneyFrame"]:SetPoint("TOP", insertedFrame, "BOTTOM");
		_G[dialog:GetName().."MoneyInputFrame"]:SetPoint("TOP", insertedFrame, "BOTTOM");

		dialog.oldOnHide = dialog.OnHide;
		function dialog:OnHide(data)
			if self.oldOnHide then
				self.OnHide = self.oldOnHide;
				self:OnHide(data);
			end
			if ( self.insertedFrame ) then
				self.insertedFrame:Hide();
				self.insertedFrame:SetParent(nil);
				local text = _G[self:GetName().."Text"];
				_G[self:GetName().."MoneyFrame"]:SetPoint("TOP", text, "BOTTOM", 0, -5);
				_G[self:GetName().."MoneyInputFrame"]:SetPoint("TOP", text, "BOTTOM", 0, -5);
			end
		end
	end
	return dialog;
end
