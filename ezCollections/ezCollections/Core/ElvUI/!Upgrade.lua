ezCollections:MergeHook("ezCollectionsElvUIHook", function()

local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule('Skins')

local StripTexturesBlizzFrames = {
	'Inset',
	'inset',
	'InsetFrame',
	'LeftInset',
	'RightInset',
	'NineSlice',
	'BG',
	'border',
	'Border',
	'BorderFrame',
	'bottomInset',
	'BottomInset',
	'bgLeft',
	'bgRight',
	'FilligreeOverlay',
	'PortraitOverlay',
	'ArtOverlayFrame',
	'Portrait',
	'portrait',
	'ScrollFrameBorder',
}
local function addapi(object)
	local mt = getmetatable(object).__index;
	function mt.StripTextures_ezCollections(object, kill, alpha)
		object:StripTextures();
		if not object:IsObjectType("Texture") then
			local FrameName = object.GetName and object:GetName()
			for _, Blizzard in pairs(StripTexturesBlizzFrames) do
				local BlizzFrame = object[Blizzard] or (FrameName and _G[FrameName..Blizzard])
				if BlizzFrame and BlizzFrame.StripTextures and BlizzFrame.StripTextures_ezCollections then
					BlizzFrame:StripTextures_ezCollections(kill, alpha)
				end
			end
		end
	end
end
local handled = {["Frame"] = true}
local object = CreateFrame("Frame")
addapi(object)
addapi(object:CreateTexture())
addapi(object:CreateFontString())

object = EnumerateFrames()
while object do
	if not handled[object:GetObjectType()] then
		addapi(object)
		handled[object:GetObjectType()] = true
	end

	object = EnumerateFrames(object)
end

local regions = {
	'Left',
	'Middle',
	'Right',
	'Mid',
	'LeftDisabled',
	'MiddleDisabled',
	'RightDisabled',
	'TopLeft',
	'TopRight',
	'BottomLeft',
	'BottomRight',
	'TopMiddle',
	'MiddleLeft',
	'MiddleRight',
	'BottomMiddle',
	'MiddleMiddle',
	'TabSpacer',
	'TabSpacer1',
	'TabSpacer2',
	'_RightSeparator',
	'_LeftSeparator',
	'Cover',
	'Border',
	'Background',
	'TopTex',
	'TopLeftTex',
	'TopRightTex',
	'LeftTex',
	'BottomTex',
	'BottomLeftTex',
	'BottomRightTex',
	'RightTex',
	'MiddleTex',
	'Center'
}
function S:HandleButton_ezCollections(button, ...)
	S:HandleButton(button, ...);
	local frame, name, kill, zero = button, nil, nil, true;
	if not name then name = frame.GetName and frame:GetName() end
	for _, area in pairs(regions) do
		local object = (name and _G[name..area]) or frame[area]
		if object then
			if kill then
				object:Kill()
			elseif zero then
				object:SetAlpha(0)
			else
				object:Hide()
			end
		end
	end
end

function S:HandleInsetFrame_ezCollections(frame)
	assert(frame, 'doesnt exist!')

	if frame.InsetBorderTop then frame.InsetBorderTop:Hide() end
	if frame.InsetBorderTopLeft then frame.InsetBorderTopLeft:Hide() end
	if frame.InsetBorderTopRight then frame.InsetBorderTopRight:Hide() end

	if frame.InsetBorderBottom then frame.InsetBorderBottom:Hide() end
	if frame.InsetBorderBottomLeft then frame.InsetBorderBottomLeft:Hide() end
	if frame.InsetBorderBottomRight then frame.InsetBorderBottomRight:Hide() end

	if frame.InsetBorderLeft then frame.InsetBorderLeft:Hide() end
	if frame.InsetBorderRight then frame.InsetBorderRight:Hide() end

	if frame.Bg then frame.Bg:Hide() end
end

function S:HandlePortraitFrame_ezCollections(frame, createBackdrop)
	assert(frame, 'doesnt exist!')

	local name = frame and frame.GetName and frame:GetName()
	local insetFrame = name and _G[name..'Inset'] or frame.Inset
	local portraitFrame = name and _G[name..'Portrait'] or frame.Portrait or frame.portrait
	local portraitFrameOverlay = name and _G[name..'PortraitOverlay'] or frame.PortraitOverlay
	local artFrameOverlay = name and _G[name..'ArtOverlayFrame'] or frame.ArtOverlayFrame

	frame:StripTextures_ezCollections()

	if portraitFrame then portraitFrame:SetAlpha(0) end
	if portraitFrameOverlay then portraitFrameOverlay:SetAlpha(0) end
	if artFrameOverlay then artFrameOverlay:SetAlpha(0) end

	if insetFrame then
		S:HandleInsetFrame_ezCollections(insetFrame)
	end

	if frame.CloseButton then
		S:HandleCloseButton(frame.CloseButton)
	end

	if createBackdrop then
		frame:CreateBackdrop('Transparent', nil, nil, nil, nil, nil, nil, true)
		frame.backdrop:Point("TOPLEFT", -4, 2);
		frame.backdrop:Point("BOTTOMRIGHT", 4, 0);
	else
		frame:SetTemplate('Transparent')
	end
end

do
	local btns = {MaximizeButton = 'up', MinimizeButton = 'down'}

	local function buttonOnEnter(btn)
		local r,g,b = unpack(E.media.rgbvaluecolor)
		btn:GetNormalTexture():SetVertexColor(r,g,b)
		btn:GetPushedTexture():SetVertexColor(r,g,b)
	end
	local function buttonOnLeave(btn)
		btn:GetNormalTexture():SetVertexColor(1, 1, 1)
		btn:GetPushedTexture():SetVertexColor(1, 1, 1)
	end

	function S:HandleMaxMinFrame_ezCollections(frame)
		assert(frame, 'does not exist.')

		if frame.isSkinned then return end

		frame:StripTextures(true)

		for name, direction in pairs(btns) do
			local button = frame[name]
			if button then
				button:Size(14, 14)
				button:ClearAllPoints()
				button:Point('CENTER')
				button:SetHitRectInsets(1, 1, 1, 1)
				button:GetHighlightTexture():Kill()

				button:SetScript('OnEnter', buttonOnEnter)
				button:SetScript('OnLeave', buttonOnLeave)

				button:SetNormalTexture(E.Media.Textures.ArrowUp)
				button:GetNormalTexture():SetRotation(S.ArrowRotation[direction])

				button:SetPushedTexture(E.Media.Textures.ArrowUp)
				button:GetPushedTexture():SetRotation(S.ArrowRotation[direction])
			end
		end

		frame.isSkinned = true
	end
end

end);
ezCollections:MergeHook("ezCollectionsElvUIEnhancedHook", function()

local E, L, V, P, G = unpack(ElvUI);
local S = E:GetModule("Skins");

local MF = E:GetModule("Enhanced_ModelFrames", true) or E:GetModule("HookModelFrames", true);
if MF then
	function MF:ModelWithControls_ezCollections(model)
		local parent = model.controlFrame:GetName();
		local zoomInButton = _G[parent.."ZoomInButton"];
		local zoomOutButton = _G[parent.."ZoomOutButton"];
		local panButton = _G[parent.."PanButton"];
		local rotateLeftButton = _G[parent.."RotateLeftButton"];
		local rotateRightButton = _G[parent.."RotateRightButton"];
		local rotateResetButton = _G[parent.."RotateResetButton"];
		if E.private.skins.blizzard.enable then
			model.controlFrame:SetSize(123, 23)
			model.controlFrame:StripTextures();
			for _, button in ipairs({ zoomInButton, zoomOutButton, panButton, rotateLeftButton, rotateRightButton, rotateResetButton }) do
				button.bg:SetTexture(nil);
				button.highlight:SetTexture(nil);
			end

			S:HandleButton(zoomInButton)

			S:HandleButton(zoomOutButton)
			zoomOutButton:SetPoint("LEFT", "$parentZoomInButton", "RIGHT", 2, 0)

			S:HandleButton(panButton)
			panButton:SetPoint("LEFT", "$parentZoomOutButton", "RIGHT", 2, 0)

			S:HandleButton(rotateLeftButton)
			rotateLeftButton:SetPoint("LEFT", "$parentPanButton", "RIGHT", 2, 0)

			S:HandleButton(rotateRightButton)
			rotateRightButton:SetPoint("LEFT", "$parentRotateLeftButton", "RIGHT", 2, 0)

			S:HandleButton(rotateResetButton)
			rotateResetButton:SetPoint("LEFT", "$parentRotateRightButton", "RIGHT", 2, 0)
		else
			model.controlFrame:SetSize(112, 23)
			zoomInButton:SetPoint("LEFT", "$parent", "LEFT", 2, 0)
			zoomOutButton:SetPoint("LEFT", "$parentZoomInButton", "RIGHT", 0, 0)
			panButton:SetPoint("LEFT", "$parentZoomOutButton", "RIGHT", 0, 0)
			rotateLeftButton:SetPoint("LEFT", "$parentPanButton", "RIGHT", 0, 0)
			rotateRightButton:SetPoint("LEFT", "$parentRotateLeftButton", "RIGHT", 0, 0)
			rotateResetButton:SetPoint("LEFT", "$parentRotateRightButton", "RIGHT", 0, 0)
		end
	end
end

end);
