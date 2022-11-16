local Transmogrify = require("transmogrificationSetting")
local VisualWeapon = Transmogrify.VisualWeapon;
local STORE = Transmogrify.STORE;

local INVTYPE_CHEST               = 5
local INVTYPE_WEAPON              = 13
local INVTYPE_ROBE                = 20
local INVTYPE_WEAPONMAINHAND      = 21
local INVTYPE_WEAPONOFFHAND       = 22

local ITEM_CLASS_WEAPON           = 2
local ITEM_CLASS_ARMOR            = 4

local ITEM_SUBCLASS_WEAPON_BOW          = 2
local ITEM_SUBCLASS_WEAPON_GUN          = 3
local ITEM_SUBCLASS_WEAPON_THROWN       = 16
local ITEM_SUBCLASS_WEAPON_CROSSBOW     = 18
local ITEM_SUBCLASS_WEAPON_WAND         = 19

local ITEM_SUBCLASS_WEAPON_FISHING_POLE = 20

local EXPANSION_WOTLK = 2
local EXPANSION_TBC = 1
local PLAYER_VISIBLE_ITEM_1_ENTRYID
local ITEM_SLOT_MULTIPLIER
local PLAYER_VISIBLE_ITEM_1_ENCHANTMENT
if GetCoreExpansion() < EXPANSION_TBC then
    PLAYER_VISIBLE_ITEM_1_ENTRYID = 260
    ITEM_SLOT_MULTIPLIER = 12
elseif GetCoreExpansion() < EXPANSION_WOTLK then
    PLAYER_VISIBLE_ITEM_1_ENTRYID = 346
    ITEM_SLOT_MULTIPLIER = 16
else
    PLAYER_VISIBLE_ITEM_1_ENTRYID = 283
    PLAYER_VISIBLE_ITEM_1_ENCHANTMENT = 284
    ITEM_SLOT_MULTIPLIER = 2
end

local function LocText(id, p) -- "%s":format("test")
    if Transmogrify.Locales[id] then
        local s = Transmogrify.Locales[id][p:GetDbcLocale()+1] or Transmogrify.Locales[id][1]
        if s then
            return s
        end
    end
    return "Text not found: "..(id or 0)
end
--[[
typedef UNORDERED_MAP<uint32, uint32> transmogData
typedef UNORDERED_MAP<uint32, transmogData> transmogMap
static transmogMap entryMap -- entryMap[pGUID][iGUID] = entry
static transmogData dataMap -- dataMap[iGUID] = pGUID
]]
local entryMap = {}
local dataMap = {}

--skin
local PlayerSkins = {};
local StoreAccountSkins = nil;
if (STORE.CDKeyAccountShare) then
    StoreAccountSkins = {};
end

--同账号下的角色列表
local AccountCharacters = nil;
if (Transmogrify.AccountMode or VisualWeapon.AccountMode) then
    AccountCharacters = {};
end

local ShopStore = nil; 
local CDKeyData = nil; 
if (STORE.Enable) then
    ShopStore = {};
    CDKeyData = {};
end

local ItemDataCache = {};
local ItemCount = 0;

function Transmogrify:GetDataMap()
    return dataMap
end

--返回列表
function Transmogrify:GetShopStoreList()
    local list = {};
    for k,v in pairs(ShopStore) do
        table.insert(list, k);
    end
    return list;
end

function Transmogrify:GetItemData(id)
    if (id < Transmogrify.MinItemEntry or id > Transmogrify.MaxItemEntry) then return nil end
    if (not ItemDataCache[id]) then 
        local Q = WorldDBQuery("select * from item_template where entry = "..id);
        if Q then
            ItemDataCache[id] = {
                entry =         Q:GetUInt32(0),
                class =         Q:GetUInt8(1),
                subclass =      Q:GetUInt8(2),
                name =          Q:GetString(4),
                display =       Q:GetUInt32(5),
                quality =       Q:GetUInt8(6),
                inventoryType = Q:GetUInt8(12),
                allowableClass= Q:GetInt32(13),
                itemset =     Q:GetUInt8(113),
                holidayId =     Q:GetUInt8(131),
            }
            ItemCount = ItemCount + 1;
        end
    end
    return ItemDataCache[id];
end

local VisualWeaponItemList = {};
for k,_ in pairs(VisualWeapon.Data) do
    table.insert(VisualWeaponItemList, k);
end

function VisualWeapon:GetVisualWeaponItemStort()
    return VisualWeaponItemList;
end

function VisualWeapon:GetVisualWeaponData()
    return VisualWeapon.Data;
end

function Transmogrify:GetItemStore()
    return ItemDataCache;
end

function Transmogrify:SetItemData(id, data)
    if (not ItemDataCache[id]) then
        ItemCount = ItemCount + 1;
    end
    ItemDataCache[id] = data;
end

function Transmogrify:GetItemDataCount()
    return ItemCount;
end

function Transmogrify:GetEntryMap()
    return entryMap
end

math.randomseed(tostring(os.time()):reverse():sub(1, 7));
function STORE:GenerateCDKey(count)
    local CDkeyList = {}
    for i=1,count do
        local cdk = "";
        for k,fm in pairs(string.split(STORE.CDKeyFormat, "%%")) do
            if (fm == "l") then
                cdk = cdk..string.char(math.random(97,122));
            elseif(fm == "u") then
                cdk = cdk..string.char(math.random(65,90));
            elseif(fm == "d") then
                cdk = cdk..string.char(math.random(48,57));
            elseif(fm == "w") then
                local rand = math.random(3);
                if (rand == 1) then
                    cdk = cdk..string.char(math.random(97,122));
                elseif(rand == 2) then
                    cdk = cdk..string.char(math.random(65,90));
                elseif(rand == 3) then
                    cdk = cdk..string.char(math.random(48,57));
                end
            elseif(fm == "a") then
                local rand = math.random(2);
                if (rand == 1) then
                    cdk = cdk..string.char(math.random(97,122));
                elseif(rand == 2) then
                    cdk = cdk..string.char(math.random(65,90));
                end
            end
        end
        table.insert(CDkeyList, cdk);
    end
    return CDkeyList;
end

function STORE:CheckCDKey(CDKey)
    return string.match(CDKey, STORE.CDKeyFormat) == CDKey;
end

--返回skins,但不更新
function Transmogrify:GetPlayerSkins(player, allCharacters)
    local list = {};
    local accountId = player:GetAccountId();
    if (not allCharacters) then
        list = PlayerSkins[player:GetGUIDLow()] or {};
    else
        AccountCharacters[accountId] = AccountCharacters[accountId] or {};
        for _,guid in pairs(AccountCharacters[accountId]) do
            for _,skin in pairs(PlayerSkins[guid]) do
                table.insert(list, skin);
            end
        end
    end
    if (STORE.CDKeyAccountShare) then
        StoreAccountSkins[accountId] = StoreAccountSkins[accountId] or {};
        for _,skin in pairs(StoreAccountSkins[accountId]) do
            table.insert(list, skin);
        end
    end
    return list;
