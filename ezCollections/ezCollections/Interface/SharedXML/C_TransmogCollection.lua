C_TransmogCollection = C_TransmogCollection or { };

local _search = { };
local _lastSearchText = nil;
local _category = nil;
local _appearanceSlotCache = { };
local _illusionSlotCache = { };
local _query = nil;
local _queryAlways = nil;
local _showCollected = nil;
local _showUncollected = nil;
local _fullMask = nil;
local _sourceMask = nil;
local _armorTypeMask = nil;
local _armorTypeMaskAny = nil;
local _classMask = nil;
local _classMaskAny = nil;
local _raceMask = nil;
local _raceMaskAny = nil;
local _expansionMask = nil;

local function GetSourceFilterCVar()
    return WardrobeFrame_IsAtTransmogrifier() and "transmogrifySourceFilters" or "wardrobeSourceFilters";
end

local function GetArmorFilterCVar()
    return WardrobeFrame_IsAtTransmogrifier() and "transmogrifyArmorFilters" or "wardrobeArmorFilters";
end

local function GetClassFilterCVar()
    return WardrobeFrame_IsAtTransmogrifier() and "transmogrifyClassFilters" or "wardrobeClassFilters";
end

local function GetRaceFilterCVar()
    return WardrobeFrame_IsAtTransmogrifier() and "transmogrifyRaceFilters" or "wardrobeRaceFilters";
end

local function GetExpansionFilterCVar()
    return WardrobeFrame_IsAtTransmogrifier() and "transmogrifyExpansionFilters" or "wardrobeExpansionFilters";
end

local function GetShowCollectedCVar()
    return WardrobeFrame_IsAtTransmogrifier() and "transmogrifyShowCollected" or "wardrobeShowCollected";
end

local function GetShowUncollectedCVar()
    return WardrobeFrame_IsAtTransmogrifier() and "transmogrifyShowUncollected" or "wardrobeShowUncollected";
end

local function ItemSubTypeToSubClassID(itemSubType)
    for i = 1, NUM_LE_ITEM_WEAPON do
        if itemSubType == select(i, GetAuctionItemSubClasses(1)) then
            return i - 1;
        end
    end
end

local function PrepareFilter()
    _showCollected = C_TransmogCollection.GetCollectedShown();
    _showUncollected = C_TransmogCollection.GetUncollectedShown();
    _fullMask = bit.bnot(0);
    _sourceMask = bit.bnot(ezCollections:GetCVar(GetSourceFilterCVar()));
    _armorTypeMask = bit.bnot(ezCollections:GetCVar(GetArmorFilterCVar()));
    _armorTypeMaskAny = bit.lshift(1, 6 - 1);
    _classMask = bit.bnot(ezCollections:GetCVar(GetClassFilterCVar()));
    _classMaskAny = bit.lshift(1, ezCollections.ClassNameToID["ANY"] - 1);
    _raceMask = bit.bnot(ezCollections:GetCVar(GetRaceFilterCVar()));
    _raceMaskAny = bit.lshift(1, ezCollections.RaceNameToID["ANY"] - 1);
    _expansionMask = bit.bnot(ezCollections:GetCVar(GetExpansionFilterCVar()));
    _queryAlways = _lastSearchText ~= "" and ezCollections:PrepareSearchQuery(_lastSearchText) or nil;
    _query = not ezCollections:UseServersideTextSearch() and _queryAlways or nil;
end

local function MatchesFilter(id)
    local isCollected = ezCollections:HasAvailableSkin(id) or false;
    if not (_showCollected and isCollected or _showUncollected and not isCollected) then
        return false, isCollected;
    end

    local info = ezCollections:GetSkinInfo(id);
    local isEnchant = ezCollections:GetEnchantFromScroll(id) and true or false;
    if _sourceMask ~= _fullMask then
        if info and info.SourceMask and bit.band(info.SourceMask, _sourceMask) == 0 then
            return false, isCollected;
        end
    end

    if _armorTypeMask ~= _fullMask then
        if info and not isEnchant and info.Armor and bit.band(bit.lshift(1, info.Armor), _armorTypeMask) == 0 then
            return false, isCollected;
        end
        if info and not isEnchant and not info.Armor and not info.Weapon and bit.band(_armorTypeMaskAny, _armorTypeMask) == 0 then
            return false, isCollected;
        end
    end

    if _classMask ~= _fullMask then
        if info and info.ClassMask and bit.band(info.ClassMask, _classMask) == 0 then
            return false, isCollected;
        end
        if info and not info.ClassMask and bit.band(_classMaskAny, _classMask) == 0 then
            return false, isCollected;
        end
    end

    if _raceMask ~= _fullMask then
        if info and info.RaceMask and bit.band(info.RaceMask, _raceMask) == 0 then
            return false, isCollected;
        end
        if info and not info.RaceMask and bit.band(_raceMaskAny, _raceMask) == 0 then
            return false, isCollected;
        end
    end

    if _expansionMask ~= _fullMask then
        if info and bit.band(bit.lshift(1, info.Expansion or 0), _expansionMask) == 0 then
            return false, isCollected;
        end
    end

    if not ezCollections:ItemMatchesSearch(id, _query) then
        return false, isCollected;
    end

    return true, isCollected, isEnchant or info and not info.Unusable, info and info.Holiday and ezCollections:IsHolidayActive(info.Holiday) or false;
end

local function MakeOutfitIcon(outfitID)
    local appearanceSources, mainHandEnchant, offHandEnchant = C_TransmogCollection.GetOutfitSources(outfitID);
    for _, slotInfo in ipairs(TRANSMOG_SLOTS) do
        if slotInfo.transmogType == LE_TRANSMOG_TYPE_APPEARANCE then
            local sourceID = appearanceSources[GetInventorySlotInfo(slotInfo.slot)];
            if sourceID and sourceID ~= ezCollections:GetHiddenVisualItem() then
                local icon = select(4, C_TransmogCollection.GetAppearanceSourceInfo(sourceID));
                if icon then
                    return icon;
                end
            end
        end
    end
end

local function MakeOutfitData(name, sources, mainHandEnchant, offHandEnchant, icon, prepaid)
    local flags = 0;
    if prepaid and ezCollections.PrepaidOutfitsEnabled then flags = bit.bor(flags, 0x1); end

    local data = format("%s:%d", ezCollections:Encode(name), flags);
    for _, slotInfo in ipairs(TRANSMOG_SLOTS) do
        local slot = GetInventorySlotInfo(slotInfo.slot);
        local source = sources[slot] or 0;
        local enchant = slot == 16 and mainHandEnchant or slot == 17 and offHandEnchant or 0;
        if source ~= 0 or enchant ~= 0 then
            data = data .. ":" .. format(enchant ~= 0 and "%d=%d,%d" or "%d=%d", slot, source, enchant);
        end
    end
    return data;
