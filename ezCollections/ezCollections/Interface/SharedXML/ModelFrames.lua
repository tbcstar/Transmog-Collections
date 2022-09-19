MODELFRAME_DRAG_ROTATION_CONSTANT = 0.010;
MODELFRAME_MAX_ZOOM = 0.7;
MODELFRAME_MIN_ZOOM = 0.0;
MODELFRAME_ZOOM_STEP = 0.15;
MODELFRAME_DEFAULT_ROTATION = 0.61;
MODELFRAME_MAX_PLAYER_ZOOM = 0.8;

local ModelSettings = {
	["HumanMale"     ] = { panMaxLeft = -0.4, panMaxRight = 0.4, panMaxTop = 0.70, panMaxBottom = -0.75, panValue = 38, zoomMultiplier = 3.0 },
	["HumanFemale"   ] = { panMaxLeft = -0.3, panMaxRight = 0.3, panMaxTop = 0.70, panMaxBottom = -0.65, panValue = 45, zoomMultiplier = 2.4, minZoom = -0.1 },
	["OrcMale"       ] = { panMaxLeft = -0.7, panMaxRight = 0.8, panMaxTop = 0.75, panMaxBottom = -0.60, panValue = 30, zoomMultiplier = 3.0 },
	["OrcFemale"     ] = { panMaxLeft = -0.4, panMaxRight = 0.3, panMaxTop = 0.80, panMaxBottom = -0.60, panValue = 37, zoomMultiplier = 3.0 },
	["DwarfMale"     ] = { panMaxLeft = -0.4, panMaxRight = 0.6, panMaxTop = 0.45, panMaxBottom = -0.60, panValue = 44, zoomMultiplier = 3.6 },
	["DwarfMaleC"    ] = { panMaxLeft = -0.4, panMaxRight = 0.6, panMaxTop = 0.80, panMaxBottom = -0.25, panValue = 47, zoomMultiplier = 2.2 },
	["DwarfFemale"   ] = { panMaxLeft = -0.3, panMaxRight = 0.3, panMaxTop = 0.70, panMaxBottom = -0.35, panValue = 47, zoomMultiplier = 2.0 },
	["NightElfMale"  ] = { panMaxLeft = -0.5, panMaxRight = 0.5, panMaxTop = 0.85, panMaxBottom = -0.85, panValue = 30, zoomMultiplier = 4.2 },
	["NightElfFemale"] = { panMaxLeft = -0.4, panMaxRight = 0.4, panMaxTop = 0.90, panMaxBottom = -0.75, panValue = 33, zoomMultiplier = 4.0 },
	["ScourgeMale"   ] = { panMaxLeft = -0.4, panMaxRight = 0.4, panMaxTop = 0.60, panMaxBottom = -0.65, panValue = 35, zoomMultiplier = 2.7 },
	["ScourgeFemale" ] = { panMaxLeft = -0.3, panMaxRight = 0.4, panMaxTop = 0.75, panMaxBottom = -0.55, panValue = 36, zoomMultiplier = 3.8 },
	["ScourgeFemaleC"] = { panMaxLeft = -0.3, panMaxRight = 0.4, panMaxTop = 0.70, panMaxBottom = -0.60, panValue = 36, zoomMultiplier = 2.8 },
	["TaurenMale"    ] = { panMaxLeft = -0.7, panMaxRight = 0.9, panMaxTop = 0.75, panMaxBottom = -0.50, panValue = 31, zoomMultiplier = 4.0 },
	["TaurenMaleC"   ] = { panMaxLeft = -0.7, panMaxRight = 0.9, panMaxTop = 0.75, panMaxBottom = -0.50, panValue = 31, zoomMultiplier = 3.0 },
	["TaurenFemale"  ] = { panMaxLeft = -0.5, panMaxRight = 0.6, panMaxTop = 1.00, panMaxBottom = -0.30, panValue = 32, zoomMultiplier = 3.0 },
	["GnomeMale"     ] = { panMaxLeft = -0.3, panMaxRight = 0.3, panMaxTop = 0.40, panMaxBottom = -0.16, panValue = 52, zoomMultiplier = 1.8 },
	["GnomeFemale"   ] = { panMaxLeft = -0.3, panMaxRight = 0.3, panMaxTop = 0.40, panMaxBottom = -0.15, panValue = 60, zoomMultiplier = 1.5 },
	["TrollMale"     ] = { panMaxLeft = -0.5, panMaxRight = 0.6, panMaxTop = 1.05, panMaxBottom = -0.45, panValue = 27, zoomMultiplier = 3.7 },
	["TrollFemale"   ] = { panMaxLeft = -0.4, panMaxRight = 0.4, panMaxTop = 1.10, panMaxBottom = -0.60, panValue = 31, zoomMultiplier = 3.8 },
	["BloodElfMale"  ] = { panMaxLeft = -0.5, panMaxRight = 0.4, panMaxTop = 0.65, panMaxBottom = -0.80, panValue = 36, zoomMultiplier = 3.7 },
	["BloodElfFemale"] = { panMaxLeft = -0.3, panMaxRight = 0.2, panMaxTop = 0.65, panMaxBottom = -0.63, panValue = 38, zoomMultiplier = 3.0 },
	["DraeneiMale"   ] = { panMaxLeft = -0.6, panMaxRight = 0.6, panMaxTop = 0.95, panMaxBottom = -0.80, panValue = 28, zoomMultiplier = 4.5 },
	["DraeneiMaleC"  ] = { panMaxLeft = -0.6, panMaxRight = 0.6, panMaxTop = 1.40, panMaxBottom = -0.45, panValue = 28, zoomMultiplier = 4.2 },
	["DraeneiFemale" ] = { panMaxLeft = -0.3, panMaxRight = 0.3, panMaxTop = 0.80, panMaxBottom = -0.85, panValue = 31, zoomMultiplier = 3.8 },
};
local function SelectSettings(model)
	local playerRaceSex = select(2, UnitRace("player"));
	if ( UnitSex("player") == 2 ) then
		playerRaceSex = playerRaceSex.."Male";
	else
		playerRaceSex = playerRaceSex.."Female";
	end
	model.cameraOption = ezCollections and ezCollections.Config and ezCollections.Config.Wardrobe.CameraOption;
	if model.cameraOption == "Classic" and ModelSettings[playerRaceSex.."C"] then
		return ModelSettings[playerRaceSex.."C"];
	end
	return ModelSettings[playerRaceSex];
