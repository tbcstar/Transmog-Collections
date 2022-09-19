C_TransmogCollection = C_TransmogCollection or { };

local _search = { };
local _lastSearchText = nil;
local _category = nil;
local _appearanceSlotCache = { };
local _showCollected = nil;
local _showUncollected = nil;
local _sourceMask = nil;
local _armorTypeMask = nil;
local _armorTypeMaskAny = nil;
local _classMask = nil;
local _classMaskAny = nil;
local _raceMask = nil;
local _raceMaskAny = nil;

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
    _sourceMask = bit.bnot(ezCollections:GetCVar(GetSourceFilterCVar()));
    _armorTypeMask = bit.bnot(ezCollections:GetCVar(GetArmorFilterCVar()));
    _armorTypeMaskAny = bit.lshift(1, 6 - 1);
    _classMask = bit.bnot(ezCollections:GetCVar(GetClassFilterCVar()));
    _classMaskAny = bit.lshift(1, ezCollections.ClassNameToID["ANY"] - 1);
    _raceMask = bit.bnot(ezCollections:GetCVar(GetRaceFilterCVar()));
    _raceMaskAny = bit.lshift(1, ezCollections.RaceNameToID["ANY"] - 1);
end

local function MatchesFilter(id)
    local isCollected = ezCollections:HasAvailableSkin(id) or false;
    if not (_showCollected and isCollected or _showUncollected and not isCollected) then
        return false, isCollected;
    end

    local info = ezCollections:GetSkinInfo(id);
    if info and info.SourceMask and bit.band(info.SourceMask, _sourceMask) == 0 then
        return false, isCollected;
    end

    if info and info.Armor and bit.band(bit.lshift(1, info.Armor), _armorTypeMask) == 0 then
        return false, isCollected;
    end

    if info and not info.Armor and not info.Weapon and bit.band(_armorTypeMaskAny, _armorTypeMask) == 0 then
        return false, isCollected;
    end

    if info and info.ClassMask and bit.band(info.ClassMask, _classMask) == 0 then
        return false, isCollected;
    end

    if info and not info.ClassMask and bit.band(_classMaskAny, _classMask) == 0 then
        return false, isCollected;
    end

    if info and info.RaceMask and bit.band(info.RaceMask, _raceMask) == 0 then
        return false, isCollected;
    end
    if info and not info.RaceMask and bit.band(_raceMaskAny, _raceMask) == 0 then
        return false, isCollected;
    end

    return true, isCollected, info and not info.Unusable, info and info.Holiday and ezCollections:IsHolidayActive(info.Holiday) or false;
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

