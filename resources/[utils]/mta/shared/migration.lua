---@alias Element userdata
---@alias Account table

local _MTAX = {}

_MTAX.__index = _MTAX

function _MTAX:New()
    local Instance = setmetatable({}, self)
    return Instance
end

function _MTAX:Accounts()
    return exports["accounts"]
end

function _MTAX:Acls()
    return exports["acls"]
end

local Main = _MTAX:New()

--- Accounts

---@param Name string
---@param Password string
---@param AllowCaseVariations? boolean
---@return Account|false
function addAccount(Name, Password, AllowCaseVariations)
    return Main:Accounts():addAccount(Name, Password, AllowCaseVariations)
end

---@param FromAccount Account
---@param ToAccount Account
---@return boolean
function copyAccountData(FromAccount, ToAccount)
    return Main:Accounts():copyAccountData(FromAccount, ToAccount)
end

---@param Name string
---@param Password? string
---@param CaseSensitive? boolean
---@return Account|false
function getAccount(Name, Password, CaseSensitive)
    return Main:Accounts():getAccount(Name, Password, CaseSensitive)
end

---@param Id number
---@return Account|false
function getAccountByID(Id)
    return Main:Accounts():getAccountByID(Id)
end

---@param TheAccount Account
---@param Key string
---@return string|number|boolean|nil
function getAccountData(TheAccount, Key)
    return Main:Accounts():getAccountData(TheAccount, Key)
end

---@param TheAccount Account
---@return number|false
function getAccountID(TheAccount)
    return Main:Accounts():getAccountID(TheAccount)
end

---@param TheAccount Account
---@return string|false
function getAccountIP(TheAccount)
    return Main:Accounts():getAccountIP(TheAccount)
end

---@param TheAccount Account
---@return string|false
function getAccountName(TheAccount)
    return Main:Accounts():getAccountName(TheAccount)
end

---@param TheAccount Account
---@return Element|false
function getAccountPlayer(TheAccount)
    return Main:Accounts():getAccountPlayer(TheAccount)
end

---@return Account[]
function getAccounts()
    return Main:Accounts():getAccounts()
end

---@param TheAccount Account
---@return string|false
function getAccountSerial(TheAccount)
    return Main:Accounts():getAccountSerial(TheAccount)
end

---@param Key string
---@param Value string
---@param CaseSensitive? boolean
---@return Account[]|false
function getAccountsByData(Key, Value, CaseSensitive)
    return Main:Accounts():getAccountsByData(Key, Value, CaseSensitive)
end

---@param Ip string
---@param CaseSensitive? boolean
---@return Account[]|false
function getAccountsByIP(Ip, CaseSensitive)
    return Main:Accounts():getAccountsByIP(Ip, CaseSensitive)
end

---@param Serial string
---@return Account[]|false
function getAccountsBySerial(Serial)
    return Main:Accounts():getAccountsBySerial(Serial)
end

---@param TheAccount Account
---@return table|false
function getAllAccountData(TheAccount)
    return Main:Accounts():getAllAccountData(TheAccount)
end

---@param Player Element
---@return Account|false
function getPlayerAccount(Player)
    return Main:Accounts():getPlayerAccount(Player)
end

---@param Player Element
---@return number|false
function getPlayerMoney(Player)
    return Main:Accounts():getPlayerMoney(Player)
end

---@param Player Element
---@return string|false
function getPlayerSerial(Player)
    return Main:Accounts():getPlayerSerial(Player)
end

---@param Player Element
---@param Amount number
---@return boolean
function givePlayerMoney(Player, Amount)
    return Main:Accounts():givePlayerMoney(Player, Amount)
end

---@param TheAccount Account
---@return boolean
function isGuestAccount(TheAccount)
    return Main:Accounts():isGuestAccount(TheAccount)
end

---@param Player Element
---@param TheAccount Account|string
---@param Password? string
---@return boolean
function logIn(Player, TheAccount, Password)
    return Main:Accounts():logIn(Player, TheAccount, Password)
end

---@param Player Element
---@return boolean
function logOut(Player)
    return Main:Accounts():logOut(Player)
end

---@param TheAccount Account
---@return boolean
function removeAccount(TheAccount)
    return Main:Accounts():removeAccount(TheAccount)
end

---@param TheAccount Account
---@param Key string
---@param Value string|number|boolean|nil
---@return boolean
function setAccountData(TheAccount, Key, Value)
    return Main:Accounts():setAccountData(TheAccount, Key, Value)
end

---@param TheAccount Account
---@param Name string
---@param AllowCaseVariations? boolean
---@return boolean
function setAccountName(TheAccount, Name, AllowCaseVariations)
    return Main:Accounts():setAccountName(TheAccount, Name, AllowCaseVariations)
end

