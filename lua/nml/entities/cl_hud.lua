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

local ply
local function HUDPaint(w,h)
  
	w,h = ScrW(), ScrH()
    for _, screen in pairs( HUD ) do
        for _, element in pairs( screen ) do
            if not element.cnd or not element.cbk then element = nil screen = nil continue end
            if not element.cnd( ply ) then continue end
            element.cbk( ply, h, w )
        end
    end
end


----------------------------------------------------------------------------------

local function HUDShouldDraw( name )

    if name ~= "CHudHealth" and name ~= "CHudBattery" then return end
    if not ply:InVehicle() or not ply:Alive() then return end
    if not ply:GetVehicle():GetParent():IsValid() then return end
    if ply:GetVehicle():GetParent():GetClass() ~= "sent_nml_base" then return end
	
	return false
	
end


hook.Add("Think","NML_Init",function()
	if not LocalPlayer():IsValid() then return end
	ply = LocalPlayer()
	hook.Remove("Think","NML_Init")
	hook.Add( "HUDShouldDraw", "NML", HUDShouldDraw )
	hook.Add( "HUDPaint", "NML", HUDPaint )
end)
----------------------------------------------------------------------------------
