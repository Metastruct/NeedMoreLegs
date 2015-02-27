------------------------------------------------------
---- Walkcycle Class
---- by shadowscion & Metamist
------------------------------------------------------

local util  = util
local math  = math
local sound = sound

local Helper         = NML.Helper
local bezier         = Helper.Bezier
local traceToVector  = Helper.TraceToVector
local traceDirection = Helper.TraceDirection

--- Walkcycle Meta Object
-- @section

local WalkCycle = {}
WalkCycle.__index = WalkCycle

--- Create a new walkcycle
-- @function NML_NewWalkCycle
-- @tparam Entity Entity You must attach the walk cycle to a valid entity
-- @tparam Vector Offset A vector local to the entity, this is where the cycle originates from
-- @tparam Number StepOrder A number ( usually 0-1 ) designating in which order the step will occur
-- @tparam Number GroundHeight How far off the ground the step will end
-- @return WalkCycle
-- @usage local WalkCycle = NML_CreateWalkCycle( Entity( 50 ), Vector(), 0.5, 25 )
function NML_CreateNewWalkCycle( entity, offset, stepOrder, groundHeight )
    if not IsValid( entity ) or not offset or not stepOrder then return end
    if not type( entity ) == "Entity" or not type( offset ) == "Vector" or not type( stepOrder ) == "Number" then return end

    local self = {}

    setmetatable( self, WalkCycle )

    self.Entity = entity
    self.Offset = offset
    self.GroundHeight = groundHeight or 0

    local trace = traceDirection( 500, entity:LocalToWorld( offset ), -entity:GetUp(), nil, MASK_SOLID_BRUSHONLY )
    local start = trace.HitPos + trace.HitNormal*self.GroundHeight

    self.StepPointA = start
    self.StepPointB = start
    self.StepPointC = start
    self.StepCurve  = start

    self.StepStart = stepOrder - math.floor( stepOrder )
    self.StepState = 0
    self.WalkCycle = 0

    return self
end

--- Walkcycle Meta Functions
-- @section

--- Step animation function
-- @function WalkCycle:DoWalkAninimation
-- @tparam Bool Active
-- @tparam Number Interp
-- @tparam Vector AddVelocity
function WalkCycle:DoWalkAnimation( active, interp, addVel )
    if active then
        if self.StepState == 0 then
            local traceA = traceToVector( self.Entity:GetPos(), self.Entity:LocalToWorld( self.Offset ), self.Entity ).HitPos
            local traceB = traceToVector( traceA, traceA + addVel, self.Entity )
            local traceC = traceDirection( 500, traceB.HitPos, -self.Entity:GetUp(), self.Entity )

            local traceD   = traceB.Hit and traceB or traceC
            local distance = self.StepPointC:Distance( traceD.HitPos )

            --if distance > 15 + math.Min( addVel:Length(), self.GroundHeight ) then
            if distance > 15 + self.GroundHeight then
                sound.Play( "nml/servo.wav", self.StepPointA, 75, 75 + addVel:Length()/25 + math.random( -10, 10 ) )

                self.StepPointA = self.StepPointC
                self.StepPointC = traceD.HitPos + traceD.HitNormal*self.GroundHeight
                self.StepPointB = ( self.StepPointA + self.StepPointC )/2 + traceD.HitNormal*( math.Clamp( distance/2, 10, 50 ) + self.GroundHeight*0 )
                self.StepState  = 1
            else
                self.StepState = -1
            end
        elseif self.StepState == 1 then
            local traceA = traceToVector( self.Entity:GetPos(), self.Entity:LocalToWorld( self.Offset ), self.Entity ).HitPos
            local traceB = traceToVector( traceA, traceA + addVel, self.Entity )
            local traceC = traceDirection( 500, traceB.HitPos, -self.Entity:GetUp(), self.Entity )

            self.StepPointC = traceB.Hit and traceB.HitPos + traceB.HitNormal*self.GroundHeight or traceC.HitPos + traceC.HitNormal*self.GroundHeight
            self.StepCurve  = bezier( self.StepPointA, self.StepPointB, self.StepPointC, interp )
        end
    elseif self.StepState ~= 0 then
        self.StepState = 0
        if self.StepCurve ~= self.StepPointC then
            if LocalPlayer():GetPos():Distance( self.StepPointC ) < 500 then
                util.ScreenShake( self.StepPointC, 5, 5, 0.25, 25 )
            end
            self.StepCurve = self.StepPointC
        end
    end
end

--- Runs the walkcycle timing ( handled internally, do not call )
-- @function WalkCycle:DoWalkCycle
-- @tparam Number WalkSize
-- @tparam Vector AddVelocity How far the step will jump from it's current position
function WalkCycle:DoWalkCycle( gaitSize, addVel )
    local interp   = 0
    local active   = false
    local stepStop = self.StepStart + gaitSize

    if self.WalkCycle >= self.StepStart and self.WalkCycle <= stepStop then
        interp = ( self.WalkCycle - self.StepStart )/( stepStop - self.StepStart )
        active = true
    end

    if self.StepStart < 0 then
        if self.WalkCycle >= math.abs( self.StepStart ) and self.WalkCycle <= 1 then
            interp = ( self.WalkCycle - self.StepStart )/( stepStop - self.StepStart )
            active = true
        end
    elseif stepStop > 1 then
        if self.WalkCycle + 1 >= self.StepStart and self.WalkCycle + 1 <= stepStop then
            interp = ( self.WalkCycle + 1 - self.StepStart )/( stepStop - self.StepStart )
            active = true
        end
    end

    self:DoWalkAnimation( active, interp, addVel )

    if self.WalkCycle > 1 then self.WalkCycle = self.WalkCycle - 1 end
end

--- Runs the entire walkcycle
-- @function WalkCycle:Think
-- @tparam Number WalkVel How fast the cycle runs
-- @tparam Vector AddVel How far the step will jump from it's current position
-- @usage WalkCycle:Think( Entity:GetVelocity():Length()/100, Entity:GetVelocity()/10 )
function WalkCycle:Think( walkVel, addVel )
    local gaitSize = 0.5 -- math.Clamp( 0.4 + 0.03*walkVel/100, 0, 1 )
    local add = math.Max( 0.05, math.Round( ( 1 - walkVel )/25, 2 ) )

    self.WalkCycle = self.WalkCycle + ( ( add + 0.03*walkVel )*20 )*FrameTime()
    --self.WalkCycle = self.WalkCycle + ( ( 0.05 + 0.03*walkVel )*20 )*FrameTime()
    self:DoWalkCycle( gaitSize - math.floor( gaitSize ), addVel )
end
