local ADDON_NAME = ...;
local ADDON_VERSION = GetAddOnMetadata(ADDON_NAME, "Version");

local ADDON_PREFIX = "ezCollections";
local ENCHANT_HIDDEN = 88;
local ITEM_HIDDEN = 15;
local ITEM_BACK = 16;
TRANSMOGRIFY_FONT_COLOR = "|cFFFF80FF";

local TRANSMOGRIFIABLE_SLOTS =
{
    [1] = "HeadSlot",
    -- [2] = "NeckSlot",
    [3] = "ShoulderSlot",
    [4] = "ShirtSlot",
    [5] = "ChestSlot",
    [6] = "WaistSlot",
    [7] = "LegsSlot",
    [8] = "FeetSlot",
    [9] = "WristSlot",
    [10] = "HandsSlot",
    -- [11] = "Finger0Slot",
    -- [12] = "Finger1Slot",
    -- [13] = "Trinket0Slot",
    -- [14] = "Trinket1Slot",
    [15] = "BackSlot",
    [16] = "MainHandSlot",
    [17] = "SecondaryHandSlot",
    [18] = "RangedSlot",
    [19] = "TabardSlot",
};

local CLASS_ID_TO_NAME =
{
    "WARRIOR",
    "PALADIN",
    "HUNTER",
    "ROGUE",
    "PRIEST",
    "DEATHKNIGHT",
    "SHAMAN",
    "MAGE",
    "WARLOCK",
    "MONK",
    "DRUID",
    "DEMONHUNTER",
    "ANY",
};

local RACE_ID_TO_NAME =
{
    "HUMAN",
    "ORC",
    "DWARF",
    "NIGHTELF",
    "UNDEAD",
    "TAUREN",
    "GNOME",
    "TROLL",
    "GOBLIN",
    "BLOODELF",
    "DRAENEI",
    "ANY",
};

local oGetInventoryItemID = GetInventoryItemID;

StaticPopupDialogs["GOSSIP_ENTER_CODE"].EditBoxOnEnterPressed = function(self, data)
    local parent = self:GetParent();
    SelectGossipOption(data, parent.editBox:GetText(), true);
    parent:Hide();
end

local dressUpAddonDisabled = nil;
if select(4, GetAddOnInfo("ezCollectionsDressUp")) and select(4, GetAddOnInfo("ElvUI")) then
    DisableAddOn("ezCollectionsDressUp");
    dressUpAddonDisabled = true;
end

-- ---------
-- Ace Addon
-- ---------
local addon = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceEvent-3.0", "AceTimer-3.0");
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME);

