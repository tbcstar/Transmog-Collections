local Transmogrify = require ("transmogrification")
local ezCollections = require("ezCollectionSetting")
local VisualWeapon = Transmogrify.VisualWeapon;
local STORE = Transmogrify.STORE;
local SERVERVERSION = ezCollections.SERVERVERSION;
local CACHEVERSION = ezCollections.CACHEVERSION;
local MaxListCount = ezCollections.MaxListCount;
local DEBUG = ezCollections.DEBUG;
local DEVELOPERMODE = ezCollections.DEVELOPERMODE;
local ClientAddonEvents
local MessageQueue = {};
local TransmogWeaponPreviewCreatureEntry = 2334;

local AddonsPrefix = "ezCollections";
local function OutputMessage(msg)
    if (DEBUG) then
        PrintInfo(msg);
    end
end

if (_ENV.regMask) then
    PrintInfo("  >>[幻化试衣间功能] ".._ENV.regMask.."");
    RegisterPlayerEvent(3, function(_, player) player:SendBroadcastMessage(string.format("|cFFCC0000欢迎使用幻化试衣间功能:|r\n    |cFF009933%s|r",_ENV.regMask)); end)
end

local LE_TRANSMOG_COLLECTION_TYPE_HEAD = 1;
local LE_TRANSMOG_COLLECTION_TYPE_SHOULDER = 2;
local LE_TRANSMOG_COLLECTION_TYPE_BACK = 3;
local LE_TRANSMOG_COLLECTION_TYPE_CHEST = 4;
local LE_TRANSMOG_COLLECTION_TYPE_TABARD = 5;
local LE_TRANSMOG_COLLECTION_TYPE_SHIRT = 6;
local LE_TRANSMOG_COLLECTION_TYPE_WRIST = 7;
local LE_TRANSMOG_COLLECTION_TYPE_HANDS = 8;
local LE_TRANSMOG_COLLECTION_TYPE_WAIST = 9;
local LE_TRANSMOG_COLLECTION_TYPE_LEGS = 10;
local LE_TRANSMOG_COLLECTION_TYPE_FEET = 11;
local LE_TRANSMOG_COLLECTION_TYPE_WAND = 12;
local LE_TRANSMOG_COLLECTION_TYPE_1H_AXE = 13;
local LE_TRANSMOG_COLLECTION_TYPE_1H_SWORD = 14;
local LE_TRANSMOG_COLLECTION_TYPE_1H_MACE = 15;
local LE_TRANSMOG_COLLECTION_TYPE_DAGGER = 16;
local LE_TRANSMOG_COLLECTION_TYPE_FIST = 17;
local LE_TRANSMOG_COLLECTION_TYPE_SHIELD = 18;
local LE_TRANSMOG_COLLECTION_TYPE_HOLDABLE = 19;
local LE_TRANSMOG_COLLECTION_TYPE_2H_AXE = 20;
local LE_TRANSMOG_COLLECTION_TYPE_2H_SWORD = 21;
local LE_TRANSMOG_COLLECTION_TYPE_2H_MACE = 22;
local LE_TRANSMOG_COLLECTION_TYPE_STAFF = 23;
local LE_TRANSMOG_COLLECTION_TYPE_POLEARM = 24;
local LE_TRANSMOG_COLLECTION_TYPE_BOW = 25;
local LE_TRANSMOG_COLLECTION_TYPE_GUN = 26;
local LE_TRANSMOG_COLLECTION_TYPE_CROSSBOW = 27;
local LE_TRANSMOG_COLLECTION_TYPE_THROWN = 28;
local LE_TRANSMOG_COLLECTION_TYPE_FISHING_POLE = 29;
local LE_TRANSMOG_COLLECTION_TYPE_MISC = 30;
local NUM_LE_TRANSMOG_COLLECTION_TYPES = 30;

local LE_TRANSMOG_SEARCH_TYPE_ITEMS = 1;
local LE_TRANSMOG_SEARCH_TYPE_BASE_SETS = 2;
local LE_TRANSMOG_SEARCH_TYPE_USABLE_SETS = 3;
local NUM_LE_TRANSMOG_SEARCH_TYPES = 3;

--SourceMask
local TRANSMOG_SOURCE_BOSS_DROP = 1;      --0x01 Boss掉落
local TRANSMOG_SOURCE_QUEST = 2;          --0x02 任务
local TRANSMOG_SOURCE_VENDOR = 3;         --0x04 商人NPC购买
local TRANSMOG_SOURCE_WORLD_DROP = 4;     --0x08 世界掉落
local TRANSMOG_SOURCE_ACHIEVEMENT = 5;    --0x16 成就
local TRANSMOG_SOURCE_PROFESSION = 6;     --0x32 
local TRANSMOG_SOURCE_STORE = 7;          --0x64 商城
local TRANSMOG_SOURCE_SUBSCRIPTION = 8;   --0x128 订阅
local MAX_TRANSMOG_SOURCES = 8;