end

local function MakeSourceType(info)
    if info and info.SourceMask and bit.band(info.SourceMask, bit.lshift(1, TRANSMOG_SOURCE_BOSS_DROP - 1)) ~= 0 and info.SourceBosses then
        return TRANSMOG_SOURCE_BOSS_DROP;
    end
    return 0;
end

local function MakeSourceText(info)
    if info and info.SourceMask then
        local result = "";
        for i = 1, C_TransmogCollection.GetNumTransmogSources() do
            if bit.band(info.SourceMask, bit.lshift(1, i - 1)) ~= 0 then
                result = result .. (result ~= "" and ", " or "") .. _G["TRANSMOG_SOURCE_"..i];
            end
        end
        return result;
    end
end

local function GetCacheContainer(create, slot, category)
    -- Cache only applicable to equipment slots
    if not slot then
        return;
    end

    local cache = category and _appearanceSlotCache or _illusionSlotCache;

    if create then
        cache[slot] = cache[slot] or { };
    end
    cache = cache[slot];

    if cache and category then
        if create then
            cache[category] = cache[category] or { };
        end
        cache = cache[category];
    end

    return cache;
end

local function GetValidSearchCache(type, category, allowNotAtTransmogrifier)
    if not WardrobeFrame_IsAtTransmogrifier() and not allowNotAtTransmogrifier or type ~= LE_TRANSMOG_SEARCH_TYPE_ITEMS then
        return;
    end

    local slot, id, enchant;
    if WardrobeFrame_IsAtTransmogrifier() then
        local _;
        slot = GetInventorySlotInfo(WardrobeCollectionFrame.ItemsCollectionFrame:GetActiveSlot());
        _, id, enchant = strsplit(":", GetInventoryItemLink("player", slot) or "");
        id = tonumber(id) or 0;
        enchant = tonumber(enchant) or 0;
    end

    local search = _search[type];
    local cacheable = not search or not ezCollections:UseServersideTextSearch() or not search.Text or search.Text == "";
    local cache = GetCacheContainer(false, slot, category);
    return cacheable and cache and cache.Entry == id and cache.Enchant == enchant and cache or nil, cacheable, slot, id, enchant;
end

local function GetDBOrCachedSearchResults(category)
    local searchType = LE_TRANSMOG_SEARCH_TYPE_ITEMS;
    local search = _search[searchType];
    if not search and not WardrobeFrame_IsAtTransmogrifier() then
        local db = ezCollections:GetDBByCategory(category);
        if db.Loaded then
            return db;
        end
        return;
    end

    local cache, cacheable, slot, id, enchant = GetValidSearchCache(searchType, category, true);
    if cache then
        return cache;
    elseif id == 0 then -- Don't check for nil, it will be returned if we're not at transmogrifier
        return;
    elseif search and search.Token and search.Category == category and ezCollections:IsSearchFinished(searchType, search.Token) and ezCollections:IsSearchMatchingParams(searchType, search.Token, search.Category, _lastSearchText, slot, id, enchant) then
        if slot and cacheable then
            cache = GetCacheContainer(true, slot, category);
            table.wipe(cache);
            cache.Entry = id;
            cache.Enchant = enchant;
            if search.Results then
                for _, id in ipairs(search.Results) do
                    if type(id) == "number" then
                        table.insert(cache, id);
                    end
                end
            end
        end
        return search.Results;
    else
        if C_TransmogCollection.SetSearch(searchType, _lastSearchText) then
            return GetDBOrCachedSearchResults(category);
        end
        return;
    end
end

-- Category

