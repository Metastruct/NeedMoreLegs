
NML = NML or {}

local file = file

function NML.NavigateFolders( dir, ftype, dtype, func )
    local _, list = file.Find( dir .. "/*", dtype )
    for _, fdir in pairs( list ) do
        NML.NavigateFolders( dir .. "/" .. fdir, ftype, dtype, func )
    end

    for _, ffile in pairs( file.Find( dir .. "/*." .. ftype, dtype ) ) do
        if func then func( dir , ffile ) end
    end
end

if SERVER then

    AddCSLuaFile()
    AddCSLuaFile( "nml/cl_init.lua" )

    include( "nml/sv_init.lua" )

else

    include( "nml/cl_init.lua" )

end
