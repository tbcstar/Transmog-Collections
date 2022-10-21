C_PetJournal = C_PetJournal or { };

local _petIDs = { };
local _petIDToCompanionIndex = { };
local _filteredPetIDs = { };
local _showCollected = nil;
local _showUncollected = nil;
local _showSubscription = nil;
local _sources = { };
local _types = { };
local _sort = 0;
local _search = nil;
local _macroBody = "/click PetJournalSummonRandomFavoritePetButton";

local function PrepareFilter()
    _showCollected = C_PetJournal.IsFilterChecked(LE_PET_JOURNAL_FILTER_COLLECTED);
    _showUncollected = C_PetJournal.IsFilterChecked(LE_PET_JOURNAL_FILTER_NOT_COLLECTED);
    _showSubscription = C_PetJournal.IsFilterChecked(LE_PET_JOURNAL_FILTER_SUBSCRIPTION);
    for filterIndex = 1, C_PetJournal.GetNumPetSources() do
        _sources[filterIndex] = C_PetJournal.IsPetSourceChecked(filterIndex);
    end
    for filterIndex = 1, C_PetJournal.GetNumPetTypes() do
        _types[filterIndex] = C_PetJournal.IsPetTypeChecked(filterIndex);
    end
    _sort = C_PetJournal.GetPetSortParameter();
    _search = ezCollections:PrepareSearchQuery(_search);
end

local function MatchesFilter(petID)
    local isCollected = petID and _petIDToCompanionIndex[petID] ~= nil;
    local _, _, flags, _, _, sourceType = ezCollections:GetPetInfo(petID);
    local name, _, petType = C_PetJournal.GetPetInfoBySpeciesID(petID);

    if ezCollections:IsActivePetSubscriptionPet(petID) then
        if not _showSubscription then
            return false;
        end
    elseif not (_showCollected and isCollected or _showUncollected and not isCollected) then
        return false;
    elseif bit.band(flags or 0, 0x20) ~= 0 and not isCollected and not ezCollections.Config.Wardrobe.PetsShowHidden then
        return false;
    end

    if not _sources[sourceType and sourceType + 1 or 12] then
        return false;
    end

    if not _types[petType] then
        return false;
    end

    if not ezCollections:TextMatchesSearch(name, _search) then
        return false;
    end

    return true;
end

