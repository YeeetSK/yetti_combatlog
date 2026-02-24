lib.locale()

local players = {}

RegisterNetEvent("yetti_combatlog:client:dropped", function(data)
    lib.requestModel(data.model)
    if not players[data.identifier] then players[data.identifier] = {} end
    players[data.identifier].entity = CreatePed(0, data.model, data.coords, false, false)

    SetPedFleeAttributes(players[data.identifier].entity, 0, 0)
    SetBlockingOfNonTemporaryEvents(players[data.identifier].entity, true)
    SetEntityInvincible(players[data.identifier].entity, true)
    FreezeEntityPosition(players[data.identifier].entity, true)
    SetEntityAlpha(players[data.identifier].entity, 180)
    SetModelAsNoLongerNeeded(data.model)

    lib.requestAnimDict('dead')
    TaskPlayAnim(players[data.identifier].entity, 'dead', 'dead_a', 5.0, 5.0, -1, 01, 0, 0, 0, 0)
    RemoveAnimDict('dead')

    if Config.Clothing == "illenium" then
        exports['illenium-appearance']:setPedAppearance(players[data.identifier].entity, data.skin)
    end


    players[data.identifier].canRob = false

    if data.canBeRobbed then
        if Config.Robbing.timeBeforePlayerCanRob ~= -1 then
            SetTimeout(Config.Robbing.timeBeforePlayerCanRob, function ()
                players[data.identifier].canRob = true
            end)
        else
            players[data.identifier].canRob = true
        end

        if Config.Robbing.timePlayerCanRobFor ~= -1 then
            SetTimeout(Config.Robbing.timePlayerCanRobFor, function ()
                players[data.identifier].canRob = false
            end)
        end
    end

    local function CanRobDisabled()
        if data.canBeRobbed and players[data.identifier].canRob then
            -- greenzone check
            local inGreenzone = false
            if #Config.GreenZones > 0 then
                for k, val in pairs(Config.GreenZones) do
                    local distance = #(vec3(data.coords.x, data.coords.y, data.coords.z) - val.coords)
                    if distance < val.radius then
                        inGreenzone = true
                    end
                end
                if inGreenzone then return true end
            end

            local inCombatzone = false
            if #Config.Combat.combatZones > 0 then
                for k, val in pairs(Config.Combat.combatZones) do
                    local distance = #(vec3(data.coords.x, data.coords.y, data.coords.z) - val.coords)
                    if distance < val.radius then
                        inCombatzone = true
                    end
                end 
            end
            if inCombatzone then return false end
            return false
        else
            return true
        end
    end

    lib.registerContext({
        id = 'yetti_combatlog_dropped_infosubmenu_' .. data.identifier,
        title = locale("submenu_info_title"),
        options = {
            {
                title = locale("submenu_info_name", data.name),
                icon = 'address-card'
            },
            {
                title = locale("submenu_info_id", data.id),
                icon = 'fingerprint'
            },
            {
                title = locale("submenu_info_license", data.license),
                icon = 'hashtag'
            },
            {
                title = locale("submenu_info_reason", data.reason),
                icon = 'file'
            },
            {
                title = locale("submenu_info_copy"),
                icon = 'copy',
                iconAnimation = 'beat',
                onSelect = function ()
                    lib.setClipboard(locale("copy_information", data.name, data.id, data.license, data.reason))
                end
            },

        }
    })

    local options = {}
    local function MakeOptions()
        options = nil
        options = {}
        options[#options + 1] = {
            title = locale("menu_info_title"),
            description = locale("menu_info_description"),
            menu = 'yetti_combatlog_dropped_infosubmenu_' .. data.identifier,
            icon = 'circle-info'
        }

        if Config.Robbing.enabled then
            options[#options + 1] = {
                title = locale("menu_inv_title"),
                description = locale("menu_inv_description"),
                icon = 'people-robbery',
                disabled = CanRobDisabled(),
                onSelect = function()
                    if lib.progressBar({
                        duration = Config.Robbing.time,
                        label = locale("progressbar_robbing"),
                        useWhileDead = false,
                        canCancel = true,
                        disable = {
                            car = true,
                            move = true
                        },
                        anim = {
                            dict = Config.Robbing.anim.dict,
                            clip = Config.Robbing.anim.clip
                        },
                    }) then
                        if players[data.identifier].canRob then
                            exports.ox_inventory:openInventory('stash', 'yetti_combatlog_stash_' .. data.identifier)
                        end
                    end
                end
            }
        end
    end
    
    exports.ox_target:addLocalEntity(players[data.identifier].entity, {
        {
            label = locale("target"),
            icon = 'fa-solid fa-arrow-right-from-bracket',
            distance = Config.Robbing.robDistance,
            onSelect = function ()
                MakeOptions()
                lib.registerContext({
                    id = 'yetti_combatlog_dropped_' .. data.identifier,
                    title = locale("menu_title"),
                    options = options,
                })
                options = {}
                lib.showContext("yetti_combatlog_dropped_" .. data.identifier)
            end
        }
    })

    SetTimeout(Config.RemovePedTime, function ()
        if players[data.identifier] then
            DeleteEntity(players[data.identifier].entity)
            exports.ox_target:removeLocalEntity(players[data.identifier].entity)
            players[data.identifier] = nil
        end
    end)
end)

