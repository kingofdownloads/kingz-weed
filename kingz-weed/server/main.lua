local QBCore = exports['qb-core']:GetCoreObject()
local plants = {}
local heatLamps = {}
local hydroponicSystems = {}
local playerReputations = {}
local playerResearch = {}
local playerAchievements = {}
local playerStats = {}
local businessData = {}
local currentCompetition = {
    active = false,
    startTime = 0,
    endTime = 0,
    entries = {}
}
local breedingAttempts = {}
local missionCooldowns = {}
local activeMissions = {}

-- Debug print to check if seeds are being registered
print("Registering usable items for seeds...")

-- Register usable items for all seed types
local seedTypes = {
    'cannabis_seed', 'purple_haze_seed', 'skunk_seed', 'og_kush_seed', 'amnesia_seed',
    'northern_lights_seed', 'white_widow_seed', 'purple_skunk_seed', 'kush_haze_seed',
    'widow_lights_seed', 'amnesia_kush_seed'
}

for _, seedType in ipairs(seedTypes) do
    print("Registering usable item: " .. seedType)
    QBCore.Functions.CreateUseableItem(seedType, function(source)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        
        if Player then
            print("Player used " .. seedType .. " from inventory")
            TriggerClientEvent('kingz-weed:client:plantSeed', src, {name = seedType})
        end
    end)
end

-- Register heat lamp item
QBCore.Functions.CreateUseableItem('heat_lamp', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        TriggerClientEvent('kingz-weed:client:placeHeatLamp', src)
    end
end)

-- Register hydroponic kit item
QBCore.Functions.CreateUseableItem('hydroponic_kit', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        TriggerClientEvent('kingz-weed:client:placeHydroponics', src)
    end
end)

-- Register bong item
QBCore.Functions.CreateUseableItem('bong', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        TriggerClientEvent('kingz-weed:client:useBong', src)
    end
end)

-- Register grinder item
QBCore.Functions.CreateUseableItem('grinder', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        TriggerClientEvent('kingz-weed:client:useGrinder', src)
    end
end)

-- Register extraction kit item
QBCore.Functions.CreateUseableItem('extraction_kit', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        TriggerClientEvent('kingz-weed:client:extractConcentrate', src)
    end
end)

-- Register brownie mix item
QBCore.Functions.CreateUseableItem('brownie_mix', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        TriggerClientEvent('kingz-weed:client:makeEdibles', src)
    end
end)

-- Register weed medicine item
QBCore.Functions.CreateUseableItem('weed_medicine', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        TriggerClientEvent('kingz-weed:client:showPlantMedicineMenu', src)
    end
end)

-- Register premium soil item
QBCore.Functions.CreateUseableItem('premium_soil', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        TriggerClientEvent('kingz-weed:client:showSoilMenu', src)
    end
end)

-- Register nutrition booster item
QBCore.Functions.CreateUseableItem('weed_nutrition', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        TriggerClientEvent('kingz-weed:client:showNutritionMenu', src)
    end
end)

-- Register drug items
for drugType, _ in pairs(Config.DrugEffects) do
    if drugType ~= 'bong_hit' then -- Skip bong_hit as it's not a direct item
        QBCore.Functions.CreateUseableItem(drugType, function(source)
            local src = source
            TriggerClientEvent('kingz-weed:client:useDrug', src, drugType)
        end)
        
        -- Also register joints
        QBCore.Functions.CreateUseableItem(drugType .. '_joint', function(source)
            local src = source
            TriggerClientEvent('kingz-weed:client:useDrug', src, drugType .. '_joint')
        end)
    end
end

-- Register edible items
QBCore.Functions.CreateUseableItem('weed_brownie', function(source)
    local src = source
    TriggerClientEvent('kingz-weed:client:useDrug', src, 'weed_brownie')
end)

-- Register concentrate items
QBCore.Functions.CreateUseableItem('weed_concentrate', function(source)
    local src = source
    TriggerClientEvent('kingz-weed:client:useDrug', src, 'weed_concentrate')
end)

-- Handle seed removal
RegisterNetEvent('kingz-weed:server:removeSeed', function(seedType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        Player.Functions.RemoveItem(seedType, 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[seedType], 'remove')
    end
end)

-- Plant a seed
RegisterNetEvent('kingz-weed:server:plantSeed', function(plantId, plantType, coords)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if this is a hybrid strain
    local isHybrid = Config.HybridStrains[plantType] ~= nil
    local plantConfig = isHybrid and Config.HybridStrains[plantType] or Config.Plants[plantType]
    
    -- Set up soil quality (default is standard)
    local soilQuality = 1.0
    
    plants[plantId] = {
        id = plantId,
        type = plantType,
        coords = coords,
        stage = 1,
        owner = Player.PlayerData.citizenid,
        plantedAt = os.time(),
        nextGrowth = os.time() + (isHybrid and Config.HybridStrains[plantType].stages[1].time or Config.Plants[plantType].stages[1].time),
        water = 50.0, -- Start at 50% water
        fertilizer = 30.0, -- Start at 30% fertilizer
        health = 100.0, -- Start with full health
        hasBugs = false,
        hasDisease = false,
        pesticideUntil = 0,
        soilQuality = soilQuality,
        isHybrid = isHybrid,
        isHydroponic = false,
        lastUpdated = os.time()
    }
    
    -- Check for achievement: first plant
    CheckAchievement(Player.PlayerData.citizenid, "first_harvest")
    
    DebugPrint('Player ' .. Player.PlayerData.charinfo.firstname .. ' planted ' .. plantType .. ' with ID: ' .. plantId)
    
    -- Sync with all clients
    TriggerClientEvent('kingz-weed:client:syncPlants', -1, plants)
end)

-- Check plant status
RegisterNetEvent('kingz-weed:server:checkPlant', function(plantId)
    local src = source
    local plant = plants[plantId]
    
    if not plant then return end
    
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Check if player owns the plant
    if plant.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_owner'), 'error')
        return
    end
    
    local timeLeft = plant.nextGrowth - os.time()
    local plantConfig = plant.isHybrid and Config.HybridStrains[plant.type] or Config.Plants[plant.type]
    
    -- Check if plant is under a heat lamp
    local isUnderHeatLamp = false
    for _, lamp in pairs(heatLamps) do
        if #(vector3(plant.coords.x, plant.coords.y, plant.coords.z) - vector3(lamp.coords.x, lamp.coords.y, lamp.coords.z)) <= Config.HeatLamps.range then
            isUnderHeatLamp = true
            break
        end
    end
    
    -- Check if plant is in a hydroponic system
    local hydroponicInfo = ""
    if plant.isHydroponic then
        hydroponicInfo = "Hydroponic System: Active (Growth +" .. (Config.Hydroponics.growthBonus * 100) .. "%)"
    end
    
    -- Calculate estimated quality
    local waterQuality = (plant.water / 100) * Config.QualityFactors.waterImpact
    local fertilizerQuality = (plant.fertilizer / 100) * Config.QualityFactors.fertilizerImpact
    local heatLampQuality = isUnderHeatLamp and Config.QualityFactors.heatLampImpact or 0
    local pestQuality = plant.hasBugs and 0 or Config.QualityFactors.pestImpact
    local diseaseQuality = plant.hasDisease and 0 or Config.QualityFactors.diseaseImpact
    local soilQuality = (plant.soilQuality - 1.0) * Config.QualityFactors.soilImpact
    
    local totalQuality = math.floor((waterQuality + fertilizerQuality + heatLampQuality + pestQuality + diseaseQuality + soilQuality) * 100)
    
    -- Determine quality level
    local qualityLevel = "Standard"
    for _, level in ipairs(Config.QualityLevels) do
        if totalQuality >= level.min and totalQuality <= level.max then
            qualityLevel = level.name
            break
        end
    end
    
    -- Update plant data with calculated values
    plant.quality = totalQuality
    plant.qualityLevel = qualityLevel
    plant.isUnderHeatLamp = isUnderHeatLamp
    
    -- Send plant data to client for UI display
    TriggerClientEvent('kingz-weed:client:showPlantInfo', src, plant)
end)

-- Water plant
RegisterNetEvent('kingz-weed:server:waterPlant', function(plantId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local plant = plants[plantId]
    
    if not plant then return end
    if not Player then return end
    
    -- Check if player owns the plant
    if plant.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_owner'), 'error')
        return
    end
    
    -- Check if plant is hydroponic (needs less water)
    local waterAmount = 1
    if plant.isHydroponic then
        -- Check if we even need water with hydroponics
        if plant.water > 80 then
            TriggerClientEvent('QBCore:Notify', src, 'Hydroponic system doesn\'t need water yet', 'error')
            return
        end
        waterAmount = 0.3 -- Only use 30% of a water bottle with hydroponics
    end
    
    -- Apply research bonuses if any
    local citizenId = Player.PlayerData.citizenid
    local researchData = playerResearch[citizenId] or {upgrades = {}}
    local resourceEfficiency = researchData.upgrades["Resource Efficiency"] or 0
    
    if resourceEfficiency > 0 then
        waterAmount = waterAmount * (1 - Config.Research.upgrades[4].effects.waterSavings[resourceEfficiency])
    end
    
    -- Remove water bottle
    if Player.Functions.RemoveItem('water_bottle', waterAmount) then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['water_bottle'], 'remove')
        
        -- Update plant water level
        plant.water = 100.0
        
        -- Improve plant health if it's low
        if plant.health < 80.0 then
            plant.health = math.min(100.0, plant.health + 10.0)
        end
        
        -- Update clients
        TriggerClientEvent('kingz-weed:client:updatePlantData', -1, plantId, {
            water = plant.water,
            health = plant.health
        })
        
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.watered'), 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_water'), 'error')
    end
end)

-- Fertilize plant
RegisterNetEvent('kingz-weed:server:fertilizePlant', function(plantId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local plant = plants[plantId]
    
    if not plant then return end
    if not Player then return end
    
    -- Check if player owns the plant
    if plant.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_owner'), 'error')
        return
    end
    
    -- Apply research bonuses if any
    local citizenId = Player.PlayerData.citizenid
    local researchData = playerResearch[citizenId] or {upgrades = {}}
    local resourceEfficiency = researchData.upgrades["Resource Efficiency"] or 0
    
    local fertilizerAmount = 1
    if resourceEfficiency > 0 then
        fertilizerAmount = fertilizerAmount * (1 - Config.Research.upgrades[4].effects.fertilizerSavings[resourceEfficiency])
        if fertilizerAmount < 0.5 then fertilizerAmount = 0.5 end -- Minimum 0.5
    end
    
    -- Remove fertilizer
    if Player.Functions.RemoveItem('fertilizer', fertilizerAmount) then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['fertilizer'], 'remove')
        
        -- Update plant fertilizer level
        plant.fertilizer = 100.0
        
        -- Improve plant health if it's low
        if plant.health < 90.0 then
            plant.health = math.min(100.0, plant.health + 15.0)
        end
        
        -- Update clients
        TriggerClientEvent('kingz-weed:client:updatePlantData', -1, plantId, {
            fertilizer = plant.fertilizer,
            health = plant.health
        })
        
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.fertilized'), 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_fertilizer'), 'error')
    end
end)

-- Apply pesticide
RegisterNetEvent('kingz-weed:server:applyPesticide', function(plantId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local plant = plants[plantId]
    
    if not plant then return end
    if not Player then return end
    
    -- Check if player owns the plant
    if plant.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_owner'), 'error')
        return
    end
    
    -- Remove pesticide
    if Player.Functions.RemoveItem('pesticide', 1) then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['pesticide'], 'remove')
        
        -- Update plant pesticide protection
        plant.hasBugs = false
        plant.pesticideUntil = os.time() + Config.PlantCare.pesticideProtectionTime
        
        -- Update clients
        TriggerClientEvent('kingz-weed:client:updatePlantData', -1, plantId, {
            hasBugs = false,
            pesticideUntil = plant.pesticideUntil
        })
        
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.pesticide_applied'), 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_pesticide'), 'error')
    end
end)

-- Apply medicine to plant
RegisterNetEvent('kingz-weed:server:applyMedicine', function(plantId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local plant = plants[plantId]
    
    if not plant then return end
    if not Player then return end
    
    -- Check if player owns the plant
    if plant.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_owner'), 'error')
        return
    end
    
    -- Check if plant has disease
    if not plant.hasDisease then
        TriggerClientEvent('QBCore:Notify', src, 'This plant doesn\'t have any disease', 'error')
        return
    end
    
    -- Remove medicine
    if Player.Functions.RemoveItem('weed_medicine', 1) then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['weed_medicine'], 'remove')
        
        -- Chance to cure disease
        if math.random(100) <= Config.PlantCare.cureChance then
            plant.hasDisease = false
            
            -- Update clients
            TriggerClientEvent('kingz-weed:client:updatePlantData', -1, plantId, {
                hasDisease = false
            })
            
            TriggerClientEvent('QBCore:Notify', src, 'Disease cured successfully!', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'Treatment failed. The disease persists.', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'You need plant medicine', 'error')
    end
end)

