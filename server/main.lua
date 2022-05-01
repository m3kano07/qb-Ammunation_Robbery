local QBCore = exports['qb-core']:GetCoreObject()
local timeOut = false

-- Callback

QBCore.Functions.CreateCallback('qb-ammuroberry:server:getCops', function(source, cb)
	local amount = 0
    for k, v in pairs(QBCore.Functions.GetQBPlayers()) do
        if v.PlayerData.job.name == "police" and v.PlayerData.job.onduty then
            amount = amount + 1
        end
    end
    cb(amount)
end)

-- Events

RegisterNetEvent('qb-ammuroberry:server:setVitrineState', function(stateType, state, k)
    Config.Locations[k][stateType] = state
    TriggerClientEvent('qb-ammuroberry:client:setVitrineState', -1, stateType, state, k)
end)

RegisterNetEvent('qb-ammuroberry:server:vitrineReward', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local otherchance = math.random(0, 1)
    local odd = math.random(0, 1)

    if otherchance == odd then
        local item = math.random(1, #Config.VitrineRewards)
        local amount = math.random(Config.VitrineRewards[item]["amount"]["min"], Config.VitrineRewards[item]["amount"]["max"])
        if Player.Functions.AddItem(Config.VitrineRewards[item]["item"], amount) then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.VitrineRewards[item]["item"]], 'add')
        else
            TriggerClientEvent('QBCore:Notify', src, 'لديك الكثير في حقيبتك', 'error')
        end
    else
        local amount = math.random(0, 1)
        if Player.Functions.AddItem("pistol_ammo", amount) then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items["pistol_ammo"], 'add')
        else
            TriggerClientEvent('QBCore:Notify', src, 'لديك الكثير في حقيبتك', 'error')
        end
    end
end)

RegisterNetEvent('qb-ammuroberry:server:setTimeout', function()
    if not timeOut then
        timeOut = true
        TriggerEvent('qb-scoreboard:server:SetActivityBusy', "Ammunation", true)
        Citizen.CreateThread(function()
            Citizen.Wait(Config.Timeout)

            for k, v in pairs(Config.Locations) do
                Config.Locations[k]["isOpened"] = false
                TriggerClientEvent('qb-ammuroberry:client:setVitrineState', -1, 'isOpened', false, k)
                TriggerClientEvent('qb-ammuroberry:client:setAlertState', -1, false)
                TriggerEvent('qb-scoreboard:server:SetActivityBusy', "Ammunation", false)
            end
            timeOut = false
        end)
    end
end)