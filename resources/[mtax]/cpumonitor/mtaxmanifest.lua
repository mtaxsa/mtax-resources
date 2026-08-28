resource_name = "cpu monitor"
resource_version = "1.0.0"
resource_author = "MTAX"

ui_page = 'web/build/index.html'


shared_files = {
    ":tunnel/shared/main.lua",
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