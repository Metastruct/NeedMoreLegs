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

----------------------------------------------------------------------------------

function Helper.Bearing( opos, oang, target )
	local pos, _ = WorldToLocal( target, Angle(), opos, oang )
	return rad2deg * -math.atan2( pos.y, pos.x )
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

----------------------------------------------------------------------------------
