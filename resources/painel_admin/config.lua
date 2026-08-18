Config = {};

Config.Command = "admin";

Config.OpenKey = "p";

Config.AdminGroups = {
	"Admin",
	"Console",
};

Config.Database = "painel_admin.db";


CreateThread = function(func)
    return setTimer(func, 0, 1)
end