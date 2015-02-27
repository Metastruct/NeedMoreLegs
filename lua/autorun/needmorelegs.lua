------------------------------------------------------------------------
---- Need More Legs
---- by shadowscion
------------------------------------------------------------------------

if SERVER then AddCSLuaFile() end

NML = NML or {}

------------------------------------------------------------------------

local types = {
    ["sv"] = function( path ) if SERVER then include( path ) end end,
    ["sh"] = function( path ) if SERVER then AddCSLuaFile( path ) end include( path ) end,
    ["cl"] = function( path ) if SERVER then AddCSLuaFile( path ) else include( path ) end end,
}

local function LoadLibFiles()
    local files, folders = file.Find( "nml/libraries/*.lua", "LUA" )
    for _, file in pairs( files ) do
        local type = string.sub( file, 1, 2 )
        if types[type] then types[type]( "nml/libraries/" .. file ) end
    end
end

local function LoadMechFiles()
    local root = "nml/mechtypes/"
    local _, folders = file.Find( root .. "*", "LUA" )

    for _, subfolder in pairs( folders ) do
        local files, _ = file.Find( root .. subfolder .. "/*.lua", "LUA" )
        for _, file in pairs( files ) do
            local type = string.sub( file, 1, 2 )
            if types[type] then types[type]( root ..subfolder .. "/" .. file ) end
        end
    end
end

LoadLibFiles()
LoadLibFiles()
LoadMechFiles()

------------------------------------------------------------------------
