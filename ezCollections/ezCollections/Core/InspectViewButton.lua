local button;
hooksecurefunc(ezCollections.AceAddon, "ADDON_LOADED", function(self, event, addon)
    if addon == "Blizzard_InspectUI" then
        if not button and not InspectFrameViewButton then
            button = CreateFrame("Button", "InspectFrameViewButton", InspectPaperDollFrame, "ezCollectionsUIPanelButtonTemplate");
            button:SetSize(0, 22);
            button:SetPoint("TOP", InspectLevelText, "BOTTOM", 0, -3);
            button:SetText(VIEW_IN_DRESSUP_FRAME);
            button:SetWidth(30 + button:GetFontString():GetStringWidth());
            button:SetScript("OnClick", function()
                PlaySound("igMainMenuOptionCheckBoxOn");
                DressUpSources(C_TransmogCollection.GetInspectSources());
            end);

            if ElvUI then
                local E = unpack(ElvUI);
                local S = E:GetModule("Skins");
                if E.private.skins.blizzard.enable and E.private.skins.blizzard.inspect then
                    S:HandleButton(button);
                end
            end
        end
    elseif addon == "Examiner" then
        if not button and not ExaminerViewButton then
            button = CreateFrame("Button", "ExaminerViewButton", Examiner.model, "ezCollectionsUIPanelButtonTemplate");
            button:SetSize(0, 22);
            button:SetPoint("TOP", 0, 2);
            button:SetText(VIEW_IN_DRESSUP_FRAME);
            button:SetWidth(30 + button:GetFontString():GetStringWidth());
            button:SetScript("OnClick", function()
                PlaySound("igMainMenuOptionCheckBoxOn");
                DressUpSources(C_TransmogCollection.GetInspectSources());
            end);
            button:SetScript("OnUpdate", function()
                local enable = Examiner.unit == "target" and UnitIsPlayer("target") and Examiner_Config and not Examiner_Config.activePage;
                button:SetAlpha(enable and 1 or 0);
                button:EnableMouse(enable);
            end);
        end
    end
end);
