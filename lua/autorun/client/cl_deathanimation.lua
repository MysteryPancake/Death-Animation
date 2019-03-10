
CreateClientConVar( 'deathanimation_random', 'death_01,death_02,death_03', true, true, 'Changes the table of random animations to play.' )

CreateClientConVar( 'deathanimation_headshot', 'death_04', true, true, 'Changes the head-shot death animation.' )
CreateClientConVar( 'deathanimation_chestshot', '%random_anim%', true, true, 'Changes the chest-shot death animation.' )
CreateClientConVar( 'deathanimation_stomachshot', '%random_anim%', true, true, 'Changes the stomach-shot death animation.' )
CreateClientConVar( 'deathanimation_leftarm', '%random_anim%', true, true, 'Changes the left-arm death animation.' )
CreateClientConVar( 'deathanimation_rightarm', '%random_anim%', true, true, 'Changes the right-arm death animation.' )
CreateClientConVar( 'deathanimation_leftleg', '%random_anim%', true, true, 'Changes the left-leg death animation.' )
CreateClientConVar( 'deathanimation_rightleg', '%random_anim%', true, true, 'Changes the right-leg death animation.' )
CreateClientConVar( 'deathanimation_generic', '%random_anim%', true, true, 'Changes the generic death animation.' )

net.Receive( 'DeathAnimation_RagColor', function()

	local rag = net.ReadEntity()
	local color = net.ReadNormal()
	
	if !IsValid( rag ) then return end
	
	rag.GetPlayerColor = function() return color end

end )