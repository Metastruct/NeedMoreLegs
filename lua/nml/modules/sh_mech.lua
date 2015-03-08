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
                self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
                self.Entity:SetSolid( SOLID_VPHYSICS )
                self.Entity:PhysicsInit( SOLID_VPHYSICS )
            else
                /*local cube = {
                    Vector( 0, 0, 0 ),
                    Vector( 0, 0, 1 ),
                    Vector( 0, 1, 0 ),
                    Vector( 0, 1, 1 ),
                    Vector( 1, 0, 0 ),
                    Vector( 1, 0, 1 ),
                    Vector( 1, 1, 0 ),
                    Vector( 1, 1, 1 ),
                }
                local mesh = {}
                for _, vec in pairs( cube ) do
                    mesh[_] = { pos = vec*100 }
                end
                self.Entity:PhysicsInitConvex( mesh )
                self.Entity:EnableCustomCollisions( true )*/

                local pboxmin, pboxmax, cboxmin, cboxmax = unpack( self.Physics )
                self.Entity:SetMoveType( MOVETYPE_CUSTOM )
                self.Entity:SetSolid( SOLID_CUSTOM )
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
            self:UpdateSkin()
            self:UpdateShading()
            self:UpdateBones()
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

function Mech:AddSkin( id, name )
    self.SkinTable[id] = name
end

function Mech:UpdateSkin()
    if self.Skin ~= self.Entity:GetMechSkin() then
        self.Skin = self.Entity:GetMechSkin()

        if not self.CSHolograms then return end
        for _, part in pairs( self.CSHolograms ) do
            part:SetSkin( self.Skin )
        end
    end
end

function Mech:UpdateShading()
    if self.Shading ~= self.Entity:GetMechToggleShading() then
        self.Shading = self.Entity:GetMechToggleShading()

        if not self.CSHolograms then return end
        for _, part in pairs( self.CSHolograms ) do
            part:SetFlagDisableShading( self.Shading )
        end
    end
end

function Mech:UpdateBones()
    if self.Bones ~= self.Entity:GetMechToggleBones() then
        self.Bones = self.Entity:GetMechToggleBones()

        if not self.CSHolograms then return end
        for _, part in pairs( self.CSHolograms ) do
            part:SetFlagShowBone( self.Bones )
        end
    end
end

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
        part:SetModel( info.Model or part.Model )
        part:SetMaterial( info.Material or nil )
        part:SetScale( info.Scale or Vector( 1, 1, 1 ) )

        -- Update
        part:UpdatePos()
        part:UpdateAngles()

        part:SetSkin( self.Skin or 0 )
        part:SetFlagDisableShading( self.Shading or false )
        part:SetFlagShowBone( self.Bones or false )

        self.CSHolograms[i] = part
    end

    self.CSHolobase.draw = true
end

--- Gait System - by Metamist
-- @section

local Helper = Addon.Helper

local clampVec = Helper.ClampVec
local bezierCurve = Helper.Bezier
local traceDirection = Helper.TraceDirection
local traceToVector = Helper.TraceToVector

function Mech:CreateGait( id, footOffset, legLength )
    if not self.Gaits then
        self.Gaits     = {}
        self.WalkCycle = 0
        self.WalkVel   = 0
        self.GaitCount = 0
    end

    local pos = traceDirection( 500, self.Entity:LocalToWorld( footOffset or Vector() ), Vector( 0, 0, -1 ), nil, MASK_SOLID_BRUSHONLY ).HitPos
    self.Gaits[id] = {
        FootData = {
            Offset = footOffset or Vector(),
            LegLength = legLength or 0,
            Prev = pos,
            Dest = pos,
            Pos = pos,
            IsMoving = false,
            ShouldMove = false,
            Height = 0,
        }
    }
    self.GaitCount = self.GaitCount + 1
end

function Mech:SetGaitStart( id, start, len )
    if not self.Gaits or not self.Gaits[id] then return end
    local start = start - math.floor( start )
    self.Gaits[id].Start = start
    self.Gaits[id].Stop = start + len
end


function Mech:RunGaitSequence()
    if not self.Gaits then return end

    local filter = table.Add( { self.Entity, self.Entity:GetMechPilotSeat() }, player.GetAll() )

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

            local vel = self.Entity:GetVelocity()/( self.AddVel or 3 )
                --vel.z = 0

            --local traceStart = self.Entity:LocalToWorld( Foot.Offset ) + vel


