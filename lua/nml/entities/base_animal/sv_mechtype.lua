------------------------------------------------------
---- Base Animal Type - Serverside File
---- by shadowscion
------------------------------------------------------

local Addon = NML or {}

local math   = math
local table  = table

local Helper = Addon.Helper

local lerp = Helper.Lerp
local divVA = Helper.DivVA
local mulVA = Helper.MulVA
local getAngVel = Helper.AngVel
local ezAngForce = Helper.EZAngForce
local podEyeTrace = Helper.PodEyeTrace
local traceDirection = Helper.TraceDirection

------------------------------------------------------

local Mech = Addon.CreateMechType( "base_animal", "nml_mechtypes" )

------------------------------------------------------

Mech:SetInitialize( function( self, ent )
    self.WalkSpeed = 0
    self.StrafeSpeed = 0
    self.SlideMode = 0

    ent:SetMechToggleBones( true )
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
        shift = ply:KeyDown( IN_SPEED ) and 1 or 0
        alt = ply:KeyDown( IN_WALK ) and 0 or 1
        space = ply:KeyDown( IN_JUMP ) and 1 or 0

        aimPos = podEyeTrace( ply ).HitPos
    else
        aimPos = ent:GetPos() + ent:GetForward()*200
    end

    self.WalkSpeed = lerp( self.WalkSpeed, w - s, 0.1 )
    self.StrafeSpeed = lerp( self.StrafeSpeed, d - a, 0.1 )

    if self.SlideMode == 0 then
        self.SlideMode = shift
    end

    -- Physics
    local trace = traceDirection( 150, phys:GetPos(), Vector( 0, 0, -1 ), { ent, veh, ply }, nil )

    if trace.Hit then
        local height = trace.StartPos:Distance( trace.HitPos )

        local forceu = Vector( 0, 0, 50 - height )*5 - divVA( phys:GetVelocity(), Vector( 20, 20, 1 ) )
        local forcef = ent:GetForward()*( ( 15 - ctrl*7.5 + shift*15 )*self.WalkSpeed )
        local forcer = ent:GetRight()*( ( 10 - ctrl*5 )*self.StrafeSpeed )

        phys:EnableGravity( false )
        phys:ApplyForceCenter( ( forceu + forcef + forcer )*phys:GetMass() )

        local turnSpd = 2000
        local turnTo = math.ApproachAngle( phys:GetAngles().y, ( aimPos - phys:GetPos() ):Angle().y, dt*turnSpd )

        ezAngForce( ent, ent:WorldToLocalAngles( Angle( 0, turnTo, 0 ) )*200, 20 )

        if self.SlideMode == 1 then
            if shift == 0 then
                self.SlideMode = 0
                ent:SetMechMode( "Slide" )
            end
        end
    else
        phys:EnableGravity( true )
    end
end )
