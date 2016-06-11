
CreateConVar( 'deathanimation_enabled', '1', { FCVAR_REPLICATED, FCVAR_NOTIFY }, 'Sets whether a death animation should play when a player dies.' )
local enabled = GetConVar( 'deathanimation_enabled' )

local function CheckAndRemoveRagdoll( ply ) -- remove the player's ragdoll when they respawn or disconnect
	if IsValid( ply.Ragdoll ) then ply.Ragdoll:Remove() end
end

local function SetEntityStuff( ent1, ent2 ) -- transfer most of the set things on entity 2 to entity 1
	if !IsValid( ent1 ) or !IsValid( ent2 ) then return end
	ent1:SetModel( ent2:GetModel() )
	ent1:SetPos( ent2:GetPos() )
	ent1:SetAngles( ent2:GetAngles() )
	ent1:SetColor( ent2:GetColor() )
	ent1:SetSkin( ent2:GetSkin() )
	ent1:SetFlexScale( ent2:GetFlexScale() )
	for i = 0, ent2:GetNumBodyGroups() - 1 do ent1:SetBodygroup( i, ent2:GetBodygroup( i ) ) end
	for i = 0, ent2:GetFlexNum() - 1 do ent1:SetFlexWeight( i, ent2:GetFlexWeight( i ) ) end
	for i = 0, ent2:GetBoneCount() do
		ent1:ManipulateBoneScale( i, ent2:GetManipulateBoneScale( i ) )
		ent1:ManipulateBoneAngles( i, ent2:GetManipulateBoneAngles( i ) )
		ent1:ManipulateBonePosition( i, ent2:GetManipulateBonePosition( i ) )
		ent1:ManipulateBoneJiggle( i, ent2:GetManipulateBoneJiggle( i ) )
	end
end

local function TransferBones( base, ragdoll ) -- transfers the bones of one entity to a ragdoll's physics bones (modified version of some of RobotBoy655's code)
	for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
		local bone = ragdoll:GetPhysicsObjectNum( i )
		if ( IsValid( bone ) ) then
			local pos, ang = base:GetBonePosition( ragdoll:TranslatePhysBoneToBone( i ) )
			if ( pos ) then bone:SetPos( pos ) end
			if ( ang ) then bone:SetAngles( ang ) end
		end
	end
end

hook.Add( 'PlayerDeath', 'DeathAnimation', function( victim, inflictor, attacker )

	if !enabled:GetBool() then return end -- don't do anything if the convar isn't enabled
	
	victim.LetRespawn = false -- don't let them respawn
		
	if IsValid( victim:GetRagdollEntity() ) then -- remove the default ragdoll
		victim:GetRagdollEntity():Remove()
	end
	
	victim:Spectate( OBS_MODE_CHASE ) -- make them spectate
	
	local animent = ents.Create( 'base_gmodentity' ) -- the entity used for the death animation
	SetEntityStuff( animent, victim )
	animent:Spawn()
	animent:Activate()
	victim:SpectateEntity( animent ) -- spectate this entity
	victim.Ragdoll = animent
	
	animent:SetSolid( SOLID_OBB ) -- this stuff isn't really needed, but just for physics
	animent:PhysicsInit( SOLID_OBB )
	animent:SetMoveType( MOVETYPE_FLYGRAVITY )
	animent:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
	local physobj = animent:GetPhysicsObject()
	if IsValid( physobj ) then
		physobj:Wake()
	end

	local seq = "death_0"..math.random( 1, 3 ) -- there are 4 sequences in total, one can be used for a headshot animation
	
	local hitgroup = victim:LastHitGroup()
	if ( hitgroup == HITGROUP_HEAD ) then seq = "death_04" end -- headshot animation
	animent:SetSequence( animent:LookupSequence( seq ) )
	animent:SetPlaybackRate( 1 )
	animent.AutomaticFrameAdvance = true
	function animent:Think() -- this makes the animation work
		self:NextThink( CurTime() )
		return true
	end
	
	timer.Simple( animent:SequenceDuration( seq ), function() -- after the sequence is done, spawn the ragdoll
		local rag = ents.Create( 'prop_ragdoll' )
		SetEntityStuff( rag, animent )
		rag:Spawn()
		rag:Activate()
		TransferBones( animent, rag )
		animent:Remove()
		victim:SpectateEntity( rag ) -- spectate the ragdoll now (this makes the screen jump over a bit though)
		victim.Ragdoll = rag
		victim.LetRespawn = true -- let them respawn now
	end )
	
end )

hook.Add( 'PlayerDeathThink', 'DeathAnimationThink', function( ply )
	if enabled:GetBool() then -- don't do anything if the convar is not enabled
		if !ply.LetRespawn then return false end -- don't let the player respawn yet
	end
end )

hook.Add( 'PlayerSpawn', 'DeathAnimationRemoveRagdoll', CheckAndRemoveRagdoll )
hook.Add( 'PlayerDisconnected', 'DeathAnimationRemoveRagdoll', CheckAndRemoveRagdoll )