-- Apply premium soil
RegisterNetEvent('kingz-weed:server:applyPremiumSoil', function(plantId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local plant = plants[plantId]
    
    if not plant then return end
    if not Player then return end
    
    -- Check if player owns the plant
    if plant.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_owner'), 'error')
        return
    end
    
    -- Check if plant already has premium soil
    if plant.soilQuality > 1.0 then
        TriggerClientEvent('QBCore:Notify', src, 'This plant already has premium soil', 'error')
        return
    end
    
    -- Remove premium soil
    if Player.Functions.RemoveItem('premium_soil', 1) then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['premium_soil'], 'remove')
        
        -- Update soil quality
        plant.soilQuality = 1.5 -- 50% better than standard soil
        
        -- Update clients
        TriggerClientEvent('kingz-weed:client:updatePlantData', -1, plantId, {
            soilQuality = plant.soilQuality
        })
        
        TriggerClientEvent('QBCore:Notify', src, 'Premium soil applied successfully!', 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'You need premium soil', 'error')
    end
end)

-- Apply nutrition booster
RegisterNetEvent('kingz-weed:server:applyNutrition', function(plantId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local plant = plants[plantId]
    
    if not plant then return end
    if not Player then return end
    
    -- Check if player owns the plant
    if plant.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_owner'), 'error')
        return
    end
    
    -- Remove nutrition booster
    if Player.Functions.RemoveItem('weed_nutrition', 1) then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['weed_nutrition'], 'remove')
        
        -- Boost plant health and growth
        plant.health = math.min(100.0, plant.health + 20.0)
        
        -- Reduce time to next growth stage by 20%
        if plant.nextGrowth > os.time() then
            local timeRemaining = plant.nextGrowth - os.time()
            plant.nextGrowth = os.time() + math.floor(timeRemaining * 0.8)
        end
        
        -- Update clients
        TriggerClientEvent('kingz-weed:client:updatePlantData', -1, plantId, {
            health = plant.health,
            nextGrowth = plant.nextGrowth
        })
        
        TriggerClientEvent('QBCore:Notify', src, 'Nutrition booster applied! Growth accelerated and health improved.', 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'You need a nutrition booster', 'error')
    end
end)

-- Remove bugs manually
RegisterNetEvent('kingz-weed:server:removeBugs', function(plantId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local plant = plants[plantId]
    
    if not plant then return end
    if not Player then return end
    
    -- Check if player owns the plant
    if plant.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_owner'), 'error')
        return
    end
    
    -- Check if plant has bugs
    if not plant.hasBugs then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_bugs'), 'error')
        return
    end
    
    -- Update plant bug status
    plant.hasBugs = false
    
    -- Update clients
    TriggerClientEvent('kingz-weed:client:updatePlantData', -1, plantId, {
        hasBugs = false
    })
    
    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.bugs_removed'), 'success')
end)

-- Harvest plant
RegisterNetEvent('kingz-weed:server:harvestPlant', function(plantId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local plant = plants[plantId]
    
    if not plant then 
        DebugPrint("Plant not found: " .. plantId)
        return 
    end
    
    if not Player then 
        DebugPrint("Player not found: " .. src)
        return 
    end
    
    -- Check if player owns the plant
    if plant.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_owner'), 'error')
        return
    end
    
    -- Check if plant is in final stage
    local plantConfig = plant.isHybrid and Config.HybridStrains[plant.type] or Config.Plants[plant.type]
    if plant.stage < #plantConfig.stages then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_ready'), 'error')
        return
    end
    
    -- Calculate quality based on care
    local waterQuality = (plant.water / 100) * Config.QualityFactors.waterImpact
    local fertilizerQuality = (plant.fertilizer / 100) * Config.QualityFactors.fertilizerImpact
    
    -- Check if plant is under a heat lamp
    local isUnderHeatLamp = false
    for _, lamp in pairs(heatLamps) do
        if #(vector3(plant.coords.x, plant.coords.y, plant.coords.z) - vector3(lamp.coords.x, lamp.coords.y, lamp.coords.z)) <= Config.HeatLamps.range then
            isUnderHeatLamp = true
            break
        end
    end
    
    local heatLampQuality = isUnderHeatLamp and Config.QualityFactors.heatLampImpact or 0
    local pestQuality = plant.hasBugs and 0 or Config.QualityFactors.pestImpact
    local diseaseQuality = plant.hasDisease and 0 or Config.QualityFactors.diseaseImpact
    local soilQuality = (plant.soilQuality - 1.0) * Config.QualityFactors.soilImpact
    
    local totalQuality = math.floor((waterQuality + fertilizerQuality + heatLampQuality + pestQuality + diseaseQuality + soilQuality) * 100)
    
    -- Apply research bonuses if any
    local citizenId = Player.PlayerData.citizenid
    local researchData = playerResearch[citizenId] or {upgrades = {}}
    
    -- Quality Control research
    local qualityControl = researchData.upgrades["Quality Control"] or 0
    if qualityControl > 0 then
        totalQuality = totalQuality + Config.Research.upgrades[3].effects.qualityBonus[qualityControl]
    end
    
    -- Cap quality at 100
    totalQuality = math.min(100, totalQuality)
    
    -- Determine quality level
    local qualityLevel = "Standard"
    local priceMultiplier = 1.0
    local effectMultiplier = 1.0
    
    for _, level in ipairs(Config.QualityLevels) do
        if totalQuality >= level.min and totalQuality <= level.max then
            qualityLevel = level.name
            priceMultiplier = level.priceMultiplier
            effectMultiplier = level.effectMultiplier
            break
        end
    end
    
    -- Check for achievement: max quality
    if totalQuality >= 100 then
        CheckAchievement(citizenId, "max_quality")
    end
    
    -- Calculate yield based on plant health, quality, and bonuses
    local yieldMultiplier = (plant.health / 100.0)
    
    -- Apply hybrid bonus if applicable
    if plant.isHybrid then
        yieldMultiplier = yieldMultiplier * (1 + Config.Breeding.hybridYieldBonus)
    end
    
    -- Apply hydroponic bonus if applicable
    if plant.isHydroponic then
        yieldMultiplier = yieldMultiplier * (1 + Config.Hydroponics.yieldBonus)
    end
    
    -- Apply research yield enhancement if applicable
    local yieldEnhancement = researchData.upgrades["Yield Enhancement"] or 0
    if yieldEnhancement > 0 then
        yieldMultiplier = yieldMultiplier * (1 + Config.Research.upgrades[2].effects.yieldBonus[yieldEnhancement])
    end
    
    -- Give yield items
    local itemsGiven = false
    local totalHarvested = 0
    
    for _, yield in ipairs(plantConfig.yield) do
        if math.random(100) <= yield.chance then
            local baseAmount = math.random(yield.amount.min, yield.amount.max)
            local adjustedAmount = math.max(1, math.floor(baseAmount * yieldMultiplier))
            totalHarvested = totalHarvested + adjustedAmount
            
            -- Add metadata for quality
            local info = {
                quality = qualityLevel,
                value = priceMultiplier,
                effect = effectMultiplier,
                thc = plantConfig.thcContent or 5,
                cbd = plantConfig.cbdContent or 1
            }
            
            Player.Functions.AddItem(yield.item, adjustedAmount, false, info)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[yield.item], 'add', adjustedAmount)
            
            DebugPrint('Player harvested ' .. adjustedAmount .. 'x ' .. yield.item .. ' with quality: ' .. qualityLevel)
            itemsGiven = true
        end
    end
    
    -- Check for bonus items
    for _, bonus in ipairs(Config.Harvesting.bonusItems) do
        if math.random(100) <= bonus.chance then
            Player.Functions.AddItem(bonus.item, 1)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[bonus.item], 'add', 1)
            DebugPrint('Player found bonus item: ' .. bonus.item)
        end
    end
    
    if not itemsGiven then
        -- Ensure at least one item is given
        local info = {
            quality = qualityLevel,
            value = priceMultiplier,
            effect = effectMultiplier,
            thc = plantConfig.thcContent or 5,
            cbd = plantConfig.cbdContent or 1
        }
        
        Player.Functions.AddItem(plantConfig.yield[1].item, 1, false, info)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[plantConfig.yield[1].item], 'add', 1)
        totalHarvested = 1
        DebugPrint('Player harvested 1x ' .. plantConfig.yield[1].item .. ' with quality: ' .. qualityLevel .. ' (fallback)')
    end
    
    -- Add research points
    AddResearchPoints(citizenId, Config.Research.researchPoints.perHarvest)
    
    -- Check for achievement: harvest 100 plants
    local harvestCount = GetPlayerStat(citizenId, "plants_harvested") or 0
    harvestCount = harvestCount + 1
    SetPlayerStat(citizenId, "plants_harvested", harvestCount)
    
    if harvestCount >= 100 then
        CheckAchievement(citizenId, "harvest_100")
    end
    
    -- Notify player about quality
    TriggerClientEvent('QBCore:Notify', src, 'Harvested ' .. qualityLevel .. ' quality weed!', 'success')
    
    -- Remove plant
    plants[plantId] = nil
    TriggerClientEvent('kingz-weed:client:removePlant', -1, plantId)
    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.harvested'), 'success')
end)

-- Destroy plant
RegisterNetEvent('kingz-weed:server:destroyPlant', function(plantId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local plant = plants[plantId]
    
    if not plant then return end
    if not Player then return end
    
    -- Check if player owns the plant
    if plant.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_owner'), 'error')
        return
    end
    
    -- Return seed if plant is removed
    Player.Functions.AddItem(plant.type, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[plant.type], 'add', 1)
    
    -- Remove plant
    plants[plantId] = nil
    TriggerClientEvent('kingz-weed:client:removePlant', -1, plantId)
end)

-- Place heat lamp
RegisterNetEvent('kingz-weed:server:placeHeatLamp', function(lampId, coords)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player has reached their limit
    local citizenId = Player.PlayerData.citizenid
    local playerLampCount = 0
    
    for _, lamp in pairs(heatLamps) do
        if lamp.owner == citizenId then
            playerLampCount = playerLampCount + 1
        end
    end
    
    if playerLampCount >= Config.HeatLamps.maxLampsPerPlayer then
        TriggerClientEvent('QBCore:Notify', src, 'You have reached the maximum number of heat lamps (' .. Config.HeatLamps.maxLampsPerPlayer .. ')', 'error')
        return
    end
    
    -- Check if player has the item
    if Player.Functions.RemoveItem('heat_lamp', 1) then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['heat_lamp'], 'remove')
        
        -- Store heat lamp data
        heatLamps[lampId] = {
            id = lampId,
            coords = coords,
            owner = Player.PlayerData.citizenid,
            placedAt = os.time()
        }
        
        -- Sync with all clients
        TriggerClientEvent('kingz-weed:client:syncHeatLamps', -1, heatLamps)
        
        DebugPrint('Player ' .. Player.PlayerData.charinfo.firstname .. ' placed heat lamp with ID: ' .. lampId)
    end
end)

-- Place hydroponic system
RegisterNetEvent('kingz-weed:server:placeHydroponics', function(systemId, coords)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player has reached their limit
    local citizenId = Player.PlayerData.citizenid
    local playerSystemCount = 0
    
    for _, system in pairs(hydroponicSystems) do
        if system.owner == citizenId then
            playerSystemCount = playerSystemCount + 1
        end
    end
    
    if playerSystemCount >= Config.Hydroponics.maxSystemsPerPlayer then
        TriggerClientEvent('QBCore:Notify', src, 'You have reached the maximum number of hydroponic systems (' .. Config.Hydroponics.maxSystemsPerPlayer .. ')', 'error')
        return
    end
    
    -- Check if player has the item
    if Player.Functions.RemoveItem('hydroponic_kit', 1) then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['hydroponic_kit'], 'remove')
        
        -- Store hydroponic system data
        hydroponicSystems[systemId] = {
            id = systemId,
            coords = coords,
            owner = Player.PlayerData.citizenid,
            placedAt = os.time(),
            lastMaintenance = os.time()
        }
        
        -- Sync with all clients
        TriggerClientEvent('kingz-weed:client:syncHydroponics', -1, hydroponicSystems)
        
        DebugPrint('Player ' .. Player.PlayerData.charinfo.firstname .. ' placed hydroponic system with ID: ' .. systemId)
    end
end)

