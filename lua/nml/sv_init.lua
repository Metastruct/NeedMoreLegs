
-- Add Client Libraries and Modules
--AddCSLuaFile( "vgui/cl_spawnmenu.lua" )
AddCSLuaFile( "vgui/sh_contextmenu.lua" )

AddCSLuaFile( "libraries/sh_plshalp.lua" )

AddCSLuaFile( "modules/cl_hologram.lua" )
AddCSLuaFile( "modules/sh_mech.lua" )

-- Load Libraries and Modules
include( "vgui/sh_contextmenu.lua" )

include( "libraries/sh_plshalp.lua" )

include( "modules/sh_mech.lua" )

-- Add and Load Mechtype Files
NML.NavigateFolders( "nml/entities", "lua", "LUA", function( dir, file )
    local type = string.sub( file, 1, 2 )
    if type == "sv" or type == "sh" then include( dir .. "/" .. file ) end
    if type == "cl" or type == "sh" then AddCSLuaFile( dir .. "/" .. file ) end
end )