local function SelectRandomFavoritePet()
    local containers = { { }, { } };

    for companionIndex = 1, GetNumCompanions("CRITTER") do
        local petID = select(3, GetCompanionInfo("CRITTER", companionIndex));
        table.insert(containers[2], petID);
        if ezCollections:GetPetFavoritesContainer()[petID] then
            table.insert(containers[1], petID);
        end
    end

    for _, container in ipairs(containers) do
        if #container > 0 then
            return container[math.random(#container)];
        end
    end
end

local function FindFavoriteMacro()
    LoadAddOn("Blizzard_MacroUI");
    local lowPriority;
    for i = 1, MAX_ACCOUNT_MACROS + MAX_CHARACTER_MACROS do
        local body = GetMacroBody(i);
        if body == _macroBody then
            return i;
        elseif body and body:find(_macroBody) then
            lowPriority = i;
        end
    end
    return lowPriority;
end

local function FindMacroIcon(icon)
    icon = icon:lower():gsub("/", "\\");
    for i = 1, GetNumMacroIcons() do
        if (GetMacroIconInfo(i) or ""):lower():gsub("/", "\\") == icon then
            return i;
        end
    end
end

local function CreateFavoriteMacro(perChar)
    local macro = CreateMacro(ezCollections.L["Macro.Pet"], FindMacroIcon([[Interface\Icons\Ability_Hunter_BeastCall]]) or 1, _macroBody, perChar);
    MacroFrame_Update();
    return macro;
end

local function ShowMacroPopup()
    LoadAddOn("Blizzard_MacroUI");
    StaticPopupDialogs["EZCOLLECTIONS_PET_MACRO_CREATE"].OnAccept = function(self)
        C_Timer.After(0, function()
            if InCombatLockdown() then
                StaticPopup_Show("EZCOLLECTIONS_ERROR", ezCollections.L["Popup.Error.Pet.Macro.Combat"]);
                return;
            end
            local numGlobal, numChar = GetNumMacros();
            if numGlobal < MAX_ACCOUNT_MACROS then
                local macro = CreateFavoriteMacro(false);
                if macro then
                    PickupMacro(macro);
                end
            elseif numChar < MAX_CHARACTER_MACROS then
                StaticPopup_Show("EZCOLLECTIONS_PET_MACRO_PERCHARACTER");
            else
                StaticPopup_Show("EZCOLLECTIONS_ERROR", ezCollections.L["Popup.Error.Mount.Macro.NoSpace"]);
            end
        end);
    end;
    StaticPopupDialogs["EZCOLLECTIONS_PET_MACRO_PERCHARACTER"].OnAccept = function(self)
        C_Timer.After(0, function()
            if InCombatLockdown() then
                StaticPopup_Show("EZCOLLECTIONS_ERROR", ezCollections.L["Popup.Error.Mount.Macro.Combat"]);
                return;
            end
            local _, numChar = GetNumMacros();
            if numChar < MAX_CHARACTER_MACROS then
                local macro = CreateFavoriteMacro(true);
                if macro then
                    PickupMacro(macro);
                end
            else
                StaticPopup_Show("EZCOLLECTIONS_ERROR", ezCollections.L["Popup.Error.Mount.Macro.NoSpace"]);
            end
        end);
    end;

    StaticPopup_Show("EZCOLLECTIONS_PET_MACRO_CREATE");
end

function C_PetJournal.RefreshPets() -- Custom
    local oldPets;
    if next(_petIDToCompanionIndex) then
        oldPets = CopyTable(_petIDToCompanionIndex);
    end

    table.wipe(_petIDs);
    table.wipe(_petIDToCompanionIndex);
    table.wipe(_filteredPetIDs);

    PrepareFilter();

    for petID, info in pairs(ezCollections.Pets) do
        local _, _, name = unpack(info);
        if name then
            table.insert(_petIDs, petID);
        end
    end

    for companionIndex = 1, GetNumCompanions("CRITTER") do
        local petID = select(3, GetCompanionInfo("CRITTER", companionIndex));
        if not tContains(_petIDs, petID) then
            table.insert(_petIDs, petID);
        end
        _petIDToCompanionIndex[petID] = companionIndex;
        if oldPets and not oldPets[petID] then
            ezCollections:GetPetNeedFanfareContainer()[petID] = true;
        end
    end

    for _, petID in ipairs(_petIDs) do
        if MatchesFilter(petID) then
            table.insert(_filteredPetIDs, petID);
        end
    end

    table.sort(_filteredPetIDs, function(a, b)
        local _, _, _, _, _, _, isFavoriteA, nameA, _, petTypeA = C_PetJournal.GetPetInfoByPetID(a);
        local _, _, _, _, _, _, isFavoriteB, nameB, _, petTypeB = C_PetJournal.GetPetInfoByPetID(b);
        local isCollectedA = _petIDToCompanionIndex[a] ~= nil;
        local isCollectedB = _petIDToCompanionIndex[b] ~= nil;

        if isFavoriteA ~= isFavoriteB then
            return isFavoriteA;
        end

        if isCollectedA ~= isCollectedB then
            return isCollectedA;
        end

        if _sort == LE_SORT_BY_PETTYPE and petTypeA ~= petTypeB then
            return petTypeA < petTypeB;
        end

        return nameA < nameB;
    end);
end

function C_PetJournal.GetFavoriteMacro() -- Custom
    return FindFavoriteMacro();
end

function C_PetJournal.GetPetIDs() -- Custom
    return _petIDs;
end

-- Pet Data

function C_PetJournal.IsJournalUnlocked()
    return true;
end

function C_PetJournal.GetNumPets()
    local numPets = #_petIDs;
    local numOwned = GetNumCompanions("CRITTER");
    return numPets, numOwned;
end

function C_PetJournal.GetNumDisplayedPets() -- Custom
    return #_filteredPetIDs;
end

function C_PetJournal.GetNumCollectedInfo(speciesID)
end

function C_PetJournal.GetPetInfoByIndex(index)
    local petID, speciesID, isOwned, customName, level, isFavorite, isRevoked, name, icon, petType, companionID, tooltip, isWild, description, canBattle, isTradeable, isUnique, obtainable;
    local _;

    petID = _filteredPetIDs[index];
    speciesID = petID; -- Custom
    isOwned = petID and _petIDToCompanionIndex[petID] ~= nil;
    isFavorite = C_PetJournal.PetIsFavorite(index);
    if speciesID then
        name, icon, petType, companionID, _, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoBySpeciesID(speciesID);
    end

    return petID, speciesID, isOwned, customName, level, isFavorite, isRevoked, name, icon, petType, companionID, tooltip, isWild, description, canBattle, isTradeable, isUnique, obtainable;
end

function C_PetJournal.GetPetModelSceneInfoBySpeciesID(speciesID)
end

function C_PetJournal.SetPetLoadOutInfo(slot, petID)
end

function C_PetJournal.GetPetInfoBySpeciesID(speciesID)
    local petID = speciesID; -- Custom

    local name, icon, petType, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable, displayID;
    local _, sourceType, sourceText;

    creatureID, petType, _, name, description, sourceType, sourceText = ezCollections:GetPetInfo(petID);

    obtainable = sourceType ~= -1;
    local companionIndex = _petIDToCompanionIndex[petID];
    if companionIndex then
        creatureID, name, _, icon = GetCompanionInfo("CRITTER", companionIndex);
    else
        name = name or GetSpellInfo(petID);
        icon = select(3, GetSpellInfo(petID));
    end
    displayID = creatureID; -- Custom

    return name or "", icon, petType and petType + 1 or 5, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable, displayID;
end

function C_PetJournal.GetOwnedBattlePetString(speciesID)
end

function C_PetJournal.GetPetInfoByPetID(petGUID)
    local petID = petGUID; -- Custom

    local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable;

    speciesID = petID; -- Custom
    isFavorite = petID and ezCollections:GetPetFavoritesContainer()[petID] and true or false;
    name, icon, petType, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable, displayID = C_PetJournal.GetPetInfoBySpeciesID(speciesID)

    return speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable;
end

function C_PetJournal.GetSummonBattlePetCooldown()
    return 0;
end

function C_PetJournal.GetPetCooldownByGUID(ID)
    return 0;
end

function C_PetJournal.GetPetLoadOutInfo(slot)
    local petID, ability1ID, ability2ID, ability3ID, locked;
    return petID, ability1ID, ability2ID, ability3ID, locked;
end

function C_PetJournal.GetPetAbilityInfo(id)
    local name, icon, petType;
    return name, icon, petType;
end

function C_PetJournal.GetPetAbilityList(speciesID, abilityIDTable, abilityLevelTable)
    return { --[[ { abilityID, level }, ... ]] };
end

-- Search

local function SearchUpdated()
    ezCollections:RaiseEvent("PET_JOURNAL_SEARCH_UPDATED");
    PetJournalResetFiltersButton_UpdateVisibility();
end

function C_PetJournal.SetSearchFilter(searchString)
    _search = searchString;
    ezCollections:RaiseEvent("PET_JOURNAL_SEARCH_UPDATED");
end

function C_PetJournal.ClearSearchFilter()
    C_PetJournal.SetSearchFilter();
end

-- Pickup

function C_PetJournal.PickupPet(petGUID)
    local displayIndex = petGUID; -- Custom

    if not next(_filteredPetIDs) or not next(_petIDToCompanionIndex) then
        C_PetJournal.RefreshPets();
    end

    if displayIndex == 0 then
        local macro = FindFavoriteMacro();
        if macro then
            PickupMacro(macro);
        else
            ShowMacroPopup();
        end
        return;
    end

    local petID = _filteredPetIDs[displayIndex];
    local companionIndex = petID and _petIDToCompanionIndex[petID];
    if companionIndex then
        PickupCompanion("CRITTER", companionIndex);
    end
end

function C_PetJournal.PickupSummonRandomPet()
    if not next(_filteredPetIDs) or not next(_petIDToCompanionIndex) then
        C_PetJournal.RefreshPets();
    end

    local macro = FindFavoriteMacro();
    if macro then
        PickupMacro(macro);
    else
        ShowMacroPopup();
    end
end

-- Pet Info

function C_PetJournal.PetIsTradable(petGUID)
    return false;
end

function C_PetJournal.PetIsCapturable(petGUID)
    return false;
end

function C_PetJournal.PetCanBeReleased(petGUID)
    return false;
end

function C_PetJournal.PetIsSummonable(petGUID)
    local isSummonable = true;
    return isSummonable;
end

function C_PetJournal.GetNumPetsNeedingFanfare()
    local count = 0;
    for petID in ezCollections:GetPetNeedFanfareContainer() do
        count = count + 1;
    end
    return count;
end

function C_PetJournal.PetNeedsFanfare(petGUID)
    local petID = petGUID; -- Custom

    return ezCollections:GetPetNeedFanfareContainer()[petID];
end

function C_PetJournal.ClearRecentFanfares()
    table.wipe(ezCollections:GetPetNeedFanfareContainer());
end

function C_PetJournal.PetIsRevoked(petGUID)
    return false;
end

function C_PetJournal.PetIsLockedForConvert(petGUID)
    return false;
end

function C_PetJournal.PetIsSlotted(petGUID)
    return false;
end

function C_PetJournal.PetIsHurt(petGUID)
    return false;
end

function C_PetJournal.ClearFanfare(petGUID)
    local petID = petGUID; -- Custom

    ezCollections:GetPetNeedFanfareContainer()[petID] = nil;
end

-- Pet Actions

function C_PetJournal.DismissPet() -- Custom
    DismissCompanion("CRITTER");
end

function C_PetJournal.SummonPetByGUID(petGUID)
    local petID = petGUID; -- Custom

    if not next(_petIDToCompanionIndex) then
        C_PetJournal.RefreshPets();
    end

    if C_PetJournal.GetSummonedPetGUID() == petID then
        DismissCompanion("CRITTER");
        return;
    end

    local companionIndex = _petIDToCompanionIndex[petID];
    if companionIndex then
        CallCompanion("CRITTER", companionIndex);
    end
end

function C_PetJournal.GetSummonedPetGUID()
    for companionIndex = 1, GetNumCompanions("CRITTER") do
        local _, _, spellID, _, active = GetCompanionInfo("CRITTER", companionIndex);
        if active then
            return spellID; -- Custom
        end
    end
end

function C_PetJournal.CagePetByID(petGUID)
end

function C_PetJournal.ReleasePetByID(petID)
end

function C_PetJournal.FindPetIDByName(petName)
    for companionIndex = 1, GetNumCompanions("CRITTER") do
        if select(2, GetCompanionInfo("CRITTER", companionIndex)) == petName then
            return companionIndex;
        end
    end
end

function C_PetJournal.SummonRandomPet()
    if not next(_petIDToCompanionIndex) then
        C_PetJournal.RefreshPets();
    end

    if C_PetJournal.GetSummonedPetGUID() then
        DismissCompanion("CRITTER");
        return;
    end

    local petID = SelectRandomFavoritePet();
    if not petID then
        return;
    end

    local companionIndex = _petIDToCompanionIndex[petID];
    if companionIndex then
        CallCompanion("CRITTER", companionIndex);
    end
end

function C_PetJournal.GetSummonRandomFavoritePetGUID()
end

function C_PetJournal.SetAbility(slotIndex, spellIndex, petSpellID)
end

function C_PetJournal.SetCustomName(petID, name)
end

function C_PetJournal.SetFavorite(petID, bool)
    local petIndex = petID; -- Custom

    local petID = _filteredPetIDs[petIndex];
    if petID then
        ezCollections:GetPetFavoritesContainer()[petID] = bool and true or nil;
    end
    SearchUpdated();
end

function C_PetJournal.PetIsFavorite(ID)
    local petIndex = ID; -- Custom

    local petID = _filteredPetIDs[petIndex];
    local isFavorite = petID and ezCollections:GetPetFavoritesContainer()[petID] and true or false;
    local canSetFavorite = true;
    return isFavorite, canSetFavorite;
end

function C_PetJournal.PetIsUsable(ID)
    local petID = ID; -- Custom

    local isCollected = petID and _petIDToCompanionIndex[petID] ~= nil;

    local isUsable = isCollected;
    return isUsable;
end

function C_PetJournal.GetPetStats(ID)
    local health, maxHealth, attack, speed, rarity;
    return health, maxHealth, attack, speed, rarity;
end

function C_PetJournal.IsFindBattleEnabled()
    return false;
end

function C_PetJournal.GetBattlePetLink(ID)
    local petIndex = ID; -- Custom

    local petID = _filteredPetIDs[petIndex];
    if petID then
        return GetSpellLink(petID);
    end
end

function C_PetJournal.GetPetTeamAverageLevel()
    return 0;
end

-- Filter

function C_PetJournal.SetPetSortParameter(parameterID)
    ezCollections:SetCVar("petJournalSort", parameterID);
    SearchUpdated();
end

function C_PetJournal.GetPetSortParameter()
    return ezCollections:GetCVar("petJournalSort");
end

function C_PetJournal.GetNumPetTypes()
    return #PET_TYPE_SUFFIX;
end

function C_PetJournal.SetPetTypeFilter(petTypeIndex, value)
    ezCollections:SetCVarBitfield("petJournalTypeFilters", petTypeIndex, not value);
    SearchUpdated();
end

function C_PetJournal.IsPetTypeChecked(petTypeIndex)
    return not ezCollections:GetCVarBitfield("petJournalTypeFilters", petTypeIndex);
end

function C_PetJournal.SetAllPetTypesChecked(checked)
    for filterIndex = 1, C_PetJournal.GetNumPetTypes() do
        ezCollections:SetCVarBitfield("petJournalTypeFilters", filterIndex, not checked);
    end
    SearchUpdated();
end

function C_PetJournal.GetNumPetSources()
    return 12;
end

function C_PetJournal.SetPetSourceChecked(petSourceIndex, value)
    ezCollections:SetCVarBitfield("petJournalSourceFilters", petSourceIndex, not value);
    SearchUpdated();
end

function C_PetJournal.IsPetSourceChecked(petSourceIndex)
    return not ezCollections:GetCVarBitfield("petJournalSourceFilters", petSourceIndex);
end

function C_PetJournal.SetAllPetSourcesChecked(checked)
    for filterIndex = 1, C_PetJournal.GetNumPetSources() do
        ezCollections:SetCVarBitfield("petJournalSourceFilters", filterIndex, not checked);
    end
    SearchUpdated();
end

function C_PetJournal.SetFilterChecked(filter, value)
    ezCollections:SetCVarBitfield("petJournalFilters", filter, not value);
    SearchUpdated();
end

function C_PetJournal.IsFilterChecked(filter)
    return not ezCollections:GetCVarBitfield("petJournalFilters", filter);
end

function C_PetJournal.SetDefaultFilters()
    ezCollections:SetCVar("petJournalFilters", 0);
    ezCollections:SetCVar("petJournalSourceFilters", 0);
    ezCollections:SetCVar("petJournalTypeFilters", 0);
    SearchUpdated();
end

function C_PetJournal.IsUsingDefaultFilters()
    return ezCollections:GetCVar("petJournalFilters") == 0
        and ezCollections:GetCVar("petJournalSourceFilters") == 0
        and ezCollections:GetCVar("petJournalTypeFilters") == 0;
end

-- Global

function C_PetJournal.IsJournalReadOnly()
    return false;
end

function C_PetJournal.GetNumMaxPets()
    return 0;
end

-- Random Display Info

function C_PetJournal.PetUsesRandomDisplay(speciesID)
    local usesRandomDisplay;
    return usesRandomDisplay;
end

function C_PetJournal.GetNumDisplays(speciesID)
    local numDisplays;
    return numDisplays;
end

function C_PetJournal.GetDisplayIDByIndex(speciesID, index)
    local displayID;
    return displayID;
end

function C_PetJournal.GetDisplayProbabilityByIndex(speciesID, index)
    local displayProbability;
    return displayProbability;
end