end

function Transmogrify:SetPlayerSkins(player, skins)
    PlayerSkins[player:GetGUIDLow()]  = skins;
end

function Transmogrify:AddPlayerSkin(player, itemData, OnlySendMsg)
    local isVisual = table.intable(VisualWeaponItemList, itemData.entry);
    if (not isVisual and itemData.class ~= 4 and itemData.class ~= 2) then return; end
    if (not isVisual and not Transmogrify.Qualities[itemData.quality]) then return; end
    local guid = player:GetGUIDLow();
    if (not PlayerSkins[guid]) then
        Transmogrify:UpdatePlayerSkins(player);
    end
    PlayerSkins[guid] = PlayerSkins[guid] or {};
    if (OnlySendMsg or not table.intable(PlayerSkins[guid], itemData.entry)) then
        if (not OnlySendMsg) then
            table.insert(PlayerSkins[guid], itemData.entry);
        end
        if (Transmogrify.Model == 2) then
            player:SendBroadcastMessage(LocText(29, player):format(itemData.name));
            player:SendAddonMessage("ezCollections", "ADD:OWNEDITEM:"..itemData.entry, 0x07, player );
            player:SendAddonMessage("ezCollections", "ADD:SKIN:"..itemData.entry, 0x07, player );
        end
        return true;
    end
    return false;
end

function Transmogrify:UpdatePlayerSkins(player, queryDatabase)
    local guid = nil;
    if (type(player) == "number") then
        guid = player;
    else
        guid = player:GetGUIDLow();
    end
    local SkinList = {};
    if (Transmogrify.Model == 2) then
        if (queryDatabase) then
            local query = CharDBQuery("SELECT guid, skins FROM _transmogrification_character_collections WHERE guid = "..guid)
            if query then
                SkinList = load("return {"..query:GetString(1).."}")();
            end
        end
    end
    if (not tonumber(player)) then
        local list = player:GetItemList();
        for k,v in pairs(list) do
            if (v:GetClass() == 4 or v:GetClass() == 2 or table.intable(VisualWeaponItemList, v:GetEntry())) then
                table.insert(SkinList, v:GetEntry());
            end
        end
    end
    
    PlayerSkins[guid] = PlayerSkins[guid] or {};
    for k,v in pairs(PlayerSkins[guid]) do
        table.insert(SkinList, v);
    end
    
    PlayerSkins[guid] = table.delRepeat(SkinList);
    return PlayerSkins[guid];
end

local function GetSlotName(slot, locale)
    if not Transmogrify.SlotNames[slot] then return end
    return locale and Transmogrify.SlotNames[slot][locale+1] or Transmogrify.SlotNames[slot][1]
end

function Transmogrify:GetFakePrice(item)
    local sellPrice = item:GetSellPrice()
    local minPrice = 10000
    if sellPrice < minPrice then
        sellPrice = minPrice
    end
    return sellPrice
end

function Transmogrify:DeleteFakeFromDB(item, removeFake, removeVisual)
    local itemGUID = item:GetGUIDLow();
    local player = item:GetOwner();
    if dataMap[itemGUID] then
        if entryMap[dataMap[itemGUID]] then
            if (removeFake) then
                entryMap[dataMap[itemGUID]][itemGUID][1] = 0;
            end
            if (removeVisual) then
                entryMap[dataMap[itemGUID]][itemGUID][2] = -1;
            end
            if (entryMap[dataMap[itemGUID]][itemGUID][1] == 0 and entryMap[dataMap[itemGUID]][itemGUID][2] == -1) then
                entryMap[dataMap[itemGUID]][itemGUID] = nil
                dataMap[itemGUID] = nil
            end
        end
    end
    if (dataMap[itemGUID]) then
        if (removeFake) then
            CharDBExecute("UPDATE _transmogrification_character SET `FakeEntry` = 0 WHERE `GUID` = "..itemGUID);
        end
        if (removeVisual) then
            CharDBExecute("UPDATE _transmogrification_character SET `visual` = -1 WHERE `GUID` = "..itemGUID);
        end
        local visual = entryMap[dataMap[itemGUID]][itemGUID][2];
        if visual == -1 then
            visual = 0;
        end
        player:SendAddonMessage("ezCollections", 
            string.format("GETTRANSMOG:%s=%s,%s,,%s:END", item:GetSlot(), item:GetEntry(), entryMap[dataMap[itemGUID]][itemGUID][1], visual),
            0x07, player);
    else
        CharDBExecute("DELETE FROM _transmogrification_character WHERE GUID = "..itemGUID);
        player:SendAddonMessage("ezCollections", string.format("GETTRANSMOG:%s=%s:END", item:GetSlot(), item:GetEntry()), 0x07, player);
    end
end

function Transmogrify:DeleteFakeEntry(item, removeFake, removeVisual)
    local player = item:GetOwner();
    if not Transmogrify:GetFakeEntry(item) then
        return false
    end
    
    if (removeFake) then
        player:SetUInt32Value(PLAYER_VISIBLE_ITEM_1_ENTRYID + (item:GetSlot() * ITEM_SLOT_MULTIPLIER), item:GetEntry())
    end
    if (removeVisual) then
        player:SetUInt16Value(PLAYER_VISIBLE_ITEM_1_ENCHANTMENT + (item:GetSlot() * ITEM_SLOT_MULTIPLIER), 0, item:GetEnchantmentId(0))
        player:SetUInt16Value(PLAYER_VISIBLE_ITEM_1_ENCHANTMENT + (item:GetSlot() * ITEM_SLOT_MULTIPLIER), 1, item:GetEnchantmentId(1))
    end
    Transmogrify:DeleteFakeFromDB(item, removeFake, removeVisual)
    return true
end


