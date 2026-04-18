SpamDetection = {
    counters = {}
}

function SpamDetection.track(source, eventName)
    if Identifiers.isWhitelisted(source) then
        return true
    end

    local rule = Config.SpamRules[eventName]
    if not rule then
        return true
    end

    SpamDetection.counters[source] = SpamDetection.counters[source] or {}

    local now = GetGameTimer()
    local bucket = SpamDetection.counters[source][eventName]

    if not bucket then
        bucket = { startedAt = now, count = 0 }
        SpamDetection.counters[source][eventName] = bucket
    end

    if now - bucket.startedAt > rule.windowMs then
        bucket.startedAt = now
        bucket.count = 0
    end

    bucket.count = bucket.count + 1

    if bucket.count > rule.maxCount then
        Evidence.add(source, 'spam_event', rule.severity or 'medium', rule.score, rule.confidence or 'high', {
            eventName = eventName,
            count = bucket.count,
            windowMs = rule.windowMs,
            maxCount = rule.maxCount
        }, 'event_blocked')

        Scoring.add(source, rule.score, ('spam on %s'):format(eventName), {
            severity = rule.severity or 'medium',
            confidence = rule.confidence or 'high',
            allowKick = true,
            evidenceSummary = ('Repeated spam on %s'):format(eventName)
        })

        return false
    end

    return true
end
