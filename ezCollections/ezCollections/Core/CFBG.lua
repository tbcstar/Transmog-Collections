ezCollections.CFBG = ezCollections.CFBG or { };

hooksecurefunc("MiniMapBattlefieldFrame_isArena", function()
    if ezCollections.CFBG.Faction and ezCollections.Config.Misc.CFBGFactionIcons and UnitInBattleground("player") and UnitFactionGroup("player") and MiniMapBattlefieldIcon:GetTexture() == [[Interface\BattlefieldFrame\Battleground-]]..UnitFactionGroup("player") then
        MiniMapBattlefieldIcon:SetTexture([[Interface\BattlefieldFrame\Battleground-]]..ezCollections.CFBG.Faction);
    end
end);

hooksecurefunc("PlayerFrame_UpdatePvPStatus", function()
    if ezCollections.CFBG.Faction and ezCollections.Config.Misc.CFBGFactionIcons and UnitInBattleground("player") and UnitIsPVP("player") and UnitFactionGroup("player") and PlayerPVPIcon:GetTexture() == [[Interface\TargetingFrame\UI-PVP-]]..UnitFactionGroup("player") then
        PlayerPVPIcon:SetTexture([[Interface\TargetingFrame\UI-PVP-]]..ezCollections.CFBG.Faction);
        PlayerPVPIconHitArea.tooltipTitle = _G["FACTION_"..strupper(ezCollections.CFBG.Faction)];
        PlayerPVPIconHitArea.tooltipText = _G["NEWBIE_TOOLTIP_"..strupper(ezCollections.CFBG.Faction)];
    end
end);

local groupmateCarryingFlag;

local function HandleGroupmate(unit)
    if groupmateCarryingFlag then return; end

    local x, y = GetPlayerMapPosition(unit);
    if x == 0 and y == 0 then return; end

    for i = 1, GetNumBattlefieldFlagPositions() do
        local flagX, flagY = GetBattlefieldFlagPosition(i);
        if math.abs(flagX - x) < 0.00001 and math.abs(flagY - y) < 0.00001 then
            for j = 1, BUFF_MAX_DISPLAY do
                local spell = select(11, UnitBuff(unit, j));
                if spell == 23333 or spell == 23335 or spell == 34976 then
                    groupmateCarryingFlag = i;
                    return true;
                end
            end
        end
    end
end

local currentUpdateFrame = 0;
local lastUpdateFrame = 0;
local function GuessFlagPositions()
    if lastUpdateFrame == currentUpdateFrame then return; end
    lastUpdateFrame = currentUpdateFrame;

    if ezCollections.CFBG.Faction and ezCollections.Config.Misc.CFBGFactionIcons and UnitInBattleground("player") then
        local mapName = GetMapInfo();
        if mapName == "WarsongGulch" then
            if GetNumBattlefieldFlagPositions() == 2 then
                return;
            end
        elseif mapName == "NetherstormArena" then
        else
            return;
        end

        groupmateCarryingFlag = nil;
        if not HandleGroupmate("player") then
            if GetNumRaidMembers() > 0 then
                for i = 1, MAX_RAID_MEMBERS do
                    if HandleGroupmate("raid"..i) then break; end
                end
            else
                for i = 1, MAX_PARTY_MEMBERS do
                    if HandleGroupmate("party"..i) then break; end
                end
            end
        end
    end
end

local oldGetBattlefieldFlagPosition = GetBattlefieldFlagPosition;
function GetBattlefieldFlagPosition(i)
    local flagX, flagY, flagToken = oldGetBattlefieldFlagPosition(i);

    if ezCollections.CFBG.Faction and ezCollections.Config.Misc.CFBGFactionIcons and UnitInBattleground("player") then
        GuessFlagPositions();

        local mapName = GetMapInfo();
        local flip;
        if mapName == "WarsongGulch" then
            if GetNumBattlefieldFlagPositions() == 2 then
                return flagX, flagY, i == 1 and "HordeFlag" or "AllianceFlag";
            end
        elseif mapName == "NetherstormArena" then
            flip = true;
        else
            return flagX, flagY, flagToken;
        end

        local myFaction = ezCollections.CFBG.Faction or "";
        local otherFaction = strupper(myFaction) == "ALLIANCE" and "Horde" or "Alliance";
        if i == groupmateCarryingFlag then
            flagToken = (flip and myFaction or otherFaction).."Flag";
        else
            flagToken = (flip and otherFaction or myFaction).."Flag";
        end
    end

    return flagX, flagY, flagToken;
end

CreateFrame("Frame"):SetScript("OnUpdate", function()
    if ezCollections.CFBG.Faction and ezCollections.Config.Misc.CFBGFactionIcons and UnitInBattleground("player") then
        currentUpdateFrame = currentUpdateFrame + 1;
        if currentUpdateFrame >= 1000000 then
            currentUpdateFrame = 0;
        end
    end
end);
