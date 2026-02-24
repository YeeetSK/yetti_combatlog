if Config.Framework ~= "qb" then return end

local QBCore = exports['qb-core']:GetCoreObject()

function GetCharName(src)
    local Player = QBCore.Functions.GetPlayer(src)
    local charinfo = Player.PlayerData.charinfo
    local name = charinfo.firstname .. ' ' .. charinfo.lastname

    return name
end

function GetPlyIdentifier(src)
    local Player = QBCore.Functions.GetPlayer(src)
    return Player.PlayerData.citizenid
end

function GetSkinData(identifier)
    local result = MySQL.single.await('SELECT skin FROM playerskins WHERE citizenid = ? AND active = ?', {
        identifier, 1
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
    local players = QBCore.Functions.GetQBPlayers()

    if players then
        local playerData = {}
        for src, data in pairs(players) do
            if not src then return end
            playerData[src] = {
                name = GetCharName(src),
                identifier = data.PlayerData.citizenid,
                license = GetPlayerIdentifierByType(src, 'license')
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
    local result = MySQL.single.await('SELECT inventory FROM players WHERE citizenid = ?', {
        identifier
    })
    return result.inventory
end

function SetPlayerInventory(identifier, inventory)
    MySQL.update.await('UPDATE players SET inventory = ? WHERE citizenid = ?', {
        inventory, identifier
    })
end

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    OnPlayerLoaded(source)
end)