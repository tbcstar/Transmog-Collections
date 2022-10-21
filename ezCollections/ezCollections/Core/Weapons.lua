function ezCollections:GetInvType(id)
    local info = ezCollections:GetSkinInfo(id);
    local invType = info and info.InventoryType;
    if invType then
        return invType - 1;
    end

    invType = select(9, GetItemInfo(id));
    invType = ezCollections.InvTypeNameToEnum[invType];
    if invType then
        return invType;
    end
end

local equippableSlotMaskByInvType =
{
    0x0,      -- INVTYPE_NON_EQUIP
    0x1,      -- INVTYPE_HEAD
    0x2,      -- INVTYPE_NECK
    0x4,      -- INVTYPE_SHOULDERS
    0x8,      -- INVTYPE_BODY
    0x10,     -- INVTYPE_CHEST
    0x20,     -- INVTYPE_WAIST
    0x40,     -- INVTYPE_LEGS
    0x80,     -- INVTYPE_FEET
    0x100,    -- INVTYPE_WRISTS
    0x200,    -- INVTYPE_HANDS
    0xC00,    -- INVTYPE_FINGER
    0x3000,   -- INVTYPE_TRINKET
    0x18000,  -- INVTYPE_WEAPON
    0x10000,  -- INVTYPE_SHIELD
    0x20000,  -- INVTYPE_RANGED
    0x4000,   -- INVTYPE_CLOAK
    0x18000,  -- INVTYPE_2HWEAPON
    0x780000, -- INVTYPE_BAG
    0x40000,  -- INVTYPE_TABARD
    0x10,     -- INVTYPE_ROBE
    0x18000,  -- INVTYPE_WEAPONMAINHAND
    0x18000,  -- INVTYPE_WEAPONOFFHAND
    0x10000,  -- INVTYPE_HOLDABLE
    0x0,      -- INVTYPE_AMMO
    0x20000,  -- INVTYPE_THROWN
    0x20000,  -- INVTYPE_RANGEDRIGHT
    0x0,      -- INVTYPE_QUIVER
    0x20000,  -- INVTYPE_RELIC
};

local function PlayerCanEquipInvTypeInSlot(invType, slot)
    return bit.band(bit.lshift(1, slot - 1), equippableSlotMaskByInvType[invType + 1]) ~= 0;
end

function ezCollections:PlayerCanDualWield()
    return IsSpellKnown(674);
end

function ezCollections:PlayerCanTitanGrip()
    return select(2, UnitClass("player")) == "WARRIOR" and select(5, GetTalentInfo(2, 27)) > 0;
end

local function GetWeaponSubType(id)
    local itemSubType = select(7, GetItemInfo(id));
    for i = 1, NUM_LE_ITEM_WEAPON do
        if itemSubType == select(i, GetAuctionItemSubClasses(1)) then
            return i - 1;
        end
    end
end

local titanGrippableSubTypes =
{
    [LE_ITEM_WEAPON_AXE1H] = true,
    [LE_ITEM_WEAPON_AXE2H] = true,
    [LE_ITEM_WEAPON_MACE1H] = true,
    [LE_ITEM_WEAPON_MACE2H] = true,
    [LE_ITEM_WEAPON_SWORD1H] = true,
    [LE_ITEM_WEAPON_SWORD2H] = true,
    [LE_ITEM_WEAPON_FIST] = false,
    [LE_ITEM_WEAPON_DAGGER] = true,
};

function ezCollections:IsTitanGrippableSubType(subType)
    return titanGrippableSubTypes[subType];
end

function ezCollections:CanEquipItemIntoSlot(id, slot)
    if not id then
        return false;
    end
    local invType = ezCollections:GetInvType(id);
    if not invType then
        return false;
    end
    if slot == 18 then
        if (UnitHasRelicSlot("player") and true or false) ~= (invType == 28) then
            return false;
        end
    end
    if select(6, GetItemInfo(id)) == select(1, GetAuctionItemClasses()) and (slot == 16 and (invType == 22) or slot == 17 and (invType == 17 or invType == 21)) then
        return ezCollections:PlayerCanTitanGrip() and ezCollections:IsTitanGrippableSubType(GetWeaponSubType(id)) and PlayerCanEquipInvTypeInSlot(invType, slot);
    end
    return slot >= 24 or PlayerCanEquipInvTypeInSlot(invType, slot);
end

function ezCollections:CanDualWieldWeapons(mh, oh, canDualWield)
    local mhInvType = ezCollections:GetInvType(mh);
    local ohInvType = ezCollections:GetInvType(oh);
    if mhInvType ~= 13 and mhInvType ~= 21 then
        return mhInvType == 17 and ohInvType ~= 15 and ezCollections:CanEquipItemIntoSlot(mh, 17);
    end
    if ohInvType == 14 or ohInvType == 23 then
        return true;
    end
    if ohInvType ~= 13 and ohInvType ~= 22 then
        return (ohInvType == 21 or ohInvType == 17) and ezCollections:CanEquipItemIntoSlot(oh, 17);
    end
    return canDualWield;
end

function ezCollections:AreWeaponsImpossibleToDisplayInPlayerModel(mh, oh)
    local isLocalPlayer = true;
    return mh and mh ~= 0 and oh and oh ~= 0 and not (ezCollections:CanEquipItemIntoSlot(mh, 16) and ezCollections:CanEquipItemIntoSlot(oh, 17) and ezCollections:CanDualWieldWeapons(mh, oh, isLocalPlayer and ezCollections:PlayerCanDualWield()));
end
