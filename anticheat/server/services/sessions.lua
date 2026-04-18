Sessions = {
    active = {}
}

local function upsertPlayerRecord(source, ids)
    local existing = MySQL.single.await([[
        SELECT id
        FROM ac_players
        WHERE license_id = ? OR fivem_id = ? OR discord_id = ? OR steam_id = ?
        LIMIT 1
    ]], {
        ids.license,
        ids.fivem,
        ids.discord,
        ids.steam
    })

    if existing then
        MySQL.update.await([[
            UPDATE ac_players
            SET license_id = COALESCE(?, license_id),
                fivem_id = COALESCE(?, fivem_id),
                discord_id = COALESCE(?, discord_id),
                steam_id = COALESCE(?, steam_id),
                last_seen_at = CURRENT_TIMESTAMP
            WHERE id = ?
        ]], {
            ids.license,
            ids.fivem,
            ids.discord,
            ids.steam,
            existing.id
        })

        return existing.id
    end

    return MySQL.insert.await([[
        INSERT INTO ac_players (license_id, fivem_id, discord_id, steam_id, first_seen_at, last_seen_at, current_risk_score, is_banned)
        VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 0)
    ]], {
        ids.license,
        ids.fivem,
        ids.discord,
        ids.steam
    })
end

function Sessions.start(source)
    local ids = Identifiers.getAll(source)
    local playerId = upsertPlayerRecord(source, ids)
    local sessionId = MySQL.insert.await([[
        INSERT INTO ac_sessions (player_id, joined_at, ip_hash, build_version, server_id)
        VALUES (?, CURRENT_TIMESTAMP, ?, ?, ?)
    ]], {
        playerId,
        Identifiers.getIpHash(ids),
        GetGameName(),
        Config.ResourceName
    })

    Sessions.active[source] = {
        source = source,
        playerId = playerId,
        sessionId = sessionId,
        name = GetPlayerName(source) or ('Player %s'):format(source),
        ids = ids,
        joinedAt = os.time(),
        lastHeartbeatAt = os.time(),
        lastPosition = nil,
        lastPositionAt = nil
    }

    Logger.info('Session started for', source, Sessions.active[source].name, 'playerId=', playerId, 'sessionId=', sessionId)
    return Sessions.active[source]
end

function Sessions.stop(source)
    local session = Sessions.active[source]
    if not session then
        return
    end

    MySQL.update.await('UPDATE ac_sessions SET left_at = CURRENT_TIMESTAMP WHERE id = ?', { session.sessionId })
    Logger.info('Session ended for', source, session.name, 'sessionId=', session.sessionId)
    Sessions.active[source] = nil
end

function Sessions.get(source)
    return Sessions.active[source]
end

function Sessions.getPlayerId(source)
    local session = Sessions.active[source]
    return session and session.playerId or nil
end

function Sessions.getSessionId(source)
    local session = Sessions.active[source]
    return session and session.sessionId or nil
end

function Sessions.touch(source)
    local session = Sessions.active[source]
    if not session then
        return
    end

    session.lastHeartbeatAt = os.time()
end

function Sessions.touchPosition(source, coords, at)
    local session = Sessions.active[source]
    if not session then
        return
    end

    session.lastPosition = coords
    session.lastPositionAt = at
end
