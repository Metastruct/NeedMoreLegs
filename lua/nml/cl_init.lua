
-- Load Libraries and Modules
--include( "vgui/cl_spawnmenu.lua" )
include( "vgui/sh_contextmenu.lua" )

include( "libraries/sh_plshalp.lua" )

include( "modules/cl_hologram.lua" )
include( "modules/sh_mech.lua" )

-- Load Client Mechtype Files
NML.NavigateFolders( "nml/entities", "lua", "LUA", function( dir, file )
    local type = string.sub( file, 1, 2 )
    if type == "cl" or type == "sh" then include( dir .. "/" .. file ) end
    --print( dir .. "/" .. file )
end )

