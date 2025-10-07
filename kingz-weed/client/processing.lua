local QBCore = exports['qb-core']:GetCoreObject()
local isProcessing = false

-- Processing menu
RegisterCommand('processweed', function()
    QBCore.Functions.TriggerCallback('kingz-weed:server:getPlayerWeed', function(items)
        if #items == 0 then
            QBCore.Functions.Notify('No Items', 'You don\'t have any weed to process', 'error')
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
            QBCore.Functions.Notify('No Weed', 'You don\'t have any weed in your inventory', 'error')
        else
            for _, item in ipairs(items) do
                QBCore.Functions.Notify('Found Weed', 'You have ' .. item.amount .. 'x ' .. item.label, 'success')
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
    -- Check if player has required items
    QBCore.Functions.TriggerCallback('kingz-weed:server:canProcess', function(canProcess, missingItem)
        if canProcess then
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
                
                -- Process the weed
                TriggerServerEvent('kingz-weed:server:processWeed', itemName, processType)
                
                QBCore.Functions.Notify('Success', 'Processing complete', 'success')
            end, function() -- Cancel
                ClearPedTasks(playerPed)
                
                QBCore.Functions.Notify('Canceled', 'Processing canceled', 'error')
            end)
        else
            QBCore.Functions.Notify('Missing Item', missingItem, 'error')
        end
    end, itemName, processType)
end

-- Helper function to reopen the processing menu
function OpenProcessingMenu()
    QBCore.Functions.TriggerCallback('kingz-weed:server:getPlayerWeed', function(items)
        if #items == 0 then
            QBCore.Functions.Notify('No Items', 'You don\'t have any weed to process', 'error')
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
