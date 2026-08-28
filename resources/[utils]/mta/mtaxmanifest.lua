resource_name    = "mta"
resource_version = "1.0.0"
resource_author  = "MTAX:SA"

resource_info = {
    description = "MTAX - MTA:SA Compatibility Layer",
    repository = "https://github.com/mtaxsa/mtax-resources",
}

shared_files = {
    "shared/migration.lua",
}

client_files = {
    "client/migration.lua",
    "client/core.lua",
    "client/widgets.lua",
}

server_files = {
    "server/migration.lua",
}
