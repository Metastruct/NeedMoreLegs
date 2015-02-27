------------------------------------------------------
---- Clientside Hologram Class
---- by shadowscion
------------------------------------------------------

local math   = math
local table  = table
local string = string
local render = render

------------------------------------------------------
---- CookieJar ( handles rendering of all holograms )
------------------------------------------------------

NML.CookieJar = NML.CookieJar or {}
local CookieJar = NML.CookieJar

function NML.GetCookieCount()
    for _, cookie in pairs( CookieJar ) do
        print( table.Count( cookie ) )
    end
end

local function BakeCookie( cookie, crumb )
    if not CookieJar[cookie] then
        CookieJar[cookie] = {}

        cookie:CallOnRemove( "GarbageDay", function( self )
            for _, crumb in pairs( CookieJar[self] ) do
                crumb = nil
            end
            CookieJar[self] = nil
            collectgarbage( "collect" )
        end )
    end

    table.insert( CookieJar[cookie], crumb )
end

hook.Remove( "PostDrawOpaqueRenderables", "DemCookiesIsDone" )
hook.Add( "PostDrawOpaqueRenderables", "DemCookiesIsDone", function( depth, sky )
    if not sky then return end
    for _, cookie in pairs( CookieJar ) do
        if not _.draw then continue end
        for _, crumb in pairs( cookie ) do
            crumb:Draw()
        end
    end
end )

--- Hologram Meta Object
-- @section


local Hologram = {}
Hologram.__index = Hologram

local template = {
    -- Entity
    Parent = nil,

    Pos  = Vector(), -- absolute position
    LPos = Vector(), -- position relative to parent
    Ang  = Angle(), -- absolute angles
    LAng = Angle(), -- angles relative to parent

    -- Properties
    Scale    = Matrix(),
    Scalar   = 1,
    Skin     = 0,
    Material = nil,
    Model    = "models/hunter/blocks/cube025x025x025.mdl",
    Color    = Color( 1, 1, 1, 1 ),

    -- Flags
    FLAG_SHOW_BONE  = false, -- a bone will be rendered between the hologram its parent
    FLAG_SHOW_AXES  = false, -- a gimbal indicator will be rendered at the hologram's position
    FLAG_SHADING    = false, -- engine lighting will be disabled

    FLAG_NODRAW     = false,
    FLAG_UPDATE_POS = false,
    FLAG_UPDATE_ANG = false,
}

--- Creates a new hologram object and attaches it to the CSEnt
-- @function NML_CSHologram
-- @tparam CSEnt CSEnt It must be a valid CSEnt
-- @return Hologram
-- @usage local Temp = NML_CSHologram( SomeCSEnt )
function NML_CSHologram( csent )
    if not IsValid( csent ) or type( csent ) ~= "CSEnt" then return end

    local self = table.Copy( template )

    self.CSEnt = csent

    setmetatable( self, Hologram )

    BakeCookie( csent, self )

    return self
end

--- Creates a new CSEnt container prop
-- @function NML_CSHolobase
-- @return CSEnt
-- @usage local Temp = NML_CSHolobase()
function NML_CSHolobase()
    local self = ClientsideModel( "models/error.mdl" )

    self:SetPos( Vector() )
    self:SetAngles( Angle() )
    self:SetNoDraw( true )
    self:Spawn()

    return self
end

--- Set Hologram Pos/Ang
-- @section

--- Set the hologram's absolute world position
-- @function Hologram:SetPos
-- @tparam Vector Pos
-- @usage Hologram:SetPos( Vector( 0, 0, 0 ) )
function Hologram:SetPos( vec )
    self.Pos = vec
    self.FLAG_UPDATE_POS = true
end

--- Set the hologram's absolute world angles
-- @function Hologram:SetAngles
-- @tparam Angle Ang
-- @usage Hologram:SetAngles( Angle( 0, 0, 0 ) )
function Hologram:SetAngles( ang )
    self.Ang = ang
    self.FLAG_UPDATE_ANG = true
end

--- Set Hologram properties
-- @section

--- Set the hologram's parent object
-- @function Hologram:SetParent
-- @tparam Parent Parent It can be an entity, player, or another hologram
-- @usage Hologram:SetParent( SomeOtherHologram )
function Hologram:SetParent( parent )
    if not IsValid( parent ) then return end

    self.Parent = parent
    self.FLAG_UPDATE_POS = true
    self.FLAG_UPDATE_ANG = true
end

