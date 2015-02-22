
if SERVER then

	AddCSLuaFile()
	AddCSLuaFile( "nml/lib/hologram.lua" )
	AddCSLuaFile( "nml/lib/gaitsystem.lua" )

	concommand.Add( "nml_reload", function()
		for _, ply in pairs( player.GetAll() ) do
			ply:SendLua( "NML.ReloadLibraries()" )
			ply:SendLua( "NML.ReloadSents()" )
		end
	end )

	return

end

NML = NML or {}

function NML.ReloadLibraries()
	include( "nml/lib/hologram.lua" )
	include( "nml/lib/gaitsystem.lua" )

	MsgC( Color( 145, 145, 175 ), "NML: Reloading libraries..\n" )
end

function NML.ReloadSents()
	local all = {}
	for _, ent in pairs( ents.GetAll() ) do
		if not string.find( ent:GetClass(), "sent_nml" ) then continue end
		if IsValid( ent ) then all[#all + 1] = ent end
	end

	if NML.Hologram then
		for _, cookie in pairs( NML.Hologram.CookieJar ) do
			_:Remove()
		end
	end

	timer.Simple( 0, function()
		for _, ent in pairs( all ) do
			hook.Remove( "Think", "nml_thinkhook_id_" .. ent:EntIndex() )
			ent:Initialize()
		end
	end )

	MsgC( Color( 145, 145, 175 ), "NML: Reloading spawned entities..\n" )
end

concommand.Add( "nml_reload_lib", NML.ReloadLibraries )
concommand.Add( "nml_reload_sent", NML.ReloadSents )

NML.ReloadLibraries()
NML.ReloadSents()