local _categoryInfo;
function C_TransmogCollection.GetCategoryInfo(categoryID)
    if not _categoryInfo then
        _categoryInfo =
        {
            [LE_TRANSMOG_COLLECTION_TYPE_HEAD]         = { InvType = "INVTYPE_HEAD" },
            [LE_TRANSMOG_COLLECTION_TYPE_SHOULDER]     = { InvType = "INVTYPE_SHOULDER" },
            [LE_TRANSMOG_COLLECTION_TYPE_BACK]         = { InvType = "INVTYPE_CLOAK" },
            [LE_TRANSMOG_COLLECTION_TYPE_CHEST]        = { InvType = "INVTYPE_CHEST" },
            [LE_TRANSMOG_COLLECTION_TYPE_TABARD]       = { InvType = "INVTYPE_TABARD" },
            [LE_TRANSMOG_COLLECTION_TYPE_SHIRT]        = { InvType = "INVTYPE_BODY" },
            [LE_TRANSMOG_COLLECTION_TYPE_WRIST]        = { InvType = "INVTYPE_WRIST" },
            [LE_TRANSMOG_COLLECTION_TYPE_HANDS]        = { InvType = "INVTYPE_HAND" },
            [LE_TRANSMOG_COLLECTION_TYPE_WAIST]        = { InvType = "INVTYPE_WAIST" },
            [LE_TRANSMOG_COLLECTION_TYPE_LEGS]         = { InvType = "INVTYPE_LEGS" },
            [LE_TRANSMOG_COLLECTION_TYPE_FEET]         = { InvType = "INVTYPE_FEET" },
            [LE_TRANSMOG_COLLECTION_TYPE_WAND]         = { InvType = "INVTYPE_RANGEDRIGHT", WeaponSlotMask = 4, WeaponSubClass = LE_ITEM_WEAPON_WAND },
            [LE_TRANSMOG_COLLECTION_TYPE_1H_AXE]       = { InvType = "INVTYPE_WEAPON",      WeaponSlotMask = 3, WeaponSubClass = LE_ITEM_WEAPON_AXE1H },
            [LE_TRANSMOG_COLLECTION_TYPE_1H_SWORD]     = { InvType = "INVTYPE_WEAPON",      WeaponSlotMask = 3, WeaponSubClass = LE_ITEM_WEAPON_SWORD1H },
            [LE_TRANSMOG_COLLECTION_TYPE_1H_MACE]      = { InvType = "INVTYPE_WEAPON",      WeaponSlotMask = 3, WeaponSubClass = LE_ITEM_WEAPON_MACE1H },
            [LE_TRANSMOG_COLLECTION_TYPE_DAGGER]       = { InvType = "INVTYPE_WEAPON",      WeaponSlotMask = 3, WeaponSubClass = LE_ITEM_WEAPON_DAGGER },
            [LE_TRANSMOG_COLLECTION_TYPE_FIST]         = { InvType = "INVTYPE_WEAPON",      WeaponSlotMask = 3, WeaponSubClass = LE_ITEM_WEAPON_FIST },
            [LE_TRANSMOG_COLLECTION_TYPE_SHIELD]       = { InvType = "INVTYPE_SHIELD",      WeaponSlotMask = 2, ArmorSubClass = LE_ITEM_ARMOR_SHIELD },
            [LE_TRANSMOG_COLLECTION_TYPE_HOLDABLE]     = { InvType = "INVTYPE_HOLDABLE",    WeaponSlotMask = 2 },
            [LE_TRANSMOG_COLLECTION_TYPE_2H_AXE]       = { InvType = "INVTYPE_2HWEAPON",    WeaponSlotMask = 3, WeaponSubClass = LE_ITEM_WEAPON_AXE2H },
            [LE_TRANSMOG_COLLECTION_TYPE_2H_SWORD]     = { InvType = "INVTYPE_2HWEAPON",    WeaponSlotMask = 3, WeaponSubClass = LE_ITEM_WEAPON_SWORD2H },
            [LE_TRANSMOG_COLLECTION_TYPE_2H_MACE]      = { InvType = "INVTYPE_2HWEAPON",    WeaponSlotMask = 3, WeaponSubClass = LE_ITEM_WEAPON_MACE2H },
            [LE_TRANSMOG_COLLECTION_TYPE_STAFF]        = { InvType = "INVTYPE_2HWEAPON",    WeaponSlotMask = 3, WeaponSubClass = LE_ITEM_WEAPON_STAFF },
            [LE_TRANSMOG_COLLECTION_TYPE_POLEARM]      = { InvType = "INVTYPE_2HWEAPON",    WeaponSlotMask = 3, WeaponSubClass = LE_ITEM_WEAPON_POLEARM },
            [LE_TRANSMOG_COLLECTION_TYPE_BOW]          = { InvType = "INVTYPE_RANGED",      WeaponSlotMask = 4, WeaponSubClass = LE_ITEM_WEAPON_BOWS },
            [LE_TRANSMOG_COLLECTION_TYPE_GUN]          = { InvType = "INVTYPE_RANGEDRIGHT", WeaponSlotMask = 4, WeaponSubClass = LE_ITEM_WEAPON_GUNS },
            [LE_TRANSMOG_COLLECTION_TYPE_CROSSBOW]     = { InvType = "INVTYPE_RANGEDRIGHT", WeaponSlotMask = 4, WeaponSubClass = LE_ITEM_WEAPON_CROSSBOW },
            [LE_TRANSMOG_COLLECTION_TYPE_THROWN]       = { InvType = "INVTYPE_THROWN",      WeaponSlotMask = 4, WeaponSubClass = LE_ITEM_WEAPON_THROWN },
            [LE_TRANSMOG_COLLECTION_TYPE_FISHING_POLE] = { InvType = "INVTYPE_2HWEAPON",    WeaponSlotMask = 3, WeaponSubClass = LE_ITEM_WEAPON_FISHINGPOLE },
            [LE_TRANSMOG_COLLECTION_TYPE_MISC]         = { InvType = "INVTYPE_WEAPON",      WeaponSlotMask = 1, WeaponSubClass = LE_ITEM_WEAPON_GENERIC },
        };
    end

    local info = _categoryInfo[categoryID];
    if info then
        if not info.Name then
            if info.WeaponSubClass then
                info.Name = select(info.WeaponSubClass + 1, GetAuctionItemSubClasses(1));
            elseif info.ArmorSubClass then
                info.Name = select(info.ArmorSubClass + 1, GetAuctionItemSubClasses(2));
            else
                info.Name = _G[info.InvType];
            end
        end

        local name = info.Name;
        local isWeapon = info.WeaponSlotMask ~= nil;
        local canEnchant = isWeapon; -- Not entirely correct, but it's not used anywhere anyway
        local canMainHand = isWeapon and bit.band(info.WeaponSlotMask, 1) ~= 0;
        local canOffHand = isWeapon and bit.band(info.WeaponSlotMask, 2) ~= 0;
        local canRanged = isWeapon and bit.band(info.WeaponSlotMask, 4) ~= 0;

        return name, isWeapon, canEnchant, canMainHand, canOffHand, canRanged, info.InvType;
    end
end

function C_TransmogCollection.GetCategoryAppearances(category)
    local results = GetDBOrCachedSearchResults(category);
    if not results then
        return { };
    end

    local invType = category and select(7, C_TransmogCollection.GetCategoryInfo(category));
    invType = invType and ezCollections.InvTypeNameToEnum[invType];
    local slot = invType and C_Transmog.GetSlotForInventoryType(invType + 1);

    local visualsList = { };
    PrepareFilter();
    if ezCollections:CanHideSlot(TransmogUtil.GetSlotName(slot):gsub("SLOT", "")) and (not _queryAlways or ezCollections:TextMatchesSearch(ezCollections:GetHiddenVisualItemName(slot), _queryAlways)) then
        local id = ezCollections:GetHiddenVisualItem();
        table.insert(visualsList,
        {
            visualID = id,
            sourceID = id,
            isCollected = true,
            isHideVisual = true,
            isUsable = ezCollections:CanTransmogrify(id),
            hasActiveRequiredHoliday = nil,
            isFavorite = false,
            uiOrder = 0,
        });
    end

    for index, id in ipairs(results) do
        if type(id) == "number" then
            local matchesFilter, isCollected, isUsable, hasActiveRequiredHoliday = MatchesFilter(id);
            if matchesFilter then
                local info = ezCollections:GetSkinInfo(id);
                table.insert(visualsList,
                {
                    visualID = id,
                    sourceID = id,
                    isCollected = isCollected,
                    isHideVisual = false,
                    isUsable = isUsable,
                    hasActiveRequiredHoliday = hasActiveRequiredHoliday,
                    isFavorite = C_TransmogCollection.GetIsAppearanceFavorite(id),
                    uiOrder = -index * 100,
                    -- Custom
                    isStoreSource = ezCollections:IsStoreItem(id, info),
                    isSubscriptionSource = ezCollections:GetSubscriptionForSkin(id),
                });
            end
        end
    end
    return visualsList;
end

function C_TransmogCollection.GetCategoryTotal(category)
    local db = ezCollections:GetDBByCategory(category);
    if db.Loaded then
        return #db - (C_TransmogCollection.IsSourceTypeFilterChecked(TRANSMOG_SOURCE_STORE) and db.StoreExclusiveCount or 0)
                    - (C_TransmogCollection.IsSourceTypeFilterChecked(TRANSMOG_SOURCE_SUBSCRIPTION) and db.SubscriptionExclusiveCount or 0)
                    - (C_TransmogCollection.IsSourceTypeFilterChecked(TRANSMOG_SOURCE_STORE) and C_TransmogCollection.IsSourceTypeFilterChecked(TRANSMOG_SOURCE_SUBSCRIPTION) and db.StoreAndSubscriptionExclusiveCount or 0);
    end
    return 0;
end

