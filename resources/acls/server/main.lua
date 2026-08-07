_ACL = {
    Path = 'acl.xml',
    Root = false,
    Dirty = false,
    SaveTimer = nil,
    Acls = { },
    Groups = { },
}


local function resolveAcl( theAcl )
    if type( theAcl ) ~= 'table' or theAcl.__type ~= 'acl' or type( theAcl.name ) ~= 'string' then
        return false
    end

    return _ACL.Acls[theAcl.name] or false
end


local function resolveAclGroup( theGroup )
    if type( theGroup ) ~= 'table' or theGroup.__type ~= 'aclgroup' or type( theGroup.name ) ~= 'string' then
        return false
    end

    return _ACL.Groups[theGroup.name] or false
end


local function resolveObjectName( theObject )
    if type( theObject ) == 'string' then
        return theObject
    end

    if type( theObject ) == 'resource' then
        return 'resource.' .. getResourceName( theObject )
    end

    if isElement( theObject ) and getElementType( theObject ) == 'player' then
        local accountsResource = getResourceFromName( 'accounts' )
        if not accountsResource or getResourceState( accountsResource ) ~= 'running' then
            return false
        end

        local acc = exports['accounts']
        local account = acc:getPlayerAccount( theObject )
        local name = account and acc:getAccountName( account )

        if type( name ) ~= 'string' then
            return false
        end

        return 'user.' .. name
    end

    return false
end


function _ACL.MarkDirty( )
    _ACL.Dirty = true

    if not isTimer( _ACL.SaveTimer ) then
        _ACL.SaveTimer = setTimer( _ACL.Flush, 10000, 1 )
    end
end


function _ACL.Flush( )
    if isTimer( _ACL.SaveTimer ) then
        killTimer( _ACL.SaveTimer )
    end
    _ACL.SaveTimer = nil

    if not _ACL.Dirty then
        return true
    end

    local saved = xmlSaveFile( _ACL.Root )
    if saved then
        _ACL.Dirty = false
    end

    return saved
end


function _ACL.LoadFromDisk( )
    if _ACL.Root then
        xmlUnloadFile( _ACL.Root )
        _ACL.Root = false
    end

    _ACL.Acls = { }
    _ACL.Groups = { }

    _ACL.Root = xmlLoadFile( _ACL.Path )
    if not _ACL.Root then
        _ACL.Root = xmlCreateFile( _ACL.Path, 'acl' )
    end

    if not _ACL.Root then
        return false
    end

    for _, node in ipairs( xmlNodeGetChildren( _ACL.Root ) ) do
        if xmlNodeGetName( node ) == 'acl' then
            local name = xmlNodeGetAttribute( node, 'name' )

            if type( name ) == 'string' then
                local acl = { __type = 'acl', name = name, node = node, rights = { } }

                for _, rightNode in ipairs( xmlNodeGetChildren( node ) ) do
                    if xmlNodeGetName( rightNode ) == 'right' then
                        local rightName = xmlNodeGetAttribute( rightNode, 'name' )
                        local access = xmlNodeGetAttribute( rightNode, 'access' )

                        if type( rightName ) == 'string' then
                            acl.rights[rightName] = { access = access == 'true', node = rightNode }
                        end
                    end
                end

                _ACL.Acls[name] = acl
            end
        end
    end

    for _, node in ipairs( xmlNodeGetChildren( _ACL.Root ) ) do
        if xmlNodeGetName( node ) == 'group' then
            local name = xmlNodeGetAttribute( node, 'name' )

            if type( name ) == 'string' then
                local group = { __type = 'aclgroup', name = name, node = node, acls = { }, objects = { } }

                for _, child in ipairs( xmlNodeGetChildren( node ) ) do
                    local childTag = xmlNodeGetName( child )
                    local childName = xmlNodeGetAttribute( child, 'name' )

                    if childTag == 'acl' and type( childName ) == 'string' and _ACL.Acls[childName] then
                        group.acls[childName] = child
                    elseif childTag == 'object' and type( childName ) == 'string' then
                        group.objects[childName] = child
                    end
                end

                _ACL.Groups[name] = group
            end
        end
    end

    return true
end