end

-- Generic model rotation functions
function Model_OnLoad(self, maxZoom, minZoom, defaultRotation, onMouseUp)
	-- set up data
	self.maxZoom = maxZoom or MODELFRAME_MAX_ZOOM;
	self.minZoom = minZoom or MODELFRAME_MIN_ZOOM;
	self.defaultRotation = defaultRotation or MODELFRAME_DEFAULT_ROTATION;
	self.onMouseUpFunc = onMouseUp or Model_OnMouseUp;

	self.rotation = self.defaultRotation;
	self:SetRotation(self.rotation);
	self:RegisterEvent("UI_SCALE_CHANGED");
	self:RegisterEvent("DISPLAY_SIZE_CHANGED");

	self.settings = SelectSettings(self);
	self.portraitZoomMultiplier = self.settings.zoomMultiplier;
	self.minZoom = self.settings.minZoom or self.minZoom;
	function self:SetPortraitZoom(zoomLevel)
		local x, y, z = self:GetPosition();
		self:SetPosition(zoomLevel * self.portraitZoomMultiplier * self:GetModelScale(), y, z);
	end
	self:SetPortraitZoom(self.minZoom);
end

function Model_OnHide(self)
	if ( self.panning ) then
		Model_StopPanning(self);
	end
	self.mouseDown = false;
	self.controlFrame:Hide();
end

function Model_OnEvent(self, event, ...)
	if self.RefreshCamera then
		self:RefreshCamera();
	end
end

function Model_OnMouseDown(model, button)
	if ( not button or button == "LeftButton" ) then
		model.mouseDown = true;
		model.rotationCursorStart = GetCursorPosition();
	end
end

function Model_OnMouseUp(model, button)
	if ( not button or button == "LeftButton" ) then
		model.mouseDown = false;
	end
end

function Model_OnMouseWheel(self, delta, maxZoom, minZoom)
	maxZoom = maxZoom or self.maxZoom;
	minZoom = minZoom or self.minZoom;
	local zoomLevel = self.zoomLevel or minZoom;
	zoomLevel = zoomLevel + delta * MODELFRAME_ZOOM_STEP * ezCollections.Config.Wardrobe.CameraZoomSpeed;
	zoomLevel = min(zoomLevel, maxZoom);
	zoomLevel = max(zoomLevel, minZoom);
	if not ezCollections.Config.Wardrobe.CameraZoomSmooth then
		self:SetPortraitZoom(zoomLevel);
	end
	self.zoomLevel = zoomLevel;
