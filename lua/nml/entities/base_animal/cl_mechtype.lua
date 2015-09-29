------------------------------------------------------
---- Base Animal Type - Clientside File
---- by shadowscion
------------------------------------------------------

local Addon = NML or {}

local math = math
local table = table

local Helper = Addon.Helper
local sin = Helper.Sin
local cos = Helper.Cos
local lerp = Helper.Lerp
local atan = Helper.Atan
local acos = Helper.Acos
local bearing = Helper.Bearing
local toLocalAxis = Helper.ToLocalAxis
local podEyeTrace = Helper.PodEyeTrace

------------------------------------------------------

local Mech = Addon.CreateMechType( "base_animal", "nml_mechtypes" )

local schematic = {
    -- Body ( 1, 2 )
    {
        Parent   = 0,
        Position = Vector( 0, 0, 0 ),
    };
    {
        Parent   = 0,
        Position = Vector( 0, 0, 0 ),
    };

    -- Neck/Head ( 3, 4, 5 )
    {
        Parent   = 1,
        Position = Vector( 35, 0, 10 ),
    };
    {
        Parent   = 3,
        Position = Vector( 10, 0, 0 ),
    };
    {
        Parent   = 4,
        Position = Vector( 17, 0, -7.5 ),
        Angle = Angle( 10, 0, 0 ),
    };

    -- Front Left Leg ( 6, 7, 8, 9 )
    {
        Parent   = 1,
        Position = Vector( 15.245, 10, 6.422 ),
    };
    {
        Parent   = 6,
        Position = Vector( 0, 9, 0 ),
        Angle = Angle( 25, 0, 0 ),
    };
    {
        Parent   = 7,
        Position = Vector( 0, 0, -34 ),
        Angle = Angle( -50, 0, 0 ),
    };
    {
        Parent   = 8,
        Position = Vector( 0, 0, -36 ),
        Angle = Angle( 25, 0, 0 ),
    };

    -- Front Right Leg ( 10, 11, 12, 13 )
    {
        Parent   = 1,
        Position = Vector( 15.245, -10, 6.422 ),
    };
    {
        Parent   = 10,
        Position = Vector( 0, -9, 0 ),
        Angle = Angle( 25, 0, 0 ),
    };
    {
        Parent   = 11,
        Position = Vector( 0, 0, -34 ),
        Angle = Angle( -50, 0, 0 ),
    };
    {
        Parent   = 12,
        Position = Vector( 0, 0, -36 ),
        Angle = Angle( 25, 0, 0 ),
    };

    -- Rear Left Leg( 14, 15, 16, 17, 18 )
    {
        Parent   = 2,
        Position = Vector( -34, 10, 6.422 ),
    };
    {
        Parent   = 14,
        Position = Vector( 0, 9, 0 ),
    };
    {
        Parent   = 15,
        Position = Vector( 0, 0, -34 ),
        Angle = Angle( 90, 0, 0 ),
    };
    {
        Parent   = 16,
        Position = Vector( 0, 0, -20 ),
        Angle = Angle( -110, 0, 0 ),
    };
    {
        Parent   = 17,
        Position = Vector( 0, 0, -32 ),
        Angle = Angle( 20, 0, 0 ),
    };

    -- Rear Right Leg( 19, 20, 21, 22, 23 )
    {
        Parent   = 2,
        Position = Vector( -34, -10, 6.422 ),
    };
    {
        Parent   = 19,
        Position = Vector( 0, -9, 0 ),
    };
    {
        Parent   = 20,
        Position = Vector( 0, 0, -34 ),
        Angle = Angle( 90, 0, 0 ),
    };
    {
        Parent   = 21,
        Position = Vector( 0, 0, -20 ),
        Angle = Angle( -110, 0, 0 ),
    };
    {
        Parent   = 22,
        Position = Vector( 0, 0, -32 ),
        Angle = Angle( 20, 0, 0 ),
    };

    -- Tail ( 24, 25, 26, 27, 28 )
    {
        Parent   = 2,
        Position = Vector( -45, 0, 15 ),
        Angle = Angle( 5, 0, 0 ),
    };
    {
        Parent   = 24,
        Position = Vector( -20, 0, 0 ),
        Angle = Angle( 5, 0, 0 ),
    };
     {
        Parent   = 25,
        Position = Vector( -20, 0, 0 ),
        Angle = Angle( 5, 0, 0 ),
    };
    {
        Parent   = 26,
        Position = Vector( -20, 0, 0 ),
        Angle = Angle( 5, 0, 0 ),
    };
    {
        Parent   = 27,
        Position = Vector( -20, 0, 0 ),
        Angle = Angle( 5, 0, 0 ),
    };
    {
        Parent   = 28,
        Position = Vector( -20, 0, 0 ),
        Angle = Angle( 5, 0, 0 ),
    };
}

