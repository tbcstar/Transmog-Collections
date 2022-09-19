C_Transmog = C_Transmog or { };

local _pending = { };
local _pendingFailReasons = { };
local _pendingApplyKey;
local _lastRequestedCost =
{
    Key = nil,
    Cost = nil,
    NumChanges = nil,
}
local _suppressUpdates = false;
local _deferredValidate = false;
local function CanTransmogrify(slot, transmogType, pending, hasPendingUndo)
    --[[
    1: "NO_ITEM",
    2: "NOT_SOULBOUND",
    3: "LEGENDARY",
    4: "ITEM_TYPE",
    5: "INVALID_TARGET",
    6: "MISMATCH",
    7: "SAME_ITEM",
    8: "INVALID_SOURCE",
    9: "NO_STATS",
    10: "CANNOT_USE",
    ]]
    if slot == GetInventorySlotInfo("RangedSlot") and UnitHasRelicSlot("player") then
        return false, 4;
    end

    local base = GetInventoryItemID("player", slot);

    if not base or base == 0 then
        return false, 1; -- NO_ITEM
    end

    --if base == pending and not hasPendingUndo then
    --    return false, 7; -- same item
    --end

    return true;
end

local function CreateTransmogKey()
    local data = format("%d", WardrobeOutfitDropDown.selectedOutfitID or -1);
    local hasValidChanges;
    for slot, transmogs in pairs(_pending) do
        local _, id, enchant = strsplit(":", GetInventoryItemLink("player", slot) or "");

        local baseEntry = GetInventoryItemID("player", slot);
        local baseEnchant = tonumber(enchant) or 0;
        local fakeEntry, fakeEnchantName, fakeEnchant = ezCollections:GetItemTransmog("player", slot);
        local pendingEntry = transmogs[LE_TRANSMOG_TYPE_APPEARANCE];
        local pendingEnchant = transmogs[LE_TRANSMOG_TYPE_ILLUSION];

        if baseEntry then
            -- Basic sanity check. (not pending) - nothing selected, (pending == 0) - undo transmog
            local entryOK = not pendingEntry or pendingEntry == 0 or pendingEntry == ezCollections:GetHiddenVisualItem() or ezCollections:HasAvailableSkin(pendingEntry);
            local enchantOK = not pendingEnchant or pendingEnchant == 0 or pendingEnchant == ezCollections:GetHiddenVisualItem() or ezCollections:HasAvailableSkin(pendingEnchant);

            -- Skip enchant if it's being applied on a non-enchantable item
            if entryOK and enchantOK and pendingEnchant and pendingEnchant ~= 0 then
                -- Figure out which skin the item will have in the result of transmogrification
                local targetEntry = pendingEntry;
                if not targetEntry then
                    targetEntry = fakeEntry and fakeEntry ~= 0 and fakeEntry or baseEntry;
                elseif targetEntry == 0 then
                    targetEntry = baseEntry;
                end

                local info = ezCollections:GetSkinInfo(targetEntry);
                if info and not info.Enchantable then
                    pendingEnchant = nil;
                end
            end

            if entryOK and enchantOK and (pendingEntry or pendingEnchant) then
                if pendingEntry == 0 then pendingEntry = -1; end
                if pendingEnchant == 0 then pendingEnchant = -1; end

                data = data .. ":" .. format("%d=%d,%d,%d,%d,%d,%d", slot, baseEntry or 0, baseEnchant or 0, fakeEntry or 0, fakeEnchant or 0, pendingEntry or 0, pendingEnchant or 0);
                hasValidChanges = true;
            end
        end
    end
    return data, hasValidChanges;
end

function C_Transmog.ClearPending(slot, transmogType)
    if slot then
        _pending[slot] = _pending[slot] or { };
        _pending[slot][transmogType] = nil;
        if not next(_pending[slot]) then
            _pending[slot] = nil;
        end
        _pendingFailReasons[slot] = _pendingFailReasons[slot] or { };
        _pendingFailReasons[slot][transmogType] = nil;
        if not next(_pendingFailReasons[slot]) then
            _pendingFailReasons[slot] = nil;
        end
    else
        table.wipe(_pending);
        table.wipe(_pendingFailReasons);
    end
    if not _suppressUpdates then
        ezCollections:RaiseEvent("TRANSMOGRIFY_UPDATE", slot, transmogType);
    end