/*
            local trace = util.TraceLine( {
                start = self.Entity:GetPos(),
                endpos = self.Entity:LocalToWorld( Foot.Offset ) + vel,
                filter = filter,
            } )

            if not trace.Hit then
                trace = util.TraceLine( {
                    start = trace.HitPos,
                    endpos = trace.HitPos - self.Entity:GetUp()*Foot.LegLength*2, -- + Vector( 0, 0, -Foot.LegLength*2 ),
                    filter = filter,
                } )
            end*/

            local preTrace = traceToVector( self.Entity:GetPos(), self.Entity:LocalToWorld( Foot.Offset ), filter ).HitPos
            local midTrace = traceToVector( preTrace, preTrace + vel, filter )
            local endTrace = traceDirection( Foot.LegLength*2, midTrace.HitPos, -self.Entity:GetUp(), filter )

            local trace = midTrace.Hit and midTrace or endTrace


            Foot.Trace = trace

            if gmove then
                Foot.Dest = trace.HitPos

                if not Foot.IsMoving then
                    Foot.Prev = Foot.Pos
                    --Foot.Prev.Z = trace.HitPos.z
                    --Foot.Prev = trace.HitPos

                    if Foot.Pos:Distance( trace.HitPos ) >= 4 then
                        local dot = 0
                        if trace.Hit then
                            --dot = 1 - Vector( 0, 0, 1 ):Dot( trace.HitNormal )
                            dot = 1 - self.Entity:GetUp():Dot( trace.HitNormal )
                        end

                        local dist = trace.StartPos:Distance( trace.HitPos )
                        local vel = self.Entity:GetVelocity()
                            --vel.z = 0

                        local thresh = Foot.LegLength + dot*100*math.Clamp( vel:Length()/100, 0, Foot.LegLength/2 )
                        if  dist <= thresh then
                            Foot.ShouldMove = true

                            if Gait.StepStartEvent then Gait.StepStartEvent( Foot.Pos, vel:Length() ) end
                        end
                    end
                end

                if Foot.ShouldMove then
                    local prev = Foot.Prev
                    local dest = trace.HitPos
                    local mid = ( dest + prev )/2 + trace.HitNormal*math.Clamp( prev:Distance( dest )/4, 0, self.Height )
                    --local mid = ( dest + prev )/2 + Vector( 0, 0, math.Clamp( prev:Distance( dest )/4, 0, self.Height ) )

                    local bezPos = bezierCurve( prev, mid, dest, gfract )
                    Foot.Pos = bezPos

                    Foot.Height = bezPos.z - dest.z
                    --Foot.Height = bezPos:Distance( dest )
                    Foot.LastMove = true
                else
                    Foot.Height = 0
                end
            else
                if Foot.LastMove then
                    Foot.Pos = Foot.Dest
                    Foot.LastMove = false

                    if Gait.StepStopEvent then Gait.StepStopEvent( Foot.Pos, Foot.Height ) end
                end
                Foot.ShouldMove = false
                Foot.Height = 0
            end

            Foot.IsMoving = gmove and Foot.ShouldMove
        end
    end

    if self.WalkCycle > 1 then self.WalkCycle = 0 end
end

function Mech:SetGaitStepStartEvent( name, cbk )
    if not cbk then return end
    if not self.Gaits then return end
    if not self.Gaits[name] then return end
    self.Gaits[name].StepStartEvent = cbk
end

function Mech:SetGaitStepStopEvent( name, cbk )
    if not cbk then return end
    if not self.Gaits then return end
    if not self.Gaits[name] then return end
    self.Gaits[name].StepStopEvent = cbk
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
        function( ply )
            if not self.Gaits then return false end
            if self.Entity:GetMechPilot() ~= ply then return false end
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

                    local tx = posx + width*gaitStop - 1
                    local ty = gpy - height*3 + sep*cnt
                    local txt = "Start: " .. math.Round( gaitStart, 4 ) .. "\nStop: " ..  math.Round( gaitStop, 4 )

                    draw.DrawText( txt, "Default", tx + 2, ty, gdbg_colorC, 0 )
                    surface.DrawLine( tx, gpy, tx, ty )
                else
                    local gpx = posx + width*gaitStart
                    local gpy = h - height - posy + sep*cnt
                    local sx = width*gaitStop - width*gaitStart

                    drawFilledRect( gpx, gpy, sx, sep, ( self.WalkCycle >= gaitStart and self.WalkCycle <= gaitStop ) and gdbg_colorA or gdbg_colorB, _ )

                    local tx = gpx + sx + 2
                    local ty = gpy - height*3 + sep*cnt
                    local txt = "Start: " .. math.Round( gaitStart, 4 ) .. "\nStop: " ..  math.Round( gaitStop, 4 )

                    draw.DrawText( txt, "Default", tx, ty, gdbg_colorC, 0 )
                    surface.DrawLine( gpx + sx - 1, gpy, gpx + sx - 1, ty )
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
