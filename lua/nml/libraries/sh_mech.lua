----------------------------------------------------------------------------------
---- Mech Class - by shadowscion
----------------------------------------------------------------------------------

--- Mech Class Meta Object
-- @section

local Mech = {}
Mech.__index = Mech

--- Creates a new mech type
-- @function NML_CreateMechType
-- @tparam String Name
-- @return MechType
-- @usage local Mech = NML_CreateMechType( "Base_Mech" )
function NML_CreateMechType( name )
    local self = {
        Name   = name,
        Skin   = 0,
        Skins  = {},
        DisableShading = false,
        DisplayBones   = false,
    }

    list.Set( "list_nml_mechs", name, self )

    setmetatable( self, Mech )

    return self
end

--- Returns an existing mech type
-- @function NML_GetMechType
-- @tparam String Name
-- @return MechType
-- @usage local Mech = NML_GetMechType( "Base_Mech" )
function NML_GetMechType( name )
    local availableTypes = list.Get( "list_nml_mechs" )
    if not availableTypes[name] then return end
    return table.Copy( availableTypes[name] )
end

--- MechType Meta Functions
-- @section

--- Sets the Initialize meta function of a mech
-- @function Mech:SetInit
-- @tparam Function InitFunc
-- @usage Mech:SetInit( function() print( "init" ) end )
function Mech:SetInit( initialize )
    local function func( self )
        if not self.Name then return end
        if not self.Entity or not IsValid( self.Entity ) then return end

        -- Creates a base hologram entity
        if CLIENT then
            self.CSHolobase = NML_CSHolobase()
            self.CSHolograms = {}

            self.Entity:CallOnRemove( "GarbageDay", function( ent )
                self.CSHolobase:Remove()
                self.CSHolograms = nil

                timer.Simple( 0.5, function()
                    if not IsValid( ent ) then return end
                    if not self.Initialize then return end
                    self:Initialize()
                end )
            end )
        end

        initialize( self )

        self:StartThink()
    end
    self.Initialize = func
end

--- Sets the Think meta function of a mech
-- @function Mech:SetThink
-- @tparam Function ThinkFunc
-- @usage Mech:SetThink( function() print( "init" ) end )
function Mech:SetThink( think )
    self.Think = think
end

--- Stops the Think meta function of a mech ( handled internally )
-- @function Mech:StopThink
function Mech:StopThink()
    if not self.UniqueID then return end
    hook.Remove( "Think", "nml_think_" .. self.UniqueID )
end

--- Starts the Think meta function of a mech ( handled internally )
-- @function Mech:StartThink
function Mech:StartThink()
    if not self.Think then return end
    if not self.UniqueID then return end

    self:StopThink()

    local function func()
        if not self.Think then self:StopThink() return end
        if not self.Entity or not IsValid( self.Entity ) then self:StopThink() return end

        if SERVER then
            self.Entity:SetBaseDriver( self.Entity:GetBaseVehicle():GetDriver() or nil )
        end

        self:Think()
    end

    hook.Add( "Think", "nml_think_" .. self.UniqueID, func )
end

--- Sets the entity of the mech object
-- @function Mech:SetEntity
-- @tparam Entity Entity
-- @usage Mech:SetEntity( Entity( 50 ) )
function Mech:SetEntity( ent )
    if not IsValid( ent ) then return end
    if ent:GetClass() ~= "sent_nml_base" then return end

    self.Entity = ent
    self.UniqueID = self.Name .. self.Entity:EntIndex()
end

--- Returns the driver of the mech vehicle
-- @function Mech:GetDriver
-- @return Driver
-- @usage local Driver = Mech:GetDriver()
function Mech:GetDriver()
    return self.Entity:GetBaseDriver()
end

--- Returns the mech vehicle
-- @function Mech:GetVehicle
-- @return Vehicle
-- @usage local Vehicle = Mech:GetVehicle()
function Mech:GetVehicle()
    return self.Entity:GetBaseVehicle()
end



if SERVER then return end

