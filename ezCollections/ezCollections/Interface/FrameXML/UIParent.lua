function CollectionsJournal_LoadUI()
	--UIParentLoadAddOn("Blizzard_Collections");
end

COLLECTIONS_JOURNAL_TAB_INDEX_MOUNTS = 1;
COLLECTIONS_JOURNAL_TAB_INDEX_PETS = COLLECTIONS_JOURNAL_TAB_INDEX_MOUNTS + 1;
COLLECTIONS_JOURNAL_TAB_INDEX_TOYS = COLLECTIONS_JOURNAL_TAB_INDEX_PETS + 1;
COLLECTIONS_JOURNAL_TAB_INDEX_HEIRLOOMS = COLLECTIONS_JOURNAL_TAB_INDEX_TOYS + 1;
COLLECTIONS_JOURNAL_TAB_INDEX_APPEARANCES = COLLECTIONS_JOURNAL_TAB_INDEX_HEIRLOOMS + 1;

function ToggleCollectionsJournal(whichFrame)
	if ( not CollectionsJournal ) then
		CollectionsJournal_LoadUI();
	end
	if ( CollectionsJournal ) then
		if ( whichFrame ) then
			-- if the request tab is being shown, close window
			if ( CollectionsJournal:IsShown() and whichFrame == PanelTemplates_GetSelectedTab(CollectionsJournal) ) then
				HideUIPanel(CollectionsJournal);
			else
				ShowUIPanel(CollectionsJournal);
				CollectionsJournal_SetTab(CollectionsJournal, whichFrame);
			end
		else
			ToggleFrame(CollectionsJournal);
		end
	end
end

function SetCollectionsJournalShown(shown, tabIndex)
	if not CollectionsJournal then
		CollectionsJournal_LoadUI();
	end
	if CollectionsJournal then
		if shown then
			ShowUIPanel(CollectionsJournal);
			if tabIndex then
				CollectionsJournal_SetTab(CollectionsJournal, tabIndex);
			end
		else
			HideUIPanel(CollectionsJournal);
		end
	end
end

function AnimateTexCoords(texture, textureWidth, textureHeight, frameWidth, frameHeight, numFrames, elapsed, throttle)
	throttle = throttle or 0.1;
	if ( not texture.frame ) then
		-- initialize everything
		texture.frame = 1;
		texture.throttle = throttle;
		texture.numColumns = floor(textureWidth/frameWidth);
		texture.numRows = floor(textureHeight/frameHeight);
		texture.columnWidth = frameWidth/textureWidth;
		texture.rowHeight = frameHeight/textureHeight;
	end
	local frame = texture.frame;
	if ( not texture.throttle or texture.throttle > throttle ) then
		local framesToAdvance = floor(texture.throttle / throttle);
		while ( frame + framesToAdvance > numFrames ) do
			frame = frame - numFrames;
		end
		frame = frame + framesToAdvance;
		texture.throttle = 0;
		local left = mod(frame-1, texture.numColumns)*texture.columnWidth;
		local right = left + texture.columnWidth;
		local bottom = ceil(frame/texture.numColumns)*texture.rowHeight;
		local top = bottom - texture.rowHeight;
		texture:SetTexCoord(left, right, top, bottom);

		texture.frame = frame;
	else
		texture.throttle = texture.throttle + elapsed;
	end
end
