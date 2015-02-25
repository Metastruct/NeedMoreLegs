----------------------------------------------------------------------------------

local Mech = NML_CreateMechType( "gtb22" )

Mech:SetAuthor( "shadowscion" )

Mech:AddSkin( 0, "Lost Planet - White" )
Mech:AddSkin( 1, "Lost Planet - Red" )
Mech:AddSkin( 2, "Combine Mech" )

----------------------------------------------------------------------------------

if SERVER then

    local Helper       = NML.Helper
    local divVA        = Helper.DivVA
    local mulVA        = Helper.MulVA
    local bearing2     = Helper.Bearing2
    local ezAngForce   = Helper.EZAngForce
    local getAngVel    = Helper.AngVel
    local rangerOffset = Helper.RangerOffset
    local podEyeTrace  = Helper.PodEyeTrace

    local function Linear( y0, y1, t )
        return y0 + t * ( y1 - y0 )
    end
    local function Cosine( y0, y1, t )
        return Linear( y0, y1, -math.cos( math.pi * t ) / 2 + 0.5 )
    end

    Mech:SetInit( function( self )
        self.Walk = 0
        self.Strafe = 0
    end )

    Mech:SetThink( function( self )
        local phys = self.Entity:GetPhysicsObject()
        if not IsValid( phys ) then return end

        local aim
        local w, a, s, d = 0, 0, 0, 0
        if IsValid( self.Vehicle ) and IsValid( self.Vehicle:GetDriver() ) then
            if self.Entity:GetPilot() ~= self.Vehicle:GetDriver() then self.Entity:SetPilot( self.Vehicle:GetDriver() ) end

            w = self.Vehicle:GetDriver():KeyDown( IN_FORWARD ) and 1 or 0
            a = self.Vehicle:GetDriver():KeyDown( IN_MOVELEFT ) and 1 or 0
            s = self.Vehicle:GetDriver():KeyDown( IN_BACK ) and 1 or 0
            d = self.Vehicle:GetDriver():KeyDown( IN_MOVERIGHT ) and 1 or 0

            aim = podEyeTrace( self.Vehicle:GetDriver() ).HitPos
        else
            aim = self.Entity:GetPos() + self.Entity:GetForward() * 100
            if self.Entity:GetPilot() ~= nil then self.Entity:SetPilot( nil ) end
        end

        self.Walk = Cosine( self.Walk, w - s, 0.1 )
        self.Strafe = Cosine( self.Strafe, d - a, 0.1 )

        local hover = rangerOffset( 150, self.Entity:GetPos(), Vector( 0, 0, -1 ), { self.Entity, self.Vehicle, self.Vehicle:GetDriver() } )
        if hover.Hit then
            local dist = hover.HitPos:Distance( phys:GetPos() )

            local forceu = Vector( 0, 0, 100 - dist ) * 5 - divVA( phys:GetVelocity(), Vector( 20, 20, 5 ) )
            local forcef = self.Entity:GetForward() * ( 15 * self.Walk )
            local forcer = self.Entity:GetRight() * ( 7.5 * self.Strafe )

            phys:EnableGravity( false )
            phys:ApplyForceCenter( ( forceu + forcef + forcer ) * phys:GetMass() )

            local turnTo = bearing2( self.Entity, aim, 10, ( w + a + s + d ) ~= 0 )
            ezAngForce( self.Entity, self.Entity:WorldToLocalAngles( Angle( 0, turnTo, 0 ) ) * 200, 20 )
        else
            phys:EnableGravity( true )
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

    self.AngVel = self.Entity:GetAngles()
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
local podEyeTrace = Helper.PodEyeTrace

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

    local aim = Vector()
    local w, a, s, d = 0, 0, 0, 0
    if IsValid( self.Entity:GetPilot() ) then
        self.Entity:GetPilot():SetNoDraw( true )
        aim = podEyeTrace( self.Entity:GetPilot() ).HitPos

        w = self.Entity:GetPilot():KeyDown( IN_FORWARD ) and 1 or 0
        a = self.Entity:GetPilot():KeyDown( IN_MOVELEFT ) and 1 or 0
        s = self.Entity:GetPilot():KeyDown( IN_BACK ) and 1 or 0
        d = self.Entity:GetPilot():KeyDown( IN_MOVERIGHT ) and 1 or 0
    else
        aim = self.Entity:GetPos() + self.Entity:GetForward() * 100
    end



    --local angVel = ( self.Entity:GetAngles() - self.AngVel ) * ( 1 / FrameTime() )
    local angVel = ( self.Entity:GetAngles() - self.AngVel ) * ( 1 / 66.666667 )
    self.AngVel = self.Entity:GetAngles()

    self:RunAllGaits( ( vel:Length() + math.abs( angVel.y ) ) / 750, vel / 4 )

    self.HeightDiff = lerp( self.HeightDiff, math.Clamp( self:GetGaitDiff( "Right", "Left" ), -50, 50 ), 0.5 )
    self.Holograms[1]:SetPos( self.Entity:LocalToWorld( Vector( 0, -self.HeightDiff / 5, math.abs( self.HeightDiff / 2 ) ) ) )
    self.Holograms[1]:SetAngles( self.Entity:LocalToWorldAngles( Angle( 0, 0, -self.HeightDiff / 3 ) ) )

    self.Holograms[2]:SetAngles( self.Holograms[1]:GetAngles():SetRoll( 0 ) )
    self.Holograms[3]:SetAngles( ( ( aim or Vector() ) - self.Holograms[3]:GetPos() ):Angle() )

    self.Holograms[4]:SetAngles( self.Holograms[1]:GetAngles():SetRoll( -math.abs( self.HeightDiff / 4 ) ) )
    self.Holograms[10]:SetAngles( self.Holograms[1]:GetAngles():SetRoll( math.abs( self.HeightDiff / 4 ) ) )

    anim( self.Entity, self.Gaits["Right"].StepCurve, self.Holograms[5], self.Holograms[6],  self.Holograms[7],  self.Holograms[8],  self.Holograms[9],  29.998, 26.526, 48.312, 1 )
    anim( self.Entity, self.Gaits["Left"].StepCurve, self.Holograms[11], self.Holograms[12], self.Holograms[13], self.Holograms[14], self.Holograms[15], 29.998, 26.526, 48.312, 1 )
end )

----------------------------------------------------------------------------------