function C_TransmogCollection.GetCategoryCollectedCount(category)
    local hideStore = C_TransmogCollection.IsSourceTypeFilterChecked(TRANSMOG_SOURCE_STORE);
    local hideSubscription = C_TransmogCollection.IsSourceTypeFilterChecked(TRANSMOG_SOURCE_SUBSCRIPTION);
    local collected = 0;
    local db = ezCollections:GetDBByCategory(category);
    if db.Loaded then
        for index, id in ipairs(db) do
            if type(id) == "number" then
                local info = (hideStore or hideSubscription) and ezCollections:GetSkinInfo(id);
                local hide = hideStore and ezCollections:IsStoreExclusiveItem(id, info)
                            or hideSubscription and ezCollections:IsSubscriptionExclusiveItem(id, info)
                            or hideStore and hideSubscription and ezCollections:IsStoreAndSubscriptionExclusiveItem(id, info);
                if not hide and ezCollections:HasAvailableSkin(id) then
                    collected = collected + 1;
                end
            end
        end
    end
    return collected;
end

-- Sources

function C_TransmogCollection.GetAppearanceSourceInfo(appearanceSourceID)
    if not appearanceSourceID then
        return;
    end
    if type(appearanceSourceID) == "string" then
        appearanceSourceID = tonumber(appearanceSourceID);
    end
    local info = ezCollections:GetSkinInfo(appearanceSourceID);
    local categoryID = ezCollections:GetSkinCategory(appearanceSourceID);
    local appearanceVisualID = appearanceSourceID;
    local canEnchant = info and info.Enchantable;
    local _, link = GetItemInfo(appearanceSourceID);
    local icon = ezCollections:GetSkinIcon(appearanceSourceID);
    return categoryID, appearanceVisualID, canEnchant, icon, nil, link;
end

function C_TransmogCollection.GetAppearanceSourceInfoForTransmog()
    -- TODO:
end

function C_TransmogCollection.GetAppearanceInfoBySource(appearanceSourceID)
    return
    {
        appearanceID = appearanceSourceID,
        sourceIsCollectedPermanent = true,
        appearanceIsCollected = ezCollections:HasAvailableSkin(appearanceSourceID) or C_TransmogCollection.IsAppearanceHiddenVisual(appearanceSourceID),
    };
end

function C_TransmogCollection.GetAppearanceCameraID(visualID, fallbackCategory)
    if type(visualID) == "number" then
        local _, isWeapon, _, _, _, _, categoryInvType = C_TransmogCollection.GetCategoryInfo(fallbackCategory);
        local itemSubType;
        local invType = categoryInvType;
        local info = ezCollections:GetSkinInfo(visualID);
        if visualID ~= ezCollections:GetHiddenVisualItem() then
            itemSubType, _, invType = select(7, GetItemInfo(visualID));
            if not invType then
                invType = info and ezCollections.InvTypeEnumToName[info.InventoryType];
            end
            if not invType then
                invType = categoryInvType;
            end
        end
        if isWeapon or info and info.Weapon then
            return ezCollections:GetWeaponCameraID(invType, itemSubType and ItemSubTypeToSubClassID(itemSubType), info and info.Camera);
        else
            return ezCollections:GetCharacterCameraID(invType, info and info.Camera);
        end
    else
        return nil;
    end
end

function C_TransmogCollection.GetAppearanceCameraIDBySource(appearanceSourceID, fallbackCategory)
    return C_TransmogCollection.GetAppearanceCameraID(appearanceSourceID, fallbackCategory);
end

function C_TransmogCollection.GetSourceRequiredHoliday(sourceID)
    local info = ezCollections:GetSkinInfo(sourceID);
    if info and info.Holiday then
        return ezCollections.Holidays[info.Holiday];
    end
end

function C_TransmogCollection.GetSourceItemID(sourceID)
    return sourceID ~= 0 and sourceID or nil;
end

function C_TransmogCollection.GetIllusionInfo(sourceID)
    local hidden = ezCollections:GetHiddenEnchant();
    local name = C_TransmogCollection.GetIllusionStrings(sourceID);
    if sourceID == hidden or sourceID == ezCollections:GetHiddenVisualItem() then
        return
        {
            sourceID = sourceID,
            name = name,
            isCollected = true,
            isHideVisual = true,
            icon = ezCollections:GetSkinIcon(sourceID),
        };
    end
    local info = ezCollections:GetSkinInfo(sourceID);
    return
    {
        sourceID = sourceID,
        name = name,
        isCollected = ezCollections:HasAvailableSkin(sourceID),
        isHideVisual = false,
        icon = ezCollections:GetSkinIcon(sourceID),
        sourceType = MakeSourceType(info),
        -- Custom
        sourceText = MakeSourceText(info),
    };
end

function C_TransmogCollection.GetIllusionSourceInfo(sourceID)
    local hidden, name = ezCollections:GetHiddenEnchant();
    if sourceID == hidden or sourceID == ezCollections:GetHiddenVisualItem() then return sourceID, name; end
    return sourceID, sourceID and ezCollections:TransformEnchantName(select(2, GetItemInfo(sourceID)) or "");
end

function C_TransmogCollection.GetIllusionFallbackWeaponSource()
    return 2018;
end

function C_TransmogCollection.GetIllusionStrings(illusionID)
    local hidden, name = ezCollections:GetHiddenEnchant();
    local hyperlink;
    if illusionID == hidden or illusionID == ezCollections:GetHiddenVisualItem() then
        -- nothing
    else
        name, hyperlink = GetItemInfo(illusionID);
        name = name and ezCollections:TransformEnchantName(hyperlink or "");
    end
    return name or "", hyperlink or "";
end

function C_TransmogCollection.GetAllAppearanceSources()
    -- TODO:
end

function C_TransmogCollection.GetItemInfo()
    -- TODO:
end

function C_TransmogCollection.GetAppearanceSourceDrops(itemModifiedAppearanceID)
    local info = ezCollections:GetSkinInfo(itemModifiedAppearanceID);
    if MakeSourceType(info) == TRANSMOG_SOURCE_BOSS_DROP then
        local drops = { };
        local bosses = info.SourceBosses;
        if type(bosses) == "string" then
            bosses = { strsplit(",", bosses) };
            for i, boss in ipairs(bosses) do
                bosses[i] = tonumber(boss);
                if boss and boss:sub(1, 1) == "0" then
                    bosses[i] = -bosses[i];
                end
            end
        end
        for _, boss in ipairs(bosses) do
            local encounter = ezCollections:GetEncounterInfo(math.abs(boss), boss < 0);
            if encounter then
                local instance = ezCollections:GetInstanceInfo(encounter.Map);
                if instance then
                    local encounterInfo =
                    {
                        instance = instance.Name,
                        instanceType = instance.Type,
                        tiers = { instance.Tier },
                        encounter = encounter.Name,
                        difficulties = { encounter.Difficulty },
                    };
                    table.insert(drops, encounterInfo);
                end
            end
        end
        return drops;
    end
