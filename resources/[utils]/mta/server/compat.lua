_MTA_COMPAT = _MTA_COMPAT or {}

local internal = nil

local function internalDatabase()
    if internal == nil then
        internal = dbConnect("sqlite", "mta_internal.db") or false
        if not internal then
            _MTA_COMPAT.warnOnce("executeSQLQuery", "could not open mta_internal.db; every call returns false")
        end
    end
    return internal
end

function executeSQLQuery(query, ...)
    if type(query) ~= "string" or query == "" then
        return false
    end

    local connection = internalDatabase()
    if not connection then
        return false
    end

    local handle = dbQuery(connection, query, ...)
    if not handle then
        return false
    end

    local rows = dbPoll(handle, -1)
    return type(rows) == "table" and rows or false
end

function setElementSyncer(element)
    if not isElement(element) then
        return false
    end
    _MTA_COMPAT.warnOnce("setElementSyncer",
        "the syncer is elected by the server and cannot be set from script; the call was ignored")
    return false
end

function getElementSyncer()
    return false
end
