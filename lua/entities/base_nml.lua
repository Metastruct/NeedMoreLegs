----------------------------------------------------------------------------------

AddCSLuaFile()

----------------------------------------------------------------------------------

ENT.Base 		= "base_anim"
ENT.Type 		= "anim"
ENT.PrintName 	= "base_nml"
ENT.Author 		= "shadowscion"
ENT.Category 	= "NeedMoreLegs"

ENT.Spawnable 		= true
ENT.AdminSpawnable 	= true

----------------------------------------------------------------------------------

function ENT:SpawnFunction( ply, trace )
 	if not trace.Hit then return end

	local sent = ents.Create( "base_nml" )

	sent:SetPos( trace.HitPos + Vector( 0, 0, 125 ) )
	sent:SetAngles( Angle( 0, 0, 0 ) )
 	sent:Spawn()
 	sent:Activate()

	return sent
end

----------------------------------------------------------------------------------

function ENT:Initialize()
	if SERVER then
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

	self.NML = NML_GetMechType( "gtb22" ) or nil
	if self.NML then
		self.NML:SetEntity( self )
		self.NML:Initialize()
	end
end

ENT.Think = nil

----------------------------------------------------------------------------------

if not CLIENT then return end

----------------------------------------------------------------------------------

function ENT:Draw()
	self:DrawModel()
end

----------------------------------------------------------------------------------
