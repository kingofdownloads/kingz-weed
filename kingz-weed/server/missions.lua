local QBCore = exports['qb-core']:GetCoreObject()
local activeMissions = {}
local missionCooldowns = {}

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
    
    -- Check if player already has an active mission
    if activeMissions[src] then
        TriggerClientEvent('QBCore:Notify', src, 'You already have an active mission', 'error')
        return
    end
    
    -- Select random location
    local location = Config.BuyerMissions.locations[math.random(#Config.BuyerMissions.locations)]
    
    -- Generate unique package ID
    local packageId = "package_" .. math.random(100000, 999999)
    
    -- Store mission data
    activeMissions[src] = {
        packageId = packageId,
        startTime = os.time(),
        endTime = os.time() + Config.BuyerMissions.timeLimit,
        dealerId = dealerId
    }
    
    -- Start mission on client
    TriggerClientEvent('kingz-weed:client:startMission', src, location, packageId)
    
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
    
    -- Set cooldown
    local citizenId = Player.PlayerData.citizenid
    missionCooldowns[citizenId] = os.time() + Config.BuyerMissions.cooldown
    
    -- Clear mission
    activeMissions[src] = nil
    
    TriggerClientEvent('QBCore:Notify', src, 'Mission completed! You earned $' .. cashReward, 'success')
end)

-- Fail a delivery mission
RegisterNetEvent('kingz-weed:server:failMission', function(packageId)
    local src = source
    
    -- Check if mission exists and matches
    if not activeMissions[src] or activeMissions[src].packageId ~= packageId then
        return
    end
    
    -- Set cooldown (shorter for failed mission)
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local citizenId = Player.PlayerData.citizenid
        missionCooldowns[citizenId] = os.time() + (Config.BuyerMissions.cooldown / 2)
    end
    
    -- Clear mission
    activeMissions[src] = nil
    
    TriggerClientEvent('QBCore:Notify', src, 'Mission failed! You ran out of time', 'error')
end)

-- Check if player can start a mission
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

-- Clean up missions when player disconnects
AddEventHandler('playerDropped', function()
    local src = source
    if activeMissions[src] then
        activeMissions[src] = nil
    end
end)
