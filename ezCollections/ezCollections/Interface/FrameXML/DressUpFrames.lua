local ADDON_NAME = ...;
local dressUpAddonEnabled;

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
	else
		local itemID = link:match("item:(%d+)");
		itemID = itemID and tonumber(itemID);
		if itemID and ezCollections:GetEnchantFromScroll(itemID) then
			return TransformTransmogLinkToItemLink("transmogillusion:"..itemID);
		end
		local dressable = itemID and ezCollections:GetDressableFromRecipe(itemID);
		if dressable then
			return TransformTransmogLinkToItemLink("item:"..dressable);
		end
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

local forceDressUpFrame = false;
local function ShouldAcceptDressUp(frame, parent)
	if forceDressUpFrame then
		return;
	end

	local parentFrame = frame and frame.parentFrame or parent;
	if parentFrame == nil then
		return;
	end

	if parentFrame.ShouldAcceptDressUp then
		return parentFrame:ShouldAcceptDressUp();
	end

	return parentFrame:IsShown();
end

local function GetFrameAndSetBackground(raceFilename, classFilename)
	local frame, model;
	if SideDressUpFrame and ShouldAcceptDressUp(SideDressUpFrame) then
		frame = SideDressUpFrame;
		model = SideDressUpModel;
		if not raceFilename then
			raceFilename = select(2, UnitRace("player"));
		end

		SetDressUpBackground(frame, raceFilename);
	elseif AuctionDressUpFrame and ShouldAcceptDressUp(AuctionDressUpFrame, AuctionFrame) then
		frame = AuctionDressUpFrame;
		model = AuctionDressUpModel;
	else
		frame = DressUpFrame;
		model = DressUpModel;
		if not classFilename then
			classFilename = select(2, UnitClass("player"));
		end

		if dressUpAddonEnabled and ezCollections.Config.Wardrobe.DressUpClassBackground then
			SetDressUpBackground(frame, nil, classFilename);
		else
			SetDressUpBackground(frame, raceFilename or select(2, UnitRace("player")));
		end
	end

	return frame, model;
end

local function GetDressUpFrameAndSetBackground()
	forceDressUpFrame = true;
	local frame, model = GetFrameAndSetBackground();
	forceDressUpFrame = false;
	return frame, model;
end

function DressUpVisual(...)
	local frame, model = GetFrameAndSetBackground();
	DressUpFrame_Show(frame, model);

	model:TryOn(...);
	return true;
end

if ADDON_NAME ~= "ezCollectionsDressUp" then
	function DressUpFrame_Show(frame, model)
		frame = frame or DressUpFrame;
		model = model or DressUpModel;
		if ( not frame:IsShown() ) then
			ShowUIPanel(frame);
			model:SetUnit("player");
		end
	end

	return;
end
dressUpAddonEnabled = true;

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
--DressUpFrameDescriptionText = nil;
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

function DressUpTexturePath(raceFileName)
	-- HACK
	local race, fileName = UnitRace("player");
	if ( strupper(fileName) == "GNOME" ) then
		if ezCollections.Config.Wardrobe.DressUpGnomeTrollBackground then
			return [[Interface\AddOns\ezCollections\Interface\DressUpFrame\DressUpBackground-Gnome]];
		end
		raceFileName = "Dwarf";
	elseif ( strupper(fileName) == "TROLL" ) then
		if ezCollections.Config.Wardrobe.DressUpGnomeTrollBackground then
			return [[Interface\AddOns\ezCollections\Interface\DressUpFrame\DressUpBackground-Troll]];
		end
		raceFileName = "Orc";
	end
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

	if dressUpAddonEnabled then
		if frame.ModelBackground then frame.ModelBackground:SetDesaturated(ezCollections.Config.Wardrobe.DressUpDesaturateBackground); end
		if frame.BGTopLeft then frame.BGTopLeft:SetDesaturated(ezCollections.Config.Wardrobe.DressUpDesaturateBackground); end
		if frame.BGTopRight then frame.BGTopRight:SetDesaturated(ezCollections.Config.Wardrobe.DressUpDesaturateBackground); end
		if frame.BGBottomLeft then frame.BGBottomLeft:SetDesaturated(ezCollections.Config.Wardrobe.DressUpDesaturateBackground); end
		if frame.BGBottomRight then frame.BGBottomRight:SetDesaturated(ezCollections.Config.Wardrobe.DressUpDesaturateBackground); end
	end
end

local function SetupDressUpModel(model)
	local x, y, z = GetUICameraInfo(ezCollections:GetCharacterCameraID("DressUp"));
	if not x then
		x, y = GetUICameraInfo(ezCollections:GetCharacterCameraID("SetsDetails"));
		z = 0;
	end
	model.defaultPosX = x or 0;
	model.defaultPosY = y or 0;
	model.defaultPosZ = z or 0;
	model.defaultZoom = model.defaultPosX / model.portraitZoomMultiplier;
	model.minZoom = model.defaultZoom - 0.5;
end