local function GetSlotByCategory(category)
    if category == LE_TRANSMOG_COLLECTION_TYPE_HEAD             then return "HEAD";         --头部
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_SHOULDER     then return "SHOULDER";     --肩膀
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_BACK         then return "BACK";         --披风
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_CHEST        then return "CHEST";        --胸部
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_TABARD       then return "TABARD";       --战袍
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_SHIRT        then return "SHIRT";        --衬衫
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_WRIST        then return "WRIST";        --护腕
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_HANDS        then return "HANDS";        --手套
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_WAIST        then return "WAIST";        --腰带
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_LEGS         then return "LEGS";         --护腿
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_FEET         then return "FEET";         --靴子
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_WAND         then return "WAND";         --远程武器
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_1H_AXE       then return "1H_AXE";       --单手斧
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_1H_SWORD     then return "1H_SWORD";     --单手剑
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_1H_MACE      then return "1H_MACE";      --单手锤
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_DAGGER       then return "DAGGER";       --匕首
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_FIST         then return "FIST";         --拳套
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_SHIELD       then return "SHIELD";       --盾牌
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_HOLDABLE     then return "HOLDABLE";     --可持物品
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_2H_AXE       then return "2H_AXE";       --双手斧
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_2H_SWORD     then return "2H_SWORD";     --双手剑
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_2H_MACE      then return "2H_MACE";      --双手锤
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_STAFF        then return "STAFF";        --法杖
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_POLEARM      then return "POLEARM";      --长柄武器
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_BOW          then return "BOW";          --弓
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_GUN          then return "GUN";          --枪
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_CROSSBOW     then return "CROSSBOW";     --弩
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_THROWN       then return "THROWN";       --投掷武器
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_FISHING_POLE then return "FISHING_POLE"; --鱼竿
    elseif category == LE_TRANSMOG_COLLECTION_TYPE_MISC         then return "MISC";         --其他
    end
    return nil;
end

local function GetCategoryBySlot(Slot)
    if Slot == "HEAD" then             return LE_TRANSMOG_COLLECTION_TYPE_HEAD;
    elseif Slot == "SHOULDER" then     return LE_TRANSMOG_COLLECTION_TYPE_SHOULDER;
    elseif Slot == "BACK" then         return LE_TRANSMOG_COLLECTION_TYPE_BACK;
    elseif Slot == "CHEST" then        return LE_TRANSMOG_COLLECTION_TYPE_CHEST;
    elseif Slot == "TABARD" then       return LE_TRANSMOG_COLLECTION_TYPE_TABARD;
    elseif Slot == "SHIRT" then        return LE_TRANSMOG_COLLECTION_TYPE_SHIRT;
    elseif Slot == "WRIST" then        return LE_TRANSMOG_COLLECTION_TYPE_WRIST;
    elseif Slot == "HANDS" then        return LE_TRANSMOG_COLLECTION_TYPE_HANDS;
    elseif Slot == "WAIST" then        return LE_TRANSMOG_COLLECTION_TYPE_WAIST;
    elseif Slot == "LEGS" then         return LE_TRANSMOG_COLLECTION_TYPE_LEGS;
    elseif Slot == "FEET" then         return LE_TRANSMOG_COLLECTION_TYPE_FEET;
    elseif Slot == "WAND" then         return LE_TRANSMOG_COLLECTION_TYPE_WAND;
    elseif Slot == "1H_AXE" then       return LE_TRANSMOG_COLLECTION_TYPE_1H_AXE;
    elseif Slot == "1H_SWORD" then     return LE_TRANSMOG_COLLECTION_TYPE_1H_SWORD;
    elseif Slot == "1H_MACE" then      return LE_TRANSMOG_COLLECTION_TYPE_1H_MACE;
    elseif Slot == "DAGGER" then       return LE_TRANSMOG_COLLECTION_TYPE_DAGGER;
    elseif Slot == "FIST" then         return LE_TRANSMOG_COLLECTION_TYPE_FIST;
    elseif Slot == "SHIELD" then       return LE_TRANSMOG_COLLECTION_TYPE_SHIELD;
    elseif Slot == "HOLDABLE" then     return LE_TRANSMOG_COLLECTION_TYPE_HOLDABLE;
    elseif Slot == "2H_AXE" then       return LE_TRANSMOG_COLLECTION_TYPE_2H_AXE;
    elseif Slot == "2H_SWORD" then     return LE_TRANSMOG_COLLECTION_TYPE_2H_SWORD;
    elseif Slot == "2H_MACE" then      return LE_TRANSMOG_COLLECTION_TYPE_2H_MACE;
    elseif Slot == "STAFF" then        return LE_TRANSMOG_COLLECTION_TYPE_STAFF;
    elseif Slot == "POLEARM" then      return LE_TRANSMOG_COLLECTION_TYPE_POLEARM;
    elseif Slot == "BOW" then          return LE_TRANSMOG_COLLECTION_TYPE_BOW;
    elseif Slot == "GUN" then          return LE_TRANSMOG_COLLECTION_TYPE_GUN;
    elseif Slot == "CROSSBOW" then     return LE_TRANSMOG_COLLECTION_TYPE_CROSSBOW;
    elseif Slot == "THROWN" then       return LE_TRANSMOG_COLLECTION_TYPE_THROWN;
    elseif Slot == "FISHING_POLE" then return LE_TRANSMOG_COLLECTION_TYPE_FISHING_POLE;
    elseif Slot == "MISC" then         return LE_TRANSMOG_COLLECTION_TYPE_MISC;
    end
    return nil;
