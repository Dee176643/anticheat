EconomyDetection = {}

function EconomyDetection.validateCashGrant(source, eventName, amount)
    if Identifiers.isWhitelisted(source) then
        return true
    end

    if type(amount) ~= 'number' or amount <= 0 then
        Evidence.add(source, 'invalid_cash_payload', 'high', 35, 'high', {
            eventName = eventName,
            amount = amount
        }, 'event_blocked')

        Scoring.add(source, 35, 'invalid cash payload', {
            severity = 'high',
            confidence = 'high',
            allowKick = true,
            evidenceSummary = 'Invalid cash payload'
        })

        return false
    end

    if amount > Config.EconomyRules.maxSingleCashGrant then
        Evidence.add(source, 'excessive_cash_grant', 'critical', 40, 'high', {
            eventName = eventName,
            amount = amount,
            limit = Config.EconomyRules.maxSingleCashGrant
        }, 'event_blocked')

        Scoring.add(source, 40, 'excessive cash grant', {
            severity = 'critical',
            confidence = 'high',
            allowKick = true,
            allowBan = true,
            evidenceSummary = 'Excessive cash grant attempt'
        })

        return false
    end

    if not Config.EconomyRules.trustedCashEvents[eventName] then
        Evidence.add(source, 'untrusted_cash_event', 'critical', 45, 'critical', {
            eventName = eventName,
            amount = amount
        }, 'event_blocked')

        Scoring.add(source, 45, 'untrusted cash event', {
            severity = 'critical',
            confidence = 'critical',
            allowKick = true,
            allowBan = true,
            evidenceSummary = 'Untrusted cash event'
        })

        return false
    end

    return true
end

function EconomyDetection.validateItemGrant(source, eventName, itemName, count)
    if Identifiers.isWhitelisted(source) then
        return true
    end

    if type(itemName) ~= 'string' or itemName == '' or type(count) ~= 'number' or count <= 0 then
        Evidence.add(source, 'invalid_item_payload', 'high', 30, 'high', {
            eventName = eventName,
            itemName = itemName,
            count = count
        }, 'event_blocked')

        Scoring.add(source, 30, 'invalid item payload', {
            severity = 'high',
            confidence = 'high',
            allowKick = true,
            evidenceSummary = 'Invalid item payload'
        })

        return false
    end

    if count > Config.EconomyRules.maxSingleItemGrant then
        Evidence.add(source, 'excessive_item_grant', 'critical', 35, 'high', {
            eventName = eventName,
            itemName = itemName,
            count = count,
            limit = Config.EconomyRules.maxSingleItemGrant
        }, 'event_blocked')

        Scoring.add(source, 35, 'excessive item grant', {
            severity = 'critical',
            confidence = 'high',
            allowKick = true,
            evidenceSummary = 'Excessive item grant'
        })

        return false
    end

    if not Config.EconomyRules.trustedItemEvents[eventName] then
        Evidence.add(source, 'untrusted_item_event', 'critical', 40, 'critical', {
            eventName = eventName,
            itemName = itemName,
            count = count
        }, 'event_blocked')

        Scoring.add(source, 40, 'untrusted item event', {
            severity = 'critical',
            confidence = 'critical',
            allowKick = true,
            allowBan = true,
            evidenceSummary = 'Untrusted item event'
        })

        return false
    end

    return true
end
