local panelOpen = false

local function setPanelState(open)
    panelOpen = open == true
    SetNuiFocus(panelOpen, panelOpen)
    SendNUIMessage({
        type = 'panel:toggle',
        open = panelOpen
    })
end

CreateThread(function()
    while true do
        Wait(30000)
        TriggerServerEvent('anticheat:heartbeat')
    end
end)

RegisterNetEvent('anticheat:client:toggleAdminPanel', function(open)
    setPanelState(open)
end)

RegisterNetEvent('anticheat:client:panelData', function(payload)
    SendNUIMessage({
        type = 'panel:data',
        payload = payload
    })
end)

RegisterNUICallback('getPanelData', function(_, cb)
    TriggerServerEvent('anticheat:admin:requestPanelData')
    cb({ ok = true })
end)

RegisterNUICallback('moderatePlayer', function(data, cb)
    TriggerServerEvent('anticheat:admin:action', data)
    cb({ ok = true })
end)

RegisterNUICallback('close', function(_, cb)
    setPanelState(false)
    cb({ ok = true })
end)