--幻化 15隐藏效果  0不应用  
--幻光 0隐藏效果  -1不应用
function Transmogrify:SetFakeEntry(item, entry, visual)
    local player = item:GetOwner();
    if player then
        local pGUID = player:GetGUIDLow();
        local iGUID = item:GetGUIDLow();
        entryMap[pGUID] = entryMap[pGUID] or {};
        entryMap[pGUID][iGUID] = entryMap[pGUID][iGUID] or {0, -1};
        if (entry and entry ~= 0) then
            entryMap[pGUID][iGUID][1] = entry;
            player:SetUInt32Value(PLAYER_VISIBLE_ITEM_1_ENTRYID + (item:GetSlot() * ITEM_SLOT_MULTIPLIER), entry);
        end
        
        if (visual and visual ~= -1) then
            entryMap[pGUID][iGUID][2] = visual;
            player:SetUInt16Value(PLAYER_VISIBLE_ITEM_1_ENCHANTMENT + (item:GetSlot() * ITEM_SLOT_MULTIPLIER), 0, visual);
        end
        
        dataMap[iGUID] = pGUID;
        CharDBExecute("REPLACE INTO _transmogrification_character (GUID, FakeEntry, visual, Owner) VALUES ("..iGUID..", ".. entryMap[pGUID][iGUID][1]..", ".. entryMap[pGUID][iGUID][2]..", "..pGUID..")")
        local msgVisual = entryMap[pGUID][iGUID][2];
        if (msgVisual == -1) then
            msgVisual = 0;
        end
        player:SendAddonMessage("ezCollections", 
            string.format("GETTRANSMOG:%s=%s,%s,%s,%s:END", item:GetSlot(), item:GetEntry(), entryMap[pGUID][iGUID][1], "", msgVisual)
            , 0x07, player);
    end
end

function Transmogrify:GetFakeEntry(item)
    local guid = item and item:GetGUIDLow()
    if guid and dataMap[guid] then
        if entryMap[dataMap[guid]] then
            return entryMap[dataMap[guid]][guid][1], entryMap[dataMap[guid]][guid][2]
        end
    end
end

function Transmogrify:SetTransmogrify(player, slotid, FakeEntry)
    local lowGUID = player:GetGUIDLow()
    if Transmogrify.RequireToken and player:GetItemCount(Transmogrify.TokenEntry) < Transmogrify.TokenAmount then
        player:SendNotification(LocText(16, player):format(GetItemLink(Transmogrify.TokenEntry, player:GetDbcLocale())));
        return;
    end
    
    local transmogrified = player:GetItemByPos(INVENTORY_SLOT_BAG_0, slotid)
    if not transmogrified then
        player:SendNotification(LocText(15, player));
        return;
    end
        
    if (Transmogrify.Model == 1 and player:GetItemCount(FakeEntry,1) < 1) then
        player:SendNotification(LocText(14, player))
        return;
    end
    
    if (not Transmogrify:SuitableForTransmogrification(player, transmogrified, FakeEntry) and FakeEntry~=Transmogrify.HIDE_ITEM) then
        player:SendNotification(LocText(13, player))
        return;
    end
    
    local price
    if Transmogrify.RequireGold == 1 then
        price = Transmogrify:GetFakePrice(transmogrified)*Transmogrify.GoldModifier
    elseif Transmogrify.RequireGold == 2 then
        price = Transmogrify.GoldCost
    end
    
    if price and player:GetCoinage() < price then
        player:SendNotification(LocText(17, player));
        return;
    end
    
    player:ModifyMoney(-1*price)
    if Transmogrify.RequireToken then
        player:RemoveItem(Transmogrify.TokenEntry, Transmogrify.TokenAmount)
    end
    Transmogrify:SetFakeEntry(transmogrified, FakeEntry, nil)
    -- transmogrifier:SetNotRefundable(player)
    -- player:PlayDirectSound(3337)
    player:SendAreaTriggerMessage(LocText(12, player):format(GetSlotName(slotid, player:GetDbcLocale())))
end

function Transmogrify:SetVisualWeapon(player, slotid, visualItem)
    if (not VisualWeapon.Enable) then return; end
    local lowGUID = player:GetGUIDLow()
    if Transmogrify.RequireToken and player:GetItemCount(Transmogrify.TokenEntry) < math.ceil(Transmogrify.TokenAmount * VisualWeapon.TokenModifier) then
        player:SendNotification(LocText(16, player):format(GetItemLink(Transmogrify.TokenEntry, player:GetDbcLocale())));
        return;
    end
    
    local transmogrified = player:GetItemByPos(INVENTORY_SLOT_BAG_0, slotid)
    if not transmogrified then
        player:SendNotification(LocText(15, player));
        return;
    end
        
    if (VisualWeapon.Model == 1 and player:GetItemCount(visualItem,1) < 1) then
        player:SendNotification(LocText(14, player))
        return;
    end
    
    if (not table.intable(VisualWeaponItemList, visualItem) and visualItem~=Transmogrify.HIDE_ITEM) then
        player:SendNotification(LocText(13, player))
        return;
    end
    
    local price
    if Transmogrify.RequireGold == 1 then
        price = Transmogrify:GetFakePrice(transmogrified)*Transmogrify.GoldModifier
    elseif Transmogrify.RequireGold == 2 then
        price = Transmogrify.GoldCost
    end
    price = price * VisualWeapon.GoldModifier;
    
    if price and player:GetCoinage() < price then
        player:SendNotification(LocText(17, player));
        return;
    end
    
    player:ModifyMoney(-1*price)
    if Transmogrify.RequireToken then
        player:RemoveItem(Transmogrify.TokenEntry, Transmogrify.TokenAmount)
    end
    
    if VisualWeapon.RemoveItem and VisualWeapon.Model == 1 and visualItem~=Transmogrify.HIDE_ITEM then
        player:RemoveItem(visualItem, 1)
    end
    
    --隐藏附魔效果
    local visual = VisualWeapon.Data[visualItem];
    if (visualItem == Transmogrify.HIDE_ITEM) then
        visual = 0;
    end
    
    Transmogrify:SetFakeEntry(transmogrified, nil, visual)
    player:SendAreaTriggerMessage(LocText(24, player):format(transmogrified:GetItemLink(), player:GetDbcLocale()))
end



function Transmogrify:IsRangedWeapon(Class, SubClass)
    return Class == ITEM_CLASS_WEAPON and (
    SubClass == ITEM_SUBCLASS_WEAPON_BOW or
    SubClass == ITEM_SUBCLASS_WEAPON_GUN or
    SubClass == ITEM_SUBCLASS_WEAPON_WAND or
    SubClass == ITEM_SUBCLASS_WEAPON_THROWN or
    SubClass == ITEM_SUBCLASS_WEAPON_CROSSBOW)
end


function VisualWeapon:GetVisualWeaponItemList(player)
    local itemList = {};
    -- 幻光模式
    if (VisualWeapon.Model == 1) then
        for _,v in pairs(player:GetItemList()) do
            if (table.intable(VisualWeaponItemList, v:GetEntry())) then
                table.insert(itemList, v:GetEntry());
            end
        end
    elseif (VisualWeapon.Model == 2) then
        for _,v in pairs(Transmogrify:GetPlayerSkins(player, VisualWeapon.AccountMode)) do
            if (table.intable(VisualWeaponItemList, v)) then
                table.insert(itemList, v);
            end
        end
    elseif (VisualWeapon.Model == 3) then
         for k,v in pairs(VisualWeaponItemList) do
            table.insert(itemList, v);
        end
    end
    return table.delRepeat(itemList);