function DressUpModel_OnLoad(self)
	Model_OnLoad(self, MODELFRAME_MAX_PLAYER_ZOOM);
	SetupDressUpModel(self);
	self.sources = nil;
	self.mainHandEnchant = nil;
	self.offHandEnchant = nil;
	self.nextWeaponSlot = 16;
	self.displayedWeapon = 1;
	self.conflictingWeapons = false;

	function self:InitSources()
		self.sources, self.mainHandEnchant, self.offHandEnchant = WardrobeOutfitDropDown:GetOutfitSourcesFromBaseEquipment();
		self.conflictingWeapons = ezCollections:AreWeaponsImpossibleToDisplayInPlayerModel(self.sources[16], self.sources[17]);
		if self.conflictingWeapons then
			self.displayedWeapon = 3;
		elseif self.sources[16] or self.sources[17] then
			self.displayedWeapon = 1;
		elseif self.sources[18] then
			self.displayedWeapon = 2;
		else
			self.displayedWeapon = 0;
		end
	end
	function self:GetSources()
		if not self.sources then
			self:InitSources();
		end
		return self.sources, self.mainHandEnchant, self.offHandEnchant;
	end

	self.oSetUnit = self.SetUnit;
	function self:SetUnit(unit, ...)
		self.unit = unit;
		local mode = UnitIsUnit(unit, "player") and "player" or "unit";
		if self:GetParent():GetMode() ~= mode then
			self:GetParent():SetMode(mode);
		end
		if self:GetParent().DualWieldResetter then
			self:GetParent().DualWieldResetter:SetUnit(unit, ...);
		end

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

		self.nextWeaponSlot = 16;
		self:InitSources();
		self:RefreshDressFromSources();
	end

	self.oUndress = self.Undress;
	function self:Undress(...)
		table.wipe(self.sources);
		self.mainHandEnchant = nil;
		self.offHandEnchant = nil;
		self.displayedWeapon = 1;
		self.conflictingWeapons = false;
		self:RefreshDressFromSources();
	end

	function self:UndressSlot(slot, illusion)
		local sources = self:GetSources();
		if slot == 16 then
			self.mainHandEnchant = nil;
		elseif slot == 17 then
			self.offHandEnchant = nil;
		end
		if not illusion then
			sources[slot] = nil;
			if slot == 16 or slot == 17 then
				self.nextWeaponSlot = sources[16] and 17 or 16;
			end
			self.conflictingWeapons = ezCollections:AreWeaponsImpossibleToDisplayInPlayerModel(sources[16], sources[17]);
			if self.displayedWeapon == 1 and self.conflictingWeapons then
				self.displayedWeapon = 3;
			elseif (self.displayedWeapon == 3 or self.displayedWeapon == 4) and not self.conflictingWeapons then
				self.displayedWeapon = (sources[16] or sources[17]) and 1 or sources[18] and 2 or 0;
			elseif self.displayedWeapon == 1 and not sources[16] and not sources[17] and sources[18] then
				self.displayedWeapon = 2;
			elseif self.displayedWeapon == 2 and not sources[18] and (sources[16] or sources[17]) then
				self.displayedWeapon = self.conflictingWeapons and 3 or 1;
			end
		end
		self:RefreshDressFromSources();
	end

	function self:GetSlotTransmogSources(slot)
		local sources, mainHandEnchant, offHandEnchant = self:GetSources();
		if slot == 16 then
			return sources[slot], mainHandEnchant;
		elseif slot == 17 then
			return sources[slot], offHandEnchant;
		else
			return sources[slot];
		end
	end

	self.oTryOn = self.TryOn;
	function self:TryOn(input, slot)
		local id, enchant;
		if type(input) == "number" then
			id = input;
		elseif type(input) == "string" then
			local _;
			id, enchant = input:match("item:(%d+):(%d+)");
			if not id then
				id = input:match("item:(%d+)");
			end
			id = id and tonumber(id) or nil;
			enchant = enchant and tonumber(enchant) or nil;
		end
		if slot and type(slot) == "string" then
			slot = GetInventorySlotInfo(slot);
		end

		local isLocalPlayerModel = true;
		if id then
			local sources = self:GetSources();
			local invType = ezCollections:GetInvType(id);
			if invType or C_TransmogCollection.IsAppearanceHiddenVisual(id) and slot then
				if slot then
					sources[slot] = id;
				elseif invType == 13 or invType == 14 or invType == 15 or invType == 17 or invType == 21 or invType == 22 or invType == 23 or invType == 25 or invType == 26 then
					-- INVTYPE_WEAPON
					if invType == 13 then
						local mainHandInvType = sources[16] and ezCollections:GetInvType(sources[16]);
						--if not sources[16] or mainHandInvType ~= 13 and mainHandInvType ~= 21 and mainHandInvType ~= 17 or not isLocalPlayerModel or not ezCollections:PlayerCanDualWield() then
						if sources[16] and (mainHandInvType == 13 or mainHandInvType == 21 or mainHandInvType == 17) and isLocalPlayerModel and ezCollections:PlayerCanDualWield() then
							slot = self.nextWeaponSlot;
							self.nextWeaponSlot = (self.nextWeaponSlot == 16 and 1 or 0) + 16;
						else
							slot = 16;
						end
					end
					-- INVTYPE_2HWEAPON, INVTYPE_WEAPONMAINHAND
					if invType == 17 or invType == 21 then
						if ezCollections:CanEquipItemIntoSlot(id, 17) then
							slot = self.nextWeaponSlot;
							self.nextWeaponSlot = (self.nextWeaponSlot == 16 and 1 or 0) + 16;
						else
							slot = 16;
							self.nextWeaponSlot = 16;
						end
					end
					-- INVTYPE_RANGEDRIGHT, INVTYPE_THROWN
					if invType == 26 or invType == 25 then
						slot = 16;
						self.nextWeaponSlot = 16;
					end
					-- INVTYPE_SHIELD, INVTYPE_RANGED, INVTYPE_HOLDABLE, INVTYPE_WEAPONOFFHAND
					if invType == 14 or invType == 15 or invType == 23 or invType == 22 then
						slot = 17;
						self.nextWeaponSlot = 16;
					end
					-- Blizzard code above deals with visual slots, but we want ranged weapons to go into ranged equipment slot
					-- INVTYPE_RANGED, INVTYPE_THROWN, INVTYPE_RANGEDRIGHT
					if invType == 15 or invType == 25 or invType == 26 then
						slot = 18;
						self.nextWeaponSlot = 16;
					end

					sources[slot] = id;
					if slot == 16 or slot == 17 then
						local otherSlot = slot == 16 and 17 or 16;
						if sources[otherSlot] then
							if ezCollections:AreWeaponsImpossibleToDisplayInPlayerModel(sources[16], sources[17]) then
								sources[otherSlot] = nil;
								if otherSlot == 16 then
									self.mainHandEnchant = nil;
								else
									self.offHandEnchant = nil;
								end
							end
						end
					end
				else
					slot = C_Transmog.GetSlotForInventoryType(invType + 1);
					if slot then
						sources[slot] = id;
					end
				end
				self.conflictingWeapons = ezCollections:AreWeaponsImpossibleToDisplayInPlayerModel(sources[16], sources[17]);
				if sources[slot] then
					if slot == 16 then
						self.mainHandEnchant = enchant == ezCollections:GetHiddenEnchant() and ezCollections:GetHiddenVisualItem() or enchant and ezCollections:GetScrollFromEnchant(enchant);
						self.displayedWeapon = self.conflictingWeapons and 3 or 1;
					elseif slot == 17 then
						self.offHandEnchant = enchant == ezCollections:GetHiddenEnchant() and ezCollections:GetHiddenVisualItem() or enchant and ezCollections:GetScrollFromEnchant(enchant);
						self.displayedWeapon = self.conflictingWeapons and 4 or 1;
					elseif slot == 18 then
						self.displayedWeapon = 2;
					end
				end
				if self.conflictingWeapons and self.displayedWeapon == 1 then
					self.displayedWeapon = 3;
				elseif not self.conflictingWeapons and (self.displayedWeapon == 3 or self.displayedWeapon == 4) then
					self.displayedWeapon = 1;
				end
			end
		end

		self:RefreshDressFromSources();
	end

	function self:RefreshDressFromSources()
		local sources, mainHandEnchant, offHandEnchant = self:GetSources();
		sources = CopyTable(sources);
		mainHandEnchant = mainHandEnchant and ezCollections:GetEnchantFromScroll(mainHandEnchant);
		offHandEnchant = offHandEnchant and ezCollections:GetEnchantFromScroll(offHandEnchant);

		self:oUndress();
		if self:GetParent().DualWieldResetter then
			self:GetParent().DualWieldResetter:Dress();
		end

		for slot = EQUIPPED_FIRST, EQUIPPED_LAST do
			local id = sources[slot];
			if id and slot ~= 16 and slot ~= 17 and slot ~= 18 and not C_TransmogCollection.IsAppearanceHiddenVisual(id) then
				self:oTryOn(id);
			end
		end

		local function EquipWeapon(slot)
			local id = sources[slot];
			if id and not C_TransmogCollection.IsAppearanceHiddenVisual(id) then
				local invType = ezCollections:GetInvType(id);
				if invType == 13 or invType == 14 or invType == 15 or invType == 17 or invType == 21 or invType == 22 or invType == 23 or invType == 25 or invType == 26 then
					if slot == 16 and mainHandEnchant then
						self:oTryOn(format("item:%d:%d", id, mainHandEnchant));
					elseif slot == 17 and offHandEnchant then
						self:oTryOn(format("item:%d:%d", id, offHandEnchant));
					elseif slot == 16 or slot == 17 or slot == 18 then
						self:oTryOn(id);
					end
				end
			end
		end

		if self.displayedWeapon == 1 then
			local mh = sources[16];
			local oh = sources[17];
			if ezCollections:AreWeaponsImpossibleToDisplayInPlayerModel(mh, oh) then
				self.displayedWeapon = 3;
			else
				local mhInvType = mh and ezCollections:GetInvType(mh);
				local ohInvType = oh and ezCollections:GetInvType(oh);
				if (mhInvType == 17 or mhInvType == 21) and not ezCollections:CanEquipItemIntoSlot(mh, 17) then
					if ohInvType == 13 then
						-- Workaround a bug with mainhand weapon overwriting offhand
						EquipWeapon(17);
					end
					-- Workaround a bug with fist weapons in mainhand being overwritten by 2H offhand when with Titan's Grip
					EquipWeapon(17);
					EquipWeapon(17);
					EquipWeapon(16);
				else
					if mhInvType == 13 and oh then
						-- Workaround a bug with first weapon after undress not alternating weapon slot
						EquipWeapon(16);
					end
					EquipWeapon(16);
					EquipWeapon(17);
				end
			end
		end
		if self.displayedWeapon == 2 then
			EquipWeapon(18);
		elseif self.displayedWeapon == 3 then
			EquipWeapon(16);
		elseif self.displayedWeapon == 4 then
			EquipWeapon(17);
		end

		if self:GetParent().OutfitDetailsPanel then
			self:GetParent().OutfitDetailsPanel:OnAppearanceChange();
		end
	end
