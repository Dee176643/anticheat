# Custom Anticheat MVP

Original FiveM anticheat starter focused on a server-authoritative core, evidence logging, risk scoring, and a safe review-first workflow.

## Included in this starter

- SQL-backed player and session tracking
- Evidence and detection persistence
- Weighted risk scoring with decay
- Ban checks on connect
- Spam detection skeleton
- Economy validation skeleton
- Movement suspicion skeleton
- Ingame admin panel via `/acmenu`
- Localhost dashboard/API scaffold on `http://127.0.0.1:3012`
- Basic player-facing commands: `/ac_score`, `/ac_evidence`

## Files that matter first

- [fxmanifest.lua](C:/Users/DEE/Desktop/anticheat/fxmanifest.lua)
- [config.lua](C:/Users/DEE/Desktop/anticheat/config.lua)
- [server/main.lua](C:/Users/DEE/Desktop/anticheat/server/main.lua)
- [server/services/scoring.lua](C:/Users/DEE/Desktop/anticheat/server/services/scoring.lua)
- [server/services/evidence.lua](C:/Users/DEE/Desktop/anticheat/server/services/evidence.lua)
- [server/detections/spam.lua](C:/Users/DEE/Desktop/anticheat/server/detections/spam.lua)
- [server/detections/economy.lua](C:/Users/DEE/Desktop/anticheat/server/detections/economy.lua)
- [server/detections/movement.lua](C:/Users/DEE/Desktop/anticheat/server/detections/movement.lua)
- [sql/custom_anticheat.sql](C:/Users/DEE/Desktop/anticheat/sql/custom_anticheat.sql)
- [api/src/index.js](C:/Users/DEE/Desktop/anticheat/api/src/index.js)
- [dashboard/index.html](C:/Users/DEE/Desktop/anticheat/dashboard/index.html)

## Setup

1. Import [sql/custom_anticheat.sql](C:/Users/DEE/Desktop/anticheat/sql/custom_anticheat.sql) into your database.
2. Make sure `oxmysql` is installed and started before this resource.
3. Add your own license into `Config.AdminLicenses` in [config.lua](C:/Users/DEE/Desktop/anticheat/config.lua) so `/acmenu` is usable ingame.
4. Add the resource to your server config and start it.
5. Tune thresholds and trusted event names in [config.lua](C:/Users/DEE/Desktop/anticheat/config.lua) for your framework.
6. For the localhost dashboard, copy [api/.env.example](C:/Users/DEE/Desktop/anticheat/api/.env.example) to `.env`, install the Node dependencies, and run `npm start` inside [`api/`](C:/Users/DEE/Desktop/anticheat/api).

## Important notes

- The sample events `anticheat:cash:add` and `anticheat:item:grant` are placeholders. Wire your actual framework reward flows into the economy validation layer before relying on them.
- Score thresholds default to review-first behavior. Auto-ban is only enabled when a rule passes `allowBan = true`.
- The ingame NUI panel lives in [`web/dist`](C:/Users/DEE/Desktop/anticheat/web/dist/index.html) and is loaded by the manifest.
- The localhost API/dashboard is scaffolded, but I could not run it here because `node` is not installed in this environment.
