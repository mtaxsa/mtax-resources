Config = {}

--- Interface

Config.Language = "en-US"

Config.Keys = {
    Panel    = "f1",
    Map      = "f2",
    Jetpack  = "j",
    StopAnim = "lshift",
}

--- World

Config.JetpackMaxHeight = 9001
Config.AircraftMaxHeight = 1600

--- Storage

Config.SettingsFile = "settings.json"
Config.SettingsPermission = "command.frconfig"

Config.Bookmarks = {
    File       = "bookmarks.json",
    Max        = 40,
    NameLength = 28,
}

--- Options
-- Defaults. /frconfig <key> <value> overrides them at runtime and saves to Config.SettingsFile.

Config.Options = {
    alpha         = true,
    anim          = true,
    clothes       = true,
    createvehicle = true,
    jetpack       = true,
    kill          = true,
    lights        = true,
    paintjob      = true,
    repair        = true,
    setskin       = true,
    setstyle      = true,
    walkstyle     = true,
    stats         = true,
    upgrades      = true,
    warp          = true,
    removeHex     = false,

    gamespeed = {
        enabled = true,
        min     = 0.25,
        max     = 3,
    },

    gravity = {
        enabled = true,
        min     = 0,
        max     = 0.1,
    },

    weapons = {
        enabled           = true,
        vehiclesenabled   = true,
        kniferestrictions = true,
        disallowed        = {},
    },

    vehicles = {
        maxperplayer    = 2,
        disallowed      = {},
        disallowed_warp = {},
    },

    gui = {
        antiram      = true,
        disablewarp  = true,
        disableknife = true,
    },
}

--- Vehicles

Config.Vehicles = {
    DestroyAfterExplode = 5000,
    Armed               = { [425] = true, [447] = true, [520] = true, [430] = true, [464] = true, [432] = true },
    NormalGravity       = { [425] = true, [520] = true },
}

--- Teleport

Config.Teleport = {
    Timeout   = 8000,
    KnifeLock = 5000,
}
