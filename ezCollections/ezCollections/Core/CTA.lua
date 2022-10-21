local ctaShortageRewards = { };

local oGetLFGDungeonRewards = GetLFGDungeonRewards;
local GetLFGDungeonRewardsImpl = oGetLFGDungeonRewards; -- Fuck ElvUI
function GetLFGDungeonRewards(dungeonID)
    return GetLFGDungeonRewardsImpl(dungeonID);
end

local function Hook()
    Hook = nil;

    local function GetShortageRewardInfo(dungeonID, i)
        local link = GetLFGDungeonRewardLink(dungeonID, i);
        if link then
            local id = ezCollections.GetItemID(link);
            if id then
                return ctaShortageRewards[id];
            end
        end
    end
    local function IsShortageRoleSelected(info)
        return bit.band(info.Roles, 2) ~= 0 and LFDQueueFrameRoleButtonTank.checkButton:GetChecked()
            or bit.band(info.Roles, 4) ~= 0 and LFDQueueFrameRoleButtonHealer.checkButton:GetChecked()
            or bit.band(info.Roles, 8) ~= 0 and LFDQueueFrameRoleButtonDPS.checkButton:GetChecked();
    end
    GetLFGDungeonRewardsImpl = function(dungeonID)
        local doneToday, moneyBase, moneyVar, experienceBase, experienceVar, numRewards = oGetLFGDungeonRewards(dungeonID);
        local leaderChecked, tankChecked, healerChecked, damageChecked = LFDQueueFrame_GetRoles();

        for i = 1, numRewards do
            local info = GetShortageRewardInfo(dungeonID, i);
            if info then
                if info.IsVisualOnly then
                    numRewards = i - 1;
                    break;
                end

                local eligible, forTank, forHealer, forDamage, itemCount = GetLFGRoleShortageRewards(dungeonID, info.ShortageIndex);
                if not ( eligible and ((tankChecked and forTank) or (healerChecked and forHealer) or (damageChecked and forDamage)) ) then
                    numRewards = i - 1;
                    break;
                end
            end
        end

        return doneToday, moneyBase, moneyVar, experienceBase, experienceVar, numRewards;
    end
    function GetLFGRoleShortageRewards(dungeonID, shortageIndex)
        local numRewards = select(6, oGetLFGDungeonRewards(dungeonID));
        local itemCount = 0;
        local roles = 0;
        for i = 1, numRewards do
            local info = GetShortageRewardInfo(dungeonID, i);
            if info and info.ShortageIndex == shortageIndex then
                if info.IsVisualOnly then
                    roles = bit.bor(roles, info.Roles);
                else
                    itemCount = itemCount + 1;
                end
            end
        end

        return true, bit.band(roles, 2) ~= 0, bit.band(roles, 4) ~= 0, bit.band(roles, 8) ~= 0, itemCount, 0, 0;
    end

    LFG_ROLE_SHORTAGE_RARE = 1;
    LFG_ROLE_SHORTAGE_UNCOMMON = 2;
    LFG_ROLE_SHORTAGE_PLENTIFUL = 3;
    LFG_ROLE_NUM_SHORTAGE_TYPES = 3;
    LFG_ID_TO_ROLES = { "DAMAGER", "TANK", "HEALER" };

    -- Role Buttons
    local function InjectRoleButton(button)
        if button.shortageBorder then return; end

        button.checkButton.onClick = LFDFrameRoleCheckButton_OnClick;

        button.layerFrame = CreateFrame("Frame", "$parentLayerFrame", button);
        button.layerFrame:SetAllPoints(true);

        button.checkButton:SetFrameLevel(button.layerFrame:GetFrameLevel() + 2);

        button.shortageBorder = button.layerFrame:CreateTexture(button:GetName().."ShortageBorder", "OVERLAY");
        button.shortageBorder:SetTexture([[Interface\AddOns\ezCollections\Interface\Common\GoldRing]]);
        button.shortageBorder:SetSize(48, 48);
        button.shortageBorder:SetPoint("CENTER", -1, 1);
        button.shortageBorder:Hide();

        button.incentiveIcon = CreateFrame("Frame", "$parentIncentiveIcon", button);
        button.incentiveIcon:SetSize(25, 25);
        button.incentiveIcon:SetPoint("BOTTOMRIGHT", 7, -7);
        button.incentiveIcon:SetScript("OnEnter", LFGRoleIconIncentive_OnEnter);
        button.incentiveIcon:SetScript("OnLeave", GameTooltip_Hide);
        button.incentiveIcon:EnableMouse(true);
        button.incentiveIcon:SetFrameLevel(button.layerFrame:GetFrameLevel() + 1);

        button.incentiveIcon.texture = button.incentiveIcon:CreateTexture("$parentTexture", "ARTWORK");
        button.incentiveIcon.texture:SetSize(17, 17);
        button.incentiveIcon.texture:SetPoint("CENTER", -3, 3);

        button.incentiveIcon.border = button.incentiveIcon:CreateTexture("$parentBorder", "OVERLAY");
        button.incentiveIcon.border:SetAllPoints(true);
        button.incentiveIcon.border:SetTexture([[Interface\AddOns\ezCollections\Interface\LFGFrame\UI-LFG-ICON-REWARDRING]]);
        button.incentiveIcon.border:SetTexCoord(0, 0.675, 0, 0.675);
    end

    hooksecurefunc("LFDFrameRoleCheckButton_OnClick", function(self)
        local dungeonID = LFDQueueFrame.type;

        if ( type(dungeonID) ~= "number" ) then --We haven't gotten info on available dungeons yet.
            return;
        end

        LFDQueueFrameRandom_UpdateFrame(); --We may show or hide shortage rewards.
    end);

    hooksecurefunc("LFG_PermanentlyDisableRoleButton", function(button)
        if ( button.shortageBorder ) then
            button.shortageBorder:SetVertexColor(0.5, 0.5, 0.5);
            button.incentiveIcon.texture:SetVertexColor(0.5, 0.5, 0.5);
            button.incentiveIcon.border:SetVertexColor(0.5, 0.5, 0.5);
        end
    end);
    hooksecurefunc("LFG_DisableRoleButton", function(button)
        if ( button.shortageBorder ) then
            button.shortageBorder:SetVertexColor(0.5, 0.5, 0.5);
            button.incentiveIcon.texture:SetVertexColor(0.5, 0.5, 0.5);
            button.incentiveIcon.border:SetVertexColor(0.5, 0.5, 0.5);
        end
    end);
    hooksecurefunc("LFG_EnableRoleButton", function(button)
        if ( button.shortageBorder ) then
            button.shortageBorder:SetVertexColor(1, 1, 1);
            button.incentiveIcon.texture:SetVertexColor(1, 1, 1);
            button.incentiveIcon.border:SetVertexColor(1, 1, 1);
        end
    end);

    function LFDQueueFrame_UpdateRoleIncentives()
        local dungeonID = LFDQueueFrame.type;
        LFG_SetRoleIconIncentive(LFDQueueFrameRoleButtonTank, nil);
        LFG_SetRoleIconIncentive(LFDQueueFrameRoleButtonHealer, nil);
        LFG_SetRoleIconIncentive(LFDQueueFrameRoleButtonDPS, nil);

        if ( type(dungeonID) == "number" ) then
            for i=1, LFG_ROLE_NUM_SHORTAGE_TYPES do
                local eligible, forTank, forHealer, forDamage, itemCount, money, xp = GetLFGRoleShortageRewards(dungeonID, i);
                if ( eligible and (itemCount ~= 0 or money ~= 0 or xp ~= 0) ) then    --Only show the icon if there is actually a reward.
                    if ( forTank ) then
                        LFG_SetRoleIconIncentive(LFDQueueFrameRoleButtonTank, i);
                    end
                    if ( forHealer ) then
                        LFG_SetRoleIconIncentive(LFDQueueFrameRoleButtonHealer, i);
                    end
                    if ( forDamage ) then
                        LFG_SetRoleIconIncentive(LFDQueueFrameRoleButtonDPS, i);
                    end
                end
            end
        end
    end
    function LFG_SetRoleIconIncentive(roleButton, incentiveIndex)
        InjectRoleButton(roleButton);
        if ( incentiveIndex ) then
            local tex;
            if ( incentiveIndex == LFG_ROLE_SHORTAGE_PLENTIFUL ) then
                tex = "Interface\\Icons\\INV_Misc_Coin_19";
            elseif ( incentiveIndex == LFG_ROLE_SHORTAGE_UNCOMMON ) then
                tex = "Interface\\Icons\\INV_Misc_Coin_18";
            elseif ( incentiveIndex == LFG_ROLE_SHORTAGE_RARE ) then
                tex = "Interface\\Icons\\INV_Misc_Coin_17";
            end
            SetPortraitToTexture(roleButton.incentiveIcon.texture, tex);
            roleButton.incentiveIcon:Show();
            roleButton.shortageBorder:Show();
        else
            roleButton.incentiveIcon:Hide();
            roleButton.shortageBorder:Hide();
        end
    end
    function LFGRoleIconIncentive_OnEnter(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        local role = LFG_ID_TO_ROLES[self:GetParent():GetID()];

        GameTooltip:SetText(format(LFG_CALL_TO_ARMS, _G[role]), 1, 1, 1);
        GameTooltip:AddLine(LFG_CALL_TO_ARMS_EXPLANATION, nil, nil, nil, 1);
        GameTooltip:Show();
    end

    function LFDQueueFrame_GetRoles()
        return LFDQueueFrameRoleButtonLeader.checkButton:GetChecked(),
            LFDQueueFrameRoleButtonTank.checkButton:GetChecked(),
            LFDQueueFrameRoleButtonHealer.checkButton:GetChecked(),
            LFDQueueFrameRoleButtonDPS.checkButton:GetChecked();
    end

    -- Reward Buttons
    local function InjectRewardButton(button)
        if button.shortageBorder then return; end

        button.layerFrame = CreateFrame("Frame", "$parentLayerFrame", button);
        button.layerFrame:SetAllPoints(true);

        button.shortageBorder = button.layerFrame:CreateTexture(button:GetName().."ShortageBorder", "ARTWORK");
        button.shortageBorder:SetSize(48, 48);
        button.shortageBorder:SetPoint("TOPLEFT", -6, 4);
        button.shortageBorder:SetTexture([[Interface\AddOns\ezCollections\Interface\TalentFrame\TalentFrame-Parts]]);
        button.shortageBorder:SetTexCoord(0.40625000, 0.57812500, 0.68359375, 0.76953125);

        button.roleIcon1 = CreateFrame("Frame", "$parentRoleIcon1", button, "LFGRewardsLootShortageTemplate");
        button.roleIcon1:SetPoint("LEFT", "$parent", "TOPLEFT");
        button.roleIcon1:Hide();
        button.roleIcon1:SetParent(button.layerFrame);

        button.roleIcon2 = CreateFrame("Frame", "$parentRoleIcon2", button, "LFGRewardsLootShortageTemplate");
        button.roleIcon2:SetPoint("LEFT", "$parentRoleIcon1", "RIGHT");
        button.roleIcon2:Hide();
        button.roleIcon2:SetParent(button.layerFrame);
    end

    function GetTexCoordsForRoleSmallCircle(role)
        if ( role == "TANK" ) then
            return 0, 19/64, 22/64, 41/64;
        elseif ( role == "HEALER" ) then
            return 20/64, 39/64, 1/64, 20/64;
        elseif ( role == "DAMAGER" ) then
            return 20/64, 39/64, 22/64, 41/64;
        else
            error("Unknown role: "..tostring(role));
        end
    end

    -- Queue Frame
    hooksecurefunc("LFDQueueFrameRandom_UpdateFrame", function()
        local parentName = "LFDQueueFrameRandomScrollFrameChildFrame"
        local parentFrame = _G[parentName];

        local dungeonID = LFDQueueFrame.type;

        if ( not dungeonID ) then    --We haven't gotten info on available dungeons yet.
            return;
        end

        local doneToday, moneyBase, moneyVar, experienceBase, experienceVar, numRewards = GetLFGDungeonRewards(dungeonID);

        for i = 1, numRewards do
            local frame = _G[parentName.."Item"..i];
            if frame then
                InjectRewardButton(frame);

                frame.shortageBorder:Hide();
                frame.roleIcon1:Hide();
                frame.roleIcon2:Hide();
                if frame:IsShown() then
                    local info = GetShortageRewardInfo(dungeonID, i);
                    if info and not info.IsVisualOnly then
                        local eligible, forTank, forHealer, forDamage, itemCount = GetLFGRoleShortageRewards(dungeonID, info.ShortageIndex);
                        frame.shortageBorder:Show();

                        local numRoles = (forTank and 1 or 0) + (forHealer and 1 or 0) + (forDamage and 1 or 0);

                        --Show role icons if this reward is specific to a role:
                        frame.roleIcon1:Hide();
                        frame.roleIcon2:Hide();

                        if ( numRoles > 0 and numRoles < 3 ) then    --If we give it to all 3 roles, no reason to show icons.
                            local roleIcon = frame.roleIcon1;
                            if ( forTank ) then
                                roleIcon.texture:SetTexCoord(GetTexCoordsForRoleSmallCircle("TANK"));
                                roleIcon.role = "TANK";
                                roleIcon:Show();
                                roleIcon = frame.roleIcon2;
                            end
                            if ( forHealer ) then
                                roleIcon.texture:SetTexCoord(GetTexCoordsForRoleSmallCircle("HEALER"));
                                roleIcon.role = "HEALER";
                                roleIcon:Show();
                                roleIcon = frame.roleIcon2;
                            end
                            if ( forDamage ) then
                                roleIcon.texture:SetTexCoord(GetTexCoordsForRoleSmallCircle("DAMAGER"));
                                roleIcon.role = "DAMAGER";
                                roleIcon:Show();
                                roleIcon = frame.roleIcon2;
                            end

                            if ( numRoles == 2 ) then
                                frame.roleIcon1:SetPoint("LEFT", frame, "TOPLEFT", 1, -2);
                            else
                                frame.roleIcon1:SetPoint("LEFT", frame, "TOPLEFT", 10, -2);
                            end
                        end
                    end
                end
            end
        end

        LFDQueueFrame_UpdateRoleIncentives();
    end);
    LFDQueueFrameRandomScrollFrameChildFrame:SetScript("OnShow", LFDQueueFrameRandom_UpdateFrame);

    -- Proposal Frame
    LFDDungeonReadyRewardTemplate = "LFDDungeonReadyRewardTemplate"; -- Fix blizzard bug
    function LFDDungeonReadyDialog_UpdateRewards(dungeonID)
        local doneToday, moneyBase, moneyVar, experienceBase, experienceVar, numRewards = GetLFGDungeonRewards(dungeonID);

        local numRandoms = 4 - GetNumPartyMembers();
        local moneyAmount = moneyBase + moneyVar * numRandoms;
        local experienceGained = experienceBase + experienceVar * numRandoms;

        local rewardsOffset = 0;

        if ( moneyAmount > 0 or experienceGained > 0 ) then --hasMiscReward ) then
            LFDDungeonReadyDialogReward_SetMisc(LFDDungeonReadyDialogRewardsFrameReward1);
            rewardsOffset = 1;
        end

        if ( moneyAmount == 0 and experienceGained == 0 and numRewards == 0 ) then
            LFDDungeonReadyDialogRewardsFrameLabel:Hide();
        else
            LFDDungeonReadyDialogRewardsFrameLabel:Show();
        end

        for i = 1, numRewards do
            local frameID = (i + rewardsOffset);
            local frame = _G["LFDDungeonReadyDialogRewardsFrameReward"..frameID];
            if ( not frame ) then
                frame = CreateFrame("FRAME", "LFDDungeonReadyDialogRewardsFrameReward"..frameID, LFDDungeonReadyDialogRewardsFrame, LFDDungeonReadyRewardTemplate);
                frame:SetID(frameID);
                LFD_MAX_REWARDS = frameID;
            end
            LFDDungeonReadyDialogReward_SetReward(frame, dungeonID, i)
        end

        local usedButtons = numRewards + rewardsOffset;
        --Hide the unused ones
        for i = usedButtons + 1, LFD_MAX_REWARDS do
            _G["LFDDungeonReadyDialogRewardsFrameReward"..i]:Hide();
        end

        LFDDungeonReadyDialogRewardsFrameReward1:ClearAllPoints();
        -- Use Cataclysm layout only for 3+ rewards
        if ( usedButtons > 2 ) then
            --Set up positions
            local iconOffset;
            if ( usedButtons > 2 ) then
                iconOffset = -5;
            else
                iconOffset = 0;
            end
            local area = usedButtons * LFDDungeonReadyDialogRewardsFrameReward1:GetWidth() + (usedButtons - 1) * iconOffset;

            LFDDungeonReadyDialogRewardsFrameReward1:SetPoint("LEFT", LFDDungeonReadyDialogRewardsFrame, "CENTER", -area/2, 5);
            for i = 2, usedButtons do
                _G["LFDDungeonReadyDialogRewardsFrameReward"..i]:SetPoint("LEFT", "LFDDungeonReadyDialogRewardsFrameReward"..(i - 1), "RIGHT", iconOffset, 0);
            end
        elseif ( usedButtons > 0 ) then
            --Set up positions
            local positionPerIcon = 1/(2 * usedButtons) * LFDDungeonReadyDialogRewardsFrame:GetWidth();
            local iconOffset = 2 * positionPerIcon - LFDDungeonReadyDialogRewardsFrameReward1:GetWidth();
            LFDDungeonReadyDialogRewardsFrameReward1:SetPoint("CENTER", LFDDungeonReadyDialogRewardsFrame, "LEFT", positionPerIcon, 5);
            for i = 2, usedButtons do
                _G["LFDDungeonReadyDialogRewardsFrameReward"..i]:SetPoint("LEFT", "LFDDungeonReadyDialogRewardsFrameReward"..(i - 1), "RIGHT", iconOffset, 0);
            end
        end
    end
end

function ezCollections:AddCTAShortageReward(item, ctaReward)
    ctaShortageRewards[item] = ctaReward;
    if Hook then
        Hook();
    end
end

function ezCollections:ResetCTAShortageReward()
    table.wipe(ctaShortageRewards);
end
