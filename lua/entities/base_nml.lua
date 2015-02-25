----------------------------------------------------------------------------------

AddCSLuaFile()

----------------------------------------------------------------------------------

ENT.Base        = "base_anim"
ENT.Type        = "anim"
ENT.PrintName   = "base_nml"
ENT.Author      = "shadowscion"
ENT.Category    = "NeedMoreLegs"

ENT.Spawnable       = true
ENT.AdminSpawnable  = true

----------------------------------------------------------------------------------

--ENT.Think = nil

function ENT:SetupDataTables()
    self:NetworkVar( "Entity", 0, "PilotSeat" )
    self:NetworkVar( "Entity", 1, "Pilot" )
end

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

function ENT:CreateSeat()
    self.Seat = ents.Create( "prop_vehicle_prisoner_pod" )

    self.Seat:SetKeyValue ("limitview", "0" )
    self.Seat:SetPos( self:GetPos() + Vector( 0, 0, 25 ) )
    self.Seat:SetModel( "models/nova/jeep_seat.mdl" )
    self.Seat:SetAngles( Angle( 0, -90, 0 ) )
    self.Seat:SetParent( self )

    self.Seat:Spawn()
    self.Seat:Activate()

    self.Seat:SetRenderMode( RENDERMODE_TRANSALPHA )
    self.Seat:SetColor( Color ( 255, 255, 255, 0 ) )

    local phys = self.Seat:GetPhysicsObject()
    if IsValid( phys ) then
        phys:EnableCollisions( false )
        phys:Wake()
    end

    self:SetPilotSeat( self.Seat )

    timer.Simple( 5, function()
        if not IsValid( self.Seat ) then return end
        self.Seat:SetNoDraw( true )
    end )
end

function ENT:Initialize()
    self.NML = NML_GetMechType( "gtb22" ) or nil

    if SERVER then
        self:SetModel( "models/hunter/blocks/cube2x2x2.mdl" )

        --self:PhysicsInit( SOLID_VPHYSICS )
        --self:SetMoveType( MOVETYPE_VPHYSICS )
        --self:SetSolid( SOLID_VPHYSICS )

        self:SetUseType( SIMPLE_USE )
        self:PhysicsInitBox( Vector(-40, -40, -50), Vector(40, 40, 50) )
        self:SetCollisionBounds( Vector(-40, -40, -100), Vector(40, 40, 75) )

        local phys = self:GetPhysicsObject()
        if IsValid( phys ) then
            phys:SetMass( 5000 )
            phys:EnableDrag( false )
            phys:EnableGravity( false )
            phys:EnableMotion( false )
            phys:Wake()
        end

        self:CreateSeat()
    end

    timer.Simple( 0, function()
        if self.NML then
            self.NML:SetEntity( self )
            self.NML:SetVehicle( self:GetPilotSeat() )
            self.NML:Initialize()
        end
    end )
end

function ENT:Use( ply )
    if not IsValid( self:GetPilotSeat() ) then return end
    if IsValid( self:GetPilot() ) then return end
    ply:EnterVehicle( self:GetPilotSeat() )
end

----------------------------------------------------------------------------------

if not CLIENT then return end

----------------------------------------------------------------------------------

function ENT:Draw()
    --self:DrawModel()
end

----------------------------------------------------------------------------------
