local QBCore = exports['qb-core']:GetCoreObject()

-- Create police alert for mission
RegisterNetEvent('kingz-weed:client:missionPoliceAlert', function(coords)
    if PlayerData.job and PlayerData.job.name == 'police' then
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, 51)
        SetBlipColour(blip, 1)
        SetBlipAsShortRange(blip, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Suspicious Package Delivery")
        EndTextCommandSetBlipName(blip)
        
        SetBlipFlashes(blip, true)
        
        lib.notify({
            title = 'Police Alert',
            description = 'Suspicious package delivery in progress',
            type = 'police'
        })
        
        -- Remove blip after 60 seconds
        Citizen.SetTimeout(60000, function()
            RemoveBlip(blip)
        end)
    end
end)
