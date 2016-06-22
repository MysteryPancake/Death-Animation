
-- Random animations
CreateClientConVar( 'deathanimation_random', 'death_01,death_02,death_03', true, true, 'Changes the table of random animations to play.' )

-- First person
CreateClientConVar( 'deathanimation_firstperson', '0', true, true, 'Toggles first person death view' )

-- Basic stuff
CreateClientConVar( 'deathanimation_kill', '%no_anim_norag%', true, true, 'Changes the kill-command death animation.' )
-- CreateClientConVar( 'deathanimation_offground', '%no_anim_norag%', true, true, 'Changes the on-ground death animation.' ) -- Too general
CreateClientConVar( 'deathanimation_fire', 'death_02', true, true, 'Changes the burning death animation.' )
CreateClientConVar( 'deathanimation_drown', '%no_anim_ragdoll%', true, true, 'Changes the drowning death animation.' )
CreateClientConVar( 'deathanimation_explosion', '%no_anim_ragdoll%', true, true, 'Changes the explosion death animation.' )

-- Hitgroups
CreateClientConVar( 'deathanimation_headshot', 'death_04', true, true, 'Changes the head-shot death animation.' )
CreateClientConVar( 'deathanimation_chestshot', '%random_anim%', true, true, 'Changes the chest-shot death animation.' )
CreateClientConVar( 'deathanimation_stomachshot', '%random_anim%', true, true, 'Changes the stomach-shot death animation.' )
CreateClientConVar( 'deathanimation_leftarm', '%random_anim%', true, true, 'Changes the left-arm death animation.' )
CreateClientConVar( 'deathanimation_rightarm', '%random_anim%', true, true, 'Changes the right-arm death animation.' )
CreateClientConVar( 'deathanimation_leftleg', '%random_anim%', true, true, 'Changes the left-leg death animation.' )
CreateClientConVar( 'deathanimation_rightleg', '%random_anim%', true, true, 'Changes the right-leg death animation.' )

-- Generic
CreateClientConVar( 'deathanimation_generic', '%random_anim%', true, true, 'Changes the generic death animation.' )

local enabled = GetConVar( 'deathanimation_enabled' )

local prevply, prevrag

net.Receive( 'DeathAnimationClient', function()

	local ply = net.ReadEntity()
	local ragind = net.ReadInt( 32 ) -- The ragdoll doesn't exist on the client yet
	
	if !IsValid( ply ) or !ply:IsPlayer() or !isnumber( ragind ) then return end
	prevply, prevrag = ply, ragind
	
end )

hook.Add( 'NetworkEntityCreated', 'DeathAnimationColorRagdoll', function( ent )

	if IsValid( ent ) and ent:IsRagdoll() and IsValid( prevply ) and prevply:IsPlayer() and isnumber( prevrag ) then
	
		local rag = Entity( prevrag )
		
		if ( ent == rag ) then
			ent.GetPlayerColor = function() return Vector( prevply:GetInfo( "cl_playercolor" ) ) end
			prevply.Ragdoll = ent
		end
		
	end
	
end )

local firstperson = GetConVar( 'deathanimation_firstperson' )

hook.Add( 'CalcView', 'DeathAnimationFirstPerson', function( ply )

	if enabled:GetBool() and !ply:Alive() and firstperson:GetBool() and IsValid( ply.Ragdoll ) then
	
		local campos = ply.Ragdoll:GetAttachment( ply.Ragdoll:LookupAttachment( "eyes" ) )
		return { origin = campos.Pos, angles = campos.Ang }
		
	end
	
end )