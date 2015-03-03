------------------------------------------------------
---- Shared Mech Class
---- by shadowscion & Metamist
------------------------------------------------------

local Addon = NML or {}

local math   = math
local util   = util
local table  = table
local string = string
local render = render

------------------------------------------------------
---- Meta Object
------------------------------------------------------

local Mech = {}
Mech.__index = Mech

--- Creates a new mech type
-- @function CreateMechType
-- @tparam String Name
-- @tparam String ListName
-- @return MechType
-- @usage local Mech = CreateMechType( "Base_Mech", "MyAddonList" )
function Addon.CreateMechType( name, listname )
    if not name or not listname then return end
    if type( name ) ~= "string" or type( listname ) ~= "string" then return end

    local self = { Name = name }

    if CLIENT then self.SkinTable = {} end

    list.Set( listname, name, self )

    setmetatable( self, Mech )

    return self
end

--- Returns an existing mech type
-- @function GetMechType
-- @tparam String Name
-- @tparam String ListName
-- @return MechType
-- @usage local Mech = GetMechType( "Base_Mech", "MyAddonList" )
function Addon.GetMechType( name, listname )
    local availableTypes = list.Get( listname or "" )
    if not availableTypes or not availableTypes[name] then return end
    return table.Copy( availableTypes[name] )
end

function Mech:__tostring()
    return ""
end

--- Set Initialize and Think functions
-- @section

--- Sets the Initialize meta function of a mech
-- @function Mech:SetInit
-- @tparam Function InitFunc
-- @usage Mech:SetInit( function() print( "init" ) end )
function Mech:SetInitialize( setFunc )
    self.Initialize = function( self )
        if not self.Name then return end
        if not IsValid( self.Entity ) then return end

        -- Creates a base hologram entity for the mech to use
        if CLIENT and Addon.CookieJar then
            self.CSHolobase = Addon.CSHolobase()
            self.CSHolograms = {}

            self.Entity:CallOnRemove( "GarbageDay", function( garbage )
                self.CSHolobase:Remove()
                self.CSHolograms = nil

                Addon.HUD[self.UniqueID] = nil

                timer.Simple( 0.5, function()
                    if not IsValid( garbage ) then return end
                    if not self.Initialize then return end
                    self:Initialize()
                end )
            end )
        end

        if SERVER then
            if not self.Physics then
                self.Entity:PhysicsInit( SOLID_VPHYSICS )
                self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
                self.Entity:SetSolid( SOLID_VPHYSICS )
            else
                local pboxmin, pboxmax, cboxmin, cboxmax = unpack( self.Physics )
                self.Entity:PhysicsInitBox( pboxmin, pboxmax )
                self.Entity:SetCollisionBounds( cboxmin or pboxmin, pboxmax or cboxmax )
            end

            local phys = self.Entity:GetPhysicsObject()
            if IsValid( phys ) then
                phys:SetMass( 5000 )
                phys:EnableDrag( false )
                phys:EnableGravity( false )
                phys:EnableMotion( false )
                phys:Wake()
            end
        end

        setFunc( self, self.Entity )

        self:StartThink()
    end
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

    hook.Add( "Think", "nml_think_" .. self.UniqueID, function()
        if not self.Think then self:StopThink() return end
        if not IsValid( self.Entity ) then self:StopThink() return end

        if SERVER then
            self.Entity:SetMechPilot( self.Entity:GetMechPilotSeat():GetDriver() or nil )

            local phys = self.Entity:GetPhysicsObject()
            if IsValid( phys ) then
                phys:EnableMotion( true )

                if phys:GetVelocity():Length() > 1000 then phys:AddVelocity( -phys:GetVelocity()/1.25 ) end
                if phys:GetAngleVelocity():Length() > 500 then phys:AddAngleVelocity( -phys:GetAngleVelocity()/1.25 ) end
            end
        else

        end

        self:Think( self.Entity, self.Entity:GetMechPilotSeat(), self.Entity:GetMechPilot(), FrameTime() )
    end )
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


--- Serverside functions
-- @section

if SERVER then

    --- Sets a custom physics and collision box
    -- @function Mech:SetPhysicsBox
    -- @tparam Vector PBoxMin Required
    -- @tparam Vector PBoxMax Required
    -- @tparam[opt=PBoxMin] Vector CBoxMin
    -- @tparam[opt=PBoxMax] Vector CBoxMax
    -- @usage Mech:SetPhysicsBox( Vector( -50, -50, -50 ) Vector( 50, 50, 50 ) )
    function Mech:SetPhysicsBox( pboxmin, pboxmax, cboxmin, cboxmax )
        if not pboxmin or not pboxmax then return end
        self.Physics = { pboxmin, pboxmax, cboxmin or nil, cboxmax or nil }
    end

end

--- Clientside functions
-- @section

if not CLIENT then return end