--- Set the hologram's scale
-- @function Hologram:SetScale
-- @tparam Vector Scale If the hologram cannot be scaled by a vector, it will use a scalar of ( x + y + z )/3
-- @usage Hologram:SetScale( Vector( 1, 1, 1 ) )
function Hologram:SetScale( vec )
    self.Scalar = ( vec.x + vec.y + vec.z )/3
    self.Scale  = Matrix()
    self.Scale:Scale( vec )
end

--- Set the hologram's model
-- @function Hologram:SetModel
-- @tparam String Model Must be a valid model
-- @usage Hologram:SetModel( "models/error.mdl" )
function Hologram:SetModel( model )
    if not file.Exists( model, "GAME" ) then self.Model = "models/error.mdl" return end
    self.Model = model
end

--- Set the hologram's material
-- @function Hologram:SetMaterial
-- @tparam String Material Must be a valid material
-- @usage Hologram:SetMaterial( "models/debug/debugwhite" )
function Hologram:SetMaterial( material )
    if not file.Exists( string.format( "materials/%s.vmt", material ), "GAME" ) then self.Material = nil return end
    self.Material = material
end

--- Set the hologram's color
-- @function Hologram:SetColor
-- @tparam Color Color Alpha component is optional
-- @usage Hologram:SetColor( Color( 255, 255, 255, 255 ) )
function Hologram:SetColor( color )
    if not color then self.Color = Color( 1, 1, 1, 1 ) return end
    self.Color = Color( color.r/255, color.g/255, color.b/255, color.a/255 )
end

--- Set the hologram's alpha
-- @function Hologram:SetAlpha
-- @tparam Number Alpha
-- @usage Hologram:SetAlpha( 255 )
function Hologram:SetAlpha( alpha )
    if not alpha then self.color.a = 1 return end
    self.Color.a = alpha/255
end

--- Set the hologram's skin
-- @function Hologram:SetSkin
-- @tparam Number Skin
-- @usage Hologram:SetSkin( 0 )
function Hologram:SetSkin( skin )
    self.Skin = skin
end

--- Set Hologram Flags
-- @section

--- Disables engine lighting for the hologram
-- @function Hologram:SetFlagDisableShading
-- @tparam Bool Shading
-- @usage Hologram:SetFlagDisableShading( true )
function Hologram:SetFlagDisableShading( bool )
    self.FLAG_SHADING = bool or false
end

--- Renders a bone from the hologram's position to the hologram's parent's position
-- @function Hologram:SetFlagShowBone
-- @tparam Bool ShowBone
-- @usage Hologram:SetFlagShowBone( true )
function Hologram:SetFlagShowBone( bool )
    self.FLAG_SHOW_BONE = bool or false
end

--- Renders a gimbal marker at the hologram's position
-- @function Hologram:SetFlagShowAxes
-- @tparam Bool ShowAxes
-- @usage Hologram:SetFlagShowAxes( true )
function Hologram:SetFlagShowAxes( bool )
    self.FLAG_SHOW_AXES = bool or false
end

--- Get Hologram Vectors/Angles
-- @section

--- Return's the hologram's absolute world position
-- @function Hologram:GetPos
-- @return Vector Position
-- @usage local Pos = Hologram:GetPos()
function Hologram:GetPos()
    return self.Pos
end

--- Return's the hologram's absolute world angles
-- @function Hologram:GetAngles
-- @return Angle Angles
-- @usage local Ang = Hologram:GetAngles()
function Hologram:GetAngles()
    return self.Ang
end

--- Converts a world space vector to a vector local to the hologram
-- @function Hologram:WorldToLocal
-- @tparam Vector WorldVector
-- @return Vector LocalVector
-- @usage local LocalVec = Hologram:WorldToLocal( Vector( 0, 0, 50 ) )
function Hologram:WorldToLocal( wvector )
    local lvec, _ = WorldToLocal( wvector, Angle(), self:GetPos(), self:GetAngles() )
    return lvec
end

--- Converts a vector local to the hologram into a world space vector
-- @function Hologram:LocalToWorld
-- @tparam Vector LocalVector
-- @return Vector WorldVector
-- @usage local WorldVec = Hologram:LocalToWorld( Vector( 0, 0, 50 ) )
function Hologram:LocalToWorld( lvector )
    local wvec, _ = LocalToWorld( lvector, Angle(), self:GetPos(), self:GetAngles() )
    return wvec
end

