local playerCache = {}
local stashSlots = GetConvarInt('inventory:slots', 50)
local stashWeight = GetConvarInt('inventory:weight', 30000)

-- taken from randolios combatlog script, please contact me if you mind
local function getPlayersNearby(coords)
    local players = GetPlayers()
    local list = {}

    for i = 1, #players do
        local ply = tonumber(players[i])
        local ped = GetPlayerPed(ply)
        local pos = GetEntityCoords(ped)
        local dist = #(coords - pos)

        if dist <= 100.0 then
            list[#list+1] = ply
        end
    end

    return list
end

function OnPlayerLoaded(src)
    local identifier = GetPlyIdentifier(src)

    -- this is to delete the ped and inventory if the player joins back in time
    for oldSrc, data in pairs(playerCache) do
        if data.identifier == identifier and data.combatlog then
            TriggerClientEvent("yetti_combatlog:client:joinedBack", -1, identifier)
            playerCache[oldSrc] = nil

            local stashItems = exports.ox_inventory:GetInventoryItems('yetti_combatlog_stash_' .. data.identifier)
            exports.ox_inventory:ClearInventory('yetti_combatlog_stash_' .. data.identifier)
            exports.ox_inventory:ClearInventory(src)

            -- give items based on what the player took
            for k, info in pairs(stashItems) do
                exports.ox_inventory:AddItem(src, info.name, info.count, info.metadata or {}, info.slot)
            end
        end
    end

    playerCache[src] = {
        name = GetCharName(src),
        identifier = identifier,
        license = GetPlayerIdentifierByType(src, 'license'),
        canBeRobbed = false
    }
end

function CombatLog(src, reason, coords)
    if not playerCache[src] then return end
    -- prepare data
    local skin, model = GetSkinData(playerCache[src].identifier)

    if reason then -- taken from randolios combatlog script
        local reason_lower = string.lower(reason)
        for key, value in pairs(Config.DropReasons) do
            if string.find(reason_lower, key) then
                reason = value
                break
            end
        end
    end

    local data = {
        id = src,
        identifier = playerCache[src].identifier,
        skin = skin,
        model = model,
        coords = coords,
        reason = reason,
        name = playerCache[src].name,
        license = playerCache[src].license,
        canBeRobbed = playerCache[src].canBeRobbed,
    }
    if not Config.Combat.enabled then
        data.canBeRobbed = true
        playerCache[src].canBeRobbed = true
    end
    playerCache[src].combatlog = true

    local stashId = 'yetti_combatlog_stash_' .. data.identifier
    if data.canBeRobbed then
        -- register stash and add items
        exports.ox_inventory:RegisterStash(stashId, 'Combatlog - ' .. data.name,
            stashSlots, stashWeight,
            nil, false, vector3(data.coords.x, data.coords.y, data.coords.z)
        )

        exports.ox_inventory:ClearInventory(stashId)
        local items = GetPlayerInventory(data.identifier)
        for k, info in pairs(json.decode(items)) do
            exports.ox_inventory:AddItem(stashId, info.name, info.count, info.metadata or {}, info.slot)
        end
    end

    -- client and removal of cached player
    -- basically almost the same as randolios combatlog since it uses his functionm
    local nearbyPlayers = getPlayersNearby(vector3(data.coords.x, data.coords.y, data.coords.z))
    if #nearbyPlayers > 0 then
        for i = 1,#nearbyPlayers do
            TriggerClientEvent("yetti_combatlog:client:dropped", nearbyPlayers[i], data)
        end
    end

    local stashItems
    if Config.Robbing.timePlayerCanRobFor ~= -1 and data.canBeRobbed then
        SetTimeout(Config.Robbing.timePlayerCanRobFor, function ()
            if playerCache[src] then
                stashItems = exports.ox_inventory:GetInventoryItems(stashId)
                exports.ox_inventory:ClearInventory(stashId)
            end
        end)
    end

    SetTimeout(Config.RemovePedTime, function ()
        if playerCache[src] then
            playerCache[src] = nil

            if data.canBeRobbed then
                if not stashItems then stashItems = exports.ox_inventory:GetInventoryItems(stashId) end
                SetPlayerInventory(data.identifier, json.encode(stashItems))
                stashItems = nil

                -- just incase someone inproperly configures timePlayerCanRobFor
                exports.ox_inventory:ClearInventory(stashId)
            end
        end
    end)
end

local combatStatusCooldown = {}
RegisterNetEvent("yetti_combatlog:server:setCombatStatus", function (status)
    local src = source
    if combatStatusCooldown[src] then DropPlayer(src, 'Combatlog - exploit detected') return end

    combatStatusCooldown[src] = true
    if Config.Debug then
        print('[DEBUG] - setting combat status to', status) 
    end
    playerCache[src].canBeRobbed = status
    SetTimeout(1500, function ()
        combatStatusCooldown[src] = false
    end)
end)

if Config.Debug then
    RegisterCommand('testcombatlog', function (src)
        local playerPed = GetPlayerPed(src)
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)

        CombatLog(src, 'exiting', vector4(coords.x, coords.y, coords.z -0.9, heading))
    end, true)

    RegisterCommand('forceclrob', function (src)
        exports.ox_inventory:forceOpenInventory(src, 'stash', 'yetti_combatlog_stash_JE0VZ3C7')
    end, true)

    RegisterCommand('cloaded', function (src)
        OnPlayerLoaded(src)
    end, true)
end


AddEventHandler('playerDropped', function(reason)
    local src = source
    local playerPed = GetPlayerPed(src)
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)

    CombatLog(src, reason, vector4(coords.x, coords.y, coords.z -0.9, heading))
end)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    lib.versionCheck('YeeetSK/yetti_combatlog')
    if #playerCache == 0 then
        playerCache = GetAllPlayersData() or {}
    end
end)
