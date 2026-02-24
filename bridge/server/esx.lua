if Config.Framework ~= "esx" then return end
local ESX = exports['es_extended']:getSharedObject()

function Notification(text, type)
    ESX.ShowNotification(text, type)
end