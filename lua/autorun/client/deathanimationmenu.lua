
local randomanims = GetConVar( 'deathanimation_random' )

local BadBeginnings = { "g_", "p_", "e_", "b_", "bg_", "hg_", "tc_", "aim_", "turn", "gest_", "pose_", "auto_", "layer_", "posture", "bodyaccent", "a_" } -- Copied from RobotBoy655
local BadStrings = { "gesture", "posture", "_trans_", "_rot_", "gest", "aim", "bodyflex_", "delta", "ragdoll", "spine", "arms" } -- Copied from RobotBoy655

local function GetGoodAnimationsAndDo( ent, func, tbl ) -- This is just used to run a function if a sequence is valid

	for _, seq in pairs( ent:GetSequenceList() ) do
	
		local goodanim = true
		
		for _, str in ipairs( BadStrings ) do
			if ( string.find( string.lower( seq ), str ) ~= nil ) then goodanim = false end
		end
		
		for _, str in ipairs( BadBeginnings ) do
			if ( str == string.Left( string.lower( seq ), string.len( str ) ) ) then goodanim = false end
		end
		
		if tbl then
			for _, str in pairs( tbl ) do
				if str == seq then goodanim = false end
			end
		end
		
		if goodanim then
			func( seq )
		end	
		
	end
	
end

