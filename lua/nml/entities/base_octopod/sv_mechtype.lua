------------------------------------------------------
---- Base Octopod Type - Serverside File
---- by shadowscion
------------------------------------------------------

local Addon = NML or {}

local math   = math
local table  = table
local string = string

local Helper = Addon.Helper

local atan = Helper.Atan
local lerp = Helper.Lerp
local divVA = Helper.DivVA
local mulVA = Helper.MulVA
local getAngVel = Helper.AngVel
local ezAngForce = Helper.EZAngForce
local podEyeTrace = Helper.PodEyeTrace
local toLocalAxis = Helper.ToLocalAxis
local traceDirection = Helper.TraceDirection
local traceToVector = Helper.TraceToVector

------------------------------------------------------

local Mech = Addon.CreateMechType( "base_octopod", "nml_mechtypes" )

-- Mech:SetPhysicsBox(
--     Vector( -40, -40, -50 ),
--     Vector( 40, 40, 50 ),
--     Vector( -40, -40, -100 ),
--     Vector( 40, 40, 75 )
--  )

------------------------------------------------------

Mech:SetInitialize( function( self )
    -- Vars
    self.WalkSpeed = 0
    self.StrafeSpeed = 0


    self.TestA = ents.Create( "prop_physics" )
    self.TestA:SetModel( "models/hunter/blocks/cube025x025x025.mdl" )
    self.TestA:Spawn()
    self.TestA:Activate()

    self.Entity:CallOnRemove( "Wtf", function( ent ) self.TestA:Remove() end )
end )

------------------------------------------------------

local function getSurfaceVec( ent, startpos, endpos, filter )
    local trace = util.TraceLine( {
        start = ent:GetPos(),
        endpos = startpos,
        filter = filter or nil,
        --mask = MASK_PLAYERSOLID_BRUSHONLY,
    } )

    if trace.Hit then
        return trace.HitPos
    else
        return util.TraceLine( {
            start = startpos,
            endpos = endpos,
            filter = filter or nil,
            --mask = MASK_PLAYERSOLID_BRUSHONLY,
        } ).HitPos
    end
end

local function getSurfaceAng( ent, aim, add, frontl, frontr, rearl, rearr )
    local axisp = toLocalAxis( ent, ( frontl + frontr )/2 - ( rearl + rearr )/2 )
    local axisr = toLocalAxis( ent, ( frontr + rearr )/2 - ( frontl + rearl )/2 )
    local yaw = toLocalAxis( ent, aim - ent:GetPos() ):Angle()

    return ent:LocalToWorldAngles( add + Angle( atan( axisp.x, axisp.z ) - 90, yaw.y, atan( -axisr.y, axisr.z ) - 90 ) )
end

local function velL( self )
    if not IsValid( self ) then return Vector() end
    return self:WorldToLocal( self:GetVelocity() + self:GetPos() )
end

local function setZ( self, z )
    return Vector( self.x or 0, self.y or 0, z or self.z )
end

local offset = 100
local height = 0
local traceHeight = -200

