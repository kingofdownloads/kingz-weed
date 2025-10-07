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
        local plantObj = CreateObject(model, plant.coords.x, plant.coords.y, plant.coords.z, false, false, false)
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
        
        -- Create new plant object
        local plantObj = CreateObject(model, plants[plantId].coords.x, plants[plantId].coords.y, plants[plantId].coords.z - 1.0, false, false, false)
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
        
        -- Plant coordinates
        local plantCoords = {
            x = coords.x,
            y = coords.y,
            z = groundZ + 0.2 -- Slightly above ground
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

-- Extract concentrate
RegisterNetEvent('kingz-weed:client:extractConcentrate', function()
    QBCore.Functions.TriggerCallback('kingz-weed:server:hasAnyWeed', function(hasWeed, weedType)
        if not hasWeed then
            QBCore.Functions.Notify('You need weed to extract concentrate', 'error')
            return
        end
        
        -- Show menu to select weed type
        QBCore.Functions.TriggerCallback('kingz-weed:server:getPlayerWeed', function(items)
            if #items == 0 then
                QBCore.Functions.Notify('You need weed to extract concentrate', 'error')
                return
            end
            
            local options = {
                {
                    title = 'Select Weed for Extraction',
                    description = 'Choose which weed to extract concentrate from',
                    icon = 'cannabis',
                }
            }
            
            for _, item in ipairs(items) do
                table.insert(options, {
                    title = 'Extract from ' .. item.label,
                    description = 'You have x' .. item.amount,
                    icon = 'cannabis',
                    onSelect = function()
                        ExtractConcentrate(item.name)
                    end
                })
            end
            
            lib.registerContext({
                id = 'extraction_menu',
                title = 'Concentrate Extraction',
                options = options
            })
            
            lib.showContext('extraction_menu')
        end)
    end)
end)

-- Extract concentrate from selected weed
function ExtractConcentrate(weedType)
    local playerPed = PlayerPedId()
    
    -- Animation
    TaskStartScenarioInPlace(playerPed, "PROP_HUMAN_PARKING_METER", 0, true)
    
    QBCore.Functions.Progressbar("extracting_concentrate", "Extracting Concentrate...", Config.Processing.extractTime * 1000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        ClearPedTasks(playerPed)
        
        -- Process weed on server
        TriggerServerEvent('kingz-weed:server:processWeed', weedType, 'concentrate')
        
        QBCore.Functions.Notify('You extracted concentrate from the weed', 'success')
    end, function() -- Cancel
        ClearPedTasks(playerPed)
        
        QBCore.Functions.Notify('You cancelled the extraction', 'error')
    end)
end

-- Make edibles
RegisterNetEvent('kingz-weed:client:makeEdibles', function()
    QBCore.Functions.TriggerCallback('kingz-weed:server:hasAnyWeed', function(hasWeed, weedType)
        if not hasWeed then
            QBCore.Functions.Notify('You need weed to make edibles', 'error')
            return
        end
        
        -- Show menu to select weed type
        QBCore.Functions.TriggerCallback('kingz-weed:server:getPlayerWeed', function(items)
            if #items == 0 then
                QBCore.Functions.Notify('You need weed to make edibles', 'error')
                return
            end
            
            local options = {
                {
                    title = 'Select Weed for Edibles',
                    description = 'Choose which weed to use in edibles',
                    icon = 'cannabis',
                }
            }
            
            for _, item in ipairs(items) do
                table.insert(options, {
                    title = 'Use ' .. item.label,
                    description = 'You have x' .. item.amount,
                    icon = 'cannabis',
                    onSelect = function()
                        MakeEdibles(item.name)
                    end
                })
            end
            
            lib.registerContext({
                id = 'edibles_menu',
                title = 'Make Edibles',
                options = options
            })
            
            lib.showContext('edibles_menu')
        end)
    end)
end)

-- Make edibles with selected weed
function MakeEdibles(weedType)
    local playerPed = PlayerPedId()
    
    -- Animation
    TaskStartScenarioInPlace(playerPed, "PROP_HUMAN_BBQ", 0, true)
    
    QBCore.Functions.Progressbar("making_edibles", "Making Edibles...", Config.Processing.edibleTime * 1000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        ClearPedTasks(playerPed)
        
        -- Process weed on server
        TriggerServerEvent('kingz-weed:server:processWeed', weedType, 'edible')
        
        QBCore.Functions.Notify('You made weed brownies', 'success')
    end, function() -- Cancel
        ClearPedTasks(playerPed)
        
        QBCore.Functions.Notify('You cancelled making edibles', 'error')
    end)
end

-- Show plant medicine menu
RegisterNetEvent('kingz-weed:client:showPlantMedicineMenu', function()
    -- Get nearby plants
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local nearbyPlants = {}
    
    for id, plant in pairs(plants) do
        local plantCoords = vector3(plant.coords.x, plant.coords.y, plant.coords.z)
        local distance = #(playerCoords - plantCoords)
        
        if distance <= 3.0 then
            table.insert(nearbyPlants, {
                id = id,
                distance = distance,
                type = plant.isHybrid and Config.HybridStrains[plant.type].label or Config.Plants[plant.type].label,
                hasDisease = plant.hasDisease
            })
        end
    end
    
    if #nearbyPlants == 0 then
        QBCore.Functions.Notify('There are no plants within range', 'error')
        return
    end
    
    -- Sort by distance
    table.sort(nearbyPlants, function(a, b)
        return a.distance < b.distance
    end)
    
    -- Create menu options
    local options = {
        {
            title = 'Apply Plant Medicine',
            description = 'Select a plant to treat',
            icon = 'pills',
        }
    }
    
    for _, plant in ipairs(nearbyPlants) do
        local status = plant.hasDisease and "Diseased" or "Healthy"
        local icon = plant.hasDisease and "virus" or "check"
        
        table.insert(options, {
            title = plant.type,
            description = 'Status: ' .. status .. ' (Distance: ' .. string.format("%.1f", plant.distance) .. 'm)',
            icon = icon,
            onSelect = function()
                TriggerServerEvent('kingz-weed:server:applyMedicine', plant.id)
            end
        })
    end
    
    lib.registerContext({
        id = 'medicine_menu',
        title = 'Plant Medicine',
        options = options
    })
    
    lib.showContext('medicine_menu')
end)

-- Show soil menu
RegisterNetEvent('kingz-weed:client:showSoilMenu', function()
    -- Get nearby plants
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local nearbyPlants = {}
    
    for id, plant in pairs(plants) do
        local plantCoords = vector3(plant.coords.x, plant.coords.y, plant.coords.z)
        local distance = #(playerCoords - plantCoords)
        
        if distance <= 3.0 then
            table.insert(nearbyPlants, {
                id = id,
                distance = distance,
                type = plant.isHybrid and Config.HybridStrains[plant.type].label or Config.Plants[plant.type].label,
                soilQuality = plant.soilQuality or 1.0
            })
        end
    end
    
    if #nearbyPlants == 0 then
        QBCore.Functions.Notify('There are no plants within range', 'error')
        return
    end
    
    -- Sort by distance
    table.sort(nearbyPlants, function(a, b)
        return a.distance < b.distance
    end)
    
    -- Create menu options
    local options = {
        {
            title = 'Apply Premium Soil',
            description = 'Select a plant to improve soil',
            icon = 'mountain',
        }
    }
    
    for _, plant in ipairs(nearbyPlants) do
        local soilStatus = plant.soilQuality > 1.0 and "Premium" or "Standard"
        local icon = plant.soilQuality > 1.0 and "check" or "mountain"
        
        table.insert(options, {
            title = plant.type,
            description = 'Soil: ' .. soilStatus .. ' (Distance: ' .. string.format("%.1f", plant.distance) .. 'm)',
            icon = icon,
            onSelect = function()
                TriggerServerEvent('kingz-weed:server:applyPremiumSoil', plant.id)
            end
        })
    end
    
    lib.registerContext({
        id = 'soil_menu',
        title = 'Premium Soil',
        options = options
    })
    
    lib.showContext('soil_menu')
end)

-- Show nutrition menu
RegisterNetEvent('kingz-weed:client:showNutritionMenu', function()
    -- Get nearby plants
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local nearbyPlants = {}
    
    for id, plant in pairs(plants) do
        local plantCoords = vector3(plant.coords.x, plant.coords.y, plant.coords.z)
        local distance = #(playerCoords - plantCoords)
        
        if distance <= 3.0 then
            table.insert(nearbyPlants, {
                id = id,
                distance = distance,
                type = plant.isHybrid and Config.HybridStrains[plant.type].label or Config.Plants[plant.type].label,
                health = plant.health
            })
        end
    end
    
    if #nearbyPlants == 0 then
        QBCore.Functions.Notify('There are no plants within range', 'error')
        return
    end
    
    -- Sort by distance
    table.sort(nearbyPlants, function(a, b)
        return a.distance < b.distance
    end)
    
    -- Create menu options
    local options = {
        {
            title = 'Apply Nutrition Booster',
            description = 'Select a plant to boost',
            icon = 'flask',
        }
    }
    
    for _, plant in ipairs(nearbyPlants) do
        local healthStatus = ""
        local icon = ""
        
        if plant.health > 80 then
            healthStatus = "Excellent"
            icon = "heart"
        elseif plant.health > 50 then
            healthStatus = "Good"
            icon = "heart-half"
        else
            healthStatus = "Poor"
            icon = "heart-broken"
        end
        
        table.insert(options, {
            title = plant.type,
            description = 'Health: ' .. healthStatus .. ' (' .. math.floor(plant.health) .. '%) (Distance: ' .. string.format("%.1f", plant.distance) .. 'm)',
            icon = icon,
            onSelect = function()
                TriggerServerEvent('kingz-weed:server:applyNutrition', plant.id)
            end
        })
    end
    
    lib.registerContext({
        id = 'nutrition_menu',
        title = 'Nutrition Booster',
        options = options
    })
    
    lib.showContext('nutrition_menu')
end)

-- Use drug
RegisterNetEvent('kingz-weed:client:useDrug', function(drugType)
    local playerPed = PlayerPedId()
    
    -- Animation
    if string.find(drugType, "joint") then
        TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_SMOKING_POT", 0, true)
    elseif drugType == "weed_brownie" then
        TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_SEAT_LEDGE_EATING", 0, true)
    elseif drugType == "weed_concentrate" then
        TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_SMOKING_POT", 0, true)
    else
        TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_SMOKING_POT", 0, true)
    end
    
    QBCore.Functions.Progressbar("using_drug", "Using " .. drugType .. "...", 5000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        ClearPedTasks(playerPed)
        
        -- Remove drug from inventory
        TriggerServerEvent('kingz-weed:server:removeDrug', drugType)
        
        -- Apply drug effect
        ApplyDrugEffect(drugType)
        
        QBCore.Functions.Notify('You used ' .. drugType, 'success')
    end, function() -- Cancel
        ClearPedTasks(playerPed)
        
        QBCore.Functions.Notify('You cancelled using ' .. drugType, 'error')
    end)
end)

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

-- Apply drug effect with quality multiplier
RegisterNetEvent('kingz-weed:client:drugEffectMultiplier', function(effectMultiplier)
    -- Store the effect multiplier for the next drug effect
    drugEffectMultiplier = effectMultiplier
end)

-- Apply bong effect with quality multiplier
RegisterNetEvent('kingz-weed:client:bongEffectMultiplier', function(effectMultiplier)
    -- Store the effect multiplier for the next bong effect
    bongEffectMultiplier = effectMultiplier
end)

-- Show competition menu
RegisterNetEvent('kingz-weed:client:showCompetitionMenu', function()
    QBCore.Functions.TriggerCallback('kingz-weed:server:getPlayerWeed', function(items)
        if #items == 0 then
            QBCore.Functions.Notify('You don\'t have any weed to enter in the competition', 'error')
            return
        end
        
        -- Get competition info
        QBCore.Functions.TriggerCallback('kingz-weed:server:getCompetitionInfo', function(competition)
            local options = {
                {
                    title = 'Weed Competition Entry',
                    description = 'Category: ' .. competition.category,
                    icon = 'trophy',
                }
            }
            
            for _, item in ipairs(items) do
                table.insert(options, {
                    title = 'Enter ' .. item.label,
                    description = 'You have x' .. item.amount,
                    icon = 'cannabis',
                    onSelect = function()
                        local itemSlot = nil
                        
                        -- Find the item slot
                        QBCore.Functions.TriggerCallback('kingz-weed:server:getItemSlot', function(slot)
                            if slot then
                                TriggerServerEvent('kingz-weed:server:submitCompetitionEntry', item.name, slot)
                            else
                                QBCore.Functions.Notify('Could not find item in inventory', 'error')
                            end
                        end, item.name)
                    end
                })
            end
            
            lib.registerContext({
                id = 'competition_menu',
                title = 'Weed Competition',
                options = options
            })
            
            lib.showContext('competition_menu')
        end)
    end)
end)

-- Start delivery mission
RegisterNetEvent('kingz-weed:client:startMission', function(location, packageId, missionType)
    -- Debug print
    print("Starting mission with location: " .. location.x .. ", " .. location.y .. ", " .. location.z)
    
    -- Create blip
    local missionBlip = AddBlipForCoord(location.x, location.y, location.z)
    SetBlipSprite(missionBlip, 501) -- Weed blip
    SetBlipColour(missionBlip, 2) -- Green
    SetBlipScale(missionBlip, 1.0)
    SetBlipAsShortRange(missionBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Delivery Location")
    EndTextCommandSetBlipName(missionBlip)
    
    -- Set route
    SetBlipRoute(missionBlip, true)
    SetBlipRouteColour(missionBlip, 2)
    
    -- Debug print
    print("Created mission blip: " .. missionBlip)
    
    -- Create package
    local packageObj = nil
    
    -- Create delivery zone
    local deliveryZone = CircleZone:Create(
        vector3(location.x, location.y, location.z),
        3.0,
        {
            name = "delivery_zone_" .. packageId,
            debugPoly = false
        }
    )
    
    deliveryZone:onPlayerInOut(function(isPointInside)
        if isPointInside then
            -- Player entered delivery zone
            QBCore.Functions.Notify('Press [E] to deliver the package', 'primary')
            
            -- Create thread to handle delivery
            Citizen.CreateThread(function()
                while isPointInside do
                    Citizen.Wait(0)
                    
                    if IsControlJustPressed(0, 38) then -- E key
                        -- Complete delivery
                        TriggerServerEvent('kingz-weed:server:completeMission', packageId)
                        
                        -- Clean up
                        RemoveBlip(missionBlip)
                        deliveryZone:destroy()
                        
                        if packageObj then
                            DeleteObject(packageObj)
                        end
                        
                        return
                    end
                end
            end)
        end
    end)
    
    -- Mission timer
    Citizen.SetTimeout(Config.BuyerMissions.timeLimit * 1000, function()
        -- Check if mission is still active
        if DoesBlipExist(missionBlip) then
            -- Mission failed
            RemoveBlip(missionBlip)
            deliveryZone:destroy()
            
            if packageObj then
                DeleteObject(packageObj)
            end
            
            QBCore.Functions.Notify('You took too long to deliver the package', 'error')
        end
    end)
end)

-- Create dealer blip for police
RegisterNetEvent('kingz-weed:client:createDealerBlip', function(coords)
    -- Check if player is police
    QBCore.Functions.GetPlayerData(function(PlayerData)
        if PlayerData.job.name == "police" then
            -- Create blip
            local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
            SetBlipSprite(blip, 51) -- Drug deal blip
            SetBlipColour(blip, 1) -- Red
            SetBlipScale(blip, 1.0)
            SetBlipAsShortRange(blip, false)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Suspicious Activity")
            EndTextCommandSetBlipName(blip)
            
            -- Flash blip
            SetBlipFlashes(blip, true)
            
            -- Remove blip after 60 seconds
            Citizen.SetTimeout(60000, function()
                RemoveBlip(blip)
            end)
            
            -- Notify police
            QBCore.Functions.Notify('A suspicious drug deal has been reported', 'primary')
        end
    end)
end)

-- Mission police alert
RegisterNetEvent('kingz-weed:client:missionPoliceAlert', function(coords)
    -- Check if player is police
    QBCore.Functions.GetPlayerData(function(PlayerData)
        if PlayerData.job.name == "police" then
            -- Create blip
            local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
            SetBlipSprite(blip, 51) -- Drug deal blip
            SetBlipColour(blip, 1) -- Red
            SetBlipScale(blip, 1.0)
            SetBlipAsShortRange(blip, false)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Drug Delivery in Progress")
            EndTextCommandSetBlipName(blip)
            
            -- Flash blip
            SetBlipFlashes(blip, true)
            
            -- Remove blip after 120 seconds
            Citizen.SetTimeout(120000, function()
                RemoveBlip(blip)
            end)
            
            -- Notify police
            QBCore.Functions.Notify('A drug delivery has been reported', 'primary')
        end
    end)
end)

-- Update research data
RegisterNetEvent('kingz-weed:client:updateResearch', function(researchData)
    -- Store research data locally if needed
    playerResearch = researchData
    
    QBCore.Functions.Notify('Research points: ' .. researchData.points, 'success')
end)

-- Shop notification
RegisterNetEvent('kingz-weed:client:shopNotify', function(message, type)
    QBCore.Functions.Notify(message, type)
end)

-- Helper function to draw 3D text
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end

-- Create shop blip
Citizen.CreateThread(function()
    local blip = AddBlipForCoord(Config.Shop.location.x, Config.Shop.location.y, Config.Shop.location.z)
    SetBlipSprite(blip, 140) -- Weed shop blip
    SetBlipColour(blip, 2) -- Green
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Weed Shop")
    EndTextCommandSetBlipName(blip)
    
    -- Create shop zone
    exports['qb-target']:AddBoxZone("weed_shop", vector3(Config.Shop.location.x, Config.Shop.location.y, Config.Shop.location.z), 2.0, 2.0, {
        name = "weed_shop",
        heading = Config.Shop.location.w,
        debugPoly = false,
        minZ = Config.Shop.location.z - 1.0,
        maxZ = Config.Shop.location.z + 1.0
    }, {
        options = {
            {
                icon = "fas fa-shopping-cart",
                label = "Browse Shop",
                action = function()
                    OpenWeedShop()
                end
            }
        },
        distance = 2.0
    })
    
        -- Create dealer blips
    for i, dealer in ipairs(Config.Dealers) do
        local blip = AddBlipForCoord(dealer.coords.x, dealer.coords.y, dealer.coords.z)
        SetBlipSprite(blip, 140) -- Weed dealer blip
        SetBlipColour(blip, 1) -- Red
        SetBlipScale(blip, 0.6)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(dealer.name)
        EndTextCommandSetBlipName(blip)
        
        -- Create dealer ped
        RequestModel(GetHashKey(dealer.model))
        while not HasModelLoaded(GetHashKey(dealer.model)) do
            Citizen.Wait(1)
        end
        
        local dealerPed = CreatePed(4, GetHashKey(dealer.model), dealer.coords.x, dealer.coords.y, dealer.coords.z - 1.0, dealer.coords.w, false, true)
        FreezeEntityPosition(dealerPed, true)
        SetEntityInvincible(dealerPed, true)
        SetBlockingOfNonTemporaryEvents(dealerPed, true)
        
        -- Create dealer zone
        exports['qb-target']:AddTargetEntity(dealerPed, {
            options = {
                {
                    icon = "fas fa-cannabis",
                    label = "Sell Weed",
                    action = function()
                        OpenDealerMenu(i)
                    end
                },
                {
                    icon = "fas fa-briefcase",
                    label = "Request Delivery Job",
                    action = function()
                        RequestDeliveryMission(i)
                    end
                }
            },
            distance = 2.0
        })
    end
    
    -- Create business blips
    if Config.Business.enabled then
        for i, business in ipairs(Config.Business.locations) do
            local blip = AddBlipForCoord(business.coords.x, business.coords.y, business.coords.z)
            SetBlipSprite(blip, business.blip.sprite)
            SetBlipColour(blip, business.blip.color)
            SetBlipScale(blip, business.blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(business.name)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

-- Open weed shop
function OpenWeedShop()
    QBCore.Functions.TriggerCallback('kingz-weed:server:getReputation', function(reputation, reputationLevel, discount)
        local options = {
            {
                title = 'Weed Shop',
                description = 'Your Reputation: ' .. reputationLevel .. ' (' .. reputation .. ' points)',
                icon = 'cannabis',
            }
        }
        
        for _, item in ipairs(Config.Shop.items) do
            local discountedPrice = math.floor(item.price * (1 - discount))
            local priceText = discountedPrice == item.price and 
                "$" .. discountedPrice or 
                "$" .. discountedPrice .. " (Discount: " .. (discount * 100) .. "%)"
            
            table.insert(options, {
                title = item.label,
                description = priceText,
                icon = 'shopping-cart',
                onSelect = function()
                    TriggerServerEvent('kingz-weed:server:buyItem', item.item, discountedPrice)
                end
            })
        end
        
        -- Check for special items based on reputation
        for _, specialItem in ipairs(Config.ShopReputation.specialItems) do
            if reputation >= specialItem.rep then
                table.insert(options, {
                    title = QBCore.Shared.Items[specialItem.item].label,
                    description = "$" .. specialItem.price .. " (Special Item)",
                    icon = 'star',
                    onSelect = function()
                        TriggerServerEvent('kingz-weed:server:buyItem', specialItem.item, specialItem.price)
                    end
                })
            end
        end
        
        lib.registerContext({
            id = 'weed_shop',
            title = 'Weed Shop',
            options = options
        })
        
        lib.showContext('weed_shop')
    end)
end

-- Open dealer menu
function OpenDealerMenu(dealerId)
    local dealer = Config.Dealers[dealerId]
    
    -- Check if dealer is open
    -- Use GetClockHours() instead of os.date
    local currentHour = GetClockHours()
    if currentHour < dealer.hours.open and currentHour >= dealer.hours.close then
        QBCore.Functions.Notify('This dealer is closed right now. Come back between ' .. dealer.hours.open .. ':00 and ' .. dealer.hours.close .. ':00', 'error')
        return
    end
    
    -- Check if dealer requires reputation
    if dealer.minReputation and dealer.reputation then
        QBCore.Functions.TriggerCallback('kingz-weed:server:getReputation', function(reputation, reputationLevel, discount)
            if reputation < dealer.minReputation then
                QBCore.Functions.Notify('This dealer doesn\'t trust you yet. You need at least ' .. dealer.minReputation .. ' reputation points.', 'error')
                return
            else
                ShowDealerSellMenu(dealerId)
            end
        end)
    else
        ShowDealerSellMenu(dealerId)
    end
end

-- Show dealer sell menu
function ShowDealerSellMenu(dealerId)
    local dealer = Config.Dealers[dealerId]
    
    QBCore.Functions.TriggerCallback('kingz-weed:server:getPlayerDrugs', function(items)
        if #items == 0 then
            QBCore.Functions.Notify('You don\'t have anything to sell to this dealer', 'error')
            return
        end
        
        local options = {
            {
                title = dealer.name,
                description = 'Select items to sell',
                icon = 'cannabis',
            }
        }
        
        for _, item in ipairs(items) do
            -- Check if this dealer buys this item
            if dealer.prices[item.name] then
                -- Calculate price range
                local minPrice = dealer.prices[item.name].min
                local maxPrice = dealer.prices[item.name].max
                local price = math.random(minPrice, maxPrice)
                
                table.insert(options, {
                    title = 'Sell ' .. item.label,
                    description = 'You have x' .. item.amount .. ' ($' .. price .. ' each)',
                    icon = 'dollar-sign',
                    onSelect = function()
                        -- Show quantity selector
                        local input = lib.inputDialog('Sell ' .. item.label, {
                            {type = 'number', label = 'Amount', description = 'How many do you want to sell?', min = 1, max = item.amount, default = 1}
                        })
                        
                        if input then
                            local amount = tonumber(input[1])
                            if amount and amount > 0 and amount <= item.amount then
                                TriggerServerEvent('kingz-weed:server:sellDrug', dealerId, item.name, amount, price)
                            end
                        end
                    end
                })
            end
        end
        
        lib.registerContext({
            id = 'dealer_menu',
            title = dealer.name,
            options = options
        })
        
        lib.showContext('dealer_menu')
    end)
end

-- Request delivery mission
function RequestDeliveryMission(dealerId)
    QBCore.Functions.TriggerCallback('kingz-weed:server:canStartMission', function(canStart, cooldownRemaining)
        if not canStart then
            if cooldownRemaining > 0 then
                QBCore.Functions.Notify('You need to wait ' .. math.ceil(cooldownRemaining / 60) .. ' more minutes', 'error')
            else
                QBCore.Functions.Notify('You already have an active mission', 'error')
            end
            return
        end
        
        -- Start mission
        TriggerServerEvent('kingz-weed:server:startMission', dealerId)
        
        QBCore.Functions.Notify('Delivery location marked on your map', 'success')
    end)
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

-- Debug command to show what weed you have
RegisterCommand('checkweed', function()
    QBCore.Functions.TriggerCallback('kingz-weed:server:getPlayerWeed', function(items)
        if #items == 0 then
            QBCore.Functions.Notify('You don\'t have any weed in your inventory', 'error')
        else
            for _, item in ipairs(items) do
                QBCore.Functions.Notify('You have ' .. item.amount .. 'x ' .. item.label, 'success')
            end
        end
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

-- Research menu
RegisterCommand('research', function()
    QBCore.Functions.TriggerCallback('kingz-weed:server:getResearch', function(researchData)
        if not researchData then
            QBCore.Functions.Notify('Could not load research data', 'error')
            return
        end
        
        local options = {
            {
                title = 'Weed Research',
                description = 'Research Points: ' .. researchData.points,
                icon = 'flask',
            }
        }
        
        for i, upgrade in ipairs(Config.Research.upgrades) do
            local currentLevel = researchData.upgrades[upgrade.name] or 0
            local nextLevel = currentLevel + 1
            
            if nextLevel <= upgrade.levels then
                local pointsRequired = upgrade.pointsRequired[nextLevel]
                local canAfford = researchData.points >= pointsRequired
                
                local description = 'Level ' .. currentLevel .. '/' .. upgrade.levels
                if currentLevel > 0 then
                    -- Show current bonuses
                    for effectName, effectValues in pairs(upgrade.effects) do
                        description = description .. '\n' .. effectName .. ': ' .. (effectValues[currentLevel] * 100) .. '%'
                    end
                end
                
                if nextLevel <= upgrade.levels then
                    description = description .. '\nNext Level: ' .. pointsRequired .. ' points'
                    
                    -- Show next level bonuses
                    for effectName, effectValues in pairs(upgrade.effects) do
                        description = description .. '\nNext ' .. effectName .. ': ' .. (effectValues[nextLevel] * 100) .. '%'
                    end
                end
                
                table.insert(options, {
                    title = upgrade.name,
                    description = description,
                    icon = canAfford and 'check' or 'times',
                    onSelect = function()
                        if canAfford then
                            TriggerServerEvent('kingz-weed:server:purchaseResearch', upgrade.name, nextLevel)
                        else
                            QBCore.Functions.Notify('You need ' .. pointsRequired .. ' points for this upgrade', 'error')
                        end
                    end,
                    disabled = not canAfford
                })
            else
                -- Max level reached
                local description = 'Level ' .. currentLevel .. '/' .. upgrade.levels .. ' (MAX)'
                
                -- Show current bonuses
                for effectName, effectValues in pairs(upgrade.effects) do
                    description = description .. '\n' .. effectName .. ': ' .. (effectValues[currentLevel] * 100) .. '%'
                end
                
                table.insert(options, {
                    title = upgrade.name,
                    description = description,
                    icon = 'star',
                    disabled = true
                })
            end
        end
        
        lib.registerContext({
            id = 'research_menu',
            title = 'Weed Research',
            options = options
        })
        
        lib.showContext('research_menu')
    end)
end, false)

-- Achievements menu
RegisterCommand('achievements', function()
    QBCore.Functions.TriggerCallback('kingz-weed:server:getAchievements', function(achievements)
        local options = {
            {
                title = 'Weed Achievements',
                description = 'View your achievements',
                icon = 'trophy',
            }
        }
        
        for _, achievement in ipairs(Config.Achievements) do
            local isUnlocked = achievements[achievement.id] ~= nil
            local icon = isUnlocked and 'check' or 'lock'
            local title = achievement.name
            
            if isUnlocked then
                title = '✓ ' .. title
            end
            
            table.insert(options, {
                title = title,
                description = achievement.description,
                icon = icon,
                onSelect = function()
                    if isUnlocked then
                        -- Use GetGameTimer instead of os.date
                        local unlockTime = achievements[achievement.id]
                        QBCore.Functions.Notify('Achievement unlocked!', 'success')
                    else
                        QBCore.Functions.Notify('Complete the requirements to unlock', 'error')
                    end
                end
            })
        end
        
        lib.registerContext({
            id = 'achievements_menu',
            title = 'Weed Achievements',
            options = options
        })
        
        lib.showContext('achievements_menu')
    end)
end, false)

-- Business management menu
RegisterCommand('business', function()
    -- Check if player owns a business
    local businessId = nil
    local business = nil
    
    -- This would normally be a server callback, but for simplicity we'll just show a placeholder
    QBCore.Functions.Notify('This feature is coming soon', 'primary')
end, false)
