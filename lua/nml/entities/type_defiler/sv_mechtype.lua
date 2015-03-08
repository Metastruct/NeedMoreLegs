------------------------------------------------------
---- WH40k Defiler - Serverside File
---- by shadowscion
------------------------------------------------------

local Addon = NML or {}

local math   = math
local table  = table
local string = string

local Helper = Addon.Helper

local sin = Helper.Sin
local cos = Helper.Cos
local atan = Helper.Atan
local lerp = Helper.Lerp
local divVA = Helper.DivVA
local mulVA = Helper.MulVA
local getAngVel = Helper.AngVel
local bearing2 = Helper.Bearing2
local ezAngForce = Helper.EZAngForce
local podEyeTrace = Helper.PodEyeTrace
local toLocalAxis = Helper.ToLocalAxis
local traceDirection = Helper.TraceDirection
local traceToVector = Helper.TraceToVector

------------------------------------------------------

local Mech = Addon.CreateMechType( "type_defiler", "nml_mechtypes" )

-- Mech:SetPhysicsBox(
--     Vector( -100, -100, 0 ),
--     Vector( 100, 100, 100 )
--  )

------------------------------------------------------

Mech:SetInitialize( function( self )
    -- Vars
    self.WalkSpeed = 0
    self.StrafeSpeed = 0

    self.JumpMode = 0
    self.JumpStart = self.Entity:GetPos()
    self.JumpFinish = self.Entity:GetPos()
    self.JumpTime = 0
end )

------------------------------------------------------

local function finalRanger( pos, filter )
    return traceDirection( 10000, pos, Vector( 0, 0, -1 ), filter, nil )
end

local function getJumpVec( self, ent, aim, ply, filter )
    local start = ent:GetPos()
    local dist = math.min( aim:Distance( start ), 1000 )
    local newAimPos = start + ( aim - start ):GetNormal()*dist
    local midPoint = ( start + newAimPos )/2

    local aimNormal = 1 - podEyeTrace( ply ).HitNormal:Dot( Vector( 0, 0, -1 ) )
    local zdiff = math.max( math.abs( newAimPos.z - start.z )/4, 150*aimNormal )

    local perp = Vector( 0, 0, 1 )
    local midPerp = midPoint + perp*( dist/2 + zdiff )
    local endPerp = newAimPos + Vector( 0, 0, 1 ) *zdiff

    local rd1 = traceDirection( start:Distance( midPerp ), start, ( midPerp - start ):GetNormal(), filter )
    local finalPos = start

    if rd1.Hit then
        local dot = 1 - rd1.HitNormal:Dot( Vector( 0, 0, 1 ) )
        local finalR = finalRanger( rd1.HitPos + rd1.HitNormal*100*dot, filter )
        finalPos = finalR.HitPos
    else
        local rd2 = traceDirection( endPerp:Distance( midPerp )*2, midPerp, ( endPerp - midPerp ):GetNormal(), filter )
        local dot = 1 - rd2.HitNormal:Dot( Vector( 0, 0, 1 ) )

        if rd2.Hit then
            local finalR = finalRanger( rd2.HitPos + rd2.HitNormal*100*dot, filter )
            finalPos = finalR.HitPos
        else
            local finalR = finalRanger( rd2.HitPos, filter )
            finalPos = finalR.HitPos
        end
    end

    local heightCheck = traceDirection( 9999, start, Vector( 0, 0, -1 ) )
    return finalPos, math.max( ( start - finalPos ):Length()/3, 200 )
    --return finalPos, math.min( math.max( ( start - finalPos ):Length()/3, 200 ), heightCheck.StartPos:Distance( heightCheck.HitPos ) - 150 )
end