end

function Transmogrify:GetCanTransmogrifyItemList(player, transmogrified)
    local itemList = {};
    -- 幻化模式
    if (Transmogrify.Model == 1) then
        for _,v in pairs(player:GetItemList()) do
            if (Transmogrify:SuitableForTransmogrification(player, transmogrified, v:GetEntry())) then
                table.insert(itemList, v:GetEntry());
            end
        end
    elseif (Transmogrify.Model == 2) then
        for _,v in pairs(Transmogrify:GetPlayerSkins(player, Transmogrify.AccountMode)) do
            if (Transmogrify:SuitableForTransmogrification(player, transmogrified, v)) then
                table.insert(itemList, v);
            end
        end
    elseif (Transmogrify.Model == 3) then
         for k,_ in pairs(ItemDataCache) do
            if (Transmogrify:SuitableForTransmogrification(player, transmogrified, k)) then
                table.insert(itemList, k);
            end
        end
    end
    return table.delRepeat(itemList);
end

--发送已经收藏的列表
function Transmogrify:GetPlayerAllSkins(player)
    local itemList = {};
    if (Transmogrify.Model == 1) then
        for _,v in pairs(player:GetItemList()) do
            table.insert(itemList, v:GetEntry());
        end
    elseif (Transmogrify.Model == 2) then
        for _,v in pairs(Transmogrify:GetPlayerSkins(player, Transmogrify.AccountMode)) do
            table.insert(itemList, v);
        end
    elseif (Transmogrify.Model == 3) then
         for k,_ in pairs(ItemDataCache) do
            table.insert(itemList, k);
        end
    end
    for k,v in pairs(VisualWeapon:GetVisualWeaponItemList(player)) do
        table.insert(itemList, v);
    end
    return table.delRepeat(itemList);
end

--transmogrified是物品对象, transmogrifier是id
function Transmogrify:SuitableForTransmogrification(player, transmogrified, transmogrifier)
    if (transmogrifier < Transmogrify.MinItemEntry or transmogrifier > Transmogrify.MaxItemEntry) then 
        return false; 
    end

    transmogrifier = Transmogrify:GetItemData(transmogrifier);
    if not transmogrified or not transmogrifier then
        return false;
    end
        
    if not Transmogrify.Qualities[transmogrifier.quality] then
        return false;
    end

    if not Transmogrify.Qualities[transmogrified:GetQuality()] then
        return false;
    end

    if transmogrified:GetDisplayId() == transmogrifier.display then
        return false;
    end

    local fentry, visual = Transmogrify:GetFakeEntry(transmogrified)
    if fentry and fentry ~= 0 and fentry == transmogrifier.entry then
        return false;
    end

    if (not Transmogrify.AllowMixedArmorTypes or not Transmogrify.AllowMixedWeaponTypes) and not player:CanUseItem(transmogrifier.entry) then
        return false;
    end

    local fierClass = transmogrifier.class
    local fiedClass = transmogrified:GetClass()
    local fierSubClass = transmogrifier.subclass
    local fiedSubClass = transmogrified:GetSubClass()
    local fierInventorytype = transmogrifier.inventoryType
    local fiedInventorytype = transmogrified:GetInventoryType()

    if fiedInventorytype == INVTYPE_BAG or
    fiedInventorytype == INVTYPE_RELIC or
    -- fiedInventorytype == INVTYPE_BODY or
    fiedInventorytype == INVTYPE_FINGER or
    fiedInventorytype == INVTYPE_TRINKET or
    fiedInventorytype == INVTYPE_AMMO or
    fiedInventorytype == INVTYPE_QUIVER then
        return false
    end

    if fierInventorytype == INVTYPE_BAG or
    fierInventorytype == INVTYPE_RELIC or
     --fierInventorytype == INVTYPE_BODY or
    fierInventorytype == INVTYPE_FINGER or
    fierInventorytype == INVTYPE_TRINKET or
    fierInventorytype == INVTYPE_AMMO or
    fierInventorytype == INVTYPE_QUIVER then
        return false
    end

    if fierClass ~= fiedClass then
        return false
    end

    if Transmogrify:IsRangedWeapon(fiedClass, fiedSubClass) ~= Transmogrify:IsRangedWeapon(fierClass, fierSubClass) then
        return false
    end
    
    if (not Transmogrify.AllowMixedArmorTypes and fierClass == ITEM_CLASS_ARMOR and (fierClass ~= fierClass or fierSubClass ~= fiedSubClass or fierInventorytype ~= fiedInventorytype)) then
        return false
    end
    
    if (not Transmogrify.AllowMixedWeaponTypes and fierClass == ITEM_CLASS_WEAPON and (fierClass ~= fierClass or fierSubClass ~= fiedSubClass or fierInventorytype ~= fiedInventorytype)) then
        return false
    end
    
    if (fierInventorytype ~= fiedInventorytype) then
        if (fierClass == ITEM_CLASS_WEAPON and not ((Transmogrify:IsRangedWeapon(fiedClass, fiedSubClass) or
            ((fiedInventorytype == INVTYPE_WEAPON or fiedInventorytype == INVTYPE_2HWEAPON) and
                (fierInventorytype == INVTYPE_WEAPON or fierInventorytype == INVTYPE_2HWEAPON)) or
            ((fiedInventorytype == INVTYPE_WEAPONMAINHAND or fiedInventorytype == INVTYPE_WEAPONOFFHAND) and
                (fierInventorytype == INVTYPE_WEAPON or fierInventorytype == INVTYPE_2HWEAPON))))) then
            return true
        end
        if (fierClass == ITEM_CLASS_ARMOR and
            not ((fierInventorytype == INVTYPE_CHEST or fierInventorytype == INVTYPE_ROBE) and
                (fiedInventorytype == INVTYPE_CHEST or fiedInventorytype == INVTYPE_ROBE))) then
            return false
        end
    end
    return true
end

local menu_id = math.random(1000)

local GOSSIP_SENDER_SHOW_SLOT           = 0x10000000;
local GOSSIP_SENDER_UPDATE              = 0x20000000;
local GOSSIP_SENDER_BACK                = 0x20000000;
local GOSSIP_SENDER_RESET               = 0x30000000;
local GOSSIP_SENDER_SHOW_ITEM_LIST      = 0x40000000;
local GOSSIP_SENDER_REMOVE              = 0x50000000;
local GOSSIP_SENDER_REMOVE_ALL          = 0x60000000;
local GOSSIP_SENDER_TRANSMOGRIFY        = 0x70000000;
local GOSSIP_SENDER_VISUAL_WEAPON       = 0x80000000;
local GOSSIP_SENDER_SET_VISUAL_WEAPON   = 0x90000000;
local GOSSIP_SENDER_REMOVE_VISUAL_WEAPON= 0xA0000000;
local GOSSIP_SENDER_CDK_EXCHANGE        = 0xB0000000;