end

local function GetCategory(class, subclass, inventoryType)
    local Category = nil;
    class = tonumber(class);
    subclass = tonumber(subclass);
    inventoryType = tonumber(inventoryType);
    if (class == 4) then
        if inventoryType == 1 then 
            Category = LE_TRANSMOG_COLLECTION_TYPE_HEAD;
        elseif inventoryType == 3 then
            Category = LE_TRANSMOG_COLLECTION_TYPE_SHOULDER;
        elseif inventoryType == 16 then
            Category = LE_TRANSMOG_COLLECTION_TYPE_BACK;
        elseif inventoryType == 5 or inventoryType == 20 then
            Category = LE_TRANSMOG_COLLECTION_TYPE_CHEST;
        elseif inventoryType == 19 then
            Category = LE_TRANSMOG_COLLECTION_TYPE_TABARD;
        elseif inventoryType == 4 then
            Category = LE_TRANSMOG_COLLECTION_TYPE_SHIRT;
        elseif inventoryType == 9 then
            Category = LE_TRANSMOG_COLLECTION_TYPE_WRIST;
        elseif inventoryType == 10 then
            Category = LE_TRANSMOG_COLLECTION_TYPE_HANDS;
        elseif inventoryType == 6 then
            Category = LE_TRANSMOG_COLLECTION_TYPE_WAIST;
        elseif inventoryType == 7 then
            Category = LE_TRANSMOG_COLLECTION_TYPE_LEGS;
        elseif inventoryType == 8 then
            Category = LE_TRANSMOG_COLLECTION_TYPE_FEET;
        elseif inventoryType == 14 then
            Category = LE_TRANSMOG_COLLECTION_TYPE_SHIELD;
        elseif inventoryType == 23 then
            Category = LE_TRANSMOG_COLLECTION_TYPE_HOLDABLE;
        elseif inventoryType ~= 11 and inventoryType ~= 12 and inventoryType ~= 2 and inventoryType ~= 0 and inventoryType ~= 28 and subclass == 0 then
            Category = LE_TRANSMOG_COLLECTION_TYPE_MISC;
        end
    elseif (class == 2) then
        if inventoryType == 26 and (subclass ~= 3 and subclass ~= 18) then
            Category = LE_TRANSMOG_COLLECTION_TYPE_WAND;
        elseif subclass == 0 and (inventoryType == 13 or inventoryType == 21 or inventoryType == 22) then
            Category = LE_TRANSMOG_COLLECTION_TYPE_1H_AXE;
        elseif subclass == 7 and (inventoryType == 13 or inventoryType == 21 or inventoryType == 22) then
            Category = LE_TRANSMOG_COLLECTION_TYPE_1H_SWORD;
        elseif subclass == 4 and (inventoryType == 13 or inventoryType == 21 or inventoryType == 22) then
            Category = LE_TRANSMOG_COLLECTION_TYPE_1H_MACE;
        elseif subclass == 15 and (inventoryType == 13 or inventoryType == 21 or inventoryType == 22) then
            Category = LE_TRANSMOG_COLLECTION_TYPE_DAGGER;
        elseif subclass == 13 and (inventoryType == 13 or inventoryType == 21 or inventoryType == 22) then
            Category = LE_TRANSMOG_COLLECTION_TYPE_FIST;
        elseif inventoryType == 17 and subclass == 1 then
            Category = LE_TRANSMOG_COLLECTION_TYPE_2H_AXE;
        elseif inventoryType == 17 and subclass == 8 then
            Category = LE_TRANSMOG_COLLECTION_TYPE_2H_SWORD;
        elseif inventoryType == 17 and subclass == 5 then
            Category = LE_TRANSMOG_COLLECTION_TYPE_2H_MACE;
        elseif (inventoryType == 17 or inventoryType == 13) and subclass == 10 then
            Category = LE_TRANSMOG_COLLECTION_TYPE_STAFF;
        elseif inventoryType == 17 and subclass == 6 then
            Category = LE_TRANSMOG_COLLECTION_TYPE_POLEARM;
        elseif inventoryType == 15 and subclass == 2 then
            Category = LE_TRANSMOG_COLLECTION_TYPE_BOW;
        elseif inventoryType == 26 and subclass == 3 then
            Category = LE_TRANSMOG_COLLECTION_TYPE_GUN;
        elseif inventoryType == 26 and subclass == 18 then
            Category = LE_TRANSMOG_COLLECTION_TYPE_CROSSBOW;
        elseif inventoryType == 25 and subclass == 16 then
            Category = LE_TRANSMOG_COLLECTION_TYPE_THROWN;
        elseif inventoryType == 17 and subclass == 20 then
            Category = LE_TRANSMOG_COLLECTION_TYPE_FISHING_POLE;
        elseif inventoryType ~= 0 and subclass == 14 then
            Category = LE_TRANSMOG_COLLECTION_TYPE_MISC;
        end
    end
    return Category;
