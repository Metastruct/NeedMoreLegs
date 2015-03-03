------------------------------------------------------
---- GTB-22 - Serverside File
---- by shadowscion
------------------------------------------------------

local Addon = NML or {}

local math   = math
local table  = table
local string = string

local Helper = Addon.Helper

local lerp = Helper.Lerp
local divVA = Helper.DivVA
local mulVA = Helper.MulVA
local getAngVel = Helper.AngVel
local ezAngForce = Helper.EZAngForce
local podEyeTrace = Helper.PodEyeTrace
local traceDirection = Helper.TraceDirection

------------------------------------------------------

local Mech = Addon.CreateMechType( "type_gtb22", "nml_mechtypes" )

Mech:SetPhysicsBox(
    Vector( -40, -40, -50 ),
    Vector( 40, 40, 50 ),
    Vector( -40, -40, -100 ),
    Vector( 40, 40, 75 )
 )

------------------------------------------------------

Mech:SetInitialize( function( self )
    -- Vars
    self.WalkSpeed = 0
    self.StrafeSpeed = 0
end )

------------------------------------------------------

Mech:SetThink( function( self, ent, veh, ply, dt )
    local phys = ent:GetPhysicsObject()
    if not IsValid( phys ) then return end

    -- Setup Inputs
    local aimPos = Vector()
    local w, a, s, d = 0, 0, 0, 0
    local ctrl, alt, space, shift = 0, 0, 0, 0

    if IsValid( ply ) then
        w = ply:KeyDown( IN_FORWARD ) and 1 or 0
        a = ply:KeyDown( IN_MOVELEFT ) and 1 or 0
        s = ply:KeyDown( IN_BACK ) and 1 or 0
        d = ply:KeyDown( IN_MOVERIGHT ) and 1 or 0

        ctrl = ply:KeyDown( IN_DUCK ) and 1 or 0
        alt = ply:KeyDown( IN_WALK ) and 0 or 1

        aimPos = podEyeTrace( ply ).HitPos
    else
        aimPos = ent:GetPos() + ent:GetForward()*200
    end

    self.WalkSpeed = lerp( self.WalkSpeed, w - s, 0.1 )
    self.StrafeSpeed = lerp( self.StrafeSpeed, d - a, 0.1 )

    -- Physics
    local trace = traceDirection( 150, phys:GetPos(), Vector( 0, 0, -1 ), { ent, veh, ply }, nil )

    if trace.Hit then
        local height = trace.StartPos:Distance( trace.HitPos )

        local forceu = Vector( 0, 0, 100 - height )*5 - divVA( phys:GetVelocity(), Vector( 20, 20, 1 ) )
        local forcef = ent:GetForward()*( ( 15 - ctrl*7.5 )*self.WalkSpeed/1.5 )
        local forcer = ent:GetRight()*( ( 7.5 - ctrl*3.75 )*self.StrafeSpeed/1.5 )

        phys:EnableGravity( false )
        phys:ApplyForceCenter( ( forceu + forcef + forcer )*phys:GetMass() )

        local turnSpd = ( ( w + a + s + d ) ~= 0 and 1 or 1 )*phys:GetVelocity():Length()*2*alt
        local turnTo = math.ApproachAngle( phys:GetAngles().y, ( aimPos - phys:GetPos() ):Angle().y, dt*turnSpd )

        ezAngForce( ent, ent:WorldToLocalAngles( Angle( 0, turnTo, 0 ) )*200, 20 )
    else
        phys:EnableGravity( true )
    end
end )
