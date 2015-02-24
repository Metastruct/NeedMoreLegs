----------------------------------------------------------------------------------
--- Gait Class - by shadowscion & Metamist
----------------------------------------------------------------------------------

local lerp = NML.Helper.Lerp
local bezier = NML.Helper.Bezier
local rangerOffset = NML.Helper.RangerOffset

local meta = {}
meta.__index = meta

function NML_CreateNewGait( entity, hipPos, stepOrder, groundHeight )
	if not entity or not hipPos or not stepOrder then return end
	if not type( entity ) == "Entity" or not type( hipPos ) == "Vector" or not type( stepOrder ) == "Number" then return end

	local self = {}

	setmetatable( self, meta )

	-- gait info
	self.Entity = entity
	self.HipPos = hipPos

	-- gait data
	local trace = rangerOffset( 500, entity:LocalToWorld( hipPos ), -entity:GetUp(), entity )
	local initv = trace.HitPos + trace.HitNormal * 15

	self.StepPointA = initv
	self.StepPointB = initv
	self.StepPointC = initv
	self.StepCurve  = initv

	self.GroundHeight = groundHeight or 0

	self.StepStart = stepOrder - math.floor( stepOrder )
	self.StepState = 0

	-- walk cycle
	self.WalkCycle = 0
	self.WalkVel = 0

	return self
end

----------------------------------------------------------------------------------

function meta:DoWalkAnimation( active, interp, addVel )
	if active then
		if self.StepState == 0 then
			local traceA = rangerOffset( self.Entity:GetPos(), self.Entity:LocalToWorld( self.HipPos ), self.Entity ).HitPos
			local traceB = rangerOffset( traceA, traceA + addVel, self.Entity )
			local traceC = rangerOffset( 500, traceB.HitPos, -self.Entity:GetUp(), self.Entity )

			local traceD   = traceB.Hit and traceB or traceC
			local distance = self.StepPointC:Distance( traceD.HitPos )

			if distance > 15 + self.GroundHeight then
				self.StepPointA = self.StepPointC
				self.StepPointC = traceD.HitPos + traceD.HitNormal * self.GroundHeight
				self.StepPointB = ( self.StepPointA + self.StepPointC ) / 2 + traceD.HitNormal * ( math.Clamp( distance / 2, 10, 50 ) + self.GroundHeight )
				self.StepState  = 1
			else
				self.StepState = -1
			end
		elseif self.StepState == 1 then
			local traceA = rangerOffset( self.Entity:GetPos(), self.Entity:LocalToWorld( self.HipPos ), self.Entity ).HitPos
			local traceB = rangerOffset( traceA, traceA + addVel, self.Entity )
			local traceC = rangerOffset( 500, traceB.HitPos, -self.Entity:GetUp(), self.Entity )

			self.StepPointC = traceB.Hit and traceB.HitPos + traceB.HitNormal * self.GroundHeight or traceC.HitPos + traceC.HitNormal * self.GroundHeight
			self.StepCurve  = bezier( self.StepPointA, self.StepPointB, self.StepPointC, interp )
		end
	elseif self.StepState ~= 0 then
		self.StepState = 0
		self.StepCurve = self.StepPointC
	end
end

----------------------------------------------------------------------------------

function meta:DoWalkCycle( gaitSize, addVel )
	local interp   = 0
	local active   = false
	local stepStop = self.StepStart + gaitSize

	if self.WalkCycle >= self.StepStart and self.WalkCycle <= stepStop then
		interp = ( self.WalkCycle - self.StepStart ) / ( stepStop - self.StepStart )
		active = true
	end

	if self.StepStart < 0 then
		if self.WalkCycle >= math.abs( self.StepStart ) and self.WalkCycle <= 1 then
			interp = ( self.WalkCycle - self.StepStart ) / ( stepStop - self.StepStart )
			active = true
		end
	elseif stepStop > 1 then
		if self.WalkCycle + 1 >= self.StepStart and self.WalkCycle + 1 <= stepStop then
			interp = ( self.WalkCycle + 1 - self.StepStart ) / ( stepStop - self.StepStart )
			active = true
		end
	end

	self:DoWalkAnimation( active, interp, addVel )

	if self.WalkCycle > 1 then self.WalkCycle = self.WalkCycle - 1 end
end

----------------------------------------------------------------------------------

function meta:Think( walkVel, addVel )
	local gaitSize = math.Clamp( 0.4 + 0.03 * walkVel / 100, 0, 1 )

	self.WalkCycle = self.WalkCycle + ( ( 0.05 + 0.03 * walkVel ) * 30 ) * FrameTime()
	self:DoWalkCycle( gaitSize - math.floor( gaitSize ), addVel )
end

// function meta:Think( rate, velMul, addVel )
// 	self.WalkVel = velMul -- lerp( self.WalkVel, velMul, 0.1 ) -- not actually doing anything...
// 	self.WalkCycle = self.WalkCycle + ( ( 0.05 + 0.03 * self.WalkVel / rate ) * 30 ) * FrameTime()

// 	local gaitSize = math.Clamp( 0.4 + 0.03 * self.WalkVel / 100, 0, 1 )
// 	self:DoWalkCycle( gaitSize - math.floor( gaitSize ), addVel )
// end

----------------------------------------------------------------------------------
