local g_microButtonAlertsEnabled = true;
local g_visibleMicroButtonAlerts = {};

--Micro Button alerts
function MicroButtonAlert_SetText(self, text)
	self.Text:SetText(text or "");
end

function MicroButtonAlert_OnLoad(self)
	self.Text:SetSpacing(4);
	MicroButtonAlert_SetText(self, self.label);
	function self:EvaluateAlertVisibility() end
end

function MicroButtonAlert_OnShow(self)
	self:SetHeight(self.Text:GetHeight() + 42);
	if ( self.tutorialIndex and ezCollections:GetCVarBitfield("closedInfoFrames", self.tutorialIndex) ) then
		self:Hide();
	end
end

function MicroButtonAlert_OnHide(self)
	g_visibleMicroButtonAlerts[self] = nil;

	if not g_microButtonAlertsEnabled then
		return;
	end

	-- If anything is shown, leave it in that state
	for i, priorityFrameName in ipairs(MAIN_MENU_MICRO_ALERT_PRIORITY) do
		local priorityFrame = _G[priorityFrameName];
		if priorityFrame:IsShown() then
			return;
		end
	end

	-- Nothing shown, try evaluating its visibility
	for i, priorityFrameName in ipairs(MAIN_MENU_MICRO_ALERT_PRIORITY) do
		local priorityFrame = _G[priorityFrameName];
		if priorityFrame ~= self then
			priorityFrame.MicroButton:EvaluateAlertVisibility();
			if priorityFrame:IsShown() then
				break;
			end
		end
	end
end

function MicroButtonAlert_CreateAlert(parent, tutorialIndex, text, anchorPoint, anchorRelativeTo, anchorRelativePoint, anchorOffsetX, anchorOffsetY)
	local alert = CreateFrame("Frame", nil, parent, "MicroButtonAlertTemplate");
	alert.tutorialIndex = tutorialIndex;

	alert:SetPoint(anchorPoint, anchorRelativeTo, anchorRelativePoint, anchorOffsetX, anchorOffsetY);

	MicroButtonAlert_SetText(alert, text);
	return alert;
end

MAIN_MENU_MICRO_ALERT_PRIORITY = {
	"CollectionsMicroButtonAlert",
};

function MainMenuMicroButton_ShowAlert(alert, text, tutorialIndex)
	if not g_microButtonAlertsEnabled then
		return false;
	end

	if tutorialIndex and ezCollections:GetCVarBitfield("closedInfoFrames", tutorialIndex) then
		return false;
	end

	local isHighestPriority = false;
	for i, priorityFrameName in ipairs(MAIN_MENU_MICRO_ALERT_PRIORITY) do
		local priorityFrame = _G[priorityFrameName];
		if alert == priorityFrame then
			isHighestPriority = true;
		end

		if priorityFrame:IsShown() then
			if not isHighestPriority then
				-- Higher priority is shown
				return false;
			end

			-- Lower priority alert is visible, kill it
			priorityFrame:Hide();
		end
	end
	alert.Text:SetText(text);
	alert:SetHeight(alert.Text:GetHeight()+42);
	alert.tutorialIndex = tutorialIndex;
	alert:Show();

	g_visibleMicroButtonAlerts[alert] = true;

	return alert:IsShown();
end
