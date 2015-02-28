------------------------------------------------------------------------
---- GTB-22
---- Serverside File
------------------------------------------------------------------------

if not SERVER then return end

local Mech = NML_CreateMechType( "gtb22" )

Mech:SetInit( function( self )
    self.Walk = 0
    self.Strafe = 0
end )

local Helper         = NML.Helper
local cLerp          = Helper.CLerp
local divVA          = Helper.DivVA
local mulVA          = Helper.MulVA
local bearing2       = Helper.Bearing2
local ezAngForce     = Helper.EZAngForce
local getAngVel      = Helper.AngVel
local traceDirection = Helper.TraceDirection
local podEyeTrace    = Helper.PodEyeTrace

Mech:SetThink( function( self )
    local entity = self.Entity
    local phys = entity:GetPhysicsObject()
    if not IsValid( phys ) then return end

    local aimPos = Vector()
    local w, a, s, d = 0, 0, 0, 0
    local ctrl = 0

    if IsValid( self:GetDriver() ) then
        aimPos = podEyeTrace( self:GetDriver() ).HitPos

        w = self:GetDriver():KeyDown( IN_FORWARD ) and 1 or 0
        a = self:GetDriver():KeyDown( IN_MOVELEFT ) and 1 or 0
        s = self:GetDriver():KeyDown( IN_BACK ) and 1 or 0
        d = self:GetDriver():KeyDown( IN_MOVERIGHT ) and 1 or 0

        ctrl = self:GetDriver():KeyDown( IN_DUCK ) and 1 or 0
    else
        aimPos = entity:GetPos() + entity:GetForward()*100
    end

    self.Walk = cLerp( self.Walk, w - s, 0.1 )
    self.Strafe = cLerp( self.Strafe, d - a, 0.1 )

    local hover = traceDirection( 150, phys:GetPos(), Vector( 0, 0, -1 ), { entity, self:GetVehicle(), self:GetDriver() } )
    if hover.Hit then
        local dist = hover.HitPos:Distance( phys:GetPos() )

        local forceu = Vector( 0, 0, 100 - dist )*5 - divVA( phys:GetVelocity(), Vector( 20, 20, 5 ) )
        local forcef = entity:GetForward()*( ( 15 - ctrl*7.5 )*self.Walk )
        local forcer = entity:GetRight()*( ( 7.5 - ctrl*3.75 )*self.Strafe )

        phys:EnableGravity( false )
        phys:ApplyForceCenter( ( forceu + forcef + forcer )*phys:GetMass() )

        local turnTo = bearing2( entity, aimPos, 15, ( w + a + s + d ) ~= 0 and math.abs( self.Walk ) > 0.9 )
        ezAngForce( entity, entity:WorldToLocalAngles( Angle( 0, turnTo, 0 ) )*200, 20 )
    else
        phys:EnableGravity( true )
    end
end )
