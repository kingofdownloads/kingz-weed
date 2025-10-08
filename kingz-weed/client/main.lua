local QBCore = exports['qb-core']:GetCoreObject()
local plants = {}
local heatLamps = {}
local hydroponicSystems = {}
local isPlanting = false
local isHarvesting = false
local isProcessing = false
local currentPlant = nil
local currentHeatLamp = nil
local currentHydroponicSystem = nil

-- Initialize
Citizen.CreateThread(function()
    -- Request plant models
    for _, plantData in pairs(Config.Plants) do
        for _, stage in pairs(plantData.stages) do
            RequestModel(stage.model)
            while not HasModelLoaded(stage.model) do
                Citizen.Wait(0)
            end
        end
    end
    
    -- Request heat lamp model
    RequestModel(Config.HeatLamps.model)
    while not HasModelLoaded(Config.HeatLamps.model) do
        Citizen.Wait(0)
    end
    
    -- Request hydroponic model
    if Config.Hydroponics.enabled then
        RequestModel(Config.Hydroponics.model)
        while not HasModelLoaded(Config.Hydroponics.model) do
            Citizen.Wait(0)
        end
    end
    
    -- Request plants from server
    TriggerServerEvent('kingz-weed:server:requestPlants')
    
    -- Request heat lamps from server
    TriggerServerEvent('kingz-weed:server:requestHeatLamps')
    
    -- Request hydroponic systems from server
    TriggerServerEvent('kingz-weed:server:requestHydroponics')
end)

-- Load plants from server
RegisterNetEvent('kingz-weed:client:syncPlants', function(serverPlants)
    plants = serverPlants
    
    -- Create plant objects
    for id, plant in pairs(plants) do
        local plantConfig = plant.isHybrid and Config.HybridStrains[plant.type] or Config.Plants[plant.type]
        local model = plantConfig.stages[plant.stage].model
        
        -- Request the model if not already loaded
        if not HasModelLoaded(model) then
            RequestModel(model)
            while not HasModelLoaded(model) do
                Wait(10)
            end
        end
        
        -- Create plant object with proper offset
        local plantObj = CreateObject(model, plant.coords.x, plant.coords.y, plant.coords.z - 0.3, false, false, false)
        SetEntityAsMissionEntity(plantObj, true, true)
        FreezeEntityPosition(plantObj, true)
        
        -- Debug print
        print("Created plant object with model: " .. model .. " at coords: " .. plant.coords.x .. ", " .. plant.coords.y .. ", " .. plant.coords.z)
        
        -- Store object handle
        plants[id].object = plantObj
        
        -- Add zone for interaction
        exports['qb-target']:AddTargetEntity(plantObj, {
            options = {
                {
                    icon = "fas fa-leaf",
                    label = "Check Plant",
                    action = function()
                        TriggerServerEvent('kingz-weed:server:checkPlant', id)
                    end
                },
                {
                    icon = "fas fa-tint",
                    label = "Water Plant",
                    action = function()
                        TriggerServerEvent('kingz-weed:server:waterPlant', id)
                    end
                },
                {
                    icon = "fas fa-seedling",
                    label = "Fertilize Plant",
                    action = function()
                        TriggerServerEvent('kingz-weed:server:fertilizePlant', id)
                    end
                },
                {
                    icon = "fas fa-bug",
                    label = "Apply Pesticide",
                    action = function()
                        TriggerServerEvent('kingz-weed:server:applyPesticide', id)
                    end
                },
                {
                    icon = "fas fa-hand-paper",
                    label = "Remove Bugs",
                    action = function()
                        TriggerServerEvent('kingz-weed:server:removeBugs', id)
                    end
                },
                {
                    icon = "fas fa-pills",
                    label = "Apply Medicine",
                    action = function()
                        TriggerServerEvent('kingz-weed:server:applyMedicine', id)
                    end
                },
                {
                    icon = "fas fa-cut",
                    label = "Harvest Plant",
                    action = function()
                        HarvestPlant(id)
                    end
                },
                {
                    icon = "fas fa-trash",
                    label = "Destroy Plant",
                    action = function()
                        TriggerServerEvent('kingz-weed:server:destroyPlant', id)
                    end
                }
            },
            distance = 2.0
        })
    end
end)