RegisterNetEvent("yetti_combatlog:client:joinedBack", function (identifier)
    if players[identifier] then
        DeleteEntity(players[identifier].entity)
        exports.ox_target:removeLocalEntity(players[identifier].entity)
        players[identifier] = nil
    end
end)

local function removeAllCombatlogs()
    for identifier, data in pairs(players) do
        DeleteEntity(data.entity)
        exports.ox_target:removeLocalEntity(data.entity)
    end
    players = nil
end

AddEventHandler('onResourceStop', function(res)
    if GetCurrentResourceName() ~= res then return end
    removeAllCombatlogs()
end)


-- no usage for combat if you can't rob
if Config.Combat.enabled and Config.Robbing.enabled then
    local combat = false

    local weapon = false
    local damage = false
    local punch = false

    local health = GetEntityHealth(PlayerPedId())
    local weaponTimeout = false
    local damageTimeout = false
    local punchTimeout = false
    Citizen.CreateThread(function ()
        if Config.Combat.punch then
            AddEventHandler('CEventShockingSeenMeleeAction', function()
                if not IsPedInMeleeCombat(PlayerPedId()) then return end
                punch = true
                if punch and not punchTimeout then
                    punchTimeout = true
                    SetTimeout(Config.Combat.timeoutAfterEnabled, function ()
                        punch = false
                        punchTimeout = false
                    end)
                end
            end)
        end

        while true do
            if Config.Combat.holdWeapon then
                if IsPedArmed(PlayerPedId(), 7) then
                    weapon = true
                else
                    if weapon and not weaponTimeout then
                        weaponTimeout = true
                        SetTimeout(Config.Combat.timeoutAfterEnabled, function ()
                            weapon = false
                            weaponTimeout = false
                        end)
                    end
                end
            end

            if Config.Combat.damage then
                if health - GetEntityHealth(PlayerPedId()) ~= 0 then
                    damage = true
                    if damage and damageTimeout then
                        SetTimeout(Config.Combat.timeoutAfterEnabled, function ()
                            damage = false
                            damageTimeout = false
                        end)
                    end
                end
            end

            -- system to reduce amount of events sent to server
            local newCombat
            if weapon or damage or punch then
                newCombat = true
            else
                newCombat = false
            end

            if newCombat ~= combat then
                TriggerServerEvent("yetti_combatlog:server:setCombatStatus", newCombat)
                combat = newCombat
            end

            Wait(2000)
        end
    end)
end