local function getSurfaceVec( ent, startpos, endpos, filter )
    local trace = util.TraceLine( {
        start = ent:GetPos(),
        endpos = startpos,
        filter = filter or nil,
        --mask = MASK_PLAYERSOLID_BRUSHONLY,
    } )

    if trace.Hit then
        return trace.HitPos
    else
        return util.TraceLine( {
            start = startpos,
            endpos = endpos,
            filter = filter or nil,
            --mask = MASK_PLAYERSOLID_BRUSHONLY,
        } ).HitPos
    end
end

local function getSurfaceAng( ent, aim, add, frontl, frontr, rearl, rearr )
    local axisp = toLocalAxis( ent, ( frontl + frontr )/2 - ( rearl + rearr )/2 )
    local axisr = toLocalAxis( ent, ( frontr + rearr )/2 - ( frontl + rearl )/2 )
    local yaw = toLocalAxis( ent, aim - ent:GetPos() ):Angle()

    return ent:LocalToWorldAngles( add + Angle( atan( axisp.x, axisp.z ) - 90, yaw.y, atan( -axisr.y, axisr.z ) - 90 ) )
end

local function podEyeTrace( ply, rot )
    if not IsValid( ply ) then return {} end
    if not ply:InVehicle() then return {} end

    local pos = ply:GetShootPos()
    local eye = ply:GetAimVector()

    if rot then eye:Rotate( rot ) end

    local dir = ply:GetVehicle():WorldToLocal( eye + ply:GetVehicle():GetPos() )

    return util.TraceLine( {
        start  = pos,
        endpos = pos + dir*32768,
        mask   = MASK_SOLID_BRUSHONLY,
    } )
end

local function velL( self )
    if not IsValid( self ) then return Vector() end
    return self:WorldToLocal( self:GetVelocity() + self:GetPos() )
end

local function setZ( self, z )
    return Vector( self.x or 0, self.y or 0, z or self.z )
end

local offset = 200
local height = 0
local traceHeight = -500

local traceMiddle = Vector( 0, 0, traceHeight )
local traceOffsetFL = Vector( offset, offset, height )
local traceOffsetFR = Vector( offset, -offset, height )
local traceOffsetRL = Vector( -offset, offset, height )
local traceOffsetRR = Vector( -offset, -offset, height )

