Evidence = {
    cache = {}
}

local function cacheEntry(source, entry)
    Evidence.cache[source] = Evidence.cache[source] or {}
    local entries = Evidence.cache[source]
    entries[#entries + 1] = entry

    if #entries > 50 then
        table.remove(entries, 1)
    end
end

function Evidence.add(source, detectionType, severity, scoreDelta, confidence, details, actionTaken)
    local session = Sessions.get(source)
    if not session then
        return nil
    end

    local detectionId = MySQL.insert.await([[
        INSERT INTO ac_detections (player_id, session_id, type, severity, score_delta, confidence, details_json, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
    ]], {
        session.playerId,
        session.sessionId,
        detectionType,
        severity,
        scoreDelta,
        confidence,
        json.encode(details or {})
    })

    MySQL.insert.await([[
        INSERT INTO ac_evidence (detection_id, kind, payload_json, created_at)
        VALUES (?, ?, ?, CURRENT_TIMESTAMP)
    ]], {
        detectionId,
        actionTaken or 'details',
        json.encode(details or {})
    })

    local entry = {
        detectionId = detectionId,
        type = detectionType,
        severity = severity,
        scoreDelta = scoreDelta,
        confidence = confidence,
        details = details or {},
        action = actionTaken or 'logged',
        createdAt = os.time()
    }

    cacheEntry(source, entry)
    Logger.warn('Evidence recorded:', 'src=' .. tostring(source), 'type=' .. detectionType, 'severity=' .. severity, 'score=' .. tostring(scoreDelta))
    return entry
end

function Evidence.get(source)
    return Evidence.cache[source] or {}
end

function Evidence.getRecent(limit)
    local merged = {}

    for source, entries in pairs(Evidence.cache) do
        local session = Sessions.get(source)

        for _, entry in ipairs(entries) do
            merged[#merged + 1] = {
                source = source,
                playerName = session and session.name or ('Player %s'):format(source),
                license = session and session.ids and session.ids.license or nil,
                detectionId = entry.detectionId,
                type = entry.type,
                severity = entry.severity,
                scoreDelta = entry.scoreDelta,
                confidence = entry.confidence,
                action = entry.action,
                details = entry.details,
                createdAt = entry.createdAt
            }
        end
    end

    table.sort(merged, function(a, b)
        return (a.createdAt or 0) > (b.createdAt or 0)
    end)

    if limit and #merged > limit then
        local trimmed = {}
        for index = 1, limit do
            trimmed[index] = merged[index]
        end
        return trimmed
    end

    return merged
end
