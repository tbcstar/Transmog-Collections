C_ToyBox = C_ToyBox or { };

local _toyIDs = { };
local _hiddenToyIDs = { };
local _filteredToyIDs = { };
local _showCollected = nil;
local _showUncollected = nil;
local _showUnusable = nil;
local _showSubscription = nil;
local _sources = { };
local _expansions = { };
local _search = nil;

local function IsToyUsable(itemID)
    local _, flags, _, _, _, holiday = ezCollections:GetToyInfoByItem(itemID);

    if bit.band(flags or 0, 0x100) ~= 0 and UnitFactionGroup("player") ~= "Horde" then return false; end
    if bit.band(flags or 0, 0x200) ~= 0 and UnitFactionGroup("player") ~= "Alliance" then return false; end
    if holiday and holiday ~= 0 and not ezCollections:IsHolidayActive(holiday) then return false; end

    if GetItemInfo(itemID) then
        local tooltip = ezCollections.textScanTooltip;
        tooltip:ClearLines();
        tooltip:SetOwner(UIParent, "ANCHOR_NONE");
        tooltip:SetHyperlink("item:"..itemID);
        local result = tooltip:IsShown() and not ezCollections:ForEachTooltipText(tooltip, function(line)
            local text = line:GetText();
            return text and text ~= "" and text ~= " " and ezCollections.IsSameColor(1, 0.125, 0.125, line:GetTextColor());
        end);
        tooltip:Hide();
        return result;
    end

    return false;
end

local function PrepareFilter()
    _showCollected = C_ToyBox.GetCollectedShown();
    _showUncollected = C_ToyBox.GetUncollectedShown();
    _showUnusable = C_ToyBox.GetUnusableShown();
    _showSubscription = C_ToyBox.GetSubscriptionShown();
    for filterIndex = 1, C_PetJournal.GetNumPetSources() do
        _sources[filterIndex] = not C_ToyBox.IsSourceTypeFilterChecked(filterIndex);
    end
    for filterIndex = 1, GetNumExpansions() do
        _expansions[filterIndex] = not C_ToyBox.IsExpansionTypeFilterChecked(filterIndex);
    end
    _search = ezCollections:PrepareSearchQuery(_search);
end

local function MatchesFilter(itemID)
    local toyID = ezCollections:GetToyIDByItem(itemID);
    local itemID, flags, expansionID, sourceType = ezCollections:GetToyInfo(toyID);
    if not toyID or not itemID then
        return false;
    end
    local isCollected = ezCollections:HasToy(toyID);
    local viaSubscription = not isCollected and ezCollections:IsActiveToySubscriptionToy(toyID);

    -- Hidden until learned
    if bit.band(flags, 0x2) ~= 0 and not isCollected and not viaSubscription and not ezCollections.Config.Wardrobe.ToysShowHidden then
        return false, true;
    end

    if viaSubscription then
        if not _showSubscription then
            return false;
        end
    elseif not (_showCollected and isCollected or _showUncollected and not isCollected) then
        return false;
    end

    if not _showUnusable and not C_ToyBox.IsToyUsable(itemID) then
        return false;
    end

    if not _sources[sourceType + 1] then
        return false;
    end

    if not _expansions[expansionID + 1] then
        return false;
    end

    if _search and not ezCollections:TextMatchesSearch(select(2, C_ToyBox.GetToyInfo(itemID)) or "", _search) then
        return false;
    end

    return true;
end

function C_ToyBox.RefreshToys() -- Custom
    table.wipe(_toyIDs);
    table.wipe(_hiddenToyIDs);
    table.wipe(_filteredToyIDs);

    PrepareFilter();

    for id, info in pairs(ezCollections.Cache.Toys) do
        if type(id) == "number" then
            local itemID = info[1];
            if itemID then
                table.insert(_toyIDs, itemID);
                local matches, hidden = MatchesFilter(itemID);
                if matches then
                    table.insert(_filteredToyIDs, itemID);
                elseif hidden then
                    table.insert(_hiddenToyIDs, itemID);
                end
            end
        end
    end

    table.sort(_filteredToyIDs, function(a, b)
        local _, nameA = C_ToyBox.GetToyInfo(a);
        local _, nameB = C_ToyBox.GetToyInfo(b);
        local isFavoriteA = C_ToyBox.GetIsFavorite(a);
        local isFavoriteB = C_ToyBox.GetIsFavorite(b);

        if isFavoriteA ~= isFavoriteB then
            return isFavoriteA;
        end

        if nameA ~= nameB then
            return nameA < nameB;
        end

        return a < b;
    end);
end

function C_ToyBox.GetToys() -- Custom
    return _toyIDs;
end

function UseToy(itemID)
    if ezCollections.ActiveToys[itemID] then
        local toyID = ezCollections:GetToyIDByItem(itemID);
        if toyID then
            ezCollections:SendAddonMessage(format("TOY:DEACTIVATE:%d", toyID));
        end
        return;
    end

    if not PlayerHasToy(itemID) then
        return;
    end

    if UnitCastingInfo("player") or UnitChannelInfo("player") then
        return;
    end

    local start, duration, enable = ezCollections:GetItemCooldown(itemID)
    if GetTime() < start + duration then
        return;
    end

    local toyID = ezCollections:GetToyIDByItem(itemID);
    if toyID then
        ezCollections:SendAddonMessage(format("TOY:USE:%d", toyID));
    end
end

function UseToyByName(toyName)
    for _, itemID in ipairs(_toyIDs) do
        local _, name = C_ToyBox.GetToyInfo(itemID);
        if name == toyName then
            UseToy(itemID);
        end
    end