end

function C_TransmogCollection.GetAppearanceSources(appearanceID, category)
    local invType = category and select(7, C_TransmogCollection.GetCategoryInfo(category));
    invType = invType and ezCollections.InvTypeNameToEnum[invType];
    local slot = invType and C_Transmog.GetSlotForInventoryType(invType + 1);

    local sources = { };
    if appearanceID then
        local name, _, quality = GetItemInfo(appearanceID);
        if quality ~= nil and quality > 6 then quality = 6; end
        local isCollected = ezCollections:HasAvailableSkin(appearanceID);
        local info = ezCollections:GetSkinInfo(appearanceID);
        table.insert(sources,
        {
            isCollected = isCollected,
            sourceIsCollectedPermanent = isCollected, -- TODO: Items in inventory should appear as sources too
            name = C_TransmogCollection.IsAppearanceHiddenVisual(appearanceID) and ezCollections:GetHiddenVisualItemName(slot) or name,
            quality = quality,
            sourceID = appearanceID,
            visualID = appearanceID,
            useError = not ezCollections:CanTransmogrify(appearanceID),
            sourceType = MakeSourceType(info),
            -- Custom
            sourceText = MakeSourceText(info),
        });
    end
    return sources;
end

function C_TransmogCollection.GetSourceIcon(sourceID)
    local icon = ezCollections:GetSkinIcon(sourceID);
    if not icon then
        ezCollections:QueryItem(sourceID);
    end
    return icon;
end

function C_TransmogCollection.GetSourceInfo(sourceID)
    local info = ezCollections:GetSkinInfo(sourceID);
    return
    {
        itemID = sourceID,
        invType = info and info.InventoryType,
        quality = select(3, GetItemInfo(sourceID)),
    };
end

function C_TransmogCollection.IsAppearanceHiddenVisual(appearanceID)
    return appearanceID == ezCollections:GetHiddenVisualItem();
end

-- Favorites

function C_TransmogCollection.GetIsAppearanceFavorite(appearanceID)
    return ezCollections:GetFavoritesContainer()[appearanceID] or false;
end

function C_TransmogCollection.SetIsAppearanceFavorite(visualID, set)
    ezCollections:GetFavoritesContainer()[visualID] = set or nil;
    ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
end

function C_TransmogCollection.CanSetFavoriteInCategory(category)
    return true;
end

function C_TransmogCollection.HasFavorites()
    return #ezCollections:GetFavoritesContainer() ~= 0;
end

-- Weapons

function C_TransmogCollection.IsCategoryValidForItem(category, equippedItemID)
    local _, isWeapon = C_TransmogCollection.GetCategoryInfo(category);
    if not isWeapon then return; end

    local equippedSubTypeName = select(7, GetItemInfo(equippedItemID));
    if equippedSubTypeName == select(LE_ITEM_ARMOR_SHIELD + 1, GetAuctionItemSubClasses(2)) then
        return category == LE_TRANSMOG_COLLECTION_TYPE_SHIELD;
    end

    local equippedSubType = equippedSubTypeName and ItemSubTypeToSubClassID(equippedSubTypeName);
    if not equippedSubType then return true; end -- Allow all categories just in case...

    local info = _categoryInfo[category];
    local compatibleMask = ezCollections.WeaponCompatibility[equippedSubType + 1];
    return not compatibleMask or info and info.WeaponSubClass and bit.band(compatibleMask, bit.lshift(1, info.WeaponSubClass)) ~= 0;
end

-- Illusions

function C_TransmogCollection.GetIllusions()
    local results = GetDBOrCachedSearchResults(nil);
    if not results then
        return { };
    end

    local illusionsList = { };
    PrepareFilter();
    if ezCollections:CanHideSlot("ENCHANT") and (not _queryAlways or ezCollections:TextMatchesSearch(select(2, ezCollections:GetHiddenEnchant()), _queryAlways)) then
        local id = ezCollections:GetHiddenVisualItem();
        table.insert(illusionsList,
        {
            visualID = id,
            sourceID = id,
            isCollected = true,
            isHideVisual = true,
            isUsable = ezCollections:CanTransmogrify(id),
            hasActiveRequiredHoliday = nil,
            isFavorite = false,
            uiOrder = 0,
        });
    end

    for index, id in ipairs(results) do
        if type(id) == "number" then
            local matchesFilter, isCollected, isUsable, hasActiveRequiredHoliday = MatchesFilter(id);
            if matchesFilter then
                local info = ezCollections:GetSkinInfo(id);
                table.insert(illusionsList,
                {
                    visualID = id,
                    sourceID = id,
                    isCollected = isCollected,
                    isHideVisual = false,
                    isUsable = isUsable,
                    hasActiveRequiredHoliday = hasActiveRequiredHoliday,
                    isFavorite = C_TransmogCollection.GetIsAppearanceFavorite(id),
                    uiOrder = -index * 100,
                    sourceType = MakeSourceType(info),
                    -- Custom
                    sourceText = MakeSourceText(info),
                    isStoreSource = ezCollections:IsStoreItem(id, info),
                    isSubscriptionSource = ezCollections:GetSubscriptionForSkin(id),
                });
            end
        end
    end
    return illusionsList;
end

-- Usable

function C_TransmogCollection.PlayerKnowsSource(sourceID)
    return true;
end

function C_TransmogCollection.PlayerCanCollectSource(sourceID)
    local isInfoReady, canCollect;
    return isInfoReady, canCollect; -- Unused
end

function C_TransmogCollection.UpdateUsableAppearances()
    ezCollections:WipeSearchResults(LE_TRANSMOG_SEARCH_TYPE_ITEMS);
    C_TransmogCollection.WipeAppearanceCache();
    C_TransmogSets.ReportSetSourceCollectedChanged();
end

function C_TransmogCollection.PlayerHasTransmog()
    -- TODO:
end

function C_TransmogCollection.PlayerHasTransmogItemModifiedAppearance()
    -- TODO:
end

-- New

function C_TransmogCollection.IsNewAppearance(visualID)
    return ezCollections.Config.TransmogCollection.NewAppearances[visualID];
end

function C_TransmogCollection.ClearNewAppearance(visualID)
    ezCollections.Config.TransmogCollection.NewAppearances[visualID] = nil;
    if ezCollections.Config.TransmogCollection.LatestAppearanceID == visualID then
        ezCollections.Config.TransmogCollection.LatestAppearanceID = nil;
        ezCollections.Config.TransmogCollection.LatestAppearanceCategoryID = nil;
    end
end

function C_TransmogCollection.GetLatestAppearance()
    if not ezCollections.Config then return; end
    return ezCollections.Config.TransmogCollection.LatestAppearanceID, ezCollections.Config.TransmogCollection.LatestAppearanceCategoryID;