-- Remove heat lamp
RegisterNetEvent('kingz-weed:server:removeHeatLamp', function(lampId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local lamp = heatLamps[lampId]
    if not lamp then return end
    
    -- Check if player owns the lamp
    if lamp.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t own this heat lamp', 'error')
        return
    end
    
    -- Return the item
    Player.Functions.AddItem('heat_lamp', 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['heat_lamp'], 'add')
    
    -- Remove lamp data
    heatLamps[lampId] = nil
    
    -- Sync with all clients
    TriggerClientEvent('kingz-weed:client:syncHeatLamps', -1, heatLamps)
    
    DebugPrint('Player ' .. Player.PlayerData.charinfo.firstname .. ' removed heat lamp with ID: ' .. lampId)
end)

-- Remove hydroponic system
RegisterNetEvent('kingz-weed:server:removeHydroponics', function(systemId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local system = hydroponicSystems[systemId]
    if not system then return end
    
    -- Check if player owns the system
    if system.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t own this hydroponic system', 'error')
        return
    end
    
    -- Return the item
    Player.Functions.AddItem('hydroponic_kit', 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['hydroponic_kit'], 'add')
    
    -- Remove system data
    hydroponicSystems[systemId] = nil
    
    -- Sync with all clients
    TriggerClientEvent('kingz-weed:client:syncHydroponics', -1, hydroponicSystems)
    
    DebugPrint('Player ' .. Player.PlayerData.charinfo.firstname .. ' removed hydroponic system with ID: ' .. systemId)
end)

-- Request plants
RegisterNetEvent('kingz-weed:server:requestPlants', function()
    local src = source
    TriggerClientEvent('kingz-weed:client:syncPlants', src, plants)
end)

-- Request heat lamps
RegisterNetEvent('kingz-weed:server:requestHeatLamps', function()
    local src = source
    TriggerClientEvent('kingz-weed:client:syncHeatLamps', src, heatLamps)
end)

-- Request hydroponic systems
RegisterNetEvent('kingz-weed:server:requestHydroponics', function()
    local src = source
    TriggerClientEvent('kingz-weed:client:syncHydroponics', src, hydroponicSystems)
end)

-- Process weed
RegisterNetEvent('kingz-weed:server:processWeed', function(itemName, processType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player has the weed
    local item = Player.Functions.GetItemByName(itemName)
    if not item then
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t have any ' .. itemName, 'error')
        return
    end
    
    -- Get item metadata
    local info = item.info or {}
    local quality = info.quality or "Standard"
    local value = info.value or 1.0
    local effect = info.effect or 1.0
    local thc = info.thc or 5
    local cbd = info.cbd or 1
    
    -- Process based on type
    if processType == 'joint' then
        -- Check if player has rolling papers
        if Player.Functions.RemoveItem('rolling_paper', 1) and Player.Functions.RemoveItem(itemName, 1) then
            -- Determine joint type
            local jointName = itemName .. '_joint'
            if itemName == 'weed' then jointName = 'joint' end
            
            -- Transfer quality metadata to joint
            local jointInfo = {
                quality = quality,
                value = value,
                effect = effect,
                thc = thc,
                cbd = cbd
            }
            
            -- Give joint
            Player.Functions.AddItem(jointName, 1, false, jointInfo)
            
            -- Show item boxes
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'remove')
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['rolling_paper'], 'remove')
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[jointName], 'add')
            
            TriggerClientEvent('QBCore:Notify', src, 'You rolled a joint', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'You need rolling papers', 'error')
        end
    elseif processType == 'packaged' then
        -- Check if player has baggies
        if Player.Functions.RemoveItem('empty_baggie', 1) and Player.Functions.RemoveItem(itemName, 1) then
            -- Determine packaged name
            local packagedName = 'packaged_' .. itemName
            
            -- Transfer quality metadata to packaged weed
            local packagedInfo = {
                quality = quality,
                value = value,
                effect = effect,
                thc = thc,
                cbd = cbd
            }
            
            -- Give packaged weed
            Player.Functions.AddItem(packagedName, 1, false, packagedInfo)
            
            -- Show item boxes
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'remove')
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['empty_baggie'], 'remove')
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[packagedName], 'add')
            
            TriggerClientEvent('QBCore:Notify', src, 'You packaged the weed', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'You need empty baggies', 'error')
        end
    elseif processType == 'concentrate' then
        -- Check if player has extraction kit
        if Player.Functions.RemoveItem('extraction_kit', 1) and Player.Functions.RemoveItem(itemName, 1) then
            -- Calculate concentrate yield based on quality
            local concentrateAmount = math.ceil(Config.Processing.concentrateYield * value)
            
            -- Transfer quality metadata to concentrate
            local concentrateInfo = {
                quality = quality,
                value = value * 1.5, -- Concentrates are more valuable
                effect = effect * 1.5, -- Concentrates are more potent
                thc = thc * 3, -- Triple the THC content
                cbd = cbd * 0.5 -- Half the CBD content
            }
            
            -- Give concentrate
            Player.Functions.AddItem('weed_concentrate', concentrateAmount, false, concentrateInfo)
            
            -- Show item boxes
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'remove')
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['extraction_kit'], 'remove')
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['weed_concentrate'], 'add', concentrateAmount)
            
            TriggerClientEvent('QBCore:Notify', src, 'You extracted ' .. concentrateAmount .. ' concentrate', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'You need an extraction kit', 'error')
        end
    elseif processType == 'edible' then
        -- Check if player has brownie mix
        if Player.Functions.RemoveItem('brownie_mix', 1) and Player.Functions.RemoveItem(itemName, 1) then
            -- Calculate edible yield
            local edibleAmount = Config.Processing.edibleYield
            
            -- Transfer quality metadata to edible
            local edibleInfo = {
                quality = quality,
                value = value * 1.2, -- Edibles are more valuable
                effect = effect * 1.2, -- Edibles are more potent
                thc = thc * 0.8, -- 80% of the THC content
                cbd = cbd * 2 -- Double the CBD content
            }
            
            -- Give edibles
            Player.Functions.AddItem('weed_brownie', edibleAmount, false, edibleInfo)
            
            -- Show item boxes
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'remove')
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['brownie_mix'], 'remove')
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['weed_brownie'], 'add', edibleAmount)
            
            TriggerClientEvent('QBCore:Notify', src, 'You made ' .. edibleAmount .. ' weed brownies', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'You need brownie mix', 'error')
        end
    end
end)

-- Grind weed
RegisterNetEvent('kingz-weed:server:grindWeed', function(weedType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player has the weed
    local item = Player.Functions.GetItemByName(weedType)
    if not item then
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t have any ' .. weedType, 'error')
        return
    end
    
    -- Get item metadata
    local info = item.info or {}
    
    if Player.Functions.RemoveItem(weedType, 1) then
        -- Determine ground weed name
        local groundWeedName = 'ground_' .. weedType
        
        -- Transfer quality metadata to ground weed
        local groundInfo = {
            quality = info.quality or "Standard",
            value = info.value or 1.0,
            effect = info.effect or 1.0,
            thc = info.thc or 5,
            cbd = info.cbd or 1
        }
        
        -- Give ground weed
        Player.Functions.AddItem(groundWeedName, 2, false, groundInfo) -- Get 2 ground weed from 1 regular
        
        -- Show item boxes
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[weedType], 'remove')
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[groundWeedName], 'add', 2)
        
        TriggerClientEvent('QBCore:Notify', src, 'You ground up the weed', 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t have any ' .. weedType, 'error')
    end
end)

-- Remove weed for bong
RegisterNetEvent('kingz-weed:server:removeWeedForBong', function(weedType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Get item metadata
    local item = Player.Functions.GetItemByName(weedType)
    if not item then return end
    
    local info = item.info or {}
    
    -- Remove the weed
    Player.Functions.RemoveItem(weedType, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[weedType], 'remove')
    
    -- Send effect multiplier to client
    local effectMultiplier = info.effect or 1.0
    TriggerClientEvent('kingz-weed:client:bongEffectMultiplier', src, effectMultiplier)
end)

-- Remove drug item when used
RegisterNetEvent('kingz-weed:server:removeDrug', function(itemName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Get item metadata
    local item = Player.Functions.GetItemByName(itemName)
    if not item then return end
    
    local info = item.info or {}
    
    Player.Functions.RemoveItem(itemName, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'remove')
    
    -- Send effect multiplier to client
    local effectMultiplier = info.effect or 1.0
    TriggerClientEvent('kingz-weed:client:drugEffectMultiplier', src, effectMultiplier)
end)

-- Cross-breeding system
RegisterNetEvent('kingz-weed:server:crossBreed', function(strain1, strain2)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenId = Player.PlayerData.citizenid
    
    -- Check breeding cooldown
    if not breedingAttempts[citizenId] then
        breedingAttempts[citizenId] = {
            count = 0,
            lastAttempt = 0
        }
    end
    
    -- Check if cooldown has passed
    local currentTime = os.time()
    local hoursSinceLastAttempt = (currentTime - breedingAttempts[citizenId].lastAttempt) / 3600
    
    if hoursSinceLastAttempt < Config.Breeding.breedingCooldown and breedingAttempts[citizenId].count >= Config.Breeding.maxBreedingAttempts then
        local hoursRemaining = math.ceil(Config.Breeding.breedingCooldown - hoursSinceLastAttempt)
        TriggerClientEvent('QBCore:Notify', src, 'You need to wait ' .. hoursRemaining .. ' more hours before breeding again', 'error')
        return
    end
    
    -- Reset count if cooldown has passed
    if hoursSinceLastAttempt >= Config.Breeding.breedingCooldown then
        breedingAttempts[citizenId].count = 0
    end
    
    -- Check if player has both seed types
    local hasSeed1 = Player.Functions.GetItemByName(strain1 .. '_seed') ~= nil
    local hasSeed2 = Player.Functions.GetItemByName(strain2 .. '_seed') ~= nil
    
    if not hasSeed1 or not hasSeed2 then
        TriggerClientEvent('QBCore:Notify', src, 'You need both seed types to cross-breed', 'error')
        return
    end
    
    -- Check if this combination can produce a hybrid
    local hybridName = nil
    for name, hybrid in pairs(Config.HybridStrains) do
        if (hybrid.parents[1] == strain1 and hybrid.parents[2] == strain2) or
           (hybrid.parents[1] == strain2 and hybrid.parents[2] == strain1) then
            hybridName = name
            break
        end
    end
    
    if not hybridName then
        TriggerClientEvent('QBCore:Notify', src, 'These strains cannot be cross-bred', 'error')
        return
    end
    
        -- Remove the seeds
    Player.Functions.RemoveItem(strain1 .. '_seed', 1)
    Player.Functions.RemoveItem(strain2 .. '_seed', 1)
    
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[strain1 .. '_seed'], 'remove')
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[strain2 .. '_seed'], 'remove')
    
    -- Update breeding attempts
    breedingAttempts[citizenId].count = breedingAttempts[citizenId].count + 1
    breedingAttempts[citizenId].lastAttempt = currentTime
    
    -- Chance to get hybrid seed
    if math.random(100) <= Config.Breeding.crossBreedChance then
        -- Success - give hybrid seed
        Player.Functions.AddItem(hybridName, 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[hybridName], 'add')
        TriggerClientEvent('QBCore:Notify', src, 'Cross-breeding successful! You created a ' .. Config.HybridStrains[hybridName].label .. ' seed!', 'success')
        
        -- Check for achievement: breed hybrid
        CheckAchievement(citizenId, "breed_hybrid")
        
        -- Add research points
        AddResearchPoints(citizenId, 20) -- Bonus points for successful breeding
    else
        -- Failure - give back one random parent seed
        local randomParent = math.random(1, 2) == 1 and strain1 or strain2
        Player.Functions.AddItem(randomParent .. '_seed', 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[randomParent .. '_seed'], 'add')
        TriggerClientEvent('QBCore:Notify', src, 'Cross-breeding failed. You got a ' .. randomParent .. ' seed back.', 'error')
    end
end)

