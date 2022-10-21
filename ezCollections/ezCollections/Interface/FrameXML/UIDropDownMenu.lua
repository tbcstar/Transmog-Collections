function UIDropDownMenu_AddSeparator(level)
	local separatorInfo = {
		hasArrow = false;
		dist = 0;
		isTitle = true;
		isUninteractable = true;
		notCheckable = true;
		iconOnly = true;
		icon = [[Interface\AddOns\ezCollections\Interface\Common\UI-TooltipDivider-Transparent]];
		tCoordLeft = 0;
		tCoordRight = 1;
		tCoordTop = 0;
		tCoordBottom = 1;
		tSizeX = 0;
		tSizeY = 8;
		tFitDropDownSizeX = true;
		iconInfo = {
			tCoordLeft = 0,
			tCoordRight = 1,
			tCoordTop = 0,
			tCoordBottom = 1,
			tSizeX = 0,
			tSizeY = 8,
			tFitDropDownSizeX = true
		},
		text = "", -- Custom
	};

	UIDropDownMenu_AddButton(separatorInfo, level);
end

function UIDropDownMenu_AddSpace(level)
	local spaceInfo = {
		hasArrow = false,
		isTitle = true,
		notCheckable = true,
	};

	UIDropDownMenu_AddButton(spaceInfo, level);
end

function UIDropDownMenu_Refresh2(frame, useValue, dropdownLevel)
	local button, checked, checkImage, normalText, width;
	local maxWidth = 0;
	if ( not dropdownLevel ) then
		dropdownLevel = UIDROPDOWNMENU_MENU_LEVEL;
	end
	
	-- Just redraws the existing menu
	for i=1, UIDROPDOWNMENU_MAXBUTTONS do
		button = _G["DropDownList"..dropdownLevel.."Button"..i];
		checked = nil;
		-- See if checked or not
		if ( UIDropDownMenu_GetSelectedName(frame) ) then
			if ( button:GetText() == UIDropDownMenu_GetSelectedName(frame) ) then
				checked = 1;
			end
		elseif ( UIDropDownMenu_GetSelectedID(frame) ) then
			if ( button:GetID() == UIDropDownMenu_GetSelectedID(frame) ) then
				checked = 1;
			end
		elseif ( UIDropDownMenu_GetSelectedValue(frame) ) then
			if ( button.value == UIDropDownMenu_GetSelectedValue(frame) ) then
				checked = 1;
			end
		end
		if (button.checked and type(button.checked) == "function") then
			checked = button.checked(button);
		end

		-- If checked show check image
		checkImage = _G["DropDownList"..dropdownLevel.."Button"..i.."Check"];
		if ( checked ) then
			if ( useValue ) then
				UIDropDownMenu_SetText(frame, button.value);
			else
				UIDropDownMenu_SetText(frame, button:GetText());
			end
			button:LockHighlight();
			checkImage:Show();
		else
			button:UnlockHighlight();
			checkImage:Hide();
		end

		if ( button:IsShown() ) then
			normalText = _G[button:GetName().."NormalText"];
			-- Determine the maximum width of a button
			width = normalText:GetWidth() + 40;
			-- Add padding if has and expand arrow or color swatch
			if ( button.hasArrow or button.hasColorSwatch ) then
				width = width + 10;
			end
			if ( button.notCheckable ) then
				width = width - 30;
			end
			if ( button.padding ) then
				width = width + button.padding;
			end
			if ( width > maxWidth ) then
				maxWidth = width;
			end
		end
	end
	for i=1, UIDROPDOWNMENU_MAXBUTTONS do
		button = _G["DropDownList"..dropdownLevel.."Button"..i];
		button:SetWidth(maxWidth);
	end
	_G["DropDownList"..dropdownLevel]:SetWidth(maxWidth+25);
end

hooksecurefunc("UIDropDownMenu_AddButton", function(info, level)
	level = level or 1;
	if info.text and info.icon then
		local listFrame = _G["DropDownList"..level];
		local button = _G[listFrame:GetName().."Button"..listFrame.numButtons];
		local icon = _G[button:GetName().."Icon"];
		icon:ClearAllPoints();
		if info.iconOnly then
			icon:SetPoint("LEFT");
		else
			icon:SetPoint("RIGHT", info.iconXOffset or 0, 0);
		end
		if info.tFitDropDownSizeX then
			icon:SetPoint("RIGHT", -5, 0);
		end
		if info.tSizeX then
			icon:SetWidth(info.tSizeX);
		else
			icon:SetWidth(16);
		end
		if info.tSizeY then
			icon:SetHeight(info.tSizeY);
		else
			icon:SetHeight(16);
		end
	end
end);
