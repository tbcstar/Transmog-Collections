local ADDON_NAME = ...;
local ADDON_VERSION = GetAddOnMetadata(ADDON_NAME, "Version");

local ADDON_PREFIX = "ezCollections";
local ENCHANT_HIDDEN = 88;
local ITEM_HIDDEN = 15;
local ITEM_BACK = 16;
TRANSMOGRIFY_FONT_COLOR = { r = 1, g = 0.5, b = 1 };
TRANSMOGRIFY_FONT_COLOR_CODE = "|cFFFF80FF";

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

local INVTYPE_ENUM_TO_NAME =
{
    [0] = "INVTYPE_NON_EQUIP",
    [1] = "INVTYPE_HEAD",
    [2] = "INVTYPE_NECK",
    [3] = "INVTYPE_SHOULDER",
    [4] = "INVTYPE_BODY",
    [5] = "INVTYPE_CHEST",
    [6] = "INVTYPE_WAIST",
    [7] = "INVTYPE_LEGS",
    [8] = "INVTYPE_FEET",
    [9] = "INVTYPE_WRIST",
    [10] = "INVTYPE_HAND",
    [11] = "INVTYPE_FINGER",
    [12] = "INVTYPE_TRINKET",
    [13] = "INVTYPE_WEAPON",
    [14] = "INVTYPE_SHIELD",
    [15] = "INVTYPE_RANGED",
    [16] = "INVTYPE_CLOAK",
    [17] = "INVTYPE_2HWEAPON",
    [18] = "INVTYPE_BAG",
    [19] = "INVTYPE_TABARD",
    [20] = "INVTYPE_ROBE",
    [21] = "INVTYPE_WEAPONMAINHAND",
    [22] = "INVTYPE_WEAPONOFFHAND",
    [23] = "INVTYPE_HOLDABLE",
    [24] = "INVTYPE_AMMO",
    [25] = "INVTYPE_THROWN",
    [26] = "INVTYPE_RANGEDRIGHT",
    [27] = "INVTYPE_QUIVER",
    [28] = "INVTYPE_RELIC",
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
    self:RegisterEvent("PLAYER_LOGOUT");
    self:RegisterEvent("INSPECT_TALENT_READY");
    self:RegisterEvent("UNIT_INVENTORY_CHANGED");
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
    self:RegisterEvent("BANKFRAME_OPENED");
    self:RegisterEvent("BAG_UPDATE");
    self:RegisterEvent("PLAYERBANKSLOTS_CHANGED");
    self:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED");
    self:RegisterEvent("ADDON_LOADED");
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("COMPANION_LEARNED");
    self:RegisterEvent("COMPANION_UNLEARNED");
    self:RegisterEvent("SPELL_UPDATE_USABLE");
    self:RegisterEvent("ACTIONBAR_UPDATE_USABLE");
    self:RegisterEvent("UNIT_SPELLCAST_START");
    self:RegisterEvent("UNIT_SPELLCAST_FAILED");
    self:RegisterEvent("PLAYER_REGEN_ENABLED");
    self:RegisterEvent("PLAYER_REGEN_DISABLED");

    local function MakePresetColor(order, name, hex, r, g, b, a)
        if not r then
            a, r, g, b = hex:match("|c(%x%x)(%x%x)(%x%x)(%x%x)");
            a = (tonumber(a or "FF", 16) or 255) / 255;
            r = (tonumber(r or "FF", 16) or 255) / 255;
            g = (tonumber(g or "FF", 16) or 255) / 255;
            b = (tonumber(b or "FF", 16) or 255) / 255;
        end
        return { Name = hex..name..FONT_COLOR_CODE_CLOSE, r = r, g = g, b = b, a = a, code = hex, key = format("%08x:%s", order, name) };
    end
    local PRESET_COLORS =
    {
        red         = MakePresetColor( 50, L["Color.Red"],      "|cFFFF0000"),
        orange      = MakePresetColor(100, L["Color.Orange"],   "|cFFF89133"),
        gold        = MakePresetColor(200, L["Color.Gold"],     "|cFFFFD200"),
        yellow      = MakePresetColor(300, L["Color.Yellow"],   "|cFFFFFF00"),
        dandelion   = MakePresetColor(350, L["Color.Dandelion"],"|cFFEBE140"),
        green       = MakePresetColor(400, L["Color.Green"],    "|cFF6BCC45"),
        teal        = MakePresetColor(450, L["Color.Teal"],     "|cFF009C70"),
        cyan        = MakePresetColor(500, L["Color.Cyan"],     "|cFF15A9F8"),
        blue        = MakePresetColor(600, L["Color.Blue"],     "|cFF88AAFF"),
        pink        = MakePresetColor(700, L["Color.Pink"],     TRANSMOGRIFY_FONT_COLOR_CODE, TRANSMOGRIFY_FONT_COLOR.r, TRANSMOGRIFY_FONT_COLOR.g, TRANSMOGRIFY_FONT_COLOR.b),
        white       = MakePresetColor(800, L["Color.White"],    "|cFFFFFFFF"),
        gray        = MakePresetColor(850, L["Color.Gray"],     "|cFF808080"),
        black       = MakePresetColor(900, L["Color.Black"],    "|cFF000000"),
    };

    local defaultsConfig =
    {
        profile =
        {
            NewVersion =
            {
                HideRetiredPopup = false,
                SkipVersionPopup = nil,
            },
            ChatLinks =
            {
                OutfitIcon =
                {
                    Enable = true,
                    Size = 17,
                    Offset = -2,
                },
            },
            Alerts =
            {
                AddSkin =
                {
                    Enable = true,
                    Color = { Custom = false, r = PRESET_COLORS["pink"].r, g = PRESET_COLORS["pink"].g, b = PRESET_COLORS["pink"].b, a = PRESET_COLORS["pink"].a },
                    FullRowColor = false,
                },
                AddToy =
                {
                    Enable = true,
                    Color = { Custom = false, r = PRESET_COLORS["yellow"].r, g = PRESET_COLORS["yellow"].g, b = PRESET_COLORS["yellow"].b, a = PRESET_COLORS["yellow"].a },
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
                    Crop = true,
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
                Toys = true,
                ToyUnlock = true,
                ToyUnlockEmbed = true,
                Color = { Custom = false, r = PRESET_COLORS["blue"].r, g = PRESET_COLORS["blue"].g, b = PRESET_COLORS["blue"].b, a = PRESET_COLORS["blue"].a },
                Separator = true,
            },
            TooltipSets =
            {
                Collected = true,
                Uncollected = true,
                Color = { Custom = false, r = PRESET_COLORS["blue"].r, g = PRESET_COLORS["blue"].g, b = PRESET_COLORS["blue"].b, a = PRESET_COLORS["blue"].a },
                Separator = true,
                SlotStateStyle = 2,
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
            Misc =
            {
                WintergraspButton = true,
                CFBGFactionIcons = true,
                CompressCache = true,
            },
            ActionButtons =
            {
                Mounts = true,
                MountsPerf = true,
                Toys = true,
                Addons =
                {
                    Bartender = true,
                    ButtonForge = true,
                    Dominos = true,
                    KActionBars = true,
                    LibActionButton = true,
                },
            },
            IconOverlays =
            {
                Enable = true,
                Cosmetic =
                {
                    Enable = true,
                },
                Junk =
                {
                    Enable = true,
                    Merchant = true,
                },
                ShowRecipes = true,
                Known =
                {
                    Enable = true,
                    Texture = "Known",
                    Style = "Shadow",
                    Color = { Custom = false, r = PRESET_COLORS["green"].r, g = PRESET_COLORS["green"].g, b = PRESET_COLORS["green"].b, a = PRESET_COLORS["green"].a },
                    Anchor = "TOPRIGHT",
                    Offset = 2,
                    Size = 13,
                },
                Unknown =
                {
                    Enable = true,
                    Texture = "Unknown",
                    Style = "Shadow",
                    Color = { Custom = false, r = PRESET_COLORS["orange"].r, g = PRESET_COLORS["orange"].g, b = PRESET_COLORS["orange"].b, a = PRESET_COLORS["orange"].a },
                    Anchor = "TOPRIGHT",
                    Offset = 2,
                    Size = 13,
                },
                Unowned =
                {
                    Enable = false,
                    Texture = "Unowned",
                    Style = "Shadow",
                    Color = { Custom = false, r = PRESET_COLORS["pink"].r, g = PRESET_COLORS["pink"].g, b = PRESET_COLORS["pink"].b, a = PRESET_COLORS["pink"].a },
                    Anchor = "TOPRIGHT",
                    Offset = 0,
                    Size = 13,
                },
                Addons =
                {
                    ["*"] = true,
                },
                AddonConfig = (function()
                    local result =
                    {
                        ["*"] = { },
                    };
                    for addon, module in pairs(ezCollections.IconOverlays:GetAddons()) do
                        if module.GetDefaults then
                            result[addon] = module.GetDefaults();
                        end
                    end
                    return result;
                end)(),
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
                DressUpGnomeTrollBackground = true,
                DressUpDesaturateBackground = false,
                DressUpSkipDressOnShow = false,
                PortraitButton = false,
                MountsUnusableInZone = false,
                MountsShowHidden = false,
                PetsShowHidden = false,
                ToysShowHidden = false,
                ShowCollectedToySourceText = false,
                TooltipCycleKeyboard = false,
                TooltipCycleMouseWheel = true,
                MountsDoubleClickIcon = false,
                MountsDoubleClickName = true,
                PetsDoubleClickIcon = false,
                PetsDoubleClickName = true,
                SearchClientside = true,
                SearchCacheNames = true,
                SearchSetsBySources = true,
                ElvUIDressUpFirstLaunch = false,
                ShowSetsInAppearances = true,
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
            ToyBox =
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
                    toyBoxCollectedFilters = 0, -- Bitfield for which collected filters are applied in the toybox
                    toyBoxExpansionFilters = 0, -- Bitfield for which expansion filters are applied in the toybox
                    toyBoxSourceFilters = 0, -- Bitfield for which source filters are applied in the toybox
                    showOutfitDetails = true, -- dressing room is opened in maximized mode, default on
                    -- Custom
                    transmogrifyShowClaimable = true,
                    transmogrifyShowPurchasable = true,
                    transmogrifyShowObtainable = true,
                    transmogrifyShowUnobtainable = false,
                    transmogrifyArmorFilters = 0,
                    transmogrifyClassFilters = 0,
                    transmogrifyRaceFilters = 0,
                    transmogrifyExpansionFilters = 0,
                    wardrobeArmorFilters = 0,
                    wardrobeClassFilters = 0,
                    wardrobeRaceFilters = 0,
                    wardrobeExpansionFilters = 0,
                    wardrobeSetsClassFilters = 0,
                    wardrobeSetsRaceFilters = 0,
                    wardrobeSetsExpansionFilters = 0,
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
            RecipeToDressable = { },
            Sets = { },
            Cameras = { },
            Toys = { },
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

    do
        for slot, db in pairs(ezCollections.Cache.Slot) do
            if db.Packed then
                for id in db.Packed:gmatch("[^,]+") do
                    table.insert(db, tonumber(id));
                end
                db.Packed = nil;
            end
        end
        for id, info in pairs(ezCollections.Cache.All) do
            if type(id) == "number" and type(info) == "string" then
                ezCollections.Cache.All[id] = ezCollections.UnpackSkin(info);
            end
        end
        local setsUnpacked = false;
        for id, info in pairs(ezCollections.Cache.Sets) do
            if  type(id) == "number" and type(info) == "string" then
                ezCollections.Cache.Sets[id] = ezCollections.UnpackSet(id, info);
                setsUnpacked = true;
            end
        end
        if setsUnpacked then
            ezCollections:PostprocessSetsAfterLoading();
        end
    end

    -- General
    local panels = { };
    local showAdvancedOptions = false;
    local bigButtonCounter = 1;
    local mediumButtonCounter = 1;
    local chatFontTextCounter = 1;
    local settingsButtonCounter = 1;
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
    LibStub("AceGUI-3.0"):RegisterWidgetType("ezCollectionsOptionsMediumButtonTemplate", function()
        local self =
        {
            type = "ezCollectionsOptionsMediumButtonTemplate",
            frame = CreateFrame("Button", "ezCollectionsOptionsMediumButton"..mediumButtonCounter, nil, "ezCollectionsOptionsMediumButtonTemplate"),
        };
        self.frame.obj = self;
        mediumButtonCounter = mediumButtonCounter + 1;
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
    LibStub("AceGUI-3.0"):RegisterWidgetType("ezCollectionsOptionsChatFontTextTemplate", function()
        local self =
        {
            type = "ezCollectionsOptionsChatFontTextTemplate",
            frame = CreateFrame("Frame", "ezCollectionsOptionsChatFontText"..chatFontTextCounter, nil, "ezCollectionsOptionsChatFontTextTemplate"),
        };
        self.frame.obj = self;
        chatFontTextCounter = chatFontTextCounter + 1;
        function self:OnAcquire()
        end
        function self:OnRelease()
        end
        function self:SetLabel(text)
            self.frame.Text:SetFont(DEFAULT_CHAT_FRAME:GetFont());
            self.frame.Text:SetText(text);
            self.frame:SetHeight(math.max(30, self.frame.Text:GetStringHeight()));
        end
        function self:SetText(text)
        end
        LibStub("AceGUI-3.0"):RegisterAsWidget(self);
        return self;
    end, 1);
    LibStub("AceGUI-3.0"):RegisterWidgetType("ezCollectionsOptionsCheckBoxWithSettingsTemplate", function()
        local self = LibStub("AceGUI-3.0"):Create("CheckBox");
        self.settingsButton = CreateFrame("CheckButton", "ezCollectionsCheckBoxWithSettings"..settingsButtonCounter, self.frame, "ezCollectionsOptionsCheckBoxWithSettingsTemplate");
        self.settingsButton.obj = self;
        settingsButtonCounter = settingsButtonCounter + 1;
        function self.settingsButton:GetArg()
            return self.obj:GetUserDataTable().option.arg;
        end
        return self;
    end, 1);
    hooksecurefunc("FCF_SetChatWindowFontSize", function()
        for i = 1, chatFontTextCounter do
            local frame = _G["ezCollectionsOptionsChatFontText"..i];
            if frame then
                frame.Text:SetFont(DEFAULT_CHAT_FRAME:GetFont());
            end
        end
    end);

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
                if menuBar and not InCombatLockdown() then
                    local copy = { }; for k, v in ipairs(buttons) do copy[k] = v; end
                    menuBar.buttons = copy;
                    menuBar:LoadButtons();
                    menuBar:Layout();
                end
                return;
            end
            if Bartender4 and Bartender4:GetModule("MicroMenu") then
                local self = Bartender4:GetModule("MicroMenu");
                if self.bar then
                    local copy = { }; for k, v in ipairs(buttons) do copy[k] = v; end
                    self.bar.buttons = copy;
                    self.button_count = #buttons
                    for i,v in pairs(buttons) do
                        v:SetParent(self.bar)
                        v:Show()
                        v:SetFrameLevel(self.bar:GetFrameLevel() + 1)
                        v.ClearSetPoint = self.bar.ClearSetPoint
                    end
                end
                return;
            end
            if ElvUI then
                local E = unpack(ElvUI);
                local AB = E:GetModule("ActionBars");
                AB.ezCollectionsMicroButtons = buttons;
                AB:UpdateMicroPositionDimensions();
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
        function ezCollectionsBartender4Hook()
            if Bartender4 and Bartender4:GetModule("MicroMenu") then
                hooksecurefunc(Bartender4:GetModule("MicroMenu"), "OnEnable", setupCollectionsMicroButton);
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
                            InterfaceOptionsFrame_OpenToCategory(panels["general"]);
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
                            InterfaceOptionsFrame_OpenToCategory(panels["general"]);
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

    local InterfaceOptionsFrame_OpenToCategory = InterfaceOptionsFrame_OpenToCategory_Fix or InterfaceOptionsFrame_OpenToCategory;
    ezCollections.ConfigHandlers =
    {
        Color =
        {
            disabled = function(self, info) return not info.arg.Enable; end,
            values = function(self, info)
                local values = { custom = L["Color.Custom"] };
                for k, v in pairs(PRESET_COLORS) do
                    values[v.key] = v.Name;
                end
                return values;
            end,
            get = function(self, info)
                local color = info.arg.Color;
                if not color.Custom then
                    for k, v in pairs(PRESET_COLORS) do
                        if v.r == color.r and v.g == color.g and v.b == color.b and v.a == color.a then
                            return v.key;
                        end
                    end
                end
                return "custom";
            end,
            set = function(self, info, value)
                local color = info.arg.Color;
                if value == "custom" then
                    color.Custom = true;
                else
                    color.Custom = false;
                    for k, v in pairs(PRESET_COLORS) do
                        if v.key == value then
                            color.r, color.g, color.b, color.a = v.r, v.g, v.b, v.a;
                        end
                    end
                end
            end,
        },
        CustomColor =
        {
            get = function(self, info)             local color = info.arg.Color; return color.r,     color.g,     color.b,     color.a;     end,
            set = function(self, info, r, g, b, a) local color = info.arg.Color;        color.r = r; color.g = g; color.b = b; color.a = a; end,
            disabled = function(self, info) return not info.arg.Enable or self:disabled2(info); end,
            disabled2 = function(self, info) return not info.arg.Color.Custom; end,
        },
        Keybind =
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
        },
    };
    ezCollections.ConfigHelpers = { };
    function ezCollections.ConfigHelpers.IntegrationAddonName(name)
        return function(info)
            return format(L[info.option.disabled() and "Config.Integration.ActionButtons.Addons.NotFound" or "Config.Integration.ActionButtons.Addons.Found"], name);
        end;
    end
    local reloadUINeeded = false;
    local reloadUINeeded2 = false;
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
                        hidden = true,
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
                            SkipVersionPopup =
                            {
                                type = "toggle",
                                name = L["Config.NewVersion.SkipVersionPopup"],
                                width = "full",
                                order = 200,
                                get = function(info) return ezCollections.NewVersion and ezCollections.Config.NewVersion.SkipVersionPopup == ezCollections.NewVersion.Version; end,
                                set = function(info, value)
                                    if value and ezCollections.NewVersion then
                                        ezCollections.Config.NewVersion.SkipVersionPopup = ezCollections.NewVersion.Version;
                                    else
                                        ezCollections.Config.NewVersion.SkipVersionPopup = nil;
                                    end
                                end,
                                hidden = function() return ezCollections.NewVersion and ezCollections.NewVersion.Disabled; end,
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
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["wardrobe"]); end,
                        dialogControl = "ezCollectionsOptionsBigButtonTemplate",
                    },
                    panelMounts =
                    {
                        type = "input",
                        name = format(L["Config.General.Panel.Tab"], MOUNTS),
                        order = 150.1,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["mounts"]); end,
                        dialogControl = "ezCollectionsOptionsMediumButtonTemplate",
                    },
                    panelPets =
                    {
                        type = "input",
                        name = format(L["Config.General.Panel.Tab"], COMPANIONS),
                        order = 150.2,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["pets"]); end,
                        dialogControl = "ezCollectionsOptionsMediumButtonTemplate",
                    },
                    panelToys =
                    {
                        type = "input",
                        name = format(L["Config.General.Panel.Tab"], TOY_BOX),
                        order = 150.3,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["toys"]); end,
                        dialogControl = "ezCollectionsOptionsMediumButtonTemplate",
                        hidden = function() return not _G["CollectionsJournalTab"..3] or _G["CollectionsJournalTab"..3].isDisabled; end,
                    },
                    panelHeirlooms =
                    {
                        type = "input",
                        name = format(L["Config.General.Panel.Tab"], HEIRLOOMS),
                        order = 150.4,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["heirlooms"]); end,
                        dialogControl = "ezCollectionsOptionsMediumButtonTemplate",
                        hidden = function() return not _G["CollectionsJournalTab"..4] or _G["CollectionsJournalTab"..4].isDisabled; end,
                    },
                    panelAppearances =
                    {
                        type = "input",
                        name = format(L["Config.General.Panel.Tab"], WARDROBE),
                        order = 150.5,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["appearances"]); end,
                        dialogControl = "ezCollectionsOptionsMediumButtonTemplate",
                    },
                    panelTransmogrify =
                    {
                        type = "input",
                        name = format(L["Config.General.Panel.Tab"], TRANSMOGRIFY),
                        width = GetLocale() == "ruRU" and "double" or nil,
                        order = 150.9,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["transmogrify"]); end,
                        dialogControl = "ezCollectionsOptionsMediumButtonTemplate",
                    },
                    panelIntegration =
                    {
                        type = "input",
                        name = L["Config.General.Panel.Integration"],
                        width = "full",
                        order = 155,
                        get = function() return L["Config.General.Panel.Integration.Desc"] end,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["integration"]); end,
                        dialogControl = "ezCollectionsOptionsBigButtonTemplate",
                    },
                    panelChat =
                    {
                        type = "input",
                        name = L["Config.Integration.Chat"],
                        order = 155.1,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["chat"]); end,
                        dialogControl = "ezCollectionsOptionsMediumButtonTemplate",
                    },
                    panelTooltips =
                    {
                        type = "input",
                        name = L["Config.Integration.Tooltips"],
                        order = 155.2,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["tooltips"]); end,
                        dialogControl = "ezCollectionsOptionsMediumButtonTemplate",
                    },
                    panelMicroButtons =
                    {
                        type = "input",
                        name = L["Config.Integration.MicroButtons"],
                        order = 155.3,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["microButtons"]); end,
                        dialogControl = "ezCollectionsOptionsMediumButtonTemplate",
                    },
                    panelMinimapButtons =
                    {
                        type = "input",
                        name = L["Config.Integration.MinimapButtons"],
                        order = 155.4,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["minimapButtons"]); end,
                        dialogControl = "ezCollectionsOptionsMediumButtonTemplate",
                    },
                    panelActionButtons =
                    {
                        type = "input",
                        name = L["Config.Integration.ActionButtons"],
                        order = 155.5,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["actionButtons"]); end,
                        dialogControl = "ezCollectionsOptionsMediumButtonTemplate",
                    },
                    panelItemButtons =
                    {
                        type = "input",
                        name = L["Config.Integration.ItemButtons"],
                        order = 155.6,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["itemButtons"]); end,
                        dialogControl = "ezCollectionsOptionsMediumButtonTemplate",
                    },
                    panelDressUp =
                    {
                        type = "input",
                        name = L["Config.Integration.DressUp"],
                        order = 155.7,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["dressUp"]); end,
                        dialogControl = "ezCollectionsOptionsMediumButtonTemplate",
                    },
                    panelBindings =
                    {
                        type = "input",
                        name = L["Config.General.Panel.Bindings"],
                        width = "full",
                        order = 160,
                        get = function() return L["Config.General.Panel.Bindings.Desc"] end,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["bindings"]); end,
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
                    panelMounts =
                    {
                        type = "input",
                        name = format(L["Config.General.Panel.Tab"], MOUNTS),
                        order = 0.1,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["mounts"]); end,
                        dialogControl = "ezCollectionsOptionsMediumButtonTemplate",
                    },
                    panelPets =
                    {
                        type = "input",
                        name = format(L["Config.General.Panel.Tab"], COMPANIONS),
                        order = 0.2,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["pets"]); end,
                        dialogControl = "ezCollectionsOptionsMediumButtonTemplate",
                    },
                    panelToys =
                    {
                        type = "input",
                        name = format(L["Config.General.Panel.Tab"], TOY_BOX),
                        order = 0.3,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["toys"]); end,
                        dialogControl = "ezCollectionsOptionsMediumButtonTemplate",
                        hidden = function() return not _G["CollectionsJournalTab"..3] or _G["CollectionsJournalTab"..3].isDisabled; end,
                    },
                    panelHeirlooms =
                    {
                        type = "input",
                        name = format(L["Config.General.Panel.Tab"], HEIRLOOMS),
                        order = 0.4,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["heirlooms"]); end,
                        dialogControl = "ezCollectionsOptionsMediumButtonTemplate",
                        hidden = function() return not _G["CollectionsJournalTab"..4] or _G["CollectionsJournalTab"..4].isDisabled; end,
                    },
                    panelAppearances =
                    {
                        type = "input",
                        name = format(L["Config.General.Panel.Tab"], WARDROBE),
                        order = 0.5,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["appearances"]); end,
                        dialogControl = "ezCollectionsOptionsMediumButtonTemplate",
                    },
                    panelTransmogrify =
                    {
                        type = "input",
                        name = format(L["Config.General.Panel.Tab"], TRANSMOGRIFY),
                        width = GetLocale() == "ruRU" and "double" or nil,
                        order = 0.9,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["transmogrify"]); end,
                        dialogControl = "ezCollectionsOptionsMediumButtonTemplate",
                    },
                    storage =
                    {
                        type = "group",
                        name = L["Config.Wardrobe.Misc.Storage"],
                        inline = true,
                        order = 50,
                        args =
                        {
                            CompressCache =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.CompressCache"],
                                desc = L["Config.Wardrobe.CompressCache.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 100,
                                get = function(info) return ezCollections.Config.Misc.CompressCache; end,
                                set = function(info, value) ezCollections.Config.Misc.CompressCache = value; end,
                            },
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
                },
            },
            mounts =
            {
                type = "group",
                name = L["Config.Mounts"],
                args =
                {
                    list =
                    {
                        type = "group",
                        name = L["Config.Mounts.List"],
                        inline = true,
                        order = 100,
                        args =
                        {
                            doubleClickIcon =
                            {
                                type = "toggle",
                                name = L["Config.Mounts.List.DoubleClick.Icon"],
                                width = "full",
                                order = 50,
                                get = function(info) return ezCollections.Config.Wardrobe.MountsDoubleClickIcon; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.MountsDoubleClickIcon = value; end,
                            },
                            doubleClickName =
                            {
                                type = "toggle",
                                name = L["Config.Mounts.List.DoubleClick.Name"],
                                width = "full",
                                order = 51,
                                get = function(info) return ezCollections.Config.Wardrobe.MountsDoubleClickName; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.MountsDoubleClickName = value; end,
                            },
                            lb1 = { type = "description", name = " ", order = 99 },
                            mountsUnusableInZone =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.MountsUnusableInZone"],
                                desc = L["Config.Wardrobe.MountsUnusableInZone.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 100,
                                get = function(info) return ezCollections.Config.Wardrobe.MountsUnusableInZone; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.MountsUnusableInZone = value; ezCollections.Callbacks.MountListUpdated(); end,
                            },
                            mountsShowHidden =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.MountsShowHidden"],
                                desc = L["Config.Wardrobe.MountsShowHidden.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 200,
                                get = function(info) return ezCollections.Config.Wardrobe.MountsShowHidden; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.MountsShowHidden = value; ezCollections.Callbacks.MountListUpdated(); end,
                            },
                        },
                    },
                },
            },
            pets =
            {
                type = "group",
                name = L["Config.Pets"],
                args =
                {
                    list =
                    {
                        type = "group",
                        name = L["Config.Pets.List"],
                        inline = true,
                        order = 100,
                        args =
                        {
                            doubleClickIcon =
                            {
                                type = "toggle",
                                name = L["Config.Pets.List.DoubleClick.Icon"],
                                width = "full",
                                order = 50,
                                get = function(info) return ezCollections.Config.Wardrobe.PetsDoubleClickIcon; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.PetsDoubleClickIcon = value; end,
                            },
                            doubleClickName =
                            {
                                type = "toggle",
                                name = L["Config.Pets.List.DoubleClick.Name"],
                                width = "full",
                                order = 51,
                                get = function(info) return ezCollections.Config.Wardrobe.PetsDoubleClickName; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.PetsDoubleClickName = value; end,
                            },
                            lb1 = { type = "description", name = " ", order = 99 },
                            petsShowHidden =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.PetsShowHidden"],
                                desc = L["Config.Wardrobe.PetsShowHidden.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 100,
                                get = function(info) return ezCollections.Config.Wardrobe.PetsShowHidden; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.PetsShowHidden = value; ezCollections.Callbacks.PetListUpdated(); end,
                            },
                        },
                    },
                },
            },
            toys =
            {
                type = "group",
                name = L["Config.Toys"],
                args =
                {
                    list =
                    {
                        type = "group",
                        name = L["Config.Toys.List"],
                        inline = true,
                        order = 100,
                        args =
                        {
                            toysShowHidden =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.ToysShowHidden"],
                                desc = L["Config.Wardrobe.ToysShowHidden.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 100,
                                get = function(info) return ezCollections.Config.Wardrobe.ToysShowHidden; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.ToysShowHidden = value; ezCollections.Callbacks.ToyListUpdated(); end,
                            },
                            showCollectedToySourceText =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.ShowCollectedToySourceText"],
                                width = "full",
                                order = 200,
                                get = function(info) return ezCollections.Config.Wardrobe.ShowCollectedToySourceText; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.ShowCollectedToySourceText = value; end,
                            },
                        },
                    },
                },
            },
            heirlooms =
            {
                type = "group",
                name = L["Config.Heirlooms"],
                args =
                {
                },
            },
            appearances =
            {
                type = "group",
                name = L["Config.Appearances"],
                args =
                {
                    sets =
                    {
                        type = "group",
                        name = L["Config.Appearances.Sets"],
                        inline = true,
                        order = 200,
                        args =
                        {
                            ShowSetsInAppearances =
                            {
                                type = "toggle",
                                name = L["Config.Appearances.Sets.ShowSetsInAppearances"],
                                desc = L["Config.Appearances.Sets.ShowSetsInAppearances.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 50,
                                get = function(info) return ezCollections.Config.Wardrobe.ShowSetsInAppearances; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.ShowSetsInAppearances = value; end,
                            },
                            tooltipCycleKeyboard =
                            {
                                type = "toggle",
                                name = L["Config.Appearances.Sets.TooltipCycle.Keyboard"],
                                desc = L["Config.Appearances.Sets.TooltipCycle.Keyboard.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 100,
                                get = function(info) return ezCollections.Config.Wardrobe.TooltipCycleKeyboard; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.TooltipCycleKeyboard = value; end,
                            },
                            tooltipCycleMouseWheel =
                            {
                                type = "toggle",
                                name = L["Config.Appearances.Sets.TooltipCycle.MouseWheel"],
                                width = "full",
                                order = 200,
                                get = function(info) return ezCollections.Config.Wardrobe.TooltipCycleMouseWheel; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.TooltipCycleMouseWheel = value; end,
                            },
                            ShowWowheadSetIcon =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.ShowWowheadSetIcon"],
                                width = "full",
                                order = 300,
                                get = function(info) return ezCollections.Config.Wardrobe.ShowWowheadSetIcon; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.ShowWowheadSetIcon = value; ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED"); end,
                            },
                        },
                    },
                    search =
                    {
                        type = "group",
                        name = L["Config.Appearances.Search"],
                        inline = true,
                        order = 900,
                        args =
                        {
                            clientside =
                            {
                                type = "toggle",
                                name = L["Config.Appearances.Search.Clientside"],
                                desc = L["Config.Appearances.Search.Clientside.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 100,
                                get = function(info) return ezCollections.Config.Wardrobe.SearchClientside; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.SearchClientside = value; end,
                            },
                            cacheNames =
                            {
                                type = "toggle",
                                name = L["Config.Appearances.Search.CacheNames"],
                                desc = L["Config.Appearances.Search.CacheNames.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 200,
                                disabled = function(info) return not ezCollections.Config.Wardrobe.SearchClientside; end,
                                get = function(info) return ezCollections.Config.Wardrobe.SearchCacheNames and ezCollections.Config.Wardrobe.SearchClientside; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.SearchCacheNames = value; table.wipe(ezCollections.ItemNamesForSearch); table.wipe(ezCollections.SetNamesForSearch); end,
                            },
                            setsBySources =
                            {
                                type = "toggle",
                                name = L["Config.Appearances.Search.SetsBySources"],
                                desc = L["Config.Appearances.Search.SetsBySources.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 300,
                                disabled = function(info) return not ezCollections.Config.Wardrobe.SearchClientside or not ezCollections.Config.Wardrobe.SearchCacheNames; end,
                                get = function(info) return ezCollections.Config.Wardrobe.SearchSetsBySources and ezCollections.Config.Wardrobe.SearchClientside and ezCollections.Config.Wardrobe.SearchCacheNames; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.SearchSetsBySources = value; table.wipe(ezCollections.SetNamesForSearch); end,
                            },
                        },
                    },
                    misc =
                    {
                        type = "group",
                        name = L["Config.Wardrobe.Misc.Misc"],
                        inline = true,
                        order = 1000,
                        args =
                        {
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
                },
            },
            transmogrify =
            {
                type = "group",
                name = L["Config.Transmogrify"],
                args =
                {
                    sets =
                    {
                        type = "group",
                        name = L["Config.Transmogrify.Sets"],
                        inline = true,
                        order = 100,
                        args =
                        {
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
                        },
                    },
                    outfits =
                    {
                        type = "group",
                        name = L["Config.Wardrobe.Misc.Outfits"],
                        inline = true,
                        order = 200,
                        args =
                        {
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
                        },
                    },
                    search =
                    {
                        type = "group",
                        name = L["Config.Appearances.Search"],
                        inline = true,
                        order = 900,
                        args =
                        {
                            clientside =
                            {
                                type = "toggle",
                                name = L["Config.Appearances.Search.Clientside"],
                                desc = L["Config.Appearances.Search.Clientside.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 100,
                                get = function(info) return ezCollections.Config.Wardrobe.SearchClientside; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.SearchClientside = value; end,
                            },
                            cacheNames =
                            {
                                type = "toggle",
                                name = L["Config.Appearances.Search.CacheNames"],
                                desc = L["Config.Appearances.Search.CacheNames.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 200,
                                disabled = function(info) return not ezCollections.Config.Wardrobe.SearchClientside; end,
                                get = function(info) return ezCollections.Config.Wardrobe.SearchCacheNames and ezCollections.Config.Wardrobe.SearchClientside; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.SearchCacheNames = value; table.wipe(ezCollections.ItemNamesForSearch); table.wipe(ezCollections.SetNamesForSearch); end,
                            },
                            setsBySources =
                            {
                                type = "toggle",
                                name = L["Config.Appearances.Search.SetsBySources"],
                                desc = L["Config.Appearances.Search.SetsBySources.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 300,
                                disabled = function(info) return not ezCollections.Config.Wardrobe.SearchClientside or not ezCollections.Config.Wardrobe.SearchCacheNames; end,
                                get = function(info) return ezCollections.Config.Wardrobe.SearchSetsBySources and ezCollections.Config.Wardrobe.SearchClientside and ezCollections.Config.Wardrobe.SearchCacheNames; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.SearchSetsBySources = value; table.wipe(ezCollections.SetNamesForSearch); end,
                            },
                        },
                    },
                    misc =
                    {
                        type = "group",
                        name = L["Config.Wardrobe.Misc.Misc"],
                        inline = true,
                        order = 1000,
                        args =
                        {
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
                    panelChat =
                    {
                        type = "input",
                        name = L["Config.Integration.Chat"],
                        order = 0.1,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["chat"]); end,
                        dialogControl = "ezCollectionsOptionsMediumButtonTemplate",
                    },
                    panelTooltips =
                    {
                        type = "input",
                        name = L["Config.Integration.Tooltips"],
                        order = 0.2,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["tooltips"]); end,
                        dialogControl = "ezCollectionsOptionsMediumButtonTemplate",
                    },
                    panelMicroButtons =
                    {
                        type = "input",
                        name = L["Config.Integration.MicroButtons"],
                        order = 0.3,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["microButtons"]); end,
                        dialogControl = "ezCollectionsOptionsMediumButtonTemplate",
                    },
                    panelMinimapButtons =
                    {
                        type = "input",
                        name = L["Config.Integration.MinimapButtons"],
                        order = 0.4,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["minimapButtons"]); end,
                        dialogControl = "ezCollectionsOptionsMediumButtonTemplate",
                    },
                    panelActionButtons =
                    {
                        type = "input",
                        name = L["Config.Integration.ActionButtons"],
                        order = 0.5,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["actionButtons"]); end,
                        dialogControl = "ezCollectionsOptionsMediumButtonTemplate",
                    },
                    panelItemButtons =
                    {
                        type = "input",
                        name = L["Config.Integration.ItemButtons"],
                        order = 0.6,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["itemButtons"]); end,
                        dialogControl = "ezCollectionsOptionsMediumButtonTemplate",
                    },
                    panelDressUp =
                    {
                        type = "input",
                        name = L["Config.Integration.DressUp"],
                        order = 0.7,
                        func = function() InterfaceOptionsFrame_OpenToCategory(panels["dressUp"]); end,
                        dialogControl = "ezCollectionsOptionsMediumButtonTemplate",
                    },
                    restoreItemIcons =
                    {
                        type = "group",
                        name = L["Config.RestoreItemIcons"],
                        inline = true,
                        order = 100,
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
                        order = 200,
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
                    misc =
                    {
                        type = "group",
                        name = L["Config.Integration.Misc"],
                        inline = true,
                        order = 1000,
                        hidden = function() return ezCollections.NewVersion and ezCollections.NewVersion.Disabled; end,
                        args =
                        {
                            wintergraspButton =
                            {
                                type = "toggle",
                                name = L["Config.Integration.Misc.WintergraspButton"],
                                desc = L["Config.Integration.Misc.WintergraspButton.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 100,
                                get = function(info) return ezCollections.Config.Misc.WintergraspButton; end,
                                set = function(info, value) ezCollections.Config.Misc.WintergraspButton = value; ezCollections:SetWintergraspButton(value); end,
                            },
                            CFBGFactionIcons =
                            {
                                type = "toggle",
                                name = L["Config.Integration.Misc.CFBGFactionIcons"],
                                desc = L["Config.Integration.Misc.CFBGFactionIcons.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 200,
                                get = function(info) return ezCollections.Config.Misc.CFBGFactionIcons; end,
                                set = function(info, value) ezCollections.Config.Misc.CFBGFactionIcons = value; MiniMapBattlefieldFrame_isArena(); PlayerFrame_UpdatePvPStatus(); end,
                            },
                        },
                    },
                },
            },
            chat =
            {
                type = "group",
                name = format(L["Config.Integration.CategoryFormat"], L["Config.Integration.Chat"]),
                args =
                {
                    links =
                    {
                        type = "group",
                        name = L["Config.Integration.Chat.Links"],
                        inline = true,
                        order = 50,
                        args =
                        {
                            outfitIconEnable =
                            {
                                type = "toggle",
                                name = L["Config.Integration.Chat.Links.OutfitIcon"],
                                width = "full",
                                order = 100,
                                get = function(info) return ezCollections.Config.ChatLinks.OutfitIcon.Enable; end,
                                set = function(info, value) ezCollections.Config.ChatLinks.OutfitIcon.Enable = value; end,
                            },
                            outfitIconSize =
                            {
                                type = "range",
                                name = L["Config.Integration.Chat.Links.OutfitIcon.Size"],
                                desc = L["Config.Integration.Chat.Links.OutfitIcon.Size.Desc"],
                                min = 0,
                                max = 32,
                                softMin = 8,
                                bigStep = 1,
                                width = "half",
                                order = 101,
                                get = function(info) return ezCollections.Config.ChatLinks.OutfitIcon.Size; end,
                                set = function(info, value) ezCollections.Config.ChatLinks.OutfitIcon.Size = value; end,
                                disabled = function() return not ezCollections.Config.ChatLinks.OutfitIcon.Enable; end,
                            },
                            outfitIconOffset =
                            {
                                type = "range",
                                name = L["Config.Integration.Chat.Links.OutfitIcon.Offset"],
                                desc = L["Config.Integration.Chat.Links.OutfitIcon.Offset.Desc"],
                                min = -10,
                                max = 10,
                                bigStep = 1,
                                width = "half",
                                order = 102,
                                get = function(info) return ezCollections.Config.ChatLinks.OutfitIcon.Offset; end,
                                set = function(info, value) ezCollections.Config.ChatLinks.OutfitIcon.Offset = value; end,
                                disabled = function() return not ezCollections.Config.ChatLinks.OutfitIcon.Enable; end,
                            },
                            outfitIconExample =
                            {
                                type = "input",
                                name = function()
                                    local icon, text = TRANSMOG_OUTFIT_HYPERLINK_TEXT:match("^(|T.-|t)(.-)$");
                                    icon = icon and ezCollections.Config.ChatLinks.OutfitIcon.Enable and icon:gsub("13:13:%-1:1", format("%1$d:%1$d:-1:%2$d", ezCollections.Config.ChatLinks.OutfitIcon.Size or 13, ezCollections.Config.ChatLinks.OutfitIcon.Offset or 1));
                                    return format(L["Config.Integration.Chat.Links.OutfitIcon.Example"], icon or "", text or "");
                                end,
                                order = 103,
                                dialogControl = "ezCollectionsOptionsChatFontTextTemplate",
                            },
                        },
                    },
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
                                order = 101,
                                handler = ezCollections.ConfigHandlers.Color, values = "values", get = "get", set = "set", disabled = "disabled",
                                arg = ezCollections.Config.Alerts.AddSkin,
                            },
                            customColor =
                            {
                                type = "color",
                                name = L["Config.Alerts.AddSkin.CustomColor"],
                                desc = L["Config.Alerts.AddSkin.CustomColor.Desc"],
                                width = "half",
                                order = 102,
                                handler = ezCollections.ConfigHandlers.CustomColor, get = "get", set = "set", disabled = "disabled",
                                arg = ezCollections.Config.Alerts.AddSkin,
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
                            lb1 = { type = "description", name = " ", order = 199 },
                            addToyEnable =
                            {
                                type = "toggle",
                                name = L["Config.Alerts.AddToy.Enable"],
                                desc = L["Config.Alerts.AddToy.Enable.Desc"],
                                width = "full",
                                order = 200,
                                get = function(info) return ezCollections.Config.Alerts.AddToy.Enable; end,
                                set = function(info, value) ezCollections.Config.Alerts.AddToy.Enable = value; end,
                            },
                            addToyColor =
                            {
                                type = "select",
                                name = L["Config.Alerts.AddToy.Color"],
                                desc = L["Config.Alerts.AddToy.Color.Desc"],
                                order = 201,
                                handler = ezCollections.ConfigHandlers.Color, values = "values", get = "get", set = "set", disabled = "disabled",
                                arg = ezCollections.Config.Alerts.AddToy,
                            },
                            addToyCustomColor =
                            {
                                type = "color",
                                name = L["Config.Alerts.AddToy.CustomColor"],
                                desc = L["Config.Alerts.AddToy.CustomColor.Desc"],
                                width = "half",
                                order = 202,
                                handler = ezCollections.ConfigHandlers.CustomColor, get = "get", set = "set", disabled = "disabled",
                                arg = ezCollections.Config.Alerts.AddToy,
                            },
                        },
                    },
                },
            },
            tooltips =
            {
                type = "group",
                name = format(L["Config.Integration.CategoryFormat"], L["Config.Integration.Tooltips"]),
                args =
                {
                    tooltipFlags =
                    {
                        type = "group",
                        name = L["Config.TooltipFlags"],
                        inline = true,
                        order = 100,
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
                                order = 300,
                                handler = ezCollections.ConfigHandlers.Color, values = "values", get = "get", set = "set", disabled = "disabled",
                                arg = ezCollections.Config.TooltipFlags,
                            },
                            customColor =
                            {
                                type = "color",
                                name = L["Config.TooltipFlags.CustomColor"],
                                desc = L["Config.TooltipFlags.CustomColor.Desc"],
                                order = 301,
                                handler = ezCollections.ConfigHandlers.CustomColor, get = "get", set = "set", disabled = "disabled",
                                arg = ezCollections.Config.TooltipFlags,
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
                            lb3 = { type = "description", name = "", order = 202.5 },
                            iconEnchantPadding1 =
                            {
                                type = "description",
                                name = "",
                                width = "normal",
                                order = 203,
                            },
                            iconEnchantPadding2 =
                            {
                                type = "description",
                                name = "",
                                width = "half",
                                order = 204,
                            },
                            iconEnchantCrop =
                            {
                                type = "toggle",
                                name = L["Config.TooltipTransmog.IconEnchant.Crop"],
                                desc = L["Config.TooltipTransmog.IconEnchant.Crop.Desc"],
                                width = "half",
                                order = 205,
                                get = function(info) return ezCollections.Config.TooltipTransmog.IconEnchant.Crop; end,
                                set = function(info, value) ezCollections.Config.TooltipTransmog.IconEnchant.Crop = value; end,
                                disabled = function() return not ezCollections.Config.TooltipTransmog.Enable or not ezCollections.Config.TooltipTransmog.IconEnchant.Enable; end,
                            },
                            lb4 = { type = "description", name = "", order = 249 },
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
                                order = 300,
                                handler = ezCollections.ConfigHandlers.Color, values = "values", get = "get", set = "set", disabled = "disabled",
                                arg = ezCollections.Config.TooltipTransmog,
                            },
                            customColor =
                            {
                                type = "color",
                                name = L["Config.TooltipTransmog.CustomColor"],
                                desc = L["Config.TooltipTransmog.CustomColor.Desc"],
                                order = 301,
                                handler = ezCollections.ConfigHandlers.CustomColor, get = "get", set = "set", disabled = "disabled",
                                arg = ezCollections.Config.TooltipTransmog,
                            },
                        },
                    },
                    tooltipSets =
                    {
                        type = "group",
                        name = L["Config.TooltipSets"],
                        inline = true,
                        order = 300,
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
                            Appearances =
                            {
                                type = "toggle",
                                name = L["Config.TooltipSets.Appearances"],
                                desc = L["Config.TooltipSets.Appearances.Desc"],
                                width = "full",
                                order = 300,
                                get = function(info) return ezCollections.Config.Wardrobe.ShowSetsInAppearances; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.ShowSetsInAppearances = value; end,
                            },
                            color =
                            {
                                type = "select",
                                name = L["Config.TooltipSets.Color"],
                                desc = L["Config.TooltipSets.Color.Desc"],
                                order = 1000,
                                handler = ezCollections.ConfigHandlers.Color, values = "values", get = "get", set = "set",
                                arg = ezCollections.Config.TooltipSets,
                            },
                            customColor =
                            {
                                type = "color",
                                name = L["Config.TooltipSets.CustomColor"],
                                desc = L["Config.TooltipSets.CustomColor.Desc"],
                                width = "half",
                                order = 1001,
                                handler = ezCollections.ConfigHandlers.CustomColor, get = "get", set = "set", disabled = "disabled2",
                                arg = ezCollections.Config.TooltipSets,
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
                            SlotStateStyle =
                            {
                                type = "select",
                                name = L["Config.TooltipSets.SlotStateStyle"],
                                desc = L["Config.TooltipSets.SlotStateStyle.Desc"],
                                width = "full",
                                order = 1100,
                                values = function()
                                    local values = { };
                                    for i = 1, 4 do
                                        values[i] = L["TooltipSets.SlotStateStyle."..i];
                                    end
                                    return values;
                                end,
                                get = function(info) return ezCollections.Config.TooltipSets.SlotStateStyle; end,
                                set = function(info, value) ezCollections.Config.TooltipSets.SlotStateStyle = value; end,
                            },
                        },
                    },
                    tooltipCollection =
                    {
                        type = "group",
                        name = L["Config.TooltipCollection"],
                        inline = true,
                        order = 400,
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
                                handler = ezCollections.ConfigHandlers.Keybind,
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
                            toys =
                            {
                                type = "toggle",
                                name = L["Config.TooltipCollection.Toys"],
                                desc = L["Config.TooltipCollection.Toys.Desc"],
                                width = "full",
                                order = 500,
                                get = function(info) return ezCollections.Config.TooltipCollection.Toys; end,
                                set = function(info, value) ezCollections.Config.TooltipCollection.Toys = value; end,
                                hidden = function() return not ezCollections.Collections.Toys.Enabled; end,
                            },
                            toyUnlock =
                            {
                                type = "toggle",
                                name = L["Config.TooltipCollection.ToyUnlock"],
                                desc = L["Config.TooltipCollection.ToyUnlock.Desc"],
                                order = 501,
                                get = function(info) return ezCollections.Config.TooltipCollection.ToyUnlock; end,
                                set = function(info, value) ezCollections.Config.TooltipCollection.ToyUnlock = value; end,
                                hidden = function() return not ezCollections.Collections.Toys.Enabled; end,
                            },
                            toyUnlockEmbed =
                            {
                                type = "toggle",
                                name = L["Config.TooltipCollection.ToyUnlock.Embed"],
                                desc = L["Config.TooltipCollection.ToyUnlock.Embed.Desc"],
                                order = 502,
                                get = function(info) return ezCollections.Config.TooltipCollection.ToyUnlockEmbed; end,
                                set = function(info, value) ezCollections.Config.TooltipCollection.ToyUnlockEmbed = value; end,
                                disabled = function() return not ezCollections.Config.TooltipCollection.ToyUnlock; end,
                                hidden = function() return not ezCollections.Collections.Toys.Enabled; end,
                            },
                            lb2 = { type = "description", name = "", order = 999 },
                            color =
                            {
                                type = "select",
                                name = L["Config.TooltipCollection.Color"],
                                desc = L["Config.TooltipCollection.Color.Desc"],
                                order = 1000,
                                handler = ezCollections.ConfigHandlers.Color, values = "values", get = "get", set = "set",
                                arg = ezCollections.Config.TooltipCollection,
                            },
                            customColor =
                            {
                                type = "color",
                                name = L["Config.TooltipCollection.CustomColor"],
                                desc = L["Config.TooltipCollection.CustomColor.Desc"],
                                width = "half",
                                order = 1001,
                                handler = ezCollections.ConfigHandlers.CustomColor, get = "get", set = "set", disabled = "disabled2",
                                arg = ezCollections.Config.TooltipCollection,
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
                },
            },
            microButtons =
            {
                type = "group",
                name = format(L["Config.Integration.CategoryFormat"], L["Config.Integration.MicroButtons"]),
                args =
                {
                    microButtons =
                    {
                        type = "group",
                        name = L["Config.Wardrobe.MicroButtons"],
                        inline = true,
                        order = 100,
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
                },
            },
            minimapButtons =
            {
                type = "group",
                name = format(L["Config.Integration.CategoryFormat"], L["Config.Integration.MinimapButtons"]),
                args =
                {
                    minimapButtons =
                    {
                        type = "group",
                        name = L["Config.Wardrobe.MinimapButtons"],
                        inline = true,
                        order = 100,
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
            actionButtons =
            {
                type = "group",
                name = format(L["Config.Integration.CategoryFormat"], L["Config.Integration.ActionButtons"]),
                args =
                {
                    actionButtons =
                    {
                        type = "group",
                        name = L["Config.Integration.ActionButtons"],
                        inline = true,
                        order = 100,
                        hidden = function() return ezCollections.NewVersion and ezCollections.NewVersion.Disabled; end,
                        args =
                        {
                            desc =
                            {
                                type = "description",
                                name = L["Config.Integration.ActionButtons.Desc"],
                                order = 0,
                            },
                            mounts =
                            {
                                type = "toggle",
                                name = L["Config.Integration.ActionButtons.Mounts"],
                                desc = L["Config.Integration.ActionButtons.Mounts.Desc"],
                                order = 100,
                                get = function(info) return ezCollections.Config.ActionButtons.Mounts; end,
                                set = function(info, value) ezCollections.Config.ActionButtons.Mounts = value; reloadUINeeded2 = true; end,
                            },
                            mountsPerf =
                            {
                                type = "toggle",
                                name = L["Config.Integration.ActionButtons.MountsPerf"],
                                desc = L["Config.Integration.ActionButtons.MountsPerf.Desc"],
                                order = 101,
                                disabled = function() return not ezCollections.Config.ActionButtons.Mounts; end,
                                get = function(info) return ezCollections.Config.ActionButtons.MountsPerf; end,
                                set = function(info, value) ezCollections.Config.ActionButtons.MountsPerf = value; end,
                            },
                            toys =
                            {
                                type = "toggle",
                                name = L["Config.Integration.ActionButtons.Toys"],
                                desc = L["Config.Integration.ActionButtons.Toys.Desc"],
                                width = "full",
                                order = 200,
                                get = function(info) return ezCollections.Config.ActionButtons.Toys; end,
                                set = function(info, value) ezCollections.Config.ActionButtons.Toys = value; reloadUINeeded2 = true; end,
                            },
                            addons =
                            {
                                type = "group",
                                name = L["Config.Integration.ActionButtons.Addons"],
                                inline = true,
                                order = 1000,
                                args =
                                {
                                    Bartender =
                                    {
                                        type = "toggle",
                                        name = ezCollections.ConfigHelpers.IntegrationAddonName("Bartender4"),
                                        width = "full",
                                        order = 100,
                                        disabled = function() return not Bartender4; end,
                                        get = function(info) return ezCollections.Config.ActionButtons.Addons.Bartender; end,
                                        set = function(info, value) ezCollections.Config.ActionButtons.Addons.Bartender = value; reloadUINeeded2 = true; end,
                                    },
                                    ButtonForge =
                                    {
                                        type = "toggle",
                                        name = ezCollections.ConfigHelpers.IntegrationAddonName("ButtonForge"),
                                        width = "full",
                                        order = 200,
                                        disabled = function() return not BFEventFrames; end,
                                        get = function(info) return ezCollections.Config.ActionButtons.Addons.ButtonForge; end,
                                        set = function(info, value) ezCollections.Config.ActionButtons.Addons.ButtonForge = value; reloadUINeeded2 = true; end,
                                    },
                                    Dominos =
                                    {
                                        type = "toggle",
                                        name = ezCollections.ConfigHelpers.IntegrationAddonName("Dominos"),
                                        width = "full",
                                        order = 300,
                                        disabled = function() return not Dominos; end,
                                        get = function(info) return ezCollections.Config.ActionButtons.Addons.Dominos; end,
                                        set = function(info, value) ezCollections.Config.ActionButtons.Addons.Dominos = value; reloadUINeeded2 = true; end,
                                    },
                                    KActionBars =
                                    {
                                        type = "toggle",
                                        name = ezCollections.ConfigHelpers.IntegrationAddonName("KActionBars"),
                                        width = "full",
                                        order = 400,
                                        disabled = function() return not KActionBars; end,
                                        get = function(info) return ezCollections.Config.ActionButtons.Addons.KActionBars; end,
                                        set = function(info, value) ezCollections.Config.ActionButtons.Addons.KActionBars = value; reloadUINeeded2 = true; end,
                                    },
                                    LibActionButton =
                                    {
                                        type = "toggle",
                                        name = ezCollections.ConfigHelpers.IntegrationAddonName("LibActionButton (ElvUI)"),
                                        width = "full",
                                        order = 500,
                                        disabled = function() return not LibStub("LibActionButton-1.0", true) and not LibStub("LibActionButton-1.0-ElvUI", true); end,
                                        get = function(info) return ezCollections.Config.ActionButtons.Addons.LibActionButton; end,
                                        set = function(info, value) ezCollections.Config.ActionButtons.Addons.LibActionButton = value; reloadUINeeded2 = true; end,
                                    },
                                },
                            },
                            reload =
                            {
                                type = "execute",
                                name = L["Config.Integration.ActionButtons.ReloadUI"],
                                desc = L["Config.Integration.ActionButtons.ReloadUI.Desc"],
                                order = 2000,
                                hidden = function() return not reloadUINeeded2; end,
                                func = function() ReloadUI(); end,
                            },
                        },
                    },
                },
            },
            itemButtons =
            {
                type = "group",
                name = format(L["Config.Integration.CategoryFormat"], L["Config.Integration.ItemButtons"]),
                args =
                {
                    IconOverlays = ezCollections.IconOverlays:MakeOptions(),
                },
            },
            dressUp =
            {
                type = "group",
                name = format(L["Config.Integration.CategoryFormat"], L["Config.Integration.DressUp"]),
                args =
                {
                    dressUp =
                    {
                        type = "group",
                        name = function() return L[IsAddOnLoaded("ezCollectionsDressUp") and "Config.Wardrobe.Misc.DressUp" or "Config.Wardrobe.Misc.DressUp.Inactive"]; end,
                        inline = true,
                        order = 100,
                        disabled = function() return not IsAddOnLoaded("ezCollectionsDressUp"); end,
                        args =
                        {
                            dressUpClassBackground =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.DressUp.ClassBackground"],
                                desc = L["Config.Wardrobe.DressUp.ClassBackground.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 100,
                                disabled = function() return not IsAddOnLoaded("ezCollectionsDressUp"); end,
                                get = function(info) return ezCollections.Config.Wardrobe.DressUpClassBackground; end,
                                set = function(info, value)
                                    ezCollections.Config.Wardrobe.DressUpClassBackground = value;
                                    if value then
                                        SetDressUpBackground(DressUpFrame, nil, select(2, UnitClass("player")));
                                    else
                                        SetDressUpBackground(DressUpFrame, select(2, UnitRace("player")));
                                    end
                                end,
                            },
                            DressUpGnomeTrollBackground =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.DressUp.GnomeTrollBackground"],
                                desc = L["Config.Wardrobe.DressUp.GnomeTrollBackground.Desc"],
                                descStyle = "inline",
                                width = "full",
                                order = 150,
                                disabled = function() return not IsAddOnLoaded("ezCollectionsDressUp") or ezCollections.Config.Wardrobe.DressUpClassBackground; end,
                                get = function(info) return ezCollections.Config.Wardrobe.DressUpGnomeTrollBackground; end,
                                set = function(info, value)
                                    ezCollections.Config.Wardrobe.DressUpGnomeTrollBackground = value;
                                    SetDressUpBackground(DressUpFrame, select(2, UnitRace("player")));
                                    if SideDressUpFrame then
                                        SetDressUpBackground(SideDressUpFrame, select(2, UnitRace("player")));
                                    end
                                end,
                            },
                            dressUpDesaturateBackground =
                            {
                                type = "toggle",
                                name = L["Config.Wardrobe.DressUp.DesaturateBackground"],
                                width = "full",
                                order = 200,
                                disabled = function() return not IsAddOnLoaded("ezCollectionsDressUp"); end,
                                get = function(info) return ezCollections.Config.Wardrobe.DressUpDesaturateBackground; end,
                                set = function(info, value)
                                    ezCollections.Config.Wardrobe.DressUpDesaturateBackground = value;
                                    if ezCollections.Config.Wardrobe.DressUpClassBackground then
                                        SetDressUpBackground(DressUpFrame, nil, select(2, UnitClass("player")));
                                    else
                                        SetDressUpBackground(DressUpFrame, select(2, UnitRace("player")));
                                    end
                                    if SideDressUpFrame then
                                        SetDressUpBackground(SideDressUpFrame, select(2, UnitRace("player")));
                                    end
                                end,
                            },
                            DressUpSkipDressOnShow =
                            {
                                type = "toggle",
                                name = L["Config.Integration.DressUp.SkipDressOnShow"],
                                width = "full",
                                order = 300,
                                disabled = function() return not IsAddOnLoaded("ezCollectionsDressUp"); end,
                                get = function(info) return ezCollections.Config.Wardrobe.DressUpSkipDressOnShow; end,
                                set = function(info, value) ezCollections.Config.Wardrobe.DressUpSkipDressOnShow = value; end,
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
                                handler = ezCollections.ConfigHandlers.Keybind,
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
                                handler = ezCollections.ConfigHandlers.Keybind,
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
                                handler = ezCollections.ConfigHandlers.Keybind,
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
                                handler = ezCollections.ConfigHandlers.Keybind,
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
                                handler = ezCollections.ConfigHandlers.Keybind,
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
                                handler = ezCollections.ConfigHandlers.Keybind,
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
                                handler = ezCollections.ConfigHandlers.Keybind,
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
                                handler = ezCollections.ConfigHandlers.Keybind,
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
                                handler = ezCollections.ConfigHandlers.Keybind,
                                arg = "TOGGLECOLLECTIONSPETJOURNAL",
                                get = "Get",
                                set = "Set",
                            },
                            lb9 = { type = "description", name = "", order = 899 },
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
                                handler = ezCollections.ConfigHandlers.Keybind,
                                arg = "TOGGLECOLLECTIONSTOYBOX",
                                get = "Get",
                                set = "Set",
                            },
                            lb10 = { type = "description", name = "", order = 999 },
                            --[[
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
                                handler = ezCollections.ConfigHandlers.Keybind,
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
                                handler = ezCollections.ConfigHandlers.Keybind,
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
                                handler = ezCollections.ConfigHandlers.Keybind,
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
    local function AddPanel(name, root)
        panels[name] = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME, not root and configTable.args[name].name or nil, not root and ADDON_NAME or nil, name);
    end
    AddPanel("general", true);
    AddPanel("wardrobe");
    AddPanel("mounts");
    AddPanel("pets");
    if _G["CollectionsJournalTab"..3] and not _G["CollectionsJournalTab"..3].isDisabled then
        AddPanel("toys");
    end
    if _G["CollectionsJournalTab"..4] and not _G["CollectionsJournalTab"..4].isDisabled then
        AddPanel("heirlooms");
    end
    AddPanel("appearances");
    AddPanel("transmogrify");
    AddPanel("integration");
    AddPanel("chat");
    AddPanel("tooltips");
    AddPanel("microButtons");
    AddPanel("minimapButtons");
    AddPanel("actionButtons");
    AddPanel("itemButtons");
    AddPanel("dressUp");
    AddPanel("bindings");

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
            bar:SetScript("OnUpdate", function() bar:SetWidth(math.floor(self:GetWidth() * 0.75)); end);
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
            bar:SetScript("OnUpdate", function() bar:SetWidth(math.floor(self:GetWidth() * 0.75)); end);
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
    StaticPopupDialogs["EZCOLLECTIONS_COPY_OUTFIT_COMMAND"] =
    {
        text = L["Popup.CopyOutfitCommand"],
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
    StaticPopupDialogs["EZCOLLECTIONS_COMPATIBILITY_DRESSUP"] =
    {
        text = "",
        button1 = "ezCollections",
        button2 = CANCEL,
        button3 = "",
        OnShow = function(self)
            local info = StaticPopupDialogs[self.which];
            local addon = info.incompatibleAddons[1] or "<ERROR>";
            self.text:SetText(format(L["Popup.Error.Compatibility.DressUp"], addon));
            self.button3:SetText(addon);
        end,
        OnAccept = function(self)
            local info = StaticPopupDialogs[self.which];
            local addon = info.incompatibleAddons[1];
            if addon then
                DisableAddOn(addon);
                table.remove(info.incompatibleAddons, 1);
            end
            info:Next();
        end,
        OnAlt = function(self)
            local info = StaticPopupDialogs[self.which];
            DisableAddOn("ezCollectionsDressUp");
            table.wipe(info.incompatibleAddons);
            info:Next();
        end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
        incompatibleAddons = { },
        Start = function(self)
            local incompatibleAddons = { "CloseUp" };
            for _, addon in ipairs(incompatibleAddons) do
                if select(4, GetAddOnInfo(addon)) then
                    table.insert(self.incompatibleAddons, addon);
                end
            end
            if next(self.incompatibleAddons) then
                self:Next();
            end
        end,
        Next = function(self)
            C_Timer.After(0, function()
                if next(self.incompatibleAddons) then
                    StaticPopup_Show("EZCOLLECTIONS_COMPATIBILITY_DRESSUP");
                else
                    StaticPopup_Show("EZCOLLECTIONS_ERROR_RELOADUI", L["Popup.Error.Compatibility.ReloadUI"]);
                end
            end);
        end,
    };

    ezCollections:InitDropDownMenus(); -- Taint avoidance

    if ezCollections.Config.RestoreItemIcons.Equipment or ezCollections.Config.RestoreItemIcons.Inspect then
        self:HookRestoreItemIcons();
    end
    if ezCollections.Config.ActionButtons.Mounts or ezCollections.Config.ActionButtons.Toys then
        self:HookActionBars();
    end

    -- Need to delay this, otherwise the addon gets enabled right during addon loading process and actually gets loaded, but something breaks
    C_Timer.After(1, function()
        if not ezCollections.Config.Wardrobe.ElvUIDressUpFirstLaunch then
            ezCollections.Config.Wardrobe.ElvUIDressUpFirstLaunch = true;
            if not select(4, GetAddOnInfo("ezCollectionsDressUp")) and select(4, GetAddOnInfo("ElvUI")) then
                EnableAddOn("ezCollectionsDressUp");
                StaticPopup_Show("EZCOLLECTIONS_ERROR_RELOADUI", L["Popup.Error.Compatibility.ElvUI.DressUp"]);
            end
        end
    end);

    if select(4, GetAddOnInfo("ezCollectionsDressUp")) then
        StaticPopupDialogs["EZCOLLECTIONS_COMPATIBILITY_DRESSUP"]:Start();
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
local function IsSameColor(aR, aG, aB, bR, bG, bB)
    return abs(aR - bR) <= 0.01
       and abs(aG - bG) <= 0.01
       and abs(aB - bB) <= 0.01;
end
local function FormatToPattern(format)
    return (format:gsub("%d+%$", ""):gsub("%(", "%%("):gsub("%)", "%%)"):gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)"):gsub("|4(.+):%1.+:%1.+;", "%1.-"):gsub("|4(.+);", ".-"));
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
local function GetUnitName(unit)
    local name, server = UnitName(unit);
    if server and server ~= "" then
        return name.."-"..server;
    end
    return name;
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
    InvTypeEnumToName = INVTYPE_ENUM_TO_NAME,
    InvTypeNameToEnum = (function() local tbl = { }; for id, name in ipairs(INVTYPE_ENUM_TO_NAME) do tbl[name] = id; end return tbl; end)(),
    ClassIDToName = CLASS_ID_TO_NAME,
    ClassNameToID = (function() local tbl = { }; for id, name in ipairs(CLASS_ID_TO_NAME) do tbl[name] = id; end return tbl; end)(),
    RaceIDToName = RACE_ID_TO_NAME,
    RaceNameToID = (function() local tbl = { }; for id, name in ipairs(RACE_ID_TO_NAME) do tbl[name] = id; end return tbl; end)(),
    RaceNameToFaction = { HUMAN = FACTION_ALLIANCE, DWARF = FACTION_ALLIANCE, NIGHTELF = FACTION_ALLIANCE, GNOME = FACTION_ALLIANCE, DRAENEI = FACTION_ALLIANCE, ORC = FACTION_HORDE, UNDEAD = FACTION_HORDE, TAUREN = FACTION_HORDE, TROLL = FACTION_HORDE, BLOODELF = FACTION_HORDE, ANY = FACTION_OTHER },
    RaceSortOrder = { "HUMAN", "DWARF", "NIGHTELF", "GNOME", "DRAENEI", "ORC", "UNDEAD", "TAUREN", "TROLL", "BLOODELF" },
    RGBPercToHex = RGBPercToHex,
    TransmogrifiableSlots = TRANSMOGRIFIABLE_SLOTS,
    IsSameColor = IsSameColor,
    FormatToPattern = FormatToPattern,
    MenuItemBack = ITEM_BACK,
    GetItemID = GetItemID,
    GetUnitName = GetUnitName,

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
        Toys = { },
    },
    IsSkinSource     = function(self, item)  local db = self.Cache.All;                  if                   not db.Loaded then return nil; end return db[GetItemID(item)] and true or false; end,
    HasOwnedItem     = function(self, item)  local db = self.Collections.OwnedItems;     if not db.Enabled or not db.Loaded then return nil; end return db[GetItemID(item)] or false; end,
    HasSkin          = function(self, item)  local db = self.Collections.Skins;          if not db.Enabled or not db.Loaded then return nil; end return db[GetItemID(item)] or false; end,
    HasTakenQuest    = function(self, quest) local db = self.Collections.TakenQuests;    if not db.Enabled or not db.Loaded then return nil; end return db[quest] or false; end,
    HasRewardedQuest = function(self, quest) local db = self.Collections.RewardedQuests; if not db.Enabled or not db.Loaded then return nil; end return db[quest] or false; end,
    HasToy           = function(self, toy)   local db = self.Collections.Toys;           if not db.Enabled or not db.Loaded then return nil; end return db[toy]   or false; end,
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
        elseif category == nil                                      then return "ENCHANT";
        end
        return nil;
    end,
    GetDBByCategory = function(self, category)
        return self.Cache.Slot[self:GetSlotByCategory(category)];
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
    GetDressableFromRecipe = function(self, recipe)
        return self.Cache.RecipeToDressable[GetItemID(recipe)];
    end,
    CanHideSlot = function(self, slot)
        return self.HideVisualSlots[slot] or false;
    end,
    GetHiddenVisualItem = function(self)
        return ITEM_HIDDEN;
    end,
    GetHiddenVisualItemName = function(self, slot)
        if type(slot) == "string" then
            slot = GetInventorySlotInfo(slot);
        end
        return slot and TRANSMOGRIFIABLE_SLOTS[slot] and L["Tooltip.Transmog.Entry.Hidden."..TRANSMOGRIFIABLE_SLOTS[slot]] or L["Tooltip.Transmog.Entry.Hidden"];
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
    GetCollectibleStatus = function(self, item)
        item = item and GetItemID(item);
        if item then
            if self:IsSkinSource(item) then
                return self:HasSkin(item);
            end

            local mount = self:GetMountIDByItem(item);
            if mount then
                return self:HasMount(mount);
            end

            local pet = self:GetPetIDByItem(item);
            if pet then
                return self:HasPet(pet);
            end

            local toy = self:GetToyIDByItem(item);
            if toy then
                return self:HasToy(toy);
            end
        end
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
    ItemNamesForSearch = { },
    SetNamesForSearch = { },
    UseServersideTextSearch = function(self)
        return not self.Config.Wardrobe.SearchClientside or not ezCollections.appearanceCacheLoaded;
    end,
    PrepareSearchQuery = function(self, query)
        if not query or query == "" then
            return;
        elseif type(query) == "string" then
            query = query and query:utf8lower();
            query = query and { strsplit(" ", query) };
            for _, part in ipairs(query) do
                if part ~= "" then
                    return query;
                end
            end
        elseif type(query) == "table" then
            return query;
        end
    end,
    InternalSearch = function(self, normalizedText, query)
        if not query or query == "" then
            return true;
        elseif type(query) == "table" then
            for _, part in ipairs(query) do
                if part ~= "" and not normalizedText:find(part, 1, true) then
                    return false;
                end
            end
            return true;
        elseif type(query) == "string" then
            return normalizedText:find(query, 1, true);
        end
    end,
    TextMatchesSearch = function(self, text, query)
        if not query or query == "" then return true; end
        return text and self:InternalSearch(text:utf8lower(), query);
    end,
    ItemMatchesSearch = function(self, item, query)
        if not query or query == "" then return true; end
        local name = self.Config.Wardrobe.SearchCacheNames and self.ItemNamesForSearch[item];
        if not name then
            name = GetItemInfo(item);
            name = name and name:utf8lower();
            if name and self.Config.Wardrobe.SearchCacheNames then
                self.ItemNamesForSearch[item] = name;
            end
        end
        return name and self:InternalSearch(name, query);
    end,
    SetMatchesSearch = function(self, set, query)
        if not query or query == "" then return true; end
        local name = self.Config.Wardrobe.SearchCacheNames and self.SetNamesForSearch[set.setID];
        if not name then
            name = set.name or "";
            name = name.." "..(set.label or "");
            name = name.." "..(set.description or "");
            if self.Config.Wardrobe.SearchCacheNames and self.Config.Wardrobe.SearchSetsBySources then
                for _, source in ipairs(set.sources) do
                    local item = source.id;
                    local itemName;
                    do
                        local name = self.Config.Wardrobe.SearchCacheNames and self.ItemNamesForSearch[item];
                        if not name then
                            name = GetItemInfo(item);
                            name = name and name:utf8lower();
                            if name and self.Config.Wardrobe.SearchCacheNames then
                                self.ItemNamesForSearch[item] = name;
                            end
                        end
                        itemName = name;
                    end
                    name = name.." "..(itemName or "");
                end
            end
            name = name and name:utf8lower();
            if name and self.Config.Wardrobe.SearchCacheNames then
                self.SetNamesForSearch[set.setID] = name;
            end
        end
        return name and self:InternalSearch(name, query);
    end,
    IsSearchInProgress = function(self, type)
        local search = self.LastSearch[type];
        return search.NumResults == nil;
    end,
    IsSearchFinished = function(self, type, token)
        local search = self.LastSearch[type];
        return search.Token == token and search.NumResults == #search.Results;
    end,
    IsSearchMatchingParams = function(self, type, token, category, query, slot, id, enchant)
        query = self:UseServersideTextSearch() and query or "";
        local search = self.LastSearch[type];
        return search.Token == token and
               search.Params[1] == category and
               search.Params[2] == query and
               search.Params[3] == slot and
               search.Params[4] == id and
               search.Params[5] == enchant;
    end,
    Search = function(self, type, category, query, slot)
        query = self:UseServersideTextSearch() and query or "";
        local search = self.LastSearch[type];

        -- Deduplicate search queries
        if type == LE_TRANSMOG_SEARCH_TYPE_ITEMS and category == search.Params[1] and query == search.Params[2] and slot == search.Params[3] then
            if slot and slot ~= 0 then
                local _, id, enchant = strsplit(":", GetInventoryItemLink("player", slot) or "");
                if tonumber(id) == search.Params[4] and tonumber(enchant) == search.Params[5] then
                    return search.Token, search.Results.Loaded;
                end
            else
                return search.Token, search.Results.Loaded;
            end
        end
        if type == LE_TRANSMOG_SEARCH_TYPE_USABLE_SETS and query == search.Params[2] and slot == search.Params[3] and C_TransmogSets.MakeCacheKey() == search.Params[4] then
            return search.Token, search.Results.Loaded;
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
        elseif type == LE_TRANSMOG_SEARCH_TYPE_USABLE_SETS then
            search.Params[4] = C_TransmogSets.MakeCacheKey();
            self:SendAddonMessage(format("TRANSMOGRIFY:SEARCH:%d:%d:%s:%s:%d", type, search.Token, self:GetSlotByCategory(category), self:Encode(query or ""), slot or 0));
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
        for t, search in pairs(self.LastSearch) do
            if not type or type == t then
                search.Token = search.Token + 1;
                table.wipe(search.Params);
                search.NumResults = 0;
                table.wipe(search.Results);
            end
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
    ItemNameDescriptions = { },
    GetSetInfo = function(self, id, baseCollectedOnly)
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
            if not baseCollectedOnly and not set.collected and set.Variants and C_TransmogSets.GetBaseSetsFilter(LE_TRANSMOG_SET_FILTER_GROUP) then
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
    SetPendingTooltipInfo = function(self, context, ...)
        self.pendingTooltipInfo[context] = { ... };
    end,
    ClearPendingTooltipInfo = function(self, context)
        self.pendingTooltipInfo[context] = nil;
    end,
    GetPendingTooltipInfo = function(self, context)
        local info = self.pendingTooltipInfo[context];
        if info then
            return unpack(info);
        end
    end,
    HasPendingTooltipInfo = function(self, context)
        return self.pendingTooltipInfo[context] ~= nil;
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
    MountNameXMountID = nil,
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
    HasMount = function(self, mountID)
        return self:HasAvailableMount(mountID) and not self:IsActiveMountSubscriptionMount(mountID);
    end,
    HasAvailableMount = function(self, mountID)
        return select(11, C_MountJournal.GetMountInfoByID(mountID));
    end,
    GetMountIDByItem = function(self, item)
        return self.ItemIDXMountID[item];
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
    HasPet = function(self, petID)
        return self:HasAvailablePet(petID) and not self:IsActivePetSubscriptionPet(petID);
    end,
    HasAvailablePet = function(self, petID)
        return C_PetJournal.PetIsUsable(petID);
    end,
    GetPetIDByItem = function(self, item)
        return self.ItemIDXPetID[item];
    end,
    GetPetFavoritesContainer = function(self)
        return self.Config.PetJournal.PerCharacter[self:GetCharacterConfigKey()].Favorites;
    end,
    GetPetNeedFanfareContainer = function(self)
        return self.Config.PetJournal.PerCharacter[self:GetCharacterConfigKey()].NeedFanfare;
    end,

    -- Toys
    ItemIDXToyID = { },
    ItemNameXToyItemID = { },
    ActiveToySubscriptionEndTime = 0,
    ActiveToySubscriptionInfo = nil,
    ActiveToySubscriptionToys = { },
    IsActiveToySubscription = function(self)
        return self.ActiveToySubscriptionEndTime and self.ActiveToySubscriptionEndTime > 0 and time() < self.ActiveToySubscriptionEndTime;
    end,
    GetActiveToySubscriptionEndTime = function(self)
        return self:IsActiveToySubscription() and self.ActiveToySubscriptionEndTime or nil;
    end,
    IsActiveToySubscriptionToy = function(self, toyID)
        return self:IsActiveToySubscription() and self.ActiveToySubscriptionToys[toyID] and true or false;
    end,
    GetToyInfo = function(self, toyID)
        local toy = self.Cache.Toys[toyID];
        if toy then
            return unpack(toy);
        end
    end,
    GetToyIDByItem = function(self, item)
        return self.ItemIDXToyID[item];
    end,
    GetToyInfoByItem = function(self, item)
        local toyID = self:GetToyIDByItem(item);
        if toyID then
            return self:GetToyInfo(toyID);
        end
    end,
    GetToyItemByName = function(self, name)
        return self.ItemNameXToyItemID[name];
    end,
    GetToyFavoritesContainer = function(self)
        return self.Config.ToyBox.PerCharacter[self:GetCharacterConfigKey()].Favorites;
    end,
    GetToyNeedFanfareContainer = function(self)
        return self.Config.PetJournal.PerCharacter[self:GetCharacterConfigKey()].NeedFanfare;
    end,
    HasAvailableToy = function(self, toyID)
        return self:HasToy(toyID) or self:IsActiveToySubscriptionToy(toyID);
    end,

    -- Cooldowns
    ItemCooldowns = { },
    GetItemCooldownData = function(self, item)
        local cooldown = self.ItemCooldowns[item];
        if cooldown then
            local start, duration, enable = unpack(cooldown);
            if GetTime() < start + duration then
                return start, duration, enable;
            else
                self.ItemCooldowns[item] = nil;
            end
        end
    end,
    GetItemCooldown = function(self, item)
        local start, duration, enable = GetItemCooldown(item);
        local cstart, cduration, cenable = self:GetItemCooldownData(item);
        start = math.max(start, cstart or 0);
        duration = math.max(duration, cduration or 0);
        enable = math.max(enable, cenable and 1 or 0);
        return start, duration, enable;
    end,
    FormatItemCooldown = function(self, remaining)
        local text = "";
        local numbers = 0;
        if remaining >= 86400000 then
            text = text .. format(DAYS_ABBR, math.floor(remaining / 86400000));
            remaining = remaining % 86400000;
            numbers = numbers + 1;
        end
        if remaining >= 3600000 then
            text = text .. (text ~= "" and TIME_UNIT_DELIMITER or "") .. format(HOURS_ABBR, math.floor(remaining / 3600000));
            remaining = remaining % 3600000;
            numbers = numbers + 1;
        end
        if numbers < 2 then
            if remaining >= 60000 then
                text = text .. (text ~= "" and TIME_UNIT_DELIMITER or "") .. format(MINUTES_ABBR, math.floor(remaining / 60000));
                remaining = remaining % 60000;
                numbers = numbers + 1;
            end
            if numbers < 2 and remaining > 0 then
                text = text .. (text ~= "" and TIME_UNIT_DELIMITER or "") .. format(SECONDS_ABBR, math.floor(remaining / 1000));
            end
        end
        if text ~= "" then
            return text;
        end
    end,

    -- Callbacks
    Callbacks =
    {
        AddOwnedItem = function()
            if ezCollections.Config.IconOverlays.Unowned.Enable then
                ezCollections.IconOverlays:Update();
            end
        end,
        RemoveOwnedItem = function()
            if ezCollections.Config.IconOverlays.Unowned.Enable then
                ezCollections.IconOverlays:Update();
            end
        end,
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
                        return;
                    end
                end
                ezCollections.appearanceCacheLoaded = true;
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
                    local info = ezCollections:GetSkinInfo(item);
                    if ezCollections:IsStoreExclusiveItem(item, info) then
                        db.StoreExclusiveCount = (db.StoreExclusiveCount or 0) + 1;
                    end
                    if ezCollections:IsSubscriptionExclusiveItem(item, info) then
                        db.SubscriptionExclusiveCount = (db.SubscriptionExclusiveCount or 0) + 1;
                    end
                    if ezCollections:IsStoreAndSubscriptionExclusiveItem(item, info) then
                        db.StoreAndSubscriptionExclusiveCount = (db.StoreAndSubscriptionExclusiveCount or 0) + 1;
                    end
                end
            end
            -- Refresh UI
            ezCollections:WipeSearchResults();
            C_TransmogCollection.WipeAppearanceCache();
            C_TransmogSets.ReportSetSourceCollectedChanged();
            C_Transmog.ValidateAllPending(true);
            ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
            ezCollections.IconOverlays:Update();
            -- Check Mounts and Pets
            ezCollections.Callbacks.MountListLoaded();
            -- Check Toys
            ezCollections.Callbacks.ToyListLoaded();
        end,
        AddSkin = function(item)
            ezCollections:WipeSearchResults();
            C_TransmogCollection.WipeAppearanceCache();
            C_TransmogCollection.AddNewAppearance(item);
            local info = ezCollections:GetSkinInfo(item);
            if info and info.Sets then
                C_TransmogSets.ReportSetSourceCollectedChanged();
            end
            C_Transmog.ValidateAllPending(true);
            ezCollections.Alerts.AddSkin(item);
            ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
            ezCollections.IconOverlays:Update();
        end,
        RemoveSkin = function(item)
            ezCollections:WipeSearchResults();
            C_TransmogCollection.WipeAppearanceCache();
            local info = ezCollections:GetSkinInfo(item);
            if info and info.Sets then
                C_TransmogSets.ReportSetSourceCollectedChanged();
            end
            C_Transmog.ValidateAllPending(true);
            ezCollections.Alerts.AddSkin(item, true);
            ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
            ezCollections.IconOverlays:Update();
        end,
        ClearSkins = function()
            ezCollections:WipeSearchResults();
            C_TransmogCollection.WipeAppearanceCache();
            C_TransmogSets.ReportSetSourceCollectedChanged();
            C_Transmog.ValidateAllPending(true);
            ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
            ezCollections.IconOverlays:Update();
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
            local category, query, slot, entry, enchant = unpack(search.Params);
            C_TransmogCollection.SearchFinished(type, search.Token, category, query, deepcopy(search.Results));
        end,
        OnChatMessageEventFilter = function(chatFrame, event, text, ...)
            if ezCollections.Config.ChatLinks.OutfitIcon.Enable then
                local replaced;
                text, replaced = text:gsub("(|cffff80ff|Hitem:0:outfit:.-|h)%[([^]]-)%](|h|r)", function(pre, linktext, post)
                    local icon, text = TRANSMOG_OUTFIT_HYPERLINK_TEXT:match("^(|T.-|t)(.-)$");
                    icon = icon and icon:gsub("13:13:%-1:1", format("%1$d:%1$d:-1:%2$d", ezCollections.Config.ChatLinks.OutfitIcon.Size or 13, ezCollections.Config.ChatLinks.OutfitIcon.Offset or 1));
                    return format("|cffff80ff[%s|r%s%s]%s", icon or "", pre or "", linktext or text or "", post or "");
                end);
                if replaced and replaced > 0 then
                    return false, text, ...;
                end
            end
            return false;
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
            ezCollections.Callbacks.MountListUpdated();
            ezCollections.Callbacks.PetListUpdated();
        end,
        MountListUpdated = function()
            ezCollections:RaiseEvent("MOUNT_JOURNAL_SEARCH_UPDATED");
            ezCollections.IconOverlays:Update();
        end,
        PetListUpdated = function()
            ezCollections:RaiseEvent("PET_JOURNAL_SEARCH_UPDATED");
            ezCollections.IconOverlays:Update();
        end,
        ToyListLoaded = function()
            local function SearchForMissingCache(db)
                if ezCollections.itemCacheRequestNeeded or not db.Loaded then
                    return;
                end
                for id, info in pairs(db) do
                    if type(id) == "number" and not GetItemInfo(info[1]) then
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

            SearchForMissingCache(ezCollections.Cache.Toys);

            table.wipe(ezCollections.ItemIDXToyID);
            table.wipe(ezCollections.ItemNameXToyItemID);
            for id, info in pairs(ezCollections.Cache.Toys) do
                if type(id) == "number" and info[1] then
                    ezCollections.ItemIDXToyID[info[1]] = id;
                    local name = GetItemInfo(info[1]);
                    if name then
                        ezCollections.ItemNameXToyItemID[name] = info[1];
                    end
                end
            end

            ezCollections.Callbacks.ToyListUpdated();
        end,
        ToyListUpdated = function()
            ezCollections:RaiseEvent("TOYS_UPDATED");
            ezCollectionsUpdateActionBars();
            ezCollections.IconOverlays:Update();
        end,
        AddToy = function(toyID)
            ezCollections.Alerts.AddToy(toyID);
            local itemID = ezCollections:GetToyInfo(toyID);
            if itemID then
                ezCollections:RaiseEvent("TOYS_UPDATED", itemID, true);
            else
                ezCollections:RaiseEvent("TOYS_UPDATED");
            end
            ezCollectionsUpdateActionBars();
            ezCollections.IconOverlays:Update();
        end,
        RemoveToy = function(toyID)
            ezCollections.Alerts.AddToy(toyID, true);
            ezCollections.Callbacks.ToyListUpdated();
        end,
        ClearToys = function()
            ezCollections.Callbacks.ToyListUpdated();
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
        AddToy = function(toyID, revoke)
            if revoke then return; end
            local config = ezCollections.Config.Alerts.AddToy;
            if not config.Enable then return; end
            local text = ERR_LEARN_TOY_S;
            local color = config.Color;
            local colorHex = "|cFF"..RGBPercToHex(color.r, color.g, color.b);
            text = colorHex..format(text, "|r%s"..colorHex).."|r";
            local itemID = ezCollections:GetToyInfo(toyID);
            if not itemID then return; end
            local _, link = GetItemInfo(itemID);
            if link then
                SendSystemMessage(format(text, link));
            else
                ezCollections:QueryItem(itemID);
                local handler = { };
                handler.func = function(arg)
                    local text, item = unpack(arg);
                    local name = GetItemInfo(item);
                    if name then
                        SendSystemMessage(format(text, link));
                    else
                        ezCollections.AceAddon:ScheduleTimer(handler.func, 1, arg);
                    end
                end;
                handler.func({ text, itemID });
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
    MenuDaily        = function(self) self:SendAddonCommand(".isengard activity"); end,

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
        if bag == -1 and slot then
            bag = BANK_CONTAINER_INVENTORY_OFFSET + slot;
            slot = nil;
        end
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
        elseif (not cache.Loading or cache.ID ~= id) and GetUnitName(unit) == GetUnitName("player") and self.setEmptyItemTransmogCache then
            cache.ID = id;
            cache.Loaded = false;
            cache.Loading = true;
            self:SendAddonMessage("GETTRANSMOG:"..request);
        end
    end,
    EmptyItemTransmogCache = function(self, bag, slot)
        local id = slot and GetContainerItemID(bag, slot) or oGetInventoryItemID("player", bag);
        if id then
            local cache = self:GetItemTransmogCache("player", bag, slot);
            cache.ID = id;
            cache.Loaded = true;
        end
    end,
    setEmptyItemTransmogCache = false,
    SetEmptyItemTransmogCache = function(self)
        if self.setEmptyItemTransmogCache then return; end
        self.setEmptyItemTransmogCache = true;
        for slot=1,150 do
            if not (slot >= BANK_CONTAINER_INVENTORY_OFFSET + 1 and slot <= BANK_CONTAINER_INVENTORY_OFFSET + NUM_BANKGENERIC_SLOTS) then
                self:EmptyItemTransmogCache(slot);
            end
        end
        for bag=0,4 do
            for slot=1,36 do
                self:EmptyItemTransmogCache(bag, slot);
            end
        end
    end,
    setEmptyBankTransmogCache = false,
    SetEmptyBankTransmogCache = function(self)
        if self.setEmptyBankTransmogCache then return; end
        self.setEmptyBankTransmogCache = true;
        for slot = BANK_CONTAINER_INVENTORY_OFFSET + 1, BANK_CONTAINER_INVENTORY_OFFSET + NUM_BANKGENERIC_SLOTS do
            self:EmptyItemTransmogCache(slot);
        end
        for bag=5,11 do
            for slot=1,36 do
                self:EmptyItemTransmogCache(bag, slot);
            end
        end
    end,
    UpdateItemTransmogCache = function(self, bagID)
        local fromSlot = 1;
        local toSlot = 150;
        if bagID == -1 then
            fromSlot = BANK_CONTAINER_INVENTORY_OFFSET + 1;
            toSlot = BANK_CONTAINER_INVENTORY_OFFSET + NUM_BANKGENERIC_SLOTS;
        elseif bagID == 0 then
            fromSlot = CONTAINER_BAG_OFFSET + 1;
            toSlot = CONTAINER_BAG_OFFSET + 16;
        elseif bagID then
            fromSlot = 0;
            toSlot = 0;
        end
        for slot = fromSlot, toSlot do
            local id = oGetInventoryItemID("player", slot);
            if not id then
                self:RemoveItemTransmogCache("player", slot);
            elseif self:PeekItemTransmogCacheID("player", slot) ~= id then
                self:RemoveItemTransmogCache("player", slot);
            end
        end
        for bag = bagID or 0, bagID or 11 do
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
    textScanTooltip = CreateFrame("GameTooltip", ADDON_NAME.."TextScanTooltip", UIParent, "GameTooltipTemplate"),
    ForEachTooltipText = function(self, tooltip, func)
        local function ForEach(func, ...)
            for i = 1, select("#", ...) do
                local region = select(i, ...)
                if region and region:GetObjectType() == "FontString" and region:IsShown() then
                    if func(region) then
                        return true;
                    end
                end
            end
        end
        return ForEach(func, tooltip:GetRegions());
    end,
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
        TOYS_UPDATED = { }, -- itemID, new

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

    -- Hooks
    MergeHook = function(self, name, func)
        local old = _G[name];
        _G[name] = old and function() old(); func(); end or func;
    end,
    DelveInto = function(self, var, ...)
        local num = select("#", ...);
        for i = 1, num do
            if not var then break; end
            var = var[select(i, ...)];
        end
        return var;
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

local cosmeticBags = { };
local function LoadItemTransmog(unit, slotStrings)
    local isPlayer = UnitIsUnit(unit, "player");
    local validateTransmog = false;
    table.wipe(cosmeticBags);
    for slotString in slotStrings:gmatch("(.-):") do
        local slots, itemString = strsplit("=", slotString, 2);
        local bag, slot = strsplit(",", slots, 2);
        local id, fakeEntry, fakeEnchantName, fakeEnchant, flags = strsplit(",", itemString);
        bag = tonumber(bag);
        if slot ~= nil then
            slot = tonumber(slot) + 1;
        else
            bag = bag + 1;
            if isPlayer then
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
        -- Collect bags containing cosmetic items for optimized ezCollections.IconOverlays:Update
        if isPlayer and cache.Flags and cache.Flags:find(ITEM_COSMETIC, 1, true) then
            if not ezCollections.hasCosmeticItems then
                ezCollections.hasCosmeticItems = true;
            end
            if not slot and (bag >= BANK_CONTAINER_INVENTORY_OFFSET + 1 and bag <= BANK_CONTAINER_INVENTORY_OFFSET + NUM_BANKGENERIC_SLOTS) then
                bag = -1;
            end
            cosmeticBags[bag] = true;
        end
    end
    if validateTransmog then
        if WardrobeFrame_IsAtTransmogrifier() then
            C_Transmog.ValidateAllPending(true);
        end
    end
    if isPlayer then
        for bag in pairs(cosmeticBags) do
            ezCollections.IconOverlays:Update(bag);
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
            local module = elvui:GetModule("Enhanced_PaperDoll", true) or elvui:GetModule("Enhanced_EquipmentInfo", true);
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
        if KPack and ezCollections:DelveInto(KPack, "options", "args", "Modules", "args", "list", "args", "Borders Colors") then
            local script = InspectFrame:GetScript("OnShow");
            if script then
                script(InspectFrame);
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
function addon:PLAYER_LOGOUT(event)
    local config = ezCollections:DelveInto(ezCollections, "Config", "Misc", "CompressCache");
    if (config == nil or config == true) and ezCollections.Cache then
        if ezCollections.Cache.Slot then
            for slot, db in pairs(ezCollections.Cache.Slot) do
                local new = { Packed = table.concat(db, ",") };
                for k, v in pairs(db) do
                    if type(k) ~= "number" and k ~= "Packed" then
                        new[k] = v;
                    end
                end
                ezCollections.Cache.Slot[slot] = new;
            end
        end
        if ezCollections.Cache.All then
            for id, info in pairs(ezCollections.Cache.All) do
                if type(id) == "number" and type(info) == "table" then
                    ezCollections.Cache.All[id] = ezCollections.PackSkin(info);
                end
            end
        end
        if ezCollections.Cache.Sets then
            for id, info in pairs(ezCollections.Cache.Sets) do
                if type(id) == "number" and type(info) == "table" then
                    ezCollections.Cache.Sets[id] = ezCollections.PackSet(info);
                end
            end
        end
    end
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
            if ezCollections.Config.NewVersion.SkipVersionPopup ~= version and (result ~= "DISABLED" or not ezCollections.Config.NewVersion.HideRetiredPopup) then
                ezCollections.Config.NewVersion.SkipVersionPopup = nil;
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
            ezCollections:SendAddonMessage("LIST:DATA:RECIPETODRESSABLE");
            ezCollections:SendAddonMessage("LIST:DATA:SETS");
            ezCollections:SendAddonMessage("LIST:DATA:CAMERAS");
            ezCollections:SendAddonMessage("LIST:DATA:TOYS");
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
    match(message, "ITEMNAMEDESCRIPTIONS:", LoadIndexedStringList(ezCollections.ItemNameDescriptions, function(container)
        for index, description in ipairs(container) do
            container[description] = index;
        end
    end));
    match(message, "FEATURE:", function(data)
        match(data, "Wintergrasp", function()
            if ezCollections.Config.Misc.WintergraspButton then
                ezCollections:SetWintergraspButton(true);
            end
        end);
        match(data, "Timewalking", function(data)
            for _, str in ipairs({ strsplit(":", data) }) do
                if str == "RESET" then
                    ezCollections:ResetTimewalking();
                    LFDQueueFrameTypeDropDown_SetUp(LFDQueueFrameTypeDropDown);
                elseif str == "END" then
                    LFDQueueFrameTypeDropDown_SetUp(LFDQueueFrameTypeDropDown);
                elseif str ~= "" then
                    local id, dataString = strsplit("=", str);
                    local name, typeID, minLevel, maxLevel, recLevel, minRecLevel, maxRecLevel, expansionLevel, groupID, texture, difficulty, maxPlayers, description, isHoliday, title = strsplit(",", dataString);
                    ezCollections:AddTimewalking(tonumber(id),
                    {
                        ezCollections:Decode(name),
                        tonumber(typeID) or 1,
                        tonumber(minLevel) or 0,
                        tonumber(maxLevel) or 80,
                        tonumber(recLevel) or 0,
                        tonumber(minRecLevel) or 0,
                        tonumber(maxRecLevel) or 0,
                        tonumber(expansionLevel) or 0,
                        tonumber(groupID) or 1,
                        ezCollections:Decode(texture),
                        tonumber(difficulty) or 0,
                        tonumber(maxPlayers) or 5,
                        ezCollections:Decode(description),
                        tonumber(isHoliday) == 1,
                        ezCollections:Decode(title),
                    });
                end
            end
        end);
        match(data, "CTA:", function(data)
            match(data, "SHORTAGEREWARDS:", function(data)
                for _, str in ipairs({ strsplit(":", data) }) do
                    if str == "RESET" then
                        ezCollections:ResetCTAShortageReward();
                        LFDQueueFrameRandom_UpdateFrame();
                    elseif str == "END" then
                        LFDQueueFrameRandom_UpdateFrame();
                    elseif str ~= "" then
                        local item, dataString = strsplit("=", str);
                        local shortageIndex, roles, isVisualOnly = strsplit(",", dataString);
                        ezCollections:AddCTAShortageReward(tonumber(item),
                        {
                            ShortageIndex = (tonumber(shortageIndex) or 0) + 1,
                            Roles = tonumber(roles) or 0,
                            IsVisualOnly = tonumber(isVisualOnly) == 1,
                        });
                    end
                end
            end);
        end);
        match(data, "CFBG:", function(data)
            local faction = strsplit(":", data);
            ezCollections.CFBG.Faction = faction ~= "" and faction or nil;
            MiniMapBattlefieldFrame_isArena();
            PlayerFrame_UpdatePvPStatus();
        end);
    end);
    match(message, "HOLIDAY:", function(data)
        match(data, "START:", function(holiday)
            ezCollections.ActiveHolidays[tonumber(holiday)] = true;
            ezCollections:WipeSearchResults();
            C_TransmogCollection.WipeAppearanceCache();
            C_Transmog.ValidateAllPending(true);
            ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
            ezCollections.Callbacks.ToyListUpdated();
        end);
        match(data, "STOP:", function(holiday)
            ezCollections.ActiveHolidays[tonumber(holiday)] = nil;
            ezCollections:WipeSearchResults();
            C_TransmogCollection.WipeAppearanceCache();
            C_Transmog.ValidateAllPending(true);
            ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
            ezCollections.Callbacks.ToyListUpdated();
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
                            C_Transmog.ValidateAllPending(true);
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
                    C_Transmog.ValidateAllPending(true);
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
    match(message, "SETUPSTARTED", function()
        table.wipe(ezCollections.ItemNameDescriptions);
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
            elseif collection == "TOY"              then ezCollections.Collections.Toys.Enabled = true;
            end
        end
    end);
    match(message, "LIST:", function(list)
        match(list, "OWNEDITEM:",           LoadList(ezCollections.Collections.OwnedItems));
        match(list, "SKIN:",                LoadList(ezCollections.Collections.Skins, ezCollections.Callbacks.SkinListLoaded));
        match(list, "TAKENQUEST:",          LoadList(ezCollections.Collections.TakenQuests));
        match(list, "REWARDEDQUEST:",       LoadList(ezCollections.Collections.RewardedQuests));
        match(list, "TOY:",                 LoadList(ezCollections.Collections.Toys, ezCollections.Callbacks.ToyListLoaded));
        for slot, db in pairs(ezCollections.Cache.Slot) do
            match(list, "ALL:"..slot..":",  LoadAllList(db, ezCollections.Cache.All, ezCollections.Callbacks.SkinListLoaded, ezCollections.UnpackSkin));
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
            match(data, "RECIPETODRESSABLE:", function(recipeToDressables)
                for _, recipeToDressable in ipairs({ strsplit(":", recipeToDressables) }) do
                    if recipeToDressable ~= "" and recipeToDressable ~= "END" then
                        local recipe, dressable = strsplit("=", recipeToDressable);
                        ezCollections.Cache.RecipeToDressable[tonumber(recipe)] = tonumber(dressable);
                    end
                end
            end);
            match(data, "SETS:", function(sets)
                for _, set in ipairs({ strsplit(":", sets) }) do
                    if set == "END" then
                        ezCollections:PostprocessSetsAfterLoading();
                    elseif set ~= "" then
                        local id, data = strsplit("=", set);
                        id = tonumber(id);
                        ezCollections.Cache.Sets[id] = ezCollections.UnpackSet(id, data, true);
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
            match(data, "TOYS:", function(toys)
                for _, toy in ipairs({ strsplit(":", toys) }) do
                    if toy == "END" then
                        ezCollections.Cache.Toys.Loaded = true;
                        ezCollections.Callbacks.ToyListLoaded();
                    elseif toy ~= "" then
                        local id, dataString = strsplit("=", toy, 2);
                        local itemID, flags, expansion, sourceType, sourceText, holiday = strsplit(",", dataString);
                        id = tonumber(id) or 0;
                        itemID = tonumber(itemID) or 0;
                        flags = tonumber(flags) or 0;
                        expansion = tonumber(expansion) or 0;
                        sourceType = tonumber(sourceType) or 0;
                        sourceText = sourceText and ezCollections:Decode(sourceText);
                        holiday = tonumber(holiday) or nil;
                        ezCollections.Cache.Toys[id] = { itemID, flags, expansion, sourceType, sourceText, holiday };
                    end
                end
            end);
        end);
    end);
    match(message, "ADD:", function(list)
        match(list, "OWNEDITEM:",           AddList(ezCollections.Collections.OwnedItems, ezCollections.Callbacks.AddOwnedItem));
        match(list, "SKIN:",                AddList(ezCollections.Collections.Skins, ezCollections.Callbacks.AddSkin));
        match(list, "TAKENQUEST:",          AddList(ezCollections.Collections.TakenQuests));
        match(list, "REWARDEDQUEST:",       AddList(ezCollections.Collections.RewardedQuests));
        match(list, "TOY:",                 AddList(ezCollections.Collections.Toys, ezCollections.Callbacks.AddToy));
    end);
    match(message, "REMOVE:", function(list)
        match(list, "OWNEDITEM:",           RemoveList(ezCollections.Collections.OwnedItems, ezCollections.Callbacks.RemoveOwnedItem));
        match(list, "SKIN:",                RemoveList(ezCollections.Collections.Skins, ezCollections.Callbacks.RemoveSkin));
        match(list, "TAKENQUEST:",          RemoveList(ezCollections.Collections.TakenQuests));
        match(list, "REWARDEDQUEST:",       RemoveList(ezCollections.Collections.RewardedQuests));
        match(list, "TOY:",                 RemoveList(ezCollections.Collections.Toys, ezCollections.Callbacks.RemoveToy));
        match(list, "UNCLAIMEDQUEST:",      RemoveList(ezCollections.UnclaimedQuests, ezCollections.Callbacks.RemoveUnclaimedQuest));
    end);
    match(message, "RELOAD:", function(list)
        match(list, "OWNEDITEM:",           ReloadList("LIST:OWNEDITEM",     ezCollections.Collections.OwnedItems));
        match(list, "SKIN:",                ReloadList("LIST:SKIN",          ezCollections.Collections.Skins, ezCollections.Callbacks.ClearSkins));
        match(list, "TAKENQUEST:",          ReloadList("LIST:TAKENQUEST",    ezCollections.Collections.TakenQuests));
        match(list, "REWARDEDQUEST:",       ReloadList("LIST:REWARDEDQUEST", ezCollections.Collections.RewardedQuests));
        match(list, "TOY:",                 ReloadList("LIST:TOY",           ezCollections.Collections.Toys, ezCollections.Callbacks.ClearToys));
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
                        C_Transmog.ValidateAllPending(true);
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
                        C_Transmog.ValidateAllPending(true);
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
            ezCollectionsUpdateActionBars();
        end);
        match(result, "SUBSCRIPTION:STATUS:", function(result)
            if not match(result, "SPELLS:",  LoadList(ezCollections.ActiveMountSubscriptionMounts, ezCollections.Callbacks.MountListUpdated)) then
                local endTime, scaling, info = strsplit(":", result, 3);
                ezCollections.ActiveMountSubscriptionEndTime = tonumber(endTime) or 0;
                ezCollections.ActiveMountSubscriptionScaling = tonumber(scaling) == 1;
                ezCollections.ActiveMountSubscriptionInfo = ezCollections:Decode(info);
                table.wipe(ezCollections.ActiveMountSubscriptionMounts);
                ezCollections.Callbacks.MountListUpdated();
                ezCollectionsUpdateActionBars();
            end
        end);
    end);
    match(message, "PET:", function(result)
        match(result, "SUBSCRIPTION:STATUS:", function(result)
            if not match(result, "SPELLS:",  LoadList(ezCollections.ActivePetSubscriptionPets, ezCollections.Callbacks.PetListUpdated)) then
                local endTime, scaling, info = strsplit(":", result, 3);
                ezCollections.ActivePetSubscriptionEndTime = tonumber(endTime) or 0;
                ezCollections.ActivePetSubscriptionInfo = ezCollections:Decode(info);
                table.wipe(ezCollections.ActivePetSubscriptionPets);
                ezCollections.Callbacks.PetListUpdated();
            end
        end);
    end);
    match(message, "TOY:", function(result)
        match(result, "SUBSCRIPTION:STATUS:", function(result)
            if not match(result, "TOYS:",  LoadList(ezCollections.ActiveToySubscriptionToys, ezCollections.Callbacks.ToyListUpdated)) then
                local endTime, info = strsplit(":", result, 2);
                ezCollections.ActiveToySubscriptionEndTime = tonumber(endTime) or 0;
                ezCollections.ActiveToySubscriptionInfo = ezCollections:Decode(info);
                table.wipe(ezCollections.ActiveToySubscriptionToys);
                ezCollections.Callbacks.ToyListUpdated();
            end
        end);
        match(result, "COOLDOWN:", function(result)
            for _, cooldown in ipairs({ strsplit(":", result) }) do
                if cooldown == "END" then
                    ezCollections.Callbacks.ToyListUpdated();
                elseif cooldown ~= "" then
                    local itemID, dataString = strsplit("=", cooldown, 2);
                    local start, duration, enabled = strsplit(",", dataString);
                    itemID = tonumber(itemID);
                    start = (tonumber(start) or 0) / 1000;
                    duration = (tonumber(duration) or 0) / 1000;
                    enabled = enabled == "1";
                    if itemID then
                        ezCollections.ItemCooldowns[itemID] = { GetTime() - start, duration, enabled };
                    end
                end
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
                ezCollections.appearanceCacheLoaded = true;
                ezCollections.preloadCacheItemsNextOffset = nil;
                ezCollections.Callbacks.ToyListLoaded();
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
local batchEquipmentRequest;
function addon:PLAYER_EQUIPMENT_CHANGED(event, slot, equipped)
    if CharacterFrame:IsShown() and PaperDollFrame:IsShown() then
        local slotName = TRANSMOGRIFIABLE_SLOTS[slot];
        local slotButton = slotName and _G["Character"..slotName];
        if slotButton and slotButton:IsShown() then
            PaperDollItemSlotButton_Update(slotButton);
        end
    end
    ezCollections:RemoveItemTransmogCache("player", slot);
    if equipped and ezCollections:IsSkinSource(oGetInventoryItemID("player", slot)) == true then
        if WardrobeFrame_IsAtTransmogrifier() then
            -- Request immediately, we need fresh info already
            ezCollections:GetItemTransmog("player", slot);
        else
            if batchEquipmentRequest then
                ezCollections.AceAddon:CancelTimer(batchEquipmentRequest);
            end
            batchEquipmentRequest = ezCollections.AceAddon:ScheduleTimer(function()
                batchEquipmentRequest = nil;
                ezCollections:SendAddonMessage("GETTRANSMOG:PLAYER:"..GetUnitName("player"));
            end, 1);
        end
    end
end
function addon:BANKFRAME_OPENED(event)
    if not ezCollections.Allowed then return; end

    ezCollections:SetEmptyBankTransmogCache();
    ezCollections.IconOverlays:Update();
end
function addon:BAG_UPDATE(event, bagID)
    if not ezCollections.Allowed then return; end

    ezCollections:UpdateItemTransmogCache(bagID);
    ezCollections.IconOverlays:Update(bagID);
end
function addon:PLAYERBANKSLOTS_CHANGED(event)
    if not ezCollections.Allowed then return; end

    ezCollections:UpdateItemTransmogCache(-1);
    ezCollections.IconOverlays:Update(-1);
end
function addon:GUILDBANKBAGSLOTS_CHANGED(event)
    if not ezCollections.Allowed then return; end

    ezCollections.IconOverlays:Update();
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
    if ezCollectionsBartender4Hook and (addon == "Bartender4" or Bartender4) then
        ezCollectionsBartender4Hook();
        ezCollectionsBartender4Hook = nil;
    end
    if ezCollectionsElvUIHook and (addon == "ElvUI" or ElvUI) then
        ezCollectionsElvUIHook();
        ezCollectionsElvUIHook = nil;
    end
    if ezCollectionsElvUIEnhancedHook and (addon == "ElvUI_Enhanced") then
        ezCollectionsElvUIEnhancedHook();
        ezCollectionsElvUIEnhancedHook = nil;
    end
    if ezCollectionsElvUIConfigHook and (addon == "ElvUI_Config" or addon == "ElvUI_OptionsUI") then
        ezCollectionsElvUIConfigHook();
        ezCollectionsElvUIConfigHook = nil;
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
    ezCollectionsUpdateActionBars();
end

local inCombat = UnitAffectingCombat("player");
local function PlayerIsAlive()
    return not UnitIsDeadOrGhost("player");
end

function addon:PLAYER_REGEN_ENABLED()
    inCombat = false;
    ezCollectionsUpdateActionBars(true);
end

function addon:PLAYER_REGEN_DISABLED()
    inCombat = true;
    ezCollectionsUpdateActionBars(true);
end

local companionUpdateDeferred = false;
function addon:COMPANION_LEARNED(event)
    if not companionUpdateDeferred then
        companionUpdateDeferred = true;
        C_Timer.After(0.1, function()
            companionUpdateDeferred = false;
            C_MountJournal.RefreshMounts();
            C_PetJournal.RefreshPets();
            ezCollectionsUpdateActionBars();
            ezCollections.IconOverlays:Update();
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
            ezCollections.IconOverlays:Update();
        end);
    end
end

local lastActionBarUpdateTime = 0;
function addon:SPELL_UPDATE_USABLE(event)
    ezCollections:RaiseEvent("MOUNT_JOURNAL_USABILITY_CHANGED");
    if ezCollections.Config.ActionButtons.Mounts and ezCollections.Config.ActionButtons.MountsPerf and math.abs(lastActionBarUpdateTime - GetTime()) > 0.01 then
        lastActionBarUpdateTime = GetTime();
        ezCollectionsUpdateActionBars(true);
    end
end

function addon:ACTIONBAR_UPDATE_USABLE(event)
    ezCollections:RaiseEvent("MOUNT_JOURNAL_USABILITY_CHANGED");
    if ezCollections.Config.ActionButtons.Mounts and ezCollections.Config.ActionButtons.MountsPerf then
        lastActionBarUpdateTime = GetTime();
    end
end

local successfullyStartedCastID = nil;
function addon:UNIT_SPELLCAST_START(event, unit, name, rank, castID)
    if ezCollections:IsMountScalingAllowed() and name and unit == "player" and IsOutdoors() then
        if castID == 0 then
            ezCollectionsUpdateActionBars();
            return;
        end
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
    if ezCollections:IsMountScalingAllowed() and name and unit == "player" and IsOutdoors() then
        if castID == 0 or castID == successfullyStartedCastID then
            C_Timer.After(0, ezCollectionsUpdateActionBars);
            return;
        end
        if not waitingForMountFailure then
            return;
        end
        for i = 1, GetNumCompanions("MOUNT") do
            local _, _, spellID = GetCompanionInfo("MOUNT", i);
            if spellID and GetSpellInfo(spellID) == name then
                if PlayerIsAlive() and not inCombat and C_MountJournal.IsMountUsable(spellID, true) then
                    ezCollections:SendAddonMessage("MOUNT:SCALINGCAST:"..spellID);
                    suppressMountError = true;
                end
            end
        end
    end
    waitingForMountFailure = false;
end

local waitingForLearnFailure = false;
local suppressLearnError = false;
hooksecurefunc("UseContainerItem", function(bag, slot)
    if not waitingForLearnFailure then
        return;
    end

    local item = GetContainerItemID(bag, slot);
    local mount = item and ezCollections:GetMountIDByItem(item);
    local pet = item and ezCollections:GetPetIDByItem(item);
    if mount and ezCollections:HasAvailableMount(mount) and not ezCollections:HasMount(mount)
    or pet and ezCollections:HasAvailablePet(pet) and not ezCollections:HasPet(pet) then
        ezCollections:SendAddonMessage(format("MOUNT:FORCELEARN:%d:%d:%d", bag, slot - 1, item));
        suppressLearnError = true;
    end
    waitingForLearnFailure = false;
end);

local alreadyKnownPattern = FormatToPattern(ERR_SPELL_ALREADY_KNOWN_S);
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
    if event == "UI_ERROR_MESSAGE" and (ezCollections:IsActiveMountSubscription() or ezCollections:IsActivePetSubscription()) then
        local text = ...;
        if text:match(alreadyKnownPattern) then
            waitingForLearnFailure = true;
            C_Timer.After(0, function()
                if not suppressLearnError then
                    self:AddMessage(text, 1.0, 0.1, 0.1, 1.0);
                end
                suppressLearnError = false;
            end);
            return;
        end
    end
    oldUIErrorsFrameOnEvent(self, event, ...);
end);

function ezCollectionsUpdateActionBars() end
function addon:HookActionBars()
    local HookBartender4, specialButtons;

    local function IsCompanionUsable(id)
        return ezCollections.Config.ActionButtons.Mounts and PlayerIsAlive() and not inCombat and ezCollections:IsMountScalingAllowed() and IsOutdoors() and C_MountJournal.IsMountUsable(id, true);
    end
    local function IsItemUsable(id)
        return ezCollections.Config.ActionButtons.Toys and PlayerIsAlive() and C_ToyBox.GetToyInfo(id) and PlayerHasToy(id) and C_ToyBox.IsToyUsable(id);
    end
    local function IsMacroUsable(id)
        local name = GetMacroSpell(id);
        if name and ezCollections.Config.ActionButtons.Mounts and PlayerIsAlive() and not inCombat and ezCollections:IsMountScalingAllowed() and IsOutdoors() then
            if not ezCollections.MountNameXMountID then
                ezCollections.MountNameXMountID = { };
                for id in pairs(ezCollections.Mounts) do
                    ezCollections.MountNameXMountID[GetSpellInfo(id)] = id;
                end
            end
            local spellID = ezCollections.MountNameXMountID[name];
            if spellID then
                return C_MountJournal.IsMountUsable(spellID, true);
            end
        end
        local name, link = GetMacroItem(id);
        if name and link and ezCollections.Config.ActionButtons.Toys then
            local id = GetItemID(link);
            return id and IsItemUsable(id);
        end
    end
    local function UpdateCompanion(icon, normalTexture, id)
        if IsCompanionUsable(id) then
            icon:SetVertexColor(1, 1, 1);
            normalTexture:SetVertexColor(1, 1, 1);
        end
    end
    local function UpdateItem(icon, normalTexture, id)
        if IsItemUsable(id) then
            icon:SetVertexColor(1, 1, 1);
            normalTexture:SetVertexColor(1, 1, 1);
        end
    end
    local function UpdateMacro(icon, normalTexture, id)
        if IsMacroUsable(id) then
            icon:SetVertexColor(1, 1, 1);
            normalTexture:SetVertexColor(1, 1, 1);
        end
    end
    local function UpdateUsable(self)
        local icon = _G[self:GetName().."Icon"];
        local normalTexture = _G[self:GetName().."NormalTexture"];

        -- Bartender4
        if self.BT4init then
            HookBartender4(self);
            icon = self.icon;
            normalTexture = self.normalTexture;
        end

        local type, id, subType, subID = GetActionInfo(self.action);
        if type == "companion" and subType == "MOUNT" then
            UpdateCompanion(icon, normalTexture, subID);
        elseif type == "item" then
            UpdateItem(icon, normalTexture, id);
        elseif type == "macro" then
            UpdateMacro(icon, normalTexture, id);
        end

        -- KActionBars
        if KActionBars and KActionBarsDB.range == true and ezCollections.Config.ActionButtons.Addons.KActionBars then
            if IsActionInRange(self.action) == 0 then icon:SetVertexColor(1.0, 0.1, 0.1) end
        end
    end

    -- Blizzard
    hooksecurefunc("ActionButton_UpdateUsable", UpdateUsable);
if ezCollections.Config.ActionButtons.Toys then
    hooksecurefunc("ActionButton_UpdateCooldown", function(self)
        local type, id, subType, subID = GetActionInfo(self.action);
        if type == "item" then
            if C_ToyBox.GetToyInfo(id) and PlayerHasToy(id) then
                local start, duration, enable = ezCollections:GetItemCooldown(id);
                CooldownFrame_SetTimer(_G[self:GetName().."Cooldown"], start, duration, enable);
            end
        end
    end);
    hooksecurefunc("ActionButton_SetTooltip", function(self)
        local type, id, subType, subID = GetActionInfo(self.action);
        if type == "item" then
            if GetItemCount(id) == 0 and C_ToyBox.GetToyInfo(id) and PlayerHasToy(id) then
                if ( GetCVar("UberTooltips") == "1" ) then
                    GameTooltip_SetDefaultAnchor(GameTooltip, self);
                else
                    local parent = self:GetParent();
                    if ( parent == MultiBarBottomRight or parent == MultiBarRight or parent == MultiBarLeft ) and not self.BT4init then -- Bartender4
                        GameTooltip:SetOwner(self, "ANCHOR_LEFT");
                    else
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
                    end
                end
                if self.BT4init and specialButtons[self.action] then -- Bartender4
                    GameTooltip:SetText(specialButtons[self.action].tooltip) -- Bartender4
                    self.UpdateTooltip = ActionButton_SetTooltip;
                elseif ( GameTooltip:SetToyByItemID(id) ) then
                    self.UpdateTooltip = ActionButton_SetTooltip;
                else
                    self.UpdateTooltip = nil;
                end
            end
        end
    end);
    local lastPreAction, lastPreButton;
    local oldActionButton_CalculateAction = ActionButton_CalculateAction;
    hooksecurefunc("ActionButton_CalculateAction", function(self, button)
        lastPreAction = oldActionButton_CalculateAction(self, button);
        lastPreButton = button;
    end);
    hooksecurefunc("UseAction", function(action, unit, button)
        -- Prevent accidental trigger when placing cursor item into action button slot
        if action ~= lastPreAction or button ~= lastPreButton then
            return;
        end

        local type, id, subType, subID = GetActionInfo(action);
        if type == "item" then
            if GetItemCount(id) == 0 and IsItemUsable(id) then
                UseToy(id);
            end
        end
    end);
end
if ezCollections.Config.ActionButtons.Toys and ezCollections.Config.ActionButtons.Addons.ButtonForge then
    hooksecurefunc("SecureCmdUseItem", function(name, bag, slot, unit) -- ButtonForge
        local id = name and type(name) == "string" and ezCollections:GetToyItemByName(name);
        if id and GetItemCount(id) == 0 and IsItemUsable(id) then
            UseToy(id);
        end
    end);
end
    local actionBarPrefixes = { "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarRightButton", "MultiBarLeftButton" };
    local function UpdateBlizzard(usable)
        for _, bar in pairs(actionBarPrefixes) do
            for i = 1, 12 do
                local button = _G[bar..i];
                if button then
                    local slot = ActionButton_GetPagedID(button) or ActionButton_CalculateAction(button) or button:GetAttribute("action");
                    if slot and HasAction(slot) then
                        if usable then
                            ActionButton_UpdateUsable(button);
                        else
                            ActionButton_UpdateState(button);
                            ActionButton_UpdateUsable(button);
                            ActionButton_UpdateCooldown(button);
                        end
                    end
                end
            end
        end
    end

    -- Bartender4
    specialButtons = {
        [132] = { icon = "Interface\\Icons\\Spell_Shadow_SacrificialShield", tooltip = LEAVE_VEHICLE}, -- Vehicle Leave Button
    }
    local hookedBartender4;
    HookBartender4 = function(self)
        if not ezCollections.Config.ActionButtons.Addons.Bartender then return; end
        if self.BT4init and not hookedBartender4 then
            hookedBartender4 = true;
            local Button = getmetatable(self).__index;
            function Button:UpdateUsable()
                local isUsable, notEnoughMana = IsUsableAction(self.action)
                local icon = self.icon

                if Bartender4.db.profile.outofrange == "button" and self.outOfRange then
                    local oorc = Bartender4.db.profile.colors.range
                    icon:SetVertexColor(oorc.r, oorc.g, oorc.b)
                else
                    if isUsable or specialButtons[self.action] then
                        icon:SetVertexColor(1.0, 1.0, 1.0)
                    elseif notEnoughMana then
                        local oomc = Bartender4.db.profile.colors.mana
                        icon:SetVertexColor(oomc.r, oomc.g, oomc.b)
                    else
                        icon:SetVertexColor(0.4, 0.4, 0.4)
                        UpdateUsable(self);
                    end
                end
            end
            function Button:SetTooltip()
                ActionButton_SetTooltip(self);
            end
            function Button:ezCollectionsUpdate(usable)
                if usable then
                    ActionButton_UpdateUsable(self);
                else
                    self:Update();
                    ActionButton_UpdateState(self);
                    ActionButton_UpdateUsable(self);
                    ActionButton_UpdateCooldown(self);
                end
            end
        end
    end
    local function UpdateBartender4(usable)
        if not ezCollections.Config.ActionButtons.Addons.Bartender then return; end
        if Bartender4 then
            for _, bar in Bartender4.Bar:GetAll() do
                if bar.ForAll then
                    bar:ForAll("ezCollectionsUpdate", usable);
                end
            end
        end
    end

    -- ButtonForge
    local hookedButtonForge;
    local function HookButtonForge(self)
        if not ezCollections.Config.ActionButtons.Addons.ButtonForge then return; end
        if not hookedButtonForge then
            hookedButtonForge = true;
            hooksecurefunc(BFButton, "UpdateUsableCompanion", function(self)
                if not ezCollections.Config.ActionButtons.Mounts then return; end
                local id = select(3, GetCompanionInfo(self.CompanionType, self.CompanionIndex));
                if (self.CompanionType == "MOUNT" and (not PlayerIsAlive() or inCombat or IsIndoors() or not C_MountJournal.IsMountUsable(id, true))) then
                    self.WIcon:SetVertexColor(0.4, 0.4, 0.4);
                    self.WNormalTexture:SetVertexColor(1.0, 1.0, 1.0);
                else
                    self.WIcon:SetVertexColor(1.0, 1.0, 1.0);
                    self.WNormalTexture:SetVertexColor(1.0, 1.0, 1.0);
                end
            end);
            hooksecurefunc(BFButton, "UpdateUsableItem", function(self) UpdateItem(self.WIcon, self.WNormalTexture, self.ItemId); end);
            hooksecurefunc(BFButton, "UpdateUsableMacro", function(self) UpdateMacro(self.WIcon, self.WNormalTexture, self.MacroIndex); end);
            hooksecurefunc(BFButton, "UpdateCooldownItem", function(self)
                if ezCollections.Config.ActionButtons.Toys and C_ToyBox.GetToyInfo(self.ItemId) and PlayerHasToy(self.ItemId) then
                    local start, duration, enable = ezCollections:GetItemCooldown(self.ItemId);
                    CooldownFrame_SetTimer(self.WCooldown, start, duration, enable);
                end
            end);
            hooksecurefunc(BFButton, "UpdateTooltipItem", function(self)
                self = self.ParentButton or self;
                local id = self.ItemId;
                if ezCollections.Config.ActionButtons.Toys and id and GetItemCount(id) == 0 and C_ToyBox.GetToyInfo(id) and PlayerHasToy(id) then
                    GameTooltip_SetDefaultAnchor(GameTooltip, self.Widget);
                    GameTooltip:SetToyByItemID(id);
                end
            end);
        end
    end
    local function UpdateButtonForge(usable)
        if not ezCollections.Config.ActionButtons.Addons.ButtonForge then return; end
        if BFEventFrames then
            HookButtonForge();
            if usable then
                BFEventFrames["Usable"]:OnEvent();
            else
                BFEventFrames["Checked"]:OnEvent();
                BFEventFrames["Usable"]:OnEvent();
                BFEventFrames["Cooldown"]:OnEvent();
            end
        end
    end

    -- LibActionButton
    local hookedLibActionButton_action;
    local function HookLibActionButton(lib)
        if not ezCollections.Config.ActionButtons.Addons.LibActionButton then return; end
        if lib and not hookedLibActionButton_action then
            for button in next, lib.buttonRegistry do
                if button._state_type == "action" and not hookedLibActionButton_action then
                    hookedLibActionButton_action = true;
                    local Action = getmetatable(button).__index;
                    function Action:IsUsable()
                        local type, id, subType, subID = GetActionInfo(self._state_action);
                        local usable;
                        if ezCollections.Config.ActionButtons.Mounts and type == "companion" and subType == "MOUNT" then
                            usable = IsCompanionUsable(subID);
                        elseif ezCollections.Config.ActionButtons.Toys and type == "item" then
                            usable = IsItemUsable(id);
                        elseif type == "macro" then
                            usable = IsMacroUsable(id);
                        end
                        return usable or IsUsableAction(self._state_action);
                    end
                    function Action:GetCooldown()
                        local type, id, subType, subID = GetActionInfo(self._state_action);
                        if ezCollections.Config.ActionButtons.Toys and type == "item" then
                            if C_ToyBox.GetToyInfo(id) and PlayerHasToy(id) then
                                return ezCollections:GetItemCooldown(id);
                            end
                        end
                        return GetActionCooldown(self._state_action);
                    end
                    function Action:SetTooltip()
                        local type, id, subType, subID = GetActionInfo(self._state_action);
                        if ezCollections.Config.ActionButtons.Toys and type == "item" then
                            if GetItemCount(id) == 0 and C_ToyBox.GetToyInfo(id) and PlayerHasToy(id) then
                                return GameTooltip:SetToyByItemID(id);
                            end
                        end
                        return GameTooltip:SetAction(self._state_action);
                    end
                end
            end
        end
    end
    local function UpdateLibActionButtonFor(lib, usable)
        if not ezCollections.Config.ActionButtons.Addons.LibActionButton then return; end
        if lib then
            HookLibActionButton(lib);
            local script = lib.eventFrame and lib.eventFrame:GetScript("OnEvent");
            if script then
                if usable then
                    script(lib.eventFrame, "ACTIONBAR_UPDATE_USABLE");
                    --script(lib.eventFrame, "SPELL_UPDATE_USABLE");
                else
                    script(lib.eventFrame, "ACTIONBAR_UPDATE_STATE");
                    script(lib.eventFrame, "ACTIONBAR_UPDATE_USABLE");
                    script(lib.eventFrame, "ACTIONBAR_UPDATE_COOLDOWN");
                    --script(lib.eventFrame, "SPELL_UPDATE_USABLE");
                    --script(lib.eventFrame, "SPELL_UPDATE_COOLDOWN");
                end
            end
        end
    end
    local function UpdateLibActionButton(usable)
        if not ezCollections.Config.ActionButtons.Addons.LibActionButton then return; end
        UpdateLibActionButtonFor(LibStub("LibActionButton-1.0", true), usable);
        UpdateLibActionButtonFor(LibStub("LibActionButton-1.0-ElvUI", true), usable);
    end

    -- Finalize
    function ezCollectionsUpdateActionBars(usable)
        UpdateBlizzard(usable);
        UpdateBartender4(usable);
        UpdateButtonForge(usable);
        UpdateLibActionButton(usable);
    end
    ezCollectionsUpdateActionBars();
end

-- ---------------------------------------------------------------------------
-- Replace transmogrified icons on paper doll frames with their original icons
-- ---------------------------------------------------------------------------
function addon:HookRestoreItemIcons()

hooksecurefunc("NotifyInspect", function(unit)
    ezCollections.lastInspectRequestUnit = GetUnitName(unit);
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
    elseif ( strsub(link, 1, 13) == "item:0:outfit" ) then
        local sources, mainHandEnchant, offHandEnchant = C_TransmogCollection.GetItemTransmogInfoListFromOutfitHyperlink(link);
        if sources then
            if ( IsModifiedClick("CHATLINK") ) then
                local hyperlink = C_TransmogCollection.GetOutfitHyperlinkFromItemTransmogInfoList(sources, mainHandEnchant, offHandEnchant);
                if not ChatEdit_InsertLink(hyperlink) then
                    ChatFrame_OpenChat(hyperlink);
                end
            elseif DressUpSources then
                DressUpSources(sources, mainHandEnchant, offHandEnchant);
            else
                StaticPopup_Show("EZCOLLECTIONS_ERROR", L["Popup.Error.DressUp.OutfitPreviewAddonDisabled"]);
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage(TRANSMOG_OUTFIT_LINK_INVALID, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
        end
    end
    return oChatFrame_OnHyperlinkShow(self, link, text, button, ...);
end

for _, chatMsg in ipairs({ "CHAT_MSG_BATTLEGROUND", "CHAT_MSG_BATTLEGROUND_LEADER", "CHAT_MSG_CHANNEL", "CHAT_MSG_EMOTE", "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER", "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING", "CHAT_MSG_SAY", "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_YELL" }) do
    ChatFrame_AddMessageEventFilter(chatMsg, ezCollections.Callbacks.OnChatMessageEventFilter);
end

SlashCmdList["TRANSMOG_OUTFIT"] = function(msg)
    if DressUpSources then
        DressUpSources(TransmogUtil.ParseOutfitSlashCommand(msg));
    else
        StaticPopup_Show("EZCOLLECTIONS_ERROR", L["Popup.Error.DressUp.OutfitPreviewAddonDisabled"]);
    end
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

local function IsTooltipItemRecipe(tooltip, id)
    if not tooltip:GetName() then return false; end
    local dressable = ezCollections:GetDressableFromRecipe(id);
    if dressable then
        if ezCollections:GetEnchantFromScroll(dressable) then
            return false;
        end
        return true, dressable;
    end

    local line = _G[tooltip:GetName().."TextLeft"..1];
    if line and line:IsShown() and line:GetText() then
        local itemName = line:GetText();
        local productName = (itemName or ""):match(".-: (.+)");
        productName = productName and "\n"..productName:utf8lower();
        if productName then
            return ezCollections:ForEachTooltipText(tooltip, function(line)
                if (line:GetText() or ""):utf8lower() == productName then
                    return true;
                end
            end);
        end
    end
    return false;
end

local function IsTooltipItemCollectible(tooltip)
    return not ezCollections:ForEachTooltipText(tooltip, function(line)
        local text = line:GetText();
        if text and (text:match(FormatToPattern(ITEM_DURATION_SEC)) or
                     text:match(FormatToPattern(ITEM_DURATION_MIN)) or
                     text:match(FormatToPattern(ITEM_DURATION_HOURS)) or
                     text:match(FormatToPattern(ITEM_DURATION_DAYS))) then
            return true;
        end
    end);
end

local function TooltipHandlerItem(tooltip)
    if not ezCollections.Allowed then return; end

    if ezCollections:HasPendingTooltipInfo("SetToyByItemID") then return; end

    local id = GetTooltipItem(tooltip);
    if not id then return; end

    local isRecipe, productID = IsTooltipItemRecipe(tooltip, id);
    if isRecipe and not tooltip.ezCollectionsAwaitingRecipe then
        tooltip.ezCollectionsAwaitingRecipe = true;
        if productID then
            id = productID;
        else
            return;
        end
    else
        tooltip.ezCollectionsAwaitingRecipe = nil;
    end

    local show = false;
    if ezCollections.Config.TooltipSets.Collected   and ezCollections:IsSkinSource(id) == true and ezCollections:HasSkin(id) == true
    or ezCollections.Config.TooltipSets.Uncollected and ezCollections:IsSkinSource(id) == true and ezCollections:HasSkin(id) == false then
        if CollectionWardrobeUtil.AddSourceSetsToTooltip(tooltip, id) then
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
    if ezCollections:IsActiveMountSubscription() or ezCollections:IsActivePetSubscription() then
        for i = 1, 20 do
            local line = _G[tooltip:GetName().."TextLeft"..i];
            if line and line:IsShown() and line:GetText() == ITEM_SPELL_KNOWN and IsSameColor(1, 0.125, 0.125, line:GetTextColor()) then
                local mount = id and ezCollections:GetMountIDByItem(id);
                local pet = id and ezCollections:GetPetIDByItem(id);
                if mount and ezCollections:HasAvailableMount(mount) and not ezCollections:HasMount(mount)
                or pet and ezCollections:HasAvailablePet(pet) and not ezCollections:HasPet(pet) then
                    line:SetText(L["Tooltip.SubscriptionLearned"]);
                    show = true;
                    break;
                end
            end
        end
    end
    if ezCollections.Config.TooltipCollection.Toys or ezCollections.Config.TooltipCollection.ToyUnlock and tooltip:GetName() then
        local toyID = ezCollections:GetToyIDByItem(id);
        if toyID then
            if ezCollections.Config.TooltipCollection.Toys then
                local line = _G[tooltip:GetName().."TextLeft2"];
                if line and line:IsShown() and line:GetText()then
                    line:SetText(format("|cFF88AAFF%s|r|n%s", TOY, line:GetText()));
                    show = true;
                end
            end
            if ezCollections.Config.TooltipCollection.ToyUnlock and ezCollections.Config.TooltipCollection.ToyUnlockEmbed and ezCollections:HasToy(toyID) == false then
                for i = 1, 20 do
                    local line = _G[tooltip:GetName().."TextLeft"..i];
                    if line and line:IsShown() and line:GetText() and line:GetText() ~= "" and line:GetText() ~= " " then
                        local text = line:GetText();
                        local r, g, b = line:GetTextColor();
                        if IsSameColor(r, g, b, 0, 1, 0) then
                            local s, e = text:find(ITEM_SPELL_TRIGGER_ONUSE);
                            if not s then
                                s, e = text:find(ITEM_SPELL_TRIGGER_ONEQUIP);
                            end
                            if s and e then
                                line:SetText(format("%s|n|n%s", ITEM_TOY_ONUSE, text:sub(e + 2)));
                                show = true;
                                break;
                            end
                        end
                    end
                end
            end
            if ezCollections.Config.TooltipCollection.ToyUnlock and not ezCollections.Config.TooltipCollection.ToyUnlockEmbed and ezCollections:HasToy(toyID) == false then
                if not separator then separator = true; tooltip:AddLine(" "); end
                tooltip:AddLine(L["Tooltip.Toys"], color.r, color.g, color.b, false);
            end
        end
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

        local hasPendingUndo, pendingEntry, hasPendingIllusionUndo, pendingEnchant = ezCollections:GetPendingTooltipInfo("SetTransmogrifyItem");

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
                    if not ezCollections.hasCosmeticItems and flags:find(ITEM_COSMETIC, 1, true) then
                        ezCollections.hasCosmeticItems = true;
                    end
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
                            local slot = slot;
                            if not slot then
                                slot = bag;
                            else
                                slot = nil;
                                local info = ezCollections:GetSkinInfo(id);
                                if info and info.InventoryType then
                                    slot = C_Transmog.GetSlotForInventoryType(info.InventoryType);
                                else
                                    local invType = select(9, GetItemInfo(id));
                                    invType = invType and ezCollections.InvTypeNameToEnum[invType];
                                    if invType then
                                        slot = C_Transmog.GetSlotForInventoryType(invType);
                                    end
                                end
                            end
                            name = ezCollections:GetHiddenVisualItemName(slot);
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
                    local scroll = ezCollections:GetScrollFromEnchant(fakeEnchant);
                    local texture = scroll and ezCollections:GetSkinIcon(scroll);
                    if not texture then
                        texture = [[Interface\AddOns\ezCollections\Textures\EnchantIcon]]; -- [[Interface\Icons\INV_Scroll_05]]
                    end
                    local size = ezCollections.Config.TooltipTransmog.IconEnchant.Size or 0;
                    local crop = ezCollections.Config.TooltipTransmog.IconEnchant.Crop and ":0:0:64:64:6:58:6:58" or "";
                    if fakeEnchant == ENCHANT_HIDDEN and ezCollections.Config.TooltipTransmog.NewHideVisualIcon then
                        texture = [[Interface\AddOns\ezCollections\Interface\Transmogrify\Transmogrify]];
                        crop = ":0:0:512:512:417:443:90:116";
                    end
                    local icon = ezCollections.Config.TooltipTransmog.IconEnchant.Enable and ("|T"..texture..":"..size..":"..size..crop.."|t ") or "";
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
                if line and line:GetText() and line:GetText() ~= " " and not line:GetText():match("|c") and IsSameColor(1, 0.8235, 0, line:GetTextColor()) and
                   line2 and line2:GetText() and line2:GetText() ~= " " and not line2:GetText():match("|c") and (IsSameColor(0.5, 0.5, 0.5, line2:GetTextColor()) or IsSameColor(1, 1, 0.5922, line2:GetTextColor())) and
                   line3 and line3:GetText() and line3:GetText() ~= " " and not line3:GetText():match("|c") and (IsSameColor(0.5, 0.5, 0.5, line3:GetTextColor()) or IsSameColor(1, 1, 0.5922, line3:GetTextColor())) then
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