local function OnGossipHello(event, player, creature)
    player:GossipClearMenu()
    for slot = EQUIPMENT_SLOT_START, EQUIPMENT_SLOT_END-1 do
        local transmogrified = player:GetItemByPos(INVENTORY_SLOT_BAG_0, slot)
        if transmogrified then
            if Transmogrify.Qualities[transmogrified:GetQuality()] then
                local slotName = GetSlotName(slot, player:GetDbcLocale())
                if slotName then
                    local fakeItem, visual = Transmogrify:GetFakeEntry(transmogrified)
                    if (fakeItem and fakeItem ~= 0) then slotName = slotName.." - "..GetItemLink(fakeItem) end
                    player:GossipMenuAddItem(3, slotName, GOSSIP_SENDER_SHOW_SLOT, slot)
                end
            end
        end
    end
    player:GossipMenuAddItem(4, LocText(2, player), GOSSIP_SENDER_REMOVE_ALL, 0, false, LocText(3, player), 0)
    if (STORE.Enable) then
        local targetText = "你角色";
        if (STORE.CDKeyAccountShare) then
            targetText = "该账号下的所有角色";
        end
        player:GossipMenuAddItem(6, LocText(30, player), GOSSIP_SENDER_CDK_EXCHANGE, 0, true, LocText(31, player):format(targetText));
    end
    player:GossipMenuAddItem(7, LocText(1, player), GOSSIP_SENDER_UPDATE, 0);
    player:GossipSendMenu(100, creature, menu_id)
end