local invTypeEnumToName =
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
            [LE_TRANSMOG_COLLECTION_TYPE_WAND]         = { InvType = "INVTYPE_WEAPON",   WeaponSlotMask = 4, WeaponSubClass = LE_ITEM_WEAPON_WAND },
            [LE_TRANSMOG_COLLECTION_TYPE_1H_AXE]       = { InvType = "INVTYPE_WEAPON",   WeaponSlotMask = 3, WeaponSubClass = LE_ITEM_WEAPON_AXE1H },
            [LE_TRANSMOG_COLLECTION_TYPE_1H_SWORD]     = { InvType = "INVTYPE_WEAPON",   WeaponSlotMask = 3, WeaponSubClass = LE_ITEM_WEAPON_SWORD1H },
            [LE_TRANSMOG_COLLECTION_TYPE_1H_MACE]      = { InvType = "INVTYPE_WEAPON",   WeaponSlotMask = 3, WeaponSubClass = LE_ITEM_WEAPON_MACE1H },
            [LE_TRANSMOG_COLLECTION_TYPE_DAGGER]       = { InvType = "INVTYPE_WEAPON",   WeaponSlotMask = 3, WeaponSubClass = LE_ITEM_WEAPON_DAGGER },
            [LE_TRANSMOG_COLLECTION_TYPE_FIST]         = { InvType = "INVTYPE_WEAPON",   WeaponSlotMask = 3, WeaponSubClass = LE_ITEM_WEAPON_FIST },
            [LE_TRANSMOG_COLLECTION_TYPE_SHIELD]       = { InvType = "INVTYPE_WEAPON",   WeaponSlotMask = 2, ArmorSubClass = LE_ITEM_ARMOR_SHIELD },
            [LE_TRANSMOG_COLLECTION_TYPE_HOLDABLE]     = { InvType = "INVTYPE_HOLDABLE", WeaponSlotMask = 2 },
            [LE_TRANSMOG_COLLECTION_TYPE_2H_AXE]       = { InvType = "INVTYPE_WEAPON",   WeaponSlotMask = 3, WeaponSubClass = LE_ITEM_WEAPON_AXE2H },
            [LE_TRANSMOG_COLLECTION_TYPE_2H_SWORD]     = { InvType = "INVTYPE_WEAPON",   WeaponSlotMask = 3, WeaponSubClass = LE_ITEM_WEAPON_SWORD2H },
            [LE_TRANSMOG_COLLECTION_TYPE_2H_MACE]      = { InvType = "INVTYPE_WEAPON",   WeaponSlotMask = 3, WeaponSubClass = LE_ITEM_WEAPON_MACE2H },
            [LE_TRANSMOG_COLLECTION_TYPE_STAFF]        = { InvType = "INVTYPE_WEAPON",   WeaponSlotMask = 3, WeaponSubClass = LE_ITEM_WEAPON_STAFF },
            [LE_TRANSMOG_COLLECTION_TYPE_POLEARM]      = { InvType = "INVTYPE_WEAPON",   WeaponSlotMask = 3, WeaponSubClass = LE_ITEM_WEAPON_POLEARM },
            [LE_TRANSMOG_COLLECTION_TYPE_BOW]          = { InvType = "INVTYPE_WEAPON",   WeaponSlotMask = 4, WeaponSubClass = LE_ITEM_WEAPON_BOWS },
            [LE_TRANSMOG_COLLECTION_TYPE_GUN]          = { InvType = "INVTYPE_WEAPON",   WeaponSlotMask = 4, WeaponSubClass = LE_ITEM_WEAPON_GUNS },
            [LE_TRANSMOG_COLLECTION_TYPE_CROSSBOW]     = { InvType = "INVTYPE_WEAPON",   WeaponSlotMask = 4, WeaponSubClass = LE_ITEM_WEAPON_CROSSBOW },
            [LE_TRANSMOG_COLLECTION_TYPE_THROWN]       = { InvType = "INVTYPE_WEAPON",   WeaponSlotMask = 4, WeaponSubClass = LE_ITEM_WEAPON_THROWN },
            [LE_TRANSMOG_COLLECTION_TYPE_FISHING_POLE] = { InvType = "INVTYPE_WEAPON",   WeaponSlotMask = 3, WeaponSubClass = LE_ITEM_WEAPON_FISHINGPOLE },
            [LE_TRANSMOG_COLLECTION_TYPE_MISC]         = { InvType = "INVTYPE_WEAPON",   WeaponSlotMask = 1, WeaponSubClass = LE_ITEM_WEAPON_GENERIC },
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
    local visualsList = { };
    if ezCollections:CanHideSlot(ezCollections:GetSlotByCategory(category)) then
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

    local search = _search[LE_TRANSMOG_SEARCH_TYPE_ITEMS];

    if search or WardrobeFrame_IsAtTransmogrifier() then
        local slot, id, enchant;
        if WardrobeFrame_IsAtTransmogrifier() then
            slot = GetInventorySlotInfo(WardrobeCollectionFrame.ItemsCollectionFrame:GetActiveSlot());
            local _;
            _, id, enchant = strsplit(":", GetInventoryItemLink("player", slot) or "");
            id = tonumber(id) or 0;
            enchant = tonumber(enchant) or 0;
            if id == 0 then
                return { };
            end
        end

        local source;
        local cache = slot and _appearanceSlotCache[slot] and _appearanceSlotCache[slot][category];
        if (not search or not search.Text) and cache and cache.Entry == id and cache.Enchant == enchant then
            source = cache;
        elseif search and search.Token and search.Category == category and ezCollections:IsSearchFinished(LE_TRANSMOG_SEARCH_TYPE_ITEMS, search.Token) and ezCollections:IsSearchMatchingParams(LE_TRANSMOG_SEARCH_TYPE_ITEMS, search.Token, search.Category, _lastSearchText, slot, id, enchant) then
            cache = nil;
            if slot and not search.Text then
                _appearanceSlotCache[slot] = _appearanceSlotCache[slot] or { };
                _appearanceSlotCache[slot][category] = _appearanceSlotCache[slot][category] or { };
                cache = _appearanceSlotCache[slot][category];
                table.wipe(cache);
                cache.Entry = id;
                cache.Enchant = enchant;
            end
            source = search.Results;
        else
            C_TransmogCollection.SetSearch(LE_TRANSMOG_SEARCH_TYPE_ITEMS, _lastSearchText);
            return { };
        end

        if source then
            PrepareFilter();
            for index, id in ipairs(source) do
                if type(id) == "number" then
                    if cache and cache ~= source then
                        table.insert(cache, id);
                    end
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
        end
    else
        local db = ezCollections:GetDBByCategory(category);
        if db.Loaded then
            PrepareFilter();
            for index, id in ipairs(db) do
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
    local collected = 0;
    local db = ezCollections:GetDBByCategory(category);
    if db.Loaded then
        for index, id in ipairs(db) do
            if type(id) == "number" then
                if ezCollections:HasSkin(id) then
                    collected = collected + 1;
                end
            end
        end
    end
    return collected;
