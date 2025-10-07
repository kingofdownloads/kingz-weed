local QBCore = exports['qb-core']:GetCoreObject()

-- Shop notification
RegisterNetEvent('kingz-weed:client:shopNotify', function(message, type)
    lib.notify({
        title = 'Weed Shop',
        description = message,
        type = type or 'info'
    })
end)