end

local function UIPanelNotShown(frame)
	return frame ~= GetUIPanel("left") and frame ~= GetUIPanel("center") and frame ~= GetUIPanel("right");
end

function DressUpFrame_Show(frame, model)
	if not frame or not model then
		frame, model = GetDressUpFrameAndSetBackground();
	end

	if ( not frame:IsShown() or frame:GetMode() ~= "player") then
		frame:SetMode("player");

		-- Restore user settings from cvar
		if frame.MaximizeMinimizeFrame then
			frame.MaximizeMinimizeFrame:OnShow();
		end
		-- Attempt to minimize the panel as much as possible
		ShowUIPanel(frame);
		if frame == DressUpFrame and UIPanelWindows["DressUpFrame"] and UIPanelNotShown(frame) then
			HideUIPanel(frame);
			if frame.MaximizeMinimizeFrame --[[and not frame.MaximizeMinimizeFrame:IsMinimized()]] then
				local isAutomaticAction = true;
				frame.MaximizeMinimizeFrame:Minimize(isAutomaticAction);
				ShowUIPanel(frame);
				if UIPanelNotShown(frame) then
					HideUIPanel(frame);
					if frame.hasOutfitControls then
						frame:SetShownOutfitDetailsPanel(false);
						frame.MaximizeMinimizeFrame:Minimize(isAutomaticAction); -- isAutomaticAction is only retained for one opening, so set it again
						ShowUIPanel(frame);
						if UIPanelNotShown(frame) then
							HideUIPanel(frame);
						end
					end
				end
			end
		end

		model:SetUnit("player");
		SetupDressUpModel(model);
		Model_Reset(model);
		if not ezCollections.Config.Wardrobe.DressUpSkipDressOnShow then
			model:Dress();
		end
	end
