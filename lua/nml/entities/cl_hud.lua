----------------------------------------------------------------------------------
---- NML Hud - by shadowscion
----------------------------------------------------------------------------------

local Addon = NML

local math = math
local surface = surface

----------------------------------------------------------------------------------

Addon.HUD = Addon.HUD or {}
local HUD = Addon.HUD

----------------------------------------------------------------------------------

local function drawHUD()
    local ply, h, w = LocalPlayer(), ScrH(), ScrW()
    for _, screen in pairs( HUD ) do
        for _, element in pairs( screen ) do
            if not element.cnd or not element.cbk then element = nil screen = nil continue end
            if not element.cnd( ply ) then continue end
            element.cbk( ply, h, w )
        end
    end
end

hook.Remove( "HUDPaint", "NML.HUDPaint" )
hook.Add( "HUDPaint", "NML.HUDPaint", drawHUD )

----------------------------------------------------------------------------------

local function hideHUD( name )
    local ply = LocalPlayer()

    if not IsValid( ply ) or not ply:Alive() then return end
    if not ply:InVehicle() or not IsValid( ply:GetVehicle():GetParent() ) then return end
    if ply:GetVehicle():GetParent():GetClass() ~= "sent_nml_base" then return end

    if name == "CHudHealth" or name == "CHudBattery" then return false end
end

hook.Remove( "HUDShouldDraw", "NML.HUDShouldDraw" )
hook.Add( "HUDShouldDraw", "NML.HUDShouldDraw", hideHUD )

----------------------------------------------------------------------------------
