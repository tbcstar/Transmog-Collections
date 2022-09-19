local ADDON_NAME = ...;

local function TransformTransmogLinkToItemLink(link)
	if not link then
		return link;
	elseif strsub(link, 1, 16) == "transmogillusion" then
		local _, sourceID = strsplit(":", link);
		local enchant = ezCollections:GetEnchantFromScroll(tonumber(sourceID) or 0);
		local item = WardrobeCollectionFrame_GetWeaponInfoForEnchant("MAINHANDSLOT");
		if not item or item == 0 then
			item = WardrobeCollectionFrame_GetWeaponInfoForEnchant("SECONDARYHANDSLOT");
			if not item or item == 0 then
				return;
			end
		end
		if enchant then
			return "item:"..item..":"..enchant;
		else
			return "item:"..item;
		end
	elseif strsub(link, 1, 18) == "transmogappearance" then
		local _, sourceID = strsplit(":", link);
		return select(6, C_TransmogCollection.GetAppearanceSourceInfo(sourceID));
	end
	return link;
end

function DressUpItemLink(link)
	link = TransformTransmogLinkToItemLink(link);
	if ( not link or not IsDressableItem(link) ) then
		return false;
	end
	return DressUpVisual(link);
end
ezCollectionsDressUpItemLink = DressUpItemLink;

function DressUpTransmogLink(link)
	if ( not link or not (strsub(link, 1, 16) == "transmogillusion" or strsub(link, 1, 18) == "transmogappearance") ) then
		return false;
	end

	link = TransformTransmogLinkToItemLink(link);
	return DressUpVisual(link);
end

function DressUpVisual(...)
	if SideDressUpFrame and ( SideDressUpFrame.parentFrame and SideDressUpFrame.parentFrame:IsShown() ) then
		if ( not SideDressUpFrame:IsShown() or SideDressUpFrame.mode ~= "player" ) then
			SideDressUpFrame.mode = "player";
			SideDressUpFrame.ResetButton:Show();

			local race, fileName = UnitRace("player");
			SetDressUpBackground(SideDressUpFrame, fileName);

			ShowUIPanel(SideDressUpFrame);
			SideDressUpModel:SetUnit("player");
		end
		SideDressUpModel:TryOn(...);
	else
		DressUpFrame_Show();
		DressUpModel:TryOn(...);
	end
	return true;
end

if ADDON_NAME ~= "ezCollectionsDressUp" then
	function DressUpFrame_Show()
		if ( not DressUpFrame:IsShown() or DressUpFrame.mode ~= "player") then
			DressUpFrame.mode = "player";

			local race, fileName = UnitRace("player");
			SetDressUpBackground(DressUpFrame, fileName);

			ShowUIPanel(DressUpFrame);
			DressUpModel:SetUnit("player");
		end
	end

	return;
end

SideDressUpFrame = nil;
SideDressUpFrameTop = nil;
SideDressUpFrameBackgroundTop = nil;
SideDressUpFrameBackgroundBot = nil;
SideDressUpModel = nil;
SideDressUpModelResetButton = nil;
SideDressUpModelCloseButton = nil;
DressUpFrame = nil;
DressUpFramePortrait = nil;
DressUpFrameTitleText = nil;
DressUpFrameDescriptionText = nil;
DressUpBackgroundTopLeft = nil;
DressUpBackgroundTopRight = nil;
DressUpBackgroundBotLeft = nil;
DressUpBackgroundBotRight = nil;
DressUpFrameCloseButton = nil;
DressUpFrameCancelButton = nil;
DressUpFrameResetButton = nil;
DressUpModel = nil;
function ezCollectionsAuctionOnShowHook(self)
	SetUpSideDressUpFrame(self, 840, 1020, "TOPLEFT", "TOPRIGHT", -2, -28);
end
function ezCollectionsAuctionOnHideHook(self)
	CloseSideDressUpFrame(self);
end

--[[
function DressUpBattlePet(creatureID, displayID)
	if ( not displayID and not creatureID ) then
		return false;
	end

	--Figure out which frame we're going to use
	local frame, model;
	if ( SideDressUpFrame.parentFrame and SideDressUpFrame.parentFrame:IsShown() ) then
		frame, model = SideDressUpFrame, SideDressUpModel;
	else
		frame, model = DressUpFrame, DressUpModel;
	end

	--Show the frame
	if ( not frame:IsShown() or frame.mode ~= "battlepet" ) then
		SetDressUpBackground(frame, "Pet");
		ShowUIPanel(frame);
	end

	--Set up the model on the frame
	frame.mode = "battlepet";
	frame.ResetButton:Hide();
	if ( displayID and displayID ~= 0 ) then
		model:SetDisplayInfo(displayID);
	else
		model:SetCreature(creatureID);
	end
	return true;
end
]]


function DressUpTexturePath(raceFileName)
	-- HACK
	if ( not raceFileName ) then
		raceFileName = "Orc";
	end
	-- END HACK

	return "Interface\\DressUpFrame\\DressUpBackground-"..raceFileName;
end

