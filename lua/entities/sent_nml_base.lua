AddCSLuaFile()

ENT.Base        = "base_anim"
ENT.Type        = "anim"
ENT.PrintName   = "base_nml"
ENT.Author      = "shadowscion"
ENT.Category    = "NeedMoreLegs"

ENT.Spawnable       = true
ENT.AdminSpawnable  = true

if SERVER then

    function ENT:SpawnFunction( ply, trace )
        if not trace.Hit then return end

        local sent = ents.Create( "sent_nml_base" )

        sent:SetPos( trace.HitPos + Vector( 0, 0, 125 ) )
        sent:SetAngles( Angle( 0, 0, 0 ) )
        sent:Spawn()
        sent:Activate()

        return sent
    end

    function ENT:Use( ply )
        if not IsValid( self:GetBaseVehicle() ) then return end
        if IsValid( self:GetBaseDriver() ) then return end
        ply:EnterVehicle( self:GetBaseVehicle() )
    end

else

    function ENT:Draw()
       -- self:DrawModel()
    end

end

function ENT:SetupDataTables()
    self:NetworkVar( "Entity", 0, "BaseVehicle" )
    self:NetworkVar( "Entity", 1, "BaseDriver" )
end

function ENT:Initialize()
    if SERVER then
        self:SetModel( "models/hunter/blocks/cube2x2x2.mdl" )

        self:SetUseType( SIMPLE_USE )
        self:PhysicsInitBox( Vector( -40, -40, -50 ), Vector( 40, 40, 50 ) )
        self:SetCollisionBounds( Vector( -40, -40, -100 ), Vector( 40, 40, 75 ) )

        local phys = self:GetPhysicsObject()
        if IsValid( phys ) then
            phys:SetMass( 5000 )
            phys:EnableDrag( false )
            phys:EnableGravity( false )
            phys:EnableMotion( false )
            phys:Wake()
        end

        local vehicle = ents.Create( "prop_vehicle_prisoner_pod" )

        vehicle:SetKeyValue( "limitview", "0" )
        vehicle:SetPos( self:LocalToWorld( Vector( 0, 0, 25 ) ) )
        vehicle:SetAngles( self:GetAngles() )
        vehicle:SetModel( "models/nova/jeep_seat.mdl" )
        vehicle:SetParent( self )
        vehicle:Spawn()
        vehicle:Activate()

        local phys = vehicle:GetPhysicsObject()
        if IsValid( phys ) then
            phys:EnableCollisions( false )
            phys:Wake()
        end

        self:SetBaseVehicle( vehicle )
    end

    self.Mech = NML_GetMechType( "gtb22" )
    if not self.Mech then return end
    if not self.Mech.Initialize then return end

    timer.Simple( 0, function()
        self.Mech:SetEntity( self )
        self.Mech:Initialize()
    end )
end