function aclCreate( aclName )
    if type( aclName ) ~= 'string' or aclName == '' then
        return false
    end

    if _ACL.Acls[aclName] then
        return false
    end

    local node = xmlCreateChild( _ACL.Root, 'acl' )
    xmlNodeSetAttribute( node, 'name', aclName )

    local acl = { __type = 'acl', name = aclName, node = node, rights = { } }
    _ACL.Acls[aclName] = acl

    _ACL.MarkDirty( )
    return acl
end


function aclDestroy( theAcl )
    local acl = resolveAcl( theAcl )
    if not acl then
        return false
    end

    for _, group in pairs( _ACL.Groups ) do
        local reference = group.acls[acl.name]
        if reference then
            xmlDestroyNode( reference )
            group.acls[acl.name] = nil
        end
    end

    xmlDestroyNode( acl.node )
    _ACL.Acls[acl.name] = nil

    _ACL.MarkDirty( )
    return true
end


function aclGet( aclName )
    return _ACL.Acls[aclName] or false
end


function aclGetName( theAcl )
    local acl = resolveAcl( theAcl )
    if not acl then
        return false
    end

    return acl.name
end


function aclList( )
    local list = { }
    for _, acl in pairs( _ACL.Acls ) do
        table.insert( list, acl )
    end
    return list
end


function aclGetRight( theAcl, rightName )
    local acl = resolveAcl( theAcl )
    if not acl then
        return nil
    end

    local right = acl.rights[rightName]
    if not right then
        return nil
    end

    return right.access
end


function aclSetRight( theAcl, rightName, hasAccess )
    local acl = resolveAcl( theAcl )
    if not acl then
        return false
    end

    if type( rightName ) ~= 'string' or rightName == '' then
        return false
    end

    if type( hasAccess ) ~= 'boolean' then
        return false
    end

    local right = acl.rights[rightName]
    if right then
        right.access = hasAccess
        xmlNodeSetAttribute( right.node, 'access', tostring( hasAccess ) )
    else
        local node = xmlCreateChild( acl.node, 'right' )
        xmlNodeSetAttribute( node, 'name', rightName )
        xmlNodeSetAttribute( node, 'access', tostring( hasAccess ) )
        acl.rights[rightName] = { access = hasAccess, node = node }
    end

    _ACL.MarkDirty( )
    return true
end


function aclRemoveRight( theAcl, rightName )
    local acl = resolveAcl( theAcl )
    if not acl then
        return false
    end

    local right = acl.rights[rightName]
    if not right then
        return false
    end

    xmlDestroyNode( right.node )
    acl.rights[rightName] = nil

    _ACL.MarkDirty( )
    return true
end


