ezCollections:MergeHook("ezCollectionsElvUIHook", function()

local E, L, V, P, G = unpack(ElvUI);
local AB = E:GetModule("ActionBars")

hooksecurefunc(AB, "UpdateMicroButtonsParent", function(self)
	CollectionsMicroButton:SetParent(ElvUI_MicroBar);
	AB:UpdateMicroPositionDimensions()
end);

hooksecurefunc(AB, "UpdateMicroPositionDimensions", function(self)
	if not ElvUI_MicroBar then return end
	if not AB.ezCollectionsMicroButtons then return end
	local MICRO_BUTTONS = AB.ezCollectionsMicroButtons;

	local numRows = 1
	local prevButton = ElvUI_MicroBar
	local offset = E:Scale(E.PixelMode and 1 or 3)
	local spacing = E:Scale(offset + self.db.microbar.buttonSpacing)

	for i = 1, #MICRO_BUTTONS do
		local button = MICRO_BUTTONS[i]
		local lastColumnButton = i - self.db.microbar.buttonsPerRow
		lastColumnButton = MICRO_BUTTONS[lastColumnButton];

		button:Size(self.db.microbar.buttonSize, self.db.microbar.buttonSize * 1.4)
		button:ClearAllPoints()
		button:Show();

		if prevButton == ElvUI_MicroBar then
			button:Point("TOPLEFT", prevButton, "TOPLEFT", offset, -offset)
		elseif (i - 1) % self.db.microbar.buttonsPerRow == 0 then
			button:Point("TOP", lastColumnButton, "BOTTOM", 0, -spacing)
			numRows = numRows + 1
		else
			button:Point("LEFT", prevButton, "RIGHT", spacing, 0)
		end

		prevButton = button
	end
end);

hooksecurefunc(AB, "SetupMicroBar", function(self)
	self:HandleMicroButton(CollectionsMicroButton);
end);

end);
ezCollections:MergeHook("ezCollectionsElvUIConfigHook", function()

local E, L, V, P, G = unpack(ElvUI);

E.Options.args.actionbar.args.microbar.args.buttonsPerRow.max = E.Options.args.actionbar.args.microbar.args.buttonsPerRow.max + 1;

end);
