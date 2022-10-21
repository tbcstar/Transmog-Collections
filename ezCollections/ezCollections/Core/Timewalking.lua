local timewalkingDungeons = { };

local function Hook()
    Hook = nil;

    local oGetLFGDungeonInfo = GetLFGDungeonInfo;
    function GetLFGDungeonInfo(id)
        local info = timewalkingDungeons[id];
        if info then
            return unpack(info);
        end
        return oGetLFGDungeonInfo(id);
    end

    local oGetLFGRandomDungeonInfo = GetLFGRandomDungeonInfo;
    function GetLFGRandomDungeonInfo(index)
        local id = oGetLFGRandomDungeonInfo(index);
        return id, GetLFGDungeonInfo(id);
    end

    local function UpdateFrame()
        local info = timewalkingDungeons[LFDQueueFrame.type];
        if info then
            LFDQueueFrameBackground:SetTexture(info[LFG_RETURN_VALUES.texture or 10]);
            LFDQueueFrameRandomScrollFrameChildFrame.title:SetText(info[LFG_RETURN_VALUES.title or 15]);
            LFDQueueFrameRandomScrollFrameChildFrame.description:SetText(info[LFG_RETURN_VALUES.description or 13]);
        end
    end
    hooksecurefunc("LFDQueueFrameRandom_UpdateFrame", UpdateFrame);
    LFDQueueFrameRandomScrollFrameChildFrame:HookScript("OnShow", UpdateFrame);
end

function ezCollections:AddTimewalking(id, info)
    timewalkingDungeons[id] = info;
    if Hook then
        Hook();
    end
end

function ezCollections:ResetTimewalking()
    table.wipe(timewalkingDungeons);
end