end

function C_TransmogCollection.AddNewAppearance(visualID) -- Custom
    ezCollections.Config.TransmogCollection.NewAppearances[visualID] = true;
    ezCollections.Config.TransmogCollection.LatestAppearanceID = visualID;
    ezCollections.Config.TransmogCollection.LatestAppearanceCategoryID = ezCollections:GetSkinCategory(visualID);

    local skin = ezCollections:GetSkinInfo(visualID);
    if skin and skin.Sets then
        ezCollections.Config.TransmogCollection.NewSetSources[visualID] = true;
        ezCollections.Config.TransmogCollection.LatestSetSource = visualID;
    end
end

-- Outfits

function C_TransmogCollection.GetOutfits()
    local ids = { };
    for id in pairs(ezCollections.Outfits) do
        table.insert(ids, id);
    end
    table.sort(ids);

    local outfits = { };
    for _, id in ipairs(ids) do
        table.insert(outfits,
        {
            outfitID = id,
            name = C_TransmogCollection.GetOutfitName(id),
            icon = MakeOutfitIcon(id),
            prepaid = C_TransmogCollection.GetOutfitPrepaid(id) or nil,
        });
    end
    return outfits or { };
end

function C_TransmogCollection.GetOutfitSources(outfitID)
    local outfit = ezCollections.Outfits[outfitID];
    if outfit then
        local appearanceSources = { };
        local mainHandEnchant;
        local offHandEnchant;
        for _, slotString in ipairs({ strsplit(":", outfit.Slots) }) do
            local slot, data = strsplit("=", slotString);
            slot = tonumber(slot);
            local entry, enchant = strsplit(",", data);
            entry = tonumber(entry);
            enchant = tonumber(enchant);

            if entry and entry ~= 0 then
                appearanceSources[slot] = entry;
            end
            if enchant and slot == GetInventorySlotInfo("MAINHANDSLOT") then
                mainHandEnchant = enchant == ezCollections:GetHiddenEnchant() and ezCollections:GetHiddenVisualItem() or ezCollections:GetScrollFromEnchant(enchant);
            elseif enchant and slot == GetInventorySlotInfo("SECONDARYHANDSLOT") then
                offHandEnchant = enchant == ezCollections:GetHiddenEnchant() and ezCollections:GetHiddenVisualItem() or ezCollections:GetScrollFromEnchant(enchant);
            end
        end
        return appearanceSources, mainHandEnchant, offHandEnchant;
    end
end

function C_TransmogCollection.GetOutfitName(outfitID)
    local outfit = ezCollections.Outfits[outfitID];
    return outfit and outfit.Name;
end

function C_TransmogCollection.GetOutfitPrepaid(outfitID) -- Custom
    if not ezCollections.PrepaidOutfitsEnabled then return false; end
    local outfit = ezCollections.Outfits[outfitID];
    return outfit and bit.band(outfit.Flags, 0x1) ~= 0;
end

function C_TransmogCollection.DeleteOutfit(outfitID)
    if ezCollections.Outfits[outfitID] then
        ezCollections:SendAddonMessage(format("TRANSMOGRIFY:OUTFIT:REMOVE:%d", outfitID));
    end
end

function C_TransmogCollection.QueryOutfitCost(name, sources, mainHandEnchant, offHandEnchant, icon, prepaid, editedOutfitID) -- Custom
    ezCollections:SendAddonMessage(format("TRANSMOGRIFY:OUTFIT:%s:%s", editedOutfitID and format("EDITCOST:%d", editedOutfitID) or "COST", MakeOutfitData(name, sources, mainHandEnchant, offHandEnchant, icon, prepaid)));
end

function C_TransmogCollection.SaveOutfit(name, sources, mainHandEnchant, offHandEnchant, icon, prepaid, editedOutfitID)
    ezCollections:SendAddonMessage(format("TRANSMOGRIFY:OUTFIT:%s:%s", editedOutfitID and format("EDIT:%d", editedOutfitID) or "ADD", MakeOutfitData(name, sources, mainHandEnchant, offHandEnchant, icon, prepaid)));
end

function C_TransmogCollection.ModifyOutfit(outfitID, newName)
    if ezCollections.Outfits[outfitID] then
        ezCollections:SendAddonMessage(format("TRANSMOGRIFY:OUTFIT:RENAME:%d:%s", outfitID, ezCollections:Encode(newName)));
    end
end

function C_TransmogCollection.GetNumMaxOutfits()
    return ezCollections.MaxOutfits;
end

-- Inspect

function C_TransmogCollection.GetInspectSources()
    -- TODO:
end

-- Search

local function SearchUpdated()
    ezCollections:RaiseEvent("TRANSMOG_SEARCH_UPDATED", LE_TRANSMOG_SEARCH_TYPE_ITEMS, _category);
    WardrobeResetFiltersButton_UpdateVisibility();
end

function C_TransmogCollection.SetSearch(type, text)
    _lastSearchText = text;

    text = ezCollections:UseServersideTextSearch() and text or "";
    _search[type] = { Category = _category, Text = text };
    local finished = false;
    if WardrobeFrame_IsAtTransmogrifier() and type == LE_TRANSMOG_SEARCH_TYPE_ITEMS and not (text == "" and GetValidSearchCache(type, _category)) then
        _search[type].Token, finished = ezCollections:Search(type, _category, text, GetInventorySlotInfo(WardrobeCollectionFrame.ItemsCollectionFrame:GetActiveSlot()));
    elseif WardrobeFrame_IsAtTransmogrifier() and type == LE_TRANSMOG_SEARCH_TYPE_USABLE_SETS then
        _search[type].Token, finished = ezCollections:Search(type, _category, text, tonumber(ezCollections:GetCVar("transmogrifySetsSlotMask")) or 0);
    elseif ezCollections:UseServersideTextSearch() then
        _search[type].Token, finished = ezCollections:Search(type, _category, text);
    else
        _search[type] = nil;
        ezCollections:RaiseEvent("TRANSMOG_SEARCH_UPDATED", type, _category);
        return true;
    end
    -- If search was started (or was deduped and already finished) - retrieve results right now
    if finished then
        ezCollections.Callbacks.SearchFinished(type);
    end
    return finished;
end

function C_TransmogCollection.ClearSearch(type)
    if not _lastSearchText then return; end
    local search = _search[type];
    if search and search.Token then
        ezCollections:EndSearch(type, search.Token);
    end
    _lastSearchText = nil;
    C_TransmogCollection.WipeSearchResults(type);
    if type == LE_TRANSMOG_SEARCH_TYPE_ITEMS then
        ezCollections:RaiseEvent("TRANSMOG_SEARCH_UPDATED", type, _category);
    else
        ezCollections:RaiseEvent("TRANSMOG_SEARCH_UPDATED", type);
    end
