
AddCSLuaFile( 'autorun/client/deathanimationmenu.lua' )
AddCSLuaFile( 'autorun/client/deathanimationconvars.lua' )

local enabled = CreateConVar( 'deathanimation_enabled', '1', { FCVAR_REPLICATED, FCVAR_NOTIFY }, 'Sets whether the death animations are enabled.' )
local onground = CreateConVar( 'deathanimation_onground', '0', { FCVAR_REPLICATED, FCVAR_NOTIFY }, 'Sets whether the death animations should only play when a player dies while on the ground.' )

local function CheckForRandomAnim( cvar, ply ) -- Used to check if a convar is '%random_anim%', and also to verify a bit of other stuff

	if !isstring( cvar ) or cvar == '' then return 'death_0'..math.random( 1, 4 ) end
	
	if cvar == '%random_anim%' then
		local anim = table.Random( string.Explode( ',', ply:GetInfo( 'deathanimation_random' ) ) )
		
		if !isstring( anim ) or anim == '' then
			return 'death_0'..math.random( 1, 4 )
		else
			return anim
		end
	else
		return cvar
	end
	
end

local function CheckAndRemoveRagdoll( ply ) -- Remove the player's ragdoll when they respawn or disconnect
	if IsValid( ply.Ragdoll ) then ply.Ragdoll:Remove() end
end

local function SetEntityStuff( ent1, ent2 ) -- Transfer most of the set things on entity 2 to entity 1
	if !IsValid( ent1 ) or !IsValid( ent2 ) then return false end
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

local function TransferBones( base, ragdoll ) -- Transfers the bones of one entity to a ragdoll's physics bones (modified version of some of RobotBoy655's code)
	if !IsValid( base ) or !IsValid( ragdoll ) then return end
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

	if !enabled:GetBool() then return end -- Don't do anything if the convar isn't enabled
	
	if !IsValid( victim ) then return end -- We need a valid victim for this
	
	if onground:GetBool() then -- Don't do anything if they're not allowed to die off ground
		if !victim:OnGround() then return end
	end
	
	victim.LetRespawn = false -- Don't let them respawn
	
	if IsValid( victim:GetRagdollEntity() ) then -- Remove the default ragdoll
		victim:GetRagdollEntity():Remove()
	end
	
	local animent = ents.Create( 'base_gmodentity' ) -- The entity used for the death animation
	SetEntityStuff( animent, victim )
	animent:Spawn()
	animent:Activate()
	
	victim:Spectate( OBS_MODE_CHASE ) -- Make them spectate
	victim:SpectateEntity( animent ) -- Spectate this entity
	
	victim.Ragdoll = animent
	
	animent:SetSolid( SOLID_OBB ) -- This stuff isn't really needed, but just for physics
	animent:PhysicsInit( SOLID_OBB )
	animent:SetMoveType( MOVETYPE_FLYGRAVITY )
	animent:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
	local physobj = animent:GetPhysicsObject()
	if IsValid( physobj ) then
		physobj:Wake()
	end

	local seq = "death_0"..math.random( 1, 4 ) -- Just in case
	
	local hitgroup = victim:LastHitGroup()
	if ( hitgroup == HITGROUP_HEAD ) then seq = CheckForRandomAnim( victim:GetInfo( 'deathanimation_headshot' ), victim ) -- This goes through getting the right sequence based on the convar
	elseif ( hitgroup == HITGROUP_CHEST ) then seq = CheckForRandomAnim( victim:GetInfo( 'deathanimation_chestshot' ), victim )
	elseif ( hitgroup == HITGROUP_STOMACH ) then seq = CheckForRandomAnim( victim:GetInfo( 'deathanimation_stomachshot' ), victim )
	elseif ( hitgroup == HITGROUP_LEFTARM ) then seq = CheckForRandomAnim( victim:GetInfo( 'deathanimation_leftarm' ), victim )
	elseif ( hitgroup == HITGROUP_RIGHTARM ) then seq = CheckForRandomAnim( victim:GetInfo( 'deathanimation_rightarm' ), victim )
	elseif ( hitgroup == HITGROUP_LEFTLEG ) then seq = CheckForRandomAnim( victim:GetInfo( 'deathanimation_leftleg' ), victim )
	elseif ( hitgroup == HITGROUP_RIGHTLEG ) then seq = CheckForRandomAnim( victim:GetInfo( 'deathanimation_rightleg' ), victim )
	else seq = CheckForRandomAnim( victim:GetInfo( 'deathanimation_generic' ), victim )
	end
	
	animent:SetSequence( animent:LookupSequence( seq ) )
	animent:SetPlaybackRate( 1 )
	animent.AutomaticFrameAdvance = true
	function animent:Think() -- This makes the animation work
		self:NextThink( CurTime() )
		return true
	end
	
	timer.Simple( animent:SequenceDuration( seq ), function() -- After the sequence is done, spawn the ragdoll
		local rag = ents.Create( 'prop_ragdoll' )
		SetEntityStuff( rag, animent )
		rag:Spawn()
		rag:Activate()
		TransferBones( animent, rag )
		animent:Remove()
		victim:SpectateEntity( rag ) -- Spectate the ragdoll now (this makes the screen jump over a bit though)
		victim.Ragdoll = rag
		victim.LetRespawn = true -- Let them respawn now
	end )
	
end )

hook.Add( 'PlayerDeathThink', 'DeathAnimationThink', function( ply )
	if enabled:GetBool() then -- Don't do anything if the convar is not enabled
		if !ply.LetRespawn then return false end -- Don't let the player respawn yet
	end
end )

hook.Add( 'PlayerSpawn', 'DeathAnimationRemoveRagdoll', CheckAndRemoveRagdoll )
hook.Add( 'PlayerDisconnected', 'DeathAnimationRemoveRagdoll', CheckAndRemoveRagdoll )
