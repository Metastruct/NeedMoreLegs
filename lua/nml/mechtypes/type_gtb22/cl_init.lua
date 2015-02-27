------------------------------------------------------------------------
---- GTB-22
---- Clientside File
------------------------------------------------------------------------

if not CLIENT then return end

local Mech = NML_CreateMechType( "gtb22" )

local schematic = {
    {
        Parent   = 0,
        Model    = "models/nml/lostplanet/gtb22/part_pelvis.mdl",
        Position = Vector( 0, 0, 0 ),
    };
    {
        Parent   = 1,
        Model    = "models/nml/lostplanet/gtb22/part_torso.mdl",
        Position = Vector( 7.215, 0, 19.261 ),
    };
    {
        Parent   = 2,
        Model    = "models/nml/lostplanet/gtb22/part_head.mdl",
        Position = Vector( 0, -0.963, 15.754 ),
    };
    {
        Parent   = 1,
        Model    = "models/nml/lostplanet/gtb22/part_r_plate.mdl",
        Position = Vector( -3.417, -13.606, 19.932 ),
    };
    {
        Parent   = 1,
        Model    = "models/nml/lostplanet/gtb22/part_r_hip.mdl",
        Position = Vector( -2.291, -9.182, -2.647 ),
    };
    {
        Parent   = 5,
        Model    = "models/nml/lostplanet/gtb22/part_r_leg_a.mdl",
        Position = Vector( 0, -22.183, 0 ),
    };
    {
        Parent   = 6,
        Model    = "models/nml/lostplanet/gtb22/part_r_leg_b.mdl",
        Position = Vector( -3.842, 0, -29.998 ),
    };
    {
        Parent   = 7,
        Model    = "models/nml/lostplanet/gtb22/part_r_leg_c.mdl",
        Position = Vector( 0, 0, -26.526 ),
    };
    {
        Parent   = 8,
        Model    = "models/nml/lostplanet/gtb22/part_r_leg_d.mdl",
        Position = Vector( 0, 0, -48.312 ),
    };
    {
        Parent   = 1,
        Model    = "models/nml/lostplanet/gtb22/part_l_plate.mdl",
        Position = Vector( -3.417, 13.606, 19.932 ),
    };
    {
        Parent   = 1,
        Model    = "models/nml/lostplanet/gtb22/part_l_hip.mdl",
        Position = Vector( -2.291, 9.182, -2.647 ),
    };
    {
        Parent   = 11,
        Model    = "models/nml/lostplanet/gtb22/part_l_leg_a.mdl",
        Position = Vector( 0, 22.183, 0 ),
    };
    {
        Parent   = 12,
        Model    = "models/nml/lostplanet/gtb22/part_l_leg_b.mdl",
        Position = Vector( -3.842, 0, -29.998 ),
    };
    {
        Parent   = 13,
        Model    = "models/nml/lostplanet/gtb22/part_l_leg_c.mdl",
        Position = Vector( 0, 0, -26.526 ),
    };
    {
        Parent   = 14,
        Model    = "models/nml/lostplanet/gtb22/part_l_leg_d.mdl",
        Position = Vector( 0, 0, -48.312 ),
    };
}

Mech:SetInit( function( self )
    -- Load the model
    self:LoadModelFromData( schematic )

    -- Setup gaits
    self:AddLeg( "Right", Vector( -10, -25, 0 ), 0, 15 )
    self:AddLeg( "Left", Vector( -10, 25, 0 ), 0.5, 15 )

    -- Setup initial values
    self.OldAngles  = self.Entity:GetAngles()
    self.HeightDiff = 0
end )

local math = math

local Helper         = NML.Helper
local lerp           = Helper.CLerp
local acos           = Helper.Acos
local atan           = Helper.Atan
local bearing        = Helper.Bearing
local toLocalAxis    = Helper.ToLocalAxis
local podEyeTrace    = Helper.PodEyeTrace
local traceToVector  = Helper.TraceToVector
local traceDirection = Helper.TraceDirection

