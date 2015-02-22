
----------------------------------------------------------------------------------

NML = NML or {}

local NML = NML
local Holo = NML.Hologram
local Gait = NML.GaitSystem

----------------------------------------------------------------------------------

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

----------------------------------------------------------------------------------

NML.Soul = {}
local Soul = NML.Soul

----------------------------------------------------------------------------------

-- Builds the model from the schematic
function Soul.Summon( self, scale, shading, skin )
    if not IsValid( self ) then return end
    if self:GetClass() ~= "sent_nml_gtb22" then return end

    Soul.Entity = self

    if self.carcass then self.carcass:Remove() end

    self.form = {} -- a table holding all of the hologram parts
    self.carcass = Holo.CreateEntity() -- a csent to draw from

    self.property_scale = scale or self.property_scale or 1
    self.property_shading = shading or self.property_shading or false
    self.property_skin = skin or self.property_skin or nil

    for i, info in ipairs( schematic ) do
        local part = Holo.CreateHologram( self.carcass )
        local partParent = self.form[info.parent] and self.form[info.parent] or self

        part:SetParent( partParent )
        part:SetPos( partParent:LocalToWorld( info.position * self.property_scale ) )
        part:SetAngles( partParent:LocalToWorldAngles( info.angle or Angle() ) )
        part:SetModel( info.model )
        part:SetMaterial( info.material or nil )
        part:SetScale( Vector( self.property_scale, self.property_scale, self.property_scale ) )
        part:SetDisableShading( self.property_shading )
        part:SetSkin( self.property_skin )

        self.form[i] = part
    end

    self.carcass.draw = true

    timer.Simple( 0.25, function() Soul.Convene( self ) end )
end

-- Activates the mech
function Soul.Convene( self )
    Soul.CreateGaits( self )

    self:CallOnRemove( "GarbageDay", function( ent )
        ent.carcass:Remove()
        ent.form  = nil
        ent.gaits = nil

        hook.Remove( "Think", "nml_thinkhook_id_" .. ent:EntIndex() )

        timer.Simple( 0, function()
            if not IsValid( ent ) then return end
            Soul.Summon( ent )
        end )
    end )

    hook.Add( "Think", "nml_thinkhook_id_" .. self:EntIndex(), Soul.Think or function() end )
end

----------------------------------------------------------------------------------

function Soul.CreateGaits( self )
    if not Soul.Entity then return end

    Soul.Entity.gaits = {}
    Soul.Entity.gaits["RF"] = Gait.New( "RF", self, Vector( -10, -25, 0 ), 0 )
    Soul.Entity.gaits["LF"] = Gait.New( "LF", self, Vector( -10, 25, 0 ), 0.5 )
end

function Soul.SetSkin( skin )
    if not Soul.Entity then return end
    if not Soul.Entity.form then return end

    for _, part in pairs( Soul.Entity.form ) do
        part:SetSkin( skin or self.property_skin or 0 )
    end
end

----------------------------------------------------------------------------------

local sin = Gait.Sin
local cos = Gait.Cos
local acos = Gait.Acos
local asin = Gait.Asin
local atan = Gait.Atan
local sign = Gait.Sign
local bearing = Gait.Bearing
local toLocalAxis = Gait.ToLocalAxis

local function anim( ent, pos, hip, fem, tib, tars, foot, length0, length1, length2, factor )
    length0 = length0 * factor
    length1 = length1 * factor
    length2 = length2 * factor

    local laxis = toLocalAxis( ent, pos - fem:GetPos() )
    local laxisAngle = laxis:Angle()
        laxisAngle.r = -bearing( fem:GetPos(), ent:GetAngles(), pos )
        laxisAngle:RotateAroundAxis( laxisAngle:Right(), 90 + 90 * ( 1 - math.min( 1, laxis:Length() / ( length0 + length2 ) - 0.5 ) ) )

    hip:SetAngles( ent:LocalToWorldAngles( Angle( 0, 0, math.Clamp( laxisAngle.r, -30, 30 ) ) ) )
    fem:SetAngles( ent:LocalToWorldAngles( laxisAngle ) )

    local laxis = toLocalAxis( fem, pos - tib:GetPos() )
    local dist = math.min( laxis:Length(), length1 + length2 - 0.001 )

    tib:SetAngles( fem:LocalToWorldAngles( Angle( atan( -laxis.z, laxis.x ) + acos( ( dist ^ 2 + length1 ^ 2 - length2 ^ 2 ) / ( 2 * length1 * dist ) ) - 90, 0, 0 ) ) )
    tars:SetAngles( tib:LocalToWorldAngles( Angle( acos( ( length2 ^ 2 + length1 ^ 2 - dist ^ 2 ) / ( 2 * length1 * length2 ) ) + 180, 0, 0 ) ) )
    foot:SetAngles( Angle( 0, ent:GetAngles().y, 0 ) )
end

function Soul.Think()
    if not IsValid( Soul.Entity ) then return end

    local holos = Soul.Entity.form
    local gaits = Soul.Entity.gaits

    if not holos or not gaits then return end

    -- Gait System & Inverse Kinematics
    local vel = Soul.Entity:GetVelocity()
    gaits["RF"]:Think( 200, vel:Length() / 5, vel / 5 )
    gaits["LF"]:Think( 200, vel:Length() / 5, vel / 5 )

    anim( Soul.Entity, gaits["RF"].stepPos, holos[5],  holos[6],  holos[7],  holos[8],  holos[9],  29.998, 26.526, 48.312, Soul.Entity.property_scale )
    anim( Soul.Entity, gaits["LF"].stepPos, holos[11], holos[12], holos[13], holos[14], holos[15], 29.998, 26.526, 48.312, Soul.Entity.property_scale )
end

----------------------------------------------------------------------------------