-- Sync heat lamps from server
RegisterNetEvent('kingz-weed:client:syncHeatLamps', function(serverHeatLamps)
    -- Remove existing heat lamp objects
    for id, lamp in pairs(heatLamps) do
        if lamp.object then
            DeleteObject(lamp.object)
        end
    end
    
    heatLamps = serverHeatLamps
    
    -- Create heat lamp objects
    for id, lamp in pairs(heatLamps) do
        -- Create heat lamp object
        local lampObj = CreateObject(Config.HeatLamps.model, lamp.coords.x, lamp.coords.y, lamp.coords.z - 1.0, false, false, false)
        SetEntityAsMissionEntity(lampObj, true, true)
        FreezeEntityPosition(lampObj, true)
        
        -- Store object handle
        heatLamps[id].object = lampObj
        
        -- Add zone for interaction
        exports['qb-target']:AddTargetEntity(lampObj, {
            options = {
                {
                    icon = "fas fa-lightbulb",
                    label = "Pick Up Heat Lamp",
                    action = function()
                        TriggerServerEvent('kingz-weed:server:removeHeatLamp', id)
                    end
                }
            },
            distance = 2.0
        })
    end
end)

-- Sync hydroponic systems from server
RegisterNetEvent('kingz-weed:client:syncHydroponics', function(serverHydroponics)
    -- Remove existing hydroponic system objects
    for id, system in pairs(hydroponicSystems) do
        if system.object then
            DeleteObject(system.object)
        end
    end
    
    hydroponicSystems = serverHydroponics
    
    -- Create hydroponic system objects
    for id, system in pairs(hydroponicSystems) do
        -- Create hydroponic system object
        local systemObj = CreateObject(Config.Hydroponics.model, system.coords.x, system.coords.y, system.coords.z - 1.0, false, false, false)
        SetEntityAsMissionEntity(systemObj, true, true)
        FreezeEntityPosition(systemObj, true)
        
        -- Store object handle
        hydroponicSystems[id].object = systemObj
        
        -- Add zone for interaction
        exports['qb-target']:AddTargetEntity(systemObj, {
            options = {
                {
                    icon = "fas fa-water",
                    label = "Pick Up Hydroponic System",
                    action = function()
                        TriggerServerEvent('kingz-weed:server:removeHydroponics', id)
                    end
                }
            },
            distance = 2.0
        })
    end
end)

-- Update plant data
RegisterNetEvent('kingz-weed:client:updatePlantData', function(plantId, data)
    if plants[plantId] then
        for key, value in pairs(data) do
            plants[plantId][key] = value
        end
        
        -- Update visual indicators
        UpdatePlantVisuals(plantId)
    end
end)

-- Update plant visuals - FIXED VERSION
function UpdatePlantVisuals(plantId)
    local plant = plants[plantId]
    if not plant or not plant.object then return end
    
    -- Water status - blue particles when well watered
    if plant.water > 80 then
        if not plant.waterEffect then
            plant.waterEffect = StartParticleFxLoopedOnEntity("ent_amb_water_drips", plant.object, 0.0, 0.0, 0.5, 0.0, 0.0, 0.0, 1.0, false, false, false)
        end
    else
        if plant.waterEffect then
            StopParticleFxLooped(plant.waterEffect, false)
            plant.waterEffect = nil
        end
    end
    
    -- Fertilizer status - green glow when well fertilized
    if plant.fertilizer > 80 then
        if not plant.fertilizerEffect then
            plant.fertilizerEffect = StartParticleFxLoopedOnEntity("ent_amb_fbi_smoke_land", plant.object, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, false, false, false)
        end
    else
        if plant.fertilizerEffect then
            StopParticleFxLooped(plant.fertilizerEffect, false)
            plant.fertilizerEffect = nil
        end
    end
    
    -- Bug infestation - add bug particles
    if plant.hasBugs then
        if not plant.bugEffect then
            plant.bugEffect = StartParticleFxLoopedOnEntity("ent_amb_flies_swarm", plant.object, 0.0, 0.0, 0.3, 0.0, 0.0, 0.0, 1.0, false, false, false)
        end
    else
        if plant.bugEffect then
            StopParticleFxLooped(plant.bugEffect, false)
            plant.bugEffect = nil
        end
    end
    
    -- Disease effect - yellowish tint
    if plant.hasDisease then
        SetEntityHealth(plant.object, 50) -- Make it look unhealthy
    else
        SetEntityHealth(plant.object, 1000) -- Make it look healthy
    end
    
    -- Heat lamp effect - reddish glow
    if plant.isUnderHeatLamp then
        if not plant.heatEffect then
            plant.heatEffect = StartParticleFxLoopedOnEntity("ent_amb_fbi_fire_beam", plant.object, 0.0, 0.0, 0.8, 0.0, 0.0, 0.0, 0.5, false, false, false)
        end
    else
        if plant.heatEffect then
            StopParticleFxLooped(plant.heatEffect, false)
            plant.heatEffect = nil
        end
    end
    
    -- Hydroponic effect - blue/green glow
    if plant.isHydroponic then
        if not plant.hydroEffect then
            plant.hydroEffect = StartParticleFxLoopedOnEntity("ent_amb_water_splash", plant.object, 0.0, 0.0, -0.3, 0.0, 0.0, 0.0, 1.0, false, false, false)
        end
    else
        if plant.hydroEffect then
            StopParticleFxLooped(plant.hydroEffect, false)
            plant.hydroEffect = nil
        end
    end
    
    -- COMPLETELY REMOVED the SetEntityScale code
    -- Instead, we'll just adjust the health visual
    local healthPercent = plant.health / 100
    if healthPercent < 0.5 then
        -- Make plant look unhealthy if health is low
        SetEntityHealth(plant.object, math.floor(healthPercent * 200))
    end