-- Sell drugs to dealer
RegisterNetEvent('kingz-weed:server:sellDrug', function(dealerId, itemName, amount, price)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if dealer exists
    local dealer = Config.Dealers[dealerId]
    if not dealer then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid dealer', 'error')
        return
    end
    
    -- Check if dealer is open
    local currentHour = tonumber(os.date("%H"))
    if currentHour < dealer.hours.open and currentHour >= dealer.hours.close then
        TriggerClientEvent('QBCore:Notify', src, 'This dealer is closed right now. Come back between ' .. dealer.hours.open .. ':00 and ' .. dealer.hours.close .. ':00', 'error')
        return
    end
    
    -- Check if dealer requires reputation
    if dealer.minReputation and dealer.reputation then
        local citizenId = Player.PlayerData.citizenid
        local reputation = playerReputations[citizenId] or 0
        
        if reputation < dealer.minReputation then
            TriggerClientEvent('QBCore:Notify', src, 'This dealer doesn\'t trust you yet. You need at least ' .. dealer.minReputation .. ' reputation points.', 'error')
            return
        end
    end
    
    -- Check if dealer requires license
    if dealer.requiresLicense then
        -- Check for medical license (implement your license system here)
        local hasLicense = Player.PlayerData.metadata.licences and Player.PlayerData.metadata.licences.medical or false
        
        if not hasLicense then
            TriggerClientEvent('QBCore:Notify', src, 'You need a medical license to sell to this dealer', 'error')
            return
        end
    end
    
    -- Check if dealer buys this item
    if not dealer.prices[itemName] then
        TriggerClientEvent('QBCore:Notify', src, 'Dealer doesn\'t buy this item', 'error')
        return
    end
    
    -- Check if player has the item
    local item = Player.Functions.GetItemByName(itemName)
    if not item or item.amount < amount then
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t have enough ' .. itemName, 'error')
        return
    end
    
    -- Get item metadata for quality
    local info = item.info or {}
    local qualityMultiplier = info.value or 1.0
    
    -- Calculate total price with quality multiplier
    local basePrice = price
    local adjustedPrice = math.floor(basePrice * qualityMultiplier)
    local totalPrice = adjustedPrice * amount
    
    -- Remove items and add money
    if Player.Functions.RemoveItem(itemName, amount) then
        Player.Functions.AddMoney('cash', totalPrice)
        
        -- Show item box
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'remove', amount)
        
        -- Notify player
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.sold', {amount = amount, item = itemName, price = totalPrice}), 'success')
        
        -- Add reputation if dealer uses reputation system
        if dealer.reputation then
            local citizenId = Player.PlayerData.citizenid
            playerReputations[citizenId] = (playerReputations[citizenId] or 0) + (Config.ShopReputation.pointsPerSale * amount)
            
            -- Notify player of reputation gain
            TriggerClientEvent('QBCore:Notify', src, 'Reputation increased by ' .. (Config.ShopReputation.pointsPerSale * amount) .. ' points', 'success')
        end
        
        -- Add research points
        AddResearchPoints(Player.PlayerData.citizenid, Config.Research.researchPoints.perSale * amount)
        
        -- Track total sales for achievements
        local totalSales = GetPlayerStat(Player.PlayerData.citizenid, "total_sales") or 0
        totalSales = totalSales + totalPrice
        SetPlayerStat(Player.PlayerData.citizenid, "total_sales", totalSales)
        
        -- Check for achievement: sell $10,000
        if totalSales >= 10000 then
            CheckAchievement(Player.PlayerData.citizenid, "sell_10000")
        end
        
        -- Chance to alert police
        local alertChance = 5 -- 5% chance
        if math.random(100) <= alertChance then
            -- Get player coords
            local coords = GetEntityCoords(GetPlayerPed(src))
            
            -- Alert police
            TriggerClientEvent('kingz-weed:client:createDealerBlip', -1, coords)
        end
    end
end)

-- Buy item from shop
RegisterNetEvent('kingz-weed:server:buyItem', function(itemName, price)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenId = Player.PlayerData.citizenid
    local reputation = playerReputations[citizenId] or 0
    
    -- Calculate discount based on reputation
    local discount = 0
    local reputationLevel = "Newcomer"
    
    for _, level in ipairs(Config.ShopReputation.levels) do
        if reputation >= level.min and reputation <= level.max then
            discount = level.discount
            reputationLevel = level.name
            break
        end
    end
    
    -- Apply discount
    local discountedPrice = math.floor(price * (1 - discount))
    
    -- Check if player has enough money
    if Player.Functions.GetMoney('cash') >= discountedPrice then
        -- Remove money
        Player.Functions.RemoveMoney('cash', discountedPrice, 'weed-shop-purchase')
        
        -- Add item
        Player.Functions.AddItem(itemName, 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'add')
        
        -- Add reputation points
        playerReputations[citizenId] = reputation + Config.ShopReputation.pointsPerPurchase
        
        -- Notify player
        if discount > 0 then
            TriggerClientEvent('kingz-weed:client:shopNotify', src, 'You purchased ' .. QBCore.Shared.Items[itemName].label .. ' with a ' .. (discount * 100) .. '% discount!', 'success')
        else
            TriggerClientEvent('kingz-weed:client:shopNotify', src, 'You purchased ' .. QBCore.Shared.Items[itemName].label, 'success')
        end
        
        TriggerClientEvent('kingz-weed:client:shopNotify', src, 'Shop Reputation: ' .. reputationLevel .. ' (' .. playerReputations[citizenId] .. ' points)', 'info')
    else
        TriggerClientEvent('kingz-weed:client:shopNotify', src, 'You don\'t have enough money', 'error')
    end
end)

