----------------------------------------------------------------------------------

local Mech = NML_CreateMechType( "gtb22" )

Mech:SetAuthor( "shadowscion" )

Mech:AddSkin( 0, "Lost Planet - White" )
Mech:AddSkin( 1, "Lost Planet - Red" )
Mech:AddSkin( 2, "Combine Mech" )

----------------------------------------------------------------------------------

if SERVER then

	Mech:SetInit( function( self )

	end )

	Mech:SetThink( function( self )
		local phys = self.Entity:GetPhysicsObject()
		if IsValid( phys ) then
			phys:ApplyForceCenter( ( self.Entity:GetForward() * 100 - phys:GetVelocity() / 5 ) * phys:GetMass() )
		end
	end )

	return

end

----------------------------------------------------------------------------------

if not CLIENT then return end

local NML = NML
local Holo = NML.Hologram
local Helper = NML.Helper

local schematic = {
    {
        parent   = 0,
        model    = "models/nml/lostplanet/gtb22/part_pelvis.mdl",
        position = Vector( 0, 0, 0 ),
    };
    {
        parent   = 1,
        model    = "models/nml/lostplanet/gtb22/part_torso.mdl",
        position = Vector( 7.215, 0, 19.261 ),
    };
    {
        parent   = 2,
        model    = "models/nml/lostplanet/gtb22/part_head.mdl",
        position = Vector( 0, -0.963, 15.754 ),
    };
    {
        parent   = 1,
        model    = "models/nml/lostplanet/gtb22/part_r_plate.mdl",
        position = Vector( -3.417, -13.606, 19.932 ),
    };
    {
        parent   = 1,
        model    = "models/nml/lostplanet/gtb22/part_r_hip.mdl",
        position = Vector( -2.291, -9.182, -2.647 ),
    };
    {
        parent   = 5,
        model    = "models/nml/lostplanet/gtb22/part_r_leg_a.mdl",
        position = Vector( 0, -22.183, 0 ),
    };
    {
        parent   = 6,
        model    = "models/nml/lostplanet/gtb22/part_r_leg_b.mdl",
        position = Vector( -3.842, 0, -29.998 ),
    };
    {
        parent   = 7,
        model    = "models/nml/lostplanet/gtb22/part_r_leg_c.mdl",
        position = Vector( 0, 0, -26.526 ),
    };
    {
        parent   = 8,
        model    = "models/nml/lostplanet/gtb22/part_r_leg_d.mdl",
        position = Vector( 0, 0, -48.312 ),
    };
    {
        parent   = 1,
        model    = "models/nml/lostplanet/gtb22/part_l_plate.mdl",
        position = Vector( -3.417, 13.606, 19.932 ),
    };
    {
        parent   = 1,
        model    = "models/nml/lostplanet/gtb22/part_l_hip.mdl",
        position = Vector( -2.291, 9.182, -2.647 ),
    };
    {
        parent   = 11,
        model    = "models/nml/lostplanet/gtb22/part_l_leg_a.mdl",
        position = Vector( 0, 22.183, 0 ),
    };
    {
        parent   = 12,
        model    = "models/nml/lostplanet/gtb22/part_l_leg_b.mdl",
        position = Vector( -3.842, 0, -29.998 ),
    };
    {
        parent   = 13,
        model    = "models/nml/lostplanet/gtb22/part_l_leg_c.mdl",
        position = Vector( 0, 0, -26.526 ),
    };
    {
        parent   = 14,
        model    = "models/nml/lostplanet/gtb22/part_l_leg_d.mdl",
        position = Vector( 0, 0, -48.312 ),
    };
}

Mech:SetInit( function( self )
	self.Holograms = {}
	self.Holoentity = Holo.CreateEntity()

	for i, info in ipairs( schematic ) do
        local part = Holo.CreateHologram( self.Holoentity )
        local partParent = self.Holograms[info.parent] and self.Holograms[info.parent] or self.Entity

        part:SetParent( partParent )
        part:SetPos( partParent:LocalToWorld( info.position ) )
        part:SetAngles( partParent:LocalToWorldAngles( info.angle or Angle() ) )
        part:SetModel( info.model )
        part:SetMaterial( info.material or nil )

        self.Holograms[i] = part
	end

	self.Holoentity.draw = true

	self.Entity:CallOnRemove( "GarbageDay", function( ent )
		self.Holoentity:Remove()
		self.Holograms = nil

		timer.Simple( 0, function()
			if not IsValid( ent ) then return end
			self:Initialize()
		end )
	end )

	self:AddGait( "Right", Vector( -10, -25, 0 ), 0, 15 )
    self:AddGait( "Left", Vector( -10, 25, 0 ), 0.5, 15 )
    self.HeightDiff = 0
end )