end

-- Update plant stage
RegisterNetEvent('kingz-weed:client:updatePlant', function(plantId, stage, data)
    if plants[plantId] then
        -- Update plant data
        plants[plantId].stage = stage
        
        for key, value in pairs(data) do
            plants[plantId][key] = value
        end
        
        -- Update plant model
        if plants[plantId].object then
            DeleteObject(plants[plantId].object)
        end
        
        local plantConfig = plants[plantId].isHybrid and Config.HybridStrains[plants[plantId].type] or Config.Plants[plants[plantId].type]
        local model = plantConfig.stages[stage].model
        
        -- Request the model if not already loaded
        if not HasModelLoaded(model) then
            RequestModel(model)
            while not HasModelLoaded(model) do
                Wait(10)
            end
        end
        
        -- Create new plant object with proper ground offset
        local plantObj = CreateObject(model, plants[plantId].coords.x, plants[plantId].coords.y, plants[plantId].coords.z - 0.3, false, false, false)
        SetEntityAsMissionEntity(plantObj, true, true)
        FreezeEntityPosition(plantObj, true)
        
        -- Store object handle
        plants[plantId].object = plantObj
        
        -- Add zone for interaction
        exports['qb-target']:AddTargetEntity(plantObj, {
            options = {
                {
                    icon = "fas fa-leaf",
                    label = "Check Plant",
                    action = function()
                        TriggerServerEvent('kingz-weed:server:checkPlant', plantId)
                    end
                },
                {
                    icon = "fas fa-tint",
                    label = "Water Plant",
                    action = function()
                        TriggerServerEvent('kingz-weed:server:waterPlant', plantId)
                    end
                },
                {
                    icon = "fas fa-seedling",
                    label = "Fertilize Plant",
                    action = function()
                        TriggerServerEvent('kingz-weed:server:fertilizePlant', plantId)
                    end
                },
                {
                    icon = "fas fa-bug",
                    label = "Apply Pesticide",
                    action = function()
                        TriggerServerEvent('kingz-weed:server:applyPesticide', plantId)
                    end
                },
                {
                    icon = "fas fa-hand-paper",
                    label = "Remove Bugs",
                    action = function()
                        TriggerServerEvent('kingz-weed:server:removeBugs', plantId)
                    end
                },
                {
                    icon = "fas fa-pills",
                    label = "Apply Medicine",
                    action = function()
                        TriggerServerEvent('kingz-weed:server:applyMedicine', plantId)
                    end
                },
                {
                    icon = "fas fa-cut",
                    label = "Harvest Plant",
                    action = function()
                        HarvestPlant(plantId)
                    end
                },
                {
                    icon = "fas fa-trash",
                    label = "Destroy Plant",
                    action = function()
                        TriggerServerEvent('kingz-weed:server:destroyPlant', plantId)
                    end
                }
            },
            distance = 2.0
        })
        
        -- Update visual indicators
        UpdatePlantVisuals(plantId)
    end
end)

-- Remove plant
RegisterNetEvent('kingz-weed:client:removePlant', function(plantId)
    if plants[plantId] and plants[plantId].object then
        DeleteObject(plants[plantId].object)
    end
    
    plants[plantId] = nil
end)

