----------------------------------------------------------------------------------

properties.Add( "NMLContext", {
	MenuLabel     = "Need More Legs",
	MenuIcon      = "icon16/picture_edit.png",
	Order         = 99999,
	PrependSpacer = true,

	Action = function() end,

	Filter = function( self, ent, ply )
		if not IsValid( ent ) or ent:GetClass() ~= "base_nml" then return false end
		if not ent.NML then return false end
		return true
	end,

	MenuOpen = function( self, opt, ent, tr )
		local context = opt:AddSubMenu()

		local opt = context:AddOption( "Disable Shading", function()
			ent.NML:SetDisableShading( not ent.NML.DisableShading )
		end )
		opt:SetChecked( ent.NML.DisableShading )

		local opt = context:AddOption( "Display Bones", function()
			ent.NML:SetDisplayBones( not ent.NML.DisplayBones )
		end )
		opt:SetChecked( ent.NML.DisplayBones )

		local opt = context:AddSubMenu( "Change Skin" )
		local skinCount = table.Count( ent.NML.Skins )

		if skinCount > 0 then
			for i = 0, skinCount - 1 do
				local skin = opt:AddOption( ent.NML.Skins[i], function()
					ent.NML:SetSkin( i )
				end )

				if ent.NML.Skin == i then
					skin:SetChecked( true )
				end
			end
		end
	end,
} )

----------------------------------------------------------------------------------