local function OnGossipSelect(event, player, creature, sender, uiAction, query)
    local gossipSender = bit_and(sender, 0xF0000000);
    local page = bit_rshift(bit_and(sender, 0x0FFFFF00),8);
    local slot = bit_and(sender, 0xFF);
    if (gossipSender == GOSSIP_SENDER_SHOW_SLOT or gossipSender == GOSSIP_SENDER_VISUAL_WEAPON) then -- Show items you can use
        local transmogrified = player:GetItemByPos(INVENTORY_SLOT_BAG_0, uiAction)
        if transmogrified then
            local lowGUID = player:GetGUIDLow()
            local limit = 0
            local price = 0
            if Transmogrify.RequireGold == 1 then
                price = Transmogrify:GetFakePrice(transmogrified)*Transmogrify.GoldModifier
            elseif Transmogrify.RequireGold == 2 then
                price = Transmogrify.GoldCost
            end
            local ApplySender = GOSSIP_SENDER_TRANSMOGRIFY;
            local ListSender = GOSSIP_SENDER_SHOW_SLOT;
            local alllist = nil;
            if (gossipSender == GOSSIP_SENDER_VISUAL_WEAPON) then
                price = price * VisualWeapon.GoldModifier;
                alllist = VisualWeapon:GetVisualWeaponItemList(player);
                ApplySender = GOSSIP_SENDER_SET_VISUAL_WEAPON;
                ListSender = GOSSIP_SENDER_VISUAL_WEAPON;
            else
                alllist = Transmogrify:GetCanTransmogrifyItemList(player, transmogrified);
            end
            
            local list = {};
            if (query) then
                for k,v in pairs(alllist) do
                    local itemData = Transmogrify:GetItemData(v);
                    local Str = itemData.name;
                    if (query and tonumber(query)) then Str = tostring(v); end
                    if (query and not string.find(Str, query)) then goto continue; end
                    table.insert(list, v);
                    ::continue::
                end
            else
                list = alllist;
            end
            for i=1,Transmogrify.PageItemLimit do
                local fakeEntry = list[i + page * Transmogrify.PageItemLimit];
                if (fakeEntry) then
                    local transmogrifier = Transmogrify:GetItemData(fakeEntry);
                    if transmogrifier then
                        local strIndex = 4;
                        local windowItemLink = transmogrifier.entry;
                        if (gossipSender == GOSSIP_SENDER_VISUAL_WEAPON) then
                            strIndex = 23;
                            windowItemLink = transmogrified:GetEntry();
                            if (VisualWeapon.RemoveItem) then
                                strIndex = 22;
                            end
                        end
                        local popup = LocText(strIndex, player):format(GetItemLink(fakeEntry, player:GetDbcLocale())).."\n\n"..GetItemLink(windowItemLink, player:GetDbcLocale()).."\n"
                        if Transmogrify.RequireToken then
                            local Amount = Transmogrify.TokenAmount;
                            if (gossipSender == GOSSIP_SENDER_VISUAL_WEAPON) then
                                Amount = math.ceil(Amount * VisualWeapon.TokenModifier);
                                if (VisualWeapon.RemoveItem) then
                                    popup = popup.."\n"..Amount.." x "..GetItemLink(fakeEntry, player:GetDbcLocale())
                                end
                            end
                            popup = popup.."\n"..Amount.." x "..GetItemLink(Transmogrify.TokenEntry, player:GetDbcLocale())
                        end
                        local GossipItemText = GetItemLink(transmogrifier.entry, player:GetDbcLocale());
                        if (table.intable(Transmogrify:GetShopStoreList(), transmogrifier.entry)) then
                            GossipItemText = GossipItemText.."|cFF3399FF[商城]|r";
                        end
                        player:GossipMenuAddItem(4, GossipItemText, ApplySender + bit_lshift(page,8) + uiAction, fakeEntry, false, popup, price)
                    end
                end
            end
            if (page * Transmogrify.PageItemLimit + 25 <= #list) then
                player:GossipMenuAddItem(3, LocText(19, player):format(page + 1, math.modf(#list / Transmogrify.PageItemLimit)), ListSender + bit_lshift(page + 1,8), uiAction);
            end
            if (page > 0) then
                player:GossipMenuAddItem(3, LocText(18, player), ListSender + bit_lshift(page - 1,8), uiAction);
            end
            player:GossipMenuAddItem(3, LocText(20, player), ListSender + bit_lshift(page,8), uiAction, true);
            if (VisualWeapon.Enable and (uiAction == EQUIPMENT_SLOT_OFFHAND or uiAction == EQUIPMENT_SLOT_MAINHAND) and gossipSender ~= GOSSIP_SENDER_VISUAL_WEAPON) then
                player:GossipMenuAddItem(3, LocText(21, player), GOSSIP_SENDER_VISUAL_WEAPON, uiAction);
            end
            
            if (gossipSender ~= GOSSIP_SENDER_VISUAL_WEAPON) then
                player:GossipMenuAddItem(4, LocText(7, player), GOSSIP_SENDER_REMOVE, uiAction, false, LocText(5, player):format(GetSlotName(uiAction, player:GetDbcLocale())));
                player:GossipMenuAddItem(7, LocText(6, player), GOSSIP_SENDER_BACK, 0);
            else
                player:GossipMenuAddItem(4, LocText(25, player), GOSSIP_SENDER_REMOVE_VISUAL_WEAPON, uiAction, false, LocText(26, player):format(GetSlotName(uiAction, player:GetDbcLocale())));
                player:GossipMenuAddItem(7, LocText(6, player), GOSSIP_SENDER_SHOW_SLOT + bit_lshift(page,8), uiAction)
            end
            
            player:GossipSendMenu(100, creature, menu_id);
        else
            OnGossipHello(event, player, creature);
        end
    elseif gossipSender == GOSSIP_SENDER_BACK then -- Back
        OnGossipHello(event, player, creature)
        
    elseif gossipSender == GOSSIP_SENDER_REMOVE_ALL then -- Remove Transmogrifications
        local removed = false
        for s = EQUIPMENT_SLOT_START, EQUIPMENT_SLOT_END-1 do
            local transmogrifier = player:GetItemByPos(INVENTORY_SLOT_BAG_0, s)
            if transmogrifier then
                if Transmogrify:DeleteFakeEntry(transmogrifier, true, true) and not removed then
                    removed = true
                end
            end
        end
        if removed then
            player:SendAreaTriggerMessage(LocText(8, player))
            -- player:PlayDirectSound(3337)
        else
            player:SendNotification(LocText(9, player))
        end
        OnGossipHello(event, player, creature)
        
    elseif gossipSender == GOSSIP_SENDER_REMOVE then -- Remove Transmogrification from single item
        local transmogrifier = player:GetItemByPos(INVENTORY_SLOT_BAG_0, uiAction)
        if transmogrifier then
            if Transmogrify:DeleteFakeEntry(transmogrifier, true, false) then
                player:SendAreaTriggerMessage(LocText(10, player):format(GetSlotName(uiAction, player:GetDbcLocale())))
                -- player:PlayDirectSound(3337)
            else
                player:SendNotification(LocText(11, player):format(GetSlotName(uiAction, player:GetDbcLocale())))
            end
        end
        OnGossipSelect(event, player, creature, GOSSIP_SENDER_SHOW_SLOT + bit_lshift(page,8), uiAction)
    elseif gossipSender == GOSSIP_SENDER_REMOVE_VISUAL_WEAPON then
        local transmogrifier = player:GetItemByPos(INVENTORY_SLOT_BAG_0, uiAction)
        if transmogrifier then
            if Transmogrify:DeleteFakeEntry(transmogrifier, false, true) then
                player:SendAreaTriggerMessage(LocText(27, player):format(GetSlotName(uiAction, player:GetDbcLocale())))
                -- player:PlayDirectSound(3337)
            else
                player:SendNotification(LocText(28, player):format(GetSlotName(uiAction, player:GetDbcLocale())))
            end
        end
        OnGossipSelect(event, player, creature, GOSSIP_SENDER_VISUAL_WEAPON + bit_lshift(page,8), uiAction)
    
    elseif gossipSender == GOSSIP_SENDER_TRANSMOGRIFY then-- Transmogrify
        Transmogrify:SetTransmogrify(player, slot, uiAction)
        OnGossipSelect(event, player, creature, GOSSIP_SENDER_SHOW_SLOT + bit_lshift(page,8), slot)
        
    elseif gossipSender == GOSSIP_SENDER_SET_VISUAL_WEAPON then --Set Visual Weapon
        Transmogrify:SetVisualWeapon(player, slot, uiAction)
        OnGossipSelect(event, player, creature, GOSSIP_SENDER_VISUAL_WEAPON + bit_lshift(page,8), slot)
        
    elseif gossipSender == GOSSIP_SENDER_CDK_EXCHANGE then
        if(STORE.Enable) then
            if (not STORE:CheckCDKey(query)) then
                player:SendBroadcastMessage(LocText(32, player));
                player:GossipComplete();
                return;
            end
            local itemID = CDKeyData[query];
            if (not itemID) then
                player:SendBroadcastMessage(LocText(33, player));
                player:GossipComplete();
                return;
            end
            local skins = Transmogrify:GetPlayerSkins(player, Transmogrify.AccountMode or VisualWeapon.AccountMode);
            if (table.intable(skins, itemID)) then
                player:SendBroadcastMessage(LocText(35, player):format(GetItemLink(itemID, player:GetDbcLocale())));
                player:GossipComplete();
                return;
            end

            local itemData = Transmogrify:GetItemData(itemID);
            if (itemData) then
                if (STORE.CDKeyAccountShare) then
                    local accountId = player:GetAccountId();
                    StoreAccountSkins[accountId] = StoreAccountSkins[accountId] or {};
                    table.insert(StoreAccountSkins[accountId], itemID);
                    player:SendBroadcastMessage(LocText(36, player):format(GetItemLink(itemID, player:GetDbcLocale()), "该账号下的所有角色"));
                else
                    player:SendBroadcastMessage(LocText(36, player):format(GetItemLink(itemID, player:GetDbcLocale()), "该角色"));
                end
                local cdkeyExecuteFunc = CharDBExecute;
                if (STORE.CDKeyDatabase == 2) then
                    cdkeyExecuteFunc = WorldDBExecute;
                end
                cdkeyExecuteFunc(string.format(
                    "update `_transmogrification_item_store_cdkey` set `使用账号` = '%s', `使用时间` = now() where `CDKey` = '%s' and `物品id` = '%s'",
                    player:GetAccountId(), query, CDKeyData[query]));
                CDKeyData[query] = nil;
                Transmogrify:AddPlayerSkin(player, itemData);
                player:GossipComplete();
            end
        end
    end
end

local function OnLogin(event, player)
    local playerGUID = player:GetGUIDLow()
    if (Transmogrify.Model == 2) then
        if (Transmogrify.AccountMode or VisualWeapon.AccountMode) then
            local accountId = player:GetAccountId();
            local query = CharDBQuery("SELECT guid FROM `characters` WHERE `account` = "..accountId);
            if query then
                repeat
                    local guid = query:GetUInt32(0);
                    AccountCharacters[accountId] = AccountCharacters[accountId] or {};
                    table.insert(AccountCharacters[accountId], guid);
                    if (guid ~= playerGUID) then
                        Transmogrify:UpdatePlayerSkins(guid, true);
                    end
                until not query:NextRow()
            end
        end
        Transmogrify:UpdatePlayerSkins(player, true);
    end
    entryMap[playerGUID] = {}
    local result = CharDBQuery("SELECT GUID, FakeEntry, visual FROM _transmogrification_character WHERE Owner = "..playerGUID)
    if result then
        repeat
            local itemGUID = result:GetUInt32(0)
            local fakeEntry = result:GetUInt32(1)
            local visual = result:GetInt32(2)
            -- if sObjectMgr:GetItemTemplate(fakeEntry) then
            -- {
            dataMap[itemGUID] = playerGUID
            entryMap[playerGUID][itemGUID] = {fakeEntry, visual}
            -- }
            -- else
            --     sLog:outError(LOG_FILTER_SQL, "Item entry (Entry: %u, itemGUID: %u, playerGUID: %u) does not exist, deleting.", fakeEntry, itemGUID, playerGUID)
            --     Transmogrification::Transmogrify:DeleteFakeFromDB(itemGUID)
            -- end
        until not result:NextRow()

        for slot = EQUIPMENT_SLOT_START, EQUIPMENT_SLOT_END-1 do
            local item = player:GetItemByPos(INVENTORY_SLOT_BAG_0, slot)
            if item then
                if entryMap[playerGUID] then
                    if entryMap[playerGUID][item:GetGUIDLow()] then
                        local FakeEntry = entryMap[playerGUID][item:GetGUIDLow()][1];
                        local Visual = entryMap[playerGUID][item:GetGUIDLow()][2];
                        if (FakeEntry ~= 0) then
                            player:UpdateUInt32Value(PLAYER_VISIBLE_ITEM_1_ENTRYID + (item:GetSlot() * ITEM_SLOT_MULTIPLIER), FakeEntry)
                        end
                        if (Visual ~= -1) then
                            player:SetUInt16Value(PLAYER_VISIBLE_ITEM_1_ENCHANTMENT + (item:GetSlot() * ITEM_SLOT_MULTIPLIER), 0, Visual)
                        end
                    end
                end
            end
        end
    end
end

local function UpdateSkinsToDatabase(player)
    local pGUID = player:GetGUIDLow();
    if (Transmogrify.Model == 2) then
        Transmogrify:UpdatePlayerSkins(player, true);
        CharDBExecute("REPLACE INTO _transmogrification_character_collections (guid, skins) VALUES ("..pGUID..", '"..table.concat(PlayerSkins[pGUID],",").."')");
    end
end

local function OnLogout(event, player)
    local pGUID = player:GetGUIDLow()
    entryMap[pGUID] = nil
    UpdateSkinsToDatabase(player);
    PlayerSkins[pGUID] = nil;
    if (Transmogrify.AccountMode or VisualWeapon.AccountMode) then
        for _,guid in pairs(AccountCharacters[player:GetAccountId()]) do
            PlayerSkins[guid] = nil;
            entryMap[guid] = nil;
        end
        AccountCharacters[player:GetAccountId()] = nil;
    end
end

local function InitItemData()
    if (not WorldDBQuery("SELECT * FROM `item_template` WHERE `entry` = '"..Transmogrify.HIDE_ITEM.."'")) then
        WorldDBQuery("INSERT INTO item_template (`entry`, `name`, `displayid`) VALUES ("..Transmogrify.HIDE_ITEM..", '隐藏', 811)")
    end
    local Qualities = {};
    for k,v in pairs(Transmogrify.Qualities) do
        if (v) then
            table.insert(Qualities, k);
        end
    end
    local Q = WorldDBQuery(string.format(
        "select * from item_template where class in (2,4) and (entry between %s and %s) and Quality in (%s)",
            Transmogrify.MinItemEntry, Transmogrify.MaxItemEntry, table.concat(Qualities, ",")));
            
    if Q then
        repeat
            local itemData = {
                entry =         Q:GetUInt32(0),
                class =         Q:GetUInt8(1),
                subclass =      Q:GetUInt8(2),
                name =          Q:GetString(4),
                display =       Q:GetUInt32(5),
                quality =       Q:GetUInt8(6),
                inventoryType = Q:GetUInt8(12),
                allowableClass= Q:GetInt32(13),
                itemset =       Q:GetUInt32(113),
                holidayId =     Q:GetUInt32(131),
            }
            Transmogrify:SetItemData(itemData.entry, itemData);
        until not Q:NextRow();
    end
    PrintInfo("载入幻化物品数据成功,共计"..ItemCount.."条记录.");
end

if (ItemCount == 0) then 
    InitItemData();
end
-- Note, Query is instant when Execute is delayed
CharDBQuery([[
CREATE TABLE IF NOT EXISTS `_transmogrification_character` (
`GUID` INT(10) UNSIGNED NOT NULL COMMENT 'Item guidLow',
`FakeEntry` INT(10) UNSIGNED NOT NULL COMMENT 'Item entry',
`visual` int(10) NOT NULL COMMENT 'Enchantment Id',
`Owner` INT(10) UNSIGNED NOT NULL COMMENT 'Player guidLow',
PRIMARY KEY (`GUID`)
)
COMMENT='version 4.0'
COLLATE='latin1_swedish_ci'
ENGINE=InnoDB;
]])

if (Transmogrify.Model == 2) then
    CharDBQuery([[
        CREATE TABLE IF NOT EXISTS `_transmogrification_character_collections`  (
          `guid` int(10) UNSIGNED NOT NULL,
          `skins` longtext CHARACTER SET utf8 COLLATE utf8_general_ci NULL,
          PRIMARY KEY (`guid`) USING BTREE
        ) ENGINE = MyISAM CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;
        ]]);
end

if (STORE.Enable) then
    WorldDBQuery([[
        CREATE TABLE IF NOT EXISTS `_transmogrification_item_store`  (
          `物品ID` int(10) NOT NULL,
          `生成CDKey数` int(10) NOT NULL,
          `描述` text CHARACTER SET utf8 COLLATE utf8_general_ci NULL,
          PRIMARY KEY (`物品ID`) USING BTREE
        ) ENGINE = MyISAM CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;
        ]]);
    local cdkeyExecuteFunc = CharDBExecute;
    local cdkeyQueryFunc = CharDBQuery;
    if (STORE.CDKeyDatabase == 2) then
        cdkeyExecuteFunc = WorldDBExecute;
        cdkeyQueryFunc = CharDBQuery;
    end
    cdkeyExecuteFunc([[
        CREATE TABLE IF NOT EXISTS `_transmogrification_item_store_cdkey`  (
          `CDKey` text CHARACTER SET utf8 COLLATE utf8_general_ci NULL,
          `物品id` int(10) NOT NULL,
          `使用账号` int(10) NULL DEFAULT NULL,
          `使用时间` timestamp NULL DEFAULT NULL
        ) ENGINE = MyISAM CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;
        ]]);
    
    local Query = WorldDBQuery("select * from _transmogrification_item_store ");
    if Query then
        repeat
            ShopStore[Query:GetUInt32(0)] = Query:GetUInt32(1);
        until not Query:NextRow();
    end
    
    local cdkeyQuery = cdkeyQueryFunc("select * from _transmogrification_item_store_cdkey");
    if cdkeyQuery then
        repeat
            local useAccount = cdkeyQuery:GetUInt32(2);
            if (useAccount == 0) then
                CDKeyData[cdkeyQuery:GetString(0)] = cdkeyQuery:GetUInt32(1);
            else
                if (STORE.CDKeyAccountShare) then
                    StoreAccountSkins[useAccount] = StoreAccountSkins[useAccount] or {};
                    table.insert(StoreAccountSkins[useAccount], cdkeyQuery:GetUInt32(1));
                end
            end
        until not cdkeyQuery:NextRow();
    end
    if (STORE.EnableGenerateCDKey) then
        local CDKeyCount = {};
        local CDKeyCountQuery = cdkeyQueryFunc(
            "SELECT `物品id` AS item, count(`物品id`) AS count FROM _transmogrification_item_store_cdkey WHERE `使用账号` IS NULL GROUP BY `物品id`;");
        if(CDKeyCountQuery) then
            repeat
                CDKeyCount[CDKeyCountQuery:GetUInt32(0)] = CDKeyCountQuery:GetUInt32(1);
            until not CDKeyCountQuery:NextRow();
        end
        for id,count in pairs(ShopStore) do
            local cdkeyCount = CDKeyCount[id] or 0;
            if (cdkeyCount < count) then
                local cdkTextList = {};
                for k,v in pairs(STORE:GenerateCDKey(count - cdkeyCount)) do
                    table.insert(cdkTextList, string.format("('%s', '%s')", v, id));
                    CDKeyData[v] = id;
                end
                cdkeyExecuteFunc("INSERT INTO `_transmogrification_item_store_cdkey`(`CDKey`, `物品id`) VALUES "..table.concat(cdkTextList, ",")..";")
            end
        end
        if (STORE.GenerateCDKeyFileAll ~= "" or STORE.GenerateCDKeyFileFormat~= "") then
            local tempCDKeyList = {};
            for cdkey,id in pairs(CDKeyData) do
                tempCDKeyList[id] = tempCDKeyList[id] or {};
                table.insert(tempCDKeyList[id], cdkey);
            end
            local allFile = nil;
            local dir = GetExecutablePath().."\\"..STORE.GenerateCDKeyDir;
            if (STORE.GenerateCDKeyFileAll ~= "") then
                if (os.execute("cd "..dir)) then
                    os.execute("rd/s/q "..dir);
                end
                os.execute("mkdir "..dir);
                allFile = io.open(dir.."\\"..STORE.GenerateCDKeyFileAll, "w+");
            end
            for id,cdkList in pairs(tempCDKeyList) do
                local file = nil;
                local itemData = Transmogrify:GetItemData(id);
                if (STORE.GenerateCDKeyFileFormat ~= "") then
                    local fileName = string.gsub(STORE.GenerateCDKeyFileFormat,"{id}", id);
                    file = io.open(dir.."\\"..fileName, "w+");
                    file:write(table.concat(cdkList, "\n"));
                    file:flush();
                end
                if (allFile) then
                    allFile:write("########  "..itemData.entry.." - "..itemData.name.."  ########\n");
                    allFile:write(table.concat(cdkList, "\n").."\n\n");
                end
            end
            if (allFile) then
                allFile:flush();
            end
        end
    end
    
end

print("Deleting non-existing transmogrification entries...")
CharDBQuery("DELETE FROM _transmogrification_character WHERE NOT EXISTS (SELECT 1 FROM item_instance WHERE item_instance.guid = _transmogrification_character.GUID)")

RegisterPlayerEvent(3, OnLogin)
RegisterPlayerEvent(4, OnLogout)
local PLAYER_EVENT_ON_SAVE = 25; --(event, player)
RegisterPlayerEvent(PLAYER_EVENT_ON_SAVE, function(event, player)
    UpdateSkinsToDatabase(player);
end)

local PLAYER_EVENT_ON_EQUIP = 29; --(event, player, item, bag, slot)
RegisterPlayerEvent(PLAYER_EVENT_ON_EQUIP, function(event, player, item, count)
    local fentry, visual = Transmogrify:GetFakeEntry(item)
    if fentry and fentry~=0 then
        if item:GetOwnerGUID() ~= player:GetGUID() then
            Transmogrify:DeleteFakeFromDB(item)
            return
        end
        player:SetUInt32Value(PLAYER_VISIBLE_ITEM_1_ENTRYID + (slot * ITEM_SLOT_MULTIPLIER), fentry)
        if (visual and visual ~= -1) then
            player:SetUInt16Value(PLAYER_VISIBLE_ITEM_1_ENCHANTMENT + (slot * ITEM_SLOT_MULTIPLIER),0 , visual)
        end
    end
end)

--添加事件查询玩家物品
if (Transmogrify.Model == 2) then
    CreateLuaEvent(function(eventId, delay, repeats)
        local players = GetPlayersInWorld()
        if players then
            for k, player in pairs(players) do
                local guid = player:GetGUIDLow();
                local oPlayerSkins = PlayerSkins[guid] or {};
                local cPlayerSkins = Transmogrify:UpdatePlayerSkins(player);
                if (#oPlayerSkins < #cPlayerSkins) then
                    local list = {};
                    for _,skin in pairs(cPlayerSkins) do
                        list[skin] = true;
                    end
                    for _,skin in pairs(oPlayerSkins) do
                        list[skin] = nil;
                    end
                    for k,_ in pairs(list) do
                        local itemData = Transmogrify:GetItemData(k);
                        if (itemData) then
                            Transmogrify:AddPlayerSkin(player, itemData, true);
                        end
                    end
                end
            end
        end
    end, Transmogrify.UpdateSkinsEventTime, 0)
end

-- Test code
--RegisterPlayerEvent(18, function(e,p,m,t,l) if m == "test" then OnGossipHello(e,p,p) end end)
--RegisterPlayerGossipEvent(menu_id, 2, OnGossipSelect)
if (Transmogrify.NPC_Entry ~= 0) then
    RegisterCreatureGossipEvent(Transmogrify.NPC_Entry, 1, OnGossipHello)
    RegisterCreatureGossipEvent(Transmogrify.NPC_Entry, 2, OnGossipSelect)
end
local plrs = GetPlayersInWorld()
if plrs then
    for k, player in ipairs(plrs) do
        OnLogin(k, player)
    end
end

if (_ENV.regMask) then
    PrintInfo("  >>[幻化大师功能] ".._ENV.regMask.."");
    RegisterPlayerEvent(3, function(_, player) player:SendBroadcastMessage(string.format("|cFFCC0000欢迎使用幻化大师功能:|r\n    |cFF009933%s|r",_ENV.regMask)); end)
end

return Transmogrify;