end

local function AddMessageQueue(player, messageType, message)
    local guid = player:GetGUIDLow();
    MessageQueue[guid] = MessageQueue[guid] or {};
    table.insert(MessageQueue[guid], {messageType, message});
end

local function SendListToAddon(player, prefix, list, func)
    local msgs = {};
    for i=1,#list do
        local index = math.modf(i / MaxListCount) + 1;
        msgs[index] = msgs[index] or "";
        local str = list[i];
        if (func) then str = func(str); end
        msgs[index] = msgs[index]..str..":";
    end
    for k,v in pairs(msgs) do
        local msg = prefix..v;
        if (k == #msgs) then msg = msg.."END"; end
        player:SendAddonMessage(AddonsPrefix, msg, 0x07, player );
    end
end

--藏品容器(字符串含标志)
local ItemTextStore = {}; --ItemTextStore[Category]
local CategoryItemStore = {};--CategoryItemStore[Category] = {item1, item2, ...}
local ItemSets = {};

local function init()
    local _items = {};
    for entry,itemData in pairs(Transmogrify:GetItemStore()) do
        --[[
        i= matchitem(data, i, "I(%d+)", function(value) info.InventoryType = tonumber(value) + 1; end)          InventoryType 发送原值,插件会自己+1
            or matchitem(data, i, "Q([Q%d]+)", function(value) info.SourceQuests = value:gsub("Q", ","); end)       需要任务
            or matchitem(data, i, "B([B%d]+)", function(value) info.SourceBosses = value:gsub("B", ","); end)       需要boss
        or matchitem(data, i, "H(%d+)", function(value) info.Holiday = tonumber(value); end)                    节日
            or matchitem(data, i, "C(%d+)", function(value) info.Camera = tonumber(value); end)                     
            or matchitem(data, i, "U()", function(value) info.Unusable = true; end)                                 不使用的
            or matchitem(data, i, "O()", function(value) info.Unobtainable = true; end)                             不可获得
        or matchitem(data, i, "E()", function(value) info.Weapon = true; info.Enchantable = true; end)          武器,可附魔   class = 2
        or matchitem(data, i, "W()", function(value) info.Weapon = true; end)                                   武器          class = 2
        or matchitem(data, i, "A(%d+)", function(value) info.Armor = tonumber(value); end)                      护甲 subclass class = 4
            or matchitem(data, i, "S([%dA-F][%dA-F])", function(value) info.SourceMask = tonumber(value, 16); end)  SourceMask
        or matchitem(data, i, "L([%dA-F]+)", function(value) info.ClassMask = tonumber(value, 16); end)         AllowableClass 职业限制
            or matchitem(data, i, "T\"(.-)\"", function(value) info.Icon = value; end)                              图标 只需文件名
            
        local TRANSMOG_SOURCE_BOSS_DROP = 1;      --0x01 Boss掉落
        local TRANSMOG_SOURCE_QUEST = 2;          --0x02 任务
        local TRANSMOG_SOURCE_VENDOR = 3;         --0x04 商人NPC购买
        local TRANSMOG_SOURCE_WORLD_DROP = 4;     --0x08 世界掉落
        local TRANSMOG_SOURCE_ACHIEVEMENT = 5;    --0x10 成就
        local TRANSMOG_SOURCE_PROFESSION = 6;     --0x20 
        local TRANSMOG_SOURCE_STORE = 7;          --0x40 商城
        local TRANSMOG_SOURCE_SUBSCRIPTION = 8;   --0x80 订阅
        local MAX_TRANSMOG_SOURCES = 8;
        ]]--
        
        local Category = GetCategory(itemData.class, itemData.subclass, itemData.inventoryType);
        if (not Category) then 
            if(itemData.class == 4 and itemData.inventoryType == 28) then 
            elseif(itemData.class == 4 and itemData.subclass == 0 and itemData.inventoryType == 0) then --排除圣物魔印等
            elseif(itemData.inventoryType == 2) then             --排除项链
            elseif(itemData.inventoryType == 11) then             --排除戒指
            elseif(itemData.inventoryType == 12) then             --排除饰品
            elseif(itemData.inventoryType == 0) then              --排除inventoryType=0
            else
                OutputMessage(string.format("跳过该物品数据[%s](id:%s class:%s subclass:%s inventoryType:%s).",
                    itemData.name, entry, itemData.class, itemData.subclass, itemData.inventoryType));
            end
            goto continue; 
        end
        _items[entry] = {};
        _items[entry].Category = Category;
        _items[entry].SourceMask = 0;
        _items[entry].Text = entry.."I"..itemData.inventoryType;
        
        CategoryItemStore[Category] = CategoryItemStore[Category] or {};
        table.insert(CategoryItemStore[Category], entry);
        
        if (itemData.class == 2) then
            if (VisualWeapon.Enable and (Category == LE_TRANSMOG_COLLECTION_TYPE_1H_AXE or 
              Category == LE_TRANSMOG_COLLECTION_TYPE_1H_SWORD or 
              Category == LE_TRANSMOG_COLLECTION_TYPE_1H_MACE or 
              Category == LE_TRANSMOG_COLLECTION_TYPE_DAGGER or 
              Category == LE_TRANSMOG_COLLECTION_TYPE_FIST or 
              Category == LE_TRANSMOG_COLLECTION_TYPE_SHIELD or 
              Category == LE_TRANSMOG_COLLECTION_TYPE_2H_AXE or 
              Category == LE_TRANSMOG_COLLECTION_TYPE_2H_SWORD or 
              Category == LE_TRANSMOG_COLLECTION_TYPE_2H_MACE or 
              Category == LE_TRANSMOG_COLLECTION_TYPE_STAFF or 
              Category == LE_TRANSMOG_COLLECTION_TYPE_POLEARM)) then
                _items[entry].Text = _items[entry].Text.."E";
            else
                _items[entry].Text = _items[entry].Text.."W";
            end
        end
        
        if (itemData.class == 4) then
            _items[entry].Text = _items[entry].Text.."A"..itemData.subclass;
        end
        
        if (itemData.allowableClass ~= -1) then
            _items[entry].Text = _items[entry].Text.."L"..string.upper(string.format("%x",itemData.allowableClass));
        end
        
        if (itemData.holidayId ~= 0) then
            _items[entry].Text = _items[entry].Text.."H"..itemData.holidayId;
        end
        
        if (itemData.itemset ~= 0) then
            ItemSets[itemData.itemset] = ItemSets[itemData.itemset] or {};
            table.insert(ItemSets[itemData.itemset], itemData.entry);
        end
        ::continue::
    end
    
    --todo: 查找掉落等内容补充后填充
    if (ezCollections.QueryQuestRewardItemText ~= "") then
        local QuestQuery = WorldDBQuery(ezCollections.QueryQuestRewardItemText);
        local questItem = {};
        if QuestQuery then
            repeat
                local QuestId = QuestQuery:GetUInt32(0);
                for i=1,QuestQuery:GetColumnCount()-1 do
                    local itemId = QuestQuery:GetUInt32(i);
                    if (_items[itemId]) then
                        questItem[itemId] = questItem[itemId] or {};
                        table.insert(questItem[itemId], QuestId);
                    end
                end
            until not QuestQuery:NextRow();
        end
        for id,questList in pairs(questItem) do
            _items[id].Text = _items[id].Text.."Q"..table.concat(questList,",");
            _items[id].SourceMask = _items[id].SourceMask  + 0x02;
        end
    end
    
    if (ezCollections.QueryNPCVendorItemText ~= "") then
        local VendorQuery = WorldDBQuery("SELECT item FROM npc_vendor where item > 0 GROUP BY item" );
        local VendorItem = {};
        if VendorQuery then
            repeat
                local item = VendorQuery:GetUInt32(0);
                if (_items[item]) then
                    _items[item].SourceMask = _items[item].SourceMask  + 0x04;
                end
            until not VendorQuery:NextRow();
        end
    end
    
    --shop
    if (STORE.Enable) then
        for _,v in pairs(Transmogrify:GetShopStoreList()) do
            _items[v].SourceMask = _items[v].SourceMask  + 0x40;
        end
    end
    
    for k,v in pairs(_items) do
        ItemTextStore[v.Category] = ItemTextStore[v.Category] or {};
        local text =  _items[k].Text;
        if (v.SourceMask ~= 0) then
            _items[k].Text = _items[k].Text.."S"..string.upper(string.format("%02X",v.SourceMask));
        end
        table.insert(ItemTextStore[v.Category], _items[k].Text);
    end
    
    
    
end
init();

local function initPlayerAddonData(player)
    local creature = player:GetNearestCreature( 50, TransmogWeaponPreviewCreatureEntry );
    if (not creature) then
        player:SpawnCreature(TransmogWeaponPreviewCreatureEntry, player:GetX(), player:GetY(), player:GetZ(), player:GetO(), 1, 1000 )
    end
    player:SendAddonMessage(AddonsPrefix, "PREVIEWCREATURE:WEAPON:"..TransmogWeaponPreviewCreatureEntry, 0x07, player );
    player:SendAddonMessage(AddonsPrefix, "COLLECTIONS:OWNEDITEM", 0x07, player );
    player:SendAddonMessage(AddonsPrefix, "COLLECTIONS:SKIN", 0x07, player );
    player:SendAddonMessage(AddonsPrefix, "HIDEVISUALSLOTS:HEAD:SHOULDER:SHIRT:CHEST:WAIST:FEET:LEGS:WRIST:HANDS:BACK:TABARD:ENCHANT:", 0x07, player );
    
    if (Transmogrify.RequireToken) then
        player:SendAddonMessage(AddonsPrefix, "TOKEN:"..Transmogrify.TokenEntry, 0x07, player );
    end
    
    if (STORE.Enable and STORE.UrlFormat ~= "" ) then
        player:SendAddonMessage(AddonsPrefix, "COLLECTIONS:STORESKIN", 0x07, player );
        player:SendAddonMessage(AddonsPrefix, "STOREPARAMS:"..STORE.UrlFormat, 0x07, player );
    end
    ClientAddonEvents.GETTRANSMOG.ALL(player);
end

ClientAddonEvents = 
{
    VERSION = function(player, args)
        local varsion = table.unpack(args)
        --todo: 目前粗暴判断只要版本号不一样就弃用
        if (tonumber(varsion) == SERVERVERSION) then
            player:SendAddonMessage(AddonsPrefix, "SERVERVERSION:"..SERVERVERSION..":OK", 0x07, player );
            player:SendAddonMessage(AddonsPrefix, "CACHEVERSION:"..CACHEVERSION, 0x07, player );
            player:SendAddonMessage(AddonsPrefix, "SEARCHPARAMS:3:1500", 0x07, player );
            player:SendAddonMessage(AddonsPrefix, "SETUPFINISHED", 0x07, player );
            player:SendAddonMessage(AddonsPrefix, "PREVIEWCREATURE:WEAPON:"..TransmogWeaponPreviewCreatureEntry, 0x07, player );
            if (DEVELOPERMODE) then
                if (player:IsGM()) then
                    player:SendAddonMessage(AddonsPrefix, "DEVELOPER", 0x07, player );
                end
            end
        else
            player:SendAddonMessage(AddonsPrefix, "SERVERVERSION:DISABLED", 0x07, player );
        end
    end,
    
    LIST = {
        OWNEDITEM = function(player, args)
            SendListToAddon(player, "LIST:OWNEDITEM:", player:GetItemList(), function(item) return item:GetEntry(); end)
        end,
        
        SKIN = function(player, args)
            SendListToAddon(player, "LIST:SKIN:", Transmogrify:GetPlayerAllSkins(player));
        end,
        
        STORESKIN = function(player, args)
            SendListToAddon(player, "LIST:STORESKIN:", Transmogrify:GetShopStoreList());
        end,
        
        ALL = {
            Func = function(player, args)
                local category = table.unpack(args);
                SendListToAddon(player, string.format("LIST:ALL:%s:",category), ItemTextStore[GetCategoryBySlot(category)]);
            end,
            
            ENCHANT = function(player, args)
                SendListToAddon(player, "LIST:ALL:ENCHANT:", VisualWeapon:GetVisualWeaponItemStort());
            end,
        },
        
        DATA = {
            SETS = function(player,args)
                player:SendAddonMessage(AddonsPrefix, "LIST:DATA:SETS:END", 0x07, player );
                return "没对这里做处理,暂时就这样."
            end,
            
            CAMERAS = function(player,args)
                player:SendAddonMessage(AddonsPrefix, "LIST:DATA:CAMERAS:0,0,0,1=1.30,-0.52,-1.15,1.57,:0,0,0,2=0.55,-0.52,-0.70,1.57,:0,0,0,3=0.00,-0.10,-0.47,0.00,:0,0,0,4=0.55,0.00,-0.90,0.00,:0,0,0,5=2.00,-0.52,-1.05,1.57,:0,0,0,6=2.00,-0.52,-1.10,1.57,:0,0,0,7=2.00,-0.52,-1.15,1.57,:0,0,0,8=2.00,-0.52,-0.95,1.57,:0,0,0,9=2.00,-0.52,-0.90,1.57,:0,0,0,10=2.00,-0.52,-0.85,1.57,:0,0,0,11=1.65,-0.52,-1.15,1.57,:0,0,0,12=2.00,-0.52,-1.00,1.57,:0,0,0,13=0.77,0.00,-0.90,0.00,:0,0,0,14=1.35,0.00,-0.88,0.00,:0,0,0,15=1.35,0.00,-0.93,0.00,:0,0,0,16=1.35,0.00,-0.98,0.00,:0,0,0,17=1.35,0.00,-0.78,0.00,:0,0,0,18=1.35,0.00,-0.73,0.00,:0,0,0,19=1.35,0.00,-0.68,0.00,:0,0,0,20=3.20,-0.32,-0.70,3.00,124:END", 0x07, player );
            end,
            
            SCROLLTOENCHANT = function(player,args)
                local list = {};
                for k,v in pairs(VisualWeapon:GetVisualWeaponData()) do
                    table.insert(list, k.."="..v);
                end
                SendListToAddon(player, "LIST:DATA:SCROLLTOENCHANT:", list);
            end,
        },
    },
     
    RELOADUI = function(player, args)
       initPlayerAddonData(player);
    end,
    
    PRELOADCACHE = {
        ITEMS = function(player, args)
            local num = table.unpack(args);
            AddMessageQueue(player, "PRELOADCACHE:ITEMS:", string.format("PRELOADCACHE:ITEMS:%s:%s",tonumber(num) + MaxListCount * 50,Transmogrify:GetItemDataCount()));
            return "不处理";
        end,
        
        MOUNTS = function(player, args)
            local num = table.unpack(args);
            AddMessageQueue(player, "PRELOADCACHE:MOUNTS:", string.format("PRELOADCACHE:MOUNTS:%s:%s",tonumber(num) + MaxListCount ,250));
            return "不处理";
        end,
    
    
    },
    
    GETTRANSMOG = {
        ALL = function(player, args)
            local msg = "";
            for slot = EQUIPMENT_SLOT_START, EQUIPMENT_SLOT_END-1 do
                local item = player:GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
                if (item) then
                    local fakeEntry, visual =  Transmogrify:GetFakeEntry(item);
                    msg = msg..slot.."="..item:GetEntry();
                    if (fakeEntry and fakeEntry ~= 0) then
                        msg = msg..","..fakeEntry;
                    end
                    if (visual and visual ~= -1) then
                        msg = msg..",,"..visual;
                    end
                    msg = msg..":";
                end
            end
            player:SendAddonMessage(AddonsPrefix, "GETTRANSMOG:ALL:"..msg.."END", 0x07, player );
        end,
        
        Func = function(player, args)
            local item = nil;
            local slot = tonumber(args[1]);
            if (slot) then
                item = player:GetItemByPos(INVENTORY_SLOT_BAG_0, tonumber(slot));
            else
                local bag, slot = table.unpack(string.split(args[1]," "))
                item = player:GetItemByPos(tonumber(bag) + INVENTORY_SLOT_BAG_START - 1, tonumber(slot));
            end
            if (item) then
                local fakeEntry, visual = Transmogrify:GetFakeEntry(item);
                local msg = "GETTRANSMOG:"..args[1].."="..item:GetEntry();
                if (fakeEntry and fakeEntry ~= 0) then
                    msg  = msg..","..fakeEntry;
                end
                if (visual and visual ~= -1) then
                    msg  = msg..",,"..visual;
                end
                msg = msg .. ":";
                player:SendAddonMessage(AddonsPrefix, msg, 0x07, player );
            end
        end,
    },
    
    TRANSMOGRIFY = {
        SEARCH = {
            [LE_TRANSMOG_SEARCH_TYPE_ITEMS] = function(player, args)
                local searchToken,categorySlot,query,args2 = table.unpack(args);
                if (categorySlot == "CANCEL") then return; end
                local category = GetCategoryBySlot(categorySlot);
                if (CategoryItemStore[category] ~= nil) then
                    local list = {};
                    for _,v in pairs(CategoryItemStore[category]) do
                        local itemData = Transmogrify:GetItemData(v);
                        local text = itemData.name;
                        if (query and tonumber(query)) then text = tostring(v); end
                        if (query and not string.find(text, query)) then goto continue; end
                        if (args2 and string.find(args2,",")) then
                            local slot,itemId, Enchant = table.unpack(string.split(args2,","));
                            --todo: 位置检查
                        end
                        table.insert(list, v);
                        ::continue::
                    end
                    player:SendAddonMessage(AddonsPrefix, string.format("TRANSMOGRIFY:SEARCH:%s:%s:OK:%s",LE_TRANSMOG_SEARCH_TYPE_ITEMS, searchToken, #list), 0x07, player );
                    SendListToAddon(player, string.format("TRANSMOGRIFY:SEARCH:%s:%s:RESULTS:%s",LE_TRANSMOG_SEARCH_TYPE_ITEMS,searchToken,v), list)
                end
            end,
            
            [LE_TRANSMOG_SEARCH_TYPE_BASE_SETS] = function(player, args)
                return "未处理";
            end,
            
            
            [LE_TRANSMOG_SEARCH_TYPE_USABLE_SETS] = function(player, args)
                return "未处理";
            end,
        
        },
        
        Func = function(player, args)
            local HandleKey = args[1];
            local selectedOutfitID = args[2];
            if (HandleKey ~= "COST" and HandleKey ~= "APPLY") then return; end
            local price = 0;
            local Token = 0;
            local msg = "TRANSMOGRIFY:"..HandleKey..":OK:%s:%s:"..selectedOutfitID;
            for i=3,#args do
                msg = msg..":"..args[i];
                local solt,info = table.unpack(string.split(args[i],"="));
                local baseEntry,baseEnchant,fakeEntry,fakeEnchant,pendingEntry,pendingEnchant = table.unpack(string.split(info,","));
                baseEntry = tonumber(baseEntry);
                pendingEntry = tonumber(pendingEntry);
                pendingEnchant = tonumber(pendingEnchant);
                local transmogrified = player:GetItemByPos(INVENTORY_SLOT_BAG_0, tonumber(solt)-1);
                if (transmogrified) then
                    local fakeEntry, visual = Transmogrify:GetFakeEntry(transmogrified);
                    if (pendingEntry ~= -1 and pendingEntry ~= 0 and fakeEntry ~= pendingEntry) then
                        if Transmogrify.RequireGold == 1 then
                            price = price + Transmogrify:GetFakePrice(transmogrified)*Transmogrify.GoldModifier;
                        elseif Transmogrify.RequireGold == 2 then
                            price = price + Transmogrify.GoldCost
                        end
                        if (Transmogrify.RequireToken) then
                            Token = Token + Transmogrify.TokenAmount;
                        end
                    end
                    if (VisualWeapon.Enable and pendingEnchant ~= -1 and pendingEnchant ~= 0 and visual ~= pendingEnchant) then
                        if Transmogrify.RequireGold == 1 then
                            price = price + Transmogrify:GetFakePrice(transmogrified)*Transmogrify.GoldModifier * VisualWeapon.GoldModifier;
                        elseif Transmogrify.RequireGold == 2 then
                            price = price + Transmogrify.GoldCost * VisualWeapon.GoldModifier;
                        end
                        if (Transmogrify.RequireToken) then
                            Token = Token + math.ceil(Transmogrify.TokenAmount * VisualWeapon.TokenModifier);
                        end
                    end
                    
                    if (HandleKey == "APPLY") then
                        if (pendingEntry ~= -1 and pendingEntry ~=0 and fakeEntry ~= pendingEntry) then
                            if (not table.intable(Transmogrify:GetCanTransmogrifyItemList(player, transmogrified), pendingEntry) and pendingEntry ~= Transmogrify.HIDE_ITEM) then goto continue; end
                            Transmogrify:SetTransmogrify(player, tonumber(solt)-1, pendingEntry);
                        end
                        
                        if (VisualWeapon.Enable) then
                            if (pendingEnchant ~= -1 and pendingEnchant ~= 0 and visual ~= pendingEnchant) then
                                if (not table.intable(VisualWeapon:GetVisualWeaponItemStort(), pendingEnchant) and pendingEnchant ~= Transmogrify.HIDE_ITEM) then goto continue; end
                                Transmogrify:SetVisualWeapon(player, tonumber(solt)-1, pendingEnchant);
                            end
                        end
                        
                        if (pendingEntry == -1 or pendingEnchant == -1) then
                            Transmogrify:DeleteFakeEntry(transmogrified, pendingEntry == -1, pendingEnchant == -1);
                        end
                    end
                end
                ::continue::
            end
            player:SendAddonMessage(AddonsPrefix, string.format(msg, price, Token), 0x07, player );
        end,
    },

    PREVIEWCREATURE = {
        WEAPON = function(player, args)
            local creature = player:GetNearestCreature( 50, TransmogWeaponPreviewCreatureEntry );
            if (not creature) then
                player:SpawnCreature( TransmogWeaponPreviewCreatureEntry, player:GetX(), player:GetY(), player:GetZ(), player:GetO(), 1, 1000 )
            end
            player:SendAddonMessage(AddonsPrefix, "PREVIEWCREATURE:WEAPON:"..TransmogWeaponPreviewCreatureEntry, 0x07, player );
        end,
    },
}

local ADDON_EVENT_ON_MESSAGE = 30; --(event, sender, type, prefix, msg, target)
RegisterServerEvent( ADDON_EVENT_ON_MESSAGE, function(event, sender, chatType, prefix, msg, target)
    if (prefix ~= AddonsPrefix) then return end
    --print("["..os.date("%H:%M:%S", os.time()).."]"..msg)
    local args = {};
    local func = ClientAddonEvents;
    msg = msg:gsub("::", ":nil:") --避免空的参数
    for k,v in pairs(string.split(msg,":")) do
        if (type(func) ~= "function") then
            if (func[v] ~= nil) then
                func = func[v];
                goto continue;
            elseif (func[tonumber(v)] ~= nil) then
                func = func[tonumber(v)];
                goto continue;
            elseif (func.Func ~= nil) then
                func = func.Func;
                table.insert(args,v);
            end
        else
            if (v == "nil") then v = "" end
            table.insert(args,v);
        end
        ::continue::
    end
    if (type(func) ~= "function") then
        OutputMessage("[幻化]接收到未经处理的数据\""..msg.."\".");
    else
        local callback = func(sender, args);
        if (callback == false) then
            OutputMessage("[幻化]插件数据\""..msg.."\"未成功处理.");
        elseif (type(callback) == "string") then
            OutputMessage("[幻化]插件数据\""..msg.."\":"..callback..".");
        end
    end
    return false;
end)

local PLAYER_EVENT_ON_LOGIN = 3; -- (event, player)
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN, function(event, player)
    initPlayerAddonData(player)
end)

for k,player in pairs(GetPlayersInWorld()) do
    player:SendAddonMessage(AddonsPrefix, "VERSIONCHECK", 0x07, player );
    initPlayerAddonData(player);
end

CreateLuaEvent(function(eventId, delay, repeats)
    for k,playerMessageQueue in pairs(MessageQueue) do
        local player = GetPlayerByGUID(k);
        for k,v in pairs(playerMessageQueue) do
            --todo: 待处理
            local messageTypetype,message = table.unpack(v);
            player:SendAddonMessage(AddonsPrefix, message, 0x07, player );
            table.remove(playerMessageQueue, k);
        end
    end
end, 1, 0)
