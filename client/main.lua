local QBCore = exports['qb-core']:GetCoreObject()
local firstAlarm = false
local smashing = false

-- Functions

local function DrawText3Ds(x, y, z, text)
	SetTextScale(0.35, 0.35)
    RegisterFontFile('space')
    fontId = RegisterFontId('space')
    SetTextFont(fontId)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local function loadParticle()
	if not HasNamedPtfxAssetLoaded("scr_jewelheist") then
		RequestNamedPtfxAsset("scr_jewelheist")
    end
    while not HasNamedPtfxAssetLoaded("scr_jewelheist") do
		Wait(0)
    end
    SetPtfxAssetNextCall("scr_jewelheist")
end

local function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(3)
    end
end

local function validWeapon()
    local ped = PlayerPedId()
    local pedWeapon = GetSelectedPedWeapon(ped)

    for k, v in pairs(Config.WhitelistedWeapons) do
        if pedWeapon == k then
            return true
        end
    end
    return false
end

local function IsWearingHandshoes()
    local armIndex = GetPedDrawableVariation(PlayerPedId(), 3)
    local model = GetEntityModel(PlayerPedId())
    local retval = true
    if model == `mp_m_freemode_01` then
        if Config.MaleNoHandshoes[armIndex] ~= nil and Config.MaleNoHandshoes[armIndex] then
            retval = false
        end
    else
        if Config.FemaleNoHandshoes[armIndex] ~= nil and Config.FemaleNoHandshoes[armIndex] then
            retval = false
        end
    end
    return retval
end

local function smashVitrine(k)
    local animDict = "missheist_jewel"
    local animName = "smash_case"
    local ped = PlayerPedId()
    local plyCoords = GetOffsetFromEntityInWorldCoords(ped, 0, 0.6, 0)
    local pedWeapon = GetSelectedPedWeapon(ped)
    if math.random(1, 100) <= 80 and not IsWearingHandshoes() then
        TriggerServerEvent("evidence:server:CreateFingerDrop", plyCoords)
    elseif math.random(1, 100) <= 5 and IsWearingHandshoes() then
        TriggerServerEvent("evidence:server:CreateFingerDrop", plyCoords)
        QBCore.Functions.Notify("لقد تركت بصمة إصبع على الزجاج", "error")
    end
    smashing = true
    QBCore.Functions.Progressbar("smash_vitrine", "جاري التكسير", Config.WhitelistedWeapons[pedWeapon]["timeOut"], false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        TriggerServerEvent('qb-ammuroberry:server:setVitrineState', "isOpened", true, k)
        TriggerServerEvent('qb-ammuroberry:server:setVitrineState', "isBusy", false, k)
        TriggerServerEvent('qb-ammuroberry:server:vitrineReward')
        TriggerServerEvent('qb-ammuroberry:server:setTimeout')
        TriggerServerEvent('police:server:policeAlert', 'السرقة جارية')
        smashing = false
        TaskPlayAnim(ped, animDict, "exit", 3.0, 3.0, -1, 2, 0, 0, 0, 0)
    end, function() -- Cancel
        TriggerServerEvent('qb-ammuroberry:server:setVitrineState', "isBusy", false, k)
        smashing = false
        TaskPlayAnim(ped, animDict, "exit", 3.0, 3.0, -1, 2, 0, 0, 0, 0)
    end)
    TriggerServerEvent('qb-ammuroberry:server:setVitrineState', "isBusy", true, k)

    CreateThread(function()
        while smashing do
            loadAnimDict(animDict)
            TaskPlayAnim(ped, animDict, animName, 3.0, 3.0, -1, 2, 0, 0, 0, 0 )
            Wait(500)
            TriggerServerEvent("InteractSound_SV:PlayOnSource", "breaking_vitrine_glass", 0.25)
            loadParticle()
            StartParticleFxLoopedAtCoord("scr_jewel_cab_smash", plyCoords.x, plyCoords.y, plyCoords.z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
            Wait(2500)
        end
    end)
end

-- Events

RegisterNetEvent('qb-ammuroberry:client:setVitrineState', function(stateType, state, k)
    Config.Locations[k][stateType] = state
end)

-- Threads

CreateThread(function()
    local Dealer = AddBlipForCoord(Config.AmmurobLocation["coords"]["x"], Config.AmmurobLocation["coords"]["y"], Config.AmmurobLocation["coords"]["z"])
    SetBlipSprite (Dealer, 158)
    SetBlipDisplay(Dealer, 4)
    SetBlipScale  (Dealer, 0.7)
    SetBlipAsShortRange(Dealer, true)
    SetBlipColour(Dealer, 3)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Ammunation")
    EndTextCommandSetBlipName(Dealer)
end)

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        inRange = false
        if LocalPlayer.state.isLoggedIn then
            PlayerData = QBCore.Functions.GetPlayerData()
            for case,_ in pairs(Config.Locations) do
                local dist = #(pos - vector3(Config.Locations[case]["coords"]["x"], Config.Locations[case]["coords"]["y"], Config.Locations[case]["coords"]["z"]))
                local storeDist = #(pos - vector3(Config.AmmurobLocation["coords"]["x"], Config.AmmurobLocation["coords"]["y"], Config.AmmurobLocation["coords"]["z"]))
                if dist < 30 then
                    inRange = true

                    if dist < 0.6 then
                        if not Config.Locations[case]["isBusy"] and not Config.Locations[case]["isOpened"] then
                            DrawText3Ds(Config.Locations[case]["coords"]["x"], Config.Locations[case]["coords"]["y"], Config.Locations[case]["coords"]["z"], '[~g~E~w~] ﺝﺎﺟﺰﻟﺍ ﺮﻴﺴﻜﺗ')
                            if IsControlJustPressed(0, 38) then
                                QBCore.Functions.TriggerCallback('qb-ammuroberry:server:getCops', function(cops)
                                    if cops >= Config.RequiredCops then
                                        if validWeapon() then
                                            smashVitrine(case)
                                        else
                                            QBCore.Functions.Notify('سلاحك ليس قويا بما فيه الكفاية', 'error')
                                        end
                                    else
                                        QBCore.Functions.Notify('يجب تواجد شرطة اكثر من '.. Config.RequiredCops ..'', 'error')
                                    end
                                end)
                            end
                        end
                    end

                    if storeDist < 2 then
                        if not firstAlarm then
                            if validWeapon() then
                                TriggerServerEvent('police:server:policeAlert', 'نشاط مشبوه')
                                firstAlarm = true
                            end
                        end
                    end
                end
            end
        end

        if not inRange then
            Wait(2000)
        end

        Wait(3)
    end
end)
