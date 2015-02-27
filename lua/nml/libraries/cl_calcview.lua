----------------------------------------------------------------------------------
---- NML Camera - by shadowscion
----------------------------------------------------------------------------------

local view = {
    origin = Vector(),
    angles = Angle(),
}

local trace = {
    mask = MASK_SOLID_BRUSHONLY,
}

local zoom = 200
local reset = true

----------------------------------------------------------------------------------

local function ShouldEnable( ply )
    if not ply:InVehicle() or not IsValid( ply:GetVehicle():GetParent() ) then return false end
    if ply:GetVehicle():GetParent():GetClass() ~= "sent_nml_base" then return false end
    if not ply:GetVehicle():GetThirdPersonMode() then return false end
    if not ply:Alive() or ply:GetViewEntity() ~= ply then return false end

    return true
end

----------------------------------------------------------------------------------

local function CalcView( ply, origin, angles, fov )
    if not ShouldEnable( ply ) then reset = true return end

    local eyePos = ply:GetVehicle():LocalToWorld( Vector() )
    local eyeDir = ply:GetVehicle():WorldToLocal( ply:GetAimVector() + ply:GetVehicle():GetPos() )

    if reset then
        view = {
            origin = eyePos,
            angles = eyeDir:Angle(),
        }
        zoom = 200
        reset = false
    end

    trace.start = eyePos
    trace.endpos = eyePos - eyeDir*zoom

    local dist = eyePos:Distance( util.TraceLine( trace ).HitPos ) - 10

    view.origin = LerpVector( 0.1, view.origin, eyePos - eyeDir*dist )
    view.angles = LerpAngle( 0.1, view.angles, eyeDir:Angle() )
    view.fov = fov

    return view
end

hook.Remove( "CalcView", "ThirdPersonViewTest" )
hook.Add( "CalcView", "ThirdPersonViewTest", CalcView )

----------------------------------------------------------------------------------

local function DrawPlayer( ply )
     if not ShouldEnable( ply ) then return end
     return true
end

hook.Remove( "ShouldDrawLocalPlayer", "ThirdPersonViewTest" )
hook.Add( "ShouldDrawLocalPlayer", "ThirdPersonViewTest", DrawPlayer )

----------------------------------------------------------------------------------

local function DoZoom( ply, bind, pressed )
    if not ShouldEnable( ply ) then return end

    local key = input.LookupBinding( bind )
    if not key and pressed then return end

    if key == "MWHEELDOWN" then zoom = math.Clamp( zoom - 50, 150, 1000 ) end
    if key == "MWHEELUP" then zoom = math.Clamp( zoom + 50, 150, 1000 ) end
end

hook.Remove( "PlayerBindPress", "ThirdPersonViewTest" )
hook.Add( "PlayerBindPress", "ThirdPersonViewTest", DoZoom )

----------------------------------------------------------------------------------
