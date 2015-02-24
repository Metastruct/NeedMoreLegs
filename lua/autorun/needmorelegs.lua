----------------------------------------------------------------------------------

NML = NML or {}

----------------------------------------------------------------------------------

AddCSLuaFile()

AddCSLuaFile( "nml/shared/properties.lua" )
AddCSLuaFile( "nml/shared/lib_mech.lua" )
AddCSLuaFile( "nml/shared/lib_helper.lua" )
AddCSLuaFile( "nml/client/lib_holo.lua" )
AddCSLuaFile( "nml/client/lib_gait.lua" )

include( "nml/shared/properties.lua" )
include( "nml/shared/lib_mech.lua" )
include( "nml/shared/lib_helper.lua" )

----------------------------------------------------------------------------------

if CLIENT then
    include( "nml/client/lib_holo.lua" )
    include( "nml/client/lib_gait.lua" )
end

for _, path in pairs( file.Find( "nml/shared/types/*.lua", "LUA" ) ) do
    local path = "nml/shared/types/" .. path

    AddCSLuaFile( path )
    include( path )
end

----------------------------------------------------------------------------------