local function legIK( ent, pos, hip, fem, tib, tars, foot, length0, length1, length2, factor )
    length0 = length0*factor
    length1 = length1*factor
    length2 = length2*factor

    local laxis = toLocalAxis( ent, pos - fem:GetPos() )
    local laxisAngle = laxis:Angle()
        laxisAngle.r = -bearing( fem:GetPos(), ent:GetAngles(), pos )
        laxisAngle:RotateAroundAxis( laxisAngle:Right(), 90 + 90*( 1 - math.min( 1, laxis:Length()/( length0 + length2 ) - 0.5 ) ) )

    hip:SetAngles( ent:LocalToWorldAngles( Angle( 0, 0, math.Clamp( laxisAngle.r, -25, 25 ) ) ) )
    fem:SetAngles( ent:LocalToWorldAngles( laxisAngle ) )

    local laxis = toLocalAxis( fem, pos - tib:GetPos() )
    local dist = math.min( laxis:Length(), length1 + length2 - 1 )

    tib:SetAngles( fem:LocalToWorldAngles( Angle( atan( -laxis.z, laxis.x ) + acos( ( dist^2 + length1^2 - length2^2 )/( 2*length1*dist ) ) - 90, 0, 0 ) ) )
    tars:SetAngles( tib:LocalToWorldAngles( Angle( acos( ( length2^2 + length1^2 - dist^2 )/( 2*length1*length2 ) ) + 180, 0, 0 ) ) )

    foot:SetAngles( Angle( 0, ent:GetAngles().y, 0 ) )
end

Mech:SetThink( function( self )
    if not self.CSHolobase then return end
    if not self.CSHolobase.draw then return end
    if not self.CSHolograms then return end

    -- Setup Vars
    local holo   = self.CSHolograms
    local entity = self.Entity
    local aimPos = Vector()
    local angles = entity:GetAngles()
    local vel = entity:GetVelocity()
    local w, a, s, d = 0, 0, 0, 0

    if IsValid( self:GetDriver() ) then
        aimPos = podEyeTrace( self:GetDriver() ).HitPos

        w = self:GetDriver():KeyDown( IN_FORWARD ) and 1 or 0
        a = self:GetDriver():KeyDown( IN_MOVELEFT ) and 1 or 0
        s = self:GetDriver():KeyDown( IN_BACK ) and 1 or 0
        d = self:GetDriver():KeyDown( IN_MOVERIGHT ) and 1 or 0
    else
        aimPos = entity:GetPos() + entity:GetForward()*100
    end

    local aimAngle = ( ( aimPos or Vector() ) - entity:GetPos() ):Angle()
    aimAngle:Normalize()

    -- Clientside angular velocity workaround
    local angVel   = ( entity:GetAngles() - self.OldAngles )*66.6666667
    self.OldAngles = entity:GetAngles()

    -- Run the leg walk cycles
    self:RunAllLegs( ( vel:Length() + math.abs( angVel.y / 3 ) )/750, vel/4 )

    -- Animate the pelvis
    self.HeightDiff = lerp( self.HeightDiff, math.Clamp( self:GetLegDiff( "Right", "Left" ), -50, 50 ), 0.5 )

    holo[1]:SetPos( entity:LocalToWorld( Vector( 0, -self.HeightDiff/5, aimAngle.p/5 + math.abs( self.HeightDiff/2 ) ) ) )
    holo[1]:SetAngles( entity:LocalToWorldAngles( Angle( 0, 0, -self.HeightDiff/3 ) ) )

    -- Animate the torso and head
    local headAngle = holo[2]:WorldToLocalAngles( LerpAngle( 0.05, holo[3]:GetAngles(), aimAngle ) )
    holo[3]:SetAngles( holo[2]:LocalToWorldAngles( Angle( math.Clamp( headAngle.p, -35, 25 ), headAngle.y, headAngle.r ) ) )

    holo[4]:SetAngles( holo[1]:LocalToWorldAngles( Angle( 0, 0, -math.abs( self.HeightDiff/4 ) ) ) )
    holo[10]:SetAngles( holo[1]:LocalToWorldAngles( Angle( 0, 0, math.abs( self.HeightDiff/4 ) ) ) )

    -- Animate the legs
    legIK( entity, self.Legs["Right"].StepCurve, holo[5], holo[6],  holo[7],  holo[8],  holo[9],  29.998, 26.526, 48.312, 1 )
    legIK( entity, self.Legs["Left"].StepCurve, holo[11], holo[12], holo[13], holo[14], holo[15], 29.998, 26.526, 48.312, 1 )
end )


    --[[local torsoAngle = self.CSHolograms[1]:WorldToLocalAngles( LerpAngle( 0.05, self.CSHolograms[2]:GetAngles(), aimAngle ) )
        self.CSHolograms[2]:SetAngles( self.CSHolograms[1]:LocalToWorldAngles( Angle( 0, torsoAngle.y, self.HeightDiff/3 ) ) )

        local headAngle =self.CSHolograms[2]:WorldToLocalAngles( LerpAngle( 0.05, self.CSHolograms[3]:GetAngles(), aimAngle ) )
        self.CSHolograms[3]:SetAngles( self.CSHolograms[2]:LocalToWorldAngles( Angle( math.Clamp( headAngle.p, -30, 15 ), 0, 0 ) ) )]]--
