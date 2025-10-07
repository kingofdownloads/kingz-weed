local QBCore = exports['qb-core']:GetCoreObject()
local isHarvesting = false
local currentPlant = nil
local currentPlantId = nil
local cuttingActive = false
local leafObjects = {}
local harvestedLeaves = 0

-- Function to start interactive harvesting
RegisterNetEvent('kingz-weed:client:startHarvesting', function(plantId, plantObject)
    if isHarvesting then return end
    
    DebugPrint("Starting interactive harvesting for plant: " .. plantId)
    
    isHarvesting = true
    currentPlant = plantObject
    currentPlantId = plantId
    harvestedLeaves = 0
    leafObjects = {}
    
    -- Start the harvesting sequence
    lib.notify({
        title = 'Harvesting',
        description = Lang:t('info.start_cutting'),
        type = 'info'
    })
    
    StartHarvestingSequence()
end)

-- Function to handle the harvesting sequence
function StartHarvestingSequence()
    CreateThread(function()
        while isHarvesting do
            -- Display instructions
            local instructionText = Lang:t('info.start_cutting')
            
            -- Draw 3D text above the plant
            if DoesEntityExist(currentPlant) then
                local plantCoords = GetEntityCoords(currentPlant)
                DrawText3D(plantCoords.x, plantCoords.y, plantCoords.z + 1.0, instructionText)
            end
            
            -- Check for key press to start cutting
            if IsControlJustPressed(0, 38) then -- E key
                StartCuttingLeaves()
            end
            
            Wait(0)
        end
    end)
end

-- Function to start cutting leaves
function StartCuttingLeaves()
    if cuttingActive then return end
    
    cuttingActive = true
    
    -- Spawn leaves on the plant that can be cut
    SpawnLeaves()
    
    -- Create thread to monitor cutting progress
    CreateThread(function()
        while cuttingActive and harvestedLeaves < Config.Harvesting.requiredLeaves do
            -- Check if all leaves have been cut
            if harvestedLeaves >= Config.Harvesting.requiredLeaves then
                FinishHarvesting()
                break
            end
            
            Wait(100)
        end
    end)
end

-- Function to spawn leaves on the plant
function SpawnLeaves()
    if not DoesEntityExist(currentPlant) then
        DebugPrint("Plant does not exist")
        return
    end
    
    local plantCoords = GetEntityCoords(currentPlant)
    local leafModel = Config.Harvesting.leafModel
    
    RequestModel(leafModel)
    while not HasModelLoaded(leafModel) do
        Wait(10)
    end
    
    -- Spawn leaves at fixed positions around the plant
    for i = 1, Config.Harvesting.requiredLeaves do
        -- Calculate positions in a circle around the plant
        local angle = (i / Config.Harvesting.requiredLeaves) * 360.0
        local radius = 0.5
        
        local offsetX = radius * math.cos(math.rad(angle))
        local offsetY = radius * math.sin(math.rad(angle))
        local offsetZ = 0.2 + (i * 0.1)
        
        local leafCoords = vector3(
            plantCoords.x + offsetX,
            plantCoords.y + offsetY,
            plantCoords.z + offsetZ
        )
        
        local leaf = CreateObject(leafModel, leafCoords.x, leafCoords.y, leafCoords.z, true, false, false)
        SetEntityCollision(leaf, true, true)
        FreezeEntityPosition(leaf, true)
        
        -- Try to use object_gizmo if available
        local success, result = pcall(function()
            return exports.object_gizmo:useGizmo(leaf)
        end)
        
        if not success then
            DebugPrint("Object gizmo not available or error: " .. tostring(result))
        end
        
        -- Add target to cut this leaf
        exports['qb-target']:AddTargetEntity(leaf, {
            options = {
                {
                    type = "client",
                    event = "kingz-weed:client:cutLeaf",
                    icon = "fas fa-cut",
                    label = "Cut Leaf",
                    leafId = i
                },
            },
            distance = 2.0
        })
        
        leafObjects[i] = leaf
    end
    
    lib.notify({
        title = 'Harvesting',
        description = Lang:t('info.cut_leaves'),
        type = 'info'
    })
end

-- Event for cutting a leaf
RegisterNetEvent('kingz-weed:client:cutLeaf', function(data)
    local leafId = data.leafId
    local leaf = leafObjects[leafId]
    
    if not leaf or not DoesEntityExist(leaf) then return end
    
    -- Play cutting animation
    local playerPed = PlayerPedId()
    local animDict = "anim@amb@business@weed@weed_inspecting_lo_med_hi@"
    local animName = "weed_crouch_checkingleaves_idle_01_inspector"
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(10)
    end
    
    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
    
    QBCore.Functions.Progressbar("cutting_leaf", Lang:t('info.cutting_leaf'), Config.Harvesting.harvestTime, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        ClearPedTasks(playerPed)
        
        -- Delete the leaf object
        DeleteEntity(leaf)
        leafObjects[leafId] = nil
        harvestedLeaves = harvestedLeaves + 1
        
        lib.notify({
            title = 'Success',
            description = Lang:t('success.leaf_cut'),
            type = 'success'
        })
        
        -- Check if all leaves are cut
        if harvestedLeaves >= Config.Harvesting.requiredLeaves then
            FinishHarvesting()
        end
    end, function() -- Cancel
        ClearPedTasks(playerPed)
    end)
end)

-- Function to finish harvesting
function FinishHarvesting()
    cuttingActive = false
    isHarvesting = false
    
    -- Clean up any remaining leaf objects
    for _, leaf in pairs(leafObjects) do
        if leaf and DoesEntityExist(leaf) then
            DeleteEntity(leaf)
        end
    end
    
    leafObjects = {}
    
    -- Trigger server event to complete harvesting
    DebugPrint("Triggering server event to harvest plant: " .. currentPlantId)
    TriggerServerEvent('kingz-weed:server:harvestPlant', currentPlantId)
    
    lib.notify({
        title = 'Success',
        description = Lang:t('success.harvested'),
        type = 'success'
    })
    
    currentPlant = nil
    currentPlantId = nil
end

-- Function to clean up if player cancels or leaves
function CleanupHarvesting()
    if not isHarvesting then return end
    
    DebugPrint("Cleaning up harvesting")
    
    for _, leaf in pairs(leafObjects) do
        if leaf and DoesEntityExist(leaf) then
            DeleteEntity(leaf)
        end
    end
    
    leafObjects = {}
    isHarvesting = false
    cuttingActive = false
    currentPlant = nil
    currentPlantId = nil
    harvestedLeaves = 0
end

-- Draw 3D text function
function DrawText3D(x, y, z, text)
    -- Set up the basic drawing
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        CleanupHarvesting()
    end
end)

-- Cleanup if player dies
AddEventHandler('baseevents:onPlayerDied', function()
    CleanupHarvesting()
end)
