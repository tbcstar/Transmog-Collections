local __orderedIndex = { };
function ezCollections:Ordered(tbl, sorter)
    local function __genOrderedIndex(t)
        local orderedIndex = { };
        for key in pairs(t) do
            table.insert(orderedIndex, key);
        end
        if sorter then
            table.sort(orderedIndex, function(a, b)
                return sorter(t[a], t[b], a, b);
            end);
        else
            table.sort(orderedIndex);
        end
        return orderedIndex;
    end

    local function orderedNext(t, state)
        local key;
        if state == nil then
            __orderedIndex[t] = __genOrderedIndex(t)
            key = __orderedIndex[t][1];
        else
            for i = 1, table.getn(__orderedIndex[t]) do
                if __orderedIndex[t][i] == state then
                    key = __orderedIndex[t][i + 1];
                end
            end
        end

        if key then
            return key, t[key];
        end

        __orderedIndex[t] = nil;
        return
    end

    return orderedNext, tbl, nil;
end