end

function DressUpSources(appearanceSources, mainHandEnchant, offHandEnchant)
	if ( not appearanceSources ) then
		return true;
	end

	local frame, self = GetDressUpFrameAndSetBackground();
	DressUpFrame_Show(frame, self);

	self.sources = CopyTable(appearanceSources);
	self.mainHandEnchant = mainHandEnchant;
	self.offHandEnchant = offHandEnchant;
	self.conflictingWeapons = ezCollections:AreWeaponsImpossibleToDisplayInPlayerModel(self.sources[16], self.sources[17]);
	if self.conflictingWeapons then
		self.displayedWeapon = 3;
	elseif self.sources[16] or self.sources[17] then
		self.displayedWeapon = 1;
	elseif self.sources[18] then
		self.displayedWeapon = 2;
	else
		self.displayedWeapon = 0;
	end

	self:RefreshDressFromSources();
end

DressUpOutfitMixin = { };

function DressUpOutfitMixin:GetSlotSourceID(slot, transmogType)
	local slotID = GetInventorySlotInfo(slot);
	local appearanceSourceID, illusionSourceID = DressUpModel:GetSlotTransmogSources(slotID);
	if ( transmogType == LE_TRANSMOG_TYPE_APPEARANCE ) then
		return appearanceSourceID;
	elseif ( transmogType == LE_TRANSMOG_TYPE_ILLUSION ) then
		return illusionSourceID;
	end
end

function DressUpOutfitMixin:LoadOutfit(outfitID)
	if ( not outfitID ) then
		return;
	end
	DressUpSources(C_TransmogCollection.GetOutfitSources(outfitID))
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

DressUpOutfitDetailsPanelMixin = { };

local CLASS_BACKGROUND_SETTINGS = {
	["DEFAULT"] = { desaturation = 0.5, alpha = 0.25 },
	["DEATHKNIGHT"] = { desaturation = 0.5, alpha = 0.30 },
	["DEMONHUNTER"] = { desaturation = 0.5, alpha = 0.30 },
	["HUNTER"] = { desaturation = 0.5, alpha = 0.45 },
	["MAGE"] = { desaturation = 0.5, alpha = 0.45 },
	["PALADIN"] = { desaturation = 0.5, alpha = 0.21 },
	["ROGUE"] = { desaturation = 0.5, alpha = 0.65 },
	["SHAMAN"] = { desaturation = 0.5, alpha = 0.40 },
	["WARLOCK"] = { desaturation = 0.5, alpha = 0.40 },
}

