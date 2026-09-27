resource_name    = "freeroam"
resource_version = "1.0.0"
resource_author  = "MTAX; original freeroam by arc_"

resource_info = {
    description = "MTAX - Freeroam",
    repository = "https://github.com/mtaxsa/mtax-resources",
}

ui_page = "web/build/index.html"

shared_files = {
    ":tunnel/shared/main.lua",
    "config.lua",
}

client_files = {
    "client/teleport.lua",
    "client/peers.lua",
    "client/main.lua",
}

server_files = {
    "server/storage.lua",
    "server/options.lua",
    "server/bookmarks.lua",
    "server/vehicles.lua",
    "server/main.lua",
}

files = {
    "web/build/index.html",
    "web/build/**/*",
}

exports = {
    "openFreeroam",
}