--- Loads a model from a table of values
-- @function Mech:LoadModelFromData
-- @tparam Table Data { Position=Vector(), Angle=Angle(), Model="String", Material="String" }
-- @usage Mech:LoadModelFromData( schematic )
function Mech:LoadModelFromData( data )
    if not self.Entity then return end
    if not self.CSHolobase then return end
    if not self.CSHolograms then return end

    for i, info in ipairs( data ) do
        local part = Addon.CSHologram( self.CSHolobase )
        local partParent = self.CSHolograms[info.Parent] and self.CSHolograms[info.Parent] or self.Entity

        part:SetParent( partParent )
        part:SetPos( partParent:LocalToWorld( info.Position or Vector() ) )
        part:SetAngles( partParent:LocalToWorldAngles( info.Angle or Angle() ) )
        part:SetModel( info.Model or "" )
        part:SetMaterial( info.Material or nil )

        -- Update
        part:UpdatePos()
        part:UpdateAngles()

        self.CSHolograms[i] = part
    end

    self.CSHolobase.draw = true
end

--- Gait System - by Metamist
-- @section

local clampVec = Addon.Helper.ClampVec
local bezierCurve = Addon.Helper.Bezier
local traceDirection = Addon.Helper.TraceDirection

function Mech:CreateGait( id, footOffset, legLength )
    if not self.Gaits then
        self.Gaits     = {}
        self.WalkCycle = 0
        self.WalkVel   = 0
        self.GaitCount = 0
    end

    self.Gaits[id] = {
        FootData = {
            Offset = footOffset or Vector(),
            LegLength = legLength or 0,
            Prev = self.Entity:LocalToWorld( footOffset or Vector() ),
            Dest = self.Entity:LocalToWorld( footOffset or Vector() ),
            Pos = self.Entity:LocalToWorld( footOffset or Vector() ),
            IsMoving = false,
            ShouldMove = false,
            Height = 0,
        }
    }
    self.GaitCount = self.GaitCount + 1
end

function Mech:SetGaitStart( id, start, len )
    if not self.Gaits or not self.Gaits[id] then return end
    self.Gaits[id].Start = start
    self.Gaits[id].Stop = start + len
end

function Mech:RunGaitSequence()
    if not self.Gaits then return end

    for _, Gait in pairs( self.Gaits ) do
        local gstart = Gait.Start
        local gstop = Gait.Stop
        local gfract = 0
        local gmove = false

        if self.WalkCycle >= gstart and self.WalkCycle <= gstop then
            gfract = ( self.WalkCycle - gstart )/( gstop - gstart )
            gmove = true
        end

        if gstart < 0 then
            if self.WalkCycle >= math.abs( gstart ) and self.WalkCycle <= 1 then
                gfract = ( self.WalkCycle - gstart )/( gstop - gstart )
                gmove = true
            end
        elseif gstop > 1 then
            if self.WalkCycle + 1 >= gstart and self.WalkCycle + 1 <= gstop then
                gfract = ( self.WalkCycle + 1 - gstart )/( gstop - gstart )
                gmove = true
            end
        end

        if Gait.FootData then
            local Foot = Gait.FootData

            local vel = self.Entity:GetVelocity()/3
            --vel.z = 0

            local traceStart = self.Entity:LocalToWorld( Foot.Offset ) + vel
            local trace = util.TraceLine( {
                start = traceStart,
                endpos = traceStart + Vector( 0, 0, -1 )*Foot.LegLength*2,
                filter = nil,
                mask = MASK_SOLID_BRUSHONLY,
            } )

            -- local trace = util.TraceHull( {
            --     start = traceStart,
            --     endpos = traceStart + Vector( 0, 0, -1 )*Foot.LegLength*2,
            --     filter = nil,
            --     mask = MASK_SOLID_BRUSHONLY,
            --     mins = Vector( -15, -15, 0 ),
            --     maxs = Vector( 15, 15, 0 ),
            -- } )

            Foot.Trace = trace

            if gmove then
                Foot.Dest = trace.HitPos

                if not Foot.IsMoving then
                    Foot.Prev = Foot.Pos
                    Foot.Prev.Z = trace.HitPos.z

                    if Foot.Pos:Distance( trace.HitPos ) >= 4 then
                        local dot = 0
                        if trace.Hit then
                            dot = 1 - Vector( 0, 0, 1 ):Dot( trace.HitNormal )
                        end

                        local dist = trace.StartPos:Distance( trace.HitPos )
                        local vel = self.Entity:GetVelocity()
                            vel.z = 0

                        local thresh = Foot.LegLength + dot*100*math.Clamp( vel:Length()/100, 0, Foot.LegLength/2 )
                        if  dist <= thresh then
                            Foot.ShouldMove = true
                        end
                    end
                end

                if Foot.ShouldMove then
                    local prev = Foot.Prev
                    local dest = trace.HitPos
                    local mid = ( dest + prev )/2 + Vector( 0, 0, math.Clamp( prev:Distance( dest )/4, 0, self.Height ) )

                    local bezPos = bezierCurve( prev, mid, dest, gfract )
                    Foot.Pos = bezPos

                    Foot.Height = bezPos.z - dest.z
                    Foot.LastMove = true
                else
                    Foot.Height = 0
                end
            else
                if Foot.LastMove then
                    Foot.Pos = Foot.Dest
                    Foot.LastMove = false

                    -- play sounds
                end
                Foot.ShouldMove = false
                Foot.Height = 0
            end

            Foot.IsMoving = gmove and Foot.ShouldMove
        end
    end

    if self.WalkCycle > 1 then self.WalkCycle = 0 end
