
local randomanims = GetConVar( 'deathanimation_random' )

local BadBeginnings = { "g_", "p_", "e_", "b_", "bg_", "hg_", "tc_", "aim_", "turn", "gest_", "pose_", "auto_", "layer_", "posture", "bodyaccent", "a_" }
local BadStrings = { "gesture", "posture", "_trans_", "_rot_", "gest", "aim", "bodyflex_", "delta", "ragdoll", "spine", "arms" } -- Copied from RobotBoy655's easy animation tool code

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

local function OpenMenuNoSort( pnl, pControlOpener ) -- This function is needed just so the DCheckBox won't get sorted
	if ( pControlOpener ) then
		if ( pControlOpener == pnl.TextEntry ) then return end
	end
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
			
		end
		
		local mdlpnl = vgui.Create( "DModelPanel" )
		mdlpnl:SetModel( LocalPlayer():GetModel() )
		mdlpnl.Entity.GetPlayerColor = function() return LocalPlayer():GetPlayerColor() end
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
			
		panel:Help( 'Animation to play when you get killed by:' )
			
		local comboboxes = {}
		comboboxes[1] = panel:ComboBox( 'A head-shot:', 'deathanimation_headshot' )
		comboboxes[2] = panel:ComboBox( 'A chest-shot:', 'deathanimation_chestshot' )
		comboboxes[3] = panel:ComboBox( 'A stomach-shot:', 'deathanimation_stomachshot' )
		comboboxes[4] = panel:ComboBox( 'A left-arm shot:', 'deathanimation_leftarm' )
		comboboxes[5] = panel:ComboBox( 'A right-arm shot:', 'deathanimation_rightarm' )
		comboboxes[6] = panel:ComboBox( 'A left-leg shot:', 'deathanimation_leftleg' )
		comboboxes[7] = panel:ComboBox( 'A right-leg shot:', 'deathanimation_rightleg' )
		comboboxes[8] = panel:ComboBox( 'Anything else:', 'deathanimation_generic' )
			
		for _, box in ipairs( comboboxes ) do
				
			box.OpenMenu = OpenMenuNoSort
				
			box:AddChoice( 'Random animation from the list', '%random_anim%' )
			
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
				if value ~= 'Random animation from table' then mdlpnl.Entity:ResetSequence( value ) end
				self:OnSelect( index, value, self.Data[ index ] )
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
		
		bgpanel.ButtonBG = vgui.Create( 'DPanel', bgpanel )
		bgpanel.ButtonBG:SetWide( 30 )
		
		local pointmat = Material( 'gui/point.png')
		
		bgpanel.ButtonBG.AddAnim = vgui.Create( 'DButton', bgpanel )
		bgpanel.ButtonBG.AddAnim:Dock( TOP )
		bgpanel.ButtonBG.AddAnim:SetFont( 'Trebuchet24' )
		bgpanel.ButtonBG.AddAnim:SetText( '<' )
		bgpanel.ButtonBG.AddAnim.Paint = PaintButton
		
		bgpanel.ButtonBG.RemoveAnim = vgui.Create( 'DButton', bgpanel )
		bgpanel.ButtonBG.RemoveAnim:Dock( BOTTOM )
		bgpanel.ButtonBG.RemoveAnim:SetFont( 'Trebuchet24' )
		bgpanel.ButtonBG.RemoveAnim:SetText( '>' )
		bgpanel.ButtonBG.RemoveAnim.Paint = bgpanel.ButtonBG.AddAnim.Paint
		
		function bgpanel.ButtonBG.RemoveAnim:DoClick()
			local selectedlines = bgpanel.AnimationList:GetSelected()
			for _, line in pairs( selectedlines ) do
				bgpanel.NonAddedAnims:AddLine( line:GetValue( 1 ) )
				bgpanel.AnimationList:RemoveLine( line:GetID() )
			end
			UpdateRandomTblCvar( bgpanel.AnimationList )
		end
		function bgpanel.ButtonBG.AddAnim:DoClick()
			local selectedlines = bgpanel.NonAddedAnims:GetSelected()
			for _, line in pairs( selectedlines ) do
				bgpanel.AnimationList:AddLine( line:GetValue( 1 ) )
				bgpanel.NonAddedAnims:RemoveLine( line:GetID() )
			end
			UpdateRandomTblCvar( bgpanel.AnimationList )
		end
		
		function bgpanel.ButtonBG:PerformLayout( w, h )
			self.AddAnim:SetTall( h/2-10 )
			self.RemoveAnim:SetTall( h/2-10 )
		end
		
		function bgpanel:PerformLayout( w, h )
			self.ButtonBG:SetTall( h )
			self.ButtonBG:CenterHorizontal()
			self.AnimationList:SetWide( w/2-25 )
			self.NonAddedAnims:SetWide( w/2-25 )
		end
		
	end )
end )
