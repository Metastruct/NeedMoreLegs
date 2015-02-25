----------------------------------------------------------------------------------
--- Clientside Hologram Class - by shadowscion
----------------------------------------------------------------------------------

collectgarbage( "collect" )

NML = NML or {}
local NML = NML

NML.Hologram = NML.Hologram or {}
local Hologram = NML.Hologram

local math = math
local file = file
local table = table
local string = string
local render = render
local assert = assert
local setmetatable = setmetatable

----------------------------------------------------------------------------------

Hologram.CookieJar = Hologram.CookieJar or {}
local CookieJar = Hologram.CookieJar

local function bake( entity, cookie )
    if not CookieJar[entity] then
        CookieJar[entity] = {}
        entity:CallOnRemove( "RemoveHolograms", function( self )
            for _, holo in pairs( CookieJar[self] ) do
                holo:Remove()
            end
            CookieJar[self] = nil
        end )
    end

    table.insert( CookieJar[entity], cookie )
end

hook.Add( "PostDrawOpaqueRenderables", "HologramDrawHook", function()
    for _, cookie in pairs( CookieJar ) do
        if not _.draw then continue end
        for _, crumb in pairs( cookie ) do
            crumb:Draw()
        end
    end
end )

--[[
hook.Add( "HUDPaint", "HologramDrawHook", function()
    for _, cookie in pairs( CookieJar ) do
        for i, crumb in pairs( cookie ) do
            local vec = crumb:GetPos():ToScreen()
            draw.DrawText( "" .. i, "BudgetLabel", vec.x, vec.y, Color( 175, 175, 225, 255 ), 1 )
        end
    end
end )
]]--

----------------------------------------------------------------------------------

local meta = {}
meta.__index = meta

function Hologram.CreateHologram( entity )
    assert( IsValid( entity ) and type( entity ) == "CSEnt", "ERROR: Holograms must be attached to a CSEnt!" )

    local self = {}

    setmetatable( self, meta )

    self:Init( entity )

    return self
end

function Hologram.CreateEntity()
    local self = ClientsideModel( "models/error.mdl" )

    self:SetPos( Vector( 0, 0, 0 ) )
    self:SetAngles( Angle( 0, 0, 0 ) )
    self:SetNoDraw( true )
    self:DrawShadow( false )
    self:Spawn()

    return self
end

----------------------------------------------------------------------------------

function meta:Init( entity )
    -- data
    self.entity  = entity or self.entity
    self.parent  = nil
    self.creator = nil

    self.pos  = Vector( 0, 0, 0 )
    self.lpos = Vector( 0, 0, 0 )
    self.ang  = Angle( 0, 0, 0 )
    self.lang = Angle( 0, 0, 0 )

    -- properties
    self.scalar   = 1
    self.scale    = Vector( 1, 1, 1 )
    self.color    = Color( 1, 1, 1, 1 )
    self.model    = "models/error.mdl"
    self.material = nil
    self.skin     = nil

    -- flags
    self.flags = {
        nodraw    = true,
        updatepos = false,
        updateang = false,
        shading   = false, -- disables engine lighting on the hologram
        showbones = false, -- draws a bone between the hologram and its parent
        showaxes  = false, -- displays a gimbal marker over the hologram
    }

    bake( self.entity, self )
end

function meta:Reset()
    self:Init()
end

function meta:Remove() -- DOESN'T WORK!!!!!!!!
    self = nil
end

function meta:IsValid()
    if not self or not IsValid( self.entity ) then
        self:Remove()
        return false
    end
    return true
end

function meta:__tostring()
    return string.format( "[%s][%s][%s]", self.creator and self.creator:GetName() or "NULL_CREATOR", self.entity:EntIndex(), self.model )
end

----------------------------------------------------------------------------------

function meta:UpdatePos()
    if self.flags.updatepos then
        if IsValid( self.parent ) then self.lpos = self.parent:WorldToLocal( self.pos ) else self.parent = nil end

        self.entity:SetRenderOrigin( self.pos )
        self.flags.updatepos = false

        return
    end

    if IsValid( self.parent ) then self.pos = self.parent:LocalToWorld( self.lpos ) else self.parent = nil end

    self.entity:SetRenderOrigin( self.pos )
end

function meta:UpdateAngles()
    if self.flags.updateang then
        if IsValid( self.parent ) then self.lang = self.parent:WorldToLocalAngles( self.ang ) else self.parent = nil end

        self.entity:SetRenderAngles( self.ang )
        self.flags.updateang = false

        return
    end

    if IsValid( self.parent ) then self.ang = self.parent:LocalToWorldAngles( self.lang ) else self.parent = nil end

    self.entity:SetRenderAngles( self.ang )
end

