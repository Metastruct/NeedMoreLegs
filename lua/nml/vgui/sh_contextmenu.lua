----------------------------------------------------------------------------------
---- NML Context Menu
----------------------------------------------------------------------------------

properties.Add( "nml_context_menu", {
    MenuLabel     = "Need More Legs",
    MenuIcon      = "icon16/picture_edit.png",
    Order         = 0,

    Filter = function( self, ent, ply )
        if not IsValid( ent ) or ent:GetClass() ~= "sent_nml_base" then return false end
        return true
    end,

    MenuOpen = function( self, option, ent, tr )
        local mainMenu = option:AddSubMenu()

        local boneMenu = mainMenu:AddOption( "Show Bones", function()
            --self:MenuSetShowBones( ent, not ent:GetShowBones() )
        end )
        --boneMenu:SetChecked( ent:GetShowBones() )

        local shadingMenu = mainMenu:AddOption( "Disable Shading", function()
            --self:MenuSetDisableShading( ent, not ent:GetDisableShading() )
        end )
        --shadingMenu:SetChecked( ent:GetDisableShading() )

        -- Change Skins
        -- if #ent.Mech.Skins > 0 then
        --     local skinMenu = mainMenu:AddSubMenu( "Change Skin" )
        --     local skinCount = #ent.Mech.Skins

        --     for i = 0, skinCount do
        --         local skin = skinMenu:AddOption( ent.Mech.Skins[i], function() self:MenuSetSkin( ent, i ) end )
        --         if ent.Mech.Skin == i then skin:SetChecked( true ) end
        --     end
        -- end
    end,

    MenuSetDisableShading = function( self, ent, status )
        self:MsgStart()
            net.WriteString( "shading" )
            net.WriteUInt( ent:EntIndex(), 16 )
            net.WriteBit( status )
        self:MsgEnd()
    end,

    MenuSetShowBones = function( self, ent, status )
        self:MsgStart()
            net.WriteString( "bones" )
            net.WriteUInt( ent:EntIndex(), 16 )
            net.WriteBit( status )
        self:MsgEnd()
    end,

    MenuSetSkin = function( self, ent, id )
        self:MsgStart()
            net.WriteString( "skin" )
            net.WriteUInt( ent:EntIndex(), 16 )
            net.WriteUInt( id, 16 )
        self:MsgEnd()
    end,

    Action = function() end,

    Receive = function( self, len, ply )
        local cmd = net.ReadString()
        local ent = Entity( net.ReadUInt( 16 ) )

        if not self:Filter( ent, ply ) then return end

        if cmd == "skin" then
            --ent:SetMechSkin( net.ReadUInt( 16 ) or 0 )
            return
        end

        if cmd == "bones" then
            --ent:SetShowBones( tobool( net.ReadBit() ) )
            return
        end

        if cmd == "shading" then
            --ent:SetDisableShading( tobool( net.ReadBit() ) )
            return
        end
    end
} )
