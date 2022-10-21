-- Fix gossips with code entry prompt not correctly submitting said code if closed by pressing Enter
do
    StaticPopupDialogs["GOSSIP_ENTER_CODE"].EditBoxOnEnterPressed = function(self, data)
        local parent = self:GetParent();
        SelectGossipOption(data, parent.editBox:GetText(), true);
        parent:Hide();
    end
end

C_Timer.After(0, function() -- Delay, because there may be a newer version of AceGUI loaded later (e.g. version 41 in Bunny67's WeakAuras port)
    local registry = LibStub("AceGUI-3.0").WidgetRegistry;
    local function Patch(type, func)
        local old = registry[type];
        if old then
            registry[type] = function()
                local self = old();
                func(self);
                return self;
            end
        end
    end

    -- Fix AceGUI's Dropdown widgets having their text on the same ARTWORK drawlayer as the rest of the widget's textures, leading to embedded textures in the text (|T...|t) to sometimes fall behind the widget
    -- This issue is not exclusive to AceGUI and happens to any control that inherits from UIDropDownMenuTemplate, but in my case I need a fix specifically for AceConfig/AceGUI
    Patch("Dropdown", function(self)
        self.text:SetDrawLayer("OVERLAY");
    end);

    -- Fix AceGUI bug introduced in backported version 41 that caused checkbox inline descriptions text to cut off early
    Patch("CheckBox", function(self)
        hooksecurefunc(self, "SetDescription", function(self, desc)
            if self.desc then
                self.desc:ClearAllPoints();
                self.desc:SetPoint("TOPLEFT", self.checkbg, "TOPRIGHT", 5, -21);
                self.desc:SetWidth(self.frame.width - 30);
                -- self.desc:SetPoint("RIGHT", self.frame, "RIGHT", -30, 0); -- Patched out call
                if self.desc:GetText() and self.desc:GetText() ~= "" then
                    self:SetHeight(28 + self.desc:GetStringHeight());
                end
            end
        end);
    end);
end);

-- Patch XLoot to support LOOT_SLOT_CHANGED and, while we're at it, fix a visual issue with border color resetting on loot list update
C_Timer.After(0, function() -- Delay so XLoot can load
    if not XLoot then return; end
    if XLoot.ezwowLootSlotChangedPatch then return; end -- Already patched
    local version = GetAddOnMetadata("XLoot", "Version");
    if version == "0.91.1-ezwow" then return; end -- Already patched
    if version ~= "0.91.1" and version ~= "0.91" then return; end -- Not the latest 3.3.5 version, might be incompatible with patch

    XLoot.ezwowLootSlotChangedPatch = true;

    -- Patch LOOT_SLOT_CHANGED
    local function OnEnable(self)
        LootFrame:UnregisterEvent("LOOT_SLOT_CHANGED");
        self:RegisterEvent("LOOT_SLOT_CHANGED", "OnChange");
    end
    hooksecurefunc(XLoot, "OnEnable", OnEnable);
    hooksecurefunc(XLoot, "OnDisable", function(self)
        LootFrame:RegisterEvent("LOOT_SLOT_CHANGED");
    end);
    function XLoot:OnChange()
        self.refreshing = true;
        self:Update();
    end
    local AceAddon = LibStub("AceAddon-2.0");
    if AceAddon and AceAddon.addonsEnabled and AceAddon.addonsEnabled[XLoot] then
        OnEnable(XLoot);
    end

    -- Patch border color resetting on update
    XLoot.oldUpdate = XLoot.Update;
    function XLoot:Update()
        self.ezwowLootSlotChangedPatchWasVisible = self.visible;
        self.visible = false;
        self:oldUpdate();
        self.ezwowLootSlotChangedPatchWasVisible = nil;
    end
    hooksecurefunc(XLoot.frame, "SetBackdropColor", function()
        local wasVisible = XLoot.ezwowLootSlotChangedPatchWasVisible;
        if wasVisible ~= nil then
            XLoot.visible = wasVisible;
        end
    end);
end);

-- Fix InterfaceOptionsFrame_OpenToCategory not actually opening the category (and not even scrolling to it)
-- Taken from addon BlizzBugsSuck (https://www.wowinterface.com/downloads/info17002-BlizzBugsSuck.html) and edited to not be global
do
	local function get_panel_name(panel)
		local tp = type(panel)
		local cat = INTERFACEOPTIONS_ADDONCATEGORIES
		if tp == "string" then
			for i = 1, #cat do
				local p = cat[i]
				if p.name == panel then
					if p.parent then
						return get_panel_name(p.parent)
					else
						return panel
					end
				end
			end
		elseif tp == "table" then
			for i = 1, #cat do
				local p = cat[i]
				if p == panel then
					if p.parent then
						return get_panel_name(p.parent)
					else
						return panel.name
					end
				end
			end
		end
	end

	local doNotRun;
	--[[local]] function InterfaceOptionsFrame_OpenToCategory_Fix(panel)
		if doNotRun or InCombatLockdown() then return end
		local panelName = get_panel_name(panel)
		if not panelName then return end -- if its not part of our list return early
		local noncollapsedHeaders = {}
		local shownpanels = 0
		local mypanel
		local t = {}
		local cat = INTERFACEOPTIONS_ADDONCATEGORIES
		for i = 1, #cat do
			local panel = cat[i]
			if not panel.parent or noncollapsedHeaders[panel.parent] then
				if panel.name == panelName then
					panel.collapsed = true
					t.element = panel
					InterfaceOptionsListButton_ToggleSubCategories(t)
					noncollapsedHeaders[panel.name] = true
					mypanel = shownpanels + 1
				end
				if not panel.collapsed then
					noncollapsedHeaders[panel.name] = true
				end
				shownpanels = shownpanels + 1
			end
		end
		local Smin, Smax = InterfaceOptionsFrameAddOnsListScrollBar:GetMinMaxValues()
		if shownpanels > 15 and Smin < Smax then
			local val = (Smax/(shownpanels-15))*(mypanel-2)
			InterfaceOptionsFrameAddOnsListScrollBar:SetValue(val)
		end
		doNotRun = true
		InterfaceOptionsFrame_OpenToCategory(panel)
		doNotRun = false
	end

	--hooksecurefunc("InterfaceOptionsFrame_OpenToCategory", InterfaceOptionsFrame_OpenToCategory_Fix)
end