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
        if not IsValid( self:GetMechPilotSeat() ) then return end
        if IsValid( self:GetMechPilot() ) then return end
        ply:EnterVehicle( self:GetMechPilotSeat() )
    end

else

    function ENT:Draw()
        self:DrawModel()
    end

end

function ENT:CanProperty( ply, property )
    if property == "remover" then return true end
    if property == "nml_context_menu" then return true end
    return false
end



function ENT:SetupDataTables()
    self:NetworkVar( "Entity", 0, "MechPilotSeat" )
    self:NetworkVar( "Entity", 1, "MechPilot" )

    self:NetworkVar( "Bool", 0, "MechToggleBones" )
    self:NetworkVar( "Bool", 1, "MechToggleShading" )
    self:NetworkVar( "Int", 0, "MechCurrentSkin" )
end

function ENT:Initialize()
    if SERVER then
        self:SetUseType( SIMPLE_USE )
        self:SetModel( "models/Combine_Helicopter/helicopter_bomb01.mdl" )

        local pod = ents.Create( "prop_vehicle_prisoner_pod" )

        pod:SetKeyValue( "limitview", 0 )
        pod:SetPos( self:LocalToWorld( Vector( 0, 0, 25 ) ) )
        pod:SetAngles( self:LocalToWorldAngles( Angle( 0, -90, 0 ) ) )
        pod:SetModel( "models/nova/jeep_seat.mdl" )
        pod:SetParent( self )
        pod:SetVehicleEntryAnim( false )
        pod:Spawn()
        pod:Activate()



        local phys = pod:GetPhysicsObject()
        if IsValid( phys ) then
            phys:EnableCollisions( false )
            phys:Wake()
        end

        self:SetMechPilotSeat( pod )
    end

    self.Mech = NML.GetMechType( "type_gtb22", "nml_mechtypes" )
    if not self.Mech then return end
    if not self.Mech.Initialize then return end

    timer.Simple( 0, function()
        self.Mech:SetEntity( self )
        self.Mech:Initialize()
    end )
end
