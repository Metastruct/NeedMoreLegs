------------------------------------------------------
---- GTB-22 - Clientside File
---- by shadowscion
------------------------------------------------------

local Addon = NML or {}

local math = math
local table = table
local string = string

local Helper         = Addon.Helper

local lerp           = Helper.Lerp
local sin            = Helper.Sin
local cos            = Helper.Cos
local acos           = Helper.Acos
local atan           = Helper.Atan
local bearing        = Helper.Bearing
local clampAng = Helper.ClampAng
local toLocalAxis    = Helper.ToLocalAxis
local podEyeTrace    = Helper.PodEyeTrace
local traceToVector  = Helper.TraceToVector
local traceDirection = Helper.TraceDirection

------------------------------------------------------

local Mech = Addon.CreateMechType( "type_gtb22", "nml_mechtypes" )

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
    {
        Parent   = 3,
        Model    = "models/nml/lostplanet/weapons/part_grenadelauncher.mdl",
        Position = Vector( -10, -32, 32.5 )
    };
    {
        Parent   = 3,
        Model    = "models/nml/lostplanet/weapons/part_rocketlauncher.mdl",
        Position = Vector( -10, 32, 32.5 )
    };
}

------------------------------------------------------

Mech:SetInitialize( function( self, ent )
    self:LoadModelFromData( schematic )
    self:CreateGait( "L", Vector( -10, 25, 0 ), 29.998 + 26.526 + 48.312 + 100 )
    self:CreateGait( "R", Vector( -10, -25, 0 ), 29.998 + 26.526 + 48.312 + 100 )

    self.Height = 300
    self.Crouch = 0
    self.Seed = CurTime() + math.random( -180, 180 )

    self.VelMul = 15
    self.PZ = 0
    self.WalkDelta = 0
    self.OldWalkCycle = 0

    self:AddGaitDebugBar( 64, 64, 96, 96*4 )
end )

------------------------------------------------------

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

    --local atn = laxisAngle.p
    --local ang = ( math.abs( atn ) > 150 and math.abs( atn ) < 180 ) and 180 or ( atn < 0 ) and atn or 180
    --foot:SetAngles( Angle( ang + 45, ent:GetAngles().y, 0 ) )
    foot:SetAngles( Angle( 0, ent:GetAngles().y, 0 ) )
end

Mech:SetThink( function( self, ent, veh, ply, dt )
    if not self.CSHolobase then return end
    if not self.CSHolograms then return end

    -- Setup Inputs
    local aimPos = Vector()
    local w, a, s, d = 0, 0, 0, 0
    local ctrl, space, shift = 0, 0, 0

    if IsValid( ply ) then
        w = ply:KeyDown( IN_FORWARD ) and 1 or 0
        a = ply:KeyDown( IN_MOVELEFT ) and 1 or 0
        s = ply:KeyDown( IN_BACK ) and 1 or 0
        d = ply:KeyDown( IN_MOVERIGHT ) and 1 or 0

        ctrl = ply:KeyDown( IN_DUCK ) and 1 or 0

        aimPos = podEyeTrace( ply ).HitPos
    else
        aimPos = ent:GetPos() + ent:GetForward()*200 - Vector( 0, 0, 25 )
    end

    -- Run Gait Sequence
    local vel = ent:GetVelocity()
    vel.z = 0

    self.WalkVel = lerp( self.WalkVel, vel:Length(), 0.1 )
    local multiplier = self.WalkVel/1000


    self.WalkCycle = self.WalkCycle + ( 0.05 + 0.03*multiplier )*dt*self.VelMul
    self.WalkDelta = self.WalkCycle - self.OldWalkCycle
    self.OldWalkCycle = self.WalkCycle

    local gaitSize = math.Clamp( 0.4 + 0.03*multiplier, 0, 0.9 )

    self:SetGaitStart( "L", 0, gaitSize )
    self:SetGaitStart( "R", 0.5, gaitSize )
    self:RunGaitSequence()

    -- Animate holograms
    local holo = self.CSHolograms

    local time = CurTime() + self.Seed
    local stime = sin( time*100 )*2
    local ctime = cos( time*100 )*2

    self.Crouch = lerp( self.Crouch, ctrl*20, 0.15 )

    -- Pelvis
    --local ppos = ent:GetPos()
    --ppos.z = ( self.Gaits["R"].FootData.Pos.z + self.Gaits["L"].FootData.Pos.z )/2 + 90
    --holo[1]:SetPos( ppos )

    local diff = self.Gaits["R"].FootData.Height - self.Gaits["L"].FootData.Height
    --local diff = -sin( self.WalkCycle*360 )*25

    holo[1]:SetPos( ent:LocalToWorld( Vector( 0, 0, math.abs( diff/2 ) - ctime - self.Crouch ) ) )
    holo[1]:SetAngles( ent:LocalToWorldAngles( Angle( -stime + self.Crouch, 0, -diff/3*0 ) ) )

    -- Torso
    holo[4]:SetAngles( holo[1]:LocalToWorldAngles( Angle( 0, 0, -math.abs( diff/4 ) - ctime + 10 ) ) )
    holo[10]:SetAngles( holo[1]:LocalToWorldAngles( Angle( 0, 0, math.abs( diff/4 ) + ctime - 10 ) ) )

    -- Head
    local headCAng = holo[3]:GetAngles()
    local headTAng = ( ( aimPos or Vector() ) - holo[3]:GetPos() ):Angle()
    headTAng:Normalize()

    local headTPitch = math.ApproachAngle( headCAng.p, headTAng.p, dt*75 )
    local headTYaw = math.ApproachAngle( headCAng.y, headTAng.y, dt*75 )

    headTAng = holo[2]:WorldToLocalAngles( Angle( headTPitch, headTYaw, 0 ) )
    holo[3]:SetAngles( holo[2]:LocalToWorldAngles( clampAng( headTAng, Angle( -20, -180, -180 ), Angle( 25, 180, 180 ) ) ) )

    -- Weapons
    local grenadeAngle = holo[3]:WorldToLocalAngles( ( ( aimPos or Vector() ) - holo[16]:LocalToWorld( Vector( 57.34, -16.446, -4.917 ) ) ):Angle() )
    holo[16]:SetAngles( holo[3]:LocalToWorldAngles( Angle( math.Clamp( grenadeAngle.p, -45, 35 ), math.Clamp( grenadeAngle.y, -35, 15 ), 0 ) ) )

    local rocketAngle = holo[3]:WorldToLocalAngles( ( ( aimPos or Vector() ) - holo[17]:LocalToWorld( Vector( 39.264, 9.418, -2.055 ) ) ):Angle() )
    holo[17]:SetAngles( holo[3]:LocalToWorldAngles( Angle( math.Clamp( rocketAngle.p, -45, 35 ), math.Clamp( rocketAngle.y, -15, 35 ), 0 ) ) )

    -- Legs
    local rFootPos = self.Gaits["R"].FootData.Pos + self.Gaits["R"].FootData.Trace.HitNormal*12
    local lFootPos = self.Gaits["L"].FootData.Pos + self.Gaits["L"].FootData.Trace.HitNormal*12

    legIK( ent, rFootPos, holo[5], holo[6],  holo[7],  holo[8],  holo[9],  29.998, 26.526, 48.312, 1 )
    legIK( ent, lFootPos, holo[11], holo[12], holo[13], holo[14], holo[15], 29.998, 26.526, 48.312, 1 )
end )
