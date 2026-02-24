fx_version "cerulean"
game "gta5"
lua54 "yes"

author 'yeeet.sk'
description 'Combatlog script with robbing'
repository 'https://github.com/Free-Studios/free-maskzones'
version 'v1.0.0'

files {
  'locales/*.json'
}

shared_scripts {
    "@ox_lib/init.lua",
    "config.lua"
}

client_scripts {
    "client/client.lua"
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "bridge/server/*.lua",
    "server/server.lua"
}