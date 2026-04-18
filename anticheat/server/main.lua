local function ensureSession(source)
    local session = Sessions.get(source)
    if session then
        return session
    end

    return Sessions.start(source)
end

local function isAdmin(source)
    return source == 0 or Identifiers.isAdmin(source)
end

local function requireAdmin(source)
    if isAdmin(source) then
        return true
    end

    TriggerClientEvent('chat:addMessage', source, {
        args = { 'Anticheat', 'You do not have permission to use the admin panel.' }
    })

    return false
end

local function buildLivePlayers()
    local players = {}

    for source, session in pairs(Sessions.active) do
        players[#players + 1] = {
            source = source,
            playerId = session.playerId,
            sessionId = session.sessionId,
            name = session.name,
            license = session.ids and session.ids.license or nil,
            discord = session.ids and session.ids.discord or nil,
            fivem = session.ids and session.ids.fivem or nil,
            steam = session.ids and session.ids.steam or nil,
            score = Scoring.get(source),
            joinedAt = session.joinedAt,
            lastHeartbeatAt = session.lastHeartbeatAt,
            isWhitelisted = Identifiers.isWhitelisted(source)
        }
    end

    table.sort(players, function(a, b)
        return a.source < b.source
    end)

    return players
end

local function buildAdminPanelData()
    return {
        generatedAt = os.time(),
        command = Config.AdminCommand,
        localDashboardUrl = ('http://%s:%s'):format(Config.LocalDashboard.host, Config.LocalDashboard.port),
        players = buildLivePlayers(),
        alerts = Evidence.getRecent(50),
        bans = Bans.getRecent(25)
    }
end

local function sendAdminPanelData(source)
    TriggerClientEvent('anticheat:client:panelData', source, buildAdminPanelData())
end

AddEventHandler('playerConnecting', function(_, _, deferrals)
    local source = source
    deferrals.defer()
    Wait(0)

    if Bans.enforceConnection(source, deferrals) then
        return
    end

    deferrals.done()
end)

AddEventHandler('playerJoining', function()
    local source = source
    ensureSession(source)
end)

AddEventHandler('playerDropped', function()
    local source = source
    Sessions.stop(source)
    SpamDetection.counters[source] = nil
    MovementDetection.history[source] = nil
    Scoring.scores[source] = nil
end)

RegisterNetEvent('anticheat:heartbeat', function()
    local source = source
    ensureSession(source)
    Sessions.touch(source)
end)

RegisterNetEvent('anticheat:admin:requestPanelData', function()
    local source = source
    if not requireAdmin(source) then
        return
    end

    sendAdminPanelData(source)
end)

RegisterNetEvent('anticheat:admin:action', function(payload)
    local source = source
    if not requireAdmin(source) then
        return
    end

    if type(payload) ~= 'table' then
        return
    end

    local action = payload.action
    local target = tonumber(payload.target)
    local reason = payload.reason or 'No reason provided'

    if not action or not target or not Sessions.get(target) then
        return
    end

    if action == 'warn' then
        TriggerClientEvent('chat:addMessage', target, {
            args = { 'Anticheat Staff', reason }
        })
    elseif action == 'kick' then
        DropPlayer(target, ('Anticheat: kicked (%s)'):format(reason))
    elseif action == 'ban' then
        Bans.issueForSource(target, reason, GetPlayerName(source) or ('Admin %s'):format(source), reason)
    end

    sendAdminPanelData(source)
end)

RegisterNetEvent('anticheat:cash:add', function(amount)
    local source = source
    ensureSession(source)

    if not SpamDetection.track(source, 'anticheat:cash:add') then
        if Config.AutoActions.blockSpamEvents then
            CancelEvent()
        end
        return
    end

    if not EconomyDetection.validateCashGrant(source, 'anticheat:cash:add', amount) then
        if Config.AutoActions.blockEconomyEvents then
            CancelEvent()
        end
        return
    end

    Logger.info('Approved cash add for', source, tostring(amount))
end)

RegisterNetEvent('anticheat:item:grant', function(itemName, count)
    local source = source
    ensureSession(source)

    if not SpamDetection.track(source, 'anticheat:item:grant') then
        if Config.AutoActions.blockSpamEvents then
            CancelEvent()
        end
        return
    end

    if not EconomyDetection.validateItemGrant(source, 'anticheat:item:grant', itemName, count) then
        if Config.AutoActions.blockEconomyEvents then
            CancelEvent()
        end
        return
    end

    Logger.info('Approved item grant for', source, tostring(itemName), tostring(count))
end)

RegisterCommand('ac_score', function(source)
    if source == 0 then
        return
    end

    local score = Scoring.get(source)
    TriggerClientEvent('chat:addMessage', source, {
        args = { 'Anticheat', ('Your score: %s'):format(score) }
    })
end, false)

RegisterCommand('ac_evidence', function(source)
    if source == 0 then
        return
    end

    local entries = Evidence.get(source)
    TriggerClientEvent('chat:addMessage', source, {
        args = { 'Anticheat', ('Recent evidence entries: %s'):format(#entries) }
    })
end, false)

RegisterCommand(Config.AdminCommand, function(source)
    if source == 0 then
        print(('Open the dashboard at http://%s:%s'):format(Config.LocalDashboard.host, Config.LocalDashboard.port))
        return
    end

    if not requireAdmin(source) then
        return
    end

    TriggerClientEvent('anticheat:client:toggleAdminPanel', source, true)
    sendAdminPanelData(source)
end, false)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= Config.ResourceName then
        return
    end

    for _, playerId in ipairs(GetPlayers()) do
        ensureSession(tonumber(playerId))
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= Config.ResourceName then
        return
    end

    for source in pairs(Sessions.active) do
        Sessions.stop(source)
    end
end)
