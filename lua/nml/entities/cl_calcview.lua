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

local function shouldEnable( ply )
    if not ply:InVehicle() or not ply:GetVehicle():GetParent():IsValid() then return false end
    if ply:GetVehicle():GetParent():GetClass() ~= "sent_nml_base" then return false end
    if not ply:Alive() or ply:GetViewEntity() ~= ply then return false end

    return true
end

----------------------------------------------------------------------------------

local function calcView( ply, origin, angles, fov )
    if not shouldEnable( ply ) then reset = true return end

    ply:GetVehicle():SetThirdPersonMode( false )

    local eyePos = ply:GetVehicle():LocalToWorld( Vector( 0, 0, 50 ) )
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

    view.origin = LerpVector( 10*FrameTime(), view.origin, eyePos - eyeDir*dist )
    view.angles = LerpAngle( 10*FrameTime(), view.angles, eyeDir:Angle() )
    view.fov = fov

    return view
end

hook.Add( "CalcView", "NML", calcView )

----------------------------------------------------------------------------------

local function ShouldDrawLocalPlayer( ply )
     if shouldEnable( ply ) then return true end
end

hook.Add( "ShouldDrawLocalPlayer", "NML", ShouldDrawLocalPlayer )

----------------------------------------------------------------------------------

local function PlayerBindPress( ply, bind, pressed )
    if not shouldEnable( ply ) then return end

    local key = input.LookupBinding( bind )
    if not key and pressed then return end

    if key == "MWHEELDOWN" then zoom = math.Clamp( zoom - 50, 150, 1000 ) end
    if key == "MWHEELUP" then zoom = math.Clamp( zoom + 50, 150, 1000 ) end
end

hook.Add( "PlayerBindPress", "NML", PlayerBindPress )

----------------------------------------------------------------------------------