end

function PlayerHasToy(itemID)
    local toyID = ezCollections:GetToyIDByItem(itemID);
    return toyID and ezCollections:HasAvailableToy(toyID);
end

function C_ToyBox.GetToyFromIndex(itemIndex)
    return _filteredToyIDs[itemIndex] or -1;
end

function C_ToyBox.GetNumToys()
    return #_toyIDs;
end

function C_ToyBox.GetNumFilteredToys()
    return #_filteredToyIDs;
end

function C_ToyBox.GetNumTotalDisplayedToys()
    return #_toyIDs - #_hiddenToyIDs;
end

function C_ToyBox.GetNumLearnedDisplayedToys()
    local collected = 0;
    for _, itemID in ipairs(_toyIDs) do
        if ezCollections:HasToy(ezCollections:GetToyIDByItem(itemID) or 0) then
            collected = collected + 1;
        end
    end
    return collected;
end

function C_ToyBox.GetToyInfo(itemID)
    local itemID = ezCollections:GetToyInfoByItem(itemID);
    local name, icon, _;
    if itemID then
        name, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemID);
        icon = icon or GetItemIcon(itemID);
    end
    return itemID, name or "", icon;
end

function C_ToyBox.GetToyLink(itemID)
    local itemID = ezCollections:GetToyInfoByItem(itemID);
    return itemID and select(2, GetItemInfo(itemID));
end

function C_ToyBox.PickupToyBoxItem(itemID)
    local itemID = ezCollections:GetToyInfoByItem(itemID);
    if itemID and PlayerHasToy(itemID) then
        PickupItem(itemID);
    end
end

function C_ToyBox.ForceToyRefilter()
    ezCollections:RaiseEvent("TOYS_UPDATED");
end

function C_ToyBox.SetCollectedShown(checked)
    ezCollections:SetCVarBitfield("toyBoxCollectedFilters", 1, not checked);
end

function C_ToyBox.SetUncollectedShown(checked)
    ezCollections:SetCVarBitfield("toyBoxCollectedFilters", 2, not checked);
end

function C_ToyBox.SetUnusableShown(checked)
    ezCollections:SetCVarBitfield("toyBoxCollectedFilters", 3, not checked);
end

function C_ToyBox.SetSubscriptionShown(checked)
    ezCollections:SetCVarBitfield("toyBoxCollectedFilters", 4, not checked);
end

function C_ToyBox.GetCollectedShown()
    return not ezCollections:GetCVarBitfield("toyBoxCollectedFilters", 1);
end

function C_ToyBox.GetUncollectedShown()
    return not ezCollections:GetCVarBitfield("toyBoxCollectedFilters", 2);
end

function C_ToyBox.GetUnusableShown()
    return not ezCollections:GetCVarBitfield("toyBoxCollectedFilters", 3);
end

function C_ToyBox.GetSubscriptionShown()
    return not ezCollections:GetCVarBitfield("toyBoxCollectedFilters", 4);
end

function C_ToyBox.SetFilterString(string)
    _search = string;
end

function C_ToyBox.SetSourceTypeFilter(sourceIndex, checked)
    ezCollections:SetCVarBitfield("toyBoxSourceFilters", sourceIndex, not checked);
end

function C_ToyBox.SetExpansionTypeFilter(expansionIndex, checked)
    ezCollections:SetCVarBitfield("toyBoxExpansionFilters", expansionIndex, not checked);
end

function C_ToyBox.IsSourceTypeFilterChecked(sourceIndex)
    return ezCollections:GetCVarBitfield("toyBoxSourceFilters", sourceIndex);
end

function C_ToyBox.IsExpansionTypeFilterChecked(expansionIndex)
    return ezCollections:GetCVarBitfield("toyBoxExpansionFilters", expansionIndex);
end

function C_ToyBox.SetAllSourceTypeFilters(checked)
    for filterIndex = 1, C_PetJournal.GetNumPetSources() do
        ezCollections:SetCVarBitfield("toyBoxSourceFilters", filterIndex, not checked);
    end
end

function C_ToyBox.SetAllExpansionTypeFilters(checked)
    for filterIndex = 1, GetNumExpansions() do
        ezCollections:SetCVarBitfield("toyBoxExpansionFilters", filterIndex, not checked);
    end
end

function C_ToyBox.SetDefaultFilters()
    ezCollections:SetCVar("toyBoxCollectedFilters", 0);
    ezCollections:SetCVar("toyBoxSourceFilters", 0);
    ezCollections:SetCVar("toyBoxExpansionFilters", 0);
end

function C_ToyBox.IsUsingDefaultFilters()
    return ezCollections:GetCVar("toyBoxCollectedFilters") == 0
        and ezCollections:GetCVar("toyBoxSourceFilters") == 0
        and ezCollections:GetCVar("toyBoxExpansionFilters") == 0;
end

function C_ToyBox.SetIsFavorite(itemID, value)
    ezCollections:GetToyFavoritesContainer()[itemID] = value and true or nil;
    ezCollections:RaiseEvent("TOYS_UPDATED");
end

function C_ToyBox.GetIsFavorite(itemID)
    return ezCollections:GetToyFavoritesContainer()[itemID] and true or false;
end

function C_ToyBox.HasFavorites()
    return next(ezCollections:GetToyFavoritesContainer()) ~= nil;
end

function C_ToyBox.IsToyUsable(itemID)
    return IsToyUsable(itemID);
end