end

function C_Transmog.ApplyAllPending(currentSpecOnly)
    if _pendingApplyKey then
        return false;
    end

    if not next(_pending) then
        return false;
    end

    local key, hasValidChanges = CreateTransmogKey();
    if key == "" or not hasValidChanges then
        return false;
    end

    _pendingApplyKey = key;
    ezCollections:SendAddonMessage("TRANSMOGRIFY:APPLY:" .. key);
    return true;
end

function C_Transmog.PendingApplied(key) -- Custom
    if key == _pendingApplyKey then
        _pendingApplyKey = nil;
        table.wipe(_pending);
        for i, slotString in ipairs({ strsplit(":", key) }) do
            if i == 1 then
                -- slotString contains selected outfit ID, do nothing
            else
                local slot, data = strsplit("=", slotString);
                local baseEntry, baseEnchant, fakeEntry, fakeEnchant, pendingEntry, pendingEnchant = strsplit(",", data);
                if tonumber(pendingEntry) ~= 0 then
                    ezCollections:RaiseEvent("TRANSMOGRIFY_SUCCESS", tonumber(slot), LE_TRANSMOG_TYPE_APPEARANCE);
                end
                if tonumber(pendingEnchant) ~= 0 then
                    ezCollections:RaiseEvent("TRANSMOGRIFY_SUCCESS", tonumber(slot), LE_TRANSMOG_TYPE_ILLUSION);
                end
            end
        end
        WardrobeTransmogFrame_OnTransmogApplied();
    end
end

function C_Transmog.PendingFailed() -- Custom
    _pendingApplyKey = nil;
end

function C_Transmog.GetCost()
    local key, hasValidChanges = CreateTransmogKey();

    local numChanges = 0;
    for slot in pairs(_pending) do
        numChanges = numChanges + 1;
    end

    if numChanges == 0 or not hasValidChanges then
        _lastRequestedCost.Key = nil;
        return 0, 0, 0;
    end

    if _lastRequestedCost.Key ~= key then
        _lastRequestedCost.Key = key;
        _lastRequestedCost.MoneyCost = nil;
        _lastRequestedCost.TokenCost = nil;
        table.wipe(_pendingFailReasons);
        ezCollections:SendAddonMessage("TRANSMOGRIFY:COST:" .. key);
    end

    return _lastRequestedCost.MoneyCost, numChanges, _lastRequestedCost.TokenCost;
end

function C_Transmog.SetCost(key, moneyCost, tokenCost) -- Custom
    if _lastRequestedCost.Key == key then
        _lastRequestedCost.MoneyCost = moneyCost;
        _lastRequestedCost.TokenCost = tokenCost;
        ezCollections:RaiseEvent("TRANSMOGRIFY_UPDATE");
    end
end

function C_Transmog.SetPending(slot, transmogType, sourceID)
    local base, _, applied, _, pending, _, hasPendingUndo = C_Transmog.GetSlotVisualInfo(slot, transmogType);
    if applied ~= 0 and sourceID == applied or applied == 0 and sourceID == base then
        C_Transmog.ClearPending(slot, transmogType);
        return;
    elseif applied ~= 0 and sourceID == base then
        sourceID = 0;
    end

    _pending[slot] = _pending[slot] or { };
    _pending[slot][transmogType] = sourceID;
    _pendingFailReasons[slot] = _pendingFailReasons[slot] or { };
    _pendingFailReasons[slot][transmogType] = nil;
    if not _suppressUpdates then
        ezCollections:RaiseEvent("TRANSMOGRIFY_UPDATE", slot, transmogType);
    end
end

