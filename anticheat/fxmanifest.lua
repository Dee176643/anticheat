fx_version 'cerulean'
game 'gta5'

name 'custom_anticheat'
author 'OpenAI'
description 'Original FiveM anticheat MVP starter'
version '1.0.0'
lua54 'yes'

ui_page 'web/dist/index.html'

shared_scripts {
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/utils/logging.lua',
    'server/services/identifiers.lua',
    'server/services/sessions.lua',
    'server/services/scoring.lua',
    'server/services/evidence.lua',
    'server/services/bans.lua',
    'server/detections/spam.lua',
    'server/detections/economy.lua',
    'server/detections/movement.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

files {
    'web/dist/index.html',
    'web/dist/app.js',
    'web/dist/styles.css'
}
