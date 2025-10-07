local QBCore = exports['qb-core']:GetCoreObject()
local activeEffects = {}

-- Use drug
RegisterNetEvent('kingz-weed:client:useDrug', function(itemName)
    -- Check if it's a joint
    local drugType = itemName
    if string.match(itemName, "joint$") then
        drugType = string.gsub(itemName, "_joint$", "")
        if drugType == "joint" then drugType = "weed" end
    end
    
    -- Check if drug exists in config
    if not Config.DrugEffects[drugType] then
        lib.notify({
            title = 'Error',
            description = 'Unknown drug type',
            type = 'error'
        })
        return
    end
    
    -- Check if already under effect
    if activeEffects[drugType] then
        lib.notify({
            title = 'Already Active',
            description = 'You are already under the effect of this drug',
            type = 'error'
        })
        return
    end
    
    -- Animation based on drug type
    local playerPed = PlayerPedId()
    if string.match(itemName, "joint$") then
        -- Joint smoking animation
        TriggerEvent('animations:client:EmoteCommandStart', {"smoke"})
    else
        -- Regular drug use animation
        TriggerEvent('animations:client:EmoteCommandStart', {"pill"})
    end
    
    QBCore.Functions.Progressbar("using_drug", "Using " .. itemName, 5000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        TriggerEvent('animations:client:EmoteCommandStart', {"c"})
        TriggerServerEvent('kingz-weed:server:removeDrug', itemName)
        ApplyDrugEffects(drugType)
    end, function() -- Cancel
        TriggerEvent('animations:client:EmoteCommandStart', {"c"})
        lib.notify({
            title = 'Canceled',
            description = Lang:t('error.canceled'),
            type = 'error'
        })
    end)
end)

-- Use bong
RegisterNetEvent('kingz-weed:client:useBong', function()
    -- Check if player has weed
    QBCore.Functions.TriggerCallback('kingz-weed:server:hasAnyWeed', function(hasWeed, weedType)
        if hasWeed then
            -- Bong animation
            local playerPed = PlayerPedId()
            
            -- Play bong sound
            TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 10.0, 'bong', 0.5)
            
            QBCore.Functions.Progressbar("using_bong", Lang:t('info.using_bong'), 8000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {
                animDict = "anim@safehouse@bong",
                anim = "bong_stage1",
                flags = 49,
            }, {
                model = "prop_bong_01",
                bone = 18905,
                coords = { x = 0.10, y = -0.25, z = 0.0 },
                rotation = { x = 95.0, y = 190.0, z = 180.0 },
            }, {}, function() -- Done
                TriggerServerEvent('kingz-weed:server:removeWeedForBong', weedType)
                ApplyDrugEffects('bong_hit')
                
                lib.notify({
                    title = 'Success',
                    description = Lang:t('success.bong_hit'),
                    type = 'success'
                })
            end, function() -- Cancel
                lib.notify({
                    title = 'Canceled',
                    description = Lang:t('error.canceled'),
                    type = 'error'
                })
            end)
        else
            lib.notify({
                title = 'No Weed',
                description = Lang:t('error.no_weed'),
                type = 'error'
            })
        end
    end)
end)

-- Use grinder
RegisterNetEvent('kingz-weed:client:useGrinder', function()
    -- Check if player has weed
    QBCore.Functions.TriggerCallback('kingz-weed:server:hasAnyWeed', function(hasWeed, weedType)
        if hasWeed then
            -- Grinding animation
            local playerPed = PlayerPedId()
            
            QBCore.Functions.Progressbar("grinding_weed", Lang:t('info.grinding_weed'), Config.Processing.grindTime * 1000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {
                animDict = "anim@amb@business@weed@weed_inspecting_lo_med_hi@",
                anim = "weed_crouch_checkingleaves_idle_01_inspector",
                flags = 49,
            }, {
                model = "prop_weed_bottle",
                bone = 18905,
                coords = { x = 0.10, y = -0.05, z = 0.0 },
                rotation = { x = 95.0, y = 190.0, z = 180.0 },
            }, {}, function() -- Done
                TriggerServerEvent('kingz-weed:server:grindWeed', weedType)
                
                lib.notify({
                    title = 'Success',
                    description = Lang:t('success.grinded'),
                    type = 'success'
                })
            end, function() -- Cancel
                lib.notify({
                    title = 'Canceled',
                    description = Lang:t('error.canceled'),
                    type = 'error'
                })
            end)
        else
            lib.notify({
                title = 'No Weed',
                description = Lang:t('error.no_weed'),
                type = 'error'
            })
        end
    end)
end)

-- Apply drug effects
function ApplyDrugEffects(drugType)
    local drugData = Config.DrugEffects[drugType]
    local playerPed = PlayerPedId()
    
    -- Start visual effect
    if drugData.effects.screenEffect then
        AnimpostfxPlay(drugData.effects.screenEffect, 0, true)
    end
    
    -- Apply movement speed
    if drugData.effects.movementSpeed then
        SetRunSprintMultiplierForPlayer(PlayerId(), drugData.effects.movementSpeed)
    end
    
    -- Apply health change
    if drugData.effects.healthIncrease then
        local health = GetEntityHealth(playerPed)
        SetEntityHealth(playerPed, math.min(health + drugData.effects.healthIncrease, 200))
    end
    
    -- Apply stress reduction
    if drugData.effects.stressReduction then
        TriggerServerEvent('hud:server:RelieveStress', drugData.effects.stressReduction)
    end
    
    -- Set active effect
    activeEffects[drugType] = true
    
    -- Notify player
    lib.notify({
        title = 'Drug Effect',
        description = Lang:t('info.drug_effect_active', {drug = drugType}),
        type = 'info'
    })
    
    -- Create thread to handle effect duration
    CreateThread(function()
        local startTime = GetGameTimer()
        local endTime = startTime + (drugData.duration * 1000)
        
        while GetGameTimer() < endTime do
            Wait(1000)
            
            -- Apply periodic effects if needed
            if drugType == 'skunk' or drugType == 'bong_hit' then
                -- Random shaking for strong drugs
                if math.random() < 0.1 then
                    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.2)
                end
            end
        end
        
        -- End effects
        EndDrugEffects(drugType)
    end)
end

-- End drug effects
function EndDrugEffects(drugType)
    local drugData = Config.DrugEffects[drugType]
    
    -- Stop visual effect
    if drugData.effects.screenEffect then
        AnimpostfxStop(drugData.effects.screenEffect)
    end
    
    -- Reset movement speed
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    
    -- Clear active effect
    activeEffects[drugType] = nil
    
    -- Notify player
    lib.notify({
        title = 'Effect Ended',
        description = Lang:t('info.drug_effect_ended', {drug = drugType}),
        type = 'info'
    })
end

-- Cleanup effects on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for drugType, _ in pairs(activeEffects) do
            if Config.DrugEffects[drugType] and Config.DrugEffects[drugType].effects.screenEffect then
                AnimpostfxStop(Config.DrugEffects[drugType].effects.screenEffect)
            end
        end
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    end
end)