end

-- Sources

function C_TransmogCollection.GetAppearanceSourceInfo(appearanceSourceID)
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
    return { sourceIsCollectedPermanent = true };
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
                invType = info and invTypeEnumToName[info.InventoryType];
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

function C_TransmogCollection.GetAppearanceCameraIDBySource(appearanceSourceID)
    return C_TransmogCollection.GetAppearanceCameraID(appearanceSourceID, LE_TRANSMOG_COLLECTION_TYPE_WAND);
end

function C_TransmogCollection.GetSourceRequiredHoliday(sourceID)
    local info = ezCollections:GetSkinInfo(sourceID);
    if info and info.Holiday then
        return ezCollections.Holidays[info.Holiday];
    end
end

function C_TransmogCollection.GetIllusionSourceInfo(sourceID)
    local hidden, name = ezCollections:GetHiddenEnchant();
    if sourceID == hidden or sourceID == ezCollections:GetHiddenVisualItem() then return sourceID, name; end
    return sourceID, sourceID and ezCollections:TransformEnchantName(select(2, GetItemInfo(sourceID)) or "");
end

function C_TransmogCollection.GetIllusionFallbackWeaponSource()
    return 22322;
end

function C_TransmogCollection.GetAllAppearanceSources()
    -- TODO:
end

function C_TransmogCollection.GetItemInfo()
    -- TODO:
end

function C_TransmogCollection.GetAppearanceSourceDrops(itemModifiedAppearanceID)
    local info = ezCollections:GetSkinInfo(itemModifiedAppearanceID);
    if info and info.SourceMask and bit.band(info.SourceMask, bit.lshift(1, TRANSMOG_SOURCE_BOSS_DROP - 1)) ~= 0 and info.SourceBosses then
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