-- Plant a seed
RegisterNetEvent('kingz-weed:client:plantSeed', function(item)
    if isPlanting then return end
    
    isPlanting = true
    
    -- Check if player is outdoors or in a valid growing location
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    if IsEntityInWater(playerPed) then
        QBCore.Functions.Notify('You cannot plant in water', 'error')
        isPlanting = false
        return
    end
    
    -- Check if player is in a vehicle
    if IsPedInAnyVehicle(playerPed, false) then
        QBCore.Functions.Notify('You cannot plant while in a vehicle', 'error')
        isPlanting = false
        return
    end
    
    -- Check if player is too close to another plant
    for _, plant in pairs(plants) do
        if #(coords - vector3(plant.coords.x, plant.coords.y, plant.coords.z)) < 1.0 then
            QBCore.Functions.Notify('You cannot plant this close to another plant', 'error')
            isPlanting = false
            return
        end
    end
    
    -- Check if player is indoors
    local isIndoors = GetInteriorFromEntity(playerPed) ~= 0
    
    if isIndoors then
        -- Check if player is in a valid growing location
        local validLocation = false
        for _, location in ipairs(Config.IndoorLocations) do
            if #(coords - vector4(location.coords.x, location.coords.y, location.coords.z, location.coords.w)) < 50.0 then
                validLocation = true
                break
            end
        end
        
        if not validLocation then
            QBCore.Functions.Notify('You cannot plant indoors except in designated growing locations', 'error')
            isPlanting = false
            return
        end
    end
    
    -- Animation
    TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_GARDENER_PLANT", 0, true)
    
    QBCore.Functions.Progressbar("planting_seed", "Planting Seed...", 5000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        ClearPedTasks(playerPed)
        
        -- Generate plant ID
        local plantId = "plant_" .. math.random(100000, 999999)
        
        -- Get ground position
        local groundZ = coords.z
        local success, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, true)
        
        -- Plant coordinates - Adjusted to be at ground level
        local plantCoords = {
            x = coords.x,
            y = coords.y,
            z = groundZ -- At ground level
        }

        
        -- Debug print
        print("Planting seed at coordinates: " .. plantCoords.x .. ", " .. plantCoords.y .. ", " .. plantCoords.z)
        
        -- Remove seed from inventory
        TriggerServerEvent('kingz-weed:server:removeSeed', item.name)
        
        -- Create plant on server
        TriggerServerEvent('kingz-weed:server:plantSeed', plantId, item.name, plantCoords)
        
        QBCore.Functions.Notify('You planted a seed', 'success')
        
        isPlanting = false
    end, function() -- Cancel
        ClearPedTasks(playerPed)
        QBCore.Functions.Notify('You cancelled planting', 'error')
        isPlanting = false
    end)
end)

-- Place heat lamp
RegisterNetEvent('kingz-weed:client:placeHeatLamp', function()
    if currentHeatLamp then return end
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    -- Check if player is in a vehicle
    if IsPedInAnyVehicle(playerPed, false) then
        QBCore.Functions.Notify('You cannot place a heat lamp while in a vehicle', 'error')
        return
    end
    
    -- Create preview object
    local lampObj = CreateObject(Config.HeatLamps.model, coords.x, coords.y, coords.z - 1.0, false, false, false)
    SetEntityAlpha(lampObj, 200, false)
    SetEntityCollision(lampObj, false, false)
    
    currentHeatLamp = {
        object = lampObj,
        coords = coords
    }
    
    -- Instructions
    QBCore.Functions.Notify('Move to position and press [E] to place, [G] to cancel', 'primary', 5000)
    
    -- Placement loop
    Citizen.CreateThread(function()
        while currentHeatLamp do
            Citizen.Wait(0)
            
            -- Update position
            local playerCoords = GetEntityCoords(playerPed)
            local forward = GetEntityForwardVector(playerPed)
            local placementCoords = vector3(
                playerCoords.x + forward.x * 1.0,
                playerCoords.y + forward.y * 1.0,
                playerCoords.z
            )
            
            -- Get ground position
            local groundZ = placementCoords.z
            local success, groundZ = GetGroundZFor_3dCoord(placementCoords.x, placementCoords.y, placementCoords.z, true)
            placementCoords = vector3(placementCoords.x, placementCoords.y, groundZ + 0.2)
            
            -- Update preview object
            SetEntityCoords(currentHeatLamp.object, placementCoords.x, placementCoords.y, placementCoords.z - 1.0, false, false, false, false)
            
            -- Controls
            if IsControlJustPressed(0, 38) then -- E key
                -- Place heat lamp
                DeleteObject(currentHeatLamp.object)
                
                -- Generate lamp ID
                local lampId = "lamp_" .. math.random(100000, 999999)
                
                -- Create heat lamp on server
                TriggerServerEvent('kingz-weed:server:placeHeatLamp', lampId, {
                    x = placementCoords.x,
                    y = placementCoords.y,
                    z = placementCoords.z
                })
                
                QBCore.Functions.Notify('You placed a heat lamp', 'success')
                
                currentHeatLamp = nil
            elseif IsControlJustPressed(0, 47) then -- G key
                -- Cancel placement
                DeleteObject(currentHeatLamp.object)
                
                QBCore.Functions.Notify('You cancelled placing the heat lamp', 'error')
                
                currentHeatLamp = nil
            end
        end
    end)
end)

