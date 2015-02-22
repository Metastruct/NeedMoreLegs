
AddCSLuaFile()

local function Reload()
	if CLIENT then NML = NML or {} end

	local folders = {
		"nml/lib/",
		"nml/mech/",
	}

	for _, dir in pairs( folders ) do
		for _, path in pairs( file.Find( dir .. "*.lua", "LUA" ) ) do
			AddCSLuaFile( dir .. path )
			if CLIENT then
				include( dir .. path )
				MsgC( Color( 155, 175, 175 ), "NML: Loaded " , Color( 175, 195, 195 ), "\"" .. dir .. path .. "\"\n" )
			end
		end
	end
end

Reload()