end

function C_TransmogCollection.EndSearch()
    for type, search in pairs(_search) do
        if search.Token and not search.Results then
            ezCollections:EndSearch(type, _search[type].Token);
        end
    end
    table.wipe(_search);
    ezCollections:WipeSearchResults();
    C_TransmogSets.ReportSetSourceCollectedChanged();
end

function C_TransmogCollection.GetSearchData(type) -- Custom
    return _search[type];
end

function C_TransmogCollection.GetLastSearchText() -- Custom
    return _lastSearchText;
end

function C_TransmogCollection.WipeSearchResults(type) -- Custom
    _search[type] = nil;
end

function C_TransmogCollection.WipeAppearanceCache() -- Custom
    table.wipe(_appearanceSlotCache);
    table.wipe(_illusionSlotCache);
    C_TransmogCollection.WipeSearchResults(LE_TRANSMOG_SEARCH_TYPE_ITEMS);
end

function C_TransmogCollection.SearchFinished(type, token, category, text, results) -- Custom
    local search = _search[type];
    if search and search.Token == token and search.Category == category and search.Text == text then
        search.Results = results;
        ezCollections:RaiseEvent("TRANSMOG_SEARCH_UPDATED", type, category);
        if type == LE_TRANSMOG_SEARCH_TYPE_USABLE_SETS then
            ezCollections:RaiseEvent("TRANSMOG_COLLECTION_ITEM_UPDATE"); -- To reload the selected set so it chooses applicable sources (sent by server)
        end
    end
end

function C_TransmogCollection.IsSearchInProgress(type)
    local search = _search[type];
    if search and search.Token then
        return search.Token and ezCollections:IsSearchInProgress(type);
    end
    return false;
end

function C_TransmogCollection.IsSearchDBLoading()
    return false;
end

function C_TransmogCollection.SearchProgress(type)
    local searchProgress = ezCollections.LastSearch[type].Duration;
    return searchProgress;
end

function C_TransmogCollection.SearchSize(type)
    local searchSize = ezCollections.SearchDelay;
    return searchSize;
end

-- Filter

function C_TransmogCollection.SetSearchAndFilterCategory(category)
    _category = category;
end

function C_TransmogCollection.SetCollectedShown(value)
    if ezCollections:SetCVar(GetShowCollectedCVar(), value) then
        SearchUpdated();
    end
end

function C_TransmogCollection.SetUncollectedShown(value)
    if ezCollections:SetCVar(GetShowUncollectedCVar(), value) then
        SearchUpdated();
    end
end

function C_TransmogCollection.GetCollectedShown()
    return ezCollections:GetCVar(GetShowCollectedCVar());
end

function C_TransmogCollection.GetUncollectedShown()
    return ezCollections:GetCVar(GetShowUncollectedCVar());
end

function C_TransmogCollection.SetSourceTypeFilter(i, value)
    if ezCollections:SetCVarBitfield(GetSourceFilterCVar(), i, not value) then
        SearchUpdated();
    end
end

function C_TransmogCollection.IsSourceTypeFilterChecked(i)
    return ezCollections:GetCVarBitfield(GetSourceFilterCVar(), i);
end

function C_TransmogCollection.SetAllSourceTypeFilters(value)
    for i = 1, C_TransmogCollection.GetNumTransmogSources() do
        ezCollections:SetCVarBitfield(GetSourceFilterCVar(), i, not value);
    end
    SearchUpdated();
end

function C_TransmogCollection.GetNumTransmogSources()
    return MAX_TRANSMOG_SOURCES;
end

function C_TransmogCollection.SetAllArmorTypeFilters(value) -- Custom
    for i = 1, 6 do
        ezCollections:SetCVarBitfield(GetArmorFilterCVar(), i, not value);
    end
    SearchUpdated();
end

function C_TransmogCollection.SetArmorTypeFilter(i, value) -- Custom
    if ezCollections:SetCVarBitfield(GetArmorFilterCVar(), i, not value) then
        SearchUpdated();
    end
end

function C_TransmogCollection.IsArmorTypeFilterChecked(i) -- Custom
    return not ezCollections:GetCVarBitfield(GetArmorFilterCVar(), i);
end

function C_TransmogCollection.SetAllClassFilters(value) -- Custom
    for _, class in ipairs(CLASS_SORT_ORDER) do
        ezCollections:SetCVarBitfield(GetClassFilterCVar(), ezCollections.ClassNameToID[class], not value);
    end
    ezCollections:SetCVarBitfield(GetClassFilterCVar(), ezCollections.ClassNameToID["ANY"], not value);
    SearchUpdated();
end

function C_TransmogCollection.SetClassFilter(i, value) -- Custom
    if ezCollections:SetCVarBitfield(GetClassFilterCVar(), i, not value) then
        SearchUpdated();
    end
end

function C_TransmogCollection.IsClassFilterChecked(i) -- Custom
    return not ezCollections:GetCVarBitfield(GetClassFilterCVar(), i);
end

function C_TransmogCollection.SetAllRaceFilters(value) -- Custom
    for _, race in ipairs(ezCollections.RaceSortOrder) do
        ezCollections:SetCVarBitfield(GetRaceFilterCVar(), ezCollections.RaceNameToID[race], not value);
    end
    ezCollections:SetCVarBitfield(GetRaceFilterCVar(), ezCollections.RaceNameToID["ANY"], not value);
    SearchUpdated();
end

function C_TransmogCollection.SetRaceFilter(i, value) -- Custom
    if ezCollections:SetCVarBitfield(GetRaceFilterCVar(), i, not value) then
        SearchUpdated();
    end
end

function C_TransmogCollection.IsRaceFilterChecked(i) -- Custom
    return not ezCollections:GetCVarBitfield(GetRaceFilterCVar(), i);
end

function C_TransmogCollection.SetFactionFilters(faction, value) -- Custom
    for race, raceFaction in pairs(ezCollections.RaceNameToFaction) do
        if raceFaction == faction then
            ezCollections:SetCVarBitfield(GetRaceFilterCVar(), ezCollections.RaceNameToID[race], not value);
        end
    end
    SearchUpdated();
end

function C_TransmogCollection.IsFactionFilterChecked(faction) -- Custom
    for race, raceFaction in pairs(ezCollections.RaceNameToFaction) do
        if raceFaction == faction and not C_TransmogCollection.IsRaceFilterChecked(ezCollections.RaceNameToID[race]) then
            return false;
        end
    end
    return true;
end

function C_TransmogCollection.SetAllExpansionFilters(value) -- Custom
    for i = 1, GetNumExpansions() do
        ezCollections:SetCVarBitfield(GetExpansionFilterCVar(), i, not value);
    end
    SearchUpdated();