---@param TheAccount Account
---@param Password string
---@return boolean
function setAccountPassword(TheAccount, Password)
    return Main:Accounts():setAccountPassword(TheAccount, Password)
end

---@param Player Element
---@param Amount number
---@return boolean
function setPlayerMoney(Player, Amount)
    return Main:Accounts():setPlayerMoney(Player, Amount)
end

---@param Player Element
---@param Amount number
---@return boolean
function takePlayerMoney(Player, Amount)
    return Main:Accounts():takePlayerMoney(Player, Amount)
end

--- Acls

---@param Name string
---@return userdata|false
function aclCreate(Name)
    return Main:Acls():aclCreate(Name)
end

---@param Name string
---@return userdata|false
function aclCreateGroup(Name)
    return Main:Acls():aclCreateGroup(Name)
end

---@param TheAcl userdata
---@return boolean
function aclDestroy(TheAcl)
    return Main:Acls():aclDestroy(TheAcl)
end

---@param TheGroup userdata
---@return boolean
function aclDestroyGroup(TheGroup)
    return Main:Acls():aclDestroyGroup(TheGroup)
end

---@param Name string
---@return userdata|false
function aclGet(Name)
    return Main:Acls():aclGet(Name)
end

---@param Name string
---@return userdata|false
function aclGetGroup(Name)
    return Main:Acls():aclGetGroup(Name)
end

---@param TheAcl userdata
---@return string|false
function aclGetName(TheAcl)
    return Main:Acls():aclGetName(TheAcl)
end

---@param TheAcl userdata
---@param RightName string
---@return boolean
function aclGetRight(TheAcl, RightName)
    return Main:Acls():aclGetRight(TheAcl, RightName)
end

---@param TheGroup userdata
---@param TheAcl userdata
---@return boolean
function aclGroupAddACL(TheGroup, TheAcl)
    return Main:Acls():aclGroupAddACL(TheGroup, TheAcl)
end

---@param TheGroup userdata
---@param ObjectName string
---@return boolean
function aclGroupAddObject(TheGroup, ObjectName)
    return Main:Acls():aclGroupAddObject(TheGroup, ObjectName)
end

---@param TheGroup userdata
---@return string|false
function aclGroupGetName(TheGroup)
    return Main:Acls():aclGroupGetName(TheGroup)
end

---@return userdata[]
function aclGroupList()
    return Main:Acls():aclGroupList()
end

---@param TheGroup userdata
---@return userdata[]|false
function aclGroupListACL(TheGroup)
    return Main:Acls():aclGroupListACL(TheGroup)
end

---@param TheGroup userdata
---@return string[]|false
function aclGroupListObjects(TheGroup)
    return Main:Acls():aclGroupListObjects(TheGroup)
end

---@param TheGroup userdata
---@param TheAcl userdata
---@return boolean
function aclGroupRemoveACL(TheGroup, TheAcl)
    return Main:Acls():aclGroupRemoveACL(TheGroup, TheAcl)
end

---@param TheGroup userdata
---@param ObjectString string
---@return boolean
function aclGroupRemoveObject(TheGroup, ObjectString)
    return Main:Acls():aclGroupRemoveObject(TheGroup, ObjectString)
end

---@return userdata[]
function aclList()
    return Main:Acls():aclList()
end

---@param TheAcl userdata
---@param AllowedType? string
---@return string[]|false
function aclListRights(TheAcl, AllowedType)
    return Main:Acls():aclListRights(TheAcl, AllowedType)
end

---@param ObjectName string
---@return userdata[]|false
function aclObjectGetGroups(ObjectName)
    return Main:Acls():aclObjectGetGroups(ObjectName)
end

---@return boolean
function aclReload()
    return Main:Acls():aclReload()
end

---@param TheAcl userdata
---@param RightName string
---@return boolean
function aclRemoveRight(TheAcl, RightName)
    return Main:Acls():aclRemoveRight(TheAcl, RightName)
end

---@return boolean
function aclSave()
    return Main:Acls():aclSave()
end

---@param TheAcl userdata
---@param RightName string
---@param HasAccess boolean
---@return boolean
function aclSetRight(TheAcl, RightName, HasAccess)
    return Main:Acls():aclSetRight(TheAcl, RightName, HasAccess)
end

---@param TheObject Element|string
---@param TheAction string
---@param DefaultPermission? boolean
---@return boolean
function hasObjectPermissionTo(TheObject, TheAction, DefaultPermission)
    return Main:Acls():hasObjectPermissionTo(TheObject, TheAction, DefaultPermission)
end

---@param TheObject Element|string
---@param TheGroup string
---@return boolean
function isObjectInACLGroup(TheObject, TheGroup)
    return Main:Acls():isObjectInACLGroup(TheObject, TheGroup)
end