end

--- Returns the difference between the height of two legs
-- @function Mech:GetGaitDiff
-- @tparam Leg LegA
-- @tparam Leg LegB
-- @return Number Diff
-- @usage local HeightDiff = Mech:GetGaitDiff( "Right", "Left" )
function Mech:GetGaitDiff( legA, legB )
    if not self.Gaits or not self.Gaits[legA] or not self.Gaits[legB] then return 0 end
    local a = self.Gaits[legA].FootData
    local b = self.Gaits[legB].FootData
    --return ( a.Pos - b.Pos ).z
    return a.Height - b.Height
    --return ( ( a.Pos - a.Trace.HitPos ) - ( b.Pos - b.Trace.HitPos ) ).z
end

--- HUD Functions
-- @section

local gdbg_colorA = Color( 255, 255, 255, 255 )
local gdbg_colorB = Color( 255, 255, 255, 90 )
local gdbg_colorC = Color( 0, 0, 0, 255 )
local gdbg_colorD = Color( 255, 255, 0, 255 )
local gdbg_colorE = Color( 0, 125, 0, 50 )

local function drawFilledRect( posx, posy, sizex, sizey, color, text )
    surface.SetDrawColor( color )
    surface.DrawRect( posx, posy, sizex, sizey )
    surface.SetDrawColor( gdbg_colorC )
    surface.DrawOutlinedRect( posx, posy, sizex, sizey )

    if text then
        surface.SetTextColor( gdbg_colorC )
        surface.SetFont( "Default" )
        surface.SetTextPos( posx + sizex/2, posy + sizey/2 - 6 )
        surface.DrawText( text )
    end
end
Addon.DrawFilledRect = drawFilledRect

--- Adds a debug bar for visualizing the gait timing
-- @function Mech:AddGaitDebugBar
-- @tparam Number PosX
-- @tparam Number PosY
-- @tparam Number Height
-- @tparam Number Width
-- @usage Mech:AddGaitDebugBar( 64, 64, 96, 96*4 )
function Mech:AddGaitDebugBar( posx, posy, height, width )
    self:AddHudElement(
        function()
            if not self.Gaits then return false end
            return true
        end,

        function( ply, h, w )
            -- Background
            drawFilledRect( posx, h - height - posy, width, height, gdbg_colorE )

            -- Gaits
            local sep = height/table.Count( self.Gaits )
            local cnt = -1

            for _, gait in pairs( self.Gaits ) do
                cnt = cnt + 1

                local gaitStart = ( gait.Start or 0 ) % 1
                local gaitStop = ( gait.Stop or 0 ) % 1

                if gaitStart > gaitStop then
                    local gpx = posx + width*gaitStart
                    local gpy = h - height - posy + sep*cnt
                    local sx = width - gpx + posx

                    local color = ( self.WalkCycle >= gaitStart or self.WalkCycle <= gaitStop ) and gdbg_colorA or gdbg_colorB
                    drawFilledRect( gpx, gpy, sx, sep, color, _ )
                    drawFilledRect( posx, gpy, width*gaitStop, sep, color, _ )
                else
                    local gpx = posx + width*gaitStart
                    local gpy = h - height - posy + sep*cnt
                    local sx = width*gaitStop - width*gaitStart

                    drawFilledRect( gpx, gpy, sx, sep, ( self.WalkCycle >= gaitStart and self.WalkCycle <= gaitStop ) and gdbg_colorA or gdbg_colorB, _ )
                end
            end

            -- Walkcycle Bar
            drawFilledRect( posx + width*self.WalkCycle, h - height - posy, 5, height, gdbg_colorD )
        end
    )
end

--- Adds a hud element to the mech
-- @function Mech:AddHudElement
-- @tparam Function Condition If false, the hud element will not be drawn ( args: ply )
-- @tparam Function Callback ( args: ply, scrh, scrw )
-- @usage Mech:AddGaitDebugBar( function() return true end, function() surface.DrawRect( 0, 0, 64, 64 ) end )
function Mech:AddHudElement( cnd, cbk )
    Addon.HUD = Addon.HUD or {}
    Addon.HUD[self.UniqueID] = Addon.HUD[self.UniqueID] or {}

    table.insert( Addon.HUD[self.UniqueID], {
        cnd = cnd,
        cbk = cbk,
    } )
end
