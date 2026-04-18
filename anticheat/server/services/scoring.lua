Scoring = {
    scores = {}
}

local severityWeights = {
    low = 0.5,
    medium = 1.0,
    high = 1.25,
    critical = 1.5
}

local confidenceWeights = {
    low = 0.5,
    medium = 1.0,
    high = 1.15,
    critical = 1.3
}

local function roundScore(value)
    return math.floor(value + 0.5)
end

local function ensureState(source)
    if not Scoring.scores[source] then
        Scoring.scores[source] = {
            score = 0,
            lastUpdated = os.time()
        }
    end

    return Scoring.scores[source]
end

function Scoring.get(source)
    return ensureState(source).score
end

function Scoring.getLevel(score)
    if score >= Config.ScoreThresholds.ban then
        return 'ban_candidate'
    end

    if score >= Config.ScoreThresholds.kick then
        return 'kick_candidate'
    end

    if score >= Config.ScoreThresholds.alert then
        return 'alert'
    end

    return 'log'
end

function Scoring.add(source, basePoints, reason, context)
    if Identifiers.isWhitelisted(source) then
        return Scoring.get(source), 'whitelisted'
    end

    local state = ensureState(source)
    local severityWeight = severityWeights[(context and context.severity) or 'medium'] or 1.0
    local confidenceWeight = confidenceWeights[(context and context.confidence) or 'medium'] or 1.0
    local appliedPoints = roundScore(basePoints * severityWeight * confidenceWeight)

    state.score = state.score + appliedPoints
    state.lastUpdated = os.time()

    local playerId = Sessions.getPlayerId(source)
    if playerId then
        MySQL.update.await('UPDATE ac_players SET current_risk_score = ?, last_seen_at = CURRENT_TIMESTAMP WHERE id = ?', {
            state.score,
            playerId
        })
    end

    local level = Scoring.getLevel(state.score)
    Logger.warn('Score change:', source, ('+%s'):format(appliedPoints), '=>', state.score, '|', reason, '|', level)

    if level == 'alert' then
        Logger.warn('Staff alert candidate for', source, 'reason:', reason)
    elseif level == 'kick_candidate' then
        Logger.warn('Kick candidate for', source, 'reason:', reason)
        if context and context.allowKick and Config.AutoActions.kickOnScoreThreshold then
            DropPlayer(source, ('Anticheat: kicked (%s)'):format(reason))
        end
    elseif level == 'ban_candidate' then
        Logger.error('Ban review candidate for', source, 'reason:', reason)
        if context and context.allowBan and Config.AutoActions.banOnCriticalDetections then
            Bans.issueForSource(source, reason, 'system', context.evidenceSummary or reason)
        end
    end

    return state.score, level
end

CreateThread(function()
    while Config.ScoreDecay.enabled do
        Wait(Config.ScoreDecay.intervalSeconds * 1000)

        for source, state in pairs(Scoring.scores) do
            local newScore = math.max(0, state.score - Config.ScoreDecay.decayAmount)
            state.score = newScore
            state.lastUpdated = os.time()

            local playerId = Sessions.getPlayerId(source)
            if playerId then
                MySQL.update.await('UPDATE ac_players SET current_risk_score = ? WHERE id = ?', {
                    newScore,
                    playerId
                })
            end
        end
    end
end)