local traceMiddle = Vector( 0, 0, traceHeight )
local traceOffsetFL = Vector( offset, offset, height )
local traceOffsetFR = Vector( offset, -offset, height )
local traceOffsetRL = Vector( -offset, offset, height )
local traceOffsetRR = Vector( -offset, -offset, height )

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

        aimPos = podEyeTrace( ply ).HitPos
    else
        aimPos = ent:GetPos() + ent:GetForward()*200
    end

    self.WalkSpeed = lerp( self.WalkSpeed, w - s, 0.1 )
    self.StrafeSpeed = lerp( self.StrafeSpeed, d - a, 0.1 )

    local entVel = phys:GetVelocity()
    local entVelL = velL( ent )
    local filter = table.Add( { ent, veh }, player.GetAll() )

    local surfaceFL = getSurfaceVec( ent, ent:LocalToWorld( traceOffsetFL ), ent:LocalToWorld( setZ( traceOffsetRR, traceHeight ) ), filter )
    local surfaceFR = getSurfaceVec( ent, ent:LocalToWorld( traceOffsetFR ), ent:LocalToWorld( setZ( traceOffsetRL, traceHeight ) ), filter )
    local surfaceRL = getSurfaceVec( ent, ent:LocalToWorld( traceOffsetRL ), ent:LocalToWorld( setZ( traceOffsetFR, traceHeight ) ), filter )
    local surfaceRR = getSurfaceVec( ent, ent:LocalToWorld( traceOffsetRR ), ent:LocalToWorld( setZ( traceOffsetFL, traceHeight ) ), filter )

    local surfaceHeight = ent:GetPos():Distance( ( surfaceFL + surfaceFR + surfaceRL + surfaceRR )/4 )

    if 100 - surfaceHeight > 0 then
        local surfaceAng = getSurfaceAng( ent, aimPos, Angle(), surfaceFL, surfaceFR, surfaceRL, surfaceRR )

        local normalU = surfaceAng:Up()
        local traceU = traceToVector( ent:GetPos(), ent:LocalToWorld( traceMiddle ), filter )
        local heightU = 40 + math.max( 0, 40 - traceU.StartPos:Distance( traceU.HitPos ) )
        local forceU = ( heightU - surfaceHeight )*normalU*5 - entVel:Dot( normalU )*normalU/2

        local normalF = surfaceAng:Forward()
        local forceF = normalF*( self.WalkSpeed*75 ) - entVel:Dot( normalF )*normalF/5

        local normalR = surfaceAng:Right()
        local forceR = normalR*( self.StrafeSpeed*75 ) - entVel:Dot( normalR )*normalR/5

        phys:ApplyForceCenter( ( forceU + forceF + forceR )*phys:GetMass() )

        ezAngForce( ent, ent:WorldToLocalAngles( surfaceAng )*300, 30 )

        phys:EnableGravity( false )
    else
        phys:EnableGravity( true )
    end
/*
        local UNormal = SurfaceAngle:up()
        local Oscillate = getFootHeight( Gaits[1, table], Gaits[2, table], 25 )
        local UHeight = 40 + SinT*3 + abs( Oscillate ) + max( 0, 40 - rangerOffsetHull( Entity, EntPos, Entity:toWorld( RangerMiddle ) ):distance() )
        local UForce = ( UHeight - SurfaceHeight )*UNormal*5 - EntVel:dot( UNormal )*UNormal/2

        local FNormal = SurfaceAngle:forward()
        local FForce = FNormal*( Owner:keyAttack2()*125 ) - EntVel:dot( FNormal )*FNormal/5

        local RNormal = SurfaceAngle:right()
        local RForce = RNormal*( Owner:keyPressed( "right" ) - Owner:keyPressed( "left" ) )*50 - EntVel:dot( RNormal )*RNormal/5

        Entity:applyAngForce( ( Entity:toLocal( SurfaceAngle )*300 - EntAngVel*30 )*Inertia )
        Entity:applyForce( ( UForce + FForce + RForce )*Mass )
        Entity:propGravity( 0 )*/

/*
    self.WalkSpeed = lerp( self.WalkSpeed, w - s, 0.1 )
    self.StrafeSpeed = lerp( self.StrafeSpeed, d - a, 0.1 )

    -- Physics
    local trace = traceDirection( 150, phys:GetPos(), Vector( 0, 0, -1 ), { ent, veh, ply }, nil )

    if trace.Hit then
        local height = trace.StartPos:Distance( trace.HitPos )

        local forceu = Vector( 0, 0, 50 - height )*5 - divVA( phys:GetVelocity(), Vector( 20, 20, 1 ) )
        local forcef = ent:GetForward()*( ( 15 - ctrl*7.5 + shift*7.5 )*alt*self.WalkSpeed )
        local forcer = ent:GetRight()*( ( 15 - ctrl*7.5 + shift*7.5 )*alt*self.StrafeSpeed )

        phys:EnableGravity( false )
        phys:ApplyForceCenter( ( forceu + forcef + forcer )*phys:GetMass() )

        local turnSpd = alt*1000
        local turnTo = math.ApproachAngle( phys:GetAngles().y, ( aimPos - phys:GetPos() ):Angle().y, dt*turnSpd )

        ezAngForce( ent, ent:WorldToLocalAngles( Angle( 0, turnTo, 0 ) )*200, 20 )
    else
        phys:EnableGravity( true )
    end*/
end )
