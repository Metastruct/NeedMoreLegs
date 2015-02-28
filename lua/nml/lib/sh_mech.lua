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
    local self = { Name = name }

    if CLIENT then
        self.Skins = {}
    end

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

            self.Skin = self.Entity:GetMechSkin()
            self.ShowBones = self.Entity:GetShowBones()
            self.DisableShading = self.Entity:GetDisableShading()

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

            local phys = self.Entity:GetPhysicsObject()
            if IsValid( phys ) then
                phys:EnableMotion( true )

                if phys:GetVelocity():Length() > 1000 then phys:AddVelocity( -phys:GetVelocity()/1.25 ) end
                if phys:GetAngleVelocity():Length() > 500 then phys:AddAngleVelocity( -phys:GetAngleVelocity()/1.25 ) end
            end
        else
            self:ResetSkin()
            self:ResetShowBones()
            self:ResetDisableShading()
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

            -- Update
            part:UpdatePos()
            part:UpdateAngles()

            part:SetSkin( self.Skin )
            part:SetFlagShowBone( self.ShowBones )
            part:SetFlagDisableShading( self.DisableShading )

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

--- Add a skin to the mech ( will also add to context menu )
-- @function Mech:AddSkin
-- @tparam Number ID -- Will not do anything if the model doesn't have a skin with this id
-- @tparam String Name
-- @usage Mech:AddSkin( 0, "SkinA" )
function Mech:AddSkin( id, name )
    if type( id ) ~= "number" then return end
    self.Skins[id] = name
end

--- Set the skin of the mech ( handled internally )
-- @function Mech:ResetSkin
function Mech:ResetSkin()
    if not self.CSHolograms then return end
    if self.Skin == self.Entity:GetMechSkin() then return end

    self.Skin = self.Entity:GetMechSkin()
    for i, part in pairs( self.CSHolograms ) do
        part:SetSkin( self.Skin )
        print( i )
    end
end

--- Draw the bones of the mech ( handled internally )
-- @function Mech:ResetShowBones
function Mech:ResetShowBones()
    if not self.CSHolograms then return end
    if self.ShowBones == self.Entity:GetShowBones() then return end

    self.ShowBones = self.Entity:GetShowBones()
    for i, part in pairs( self.CSHolograms ) do
        part:SetFlagShowBone( self.ShowBones )
    end
end

--- Disable the shading of the mech ( handled internally )
-- @function Mech:SetDisableShading
function Mech:ResetDisableShading( shading )
    if not self.CSHolograms then return end
    if self.DisableShading == self.Entity:GetDisableShading() then return end

    self.DisableShading = self.Entity:GetDisableShading()
    for i, part in pairs( self.CSHolograms ) do
        part:SetFlagDisableShading( self.DisableShading )
    end
end

--- Adds a walkcycle leg object to the mech
-- @function Mech:AddLeg
-- @tparam String Name
-- @tparam Vector Offset
-- @tparam Number StepOrder
-- @tparam Number GroundHeight
-- @return WalkCycleObj
-- @usage local Leg = Mech:AddLeg( "Right", Vector( 0, 20, 0 ), 0, 15 )
function Mech:AddLeg( name, offset, stepOrder, groundHeight )
    if not self.Entity then return nil end
    if not self.Legs then self.Legs = {} end
    self.Legs[name] = NML_CreateNewWalkCycle( self.Entity, offset, stepOrder, groundHeight )
    return self.Legs[name]
end

--- Runs every leg attached to the mech
-- @function Mech:RunAllLegs
-- @tparam Number WalkVel How fast the cycle runs
-- @tparam Vector AddVel How far the step will jump from it's current position
-- @usage Mech:RunAllLegs( Entity:GetVelocity():Length()/100, Entity:GetVelocity()/10 )
function Mech:RunAllLegs( walkVel, addVel )
    if not self.Legs then return end
    for _, leg in pairs( self.Legs ) do
        leg:Think( walkVel, addVel )
    end
end

--- Returns the difference between the height of two legs
-- @function Mech:GetLegDiff
-- @tparam Leg LegA
-- @tparam Leg LegB
-- @return Number Diff
-- @usage local HeightDiff = Mech:GetLegDiff( "Right", "Left" )
function Mech:GetLegDiff( legA, legB )
    if not self.Legs or not self.Legs[legA] or not self.Legs[legB] then return 0 end
    return ( ( self.Legs[legA].StepCurve - self.Legs[legA].StepPointC ) - ( self.Legs[legB].StepCurve - self.Legs[legB].StepPointC ) ).z
end
