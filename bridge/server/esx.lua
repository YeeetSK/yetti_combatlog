if Config.Framework ~= "esx" then return end
local ESX = exports['es_extended']:getSharedObject()

function GetCharName(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    return xPlayer.getName()
end

function GetPlyIdentifier(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    return xPlayer.identifier
end

function GetSkinData(identifier)
    local result = MySQL.single.await('SELECT skin FROM users WHERE identifier = ?', {
        identifier
    })
    if result and result.skin then
        local skinData = json.decode(result.skin)
        if skinData then
            return skinData, skinData.model
        end
    end
    return false
end

function GetAllPlayersData()
    local xPlayers = ESX.GetExtendedPlayers()

    if xPlayers then
        local playerData = {}
        for i, xPlayer in ipairs(xPlayers) do
            local src = tonumber(xPlayer.source)
            if not src then return end
            playerData[src] = {
                name = GetCharName(src),
                identifier = GetPlyIdentifier(src),
                license = GetConvar('esx:identifier', 'license') or GetPlayerIdentifierByType(src, 'license')
            }
        end
        return playerData
    else
        if Config.Debug then
            print("No players online, script restarted")
            return
        end
    end
end

function GetPlayerInventory(identifier)
    local result = MySQL.single.await('SELECT inventory FROM users WHERE citizenid = ?', {
        identifier
    })
    return result.inventory
end

function SetPlayerInventory(identifier, inventory)
    MySQL.update.await('UPDATE users SET inventory = ? WHERE identifier = ?', {
        inventory, identifier
    })
end

AddEventHandler('esx:playerLoaded', function(source)
    OnPlayerLoaded(source)
end)
