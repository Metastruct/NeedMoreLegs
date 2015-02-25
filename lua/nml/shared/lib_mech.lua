----------------------------------------------------------------------------------
--- Mech Class - by shadowscion
----------------------------------------------------------------------------------

local meta = {}
meta.__index = meta

function NML_CreateMechType( name )
    local self = {
        Name   = name,
        Author = "nil",
        Skin   = 0,
        Skins  = {},
        DisableShading = false,
        DisplayBones   = false,
    }

    list.Set( "list_nml_mechs", name, self )

    setmetatable( self, meta )

    return self
end

function NML_GetMechType( name )
    local availableTypes = list.Get( "list_nml_mechs" )
    if not availableTypes[name] then return end
    return table.Copy( availableTypes[name] )
end

----------------------------------------------------------------------------------

function meta:SetInit( initialize )
    local function func( self )
        if not self.Name then return end
        if not self.Entity or not IsValid( self.Entity ) then return end

        initialize( self )

        self:StartThink()

        MsgC( Color( 255, 225, 225 ), "NML: " .. self.Name .. " successfully spawned.\n" )
    end
    self.Initialize = func
end

function meta:SetThink( think )
    self.Think = think
end

function meta:StopThink()
    if not self.UniqueID then return end
    hook.Remove( "Think", "nml_think_" .. self.UniqueID )
end

function meta:StartThink()
    if not self.Think then return end
    if not self.UniqueID then return end

    self:StopThink()

    local function func()
        if not self.Think then self:StopThink() return end
        if not self.Entity or not IsValid( self.Entity ) then self:StopThink() return end

        self:Think()
    end

    hook.Add( "Think", "nml_think_" .. self.UniqueID, func )
end

----------------------------------------------------------------------------------

function meta:SetAuthor( author )
    self.Author = author
end

function meta:SetVehicle( vehicle )
    self.Vehicle = vehicle
end

function meta:SetEntity( entity )
    self.Entity = entity
    self.UniqueID = self.Name .. self.Entity:EntIndex()
end

function meta:SetDisableShading( status )
    self.DisableShading = status or false

    if SERVER then return end

    if not self.Holograms then return end
    for _, part in pairs( self.Holograms ) do
        part:SetDisableShading( self.DisableShading )
    end
end

function meta:SetDisplayBones( status )
    self.DisplayBones = status or false

    if SERVER then return end

    if not self.Holograms then return end
    for _, part in pairs( self.Holograms ) do
        part:SetDisplayBones( self.DisplayBones )
    end
end

function meta:SetSkin( skinID )
    if not self.Skins[skinID] then return end
    self.Skin = skinID

    if SERVER then return end

    if not self.Holograms then return end
    for _, part in pairs( self.Holograms ) do
        part:SetSkin( self.Skin )
    end
end

----------------------------------------------------------------------------------

function meta:AddSkin( skinID, name )
    self.Skins[skinID] = name
end

----------------------------------------------------------------------------------

if SERVER then

    return
end

----------------------------------------------------------------------------------

if not CLIENT then return end

----------------------------------------------------------------------------------

function meta:AddGait( name, hipPos, stepOrder, groundHeight )
    if not self.Gaits then self.Gaits = {} end
    self.Gaits[name] = NML_CreateNewGait( self.Entity, hipPos, stepOrder, groundHeight )
end

function meta:RunAllGaits( rate, addVel )
    if not self.Gaits then return end
    for _, gait in pairs( self.Gaits ) do
        gait:Think( rate, addVel )
    end
end

function meta:GetGaitDiff( gaitA, gaitB )
    if not self.Gaits or not self.Gaits[gaitA] or not self.Gaits[gaitB] then return 0 end
    return ( ( self.Gaits[gaitA].StepCurve - self.Gaits[gaitA].StepPointC ) - ( self.Gaits[gaitB].StepCurve - self.Gaits[gaitB].StepPointC ) ).z
end

----------------------------------------------------------------------------------
