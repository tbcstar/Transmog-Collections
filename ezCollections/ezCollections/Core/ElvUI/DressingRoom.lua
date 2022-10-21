ezCollections:MergeHook("ezCollectionsElvUIHook", function()

local E, L, V, P, G = unpack(ElvUI);
local S = E:GetModule("Skins");

local function SetToggleIcon(button, texture)
	local icon = button:CreateTexture()
	icon:SetTexCoord(unpack(E.TexCoords))
	icon:SetInside()
	icon:SetTexture(texture)

	button:StyleButton()
end

local function SetItemQuality(slot)
	if --[[not slot.slotState and]] not slot.isHiddenVisual and slot.transmogID then
		slot.backdrop:SetBackdropBorderColor(slot.Name:GetTextColor())
	else
		slot.backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
	end
end

local function DetailsPanelRefresh(panel)
	if not panel.slotPool then return end

	for slot in panel.slotPool:EnumerateActive() do
		if not slot.backdrop then
			slot:CreateBackdrop()
			slot.backdrop:SetOutside(slot.Icon)
			slot.IconBorder:SetAlpha(0)
			S:HandleIcon(slot.Icon)
			slot.Icon:SetParent(slot);
		end

		SetItemQuality(slot)
	end
end

local function DressUpConfigureSize(frame, isMinimized)
	frame.OutfitDetailsPanel:ClearAllPoints()
	frame.OutfitDetailsPanel:Point('TOPLEFT', frame, 'TOPRIGHT', 4-7+1, 20)

	frame.OutfitDropDown:ClearAllPoints()
	frame.OutfitDropDown:Point('TOP', -(isMinimized and 42 or 28), -32)
	frame.OutfitDropDown:Width(isMinimized and 140 or 190)
end

-- Override old callback to patch DressUpFrame in the entirely new way
E:RegisterCallback("Skin_DressingRoom", function()
	if not (E.private.skins.blizzard.enable and E.private.skins.blizzard.dressingroom) then return end

	local DressUpFrame = _G.DressUpFrame
	S:HandlePortraitFrame_ezCollections(DressUpFrame, true)
	S:HandleMaxMinFrame_ezCollections(DressUpFrame.MaximizeMinimizeFrame)
	S:HandleButton(_G.DressUpFrameResetButton)
	S:HandleButton(_G.DressUpFrameCancelButton)
	S:HandleButton(DressUpFrame.LinkButton)
	S:HandleButton(DressUpFrame.ToggleOutfitDetailsButton)
	SetToggleIcon(DressUpFrame.ToggleOutfitDetailsButton, [[Interface\AddOns\ezCollections\Interface\Icons\70_Professions_Scroll_01]])

	DressUpFrame.ModelBackground:SetDrawLayer('BACKGROUND', 1)
	DressUpFrame.LinkButton:Size(110, 22)
	DressUpFrame.LinkButton:ClearAllPoints()
	DressUpFrame.LinkButton:Point('BOTTOMLEFT', 4, 4)

	_G.DressUpFrameCancelButton:Point('BOTTOMRIGHT', -4, 4)
	_G.DressUpFrameResetButton:Point('RIGHT', _G.DressUpFrameCancelButton, 'LEFT', -3, 0)

	local OutfitDropDown = DressUpFrame.OutfitDropDown
	S:HandleDropDownBox(OutfitDropDown)
	S:HandleButton(OutfitDropDown.SaveButton)
	OutfitDropDown:Height(23)
	OutfitDropDown.SaveButton:Size(80, 22)
	OutfitDropDown.SaveButton:Point('LEFT', OutfitDropDown, 'RIGHT', -7, 4)
	OutfitDropDown.Text:ClearAllPoints()
	OutfitDropDown.Text:Point('LEFT', OutfitDropDown.backdrop, 4, 0)
	OutfitDropDown.Text:Point('RIGHT', OutfitDropDown.backdrop, -4, 0)
	OutfitDropDown.backdrop:Point('TOPLEFT', 3, 3)

	-- 9.1.5 Outfit DetailPanel | Dont use StripTextures on the DetailsPanel, plx
	DressUpFrame.OutfitDetailsPanel:DisableDrawLayer('BACKGROUND')
	DressUpFrame.OutfitDetailsPanel:DisableDrawLayer('OVERLAY') -- to keep Artwork on the frame
	DressUpFrame.OutfitDetailsPanel:CreateBackdrop('Transparent')
	DressUpFrame.OutfitDetailsPanel.backdrop:Point("TOPLEFT", 7-2, -20+2);
	DressUpFrame.OutfitDetailsPanel.backdrop:Point("BOTTOMRIGHT", -7+2, 8-2);
	--DressUpFrame.OutfitDetailsPanel.ClassBackground:SetAllPoints()
	hooksecurefunc(DressUpFrame.OutfitDetailsPanel, 'Refresh', DetailsPanelRefresh)
	hooksecurefunc(DressUpFrame, 'ConfigureSize', DressUpConfigureSize)

	local WardrobeOutfitFrame = _G.WardrobeOutfitFrame
	WardrobeOutfitFrame:StripTextures_ezCollections(true)
	WardrobeOutfitFrame:SetTemplate('Transparent')

	S:HandleCheckBox(DressUpFrame.OutfitDetailsPanel.DisplayMeleeButton);
	S:HandleCheckBox(DressUpFrame.OutfitDetailsPanel.DisplayRangedButton);
	S:HandleCheckBox(DressUpFrame.OutfitDetailsPanel.DisplayMainHandButton);
	S:HandleCheckBox(DressUpFrame.OutfitDetailsPanel.DisplayOffHandButton);

	SideDressUpFrame:StripTextures_ezCollections();
	SideDressUpFrame:CreateBackdrop("Default");
	SideDressUpFrame.backdrop:SetOutside(SideDressUpFrame.BGTopLeft, nil, nil, SideDressUpFrame.BGBottomLeft);
	S:HandleButton(SideDressUpFrame.ResetButton);
	S:HandleCloseButton(SideDressUpModelCloseButton, SideDressUpFrame.backdrop);
end);

local TT = E:GetModule("Tooltip", true);
if TT then
	local old = TT.SetHyperlink;
	function TT:SetHyperlink(refTooltip, link)
		if self.db.spellID and link:find("^item:") then
			local id = tonumber(link:match("(%d+)"));
			if id ~= 0 then
				old(TT, refTooltip, link);
			end
		end
	end
end

-- Patch fonts
SystemFont_Shadow_Small2:SetFont(E["media"].normFont, E.db.general.fontSize);
SystemFont_Shadow_Med2:SetFont(E["media"].normFont, E.db.general.fontSize);

end);
ezCollections:MergeHook("ezCollectionsElvUIEnhancedHook", function()

local E, L, V, P, G = unpack(ElvUI);
local S = E:GetModule("Skins");

-- Patch out ElvUI_Enhanced's DressUp enhancements, we already support them all
local mod = E:GetModule("Enhanced_Blizzard", true);
if mod then
	function mod:UpdateDressUpFrame()
	end
	function mod:SelectOutfit()
	end
	function mod:DressUpFrame()
	end
end

-- Patch Undress button for AuctionUI
local UB = E:GetModule("Enhanced_UndressButtons", true);
if UB then
	local old = UB.CreateUndressButton;
	function UB:CreateUndressButton(auction)
		old(UB, auction);
		if auction then
			self.auctionDressUpButton:SetParent(SideDressUpFrame);
			self.auctionDressUpButton:SetFrameLevel(SideDressUpFrame.ResetButton:GetFrameLevel() + 1);
			self.auctionDressUpButton.model = SideDressUpModel;

			if not (E.private.skins.blizzard.enable and E.private.skins.blizzard.dressingroom) then
				self.auctionDressUpButton:Point("BOTTOM", SideDressUpFrame.ResetButton, "BOTTOM", 0, -25);
			else
				S:HandleButton(self.auctionDressUpButton);
				self.auctionDressUpButton:Point("RIGHT", SideDressUpFrame.ResetButton, "LEFT", -3, 0);
				SideDressUpFrame.ResetButton:Point("BOTTOM", SideDressUpFrame.ResetButton:GetParent(), "BOTTOM", 41, 3);
			end
		end
	end
end

-- Patch Model frame improvements to skip DressUpModel (already supports them) and instead only skin control buttons. SideDressUpModel is already skipped since it's not the default AuctionDressUpModel
local MF = E:GetModule("Enhanced_ModelFrames", true) or E:GetModule("HookModelFrames", true);
if MF then
	function MF:ModelWithControls_ezCollections(model)
		local parent = model.controlFrame:GetName();
		local zoomInButton = _G[parent.."ZoomInButton"];
		local zoomOutButton = _G[parent.."ZoomOutButton"];
		local panButton = _G[parent.."PanButton"];
		local rotateLeftButton = _G[parent.."RotateLeftButton"];
		local rotateRightButton = _G[parent.."RotateRightButton"];
		local rotateResetButton = _G[parent.."RotateResetButton"];
		if E.private.skins.blizzard.enable then
			model.controlFrame:SetSize(123, 23)
			model.controlFrame:StripTextures();
			for _, button in ipairs({ zoomInButton, zoomOutButton, panButton, rotateLeftButton, rotateRightButton, rotateResetButton }) do
				button.bg:SetTexture(nil);
				button.highlight:SetTexture(nil);
			end

			S:HandleButton(zoomInButton)

			S:HandleButton(zoomOutButton)
			zoomOutButton:SetPoint("LEFT", "$parentZoomInButton", "RIGHT", 2, 0)

			S:HandleButton(panButton)
			panButton:SetPoint("LEFT", "$parentZoomOutButton", "RIGHT", 2, 0)

			S:HandleButton(rotateLeftButton)
			rotateLeftButton:SetPoint("LEFT", "$parentPanButton", "RIGHT", 2, 0)

			S:HandleButton(rotateRightButton)
			rotateRightButton:SetPoint("LEFT", "$parentRotateLeftButton", "RIGHT", 2, 0)

			S:HandleButton(rotateResetButton)
			rotateResetButton:SetPoint("LEFT", "$parentRotateRightButton", "RIGHT", 2, 0)
		else
			model.controlFrame:SetSize(112, 23)
			zoomInButton:SetPoint("LEFT", "$parent", "LEFT", 2, 0)
			zoomOutButton:SetPoint("LEFT", "$parentZoomInButton", "RIGHT", 0, 0)
			panButton:SetPoint("LEFT", "$parentZoomOutButton", "RIGHT", 0, 0)
			rotateLeftButton:SetPoint("LEFT", "$parentPanButton", "RIGHT", 0, 0)
			rotateRightButton:SetPoint("LEFT", "$parentRotateLeftButton", "RIGHT", 0, 0)
			rotateResetButton:SetPoint("LEFT", "$parentRotateRightButton", "RIGHT", 0, 0)
		end
	end

	local old = MF.ModelWithControls;
	function MF:ModelWithControls(model)
		if model == DressUpModel then
			MF:ModelWithControls_ezCollections(model);
		else
			old(self, model);
		end
	end

	hooksecurefunc(MF, "Initialize", function()
		if E.private.enhanced.character.modelFrames then
			MF:ModelWithControls_ezCollections(SideDressUpModel);
		end
	end);
end

local EE = E:GetModule("ElvUI_Enhanced", true);
if EE then
	hooksecurefunc(EE, "GetOptions", function()
		E.Options.args.enhanced.args.blizzardGroup.args.dressingRoom.args.multiplier.disabled = true;
	end);
end

end);
