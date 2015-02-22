
----------------------------------------------------------------------------------

--[[
	Mech & Gait System ( ported from my e2 collection )
	by shadowscion

	credits:
		• Metamist - lua help and coming up with the gait timing system
		• OmicroN - a lot of e2 help over the years that made much of this possible
		• Ruadhan - for getting me started with gmod mechs in the first place
]]--

collectgarbage( "collect" )

----------------------------------------------------------------------------------
--- Mech System
----------------------------------------------------------------------------------

local Mech = {}
Mech.__index = Mech

function NML_AddMechType( name )
	local self = {}

	setmetatable( self, Mech )

	self.Name = name

	list.Set( "NML_Mechs", name, self )

	return self
end

function NML_GetMechType( name )
	local types = list.Get( "NML_Mechs" )
	if not types[name] then return {} end
	return table.Copy( types[name] )
end

----------------------------------------------------------------------------------

function Mech:SetInit( initFunc )
	self.Initialize = function( self )
		if not self.Name then return end
		if not self.Entity or not IsValid( self.Entity ) then return end

		initFunc( self )

		self.hookid = self.Name .. self.Entity:EntIndex()
		self:StartThink()
	end
end

function Mech:SetThink( thinkFunc )
	self.Think = thinkFunc
end

function Mech:SetEntity( entity )
	if type( entity ) ~= "Entity" then return end
	self.Entity = entity
end

function Mech:SetPlayer( player )
	if type( player ) ~= "Player" then return end
	self.Player = player
end

function Mech:SetSkin( skinid )
	if not self.skins then return end
	if not self.skins[skinid] then return end
	self.skin = skinid
end

----------------------------------------------------------------------------------

function Mech:StopThink()
	if not self.hookid then return end
	hook.Remove( "Think", "NML_Think_" .. self.hookid )
end

function Mech:StartThink()
	if not self.hookid then return end

	self:StopThink()
	hook.Add( "Think", "NML_Think_" .. self.hookid, function()
		if not self.Think then self:StopThink() return end
		if not self.Entity or not IsValid( self.Entity ) then self:StopThink() return end

		self:Think()
	end )
end

----------------------------------------------------------------------------------

function Mech:AddSkin( name, skinid )
	self.Skins = self.Skins or {}
	self.Skins[skinid] = name
end

function Mech:AddGait( name, offset, order )
	self.Gaits = self.Gaits or {}
	self.Gaits[name] = NML_CreateNewGait( self.Entity, offset, order )
end

function Mech:RunAllGaits( rate, velMul, addVel )
	for _, gait in pairs( self.Gaits or {} ) do
		gait:Think( rate, velMul, addVel )
	end
end

function Mech:GetGait( name )
	if not self.Gaits or not self.Gaits[name] then return end
	return self.Gaits[name]
end

function Mech:GetGaitPos( name )
	return self:GetGait( name ).StepCurve or Vector()
end

----------------------------------------------------------------------------------
--- Gait System
----------------------------------------------------------------------------------

local lerp = NML.Helper.Lerp
local bezier = NML.Helper.Bezier
local rangerOffset = NML.Helper.RangerOffset

local Gait = {}
Gait.__index = Gait

function NML_CreateNewGait( entity, offset, order )
	if not entity or not offset or not order then return end
	if not type( entity ) == "Entity" or not type( offset ) == "Vector" or not type( order ) == "Number" then return end

	local self = {}

	setmetatable( self, Gait )

	-- gait info
	self.Entity = entity
	self.Offset = offset

	-- gait data
	local trace = rangerOffset( 500, entity:LocalToWorld( offset ), -entity:GetUp(), entity )
	local initv = trace.HitPos + trace.HitNormal * 15

	self.StepPointA = initv
	self.StepPointB = initv
	self.StepPointC = initv
	self.StepCurve  = initv

	self.StepStart = order - math.floor( order )
	self.StepState = 0

	-- walk cycle
	self.WalkCycle = 0
	self.WalkVel = 0

	return self
end

----------------------------------------------------------------------------------

function Gait:DoWalkAnimation( active, interp, addVel )
	if active then
		if self.StepState == 0 then
			local traceA = rangerOffset( self.Entity:GetPos(), self.Entity:LocalToWorld( self.Offset ), self.Entity ).HitPos
			local traceB = rangerOffset( traceA, traceA + addVel, self.Entity )
			local traceC = rangerOffset( 500, traceB.HitPos, -self.Entity:GetUp(), self.Entity )

			local traceD   = traceB.Hit and traceB or traceC
			local distance = self.StepPointC:Distance( traceD.HitPos )

			if distance > 15 then
				self.StepPointA = self.StepPointC
				self.StepPointC = traceD.HitPos
				self.StepPointB = ( self.StepPointA + self.StepPointC ) / 2 + traceD.HitNormal * math.Clamp( distance / 2, 10, 50 )
				self.StepState  = 1
			else
				self.StepState = -1
			end
		elseif self.StepState == 1 then
			local traceA = rangerOffset( self.Entity:GetPos(), self.Entity:LocalToWorld( self.Offset ), self.Entity ).HitPos
			local traceB = rangerOffset( traceA, traceA + addVel, self.Entity )
			local traceC = rangerOffset( 500, traceB.HitPos, -self.Entity:GetUp(), self.Entity )

			self.StepPointC = traceB.Hit and traceB.HitPos + traceB.HitNormal * 15 or traceC.HitPos + traceC.HitNormal * 15
			self.StepCurve  = bezier( self.StepPointA, self.StepPointB, self.StepPointC, interp )
		end
	elseif self.StepState ~= 0 then
		self.StepState = 0
		self.StepCurve  = self.StepPointC
	end
end

----------------------------------------------------------------------------------

function Gait:DoWalkCycle( gaitSize, addVel )
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

function Gait:Think( rate, velMul, addVel )
	self.WalkVel   = lerp( self.WalkVel, velMul, 0.1 * FrameTime() )
	self.WalkCycle = self.WalkCycle + ( ( 0.05 + 0.03 * self.WalkVel / rate ) * 30 ) * FrameTime()

	local gaitSize = math.Clamp( 0.4 + 0.03 * self.WalkVel / 100, 0, 0.9 )
	self:DoWalkCycle( gaitSize - math.floor( gaitSize ), addVel )
end

----------------------------------------------------------------------------------
