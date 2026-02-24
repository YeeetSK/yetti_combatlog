if Config.Framework ~= "qbox" then return end

function GetCharName(src)
    local Player = exports.qbx_core:GetPlayer(src)
    local charinfo = Player.PlayerData.charinfo
    local name = charinfo.firstname .. ' ' .. charinfo.lastname

    return name
end

function GetPlyIdentifier(src)
    local Player = exports.qbx_core:GetPlayer(src)
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
    local players = exports.qbx_core:GetPlayersData()

    if players then
        local playerData = {}
        for k, data in pairs(players) do
            local src = tonumber(data.source)
            if not src then return end
            playerData[src] = {
                name = GetCharName(src),
                identifier = data.citizenid,
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