--- Converts a world space angle to an angle local to the hologram
-- @function Hologram:WorldToLocalAngles
-- @tparam Angle WorldAngle
-- @return Angle LocalAngle
-- @usage local LocalAng = Hologram:WorldToLocalAngles( Angle( 0, 0, 50 ) )
function Hologram:WorldToLocalAngles( wangle )
    local _, lang = WorldToLocal( Vector(), wangle, self:GetPos(), self:GetAngles() )
    return lang
end

--- Converts an angle local to the hologram into a world space angle
-- @function Hologram:LocalToWorldAngles
-- @tparam Angle LocalAngle
-- @return Angle WorldAngle
-- @usage local WorldAng = Hologram:LocalToWorldAngles( Angle( 0, 0, 50 ) )
function Hologram:LocalToWorldAngles( langle )
    local _, wang = LocalToWorld( Vector(), langle, self:GetPos(), self:GetAngles() )
    return wang
end

--- Get Hologram Directions
-- @section

--- Return's the unit vector of the hologram's up axis
-- @function Hologram:GetUp
-- @return Vector UpAxis
-- @usage local Up = Hologram:GetUp()
function Hologram:GetUp()
    return self:GetAngles():Up()
end

--- Return's the unit vector of the hologram's right axis
-- @function Hologram:GetRight
-- @return Vector RightAxis
-- @usage local Right = Hologram:GetRight()
function Hologram:GetRight()
    return self:GetAngles():Right()
end

--- Return's the unit vector of the hologram's forward axis
-- @function Hologram:GetForward
-- @return Vector ForwardAxis
-- @usage local Forward = Hologram:GetForward()
function Hologram:GetForward()
    return self:GetAngles():Forward()
end

--- Return's the unit vectors of all of the hologram's axes
-- @function Hologram:GetDirections
-- @return[1] Vector UpAxis
-- @return[2] Vector RightAxis
-- @return[3] Vector ForwardAxis
-- @usage local Up, Right, Forward = Hologram:GetDirections()
function Hologram:GetDirections()
    return self:GetUp(), self:GetRight(), self:GetForward()
end

--- Get Hologram Properties
-- @section

--- Confirms that the hologram object is valid
-- @function Hologram:IsValid
-- @usage IsValid( Hologram )
function Hologram:IsValid()
    if not self or not IsValid( self.CSEnt ) then
        self = nil
        return false
    end
    return true
end

--- Return's the hologram's parent
-- @function Hologram:GetParent
-- @return Parent
-- @usage local Parent = Hologram:GetParent()
function Hologram:GetParent()
    return self.Parent
end

--- Return's the hologram's scale and scalar
-- @function Hologram:GetScale
-- @return[1] Vector Scale
-- @return[2] Number Scalar
-- @usage local Scale, Scalar = Hologram:GetScale()
function Hologram:GetScale()
    return self.Scale:GetScale(), self.Scalar
end

--- Return's the hologram's model
-- @function Hologram:GetModel
-- @return String Model
-- @usage local Model = Hologram:GetModel()
function Hologram:GetModel()
    return self.Model
end

--- Return's the hologram's material
-- @function Hologram:GetMaterial
-- @return String Material
-- @usage local Material = Hologram:SetMaterial()
function Hologram:GetMaterial()
    return self.Material
end

--- Return's the hologram's color
-- @function Hologram:GetColor
-- @return Color Color
-- @usage local Color = Hologram:GetColor()
function Hologram:GetColor()
    return Color( self.Color.r*255, self.Color.g*255, self.Color.b*255, self.Color.a*255 )
end

--- Return's the hologram's alpha
-- @function Hologram:GetAlpha
-- @return Number Alpha
-- @usage local Alpha = Hologram:GetAlpha()
function Hologram:GetAlpha()
    return self.Color.a*255
end


--- Drawing ( handled internally )
-- @section

--- Updates the hologram's position in the draw hook ( handled by cookiejar, do not call this function )
-- @function Hologram:UpdatePos
function Hologram:UpdatePos()
    if self.FLAG_UPDATE_POS then
        if self.Parent then self.LPos = self.Parent:WorldToLocal( self.Pos ) end
        self.CSEnt:SetRenderOrigin( self.Pos )
        self.FLAG_UPDATE_POS = false
        return
    end
    if self.Parent then self.Pos = self.Parent:LocalToWorld( self.LPos ) end
    self.CSEnt:SetRenderOrigin( self.Pos )
end