function C_Transmog.ClearSlotFailReasons(key) -- Custom
    if _lastRequestedCost.Key == key or _pendingApplyKey and _pendingApplyKey == key then
        table.wipe(_pendingFailReasons);
    end
end
function C_Transmog.SetSlotFailReason(key, slot, transmogType, reason) -- Custom
    if _lastRequestedCost.Key == key or _pendingApplyKey and _pendingApplyKey == key then
        _pendingFailReasons[slot] = _pendingFailReasons[slot] or { };
        _pendingFailReasons[slot][transmogType] = reason;
    end
end
function C_Transmog.GetSlotFailReason(slot, transmogType) -- Custom
    return _pendingFailReasons[slot] and _pendingFailReasons[slot][transmogType];
end

function C_Transmog.GetApplyWarnings()
    local result = { };
    --[[ Unused
    table.insert(result,
    {
        itemLink = "",
        text = "",
    });
    ]]
    return #result > 0 and result or nil;
end

function C_Transmog.GetSlotInfo(slot, transmogType)
    local base, _, applied, _, pending, _, hasPendingUndo = C_Transmog.GetSlotVisualInfo(slot, transmogType);
    local topmost = pending;
    if topmost == 0 or hasPendingUndo then topmost = applied; end
    if topmost == 0 or topmost == applied and applied == ezCollections:GetHiddenVisualItem() then topmost = base; end

    local isTransmogrified = applied ~= 0;
    local hasPending = pending ~= 0;
    local isPendingCollected = pending and ezCollections:HasAvailableSkin(pending) or pending == ezCollections:GetHiddenVisualItem() or false;
    local canTransmogrify, cannotTransmogrifyReason = CanTransmogrify(slot, transmogType, pending, hasPendingUndo);
    local hasUndo = hasPendingUndo;
    local isHideVisual = (hasPending and pending or applied) == ezCollections:GetHiddenVisualItem();
    local texture = topmost ~= 0 and ezCollections:GetSkinIcon(topmost) or nil;
    return isTransmogrified, hasPending, isPendingCollected, canTransmogrify, cannotTransmogrifyReason, hasUndo, isHideVisual, texture;
end

function C_Transmog.GetSlotUseError(slot, transmogType)
    -- TODO:
end

function C_Transmog.Close()
end

function C_Transmog.ValidateAllPending(defer)
    if defer then
        if not _deferredValidate then
            _deferredValidate = true;
            C_Timer.After(0, function() C_Transmog.ValidateAllPending(); _deferredValidate = false; end);
        end
        return;
    end
    _lastRequestedCost.Key = nil;
    for _, slotInfo in ipairs(TRANSMOG_SLOTS) do
        local slot = GetInventorySlotInfo(slotInfo.slot);
        local transmogType = slotInfo.transmogType;
        if _pending[slot] and _pending[slot][transmogType] then
            C_Transmog.SetPending(slot, transmogType, _pending[slot][transmogType]);
        else
            ezCollections:RaiseEvent("TRANSMOGRIFY_UPDATE", slot, transmogType);
        end
    end
end

function C_Transmog.GetItemInfo()
    -- TODO:
end

function C_Transmog.CanTransmogItemWithItem()
    -- TODO:
end

function C_Transmog.LoadOutfit(outfitID)
    _suppressUpdates = true;
    C_Transmog.ClearPending();
    _lastRequestedCost.Key = nil;

    local appearanceSources, mainHandEnchant, offHandEnchant = C_TransmogCollection.GetOutfitSources(outfitID);
    for slot, sourceID in pairs(appearanceSources) do
        C_Transmog.SetPending(slot, LE_TRANSMOG_TYPE_APPEARANCE, sourceID);
    end
    if mainHandEnchant then
        C_Transmog.SetPending(GetInventorySlotInfo("MAINHANDSLOT"), LE_TRANSMOG_TYPE_ILLUSION, mainHandEnchant);
    end
    if offHandEnchant then
        C_Transmog.SetPending(GetInventorySlotInfo("SECONDARYHANDSLOT"), LE_TRANSMOG_TYPE_ILLUSION, offHandEnchant);
    end
    _suppressUpdates = false;
    ezCollections:RaiseEvent("TRANSMOGRIFY_UPDATE");
