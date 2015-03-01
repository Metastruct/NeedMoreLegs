------------------------------------------------------
---- Base Biped Type - Clientside File
---- by shadowscion
------------------------------------------------------

local Addon = NML or {}

local math = math
local table = table
local string = string

local Helper = Addon.Helper
local lerp = Helper.Lerp
------------------------------------------------------

local Mech = Addon.CreateMechType( "base_biped", "nml_mechtypes" )

local schematic = {
    {
        Parent   = 0,
        Model    = "models/hunter/blocks/cube025x025x025.mdl",
        Position = Vector( 0, 20, 0 ),
    };
    {
        Parent   = 0,
        Model    = "models/hunter/blocks/cube025x025x025.mdl",
        Position = Vector( 0, -20, 0 ),
    };
}

------------------------------------------------------

Mech:SetInitialize( function( self, ent )
    self:LoadModelFromData( schematic )
    self:CreateGait( "L", Vector( 0, 20, 0 ), 100 )
    self:CreateGait( "R", Vector( 0, -20, 0 ), 100 )

    self.CSHolograms[1].Parent = nil
    self.CSHolograms[2].Parent = nil

    self.Height = 50
end )

------------------------------------------------------

Mech:SetThink( function( self, ent, dt )
    local vel = ent:GetVelocity()
        vel.z = 0

    self.WalkVel = lerp( self.WalkVel, vel:Length(), 0.1 )

    local multiplier = self.WalkVel/515

    self.WalkCycle = self.WalkCycle + ( 0.05 + 0.03*multiplier )*dt*30

    local gaitSize = math.Clamp( 0.4 + 0.03*multiplier, 0, 0.9 )

    self:SetGaitStart( "L", 0, gaitSize )
    self:SetGaitStart( "R", 0.5, gaitSize )
    self:RunGaitSequence()

    self.CSHolograms[1]:SetPos( self.Gaits["L"].FootData.Pos )
    self.CSHolograms[2]:SetPos( self.Gaits["R"].FootData.Pos )
end )
