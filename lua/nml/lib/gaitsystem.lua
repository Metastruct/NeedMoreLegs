
----------------------------------------------------------------------------------

collectgarbage( "collect" )

NML = NML or {}
local NML = NML

NML.GaitSystem = NML.GaitSystem or {}
local GaitSystem = NML.GaitSystem

local util = util
local math = math
local unpack = unpack
local setmetatable = setmetatable

----------------------------------------------------------------------------------

local pi = math.pi
local deg2rad = pi / 180
local rad2deg = 180 / pi

function GaitSystem.Sin( deg )
    return math.sin( deg * deg2rad )
end

function GaitSystem.Cos( deg )
    return math.cos( deg * deg2rad )
end

function GaitSystem.Acos( rad )
    return math.acos( rad ) * rad2deg
end

function GaitSystem.Asin( rad )
    return math.asin( rad ) * rad2deg
end

function GaitSystem.Atan( a, b )
    return math.atan2( a, b ) * rad2deg
end

function GaitSystem.Sign( a )
	if a > 0 then return 1 end
	if a < 0 then return -1 end
	return 0
end

----------------------------------------------------------------------------------

function GaitSystem.Bearing( opos, oang, target )
	local pos, _ = WorldToLocal( target, Angle(), opos, oang )
	return rad2deg * -math.atan2( pos.y, pos.x )
end

function GaitSystem.ToLocalAxis( entity, axis )
	return entity:WorldToLocal( axis + entity:GetPos() )
end

local function lerp( x, y, ratio )
	return x * ratio + y * ( 1 - ratio )
end
GaitSystem.Lerp = lerp

local function lerpVec( startPos, endPos, ratio )
	return Vector( lerp( startPos.x, endPos.x, ratio ), lerp( startPos.y, endPos.y, ratio ), lerp( startPos.z, endPos.z, ratio ) )
end
GaitSystem.LerpVector = lerpVec

local function bezier( startPos, midPos, endPos, ratio )
	return lerpVec( lerpVec( endPos, midPos, ratio ), lerpVec( midPos, startPos, ratio ), ratio )
end
GaitSystem.Bezier = bezier

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
GaitSystem.RangerOffset = rangerOffset

----------------------------------------------------------------------------------
--- Mech Gait System
--- by shadowscion & Metamist
----------------------------------------------------------------------------------

local Gait = {}
Gait.__index = Gait

function GaitSystem.New( ... )
	local name, entity, offset, order = unpack( {...} )

	if not name or not entity or not offset or not order then return end
	if not type( name ) == "string" or not type( entity ) == "Entity" or not type( offset ) == "Vector" or not type( order ) == "Number" then return end

	local self = {}

	setmetatable( self, Gait )

	-- gait info
	self.name   = name
	self.entity = entity
	self.offset = offset

	local tr  = rangerOffset( 500, entity:LocalToWorld( offset ), -entity:GetUp(), entity )
	local vec = tr.HitPos + tr.HitNormal * 15

	-- gait data
	self.curve0  = vec --
	self.curve1  = vec -- bezier curve points
	self.curve2  = vec --
	self.stepPos = vec --

	self.stepOrder = order
	self.stepStart = order - math.floor( order )
	self.stepTake  = 0

	-- walk cycle
	self.walkVel   = 0
	self.walkCycle = 0

	return self
end

----------------------------------------------------------------------------------

function Gait:DoWalkAnimation( gmove, gfract, stepVel )
	if gmove then
		if self.stepTake == 0 then
			local traceA = rangerOffset( self.entity:GetPos(), self.entity:LocalToWorld( self.offset ), self.entity ).HitPos
			local traceB = rangerOffset( traceA, traceA + stepVel, self.entity )
			local traceC = rangerOffset( 500, traceB.HitPos, -self.entity:GetUp(), self.entity )

			local traceD = traceB.Hit and traceB or traceC
			local distance = self.curve2:Distance( traceD.HitPos )

			if distance > 15 then
				self.curve0 = self.curve2
				self.curve2 = traceD.HitPos
				self.curve1 = ( self.curve0 + self.curve2 ) / 2 + traceD.HitNormal * math.Clamp( distance / 2, 10, 50 )
				self.stepTake = 1
			else
				self.stepTake = -1
			end
		elseif self.stepTake == 1 then
			local traceA = rangerOffset( self.entity:GetPos(), self.entity:LocalToWorld( self.offset ), self.entity ).HitPos
			local traceB = rangerOffset( traceA, traceA + stepVel, self.entity )
			local traceC = rangerOffset( 500, traceB.HitPos, -self.entity:GetUp(), self.entity )

			self.curve2  = traceB.Hit and traceB.HitPos + traceB.HitNormal * 15 or traceC.HitPos + traceC.HitNormal * 15
			self.stepPos = bezier( self.curve0, self.curve1, self.curve2, gfract )
		end
	elseif self.stepTake ~= 0 then
		self.stepTake = 0
		self.stepPos  = self.curve2
	end
end

function Gait:DoWalkCycle( gaitSize, stepVel )
	-- gait information
	local gfract = 0
	local gmove  = false
	local gstop  = self.stepStart + gaitSize

	if self.walkCycle >= self.stepStart and self.walkCycle <= gstop then
		gfract = ( self.walkCycle - self.stepStart ) / ( gstop - self.stepStart )
		gmove = true
	end

	if self.stepStart < 0 then
		if self.walkCycle >= math.abs( self.stepStart ) and self.walkCycle <= 1 then
			gfract = ( self.walkCycle - self.stepStart ) / ( gstop - self.stepStart )
			gmove = true
		end
	elseif gstop > 1 then
		if self.walkCycle + 1 >= self.stepStart and self.walkCycle + 1 <= gstop then
			gfract = ( self.walkCycle + 1 - self.stepStart ) / ( gstop - self.stepStart )
			gmove = true
		end
	end

	-- perform leg animation
	self:DoWalkAnimation( gmove, gfract, stepVel )

	-- reset walk cycle
	if self.walkCycle > 1 then self.walkCycle = self.walkCycle - 1 end
end

function Gait:Think( rate, velMul, stepVel )
	--self.walkVel = lerp( self.walkVel, velMul, 0.1 )
	self.walkVel = lerp( self.walkVel, velMul, 0.1 * FrameTime() )
	self.walkCycle = self.walkCycle + ( ( 0.05 + 0.03 * self.walkVel / rate ) * 30 ) * FrameTime()

	local gaitSize = math.Clamp( 0.4 + 0.03 * self.walkVel / 100, 0, 0.9 )
	self:DoWalkCycle( gaitSize - math.floor( gaitSize ), stepVel )
end

----------------------------------------------------------------------------------
