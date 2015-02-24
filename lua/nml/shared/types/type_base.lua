----------------------------------------------------------------------------------

local Mech = NML_CreateMechType( "base_mechtype" )

----------------------------------------------------------------------------------

Mech:SetInit( function( self )
	if SERVER then

		return
	end

	if not CLIENT then return end

end )

Mech:SetThink( function( self )
	if SERVER then

		return
	end

	if not CLIENT then return end

end )

----------------------------------------------------------------------------------
