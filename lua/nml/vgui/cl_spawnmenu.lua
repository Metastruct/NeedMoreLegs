----------------------------------------------------------------------------------
---- NML Spawn Menu
----------------------------------------------------------------------------------

CreateClientConVar( "nml_spawntype", "", true, true )

----------------------------------------------------------------------------------

spawnmenu.AddContentType( "sent_nml_base", function( container, obj )
    if not obj.Name then return end

    local icon = vgui.Create( "ContentIcon", container )

    icon:SetContentType( "sent_nml_base" )
    icon:SetSpawnName( obj.Name )
    icon:SetName( obj.Name )
    icon:SetMaterial( "" )
    icon:SetColor( Color( 205, 92, 92, 255 ) )

    icon.DoClick = function()
        RunConsoleCommand( "nml_spawntype", obj.Name )
        RunConsoleCommand( "gm_spawnsent", "sent_nml_base" )
        surface.PlaySound( "ui/buttonclickrelease.wav" )
    end

    if IsValid( container ) then
        container:Add( icon )
    end

    return icon
end )

----------------------------------------------------------------------------------

spawnmenu.AddCreationTab( "Need More Legs", function()
    local ctrl = vgui.Create( "SpawnmenuContentPanel" )
    ctrl:CallPopulateHook( "PopulateNeedMoreLegs" )

    return ctrl
end, "icon16/bricks.png", 9999 )

----------------------------------------------------------------------------------

hook.Add( "PopulateNeedMoreLegs", "AddEntityContent", function( pnlContent, tree, node )
    local SpawnableEntities = list.Get( "nml_mechtypes" )
    if not SpawnableEntities then return false end

    local Sorted = {}
    for _, Data in pairs( SpawnableEntities ) do
        table.insert( Sorted, {
            Name = Data.Name,
            Author = Data.Author or nil,
        } )
    end

    if not Sorted then return false end

    local node = tree:AddNode( "Need More Legs", "icon16/bricks.png" )

    node.DoPopulate = function( self )
        if self.PropPanel then return end

        self.PropPanel = vgui.Create( "ContentContainer", pnlContent )
        self.PropPanel:SetVisible( false )
        self.PropPanel:SetTriggerSpawnlistChange( false )

        for _, Data in pairs( Sorted ) do
            spawnmenu.CreateContentIcon( "sent_nml_base", self.PropPanel, Data )
        end
    end

    node.DoClick = function( self )
        self:DoPopulate()
        pnlContent:SwitchPanel( self.PropPanel )
    end

    local FirstNode = tree:Root():GetChildNode( 0 )
    if IsValid( FirstNode ) then
        FirstNode:InternalDoClick()
    end
end )

----------------------------------------------------------------------------------