function aclListRights( theAcl, allowedType )
    local acl = resolveAcl( theAcl )
    if not acl then
        return false
    end

    local validTypes = { general = true, ['function'] = true, resource = true, command = true }
    if not validTypes[allowedType] then
        return false
    end

    local prefix = allowedType .. '.'
    local rights = { }

    for rightName in pairs( acl.rights ) do
        if rightName:sub( 1, #prefix ) == prefix then
            table.insert( rights, rightName )
        end
    end

    return rights
end


function aclCreateGroup( groupName )
    if type( groupName ) ~= 'string' or groupName == '' then
        return false
    end

    if _ACL.Groups[groupName] then
        return false
    end

    local node = xmlCreateChild( _ACL.Root, 'group' )
    xmlNodeSetAttribute( node, 'name', groupName )

    local group = { __type = 'aclgroup', name = groupName, node = node, acls = { }, objects = { } }
    _ACL.Groups[groupName] = group

    _ACL.MarkDirty( )
    return group
end


function aclDestroyGroup( theGroup )
    local group = resolveAclGroup( theGroup )
    if not group then
        return false
    end

    xmlDestroyNode( group.node )
    _ACL.Groups[group.name] = nil

    _ACL.MarkDirty( )
    return true
end


function aclGetGroup( groupName )
    return _ACL.Groups[groupName] or false
end


function aclGroupGetName( theGroup )
    local group = resolveAclGroup( theGroup )
    if not group then
        return false
    end

    return group.name
end


function aclGroupList( )
    local list = { }
    for _, group in pairs( _ACL.Groups ) do
        table.insert( list, group )
    end
    return list
end


function aclGroupAddACL( theGroup, theAcl )
    local group = resolveAclGroup( theGroup )
    local acl = resolveAcl( theAcl )
    if not group or not acl then
        return false
    end

    if group.acls[acl.name] then
        return false
    end

    local node = xmlCreateChild( group.node, 'acl' )
    xmlNodeSetAttribute( node, 'name', acl.name )
    group.acls[acl.name] = node

    _ACL.MarkDirty( )
    return true
end


function aclGroupRemoveACL( theGroup, theAcl )
    local group = resolveAclGroup( theGroup )
    local acl = resolveAcl( theAcl )
    if not group or not acl then
        return false
    end

    local node = group.acls[acl.name]
    if not node then
        return false
    end

    xmlDestroyNode( node )
    group.acls[acl.name] = nil

    _ACL.MarkDirty( )
    return true
end


function aclGroupListACL( theGroup )
    local group = resolveAclGroup( theGroup )
    if not group then
        return false
    end

    local list = { }
    for aclName in pairs( group.acls ) do
        local acl = _ACL.Acls[aclName]
        if acl then
            table.insert( list, acl )
        end
    end
    return list
end


function aclGroupAddObject( theGroup, theObjectName )
    local group = resolveAclGroup( theGroup )
    if not group then
        return false
    end

    if type( theObjectName ) ~= 'string' or theObjectName == '' then
        return false
    end

    if group.objects[theObjectName] then
        return false
    end

    local node = xmlCreateChild( group.node, 'object' )
    xmlNodeSetAttribute( node, 'name', theObjectName )
    group.objects[theObjectName] = node

    _ACL.MarkDirty( )
    return true
end


function aclGroupRemoveObject( theGroup, theObjectName )
    local group = resolveAclGroup( theGroup )
    if not group then
        return false
    end

    local node = group.objects[theObjectName]
    if not node then
        return false
    end

    xmlDestroyNode( node )
    group.objects[theObjectName] = nil

    _ACL.MarkDirty( )
    return true
end


function aclGroupListObjects( theGroup )
    local group = resolveAclGroup( theGroup )
    if not group then
        return false
    end

    local list = { }
    for objectName in pairs( group.objects ) do
        table.insert( list, objectName )
    end
    return list
end


local function groupContainsObject( group, objectName )
    if group.objects[objectName] then
        return true
    end

    local prefix = objectName:match( '^([^%.]+)%.' )
    if prefix and group.objects[prefix .. '.*'] then
        return true
    end

    return false
end


function aclObjectGetGroups( object )
    if type( object ) ~= 'string' then
        return false
    end

    local list = { }
    for _, group in pairs( _ACL.Groups ) do
        if groupContainsObject( group, object ) then
            table.insert( list, group )
        end
    end
    return list
end


function isObjectInACLGroup( theObjectName, theGroup )
    local group = resolveAclGroup( theGroup )
    if not group or type( theObjectName ) ~= 'string' then
        return false
    end

    return groupContainsObject( group, theObjectName )
end


function hasObjectPermissionTo( theObject, theAction, defaultPermission )
    if defaultPermission == nil then
        defaultPermission = false
    end

    local objectName = resolveObjectName( theObject )
    if not objectName or type( theAction ) ~= 'string' then
        return nil
    end

    local resultFound = false
    local result = false

    for _, group in pairs( _ACL.Groups ) do
        if groupContainsObject( group, objectName ) then
            for aclName in pairs( group.acls ) do
                local acl = _ACL.Acls[aclName]
                local right = acl and acl.rights[theAction]

                if right then
                    resultFound = true
                    if right.access then
                        return true
                    end
                    result = false
                end
            end
        end
    end

    if resultFound then
        return result
    end

    return defaultPermission
end


function aclSave( )
    return _ACL.Flush( )
end


function aclReload( )
    return _ACL.LoadFromDisk( )
end


_ACL.LoadFromDisk( )


addEventHandler( 'onResourceStop', resourceRoot, function( )
    _ACL.Flush( )
end )