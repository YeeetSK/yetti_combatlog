Config = {}
-- also enables /testcombatlog command which spawns your ped (robbing not suggested)
Config.Debug = true -- debug prints, red spheres for greenzones

Config.Framework = "auto" -- "auto" or "esx", "qbox", "qb"
Config.Clothing = "illenium" -- "illenium", "custom"
Config.RemovePedTime = 5 * 60 * 1000 -- time before the ped gets deleted

Config.DropReasons = {
    -- taken from https://github.com/Randolio/randol_combatlog/blob/main/sv_config.lua#L2-L10
    ['game crashed'] = 'Head Popped',
    ['timed out'] = 'Head Popped',
    ['exiting'] = 'F8 Quit',
    ['you were kicked for being afk'] = 'Kicked for AFK',
    ['banned'] = 'Banned.',
    ['exploit'] = 'Exploiting',
    ['kicked'] = 'Kicked',
}

-- Sphere zones where players can't be robbed
Config.GreenZones = {
    -- {
    --     coords = vector3(-1589.4160, -1034.5774, 13.0190),
    --     radius = 10
    -- }
}

-- combat system, this tracks if the player is likely in a RP situation, eg. is holding a gun
-- if this is enabled, players can only be robbed if they were in combat 
Config.Combat = {
    enabled = true,
    damage = true, -- take damage = combat on
    holdWeapon = true,
    punch = true,
    timeoutAfterEnabled = 45 * 1000, -- if the system detects one of the above, how long untill you get out of combat
    -- where players are always in combat (can always be robbed if they combatlog here)
    combatZones = {
        -- {
        --     coords = vector3(-1589.4160, -1034.5774, 13.0190),
        --     radius = 10
        -- }
    }
}

-- Take items from dead players
Config.Robbing = {
    enabled = true,
    robDistance = 3, -- how far you can be, otherwise you can't target
    time = 3000, -- progressbar time
    timeBeforePlayerCanRob = 120 * 1000, -- gives player time to join back, set to -1 to be able to rob instantly
    -- after the value above passes, how much time the player gets to rob the person, set to -1 for infinite (until ped deleted)
    timePlayerCanRobFor = 60 * 1000,
    anim = {
        dict = "mini@repair",
        clip = "fixing_a_ped"
    }
}

if Config.Framework == "auto" then
    if GetResourceState('qbx_core') == 'started' then
        Config.Framework = "qbox"
    elseif GetResourceState('qb-core') == 'started' then
        Config.Framework = "qb"
    elseif GetResourceState('es_extended') == 'started' then
        Config.Framework = "esx"
    end
end