end

function Model_OnUpdate(self, elapsedTime, rotationsPerSecond)
	if ( not rotationsPerSecond ) then
		rotationsPerSecond = ROTATIONS_PER_SECOND;
	end

	if ezCollections.Config.Wardrobe.CameraOption ~= self.cameraOption then
		self.settings = SelectSettings(self);
		self.portraitZoomMultiplier = self.settings.zoomMultiplier;
		self.minZoom = self.settings.minZoom or self.minZoom;
	end

	if ezCollections.Config.Wardrobe.CameraZoomSmooth and self.zoomLevel then
		local x, y, z = self:GetPosition();
		local tx = self.zoomLevel * self.portraitZoomMultiplier * self:GetModelScale();
		local delta = tx - x;
		if math.abs(delta) > 0.001 then
			self.cameraX = x + delta * elapsedTime * 20 * ezCollections.Config.Wardrobe.CameraZoomSmoothSpeed;
			if delta > 0 and self.cameraX > tx or delta < 0 and self.cameraX < tx then
				self.cameraX = tx;
			end
			self:SetPosition(self.cameraX, y, z);
		elseif math.abs(delta) > 0.0001 then
			self.cameraX = tx;
			self:SetPosition(self.cameraX, y, z);
		end
	end

	-- Mouse drag rotation
	if (self.mouseDown) then
		if ( self.rotationCursorStart ) then
			local x = GetCursorPosition();
			local diff = (x - self.rotationCursorStart) * MODELFRAME_DRAG_ROTATION_CONSTANT;
			self.rotationCursorStart = GetCursorPosition();
			self.rotation = self.rotation + diff;
			if ( self.rotation < 0 ) then
				self.rotation = self.rotation + (2 * PI);
			end
			if ( self.rotation > (2 * PI) ) then
				self.rotation = self.rotation - (2 * PI);
			end
			self:SetRotation(self.rotation, false);
		end
	elseif ( self.panning ) then
		local modelScale = self:GetModelScale();
		local cursorX, cursorY = GetCursorPosition();
		local scale = UIParent:GetEffectiveScale();
		ModelPanningFrame:SetPoint("BOTTOMLEFT", cursorX / scale - 16, cursorY / scale - 16);	-- half the texture size to center it on the cursor
		-- settings
		local settings = self.settings;

		local zoom = self.zoomLevel or self.minZoom;
		if ezCollections.Config.Wardrobe.CameraZoomSmooth and self.zoomLevel then
			zoom = self.cameraX / self:GetModelScale() / self.portraitZoomMultiplier;
		end
		zoom = 1 + zoom - self.minZoom;	-- want 1 at minimum zoom

		-- Panning should require roughly the same mouse movement regardless of zoom level so the model moves at the same rate as the cursor
		-- This formula more or less works for all zoom levels, found via trial and error
		local transformationRatio = settings.panValue * 2 ^ (zoom * 2) * scale / modelScale;

		local dx = (cursorX - self.cursorX) / transformationRatio;
		local dy = (cursorY - self.cursorY) / transformationRatio;
		local cameraY = self.cameraY + dx;
		local cameraZ = self.cameraZ + dy;
		-- bounds
		if ezCollections.Config.Wardrobe.CameraPanLimit then
			--scale = scale * modelScale;
			scale = modelScale;
			local maxCameraY = settings.panMaxRight * scale;
			cameraY = min(cameraY, maxCameraY);
			local minCameraY = settings.panMaxLeft * scale;
			cameraY = max(cameraY, minCameraY);
			local maxCameraZ = settings.panMaxTop * scale;
			cameraZ = min(cameraZ, maxCameraZ);
			local minCameraZ = settings.panMaxBottom * scale;
			cameraZ = max(cameraZ, minCameraZ);
		end

		self:SetPosition(self.cameraX, cameraY, cameraZ);
	end

	-- Rotate buttons
	local leftButton, rightButton;
	if ( self.controlFrame ) then
		leftButton = self.controlFrame.rotateLeftButton;
		rightButton = self.controlFrame.rotateRightButton;
	else
		leftButton = self.RotateLeftButton or (self:GetName() and _G[self:GetName().."RotateLeftButton"]);
		rightButton = self.RotateRightButton or (self:GetName() and _G[self:GetName().."RotateRightButton"]);
	end

	Model_UpdateRotation(self, leftButton, rightButton, elapsedTime, rotationsPerSecond);
