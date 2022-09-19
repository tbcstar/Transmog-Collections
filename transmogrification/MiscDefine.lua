
--slot
EQUIPMENT_SLOT_START        = 0;
EQUIPMENT_SLOT_HEAD         = 0;
EQUIPMENT_SLOT_NECK         = 1;
EQUIPMENT_SLOT_SHOULDERS    = 2;
EQUIPMENT_SLOT_BODY         = 3;
EQUIPMENT_SLOT_CHEST        = 4;
EQUIPMENT_SLOT_WAIST        = 5;
EQUIPMENT_SLOT_LEGS         = 6;
EQUIPMENT_SLOT_FEET         = 7;
EQUIPMENT_SLOT_WRISTS       = 8;
EQUIPMENT_SLOT_HANDS        = 9;
EQUIPMENT_SLOT_FINGER1      = 10;
EQUIPMENT_SLOT_FINGER2      = 11;
EQUIPMENT_SLOT_TRINKET1     = 12;
EQUIPMENT_SLOT_TRINKET2     = 13;
EQUIPMENT_SLOT_BACK         = 14;
EQUIPMENT_SLOT_MAINHAND     = 15;
EQUIPMENT_SLOT_OFFHAND      = 16;
EQUIPMENT_SLOT_RANGED       = 17;
EQUIPMENT_SLOT_TABARD       = 18;
EQUIPMENT_SLOT_END          = 19;

INVENTORY_SLOT_BAG_START    = 19;
INVENTORY_SLOT_BAG_END      = 23;

INVENTORY_SLOT_ITEM_START   = 23;
INVENTORY_SLOT_ITEM_END     = 39;

BANK_SLOT_ITEM_START        = 39;
BANK_SLOT_ITEM_END          = 67;

BANK_SLOT_BAG_START         = 67;
BANK_SLOT_BAG_END           = 74;

BUYBACK_SLOT_START          = 74;
BUYBACK_SLOT_END            = 86;

KEYRING_SLOT_START          = 86;
KEYRING_SLOT_END            = 118;
    
CURRENCYTOKEN_SLOT_START    = 118;
CURRENCYTOKEN_SLOT_END      = 150;

INVENTORY_SLOT_BAG_0        = 255;

function Player:GetItemList(pushEquip, pushBag, pushKey, pushBank)
    pushEquip = pushEquip and true or false;
    pushBag = pushBag and true or false;
    pushKey = pushKey and true or false;
    pushBank = pushBank and true or false;
    local itemList = {}
    local Bag_start = (pushEquip and {EQUIPMENT_SLOT_START} or {INVENTORY_SLOT_ITEM_START})[1];
    local Bank_end = (pushBag and {BANK_SLOT_BAG_END} or {BANK_SLOT_ITEM_END})[1];
    
    --默认背包位置,含装备
    for slot = Bag_start, INVENTORY_SLOT_ITEM_END-1 do
        local item = self:GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
        if (item) then
            table.insert(itemList, item);
        end
    end
    
    --银行默认位置,含银行背包位
    if (pushBank) then
        for slot = BANK_SLOT_ITEM_START, Bank_end-1 do
            local item = self:GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
            if (item) then
                table.insert(itemList, item);
            end
        end
    end
    
    --装备的包位
    if (pushBag) then
        for slot = INVENTORY_SLOT_BAG_START, INVENTORY_SLOT_BAG_END-1 do
            local item = self:GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
            if (item) then
                table.insert(itemList, item);
            end
        end
    end
    
    --钥匙包
    if (pushKey) then
        for slot = KEYRING_SLOT_START, KEYRING_SLOT_END-1 do
            local item = self:GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
            if (item) then
                table.insert(itemList, item);
            end
        end
    end
    
    --背包里的物品
    for  i = INVENTORY_SLOT_BAG_START,INVENTORY_SLOT_BAG_END-1 do
        local bag = self:GetItemByPos(INVENTORY_SLOT_BAG_0, i);
        if (bag) then
            for j = 0, bag:GetBagSize()-1 do
                local item = self:GetItemByPos(i, j);
                if (item) then
                    table.insert(itemList, item);
                end
            end
        end
    end
    
    --银行的包里的物品
    if (pushBank) then        
        for  i = BANK_SLOT_BAG_START,BANK_SLOT_BAG_END-1 do
            local bag = self:GetItemByPos(INVENTORY_SLOT_BAG_0, i);
            if (bag) then
                for j = 0, bag:GetBagSize()-1 do
                    local item = self:GetItemByPos(i, j);
                    if (item) then
                        table.insert(itemList, item);
                    end
                end
            end
        end
    end
    
    for slot = CURRENCYTOKEN_SLOT_START, CURRENCYTOKEN_SLOT_END-1 do
        local item = self:GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
        if (item) then
            table.insert(itemList, item);
        end
    end
    return itemList;
end

string.split = function(s, p)
    local rt= {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end)
    return rt
end

table.intable = function(t, value)
    for k,v in pairs(t) do 
        if (value == v) then
            return true;
        end
    end
    return false;
end
table.delRepeat = function(t)
    local a = {};
    local b = {};
    for k,v in pairs(t) do a[v] = true; end
    for k,v in pairs(a) do table.insert(b,k) end
    return b;
end

_ENV["GetExecutablePath"] = function()
    local obj=io.popen("cd") 
    local path=obj:read("*all"):sub(1,-2)
    obj:close()
    return path;
end

return _ENV;
