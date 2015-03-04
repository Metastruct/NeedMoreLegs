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
            self:MenuSetToggleBones( ent, not ent:GetMechToggleBones() )
        end )
        boneMenu:SetChecked( ent:GetMechToggleBones() )

        local shadingMenu = mainMenu:AddOption( "Toggle Fullbright", function()
            self:MenuSetToggleShading( ent, not ent:GetMechToggleShading() )
        end )
        shadingMenu:SetChecked( ent:GetMechToggleShading() )

        -- Change Skins
        local skinCount = ent.Mech.SkinTable and #ent.Mech.SkinTable or 0
        if skinCount > 0 then
            local skinMenu = mainMenu:AddSubMenu( "Change Skin" )

            for i = 0, skinCount do
            local skin = skinMenu:AddOption( ent.Mech.SkinTable[i], function() self:MenuSetMechSkin( ent, i ) end )
            if ent.Mech.Skin == i then skin:SetChecked( true ) end
            end
        end
    end,

    MenuSetToggleShading = function( self, ent, status )
        self:MsgStart()
            net.WriteString( "shading" )
            net.WriteUInt( ent:EntIndex(), 16 )
            net.WriteBit( status )
        self:MsgEnd()
    end,

    MenuSetToggleBones = function( self, ent, status )
        self:MsgStart()
            net.WriteString( "bones" )
            net.WriteUInt( ent:EntIndex(), 16 )
            net.WriteBit( status )
        self:MsgEnd()
    end,

    MenuSetMechSkin = function( self, ent, id )
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
            ent:SetMechSkin( net.ReadUInt( 16 ) or 0 )
            return
        end

        if cmd == "bones" then
            ent:SetMechToggleBones( tobool( net.ReadBit() ) )
            return
        end

        if cmd == "shading" then
            ent:SetMechToggleShading( tobool( net.ReadBit() ) )
            return
        end
    end
} )
