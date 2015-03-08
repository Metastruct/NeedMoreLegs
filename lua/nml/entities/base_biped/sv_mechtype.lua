------------------------------------------------------
---- Base Biped Type - Serverside File
---- by shadowscion
------------------------------------------------------

local Addon = NML or {}

local math   = math
local table  = table
local string = string

------------------------------------------------------

local Mech = Addon.CreateMechType( "base_biped", "nml_mechtypes" )

Mech:SetPhysicsBox( Vector( -200, -200, 0), Vector( 200, 200, 200 ) )

------------------------------------------------------

Mech:SetInitialize( function( self )

end )

------------------------------------------------------

Mech:SetThink( function( self, dt )

end )