function meta:UpdateScale()
    if self.entity.EnableMatrix then
        local matrix = Matrix()
        matrix:Scale( self.scale )

        self.entity:EnableMatrix( "RenderMultiply", matrix )
    else
        self.entity:SetModelScale( self.scalar, 0 )
    end

    self.entity:SetupBones()
end

function meta:UpdateNoDraw()
     self.flags.nodraw = ( self:GetPos() - EyePos() ):Dot( EyeVector() ) < 0.5
end

local boneMaterial = Material( "widgets/bone_small.png", "unlitsmooth" )
local boneColor = Color( 225, 225, 255, 225 )

function meta:DrawBones()
    if not self.flags.showbones then return end
    if not self.parent then return end

    cam.IgnoreZ( true )
        render.SetMaterial( boneMaterial )
        render.DrawBeam( self.pos, self.parent:GetPos(), self.pos:Distance( self.parent:GetPos() ) * 0.2, 0, 1, boneColor )
    cam.IgnoreZ( false )
end

function meta:Draw()
    if not IsValid( self ) then return end

    if self.flags.nodraw then
        self:UpdatePos()
        self:UpdateNoDraw()
        return
    end

    self.entity:SetModel( self.model )
    self.entity:SetMaterial( self.material )
    self.entity:SetSkin( self.skin or 0 )

    self:UpdatePos()
    self:UpdateAngles()
    self:UpdateScale()
    self:UpdateNoDraw()

    render.SuppressEngineLighting( self.flags.shading )
    render.SetColorModulation( self.color.r, self.color.g, self.color.b )
    render.SetBlend( self.color.a )

    self.entity:DrawModel()

    render.SuppressEngineLighting( false )
    render.SetColorModulation( 1, 1, 1 )
    render.SetBlend( 1 )

    self:DrawBones()
end

----------------------------------------------------------------------------------

function meta:SetParent( parent )
    if not IsValid( parent ) then return end

    self.parent = parent
    self.flags.updatepos = true
    self.flags.updateang = true
end

function meta:SetPos( vec )
    self.pos = vec
    self.flags.updatepos = true
end

function meta:SetAngles( ang )
    self.ang = ang
    self.flags.updateang = true
end

function meta:SetScale( vec )
    self.scale = vec
    self.scalar = ( vec.x + vec.y + vec.z ) / 3
end

function meta:SetModel( model )
    -- if not util.IsValidModel( model ) then self.model = "models / error.mdl" return end
    if not file.Exists( model, "GAME" ) then self.model = "models/error.mdl" return end
    self.model = model
end

function meta:SetMaterial( material )
    if not file.Exists( string.format( "materials/%s.vmt", material ), "GAME" ) then self.material = nil return end
    self.material = material
end

function meta:SetColor( color )
    if not color then self.color = Color( 1, 1, 1, 1 ) return end
    self.color = Color( color.r / 255, color.g / 255, color.b / 255, color.a / 255 )
end

function meta:SetAlpha( alpha )
    if not alpha then self.color.a = 1 return end
    self.color.a = alpha / 255
end

function meta:SetDisableShading( shading )
    self.flags.shading = shading or false
end

function meta:SetDisplayBones( drawBones )
    self.flags.showbones = drawBones or false
end

function meta:SetSkin( skin )
    self.skin = skin or nil
end

function meta:SetNoDraw( nodraw )
    self.flags.nodraw = nodraw or false
end

----------------------------------------------------------------------------------

function meta:GetEntity()
    return self.entity
end

function meta:GetParent()
    return self.parent
end

function meta:GetPos()
    return self.pos
end

function meta:GetAngles()
    return self.ang
end

function meta:GetScale()
    return self.scale, self.scalar
end

function meta:GetModel()
    return self.model
end

function meta:GetMaterial()
    return self.material
end

function meta:GetColor()
    return Color( self.color.r * 255, self.color.g * 255, self.color.b * 255, self.color.a * 255 )
end

function meta:GetAlpha()
    return self.color.a * 255
end

----------------------------------------------------------------------------------

function meta:GetUp()
    return self:GetAngles():Up()
end

function meta:GetForward()
    return self:GetAngles():Forward()
end

function meta:GetRight()
    return self:GetAngles():Right()
end

function meta:WorldToLocal( wvector )
    local lvec, _ = WorldToLocal( wvector, Angle(), self:GetPos(), self:GetAngles() )
    return lvec
end

function meta:LocalToWorld( lvector )
    local wvec, _ = LocalToWorld( lvector, Angle(), self:GetPos(), self:GetAngles() )
    return wvec
end

function meta:WorldToLocalAngles( wangle )
    local _, lang = WorldToLocal( Vector(), wangle, self:GetPos(), self:GetAngles() )
    return lang
end

function meta:LocalToWorldAngles( langle )
    local _, wang = LocalToWorld( Vector(), langle, self:GetPos(), self:GetAngles() )
    return wang
end

----------------------------------------------------------------------------------
