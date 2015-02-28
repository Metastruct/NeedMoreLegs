
NML = NML or {}

if SERVER then
    AddCSLuaFile()

    local function addResourceFiles( dir )
        local _, folders = file.Find( dir .. "/*", "GAME" )
        for _, fdir in ipairs( folders ) do
            if fdir ~= ".svn" then
                addResourceFiles( dir .. "/" .. fdir )
            end
        end

        for _, file in pairs( file.Find( dir .. "/*", "GAME" ) ) do
            resource.AddSingleFile( dir .. "/" .. file )
        end
    end

    addResourceFiles( "materials/nml" )
    addResourceFiles( "models/nml" )
    addResourceFiles( "sound/nml" )
end

local types = {
    ["sv"] = function( path ) if SERVER then include( path ) end end,
    ["sh"] = function( path ) if SERVER then AddCSLuaFile( path ) end include( path ) end,
    ["cl"] = function( path ) if SERVER then AddCSLuaFile( path ) else include( path ) end end,
}

local function loadLuaFiles( dir )
    local _, folders = file.Find( dir .. "/*", "LUA" )
    for _, fdir in ipairs( folders ) do
        loadLuaFiles( dir .. "/" .. fdir )
    end

    for _, file in pairs( file.Find( dir .. "/*.lua", "LUA" ) ) do
        local type = string.sub( file, 1, 2 )
        if types[type] then types[type]( dir .. "/" .. file ) end
    end
end

loadLuaFiles( "nml/misc" )
loadLuaFiles( "nml/lib" )
loadLuaFiles( "nml/mechs" )
