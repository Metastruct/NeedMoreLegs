----------------------------------------------------------------------------------
---- NML Base Entity - by shadowscion
----------------------------------------------------------------------------------

AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.Author = "shadowscion"
ENT.PrintName = "base_nml"

ENT.Spawnable = true
ENT.AdminSpawnable = true

----------------------------------------------------------------------------------
---- DTVars

function ENT:SetupDataTables()
    self:NetworkVar( "String", 0, "SpawnType" )

    self:NetworkVar( "Entity", 0, "MechPilotSeat" )
    self:NetworkVar( "Entity", 1, "MechPilot" )
    self:NetworkVar( "Bool", 0, "MechToggleBones" )
    self:NetworkVar( "Bool", 1, "MechToggleShading" )
    self:NetworkVar( "Int", 0, "MechCurrentSkin" )
end

----------------------------------------------------------------------------------
---- Spawn Function

function ENT:SpawnFunction( ply, trace )
    if not trace.Hit then return end

    local type = ply:GetInfo( "nml_spawntype" )
    local types = list.Get( "nml_mechtypes" )
    if not types[type] then return end

    local sent = ents.Create( "sent_nml_base" )

    sent:SetSpawnType( type )
    sent:SetPos( trace.HitPos + Vector( 0, 0, 125 ) )
    sent:SetAngles( Angle( 0, 0, 0 ) )
    sent:Spawn()
    sent:Activate()

    return sent
end

----------------------------------------------------------------------------------
---- Initialize
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

    self.Mech = NML.GetMechType( self:GetSpawnType(), "nml_mechtypes" )
    if not self.Mech then self:Remove() return end
    if not self.Mech.Initialize then self:Remove() return end

    timer.Simple( 0, function()
        self.Mech:SetEntity( self )
        self.Mech:Initialize()
    end )
end

----------------------------------------------------------------------------------

function ENT:CanProperty( ply, property )
    if property == "remover" then return true end
    if property == "nml_context_menu" then return true end
    return false
end

----------------------------------------------------------------------------------

function ENT:Use( ply )
    if not IsValid( self:GetMechPilotSeat() ) then return end
    if IsValid( self:GetMechPilot() ) then return end
    ply:EnterVehicle( self:GetMechPilotSeat() )
end

----------------------------------------------------------------------------------

function ENT:Draw()
    --self:DrawModel()
end

----------------------------------------------------------------------------------
