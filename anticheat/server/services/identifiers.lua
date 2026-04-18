Identifiers = {}

local identifierOrder = { 'license', 'fivem', 'discord', 'steam' }

local function extractIdentifierMap(source)
    local ids = {
        license = nil,
        discord = nil,
        steam = nil,
        fivem = nil,
        ip = nil
    }

    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        if identifier:find('license:') == 1 then
            ids.license = identifier
        elseif identifier:find('discord:') == 1 then
            ids.discord = identifier
        elseif identifier:find('steam:') == 1 then
            ids.steam = identifier
        elseif identifier:find('fivem:') == 1 then
            ids.fivem = identifier
        elseif identifier:find('ip:') == 1 then
            ids.ip = identifier
        end
    end

    return ids
end

function Identifiers.getAll(source)
    return extractIdentifierMap(source)
end

function Identifiers.getPrimary(source)
    local ids = extractIdentifierMap(source)

    for _, key in ipairs(identifierOrder) do
        if ids[key] then
            return ids[key]
        end
    end

    return nil
end

function Identifiers.getIpHash(ids)
    if not ids or not ids.ip then
        return nil
    end

    return tostring(GetHashKey(ids.ip))
end

function Identifiers.isWhitelisted(source)
    local ids = extractIdentifierMap(source)
    return ids.license and Config.WhitelistedLicenses[ids.license] == true or false
end

function Identifiers.isAdmin(source)
    local ids = extractIdentifierMap(source)
    if not ids.license then
        return false
    end

    return Config.AdminLicenses[ids.license] == true or Config.WhitelistedLicenses[ids.license] == true
end