function DressUpOutfitDetailsPanelMixin:OnLoad()
	Mixin(self.ClassBackground, SetAtlasMixin);
	self.slotPool = CreateFramePool("FRAME", self, "DressUpOutfitSlotFrameTemplate");
	self.slotPool.name = self:GetName().."Pool";
	local classFilename = select(2, UnitClass("player"));
	self.ClassBackground:SetAtlas("dressingroom-background-"..classFilename);
	local settings = CLASS_BACKGROUND_SETTINGS[classFilename] or CLASS_BACKGROUND_SETTINGS["DEFAULT"];
	self.ClassBackground:SetDesaturated(settings.desaturation > 0);
	self.ClassBackground:SetAlpha(settings.alpha);
	local frameLevel = self:GetParent()--[[.NineSlice]]:GetFrameLevel();
	self:SetFrameLevel(frameLevel + 1);
end

function DressUpOutfitDetailsPanelMixin:OnShow()
	ezCollections:RegisterEvent(self, "TRANSMOG_COLLECTION_ITEM_UPDATE");
	ezCollections:RegisterEvent(self, "TRANSMOG_SOURCE_COLLECTABILITY_UPDATE");
	self:Refresh();
end

function DressUpOutfitDetailsPanelMixin:OnHide()
	ezCollections:UnregisterEvent(self, "TRANSMOG_COLLECTION_ITEM_UPDATE");
	ezCollections:UnregisterEvent(self, "TRANSMOG_SOURCE_COLLECTABILITY_UPDATE");
end

function DressUpOutfitDetailsPanelMixin:OnEvent(event, ...)
	if event == "TRANSMOG_COLLECTION_ITEM_UPDATE" then
		if self.waitingOnItemData then
			self:Refresh();
		elseif self.mousedOverFrame then
			self.mousedOverFrame:OnEnter();
		end
	elseif event == "TRANSMOG_SOURCE_COLLECTABILITY_UPDATE" then
		self:MarkDirty();
	end
end

function DressUpOutfitDetailsPanelMixin:OnUpdate()
	self:SetScript("OnUpdate", nil);
	self:Refresh();
end

function DressUpOutfitDetailsPanelMixin:OnKeyDown(key)
	if key == WARDROBE_CYCLE_KEY and self.mousedOverFrame then
		--self:SetPropagateKeyboardInput(false);
		self.mousedOverFrame:OnCycleKeyDown();
	else
		--self:SetPropagateKeyboardInput(true);
	end
end

function DressUpOutfitDetailsPanelMixin:MarkDirty()
	self:SetScript("OnUpdate", self.OnUpdate);
end

function DressUpOutfitDetailsPanelMixin:MarkWaitingOnItemData()
	self.waitingOnItemData = true;
end

function DressUpOutfitDetailsPanelMixin:OnAppearanceChange()
	if self:IsShown() then
		self:Refresh();
	end
end

function DressUpOutfitDetailsPanelMixin:SetMousedOverFrame(frame)
	self.mousedOverFrame = frame;
end

function DressUpOutfitDetailsPanelMixin:Refresh()
	self.slotPool:ReleaseAll();
	self.lastFrame = nil;
	self.validMainHand = false;
	self.waitingOnItemData = false;
	self.DisplayMeleeButton:Hide();
	self.DisplayRangedButton:Hide();
	self.DisplayMainHandButton:Hide();
	self.DisplayOffHandButton:Hide();

	local sources, mainHandEnchant, offHandEnchant = DressUpModel:GetSources();

	local spacer = false;
	for _, slotID in ipairs(TransmogSlotOrder) do
		local source = sources[slotID] or 0;
		if source then
			-- spacer before weapons
			if not spacer and (slotID == INVSLOT_MAINHAND or slotID == INVSLOT_OFFHAND) or slotID == INVSLOT_RANGED then
				spacer = true;
				self:AddSlotFrame(nil, nil, nil);
			end
			-- primary
			local frame = self:AddSlotFrame(slotID, source, "appearanceID");
			local button;
			if (slotID == INVSLOT_MAINHAND or slotID == INVSLOT_OFFHAND and (not self.DisplayMeleeButton:IsShown() or DressUpModel.conflictingWeapons)) and frame.transmogID then
				if DressUpModel.conflictingWeapons then
					if slotID == INVSLOT_MAINHAND then
						button = self.DisplayMainHandButton;
						button:SetChecked(DressUpModel.displayedWeapon == 3);
					else
						button = self.DisplayOffHandButton;
						button:SetChecked(DressUpModel.displayedWeapon == 4);
					end
				else
					button = self.DisplayMeleeButton;
					button:SetChecked(DressUpModel.displayedWeapon == 1);
				end
			elseif slotID == INVSLOT_RANGED and frame.transmogID then
				button = self.DisplayRangedButton;
				button:SetChecked(DressUpModel.displayedWeapon == 2);
			end
			if button then
				button:SetPoint("RIGHT", frame, "RIGHT");
				button:Show();
				button:SetFrameLevel(frame:GetFrameLevel() + 1);
			end
			-- illusion
			if slotID == INVSLOT_MAINHAND and mainHandEnchant then
				self:AddSlotFrame(slotID, mainHandEnchant, "illusionID");
			end
			if slotID == INVSLOT_OFFHAND and offHandEnchant then
				self:AddSlotFrame(slotID, offHandEnchant, "illusionID");
			end
		end
	end
end

