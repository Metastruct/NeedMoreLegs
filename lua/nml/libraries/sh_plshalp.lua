------------------------------------------------------
---- General Helper Functions
------------------------------------------------------

local Addon = NML or {}
Addon.Helper = Addon.Helper or {}

local Helper = Addon.Helper

--- Math
-- @section

local math = math

--- Determines whether a vector or angle is not inf
-- @function notHuge
-- @param Value Can either be a vector or angle
-- @return Bool Valid
-- @usage local Valid = notHuge( Vector() )
local function notHuge( value )
    return -math.huge < value[1] and value[1] < math.huge and
    -math.huge < value[2] and value[2] < math.huge and
    -math.huge < value[3] and value[3] < math.huge
end
Helper.NotHuge = notHuge

--- Clamps vector A within minvec and maxvec
-- @function clampVec
-- @tparam Vector Value
-- @tparam Vector Min
-- @tparam Vector Max
-- @param Vector
-- @usage local V = clampVec( Vector( 50, 0, 0 ), Vector(), Vector( 100, 0, 0 ) )
local function clampVec( v0, v1, v2 )
    return Vector(
        math.Clamp( v0.x, v1.x, v2.x ),
        math.Clamp( v0.y, v1.y, v2.y ),
        math.Clamp( v0.z, v1.z, v2.z )
    )
end
Helper.ClampVec = clampVec

--- Clamps angle A within minang and maxang
-- @function clampAng
-- @tparam Angle Value
-- @tparam Angle Min
-- @tparam Angle Max
-- @param Angle
-- @usage local A = clampAng( Angle( 50, 0, 0 ), Angle(), Angle( 100, 0, 0 ) )
local function clampAng( a0, a1, a2 )
    local ang =  Angle(
        math.Clamp( a0.p, a1.p, a2.p ),
        math.Clamp( a0.y, a1.y, a2.y ),
        math.Clamp( a0.r, a1.r, a2.r )
    )
    ang:Normalize()
    return ang
end
Helper.ClampAng = clampAng

--- Returns sin( n ) in radians
-- @function sin
-- @tparam Number Degrees
-- @return Radians
-- @usage local Rad = sin( 90 )
local function sin( deg )
    return math.sin( math.rad( deg ) )
end
Helper.Sin = sin

--- Returns cos( n ) in radians
-- @function cos
-- @tparam Number Degrees
-- @return Radians
-- @usage local Rad = cos( 90 )
local function cos( deg )
    return math.cos( math.rad( deg ) )
end
Helper.Cos = cos

--- Returns inverse cos( n ) in degrees
-- @function acos
-- @tparam Number Radians
-- @return Degrees
-- @usage local Deg = acos( 0.5 )
local function acos( rad )
    return math.deg( math.acos( rad ) )
end
Helper.Acos = acos

--- Returns inverse sine( n ) in degrees
-- @function asin
-- @tparam Number Radians
-- @return Degrees
-- @usage local Deg = asin( 0.5 )
local function asin( rad )
    return math.deg( math.asin( rad ) )
end
Helper.Asin = asin

--- Returns inverse tangent( a/b ) in degrees
-- @function atan
-- @tparam Number A
-- @tparam Number B
-- @return Degrees
-- @usage local Deg = atan( 1, 3 )
local function atan( a, b )
    return math.deg( math.atan2( a, b ) )
end
Helper.Atan = atan

--- Returns the sign (  + - ) of n
-- @function sign
-- @tparam Number Num
-- @return Num
-- @usage local Sign = sign( -1 )
local function sign( num )
    if num > 0 then return 1 end
    if num < 0 then return -1 end
    return 0
end
Helper.Sign = sign

--- Custom Vector/Angle division operator
-- @function divVA
-- @param ValueA Can either be a vector or angle
-- @param ValueB Can either be a vector or angle ( must be same as value A )
-- @return Value
-- @usage local Test = divVA( Vector(), Vector( 50, 0, 0 ) )
local function divVA( valueA, valueB )
    if type( valueA ) == "Vector" and type( valueB ) == "Vector" then return Vector( valueA.x/valueB.x, valueA.y/valueB.y, valueA.z/valueB.z ) end
    if type( valueA ) == "Angle" and type( valueB ) == "Angle" then return Angle( valueA.p/valueB.p, valueA.y/valueB.y, valueA.r/valueB.r ) end
    return nil
end
Helper.DivVA = divVA

