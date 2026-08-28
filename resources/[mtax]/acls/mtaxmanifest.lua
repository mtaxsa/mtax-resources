resource_name = "acls"
resource_version = "1.0.0"
resource_author = "MTAX"

server_files = {
    "server/main.lua",
}

exports = {
    'aclCreate',
    'aclCreateGroup',
    'aclDestroy',
    'aclDestroyGroup',
    'aclGet',
    'aclGetGroup',
    'aclGetName',
    'aclGetRight',
    'aclGroupAddACL',
    'aclGroupAddObject',
    'aclGroupGetName',
    'aclGroupList',
    'aclGroupListACL',
    'aclGroupListObjects',
    'aclGroupRemoveACL',
    'aclGroupRemoveObject',
    'aclObjectGetGroups',
    'aclList',
    'aclListRights',
    'aclReload',
    'aclRemoveRight',
    'aclSave',
    'aclSetRight',
    'hasObjectPermissionTo',
    'isObjectInACLGroup',
    'getAccountName',
    'getPlayerAccount'
}


files = {
    'acl.xml'
}