Mech:SetThink( function( self, ent, veh, ply, dt )
    local phys = ent:GetPhysicsObject()
    if not IsValid( phys ) then return end

    -- Setup Inputs
    local aimPos = Vector()
    local w, a, s, d = 0, 0, 0, 0
    local ctrl, alt, space, shift = 0, 0, 0, 0

    if IsValid( ply ) then
        w = ply:KeyDown( IN_FORWARD ) and 1 or 0
        a = ply:KeyDown( IN_MOVELEFT ) and 1 or 0
        s = ply:KeyDown( IN_BACK ) and 1 or 0
        d = ply:KeyDown( IN_MOVERIGHT ) and 1 or 0

        ctrl = ply:KeyDown( IN_DUCK ) and 1 or 0
        shift = ply:KeyDown( IN_SPEED ) and 1 or 0
        space = ply:KeyDown( IN_JUMP ) and 1 or 0
        alt = ply:KeyDown( IN_WALK ) and 0 or 1

        aimPos = podEyeTrace( ply ).HitPos
    else
        aimPos = ent:GetPos() + ent:GetForward()*200
    end

    self.WalkSpeed = lerp( self.WalkSpeed, w - s, 0.1 )
    self.StrafeSpeed = lerp( self.StrafeSpeed, d - a, 0.1 )

    if self.JumpMode == 0 then
        self.JumpMode = space
    end


    local mode = ent:GetMechMode()

    if mode == "Normal" then

        local entVel = phys:GetVelocity()
        local entVelL = velL( ent )
        local filter = table.Add( { ent, veh }, player.GetAll() )

        local surfaceFL = getSurfaceVec( ent, ent:LocalToWorld( traceOffsetFL ), ent:LocalToWorld( setZ( traceOffsetRR, traceHeight ) ), filter )
        local surfaceFR = getSurfaceVec( ent, ent:LocalToWorld( traceOffsetFR ), ent:LocalToWorld( setZ( traceOffsetRL, traceHeight ) ), filter )
        local surfaceRL = getSurfaceVec( ent, ent:LocalToWorld( traceOffsetRL ), ent:LocalToWorld( setZ( traceOffsetFR, traceHeight ) ), filter )
        local surfaceRR = getSurfaceVec( ent, ent:LocalToWorld( traceOffsetRR ), ent:LocalToWorld( setZ( traceOffsetFL, traceHeight ) ), filter )

        local surfaceHeight = ent:GetPos():Distance( ( surfaceFL + surfaceFR + surfaceRL + surfaceRR )/4 )

        if 200 - surfaceHeight > 0 then
            local surfaceAng = getSurfaceAng( ent, aimPos, Angle( space*15 + self.WalkSpeed*5, 0, self.StrafeSpeed*5 ), surfaceFL, surfaceFR, surfaceRL, surfaceRR )

            local normalU = surfaceAng:Up()
            local traceU = traceToVector( ent:GetPos(), ent:LocalToWorld( traceMiddle ), filter )
            local heightU = ( 70 - space*30 ) + math.max( 0, 70 - traceU.StartPos:Distance( traceU.HitPos ) )
            local forceU = ( heightU - surfaceHeight )*normalU*5 - entVel:Dot( normalU )*normalU/2

            local normalF = surfaceAng:Forward()
            local forceF = normalF*( self.WalkSpeed*( 70 + shift*30 ) ) - entVel:Dot( normalF )*normalF/5

            local normalR = surfaceAng:Right()
            local forceR = normalR*( self.StrafeSpeed*( 70 + shift*30 ) ) - entVel:Dot( normalR )*normalR/5

            phys:ApplyForceCenter( ( forceU + forceF + forceR )*phys:GetMass() )
            ezAngForce( ent, ent:WorldToLocalAngles( surfaceAng )*300, 30 )
            phys:EnableGravity( false )

            if IsValid( ply ) then
                if self.JumpMode == 1 then
                    if space == 0 then
                        ent:SetMechMode( "CalcJump" )
                        self.JumpMode = 0
                    end
                end
                --if ply:KeyReleased( IN_JUMP ) then
                -- if not ply:KeyDown( IN_JUMP ) and ply:KeyDownLast( IN_JUMP ) then
                --     print( "wtf" )
                --     ent:SetMechMode( "CalcJump" )
                -- end
            end
        else
            phys:EnableGravity( true )
        end
    end

    if mode == "CalcJump" then
        local ground = traceDirection( 500, ent:GetPos(), -ent:GetUp(), table.Add( { ent, veh }, player.GetAll() ) )

        self.JumpStart = ent:GetPos()
        self.JumpFinish, self.JumpHeight = getJumpVec( self, ent, podEyeTrace( ply, Angle( 0, s*180 - ( d-a )*90, 0 ) ).HitPos, ply, { veh, ent, ply } )
        self.JumpTime = 0

        ent:SetMechMode( "DoJump" )
    end

    if mode == "DoJump" then
        self.JumpTime = math.min( self.JumpTime + dt/1.25, 1 )

        local jPos = LerpVector( self.JumpTime, self.JumpStart, self.JumpFinish ) + Vector( 0, 0, sin( self.JumpTime*180 )*self.JumpHeight )
        local jAng = Angle( sin( self.JumpTime*360 )*-25, bearing2( ent, aimPos, 5, 1 ), 0 )

        phys:ApplyForceCenter( ( ( jPos - ent:GetPos() )*10 - phys:GetVelocity() )*phys:GetMass() )
        ezAngForce( ent, ent:WorldToLocalAngles( jAng )*300, 30 )
        phys:EnableGravity( false )

        if self.JumpTime == 1 then
            ent:SetMechMode( "Normal" )
        end
    end

end )