function DressUpOutfitDetailsPanelMixin:AddSlotFrame(slotID, transmogInfo, field)
	-- hide offhand if empty and mainhand has something
	if slotID == INVSLOT_OFFHAND and self.validMainHand and not transmogInfo then
		return;
	end

	local frame = self.slotPool:Acquire();
	local isValid = false;
	if transmogInfo then
		isValid = frame:SetUp(slotID, transmogInfo, field);
		frame:Show();
		frame:SetHeight(24);
		frame:SetFrameLevel(self:GetFrameLevel() + 1);
	else
		-- spacer
		isValid = true;
		frame:Hide();
		frame:SetHeight(18);
	end

	if isValid then
		frame.slotID = slotID;
		if self.lastFrame then
			frame:SetPoint("TOPLEFT", self.lastFrame, "BOTTOMLEFT");
		else
			frame:SetPoint("TOPLEFT", 23, -33);
		end
		self.lastFrame = frame;

		if isValid and slotID == INVSLOT_MAINHAND and transmogInfo then
			self.validMainHand = true;
		end
	else
		frame:Hide();
	end
	return frame;
end

DressUpOutfitDetailsSlotMixin = { };

function DressUpOutfitDetailsSlotMixin:OnHide()
	if self.itemDataLoadedCancelFunc then
		self.itemDataLoadedCancelFunc();
		self.itemDataLoadedCancelFunc = nil;
	end
	self.item = nil;
end

local OUTFIT_SLOT_STATE_ERROR = 1;
local OUTFIT_SLOT_STATE_COLLECTED = 2;
local OUTFIT_SLOT_STATE_UNCOLLECTED = 3;

local GRAY_FONT_ALPHA = 0.7;

local TRANSMOGRIFY_TOOLTIP_APPEARANCE_KNOWN_CHECKMARK = [[|TInterface\AddOns\ezCollections\interface\Common\CommonIcons:16:16:0:-1:2048:1024:1:257:517:773|t ]]..TRANSMOGRIFY_TOOLTIP_APPEARANCE_KNOWN;

function DressUpOutfitDetailsSlotMixin:OnEnter()
	if not self.transmogID then
		return;
	end

	if self.item and not GetItemInfo(self.item) then
		self:GetParent():MarkDirty();
		return;
	end

	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	if self.isHiddenVisual then
		GameTooltip_AddColoredLine(GameTooltip, self.name, NORMAL_FONT_COLOR);
	elseif not self.item then
		-- illusion
		GameTooltip_AddColoredLine(GameTooltip, self.name, NORMAL_FONT_COLOR);
		GameTooltip_AddColoredLine(GameTooltip, _G[TransmogUtil.GetSlotName(self.slotID)], HIGHLIGHT_FONT_COLOR);
		local illusionInfo = C_TransmogCollection.GetIllusionInfo(self.transmogID);
		local sourceText = CollectionWardrobeUtil.GetAppearanceSourceTextWithDrops(illusionInfo, illusionInfo.sourceText);
		if ( sourceText ) then
			GameTooltip_AddColoredLine(GameTooltip, sourceText, HIGHLIGHT_FONT_COLOR, true);
		end
		if ezCollections.Config.Wardrobe.ShowItemID then
			GameTooltip_AddColoredLine(GameTooltip, "ID "..self.transmogID, GRAY_FONT_COLOR, true);
		end
		if self.slotState == OUTFIT_SLOT_STATE_UNCOLLECTED then
			GameTooltip_AddColoredLine(GameTooltip, TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN, LIGHTBLUE_FONT_COLOR);
		else
			GameTooltip_AddColoredLine(GameTooltip, TRANSMOGRIFY_TOOLTIP_APPEARANCE_KNOWN_CHECKMARK, GREEN_FONT_COLOR);
		end
	elseif self.slotState == OUTFIT_SLOT_STATE_ERROR then
		local hasData, canCollect = C_TransmogCollection.AccountCanCollectSource(self.transmogID);
		-- hasData should be true, there's a check that the item data is cached at the top of the function

		if not canCollect and (self.slotID == INVSLOT_MAINHAND or self.slotID == INVSLOT_OFFHAND) then
			local pairedTransmogID = C_TransmogCollection.GetPairedArtifactAppearance(self.transmogID);
			if pairedTransmogID then
				hasData, canCollect = C_TransmogCollection.AccountCanCollectSource(pairedTransmogID);
				if not hasData then
					self:GetParent():MarkDirty();
					return;
				end
			end
		end

		if canCollect then
			GameTooltip:AddLine(self.name, GetItemQualityColor(select(3, GetItemInfo(self.item))));
			local slotName = TransmogUtil.GetSlotName(self.slotID);
			GameTooltip_AddColoredLine(GameTooltip, _G[slotName], HIGHLIGHT_FONT_COLOR);
			if ezCollections.Config.Wardrobe.ShowItemID then
				GameTooltip_AddColoredLine(GameTooltip, "ID "..self.transmogID, GRAY_FONT_COLOR, true);
			end
			GameTooltip_AddErrorLine(GameTooltip, TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNUSABLE);
		else
			local hideVendorPrice = true;
			GameTooltip:SetHyperlink(select(2, GetItemInfo(self.item)), nil, nil, nil, hideVendorPrice);
			GameTooltip_AddErrorLine(GameTooltip, TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNCOLLECTABLE);
		end
	--elseif self.slotState == OUTFIT_SLOT_STATE_UNCOLLECTED then
	else
		if C_TransmogCollection.PlayerKnowsSource(self.transmogID) then
			self:GetParent():SetMousedOverFrame(self);

			local appearanceInfo = C_TransmogCollection.GetAppearanceInfoBySource(self.transmogID);
			local sources = CollectionWardrobeUtil.GetSortedAppearanceSources(appearanceInfo.appearanceID);
			local showUseError = true;
			local inLegionArtifactCategory = false;
			local slotName = TransmogUtil.GetSlotName(self.slotID);
			local subheaderString = format("|cFFFFFFFF%s|r", _G[slotName]);
			self.tooltipSourceIndex, self.tooltipCycle = CollectionWardrobeUtil.SetAppearanceTooltip(GameTooltip, sources, self.transmogID, self.tooltipSourceIndex, showUseError, inLegionArtifactCategory, subheaderString, false);
		else
			GameTooltip:AddLine(self.name, GetItemQualityColor(select(3, GetItemInfo(self.item))));
			local slotName = TransmogUtil.GetSlotName(self.slotID);
			GameTooltip_AddColoredLine(GameTooltip, _G[slotName], HIGHLIGHT_FONT_COLOR);
			if ezCollections.Config.Wardrobe.ShowItemID then
				GameTooltip_AddColoredLine(GameTooltip, "ID "..self.transmogID, GRAY_FONT_COLOR, true);
			end
		end
		if self.slotState == OUTFIT_SLOT_STATE_UNCOLLECTED then
			GameTooltip_AddColoredLine(GameTooltip, TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN, LIGHTBLUE_FONT_COLOR);
		else
			GameTooltip_AddColoredLine(GameTooltip, TRANSMOGRIFY_TOOLTIP_APPEARANCE_KNOWN_CHECKMARK, GREEN_FONT_COLOR);
		end
	--[[
	else
		GameTooltip:AddLine(self.name, GetItemQualityColor(select(3, GetItemInfo(self.item))));
		local slotName = TransmogUtil.GetSlotName(self.slotID);
		GameTooltip_AddColoredLine(GameTooltip, _G[slotName], HIGHLIGHT_FONT_COLOR);
		if ezCollections.Config.Wardrobe.ShowItemID then
			GameTooltip_AddColoredLine(GameTooltip, "ID "..self.transmogID, GRAY_FONT_COLOR, true);
		end
		GameTooltip_AddColoredLine(GameTooltip, TRANSMOGRIFY_TOOLTIP_APPEARANCE_KNOWN_CHECKMARK, GREEN_FONT_COLOR);
	]]
	end
	GameTooltip:Show();