------------------------------------------------------

Mech.Height = 200
Mech.AddVel = 6 --10 --6

local ikf_length0 = 34
local ikf_length1 = 36

local ikr_length0 = 34
local ikr_length1 = 20
local ikr_length2 = 32

function Mech:NewLink( id, parent, ahead, offset )
    if not self.Links then self.Links = {} end

    self.Links[#self.Links + 1] = {
        Holo = self.CSHolograms[id],
        Parent = self.CSHolograms[parent],
        Ahead = self.CSHolograms[ahead],
        Offset = offset,
    }

    self.CSHolograms[id].Bone = self.CSHolograms[id].Parent
    self.CSHolograms[id].Parent = nil
end

function Mech:RunLinks( roll )
    if not self.Links then return end

    local count = #self.Links
    for _, link in ipairs( self.Links ) do
        link.Holo:SetPos( link.Parent:LocalToWorld( link.Offset ) )
        if _ < count and link.Ahead then
            link.Holo:SetAngles( ( link.Parent:GetPos() - link.Ahead:GetPos() ):Angle() )
        end
    end
end

Mech:SetInitialize( function( self, ent )
    self:LoadModelFromData( schematic )

    self:CreateGait( "FL", Vector( 35, 15, 0 ), ( ikf_length0 + ikf_length1 ) )
    self:CreateGait( "FR", Vector( 35, -15, 0 ), ( ikf_length0 + ikf_length1 ) )
    self:CreateGait( "RL", Vector( -55, 15, 0 ), ( ikr_length0 + ikr_length1 + ikr_length2 ) )
    self:CreateGait( "RR", Vector( -55, -15, 0 ), ( ikr_length0 + ikr_length1 + ikr_length2 ) )

    self.BodyAngVel = Angle()
    self.HeightDiff = 0
    self.NeckAngle = ent:GetAngles()

    self:NewLink( 24, 2, 25, Vector( -45, 0, 15 ) )
    self:NewLink( 25, 24, 26, Vector( -20, 0, 0 ) )
    self:NewLink( 26, 25, 27, Vector( -20, 0, 0 ) )
    self:NewLink( 27, 26, 28, Vector( -20, 0, 0 ) )
    self:NewLink( 28, 27, 29, Vector( -20, 0, 0 ) )
    self:NewLink( 29, 28, nil, Vector( -20, 0, 0 ) )
    self.CSHolograms[29]:SetAlpha( 0 )

    for _, holo in pairs( self.CSHolograms ) do
        holo:SetScale( Vector( 0.33, 0.33, 0.33 ) )
        holo:SetColor( Color( 60, 60, 60 ) )
    end

    ent.Draw = function() end

    --self:AddGaitDebugBar( 64, 64, 96*1.25, 96*4*1.25 )

    self.val1 = 0
    self.val2 = 0
end )

------------------------------------------------------

local function rear_ik( ent, pos, hip, fem, tib, tars, foot, length0, length1, length2, factor )
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

local function front_ik( ent, pos, hip, fem, tib, foot, length1, length2, factor )
    length1 = length1*factor
    length2 = length2*factor

    local laxis = toLocalAxis( ent, pos - fem:GetPos() )
    local dist = math.min( laxis:Length(), length1 + length2 - 1 )

    local laxisAngle = laxis:Angle()
        laxisAngle.r = -bearing( fem:GetPos(), ent:GetAngles(), pos )
        laxisAngle:RotateAroundAxis( laxisAngle:Right(), 90 - acos( ( dist^2 + length1^2 - length2^2 )/( 2*length1*dist ) ) )

    hip:SetAngles( ent:LocalToWorldAngles( Angle( 0, 0, math.Clamp( laxisAngle.r, -25, 25 ) ) ) )
    fem:SetAngles( ent:LocalToWorldAngles( laxisAngle ) )

    tib:SetAngles( fem:LocalToWorldAngles( Angle( acos( ( length2^2 + length1^2 - dist^2 )/( 2*length1*length2 ) ) + 180, 0, 0 ) ) )
    foot:SetAngles( Angle( 0, ent:GetAngles().y, 0 ) )
end

local function velL( self )
    if not IsValid( self ) then return Vector() end
    return self:WorldToLocal( self:GetVelocity() + self:GetPos() )
end