--- Custom Vector/Angle multiplication operator
-- @function mulVA
-- @param ValueA Can either be a vector or angle
-- @param ValueB Can either be a vector or angle ( must be same as value A )
-- @return Value
-- @usage local Test = mulVA( Vector(), Vector( 50, 0, 0 ) )
local function mulVA( valueA, valueB )
    if type( valueA ) == "Vector" and type( valueB ) == "Vector" then return Vector( valueA.x*valueB.x, valueA.y*valueB.y, valueA.z*valueB.z ) end
    if type( valueA ) == "Angle" and type( valueB ) == "Angle" then return Angle( valueA.p*valueB.p, valueA.y*valueB.y, valueA.r*valueB.r ) end
    return nil
end
Helper.MulVA = mulVA

--- Returns the bearing between two vectors and an angle
-- @function bearing
-- @tparam Vector OriginPos
-- @tparam Angle OriginAngle
-- @tparam Vector Target
-- @return Number Bearing
-- @usage local Bearing = bearing( Vector(), Angle(), Vector( 0, 100, 0 ) )
local function bearing( opos, oang, target )
    local pos, _ = WorldToLocal( target, Angle(), opos, oang )
    return -atan( pos.y, pos.x )
end
Helper.Bearing = bearing

--- Returns the bearing between an entity and a vector
-- @function bearing2
-- @tparam Entity Entity
-- @tparam Vector Target
-- @tparam Number Multiplyer Dampens the bearing
-- @tparam Number Condition If false, entity's yaw is returned
-- @return Number Bearing
-- @usage local Bearing = bearing( Entity( 50 ), Vector( 0, 100, 0 ), 10, true )
local function bearing2( ent, target, mul, condition )
    local yaw = ent:GetAngles().y
    if not condition then return yaw end
    return yaw - bearing( ent:GetPos(), Angle( 0, yaw, 0 ), target )/mul
end
Helper.Bearing2 = bearing2

--- Transforms a world axis to an axis local to an entity
-- @function toLocalAxis
-- @tparam Entity Entity
-- @tparam Vector Axis
-- @return Vector LocalAxis
-- @usage local Axis = toLocalAxis( Entity( 50 ), Vector( 0.5, 0, 0 ) )
local function toLocalAxis( ent, axis )
    return ent:WorldToLocal( axis + ent:GetPos() )
end
Helper.ToLocalAxis = toLocalAxis

--- Interpolation
-- @section

--- Linearly interpolates between two numbers
-- @function lerp
-- @tparam Number A
-- @tparam Number B
-- @tparam Number Ratio
-- @return Number Interpolation
-- @usage local Interpolation = lerp( 0, 1, 0.5 )
local function lerp( y0, y1, t )
    return y0 + ( y1 - y0 )*t
end
Helper.Lerp = lerp

--- Returns a cosine interpolation between two numbers
-- @function clerp
-- @tparam Number A
-- @tparam Number B
-- @tparam Number Ratio
-- @return Number Interpolation
-- @usage local Interpolation = clerp( 0, 1, 0.5 )
local function clerp( y0, y1, t )
    return lerp( y0, y1, -math.cos( math.pi*t )/2 + 0.5 )
end
Helper.CLerp = clerp

--- Linearly interpolates between two vectors
-- @function lerpVec
-- @tparam Vector StartPos
-- @tparam Vector EndPos
-- @tparam Number Ratio
-- @return Vector Interpolation
-- @usage local Interpolation = lerpVec( 0, 1, 0.5 )
local function lerpVec( startPos, endPos, ratio )
    return Vector( lerp( startPos.x, endPos.x, ratio ), lerp( startPos.y, endPos.y, ratio ), lerp( startPos.z, endPos.z, ratio ) )
end
Helper.LerpVec = lerpVec

--- Returns a bezier spline between three vectors
-- @function bezier
-- @tparam Vector StartPos
-- @tparam Vector MidPos
-- @tparam Vector EndPos
-- @tparam Number Ratio
-- @return Vector Bezier
-- @usage local Bezier = bezier( Vector(), Vector( 50, 0, 0 ), Vector( 0, 0, 100 ), 0.5 )
local function bezier( startPos, midPos, endPos, ratio )
    return Vector(
        ( 1 - ratio )^2*startPos.x + ( 2*( 1 - ratio )*ratio*midPos.x ) + ratio^2*endPos.x,
        ( 1 - ratio )^2*startPos.y + ( 2*( 1 - ratio )*ratio*midPos.y ) + ratio^2*endPos.y,
        ( 1 - ratio )^2*startPos.z + ( 2*( 1 - ratio )*ratio*midPos.z ) + ratio^2*endPos.z
    )
end
Helper.Bezier = bezier

--- Trace
-- @section

local util = util