end

function DressUpOutfitDetailsSlotMixin:OnLeave()
	self:GetParent():SetMousedOverFrame(nil);
	self.tooltipSourceIndex = nil;
	self.tooltipCycle = nil;
	GameTooltip:Hide();
end

function DressUpOutfitDetailsSlotMixin:OnMouseUp(button)
	if button == "RightButton" then
		if self.transmogID then
			PlaySound("gsTitleOptionOK");
			DressUpModel:UndressSlot(self.slotID, not self.item);
		end
	elseif IsModifiedClick("CHATLINK") and self.transmogID then
		local link;
		if self.item then
			link = select(6, C_TransmogCollection.GetAppearanceSourceInfo(self.transmogID));
		else
			link = select(2, C_TransmogCollection.GetIllusionStrings(self.transmogID));
		end
		if link then
			if not ChatEdit_InsertLink(link) then
				ChatFrame_OpenChat(link);
			end
		end
	end
end

function DressUpOutfitDetailsSlotMixin:OnCycleKeyDown()
	if not self.tooltipCycle and not self.tooltipSourceIndex then
		return;
	end
	if IsShiftKeyDown() then
		self.tooltipSourceIndex = self.tooltipSourceIndex - 1;
	else
		self.tooltipSourceIndex = self.tooltipSourceIndex + 1;
	end
	self:OnEnter();
end

function DressUpOutfitDetailsSlotMixin:SetUp(slotID, source, field)
	if field == "appearanceID" then
		return self:SetAppearance(slotID, source);
	elseif field == "illusionID" then
		return self:SetIllusion(source);
	end
end

function DressUpOutfitDetailsSlotMixin:SetAppearance(slotID, transmogID)
	local itemID = C_TransmogCollection.GetSourceItemID(transmogID);
	if not itemID then
		self.Icon:SetTexture(nil);
		self.IconBorder:SetTexture(nil);
		self.HiddenIcon:Hide();
		local slotName = TransmogUtil.GetSlotName(slotID);
		self.Name:SetFormattedText(TRANSMOG_EMPTY_SLOT_FORMAT, _G[slotName]);
		self.Name:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
		self.Name:SetAlpha(GRAY_FONT_ALPHA);
		self.transmogID = nil;
	else
		local appearanceInfo = C_TransmogCollection.GetAppearanceInfoBySource(transmogID);
		local hasAllData = false;
		transmogID, hasAllData = transmogID, GetItemInfo(transmogID) ~= nil;
		if not hasAllData then
			self:GetParent():MarkWaitingOnItemData();
		end
		itemID = transmogID;

		self.item = itemID;
		if not GetItemInfo(self.item) then
			self.Icon:SetTexture(nil);
			self.IconBorder:SetTexture(nil);
			self.Name:SetText(nil);
			ezCollections:QueryItem(self.item);
		end
		self:SetItemInfo(transmogID, appearanceInfo, slotID);
	end

	return true;
