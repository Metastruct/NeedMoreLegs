
----------------------------------------------------------------------------------

AddCSLuaFile()

----------------------------------------------------------------------------------

ENT.Base 		= "base_anim"
ENT.Type 		= "anim"
ENT.PrintName 	= "GTB-22"
ENT.Author 		= "shadowscion"
ENT.Category 	= "NeedMoreLegs"

ENT.Spawnable 		= true
ENT.AdminSpawnable 	= true
 ENT.Editable       = true

----------------------------------------------------------------------------------

function ENT:SpawnFunction( ply, trace )
 	if not trace.Hit then return end

	local sent = ents.Create( "sent_nml_gtb22" )

	sent:SetPos( trace.HitPos + Vector( 0, 0, 125 ) )
	sent:SetAngles( Angle( 0, 0, 0 ) )
 	sent:Spawn()
 	sent:Activate()

	return sent
end

----------------------------------------------------------------------------------

if SERVER then
	function ENT:Initialize()
		self:SetModel( "models/hunter/blocks/cube025x025x025.mdl" )

		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )

		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then
			phys:EnableDrag( false )
			phys:EnableGravity( false )
			phys:EnableMotion( false )
		    phys:Wake()
		end
	end

	return
end

----------------------------------------------------------------------------------

if not CLIENT then return end

----------------------------------------------------------------------------------

function ENT:Initialize()
	if not IsValid( self ) then return end

	local Mech = NML_GetMechType( "GTB22" )

	Mech:SetEntity( self )
	Mech:Initialize()
end

function ENT:Draw()
	self:DrawModel()
end

----------------------------------------------------------------------------------