local function OpenMenuNoSort( pnl ) -- This function is needed just so the DCheckBox won't get sorted
	if ( #pnl.Choices == 0 ) then return end
	if ( IsValid( pnl.Menu ) ) then
		pnl.Menu:Remove()
		pnl.Menu = nil
	end
	pnl.Menu = DermaMenu()
	for k, v in pairs( pnl.Choices ) do
		pnl.Menu:AddOption( v, function() pnl:ChooseOption( v, k ) end )
	end
	local x, y = pnl:LocalToScreen( 0, pnl:GetTall() )
	pnl.Menu:SetMinimumWidth( pnl:GetWide() )
	pnl.Menu:Open( x, y, false, pnl )
end

local function PaintButton( btn, w, h ) -- Used to paint the buttons

	if btn.Depressed then
		surface.SetDrawColor( 0, 200, 255, 255 )
	elseif btn.Hovered then
		surface.SetDrawColor( 200, 200, 200, 255 )
	else
		surface.SetDrawColor( 255, 255, 255, 255 )
	end
	
	surface.DrawRect( 0, 0, w, h )
	
	surface.SetDrawColor( 0, 0, 0, 255 )
	surface.DrawOutlinedRect( 0, 0, w, h )
	
end

local function UpdateRandomTblCvar( tbl ) -- Update the convar from the table

	local str = ''
	
	for k, line in pairs( tbl:GetLines() ) do
		str = str .. line:GetValue(1) .. ','
	end
	
	RunConsoleCommand( 'deathanimation_random', string.sub( str, 1, #str-1 ) ) -- string.sub to remove the last ,

end

hook.Add( 'PopulateToolMenu', 'DeathAnimationSettings', function()
	spawnmenu.AddToolMenuOption( 'Options', 'Death', 'Death_Animation_Settings', 'Death Animations', '', '', function( panel )
		
		panel:ClearControls()
		
		if LocalPlayer():IsAdmin() then
			panel:CheckBox( 'Animations enabled', 'deathanimation_enabled' )
			panel:CheckBox( "Don't remove ragdolls", 'deathanimation_keepragdolls' )
		end
		
		panel:CheckBox( 'First-person death', 'deathanimation_firstperson' )
		
		local mdlpnl = vgui.Create( "DModelPanel" )
		local model = LocalPlayer():GetInfo( "cl_playermodel" )
		mdlpnl:SetModel( util.IsValidRagdoll( model ) and model or LocalPlayer():GetModel() )
		mdlpnl.Entity.GetPlayerColor = function() return Vector( LocalPlayer():GetInfo( 'cl_playercolor' ) ) end
		mdlpnl:SetHeight( 300 )
		function mdlpnl:LayoutEntity( ent ) -- Needed to make sure the entity is visible in the modelpanel, and to play the animation
			local mn, mx = ent:GetRenderBounds()
			local size = 0
			size = math.max( size, math.abs(mn.x) + math.abs(mx.x) )
			size = math.max( size, math.abs(mn.y) + math.abs(mx.y) )
			size = math.max( size, math.abs(mn.z) + math.abs(mx.z) )
			self:SetFOV( 45 )
			self:SetCamPos( Vector( size, size, size ) )
			self:SetLookAt( ( mn + mx ) * 0.5 )
			if ( ent:GetCycle() >= 0.95 ) then ent:SetCycle( 0.05 ) end
			self:RunAnimation()
		end

		panel:AddItem( mdlpnl )
			
		panel:Help( 'Animation to play when you get killed:' )
			
		local comboboxes = {
			{ panel:ComboBox( "By the 'kill' command:", 'deathanimation_kill' ) },
			-- { panel:ComboBox( 'While off ground:', 'deathanimation_offground' ) }, -- Too general
			{ panel:ComboBox( 'By burning:', 'deathanimation_fire' ) },
			{ panel:ComboBox( 'By drowning:', 'deathanimation_drown' ) },
			{ panel:ComboBox( 'By an explosion:', 'deathanimation_explosion' ) },
			{ panel:ComboBox( 'By a head-shot:', 'deathanimation_headshot' ) },
			{ panel:ComboBox( 'By a chest-shot:', 'deathanimation_chestshot' ) },
			{ panel:ComboBox( 'By a stomach-shot:', 'deathanimation_stomachshot' ) },
			{ panel:ComboBox( 'By a left-arm shot:', 'deathanimation_leftarm' ) },
			{ panel:ComboBox( 'By a right-arm shot:', 'deathanimation_rightarm' ) },
			{ panel:ComboBox( 'By a left-leg shot:', 'deathanimation_leftleg' ) },
			{ panel:ComboBox( 'By a right-leg shot:', 'deathanimation_rightleg' ) },
			{ panel:ComboBox( 'By anything else:', 'deathanimation_generic' ) }
		}
			
		for _, tbl in ipairs( comboboxes ) do
			
			local box, lbl = tbl[1], tbl[2]
			
			local parent = lbl:GetParent()
			
			if IsValid( parent ) then
				lbl:SetWrap( true )
				lbl:SetAutoStretchVertical( true )
				parent:SetTall(40)
			end
			
			box.OpenMenu = OpenMenuNoSort
			
			box:AddChoice( 'No animation (spawn ragdoll)', '%no_anim_ragdoll%' )
			box:AddChoice( 'No animation (no ragdoll)', '%no_anim_norag%' )
			box:AddChoice( 'Random animation from list', '%random_anim%' )
			
			local deathtbl = {}
			for i = 1, 4 do
				if table.HasValue( mdlpnl.Entity:GetSequenceList(), 'death_0'..i ) then -- My brain is dead, leave me alone
					box:AddChoice( 'death_0'..i )
					table.insert( deathtbl, 'death_0'..i )
				end
			end
				
			GetGoodAnimationsAndDo( mdlpnl.Entity, function( seq ) box:AddChoice( seq ) end, deathtbl )
				
			function box:ChooseOption( value, index )
				if ( self.Menu ) then
					self.Menu:Remove()
					self.Menu = nil
				end
				self:SetText( value )
				self.selected = index
				local data = self.Data[ index ]
				if ( data ~= '%random_anim%' and data ~= '%no_anim_norag%' and data ~= '%no_anim_ragdoll%' ) then mdlpnl.Entity:ResetSequence( value ) end
				self:OnSelect( index, value, data )
			end
				
		end
			
		local bgpanel = vgui.Create( "DPanel" )
		bgpanel:SetHeight( 200 )
		bgpanel:DockPadding( 5, 5, 5, 5 )
		panel:AddItem( bgpanel )
			
		bgpanel.AnimationList = vgui.Create( "DListView", bgpanel )
		bgpanel.AnimationList:AddColumn( 'Random animations' )
		bgpanel.AnimationList:Dock( LEFT )
		local randomanimtbl = string.Explode( ",", randomanims:GetString() )
		for k, v in pairs( randomanimtbl ) do
			bgpanel.AnimationList:AddLine( v )
		end
			
		bgpanel.NonAddedAnims = vgui.Create( "DListView", bgpanel )
		bgpanel.NonAddedAnims:AddColumn( 'Other animations' )
		bgpanel.NonAddedAnims:Dock( RIGHT )
		GetGoodAnimationsAndDo( mdlpnl.Entity, function( seq ) bgpanel.NonAddedAnims:AddLine( seq ) end, randomanimtbl )
			
		function bgpanel.NonAddedAnims:OnRowSelected( rowIndex, row ) -- Don't let the player select more than one list at once
			if bgpanel.AnimationList:GetSelectedLine() then
				bgpanel.AnimationList:ClearSelection()
			end
		end
			
		function bgpanel.AnimationList:OnRowSelected( rowIndex, row ) -- Don't let the player select more than one list at once
			if bgpanel.NonAddedAnims:GetSelectedLine() then
				bgpanel.NonAddedAnims:ClearSelection()
			end
		end
		
		bgpanel.AddAnim = vgui.Create( 'DButton', bgpanel )
		bgpanel.AddAnim:Dock( TOP )
		bgpanel.AddAnim:SetFont( 'Trebuchet24' )
		bgpanel.AddAnim:SetText( '<' )
		bgpanel.AddAnim.Paint = PaintButton
		
		bgpanel.RemoveAnim = vgui.Create( 'DButton', bgpanel )
		bgpanel.RemoveAnim:Dock( BOTTOM )
		bgpanel.RemoveAnim:SetFont( 'Trebuchet24' )
		bgpanel.RemoveAnim:SetText( '>' )
		bgpanel.RemoveAnim.Paint = PaintButton
		
		function bgpanel.RemoveAnim:DoClick()
			local selectedlines = bgpanel.AnimationList:GetSelected()
			for _, line in pairs( selectedlines ) do
				bgpanel.NonAddedAnims:AddLine( line:GetValue( 1 ) )
				bgpanel.AnimationList:RemoveLine( line:GetID() )
			end
			UpdateRandomTblCvar( bgpanel.AnimationList )
		end
		function bgpanel.AddAnim:DoClick()
			local selectedlines = bgpanel.NonAddedAnims:GetSelected()
			for _, line in pairs( selectedlines ) do
				bgpanel.AnimationList:AddLine( line:GetValue( 1 ) )
				bgpanel.NonAddedAnims:RemoveLine( line:GetID() )
			end
			UpdateRandomTblCvar( bgpanel.AnimationList )
		end
		
		function bgpanel:PerformLayout( w, h )
			self.AddAnim:SetTall( h/2-10 )
			self.RemoveAnim:SetTall( h/2-10 )
			self.AnimationList:SetWide( w/2-25 )
			self.NonAddedAnims:SetWide( w/2-25 )
		end
		
	end )
end )