-- Start a delivery mission
RegisterNetEvent('kingz-weed:server:startMission', function(dealerId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player is on cooldown
    local citizenId = Player.PlayerData.citizenid
    
    if missionCooldowns[citizenId] and missionCooldowns[citizenId] > os.time() then
        TriggerClientEvent('QBCore:Notify', src, 'You need to wait before taking another mission', 'error')
        return
    end
    
    -- Select random location
    local location = Config.BuyerMissions.locations[math.random(#Config.BuyerMissions.locations)]
    
    -- Select random mission type
    local missionType = Config.BuyerMissions.missionTypes[math.random(#Config.BuyerMissions.missionTypes)]
    
    -- Generate unique package ID
    local packageId = "package_" .. math.random(100000, 999999)
    
    -- Store mission data
    activeMissions[src] = {
        packageId = packageId,
        startTime = os.time(),
        endTime = os.time() + Config.BuyerMissions.timeLimit,
        dealerId = dealerId,
        missionType = missionType
    }
    
    -- Start mission on client
    TriggerClientEvent('kingz-weed:client:startMission', src, location, packageId, missionType)
    
    -- Chance to alert police
    if math.random(100) <= Config.BuyerMissions.policeAlertChance then
        TriggerClientEvent('kingz-weed:client:missionPoliceAlert', -1, location)
    end
end)

-- Complete a delivery mission
RegisterNetEvent('kingz-weed:server:completeMission', function(packageId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if mission exists and matches
    if not activeMissions[src] or activeMissions[src].packageId ~= packageId then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid mission', 'error')
        return
    end
    
    -- Calculate rewards
    local cashReward = math.random(Config.BuyerMissions.rewards.cash.min, Config.BuyerMissions.rewards.cash.max)
    
    -- Bonus for high-risk missions
    if activeMissions[src].missionType == "highRisk" then
        cashReward = cashReward * 1.5
    end
    
    -- Give cash reward
    Player.Functions.AddMoney('cash', cashReward)
    
    -- Chance for item rewards
    for _, itemReward in ipairs(Config.BuyerMissions.rewards.items) do
        if math.random(100) <= itemReward.chance then
            local amount = math.random(itemReward.amount.min, itemReward.amount.max)
            Player.Functions.AddItem(itemReward.item, amount)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemReward.item], 'add', amount)
        end
    end
    
    -- Very rare chance for vehicle reward
    for _, vehicleReward in ipairs(Config.BuyerMissions.vehicleRewards) do
        if math.random(100) <= vehicleReward.chance then
            -- Give vehicle (implement your vehicle giving system here)
            TriggerClientEvent('QBCore:Notify', src, 'You won a ' .. vehicleReward.vehicle .. '! Check your garage.', 'success')
            -- Example: TriggerEvent('qb-vehicleshop:server:giveVehicle', src, vehicleReward.vehicle)
        end
    end
    
    -- Add reputation
    local citizenId = Player.PlayerData.citizenid
    playerReputations[citizenId] = (playerReputations[citizenId] or 0) + 50
    
    -- Set cooldown
    missionCooldowns[citizenId] = os.time() + Config.BuyerMissions.cooldown
    
    -- Clear mission
    activeMissions[src] = nil
    
    TriggerClientEvent('QBCore:Notify', src, 'Mission completed! You earned $' .. cashReward, 'success')
end)

-- Competition system
function StartNewCompetition()
    currentCompetition = {
        active = true,
        startTime = os.time(),
        endTime = os.time() + (Config.Competitions.durationHours * 3600),
        entries = {},
        category = Config.Competitions.categories[math.random(#Config.Competitions.categories)]
    }
    
    -- Announce to all players
    for _, playerId in ipairs(QBCore.Functions.GetPlayers()) do
        TriggerClientEvent('QBCore:Notify', playerId, 'A new weed competition has started! Category: ' .. currentCompetition.category, 'primary')
        TriggerClientEvent('QBCore:Notify', playerId, 'Use /entercompetition to participate. Entry fee: $' .. Config.Competitions.entryFee, 'primary')
    end
    
    -- Schedule end of competition
    SetTimeout(Config.Competitions.durationHours * 3600 * 1000, EndCompetition)
end

function EndCompetition()
    if not currentCompetition.active then return end
    
    -- Sort entries by quality
    table.sort(currentCompetition.entries, function(a, b)
        return a.quality > b.quality
    end)
    
    -- Award prizes
    for i = 1, math.min(#currentCompetition.entries, #Config.Competitions.prizes) do
        local entry = currentCompetition.entries[i]
        local prize = Config.Competitions.prizes[i]
        
        -- Find player
        local Player = QBCore.Functions.GetPlayerByCitizenId(entry.citizenid)
        if Player then
            -- Award cash
            Player.Functions.AddMoney('cash', prize.cash, 'weed-competition-prize')
            
            -- Award reputation
            playerReputations[entry.citizenid] = (playerReputations[entry.citizenid] or 0) + prize.reputation
            
            -- Award item
            Player.Functions.AddItem(prize.item, 1)
            TriggerClientEvent('inventory:client:ItemBox', Player.PlayerData.source, QBCore.Shared.Items[prize.item], 'add')
            
            -- Add research points
            AddResearchPoints(entry.citizenid, Config.Research.researchPoints.perCompetition)
            
            -- Check for achievement: win competition
            if i == 1 then
                CheckAchievement(entry.citizenid, "win_competition")
            end
            
            -- Notify player
            TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, 'You won ' .. i .. getOrdinalSuffix(i) .. ' place in the weed competition! Prize: $' .. prize.cash, 'success')
        end
    end
    
    -- Announce results to all players
    for _, playerId in ipairs(QBCore.Functions.GetPlayers()) do
        TriggerClientEvent('QBCore:Notify', playerId, 'The weed competition has ended!', 'primary')
        
        if #currentCompetition.entries > 0 then
            local winner = currentCompetition.entries[1]
            TriggerClientEvent('QBCore:Notify', playerId, 'Winner: ' .. winner.playerName .. ' with ' .. winner.strainName .. ' (' .. winner.quality .. ' quality)', 'primary')
        else
            TriggerClientEvent('QBCore:Notify', playerId, 'No entries were submitted.', 'primary')
        end
    end
    
    -- Reset competition
    currentCompetition.active = false
    
    -- Schedule next competition
    SetTimeout((Config.Competitions.intervalHours - Config.Competitions.durationHours) * 3600 * 1000, StartNewCompetition)
end

-- Helper function for ordinal suffixes
function getOrdinalSuffix(num)
    local suffixes = {"st", "nd", "rd"}
    local suffix = "th"
    
    if num <= 3 then
        suffix = suffixes[num]
    end
    
    return suffix
end

-- Event to submit competition entry
RegisterNetEvent('kingz-weed:server:submitCompetitionEntry', function(itemName, itemSlot)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    if not currentCompetition.active then
        TriggerClientEvent('QBCore:Notify', src, 'There is no active competition right now.', 'error')
        return
    end
    
    -- Check if player already entered
    for _, entry in ipairs(currentCompetition.entries) do
        if entry.citizenid == Player.PlayerData.citizenid then
            TriggerClientEvent('QBCore:Notify', src, 'You have already entered this competition.', 'error')
            return
        end
    end
    
    -- Check if player has entry fee
    if Player.Functions.GetMoney('cash') < Config.Competitions.entryFee then
        TriggerClientEvent('QBCore:Notify', src, 'You need $' .. Config.Competitions.entryFee .. ' to enter the competition.', 'error')
        return
    end
    
    -- Get item from inventory
    local item = Player.Functions.GetItemBySlot(itemSlot)
    if not item or item.name ~= itemName then
        TriggerClientEvent('QBCore:Notify', src, 'Item not found.', 'error')
        return
    end
    
    -- Check if item has quality metadata
    local info = item.info or {}
    local quality = 50 -- Default quality
    local qualityName = "Standard"
    local thcContent = info.thc or 5
    local cbdContent = info.cbd or 1
    
    if info.quality then
        qualityName = info.quality
        
        -- Convert quality name to number
        for _, level in ipairs(Config.QualityLevels) do
            if level.name == qualityName then
                quality = (level.min + level.max) / 2 -- Use average of range
                break
            end
        end
    end
    
    -- Calculate competition score based on category
    local score = quality
    if currentCompetition.category == "Highest THC Content" then
        score = thcContent * 5 -- Weight THC content more heavily
    elseif currentCompetition.category == "Best Quality" then
        score = quality -- Already using quality
    elseif currentCompetition.category == "Most Exotic Strain" then
        -- Rarer strains get higher scores
        local rarityScore = 50
        if itemName == "white_widow" or itemName == "amnesia_kush" then
            rarityScore = 90
        elseif itemName == "og_kush" or itemName == "amnesia" then
            rarityScore = 80
        elseif itemName == "purple_haze" or itemName == "skunk" then
            rarityScore = 70
        elseif itemName == "weed" then
            rarityScore = 50
        end
        score = (quality * 0.6) + (rarityScore * 0.4) -- 60% quality, 40% rarity
    elseif currentCompetition.category == "Best Hybrid" then
        -- Check if it's a hybrid
        local isHybrid = false
        for hybridName, _ in pairs(Config.HybridStrains) do
            if itemName == hybridName:gsub("_seed", "") then
                isHybrid = true
                break
            end
        end
        
        if isHybrid then
            score = quality * 1.5 -- Bonus for hybrids
        else
            score = quality * 0.5 -- Penalty for non-hybrids
        end
    end
    
    -- Remove entry fee
    Player.Functions.RemoveMoney('cash', Config.Competitions.entryFee, 'weed-competition-entry')
    
    -- Remove the weed item
    Player.Functions.RemoveItem(itemName, 1, itemSlot)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'remove')
    
    -- Add entry to competition
    table.insert(currentCompetition.entries, {
        citizenid = Player.PlayerData.citizenid,
        playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        strainName = QBCore.Shared.Items[itemName].label,
        quality = score,
        qualityName = qualityName,
        thcContent = thcContent,
        cbdContent = cbdContent
    })
    
    TriggerClientEvent('QBCore:Notify', src, 'You entered the competition with ' .. QBCore.Shared.Items[itemName].label .. ' (' .. qualityName .. ' quality).', 'success')
end)

-- Research system
function AddResearchPoints(citizenId, points)
    if not playerResearch[citizenId] then
        playerResearch[citizenId] = {
            points = 0,
            upgrades = {}
        }
    end
    
    playerResearch[citizenId].points = playerResearch[citizenId].points + points
    
    -- Notify player if online
    local Player = QBCore.Functions.GetPlayerByCitizenId(citizenId)
    if Player then
        TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, 'You gained ' .. points .. ' research points. Total: ' .. playerResearch[citizenId].points, 'success')
    end
end

-- Purchase research upgrade
RegisterNetEvent('kingz-weed:server:purchaseResearch', function(upgradeName, level)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenId = Player.PlayerData.citizenid
    
    -- Initialize research data if needed
    if not playerResearch[citizenId] then
        playerResearch[citizenId] = {
            points = 0,
            upgrades = {}
        }
    end
    
    -- Find the upgrade
    local upgradeFound = false
    local upgradeData = nil
    
    for _, upgrade in ipairs(Config.Research.upgrades) do
        if upgrade.name == upgradeName then
            upgradeFound = true
            upgradeData = upgrade
            break
        end
    end
    
    if not upgradeFound then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid research upgrade', 'error')
        return
    end
    
    -- Check if level is valid
    if level < 1 or level > upgradeData.levels then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid upgrade level', 'error')
        return
    end
    
    -- Check if player already has this level or higher
    local currentLevel = playerResearch[citizenId].upgrades[upgradeName] or 0
    if currentLevel >= level then
        TriggerClientEvent('QBCore:Notify', src, 'You already have this upgrade level or higher', 'error')
        return
    end
    
    -- Check if player has enough points
    local pointsRequired = upgradeData.pointsRequired[level]
    if playerResearch[citizenId].points < pointsRequired then
        TriggerClientEvent('QBCore:Notify', src, 'Not enough research points. You need ' .. pointsRequired .. ' points.', 'error')
        return
    end
    
    -- Purchase the upgrade
    playerResearch[citizenId].points = playerResearch[citizenId].points - pointsRequired
    playerResearch[citizenId].upgrades[upgradeName] = level
    
    TriggerClientEvent('QBCore:Notify', src, 'Research upgrade purchased: ' .. upgradeName .. ' Level ' .. level, 'success')
    
    -- Send updated research data to client
    TriggerClientEvent('kingz-weed:client:updateResearch', src, playerResearch[citizenId])
end)

-- Achievement system
function CheckAchievement(citizenId, achievementId)
    -- Check if player already has this achievement
    local playerAchievements = GetPlayerAchievements(citizenId)
    
    if playerAchievements[achievementId] then
        return -- Already has achievement
    end
    
    -- Find achievement data
    local achievementData = nil
    for _, achievement in ipairs(Config.Achievements) do
        if achievement.id == achievementId then
            achievementData = achievement
            break
        end
    end
    
    if not achievementData then
        return -- Achievement not found
    end
    
    -- Award achievement
    playerAchievements[achievementId] = os.time()
    
    -- Find player
    local Player = QBCore.Functions.GetPlayerByCitizenId(citizenId)
    if Player then
        -- Give rewards
        if achievementData.reward.item then
            Player.Functions.AddItem(achievementData.reward.item, achievementData.reward.amount or 1)
            TriggerClientEvent('inventory:client:ItemBox', Player.PlayerData.source, QBCore.Shared.Items[achievementData.reward.item], 'add', achievementData.reward.amount or 1)
        end
        
        if achievementData.reward.reputation then
            playerReputations[citizenId] = (playerReputations[citizenId] or 0) + achievementData.reward.reputation
        end
        
        -- Notify player
        TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, 'Achievement Unlocked: ' .. achievementData.name, 'success')
        TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, achievementData.description, 'success')
    end
    
    -- Save achievements
    SavePlayerAchievements(citizenId, playerAchievements)
end

function GetPlayerAchievements(citizenId)
    if not playerAchievements[citizenId] then
        playerAchievements[citizenId] = {}
        -- In a real implementation, you would load from database here
    end
    
    return playerAchievements[citizenId]
end

function SavePlayerAchievements(citizenId, achievements)
    playerAchievements[citizenId] = achievements
    -- In a real implementation, you would save to database here
end

-- Player stats system
function GetPlayerStat(citizenId, statName)
    -- In a real implementation, you would load from database
    -- For now, we'll use a simple in-memory storage
    if not playerStats[citizenId] then playerStats[citizenId] = {} end
    
    return playerStats[citizenId][statName]
end

function SetPlayerStat(citizenId, statName, value)
    -- In a real implementation, you would save to database
    if not playerStats[citizenId] then playerStats[citizenId] = {} end
    
    playerStats[citizenId][statName] = value
end

-- Callbacks
QBCore.Functions.CreateCallback('kingz-weed:server:hasItem', function(source, cb, itemName)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        local item = Player.Functions.GetItemByName(itemName)
        cb(item ~= nil and item.amount > 0)
    else
        cb(false)
    end
end)

QBCore.Functions.CreateCallback('kingz-weed:server:getPlayerDrugs', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    local items = {}
    
    if Player then
        for dealerId, dealer in ipairs(Config.Dealers) do
            for itemName, price in pairs(dealer.prices) do
                local item = Player.Functions.GetItemByName(itemName)
                if item then
                    table.insert(items, {
                        name = itemName,
                        label = QBCore.Shared.Items[itemName].label,
                        amount = item.amount,
                        dealerId = dealerId
                    })
                end
            end
        end
    end
    
    cb(items)
end)

QBCore.Functions.CreateCallback('kingz-weed:server:getPlayerWeed', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    local items = {}
    
    if Player then
        -- Check for all weed types directly
        local weedTypes = {
            'weed', 'purple_haze', 'skunk', 'og_kush', 'amnesia', 'northern_lights', 'white_widow',
            'purple_skunk', 'kush_haze', 'widow_lights', 'amnesia_kush'
        }
        
        for _, weedType in ipairs(weedTypes) do
            local item = Player.Functions.GetItemByName(weedType)
            if item and item.amount > 0 then
                table.insert(items, {
                    name = weedType,
                    label = QBCore.Shared.Items[weedType].label,
                    amount = item.amount
                })
            end
        end
        
        -- Debug print
        if #items == 0 then
            print("Player has no weed items found")
            -- Check what items the player actually has
            local inventory = Player.PlayerData.items
            for _, item in pairs(inventory) do
                if item then
                    print("Player has item: " .. item.name .. " x" .. item.amount)
                end
            end
        else
            print("Found " .. #items .. " weed items")
        end
    end
    
    cb(items)
end)

QBCore.Functions.CreateCallback('kingz-weed:server:canProcess', function(source, cb, itemName, processType)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then
        cb(false, "Player not found")
        return
    end
    
    -- Check if player has the weed
    local hasWeed = Player.Functions.GetItemByName(itemName) ~= nil
    if not hasWeed then
        cb(false, "You don't have any " .. itemName)
        return
    end
    
    -- Check for required items based on process type
    if processType == 'joint' then
        local hasPapers = Player.Functions.GetItemByName('rolling_paper') ~= nil
        cb(hasPapers, "You need rolling papers")
    elseif processType == 'packaged' then
        local hasBaggies = Player.Functions.GetItemByName('empty_baggie') ~= nil
        cb(hasBaggies, "You need empty baggies")
    elseif processType == 'concentrate' then
        local hasKit = Player.Functions.GetItemByName('extraction_kit') ~= nil
        cb(hasKit, "You need an extraction kit")
    elseif processType == 'edible' then
        local hasMix = Player.Functions.GetItemByName('brownie_mix') ~= nil
        cb(hasMix, "You need brownie mix")
    else
        cb(false, "Unknown process type")
    end
end)

QBCore.Functions.CreateCallback('kingz-weed:server:hasAnyWeed', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then
        cb(false)
        return
    end
    
    -- Check for any weed type
    local weedTypes = {
        'weed', 'purple_haze', 'skunk', 'og_kush', 'amnesia', 'northern_lights', 'white_widow',
        'purple_skunk', 'kush_haze', 'widow_lights', 'amnesia_kush'
    }
    
    for _, weedType in ipairs(weedTypes) do
        local item = Player.Functions.GetItemByName(weedType)
        if item and item.amount > 0 then
            cb(true, weedType)
            return
        end
    end
    
    cb(false)
end)

QBCore.Functions.CreateCallback('kingz-weed:server:getItemSlot', function(source, cb, itemName)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then
        cb(nil)
        return
    end
    
    local items = Player.PlayerData.items
    for slot, item in pairs(items) do
        if item and item.name == itemName then
            cb(slot)
            return
        end
    end
    
    cb(nil)
end)

QBCore.Functions.CreateCallback('kingz-weed:server:canStartMission', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then
        cb(false, 0)
        return
    end
    
    local citizenId = Player.PlayerData.citizenid
    
    -- Check if player is on cooldown
    if missionCooldowns[citizenId] and missionCooldowns[citizenId] > os.time() then
        local cooldownRemaining = missionCooldowns[citizenId] - os.time()
        cb(false, cooldownRemaining)
        return
    end
    
    -- Check if player already has an active mission
    if activeMissions[source] then
        cb(false, 0)
        return
    end
    
    cb(true, 0)
end)

QBCore.Functions.CreateCallback('kingz-weed:server:getResearch', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then
        cb(nil)
        return
    end
    
    local citizenId = Player.PlayerData.citizenid
    
    if not playerResearch[citizenId] then
        playerResearch[citizenId] = {
            points = 0,
            upgrades = {}
        }
    end
    
    cb(playerResearch[citizenId])
end)

QBCore.Functions.CreateCallback('kingz-weed:server:getAchievements', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then
        cb(nil)
        return
    end
    
    local citizenId = Player.PlayerData.citizenid
    cb(GetPlayerAchievements(citizenId))
end)

QBCore.Functions.CreateCallback('kingz-weed:server:getReputation', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then
        cb(0, "Newcomer", 0)
        return
    end
    
    local citizenId = Player.PlayerData.citizenid
    local reputation = playerReputations[citizenId] or 0
    
    -- Determine reputation level
    local reputationLevel = "Newcomer"
    local discount = 0
    
    for _, level in ipairs(Config.ShopReputation.levels) do
        if reputation >= level.min and reputation <= level.max then
            reputationLevel = level.name
            discount = level.discount
            break
        end
    end
    
    cb(reputation, reputationLevel, discount)
end)

QBCore.Functions.CreateCallback('kingz-weed:server:getCompetitionInfo', function(source, cb)
    cb(currentCompetition)
end)

-- Thread to handle plant growth and care
CreateThread(function()
    while true do
        Wait(10000) -- Check every 10 seconds
        local currentTime = os.time()
        local playersToNotify = {}
        local currentSeason = GetCurrentSeason()
        local seasonConfig = Config.Seasons[currentSeason]
        
        for id, plant in pairs(plants) do
            -- Calculate time passed since last check
            local timePassed = currentTime - (plant.lastUpdated or currentTime)
            plant.lastUpdated = currentTime
            
            local minutesPassed = timePassed / 60 -- Convert seconds to minutes
            
            -- Calculate water decay rate
            local waterDecayRate = 0.2 -- % per minute
            local fertilizerDecayRate = 0.15 -- % per minute
            
            -- Check if plant is under a heat lamp
            local isUnderHeatLamp = false
            for _, lamp in pairs(heatLamps) do
                if #(vector3(plant.coords.x, plant.coords.y, plant.coords.z) - vector3(lamp.coords.x, lamp.coords.y, lamp.coords.z)) <= Config.HeatLamps.range then
                    isUnderHeatLamp = true
                    break
                end
            end
            
            -- Check if plant is in a hydroponic system
            local isHydroponic = plant.isHydroponic
            
            -- Apply research bonuses if any
            local citizenId = plant.owner
            local researchData = playerResearch[citizenId] or {upgrades = {}}
            
            -- Resource Efficiency research
            local resourceEfficiency = researchData.upgrades["Resource Efficiency"] or 0
            if resourceEfficiency > 0 then
                waterDecayRate = waterDecayRate * (1 - Config.Research.upgrades[4].effects.waterSavings[resourceEfficiency])
                fertilizerDecayRate = fertilizerDecayRate * (1 - Config.Research.upgrades[4].effects.fertilizerSavings[resourceEfficiency])
            end
            
            -- Adjust decay rates based on conditions
            if isUnderHeatLamp then
                waterDecayRate = waterDecayRate * (1 + Config.HeatLamps.effects.waterConsumptionIncrease)
            end
            
            if isHydroponic then
                waterDecayRate = waterDecayRate * (1 - Config.Hydroponics.waterSavings)
            end
            
            -- Apply seasonal effects
            waterDecayRate = waterDecayRate * (1 + seasonConfig.waterDecayIncrease)
            
            -- Decay water and fertilizer levels
            plant.water = math.max(0, plant.water - (waterDecayRate * minutesPassed * 100))
            plant.fertilizer = math.max(0, plant.fertilizer - (fertilizerDecayRate * minutesPassed * 100))
            
            -- Check for bug infestation
            if plant.pesticideUntil < currentTime and not plant.hasBugs then
                -- Apply pest resistance research if any
                local pestResistance = researchData.upgrades["Pest Resistance"] or 0
                local bugChance = Config.PlantCare.bugInfestationChance
                
                if pestResistance > 0 then
                    bugChance = bugChance * (1 - Config.Research.upgrades[5].effects.bugResistance[pestResistance])
                end
                
                -- Apply seasonal effects
                bugChance = bugChance * seasonConfig.bugChanceMultiplier
                
                -- Chance for bugs to appear
                if math.random(1, 1000) <= bugChance * 10 then -- Convert to per 10 seconds
                    plant.hasBugs = true
                    
                    -- Find plant owner to notify
                    for _, playerId in ipairs(QBCore.Functions.GetPlayers()) do
                        local Player = QBCore.Functions.GetPlayer(playerId)
                        if Player and Player.PlayerData.citizenid == plant.owner then
                            if not playersToNotify[playerId] then
                                playersToNotify[playerId] = {}
                            end
                            table.insert(playersToNotify[playerId], {
                                type = "bugs",
                                plantType = (plant.isHybrid and Config.HybridStrains[plant.type] or Config.Plants[plant.type]).label
                            })
                            break
                        end
                    end
                end
            end
            
            -- Check for disease
            if not plant.hasDisease then
                local diseaseChance = Config.PlantCare.diseaseChance / (24 * 60) -- Convert from daily chance to per minute
                
                if math.random(1, 10000) <= diseaseChance * minutesPassed * 10000 then
                    plant.hasDisease = true
                    
                    -- Find plant owner to notify
                    for _, playerId in ipairs(QBCore.Functions.GetPlayers()) do
                        local Player = QBCore.Functions.GetPlayer(playerId)
                        if Player and Player.PlayerData.citizenid == plant.owner then
                            if not playersToNotify[playerId] then
                                playersToNotify[playerId] = {}
                            end
                            table.insert(playersToNotify[playerId], {
                                type = "disease",
                                plantType = (plant.isHybrid and Config.HybridStrains[plant.type] or Config.Plants[plant.type]).label
                            })
                            break
                        end
                    end
                end
            end
            
            -- Update health based on water, fertilizer, bugs, and disease
            local healthChange = 0
            
            -- Water effects on health
            if plant.water < 20 then
                healthChange = healthChange - (Config.PlantCare.waterDecay * minutesPassed) -- Lose health when very thirsty
            elseif plant.water < 40 then
                healthChange = healthChange - (Config.PlantCare.waterDecay * 0.5 * minutesPassed) -- Lose less health when thirsty
            elseif plant.water > 80 then
                healthChange = healthChange + (0.1 * minutesPassed) -- Gain health when well-watered
            end
            
            -- Fertilizer effects on health
            if plant.fertilizer < 20 then
                healthChange = healthChange - (Config.PlantCare.fertilizeDecay * minutesPassed) -- Lose health when very hungry
            elseif plant.fertilizer < 40 then
                healthChange = healthChange - (Config.PlantCare.fertilizeDecay * 0.5 * minutesPassed) -- Lose less health when hungry
            elseif plant.fertilizer > 80 then
                healthChange = healthChange + (0.2 * minutesPassed) -- Gain health when well-fed
            end
            
            -- Bug effects on health
            if plant.hasBugs then
                healthChange = healthChange - (Config.PlantCare.bugDamage * minutesPassed)
            end
            
            -- Disease effects on health
            if plant.hasDisease then
                healthChange = healthChange - (Config.PlantCare.diseaseDamage * minutesPassed)
            end
            
            -- Heat lamp bonus to health
            if isUnderHeatLamp then
                healthChange = healthChange + (0.1 * minutesPassed) -- Additional health gain under heat lamp
            end
            
            -- Hydroponic bonus to health
            if isHydroponic then
                healthChange = healthChange + (0.15 * minutesPassed) -- Additional health gain with hydroponics
            end
            
            -- Calculate max health (with bonuses if applicable)
            local maxHealth = Config.PlantCare.maxHealth
            
            if isUnderHeatLamp then
                maxHealth = maxHealth + Config.HeatLamps.effects.maxHealthBonus
            end
            
            -- Update plant health
            plant.health = math.max(0, math.min(maxHealth, plant.health + healthChange))
            
            -- Handle growth if plant is healthy enough
            if plant.health > 30 and plant.nextGrowth <= currentTime then
                local plantConfig = plant.isHybrid and Config.HybridStrains[plant.type] or Config.Plants[plant.type]
                
                if plant.stage < #plantConfig.stages then
                    -- Advance to next stage
                    plant.stage = plant.stage + 1
                    local nextStageConfig = plantConfig.stages[plant.stage]
                    
                    -- Set next growth time if not final stage
                    if nextStageConfig.time > 0 then
                        local growthTime = nextStageConfig.time
                        
                        -- Apply heat lamp growth speed bonus
                        if isUnderHeatLamp then
                            growthTime = growthTime * (1 - Config.HeatLamps.effects.growthSpeedBonus)
                        end
                        
                        -- Apply hydroponic growth speed bonus
                        if isHydroponic then
                            growthTime = growthTime * (1 - Config.Hydroponics.growthBonus)
                        end
                        
                        -- Apply seasonal growth bonus
                        growthTime = growthTime * (1 - seasonConfig.growthBonus)
                        
                        -- Apply research growth acceleration if any
                        local growthAcceleration = researchData.upgrades["Growth Acceleration"] or 0
                        if growthAcceleration > 0 then
                            growthTime = growthTime * (1 - Config.Research.upgrades[1].effects.growthBonus[growthAcceleration])
                        end
                        
                        plant.nextGrowth = currentTime + growthTime
                    else
                        plant.nextGrowth = 0 -- Final stage
                    end
                    
                    -- Find plant owner to notify
                    for _, playerId in ipairs(QBCore.Functions.GetPlayers()) do
                        local Player = QBCore.Functions.GetPlayer(playerId)
                        if Player and Player.PlayerData.citizenid == plant.owner then
                            if not playersToNotify[playerId] then
                                playersToNotify[playerId] = {}
                            end
                            table.insert(playersToNotify[playerId], {
                                type = "growth",
                                plantType = plantConfig.label,
                                stage = plant.stage,
                                maxStage = #plantConfig.stages
                            })
                            break
                        end
                    end
                    
                    -- Update plant model on all clients
                    TriggerClientEvent('kingz-weed:client:updatePlant', -1, id, plant.stage, {
                        water = plant.water,
                        fertilizer = plant.fertilizer,
                        health = plant.health,
                        isUnderHeatLamp = isUnderHeatLamp,
                        isHydroponic = isHydroponic,
                        hasBugs = plant.hasBugs,
                        hasDisease = plant.hasDisease,
                        pesticideUntil = plant.pesticideUntil,
                        soilQuality = plant.soilQuality
                    })
                    
                    DebugPrint('Plant ID: ' .. id .. ' advanced to stage: ' .. plant.stage)
                end
            else
                -- Update clients with new plant data
                TriggerClientEvent('kingz-weed:client:updatePlantData', -1, id, {
                    water = plant.water,
                    fertilizer = plant.fertilizer,
                    health = plant.health,
                    isUnderHeatLamp = isUnderHeatLamp,
                    isHydroponic = isHydroponic,
                    hasBugs = plant.hasBugs,
                    hasDisease = plant.hasDisease,
                    pesticideUntil = plant.pesticideUntil,
                    soilQuality = plant.soilQuality
                })
            end
            
            -- If health reaches 0, plant dies
            if plant.health <= 0 then
                DebugPrint('Plant ID: ' .. id .. ' died due to neglect')
                
                -- Find plant owner to notify
                for _, playerId in ipairs(QBCore.Functions.GetPlayers()) do
                    local Player = QBCore.Functions.GetPlayer(playerId)
                    if Player and Player.PlayerData.citizenid == plant.owner then
                        if not playersToNotify[playerId] then
                            playersToNotify[playerId] = {}
                        end
                        table.insert(playersToNotify[playerId], {
                            type = "death",
                            plantType = (plant.isHybrid and Config.HybridStrains[plant.type] or Config.Plants[plant.type]).label
                        })
                        break
                    end
                end
                
                -- Remove plant
                plants[id] = nil
                TriggerClientEvent('kingz-weed:client:removePlant', -1, id)
            end
        end
        
        -- Send notifications to players
        for playerId, notifications in pairs(playersToNotify) do
            for _, notification in ipairs(notifications) do
                if notification.type == "growth" then
                    TriggerClientEvent('QBCore:Notify', playerId, 'Your ' .. notification.plantType .. ' grew to stage ' .. notification.stage .. '/' .. notification.maxStage, 'success')
                elseif notification.type == "death" then
                    TriggerClientEvent('QBCore:Notify', playerId, 'Your ' .. notification.plantType .. ' died due to neglect', 'error')
                elseif notification.type == "bugs" then
                    TriggerClientEvent('QBCore:Notify', playerId, 'Your ' .. notification.plantType .. ' has a bug infestation!', 'error')
                elseif notification.type == "disease" then
                    TriggerClientEvent('QBCore:Notify', playerId, 'Your ' .. notification.plantType .. ' has developed a disease!', 'error')
                end
            end
        end
    end
end)

-- Thread to handle electricity costs for heat lamps and hydroponics
CreateThread(function()
    while true do
        Wait(3600000) -- Check every hour
        
        -- Process heat lamp electricity costs
        for lampId, lamp in pairs(heatLamps) do
            local owner = lamp.owner
            local Player = QBCore.Functions.GetPlayerByCitizenId(owner)
            
            if Player then
                -- Charge electricity cost
                Player.Functions.RemoveMoney('bank', Config.HeatLamps.electricityCost, 'heat-lamp-electricity')
                TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, 'You were charged $' .. Config.HeatLamps.electricityCost .. ' for heat lamp electricity', 'primary')
            end
        end
        
        -- Process hydroponic system maintenance costs
        for systemId, system in pairs(hydroponicSystems) do
            local owner = system.owner
            local Player = QBCore.Functions.GetPlayerByCitizenId(owner)
            
            if Player then
                -- Charge maintenance cost
                Player.Functions.RemoveMoney('bank', Config.Hydroponics.maintenanceCost, 'hydroponics-maintenance')
                TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, 'You were charged $' .. Config.Hydroponics.maintenanceCost .. ' for hydroponic system maintenance', 'primary')
            end
        end
    end
end)

-- Thread to handle business operations
CreateThread(function()
    if not Config.Business.enabled then return end
    
    while true do
        Wait(3600000) -- Process every hour
        
        for businessId, business in pairs(businessData) do
            -- Calculate customers this hour
            local customers = math.random(business.customerFrequency - 2, business.customerFrequency + 2)
            
            -- Calculate sales
            local totalSales = 0
            local totalCost = 0
            local inventory = business.inventory or {}
            
            for i = 1, customers do
                -- Select random product
                if #inventory > 0 then
                    local randomIndex = math.random(#inventory)
                    local product = inventory[randomIndex]
                    
                    if product.amount > 0 then
                        -- Sell one product
                        product.amount = product.amount - 1
                        totalSales = totalSales + product.price
                        totalCost = totalCost + product.cost
                        
                        -- Remove from inventory if out of stock
                        if product.amount <= 0 then
                            table.remove(inventory, randomIndex)
                        end
                    end
                end
            end
            
            -- Calculate profit
            local profit = totalSales - totalCost
            
            -- Apply tax
            local taxAmount = profit * Config.Business.taxRate
            profit = profit - taxAmount
            
            -- Add money to business owner
            if profit > 0 then
                local owner = business.owner
                local Player = QBCore.Functions.GetPlayerByCitizenId(owner)
                
                if Player then
                    Player.Functions.AddMoney('bank', profit, 'weed-business-profit')
                    TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, 'Your business made $' .. profit .. ' profit this hour', 'success')
                end
            end
            
            -- Update business data
            business.inventory = inventory
            business.lastProfit = profit
            business.totalProfit = (business.totalProfit or 0) + profit
            
            -- Daily expenses once per day
            if tonumber(os.date("%H")) == 0 then -- Midnight
                local owner = business.owner
                local Player = QBCore.Functions.GetPlayerByCitizenId(owner)
                
                if Player then
                    Player.Functions.RemoveMoney('bank', business.dailyExpenses, 'weed-business-expenses')
                    TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, 'Your business had $' .. business.dailyExpenses .. ' in daily expenses', 'primary')
                end
            end
        end
    end
end)