-- Place hydroponic system
RegisterNetEvent('kingz-weed:client:placeHydroponics', function()
    if not Config.Hydroponics.enabled then return end
    if currentHydroponicSystem then return end
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    -- Check if player is in a vehicle
    if IsPedInAnyVehicle(playerPed, false) then
        QBCore.Functions.Notify('You cannot place a hydroponic system while in a vehicle', 'error')
        return
    end
    
    -- Check if player is indoors
    local isIndoors = GetInteriorFromEntity(playerPed) ~= 0
    
    if not isIndoors then
        QBCore.Functions.Notify('Hydroponic systems can only be placed indoors', 'error')
        return
    end
    
    -- Create preview object
    local systemObj = CreateObject(Config.Hydroponics.model, coords.x, coords.y, coords.z - 1.0, false, false, false)
    SetEntityAlpha(systemObj, 200, false)
    SetEntityCollision(systemObj, false, false)
    
    currentHydroponicSystem = {
        object = systemObj,
        coords = coords
    }
    
    -- Instructions
    QBCore.Functions.Notify('Move to position and press [E] to place, [G] to cancel', 'primary', 5000)
    
    -- Placement loop
    Citizen.CreateThread(function()
        while currentHydroponicSystem do
            Citizen.Wait(0)
            
            -- Update position
            local playerCoords = GetEntityCoords(playerPed)
            local forward = GetEntityForwardVector(playerPed)
            local placementCoords = vector3(
                playerCoords.x + forward.x * 1.0,
                playerCoords.y + forward.y * 1.0,
                playerCoords.z
            )
            
            -- Update preview object
            SetEntityCoords(currentHydroponicSystem.object, placementCoords.x, placementCoords.y, placementCoords.z - 1.0, false, false, false, false)
            
            -- Controls
            if IsControlJustPressed(0, 38) then -- E key
                -- Place hydroponic system
                DeleteObject(currentHydroponicSystem.object)
                
                -- Generate system ID
                local systemId = "hydro_" .. math.random(100000, 999999)
                
                -- Create hydroponic system on server
                TriggerServerEvent('kingz-weed:server:placeHydroponics', systemId, {
                    x = placementCoords.x,
                    y = placementCoords.y,
                    z = placementCoords.z
                })
                
                QBCore.Functions.Notify('You placed a hydroponic system', 'success')
                
                currentHydroponicSystem = nil
            elseif IsControlJustPressed(0, 47) then -- G key
                -- Cancel placement
                DeleteObject(currentHydroponicSystem.object)
                
                QBCore.Functions.Notify('You cancelled placing the hydroponic system', 'error')
                
                currentHydroponicSystem = nil
            end
        end
    end)
end)

-- Show plant info
RegisterNetEvent('kingz-weed:client:showPlantInfo', function(plant)
    -- Calculate time left - FIXED: Replaced os.time()
    local timeLeft = plant.nextGrowth - math.floor(GetGameTimer() / 1000)
    local plantConfig = plant.isHybrid and Config.HybridStrains[plant.type] or Config.Plants[plant.type]
    
    -- Create interactive UI
    SendNUIMessage({
        type = "showPlantInfo",
        plantInfo = {
            id = plant.id,
            name = plantConfig.label,
            stage = plant.stage,
            maxStage = #plantConfig.stages,
            water = math.floor(plant.water),
            fertilizer = math.floor(plant.fertilizer),
            health = math.floor(plant.health),
            quality = plant.quality or 50,
            qualityLevel = plant.qualityLevel or "Standard",
            timeLeft = timeLeft > 0 and math.ceil(timeLeft / 60) or 0,
            hasBugs = plant.hasBugs,
            hasDisease = plant.hasDisease,
            isUnderHeatLamp = plant.isUnderHeatLamp,
            isHydroponic = plant.isHydroponic,
            thcContent = plantConfig.thcContent,
            cbdContent = plantConfig.cbdContent,
            isHybrid = plant.isHybrid,
            readyToHarvest = plant.stage == #plantConfig.stages
        }
    })
    
    -- Show plant care options
    SetNuiFocus(true, true)
end)

