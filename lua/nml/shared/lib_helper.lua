----------------------------------------------------------------------------------

NML.Helper = NML.Helper or {}
local Helper = NML.Helper

----------------------------------------------------------------------------------

local util = util
local math = math

local pi = math.pi
local deg2rad = pi / 180
local rad2deg = 180 / pi

function Helper.Sin( deg )
    return math.sin( deg * deg2rad )
end

function Helper.Cos( deg )
    return math.cos( deg * deg2rad )
end

function Helper.Acos( rad )
    return math.acos( rad ) * rad2deg
end

function Helper.Asin( rad )
    return math.asin( rad ) * rad2deg
end

function Helper.Atan( a, b )
    return math.atan2( a, b ) * rad2deg
end

function Helper.Sign( a )
    if a > 0 then return 1 end
    if a < 0 then return -1 end
    return 0
end

---------------------------------------------------------------------------------

local function bearing( opos, oang, target )
    local pos, _ = WorldToLocal( target, Angle(), opos, oang )
    return rad2deg * -math.atan2( pos.y, pos.x )
end
Helper.Bearing = bearing

function Helper.Bearing2( ent, target, mul, condition )
    local yaw = ent:GetAngles().y
    if not condition then return yaw end
    return yaw - bearing( ent:GetPos(), Angle( 0, yaw, 0 ), target ) / mul
end

function Helper.ToLocalAxis( entity, axis )
    return entity:WorldToLocal( axis + entity:GetPos() )
end

local function lerp( x, y, ratio )
    return x * ratio + y * ( 1 - ratio )
end
Helper.Lerp = lerp

local function lerpVec( startPos, endPos, ratio )
    return Vector( lerp( startPos.x, endPos.x, ratio ), lerp( startPos.y, endPos.y, ratio ), lerp( startPos.z, endPos.z, ratio ) )
end
Helper.LerpVector = lerpVec

local function bezier( startPos, midPos, endPos, ratio )
    return lerpVec( lerpVec( endPos, midPos, ratio ), lerpVec( midPos, startPos, ratio ), ratio )
end
Helper.Bezier = bezier

local function rangerOffset( ... )
    local args = {...}

    -- from vec to vec
    -- args - start, end, filter
    if #args == 3 then
        return util.TraceLine( {
            start  = args[1],
            endpos = args[2],
            filter = args[3],
        } )
    end

    -- from vec to direction * distance
    -- args - dist, start, dir, filter
    if #args == 4 then
        return util.TraceLine( {
            start  = args[2],
            endpos = args[2] + args[3] * args[1],
            filter = args[4],
        } )
    end

    return nil
end
Helper.RangerOffset = rangerOffset

local function podEyeTrace( ply )
    if not ply:InVehicle() then return {} end

    local pos = ply:GetShootPos()
    local dir = ply:GetVehicle():WorldToLocal( ply:GetAimVector() + ply:GetVehicle():GetPos() )

    return util.TraceLine( {
        start  = pos,
        endpos = pos + dir * 32768,
        mask   = MASK_SOLID_BRUSHONLY,
    } )
end
Helper.PodEyeTrace = podEyeTrace

----------------------------------------------------------------------------------

local function notHuge( value )
    return -math.huge < value[1] and value[1] < math.huge and
    -math.huge < value[2] and value[2] < math.huge and
    -math.huge < value[3] and value[3] < math.huge
end
Helper.NotHuge = notHuge

local function divVA( valueA, valueB )
    if type( valueA ) == "Vector" and type( valueB ) == "Vector" then return Vector( valueA.x / valueB.x, valueA.y / valueB.y, valueA.z / valueB.z ) end
    if type( valueA ) == "Angle" and type( valueB ) == "Angle" then return Angle( valueA.p / valueB.p, valueA.y / valueB.y, valueA.r / valueB.r ) end
    return nil
end
Helper.DivVA = divVA

local function mulVA( valueA, valueB )
    if type( valueA ) == "Vector" and type( valueB ) == "Vector" then return Vector( valueA.x * valueB.x, valueA.y * valueB.y, valueA.z * valueB.z ) end
    if type( valueA ) == "Angle" and type( valueB ) == "Angle" then return Angle( valueA.p * valueB.p, valueA.y * valueB.y, valueA.r * valueB.r ) end
    return nil
end
Helper.MulVA = mulVA

if SERVER then
    local function inertiaAsAngle( ent )
        local phys = ent:GetPhysicsObject()
        if IsValid( phys ) then
            local vec = phys:GetInertia()
            return Angle( vec.y, vec.z, vec.x )
        end
        return Angle()
    end
    Helper.InertiaAsAngle = inertiaAsAngle

    local function angVel( ent )
        local phys = ent:GetPhysicsObject()
        if IsValid( phys ) then
            local vec = phys:GetAngleVelocity()
            return Angle( vec.y, vec.z, vec.x )
        end
        return Angle()
    end
    Helper.AngVel = angVel

    local function applyAngForce( ent, angForce )
        if angForce.p == 0 and angForce.y == 0 and angForce.r == 0 then return end
        if not notHuge( angForce ) then return end

        local phys = ent:GetPhysicsObject()
        if not IsValid( phys ) then return end

        local up = ent:GetUp()
        local left = ent:GetRight() * -1
        local forward = ent:GetForward()

        if angForce.p ~= 0 then
            local pitch = up * ( angForce.p * 0.5 )
            phys:ApplyForceOffset( forward, pitch )
            phys:ApplyForceOffset( forward * -1, pitch * -1 )
        end

        if angForce.y ~= 0 then
            local yaw = forward * ( angForce.y * 0.5 )
            phys:ApplyForceOffset( left, yaw )
            phys:ApplyForceOffset( left * -1, yaw * -1 )
        end

        if angForce.r ~= 0 then
            local roll = left * ( angForce.r * 0.5 )
            phys:ApplyForceOffset( up, roll )
            phys:ApplyForceOffset( up * -1, roll * -1 )
        end
    end
    Helper.ApplyAngForce = applyAngForce

    function Helper.EZAngForce( ent, force, damping )
        applyAngForce( ent, mulVA( force - angVel( ent ) * damping, inertiaAsAngle( ent ) ) )
    end
end

----------------------------------------------------------------------------------