-- Start competition system when resource starts
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if Config.Competitions.enabled then
            StartNewCompetition()
        end
        
        -- Debug item names
        DebugItemNames()
    end
end)

-- Function to debug item names
function DebugItemNames()
    print("=== DEBUG: CHECKING ITEM NAMES ===")
    for itemName, _ in pairs(QBCore.Shared.Items) do
        if string.find(itemName:lower(), "weed") or 
           string.find(itemName:lower(), "joint") or 
           string.find(itemName:lower(), "seed") or
           string.find(itemName:lower(), "kush") or
           string.find(itemName:lower(), "haze") or
           string.find(itemName:lower(), "skunk") or
           string.find(itemName:lower(), "amnesia") then
            print("Found item: " .. itemName)
        end
    end
    print("================================")
end

-- Commands
RegisterCommand('buyheatLamp', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player has enough money
    if Player.Functions.GetMoney('cash') >= Config.HeatLamps.price then
        -- Remove money
        Player.Functions.RemoveMoney('cash', Config.HeatLamps.price, 'bought-heat-lamp')
        
        -- Add heat lamp item
        Player.Functions.AddItem('heat_lamp', 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['heat_lamp'], 'add')
        
        TriggerClientEvent('QBCore:Notify', src, 'You purchased a heat lamp for $' .. Config.HeatLamps.price, 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'You need $' .. Config.HeatLamps.price .. ' to buy a heat lamp', 'error')
    end
end, false)

