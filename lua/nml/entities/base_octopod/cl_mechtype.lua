------------------------------------------------------
---- Base Biped Type - Clientside File
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
local bearing = Helper.Bearing
local podEyeTrace = Helper.PodEyeTrace
local toLocalAxis = Helper.ToLocalAxis

------------------------------------------------------

local Mech = Addon.CreateMechType( "base_octopod", "nml_mechtypes" )

Mech.Height = 50
Mech.AddVel = 5

local schematic = {
    -- Base
    { Parent = 0, Position = Vector( 0, 0, 0 ) };

    -- Front Legs Left ( 2, 3, 4 )
    { Parent = 1, Position = Vector( 10, 10, 0 ) };
    { Parent = 2, Position = Vector( 0, 0, 75 ) };
    { Parent = 3, Position = Vector( 0, 0, 50 ) };

    -- Front Legs Right ( 5, 6, 7 )
    { Parent = 1, Position = Vector( 10, -10, 0 ) };
    { Parent = 5, Position = Vector( 0, 0, 75 ) };
    { Parent = 6, Position = Vector( 0, 0, 50 ) };

    -- Middle Legs LeftF ( 8, 9, 10 )
    { Parent = 1, Position = Vector( 5, 13, 0 ) };
    { Parent = 8, Position = Vector( 0, 0, 60 ) };
    { Parent = 9, Position = Vector( 0, 0, 35 ) };

    -- Middle Legs LeftR ( 11, 12, 13 )
    { Parent = 1, Position = Vector( 0, 13, 0 ) };
    { Parent = 11, Position = Vector( 0, 0, 60 ) };
    { Parent = 12, Position = Vector( 0, 0, 35 ) };

    -- Middle Legs RightF ( 14, 15, 16 )
    { Parent = 1, Position = Vector( 5, -13, 0 ) };
    { Parent = 14, Position = Vector( 0, 0, 60 ) };
    { Parent = 15, Position = Vector( 0, 0, 35 ) };

    -- Middle Legs RightR ( 17, 18, 19 )
    { Parent = 1, Position = Vector( 0, -13, 0 ) };
    { Parent = 17, Position = Vector( 0, 0, 60 ) };
    { Parent = 18, Position = Vector( 0, 0, 35 ) };

    -- Rear Legs Left ( 20, 21, 22 )
    { Parent = 1, Position = Vector( -5, 12, 0 ) };
    { Parent = 20, Position = Vector( 0, 0, 60 ) };
    { Parent = 21, Position = Vector( 0, 0, 35 ) };

    -- Rear Legs Right ( 23, 24, 25 )
    { Parent = 1, Position = Vector( -5, -12, 0 ) };
    { Parent = 23, Position = Vector( 0, 0, 60 ) };
    { Parent = 24, Position = Vector( 0, 0, 35 ) };
}

for i = 1, 8 do
    table.insert( schematic, { Parent = i*3 + 1, Position = Vector( 0, 0, i > 2 and 60 or 75 ) } )
end
------------------------------------------------------

local ikf_length0 = 75
local ikf_length1 = 50

local ik_length0 = 60
local ik_length1 = 35

--local function legIK( ent, pos, hip, fem, tib, tars, foot, toe, length0, length1, length2, factor )
local function legIK( ent, pos, fem, tib, tars, length0, length1 )
    local laxis = toLocalAxis( ent, pos - fem:GetPos() )
    local dist = math.min( laxis:Length() - length1, length0*2 - 1 )

    local laxisAngle = laxis:Angle()
        laxisAngle:RotateAroundAxis( laxisAngle:Right(), -90 + acos( dist/( length0 + length0 ) ) )

    fem:SetAngles( ent:LocalToWorldAngles( laxisAngle ) )
    tib:SetAngles( fem:LocalToWorldAngles( Angle( asin( dist/( length0 + length0 ) ) - 90, 180, 0 ) ) )
    tars:SetAngles( fem:LocalToWorldAngles( Angle( acos( ( dist^2 - ( 2*length0*length0 ) )/( 2*length0*length0 ) ), 0, 0 ) ) )
end


Mech:SetInitialize( function( self, ent )
    self:LoadModelFromData( schematic )

    self:CreateGait( 1, Vector( 150, 80, 0 ), ( ikf_length0*2 + ikf_length1 )*2 )
    self:CreateGait( 2, Vector( 150, -80, 0 ), ( ikf_length0*2 + ikf_length1 )*2 )
    self:CreateGait( 3, Vector( 60, 100, 0 ), ( ik_length0*2 + ik_length1 )*2 )
    self:CreateGait( 4, Vector( -20, 100, 0 ), ( ik_length0*2 + ik_length1 )*2 )
    self:CreateGait( 5, Vector( 60, -100, 0 ), ( ik_length0*2 + ik_length1 )*2 )
    self:CreateGait( 6, Vector( -20, -100, 0 ), ( ik_length0*2 + ik_length1 )*2 )
    self:CreateGait( 7, Vector( -80, 80, 0 ), ( ik_length0*2 + ik_length1 )*2 )
    self:CreateGait( 8, Vector( -80, -80, 0 ), ( ik_length0*2 + ik_length1 )*2 )


end )

------------------------------------------------------

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

    -- Run gait sequence
    self.WalkVel = lerp( self.WalkVel, ent:GetVelocity():Length(), 0.1 )
    local multiplier = self.WalkVel/1000

    self.WalkCycle = self.WalkCycle + ( 0.05 + 0.03*multiplier )*dt*30
    local gaitSize = math.Clamp( 0.4 + 0.03*multiplier, 0, 0.9 )

    self:SetGaitStart( 1, 0.25, gaitSize )
    self:SetGaitStart( 2, 0.50, gaitSize )
    self:SetGaitStart( 3, 0.75, gaitSize )
    self:SetGaitStart( 4, 1.00, gaitSize )
    self:SetGaitStart( 5, 1.25, gaitSize )
    self:SetGaitStart( 6, 1.50, gaitSize )
    self:SetGaitStart( 7, 1.75, gaitSize )
    self:SetGaitStart( 8, 2.00, gaitSize )

    self:RunGaitSequence()

    -- Animate legs
    local holo = self.CSHolograms

    legIK( ent, self.Gaits[1].FootData.Pos, holo[2], holo[3], holo[4], 75, 50 )
    legIK( ent, self.Gaits[2].FootData.Pos, holo[5], holo[6], holo[7], 75, 50 )
    legIK( ent, self.Gaits[3].FootData.Pos, holo[8], holo[9], holo[10], 60, 35 )
    legIK( ent, self.Gaits[4].FootData.Pos, holo[11], holo[12], holo[13], 60, 35 )
    legIK( ent, self.Gaits[5].FootData.Pos, holo[14], holo[15], holo[16], 60, 35 )
    legIK( ent, self.Gaits[6].FootData.Pos, holo[17], holo[18], holo[19], 60, 35 )
    legIK( ent, self.Gaits[7].FootData.Pos, holo[20], holo[21], holo[22], 60, 35 )
    legIK( ent, self.Gaits[8].FootData.Pos, holo[23], holo[24], holo[25], 60, 35 )

end )