end

function C_TransmogCollection.SetExpansionFilter(i, value) -- Custom
    if ezCollections:SetCVarBitfield(GetExpansionFilterCVar(), i, not value) then
        SearchUpdated();
    end
end

function C_TransmogCollection.IsExpansionFilterChecked(i) -- Custom
    return not ezCollections:GetCVarBitfield(GetExpansionFilterCVar(), i);
end

function C_TransmogCollection.SetDefaultFilters()
    ezCollections:SetCVar(GetSourceFilterCVar(), 0);
    ezCollections:SetCVar(GetArmorFilterCVar(), 0);
    ezCollections:SetCVar(GetClassFilterCVar(), 0);
    ezCollections:SetCVar(GetRaceFilterCVar(), 0);
    ezCollections:SetCVar(GetExpansionFilterCVar(), 0);
    ezCollections:SetCVarBool(GetShowCollectedCVar(), true);
    ezCollections:SetCVarBool(GetShowUncollectedCVar(), true);
    SearchUpdated();
end

function C_TransmogCollection.IsUsingDefaultFilters()
    return ezCollections:GetCVar(GetSourceFilterCVar()) == 0
        and ezCollections:GetCVar(GetArmorFilterCVar()) == 0
        and ezCollections:GetCVar(GetClassFilterCVar()) == 0
        and ezCollections:GetCVar(GetRaceFilterCVar()) == 0
        and ezCollections:GetCVar(GetExpansionFilterCVar()) == 0
        and ezCollections:GetCVarBool(GetShowCollectedCVar()) == true
        and ezCollections:GetCVarBool(GetShowUncollectedCVar()) == true;
end

function C_TransmogCollection.SetShowMissingSourceInItemTooltips(value)
    ezCollections:SetCVar("missingTransmogSourceInItemTooltips", value);
end

function C_TransmogCollection.GetShowMissingSourceInItemTooltips()
    return ezCollections:GetCVarBool("missingTransmogSourceInItemTooltips");
end

local ALPHABET_START = 0x26;
local ALPHABET_END = 0x7C;
local ALPHABET_SIZE = ALPHABET_END - ALPHABET_START;
local PLACES = 3;
local PLACE_VALUES = { 1, ALPHABET_SIZE, ALPHABET_SIZE * ALPHABET_SIZE };
function C_TransmogCollection.GetItemTransmogInfoListFromOutfitHyperlink(hyperlink)
    local payload = hyperlink:match("^item:0:outfit:(.-)$");
    if not payload or payload:len() ~= #TRANSMOG_SLOTS * PLACES then
        return;
    end

    local sources = { };
    local mainHandEnchant = nil;
    local offHandEnchant = nil;
    for slotIndex, slotInfo in ipairs(TRANSMOG_SLOTS) do
        local source = 0;
        for i = 1, PLACES do
            source = source + (payload:byte((slotIndex - 1) * PLACES + i) - ALPHABET_START) * PLACE_VALUES[PLACES - i + 1];
        end
        if source ~= 0 then
            local slotID = GetInventorySlotInfo(slotInfo.slot);
            if slotInfo.transmogType == LE_TRANSMOG_TYPE_APPEARANCE then
                sources[slotID] = source;
            elseif slotInfo.transmogType == LE_TRANSMOG_TYPE_ILLUSION then
                if slotID == INVSLOT_MAINHAND then
                    mainHandEnchant = source;
                end
                if slotID == INVSLOT_OFFHAND then
                    offHandEnchant = source;
                end
            end
        end
    end

    return sources, mainHandEnchant, offHandEnchant;
end

function C_TransmogCollection.GetOutfitHyperlinkFromItemTransmogInfoList(sources, mainHandEnchant, offHandEnchant)
    local payload = "";
    for slotIndex, slotInfo in ipairs(TRANSMOG_SLOTS) do
        local slotID = GetInventorySlotInfo(slotInfo.slot);
        local source;
        if slotInfo.transmogType == LE_TRANSMOG_TYPE_APPEARANCE then
            source = sources[slotID];
        elseif slotInfo.transmogType == LE_TRANSMOG_TYPE_ILLUSION then
            if slotID == INVSLOT_MAINHAND then
                source = mainHandEnchant;
            end
            if slotID == INVSLOT_OFFHAND then
                source = offHandEnchant;
            end
        end
        source = source or 0;
        for i = 1, PLACES do
            local denom = PLACE_VALUES[PLACES - i + 1];
            local quotient = math.floor(source / denom);
            local remainder = source % denom;
            if quotient >= ALPHABET_SIZE then -- Failure case if item ID is too large to fit into the block
                quotient = 0;
                remainder = 0;
            end
            payload = payload .. string.char(ALPHABET_START + quotient);
            source = remainder;
        end
    end

    return format("|cffff80ff|Hitem:0:outfit:%s|h[%s]|h|r", payload or "", TRANSMOG_OUTFIT_HYPERLINK_TEXT:match("^|T.-|t(.-)$") or "Outfit") or "";
end

function C_TransmogCollection.GetInspectSources()
    local sources = { };
    local mainHandEnchant = nil;
    local offHandEnchant = nil;
    if ezCollections.lastInspectTarget ~= "" and ezCollections.GetUnitName("target") == ezCollections.lastInspectTarget and IsInspectFrameShown() then
        for slotIndex, slotInfo in ipairs(TRANSMOG_SLOTS) do
            local slotID = GetInventorySlotInfo(slotInfo.slot);

            local _, id, enchant = strsplit(":", GetInventoryItemLink("target", slotID) or "");

            id = GetInventoryItemID("target", slotID) or tonumber(id) or 0;
            enchant = tonumber(enchant) or 0;
            local fakeEntry, _, fakeEnchant = ezCollections:GetItemTransmog("target", slotID);

            if fakeEntry and fakeEntry ~= 0 then
                id = fakeEntry;
            end
            if fakeEnchant and fakeEnchant ~= 0 then
                enchant = fakeEnchant;
            end

            if slotID == INVSLOT_RANGED and UnitHasRelicSlot("target") then
                id = nil;
            end

            if id and id ~= 0 then
                sources[slotID] = id;
            end
            if enchant and enchant ~= 0 then
                if slotID == INVSLOT_MAINHAND then
                    mainHandEnchant = enchant == ezCollections:GetHiddenEnchant() and ezCollections:GetHiddenVisualItem() or ezCollections:GetScrollFromEnchant(enchant);
                elseif slotID == INVSLOT_OFFHAND then
                    offHandEnchant = enchant == ezCollections:GetHiddenEnchant() and ezCollections:GetHiddenVisualItem() or ezCollections:GetScrollFromEnchant(enchant);
                end
            end
        end
    end

    return sources, mainHandEnchant, offHandEnchant;
end
