resource_name = "debug"
resource_version = "1.0.0"
resource_author = "MTAX"

ui_page = 'web/build/index.html'


shared_files = {
    "shared/tunnel.lua",
}

client_files = {
	"client/client.lua"
}

server_files = {
	"server/server.lua"
}

files = {
	'web/build/index.html',
	'web/build/**/*'
}