function C_TransmogCollection.GetAppearanceSources(appearanceID)
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
            name = name,
            quality = quality,
            sourceID = appearanceID,
            visualID = appearanceID,
            useError = not ezCollections:CanTransmogrify(appearanceID),
            sourceType = (function()
                if info and info.SourceMask and bit.band(info.SourceMask, bit.lshift(1, TRANSMOG_SOURCE_BOSS_DROP - 1)) ~= 0 and info.SourceBosses then
                    return TRANSMOG_SOURCE_BOSS_DROP;
                end
                return 0;
            end)(),
            -- Custom
            sourceText = (function()
                if info and info.SourceMask then
                    local result = "";
                    for i = 1, C_TransmogCollection.GetNumTransmogSources() do
                        if bit.band(info.SourceMask, bit.lshift(1, i - 1)) ~= 0 then
                            result = result .. (result ~= "" and ", " or "") .. _G["TRANSMOG_SOURCE_"..i];
                        end
                    end
                    return result;
                end
            end)();
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
    local illusionsList = { };
    local db = ezCollections:GetIllusionsDB();
    if ezCollections:CanHideSlot("ENCHANT") then
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
    if db.Loaded then
        for index, id in ipairs(db) do
            if type(id) == "number" then
                local info = ezCollections:GetSkinInfo(id);
                table.insert(illusionsList,
                {
                    visualID = id,
                    sourceID = id,
                    isCollected = ezCollections:HasAvailableSkin(id),
                    isHideVisual = false,
                    isUsable = ezCollections:CanTransmogrify(id),
                    hasActiveRequiredHoliday = nil,
                    isFavorite = C_TransmogCollection.GetIsAppearanceFavorite(id),
                    uiOrder = -index * 100,
                    sourceType = (function()
                        if info and info.SourceMask and bit.band(info.SourceMask, bit.lshift(1, TRANSMOG_SOURCE_BOSS_DROP - 1)) ~= 0 and info.SourceBosses then
                            return TRANSMOG_SOURCE_BOSS_DROP;
                        end
                        return 0;
                    end)(),
                    -- Custom
                    sourceText = (function()
                        if info and info.SourceMask then
                            local result = "";
                            for i = 1, C_TransmogCollection.GetNumTransmogSources() do
                                if bit.band(info.SourceMask, bit.lshift(1, i - 1)) ~= 0 then
                                    result = result .. (result ~= "" and ", " or "") .. _G["TRANSMOG_SOURCE_"..i];
                                end
                            end
                            return result;
                        end
                    end)();
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
    return ezCollections:HasAvailableSkin(sourceID) or sourceID == ezCollections:GetHiddenVisualItem();
end

function C_TransmogCollection.PlayerCanCollectSource(sourceID)
    local isInfoReady, canCollect;
    return isInfoReady, canCollect; -- Unused
end

function C_TransmogCollection.UpdateUsableAppearances()
    ezCollections:WipeSearchResults();
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

function C_TransmogCollection.SetSearch(type, text)
    _lastSearchText = text;
    _search[type] = { Category = _category, Text = text };
    if WardrobeFrame_IsAtTransmogrifier() and type == LE_TRANSMOG_SEARCH_TYPE_ITEMS then
        _search[type].Token = ezCollections:Search(type, _category, text, GetInventorySlotInfo(WardrobeCollectionFrame.ItemsCollectionFrame:GetActiveSlot()));
    elseif WardrobeFrame_IsAtTransmogrifier() and type == LE_TRANSMOG_SEARCH_TYPE_USABLE_SETS then
        _search[type].Token = ezCollections:Search(type, _category, text, tonumber(ezCollections:GetCVar("transmogrifySetsSlotMask")) or 0);
    else
        _search[type].Token = ezCollections:Search(type, _category, text);
    end
    local finished = false;
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
    ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
end

function C_TransmogCollection.EndSearch()
    for type, search in pairs(_search) do
        if search.Token and not search.Results then
            ezCollections:EndSearch(type, _search[type].Token);
        end
    end
    table.wipe(_search);
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
    C_TransmogCollection.WipeSearchResults(LE_TRANSMOG_SEARCH_TYPE_ITEMS);
end

function C_TransmogCollection.SearchFinished(type, token, category, text, results) -- Custom
    local search = _search[type];
    if search and search.Token == token and search.Category == category and search.Text == text then
        search.Results = results;
        if text then
            ezCollections:RaiseEvent("TRANSMOG_SEARCH_UPDATED", type, category);
        else
            ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
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
        ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
    end
end

function C_TransmogCollection.SetUncollectedShown(value)
    if ezCollections:SetCVar(GetShowUncollectedCVar(), value) then
        ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
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
        ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
    end
end

function C_TransmogCollection.IsSourceTypeFilterChecked(i)
    return ezCollections:GetCVarBitfield(GetSourceFilterCVar(), i);
end

function C_TransmogCollection.SetAllSourceTypeFilters(value)
    for i = 1, C_TransmogCollection.GetNumTransmogSources() do
        ezCollections:SetCVarBitfield(GetSourceFilterCVar(), i, not value);
    end
    ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
end

function C_TransmogCollection.GetNumTransmogSources()
    return MAX_TRANSMOG_SOURCES;
end

function C_TransmogCollection.SetAllArmorTypeFilters(value) -- Custom
    for i = 1, 6 do
        ezCollections:SetCVarBitfield(GetArmorFilterCVar(), i, not value);
    end
    ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
end

function C_TransmogCollection.SetArmorTypeFilter(i, value) -- Custom
    if ezCollections:SetCVarBitfield(GetArmorFilterCVar(), i, not value) then
        ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
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
    ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
end

function C_TransmogCollection.SetClassFilter(i, value) -- Custom
    if ezCollections:SetCVarBitfield(GetClassFilterCVar(), i, not value) then
        ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
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
    ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
end

function C_TransmogCollection.SetRaceFilter(i, value) -- Custom
    if ezCollections:SetCVarBitfield(GetRaceFilterCVar(), i, not value) then
        ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
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
    ezCollections:RaiseEvent("TRANSMOG_COLLECTION_UPDATED");
end

function C_TransmogCollection.IsFactionFilterChecked(faction) -- Custom
    for race, raceFaction in pairs(ezCollections.RaceNameToFaction) do
        if raceFaction == faction and not C_TransmogCollection.IsRaceFilterChecked(ezCollections.RaceNameToID[race]) then
            return false;
        end
    end
    return true;
end

function C_TransmogCollection.SetShowMissingSourceInItemTooltips(value)
    ezCollections:SetCVar("missingTransmogSourceInItemTooltips", value);
end

function C_TransmogCollection.GetShowMissingSourceInItemTooltips()
    return ezCollections:GetCVarBool("missingTransmogSourceInItemTooltips");
end