Mech:SetThink( function( self, ent, veh, ply, dt )

    -- Setup Inputs
    local holo = self.CSHolograms
	
	
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

    local time = UnPredictedCurTime()
    local sint = sin( time * 100 )
    local cost = cos( time * 100 )

    local angVel = ( ent:GetAngles() - self.BodyAngVel )*( 1/dt )
    self.BodyAngVel = ent:GetAngles()

    local vel = ent:GetVelocity()
    self.WalkVel = lerp( self.WalkVel, vel:Length() + math.abs( angVel.y/5 ), 0.1 )

    local multiplier = self.WalkVel/515
    self.WalkCycle = self.WalkCycle + ( 0.05 + 0.03*multiplier )*dt*30
    local gaitSize = math.Clamp( 0.4 + 0.03*multiplier, 0, 0.9 )

    self.val1 = lerp( self.val1, shift, dt*2.5 )

    self.AddVel = lerp( 6, 10, self.val1 )
    self:SetGaitStart( "FL", lerp( 0, 0, self.val1 ) , gaitSize )
    self:SetGaitStart( "FR", lerp( 0.5, 0.125, self.val1 ), gaitSize )
    self:SetGaitStart( "RL", lerp( 0.75, 0.5, self.val1 ), gaitSize )
    self:SetGaitStart( "RR", lerp( 0.25, 0.6125, self.val1 ), gaitSize )
    self:RunGaitSequence()

	if not holo then return end
	
    if shift == 1 then


        -- self:SetGaitStart( "FL", 0, gaitSize )
        -- self:SetGaitStart( "FR", 0.125, gaitSize )
        -- self:SetGaitStart( "RL", 0.5, gaitSize )
        -- self:SetGaitStart( "RR", 0.6125, gaitSize )
        -- self:RunGaitSequence()

        local diff = self.Gaits["FL"].FootData.Height - self.Gaits["RL"].FootData.Height
        local neckAngle = ( ( aimPos or Vector() ) - holo[1]:GetPos() ):Angle() - ent:GetAngles()
        neckAngle:Normalize()

        self.NeckAngle = LerpAngle( 15*dt, self.NeckAngle, neckAngle*( 1/3 ) )

        holo[1]:SetPos( ent:LocalToWorld( Vector( 0, 0, diff/2.5 + self.NeckAngle.p*0 ) ) )
        holo[2]:SetPos( ent:LocalToWorld( Vector( 0, 0, diff/2.5 + self.NeckAngle.p*0 ) ) )
        holo[1]:SetAngles( ent:LocalToWorldAngles( Angle( -diff, 0, 0 ) ) )
        holo[2]:SetAngles( ent:LocalToWorldAngles( Angle( -diff/2, 0, 0 ) ) )

        holo[3]:SetAngles( ent:LocalToWorldAngles( self.NeckAngle ) )
        holo[4]:SetAngles( holo[3]:LocalToWorldAngles( self.NeckAngle ) )
    else
        --self.AddVel = 6

        -- self:SetGaitStart( "FL", 0, gaitSize )
        -- self:SetGaitStart( "FR", 0.5, gaitSize )
        -- self:SetGaitStart( "RL", 0.75, gaitSize )
        -- self:SetGaitStart( "RR", 0.25, gaitSize )
        -- self:RunGaitSequence()

        local diff = self.Gaits["FL"].FootData.Height - self.Gaits["FR"].FootData.Height
        local neckAngle = ( ( aimPos or Vector() ) - holo[1]:GetPos() ):Angle() + Angle( 0, diff, 0 ) - ent:GetAngles()
        neckAngle:Normalize()

        self.NeckAngle = LerpAngle( 15*dt, self.NeckAngle, neckAngle*( 1/3 ) )

        holo[1]:SetPos( ent:LocalToWorld( Vector( 0, 0, math.abs( diff/3 ) + self.NeckAngle.p  + cost*2 ) ) )
        holo[2]:SetPos( ent:LocalToWorld( Vector( 0, 0, math.abs( diff/3 ) + self.NeckAngle.p + cost*2 ) ) )
        holo[1]:SetAngles( ent:LocalToWorldAngles( self.NeckAngle - Angle( sint*2, 0, 0 ) ) )
        holo[2]:SetAngles( ent:LocalToWorldAngles( Angle( self.NeckAngle.p - cost*2, -self.NeckAngle.y, self.NeckAngle.r ) ) )

        holo[3]:SetAngles( ent:LocalToWorldAngles( self.NeckAngle ) )
        holo[4]:SetAngles( holo[3]:LocalToWorldAngles( self.NeckAngle ) )
    end

    self:RunLinks()

    front_ik( ent, self.Gaits["FL"].FootData.Pos, holo[6], holo[7], holo[8], holo[9], ikf_length0, ikf_length1, 1 )
    front_ik( ent, self.Gaits["FR"].FootData.Pos, holo[10], holo[11], holo[12], holo[13], ikf_length0, ikf_length1, 1 )
    rear_ik( ent, self.Gaits["RL"].FootData.Pos, holo[14], holo[15], holo[16], holo[17], holo[18], ikr_length0, ikr_length1, ikr_length2, 1 )
    rear_ik( ent, self.Gaits["RR"].FootData.Pos, holo[19], holo[20], holo[21], holo[22], holo[23], ikr_length0, ikr_length1, ikr_length2, 1 )
end )