--- Updates the hologram's angles in the draw hook ( handled by cookiejar, do not call this function )
-- @function Hologram:UpdateAngles
function Hologram:UpdateAngles()
    if self.FLAG_UPDATE_ANG then
        if self.Parent then self.LAng = self.Parent:WorldToLocalAngles( self.Ang ) end
        self.CSEnt:SetRenderAngles( self.Ang )
        self.FLAG_UPDATE_ANG = false
        return
    end
    if self.Parent then self.Ang = self.Parent:LocalToWorldAngles( self.LAng ) end
    self.CSEnt:SetRenderAngles( self.Ang )
end

--- Updates the hologram's scale in the draw hook ( handled by cookiejar, do not call this function )
-- @function Hologram:UpdateScale
function Hologram:UpdateScale()
    if self.CSEnt.EnableMatrix then
        self.CSEnt:EnableMatrix( "RenderMultiply", self.Scale )
    else
        self.CSEnt:SetModelScale( self.Scalar, 0 )
    end
    self.CSEnt:SetupBones()
end

--- Updates the hologram's nodraw status in the draw hook ( handled by cookiejar, do not call this function )
-- @function Hologram:UpdateNoDraw
function Hologram:UpdateNoDraw()
    self.FLAG_NODRAW = ( self.CSEnt:GetRenderOrigin() - EyePos() ):Dot( EyeVector() ) < 0.5
end

--- Draws the hologram ( handled by cookiejar, do not call this function )
-- @function Hologram:Draw
function Hologram:Draw()
    if not IsValid( self ) then return end

    if self.FLAG_NODRAW then
        self:UpdatePos()
        self:UpdateNoDraw()
        return
    end

    self.CSEnt:SetModel( self.Model )
    self.CSEnt:SetMaterial( self.Material )
    self.CSEnt:SetSkin( self.Skin )

    self:UpdatePos()
    self:UpdateAngles()
    self:UpdateScale()
    self:UpdateNoDraw()

    render.SuppressEngineLighting( self.FLAG_SHADING )
    render.SetColorModulation( self.Color.r, self.Color.g, self.Color.b )
    render.SetBlend( self.Color.a )

    self.CSEnt:DrawModel()

    render.SuppressEngineLighting( false )
    render.SetColorModulation( 1, 1, 1 )
    render.SetBlend( 1 )

    self:DrawBones()
end

--- Draws the hologram bones ( handled by cookiejar, do not call this function )
-- @function Hologram:DrawBones
local boneMaterial = Material( "widgets/bone_small.png", "unlitsmooth" )
local boneColor = Color( 225, 225, 255, 225 )

function Hologram:DrawBones()
    if not self.FLAG_SHOW_BONE then return end
    if not self.Parent then return end

    cam.IgnoreZ( true )
        render.SetMaterial( boneMaterial )
        render.DrawBeam( self.Pos, self.Parent:GetPos(), self.Pos:Distance( self.Parent:GetPos() )*0.2, 0, 1, boneColor )
    cam.IgnoreZ( false )
end

--[[
function Hologram:SetPos( vec )
    if self.Parent then self.LPos = self.Parent:WorldToLocal( vec ) end
    self.Pos = vec
    self.FLAG_UPDATE_POS = true
end

function Hologram:SetAngles( ang )
    if self.Parent then self.LAng = self.Parent:WorldToLocalAngles( ang ) end
    self.Ang = ang
    self.FLAG_UPDATE_ANG = true
end

function Hologram:SetParent( parent )
    self.Parent = parent

    self.LPos = self.Parent:WorldToLocal( self.Pos )
    self.LAng = self.Parent:WorldToLocalAngles( self.Ang )

    self.FLAG_UPDATE_POS = false
    self.FLAG_UPDATE_ANG = false
end

function Hologram:UpdatePos()
    if self.FLAG_UPDATE_POS then
        self.CSEnt:SetRenderOrigin( self.Pos )
        self.FLAG_UPDATE_POS = false
        return
    end
    if self.Parent then
        self.CSEnt:SetRenderOrigin( self.Parent:LocalToWorld( self.LPos ) )
        return
    end
    self.CSEnt:SetRenderOrigin( self.Pos )
end

function Hologram:UpdateAngles()
    if self.FLAG_UPDATE_ANG then
        self.CSEnt:SetRenderAngles( self.Ang )
        self.FLAG_UPDATE_ANG = false
        return
    end
    if self.Parent then
        self.CSEnt:SetRenderAngles( self.Parent:LocalToWorldAngles( self.LAng ) )
        return
    end
    self.CSEnt:SetRenderAngles( self.Ang )
end
]]--