end

function C_Transmog.LoadSources(sourceIDTable, mainHandEnchant, offHandEnchant)
    _suppressUpdates = true;
    C_Transmog.ClearPending();
    --_lastRequestedCost.Key = nil; -- Needed?

    for slot, sourceID in pairs(sourceIDTable) do
        C_Transmog.SetPending(slot, LE_TRANSMOG_TYPE_APPEARANCE, sourceID);
    end
    if ezCollections.Config.Wardrobe.HideExtraSlotsOnSetSelect then
        for _, slotInfo in ipairs(TRANSMOG_SLOTS) do
            if slotInfo.transmogType == LE_TRANSMOG_TYPE_APPEARANCE and slotInfo.armorCategoryID then
                local slot = GetInventorySlotInfo(slotInfo.slot);
                local baseSourceID, baseVisualID, appliedSourceID, appliedVisualID, pendingSourceID, pendingVisualID, hasPendingUndo = C_Transmog.GetSlotVisualInfo(slot, LE_TRANSMOG_TYPE_APPEARANCE);
                if not sourceIDTable[slot] and baseSourceID ~= 0 and appliedSourceID ~= ezCollections:GetHiddenVisualItem() and ezCollections:CanHideSlot(slotInfo.slot:gsub("SLOT", "")) then
                    C_Transmog.SetPending(slot, LE_TRANSMOG_TYPE_APPEARANCE, ezCollections:GetHiddenVisualItem());
                end
            end
        end
    end
    if mainHandEnchant ~= -1 then
        C_Transmog.SetPending(GetInventorySlotInfo("MAINHANDSLOT"), LE_TRANSMOG_TYPE_ILLUSION, mainHandEnchant);
    end
    if offHandEnchant ~= -1 then
        C_Transmog.SetPending(GetInventorySlotInfo("SECONDARYHANDSLOT"), LE_TRANSMOG_TYPE_ILLUSION, offHandEnchant);
    end
    _suppressUpdates = false;
    ezCollections:RaiseEvent("TRANSMOGRIFY_UPDATE");
end

function C_Transmog.GetSlotVisualInfo(slot, transmogType)
    local fakeEntry, fakeEnchantName, fakeEnchant = ezCollections:GetItemTransmog("player", slot);
    local base, fake;
    if transmogType == LE_TRANSMOG_TYPE_APPEARANCE then
        base = GetInventoryItemID("player", slot) or 0;
        fake = fakeEntry or 0;
    elseif transmogType == LE_TRANSMOG_TYPE_ILLUSION then
        local _, id, enchant = strsplit(":", GetInventoryItemLink("player", slot) or "");
        base = ezCollections:GetScrollFromEnchant(tonumber(enchant) or 0) or 0;
        fake = fakeEnchant == ezCollections:GetHiddenEnchant() and ezCollections:GetHiddenVisualItem() or ezCollections:GetScrollFromEnchant(fakeEnchant or 0) or 0;
    end

    local baseSourceID = base;
    local baseVisualID = baseSourceID;
    local appliedSourceID = fake;
    local appliedVisualID = appliedSourceID;
    local pendingSourceID = _pending[slot] and _pending[slot][transmogType] or 0;
    local pendingVisualID = pendingSourceID;
    local hasPendingUndo = _pending[slot] and _pending[slot][transmogType] == 0;
    return baseSourceID, baseVisualID, appliedSourceID, appliedVisualID, pendingSourceID, pendingVisualID, hasPendingUndo;
end

local _GetSlotForInventoryTypeData = { nil, 1, nil, 3, 4, 5, 6, 7, 8, 9, 10, nil, nil, 16, 17, 18, 15, 16, nil, 19, 5, 16, 16, 17, nil, 18, 18, nil, nil };
function C_Transmog.GetSlotForInventoryType(inventoryType)
    return _GetSlotForInventoryTypeData[inventoryType];
end