end

function DressUpOutfitDetailsSlotMixin:SetItemInfo(transmogID, appearanceInfo, slotID)
	local icon = C_TransmogCollection.GetSourceIcon(transmogID);
	local name = GetItemInfo(self.item);
	local slotState, isHiddenVisual;

	if not appearanceInfo then
		-- either uncollectable, or collectable but hidden until collected
		local hasData, canCollect = C_TransmogCollection.PlayerCanCollectSource(transmogID);
		if canCollect then
			slotState = OUTFIT_SLOT_STATE_UNCOLLECTED;
		else
			slotState = OUTFIT_SLOT_STATE_ERROR;
		end
	elseif appearanceInfo.appearanceIsCollected then
		-- collected
		slotState = OUTFIT_SLOT_STATE_COLLECTED;
		isHiddenVisual = C_TransmogCollection.IsAppearanceHiddenVisual(transmogID);
		if isHiddenVisual then
			name = ezCollections:GetHiddenVisualItemName(slotID);
			icon = select(2, GetInventorySlotInfo(TransmogUtil.GetSlotName(slotID)));
		end
	else
		-- uncollected
		slotState = OUTFIT_SLOT_STATE_UNCOLLECTED;
	end

	local useSmallIcon = false;
	self:SetDetails(transmogID, icon, name, useSmallIcon, slotState, isHiddenVisual);
end

function DressUpOutfitDetailsSlotMixin:SetIllusion(transmogID)
	local illusionInfo = C_TransmogCollection.GetIllusionInfo(transmogID);
	if not illusionInfo then
		return false;
	end

	local name = illusionInfo.name; --C_TransmogCollection.GetIllusionStrings(illusionInfo.sourceID);
	local useSmallIcon = true;
	local slotState = illusionInfo.isCollected and OUTFIT_SLOT_STATE_COLLECTED or OUTFIT_SLOT_STATE_UNCOLLECTED;
	local isHiddenVisual = illusionInfo.isHideVisual;
	local icon = illusionInfo.icon;
	if isHiddenVisual then
		icon = [[Interface\AddOns\ezCollections\Textures\EnchantSlotIcon]];
	end
	self:SetDetails(transmogID, icon, TRANSMOGRIFIED_ENCHANT:format(name), useSmallIcon, slotState, isHiddenVisual);

	return true;
end

local s_qualityToAtlasColorName = {
	[0] = "gray",
	[1] = "white",
	[2] = "green",
	[3] = "blue",
	[4] = "purple",
	[5] = "orange",
	[6] = "artifact",
	[7] = "artifact", -- "account"
};

function DressUpOutfitDetailsSlotMixin:SetDetails(transmogID, icon, name, useSmallIcon, slotState, isHiddenVisual)
	-- info for tooltip
	self.transmogID = transmogID;
	self.name = name;
	self.slotState = slotState;
	self.isHiddenVisual = isHiddenVisual;

	local nameColor = NORMAL_FONT_COLOR;
	local nameAlpha = 1;
	local borderType;
	if slotState == OUTFIT_SLOT_STATE_ERROR then
		nameColor = RED_FONT_COLOR;
		borderType = "error";
	elseif slotState == OUTFIT_SLOT_STATE_UNCOLLECTED then
		nameColor = GRAY_FONT_COLOR;
		borderType = "uncollected";
		nameAlpha = GRAY_FONT_ALPHA;
	elseif isHiddenVisual then
		borderType = "uncollected";
	else
		-- this is something collected, show in default colors
		if self.item then
			local _, _, quality = GetItemInfo(self.item);
			quality = quality or 1;
			local r, g, b = GetItemQualityColor(quality);
			nameColor = { r = r, g = g, b = b };
			local colorName = s_qualityToAtlasColorName[quality];
			borderType = colorName;
		else
			borderType = "illusion";
		end
	end

	self.Name:SetText(name);
	self.Name:SetTextColor(nameColor.r, nameColor.g, nameColor.b);
	self.Name:SetAlpha(nameAlpha);

	self.Icon:SetTexture(icon);
	if slotState == OUTFIT_SLOT_STATE_UNCOLLECTED or isHiddenVisual then
		self.Icon:SetAlpha(0.3);
		self.Icon:SetDesaturated(true);
	else
		self.Icon:SetAlpha(1);
		self.Icon:SetDesaturated(false);
	end

	if useSmallIcon then
		borderType = "small-"..borderType;
		self.Icon:SetSize(14, 14);
		if isHiddenVisual then
			self.HiddenIcon:SetSize(24, 20);
		end
	else
		self.Icon:SetSize(20, 20);
		if isHiddenVisual then
			self.HiddenIcon:SetSize(26, 22);
		end
	end
	self.IconBorder:SetAtlas("dressingroom-itemborder-"..borderType);
	self.HiddenIcon:SetShown(isHiddenVisual);
end