function addon:OnInitialize()
    BINDING_HEADER_EZCOLLECTIONS                    = L["Binding.Header"];
    BINDING_NAME_EZCOLLECTIONS_UNLOCK_SKIN          = L["Binding.UnlockSkin"];
    BINDING_NAME_EZCOLLECTIONS_MENU_ISENGARD        = L["Binding.Menu.Isengard"];
    BINDING_NAME_EZCOLLECTIONS_MENU_TRANSMOG        = L["Binding.Menu.Transmog"];
    BINDING_NAME_EZCOLLECTIONS_MENU_TRANSMOG_SETS   = L["Binding.Menu.Transmog.Sets"];
    BINDING_NAME_EZCOLLECTIONS_MENU_COLLECTIONS     = L["Binding.Menu.Collections"];
    BINDING_NAME_EZCOLLECTIONS_MENU_DAILY           = L["Binding.Menu.Daily"];

    self:RegisterEvent("CHAT_MSG_ADDON");
    self:RegisterEvent("PLAYER_LOGIN");
    self:RegisterEvent("INSPECT_TALENT_READY");
    self:RegisterEvent("UNIT_INVENTORY_CHANGED");
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
    self:RegisterEvent("BANKFRAME_OPENED");
    self:RegisterEvent("BAG_UPDATE");
    self:RegisterEvent("ADDON_LOADED");
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("COMPANION_LEARNED");
    self:RegisterEvent("COMPANION_UNLEARNED");
    self:RegisterEvent("SPELL_UPDATE_USABLE");
    self:RegisterEvent("ACTIONBAR_UPDATE_USABLE");
    self:RegisterEvent("UNIT_SPELLCAST_START");
    self:RegisterEvent("UNIT_SPELLCAST_FAILED");

    local PRESET_COLORS =
    {
        pink        = { Name = L["Color.Pink"],     r =         1, g =       0.5, b = 1, a = 1, code = TRANSMOGRIFY_FONT_COLOR },
        blue        = { Name = L["Color.Blue"],     r = 0x88/0xFF, g = 0xAA/0xFF, b = 1, a = 1, code = "|cFF88AAFF" },
        gold        = { Name = L["Color.Gold"],     r = 0xFF/0xFF, g = 0xD2/0xFF, b = 0, a = 1, code = "|cFFFFD200" },
        white       = { Name = L["Color.White"],    r =         1, g =         1, b = 1, a = 1, code = "|cFFFFFFFF" },
    };

    local defaultsConfig =
    {
        profile =
        {
            NewVersion =
            {
                HideRetiredPopup = false,
            },
            Alerts =
            {
                AddSkin =
                {
                    Enable = true,
                    Color = { Custom = false, r = PRESET_COLORS["pink"].r, g = PRESET_COLORS["pink"].g, b = PRESET_COLORS["pink"].b, a = PRESET_COLORS["pink"].a },
                    FullRowColor = false,
                },
            },
            TooltipFlags =
            {
                Enable = true,
                Color = { Custom = false, r = PRESET_COLORS["pink"].r, g = PRESET_COLORS["pink"].g, b = PRESET_COLORS["pink"].b, a = PRESET_COLORS["pink"].a },
            },
            TooltipTransmog =
            {
                Enable = true,
                IconEntry =
                {
                    Enable = false,
                    Size = 0,
                    Crop = true,
                },
                IconEnchant =
                {
                    Enable = false,
                    Size = 0,
                },
                Color = { Custom = false, r = PRESET_COLORS["pink"].r, g = PRESET_COLORS["pink"].g, b = PRESET_COLORS["pink"].b, a = PRESET_COLORS["pink"].a },
                NewHideVisualIcon = true,
            },
            TooltipCollection =
            {
                OwnedItems = false,
                Skins = true,
                SkinUnlock = true,
                TakenQuests = false,
                RewardedQuests = false,
                Color = { Custom = false, r = PRESET_COLORS["blue"].r, g = PRESET_COLORS["blue"].g, b = PRESET_COLORS["blue"].b, a = PRESET_COLORS["blue"].a },
                Separator = true,
            },
            TooltipSets =
            {
                Collected = true,
                Uncollected = true,
                Color = { Custom = false, r = PRESET_COLORS["blue"].r, g = PRESET_COLORS["blue"].g, b = PRESET_COLORS["blue"].b, a = PRESET_COLORS["blue"].a },
                Separator = true,
            },
            RestoreItemIcons =
            {
                Equipment = true,
                Inspect = true,
                EquipmentManager = true,
                Global = false,
            },
            RestoreItemSets =
            {
                Equipment = true,
                Inspect = true,
            },
            Wardrobe =
            {
                CameraOption = ezCollections.CameraOptions[1],
                CameraOptionSetup = false,
                CameraZoomSpeed = 0.5,
                CameraZoomSmooth = true,
                CameraZoomSmoothSpeed = 0.5,
                CameraPanLimit = true,
                MicroButtonsOption = nil,
                MicroButtonsTransmogrify = nil, -- Obsolete
                MicroButtonsRMB = nil, -- Obsolete
                MicroButtonsActionLMB = nil,
                MicroButtonsActionRMB = nil,
                MicroButtonsIcon = nil,
                MinimapButtonCollections = { minimapPos = 205 },
                MinimapButtonCollectionsRMB = false,
                MinimapButtonTransmogrify = { minimapPos = 225 },
                MinimapButtonTransmogrifyRMB = false,
                OutfitsSort = 1,
                OutfitsPrepaidSheen = true,
                OutfitsSelectLastUsed = false,
                PerCharacterFavorites = false,
                HideExtraSlotsOnSetSelect = false,
                ShowWowheadSetIcon = true,
                ShowSetID = false,
                ShowItemID = false,
                ShowCollectedVisualSourceText = false,
                ShowCollectedVisualSources = false,
                WindowsCloseWithEscape = true,
                WindowsStrata = "HIGH",
                WindowsClampToScreen = true,
                WindowsLockTransmogrify = true,
                WindowsLayoutTransmogrify = true,
                WindowsLockCollections = true,
                WindowsLayoutCollections = true,
                EtherealWindowSound = true,
                DressUpClassBackground = false,
                PortraitButton = false,
                MountsUnusableInZone = false,
                MountsShowHidden = false,
            },
            TransmogCollection =
            {
                PerCharacter =
                {
                    ["*"] =
                    {
                        Favorites = { },
                        SetFavorites = { },
                    },
                },
                Favorites = { },
                NewAppearances = { },
                LatestAppearanceID = nil,
                LatestAppearanceCategoryID = nil,
                SetFavorites = { },
                NewSetSources = { },
                LatestSetSource = nil,
            },
            MountJournal =
            {
                PerCharacter =
                {
                    ["*"] =
                    {
                        Favorites = { },
                        NeedFanfare = { },
                    },
                },
            },
            PetJournal =
            {
                PerCharacter =
                {
                    ["*"] =
                    {
                        Favorites = { },
                        NeedFanfare = { },
                    },
                },
            },
            CVar =
            {
                ["*"] =
                {
                    closedInfoFrames = 0, -- Bitfield for which help frames have been acknowledged by the user
                    transmogrifySourceFilters = 0, -- Bitfield for which source filters are applied in the  wardrobe at the transmogrifier
                    wardrobeSourceFilters = 0, -- Bitfield for which source filters are applied in the wardrobe in the collection journal
                    wardrobeSetsFilters = 0, -- Bitfield for which transmog sets filters are applied in the wardrobe in the collection journal
                    transmogrifyShowCollected = true, -- Whether to show collected transmogs in the at the transmogrifier
                    transmogrifyShowUncollected = true, -- Whether to show uncollected transmogs in the at the transmogrifier
                    wardrobeShowCollected = true, -- Whether to show collected transmogs in the wardrobe
                    wardrobeShowUncollected = true, -- Whether to show uncollected transmogs in the wardrobe
                    missingTransmogSourceInItemTooltips = false, -- Whether to show if you have collected the appearance of an item but not from that item itself
                    lastTransmogOutfitIDSpec1 = "", -- SetID of the last applied transmog outfit for the 1st spec
                    lastTransmogOutfitIDSpec2 = "", -- SetID of the last applied transmog outfit for the 2nd spec
                    lastTransmogOutfitIDSpec3 = "", -- SetID of the last applied transmog outfit for the 3rd spec
                    lastTransmogOutfitIDSpec4 = "", -- SetID of the last applied transmog outfit for the 4th spec
                    -- latestTransmogSetSource, -- itemModifiedAppearanceID of the latest collected source belonging to a set
                    transmogCurrentSpecOnly = false, -- Stores whether transmogs apply to current spec instead of all specs
                    miniDressUpFrame = false,
                    mountJournalGeneralFilters = 0, -- Bitfield for which collected filters are applied in the mount journal
                    mountJournalSourcesFilter = 0, -- Bitfield for which source filters are applied in the mount journal
                    mountJournalTypeFilter = 0, -- Bitfield for which type filters are applied in the mount journal
                    petJournalFilters = 0, -- Bitfield for which collected filters are applied in the pet journal
                    petJournalSort = 1, -- Sorting value for the pet journal
                    petJournalSourceFilters = 0, -- Bitfield for which source filters are applied in the pet journal
                    petJournalTab = 5, -- Stores the last tab the pet journal was opened to
                    petJournalTypeFilters = 0, -- Bitfield for which type filters are applied in the pet journal
                    -- Custom
                    transmogrifyShowClaimable = true,
                    transmogrifyShowPurchasable = true,
                    transmogrifyShowObtainable = true,
                    transmogrifyShowUnobtainable = false,
                    transmogrifyArmorFilters = 0,
                    transmogrifyClassFilters = 0,
                    transmogrifyRaceFilters = 0,
                    wardrobeArmorFilters = 0,
                    wardrobeClassFilters = 0,
                    wardrobeRaceFilters = 0,
                    wardrobeSetsClassFilters = 0,
                    wardrobeSetsRaceFilters = 0,
                    transmogrifySetsSlotMask = 0,
                },
            }
        },
    };
    local defaultsCache =
    {
        realm =
        {
            Version = 0,
            AddonVersion = nil,
            All = { },
            Slot =
            {
                ["HEAD"]            = { },
                ["SHOULDER"]        = { },
                ["BACK"]            = { },
                ["CHEST"]           = { },
                ["TABARD"]          = { },
                ["SHIRT"]           = { },
                ["WRIST"]           = { },
                ["HANDS"]           = { },
                ["WAIST"]           = { },
                ["LEGS"]            = { },
                ["FEET"]            = { },
                ["WAND"]            = { },
                ["1H_AXE"]          = { },
                ["1H_SWORD"]        = { },
                ["1H_MACE"]         = { },
                ["DAGGER"]          = { },
                ["FIST"]            = { },
                ["SHIELD"]          = { },
                ["HOLDABLE"]        = { },
                ["2H_AXE"]          = { },
                ["2H_SWORD"]        = { },
                ["2H_MACE"]         = { },
                ["STAFF"]           = { },
                ["POLEARM"]         = { },
                ["BOW"]             = { },
                ["GUN"]             = { },
                ["CROSSBOW"]        = { },
                ["THROWN"]          = { },
                ["FISHING_POLE"]    = { },
                ["MISC"]            = { },
                ["ENCHANT"]         = { },
            },
            ScrollToEnchant = { },
            EnchantToScroll = { },
            Sets = { },
            Cameras = { },
        },
    };

    local config = LibStub("AceDB-3.0"):New(ADDON_NAME.."Config", defaultsConfig, true);
    ezCollections.Config = config.profile;
    local cache = LibStub("AceDB-3.0"):New(ADDON_NAME.."Cache", defaultsCache, true);
    ezCollections.Cache = cache.realm;

    ezCollections.ClearCache = function(self)
        cache:ResetDB(nil);
        self.Cache = cache.realm;
    end;

    -- General
    local panelGeneral, panelWardrobe, panelIntegration, panelBindings;
    local showAdvancedOptions = false;
    local bigButtonCounter = 1;
    LibStub("AceGUI-3.0"):RegisterWidgetType("ezCollectionsOptionsBigButtonTemplate", function()
        local self =
        {
            type = "ezCollectionsOptionsBigButtonTemplate",
            frame = CreateFrame("Button", "ezCollectionsOptionsBigButton"..bigButtonCounter, nil, "ezCollectionsOptionsBigButtonTemplate"),
        };
        self.frame.obj = self;
        bigButtonCounter = bigButtonCounter + 1;
        function self:OnAcquire()
        end
        function self:OnRelease()
        end
        function self:SetLabel(text)
            self.frame.ContentsFrame.Header:SetText(text);
        end
        function self:SetText(text)
            self.frame.ContentsFrame.Text:SetText(text);
        end
        LibStub("AceGUI-3.0"):RegisterAsWidget(self);
        return self;
    end, 1);
    LibStub("AceGUI-3.0"):RegisterWidgetType("ezCollectionsOptionsMicroButtonIconTemplate", function()
        local self =
        {
            type = "ezCollectionsOptionsMicroButtonIconTemplate",
            frame = CreateFrame("CheckButton", nil, nil, "ezCollectionsOptionsMicroButtonIconTemplate"),
        };
        self.frame.obj = self;
        Mixin(self.frame, SetEnabledMixin);
        function self:OnAcquire()
        end
        function self:OnRelease()
        end
        function self:SetLabel(text)
            self.frame:GetNormalTexture():SetTexture(format("%s-Up", text));
            self.frame:GetPushedTexture():SetTexture(format("%s-Down", text));
            self.frame:GetCheckedTexture():SetTexture(format("%s-Down", text));
        end
        function self:SetText(text)
        end
        function self:SetDisabled(disabled)
            self.frame:SetEnabled(not disabled);
            self.frame:GetNormalTexture():SetDesaturated(disabled);
            self.frame:GetPushedTexture():SetDesaturated(disabled);
            self.frame:GetCheckedTexture():SetDesaturated(disabled);
        end
        function self:OnWidthSet(width)
            if width ~= 28 then
                self:SetWidth(28);
                self:SetHeight(37);
            end
        end
        LibStub("AceGUI-3.0"):RegisterAsWidget(self);
        return self;
    end, 1);

    -- Wardrobe
    local function updateSpecButton()
        if ezCollections.Config.Wardrobe.OutfitsSelectLastUsed then
            WardrobeTransmogFrame.SpecButton:Enable();
            WardrobeTransmogFrame.SpecButton:EnableMouse(true);
            WardrobeTransmogFrame.SpecButton.Icon:SetDesaturated(false);
        else
            WardrobeTransmogFrame.SpecButton:Disable();
            WardrobeTransmogFrame.SpecButton:EnableMouse(false);
            WardrobeTransmogFrame.SpecButton.Icon:SetDesaturated(true);
            WardrobeTransmogFrame.SpecHelpBox:Hide();
        end
    end
    updateSpecButton();

    -- Windows
    local windowStratas;
    local updateWindows;
    do
        windowStratas =
        {
            "BACKGROUND",
            "LOW",
            "MEDIUM",
            "HIGH",
            "DIALOG",
        };
        updateWindows = function(togglingLayout)
            for _, window in ipairs({ WardrobeFrame, CollectionsJournal }) do
                if ezCollections.Config.Wardrobe.WindowsCloseWithEscape then
                    table.insert(UISpecialFrames, window:GetName());
                else
                    tDeleteItem(UISpecialFrames, window:GetName());
                end
                window:SetFrameStrata(ezCollections.Config.Wardrobe.WindowsStrata);
                window:SetClampedToScreen(ezCollections.Config.Wardrobe.WindowsClampToScreen);
                local wasOpen;
                if togglingLayout then
                    wasOpen = window:IsShown();
                    HideUIPanel(window);
                end
                if window == WardrobeFrame then
                    window:SetAttribute("UIPanelLayout-enabled", ezCollections.Config.Wardrobe.WindowsLockTransmogrify and ezCollections.Config.Wardrobe.WindowsLayoutTransmogrify);
                else
                    window:SetAttribute("UIPanelLayout-enabled", ezCollections.Config.Wardrobe.WindowsLockCollections and ezCollections.Config.Wardrobe.WindowsLayoutCollections);
                end
                UpdateUIPanelPositions(window);
                if wasOpen then
                    ShowUIPanel(window);
                end
            end
        end
    end
    updateWindows();

    -- Micro Buttons
    local microButtonActions;
    local microButtonIcons;
    local microButtonOptions;
    local setupCollectionsMicroButton;
    do
        -- Upgrade settings from version <2.2
        if not ezCollections.Config.Wardrobe.MicroButtonsActionLMB then
            ezCollections.Config.Wardrobe.MicroButtonsActionLMB = ezCollections.Config.Wardrobe.MicroButtonsTransmogrify and 6 or 0;
        end
        if not ezCollections.Config.Wardrobe.MicroButtonsActionRMB then
            if ezCollections.Config.Wardrobe.MicroButtonsRMB then
                ezCollections.Config.Wardrobe.MicroButtonsActionRMB = ezCollections.Config.Wardrobe.MicroButtonsTransmogrify and 0 or 6;
            else
                ezCollections.Config.Wardrobe.MicroButtonsActionRMB = 0;
            end
        end
        if not ezCollections.Config.Wardrobe.MicroButtonsIcon then
            ezCollections.Config.Wardrobe.MicroButtonsIcon = ezCollections.Config.Wardrobe.MicroButtonsTransmogrify and 6 or 5;
        end

        CreateFrame("Button", "CollectionsMicroButton", MainMenuBarArtFrame, "MainMenuBarMicroButton");
        CreateFrame("Button", "CollectionsMicroButtonAlert", CollectionsMicroButton, "MicroButtonAlertTemplate");
        LoadMicroButtonTextures(CollectionsMicroButton, "Help");
        local function getCoreMicroButtons()
            return
            {
                CharacterMicroButton,
                SpellbookMicroButton,
                TalentMicroButton,
                AchievementMicroButton,
                QuestLogMicroButton,
                SocialsMicroButton,
                PVPMicroButton,
                LFDMicroButton,
                MainMenuMicroButton,
                HelpMicroButton,
            };
        end
        local microButtonNames =
        {
            [CharacterMicroButton] = CHARACTER_BUTTON,
            [SpellbookMicroButton] = SPELLBOOK_ABILITIES_BUTTON,
            [TalentMicroButton] = TALENTS_BUTTON,
            [AchievementMicroButton] = ACHIEVEMENT_BUTTON,
            [QuestLogMicroButton] = QUESTLOG_BUTTON,
            [SocialsMicroButton] = SOCIAL_BUTTON,
            [PVPMicroButton] = PLAYER_V_PLAYER,
            [LFDMicroButton] = DUNGEONS_BUTTON,
            [MainMenuMicroButton] = MAINMENU_BUTTON,
            [HelpMicroButton] = HELP_BUTTON,
        };
        microButtonActions =
        {
            [0] = COLLECTIONS,
            [1] = MOUNTS,
            [2] = COMPANIONS,
            [3] = TOY_BOX,
            [4] = HEIRLOOMS,
            [5] = WARDROBE,
            [6] = TRANSMOGRIFY,
        };
        local microButtonBindings =
        {
            [0] = "TOGGLECOLLECTIONS",
            [1] = "TOGGLECOLLECTIONSMOUNTJOURNAL",
            [2] = "TOGGLECOLLECTIONSPETJOURNAL",
            [3] = "TOGGLECOLLECTIONSTOYBOX",
            [4] = "TOGGLECOLLECTIONSHEIRLOOM",
            [5] = "TOGGLECOLLECTIONSWARDROBE",
            [6] = "TOGGLETRANSMOGRIFY",
        };
        microButtonIcons =
        {
            [1] = [[Interface\AddOns\ezCollections\Interface\Buttons\UI-MicroButton-Mounts]],
            [5] = [[Interface\AddOns\ezCollections\Textures\UI-MicroButton-Collections]],
            [6] = [[Interface\AddOns\ezCollections\Textures\UI-MicroButton-Transmogrify]],
        };
        local microButtonInserted;
        local function positionMicroButtons(buttons, inserted)
            if Dominos and Dominos.MenuBar then
                function Dominos.MenuBar:NumButtons()
                    return #buttons;
                end
                function Dominos.MenuBar:AddButton(i)
                    local b = buttons[i]
                    if b then
                        b:SetParent(self.header);
                        b:Show();
                        self.buttons[i] = b;
                    end
                end
                local menuBar = Dominos.Frame:Get("menu");
                if menuBar then
                    menuBar.buttons = CopyTable(buttons);
                    menuBar:LoadButtons();
                    menuBar:Layout();
                end
                return;
            end
            microButtonInserted = inserted;
            if UnitHasVehicleUI("player") then
                return;
            end
            for i, button in ipairs(buttons) do
                if i == 1 then
                    button:SetPoint("BOTTOMLEFT", MainMenuBarArtFrame, "BOTTOMLEFT", inserted and 545 or 552, 2);
                else
                    button:SetPoint("BOTTOMLEFT", buttons[i-1], "BOTTOMRIGHT", inserted and -4 or -3, 0);
                end
                button:Show();
            end
        end
        microButtonOptions =
        {
            { L["Config.Wardrobe.MicroButtons.Option.None"], function() positionMicroButtons(getCoreMicroButtons()); CollectionsMicroButton:Hide(); end },
        };
        local function GetMicroButtonTexture(button)
            if button == CharacterMicroButton then
                return [[Interface\AddOns\ezCollections\Textures\UI-MicroButton-Character]];
            elseif button == PVPMicroButton then
                return [[Interface\AddOns\ezCollections\Textures\UI-MicroButton-PVP-]]..(UnitFactionGroup("player") or "FFA");
            else
                return button:GetNormalTexture():GetTexture();
            end
        end
        for i, button in ipairs(getCoreMicroButtons()) do
            if button == LFDMicroButton and not ezCollections.Config.Wardrobe.MicroButtonsOption then
                ezCollections.Config.Wardrobe.MicroButtonsOption = 1 + i;
            end
            table.insert(microButtonOptions, 1 + i,
            {
                format(L["Config.Wardrobe.MicroButtons.Option.Insert"], GetMicroButtonTexture(button), microButtonNames[button]),
                function()
                    local buttons = getCoreMicroButtons();
                    for i, b in ipairs(buttons) do
                        if b == button then
                            table.insert(buttons, i + 1, CollectionsMicroButton);
                            break;
                        end
                    end
                    positionMicroButtons(buttons, true);
                end,
            });
            if button ~= CharacterMicroButton then
                table.insert(microButtonOptions,
                {
                    format(L["Config.Wardrobe.MicroButtons.Option.Replace"], GetMicroButtonTexture(button), microButtonNames[button]),
                    function()
                        local buttons = getCoreMicroButtons();
                        for i, b in ipairs(buttons) do
                            if b == button then
                                if not UnitHasVehicleUI("player") then
                                    b:Hide();
                                end
                                buttons[i] = CollectionsMicroButton;
                                break;
                            end
                        end
                        positionMicroButtons(buttons);
                    end,
                });
            end
        end
        setupCollectionsMicroButton = function()
            microButtonOptions[ezCollections.Config.Wardrobe.MicroButtonsOption][2]();
            local lmb = ezCollections.Config.Wardrobe.MicroButtonsActionLMB or 0;
            local rmb = ezCollections.Config.Wardrobe.MicroButtonsActionRMB or 0;
            local name = microButtonIcons[ezCollections.Config.Wardrobe.MicroButtonsIcon or 1];
            LoadMicroButtonTextures(CollectionsMicroButton, "Help");
            CollectionsMicroButton:SetNormalTexture(name.."-Up");
            CollectionsMicroButton:SetPushedTexture(name.."-Down");
            CollectionsMicroButton.tooltipText = MicroButtonTooltipText(COLLECTIONS, "TOGGLECOLLECTIONS");
            CollectionsMicroButton.newbieText = format(L["Tooltip.MicroButton"],
                                                       (lmb ~= 0 or rmb ~= 0)
                                                       and format(L["Tooltip.MicroButton.Buttons"],
                                                                  lmb ~= 0 and format(L["Tooltip.MicroButton.LMB"], microButtonActions[lmb]) or "",
                                                                  rmb ~= 0 and format(L["Tooltip.MicroButton.RMB"], microButtonActions[rmb]) or "")
                                                       or "");
            UpdateMicroButtons();
        end
        hooksecurefunc("VehicleMenuBar_MoveMicroButtons", function(skinName)
            if Dominos and Dominos.MenuBar then
                setupCollectionsMicroButton();
                return;
            end
            if not skinName and not UnitHasVehicleUI("player") then
                setupCollectionsMicroButton();
            else
                local buttons = getCoreMicroButtons();
                for i, button in ipairs(buttons) do
                    if button ~= CharacterMicroButton and button ~= SocialsMicroButton then
                        button:SetPoint("BOTTOMLEFT", buttons[i-1], "BOTTOMRIGHT", -3, 0);
                    end
                    button:Show();
                end
            end
        end);
        hooksecurefunc("UpdateMicroButtons", function()
            if CollectionsJournal:IsShown() or WardrobeFrame:IsShown() then
                CollectionsMicroButton:SetButtonState("PUSHED", 1);
            else
                CollectionsMicroButton:SetButtonState("NORMAL");
            end
        end);
        function ezCollectionsDominosHook()
            if Dominos and not Dominos.MenuBar then
                setupCollectionsMicroButton();
            end
        end
        CollectionsMicroButton:SetScript("OnEvent", function(self, event)
            if event == "UPDATE_BINDINGS" then
                setupCollectionsMicroButton();
            end
        end)
        CollectionsMicroButton:SetScript("OnClick", function(self, button)
            local action = ezCollections.Config.Wardrobe.MicroButtonsActionLMB or 0;
            if button == "RightButton" then
                action = ezCollections.Config.Wardrobe.MicroButtonsActionRMB or 0;
            end
            if CollectionsJournal:IsShown() or WardrobeFrame:IsShown() then
                HideUIPanel(CollectionsJournal);
                HideUIPanel(WardrobeFrame);
            elseif action == 0 and ezCollections:GetCVar("petJournalTab") ~= 6 then
                HideUIPanel(WardrobeFrame);
                ToggleCollectionsJournal();
            elseif action == 6 or (action == 0 and ezCollections:GetCVar("petJournalTab") == 6) then
                HideUIPanel(CollectionsJournal);
                ShowUIPanel(WardrobeFrame);
            else
                HideUIPanel(WardrobeFrame);
                ToggleCollectionsJournal(action);
            end
        end);
        CollectionsMicroButton:Hide();
        CollectionsMicroButtonAlert:SetPoint("BOTTOM", CollectionsMicroButton, "TOP", 0, -8);
        CollectionsMicroButtonAlert:HookScript("OnUpdate", function(self)
            self:SetFrameStrata("DIALOG");
        end);
        MicroButtonAlert_OnLoad(CollectionsMicroButtonAlert);
        C_Timer.After(1, function()
            if not CollectionsMicroButton:IsVisible() or KMicroMenuArt or ElvUI then
                if not ezCollections:GetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_EZCOLLECTIONS_MICRO_BUTTON) then
                    local button = _G["LibDBIcon10_ezCollections - Collections"];
                    if button and button:IsShown() and button:IsVisible() then
                        local x = button:GetCenter();
                        local left = x < GetScreenWidth() / 2;
                        ezCollectionsMinimapHelpBox:SetParent(button);
                        ezCollectionsMinimapHelpBox:ClearAllPoints();
                        ezCollectionsMinimapHelpBox:SetLeft(left);
                        ezCollectionsMinimapHelpBox:SetPoint(left and "LEFT" or "RIGHT", button, "CENTER", left and 30 or -30, 0);
                        ezCollectionsMinimapHelpBox:Show();
                    end
                end
            else
                MainMenuMicroButton_ShowAlert(CollectionsMicroButtonAlert, L["Tutorial.MicroButton"], LE_FRAME_TUTORIAL_EZCOLLECTIONS_MICRO_BUTTON);
            end
        end);
        setupCollectionsMicroButton();
    end

    -- Minimap Button
    local setupMinimapButtons;
    do
        LibStub("LibDBIcon-1.0"):Register("ezCollections - Collections", LibStub("LibDataBroker-1.1"):NewDataObject("ezCollections - Collections",
        {
            type = "launcher",
            text = L["Minimap.Collections"],
            icon = [[Interface\Icons\INV_Chest_Cloth_17]],
            OnClick = function(ldb, button)
                if button == "LeftButton" or button == "RightButton" then
                    local window = CollectionsJournal;
                    if button == "RightButton" then
                        if ezCollections.Config.Wardrobe.MinimapButtonCollectionsRMB then
                            window = WardrobeFrame;
                        else
                            InterfaceOptionsFrame_Show();
                            InterfaceOptionsFrame_OpenToCategory(panelGeneral);
                            return;
                        end
                    end
                    if window:IsShown() then
                        HideUIPanel(window);
                    elseif window == CollectionsJournal then
                        HideUIPanel(WardrobeFrame);
                        ToggleCollectionsJournal(COLLECTIONS_JOURNAL_TAB_INDEX_APPEARANCES);
                    elseif window == WardrobeFrame then
                        HideUIPanel(CollectionsJournal);
                        ShowUIPanel(WardrobeFrame);
                    end
                end
            end,
            OnTooltipShow = function(tooltip)
                tooltip:SetText(L["Minimap.Collections"]);
                if ezCollections.Config.Wardrobe.MinimapButtonCollectionsRMB then
                    tooltip:AddLine(L["Minimap.Collections.RMBTooltip"], HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1);
                end
            end,
        }), ezCollections.Config.Wardrobe.MinimapButtonCollections);
        LibStub("LibDBIcon-1.0"):Register("ezCollections - Transmogrify", LibStub("LibDataBroker-1.1"):NewDataObject("ezCollections - Transmogrify",
        {
            type = "launcher",
            text = L["Minimap.Transmogrify"],
            icon = [[Interface\AddOns\ezCollections\Interface\Icons\INV_Arcane_Orb]],
            OnClick = function(ldb, button)
                if button == "LeftButton" or button == "RightButton" then
                    local window = WardrobeFrame;
                    if button == "RightButton" then
                        if ezCollections.Config.Wardrobe.MinimapButtonTransmogrifyRMB then
                            window = CollectionsJournal;
                        else
                            InterfaceOptionsFrame_Show();
                            InterfaceOptionsFrame_OpenToCategory(panelGeneral);
                            return;
                        end
                    end
                    if window:IsShown() then
                        HideUIPanel(window);
                    elseif window == CollectionsJournal then
                        HideUIPanel(WardrobeFrame);
                        ToggleCollectionsJournal(COLLECTIONS_JOURNAL_TAB_INDEX_APPEARANCES);
                    elseif window == WardrobeFrame then
                        HideUIPanel(CollectionsJournal);
                        ShowUIPanel(WardrobeFrame);
                    end
                end
            end,
            OnTooltipShow = function(tooltip)
                tooltip:SetText(L["Minimap.Transmogrify"]);
                if ezCollections.Config.Wardrobe.MinimapButtonTransmogrifyRMB then
                    tooltip:AddLine(L["Minimap.Transmogrify.RMBTooltip"], HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1);
                end
            end,
        }), ezCollections.Config.Wardrobe.MinimapButtonTransmogrify);
        setupMinimapButtons = function()
            if ezCollections.Config.Wardrobe.MinimapButtonCollections.hide then
                LibStub("LibDBIcon-1.0"):Hide("ezCollections - Collections");
            else
                LibStub("LibDBIcon-1.0"):Show("ezCollections - Collections");
            end
            if ezCollections.Config.Wardrobe.MinimapButtonTransmogrify.hide then
                LibStub("LibDBIcon-1.0"):Hide("ezCollections - Transmogrify");
            else
                LibStub("LibDBIcon-1.0"):Show("ezCollections - Transmogrify");
            end
        end;
        setupMinimapButtons();
    end

    local keybindHandler =
    {
        Get = function(self, info)
            return table.concat({ GetBindingKey(info.arg) }, ", ");
        end,
        Set = function(self, info, value)
            if value == "" then value = nil; end

            if value and GetBindingAction(value) ~= "" and GetBindingAction(value) ~= info.arg then
                self:Error(L["Binding.Error.AlreadyBound"]);
                return;
            end

            if value then
                if not SetBinding(value, info.arg) then
                    self:Error(L["Binding.Error.BindingFailed"]);
                    return;
                end
            else
                local keys = { GetBindingKey(info.arg) };
                for _, key in pairs(keys) do
                    SetBinding(key);
                end
            end

            if GetCurrentBindingSet()==1 or GetCurrentBindingSet()==2 then
                SaveBindings(GetCurrentBindingSet());
            end
        end,
        Error = function(self, message)
            StaticPopupDialogs["EZCOLLECTIONS_KEYBINDING_ERROR"].text = message;
            StaticPopup_Show("EZCOLLECTIONS_KEYBINDING_ERROR");
        end,
    };
    local reloadUINeeded = false;
    local configTable =
    {
        type = "group",
        name = L["Addon.Color"],
        args =
        {
            general =
            {
                type = "group",
                name = L["Config.General"],
                args =
                {
                    info =
                    {
                        type = "description",
                        name = L["Config.General.Addon"],
                        order = 0,
                    },
                    newVersion =
                    {
                        type = "group",
                        name = function() return ezCollections.NewVersion == nil and "" or ezCollections.NewVersion.Disabled and L["Config.NewVersion.Disabled"] or ezCollections.NewVersion.Outdated and L["Config.NewVersion.Outdated"] or L["Config.NewVersion.Compatible"] end,
                        inline = true,
                        order = 100,
                        hidden = function() return ezCollections.NewVersion == nil; end,
                        args =
                        {
                            desc =
                            {
                                type = "description",
                                name = L["Config.NewVersion.Desc"],
                                order = 0,
                                hidden = function() return ezCollections.NewVersion and ezCollections.NewVersion.Disabled; end,
                            },
                            url =
                            {
                                type = "input",
                                name = L["Config.NewVersion.URL"],
                                order = 1,
                                width = "full",
                                get = function(info) return ezCollections.NewVersion.URL; end;
                                set = function(info, value) end;
                                hidden = function() return ezCollections.NewVersion and ezCollections.NewVersion.Disabled; end,
                            },
                            clientVersion =
                            {
                                type = "description",
                                name = function() return format(L["Config.NewVersion.ClientVersion"], ADDON_VERSION); end;
                                order = 2,
                                hidden = function() return ezCollections.NewVersion and ezCollections.NewVersion.Disabled; end,
                            },
                            serverVersion =
                            {
                                type = "description",
                                name = function() return format(L["Config.NewVersion.ServerVersion"], ezCollections.NewVersion.Version); end;
                                order = 3,
                                hidden = function() return ezCollections.NewVersion and ezCollections.NewVersion.Disabled; end,
                            },
                            hideRetiredPopup =
                            {
                                type = "toggle",
                                name = L["Config.NewVersion.HideRetiredPopup"],
                                desc = L["Config.NewVersion.HideRetiredPopup.Desc"],
                                width = "full",
                                order = 100,
                                get = function(info) return ezCollections.Config.NewVersion.HideRetiredPopup; end,
                                set = function(info, value) ezCollections.Config.NewVersion.HideRetiredPopup = value; end,
                                hidden = function() return ezCollections.NewVersion and not ezCollections.NewVersion.Disabled; end,
                            },
                        },
                    },
                    panelWardrobe =
                    {
                        type = "input",
                        name = L["Config.General.Panel.Wardrobe"],
                        width = "full",
                        order = 150,
                        get = function() return L["Config.General.Panel.Wardrobe.Desc"] end,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panelWardrobe); end,
                        dialogControl = "ezCollectionsOptionsBigButtonTemplate",
                    },
                    panelIntegration =
                    {
                        type = "input",
                        name = L["Config.General.Panel.Integration"],
                        width = "full",
                        order = 155,
                        get = function() return L["Config.General.Panel.Integration.Desc"] end,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panelIntegration); end,
                        dialogControl = "ezCollectionsOptionsBigButtonTemplate",
                    },
                    panelBindings =
                    {
                        type = "input",
                        name = L["Config.General.Panel.Bindings"],
                        width = "full",
                        order = 160,
                        get = function() return L["Config.General.Panel.Bindings.Desc"] end,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panelBindings); end,
                        dialogControl = "ezCollectionsOptionsBigButtonTemplate",
                    },
                    showAdvancedOptions =
                    {
                        type = "toggle",
                        name = L["Config.General.Advanced"],
                        width = "full",
                        order = 199,
                        get = function(info) return showAdvancedOptions; end,
                        set = function(info, value) showAdvancedOptions = value; end,
                    },
                    cache =
                    {
                        type = "group",
                        name = L["Config.Cache"],
                        inline = true,
                        order = 200,
                        hidden = function() return not showAdvancedOptions; end,
                        args =
                        {
                            desc =
                            {
                                type = "description",
                                name = L["Config.Cache.Desc"],
                                order = 0,
                            },
                            clear =
                            {
                                type = "execute",
                                name = L["Config.Cache.Clear"],
                                desc = L["Config.Cache.Clear.Desc"],
                                width = "full",
                                order = 1,
                                func = function() StaticPopup_Show("EZCOLLECTIONS_CONFIRM_CACHE_RESET"); end,
                            },
                        },
                    },
                    config =
                    {
                        type = "group",
                        name = L["Config.Config"],
                        inline = true,
                        order = 300,
                        hidden = function() return not showAdvancedOptions; end,
                        args =
                        {
                            desc =
                            {
                                type = "description",
                                name = L["Config.Config.Desc"],
                                order = 0,
                            },
                            reset =
                            {
                                type = "execute",
                                name = L["Config.Config.Reset"],
                                desc = L["Config.Config.Reset.Desc"],
                                width = "full",
                                order = 100,
                                func = function() StaticPopup_Show("EZCOLLECTIONS_CONFIRM_CONFIG_RESET"); end,
                            },
                        },
                    },
                },
            },
            wardrobe =
            {
                type = "group",
                name = L["Config.Wardrobe"],
                args =
                {
                    misc =
                    {
                        type = "group",
                        name = L["Config.Wardrobe.Misc"],
                        inline = true,
                        order = 50,
                        args =
                        {
                            headerTransmog = { type = "header", name = L["Config.Wardrobe.Misc.Transmog"], order = 49 },
                            hideExtraSlotsOnSetSelect =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.HideExtraSlotsOnSetSelect"],
                                desc = L["Config.Wardrobe.HideExtraSlotsOnSetSelect.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 50,
                                get = function(info) return ezCollections.Config.Wardrobe.HideExtraSlotsOnSetSelect; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.HideExtraSlotsOnSetSelect = value; ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED"); end,
                            },
                            headerOutfits = { type = "header", name = L["Config.Wardrobe.Misc.Outfits"], order = 99 },
                            outfitsSort =
                            {
                                type = "select",
                                name = L["Config.Wardrobe.OutfitsSort"],
                                order = 100,
                                values =
                                {
                                    L["Config.Wardrobe.OutfitsSort.1"],
                                    L["Config.Wardrobe.OutfitsSort.2"],
                                },
                                get = function(info) return ezCollections.Config.Wardrobe.OutfitsSort; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.OutfitsSort = value; ezCollections:RaiseEvent("TRANSMOG_OUTFITS_CHANGED"); end,
                            },
                            lb1 = { type = "description", name = "", order = 109 },
                            outfitsSelectLastUsed =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.OutfitsSelectLastUsed"],
                                desc = L["Config.Wardrobe.OutfitsSelectLastUsed.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 110,
                                get = function(info) return ezCollections.Config.Wardrobe.OutfitsSelectLastUsed; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.OutfitsSelectLastUsed = value; updateSpecButton(); end,
                            },
                            outfitsPrepaidSheen =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.OutfitsPrepaidSheen"],
                                desc = L["Config.Wardrobe.OutfitsPrepaidSheen.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 115,
                                get = function(info) return ezCollections.Config.Wardrobe.OutfitsPrepaidSheen; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.OutfitsPrepaidSheen = value; ezCollections:RaiseEvent("TRANSMOG_OUTFITS_CHANGED"); end,
                            },
                            headerStorage = { type = "header", name = L["Config.Wardrobe.Misc.Storage"], order = 124 },
                            perCharacterFavorites =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.PerCharacterFavorites"],
                                desc = L["Config.Wardrobe.PerCharacterFavorites.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 125,
                                get = function(info) return ezCollections.Config.Wardrobe.PerCharacterFavorites; end,
                                set = function(info, value)
                                    ezCollections.Config.Wardrobe.PerCharacterFavorites = value;
                                    ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
                                    ezCollections:RaiseEvent("TRANSMOG_SETS_UPDATE_FAVORITE");
                                    StaticPopup_Hide("EZCOLLECTIONS_CONFIRM_FAVORITES_SPLIT");
                                    StaticPopup_Hide("EZCOLLECTIONS_CONFIRM_FAVORITES_MERGE");
                                    StaticPopup_Show(ezCollections.Config.Wardrobe.PerCharacterFavorites and "EZCOLLECTIONS_CONFIRM_FAVORITES_SPLIT" or "EZCOLLECTIONS_CONFIRM_FAVORITES_MERGE");
                                end,
                            },
                            favoritesMerge =
                            {
                                type = "execute",
                                name = L["Config.Wardrobe.FavoritesMerge"],
                                width = "full",
                                order = 126,
                                hidden = function() return ezCollections.Config.Wardrobe.PerCharacterFavorites; end,
                                func = function()
                                    StaticPopup_Hide("EZCOLLECTIONS_CONFIRM_FAVORITES_SPLIT");
                                    StaticPopup_Show("EZCOLLECTIONS_CONFIRM_FAVORITES_MERGE");
                                end,
                            },
                            favoritesSplit =
                            {
                                type = "execute",
                                name = L["Config.Wardrobe.FavoritesSplit"],
                                width = "full",
                                order = 127,
                                hidden = function() return not ezCollections.Config.Wardrobe.PerCharacterFavorites; end,
                                func = function()
                                    StaticPopup_Hide("EZCOLLECTIONS_CONFIRM_FAVORITES_MERGE");
                                    StaticPopup_Show("EZCOLLECTIONS_CONFIRM_FAVORITES_SPLIT");
                                end,
                            },
                            headerDressUp =
                            {
                                type = "header",
                                name = L["Config.Wardrobe.Misc.DressUp"],
                                order = 150,
                                hidden = function() return not IsAddOnLoaded("ezCollectionsDressUp"); end,
                            },
                            headerDressUpInactive =
                            {
                                type = "header",
                                name = L["Config.Wardrobe.Misc.DressUp.Inactive"],
                                order = 150,
                                hidden = function() return IsAddOnLoaded("ezCollectionsDressUp"); end,
                            },
                            dressUpClassBackground =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.DressUpClassBackground"],
                                desc = L["Config.Wardrobe.DressUpClassBackground.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 160,
                                disabled = function() return not IsAddOnLoaded("ezCollectionsDressUp"); end,
                                get = function(info) return ezCollections.Config.Wardrobe.DressUpClassBackground; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.DressUpClassBackground = value; if value then SetDressUpBackground(DressUpFrame, nil, select(2, UnitClass("player"))); else SetDressUpBackground(DressUpFrame, select(2, UnitRace("player"))); end end,
                            },
                            headerMounts = { type = "header", name = L["Config.Wardrobe.Misc.Mounts"], order = 179 },
                            mountsUnusableInZone =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.MountsUnusableInZone"],
                                desc = L["Config.Wardrobe.MountsUnusableInZone.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 180,
                                get = function(info) return ezCollections.Config.Wardrobe.MountsUnusableInZone; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.MountsUnusableInZone = value; ezCollections:RaiseEvent("MOUNT_JOURNAL_USABILITY_CHANGED"); end,
                            },
                            mountsShowHidden =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.MountsShowHidden"],
                                desc = L["Config.Wardrobe.MountsShowHidden.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 185,
                                get = function(info) return ezCollections.Config.Wardrobe.MountsShowHidden; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.MountsShowHidden = value; ezCollections:RaiseEvent("MOUNT_JOURNAL_USABILITY_CHANGED"); end,
                            },
                            headerMisc = { type = "header", name = L["Config.Wardrobe.Misc.Misc"], order = 189 },
                            portraitButton =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.PortraitButton"],
                                desc = L["Config.Wardrobe.PortraitButton.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 190,
                                get = function(info) return ezCollections.Config.Wardrobe.PortraitButton; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.PortraitButton = value; CollectionsJournalPortraitButton:UpdateVisibility(); WardrobeFramePortraitButton:UpdateVisibility(); end,
                            },
                            showWowheadSetIcon =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.ShowWowheadSetIcon"],
                                width = "full",
                                order = 200,
                                get = function(info) return ezCollections.Config.Wardrobe.ShowWowheadSetIcon; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.ShowWowheadSetIcon = value; ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED"); end,
                            },
                            showSetID =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.ShowSetID"],
                                width = "full",
                                order = 300,
                                get = function(info) return ezCollections.Config.Wardrobe.ShowSetID; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.ShowSetID = value; ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED"); end,
                            },
                            showItemID =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.ShowItemID"],
                                width = "full",
                                order = 400,
                                get = function(info) return ezCollections.Config.Wardrobe.ShowItemID; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.ShowItemID = value; end,
                            },
                            showCollectedVisualSourceText =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.ShowCollectedVisualSourceText"],
                                width = "full",
                                order = 500,
                                get = function(info) return ezCollections.Config.Wardrobe.ShowCollectedVisualSourceText; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.ShowCollectedVisualSourceText = value; end,
                            },
                            showCollectedVisualSources =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.ShowCollectedVisualSources"],
                                width = "full",
                                order = 600,
                                get = function(info) return ezCollections.Config.Wardrobe.ShowCollectedVisualSources; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.ShowCollectedVisualSources = value; end,
                            },
                        },
                    },
                    windows =
                    {
                        type = "group",
                        name = L["Config.Wardrobe.Windows"],
                        inline = true,
                        order = 75,
                        args =
                        {
                            closeWithEscape =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.CloseWithEscape"],
                                width = "full",
                                order = 100,
                                get = function(info) return ezCollections.Config.Wardrobe.WindowsCloseWithEscape; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.WindowsCloseWithEscape = value; updateWindows(); end,
                            },
                            strata =
                            {
                                type = "select",
                                name = L["Config.Wardrobe.Strata"],
                                order = 200,
                                values = windowStratas,
                                get = function(info) for k, v in ipairs(windowStratas) do if v == ezCollections.Config.Wardrobe.WindowsStrata then return k; end end end,
                                set = function(info, value) ezCollections.Config.Wardrobe.WindowsStrata = windowStratas[value]; updateWindows(); end,
                            },
                            clampToScreen =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.ClampToScreen"],
                                width = "full",
                                order = 300,
                                get = function(info) return ezCollections.Config.Wardrobe.WindowsClampToScreen; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.WindowsClampToScreen = value; updateWindows(); end,
                            },
                            lb1 = { type = "description", name = " ", order = 399 },
                            lockTransmogrify =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.LockTransmogrify"],
                                width = "full",
                                order = 400,
                                get = function(info) return ezCollections.Config.Wardrobe.WindowsLockTransmogrify; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.WindowsLockTransmogrify = value; updateWindows(ezCollections.Config.Wardrobe.WindowsLayoutTransmogrify); end,
                            },
                            layoutTransmogrify =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.LayoutTransmogrify"],
                                desc = L["Config.Wardrobe.LayoutTransmogrify.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 450,
                                disabled = function() return not ezCollections.Config.Wardrobe.WindowsLockTransmogrify; end,
                                get = function(info) return ezCollections.Config.Wardrobe.WindowsLayoutTransmogrify; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.WindowsLayoutTransmogrify = value; updateWindows(true); end,
                            },
                            etherealWindowSound =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.EtherealWindowSound"],
                                desc = L["Config.Wardrobe.EtherealWindowSound.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 475,
                                get = function(info) return ezCollections.Config.Wardrobe.EtherealWindowSound; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.EtherealWindowSound = value; end,
                            },
                            lb2 = { type = "description", name = " ", order = 499 },
                            lockCollections =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.LockCollections"],
                                width = "full",
                                order = 500,
                                get = function(info) return ezCollections.Config.Wardrobe.WindowsLockCollections; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.WindowsLockCollections = value; updateWindows(ezCollections.Config.Wardrobe.WindowsLayoutCollections); end,
                            },
                            layoutCollections =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.LayoutCollections"],
                                desc = L["Config.Wardrobe.LayoutCollections.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 550,
                                disabled = function() return not ezCollections.Config.Wardrobe.WindowsLockCollections; end,
                                get = function(info) return ezCollections.Config.Wardrobe.WindowsLayoutCollections; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.WindowsLayoutCollections = value; updateWindows(true); end,
                            },
                            lb3 = { type = "description", name = " ", order = 599 },
                            resetPositions =
                            {
                                type = "execute",
                                name = L["Config.Wardrobe.ResetPositions"],
                                order = 600,
                                func = function()
                                    WardrobeFrame:ClearAllPoints();
                                    WardrobeFrame:SetPoint("CENTER", UIParent, "CENTER");
                                    CollectionsJournal:ClearAllPoints();
                                    CollectionsJournal:SetPoint("CENTER", UIParent, "CENTER");
                                end,
                            },
                        },
                    },
                    cameras =
                    {
                        type = "group",
                        name = L["Config.Wardrobe.Cameras"],
                        inline = true,
                        order = 100,
                        args =
                        {
                            desc =
                            {
                                type = "description",
                                name = L["Config.Wardrobe.Cameras.Desc"],
                                order = 0,
                            },
                            option =
                            {
                                type = "select",
                                name = L["Config.Wardrobe.Cameras.Option"],
                                order = 100,
                                values = function()
                                    local values = { };
                                    for index, option in ipairs(ezCollections.CameraOptions) do
                                        values[option] = ezCollections:GetCameraOptionName(option);
                                    end
                                    return values;
                                end,
                                get = function(info)
                                    return ezCollections.Config.Wardrobe.CameraOption;
                                end,
                                set = function(info, value)
                                    ezCollections.Config.Wardrobe.CameraOption = value;
                                    ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
                                end,
                            },
                            popup =
                            {
                                type = "execute",
                                name = L["Config.Wardrobe.Cameras.Popup"],
                                order = 200,
                                func = function()
                                    HideUIPanel(InterfaceOptionsFrame);
                                    HideUIPanel(GameMenuFrame);
                                    StaticPopupSpecial_Show(ezCollectionsCameraPreviewPopup);
                                end,
                            },
                            panLimit =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.Cameras.PanLimit"],
                                width = "full",
                                order = 300,
                                get = function(info) return ezCollections.Config.Wardrobe.CameraPanLimit; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.CameraPanLimit = value; end,
                            },
                            zoomSpeed =
                            {
                                type = "range",
                                name = L["Config.Wardrobe.Cameras.ZoomSpeed"],
                                width = "full",
                                order = 350,
                                min = 0.01,
                                max = 1,
                                step = 0.01,
                                isPercent = true,
                                get = function(info) return ezCollections.Config.Wardrobe.CameraZoomSpeed; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.CameraZoomSpeed = value; end,
                            },
                            zoomSmooth =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.Cameras.ZoomSmooth"],
                                width = "full",
                                order = 400,
                                get = function(info) return ezCollections.Config.Wardrobe.CameraZoomSmooth; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.CameraZoomSmooth = value; end,
                            },
                            zoomSmoothSpeed =
                            {
                                type = "range",
                                name = L["Config.Wardrobe.Cameras.ZoomSmoothSpeed"],
                                width = "full",
                                order = 450,
                                min = 0.01,
                                max = 1,
                                step = 0.01,
                                isPercent = true,
                                disabled = function(info) return not ezCollections.Config.Wardrobe.CameraZoomSmooth; end,
                                get = function(info) return ezCollections.Config.Wardrobe.CameraZoomSmoothSpeed; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.CameraZoomSmoothSpeed = value; end,
                            },
                        },
                    },
                    microButtons =
                    {
                        type = "group",
                        name = L["Config.Wardrobe.MicroButtons"],
                        inline = true,
                        order = 200,
                        args =
                        {
                            desc =
                            {
                                type = "description",
                                name = L["Config.Wardrobe.MicroButtons.Desc"],
                                order = 0,
                            },
                            option =
                            {
                                type = "select",
                                name = L["Config.Wardrobe.MicroButtons.Option"],
                                width = "full",
                                order = 100,
                                values = function()
                                    local values = { };
                                    for id, data in ipairs(microButtonOptions) do
                                        values[id] = data[1];
                                    end
                                    return values;
                                end,
                                get = function(info) return ezCollections.Config.Wardrobe.MicroButtonsOption; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.MicroButtonsOption = value; setupCollectionsMicroButton(); end,
                            },
                            actionLMB =
                            {
                                type = "select",
                                name = L["Config.Wardrobe.MicroButtons.Action.LMB"],
                                order = 200,
                                disabled = function(info)
                                    return ezCollections.Config.Wardrobe.MicroButtonsOption == 1;
                                end,
                                values = function()
                                    local values = { };
                                    for id, data in pairs(microButtonActions) do
                                        if id == 0 then
                                            values[id] = L["Config.Wardrobe.MicroButtons.Action.Last"];
                                        elseif _G["CollectionsJournalTab"..id] and not _G["CollectionsJournalTab"..id].isDisabled then
                                            values[id] = format(L["Config.Wardrobe.MicroButtons.Action.Tab"], data);
                                        end
                                    end
                                    return values;
                                end,
                                get = function(info) return ezCollections.Config.Wardrobe.MicroButtonsActionLMB; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.MicroButtonsActionLMB = value; setupCollectionsMicroButton(); end,
                            },
                            actionRMB =
                            {
                                type = "select",
                                name = L["Config.Wardrobe.MicroButtons.Action.RMB"],
                                order = 201,
                                disabled = function(info)
                                    return ezCollections.Config.Wardrobe.MicroButtonsOption == 1;
                                end,
                                values = function()
                                    local values = { };
                                    for id, data in pairs(microButtonActions) do
                                        if id == 0 then
                                            values[id] = L["Config.Wardrobe.MicroButtons.Action.Last"];
                                        elseif _G["CollectionsJournalTab"..id] and not _G["CollectionsJournalTab"..id].isDisabled then
                                            values[id] = format(L["Config.Wardrobe.MicroButtons.Action.Tab"], data);
                                        end
                                    end
                                    return values;
                                end,
                                get = function(info) return ezCollections.Config.Wardrobe.MicroButtonsActionRMB; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.MicroButtonsActionRMB = value; setupCollectionsMicroButton(); end,
                            },
                            icon = (function()
                                local group =
                                {
                                    type = "group",
                                    name = L["Config.Wardrobe.MicroButtons.Icon"],
                                    inline = true,
                                    order = 300,
                                    disabled = function(info)
                                        return ezCollections.Config.Wardrobe.MicroButtonsOption == 1;
                                    end,
                                    args = { },
                                };
                                for id, data in pairs(microButtonIcons) do
                                    group.args["icon"..id] =
                                    {
                                        type = "input",
                                        name = microButtonIcons[id],
                                        width = "half",
                                        order = id,
                                        func = function() ezCollections.Config.Wardrobe.MicroButtonsIcon = id; setupCollectionsMicroButton(); end,
                                        dialogControl = "ezCollectionsOptionsMicroButtonIconTemplate",
                                    };
                                end
                                return group;
                            end)(),
                        },
                    },
                    minimapButtons =
                    {
                        type = "group",
                        name = L["Config.Wardrobe.MinimapButtons"],
                        inline = true,
                        order = 300,
                        args =
                        {
                            desc =
                            {
                                type = "description",
                                name = L["Config.Wardrobe.MinimapButtons.Desc"],
                                order = 0,
                            },
                            collections =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.MinimapButtons.Collections"],
                                width = "full",
                                order = 100,
                                get = function(info) return not ezCollections.Config.Wardrobe.MinimapButtonCollections.hide; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.MinimapButtonCollections.hide = not value; setupMinimapButtons(); end,
                            },
                            collectionsRMB =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.MinimapButtons.Collections.RMB"],
                                width = "full",
                                order = 101,
                                get = function(info) return ezCollections.Config.Wardrobe.MinimapButtonCollectionsRMB; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.MinimapButtonCollectionsRMB = value; end,
                            },
                            collectionsPos =
                            {
                                type = "range",
                                name = L["Config.Wardrobe.MinimapButtons.Collections.Pos"],
                                order = 102,
                                min = 0,
                                max = 360,
                                step = 1,
                                get = function(info) return ezCollections.Config.Wardrobe.MinimapButtonCollections.minimapPos or 205; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.MinimapButtonCollections.minimapPos = value; setupMinimapButtons(); end,
                            },
                            lb1 = { type = "description", name = " ", order = 199 },
                            transmogrify =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.MinimapButtons.Transmogrify"],
                                width = "full",
                                order = 200,
                                get = function(info) return not ezCollections.Config.Wardrobe.MinimapButtonTransmogrify.hide; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.MinimapButtonTransmogrify.hide = not value; setupMinimapButtons(); end,
                            },
                            transmogrifyRMB =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.MinimapButtons.Transmogrify.RMB"],
                                width = "full",
                                order = 201,
                                get = function(info) return ezCollections.Config.Wardrobe.MinimapButtonTransmogrifyRMB; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.MinimapButtonTransmogrifyRMB = value; end,
                            },
                            transmogrifyPos =
                            {
                                type = "range",
                                name = L["Config.Wardrobe.MinimapButtons.Transmogrify.Pos"],
                                order = 202,
                                min = 0,
                                max = 360,
                                step = 1,
                                get = function(info) return ezCollections.Config.Wardrobe.MinimapButtonTransmogrify.minimapPos or 225; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.MinimapButtonTransmogrify.minimapPos = value; setupMinimapButtons(); end,
                            },
                        },
                    },
                },
            },
            integration =
            {
                type = "group",
                name = L["Config.Integration"],
                args =
                {
                    alerts =
                    {
                        type = "group",
                        name = L["Config.Alerts"],
                        inline = true,
                        order = 100,
                        hidden = function() return ezCollections.NewVersion and ezCollections.NewVersion.Disabled; end,
                        args =
                        {
                            desc =
                            {
                                type = "description",
                                name = L["Config.Alerts.Desc"],
                                order = 0,
                            },
                            enable =
                            {
                                type = "toggle",
                                name = L["Config.Alerts.AddSkin.Enable"],
                                desc = L["Config.Alerts.AddSkin.Enable.Desc"],
                                width = "full",
                                order = 100,
                                get = function(info) return ezCollections.Config.Alerts.AddSkin.Enable; end,
                                set = function(info, value) ezCollections.Config.Alerts.AddSkin.Enable = value; end,
                            },
                            color =
                            {
                                type = "select",
                                name = L["Config.Alerts.AddSkin.Color"],
                                desc = L["Config.Alerts.AddSkin.Color.Desc"],
                                values = function()
                                    local values = { custom = L["Color.Custom"] };
                                    for k,v in pairs(PRESET_COLORS) do
                                        values[k] = v.Name;
                                    end
                                    return values;
                                end,
                                order = 101,
                                get = function(info)
                                    local color = ezCollections.Config.Alerts.AddSkin.Color;
                                    if not color.Custom then
                                        for k,v in pairs(PRESET_COLORS) do
                                            if v.r == color.r and
                                               v.g == color.g and
                                               v.b == color.b and
                                               v.a == color.a then
                                                return k;
                                            end
                                        end
                                    end
                                    return "custom";
                                end,
                                set = function(info, value)
                                    local color = ezCollections.Config.Alerts.AddSkin.Color;
                                    if value == "custom" then
                                        color.Custom = true;
                                    else
                                        color.Custom = false;
                                        color.r = PRESET_COLORS[value].r;
                                        color.g = PRESET_COLORS[value].g;
                                        color.b = PRESET_COLORS[value].b;
                                        color.a = PRESET_COLORS[value].a;
                                    end
                                end,
                                disabled = function() return not ezCollections.Config.Alerts.AddSkin.Enable; end,
                            },
                            customColor =
                            {
                                type = "color",
                                name = L["Config.Alerts.AddSkin.CustomColor"],
                                desc = L["Config.Alerts.AddSkin.CustomColor.Desc"],
                                width = "half",
                                order = 102,
                                get = function(info)             local color = ezCollections.Config.Alerts.AddSkin.Color; return color.r,     color.g,     color.b,     color.a;     end,
                                set = function(info, r, g, b, a) local color = ezCollections.Config.Alerts.AddSkin.Color;        color.r = r; color.g = g; color.b = b; color.a = a; end,
                                disabled = function() return not ezCollections.Config.Alerts.AddSkin.Enable or not ezCollections.Config.Alerts.AddSkin.Color.Custom; end,
                            },
                            fullRowColor =
                            {
                                type = "toggle",
                                name = L["Config.Alerts.AddSkin.FullRowColor"],
                                desc = L["Config.Alerts.AddSkin.FullRowColor.Desc"],
                                width = "half",
                                order = 103,
                                get = function(info) return ezCollections.Config.Alerts.AddSkin.FullRowColor; end,
                                set = function(info, value) ezCollections.Config.Alerts.AddSkin.FullRowColor = value; end,
                                disabled = function() return not ezCollections.Config.Alerts.AddSkin.Enable; end,
                            },
                        },
                    },
                    tooltipFlags =
                    {
                        type = "group",
                        name = L["Config.TooltipFlags"],
                        inline = true,
                        order = 150,
                        hidden = function() return ezCollections.NewVersion and ezCollections.NewVersion.Disabled; end,
                        args =
                        {
                            desc =
                            {
                                type = "description",
                                name = L["Config.TooltipFlags.Desc"],
                                order = 0,
                            },
                            enable =
                            {
                                type = "toggle",
                                name = L["Config.TooltipFlags.Enable"],
                                desc = L["Config.TooltipFlags.Enable.Desc"],
                                width = "full",
                                order = 1,
                                get = function(info) return ezCollections.Config.TooltipFlags.Enable; end,
                                set = function(info, value) ezCollections.Config.TooltipFlags.Enable = value; end,
                            },
                            color =
                            {
                                type = "select",
                                name = L["Config.TooltipFlags.Color"],
                                desc = L["Config.TooltipFlags.Color.Desc"],
                                values = function()
                                    local values = { custom = L["Color.Custom"] };
                                    for k,v in pairs(PRESET_COLORS) do
                                        values[k] = v.Name;
                                    end
                                    return values;
                                end,
                                order = 300,
                                get = function(info)
                                    local color = ezCollections.Config.TooltipFlags.Color;
                                    if not color.Custom then
                                        for k,v in pairs(PRESET_COLORS) do
                                            if v.r == color.r and
                                               v.g == color.g and
                                               v.b == color.b and
                                               v.a == color.a then
                                                return k;
                                            end
                                        end
                                    end
                                    return "custom";
                                end,
                                set = function(info, value)
                                    local color = ezCollections.Config.TooltipFlags.Color;
                                    if value == "custom" then
                                        color.Custom = true;
                                    else
                                        color.Custom = false;
                                        color.r = PRESET_COLORS[value].r;
                                        color.g = PRESET_COLORS[value].g;
                                        color.b = PRESET_COLORS[value].b;
                                        color.a = PRESET_COLORS[value].a;
                                    end
                                end,
                                disabled = function() return not ezCollections.Config.TooltipFlags.Enable; end,
                            },
                            customColor =
                            {
                                type = "color",
                                name = L["Config.TooltipFlags.CustomColor"],
                                desc = L["Config.TooltipFlags.CustomColor.Desc"],
                                order = 301,
                                get = function(info)             local color = ezCollections.Config.TooltipFlags.Color; return color.r,     color.g,     color.b,     color.a;     end,
                                set = function(info, r, g, b, a) local color = ezCollections.Config.TooltipFlags.Color;        color.r = r; color.g = g; color.b = b; color.a = a; end,
                                disabled = function() return not ezCollections.Config.TooltipFlags.Enable or not ezCollections.Config.TooltipFlags.Color.Custom; end,
                            },
                        },
                    },
                    tooltipTransmog =
                    {
                        type = "group",
                        name = L["Config.TooltipTransmog"],
                        inline = true,
                        order = 200,
                        hidden = function() return ezCollections.NewVersion and ezCollections.NewVersion.Disabled; end,
                        args =
                        {
                            desc =
                            {
                                type = "description",
                                name = L["Config.TooltipTransmog.Desc"],
                                order = 0,
                            },
                            enable =
                            {
                                type = "toggle",
                                name = L["Config.TooltipTransmog.Enable"],
                                desc = L["Config.TooltipTransmog.Enable.Desc"],
                                width = "full",
                                order = 1,
                                get = function(info) return ezCollections.Config.TooltipTransmog.Enable; end,
                                set = function(info, value) ezCollections.Config.TooltipTransmog.Enable = value; end,
                            },
                            iconEntry =
                            {
                                type = "toggle",
                                name = L["Config.TooltipTransmog.IconEntry"],
                                desc = L["Config.TooltipTransmog.IconEntry.Desc"],
                                width = "normal",
                                order = 100,
                                get = function(info) return ezCollections.Config.TooltipTransmog.IconEntry.Enable; end,
                                set = function(info, value) ezCollections.Config.TooltipTransmog.IconEntry.Enable = value; end,
                                disabled = function() return not ezCollections.Config.TooltipTransmog.Enable; end,
                            },
                            iconEntrySize =
                            {
                                type = "range",
                                name = L["Config.TooltipTransmog.IconEntry.Size"],
                                desc = L["Config.TooltipTransmog.IconEntry.Size.Desc"],
                                min = 0,
                                max = 64,
                                softMin = 8,
                                bigStep = 1,
                                width = "half",
                                order = 101,
                                get = function(info) return ezCollections.Config.TooltipTransmog.IconEntry.Size; end,
                                set = function(info, value) ezCollections.Config.TooltipTransmog.IconEntry.Size = value; end,
                                disabled = function() return not ezCollections.Config.TooltipTransmog.Enable or not ezCollections.Config.TooltipTransmog.IconEntry.Enable or ezCollections.Config.TooltipTransmog.IconEntry.Size == 0; end,
                            },
                            iconEntrySizeAuto =
                            {
                                type = "toggle",
                                name = L["Config.TooltipTransmog.IconEntry.Size.Auto"],
                                desc = L["Config.TooltipTransmog.IconEntry.Size.Auto.Desc"],
                                width = "half",
                                order = 102,
                                get = function(info) return ezCollections.Config.TooltipTransmog.IconEntry.Size == 0; end,
                                set = function(info, value) ezCollections.Config.TooltipTransmog.IconEntry.Size = value and 0 or 16; end,
                                disabled = function() return not ezCollections.Config.TooltipTransmog.Enable or not ezCollections.Config.TooltipTransmog.IconEntry.Enable; end,
                            },
                            lb1 = { type = "description", name = "", order = 102.5 },
                            iconEntryPadding1 =
                            {
                                type = "description",
                                name = "",
                                width = "normal",
                                order = 103,
                            },
                            iconEntryPadding2 =
                            {
                                type = "description",
                                name = "",
                                width = "half",
                                order = 104,
                            },
                            iconEntryCrop =
                            {
                                type = "toggle",
                                name = L["Config.TooltipTransmog.IconEntry.Crop"],
                                desc = L["Config.TooltipTransmog.IconEntry.Crop.Desc"],
                                width = "half",
                                order = 105,
                                get = function(info) return ezCollections.Config.TooltipTransmog.IconEntry.Crop; end,
                                set = function(info, value) ezCollections.Config.TooltipTransmog.IconEntry.Crop = value; end,
                                disabled = function() return not ezCollections.Config.TooltipTransmog.Enable or not ezCollections.Config.TooltipTransmog.IconEntry.Enable; end,
                            },
                            lb2 = { type = "description", name = "", order = 199 },
                            iconEnchant =
                            {
                                type = "toggle",
                                name = L["Config.TooltipTransmog.IconEnchant"],
                                desc = L["Config.TooltipTransmog.IconEnchant.Desc"],
                                width = "normal",
                                order = 200,
                                get = function(info) return ezCollections.Config.TooltipTransmog.IconEnchant.Enable; end,
                                set = function(info, value) ezCollections.Config.TooltipTransmog.IconEnchant.Enable = value; end,
                                disabled = function() return not ezCollections.Config.TooltipTransmog.Enable; end,
                            },
                            iconEnchantSize =
                            {
                                type = "range",
                                name = L["Config.TooltipTransmog.IconEnchant.Size"],
                                desc = L["Config.TooltipTransmog.IconEnchant.Size.Desc"],
                                min = 0,
                                max = 64,
                                softMin = 8,
                                bigStep = 1,
                                width = "half",
                                order = 201,
                                get = function(info) return ezCollections.Config.TooltipTransmog.IconEnchant.Size; end,
                                set = function(info, value) ezCollections.Config.TooltipTransmog.IconEnchant.Size = value; end,
                                disabled = function() return not ezCollections.Config.TooltipTransmog.Enable or not ezCollections.Config.TooltipTransmog.IconEnchant.Enable or ezCollections.Config.TooltipTransmog.IconEnchant.Size == 0; end,
                            },
                            iconEnchantSizeAuto =
                            {
                                type = "toggle",
                                name = L["Config.TooltipTransmog.IconEnchant.Size.Auto"],
                                desc = L["Config.TooltipTransmog.IconEnchant.Size.Auto.Desc"],
                                width = "half",
                                order = 202,
                                get = function(info) return ezCollections.Config.TooltipTransmog.IconEnchant.Size == 0; end,
                                set = function(info, value) ezCollections.Config.TooltipTransmog.IconEnchant.Size = value and 0 or 16; end,
                                disabled = function() return not ezCollections.Config.TooltipTransmog.Enable or not ezCollections.Config.TooltipTransmog.IconEnchant.Enable; end,
                            },
                            lb3 = { type = "description", name = "", order = 249 },
                            newHideVisualIcon =
                            {
                                type = "toggle",
                                name = L["Config.TooltipTransmog.NewHideVisualIcon"],
                                desc = L["Config.TooltipTransmog.NewHideVisualIcon.Desc"],
                                width = "full",
                                order = 250,
                                get = function(info) return ezCollections.Config.TooltipTransmog.NewHideVisualIcon; end,
                                set = function(info, value) ezCollections.Config.TooltipTransmog.NewHideVisualIcon = value; end,
                                disabled = function() return not ezCollections.Config.TooltipTransmog.Enable; end,
                            },
                            color =
                            {
                                type = "select",
                                name = L["Config.TooltipTransmog.Color"],
                                desc = L["Config.TooltipTransmog.Color.Desc"],
                                values = function()
                                    local values = { custom = L["Color.Custom"] };
                                    for k,v in pairs(PRESET_COLORS) do
                                        values[k] = v.Name;
                                    end
                                    return values;
                                end,
                                order = 300,
                                get = function(info)
                                    local color = ezCollections.Config.TooltipTransmog.Color;
                                    if not color.Custom then
                                        for k,v in pairs(PRESET_COLORS) do
                                            if v.r == color.r and
                                               v.g == color.g and
                                               v.b == color.b and
                                               v.a == color.a then
                                                return k;
                                            end
                                        end
                                    end
                                    return "custom";
                                end,
                                set = function(info, value)
                                    local color = ezCollections.Config.TooltipTransmog.Color;
                                    if value == "custom" then
                                        color.Custom = true;
                                    else
                                        color.Custom = false;
                                        color.r = PRESET_COLORS[value].r;
                                        color.g = PRESET_COLORS[value].g;
                                        color.b = PRESET_COLORS[value].b;
                                        color.a = PRESET_COLORS[value].a;
                                    end
                                end,
                                disabled = function() return not ezCollections.Config.TooltipTransmog.Enable; end,
                            },
                            customColor =
                            {
                                type = "color",
                                name = L["Config.TooltipTransmog.CustomColor"],
                                desc = L["Config.TooltipTransmog.CustomColor.Desc"],
                                order = 301,
                                get = function(info)             local color = ezCollections.Config.TooltipTransmog.Color; return color.r,     color.g,     color.b,     color.a;     end,
                                set = function(info, r, g, b, a) local color = ezCollections.Config.TooltipTransmog.Color;        color.r = r; color.g = g; color.b = b; color.a = a; end,
                                disabled = function() return not ezCollections.Config.TooltipTransmog.Enable or not ezCollections.Config.TooltipTransmog.Color.Custom; end,
                            },
                        },
                    },
                    tooltipSets =
                    {
                        type = "group",
                        name = L["Config.TooltipSets"],
                        inline = true,
                        order = 250,
                        hidden = function() return ezCollections.NewVersion and ezCollections.NewVersion.Disabled; end,
                        args =
                        {
                            desc =
                            {
                                type = "description",
                                name = L["Config.TooltipSets.Desc"],
                                order = 0,
                            },
                            collected =
                            {
                                type = "toggle",
                                name = L["Config.TooltipSets.Collected"],
                                desc = L["Config.TooltipSets.Collected.Desc"],
                                width = "full",
                                order = 100,
                                get = function(info) return ezCollections.Config.TooltipSets.Collected; end,
                                set = function(info, value) ezCollections.Config.TooltipSets.Collected = value; end,
                            },
                            uncollected =
                            {
                                type = "toggle",
                                name = L["Config.TooltipSets.Uncollected"],
                                desc = L["Config.TooltipSets.Uncollected.Desc"],
                                width = "full",
                                order = 200,
                                get = function(info) return ezCollections.Config.TooltipSets.Uncollected; end,
                                set = function(info, value) ezCollections.Config.TooltipSets.Uncollected = value; end,
                            },
                            color =
                            {
                                type = "select",
                                name = L["Config.TooltipSets.Color"],
                                desc = L["Config.TooltipSets.Color.Desc"],
                                values = function()
                                    local values = { custom = L["Color.Custom"] };
                                    for k,v in pairs(PRESET_COLORS) do
                                        values[k] = v.Name;
                                    end
                                    return values;
                                end,
                                order = 1000,
                                get = function(info)
                                    local color = ezCollections.Config.TooltipSets.Color;
                                    if not color.Custom then
                                        for k,v in pairs(PRESET_COLORS) do
                                            if v.r == color.r and
                                            v.g == color.g and
                                            v.b == color.b and
                                            v.a == color.a then
                                                return k;
                                            end
                                        end
                                    end
                                    return "custom";
                                end,
                                set = function(info, value)
                                    local color = ezCollections.Config.TooltipSets.Color;
                                    if value == "custom" then
                                        color.Custom = true;
                                    else
                                        color.Custom = false;
                                        color.r = PRESET_COLORS[value].r;
                                        color.g = PRESET_COLORS[value].g;
                                        color.b = PRESET_COLORS[value].b;
                                        color.a = PRESET_COLORS[value].a;
                                    end
                                end,
                            },
                            customColor =
                            {
                                type = "color",
                                name = L["Config.TooltipSets.CustomColor"],
                                desc = L["Config.TooltipSets.CustomColor.Desc"],
                                width = "half",
                                order = 1001,
                                get = function(info)             local color = ezCollections.Config.TooltipSets.Color; return color.r,     color.g,     color.b,     color.a;     end,
                                set = function(info, r, g, b, a) local color = ezCollections.Config.TooltipSets.Color;        color.r = r; color.g = g; color.b = b; color.a = a; end,
                                disabled = function() return not ezCollections.Config.TooltipSets.Color.Custom; end,
                            },
                            separator =
                            {
                                type = "toggle",
                                name = L["Config.TooltipSets.Separator"],
                                desc = L["Config.TooltipSets.Separator.Desc"],
                                width = "half",
                                order = 1002,
                                get = function(info) return ezCollections.Config.TooltipSets.Separator; end,
                                set = function(info, value) ezCollections.Config.TooltipSets.Separator = value; end,
                            },
                        },
                    },
                    tooltipCollection =
                    {
                        type = "group",
                        name = L["Config.TooltipCollection"],
                        inline = true,
                        order = 300,
                        hidden = function() return ezCollections.NewVersion and ezCollections.NewVersion.Disabled; end,
                        args =
                        {
                            desc =
                            {
                                type = "description",
                                name = L["Config.TooltipCollection.Desc"],
                                order = 0,
                            },
                            ownedItems =
                            {
                                type = "toggle",
                                name = L["Config.TooltipCollection.OwnedItems"],
                                desc = L["Config.TooltipCollection.OwnedItems.Desc"],
                                width = "full",
                                order = 100,
                                get = function(info) return ezCollections.Config.TooltipCollection.OwnedItems; end,
                                set = function(info, value) ezCollections.Config.TooltipCollection.OwnedItems = value; end,
                                hidden = function() return not ezCollections.Collections.OwnedItems.Enabled; end,
                            },
                            skins =
                            {
                                type = "toggle",
                                name = L["Config.TooltipCollection.Skins"],
                                desc = L["Config.TooltipCollection.Skins.Desc"],
                                width = "full",
                                order = 200,
                                get = function(info) return ezCollections.Config.TooltipCollection.Skins; end,
                                set = function(info, value) ezCollections.Config.TooltipCollection.Skins = value; end,
                                hidden = function() return not ezCollections.Collections.Skins.Enabled; end,
                            },
                            skinUnlock =
                            {
                                type = "toggle",
                                name = L["Config.TooltipCollection.SkinUnlock"],
                                desc = L["Config.TooltipCollection.SkinUnlock.Desc"],
                                order = 201,
                                get = function(info) return ezCollections.Config.TooltipCollection.SkinUnlock; end,
                                set = function(info, value) ezCollections.Config.TooltipCollection.SkinUnlock = value; end,
                                hidden = function() return not ezCollections.Collections.Skins.Enabled; end,
                            },
                            skinUnlockBinding =
                            {
                                type = "keybinding",
                                name = L["Config.TooltipCollection.SkinUnlock.Binding"],
                                desc = L["Config.TooltipCollection.SkinUnlock.Binding.Desc"],
                                order = 202,
                                handler = keybindHandler,
                                arg = "EZCOLLECTIONS_UNLOCK_SKIN",
                                get = "Get",
                                set = "Set",
                                hidden = function() return not ezCollections.Collections.Skins.Enabled; end,
                            },
                            lb1 = { type = "description", name = "", order = 299 },
                            takenQuests =
                            {
                                type = "toggle",
                                name = L["Config.TooltipCollection.TakenQuests"],
                                desc = L["Config.TooltipCollection.TakenQuests.Desc"],
                                width = "full",
                                order = 300,
                                get = function(info) return ezCollections.Config.TooltipCollection.TakenQuests; end,
                                set = function(info, value) ezCollections.Config.TooltipCollection.TakenQuests = value; end,
                                hidden = function() return not ezCollections.Collections.TakenQuests.Enabled; end,
                            },
                            rewardedQuests =
                            {
                                type = "toggle",
                                name = L["Config.TooltipCollection.RewardedQuests"],
                                desc = L["Config.TooltipCollection.RewardedQuests.Desc"],
                                width = "full",
                                order = 400,
                                get = function(info) return ezCollections.Config.TooltipCollection.RewardedQuests; end,
                                set = function(info, value) ezCollections.Config.TooltipCollection.RewardedQuests = value; end,
                                hidden = function() return not ezCollections.Collections.RewardedQuests.Enabled; end,
                            },
                            color =
                            {
                                type = "select",
                                name = L["Config.TooltipCollection.Color"],
                                desc = L["Config.TooltipCollection.Color.Desc"],
                                values = function()
                                    local values = { custom = L["Color.Custom"] };
                                    for k,v in pairs(PRESET_COLORS) do
                                        values[k] = v.Name;
                                    end
                                    return values;
                                end,
                                order = 1000,
                                get = function(info)
                                    local color = ezCollections.Config.TooltipCollection.Color;
                                    if not color.Custom then
                                        for k,v in pairs(PRESET_COLORS) do
                                            if v.r == color.r and
                                               v.g == color.g and
                                               v.b == color.b and
                                               v.a == color.a then
                                                return k;
                                            end
                                        end
                                    end
                                    return "custom";
                                end,
                                set = function(info, value)
                                    local color = ezCollections.Config.TooltipCollection.Color;
                                    if value == "custom" then
                                        color.Custom = true;
                                    else
                                        color.Custom = false;
                                        color.r = PRESET_COLORS[value].r;
                                        color.g = PRESET_COLORS[value].g;
                                        color.b = PRESET_COLORS[value].b;
                                        color.a = PRESET_COLORS[value].a;
                                    end
                                end,
                            },
                            customColor =
                            {
                                type = "color",
                                name = L["Config.TooltipCollection.CustomColor"],
                                desc = L["Config.TooltipCollection.CustomColor.Desc"],
                                width = "half",
                                order = 1001,
                                get = function(info)             local color = ezCollections.Config.TooltipCollection.Color; return color.r,     color.g,     color.b,     color.a;     end,
                                set = function(info, r, g, b, a) local color = ezCollections.Config.TooltipCollection.Color;        color.r = r; color.g = g; color.b = b; color.a = a; end,
                                disabled = function() return not ezCollections.Config.TooltipCollection.Color.Custom; end,
                            },
                            separator =
                            {
                                type = "toggle",
                                name = L["Config.TooltipCollection.Separator"],
                                desc = L["Config.TooltipCollection.Separator.Desc"],
                                width = "half",
                                order = 1002,
                                get = function(info) return ezCollections.Config.TooltipCollection.Separator; end,
                                set = function(info, value) ezCollections.Config.TooltipCollection.Separator = value; end,
                            },
                        },
                    },
                    restoreItemIcons =
                    {
                        type = "group",
                        name = L["Config.RestoreItemIcons"],
                        inline = true,
                        order = 400,
                        hidden = function() return ezCollections.NewVersion and ezCollections.NewVersion.Disabled; end,
                        args =
                        {
                            desc =
                            {
                                type = "description",
                                name = L["Config.RestoreItemIcons.Desc"],
                                order = 0,
                            },
                            equipment =
                            {
                                type = "toggle",
                                name = L["Config.RestoreItemIcons.Equipment"],
                                desc = L["Config.RestoreItemIcons.Equipment.Desc"],
                                width = "full",
                                order = 100,
                                get = function(info) return ezCollections.Config.RestoreItemIcons.Equipment; end,
                                set = function(info, value) ezCollections.Config.RestoreItemIcons.Equipment = value; reloadUINeeded = true; end,
                            },
                            equipmentManager =
                            {
                                type = "toggle",
                                name = L["Config.RestoreItemIcons.EquipmentManager"],
                                desc = L["Config.RestoreItemIcons.EquipmentManager.Desc"],
                                width = "full",
                                order = 150,
                                disabled = function() return not ezCollections.Config.RestoreItemIcons.Equipment; end,
                                get = function(info) return ezCollections.Config.RestoreItemIcons.EquipmentManager; end,
                                set = function(info, value) ezCollections.Config.RestoreItemIcons.EquipmentManager = value; reloadUINeeded = true; end,
                            },
                            inspect =
                            {
                                type = "toggle",
                                name = L["Config.RestoreItemIcons.Inspect"],
                                desc = L["Config.RestoreItemIcons.Inspect.Desc"],
                                width = "full",
                                order = 200,
                                get = function(info) return ezCollections.Config.RestoreItemIcons.Inspect; end,
                                set = function(info, value) ezCollections.Config.RestoreItemIcons.Inspect = value; reloadUINeeded = true; end,
                            },
                            global =
                            {
                                type = "toggle",
                                name = L["Config.RestoreItemIcons.Global"],
                                desc = L["Config.RestoreItemIcons.Global.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 900,
                                disabled = function() return not ezCollections.Config.RestoreItemIcons.Equipment and not ezCollections.Config.RestoreItemIcons.Inspect; end,
                                get = function(info) return ezCollections.Config.RestoreItemIcons.Global; end,
                                set = function(info, value) ezCollections.Config.RestoreItemIcons.Global = value; reloadUINeeded = true; end,
                            },
                            reload =
                            {
                                type = "execute",
                                name = L["Config.RestoreItemIcons.ReloadUI"],
                                desc = L["Config.RestoreItemIcons.ReloadUI.Desc"],
                                order = 1000,
                                hidden = function() return not reloadUINeeded; end,
                                func = function() ReloadUI(); end,
                            },
                        },
                    },
                    restoreItemSets =
                    {
                        type = "group",
                        name = L["Config.RestoreItemSets"],
                        inline = true,
                        order = 401,
                        hidden = function() return ezCollections.NewVersion and ezCollections.NewVersion.Disabled; end,
                        args =
                        {
                            desc =
                            {
                                type = "description",
                                name = L["Config.RestoreItemSets.Desc"],
                                order = 0,
                            },
                            equipment =
                            {
                                type = "toggle",
                                name = L["Config.RestoreItemSets.Equipment"],
                                desc = L["Config.RestoreItemSets.Equipment.Desc"],
                                width = "full",
                                order = 100,
                                get = function(info) return ezCollections.Config.RestoreItemSets.Equipment; end,
                                set = function(info, value) ezCollections.Config.RestoreItemSets.Equipment = value; end,
                            },
                            inspect =
                            {
                                type = "toggle",
                                name = L["Config.RestoreItemSets.Inspect"],
                                desc = L["Config.RestoreItemSets.Inspect.Desc"],
                                width = "full",
                                order = 200,
                                get = function(info) return ezCollections.Config.RestoreItemSets.Inspect; end,
                                set = function(info, value) ezCollections.Config.RestoreItemSets.Inspect = value; end,
                            },
                        },
                    },
                },
            },
            bindings =
            {
                type = "group",
                name = L["Config.Bindings"],
                args =
                {
                    bindings =
                    {
                        type = "group",
                        name = L["Config.Bindings"],
                        inline = true,
                        args =
                        {
                            desc =
                            {
                                type = "description",
                                name = L["Config.Bindings.Desc"],
                                order = 0,
                            },
                            skinUnlockDesc =
                            {
                                type = "description",
                                name = L["Binding.UnlockSkin"],
                                width = "normal",
                                order = 100,
                            },
                            skinUnlock =
                            {
                                type = "keybinding",
                                name = "",
                                order = 101,
                                handler = keybindHandler,
                                arg = "EZCOLLECTIONS_UNLOCK_SKIN",
                                get = "Get",
                                set = "Set",
                            },
                            lb1 = { type = "description", name = "", order = 198 },
                            headerIsengard = { type = "header", name = L["Binding.Header.Isengard"], order = 199 },
                            menuIsengardDesc =
                            {
                                type = "description",
                                name = L["Binding.Menu.Isengard"],
                                width = "normal",
                                order = 200,
                            },
                            menuIsengard =
                            {
                                type = "keybinding",
                                name = "",
                                order = 201,
                                handler = keybindHandler,
                                arg = "EZCOLLECTIONS_MENU_ISENGARD",
                                get = "Get",
                                set = "Set",
                            },
                            lb2 = { type = "description", name = "", order = 299 },
                            menuTransmogDesc =
                            {
                                type = "description",
                                name = L["Binding.Menu.Transmog"],
                                width = "normal",
                                order = 300,
                            },
                            menuTransmog =
                            {
                                type = "keybinding",
                                name = "",
                                order = 301,
                                handler = keybindHandler,
                                arg = "EZCOLLECTIONS_MENU_TRANSMOG",
                                get = "Get",
                                set = "Set",
                            },
                            lb3 = { type = "description", name = "", order = 349 },
                            menuTransmogSetsDesc =
                            {
                                type = "description",
                                name = L["Binding.Menu.Transmog.Sets"],
                                width = "normal",
                                order = 350,
                            },
                            menuTransmogSets =
                            {
                                type = "keybinding",
                                name = "",
                                order = 351,
                                handler = keybindHandler,
                                arg = "EZCOLLECTIONS_MENU_TRANSMOG_SETS",
                                get = "Get",
                                set = "Set",
                            },
                            lb4 = { type = "description", name = "", order = 399 },
                            menuCollectionsDesc =
                            {
                                type = "description",
                                name = L["Binding.Menu.Collections"],
                                width = "normal",
                                order = 400,
                            },
                            menuCollections =
                            {
                                type = "keybinding",
                                name = "",
                                order = 401,
                                handler = keybindHandler,
                                arg = "EZCOLLECTIONS_MENU_COLLECTIONS",
                                get = "Get",
                                set = "Set",
                            },
                            lb5 = { type = "description", name = "", order = 499 },
                            menuDailyDesc =
                            {
                                type = "description",
                                name = L["Binding.Menu.Daily"],
                                width = "normal",
                                order = 500,
                            },
                            menuDaily =
                            {
                                type = "keybinding",
                                name = "",
                                order = 501,
                                handler = keybindHandler,
                                arg = "EZCOLLECTIONS_MENU_DAILY",
                                get = "Get",
                                set = "Set",
                            },
                            lb6 = { type = "description", name = "", order = 598 },
                            headerWardrobe = { type = "header", name = L["Binding.Header.Wardrobe"], order = 599 },
                            collectionsDesc =
                            {
                                type = "description",
                                name = BINDING_NAME_TOGGLECOLLECTIONS,
                                width = "normal",
                                order = 600,
                            },
                            collections =
                            {
                                type = "keybinding",
                                name = "",
                                order = 601,
                                handler = keybindHandler,
                                arg = "TOGGLECOLLECTIONS",
                                get = "Get",
                                set = "Set",
                            },
                            lb7 = { type = "description", name = "", order = 699 },
                            mountsDesc =
                            {
                                type = "description",
                                name = BINDING_NAME_TOGGLECOLLECTIONSMOUNTJOURNAL,
                                width = "normal",
                                order = 700,
                            },
                            mounts =
                            {
                                type = "keybinding",
                                name = "",
                                order = 701,
                                handler = keybindHandler,
                                arg = "TOGGLECOLLECTIONSMOUNTJOURNAL",
                                get = "Get",
                                set = "Set",
                            },
                            lb8 = { type = "description", name = "", order = 799 },
                            petsDesc =
                            {
                                type = "description",
                                name = BINDING_NAME_TOGGLECOLLECTIONSPETJOURNAL,
                                width = "normal",
                                order = 800,
                            },
                            pets =
                            {
                                type = "keybinding",
                                name = "",
                                order = 801,
                                handler = keybindHandler,
                                arg = "TOGGLECOLLECTIONSPETJOURNAL",
                                get = "Get",
                                set = "Set",
                            },
                            lb9 = { type = "description", name = "", order = 899 },
                            --[[
                            toyboxDesc =
                            {
                                type = "description",
                                name = BINDING_NAME_TOGGLECOLLECTIONSTOYBOX,
                                width = "normal",
                                order = 900,
                            },
                            toybox =
                            {
                                type = "keybinding",
                                name = "",
                                order = 901,
                                handler = keybindHandler,
                                arg = "TOGGLECOLLECTIONSTOYBOX",
                                get = "Get",
                                set = "Set",
                            },
                            lb10 = { type = "description", name = "", order = 999 },
                            heirloomsDesc =
                            {
                                type = "description",
                                name = BINDING_NAME_TOGGLECOLLECTIONSHEIRLOOM,
                                width = "normal",
                                order = 1000,
                            },
                            heirlooms =
                            {
                                type = "keybinding",
                                name = "",
                                order = 1001,
                                handler = keybindHandler,
                                arg = "TOGGLECOLLECTIONSHEIRLOOM",
                                get = "Get",
                                set = "Set",
                            },
                            lb11 = { type = "description", name = "", order = 1099 },
                            ]]
                            appearancesDesc =
                            {
                                type = "description",
                                name = BINDING_NAME_TOGGLECOLLECTIONSWARDROBE,
                                width = "normal",
                                order = 1100,
                            },
                            appearances =
                            {
                                type = "keybinding",
                                name = "",
                                order = 1101,
                                handler = keybindHandler,
                                arg = "TOGGLECOLLECTIONSWARDROBE",
                                get = "Get",
                                set = "Set",
                            },
                            lb12 = { type = "description", name = "", order = 1199 },
                            transmogrifyDesc =
                            {
                                type = "description",
                                name = BINDING_NAME_TOGGLETRANSMOGRIFY,
                                width = "normal",
                                order = 1200,
                            },
                            transmogrify =
                            {
                                type = "keybinding",
                                name = "",
                                order = 1201,
                                handler = keybindHandler,
                                arg = "TOGGLETRANSMOGRIFY",
                                get = "Get",
                                set = "Set",
                            },
                        },
                    },
                },
            },
        },
    };
    LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME, configTable);
    panelGeneral     = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME, nil, nil, 'general');
    panelWardrobe    = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME, configTable.args.wardrobe.name, ADDON_NAME, 'wardrobe');
    panelIntegration = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME, configTable.args.integration.name, ADDON_NAME, 'integration');
    panelBindings    = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME, configTable.args.bindings.name, ADDON_NAME, 'bindings');

    StaticPopupDialogs["EZCOLLECTIONS_ERROR"] =
    {
        text = L["Popup.Error"],
        button1 = OKAY,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
        hideOnEnter = 1,
    };
    StaticPopupDialogs["EZCOLLECTIONS_ERROR_RELOADUI"] =
    {
        text = L["Popup.Error"],
        button1 = L["Popup.Error.ReloadUI"],
        button2 = CLOSE,
        OnAccept = function(self)
            ReloadUI();
        end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
        hideOnEnter = 1,
    };
    StaticPopupDialogs["EZCOLLECTIONS_NEW_VERSION"] =
    {
        text = "",
        button1 = OKAY,
        hasEditBox = 1,
        OnShow = function(self)
            self.text:SetText(format(ezCollections.NewVersion.Disabled and L["Popup.NewVersion.Disabled"] or ezCollections.NewVersion.Outdated and L["Popup.NewVersion.Outdated"] or L["Popup.NewVersion.Compatible"], ezCollections.NewVersion.Version));
            if ezCollections.NewVersion.Disabled then
                self.editBox:Hide();
            else
                self.editBox:SetText(ezCollections.NewVersion.URL);
                self.editBox:SetFocus();
                self.editBox:HighlightText();
            end
        end,
        EditBoxOnEnterPressed = function(self, data)
            self:GetParent():Hide();
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide();
        end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
        hideOnEnter = 1,
        showAlert = 1,
    };
    StaticPopupDialogs["EZCOLLECTIONS_CONFIRM_CACHE_RESET"] =
    {
        text = L["Popup.Confirm.CacheReset"],
        button1 = YES,
        button2 = NO,
        OnAccept = function(self)
            ezCollections:ClearCache();
            ReloadUI();
        end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
    };
    StaticPopupDialogs["EZCOLLECTIONS_CONFIRM_CONFIG_RESET"] =
    {
        text = L["Popup.Confirm.ConfigReset"],
        button1 = YES,
        button2 = NO,
        OnAccept = function(self)
            config:ResetProfile();
            WardrobeFrame:SetUserPlaced(false);
            CollectionsJournal:SetUserPlaced(false);
            ReloadUI();
        end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
    };
    StaticPopupDialogs["EZCOLLECTIONS_CONFIRM_FAVORITES_MERGE"] =
    {
        text = L["Popup.Confirm.FavoritesMerge"],
        button1 = YES,
        button2 = NO,
        OnAccept = function(self)
            for key, container in pairs(ezCollections.Config.TransmogCollection.PerCharacter) do
                if key ~= "*" then
                    for id, fav in pairs(container.Favorites) do
                        if fav then
                            ezCollections.Config.TransmogCollection.Favorites[id] = true;
                        end
                    end
                    for id, fav in pairs(container.SetFavorites) do
                        if fav then
                            ezCollections.Config.TransmogCollection.SetFavorites[id] = true;
                        end
                    end
                end
            end
            ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
            ezCollections:RaiseEvent("TRANSMOG_SETS_UPDATE_FAVORITE");
        end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
    };
    StaticPopupDialogs["EZCOLLECTIONS_CONFIRM_FAVORITES_SPLIT"] =
    {
        text = L["Popup.Confirm.FavoritesSplit"],
        button1 = YES,
        button2 = NO,
        OnAccept = function(self)
            for key, container in pairs(ezCollections.Config.TransmogCollection.PerCharacter) do
                if key ~= "*" then
                    for id, fav in pairs(ezCollections.Config.TransmogCollection.Favorites) do
                        if fav then
                            container.Favorites[id] = true;
                        end
                    end
                    for id, fav in pairs(ezCollections.Config.TransmogCollection.SetFavorites) do
                        if fav then
                            container.SetFavorites[id] = true;
                        end
                    end
                end
            end
            ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
            ezCollections:RaiseEvent("TRANSMOG_SETS_UPDATE_FAVORITE");
        end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
    };
    StaticPopupDialogs["EZCOLLECTIONS_UNLOCK_SKIN"] =
    {
        text = "",
        button1 = YES,
        button2 = NO,
        OnShow = function(self)
            self.text:SetText(format(L["Popup.UnlockSkin"], StaticPopupDialogs["EZCOLLECTIONS_UNLOCK_SKIN"].itemLink));
        end,
        OnAccept = function(self)
            ezCollections:SendAddonMessage( "UNLOCKSKIN:"..StaticPopupDialogs["EZCOLLECTIONS_UNLOCK_SKIN"].commandData);
        end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
        itemLink = nil,
        commandData = nil,
    };
    StaticPopupDialogs["EZCOLLECTIONS_KEYBINDING_ERROR"] =
    {
        text = "",
        button1 = OKAY,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
    };
    StaticPopupDialogs["EZCOLLECTIONS_PRELOADING_ITEM_CACHE"] =
    {
        text = L["Popup.PreloadingItemCache"],
        OnShow = function(self)
            local bar = StaticPopupDialogs["EZCOLLECTIONS_PRELOADING_ITEM_CACHE"].progressBar;
            bar:SetParent(self);
            bar:SetPoint("BOTTOM", self, "BOTTOM", 0, 22);
            bar:SetWidth(math.floor(self:GetWidth() * 0.75));
            bar:SetMinMaxValues(0, 1);
            bar:SetValue(0);
            bar:Show();
            bar:SetScript("OnEvent", function(self, event, current, total)
                self:SetMinMaxValues(0, total);
                self:SetValue(current);
                self.text:SetText(format("%d / %d", current, total));
                if current >= total then
                    StaticPopup_Hide("EZCOLLECTIONS_PRELOADING_ITEM_CACHE");
                end
            end);
            ezCollections:RegisterEvent(bar, "EZCOLLECTIONS_PRELOAD_ITEM_CACHE_PROGRESS");
        end,
        OnHide = function(self)
            local bar = StaticPopupDialogs["EZCOLLECTIONS_PRELOADING_ITEM_CACHE"].progressBar;
            bar:Hide();
            bar:SetParent(nil);
            ezCollections:UnregisterEvent(bar, "EZCOLLECTIONS_PRELOAD_ITEM_CACHE_PROGRESS");
        end,
        timeout = 0,
        whileDead = 1,
        progressBar = CreateFrame("StatusBar", "ezCollectionsItemCacheProgressBar", nil, "ezCollectionsProgressBarTemplate"),
    };
    StaticPopupDialogs["EZCOLLECTIONS_PRELOADING_MOUNT_CACHE"] =
    {
        text = L["Popup.PreloadingMountCache"],
        OnShow = function(self)
            local bar = StaticPopupDialogs["EZCOLLECTIONS_PRELOADING_MOUNT_CACHE"].progressBar;
            bar:SetParent(self);
            bar:SetPoint("BOTTOM", self, "BOTTOM", 0, 22);
            bar:SetWidth(math.floor(self:GetWidth() * 0.75));
            bar:SetMinMaxValues(0, 1);
            bar:SetValue(0);
            bar:Show();
            bar:SetScript("OnEvent", function(self, event, current, total)
                self:SetMinMaxValues(0, total);
                self:SetValue(current);
                self.text:SetText(format("%d / %d", current, total));
                if current >= total then
                    StaticPopup_Hide("EZCOLLECTIONS_PRELOADING_MOUNT_CACHE");
                end
            end);
            ezCollections:RegisterEvent(bar, "EZCOLLECTIONS_PRELOAD_MOUNT_CACHE_PROGRESS");
        end,
        OnHide = function(self)
            local bar = StaticPopupDialogs["EZCOLLECTIONS_PRELOADING_MOUNT_CACHE"].progressBar;
            bar:Hide();
            bar:SetParent(nil);
            ezCollections:UnregisterEvent(bar, "EZCOLLECTIONS_PRELOAD_MOUNT_CACHE_PROGRESS");
        end,
        timeout = 0,
        whileDead = 1,
        progressBar = CreateFrame("StatusBar", "ezCollectionsMountCacheProgressBar", nil, "ezCollectionsProgressBarTemplate"),
    };
    StaticPopupDialogs["EZCOLLECTIONS_STORE_URL"] =
    {
        text = L["Popup.StoreURL"],
        button1 = OKAY,
        hasEditBox = 1,
        OnShow = function(self, data)
            self.editBox:SetText(data);
            self.editBox:SetFocus();
            self.editBox:HighlightText();
        end,
        EditBoxOnEnterPressed = function(self)
            self:GetParent():Hide();
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide();
        end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
        hideOnEnter = 1,
    };
    StaticPopupDialogs["EZCOLLECTIONS_MOUNT_MACRO_CREATE"] =
    {
        text = L["Popup.Mount.Macro.Create"],
        button1 = YES,
        button2 = NO,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
    };
    StaticPopupDialogs["EZCOLLECTIONS_MOUNT_MACRO_PERCHARACTER"] =
    {
        text = L["Popup.Mount.Macro.PerCharacter"],
        button1 = OKAY,
        button2 = CANCEL,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
    };
    StaticPopupDialogs["EZCOLLECTIONS_PET_MACRO_CREATE"] =
    {
        text = L["Popup.Pet.Macro.Create"],
        button1 = YES,
        button2 = NO,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
    };
    StaticPopupDialogs["EZCOLLECTIONS_PET_MACRO_PERCHARACTER"] =
    {
        text = L["Popup.Pet.Macro.PerCharacter"],
        button1 = OKAY,
        button2 = CANCEL,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
    };

    ezCollections:InitDropDownMenus(); -- Taint avoidance

    if ezCollections.Config.RestoreItemIcons.Equipment or ezCollections.Config.RestoreItemIcons.Inspect then
        self:HookRestoreItemIcons();
    end

    if dressUpAddonDisabled then
        StaticPopup_Show("EZCOLLECTIONS_ERROR_RELOADUI", L["Popup.Error.Compatibility.ElvUI.DressUp"]);
    end

    PanelTemplates_SetTab(CollectionsJournal, tonumber(ezCollections:GetCVar("petJournalTab")) or 5);