-- Also add an alias with the original typo for backward compatibility
RegisterCommand('buyheatamp', function(source)
    local src = source
    ExecuteCommand('buyheatLamp')
end, false)

-- Direct command to buy a heat lamp
RegisterCommand('buyheatlampdirect', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then 
        print("Player not found")
        return 
    end
    
    print("Player attempting to buy heat lamp")
    
    -- Add heat lamp item directly
    Player.Functions.AddItem('heat_lamp', 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['heat_lamp'], 'add')
    
    TriggerClientEvent('QBCore:Notify', src, 'You received a heat lamp', 'success')
    print("Heat lamp given to player")
end, false)

-- Debug command to check inventory
RegisterCommand('checkinventory', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local inventory = Player.PlayerData.items
    TriggerClientEvent('QBCore:Notify', src, 'Checking inventory (see server console)', 'primary')
    
    print("=== PLAYER INVENTORY ===")
    for _, item in pairs(inventory) do
        if item then
            print(item.name .. " x" .. item.amount)
        end
    end
    print("========================")
end, false)

-- Debug command to give seeds
RegisterCommand('giveseed', function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local seedType = args[1] or 'cannabis_seed'
    local amount = tonumber(args[2]) or 5
    
    if Player then
        if Config.Plants[seedType] or Config.HybridStrains[seedType] then
            Player.Functions.AddItem(seedType, amount)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[seedType], 'add', amount)
            TriggerClientEvent('QBCore:Notify', src, 'You received ' .. amount .. ' ' .. seedType, 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'Invalid seed type: ' .. seedType, 'error')
        end
    end
end, false)

-- Debug command to give processing items
RegisterCommand('giveweedtools', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        -- Check if pesticide item exists
        if QBCore.Shared.Items['pesticide'] then
            print("Adding pesticide to player inventory")
            Player.Functions.AddItem('pesticide', 5)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['pesticide'], 'add', 5)
        else
            print("WARNING: Pesticide item does not exist in shared items")
            TriggerClientEvent('QBCore:Notify', src, 'WARNING: Pesticide item does not exist in shared items', 'error')
        end
        
        Player.Functions.AddItem('water_bottle', 10)
        Player.Functions.AddItem('fertilizer', 10)
        Player.Functions.AddItem('rolling_paper', 20)
        Player.Functions.AddItem('empty_baggie', 20)
        Player.Functions.AddItem('bong', 1)
        Player.Functions.AddItem('grinder', 1)
        Player.Functions.AddItem('extraction_kit', 1)
        Player.Functions.AddItem('brownie_mix', 5)
        Player.Functions.AddItem('weed_medicine', 3)
        Player.Functions.AddItem('premium_soil', 3)
        Player.Functions.AddItem('weed_nutrition', 3)
        Player.Functions.AddItem('hydroponic_kit', 1)
        
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['water_bottle'], 'add', 10)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['fertilizer'], 'add', 10)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['rolling_paper'], 'add', 20)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['empty_baggie'], 'add', 20)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['bong'], 'add', 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['grinder'], 'add', 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['extraction_kit'], 'add', 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['brownie_mix'], 'add', 5)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['weed_medicine'], 'add', 3)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['premium_soil'], 'add', 3)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['weed_nutrition'], 'add', 3)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['hydroponic_kit'], 'add', 1)
        
        TriggerClientEvent('QBCore:Notify', src, 'You received weed growing tools', 'success')
    end
end, false)

-- Debug command to give weed directly
RegisterCommand('giveweed', function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local weedType = args[1] or 'weed'
    local amount = tonumber(args[2]) or 5
    
    if Player then
        local weedTypes = {
            'weed', 'purple_haze', 'skunk', 'og_kush', 'amnesia', 'northern_lights', 'white_widow',
            'purple_skunk', 'kush_haze', 'widow_lights', 'amnesia_kush'
        }
        
        if weedType == 'all' then
            for _, type in ipairs(weedTypes) do
                Player.Functions.AddItem(type, amount)
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[type], 'add', amount)
            end
            TriggerClientEvent('QBCore:Notify', src, 'You received all types of weed', 'success')
        else
            -- Check if weedType is valid
            local validType = false
            for _, type in ipairs(weedTypes) do
                if type == weedType then
                    validType = true
                    break
                end
            end
            
            if validType then
                Player.Functions.AddItem(weedType, amount)
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[weedType], 'add', amount)
                TriggerClientEvent('QBCore:Notify', src, 'You received ' .. amount .. ' ' .. weedType, 'success')
            else
                TriggerClientEvent('QBCore:Notify', src, 'Invalid weed type: ' .. weedType, 'error')
            end
        end
    end
end, false)

-- Debug command to give pesticide
RegisterCommand('givepesticide', function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local amount = tonumber(args[1]) or 5
    
    if Player then
        Player.Functions.AddItem('pesticide', amount)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['pesticide'], 'add', amount)
        TriggerClientEvent('QBCore:Notify', src, 'You received ' .. amount .. ' pesticide', 'success')
        print("Gave player " .. amount .. " pesticide")
    end
end, false)

-- Command to check reputation
RegisterCommand('checkrep', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenId = Player.PlayerData.citizenid
    local reputation = playerReputations[citizenId] or 0
    
    -- Determine reputation level
    local reputationLevel = "Newcomer"
    local discount = 0
    
    for _, level in ipairs(Config.ShopReputation.levels) do
        if reputation >= level.min and reputation <= level.max then
            reputationLevel = level.name
            discount = level.discount
            break
        end
    end
    
    TriggerClientEvent('QBCore:Notify', src, 'Shop Reputation: ' .. reputationLevel .. ' (' .. reputation .. ' points)', 'primary')
    TriggerClientEvent('QBCore:Notify', src, 'Discount: ' .. (discount * 100) .. '%', 'primary')
end, false)

-- Command to check research
RegisterCommand('checkresearch', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenId = Player.PlayerData.citizenid
    
    if not playerResearch[citizenId] then
        playerResearch[citizenId] = {
            points = 0,
            upgrades = {}
        }
    end
    
    TriggerClientEvent('QBCore:Notify', src, 'Research Points: ' .. playerResearch[citizenId].points, 'primary')
    
    -- Show upgrades
    for name, level in pairs(playerResearch[citizenId].upgrades) do
        TriggerClientEvent('QBCore:Notify', src, name .. ': Level ' .. level, 'primary')
    end
end, false)

-- Command to check achievements
RegisterCommand('checkachievements', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenId = Player.PlayerData.citizenid
    local achievements = GetPlayerAchievements(citizenId)
    
    local count = 0
    for id, _ in pairs(achievements) do
        count = count + 1
    end
    
    TriggerClientEvent('QBCore:Notify', src, 'You have ' .. count .. ' achievements', 'primary')
    
    -- Show each achievement
    for id, timestamp in pairs(achievements) do
        -- Find achievement data
        for _, achievement in ipairs(Config.Achievements) do
            if achievement.id == id then
                TriggerClientEvent('QBCore:Notify', src, achievement.name .. ': ' .. achievement.description, 'primary')
                break
            end
        end
    end
end, false)

-- Command to enter competition
RegisterCommand('entercompetition', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    if not currentCompetition.active then
        TriggerClientEvent('QBCore:Notify', src, 'There is no active competition right now.', 'error')
        return
    end
    
    -- Check if player already entered
    for _, entry in ipairs(currentCompetition.entries) do
        if entry.citizenid == Player.PlayerData.citizenid then
            TriggerClientEvent('QBCore:Notify', src, 'You have already entered this competition.', 'error')
            return
        end
    end
    
    -- Check if player has entry fee
    if Player.Functions.GetMoney('cash') < Config.Competitions.entryFee then
        TriggerClientEvent('QBCore:Notify', src, 'You need $' .. Config.Competitions.entryFee .. ' to enter the competition.', 'error')
        return
    end
    
    -- Show menu to select weed to enter
    TriggerClientEvent('kingz-weed:client:showCompetitionMenu', src)
end, false)

-- Command to cross-breed seeds
RegisterCommand('crossbreed', function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local strain1 = args[1]
    local strain2 = args[2]
    
    if not strain1 or not strain2 then
        TriggerClientEvent('QBCore:Notify', src, 'Usage: /crossbreed [strain1] [strain2]', 'error')
        return
    end
    
    TriggerEvent('kingz-weed:server:crossBreed', strain1, strain2)
end, false)

-- Command to show available strains for breeding
RegisterCommand('breedingguide', function(source)
    local src = source
    
    TriggerClientEvent('QBCore:Notify', src, 'Available Hybrid Combinations:', 'primary')
    
    for hybridName, hybrid in pairs(Config.HybridStrains) do
        local parent1 = hybrid.parents[1]
        local parent2 = hybrid.parents[2]
        TriggerClientEvent('QBCore:Notify', src, parent1 .. ' + ' .. parent2 .. ' = ' .. hybridName:gsub("_seed", ""), 'primary')
    end
end, false)

-- Command to buy a business license
RegisterCommand('buybusinesslicense', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player has enough money
    if Player.Functions.GetMoney('bank') >= Config.Business.licenseCost then
        -- Remove money
        Player.Functions.RemoveMoney('bank', Config.Business.licenseCost, 'weed-business-license')
        
        -- Add license to player metadata
        local metadata = Player.PlayerData.metadata
        if not metadata.licenses then metadata.licenses = {} end
        metadata.licenses.weedbusiness = true
        Player.Functions.SetMetadata('licenses', metadata.licenses)
        
        TriggerClientEvent('QBCore:Notify', src, 'You purchased a weed business license for $' .. Config.Business.licenseCost, 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'You need $' .. Config.Business.licenseCost .. ' in your bank to buy a business license', 'error')
    end
end, false)

-- Command to check if player has a business license
RegisterCommand('checkbusinesslicense', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local hasLicense = Player.PlayerData.metadata.licenses and Player.PlayerData.metadata.licenses.weedbusiness or false
    
    if hasLicense then
        TriggerClientEvent('QBCore:Notify', src, 'You have a valid weed business license', 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'You do not have a weed business license', 'error')
    end
end, false)

