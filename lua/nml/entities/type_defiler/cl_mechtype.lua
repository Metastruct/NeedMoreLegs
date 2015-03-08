------------------------------------------------------
---- WH40k Defiler - Clientside File
---- by shadowscion
------------------------------------------------------

local Addon = NML or {}

local math = math
local table = table
local string = string

local Helper = Addon.Helper

local sin = Helper.Sin
local cos = Helper.Cos
local lerp = Helper.Lerp
local atan = Helper.Atan
local acos = Helper.Acos
local asin = Helper.Asin
local clampAng = Helper.ClampAng
local bearing = Helper.Bearing
local podEyeTrace = Helper.PodEyeTrace
local toLocalAxis = Helper.ToLocalAxis
local traceDirection = Helper.TraceDirection

------------------------------------------------------

local Mech = Addon.CreateMechType( "type_defiler", "nml_mechtypes" )

Mech.Height = 50
Mech.AddVel = 5

local schematic = {
    {
        Parent = 0,
        Position = Vector(),
        Model = "models/nml/wh40k/defiler/part_body.mdl",
    };

    {
        Parent = 1,
        Position = Vector( 43.77554321289063, 0, 27.28911399841309 ),
        Model = "models/nml/wh40k/defiler/part_torso.mdl",
    };
    {
        Parent = 2,
        Position = Vector( -15.097382, 0, 110.161095 ),
        Model = "models/nml/wh40k/defiler/part_head.mdl",
    };
    {
        Parent = 2,
        Position = Vector( 40.256866, 0, 39.580124 ),
        Model = "models/nml/wh40k/defiler/part_cannon.mdl",
    };

    {
        Parent = 2,
        Position = Vector( -27.17300033569336, 69.105858, 74.268875 ),
        Model = "models/nml/wh40k/defiler/part_l_weapon_a.mdl",
    };
    {
        Parent = 2,
        Position = Vector( -27.17300033569336, 69.105858, 74.268875 ),
        Model = "models/nml/wh40k/defiler/part_l_weapon_b.mdl",
    };
    {
        Parent = 2,
        Position = Vector( -19.235614776611328, -60.858875, 79.262390 ),
        Model = "models/nml/wh40k/defiler/part_r_weapon_a.mdl",
    };

    -- Rear Right Leg ( 8, 9, 10 )
    {
        Parent = 1,
        Position = Vector( -54.43307113647461, -43.13426208496094, -8.786996841430664 ),
        Model = "models/nml/wh40k/defiler/part_leg_a.mdl",
    };
    {
        Parent = 8,
        Position = Vector( 0, 0, 79.391212 ),
        Model = "models/nml/wh40k/defiler/part_leg_b.mdl",
    };
    {
        Parent = 9,
        Position = Vector( 7.803009, 0, 54.447861 ),
        Model = "models/nml/wh40k/defiler/part_leg_c.mdl",
    };

    -- Rear Left Leg ( 11, 12, 13 )
    {
        Parent = 1,
        Position = Vector( -54.43307113647461, 43.13426208496094, -8.786996841430664 ),
        Model = "models/nml/wh40k/defiler/part_leg_a.mdl",
    };
    {
        Parent = 11,
        Position = Vector( 0, 0, 79.391212 ),
        Model = "models/nml/wh40k/defiler/part_leg_b.mdl",
    };
    {
        Parent = 12,
        Position = Vector( 7.803009, 0, 54.447861 ),
        Model = "models/nml/wh40k/defiler/part_leg_c.mdl",
    };

    -- Front Right Leg ( 14, 15, 16 )
    {
        Parent = 1,
        Position = Vector( 25, -43.13426208496094, -8.786996841430664 ),
        Model = "models/nml/wh40k/defiler/part_leg_a.mdl",
    };
    {
        Parent = 14,
        Position = Vector( 0, 0, 79.391212 ),
        Model = "models/nml/wh40k/defiler/part_leg_b.mdl",
    };
    {
        Parent = 15,
        Position = Vector( 7.803009, 0, 54.447861 ),
        Model = "models/nml/wh40k/defiler/part_leg_c.mdl",
    };

    -- Front Left Leg ( 17, 18, 19 )
    {
        Parent = 1,
        Position = Vector( 25, 43.13426208496094, -8.786996841430664 ),
        Model = "models/nml/wh40k/defiler/part_leg_a.mdl",
    };
    {
        Parent = 17,
        Position = Vector( 0, 0, 79.391212 ),
        Model = "models/nml/wh40k/defiler/part_leg_b.mdl",
    };
    {
        Parent = 18,
        Position = Vector( 7.803009, 0, 54.447861 ),
        Model = "models/nml/wh40k/defiler/part_leg_c.mdl",
    };

    -- Front Right Claw( 20, 21, 22, 23 )
    {
        Parent = 1,
        Position = Vector( 64.451958, -67.978256, -11.584712 ),
        Model = "models/nml/wh40k/defiler/part_claw_a.mdl",
    };
    {
        Parent = 20,
        Position = Vector( 0, 0, 84.152908 ),
        Model = "models/nml/wh40k/defiler/part_claw_b.mdl",
    };
    {
        Parent = 21,
        Position = Vector( 2.722275, 0, 36.142647 ),
        Model = "models/nml/wh40k/defiler/part_claw_c.mdl",
    };
    {
        Parent = 22,
        Position = Vector( -7.219906, 0, 58.362350 ),
        Model = "models/nml/wh40k/defiler/part_claw_d.mdl",
    };

    -- Front Left Claw( 24, 25, 26, 27 )
    {
        Parent = 1,
        Position = Vector( 64.451958, 67.978256, -11.584712 ),
        Model = "models/nml/wh40k/defiler/part_claw_a.mdl",
    };
    {
        Parent = 24,
        Position = Vector( 0, 0, 84.152908 ),
        Model = "models/nml/wh40k/defiler/part_claw_b.mdl",
    };
    {
        Parent = 25,
        Position = Vector( 2.722275, 0, 36.142647 ),
        Model = "models/nml/wh40k/defiler/part_claw_c.mdl",
    };
    {
        Parent = 26,
        Position = Vector( -7.219906, 0, 58.362350 ),
        Model = "models/nml/wh40k/defiler/part_claw_d.mdl",
    };
}

