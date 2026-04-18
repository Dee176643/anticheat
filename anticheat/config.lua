Config = {}

Config.ResourceName = GetCurrentResourceName()
Config.Debug = true
Config.AlertWebhook = ''
Config.AdminCommand = 'acmenu'

Config.LocalDashboard = {
    host = '127.0.0.1',
    port = 3012
}

Config.ScoreThresholds = {
    alert = 25,
    kick = 60,
    ban = 100
}

Config.ScoreDecay = {
    enabled = true,
    intervalSeconds = 600,
    decayAmount = 5
}

Config.SpamRules = {
    ['anticheat:cash:add'] = { windowMs = 5000, maxCount = 3, score = 20, severity = 'medium', confidence = 'high' },
    ['anticheat:item:grant'] = { windowMs = 5000, maxCount = 3, score = 20, severity = 'medium', confidence = 'high' },
    ['esx_society:openBossMenu'] = { windowMs = 4000, maxCount = 2, score = 25, severity = 'high', confidence = 'high' }
}

Config.EconomyRules = {
    maxSingleCashGrant = 50000,
    maxSingleItemGrant = 20,
    trustedCashEvents = {
        ['jobs:salary:pay'] = true,
        ['mission:reward:pay'] = true
    },
    trustedItemEvents = {
        ['inventory:server:grantReward'] = true
    }
}

Config.MovementRules = {
    checkIntervalMs = 2000,
    maxTeleportDistance = 150.0,
    minTeleportWindowMs = 1500,
    repeatedTeleportScore = 30,
    cooldownMs = 8000
}

Config.AutoActions = {
    kickOnScoreThreshold = false,
    banOnCriticalDetections = true,
    blockSpamEvents = true,
    blockEconomyEvents = true
}

Config.WhitelistedLicenses = {
    -- ['license:xxxxxxxx'] = true
}

Config.AdminLicenses = {
    -- ['license:xxxxxxxx'] = true
}