--- A trace that points in a direction for a set distance
-- @function traceDirection
-- @tparam Number Distance
-- @tparam Vector StartPos
-- @tparam Vector Direction
-- @tparam Table Filter
-- @tparam Enum Mask
-- @return TraceData
-- @usage local Trace = traceDirection( 500, Vector(), Vector( 0, 0, 1 ), nil, MASK_SOLID_BRUSHONLY )
local function traceDirection( dist, start, dir, filter, mask )
    local data = {
        start  = start,
        endpos = start + dir*dist,
        filter = filter or nil,
        mask   = mask or nil,
    }
    return util.TraceLine( data )
end
Helper.TraceDirection = traceDirection

--- A trace that goes from vector A to vector B
-- @function traceToVector
-- @tparam Vector StartPos
-- @tparam Vector EndPos
-- @tparam Table Filter
-- @tparam Enum Mask
-- @return TraceData
-- @usage local Trace = traceDirection( Vector(), Vector( 0, 0, 100 ), nil, MASK_SOLID_BRUSHONLY )
local function traceToVector( start, endpos, filter, mask )
    local data = {
        start  = start,
        endpos = endpos,
        filter = filter or nil,
        mask   = mask or nil,
    }
    return util.TraceLine( data )
end
Helper.TraceToVector = traceToVector

--- A trace that is localized around the player's vehicle's axis
-- @function podEyeTrace
-- @tparam Player Player
-- @return TraceData
-- @usage local Trace = podEyeTrace( LocalPlayer() )
local function podEyeTrace( ply )
    if not IsValid( ply ) then return {} end
    if not ply:InVehicle() then return {} end

    local pos = ply:GetShootPos()
    local dir = ply:GetVehicle():WorldToLocal( ply:GetAimVector() + ply:GetVehicle():GetPos() )

    return util.TraceLine( {
        start  = pos,
        endpos = pos + dir*32768,
        mask   = MASK_SOLID_BRUSHONLY,
    } )
end
Helper.PodEyeTrace = podEyeTrace

---- Serverside Functions
-- @section

if CLIENT then return end

--- Return an entity's inertia as an angle
-- @function inertiaAsAngle
-- @tparam Entity Entity
-- @return Angle Inertia
-- @usage local Inertia = inertiaAsAngle( Entity( 50 ) )
local function inertiaAsAngle( ent )
    local phys = ent:GetPhysicsObject()
    if IsValid( phys ) then
        local vec = phys:GetInertia()
        return Angle( vec.y, vec.z, vec.x )
    end
    return Angle()
end
Helper.InertiaAsAngle = inertiaAsAngle

--- Return an entity's angular velocity
-- @function angVel
-- @tparam Entity Entity
-- @return Angle AngularVelocity
-- @usage local AngVel = angVel( Entity( 50 ) )
local function angVel( ent )
    local phys = ent:GetPhysicsObject()
    if IsValid( phys ) then
        local vec = phys:GetAngleVelocity()
        return Angle( vec.y, vec.z, vec.x )
    end
    return Angle()
end
Helper.AngVel = angVel

--- Applies an angular force to an entity
-- @function applyAngForce
-- @tparam Entity Entity
-- @tparam Angle AngularForce
-- @usage applyAngForce( Entity( 50 ), Angle( 100, 0, 0 ) )
local function applyAngForce( ent, angForce )
    if angForce.p == 0 and angForce.y == 0 and angForce.r == 0 then return end
    if not notHuge( angForce ) then return end

    local phys = ent:GetPhysicsObject()
    if not IsValid( phys ) then return end

    local up = ent:GetUp()
    local left = ent:GetRight()*-1
    local forward = ent:GetForward()

    if angForce.p ~= 0 then
        local pitch = up*( angForce.p*0.5 )
        phys:ApplyForceOffset( forward, pitch )
        phys:ApplyForceOffset( forward*-1, pitch*-1 )
    end

    if angForce.y ~= 0 then
        local yaw = forward*( angForce.y*0.5 )
        phys:ApplyForceOffset( left, yaw )
        phys:ApplyForceOffset( left*-1, yaw*-1 )
    end

    if angForce.r ~= 0 then
        local roll = left*( angForce.r*0.5 )
        phys:ApplyForceOffset( up, roll )
        phys:ApplyForceOffset( up*-1, roll*-1 )
    end
end
Helper.ApplyAngForce = applyAngForce

--- Applies a dampened and smoothed angular force to an entity
-- @function applyAngForce
-- @tparam Entity Entity
-- @tparam Angle AngularForce
-- @tparam Number Damping
-- @usage ezAngForce( Entity( 50 ), Angle( 100, 0, 0 ), 20 )
local function ezAngForce( ent, force, damping )
    applyAngForce( ent, mulVA( force - angVel( ent )*damping, inertiaAsAngle( ent ) ) )
end
Helper.EZAngForce = ezAngForce
