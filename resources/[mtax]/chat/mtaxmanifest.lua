resource_name    = "chat"
resource_version = "1.0.0"
resource_author  = "MTAX"

resource_info = {
    description = "MTAX - Chat",
    repository = "https://github.com/mtaxsa/mtax-resources",
}

ui_page = "web/build/index.html"

shared_files = {
    ":tunnel/shared/main.lua",
    "config.lua",
    "shared/text.lua",
}

client_files = {
    "client/labels.lua",
    "client/main.lua",
}

server_files = {
    "server/main.lua",
}

files = {
    "web/build/index.html",
    "web/build/**/*",
}

exports = {
    "outputChatBox",
    "clearChat",
    "isChatEnabled",
    "setChatEnabled",
    "getPlayerChatID",
    "getPlayerFromChatID",
}
