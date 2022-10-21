function ezCollections.PackSet(set)
    local itemStrings = "";
    for _, source in ipairs(set.sources) do
        itemStrings = itemStrings .. "," .. source.id;
        if source.flags ~= 0 then
            itemStrings = itemStrings .. "F" .. source.flags;
        end
    end
    return format("%s,%u,%u,%s,%s,%u,%u,%u,%d%s",
        ezCollections:Encode(set.name),
        set.classMask,
        set.flags,
        set.label and ezCollections:Encode(set.label) or "",
        set.description and ezCollections:Encode(set.description) or "",
        set.baseSetID or 0,
        set.expansionID,
        set.patchID,
        set.uiOrder,
        itemStrings);
end

function ezCollections.UnpackSet(id, data, fromServer)
    local name, classMask, flags, label, description, parent, expansion, patch, order, itemStrings = strsplit(",", data, 10);
    name = ezCollections:Decode(name);
    classMask = tonumber(classMask);
    flags = tonumber(flags);
    label = ezCollections:Decode(label);
    description = ezCollections:Decode(description);
    parent = tonumber(parent);
    expansion = tonumber(expansion);
    patch = tonumber(patch);
    order = tonumber(order);

    local set =
    {
        setID = id,
        name = name,
        baseSetID = parent ~= 0 and parent or nil,
        description = #description ~= 0 and description or nil,
        label = #label ~= 0 and label or nil,
        expansionID = expansion,
        patchID = patch,
        uiOrder = order,
        classMask = classMask,
        hiddenUntilCollected = bit.band(flags, 2) ~= 0,
        requiredFaction = bit.band(flags, 4) ~= 0 and "ALLIANCE" or (bit.band(flags, 8) ~= 0 and "HORDE" or nil),
        collected = nil,
        favorite = nil,
        limitedTimeSet = nil,
        sources = { },
        flags = flags,
    };
    if itemStrings then
        for _, item in ipairs({ strsplit(",", itemStrings) }) do
            local id, flags = strsplit("F", item);
            flags = tonumber(flags) or 0;
            local source =
            {
                id = tonumber(id),
                flags = flags,
            };
            if fromServer and bit.band(flags, 0x1) ~= 0 then
                table.insert(set.sources, 1, source);
            else
                table.insert(set.sources, source);
            end
        end
    end

    return set;
end

function ezCollections:PostprocessSetsAfterLoading()
    for id, set in pairs(self.Cache.Sets) do
        for _, source in ipairs(set.sources) do
            local skin = self.Cache.All[source.id];
            if skin and not (skin.Sets and tContains(skin.Sets, set.setID)) then
                skin.Sets = skin.Sets or { };
                table.insert(skin.Sets, set.setID);
            end
        end
        if set.baseSetID then
            local baseSet = self.Cache.Sets[set.baseSetID];
            if baseSet and not (baseSet.Variants and tContains(baseSet.Variants, set.setID)) then
                baseSet.Variants = baseSet.Variants or { };
                table.insert(baseSet.Variants, set.setID);
            end
        end
    end
end