-- Harvest plant - FIXED: Updated notification style
function HarvestPlant(plantId)
    if isHarvesting then return end
    if not plants[plantId] then return end
    
    local plantConfig = plants[plantId].isHybrid and Config.HybridStrains[plants[plantId].type] or Config.Plants[plants[plantId].type]
    
    -- Check if plant is ready to harvest
    if plants[plantId].stage < #plantConfig.stages then
        QBCore.Functions.Notify('This plant is not ready to harvest yet', 'error')
        return
    end
    
    isHarvesting = true
    currentPlant = plantId
    
    -- Start harvesting minigame
    local playerPed = PlayerPedId()
    
    -- Create interactive harvesting UI
    SendNUIMessage({
        type = "startHarvesting",
        plantInfo = {
            id = plantId,
            name = plantConfig.label,
            quality = plants[plantId].quality or 50,
            leaves = Config.Harvesting.requiredLeaves
        }
    })
    
    SetNuiFocus(true, true)
    
    -- Play harvesting animation
    TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_GARDENER_PLANT", 0, true)
end

-- NUI callback for harvesting progress
RegisterNUICallback('harvestProgress', function(data, cb)
    local plantId = data.plantId
    local progress = data.progress
    
    if progress >= 100 then
        -- Harvesting complete
        ClearPedTasks(PlayerPedId())
        
        -- Complete harvest on server
        TriggerServerEvent('kingz-weed:server:harvestPlant', plantId)
        
        QBCore.Functions.Notify('You successfully harvested the plant', 'success')
        
        isHarvesting = false
        currentPlant = nil
        SetNuiFocus(false, false)
    end
    
    cb({})
end)

RegisterNUICallback('cancelHarvest', function(data, cb)
    ClearPedTasks(PlayerPedId())
    isHarvesting = false
    currentPlant = nil
    SetNuiFocus(false, false)
    
    QBCore.Functions.Notify('You cancelled harvesting the plant', 'error')
    
    cb({})
end)

-- NUI callback for plant actions
RegisterNUICallback('plantAction', function(data, cb)
    local plantId = data.plantId
    local action = data.action
    
    if action == "water" then
        TriggerServerEvent('kingz-weed:server:waterPlant', plantId)
    elseif action == "fertilize" then
        TriggerServerEvent('kingz-weed:server:fertilizePlant', plantId)
    elseif action == "pesticide" then
        TriggerServerEvent('kingz-weed:server:applyPesticide', plantId)
    elseif action == "medicine" then
        TriggerServerEvent('kingz-weed:server:applyMedicine', plantId)
    elseif action == "harvest" then
        HarvestPlant(plantId)
    elseif action == "destroy" then
        TriggerServerEvent('kingz-weed:server:destroyPlant', plantId)
    end
    
    SetNuiFocus(false, false)
    cb({})
end)

RegisterNUICallback('closeMenu', function(data, cb)
    SetNuiFocus(false, false)
    cb({})
end)

-- Use bong
RegisterNetEvent('kingz-weed:client:useBong', function()
    QBCore.Functions.TriggerCallback('kingz-weed:server:hasAnyWeed', function(hasWeed, weedType)
        if not hasWeed then
            QBCore.Functions.Notify('You need weed to use a bong', 'error')
            return
        end
        
        -- Show menu to select weed type
        QBCore.Functions.TriggerCallback('kingz-weed:server:getPlayerWeed', function(items)
            if #items == 0 then
                QBCore.Functions.Notify('You need weed to use a bong', 'error')
                return
            end
            
                        local options = {
                {
                    title = 'Select Weed for Bong',
                    description = 'Choose which weed to smoke',
                    icon = 'cannabis',
                }
            }
            
            for _, item in ipairs(items) do
                table.insert(options, {
                    title = 'Use ' .. item.label,
                    description = 'You have x' .. item.amount,
                    icon = 'cannabis',
                    onSelect = function()
                        UseBong(item.name)
                    end
                })
            end
            
            lib.registerContext({
                id = 'bong_menu',
                title = 'Bong',
                options = options
            })
            
            lib.showContext('bong_menu')
        end)
    end)
end)