----------------------------------------------------------------------------------

local sin = Helper.Sin
local cos = Helper.Cos
local acos = Helper.Acos
local asin = Helper.Asin
local atan = Helper.Atan
local sign = Helper.Sign
local lerp = Helper.Lerp
local bearing = Helper.Bearing
local toLocalAxis = Helper.ToLocalAxis

local angle = FindMetaTable( "Angle" )

function angle:SetRoll( roll )
    return Angle( self.p, self.y, roll )
end

function angle:SetPitch( pitch )
    return Angle( pitch, self.y, self.r )
end

local function anim( ent, pos, hip, fem, tib, tars, foot, length0, length1, length2, factor )
    length0 = length0 * factor
    length1 = length1 * factor
    length2 = length2 * factor

    local laxis = toLocalAxis( ent, pos - fem:GetPos() )
    local laxisAngle = laxis:Angle():SetRoll( -bearing( fem:GetPos(), ent:GetAngles(), pos ) )
        laxisAngle:RotateAroundAxis( laxisAngle:Right(), 90 + 90 * ( 1 - math.min( 1, laxis:Length() / ( length0 + length2 ) - 0.5 ) ) )

    hip:SetAngles( ent:LocalToWorldAngles( Angle( 0, 0, math.Clamp( laxisAngle.r, -25, 25 ) ) ) )
    fem:SetAngles( ent:LocalToWorldAngles( laxisAngle ) )

    local laxis = toLocalAxis( fem, pos - tib:GetPos() )
    local dist = math.min( laxis:Length(), length1 + length2 - 1 )

    tib:SetAngles( fem:LocalToWorldAngles( Angle( atan( -laxis.z, laxis.x ) + acos( ( dist ^ 2 + length1 ^ 2 - length2 ^ 2 ) / ( 2 * length1 * dist ) ) - 90, 0, 0 ) ) )
    tars:SetAngles( tib:LocalToWorldAngles( Angle( acos( ( length2 ^ 2 + length1 ^ 2 - dist ^ 2 ) / ( 2 * length1 * length2 ) ) + 180, 0, 0 ) ) )
    foot:SetAngles( Angle( 0, ent:GetAngles().y, 0 ) )
end

Mech:SetThink( function( self )
    local vel = self.Entity:GetVelocity()

    self:RunAllGaits( vel:Length() / 1000, vel / 7.5 )

    self.HeightDiff = lerp( self.HeightDiff, math.Clamp( self:GetGaitDiff( "Right", "Left" ), -50, 50 ), 30 * FrameTime() )
    self.Holograms[1]:SetPos( self.Entity:LocalToWorld( Vector( 0, 0, math.abs( self.HeightDiff / 3 ) ) ) )
    self.Holograms[1]:SetAngles( self.Entity:LocalToWorldAngles( Angle( 0, 0, -self.HeightDiff / 3 ) ) )

    self.Holograms[2]:SetAngles( self.Holograms[1]:GetAngles():SetRoll( 0 ) )
    self.Holograms[3]:SetAngles( self.Holograms[2]:GetAngles():SetPitch( math.abs( self.HeightDiff / 3 ) ) )

    self.Holograms[4]:SetAngles( self.Holograms[1]:GetAngles():SetRoll( -math.abs( self.HeightDiff / 4 ) ) )
    self.Holograms[10]:SetAngles( self.Holograms[1]:GetAngles():SetRoll( math.abs( self.HeightDiff / 4 ) ) )

    anim( self.Entity, self.Gaits["Right"].StepCurve, self.Holograms[5], self.Holograms[6],  self.Holograms[7],  self.Holograms[8],  self.Holograms[9],  29.998, 26.526, 48.312, 1 )
    anim( self.Entity, self.Gaits["Left"].StepCurve, self.Holograms[11], self.Holograms[12], self.Holograms[13], self.Holograms[14], self.Holograms[15], 29.998, 26.526, 48.312, 1 )
end )

----------------------------------------------------------------------------------
