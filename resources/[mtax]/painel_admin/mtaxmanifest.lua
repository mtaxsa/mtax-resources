resource_name    = "mtax-admin"
resource_version = "1.0.0"
resource_author  = "Maicon Costa"

resource_info = {
	description = "MTAX - Admin Panel",
	repository = "https://github.com/mtaxsa/mtax-resources",
}

shared_files = {
	"config.lua",
}

server_files = {
	"server/**/*.lua",
}

client_files = {
	"client/**/*.lua",
}

files = {
	"web/build/index.html",
	"web/build/**/*",
}

ui_page = "web/build/index.html"