------------------------------------------------------


Mech:SetInitialize( function( self, ent )
    self:LoadModelFromData( schematic )

    self:CreateGait( 1, Vector( 200, -100, 0 ), ( 95.73762*2 + 36.142647 )*2 )
    self:CreateGait( 2, Vector( 200, 100, 0 ), ( 95.73762*2 + 36.142647 )*2 )

    self:CreateGait( 3, Vector( -100, -150, 0 ), ( 88.17820884143066 + 54.447861 )*2 )
    self:CreateGait( 4, Vector( -100, 150, 0 ), ( 88.17820884143066 + 54.447861 )*2 )
    self:CreateGait( 5, Vector( 60, -150, 0 ), ( 88.17820884143066 + 54.447861 )*2 )
    self:CreateGait( 6, Vector( 60, 150, 0 ), ( 88.17820884143066 + 54.447861 )*2 )

    self.JumpMode = 0
    self.JumpTime = 0

    self.CSHolograms[1]:SetThink( function()
        -- local hPos = math.Clamp( self.Gaits[1].FootData.Height - self.Gaits[2].FootData.Height, -50, 50 )
        -- self.CSHolograms[1]:SetPos( ent:LocalToWorld( Vector( 0, 0, math.abs( hPos/3 ) ) ) )
        -- self.CSHolograms[1]:UpdatePos()
    end )
end )

------------------------------------------------------

--local function legIK( ent, pos, hip, fem, tib, tars, foot, toe, length0, length1, length2, factor )
local function legIK( ent, pos, fem, tib, tars, length0, length1 )
    local laxis = toLocalAxis( ent, pos - fem:GetPos() )
    local dist = math.min( laxis:Length() - length1, length0*2 - 1 )

    local laxisAngle = laxis:Angle()
        laxisAngle:RotateAroundAxis( laxisAngle:Right(), -90 + acos( dist/( length0 + length0 ) ) )

    fem:SetAngles( ent:LocalToWorldAngles( laxisAngle ) )
    tib:SetAngles( fem:LocalToWorldAngles( Angle( -asin( dist/( length0 + length0 ) ) + 90, 0, 0 ) ) )
    tars:SetAngles( fem:LocalToWorldAngles( Angle( acos( ( dist^2 - ( 2*length0*length0 ) )/( 2*length0*length0 ) ), 0, 0 ) ) )
end

local function rear_ik( ent, pos, fem, tib, tars, length0, length1 )
    local laxis = toLocalAxis( ent, pos - fem:GetPos() )
    local dist = math.min( laxis:Length(), length0 + length1 - 1 )

    local laxisAngle = laxis:Angle()
        laxisAngle:RotateAroundAxis( laxisAngle:Right(), acos( ( length1^2 - length0^2 - dist^2 )/( -2*length0*dist ) ) - 90 )

    fem:SetAngles( ent:LocalToWorldAngles( laxisAngle ) )
    tib:SetAngles( fem:LocalToWorldAngles( Angle( -acos( ( dist^2 - length0^2 - length1^2 )/( -2*length0*length1 ) ) + 180, 0, 0 ) ) )

    laxis = toLocalAxis( tib, pos - tars:GetPos() )
    tars:SetAngles( tib:LocalToWorldAngles( Angle( atan( -laxis.x, laxis.z ), 0, 0 ) ) )