-- Command to buy a business
RegisterCommand('buybusiness', function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local businessId = tonumber(args[1])
    
    if not businessId or not Config.Business.locations[businessId] then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid business ID', 'error')
        return
    end
    
    local business = Config.Business.locations[businessId]
    
    -- Check if player has a business license
    local hasLicense = Player.PlayerData.metadata.licenses and Player.PlayerData.metadata.licenses.weedbusiness or false
    
    if not hasLicense then
        TriggerClientEvent('QBCore:Notify', src, 'You need a business license first. Use /buybusinesslicense', 'error')
        return
    end
    
    -- Check if business is already owned
    if businessData[businessId] and businessData[businessId].owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, 'This business is already owned by someone else', 'error')
        return
    end
    
    -- Check if player has enough money
    if Player.Functions.GetMoney('bank') >= business.price then
        -- Remove money
        Player.Functions.RemoveMoney('bank', business.price, 'weed-business-purchase')
        
        -- Set up business data
        businessData[businessId] = {
            id = businessId,
            name = business.name,
            owner = Player.PlayerData.citizenid,
            employees = {},
            inventory = {},
            dailyExpenses = business.dailyExpenses,
            customerFrequency = business.customerFrequency,
            inventoryLimit = business.inventoryLimit,
            totalProfit = 0,
            lastProfit = 0,
            upgrades = {}
        }
        
        TriggerClientEvent('QBCore:Notify', src, 'You purchased ' .. business.name .. ' for $' .. business.price, 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'You need $' .. business.price .. ' in your bank to buy this business', 'error')
    end
end, false)

-- Command to add inventory to business
RegisterCommand('addbusinessinventory', function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local businessId = tonumber(args[1])
    local itemName = args[2]
    local amount = tonumber(args[3]) or 1
    
    if not businessId or not itemName or not amount then
        TriggerClientEvent('QBCore:Notify', src, 'Usage: /addbusinessinventory [businessId] [itemName] [amount]', 'error')
        return
    end
    
    -- Check if business exists and player owns it
    if not businessData[businessId] or businessData[businessId].owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t own this business', 'error')
        return
    end
    
    -- Check if player has the item
    local item = Player.Functions.GetItemByName(itemName)
    if not item or item.amount < amount then
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t have enough ' .. itemName, 'error')
        return
    end
    
    -- Check inventory limit
    local currentInventorySize = 0
    for _, invItem in ipairs(businessData[businessId].inventory) do
        currentInventorySize = currentInventorySize + invItem.amount
    end
    
    if currentInventorySize + amount > businessData[businessId].inventoryLimit then
        TriggerClientEvent('QBCore:Notify', src, 'Business inventory is full', 'error')
        return
    end
    
    -- Get item info
    local info = item.info or {}
    local quality = info.quality or "Standard"
    local value = info.value or 1.0
    
    -- Calculate cost and price
    local itemData = QBCore.Shared.Items[itemName]
    local baseCost = 0
    local basePrice = 0
    
    -- Find dealer price for this item
    for _, dealer in ipairs(Config.Dealers) do
        if dealer.prices[itemName] then
            baseCost = dealer.prices[itemName].min
            basePrice = dealer.prices[itemName].max
            break
        end
    end
    
    -- Adjust based on quality
    local cost = math.floor(baseCost * value)
    local price = math.floor(basePrice * value * 1.5) -- 50% markup
    
    -- Remove item from player
    Player.Functions.RemoveItem(itemName, amount)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'remove', amount)
    
    -- Add to business inventory
    local found = false
    for _, invItem in ipairs(businessData[businessId].inventory) do
        if invItem.name == itemName and invItem.quality == quality then
            invItem.amount = invItem.amount + amount
            found = true
            break
        end
    end
    
    if not found then
        table.insert(businessData[businessId].inventory, {
            name = itemName,
            label = itemData.label,
            amount = amount,
            quality = quality,
            cost = cost,
            price = price
        })
    end
    
    TriggerClientEvent('QBCore:Notify', src, 'Added ' .. amount .. 'x ' .. itemData.label .. ' to business inventory', 'success')
end, false)

-- Command to check business inventory
RegisterCommand('checkbusiness', function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local businessId = tonumber(args[1])
    
    if not businessId then
        TriggerClientEvent('QBCore:Notify', src, 'Usage: /checkbusiness [businessId]', 'error')
        return
    end
    
    -- Check if business exists and player owns it
    if not businessData[businessId] or businessData[businessId].owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t own this business', 'error')
        return
    end
    
    local business = businessData[businessId]
    
    TriggerClientEvent('QBCore:Notify', src, business.name .. ' - Business Status', 'primary')
    TriggerClientEvent('QBCore:Notify', src, 'Last Hour Profit: $' .. business.lastProfit, 'primary')
    TriggerClientEvent('QBCore:Notify', src, 'Total Profit: $' .. business.totalProfit, 'primary')
    TriggerClientEvent('QBCore:Notify', src, 'Daily Expenses: $' .. business.dailyExpenses, 'primary')
    TriggerClientEvent('QBCore:Notify', src, 'Customers per Hour: ~' .. business.customerFrequency, 'primary')
    TriggerClientEvent('QBCore:Notify', src, 'Inventory: ' .. #business.inventory .. ' products', 'primary')
    
    -- Show inventory details
    for _, item in ipairs(business.inventory) do
        TriggerClientEvent('QBCore:Notify', src, item.label .. ': ' .. item.amount .. 'x ($' .. item.price .. ' each)', 'primary')
    end
end, false)

-- Command to upgrade business
RegisterCommand('upgradebusiness', function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local businessId = tonumber(args[1])
    local upgradeId = tonumber(args[2])
    
    if not businessId or not upgradeId then
        TriggerClientEvent('QBCore:Notify', src, 'Usage: /upgradebusiness [businessId] [upgradeId]', 'error')
        return
    end
    
    -- Check if business exists and player owns it
    if not businessData[businessId] or businessData[businessId].owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t own this business', 'error')
        return
    end
    
    -- Check if upgrade exists
    if not Config.Business.upgrades[upgradeId] then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid upgrade ID', 'error')
        return
    end
    
    local upgrade = Config.Business.upgrades[upgradeId]
    
    -- Check if player already has this upgrade
    if businessData[businessId].upgrades[upgrade.name] then
        TriggerClientEvent('QBCore:Notify', src, 'You already have this upgrade', 'error')
        return
    end
    
    -- Check if player has enough money
    if Player.Functions.GetMoney('bank') >= upgrade.price then
        -- Remove money
        Player.Functions.RemoveMoney('bank', upgrade.price, 'weed-business-upgrade')
        
        -- Add upgrade
        businessData[businessId].upgrades[upgrade.name] = true
        
        -- Apply upgrade effects
        if upgrade.securityBonus then
            businessData[businessId].securityLevel = (businessData[businessId].securityLevel or 0) + upgrade.securityBonus
        end
        
        if upgrade.customerBonus then
            businessData[businessId].customerFrequency = businessData[businessId].customerFrequency + upgrade.customerBonus
        end
        
        if upgrade.efficiencyBonus then
            businessData[businessId].dailyExpenses = businessData[businessId].dailyExpenses * (1 - upgrade.efficiencyBonus)
        end
        
        if upgrade.inventoryBonus then
            businessData[businessId].inventoryLimit = businessData[businessId].inventoryLimit + upgrade.inventoryBonus
        end
        
        TriggerClientEvent('QBCore:Notify', src, 'You purchased the ' .. upgrade.name .. ' upgrade for $' .. upgrade.price, 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'You need $' .. upgrade.price .. ' in your bank to buy this upgrade', 'error')
    end
end, false)

-- Command to show available business upgrades
RegisterCommand('businessupgrades', function(source)
    local src = source
    
    TriggerClientEvent('QBCore:Notify', src, 'Available Business Upgrades:', 'primary')
    
    for id, upgrade in ipairs(Config.Business.upgrades) do
        TriggerClientEvent('QBCore:Notify', src, id .. '. ' .. upgrade.name .. ' - $' .. upgrade.price, 'primary')
    end
end, false)

-- Command to purchase research upgrade
RegisterCommand('buyresearch', function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local upgradeId = tonumber(args[1])
    local level = tonumber(args[2]) or 1
    
    if not upgradeId then
        TriggerClientEvent('QBCore:Notify', src, 'Usage: /buyresearch [upgradeId] [level]', 'error')
        return
    end
    
    -- Check if upgrade exists
    if not Config.Research.upgrades[upgradeId] then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid upgrade ID', 'error')
        return
    end
    
    local upgrade = Config.Research.upgrades[upgradeId]
    
    -- Trigger purchase event
    TriggerEvent('kingz-weed:server:purchaseResearch', upgrade.name, level)
end, false)

-- Command to show available research upgrades
RegisterCommand('researchupgrades', function(source)
    local src = source
    
    TriggerClientEvent('QBCore:Notify', src, 'Available Research Upgrades:', 'primary')
    
    for id, upgrade in ipairs(Config.Research.upgrades) do
        TriggerClientEvent('QBCore:Notify', src, id .. '. ' .. upgrade.name .. ' (Levels: ' .. upgrade.levels .. ')', 'primary')
        
        for level = 1, upgrade.levels do
            TriggerClientEvent('QBCore:Notify', src, '   Level ' .. level .. ': ' .. upgrade.pointsRequired[level] .. ' points', 'primary')
        end
    end
end, false)

-- Command to give research points (admin only)
RegisterCommand('giveresearchpoints', function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player is admin
    if not Player.PlayerData.admin then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to use this command', 'error')
        return
    end
    
    local targetId = tonumber(args[1])
    local points = tonumber(args[2]) or 100
    
    if not targetId then
        TriggerClientEvent('QBCore:Notify', src, 'Usage: /giveresearchpoints [playerId] [points]', 'error')
        return
    end
    
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    
    if not TargetPlayer then
        TriggerClientEvent('QBCore:Notify', src, 'Player not found', 'error')
        return
    end
    
    AddResearchPoints(TargetPlayer.PlayerData.citizenid, points)
    
    TriggerClientEvent('QBCore:Notify', src, 'Gave ' .. points .. ' research points to ' .. TargetPlayer.PlayerData.charinfo.firstname, 'success')
    TriggerClientEvent('QBCore:Notify', targetId, 'You received ' .. points .. ' research points', 'success')
end, false)

-- Command to give reputation points (admin only)
RegisterCommand('givereputation', function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player is admin
    if not Player.PlayerData.admin then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to use this command', 'error')
        return
    end
    
    local targetId = tonumber(args[1])
    local points = tonumber(args[2]) or 100
    
    if not targetId then
        TriggerClientEvent('QBCore:Notify', src, 'Usage: /givereputation [playerId] [points]', 'error')
        return
    end
    
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    
    if not TargetPlayer then
        TriggerClientEvent('QBCore:Notify', src, 'Player not found', 'error')
        return
    end
    
    local citizenId = TargetPlayer.PlayerData.citizenid
    playerReputations[citizenId] = (playerReputations[citizenId] or 0) + points
    
    TriggerClientEvent('QBCore:Notify', src, 'Gave ' .. points .. ' reputation points to ' .. TargetPlayer.PlayerData.charinfo.firstname, 'success')
    TriggerClientEvent('QBCore:Notify', targetId, 'You received ' .. points .. ' reputation points', 'success')
end, false)

-- Command to start a competition (admin only)
RegisterCommand('startcompetition', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player is admin
    if not Player.PlayerData.admin then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to use this command', 'error')
        return
    end
    
    if currentCompetition.active then
        TriggerClientEvent('QBCore:Notify', src, 'A competition is already active', 'error')
        return
    end
    
    StartNewCompetition()
    TriggerClientEvent('QBCore:Notify', src, 'Started a new weed competition', 'success')
end, false)

-- Command to end current competition (admin only)
RegisterCommand('endcompetition', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player is admin
    if not Player.PlayerData.admin then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to use this command', 'error')
        return
    end
    
    if not currentCompetition.active then
        TriggerClientEvent('QBCore:Notify', src, 'There is no active competition', 'error')
        return
    end
    
    EndCompetition()
    TriggerClientEvent('QBCore:Notify', src, 'Ended the current weed competition', 'success')
end, false)

-- Command to check pesticide
RegisterCommand('checkpesticide', function(source)
    local src = source
    
    if QBCore.Shared.Items['pesticide'] then
        print("Pesticide item exists in shared items")
        print("Name: " .. QBCore.Shared.Items['pesticide'].name)
        print("Label: " .. QBCore.Shared.Items['pesticide'].label)
        TriggerClientEvent('QBCore:Notify', src, 'Pesticide item exists in shared items', 'success')
    else
        print("Pesticide item does NOT exist in shared items")
        TriggerClientEvent('QBCore:Notify', src, 'Pesticide item does NOT exist in shared items', 'error')
    end
end, false)