function SetDressUpBackground(frame, fileName, atlasPostfix)
	if not frame then
		frame = DressUpFrame;
	end
	if not fileName and not atlasPostfix then
		fileName = select(2, UnitRace("player"));
	end

	local texture = DressUpTexturePath(fileName);
	
	if ( frame.BGTopLeft ) then
		frame.BGTopLeft:SetTexture(texture..1);
	end
	if ( frame.BGTopRight ) then
		frame.BGTopRight:SetTexture(texture..2);
	end
	if ( frame.BGBottomLeft ) then
		frame.BGBottomLeft:SetTexture(texture..3);
	end
	if ( frame.BGBottomRight ) then
		frame.BGBottomRight:SetTexture(texture..4);
	end
	
	if ( frame.ModelBackground and atlasPostfix ) then
		frame.ModelBackground:SetAtlas("dressingroom-background-"..atlasPostfix);
		if frame.ModelBackground then frame.ModelBackground:Show(); end
		if frame.BGTopLeft then frame.BGTopLeft:Hide(); end
		if frame.BGTopRight then frame.BGTopRight:Hide(); end
		if frame.BGBottomLeft then frame.BGBottomLeft:Hide(); end
		if frame.BGBottomRight then frame.BGBottomRight:Hide(); end
	else
		if frame.ModelBackground then frame.ModelBackground:Hide(); end
		if frame.BGTopLeft then frame.BGTopLeft:Show(); end
		if frame.BGTopRight then frame.BGTopRight:Show(); end
		if frame.BGBottomLeft then frame.BGBottomLeft:Show(); end
		if frame.BGBottomRight then frame.BGBottomRight:Show(); end
	end
end

function DressUpModel_OnLoad(self)
	Model_OnLoad(self, MODELFRAME_MAX_PLAYER_ZOOM);
	self.defaultPosX = GetUICameraInfo(ezCollections:GetCharacterCameraID("SetsDetails"));
	self.defaultZoom = self.defaultPosX / self.portraitZoomMultiplier;
	self.minZoom = self.defaultZoom - 0.5;

	self.oSetUnit = self.SetUnit;
	function self:SetUnit(unit, ...)
		self.unit = unit;

		local x, y, z = self:GetPosition();
		self:SetPosition(0, 0, 0);
		self:oSetUnit(unit, ...);
		self:SetPosition(x, y, z);
	end

	self.oSetCreature = self.SetCreature;
	function self:SetCreature(creature, ...)
		self.unit = creature;

		local x, y, z = self:GetPosition();
		self:SetPosition(0, 0, 0);
		self:oSetCreature(creature, ...);
		self:SetPosition(x, y, z);
	end

	self.oDress = self.Dress;
	function self:Dress(...)
		local x, y, z = self:GetPosition();
		self:SetPosition(0, 0, 0);
		self:oDress(...);
		self:SetPosition(x, y, z);
	end
end

function DressUpFrame_Show()
	if ( not DressUpFrame:IsShown() or DressUpFrame.mode ~= "player") then
		DressUpFrame.mode = "player";
		DressUpFrame.ResetButton:Show();

		if ezCollections.Config.Wardrobe.DressUpClassBackground then
			local className, classFileName = UnitClass("player");
			SetDressUpBackground(DressUpFrame, nil, classFileName);
		else
			local race, fileName = UnitRace("player");
			SetDressUpBackground(DressUpFrame, fileName);
		end

		ShowUIPanel(DressUpFrame);
		DressUpModel:SetUnit("player");
		DressUpModel.defaultPosX = GetUICameraInfo(ezCollections:GetCharacterCameraID("SetsDetails"));
		DressUpModel.defaultZoom = DressUpModel.defaultPosX / DressUpModel.portraitZoomMultiplier;
		DressUpModel.minZoom = DressUpModel.defaultZoom - 0.5;
		Model_Reset(DressUpModel);
	end
end

function SideDressUpFrame_OnShow(self)
	self.parentFrame:SetAttribute("UIPanelLayout-width", self.openWidth);
	UpdateUIPanelPositions(self.parentFrame);
	PlaySound("igCharacterInfoOpen");
end

function SideDressUpFrame_OnHide(self)
	self.parentFrame:SetAttribute("UIPanelLayout-width", self.closedWidth);
	UpdateUIPanelPositions();
	PlaySound("igCharacterInfoClose");
end

function SetUpSideDressUpFrame(parentFrame, closedWidth, openWidth, point, relativePoint, offsetX, offsetY)
	local self = SideDressUpFrame;
	if ( self.parentFrame ) then
		if ( self.parentFrame == parentFrame ) then
			return;
		end
		if ( self:IsShown() ) then
			HideUIPanel(self);
		end
	end	
	self.parentFrame = parentFrame;
	self.closedWidth = closedWidth;
	self.openWidth = openWidth;	
	relativePoint = relativePoint or point;
	self:SetParent(parentFrame);
	self:SetPoint(point, parentFrame, relativePoint, offsetX, offsetY);
end

function CloseSideDressUpFrame(parentFrame)
	if ( SideDressUpFrame.parentFrame and SideDressUpFrame.parentFrame == parentFrame ) then
		HideUIPanel(SideDressUpFrame);
	end
end