--------------------------------------------------
-- DRESS UP MODEL FRAME LINK BUTTON MIXIN
DressUpModelFrameLinkButtonMixin = {};

local function LinkOutfitDropDownInit()
	local info = UIDropDownMenu_CreateInfo();
	info.notCheckable = true;

	info.text = TRANSMOG_OUTFIT_POST_IN_CHAT;
	info.func = function()
		local sources, mainHandEnchant, offHandEnchant = DressUpModel:GetSources();
		local hyperlink = C_TransmogCollection.GetOutfitHyperlinkFromItemTransmogInfoList(sources, mainHandEnchant, offHandEnchant);
		if not ChatEdit_InsertLink(hyperlink) then
			ChatFrame_OpenChat(hyperlink);
		end
	end;
	UIDropDownMenu_AddButton(info);

	info.text = TRANSMOG_OUTFIT_COPY_TO_CLIPBOARD;
	info.func = function()
		local sources, mainHandEnchant, offHandEnchant = DressUpModel:GetSources();
		local slashCommand = TransmogUtil.CreateOutfitSlashCommand(sources, mainHandEnchant, offHandEnchant);
		StaticPopup_Show("EZCOLLECTIONS_COPY_OUTFIT_COMMAND", nil, nil, slashCommand);
		--CopyToClipboard(slashCommand);
		--DEFAULT_CHAT_FRAME:AddMessage(TRANSMOG_OUTFIT_COPY_TO_CLIPBOARD_NOTICE, YELLOW_FONT_COLOR.r, YELLOW_FONT_COLOR.g, YELLOW_FONT_COLOR.b);
	end;
	UIDropDownMenu_AddButton(info);
end

function DressUpModelFrameLinkButtonMixin:OnLoad()
	ezCollections:UIDropDownMenu_Initialize(self.DropDown, LinkOutfitDropDownInit, "MENU");
end

function DressUpModelFrameLinkButtonMixin:OnClick()
	ToggleDropDownMenu(1, nil, self.DropDown, self, self:GetRight() - self:GetLeft() - (159 - 136), 73);
	PlaySound("igMainMenuOptionCheckBoxOn");
end

--------------------------------------------------
-- DRESS UP MODEL FRAME MAX MIN MIXIN
DressUpModelFrameMaximizeMinimizeMixin = {};

function DressUpModelFrameMaximizeMinimizeMixin:OnLoad()
	local function OnMaximize(frame)
		local isMinimized = false;
		frame:GetParent():ConfigureSize(isMinimized);
	end

	self:SetOnMaximizedCallback(OnMaximize);

	local function OnMinimize(frame)
		local isMinimized = true;
		frame:GetParent():ConfigureSize(isMinimized);
	end

	self:SetOnMinimizedCallback(OnMinimize);

	self:SetMinimizedCVar("miniDressUpFrame");
end

--------------------------------------------------
-- BASE MODEL FRAME FRAME MIXIN
DressUpModelFrameBaseMixin = { };

function DressUpModelFrameBaseMixin:SetMode(mode)
	self.mode = mode;
	if self.hasOutfitControls then
		local inPlayerMode = mode == "player";
		self.ResetButton:SetShown(inPlayerMode);
		self.LinkButton:SetShown(inPlayerMode);
		self.ToggleOutfitDetailsButton:SetShown(inPlayerMode);
		self.OutfitDropDown:SetShown(inPlayerMode);
		if not inPlayerMode then
			self:SetShownOutfitDetailsPanel(false);
		else
			self:SetShownOutfitDetailsPanel(ezCollections:GetCVarBool("showOutfitDetails"));
		end
	end
end

function DressUpModelFrameBaseMixin:GetMode()
	return self.mode;
end

--------------------------------------------------
-- DEFAULT MODEL FRAME FRAME MIXIN
DressUpModelFrameMixin = CreateFromMixins(DressUpModelFrameBaseMixin);

function DressUpModelFrameMixin:OnLoad()
	self.TitleText:SetText(DRESSUP_FRAME);
end

function DressUpModelFrameMixin:OnShow()
	SetPortraitTexture(DressUpFramePortrait, "player");
	PlaySound("igCharacterInfoOpen");
end

function DressUpModelFrameMixin:OnHide()
	PlaySound("igCharacterInfoClose");
	if self.forcedMaximized then
		self.forcedMaximized = nil;
		local minimized = GetCVarBool("miniDressUpFrame");
		if minimized then
			local isAutomaticAction = true;
			self.MaximizeMinimizeFrame:Minimize(isAutomaticAction);
		end
	end
end

function DressUpModelFrameMixin:OnDressModel()
	if self.OutfitDropDown then
		if not self.gotDressed then
			self.gotDressed = true;
			C_Timer.After(0, function()
				self.gotDressed = nil;
				self.OutfitDropDown:UpdateSaveButton();
				self.OutfitDetailsPanel:OnAppearanceChange();
			end);
		end
	end
end

function DressUpModelFrameMixin:ToggleOutfitDetails()
	local show = not self.OutfitDetailsPanel:IsShown();
	self:SetShownOutfitDetailsPanel(show);
	ezCollections:SetCVar("showOutfitDetails", show);
end

function DressUpModelFrameMixin:ConfigureSize(isMinimized)
	if isMinimized then
		self:SetSize(334, 423);
		self.BGTopLeft:SetSize(256, 256);
		self.BGTopRight:SetSize(62, 256);
		self.BGBotLeft:SetSize(256, 128);
		self.BGBotRight:SetSize(62, 128);
		self:SetAttribute("UIPanelLayout-width", self:GetWidth() + (self.extraWidth or 0));
		self.OutfitDetailsPanel:SetPoint("TOPLEFT", self, "TOPRIGHT", -4, -1);
		self.OutfitDropDown:SetPoint("TOP", -42, -28);
		UIDropDownMenu_SetWidth(self.OutfitDropDown, 120);
		UpdateUIPanelPositions(self);
	else
		self:SetSize(450, 545);
		self.BGTopLeft:SetSize(350, 350);
		self.BGTopRight:SetSize(84, 350);
		self.BGBotLeft:SetSize(350, 175);
		self.BGBotRight:SetSize(84, 175);
		self:SetAttribute("UIPanelLayout-width", self:GetWidth() + (self.extraWidth or 0));
		self.OutfitDetailsPanel:SetPoint("TOPLEFT", self, "TOPRIGHT", -9, -29);
		self.OutfitDropDown:SetPoint("TOP", -23, -28);
		UIDropDownMenu_SetWidth(self.OutfitDropDown, 163);
		UpdateUIPanelPositions(self);
	end
	UpdateUIPanelPositions(self);
end

function DressUpModelFrameMixin:SetShownOutfitDetailsPanel(show)
	self.OutfitDetailsPanel:SetShown(show);
	local outfitDetailsPanelWidth = 297; -- Original 307 prevents opening Transmogrify and maximized DressUpFrame at 1080p
	self.extraWidth = show and outfitDetailsPanelWidth or 0;
    self:SetAttribute("UIPanelLayout-width", self:GetWidth() + (self.extraWidth or 0));
	UpdateUIPanelPositions(self);
end

function DressUpModelFrameMixin:ForceOutfitDetailsOn()
	self.forcedMaximized = true;
	local isAutomaticAction = true;
	self.MaximizeMinimizeFrame:Maximize(isAutomaticAction);
	self:SetShownOutfitDetailsPanel(true);
end
