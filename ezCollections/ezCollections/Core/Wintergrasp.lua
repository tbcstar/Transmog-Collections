local L = ezCollections.L;

function ezCollections:JoinWintergrasp()
    self:SendAddonCommand(".isengard wg queue");
end

local button;
local backup_PVPBATTLEGROUND_WINTERGRASPTIMER_CAN_QUEUE = PVPBATTLEGROUND_WINTERGRASPTIMER_CAN_QUEUE;

local function OnEnable() end
local function OnDisable() end

local skinned = false;
local function ElvUIHook()
    if not button or not ElvUI or skinned then return; end
    local E = unpack(ElvUI);
    local S = E:GetModule("Skins");
    if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.pvp then return end
    button:GetHighlightTexture():SetAlpha(1);
    button.highlight:StripTextures();
    S:HandleButton_ezCollections(button);
    button:HookScript("OnEnable", function(self)
        self:SetTemplate("Default", true);
    end);
    button:HookScript("OnDisable", function(self)
        self:SetTemplate("NoBackdrop", true);
    end);
    if GetAddOnMetadata("ElvUI", "Version") >= "6.07" then
        button:SetPoint("RIGHT", PVPBattlegroundFrame, "TOPRIGHT", -42+2, -58);
        OnDisable = function()
            WintergraspTimer:SetPoint("RIGHT", PVPBattlegroundFrame, "TOPRIGHT", -42, -58);
        end
    end
    skinned = true;
    ElvUIHook = function() end
    return true;
end
ezCollections:MergeHook("ezCollectionsElvUIHook", function()
    local E = unpack(ElvUI);
    local S = E:GetModule("Skins");
    S:AddCallback("Skin_PvP_ezCollections", ElvUIHook);
end);

function ezCollections:SetWintergraspButton(enabled)
    if enabled then
        if not button then
            button = CreateFrame("Button", nil, PVPBattlegroundFrame, "UIMenuButtonStretchTemplate");
            button:SetPoint("RIGHT", PVPBattlegroundFrame, "TOPRIGHT", -40+2, -55);
            button:HookScript("OnClick", function(self)
                PlaySound("gsTitleOptionOK");
                ezCollections:JoinWintergrasp();
            end);
            button:HookScript("OnMouseDown", function(self)
                if self:IsEnabled() == 1 then
                    WintergraspTimer:SetPoint("TOPRIGHT", self, "TOPRIGHT", -2+1, -2-1);
                end
            end);
            button:HookScript("OnMouseUp", function(self)
                WintergraspTimer:SetPoint("TOPRIGHT", self, "TOPRIGHT", -2, -2);
            end);
            button:HookScript("OnDisable", function(self)
                self:SetTextures(nil);
            end);
            button:HookScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 5-2, 40+2);
                GameTooltip:SetText(WintergraspTimer.tooltip);
                self.highlight:Show();
            end);
            button:HookScript("OnLeave", function(self)
                GameTooltip:Hide();
                self.highlight:Hide();
            end);
            button:HookScript("OnUpdate", function(self)
                self:SetWidth(2+5+WintergraspTimer.text:GetStringWidth()+3+WintergraspTimer:GetWidth()+2);
                self:SetHeight(2+WintergraspTimer:GetHeight()+2);
                if WintergraspTimer:IsShown() and CanQueueForWintergrasp() then
                    self:Enable();
                    WintergraspTimer:EnableMouse(false);
                else
                    self:Disable();
                    WintergraspTimer:EnableMouse(true);
                end
            end);
            button:GetHighlightTexture():SetAlpha(0);
            button.highlight = CreateFrame("Frame", nil, button);
            button.highlight:SetAllPoints(true);
            button.highlight:Hide();
            local texture = button.highlight:CreateTexture(nil, "ARTWORK");
            texture:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-Tab-Highlight]]);
            texture:SetBlendMode("ADD");
            texture:SetTexCoord(0.02, 0.98, 0.85, 0.5);
            texture:SetPoint("TOPLEFT");
            texture:SetPoint("BOTTOMRIGHT", button.highlight, "RIGHT");
            texture = button.highlight:CreateTexture(nil, "ARTWORK");
            texture:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-Tab-Highlight]]);
            texture:SetBlendMode("ADD");
            texture:SetTexCoord(0.02, 0.98, 0.5, 0.85);
            texture:SetPoint("TOPLEFT", button.highlight, "LEFT");
            texture:SetPoint("BOTTOMRIGHT");
            ElvUIHook();
        end

        PVPBATTLEGROUND_WINTERGRASPTIMER_CAN_QUEUE = L["Misc.WintergraspButton.CanQueue"];
        WintergraspTimer:SetParent(button);
        WintergraspTimer:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -2);
        WintergraspTimer:EnableMouse(true);
        WintergraspTimer.text:SetText(nil);
        WintergraspTimer.text:SetSpacing(0);
        WintergraspTimer.canQueue = nil;
        button:Show();
        WintergraspTimer:SetFrameLevel(button:GetFrameLevel() + 1);
        button.highlight:SetFrameLevel(WintergraspTimer:GetFrameLevel() + 1);
        OnEnable();
    else
        PVPBATTLEGROUND_WINTERGRASPTIMER_CAN_QUEUE = backup_PVPBATTLEGROUND_WINTERGRASPTIMER_CAN_QUEUE;
        WintergraspTimer:SetParent(PVPBattlegroundFrame);
        WintergraspTimer:SetPoint("RIGHT", PVPBattlegroundFrame, "TOPRIGHT", -40, -55);
        WintergraspTimer:EnableMouse(true);
        WintergraspTimer.text:SetText(nil);
        WintergraspTimer.text:SetSpacing(4);
        WintergraspTimer.canQueue = nil;
        if button then
            button:Hide();
        end
        OnDisable();
    end
end
