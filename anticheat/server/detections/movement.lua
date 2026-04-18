MovementDetection = {
    history = {}
}

local function distance(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z

    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function MovementDetection.update(source)
    if Identifiers.isWhitelisted(source) then
        return
    end

    local ped = GetPlayerPed(source)
    if ped == 0 then
        return
    end

    local coords = GetEntityCoords(ped)
    local now = GetGameTimer()

    MovementDetection.history[source] = MovementDetection.history[source] or {
        lastCoords = nil,
        lastAt = nil,
        lastFlagAt = nil,
        streak = 0
    }

    local state = MovementDetection.history[source]

    if state.lastCoords and state.lastAt then
        local dist = distance(coords, state.lastCoords)
        local delta = now - state.lastAt
        local withinCooldown = state.lastFlagAt and now - state.lastFlagAt < Config.MovementRules.cooldownMs

        if not withinCooldown and delta > 0 and delta <= Config.MovementRules.minTeleportWindowMs and dist >= Config.MovementRules.maxTeleportDistance then
            state.streak = state.streak + 1
            state.lastFlagAt = now

            local score = state.streak >= 2 and Config.MovementRules.repeatedTeleportScore or 15
            local confidence = state.streak >= 2 and 'high' or 'medium'

            Evidence.add(source, 'teleport_suspected', 'medium', score, confidence, {
                distance = dist,
                deltaMs = delta,
                streak = state.streak,
                from = state.lastCoords,
                to = coords
            }, 'logged')

            Scoring.add(source, score, 'teleport suspicion', {
                severity = 'medium',
                confidence = confidence,
                evidenceSummary = 'Teleport suspicion pattern'
            })
        elseif dist < 10.0 then
            state.streak = 0
        end
    end

    state.lastCoords = coords
    state.lastAt = now
    Sessions.touchPosition(source, coords, now)
end

CreateThread(function()
    while true do
        Wait(Config.MovementRules.checkIntervalMs)

        for source in pairs(Sessions.active) do
            MovementDetection.update(source)
        end
    end
end)
