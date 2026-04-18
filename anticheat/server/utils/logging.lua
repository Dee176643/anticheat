Logger = {}

local function join(parts)
    local out = {}

    for index = 1, #parts do
        out[index] = tostring(parts[index])
    end

    return table.concat(out, ' ')
end

function Logger.debug(...)
    if not Config.Debug then
        return
    end

    print(('^5[%s DEBUG]^7 %s'):format(Config.ResourceName, join({ ... })))
end

function Logger.info(...)
    print(('^2[%s]^7 %s'):format(Config.ResourceName, join({ ... })))
end

function Logger.warn(...)
    print(('^3[%s]^7 %s'):format(Config.ResourceName, join({ ... })))
end

function Logger.error(...)
    print(('^1[%s]^7 %s'):format(Config.ResourceName, join({ ... })))
end