end

function Model_UpdateRotation(self, leftButton, rightButton, elapsedTime, rotationsPerSecond)
	rotationsPerSecond = rotationsPerSecond or ROTATIONS_PER_SECOND;

	if ( rightButton and rightButton:GetButtonState() == "PUSHED" ) then
		self.rotation = self.rotation + (elapsedTime * 2 * PI * rotationsPerSecond);
		if ( self.rotation > (2 * PI) ) then
			self.rotation = self.rotation - (2 * PI);
		end
		self:SetRotation(self.rotation);
	elseif ( leftButton and leftButton:GetButtonState() == "PUSHED" ) then
		self.rotation = self.rotation - (elapsedTime * 2 * PI * rotationsPerSecond);
		if ( self.rotation < 0 ) then
			self.rotation = self.rotation + (2 * PI);
		end
		self:SetRotation(self.rotation);
	end
end

function Model_SetDefaultRotation(self, rotation)
	self.defaultRotation = rotation;
	self.rotation = rotation;
	self:SetRotation(rotation);
end

function Model_Reset(self)
	self.rotation = self.defaultRotation;
	self:SetRotation(self.rotation);
	self:SetPosition((self.defaultPosX or 0) * self:GetModelScale(), (self.defaultPosY or 0) * self:GetModelScale(), (self.defaultPosZ or 0) * self:GetModelScale());
	self.zoomLevel = self.defaultZoom or self.minZoom;
	self:SetPortraitZoom(self.zoomLevel);
end

function Model_StartPanning(self, usePanningFrame)
	if ( usePanningFrame ) then
		ModelPanningFrame.model = self;
		ModelPanningFrame:Show();
	end
	self.panning = true;
	local cameraX, cameraY, cameraZ = self:GetPosition();
	self.cameraX = cameraX;
	self.cameraY = cameraY;
	self.cameraZ = cameraZ;
	local cursorX, cursorY = GetCursorPosition();
	self.cursorX = cursorX;
	self.cursorY = cursorY;
end

function Model_StopPanning(self)
	self.panning = false;
	ModelPanningFrame:Hide();
end

function ModelControlButton_OnMouseDown(self)
	self.bg:SetTexCoord(0.01562500, 0.26562500, 0.14843750, 0.27343750);
	self.icon:SetPoint("CENTER", 1, -1);
	self:GetParent().buttonDown = self;
end

function ModelControlButton_OnMouseUp(self)
	self.bg:SetTexCoord(0.29687500, 0.54687500, 0.14843750, 0.27343750);
	self.icon:SetPoint("CENTER", 0, 0);
	self:GetParent().buttonDown = nil;
end

MODELFRAME_UI_CAMERA_POSITION = { x = 4, y = 0, z = 0, };
MODELFRAME_UI_CAMERA_TARGET = { x = 0, y = 0, z = 0, };

local targetAspectRatio = 1600/900;

function Model_ApplyUICamera(model, cameraID)
	local x, y, z, f, _, _, anim = GetUICameraInfo(cameraID);
	if x then
		local ratio = GetScreenWidth() / GetScreenHeight();
		ratio = 0.5 + (targetAspectRatio / ratio) / 2;
		ratio = ratio * model:GetModelScale();
		model:SetPosition(x * ratio, y * ratio, z * ratio);
		model:SetFacing(f);
		model.cameraAnimID = anim;
	else
		model:SetPosition(1 * model:GetModelScale(), 0, 0);
		model:SetFacing(0);
		model.cameraAnimID = nil;
	end

	if model.zoomLevel then
		model.zoomLevel = model:GetPosition() / model:GetModelScale() / model.portraitZoomMultiplier;
	end
end

function GetUICameraInfo(cameraID)
	local posX, posY, posZ, yaw, pitch, roll, animId, animVariation, animFrame, centerModel;
	local camera;
	if cameraID >= 0 then
		camera = ezCollections.Cameras[cameraID];
	else
		camera = ezCollections.Cache.Cameras[-cameraID];
	end
	if camera then
		posX, posY, posZ, yaw, animId = unpack(camera);
	end
	return posX, posY, posZ, yaw, pitch, roll, animId, animVariation, animFrame, centerModel;
end