-- Use bong with selected weed
function UseBong(weedType)
    local playerPed = PlayerPedId()
    
    -- Animation
    TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_SMOKING_POT", 0, true)
    
    QBCore.Functions.Progressbar("using_bong", "Using Bong...", 8000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        ClearPedTasks(playerPed)
        
        -- Remove weed from inventory
        TriggerServerEvent('kingz-weed:server:removeWeedForBong', weedType)
        
        -- Apply drug effect
        ApplyDrugEffect('bong_hit')
        
        QBCore.Functions.Notify('You took a hit from the bong', 'success')
    end, function() -- Cancel
        ClearPedTasks(playerPed)
        
        QBCore.Functions.Notify('You cancelled using the bong', 'error')
    end)
end

-- Use grinder
RegisterNetEvent('kingz-weed:client:useGrinder', function()
    QBCore.Functions.TriggerCallback('kingz-weed:server:hasAnyWeed', function(hasWeed, weedType)
        if not hasWeed then
            QBCore.Functions.Notify('You need weed to use a grinder', 'error')
            return
        end
        
        -- Show menu to select weed type
        QBCore.Functions.TriggerCallback('kingz-weed:server:getPlayerWeed', function(items)
            if #items == 0 then
                QBCore.Functions.Notify('You need weed to use a grinder', 'error')
                return
            end
            
            local options = {
                {
                    title = 'Select Weed to Grind',
                    description = 'Choose which weed to grind',
                    icon = 'cannabis',
                }
            }
            
            for _, item in ipairs(items) do
                table.insert(options, {
                    title = 'Grind ' .. item.label,
                    description = 'You have x' .. item.amount,
                    icon = 'cannabis',
                    onSelect = function()
                        UseGrinder(item.name)
                    end
                })
            end
            
            lib.registerContext({
                id = 'grinder_menu',
                title = 'Grinder',
                options = options
            })
            
            lib.showContext('grinder_menu')
        end)
    end)
end)

-- Use grinder with selected weed
function UseGrinder(weedType)
    local playerPed = PlayerPedId()
    
    -- Animation
    TaskStartScenarioInPlace(playerPed, "PROP_HUMAN_PARKING_METER", 0, true)
    
    QBCore.Functions.Progressbar("using_grinder", "Grinding Weed...", Config.Processing.grindTime * 1000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        ClearPedTasks(playerPed)
        
        -- Grind weed on server
        TriggerServerEvent('kingz-weed:server:grindWeed', weedType)
        
        QBCore.Functions.Notify('You ground up the weed', 'success')
    end, function() -- Cancel
        ClearPedTasks(playerPed)
        
        QBCore.Functions.Notify('You cancelled grinding the weed', 'error')
    end)
end

-- Process weed function
function ProcessWeed(itemName, processType, progressText, duration)
    if isProcessing then return end
    
    -- Check if player has required items
    QBCore.Functions.TriggerCallback('kingz-weed:server:canProcess', function(canProcess, missingItem)
        if canProcess then
            isProcessing = true
            
            -- Play processing animation
            local playerPed = PlayerPedId()
            TaskStartScenarioInPlace(playerPed, "PROP_HUMAN_PARKING_METER", 0, true)
            
            QBCore.Functions.Progressbar("processing_weed", progressText, duration * 1000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {}, {}, {}, function() -- Done
                ClearPedTasks(playerPed)
                isProcessing = false
                
                -- Process the weed
                TriggerServerEvent('kingz-weed:server:processWeed', itemName, processType)
                
                QBCore.Functions.Notify('Processing complete', 'success')
            end, function() -- Cancel
                ClearPedTasks(playerPed)
                isProcessing = false
                
                QBCore.Functions.Notify('Processing canceled', 'error')
            end)
        else
            QBCore.Functions.Notify(missingItem, 'error')
        end
    end, itemName, processType)
end