end

-- ----------------
-- Helper functions
-- ----------------
local function RGBPercToHex(r, g, b)
    r = r <= 1 and r >= 0 and r or 0
    g = g <= 1 and g >= 0 and g or 0
    b = b <= 1 and b >= 0 and b or 0
    return string.format("%02X%02X%02X", r*255, g*255, b*255)
end
local function IsSameColor(color, r, g, b)
    return abs(color[1] - r) <= 0.01
       and abs(color[2] - g) <= 0.01
       and abs(color[3] - b) <= 0.01;
end
local function FormatToPattern(format)
    return (format:gsub("%(", "%%("):gsub("%)", "%%)"):gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)"):gsub("|4(.+):%1.+:%1.+;", "%1.-"):gsub("|4(.+);", ".-"));
end
local function starts_with(str, start)
   return str:sub(1, #start) == start
end
local function ends_with(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end
local function match(str, prefix, callback)
    if starts_with(str, prefix) then
        callback(str:sub(#prefix + 1));
        return true;
    end
    return false;
end
local function deepcopy(orig)
    if type(orig) == 'table' then
        local copy = { };
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
        return copy;
    else
        return orig;
    end
end
local function GetItemID(item)
    if type(item) == "number" then
        return item;
    else
        local _, link = GetItemInfo(item);
        local _, id, _ = strsplit(":", link);
        return tonumber(id);
    end
end

-- -----------------
-- Main core and API
-- -----------------
ezCollections =
{
    Name = ADDON_NAME,
    Version = ADDON_VERSION,
    AceAddon = addon,
    L = L,
    Config = nil,
    Cache = nil,
    ClearCache = nil,
    Allowed = false,
    Token = nil,
    HideVisualSlots = { },
    WeaponCompatibility = { },
    ClassIDToName = CLASS_ID_TO_NAME,
    ClassNameToID = (function() local tbl = { }; for id, name in ipairs(CLASS_ID_TO_NAME) do tbl[name] = id; end return tbl; end)(),
    RaceIDToName = RACE_ID_TO_NAME,
    RaceNameToID = (function() local tbl = { }; for id, name in ipairs(RACE_ID_TO_NAME) do tbl[name] = id; end return tbl; end)(),
    RaceNameToFaction = { HUMAN = FACTION_ALLIANCE, DWARF = FACTION_ALLIANCE, NIGHTELF = FACTION_ALLIANCE, GNOME = FACTION_ALLIANCE, DRAENEI = FACTION_ALLIANCE, ORC = FACTION_HORDE, UNDEAD = FACTION_HORDE, TAUREN = FACTION_HORDE, TROLL = FACTION_HORDE, BLOODELF = FACTION_HORDE, ANY = FACTION_OTHER },
    RaceSortOrder = { "HUMAN", "DWARF", "NIGHTELF", "GNOME", "DRAENEI", "ORC", "UNDEAD", "TAUREN", "TROLL", "BLOODELF" },
    RGBPercToHex = RGBPercToHex,
    TransmogrifiableSlots = TRANSMOGRIFIABLE_SLOTS,

    -- Communications
    NewVersion = nil,
    SendAddonMessage = function(self, msg)
        SendAddonMessage(ADDON_PREFIX, msg, "WHISPER", UnitName("player"));
    end,
    SendAddonCommand = function(self, msg)
        SendAddonMessage(msg.." ", "", "WHISPER", UnitName("player"));
    end,
    Encode = function(self, str)
        return str:gsub(":", "\1"):gsub(",", "\2");
    end,
    Decode = function(self, str)
        return str:gsub("\1", ":"):gsub("\2", ",");
    end,

    -- Collections
    Collections =
    {
        OwnedItems = { },
        Skins = { },
        TakenQuests = { },
        RewardedQuests = { },
    },
    IsSkinSource     = function(self, item)  local db = self.Cache.All;                  if                   not db.Loaded then return nil; end return db[GetItemID(item)] and true or false; end,
    HasOwnedItem     = function(self, item)  local db = self.Collections.OwnedItems;     if not db.Enabled or not db.Loaded then return nil; end return db[GetItemID(item)] or false; end,
    HasSkin          = function(self, item)  local db = self.Collections.Skins;          if not db.Enabled or not db.Loaded then return nil; end return db[GetItemID(item)] or false; end,
    HasTakenQuest    = function(self, quest) local db = self.Collections.TakenQuests;    if not db.Enabled or not db.Loaded then return nil; end return db[quest] or false; end,
    HasRewardedQuest = function(self, quest) local db = self.Collections.RewardedQuests; if not db.Enabled or not db.Loaded then return nil; end return db[quest] or false; end,
    GetSlotByCategory = function(self, category)
            if category == LE_TRANSMOG_COLLECTION_TYPE_HEAD         then return "HEAD";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_SHOULDER     then return "SHOULDER";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_BACK         then return "BACK";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_CHEST        then return "CHEST";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_TABARD       then return "TABARD";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_SHIRT        then return "SHIRT";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_WRIST        then return "WRIST";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_HANDS        then return "HANDS";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_WAIST        then return "WAIST";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_LEGS         then return "LEGS";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_FEET         then return "FEET";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_WAND         then return "WAND";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_1H_AXE       then return "1H_AXE";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_1H_SWORD     then return "1H_SWORD";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_1H_MACE      then return "1H_MACE";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_DAGGER       then return "DAGGER";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_FIST         then return "FIST";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_SHIELD       then return "SHIELD";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_HOLDABLE     then return "HOLDABLE";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_2H_AXE       then return "2H_AXE";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_2H_SWORD     then return "2H_SWORD";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_2H_MACE      then return "2H_MACE";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_STAFF        then return "STAFF";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_POLEARM      then return "POLEARM";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_BOW          then return "BOW";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_GUN          then return "GUN";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_CROSSBOW     then return "CROSSBOW";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_THROWN       then return "THROWN";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_FISHING_POLE then return "FISHING_POLE";
        elseif category == LE_TRANSMOG_COLLECTION_TYPE_MISC         then return "MISC";
        end
        return nil;
    end,
    GetDBByCategory = function(self, category)
        return self.Cache.Slot[self:GetSlotByCategory(category)];
    end,
    GetIllusionsDB = function(self)
        return self.Cache.Slot["ENCHANT"];
    end,
    GetSkinCategory = function(self, item)
        for slot, db in pairs(self.Cache.Slot) do
            if db.Loaded then
                for i, id in ipairs(db) do
                    if id == item then
                        for category = 1, NUM_LE_TRANSMOG_COLLECTION_TYPES do
                            if self:GetSlotByCategory(category) == slot then
                                return category;
                            end
                        end
                        return nil;
                    end
                end
            end
        end
        return nil;
    end,
    GetSkinInfo = function(self, id)
        return self.Cache.All[id];
    end,
    GetSkinIcon = function(self, id)
        local info = self:GetSkinInfo(id);
        if info and info.Icon then
            return [[Interface\Icons\]]..info.Icon;
        end
        return select(10, GetItemInfo(id));
    end,
    GetInstanceInfo = function(self, id)
        local data = self.Instances[id];
        if data then
            local type, tier, name, overrideDifficulty = strsplit(",", data, 4);
            return
            {
                Type = tonumber(type) or INSTANCE_TYPE_DUNGEON,
                Tier = L["InstanceTier."..((tonumber(tier) or 0) + 1)],
                Name = name,
                OverrideDifficulty = tonumber(overrideDifficulty),
            };
        end
    end,
    GetEncounterInfo = function(self, id, dynamicHeroic)
        local data = self.Encounters[id];
        if data then
            local map, difficulty, name = strsplit(",", data, 3);
            local instance = self:GetInstanceInfo(tonumber(map) or 0);
            return
            {
                Map = tonumber(map) or 0,
                Difficulty = L[format("Difficulty.%d.%d", instance and instance.Type or 1, instance.OverrideDifficulty or ((tonumber(difficulty) or 0) + 1 + (dynamicHeroic and 2 or 0)))];
                Name = name,
            };
        end
    end,
    GetEnchantFromScroll = function(self, scroll)
        return self.Cache.ScrollToEnchant[scroll];
    end,
    GetScrollFromEnchant = function(self, enchant)
        return self.Cache.EnchantToScroll[enchant];
    end,
    CanHideSlot = function(self, slot)
        return self.HideVisualSlots[slot] or false;
    end,
    GetHiddenVisualItem = function(self)
        return ITEM_HIDDEN;
    end,
    GetHiddenEnchant = function(self)
        return ENCHANT_HIDDEN, L["Tooltip.Transmog.Enchant.Hidden"];
    end,
    TransformEnchantName = function(self, name)
        name = name or "";
        name = name:gsub("%[", ""):gsub("%]", ""):gsub(".- %- ", ""):gsub(".-: ", "");
        return name:utf8sub(1, 1):utf8upper() .. name:utf8sub(2);
    end,
    CanTransmogrify = function(self, source)
        if source == ITEM_HIDDEN then return true; end
        if self:GetEnchantFromScroll(source) then return true; end
        return IsEquippableItem(source) and self:GetSkinInfo(source);
    end,
    CreatureWeaponPreview = 0,
    searchUpdater = CreateFrame("Frame", ADDON_NAME.."SearchUpdater", UIParent),
    SearchMinChars = 3,
    SearchDelay = 0,
    SearchMaxSetsSlotMask = 5,
    LastSearch =
    {
        [LE_TRANSMOG_SEARCH_TYPE_ITEMS]       = { Token = 0, Params = { }, Duration = 0, NumResults = 0, Results = { } },
        [LE_TRANSMOG_SEARCH_TYPE_BASE_SETS]   = { Token = 0, Params = { }, Duration = 0, NumResults = 0, Results = { } },
        [LE_TRANSMOG_SEARCH_TYPE_USABLE_SETS] = { Token = 0, Params = { }, Duration = 0, NumResults = 0, Results = { } },
    },
    IsSearchInProgress = function(self, type)
        local search = self.LastSearch[type];
        return search.NumResults == nil;
    end,
    IsSearchFinished = function(self, type, token)
        local search = self.LastSearch[type];
        return search.Token == token and search.NumResults == #search.Results;
    end,
    IsSearchMatchingParams = function(self, type, token, category, query, slot, id, enchant)
        local search = self.LastSearch[type];
        return search.Token == token and
               search.Params[1] == category and
               search.Params[2] == query and
               search.Params[3] == slot and
               search.Params[4] == id and
               search.Params[5] == enchant;
    end,
    Search = function(self, type, category, query, slot)
        local search = self.LastSearch[type];

        -- Deduplicate search queries
        if category == search.Params[1] and query == search.Params[2] and slot == search.Params[3] and type == LE_TRANSMOG_SEARCH_TYPE_ITEMS then
            if slot and slot ~= 0 then
                local _, id, enchant = strsplit(":", GetInventoryItemLink("player", slot) or "");
                if tonumber(id) == search.Params[4] and tonumber(enchant) == search.Params[5] then
                    C_Timer.After(0, function() self.Callbacks.SearchFinished(type); end);
                    return search.Token;
                end
            else
                C_Timer.After(0, function() self.Callbacks.SearchFinished(type); end);
                return search.Token;
            end
        end

        search.Token = search.Token + 1;
        search.Params = { category, query, slot, nil, nil };
        search.Duration = 0;
        search.NumResults = nil;
        table.wipe(search.Results);

        if not self.searchUpdater:GetScript("OnUpdate") then
            self.searchUpdater:SetScript("OnUpdate", ezCollections.Callbacks.SearchUpdate);
        end

        if slot and slot ~= 0 and type == LE_TRANSMOG_SEARCH_TYPE_ITEMS then
            local _, id, enchant = strsplit(":", GetInventoryItemLink("player", slot) or "");
            search.Params[4] = tonumber(id);
            search.Params[5] = tonumber(enchant);
            self:SendAddonMessage(format("TRANSMOGRIFY:SEARCH:%d:%d:%s:%s:%d,%d,%d", type, search.Token, self:GetSlotByCategory(category), self:Encode(query or ""), slot, tonumber(id) or 0, tonumber(enchant) or 0));
        elseif slot and slot ~= 0 and type == LE_TRANSMOG_SEARCH_TYPE_USABLE_SETS then
            self:SendAddonMessage(format("TRANSMOGRIFY:SEARCH:%d:%d:%s:%s:%d", type, search.Token, self:GetSlotByCategory(category), self:Encode(query or ""), slot));
        else
            self:SendAddonMessage(format("TRANSMOGRIFY:SEARCH:%d:%d:%s:%s", type, search.Token, self:GetSlotByCategory(category), self:Encode(query or "")));
        end
        return search.Token;
    end,
    EndSearch = function(self, type, token)
        local search = self.LastSearch[type];
        if search.Token == token and self:IsSearchInProgress(type) then
            self:SendAddonMessage(format("TRANSMOGRIFY:SEARCH:%d:%d:CANCEL", type, search.Token));
            search.Token = search.Token + 1;
        end
    end,
    WipeSearchResults = function(self, type)
        for type, search in pairs(self.LastSearch) do
            search.Token = search.Token + 1;
            table.wipe(search.Params);
            search.NumResults = 0;
            table.wipe(search.Results);
        end
    end,
    GetFavoritesContainer = function(self)
        if self.Config.Wardrobe.PerCharacterFavorites then
            return self.Config.TransmogCollection.PerCharacter[self:GetCharacterConfigKey()].Favorites;
        else
            return self.Config.TransmogCollection.Favorites;
        end
    end,

    -- Sets
    GetSetInfo = function(self, id)
        local set = self.Cache.Sets[id];
        if set then
            --set = deepcopy(set);
            local slots = { };
            for _, source in ipairs(set.sources) do
                source.collected = self:HasAvailableSkin(source.id);
                local info = self:GetSkinInfo(source.id);
                if info and info.InventoryType then
                    local slot = C_Transmog.GetSlotForInventoryType(info.InventoryType);
                    slots[slot] = slots[slot] or source.collected;
                end
            end
            set.collected = true;
            for slot, collected in pairs(slots) do
                if not collected then
                    set.collected = nil;
                    break;
                end
            end
            if not set.collected and set.Variants and C_TransmogSets.GetBaseSetsFilter(LE_TRANSMOG_SET_FILTER_GROUP) then
                for _, variantID in ipairs(set.Variants) do
                    local variantSet = ezCollections:GetSetInfo(variantID);
                    if variantSet and variantSet.collected then
                        set.collected = true;
                        break;
                    end
                end
            end
            set.favorite = C_TransmogSets.GetIsFavorite(set.setID);
            set.favoriteSetID = nil;
            if set.favorite then
                set.favoriteSetID = set.setID;
            elseif set.Variants then
                for _, variantID in ipairs(set.Variants) do
                    if C_TransmogSets.GetIsFavorite(variantID) then
                        set.favoriteSetID = variantID;
                        break;
                    end
                end
            end
            set.limitedTimeSet = nil;
        end
        return set;
    end,
    GetSetFavoritesContainer = function(self)
        if self.Config.Wardrobe.PerCharacterFavorites then
            return self.Config.TransmogCollection.PerCharacter[self:GetCharacterConfigKey()].SetFavorites;
        else
            return self.Config.TransmogCollection.SetFavorites;
        end
    end,

    -- Outfits
    MaxOutfits = 0,
    PrepaidOutfitsEnabled = false,
    Outfits = { },

    -- Claim Quests
    UnclaimedQuests = { },
    LastClaimQuestSkin = nil,
    LastClaimQuestData = nil,
    LastClaimSetSlotQuestSet = nil,
    LastClaimSetSlotQuestSlot = nil,
    LastClaimSetSlotQuestData = nil,
    IsUnclaimedQuest = function(self, quest)
        return self.UnclaimedQuests[quest];
    end,
    AreUnclaimedQuests = function(self, quests)
        if type(quests) == "string" then
            quests = { strsplit(",", quests) };
            for i, quest in ipairs(quests) do
                quests[i] = tonumber(quest);
            end
        end
        for _, quest in ipairs(quests) do
            if self:IsUnclaimedQuest(quest) then
                return true;
            end
        end
    end,
    CanClaimSkin = function(self, skin)
        local info = self:GetSkinInfo(skin);
        return info and info.SourceQuests and self:AreUnclaimedQuests(info.SourceQuests);
    end,
    ClaimQuest = function(self, quest, skin)
        self.LastClaimQuestSkin = nil;
        self.LastClaimQuestData = nil;
        self.LastClaimSetSlotQuestSet = nil;
        self.LastClaimSetSlotQuestSlot = nil;
        self.LastClaimSetSlotQuestData = nil;
        ezCollections:SendAddonMessage(format("CLAIMQUEST:CLAIM:%d:%d", quest, skin));
    end,
    BeginClaimQuest = function(self, skin)
        if self.LastClaimQuestSkin == skin and self.LastClaimQuestData then
            self.Callbacks.ReceivedClaimQuests();
        elseif self.LastClaimQuestSkin ~= skin then
            self.LastClaimQuestSkin = skin;
            self.LastClaimQuestData = nil;
            self:SendAddonMessage(format("CLAIMQUEST:GETQUESTS:%d", skin));
        end
    end,
    CanClaimSetSlotSkin = function(self, set, slot)
        for _, source in ipairs(C_TransmogSets.GetSourcesForSlot(set, slot)) do
            local info = self:GetSkinInfo(source.sourceID);
            if info and info.SourceQuests and self:AreUnclaimedQuests(info.SourceQuests) then
                return true;
            end
        end
    end,
    BeginClaimSetSlotQuest = function(self, set, slot)
        if self.LastClaimSetSlotQuestSet == set and self.LastClaimSetSlotQuestSlot == slot and self.LastClaimSetSlotQuestData then
            self.Callbacks.ReceivedClaimSetSlotQuests();
        elseif self.LastClaimSetSlotQuestSet ~= set or self.LastClaimSetSlotQuestSlot ~= slot then
            self.LastClaimSetSlotQuestSet = set;
            self.LastClaimSetSlotQuestSlot = slot;
            self.LastClaimSetSlotQuestData = nil;
            self:SendAddonMessage(format("CLAIMQUEST:GETSLOTSETQUESTS:%d:%d", set, slot));
        end
    end,

    pendingTooltipInfo = { },
    SetPendingTooltipInfo = function(self, ...)
        self.pendingTooltipInfo = { ... };
    end,

    -- Holidays
    ActiveHolidays = { },
    IsHolidayActive = function(self, holiday)
        return self.ActiveHolidays[holiday];
    end,

    -- Store
    StoreSkins = { },
    IsStoreItem = function(self, item, info)
        info = info or self:GetSkinInfo(item);
        if info then
            return info.SourceMask and bit.band(info.SourceMask, bit.lshift(1, TRANSMOG_SOURCE_STORE - 1)) ~= 0 or false;
        end
    end,
    IsStoreExclusiveItem = function(self, item, info)
        info = info or self:GetSkinInfo(item);
        if info then
            return info.SourceMask == bit.lshift(1, TRANSMOG_SOURCE_STORE - 1);
        end
    end,
    GetStoreSetSource = function(self, set, slot)
        for _, source in ipairs(C_TransmogSets.GetSourcesForSlot(set, slot)) do
            if self:IsStoreItem(source.sourceID) then
                return source.sourceID;
            end
        end
    end,

    -- Subscriptions
    Subscriptions = { },
    SubscriptionBySkin = { },
    GetSubscriptionForSkin = function(self, skin)
        local id = self.SubscriptionBySkin[skin];
        return id and self.Subscriptions[id];
    end,
    GetActiveSubscriptionForSkin = function(self, skin)
        local subscription = self:GetSubscriptionForSkin(skin);
        return subscription and subscription.Active and subscription or nil;
    end,
    GetSubscriptionForSetSource = function(self, set, slot)
        for _, source in ipairs(C_TransmogSets.GetSourcesForSlot(set, slot)) do
            local subscription = self:GetSubscriptionForSkin(source.sourceID);
            if subscription then
                return subscription;
            end
        end
    end,
    IsSubscriptionExclusiveItem = function(self, item, info)
        info = info or self:GetSkinInfo(item);
        if info then
            return info.SourceMask == bit.lshift(1, TRANSMOG_SOURCE_SUBSCRIPTION - 1);
        end
    end,
    HasAvailableSkin = function(self, skin)
        return self:HasSkin(skin) or self:GetActiveSubscriptionForSkin(skin) ~= nil;
    end,

    IsStoreAndSubscriptionExclusiveItem = function(self, item, info)
        info = info or self:GetSkinInfo(item);
        if info then
            return info.SourceMask == bit.bor(bit.lshift(1, TRANSMOG_SOURCE_STORE - 1), bit.lshift(1, TRANSMOG_SOURCE_SUBSCRIPTION - 1));
        end
    end,
    IsStoreOrSubscriptionExclusiveItem = function(self, item, info)
        info = info or self:GetSkinInfo(item);
        if info and info.SourceMask then
            return bit.band(info.SourceMask, bit.bnot(bit.bor(bit.lshift(1, TRANSMOG_SOURCE_STORE - 1), bit.lshift(1, TRANSMOG_SOURCE_SUBSCRIPTION - 1)))) == 0;
        end
    end,
    FormatRemainingTime = function(self, duration, short)
        if duration >= 24 * 60 * 60 then
            return format(short and SPELL_TIME_REMAINING_DAYS:match("%%.+;") or SPELL_TIME_REMAINING_DAYS, math.floor(duration / (24 * 60 * 60)));
        elseif duration >= 60 * 60 then
            return format(short and SPELL_TIME_REMAINING_HOURS:match("%%.+;") or SPELL_TIME_REMAINING_HOURS, math.floor(duration / (60 * 60)));
        elseif duration >= 60 then
            return format(short and SPELL_TIME_REMAINING_MIN:match("%%.+;") or SPELL_TIME_REMAINING_MIN, math.floor(duration / 60));
        elseif duration >= 0 then
            return format(short and SPELL_TIME_REMAINING_SEC:match("%%.+;") or SPELL_TIME_REMAINING_SEC, math.floor(duration));
        end
    end,

    -- Mounts
    ActiveMountPremiumEndTime = 0,
    ActiveMountPremiumScaling = nil,
    ActiveMountPremiumInfo = nil,
    ActiveMountSubscriptionEndTime = 0,
    ActiveMountSubscriptionScaling = nil,
    ActiveMountSubscriptionInfo = nil,
    ActiveMountSubscriptionMounts = { },
    IsActiveMountPremium = function(self)
        return self.ActiveMountPremiumEndTime and self.ActiveMountPremiumEndTime > 0 and time() < self.ActiveMountPremiumEndTime;
    end,
    GetActiveMountPremiumEndTime = function(self)
        return self:IsActiveMountPremium() and self.ActiveMountPremiumEndTime or nil;
    end,
    IsActiveMountSubscription = function(self)
        return self.ActiveMountSubscriptionEndTime and self.ActiveMountSubscriptionEndTime > 0 and time() < self.ActiveMountSubscriptionEndTime;
    end,
    GetActiveMountSubscriptionEndTime = function(self)
        return self:IsActiveMountSubscription() and self.ActiveMountSubscriptionEndTime or nil;
    end,
    IsActiveMountSubscriptionMount = function(self, mountID)
        return self:IsActiveMountSubscription() and self.ActiveMountSubscriptionMounts[mountID] and true or false;
    end,
    IsMountScalingAllowed = function(self)
        return self.ActiveMountPremiumScaling and self:IsActiveMountPremium() or
               self.ActiveMountSubscriptionScaling and self:IsActiveMountSubscription();
    end,
    GetMountScalingEndTime = function(self)
        return math.max(self.ActiveMountPremiumScaling and self:GetActiveMountPremiumEndTime() or 0,
                        self.ActiveMountSubscriptionScaling and self:GetActiveMountSubscriptionEndTime() or 0);
    end,
    GetMountFavoritesContainer = function(self)
        return self.Config.MountJournal.PerCharacter[self:GetCharacterConfigKey()].Favorites;
    end,
    GetMountNeedFanfareContainer = function(self)
        return self.Config.MountJournal.PerCharacter[self:GetCharacterConfigKey()].NeedFanfare;
    end,

    -- Pets
    ActivePetSubscriptionEndTime = 0,
    ActivePetSubscriptionInfo = nil,
    ActivePetSubscriptionPets = { },
    IsActivePetSubscription = function(self)
        return self.ActivePetSubscriptionEndTime and self.ActivePetSubscriptionEndTime > 0 and time() < self.ActivePetSubscriptionEndTime;
    end,
    GetActivePetSubscriptionEndTime = function(self)
        return self:IsActivePetSubscription() and self.ActivePetSubscriptionEndTime or nil;
    end,
    IsActivePetSubscriptionPet = function(self, petID)
        return self:IsActivePetSubscription() and self.ActivePetSubscriptionPets[petID] and true or false;
    end,
    GetPetFavoritesContainer = function(self)
        return self.Config.PetJournal.PerCharacter[self:GetCharacterConfigKey()].Favorites;
    end,
    GetPetNeedFanfareContainer = function(self)
        return self.Config.PetJournal.PerCharacter[self:GetCharacterConfigKey()].NeedFanfare;
    end,

    -- Callbacks
    Callbacks =
    {
        SkinListLoaded = function()
            if not ezCollections.Cache.All.Loaded then
                return;
            end
            local function SearchForMissingCache(db)
                if ezCollections.itemCacheRequestNeeded or not db.Loaded then
                    return;
                end
                for item in pairs(db) do
                    if type(item) == "number" and not GetItemInfo(item) then
                        ezCollections.itemCacheRequestNeeded = true;
                        C_Timer.After(1, function()
                            if not ezCollections.itemCacheRequested then
                                ezCollections.itemCacheRequested = true;
                                ezCollections:SendAddonMessage("PRELOADCACHE:ITEMS:0");
                                StaticPopup_Show("EZCOLLECTIONS_PRELOADING_ITEM_CACHE");
                            end
                        end);
                        break;
                    end
                end
            end
            --SearchForMissingCache(ezCollections.Collections.Skins);
            SearchForMissingCache(ezCollections.Cache.All);
            -- Count store-exclusive items to exclude them from total category count
            ezCollections.Cache.All.StoreExclusiveCount = nil;
            ezCollections.Cache.All.SubscriptionExclusiveCount = nil;
            ezCollections.Cache.All.StoreAndSubscriptionExclusiveCount = nil;
            for item, info in pairs(ezCollections.Cache.All) do
                if type(item) == "number" then
                    -- Dynamic store skins
                    if ezCollections.StoreSkins.Loaded then
                        if ezCollections.StoreSkins[item] then
                            info.SourceMask = bit.bor(info.SourceMask or 0, bit.lshift(1, TRANSMOG_SOURCE_STORE - 1));
                        elseif info.SourceMask then
                            info.SourceMask = bit.band(info.SourceMask, bit.bnot(bit.lshift(1, TRANSMOG_SOURCE_STORE - 1)));
                        end
                    end
                    -- Dynamic subscription skins
                    if ezCollections:GetSubscriptionForSkin(item) then
                        info.SourceMask = bit.bor(info.SourceMask or 0, bit.lshift(1, TRANSMOG_SOURCE_SUBSCRIPTION - 1));
                    elseif info.SourceMask then
                        info.SourceMask = bit.band(info.SourceMask, bit.bnot(bit.lshift(1, TRANSMOG_SOURCE_SUBSCRIPTION - 1)));
                    end
                    -- Count exclusives so we can subtract them from total count
                    if ezCollections:IsStoreExclusiveItem(item, info) then
                        ezCollections.Cache.All.StoreExclusiveCount = (ezCollections.Cache.All.StoreExclusiveCount or 0) + 1;
                    end
                    if ezCollections:IsSubscriptionExclusiveItem(item, info) then
                        ezCollections.Cache.All.SubscriptionExclusiveCount = (ezCollections.Cache.All.SubscriptionExclusiveCount or 0) + 1;
                    end
                    if ezCollections:IsStoreAndSubscriptionExclusiveItem(item, info) then
                        ezCollections.Cache.All.StoreAndSubscriptionExclusiveCount = (ezCollections.Cache.All.StoreAndSubscriptionExclusiveCount or 0) + 1;
                    end
                    
                end
            end
            for slot, db in pairs(ezCollections.Cache.Slot) do
                db.StoreExclusiveCount = nil;
                db.SubscriptionExclusiveCount = nil;
                db.StoreAndSubscriptionExclusiveCount = nil;
                for _, item in ipairs(db) do
                    if ezCollections:IsStoreExclusiveItem(item) then
                        db.StoreExclusiveCount = (db.StoreExclusiveCount or 0) + 1;
                    end
                    if ezCollections:IsSubscriptionExclusiveItem(item) then
                        db.SubscriptionExclusiveCount = (db.SubscriptionExclusiveCount or 0) + 1;
                    end
                    if ezCollections:IsStoreAndSubscriptionExclusiveItem(item) then
                        db.StoreAndSubscriptionExclusiveCount = (db.StoreAndSubscriptionExclusiveCount or 0) + 1;
                    end
                end
            end
            -- Refresh UI
            ezCollections:WipeSearchResults();
            C_TransmogCollection.WipeAppearanceCache();
            C_TransmogSets.ReportSetSourceCollectedChanged();
            ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
            -- Check Mounts and Pets
            ezCollections.Callbacks.MountListLoaded();
        end,
        AddSkin = function(item)
            ezCollections:WipeSearchResults();
            C_TransmogCollection.WipeAppearanceCache();
            C_TransmogCollection.AddNewAppearance(item);
            local info = ezCollections:GetSkinInfo(item);
            if info and info.Sets then
                C_TransmogSets.ReportSetSourceCollectedChanged();
            end
            ezCollections.Alerts.AddSkin(item);
            ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
        end,
        RemoveSkin = function(item)
            ezCollections:WipeSearchResults();
            C_TransmogCollection.WipeAppearanceCache();
            local info = ezCollections:GetSkinInfo(item);
            if info and info.Sets then
                C_TransmogSets.ReportSetSourceCollectedChanged();
            end
            ezCollections.Alerts.AddSkin(item, true);
            ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
        end,
        ClearSkins = function()
            ezCollections:WipeSearchResults();
            C_TransmogCollection.WipeAppearanceCache();
            C_TransmogSets.ReportSetSourceCollectedChanged();
            ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
        end,
        ReceivedClaimQuests = function()
            if ezCollections.LastClaimQuestSkin and ezCollections.LastClaimQuestData then
                for _, model in ipairs(WardrobeCollectionFrame.ItemsCollectionFrame.Models) do
                    if model:IsShown() and model.visualInfo and model.visualInfo.visualID == ezCollections.LastClaimQuestSkin and model.ClaimQuest:IsShown() then
                        if #ezCollections.LastClaimQuestData == 1 then
                            ezCollectionsClaimQuestPopup.skin = ezCollections.LastClaimQuestSkin;
                            ezCollectionsClaimQuestPopup.quest = deepcopy(ezCollections.LastClaimQuestData[1]);
                            StaticPopupSpecial_Show(ezCollectionsClaimQuestPopup);
                            return;
                        end
                        local menu = { };
                        table.insert(menu, { text = L["ClaimQuest.Menu.Title"], notCheckable = true, isTitle = true });
                        for _, quest in ipairs(ezCollections.LastClaimQuestData) do
                            table.insert(menu,
                            {
                                text = format(L["ClaimQuest.Menu.Claim"], quest.Name),
                                notCheckable = true,
                                arg1 = ezCollections.LastClaimQuestSkin,
                                arg2 = quest,
                                func = function(self, skin, quest)
                                    ezCollectionsClaimQuestPopup.skin = skin;
                                    ezCollectionsClaimQuestPopup.quest = deepcopy(quest);
                                    StaticPopupSpecial_Show(ezCollectionsClaimQuestPopup);
                                end,
                            });
                        end
                        table.insert(menu, { text = CANCEL, notCheckable = true });
                        EasyMenu(menu, WardrobeCollectionFrame.ClaimQuestMenu, model.ClaimQuest, 0, 0, "MENU");
                        return;
                    end
                end
            end
        end,
        ReceivedClaimSetSlotQuests = function()
            if ezCollections.LastClaimSetSlotQuestSet == WardrobeCollectionFrame.SetsCollectionFrame:GetSelectedSetID() and ezCollections.LastClaimSetSlotQuestSlot and ezCollections.LastClaimSetSlotQuestData then
                for itemFrame in WardrobeCollectionFrame.SetsCollectionFrame.DetailsFrame.itemFramesPool:EnumerateActive() do
                    if itemFrame:IsShown() and C_Transmog.GetSlotForInventoryType(itemFrame.invType) == ezCollections.LastClaimSetSlotQuestSlot and itemFrame.ClaimQuest:IsShown() then
                        if #ezCollections.LastClaimSetSlotQuestData == 1 then
                            ezCollectionsClaimQuestPopup.skin = ezCollections.LastClaimSetSlotQuestData[1].ItemID;
                            ezCollectionsClaimQuestPopup.quest = deepcopy(ezCollections.LastClaimSetSlotQuestData[1]);
                            StaticPopupSpecial_Show(ezCollectionsClaimQuestPopup);
                            return;
                        end
                        local menu = { };
                        table.insert(menu, { text = L["ClaimQuest.Menu.Title"], notCheckable = true, isTitle = true });
                        for _, quest in ipairs(ezCollections.LastClaimSetSlotQuestData) do
                            table.insert(menu,
                            {
                                text = format(L["ClaimQuest.Menu.ClaimSetSlot"], quest.ItemColor, quest.ItemName, quest.Name),
                                notCheckable = true,
                                arg1 = quest.ItemID,
                                arg2 = quest,
                                func = function(self, skin, quest)
                                    ezCollectionsClaimQuestPopup.skin = skin;
                                    ezCollectionsClaimQuestPopup.quest = deepcopy(quest);
                                    StaticPopupSpecial_Show(ezCollectionsClaimQuestPopup);
                                end,
                            });
                        end
                        table.insert(menu, { text = CANCEL, notCheckable = true });
                        EasyMenu(menu, WardrobeCollectionFrame.ClaimQuestMenu, itemFrame.ClaimQuest, 0, 0, "MENU");
                        return;
                    end
                end
            end
        end,
        RemoveUnclaimedQuest = function(quest)
            ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
        end,
        SearchUpdate = function(self, elapsed)
            for type, search in pairs(ezCollections.LastSearch) do
                if ezCollections:IsSearchInProgress(type) then
                    search.Duration = search.Duration + elapsed * 1000;
                end
            end
        end,
        SearchFinished = function(type)
            local search = ezCollections.LastSearch[type];
            -- print("Search finished", type, search.Duration, unpack(search.Params));
            -- print("Results:", #search.Results);
            local category, query, slot, entry, enchant = unpack(search.Params);
            C_TransmogCollection.SearchFinished(type, search.Token, category, query, deepcopy(search.Results));
        end,

        MountListLoaded = function()
            local function SearchForMissingCache(db)
                if not ezCollections.cacheTestTooltip:GetParent() then
                    ezCollections.cacheTestTooltip:AddFontStrings(ezCollections.cacheTestTooltip:CreateFontString(), ezCollections.cacheTestTooltip:CreateFontString());
                end
                for id, info in pairs(db) do
                    local creatureID = info[1];
                    if creatureID then
                        ezCollections.cacheTestTooltip:SetOwner(WorldFrame, "ANCHOR_NONE");
                        ezCollections.cacheTestTooltip:SetHyperlink(("unit:0xF5300%05X000000"):format(creatureID));
                        local shown = ezCollections.cacheTestTooltip:IsShown();
                        local line = _G[ezCollections.cacheTestTooltip:GetName().."TextLeft1"];
                        local text = line and line:GetText() and line:GetText() ~= "" and line:GetText();
                        ezCollections.cacheTestTooltip:Hide();
                        if shown then
                            if text then
                                db[id][4] = text; -- Fill mount/pet name from creature cache
                            end
                        else
                            if not ezCollections.mountCacheRequestNeeded then
                                ezCollections.mountCacheRequestNeeded = true;
                                C_Timer.After(1.1, function()
                                    if not ezCollections.mountCacheRequested then
                                        ezCollections.mountCacheRequested = true;
                                        ezCollections:SendAddonMessage("PRELOADCACHE:MOUNTS:0");
                                        StaticPopup_Show("EZCOLLECTIONS_PRELOADING_MOUNT_CACHE");
                                    end
                                end);
                            end
                        end
                    end
                end
            end

            SearchForMissingCache(ezCollections.Mounts);
            SearchForMissingCache(ezCollections.Pets);
        end,
        MountListUpdated = function()
            ezCollections:RaiseEvent("MOUNT_JOURNAL_SEARCH_UPDATED");
        end,
        PetListUpdated = function()
            ezCollections:RaiseEvent("PET_JOURNAL_SEARCH_UPDATED");
        end,
    },

    -- Alerts
    Alerts =
    {
        AddSkin = function(item, revoke)
            local config = ezCollections.Config.Alerts.AddSkin;
            if not config.Enable then return; end
            local text = revoke and ERR_REVOKE_TRANSMOG_S or ERR_LEARN_TRANSMOG_S;
            local color = config.Color;
            local colorHex = "|cFF"..RGBPercToHex(color.r, color.g, color.b);
            if config.FullRowColor then
                text = colorHex..text.."|r";
            else
                text = "|cFFFFFFFF"..format(text, "|r"..colorHex.."%s|r|cFFFFFFFF").."|r";
            end
            local linkType = ezCollections:GetEnchantFromScroll(item) and "transmogillusion" or "transmogappearance";
            local name = GetItemInfo(item);
            if name then
                SendSystemMessage(format(text, format("|H%s:%d|h[%s]|h", linkType, item, name or "")));
            else
                ezCollections:QueryItem(item);
                local handler = { };
                handler.func = function(arg)
                    local text, item = unpack(arg);
                    local name = GetItemInfo(item);
                    if name then
                        SendSystemMessage(format(text, format("|H%s:%d|h[%s]|h", linkType, item, name or "")));
                    else
                        ezCollections.AceAddon:ScheduleTimer(handler.func, 1, arg);
                    end
                end;
                handler.func({ text, item });
            end
        end,
    },

    -- Bindings
    itemUnderCursor = { ID = nil, Bag = nil, Slot = nil },
    UnlockSkinHintCommand = "",
    UnlockSkinUnderCursor = function(self)
        if self.Allowed and self.itemUnderCursor.ID and self.itemUnderCursor.Bag then
            local _, link, _, _, _, _, _, _, _, texture = GetItemInfo(self.itemUnderCursor.ID);
            texture = texture or ezCollections:GetSkinIcon(self.itemUnderCursor.ID);
            StaticPopupDialogs["EZCOLLECTIONS_UNLOCK_SKIN"].itemLink = "|T"..texture..":30:30:0:-8|t "..link;
            if self.itemUnderCursor.Slot then
                StaticPopupDialogs["EZCOLLECTIONS_UNLOCK_SKIN"].commandData = self.itemUnderCursor.ID.." "..self.itemUnderCursor.Bag.." "..(self.itemUnderCursor.Slot - 1);
            else
                StaticPopupDialogs["EZCOLLECTIONS_UNLOCK_SKIN"].commandData = self.itemUnderCursor.ID.." "..(self.itemUnderCursor.Bag - 1);
            end
            StaticPopup_Show("EZCOLLECTIONS_UNLOCK_SKIN");
        end
    end,
    MenuIsengard     = function(self) self:SendAddonCommand(".isengard"); end,
    MenuTransmog     = function(self) self:SendAddonCommand(".isengard transmog"); end,
    MenuTransmogSets = function(self) self:SendAddonCommand(".isengard transmog set"); end,
    MenuCollections  = function(self) self:SendAddonCommand(".isengard transmog collection"); end,
    MenuDaily        = function(self) self:SendAddonCommand(".isengard daily"); end,

    -- Item Transmog
    ItemTransmogCache = { },
    GetItemTransmogCache = function(self, unit, bag, slot)
        unit = GetUnitName(unit or "player") or unit;
        self.ItemTransmogCache[unit] = self.ItemTransmogCache[unit] or { };
        self.ItemTransmogCache[unit][bag] = self.ItemTransmogCache[unit][bag] or { };
        if slot ~= nil then
            self.ItemTransmogCache[unit][bag][slot] = self.ItemTransmogCache[unit][bag][slot] or { };
            return self.ItemTransmogCache[unit][bag][slot];
        else
            return self.ItemTransmogCache[unit][bag];
        end
    end,
    PeekItemTransmogCacheID = function(self, unit, bag, slot)
        unit = GetUnitName(unit or "player") or unit;
        if slot ~= nil then
            return self.ItemTransmogCache[unit] and self.ItemTransmogCache[unit][bag] and self.ItemTransmogCache[unit][bag][slot] and self.ItemTransmogCache[unit][bag][slot].ID;
        else
            return self.ItemTransmogCache[unit] and self.ItemTransmogCache[unit][bag] and self.ItemTransmogCache[unit][bag].ID;
        end
    end,
    RemoveItemTransmogCache = function(self, unit, bag, slot)
        unit = GetUnitName(unit or "player") or unit;
        if not UnitIsUnit(unit, "player") then return; end
        if slot ~= nil then
            if self.ItemTransmogCache[unit] and self.ItemTransmogCache[unit][bag] then
                self.ItemTransmogCache[unit][bag][slot] = nil;
            end
        else
            if self.ItemTransmogCache[unit] then
                local cache = self.ItemTransmogCache[unit][bag];
                if cache then
                    cache.ID = nil;
                    cache.FakeEntry = nil;
                    cache.FakeEntryDeactivated = nil;
                    cache.FakeEnchant = nil;
                    cache.FakeEnchantName = nil;
                    cache.Flags = nil;
                    cache.Loaded = nil;
                    cache.Loading = nil;
                    if not next(cache) then
                        self.ItemTransmogCache[unit][bag] = nil;
                    end
                end
            end
        end
    end,
    ClearItemTransmogCache = function(self, unit)
        if UnitIsUnit(unit, "player") then return; end
        unit = GetUnitName(unit or "player") or unit;
        self.ItemTransmogCache[unit] = { };
    end,
    ClearItemTransmogCacheWithFakeEntry = function(self, unit, fakeEntry)
        if not UnitIsUnit(unit, "player") then return; end
        unit = GetUnitName(unit or "player") or unit;
        local toRemove = { };
        if self.ItemTransmogCache[unit] then
            for bag, slots in pairs(self.ItemTransmogCache[unit]) do
                if type(bag) == "number" then
                    if slots.FakeEntry == fakeEntry then
                        table.insert(toRemove, { unit, bag });
                    end
                    for slot, data in pairs(slots) do
                        if type(slot) == "number" then
                            if data.FakeEntry == fakeEntry then
                                table.insert(toRemove, { unit, bag, slot });
                            end
                        end
                    end
                end
            end
        end
        for _, params in ipairs(toRemove) do
            self:RemoveItemTransmogCache(unpack(params));
        end
    end,
    GetItemTransmog = function(self, unit, bag, slot)
        local id, request;
        if slot ~= nil then
            id = GetContainerItemID(bag, slot);
            request = bag.." "..(slot - 1);
        else
            id = oGetInventoryItemID(unit, bag);
            request = tostring(bag - 1);
        end
        if not id then return; end

        local cache = self:GetItemTransmogCache(unit, bag, slot);
        if cache.Loaded and (cache.ID == id or cache.FakeEntry == id and GetUnitName(unit) ~= GetUnitName("player")) then -- Upon inspect, GetInventoryItemID returns visible item IDs, i.e. fake transmogrified entries
            return cache.FakeEntry, cache.FakeEnchantName, cache.FakeEnchant, cache.Flags, cache.FakeEntryDeactivated;
        elseif (not cache.Loading or cache.ID ~= id) and GetUnitName(unit) == GetUnitName("player") then
            cache.ID = id;
            cache.Loaded = false;
            cache.Loading = true;
            self:SendAddonMessage("GETTRANSMOG:"..request);
        end
    end,
    setEmptyItemTransmogCache = false,
    SetEmptyItemTransmogCache = function(self)
        if self.setEmptyItemTransmogCache then return; end
        self.setEmptyItemTransmogCache = true;
        for slot=1,150 do
            local id = oGetInventoryItemID("player", slot);
            if id then
                local cache = self:GetItemTransmogCache("player", slot);
                cache.ID = id;
                cache.Loaded = true;
            end
        end
        for bag=0,4 do
            for slot=1,36 do
                local id = GetContainerItemID(bag, slot);
                if id then
                    local cache = self:GetItemTransmogCache("player", bag, slot);
                    cache.ID = id;
                    cache.Loaded = true;
                end
            end
        end
    end,
    setEmptyBankTransmogCache = false,
    SetEmptyBankTransmogCache = function(self)
        if self.setEmptyBankTransmogCache then return; end
        self.setEmptyBankTransmogCache = true;
        for bag=5,11 do
            for slot=1,36 do
                local id = GetContainerItemID(bag, slot);
                if id then
                    local cache = self:GetItemTransmogCache("player", bag, slot);
                    if cache.ID == nil and not cache.Loaded then
                        cache.ID = id;
                        cache.Loaded = true;
                    end
                end
            end
        end
    end,
    UpdateItemTransmogCache = function(self)
        for slot=1,150 do
            local id = oGetInventoryItemID("player", slot);
            if not id then
                self:RemoveItemTransmogCache("player", slot);
            elseif self:PeekItemTransmogCacheID("player", slot) ~= id then
                self:RemoveItemTransmogCache("player", slot);
            end
        end
        for bag=0,11 do
            if bag >= 5 and not self.setEmptyBankTransmogCache then break; end
            for slot=1,36 do
                local id = GetContainerItemID(bag, slot);
                if not id then
                    self:RemoveItemTransmogCache("player", bag, slot);
                elseif self:PeekItemTransmogCacheID("player", bag, slot) ~= id then
                    self:RemoveItemTransmogCache("player", bag, slot);
                end
            end
        end
    end,
    lastInspectTarget = "",
    inspectFrameHooked = false,
    missingInspectItems = nil,
    dataRequestTooltip = CreateFrame("GameTooltip", ADDON_NAME.."DataRequestTooltip", UIParent),
    cacheTestTooltip = CreateFrame("GameTooltip", ADDON_NAME.."CacheTestTooltip", UIParent, "GameTooltipTemplate"),
    awaitingItemCache = nil,
    QueryItem = function(self, item)
        if GetItemInfo(item) then return; end
        if not self.awaitingItemCache then
            self.awaitingItemCache = { };
            self.AceAddon:ScheduleRepeatingTimer(function()
                local found = nil;
                for item in pairs(ezCollections.awaitingItemCache) do
                    if GetItemInfo(item) then
                        found = found or { };
                        table.insert(found, item);
                    end
                end
                if found then
                    for _, item in ipairs(found) do
                        ezCollections.awaitingItemCache[item] = nil;
                        ezCollections:RaiseEvent("GET_ITEM_INFO_RECEIVED", item, true);
                    end
                    ezCollections:RaiseEvent("TRANSMOG_COLLECTION_ITEM_UPDATE");
                end
            end, 0.25);
        end
        if self.awaitingItemCache[item] then return; end
        self.awaitingItemCache[item] = true;
        self.dataRequestTooltip:SetHyperlink("item:" .. item);
        self.dataRequestTooltip:Hide();
    end,

    -- Config
    GetCharacterConfigKey = function(self)
        return format("%s - %s", UnitName("player"), GetRealmName());
    end,
    GetCVar = function(self, cvar)
        if not self.Config then
            if cvar == "transmogCurrentSpecOnly" then
                return false;
            else
                error("GetCVar OnLoad");
            end
        end
        return self.Config.CVar[self:GetCharacterConfigKey()][cvar];
    end,
    SetCVar = function(self, cvar, value)
        if self:GetCVar(cvar) == value then
            return false;
        end
        self.Config.CVar[self:GetCharacterConfigKey()][cvar] = value;
        return true;
    end,
    GetCVarBool = function(self, cvar)
        return not not self:GetCVar(cvar);
    end,
    SetCVarBool = function(self, cvar, value)
        self:SetCVar(cvar, not not value);
    end,
    GetCVarBitfield = function(self, cvar, index)
        return bit.band(self.Config.CVar[self:GetCharacterConfigKey()][cvar], bit.lshift(1, index - 1)) ~= 0;
    end,
    SetCVarBitfield = function(self, cvar, index, set)
        if self:GetCVarBitfield(cvar, index) == (set and true or false) then
            return false;
        end
        local container = self.Config.CVar[self:GetCharacterConfigKey()];
        if set then
            container[cvar] = bit.bor(container[cvar], bit.lshift(1, index - 1));
        else
            container[cvar] = bit.band(container[cvar], bit.bnot(bit.lshift(1, index - 1)));
        end
        return true;
    end,
    GetCameraOptionName = function(self, option)
        return L["Cameras."..option];
    end,

    -- Events
    registeredEvents =
    {
        TRANSMOGRIFY_UPDATE = { }, -- slotID, transmogType
        TRANSMOGRIFY_ITEM_UPDATE = { }, -- slotID, transmogType
        TRANSMOGRIFY_SUCCESS = { }, -- slotID, transmogType
        TRANSMOG_COLLECTION_UPDATED = { },
        TRANSMOG_COLLECTION_ITEM_UPDATE = { },
        TRANSMOG_COLLECTION_CAMERA_UPDATE = { },
        TRANSMOG_SEARCH_UPDATED = { },
        SEARCH_DB_LOADED = { },
        PLAYER_SPECIALIZATION_CHANGED = { },
        TRANSMOG_SOURCE_COLLECTABILITY_UPDATE = { }, -- sourceID, canCollect
        TRANSMOG_OUTFITS_CHANGED = { },
        TRANSMOG_SETS_UPDATE_FAVORITE = { },
        GET_ITEM_INFO_RECEIVED = { },
        MOUNT_JOURNAL_SEARCH_UPDATED = { },
        MOUNT_JOURNAL_USABILITY_CHANGED = { },
        PET_JOURNAL_SEARCH_UPDATED = { },

        -- Custom
        EZCOLLECTIONS_PRELOAD_ITEM_CACHE_PROGRESS = { },
        EZCOLLECTIONS_PRELOAD_MOUNT_CACHE_PROGRESS = { },
        PLAYER_EQUIPMENT_CHANGED = { },
    },
    RegisterEvent = function(self, frame, event)
        self.registeredEvents[event][frame] = true;
    end,
    UnregisterEvent = function(self, frame, event)
        self.registeredEvents[event][frame] = nil;
    end,
    RaiseEvent = function(self, event, ...)
        for frame, _ in pairs(self.registeredEvents[event]) do
            local script = frame:GetScript("OnEvent");
            if script then
                script(frame, event, ...);
            end
        end
    end,

    -- Taint
    pendingUIDropDownMenu_Initialize = { },
    UIDropDownMenu_Initialize = function(self, frame, initFunction, displayMode, level, menuList)
        if self.pendingUIDropDownMenu_Initialize then
            table.insert(self.pendingUIDropDownMenu_Initialize, function()
                UIDropDownMenu_Initialize(frame, initFunction, displayMode, level, menuList);
            end);
        else
            UIDropDownMenu_Initialize(frame, initFunction, displayMode, level, menuList);
        end
    end,
    InitDropDownMenus = function(self)
        for _, func in ipairs(self.pendingUIDropDownMenu_Initialize) do
            func();
        end
        self.pendingUIDropDownMenu_Initialize = nil;
    end,
};

-- --------------------------------------
-- Helper functions to manage collections
-- --------------------------------------
local function LoadList(container, callback)
    return function(ids)
        for id in ids:gmatch("(%d+):") do
            container[tonumber(id)] = true;
        end
        if ends_with(ids, "END") then
            container.Loaded = true;
            if callback then
                callback(container);
            end
        end
    end;
end
local function LoadIndexedList(container, callback)
    return function(ids)
        for id in ids:gmatch("(%d+):") do
            table.insert(container, tonumber(id))
        end
        if ends_with(ids, "END") then
            container.Loaded = true;
            if callback then
                callback(container);
            end
        end
    end;
end
local function LoadIndexedStringList(container, callback)
    return function(ids)
        for data in ids:gmatch("(.-):") do
            table.insert(container, data)
        end
        if ends_with(ids, "END") then
            container.Loaded = true;
            if callback then
                callback(container);
            end
        end
    end;
end
local function LoadAllList(container, allContainer, callback, dataTransform)
    return function(ids)
        for id, data in ids:gmatch("(%d+)(.-):") do
            id = tonumber(id);
            table.insert(container, id)
            if data and dataTransform then
                allContainer[id] = dataTransform(data);
            else
                allContainer[id] = data or true;
            end
        end
        if ends_with(ids, "END") then
            container.Loaded = true;
            allContainer.Loaded = true;
            for _, db in pairs(ezCollections.Cache.Slot) do
                if type(db) == "table" and not db.Loaded then
                    allContainer.Loaded = false;
                    break;
                end
            end
            if callback then
                callback(container, allContainer);
            end
        end
    end;
end
local function AddList(container, callback)
    return function(id)
        container[tonumber(id)] = true;
        if callback then
            callback(tonumber(id));
        end
    end;
end
local function RemoveList(container, callback)
    return function(id)
        container[tonumber(id)] = nil;
        if callback then
            callback(tonumber(id));
        end
    end;
end
local function ReloadList(request, container, callback)
    return function(ids)
        for id in pairs(container) do
            if type(id) == "number" then
                container[id] = nil;
            end
        end
        container.Loaded = false;
        if callback then
            callback(container);
        end
        ezCollections:SendAddonMessage(request);
    end;
end
local function ReloadAllList(request, container, allContainer, callback)
    return function(ids)
        for index, id in pairs(container) do
            if type(index) == "number" then
                allContainer[id] = nil;
                container[index] = nil;
            end
        end
        container.Loaded = false;
        allContainer.Loaded = false;
        if callback then
            callback(container, allContainer);
        end
        ezCollections:SendAddonMessage(request);
    end;
end
local function LoadItemTransmog(unit, slotStrings)
    local validateTransmog = false;
    for slotString in slotStrings:gmatch("(.-):") do
        local slots, itemString = strsplit("=", slotString, 2);
        local bag, slot = strsplit(",", slots, 2);
        local id, fakeEntry, fakeEnchantName, fakeEnchant, flags = strsplit(",", itemString);
        bag = tonumber(bag);
        if slot ~= nil then
            slot = tonumber(slot) + 1;
        else
            bag = bag + 1;
            if unit == "player" then
                validateTransmog = true;
            end
        end
        local cache = ezCollections:GetItemTransmogCache(unit, bag, slot);
        cache.ID = tonumber(id);
        cache.FakeEntry = tonumber(fakeEntry);
        cache.FakeEntryDeactivated = cache.FakeEntry and cache.FakeEntry < 0;
        cache.FakeEntry = cache.FakeEntry and math.abs(cache.FakeEntry);
        cache.FakeEnchant = tonumber(fakeEnchant);
        cache.FakeEnchantName = fakeEnchantName;
        cache.Flags = flags and flags ~= "" and ezCollections:Decode(flags);
        cache.Loaded = true;
        cache.Loading = false;
    end
    if validateTransmog then
        if WardrobeFrame_IsAtTransmogrifier() then
            C_Transmog.ValidateAllPending(true);
        end
    end
end

-- --------------------
-- Addon event handling
-- --------------------
function IsInspectFrameShown()
    return InspectFrame and InspectFrame:IsShown()
        or Examiner and Examiner:IsShown();
end
function addon:InitVersion()
    if self.versionRequestAttempts > 0 then
        self.versionRequestAttempts = self.versionRequestAttempts - 1;
        ezCollections:SendAddonMessage("VERSION:"..ADDON_VERSION);
    else
        self:CancelTimer(self.versionTimer);
        self.versionTimer = nil;
    end
end
function addon:UpdateInspect(unit)
    if not ezCollections.Config.RestoreItemIcons.Inspect then return; end

    -- GearScoreList requests inspects by hovering over players, which can screw up with us,
    -- since client can only hold one inspected unit in memory and we're expecting to update inspected slots later down the line
    if ezCollections.lastInspectRequestUnit ~= unit then
        ezCollections.lastInspectTarget = "";
        NotifyInspect("target");
        return;
    end

    ezCollections.missingInspectItems = { };
    if ezCollections.lastInspectTarget ~= "" and unit == ezCollections.lastInspectTarget and IsInspectFrameShown() then
        if InspectPaperDollItemSlotButton_Update then
            for _, slot in pairs(TRANSMOGRIFIABLE_SLOTS) do
                InspectPaperDollItemSlotButton_Update(_G["Inspect"..slot]);
            end
        end
        local elvui = LibStub("AceAddon-3.0"):GetAddon("ElvUI", true);
        if elvui then
            local module = elvui:GetModule("Enhanced_PaperDoll");
            if module then
                module:UpdatePaperDoll("target");
            end
        end
        if oGlow and oGlow.updateInspect then
            oGlow.updateInspect();
        end
        if Examiner then
            local module = Examiner:GetModuleFromToken("ItemSlots")
            if module then
                module:UpdateItemSlots();
            end
        end
    end
    if ezCollections.missingInspectItems and #ezCollections.missingInspectItems > 0 then
        for i, id in pairs(ezCollections.missingInspectItems) do
            ezCollections:QueryItem(id);
        end
        self:ScheduleTimer("UpdateInspect", 1, unit);
    end
    ezCollections.missingInspectItems = nil;
end
function addon:PLAYER_LOGIN(event)
    self.versionRequestAttempts = 3;
    self:InitVersion();
    if self.versionTimer then
        self:CancelTimer(self.versionTimer);
    end
    self.versionTimer = self:ScheduleRepeatingTimer("InitVersion", 10);
end
function addon:CHAT_MSG_ADDON(event, prefix, message, distribution, sender)
    if prefix ~= ADDON_PREFIX or sender ~= "" then return; end

    match(message, "VERSIONCHECK", function(version)
        self:PLAYER_LOGIN(event);
    end);
    match(message, "SERVERVERSION:", function(version)
        self.versionRequestAttempts = 0;
        local version, result, url = strsplit(":", version, 3);
        if version == "DISABLED" then
            result = "DISABLED";
        end
        if result ~= "OK" then
            ezCollections.NewVersion = { Version = version, URL = url };
            if result == "DISABLED" then
                ezCollections.NewVersion.Disabled = true;
            elseif result ~= "COMPATIBLE" then
                ezCollections.NewVersion.Outdated = true;
            end
            if result ~= "DISABLED" or not ezCollections.Config.NewVersion.HideRetiredPopup then
                StaticPopup_Show("EZCOLLECTIONS_NEW_VERSION");
            end
        end
        if not ezCollections.Allowed and (result == "OK" or result == "COMPATIBLE") then
            ezCollections.Allowed = true;
            ezCollections:SendAddonMessage("GETTRANSMOG:ALL");
        end
    end);
    match(message, "CACHEVERSION:", function(version)
        if ezCollections.Cache.Version == tonumber(version) and ezCollections.Cache.AddonVersion == ADDON_VERSION then
            ezCollections.Callbacks.SkinListLoaded();
        else
            ezCollections:ClearCache();
            ezCollections.Cache.Version = tonumber(version);
            ezCollections.Cache.AddonVersion = ADDON_VERSION;
            for slot, db in pairs(ezCollections.Cache.Slot) do
                ezCollections:SendAddonMessage("LIST:ALL:"..slot);
            end
            ezCollections:SendAddonMessage("LIST:DATA:SCROLLTOENCHANT");
            ezCollections:SendAddonMessage("LIST:DATA:SETS");
            ezCollections:SendAddonMessage("LIST:DATA:CAMERAS");
        end
    end);
    match(message, "UNLOCKSKINHINTCOMMAND:", function(command)
        ezCollections.UnlockSkinHintCommand = command;
    end);
    match(message, "TOKEN:", function(token)
        token = tonumber(token);
        if token ~= 0 then
            ezCollections.Token = token;
            ezCollections:QueryItem(token);
        else
            ezCollections.Token = nil;
        end
    end);
    match(message, "HIDEVISUALSLOTS:", function(slots)
        ezCollections.HideVisualSlots = { };
        for _, slot in ipairs({ strsplit(":", slots) }) do
            if slot ~= "" then
                ezCollections.HideVisualSlots[slot] = true;
            end
        end
    end);
    match(message, "WEAPONCOMPATIBILITY:", function(data)
        ezCollections.WeaponCompatibility = { };
        for i, mask in ipairs({ strsplit(":", data) }) do
            if mask ~= "" and i ~= 10 and i ~= 12 and i ~= 13 and i ~= 18 then -- Skip obsolete, exotic and exotic2, spear
                mask = tonumber(mask) or bit.lshift(1, i - 1);
                local a = bit.rshift(bit.band(mask, 0x0001FF), 0);
                local b = bit.rshift(bit.band(mask, 0x000400), 1); -- Skip obsolete
                local c = bit.rshift(bit.band(mask, 0x01E000), 3); -- Skip exotic, exotic 2
                local d = bit.rshift(bit.band(mask, 0x1C0000), 4); -- Skip spear
                mask = bit.bor(bit.bor(bit.bor(a, b), c), d);
                table.insert(ezCollections.WeaponCompatibility, mask);
            end
        end
    end);
    match(message, "SEARCHPARAMS:", function(data)
        local minChars, delay, maxSetsSlotMask = strsplit(":", data);
        ezCollections.SearchMinChars = tonumber(minChars) or 3;
        ezCollections.SearchDelay = math.max(1, tonumber(delay) or 0);
        ezCollections.SearchMaxSetsSlotMask = tonumber(maxSetsSlotMask) or 5;
    end);
    match(message, "OUTFITPARAMS:", function(data)
        local maxOutfits, outfitCostHint, outfitEditCostHint, prepaidEnabled = strsplit(":", data);
        ezCollections.MaxOutfits = tonumber(maxOutfits) or 0;
        ezCollections.OutfitCostHint = ezCollections:Decode(outfitCostHint);
        ezCollections.OutfitEditCostHint = ezCollections:Decode(outfitEditCostHint);
        ezCollections.PrepaidOutfitsEnabled = tonumber(prepaidEnabled) == 1;
    end);
    match(message, "STOREPARAMS:", function(data)
        local urlSkinFormat = strsplit(":", data);
        ezCollections.StoreURLSkinFormat = ezCollections:Decode(urlSkinFormat);
    end);
    match(message, "PREVIEWCREATURE:", function(data)
        local type, id = strsplit(":", data);
        if type == "WEAPON" then
            ezCollections.CreatureWeaponPreview = tonumber(id);
            C_Timer.NewTicker(5, function() ezCollectionsModelPreloader:Refresh(); end);
        end

        if not ezCollections.cacheTestTooltip:GetParent() then
            ezCollections.cacheTestTooltip:AddFontStrings(ezCollections.cacheTestTooltip:CreateFontString(), ezCollections.cacheTestTooltip:CreateFontString());
        end
        ezCollections.cacheTestTooltip:SetOwner(WorldFrame, "ANCHOR_NONE");
        ezCollections.cacheTestTooltip:SetHyperlink(("unit:0xF5300%05X000000"):format(tonumber(id)))
        if not ezCollections.cacheTestTooltip:IsShown() then
            ezCollections:SendAddonMessage("PREVIEWCREATURE:" .. type);
        end
        ezCollections.cacheTestTooltip:Hide();
    end);
    match(message, "HOLIDAY:", function(data)
        match(data, "START:", function(holiday)
            ezCollections.ActiveHolidays[tonumber(holiday)] = true;
            ezCollections:WipeSearchResults();
            C_TransmogCollection.WipeAppearanceCache();
            ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
        end);
        match(data, "STOP:", function(holiday)
            ezCollections.ActiveHolidays[tonumber(holiday)] = nil;
            ezCollections:WipeSearchResults();
            C_TransmogCollection.WipeAppearanceCache();
            ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
        end);
    end);
    match(message, "SUBSCRIPTION:", function(data)
        match(data, "ADD:", function(data)
            local id, endTime, url, name, description = strsplit(":", data);
            id = tonumber(id);
            if id then
                local subscription =
                {
                    EndTime = tonumber(endTime),
                    Active = time() < tonumber(endTime),
                    URL = ezCollections:Decode(url),
                    Name = ezCollections:Decode(name),
                    Description = ezCollections:Decode(description),
                    Skins = { },
                };

                ezCollections.Subscriptions[id] = subscription;

                if subscription.Active and not ezCollections.updateSubscriptionsScheduled then
                    ezCollections.updateSubscriptionsScheduled = true;
                    C_Timer.NewTicker(1, function()
                        local now = nil;
                        local deactivated = false;
                        for id, subscription in pairs(ezCollections.Subscriptions) do
                            if subscription.Active then
                                if not now then
                                    now = time();
                                end
                                if now >= subscription.EndTime then
                                    subscription.Active = false;
                                    deactivated = true;
                                    for _, skin in ipairs(subscription.Skins) do
                                        ezCollections:ClearItemTransmogCacheWithFakeEntry("player", skin);
                                    end
                                end
                            end
                        end
                        if deactivated then
                            ezCollections:WipeSearchResults();
                            C_TransmogCollection.WipeAppearanceCache();
                            C_TransmogSets.ReportSetSourceCollectedChanged();
                            ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
                        end
                    end);
                end
            end
        end);
        for id, subscription in pairs(ezCollections.Subscriptions) do
            local closureID = id;
            match(data, "SKINS:"..id..":", LoadIndexedList(subscription.Skins, function(skins)
                for _, skin in ipairs(skins) do
                    ezCollections.SubscriptionBySkin[skin] = closureID;
                end
                ezCollections.Callbacks.SkinListLoaded();
            end));
        end
        match(data, "REMOVE:", function(data)
            local id = strsplit(":", data);
            id = tonumber(id);
            if id then
                local subscription = ezCollections.Subscriptions[id];
                if subscription then
                    subscription.EndTime = time();
                    subscription.Active = false;
                    ezCollections:WipeSearchResults();
                    C_TransmogCollection.WipeAppearanceCache();
                    C_TransmogSets.ReportSetSourceCollectedChanged();
                    ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
                end
            end
        end);
        match(data, "RELOAD", function()
            table.wipe(ezCollections.Subscriptions);
            table.wipe(ezCollections.SubscriptionBySkin);
        end);
    end);
    match(message, "DEVELOPER", function()
        ezCollections.Developer = true;
    end);
    match(message, "SETUPFINISHED", function()
        C_Timer.After(5, function()
            local function StartUp()
                if not ezCollections.Config.Wardrobe.CameraOptionSetup and ezCollections:PlayerHasDifferentCameraOptions() then
                    C_Timer.After(1, function()
                        StaticPopupSpecial_Show(ezCollectionsCameraPreviewPopup);
                    end);
                end
            end
            if StaticPopup_Visible("EZCOLLECTIONS_PRELOADING_ITEM_CACHE") then
                local oldOnHide = StaticPopupDialogs["EZCOLLECTIONS_PRELOADING_ITEM_CACHE"].OnHide;
                StaticPopupDialogs["EZCOLLECTIONS_PRELOADING_ITEM_CACHE"].OnHide = function(self)
                    oldOnHide(self);
                    StartUp();
                end;
            else
                StartUp();
            end
        end);
    end);
    match(message, "COLLECTIONS:", function(collections)
        for k, collection in pairs({ strsplit(":", collections) }) do
            if collection ~= "END" then
                ezCollections:SendAddonMessage("LIST:"..collection);
            end
                if collection == "OWNEDITEM"        then ezCollections.Collections.OwnedItems.Enabled = true;
            elseif collection == "SKIN"             then ezCollections.Collections.Skins.Enabled = true;
            elseif collection == "TAKENQUEST"       then ezCollections.Collections.TakenQuests.Enabled = true;
            elseif collection == "REWARDEDQUEST"    then ezCollections.Collections.RewardedQuests.Enabled = true;
            end
        end
    end);
    match(message, "LIST:", function(list)
        local function matchitem(data, start, pattern, func)
            local s, e, group = data:find(pattern, start);
            if s and e and group and s == start then
                func(group);
                return e + 1;
            end
        end
        match(list, "OWNEDITEM:",           LoadList(ezCollections.Collections.OwnedItems));
        match(list, "SKIN:",                LoadList(ezCollections.Collections.Skins, ezCollections.Callbacks.SkinListLoaded));
        match(list, "TAKENQUEST:",          LoadList(ezCollections.Collections.TakenQuests));
        match(list, "REWARDEDQUEST:",       LoadList(ezCollections.Collections.RewardedQuests));
        for slot, db in pairs(ezCollections.Cache.Slot) do
            match(list, "ALL:"..slot..":",  LoadAllList(db, ezCollections.Cache.All, ezCollections.Callbacks.SkinListLoaded, function(data)
                local info = { };
                local i = 1;
                while i do
                    i= matchitem(data, i, "I(%d+)", function(value) info.InventoryType = tonumber(value) + 1; end)
                    or matchitem(data, i, "Q([Q%d]+)", function(value) info.SourceQuests = value:gsub("Q", ","); end)
                    or matchitem(data, i, "B([B%d]+)", function(value) info.SourceBosses = value:gsub("B", ","); end)
                    or matchitem(data, i, "H(%d+)", function(value) info.Holiday = tonumber(value); end)
                    or matchitem(data, i, "C(%d+)", function(value) info.Camera = tonumber(value); end)
                    or matchitem(data, i, "U()", function(value) info.Unusable = true; end)
                    or matchitem(data, i, "O()", function(value) info.Unobtainable = true; end)
                    or matchitem(data, i, "E()", function(value) info.Weapon = true; info.Enchantable = true; end)
                    or matchitem(data, i, "W()", function(value) info.Weapon = true; end)
                    or matchitem(data, i, "A(%d+)", function(value) info.Armor = tonumber(value); end)
                    or matchitem(data, i, "S([%dA-F][%dA-F])", function(value) info.SourceMask = tonumber(value, 16); end)
                    or matchitem(data, i, "L([%dA-F]+)", function(value) info.ClassMask = tonumber(value, 16); end)
                    or matchitem(data, i, "R([%dA-F]+)", function(value) info.RaceMask = tonumber(value, 16); end)
                    or matchitem(data, i, "T\"(.-)\"", function(value) info.Icon = value; end)
                end
                return info;
            end));
        end
        match(list, "UNCLAIMEDQUEST:",     LoadList(ezCollections.UnclaimedQuests));
        match(list, "HOLIDAY:",            LoadList(ezCollections.ActiveHolidays));
        match(list, "STORESKIN:",          LoadList(ezCollections.StoreSkins, ezCollections.Callbacks.SkinListLoaded));
        match(list, "DATA:", function(data)
            match(data, "SCROLLTOENCHANT:", function(scrollToEnchants)
                for _, scrollToEnchant in ipairs({ strsplit(":", scrollToEnchants) }) do
                    if scrollToEnchant ~= "" and scrollToEnchant ~= "END" then
                        local scroll, enchant = strsplit("=", scrollToEnchant);
                        ezCollections.Cache.ScrollToEnchant[tonumber(scroll)] = tonumber(enchant);
                        ezCollections.Cache.EnchantToScroll[tonumber(enchant)] = tonumber(scroll);
                    end
                end
            end);
            match(data, "SETS:", function(sets)
                for _, set in ipairs({ strsplit(":", sets) }) do
                    if set == "END" then
                        for id, set in pairs(ezCollections.Cache.Sets) do
                            for _, source in ipairs(set.sources) do
                                local skin = ezCollections.Cache.All[source.id];
                                if skin and not (skin.Sets and tContains(skin.Sets, set.setID)) then
                                    skin.Sets = skin.Sets or { };
                                    table.insert(skin.Sets, set.setID);
                                end
                            end
                            if set.baseSetID then
                                local baseSet = ezCollections.Cache.Sets[set.baseSetID];
                                if baseSet then
                                    baseSet.Variants = baseSet.Variants or { };
                                    table.insert(baseSet.Variants, set.setID);
                                end
                            end
                        end
                    elseif set ~= "" then
                        local id, data = strsplit("=", set);
                        id = tonumber(id);

                        local name, classMask, flags, label, description, parent, expansion, patch, order, itemStrings = strsplit(",", data, 10);
                        name = ezCollections:Decode(name);
                        classMask = tonumber(classMask);
                        flags = tonumber(flags);
                        label = ezCollections:Decode(label);
                        description = ezCollections:Decode(description);
                        parent = tonumber(parent);
                        expansion = tonumber(expansion);
                        patch = tonumber(patch);
                        order = tonumber(order);

                        local set =
                        {
                            setID = id,
                            name = name,
                            baseSetID = parent ~= 0 and parent or nil,
                            description = #description ~= 0 and description or nil,
                            label = #label ~= 0 and label or nil,
                            expansionID = expansion,
                            patchID = patch,
                            uiOrder = order,
                            classMask = classMask,
                            hiddenUntilCollected = bit.band(flags, 2) ~= 0,
                            requiredFaction = bit.band(flags, 4) ~= 0 and "ALLIANCE" or (bit.band(flags, 8) ~= 0 and "HORDE" or nil),
                            collected = nil,
                            favorite = nil,
                            limitedTimeSet = nil,
                            sources = { },
                            flags = flags,
                        };
                        if itemStrings then
                            for _, item in ipairs({ strsplit(",", itemStrings) }) do
                                local id, flags = strsplit("F", item);
                                flags = tonumber(flags) or 0;
                                local source =
                                {
                                    id = tonumber(id),
                                    flags = flags,
                                };
                                if bit.band(flags, 0x1) ~= 0 then
                                    table.insert(set.sources, 1, source);
                                else
                                    table.insert(set.sources, source);
                                end
                            end
                        end

                        ezCollections.Cache.Sets[id] = set;
                    end
                end
            end);
            match(data, "CAMERAS:", function(cameras)
                for _, camera in ipairs({ strsplit(":", cameras) }) do
                    if camera ~= "" and camera ~= "END" then
                        local idString, dataString = strsplit("=", camera);
                        local option, race, sex, id = strsplit(",", idString);
                        local x, y, z, f, anim, name = strsplit(",", dataString);
                        option = tonumber(option) or 0;
                        race = tonumber(race) or 0;
                        sex = tonumber(sex) or 0;
                        id = tonumber(id) or 0;
                        x = tonumber(x) or 0;
                        y = tonumber(y) or 0;
                        z = tonumber(z) or 0;
                        f = tonumber(f) or 0;
                        anim = anim and tonumber(anim);
                        name = name and ezCollections:Decode(name);
                        ezCollections.Cache.Cameras[option * ezCollections.CameraOptionsToCameraID[ezCollections.CameraOptions[1]] + race * ezCollections.RaceToCameraID.Human + sex * ezCollections.SexToCameraID[1] + id] = { x, y, z, f, anim, name };
                    end
                end
            end);
        end);
    end);
    match(message, "ADD:", function(list)
        match(list, "OWNEDITEM:",           AddList(ezCollections.Collections.OwnedItems));
        match(list, "SKIN:",                AddList(ezCollections.Collections.Skins, ezCollections.Callbacks.AddSkin));
        match(list, "TAKENQUEST:",          AddList(ezCollections.Collections.TakenQuests));
        match(list, "REWARDEDQUEST:",       AddList(ezCollections.Collections.RewardedQuests));
    end);
    match(message, "REMOVE:", function(list)
        match(list, "OWNEDITEM:",           RemoveList(ezCollections.Collections.OwnedItems));
        match(list, "SKIN:",                RemoveList(ezCollections.Collections.Skins, ezCollections.Callbacks.RemoveSkin));
        match(list, "TAKENQUEST:",          RemoveList(ezCollections.Collections.TakenQuests));
        match(list, "REWARDEDQUEST:",       RemoveList(ezCollections.Collections.RewardedQuests));
        match(list, "UNCLAIMEDQUEST:",      RemoveList(ezCollections.UnclaimedQuests, ezCollections.Callbacks.RemoveUnclaimedQuest));
    end);
    match(message, "RELOAD:", function(list)
        match(list, "OWNEDITEM:",           ReloadList("LIST:OWNEDITEM",     ezCollections.Collections.OwnedItems));
        match(list, "SKIN:",                ReloadList("LIST:SKIN",          ezCollections.Collections.Skins, ezCollections.Callbacks.ClearSkins));
        match(list, "TAKENQUEST:",          ReloadList("LIST:TAKENQUEST",    ezCollections.Collections.TakenQuests));
        match(list, "REWARDEDQUEST:",       ReloadList("LIST:REWARDEDQUEST", ezCollections.Collections.RewardedQuests));
        for slot, db in pairs(ezCollections.Cache.Slot) do
            match(list, "ALL:"..slot..":",  ReloadAllList("LIST:ALL:"..slot, db, ezCollections.Cache.All));
        end
        match(list, "STORESKIN:",           ReloadList("LIST:STORESKIN",    ezCollections.StoreSkins, ezCollections.Callbacks.ClearSkins));
    end);
    match(message, "GETTRANSMOG:", function(data)
        if not match(data, "PLAYER:", function(nameSlotStrings)
            local unit, slotStrings = strsplit(":", nameSlotStrings, 2);
            ezCollections:ClearItemTransmogCache(unit);
            LoadItemTransmog(unit, slotStrings);
            ezCollections.AceAddon:UpdateInspect(unit);
        end) and not match(data, "ALL:", function(slotStrings)
            ezCollections:SetEmptyItemTransmogCache();
            LoadItemTransmog("player", slotStrings);
        end) then
            LoadItemTransmog("player", data);
            ezCollections:RaiseEvent("TRANSMOGRIFY_UPDATE");
            ezCollections:RaiseEvent("PLAYER_EQUIPMENT_CHANGED");
        end
    end);
    match(message, "CLAIMQUEST:", function(data)
        match(data, "GETQUESTS:", function(result)
            local skin, questStrings = strsplit(":", result, 2);
            if tonumber(skin) == ezCollections.LastClaimQuestSkin then
                ezCollections.LastClaimQuestData = { };
                for _, questString in ipairs({ strsplit(":", questStrings) }) do
                    if questString == "END" then
                        ezCollections.Callbacks.ReceivedClaimQuests();
                    elseif questString ~= "" then
                        local quest, questData = strsplit("=", questString, 2);
                        local name, choicesString = strsplit(",", questData, 2);
                        local info =
                        {
                            ID = tonumber(quest),
                            Name = ezCollections:Decode(name),
                            Choices = { },
                        };
                        for _, choice in ipairs({ strsplit(",", choicesString) }) do
                            table.insert(info.Choices, tonumber(choice));
                        end
                        table.insert(ezCollections.LastClaimQuestData, info);
                    end
                end
            end
        end);
        match(data, "GETSLOTSETQUESTS:", function(result)
            local set, slot, questStrings = strsplit(":", result, 3);
            if tonumber(set) == ezCollections.LastClaimSetSlotQuestSet and tonumber(slot) == ezCollections.LastClaimSetSlotQuestSlot then
                ezCollections.LastClaimSetSlotQuestData = { };
                for _, questString in ipairs({ strsplit(":", questStrings) }) do
                    if questString == "END" then
                        ezCollections.Callbacks.ReceivedClaimSetSlotQuests();
                    elseif questString ~= "" then
                        local quest, questData = strsplit("=", questString, 2);
                        local itemID, itemName, itemColor, questName, choicesString = strsplit(",", questData, 5);
                        local info =
                        {
                            ItemID = tonumber(itemID),
                            ItemName = ezCollections:Decode(itemName),
                            ItemColor = itemColor,
                            ID = tonumber(quest),
                            Name = ezCollections:Decode(questName),
                            Choices = { },
                        };
                        for _, choice in ipairs({ strsplit(",", choicesString) }) do
                            table.insert(info.Choices, tonumber(choice));
                        end
                        table.insert(ezCollections.LastClaimSetSlotQuestData, info);
                    end
                end
            end
        end);
    end);
    match(message, "TRANSMOGRIFY:", function(data)
        match(data, "COST:", function(result)
            if not match(result, "OK:", function(costStrings)
                local moneyCost, tokenCost, key = strsplit(":", costStrings, 3);
                C_Transmog.ClearSlotFailReasons(key);
                C_Transmog.SetCost(key, tonumber(moneyCost), tonumber(tokenCost));
            end) and not match(result, "FAIL:", function(costStrings)
                local entryFailReasons, enchantFailReasons, key = strsplit(":", costStrings, 3);
                C_Transmog.ClearSlotFailReasons(key);
                if entryFailReasons ~= "" then
                    for _, slotReason in ipairs({ strsplit(",", entryFailReasons) }) do
                        local slot, reason = strsplit("=", slotReason, 2);
                        C_Transmog.SetSlotFailReason(key, tonumber(slot), LE_TRANSMOG_TYPE_APPEARANCE, ezCollections:Decode(reason));
                    end
                end
                if enchantFailReasons ~= "" then
                    for _, slotReason in ipairs({ strsplit(",", enchantFailReasons) }) do
                        local slot, reason = strsplit("=", slotReason, 2);
                        C_Transmog.SetSlotFailReason(key, tonumber(slot), LE_TRANSMOG_TYPE_ILLUSION, ezCollections:Decode(reason));
                    end
                end
                ezCollections:RaiseEvent("TRANSMOGRIFY_UPDATE");
            end) then
                StaticPopup_Show("EZCOLLECTIONS_ERROR", L["Popup.Error.Transmogrify.Cost"] .. result);
            end
        end);
        match(data, "APPLY:", function(result)
            if not match(result, "OK:", function(costStrings)
                local moneyCost, tokenCost, key = strsplit(":", costStrings, 3);
                C_Transmog.PendingApplied(key);
            end) and not match(result, "FAIL:", function(costStrings)
                local entryFailReasons, enchantFailReasons, key = strsplit(":", costStrings, 3);
                C_Transmog.ClearSlotFailReasons(key);
                if entryFailReasons ~= "" then
                    for _, slotReason in ipairs({ strsplit(",", entryFailReasons) }) do
                        local slot, reason = strsplit("=", slotReason, 2);
                        C_Transmog.SetSlotFailReason(key, tonumber(slot), LE_TRANSMOG_TYPE_APPEARANCE, ezCollections:Decode(reason));
                    end
                end
                if enchantFailReasons ~= "" then
                    for _, slotReason in ipairs({ strsplit(",", enchantFailReasons) }) do
                        local slot, reason = strsplit("=", slotReason, 2);
                        C_Transmog.SetSlotFailReason(key, tonumber(slot), LE_TRANSMOG_TYPE_ILLUSION, ezCollections:Decode(reason));
                    end
                end
                C_Transmog.PendingFailed();
                ezCollections:RaiseEvent("TRANSMOGRIFY_UPDATE");
            end) then
                C_Transmog.PendingFailed();
                StaticPopup_Show("EZCOLLECTIONS_ERROR", L["Popup.Error.Transmogrify.Apply"] .. result);
            end
        end);
        for type, search in pairs(ezCollections.LastSearch) do
            match(data, "SEARCH:"..type..":"..search.Token..":", function(result)
                if not match(result, "OK:", function(resultsString)
                    local numResults = strsplit(":", resultsString, 1);
                    search.NumResults = tonumber(numResults);
                    table.wipe(search.Results);
                    if search.NumResults == 0 then
                        ezCollections.Callbacks.SearchFinished(type);
                    end
                end) and not match(result, "RESULTS:", (type == LE_TRANSMOG_SEARCH_TYPE_USABLE_SETS and LoadIndexedStringList or LoadIndexedList)(search.Results, function()
                    if search.NumResults == #search.Results then
                        ezCollections.Callbacks.SearchFinished(type);
                    else
                        StaticPopup_Show("EZCOLLECTIONS_ERROR", L["Popup.Error.Transmogrify.Search.ResultsMismatch"]);
                    end
                end)) and not match(result, "FAIL:", function(result)
                    StaticPopup_Show("EZCOLLECTIONS_ERROR", L["Popup.Error.Transmogrify.Search"] .. result);
                end) then
                    StaticPopup_Show("EZCOLLECTIONS_ERROR", L["Popup.Error.Transmogrify.Search"] .. result);
                end
            end);
        end
        match(data, "OUTFIT:", function(result)
            match(result, "COST:", function(result)
                if not match(result, "OK:", function(result)
                    local moneyCost, tokenCost, outfitData = strsplit(":", result, 3);
                    if not WardrobeOutfitSaveFrame.editedOutfitID then
                        WardrobeOutfitSaveFrame:Update(false, true, nil, tonumber(moneyCost), tonumber(tokenCost));
                    end
                end) and not match(result, "FAIL:", function(result)
                    local moneyCost, tokenCost, failedItemMask, failedEnchantMask, errorText = strsplit(":", result);
                    if not WardrobeOutfitSaveFrame.editedOutfitID then
                        WardrobeOutfitSaveFrame:Update(false, false, ezCollections:Decode(errorText), tonumber(moneyCost), tonumber(tokenCost), tonumber(failedItemMask), tonumber(failedEnchantMask));
                    end
                end) then
                    StaticPopup_Show("EZCOLLECTIONS_ERROR", L["Popup.Error.Transmogrify.Outfit.Cost"] .. result);
                end
            end);
            match(result, "ADD:", function(result)
                if not match(result, "OK:", function(result)
                    local moneyCost, tokenCost, outfitData = strsplit(":", result, 3);
                    if not WardrobeOutfitSaveFrame.editedOutfitID then
                        StaticPopupSpecial_Hide(WardrobeOutfitSaveFrame);
                    end
                end) and not match(result, "FAIL:", function(result)
                    local moneyCost, tokenCost, failedItemMask, failedEnchantMask, errorText = strsplit(":", result);
                    if not WardrobeOutfitSaveFrame.editedOutfitID then
                        WardrobeOutfitSaveFrame:Update(false, false, ezCollections:Decode(errorText), tonumber(moneyCost), tonumber(tokenCost), tonumber(failedItemMask), tonumber(failedEnchantMask));
                    end
                end) then
                    local id, name, flags, slotStrings = strsplit(":", result, 4);
                    id = tonumber(id);
                    if id then
                        ezCollections.Outfits[id] =
                        {
                            Name = ezCollections:Decode(name),
                            Flags = tonumber(flags) or 0,
                            Slots = slotStrings,
                        };
                        ezCollections:RaiseEvent("TRANSMOG_OUTFITS_CHANGED");
                        C_Transmog.ValidateAllPending();
                    else
                        StaticPopup_Show("EZCOLLECTIONS_ERROR", L["Popup.Error.Transmogrify.Outfit.Add"] .. result);
                    end
                end
            end);
            match(result, "EDIT:", function(result)
                if not match(result, "OK:", function(result)
                    local outfitID, moneyCost, tokenCost, outfitData = strsplit(":", result, 4);
                    outfitID = tonumber(outfitID);
                    if outfitID and outfitID == WardrobeOutfitSaveFrame.editedOutfitID then
                        StaticPopupSpecial_Hide(WardrobeOutfitSaveFrame);
                    end
                end) and not match(result, "FAIL:", function(result)
                    local outfitID, moneyCost, tokenCost, failedItemMask, failedEnchantMask, errorText = strsplit(":", result);
                    outfitID = tonumber(outfitID);
                    if outfitID and outfitID == WardrobeOutfitSaveFrame.editedOutfitID then
                        WardrobeOutfitSaveFrame:Update(false, false, ezCollections:Decode(errorText), tonumber(moneyCost), tonumber(tokenCost), tonumber(failedItemMask), tonumber(failedEnchantMask));
                    end
                end) then
                    StaticPopup_Show("EZCOLLECTIONS_ERROR", L["Popup.Error.Transmogrify.Outfit.Edit"] .. result);
                end
            end);
            match(result, "EDITCOST:", function(result)
                if not match(result, "OK:", function(result)
                    local outfitID, moneyCost, tokenCost, outfitData = strsplit(":", result, 4);
                    outfitID = tonumber(outfitID);
                    if outfitID and outfitID == WardrobeOutfitSaveFrame.editedOutfitID then
                        WardrobeOutfitSaveFrame:Update(false, true, nil, tonumber(moneyCost), tonumber(tokenCost));
                    end
                end) and not match(result, "FAIL:", function(result)
                    local outfitID, moneyCost, tokenCost, failedItemMask, failedEnchantMask, errorText = strsplit(":", result, 6);
                    outfitID = tonumber(outfitID);
                    if outfitID and outfitID == WardrobeOutfitSaveFrame.editedOutfitID then
                        WardrobeOutfitSaveFrame:Update(false, false, ezCollections:Decode(errorText), tonumber(moneyCost), tonumber(tokenCost), tonumber(failedItemMask), tonumber(failedEnchantMask));
                    end
                end) then
                    StaticPopup_Show("EZCOLLECTIONS_ERROR", L["Popup.Error.Transmogrify.Outfit.EditCost"] .. result);
                end
            end);
            match(result, "RENAME:", function(result)
                if not match(result, "OK", function() end) then
                    StaticPopup_Show("EZCOLLECTIONS_ERROR", L["Popup.Error.Transmogrify.Outfit.Rename"] .. result);
                end
            end);
            match(result, "REMOVE:", function(result)
                if not match(result, "OK", function() end) then
                    local id = strsplit(":", result);
                    id = tonumber(id);
                    if id then
                        for specIndex = 1, GetNumSpecializations() do
                            if tonumber(ezCollections:GetCVar("lastTransmogOutfitIDSpec"..specIndex)) == id then
                                ezCollections:SetCVar("lastTransmogOutfitIDSpec"..specIndex, "");
                            end
                        end
                        ezCollections.Outfits[id] = nil;
                        ezCollections:RaiseEvent("TRANSMOG_OUTFITS_CHANGED");
                        C_Transmog.ValidateAllPending();
                    else
                        StaticPopup_Show("EZCOLLECTIONS_ERROR", L["Popup.Error.Transmogrify.Outfit.Remove"] .. result);
                    end
                end
            end);
        end);
    end);
    match(message, "MOUNT:", function(result)
        match(result, "PREMIUM:STATUS:", function(result)
            local endTime, scaling, info = strsplit(":", result, 3);
            ezCollections.ActiveMountPremiumEndTime = tonumber(endTime) or 0;
            ezCollections.ActiveMountPremiumScaling = tonumber(scaling) == 1;
            ezCollections.ActiveMountPremiumInfo = ezCollections:Decode(info);
            ezCollections.Callbacks.MountListUpdated();
        end);
        match(result, "SUBSCRIPTION:STATUS:", function(result)
            if not match(result, "SPELLS:",  LoadList(ezCollections.ActiveMountSubscriptionMounts, ezCollections.Callbacks.MountListUpdated)) then
                local endTime, scaling, info = strsplit(":", result, 3);
                ezCollections.ActiveMountSubscriptionEndTime = tonumber(endTime) or 0;
                ezCollections.ActiveMountSubscriptionScaling = tonumber(scaling) == 1;
                ezCollections.ActiveMountSubscriptionInfo = ezCollections:Decode(info);
                table.wipe(ezCollections.ActiveMountSubscriptionMounts);
                ezCollections.Callbacks.MountListUpdated();
            end
        end);
    end);
    match(message, "PET:", function(result)
        match(result, "SUBSCRIPTION:STATUS:", function(result)
            if not match(result, "SPELLS:",  LoadList(ezCollections.ActivePetSubscriptionPets, ezCollections.Callbacks.PetListUpdated)) then
                local endTime, scaling, info = strsplit(":", result, 3);
                ezCollections.ActivePetSubscriptionEndTime = tonumber(endTime) or 0;
                ezCollections.ActivePetSubscriptionScaling = tonumber(scaling) == 1;
                ezCollections.ActivePetSubscriptionInfo = ezCollections:Decode(info);
                table.wipe(ezCollections.ActivePetSubscriptionPets);
                ezCollections.Callbacks.PetListUpdated();
            end
        end);
    end);
    match(message, "PRELOADCACHE:ITEMS:", function(result)
        local offset, total = strsplit(":", result);
        offset = tonumber(offset);
        total = tonumber(total);
        if not offset or not total then
            ezCollections.preloadCacheItemsNextOffset = nil;
            StaticPopup_Hide("EZCOLLECTIONS_PRELOADING_ITEM_CACHE");
            if result == "Throttled" then
                StaticPopup_Show("EZCOLLECTIONS_ERROR", L["Popup.PreloadingItemCache.Throttled"]);
            else
                StaticPopup_Show("EZCOLLECTIONS_ERROR", L["Popup.Error.UnknownParam"] .. result);
            end
        else
            ezCollections:RaiseEvent("EZCOLLECTIONS_PRELOAD_ITEM_CACHE_PROGRESS", offset, total);
            if offset < total then
                ezCollections.preloadCacheItemsNextOffset = offset;
                ezCollections:SendAddonMessage("PRELOADCACHE:ITEMS:"..offset);
            else
                ezCollections.preloadCacheItemsNextOffset = nil;
            end
        end
    end);
    match(message, "PRELOADCACHE:MOUNTS:", function(result)
        local offset, total = strsplit(":", result);
        offset = tonumber(offset);
        total = tonumber(total);
        if not offset or not total then
            ezCollections.preloadCacheMountsNextOffset = nil;
            StaticPopup_Hide("EZCOLLECTIONS_PRELOADING_MOUNT_CACHE");
            if result == "Throttled" then
                StaticPopup_Show("EZCOLLECTIONS_ERROR", L["Popup.PreloadingMountCache.Throttled"]);
            else
                StaticPopup_Show("EZCOLLECTIONS_ERROR", L["Popup.Error.UnknownParam"] .. result);
            end
        else
            ezCollections:RaiseEvent("EZCOLLECTIONS_PRELOAD_MOUNT_CACHE_PROGRESS", offset, total);
            if offset < total then
                ezCollections.preloadCacheMountsNextOffset = offset;
                ezCollections:SendAddonMessage("PRELOADCACHE:MOUNTS:"..offset);
            else
                ezCollections.preloadCacheMountsNextOffset = nil;
                ezCollections.Callbacks.MountListLoaded();
            end
        end
    end);
end
function addon:INSPECT_TALENT_READY(event)
    local target = GetUnitName("target");
    if not ezCollections.Allowed or not ezCollections.Config.RestoreItemIcons.Inspect or not target or not IsInspectFrameShown() then return; end
    local needs = self.needsInspectUpdate;
    self.needsInspectUpdate = nil;
    if target == ezCollections.lastInspectTarget then
        if needs then
            -- Must be delayed because for some unknown reason GetInventoryItem* will return old values here
            if not self.inspectUpdateTimer then
                self.inspectUpdateTimer = self:ScheduleTimer(function() self.inspectUpdateTimer = nil; self:UpdateInspect(target); end, 0.1);
            end
        end
        return;
    end

    if not ezCollections.inspectFrameHooked then
        if InspectFrame then
            InspectFrame:HookScript("OnHide", function(self)
                ezCollections.lastInspectTarget = "";
            end);
        end
        if Examiner then
            Examiner:HookScript("OnHide", function(self)
                ezCollections.lastInspectTarget = "";
            end);
        end
        ezCollections.inspectFrameHooked = true;
    end
    ezCollections.lastInspectTarget = target;
    ezCollections:ClearItemTransmogCache(target);
    ezCollections:SendAddonMessage("GETTRANSMOG:PLAYER:"..target);
end
function addon:UNIT_INVENTORY_CHANGED(event, unit)
    local target = GetUnitName(unit);
    if not ezCollections.Allowed or not ezCollections.Config.RestoreItemIcons.Inspect or not target or not IsInspectFrameShown() or target ~= ezCollections.lastInspectTarget then return; end

    if not self.reinspectTimer then
        self.reinspectTimer = self:ScheduleTimer(function() self.reinspectTimer = nil; NotifyInspect("target"); end, 0.5);
    end

    self.needsInspectUpdate = true;
    ezCollections:ClearItemTransmogCache(target);
    ezCollections:SendAddonMessage("GETTRANSMOG:PLAYER:"..target);
end
function addon:PLAYER_EQUIPMENT_CHANGED(event, slot, equipped)
    if CharacterFrame:IsShown() and PaperDollFrame:IsShown() then
        local slotName = TRANSMOGRIFIABLE_SLOTS[slot];
        local slotButton = slotName and _G["Character"..slotName];
        if slotButton and slotButton:IsShown() then
            PaperDollItemSlotButton_Update(slotButton);
        end
    end
    ezCollections:RemoveItemTransmogCache("player", slot);
    if WardrobeFrame_IsAtTransmogrifier() and equipped and ezCollections:IsSkinSource(oGetInventoryItemID("player", slot)) == true then
        ezCollections:GetItemTransmog("player", slot);
    end
end
function addon:BANKFRAME_OPENED(event)
    if not ezCollections.Allowed then return; end

    ezCollections:SetEmptyBankTransmogCache();
end
function addon:BAG_UPDATE(event, bagID)
    if not ezCollections.Allowed then return; end

    ezCollections:UpdateItemTransmogCache();
end
function addon:ADDON_LOADED(event, addon)
    if ezCollectionsInspectHook and (addon == "Blizzard_InspectUI" or InspectPaperDollItemSlotButton_Update) then
        hooksecurefunc("InspectPaperDollItemSlotButton_Update", ezCollectionsInspectHook);
        ezCollectionsInspectHook = nil;
    end
    if ezCollectionsAuctionOnShowHook and (addon == "Blizzard_AuctionUI" or AuctionFrame) then
        AuctionFrame:HookScript("OnShow", ezCollectionsAuctionOnShowHook);
        ezCollectionsAuctionOnShowHook = nil;
    end
    if ezCollectionsAuctionOnHideHook and (addon == "Blizzard_AuctionUI" or AuctionFrame) then
        AuctionFrame:HookScript("OnHide", ezCollectionsAuctionOnHideHook);
        ezCollectionsAuctionOnHideHook = nil;
    end
    if ezCollectionsDressUpItemLink and addon == "Blizzard_AuctionUI" then
        DressUpItemLink = ezCollectionsDressUpItemLink;
    end
    if ezCollectionsDominosHook and (addon == "Dominos" or Dominos) then
        ezCollectionsDominosHook();
        ezCollectionsDominosHook = nil;
    end
end
function addon:PLAYER_ENTERING_WORLD(event)
    if ezCollections and ezCollections.preloadCacheItemsNextOffset then
        ezCollections:SendAddonMessage("PRELOADCACHE:ITEMS:"..ezCollections.preloadCacheItemsNextOffset);
    end
    if ezCollections and ezCollections.preloadCacheMountsNextOffset then
        ezCollections:SendAddonMessage("PRELOADCACHE:MOUNTS:"..ezCollections.preloadCacheMountsNextOffset);
    end
    C_MountJournal.RefreshMounts();
    C_PetJournal.RefreshPets();
end

local companionUpdateDeferred = false;
function addon:COMPANION_LEARNED(event)
    if not companionUpdateDeferred then
        companionUpdateDeferred = true;
        C_Timer.After(0.1, function()
            companionUpdateDeferred = false;
            C_MountJournal.RefreshMounts();
            C_PetJournal.RefreshPets();
        end);
    end
end

function addon:COMPANION_UNLEARNED(event)
    if not companionUpdateDeferred then
        companionUpdateDeferred = true;
        C_Timer.After(0.1, function()
            companionUpdateDeferred = false;
            C_MountJournal.RefreshMounts();
            C_PetJournal.RefreshPets();
        end);
    end
end

function addon:SPELL_UPDATE_USABLE(event)
    ezCollections:RaiseEvent("MOUNT_JOURNAL_USABILITY_CHANGED");
end

function addon:ACTIONBAR_UPDATE_USABLE(event)
    ezCollections:RaiseEvent("MOUNT_JOURNAL_USABILITY_CHANGED");
end

local successfullyStartedCastID = nil;
function addon:UNIT_SPELLCAST_START(event, unit, name, rank, castID)
    if ezCollections:IsMountScalingAllowed() and name and unit == "player" and castID ~= 0 and IsOutdoors() then
        for i = 1, GetNumCompanions("MOUNT") do
            local _, _, spellID = GetCompanionInfo("MOUNT", i);
            if spellID and GetSpellInfo(spellID) == name then
                successfullyStartedCastID = castID;
            end
        end
    end
end

local waitingForMountFailure = false;
local suppressMountError = false;
function addon:UNIT_SPELLCAST_FAILED(event, unit, name, rank, castID)
    if ezCollections:IsMountScalingAllowed() and waitingForMountFailure and name and unit == "player" and castID ~= 0 and castID ~= successfullyStartedCastID and IsOutdoors() then
        for i = 1, GetNumCompanions("MOUNT") do
            local _, _, spellID = GetCompanionInfo("MOUNT", i);
            if spellID and GetSpellInfo(spellID) == name then
                if C_MountJournal.IsMountUsable(spellID, true) then
                    ezCollections:SendAddonMessage("MOUNT:SCALINGCAST:"..spellID);
                    suppressMountError = true;
                end
            end
        end
    end
    waitingForMountFailure = false;
end

local oldUIErrorsFrameOnEvent = UIErrorsFrame:GetScript("OnEvent");
UIErrorsFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "UI_ERROR_MESSAGE" and ezCollections:IsMountScalingAllowed() then
        local text = ...;
        if text == SPELL_FAILED_NOT_HERE then
            waitingForMountFailure = true;
            C_Timer.After(0, function()
                if not suppressMountError then
                    self:AddMessage(text, 1.0, 0.1, 0.1, 1.0);
                end
                suppressMountError = false;
            end);
            return;
        end
    end
    oldUIErrorsFrameOnEvent(self, event, ...);
end);

-- ---------------------------------------------------------------------------
-- Replace transmogrified icons on paper doll frames with their original icons
-- ---------------------------------------------------------------------------
function addon:HookRestoreItemIcons()

hooksecurefunc("NotifyInspect", function(unit)
    ezCollections.lastInspectRequestUnit = UnitName(unit);
end);
GetInventoryItemID = function(unit, slot, ...)
    if ezCollections.Allowed and ezCollections.Config.RestoreItemIcons.Equipment and UnitIsUnit(unit, "player") then
        -- Do nothing, GetInventoryItemID should be able to return real values for current player
    elseif ezCollections.Allowed and ezCollections.Config.RestoreItemIcons.Inspect and UnitIsUnit(unit, "target") and GetUnitName("target") == ezCollections.lastInspectTarget then
        local id = ezCollections:GetItemTransmogCache(unit, slot).ID;
        if id and id ~= 0 then
            return id;
        end
    end
    return oGetInventoryItemID(unit, slot, ...);
end
--[[ Called from secure code
local oGetInventoryItemLink = GetInventoryItemLink;
GetInventoryItemLink = function(unit, slot, ...)
    if ezCollections.Allowed and ezCollections.Config.RestoreItemIcons.Equipment and UnitIsUnit(unit, "player") then
        -- Do nothing, GetInventoryItemLink should be able to return real values for current player
    elseif ezCollections.Allowed and ezCollections.Config.RestoreItemIcons.Inspect and UnitIsUnit(unit, "target") and GetUnitName("target") == ezCollections.lastInspectTarget then
        local id = ezCollections:GetItemTransmogCache(unit, slot).ID;
        if id and id ~= 0 then
            local link = oGetInventoryItemLink(unit, slot, ...);
            if not link then
                local _, link = GetItemInfo(id);
                return link;
            end
            local parts = { strsplit(":", link) };
            parts[2] = id;
            return table.concat(parts, ":");
        end
    end
    return oGetInventoryItemLink(unit, slot, ...);
end
]]
local oGetInventoryItemTexture = GetInventoryItemTexture;
ezCollectionsGetInventoryItemTexture = function(unit, slot, ...)
    if ezCollections.Allowed and ezCollections.Config.RestoreItemIcons.Equipment and UnitIsUnit(unit, "player") then
        local id = GetInventoryItemID(unit, slot);
        if not id or id == 0 then return; end
        local texture = ezCollections:GetSkinIcon(id);
        return texture or oGetInventoryItemTexture(unit, slot, ...);
    elseif ezCollections.Allowed and ezCollections.Config.RestoreItemIcons.Inspect and UnitIsUnit(unit, "target") and GetUnitName("target") == ezCollections.lastInspectTarget then
        local id = ezCollections:GetItemTransmogCache(unit, slot).ID or GetInventoryItemID(unit, slot);
        if not id or id == 0 then return; end
        local texture = ezCollections:GetSkinIcon(id);
        if not texture and ezCollections.missingInspectItems then
            table.insert(ezCollections.missingInspectItems, id);
        end
        return texture or oGetInventoryItemTexture(unit, slot, ...);
    end
    return oGetInventoryItemTexture(unit, slot, ...);
end

if ezCollections.Config.RestoreItemIcons.Global then
    GetInventoryItemTexture = ezCollectionsGetInventoryItemTexture;
else
    if ezCollections.Config.RestoreItemIcons.Equipment then
        hooksecurefunc("PaperDollItemSlotButton_Update", function(self)
            local textureName = ezCollectionsGetInventoryItemTexture("player", self:GetID());
            local cooldown = _G[self:GetName().."Cooldown"];
            if ( textureName ) then
                SetItemButtonTexture(self, textureName);
                SetItemButtonCount(self, GetInventoryItemCount("player", self:GetID()));
                if ( GetInventoryItemBroken("player", self:GetID()) ) then
                    SetItemButtonTextureVertexColor(self, 0.9, 0, 0);
                    SetItemButtonNormalTextureVertexColor(self, 0.9, 0, 0);
                else
                    SetItemButtonTextureVertexColor(self, 1.0, 1.0, 1.0);
                    SetItemButtonNormalTextureVertexColor(self, 1.0, 1.0, 1.0);
                end
                if ( cooldown ) then
                    local start, duration, enable = GetInventoryItemCooldown("player", self:GetID());
                    CooldownFrame_SetTimer(cooldown, start, duration, enable);
                end
                self.hasItem = 1;
            else
                local textureName = self.backgroundTextureName;
                if ( self.checkRelic and UnitHasRelicSlot("player") ) then
                    textureName = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Relic.blp";
                end
                SetItemButtonTexture(self, textureName);
                SetItemButtonCount(self, 0);
                SetItemButtonTextureVertexColor(self, 1.0, 1.0, 1.0);
                SetItemButtonNormalTextureVertexColor(self, 1.0, 1.0, 1.0);
                if ( cooldown ) then
                    cooldown:Hide();
                end
                self.hasItem = nil;
            end
        end);
    end
    if ezCollections.Config.RestoreItemIcons.Inspect then
        function ezCollectionsInspectHook(button)
            local unit = InspectFrame.unit;
            local textureName = ezCollectionsGetInventoryItemTexture(unit, button:GetID());
            if ( textureName ) then
                SetItemButtonTexture(button, textureName);
                SetItemButtonCount(button, GetInventoryItemCount(unit, button:GetID()));
                button.hasItem = 1;
            else
                local textureName = button.backgroundTextureName;
                if ( button.checkRelic and UnitHasRelicSlot(unit) ) then
                    textureName = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Relic.blp";
                end
                SetItemButtonTexture(button, textureName);
                SetItemButtonCount(button, 0);
                button.hasItem = nil;
            end
        end
        if InspectPaperDollItemSlotButton_Update then
            hooksecurefunc("InspectPaperDollItemSlotButton_Update", ezCollectionsInspectHook);
        end
    end
end

if ezCollections.Config.RestoreItemIcons.EquipmentManager then
    local _equippedItems = {};
    local _numItems;
    local _specialIcon;
    local _TotalItems;
    function RefreshEquipmentSetIconInfo()
        _numItems = 0;
        for i = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
            _equippedItems[i] = ezCollectionsGetInventoryItemTexture("player", i);
            if(_equippedItems[i]) then
                _numItems = _numItems + 1;
                for j=INVSLOT_FIRST_EQUIPPED, (i-1) do
                    if(_equippedItems[i] == _equippedItems[j]) then
                        _equippedItems[i] = nil;
                        _numItems = _numItems - 1;
                        break;
                    end
                end
            end
        end
    end
    function GetEquipmentSetIconInfo(index)
        for i = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
            if (_equippedItems[i]) then
                index = index - 1;
                if ( index == 0 ) then
                    return _equippedItems[i], -i;
                end
            end
        end
        if(index>GetNumMacroIcons()) then
            return _specialIcon, index;
        end
        return GetMacroIconInfo(index), index;
    end
    function GearManagerDialogPopup_Update()
        RefreshEquipmentSetIconInfo();

        local popup = GearManagerDialogPopup;
        local buttons = popup.buttons;
        local offset = FauxScrollFrame_GetOffset(GearManagerDialogPopupScrollFrame) or 0;
        local button;
        -- Icon list
        local texture, index, button, realIndex;
        for i=1, NUM_GEARSET_ICONS_SHOWN do
            local button = buttons[i];
            index = (offset * NUM_GEARSET_ICONS_PER_ROW) + i;
            if ( index <= _TotalItems ) then
                texture, _ = GetEquipmentSetIconInfo(index);
                -- button.name:SetText(index); --dcw
                button.icon:SetTexture(texture);
                button:Show();
                if ( index == popup.selectedIcon ) then
                    button:SetChecked(1);
                elseif ( texture == popup.selectedTexture ) then
                    button:SetChecked(1);
                    popup:SetSelection(false, index);
                else
                    button:SetChecked(nil);
                end
            else
                button.icon:SetTexture("");
                button:Hide();
            end
        end
        -- Scrollbar stuff
        FauxScrollFrame_Update(GearManagerDialogPopupScrollFrame, ceil(_TotalItems / NUM_GEARSET_ICONS_PER_ROW) , NUM_GEARSET_ICON_ROWS, GEARSET_ICON_ROW_HEIGHT );
    end
    function RecalculateGearManagerDialogPopup()
        local popup = GearManagerDialogPopup;
        local selectedSet = GearManagerDialog.selectedSet;
        if ( selectedSet ) then
            popup:SetSelection(true, selectedSet.icon:GetTexture());
            local editBox = GearManagerDialogPopupEditBox;
            editBox:SetText(selectedSet.name);
            editBox:HighlightText(0);
        end
        RefreshEquipmentSetIconInfo();
        _TotalItems = GetNumMacroIcons() + _numItems;
        _specialIcon = nil;
        local texture;
        if(popup.selectedTexture) then
            local index = 1;
            local foundIndex = nil;
            for index=1, _TotalItems do
                texture, _ = GetEquipmentSetIconInfo(index);
                if ( texture == popup.selectedTexture ) then
                    foundIndex = index;
                    break;
                end
            end
            if (foundIndex == nil) then
                _specialIcon = popup.selectedTexture;
                _TotalItems = _TotalItems + 1;
                foundIndex = _TotalItems;
            else
                _specialIcon = nil;
            end
            local offsetnumIcons = floor((_TotalItems-1)/NUM_GEARSET_ICONS_PER_ROW);
            local offset = floor((foundIndex-1) / NUM_GEARSET_ICONS_PER_ROW);
            offset = offset + min((NUM_GEARSET_ICON_ROWS-1), offsetnumIcons-offset) - (NUM_GEARSET_ICON_ROWS-1);
            if(foundIndex<=NUM_GEARSET_ICONS_SHOWN) then
                offset = 0;
            end
            FauxScrollFrame_OnVerticalScroll(GearManagerDialogPopupScrollFrame, offset*GEARSET_ICON_ROW_HEIGHT, GEARSET_ICON_ROW_HEIGHT, nil);
        end
        GearManagerDialogPopup_Update();
    end
end

end

-- -------------------------------------------------------------------------------------
-- Inform the server that we're reloading UI and the addon might be disabled from now on
-- -------------------------------------------------------------------------------------
local oReloadUI = ReloadUI;
ReloadUI = function(...)
    if ezCollections.Allowed then
        ezCollections:SendAddonMessage("RELOADUI");
    end
    oReloadUI(...);
end

-- ---------------------------------
-- Add support for custom hyperlinks
-- ---------------------------------
local oChatFrame_OnHyperlinkShow = ChatFrame_OnHyperlinkShow;
ChatFrame_OnHyperlinkShow = function(self, link, text, button, ...)
    if ( strsub(link, 1, 16) == "transmogillusion" ) then
        if ( IsModifiedClick("CHATLINK") ) then
            local _, sourceID = strsplit(":", link);
            local itemLink = select(6, C_TransmogCollection.GetAppearanceSourceInfo(sourceID));
            HandleModifiedItemClick(itemLink);
        elseif not HandleModifiedItemClick(link) then
            DressUpTransmogLink(link);
        end
        return;
    elseif ( strsub(link, 1, 18) == "transmogappearance" ) then
        if ( IsModifiedClick("CHATLINK") ) then
            local _, sourceID = strsplit(":", link);
            local itemLink = select(6, C_TransmogCollection.GetAppearanceSourceInfo(sourceID));
            HandleModifiedItemClick(itemLink);
        elseif IsModifiedClick("DRESSUP") then
            DressUpTransmogLink(link);
        else
            if ( not CollectionsJournal ) then
                CollectionsJournal_LoadUI();
            end
            if ( CollectionsJournal ) then
                WardrobeCollectionFrame_OpenTransmogLink(link);
            end
        end
        return;
    end
    return oChatFrame_OnHyperlinkShow(self, link, text, button, ...);
end

-- ------------------------------------------------------------
-- Add extra lines to tooltips about collection-related objects
-- ------------------------------------------------------------
local function GetTooltipItem(tooltip)
    local name, link = tooltip:GetItem();
    if not link then return; end
    local _, id, _ = strsplit(":", link);
    if not id then return; end
    id = tonumber(id);
    if id == ITEM_BACK or id == ITEM_HIDDEN then return; end
    return id, name, link;
end

local function IsTooltipItemCollectible(tooltip)
    local function ForEach(func, ...)
        for i = 1, select("#", ...) do
            local region = select(i, ...)
            if region and region:GetObjectType() == "FontString" then
                if func(region) then
                    return true;
                end
            end
        end
    end

    return not ForEach(function(line)
        local text = line:GetText();
        if text and (text:match(FormatToPattern(ITEM_DURATION_SEC)) or
                     text:match(FormatToPattern(ITEM_DURATION_MIN)) or
                     text:match(FormatToPattern(ITEM_DURATION_HOURS)) or
                     text:match(FormatToPattern(ITEM_DURATION_DAYS))) then
            return true;
        end
    end, tooltip:GetRegions());
end

local function TooltipHandlerItem(tooltip)
    if not ezCollections.Allowed then return; end

    local id = GetTooltipItem(tooltip);
    if not id then return; end

    local show = false;
    if ezCollections.Config.TooltipSets.Collected   and ezCollections:IsSkinSource(id) == true and ezCollections:HasSkin(id) == true
    or ezCollections.Config.TooltipSets.Uncollected and ezCollections:IsSkinSource(id) == true and ezCollections:HasSkin(id) == false then
        local info = ezCollections:GetSkinInfo(id);
        if info and info.Sets then
            local color = ezCollections.Config.TooltipSets.Color;
            if ezCollections.Config.TooltipSets.Separator then tooltip:AddLine(" "); end
            if #info.Sets == 1 then
                local set = ezCollections.Cache.Sets[info.Sets[1]];
                tooltip:AddDoubleLine(format(L["Tooltip.Sets.Header.Singular"], format("|cFF%s%s|r", RGBPercToHex(color.r, color.g, color.b), set.name)), set.description, color.r * 0.75, color.g * 0.75, color.b * 0.75, color.r * 0.75, color.g * 0.75, color.b * 0.75, false);
            else
                tooltip:AddLine(format(L["Tooltip.Sets.Header.Plural"], #info.Sets), color.r * 0.75, color.g * 0.75, color.b * 0.75, false);
                for _, setID in ipairs(info.Sets) do
                    local set = ezCollections.Cache.Sets[setID];
                    tooltip:AddDoubleLine(format(L["Tooltip.Sets.Set"], format("|cFF%s%s|r", RGBPercToHex(color.r, color.g, color.b), set.name)), set.description, color.r * 0.75, color.g * 0.75, color.b * 0.75, color.r * 0.75, color.g * 0.75, color.b * 0.75, false);
                end
            end
            show = true;
        end
    end
    local color = ezCollections.Config.TooltipCollection.Color;
    local separator = not ezCollections.Config.TooltipCollection.Separator;
    if ezCollections.Config.TooltipCollection.OwnedItems and ezCollections:HasOwnedItem(id) == false then
        if not separator then separator = true; tooltip:AddLine(" "); end
        tooltip:AddLine(L["Tooltip.OwnedItems"], color.r, color.g, color.b, false);
        show = true;
    end
    if ezCollections.Config.TooltipCollection.Skins and ezCollections:IsSkinSource(id) == true and ezCollections:HasSkin(id) == false and IsTooltipItemCollectible(tooltip) then
        if not separator then separator = true; tooltip:AddLine(" "); end
        tooltip:AddLine(L["Tooltip.Skins"], color.r, color.g, color.b, false);
        show = true;
    end
    if show then
        tooltip:Show();
    end
end
local function TooltipHandlerClear(tooltip)
    ezCollections.itemUnderCursor.ID = nil;
    ezCollections.itemUnderCursor.Bag = nil;
    ezCollections.itemUnderCursor.Slot = nil;
end
local function TooltipHandlerHyperlink(tooltip, link)
    if not ezCollections.Allowed then return; end

    local linkType, linkData = strsplit(":", link);
    if linkType == "quest" then
        local id = tonumber((linkData));

        local show = false;
        local color = ezCollections.Config.TooltipCollection.Color;
        local separator = not ezCollections.Config.TooltipCollection.Separator;
        if ezCollections.Config.TooltipCollection.TakenQuests and ezCollections:HasTakenQuest(id) == false then
            if not separator then separator = true; tooltip:AddLine(" "); end
            tooltip:AddLine(L["Tooltip.TakenQuests"], color.r, color.g, color.b, false);
            show = true;
        elseif ezCollections.Config.TooltipCollection.RewardedQuests and ezCollections:HasRewardedQuest(id) == false then
            if not separator then separator = true; tooltip:AddLine(" "); end
            tooltip:AddLine(L["Tooltip.RewardedQuests"], color.r, color.g, color.b, false);
            show = true;
        end
        if show then
            tooltip:Show();
        end
    end
end
local function TooltipHandlerInventory(tooltip, ...)
    if not ezCollections.Allowed then return; end

    local id = GetTooltipItem(tooltip);
    if not id then return; end

    if ezCollections:IsSkinSource(id) == true then
        local show = false;

        local unit, bag, slot;
        if type(select(1, ...)) == "string" then
            unit, bag = ...;
        else
            unit = "player";
            bag, slot = ...;
        end

        local hasPendingUndo, pendingEntry, hasPendingIllusionUndo, pendingEnchant = unpack(ezCollections.pendingTooltipInfo);

        if ezCollections.Config.TooltipTransmog.Enable or ezCollections.Config.TooltipFlags.Enable then
            local fakeEntry, fakeEnchantName, fakeEnchant, flags, fakeEntryDeactivated = ezCollections:GetItemTransmog(unit, bag, slot);
            if pendingEntry or pendingEnchant then
                if pendingEntry and pendingEntry ~= 0 then
                    fakeEntry = pendingEntry;
                    fakeEntryDeactivated = false;
                end
                if pendingEnchant and pendingEnchant ~= 0 then
                    fakeEnchant = pendingEnchant;
                    fakeEnchantName = select(2, GetItemInfo(fakeEnchant));
                    if fakeEnchantName then
                        fakeEnchantName = ezCollections:TransformEnchantName(fakeEnchantName);
                    else
                        fakeEnchantName = L["Tooltip.Transmog.Loading"];
                    end
                end
            end
            local prefixText = "";
            local text = "";
            if ezCollections.Config.TooltipFlags.Enable then
                local color = ezCollections.Config.TooltipFlags.Color;
                local colorHex = "|cFF"..RGBPercToHex(color.r, color.g, color.b);
                if flags and flags ~= "" then
                    prefixText = prefixText..(#prefixText > 0 and "|n" or "")..colorHex..flags.."|r";
                end
            end
            if ezCollections.Config.TooltipTransmog.Enable then
                local color = ezCollections.Config.TooltipTransmog.Color;
                local colorHex = "|cFF"..RGBPercToHex(color.r, color.g, color.b);
                if fakeEntry and fakeEntry ~= 0 or hasPendingUndo then
                    if hasPendingUndo then
                        text = text..colorHex..TRANSMOGRIFY_TOOLTIP_REVERT.."|r";
                    else
                        if pendingEntry or pendingEnchant then
                            text = text..colorHex..WILL_BE_TRANSMOGRIFIED_HEADER.."|r";
                        else
                            text = text..colorHex..TRANSMOGRIFIED_HEADER.."|r";
                        end
                        local name = GetItemInfo(fakeEntry);
                        local texture = ezCollections:GetSkinIcon(fakeEntry);
                        if fakeEntry == ITEM_HIDDEN then
                            name = L["Tooltip.Transmog.Entry.Hidden"];
                            texture = [[Interface\PaperDollInfoFrame\UI-GearManager-LeaveItem-Transparent]];
                        end
                        if not name or not texture then
                            name = "|cFFFF0000"..RETRIEVING_ITEM_INFO.."|r";
                            texture = [[Interface\Icons\INV_Misc_QuestionMark]];
                            ezCollections:QueryItem(fakeEntry);
                        end
                        local size = ezCollections.Config.TooltipTransmog.IconEntry.Size or 0;
                        local crop = ezCollections.Config.TooltipTransmog.IconEntry.Crop and ":0:0:64:64:6:58:6:58" or "";
                        if fakeEntry == ITEM_HIDDEN and ezCollections.Config.TooltipTransmog.NewHideVisualIcon then
                            texture = [[Interface\AddOns\ezCollections\Interface\Transmogrify\Transmogrify]];
                            crop = ":0:0:512:512:417:443:90:116";
                        end
                        local icon = ezCollections.Config.TooltipTransmog.IconEntry.Enable and ("|T"..texture..":"..size..":"..size..crop.."|t ") or "";
                        text = text.."|n"..colorHex..icon..format(L[fakeEntryDeactivated and "Tooltip.Transmog.EntryFormat.Deactivated" or "Tooltip.Transmog.EntryFormat"], name).."|r";
                    end
                end
                if fakeEnchant and fakeEnchant ~= 0 or hasPendingIllusionUndo then
                    local size = ezCollections.Config.TooltipTransmog.IconEnchant.Size or 0;
                    local icon = ezCollections.Config.TooltipTransmog.IconEnchant.Enable and [[|TInterface\AddOns\ezCollections\Textures\EnchantIcon:]]..size..":"..size..":0:0:64:64:7:55:8:56|t " or "";
                    -- [[|TInterface\Icons\INV_Scroll_05:0:0:0:0:64:64:6:58:6:58|t ]]
                    if fakeEnchant == ENCHANT_HIDDEN and ezCollections.Config.TooltipTransmog.NewHideVisualIcon then
                        icon = [[|TInterface\AddOns\ezCollections\Interface\Transmogrify\Transmogrify:]]..size..":"..size..":0:0:512:512:417:443:90:116|t ";
                    end
                    text = text..(#text > 0 and "|n" or "")..colorHex..icon..format(L["Tooltip.Transmog.EnchantFormat"], hasPendingIllusionUndo and TRANSMOGRIFY_TOOLTIP_REVERT or fakeEnchantName).."|r";
                end
            end
            if text ~= "" then
                for i = 2,3 do
                    local line = _G[tooltip:GetName().."TextLeft"..i];
                    if line and line:GetText() and line:GetText():match(ITEM_LEVEL) then
                        line:SetText(line:GetText().."|n"..text);
                        line:SetNonSpaceWrap(false);
                        show = true;
                        break;
                    end
                end
                if not show then
                    for i = 2,5 do
                        local line = _G[tooltip:GetName().."TextLeft"..i];
                        if line and line:GetText() and not line:GetText():match(ITEM_HEROIC) and not line:GetText():match(ITEM_HEROIC_EPIC) then
                            line:SetText(text.."|n"..line:GetText());
                            line:SetNonSpaceWrap(false);
                            show = true;
                            break;
                        end
                    end
                end
            end
            if prefixText ~= "" then
                for i = 2, 2 do
                    local line = _G[tooltip:GetName().."TextLeft"..i];
                    if line and line:GetText() then
                        line:SetText(prefixText.."|n"..line:GetText());
                        line:SetNonSpaceWrap(false);
                        show = true;
                        break;
                    end
                end
            end
        end

        if ezCollections.Config.TooltipCollection.SkinUnlock and unit == "player" and ezCollections:HasSkin(id) == false and IsTooltipItemCollectible(tooltip) then
            local color = ezCollections.Config.TooltipCollection.Color;
            local text;
            if GetBindingKey("EZCOLLECTIONS_UNLOCK_SKIN") then
                text = format(L["Tooltip.UnlockSkin.Binding"], table.concat({ GetBindingKey("EZCOLLECTIONS_UNLOCK_SKIN") }, L["Tooltip.UnlockSkin.Binding.Separator"]));
            else
                text = format(L["Tooltip.UnlockSkin.Command"], ezCollections.UnlockSkinHintCommand);
            end
            tooltip:AddLine(text, color.r * 0.75, color.g * 0.75, color.b * 0.75, false);
            ezCollections.itemUnderCursor.ID = id;
            ezCollections.itemUnderCursor.Bag = bag;
            ezCollections.itemUnderCursor.Slot = slot;
            show = true;
        end

        if (ezCollections.Config.RestoreItemSets.Equipment and unit == "player" or ezCollections.Config.RestoreItemSets.Inspect and UnitIsUnit(unit, "target") and GetUnitName("target") == ezCollections.lastInspectTarget) and bag >= 1 and bag <= 19 then
            for i = 1, 30 do
                local line = _G[tooltip:GetName().."TextLeft"..i];
                local line2 = _G[tooltip:GetName().."TextLeft"..(i+1)];
                local line3 = _G[tooltip:GetName().."TextLeft"..(i+2)];
                if line and line:GetText() and line:GetText() ~= " " and not line:GetText():match("|c") and IsSameColor({ line:GetTextColor() }, 1, 0.8235, 0) and
                   line2 and line2:GetText() and line2:GetText() ~= " " and not line2:GetText():match("|c") and (IsSameColor({ line2:GetTextColor() }, 0.5, 0.5, 0.5) or IsSameColor({ line2:GetTextColor() }, 1, 1, 0.5922)) and
                   line3 and line3:GetText() and line3:GetText() ~= " " and not line3:GetText():match("|c") and (IsSameColor({ line3:GetTextColor() }, 0.5, 0.5, 0.5) or IsSameColor({ line3:GetTextColor() }, 1, 1, 0.5922)) then
                    local data = ezCollections:GetItemSetData(unit, id);
                    local setName, count, max = line:GetText():match(FormatToPattern(ITEM_SET_NAME));
                    if not data or not setName or not count or not max or not tonumber(max) or tonumber(max) == 0 then break; end
                    line:SetText(ITEM_SET_NAME:format(setName, data.EquippedItemCount, tonumber(max)));
                    for index, item in ipairs(data.SetItems) do
                        i = i + 1;
                        line = _G[tooltip:GetName().."TextLeft"..i];
                        if not line or line:GetText() == " " then -- Can happen if items are still caching
                            i = i - 1;
                            break;
                        end
                        if data.EquippedItems[index] then
                            line:SetTextColor(1, 1, 0x97 / 0xFF, 1); -- Hardcoded in .exe
                        else
                            line:SetTextColor(0.5, 0.5, 0.5, 1); -- Hardcoded in .exe
                        end
                        if data.EquippedItemNames[index] then
                            line:SetText(("  %s"):format(data.EquippedItemNames[index])); -- Hardcoded in .exe
                        end
                    end
                    i = i + 1;
                    line = _G[tooltip:GetName().."TextLeft"..i];
                    if line and line:GetText() == " " then
                        for index, threshold in ipairs(data.SetSpellThresholds) do
                            i = i + 1;
                            line = _G[tooltip:GetName().."TextLeft"..i];
                            local _, description = line:GetText():match(FormatToPattern(ITEM_SET_BONUS_GRAY));
                            if not description then
                                description = line:GetText():match(FormatToPattern(ITEM_SET_BONUS));
                            end
                            if description then
                                if data.EquippedItemCount >= threshold then
                                    line:SetFormattedText(ITEM_SET_BONUS, description);
                                    line:SetTextColor(0, 1, 0, 1); -- Hardcoded in .exe
                                else
                                    line:SetFormattedText(ITEM_SET_BONUS_GRAY, threshold, description);
                                    line:SetTextColor(0.5, 0.5, 0.5, 1); -- Hardcoded in .exe
                                end
                            end
                        end
                    end
                    break;
                end
            end
        end

        if show then
            tooltip:Show();
        end
    end
end

CreateFrame("Frame", ADDON_NAME.."TooltipHooker", UIParent):SetScript("OnUpdate", function(self, ...)
    local tooltips =
    {
        -- Game's own tooltips
        GameTooltip, ItemRefTooltip,
        -- Tooltips from other addons (feel free to add yours)
        AtlasLootTooltip, AtlasQuestTooltip, LightHeadedTooltip, MobMapTooltip, PWTooltip,
    };
    for k, tooltip in pairs(tooltips) do
        if tooltip then
            tooltip:HookScript("OnTooltipSetItem", TooltipHandlerItem);
            tooltip:HookScript("OnTooltipCleared", TooltipHandlerClear);
            hooksecurefunc(tooltip, "SetHyperlink", TooltipHandlerHyperlink);
            hooksecurefunc(tooltip, "SetInventoryItem", TooltipHandlerInventory);
            hooksecurefunc(tooltip, "SetBagItem", TooltipHandlerInventory);
        end
    end
    self:SetScript("OnUpdate", nil);
end);