--- Loads a model from a table of values
-- @function Mech:LoadModelFromData
-- @tparam Table Data { Position=Vector(), Angle=Angle(), Model="String", Material="String" }
-- @usage Mech:LoadModelFromData( schematic )
function Mech:LoadModelFromData( data )
    if not self.Entity then return end
    if not self.CSHolobase then return end
    if not self.CSHolograms then return end

    local coro = coroutine.create( function()
        for i, info in ipairs( data ) do
            local part = NML_CSHologram( self.CSHolobase )
            local partParent = self.CSHolograms[info.Parent] and self.CSHolograms[info.Parent] or self.Entity

            part:SetParent( partParent )
            part:SetPos( partParent:LocalToWorld( info.Position or Vector() ) )
            part:SetAngles( partParent:LocalToWorldAngles( info.Angle or Angle() ) )
            part:SetModel( info.Model or "" )
            part:SetMaterial( info.Material or nil )

            part:UpdatePos()
            part:UpdateAngles()

            self.CSHolograms[i] = part

            coroutine.yield( false )
        end
        coroutine.yield( true )
    end )

    timer.Create( self.UniqueID, 0.01, 0, function()
        local _, go = coroutine.resume( coro )
        if go then
            self.CSHolobase.draw = true
            timer.Stop( self.UniqueID )
        end
    end )
end

function Mech:AddLeg( name, offset, stepOrder, groundHeight )
    if not self.Entity then return nil end
    if not self.Legs then self.Legs = {} end
    self.Legs[name] = NML_CreateNewWalkCycle( self.Entity, offset, stepOrder, groundHeight )
end

function Mech:RunAllLegs( walkVel, addVel )
    if not self.Legs then return end
    for _, leg in pairs( self.Legs ) do
        leg:Think( walkVel, addVel )
    end
end

function Mech:GetLegDiff( legA, legB )
    if not self.Legs or not self.Legs[legA] or not self.Legs[legB] then return 0 end
    return ( ( self.Legs[legA].StepCurve - self.Legs[legA].StepPointC ) - ( self.Legs[legB].StepCurve - self.Legs[legB].StepPointC ) ).z
end

--[[

--- MechType Properties and Details
-- @section

--- Sets the base entity of the mechtype
-- @function Mech:SetEntity
-- @tparam Entity Entity
-- @usage Mech:SetEntity( Entity( 50 ) )
function Mech:SetEntity( entity )
    self.Entity = entity
    self.UniqueID = self.Name .. self.Entity:EntIndex()
end

--- Sets the base vehicle of the mechtype
-- @function Mech:SetVehicle
-- @tparam Entity Vehicle
-- @usage Mech:SetVehicle( Entity( 50 ) )
function Mech:SetVehicle( vehicle )
    self.Vehicle = vehicle
end



function Mech:SetDisableShading( status )
    self.DisableShading = status or false

    if SERVER then return end

    if not self.Holograms then return end
    for _, part in pairs( self.Holograms ) do
        part:SetDisableShading( self.DisableShading )
    end
end

function Mech:SetDisplayBones( status )
    self.DisplayBones = status or false

    if SERVER then return end

    if not self.Holograms then return end
    for _, part in pairs( self.Holograms ) do
        part:SetDisplayBones( self.DisplayBones )
    end
end

function Mech:SetSkin( skinID )
    if not self.Skins[skinID] then return end
    self.Skin = skinID

    if SERVER then return end

    if not self.Holograms then return end
    for _, part in pairs( self.Holograms ) do
        part:SetSkin( self.Skin )
    end
end

----------------------------------------------------------------------------------

function Mech:AddSkin( skinID, name )
    self.Skins[skinID] = name
end

----------------------------------------------------------------------------------

if not CLIENT then return end

----------------------------------------------------------------------------------

function Mech:AddGait( name, hipPos, stepOrder, groundHeight )
    if not self.Gaits then self.Gaits = {} end
    self.Gaits[name] = NML_CreateNewGait( self.Entity, hipPos, stepOrder, groundHeight )
end

function Mech:RunAllGaits( rate, addVel )
    if not self.Gaits then return end
    for _, gait in pairs( self.Gaits ) do
        gait:Think( rate, addVel )
    end
end

function Mech:GetGaitDiff( gaitA, gaitB )
    if not self.Gaits or not self.Gaits[gaitA] or not self.Gaits[gaitB] then return 0 end
    return ( ( self.Gaits[gaitA].StepCurve - self.Gaits[gaitA].StepPointC ) - ( self.Gaits[gaitB].StepCurve - self.Gaits[gaitB].StepPointC ) ).z
end

----------------------------------------------------------------------------------
]]--