-- Apply drug effect
function ApplyDrugEffect(drugType)
    local playerPed = PlayerPedId()
    local drugConfig = Config.DrugEffects[drugType]
    
    if not drugConfig then
        -- Try to find base drug type (remove _joint suffix)
        local baseDrugType = drugType:gsub("_joint", "")
        drugConfig = Config.DrugEffects[baseDrugType]
        
        if not drugConfig then
            return
        end
    end
    
    -- Apply screen effect
    if drugConfig.effects.screenEffect then
        AnimpostfxPlay(drugConfig.effects.screenEffect, 0, true)
        
        -- Clear screen effect after duration
        Citizen.SetTimeout(drugConfig.duration * 1000, function()
            AnimpostfxStop(drugConfig.effects.screenEffect)
        end)
    end
    
    -- Apply movement speed
    if drugConfig.effects.movementSpeed then
        -- Store original speed
        local originalSpeed = GetEntitySpeed(playerPed)
        
        -- Set movement speed multiplier
        SetRunSprintMultiplierForPlayer(PlayerId(), drugConfig.effects.movementSpeed)
        
        -- Reset movement speed after duration
        Citizen.SetTimeout(drugConfig.duration * 1000, function()
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        end)
    end
    
    -- Apply stress reduction
    if drugConfig.effects.stressReduction then
        -- Implement stress reduction based on your stress system
        -- Example: TriggerEvent('stress:remove', drugConfig.effects.stressReduction)
        TriggerEvent('hud:client:UpdateStress', -drugConfig.effects.stressReduction)
    end
    
    -- Apply health increase
    if drugConfig.effects.healthIncrease then
        local currentHealth = GetEntityHealth(playerPed)
        local maxHealth = GetEntityMaxHealth(playerPed)
        local newHealth = math.min(maxHealth, currentHealth + drugConfig.effects.healthIncrease)
        
        SetEntityHealth(playerPed, newHealth)
    end
end

-- Processing menu
RegisterCommand('processweed', function()
    QBCore.Functions.TriggerCallback('kingz-weed:server:getPlayerWeed', function(items)
        if #items == 0 then
            QBCore.Functions.Notify('You don\'t have any weed to process', 'error')
            return
        end
        
        local options = {
            {
                title = 'Weed Processing',
                description = 'Process your harvested weed',
                icon = 'cannabis',
            }
        }
        
        for _, item in ipairs(items) do
            table.insert(options, {
                title = 'Process ' .. item.label,
                description = 'You have x' .. item.amount,
                icon = 'joint',
                onSelect = function()
                    OpenProcessOptions(item.name, item.label, item.amount)
                end
            })
        end
        
        lib.registerContext({
            id = 'processing_menu',
            title = 'Weed Processing',
            options = options
        })
        
        lib.showContext('processing_menu')
    end)
end, false)

-- Process options menu
function OpenProcessOptions(itemName, itemLabel, amount)
    local options = {
        {
            title = 'Process ' .. itemLabel,
            description = 'Select a processing method',
            icon = 'cannabis',
        },
        {
            title = 'Roll Joint',
            description = 'Create a joint from ' .. itemLabel,
            icon = 'joint',
            onSelect = function()
                ProcessWeed(itemName, 'joint', 'Rolling joint', Config.Processing.rollTime)
            end
        },
        {
            title = 'Package Weed',
            description = 'Package ' .. itemLabel .. ' for sale',
            icon = 'box',
            onSelect = function()
                ProcessWeed(itemName, 'packaged', 'Packaging weed', Config.Processing.baggieTime)
            end
        },
        {
            title = 'Extract Concentrate',
            description = 'Extract concentrate from ' .. itemLabel,
            icon = 'vial',
            onSelect = function()
                ProcessWeed(itemName, 'concentrate', 'Extracting concentrate', Config.Processing.extractTime)
            end
        },
        {
            title = 'Make Edibles',
            description = 'Make edibles with ' .. itemLabel,
            icon = 'cookie',
            onSelect = function()
                ProcessWeed(itemName, 'edible', 'Making edibles', Config.Processing.edibleTime)
            end
        },
        {
            title = 'Back',
            icon = 'arrow-left',
            onSelect = function()
                OpenProcessingMenu()
            end
        }
    }
    
    lib.registerContext({
        id = 'process_options',
        title = 'Process ' .. itemLabel,
        options = options
    })
    
    lib.showContext('process_options')
end

-- Helper function to reopen the processing menu
function OpenProcessingMenu()
    QBCore.Functions.TriggerCallback('kingz-weed:server:getPlayerWeed', function(items)
        if #items == 0 then
            QBCore.Functions.Notify('You don\'t have any weed to process', 'error')
            return
        end
        
        local options = {
            {
                title = 'Weed Processing',
                description = 'Process your harvested weed',
                icon = 'cannabis',
            }
        }
        
        for _, item in ipairs(items) do
            table.insert(options, {
                title = 'Process ' .. item.label,
                description = 'You have x' .. item.amount,
                icon = 'joint',
                onSelect = function()
                    OpenProcessOptions(item.name, item.label, item.amount)
                end
            })
        end
        
        lib.registerContext({
            id = 'processing_menu',
            title = 'Weed Processing',
            options = options
        })
        
        lib.showContext('processing_menu')
    end)
end