end


Mech:SetThink( function( self, ent, veh, ply, dt )
    if not self.CSHolobase then return end
    if not self.CSHolograms then return end
    --if true then return false end

    -- Setup Inputs
    local aimPos = Vector()
    local w, a, s, d = 0, 0, 0, 0
    local ctrl, alt, space, shift = 0, 0, 0, 0

    if IsValid( ply ) then
        w = ply:KeyDown( IN_FORWARD ) and 1 or 0
        a = ply:KeyDown( IN_MOVELEFT ) and 1 or 0
        s = ply:KeyDown( IN_BACK ) and 1 or 0
        d = ply:KeyDown( IN_MOVERIGHT ) and 1 or 0

        ctrl = ply:KeyDown( IN_DUCK ) and 1 or 0
        shift = ply:KeyDown( IN_SPEED ) and 1 or 0
        alt = ply:KeyDown( IN_WALK ) and 1 or 0
        space = ply:KeyDown( IN_JUMP ) and 1 or 0

        aimPos = podEyeTrace( ply ).HitPos
    else
        aimPos = ent:GetPos() + ent:GetForward()*200
    end

    local holo = self.CSHolograms

    local mode = ent:GetMechMode()

    if mode == "Normal" then
        -- Run gait sequence
        self.WalkVel = lerp( self.WalkVel, ent:GetVelocity():Length(), 0.1 )
        local multiplier = self.WalkVel/1000

        self.WalkCycle = self.WalkCycle + ( 0.05 + 0.03*multiplier )*dt*30
        local gaitSize = math.Clamp( 0.4 + 0.03*multiplier, 0, 0.9 )

        self:SetGaitStart( 1, 0, gaitSize )
        self:SetGaitStart( 2, 0.5, gaitSize )
        self:SetGaitStart( 3, 0.25, gaitSize )
        self:SetGaitStart( 4, 0.75, gaitSize )
        self:SetGaitStart( 5, 0.5, gaitSize )
        self:SetGaitStart( 6, 1.00, gaitSize )

        self:RunGaitSequence()
        self.JumpTime = 0

        local hPos = math.Clamp( self.Gaits[1].FootData.Height - self.Gaits[2].FootData.Height, -50, 50 )
        self.CSHolograms[1]:SetPos( ent:LocalToWorld( Vector( 0, 0, math.abs( hPos/3 ) ) ) )
        --self.CSHolograms[1]:UpdatePos()
    end

    if mode == "DoJump" then
        self.JumpTime = math.min( self.JumpTime + dt/1.25, 1 )
        local tempLegVec = ent:GetVelocity()/15
            tempLegVec.z = -tempLegVec.z*3

        local jtrace1 = traceDirection( 500, ent:LocalToWorld( self.Gaits[1].FootData.Offset ), Vector( 0, 0, -1 ) )
        local jtrace2 = traceDirection( 500, ent:LocalToWorld( self.Gaits[2].FootData.Offset ), Vector( 0, 0, -1 ) )
        local jtrace3 = traceDirection( 500, ent:LocalToWorld( self.Gaits[3].FootData.Offset ), Vector( 0, 0, -1 ) )
        local jtrace4 = traceDirection( 500, ent:LocalToWorld( self.Gaits[4].FootData.Offset ), Vector( 0, 0, -1 ) )
        local jtrace5 = traceDirection( 500, ent:LocalToWorld( self.Gaits[5].FootData.Offset ), Vector( 0, 0, -1 ) )
        local jtrace6 = traceDirection( 500, ent:LocalToWorld( self.Gaits[6].FootData.Offset ), Vector( 0, 0, -1 ) )

        local time = sin( self.JumpTime*180 )

        self.Gaits[1].FootData.Pos = LerpVector( time, jtrace1.HitPos, ent:LocalToWorld( self.Gaits[1].FootData.Offset ) + tempLegVec )
        self.Gaits[2].FootData.Pos = LerpVector( time, jtrace2.HitPos, ent:LocalToWorld( self.Gaits[2].FootData.Offset ) + tempLegVec )
        self.Gaits[3].FootData.Pos = LerpVector( time, jtrace3.HitPos, ent:LocalToWorld( self.Gaits[3].FootData.Offset ) + tempLegVec )
        self.Gaits[4].FootData.Pos = LerpVector( time, jtrace4.HitPos, ent:LocalToWorld( self.Gaits[4].FootData.Offset ) + tempLegVec )
        self.Gaits[5].FootData.Pos = LerpVector( time, jtrace5.HitPos, ent:LocalToWorld( self.Gaits[5].FootData.Offset ) + tempLegVec )
        self.Gaits[6].FootData.Pos = LerpVector( time, jtrace6.HitPos, ent:LocalToWorld( self.Gaits[6].FootData.Offset ) + tempLegVec )

        self.WalkCycle = 0
        self.WalkVel = 0

        self.Gaits[1].FootData.Prev = self.Gaits[1].FootData.Pos
        self.Gaits[1].FootData.Dest = self.Gaits[1].FootData.Pos

        self.Gaits[2].FootData.Prev = self.Gaits[2].FootData.Pos
        self.Gaits[2].FootData.Dest = self.Gaits[2].FootData.Pos
        self.Gaits[3].FootData.Prev = self.Gaits[3].FootData.Pos
        self.Gaits[3].FootData.Dest = self.Gaits[3].FootData.Pos
        self.Gaits[4].FootData.Prev = self.Gaits[4].FootData.Pos
        self.Gaits[4].FootData.Dest = self.Gaits[4].FootData.Pos
        self.Gaits[5].FootData.Prev = self.Gaits[5].FootData.Pos
        self.Gaits[5].FootData.Dest = self.Gaits[5].FootData.Pos
        self.Gaits[6].FootData.Prev = self.Gaits[6].FootData.Pos
        self.Gaits[6].FootData.Dest = self.Gaits[6].FootData.Pos
    end

    -- Animate legs

    local torsoCAng = holo[2]:GetAngles()
    local torsoTAng = ( ( aimPos or Vector() ) - holo[2]:GetPos() ):Angle()
    torsoTAng:Normalize()

    local torsoTPitch = math.ApproachAngle( torsoCAng.p, torsoTAng.p, dt*75 )
    local torsoTYaw = math.ApproachAngle( torsoCAng.y, torsoTAng.y, dt*125 )

    torsoTAng = holo[1]:WorldToLocalAngles( Angle( torsoTPitch, torsoTYaw, 0 ) )
    holo[2]:SetAngles( holo[1]:LocalToWorldAngles( clampAng( torsoTAng, Angle( -20, -180, -180 ), Angle( 25, 180, 180 ) ) ) )

    holo[3]:SetAngles( ( ( aimPos or Vector() ) - holo[3]:GetPos() ):Angle() )

    local machinegunAngle = holo[2]:WorldToLocalAngles( ( ( aimPos or Vector() ) - holo[6]:LocalToWorld( Vector() ) ):Angle() )
    holo[6]:SetAngles( holo[2]:LocalToWorldAngles( Angle( math.Clamp( machinegunAngle.p, -45, 45 ), math.Clamp( machinegunAngle.y, -25, 45 ), 0 ) ) )

    local flamerAngle = holo[2]:WorldToLocalAngles( ( ( aimPos or Vector() ) - holo[7]:LocalToWorld( Vector() ) ):Angle() )
    holo[7]:SetAngles( holo[2]:LocalToWorldAngles( Angle( math.Clamp( flamerAngle.p, -45, 45 ), math.Clamp( flamerAngle.y, -45, 25 ), 0 ) ) )

    local fposl = self.Gaits[1].FootData.Pos + self.Gaits[1].FootData.Trace.HitNormal*24
    local fposr = self.Gaits[2].FootData.Pos + self.Gaits[2].FootData.Trace.HitNormal*24

    legIK( ent, fposl, holo[20], holo[21], holo[22], 95.73762 + 0, 36.142647 )
    legIK( ent, fposr, holo[24], holo[25], holo[26], 95.73762 + 0, 36.142647 )

    rear_ik( ent, self.Gaits[3].FootData.Pos, holo[8], holo[9], holo[10], 88.17820884143066, 130 )
    rear_ik( ent, self.Gaits[4].FootData.Pos, holo[11], holo[12], holo[13], 88.17820884143066, 130 )
    rear_ik( ent, self.Gaits[5].FootData.Pos, holo[14], holo[15], holo[16], 88.17820884143066, 130 )
    rear_ik( ent, self.Gaits[6].FootData.Pos, holo[17], holo[18], holo[19], 88.17820884143066, 130 )

end )

