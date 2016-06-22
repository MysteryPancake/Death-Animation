
AddCSLuaFile( 'autorun/client/deathanimationmenu.lua' )
AddCSLuaFile( 'autorun/client/cl_deathanimation.lua' )

util.AddNetworkString( 'DeathAnimationClient' )

CreateConVar( 'deathanimation_enabled', '1', { FCVAR_REPLICATED, FCVAR_NOTIFY }, 'Sets whether the death animations are enabled.' )
CreateConVar( 'deathanimation_keepragdolls', '0', { FCVAR_REPLICATED, FCVAR_NOTIFY }, 'Sets whether death ragdolls should be kept after death rather than being removed.' )

local enabled = GetConVar( 'deathanimation_enabled' )
local keeprags = GetConVar( 'deathanimation_keepragdolls' )

local LastDamageData = {} -- Used to store damage data to use later

local function CheckAnimation( cvar, ply )

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

local function GetAppropriateAnimation( ply, hitgroup, dmginfo )

	-- Basic stuff
	if ( dmginfo:GetInflictor() == ply ) then return ply:GetInfo( 'deathanimation_kill' ) end
	-- if !ply:OnGround() then return ply:GetInfo( 'deathanimation_offground' ) end -- Too general
	if dmginfo:IsDamageType( DMG_BURN ) then return ply:GetInfo( 'deathanimation_fire' ) end
	if dmginfo:IsDamageType( DMG_DROWN ) then return ply:GetInfo( 'deathanimation_drown' ) end
	if dmginfo:IsExplosionDamage() then return ply:GetInfo( 'deathanimation_explosion' ) end
	
	-- Hitgroups
	if ( hitgroup == HITGROUP_HEAD ) then return ply:GetInfo( 'deathanimation_headshot' ) end
	if ( hitgroup == HITGROUP_CHEST ) then return ply:GetInfo( 'deathanimation_chestshot' ) end
	if ( hitgroup == HITGROUP_STOMACH ) then return ply:GetInfo( 'deathanimation_stomachshot' ) end
	if ( hitgroup == HITGROUP_LEFTARM ) then return ply:GetInfo( 'deathanimation_leftarm' ) end
	if ( hitgroup == HITGROUP_RIGHTARM ) then return ply:GetInfo( 'deathanimation_rightarm' ) end
	if ( hitgroup == HITGROUP_LEFTLEG ) then return ply:GetInfo( 'deathanimation_leftleg' ) end
	if ( hitgroup == HITGROUP_RIGHTLEG ) then return ply:GetInfo( 'deathanimation_rightleg' ) end
	
	-- Generic
	return ply:GetInfo( 'deathanimation_generic' )
	
end

local function GetProperPlayerModel( ply )

	if ply.getPreferredModel then return ply:getPreferredModel( ply:Team() ) end -- DarkRP
	
	local cl_playermodel = ply:GetInfo( "cl_playermodel" )
	local modelpath = player_manager.TranslatePlayerModel( cl_playermodel )
	
	if util.IsValidRagdoll( modelpath ) then
		return modelpath
	else
		return ply:GetModel()
	end

end

local function AllowBoneMovement( ragdoll, bool ) -- Changes whether ragdolls can move
	if !IsValid( ragdoll ) then return end
	for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
	local bone = ragdoll:GetPhysicsObjectNum( i )
		if ( IsValid( bone ) ) then
			bone:EnableMotion( bool )
		end
	end
end

local function TransferBones( base, ragdoll ) -- Transfers the bones of one entity to a ragdoll's physics bones (modified version of some of RobotBoy655's code)
	if !IsValid( base ) or !IsValid( ragdoll ) then return end
	for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
		local physbone = ragdoll:GetPhysicsObjectNum( i )
		if ( IsValid( physbone ) ) then
			local pos, ang = base:GetBonePosition( ragdoll:TranslatePhysBoneToBone( i ) )
			if ( pos ) then physbone:SetPos( pos, true ) end
			if ( ang ) then physbone:SetAngles( ang, true ) end
		end
	end
end

local function SetEntityStuff( ent, ply ) -- Transfer most of the set things on the player to ent

	if !IsValid( ent ) or !IsValid( ply ) then return false end
	
	ent:SetModel( GetProperPlayerModel( ply ) )
	ent:SetPos( ply:GetPos() )
	ent:SetAngles( ply:GetAngles() )
	ent:SetColor( ply:GetColor() )
	ent:SetSkin( ply:GetInfoNum( "cl_playerskin", 0 ) )
	ent:SetFlexScale( ply:GetFlexScale() )
	ent:SetOwner( ply )
	if CPPI then
		ent:CPPISetOwner( ply )
	end
	
	local groups = string.Explode( " ", ply:GetInfo( "cl_playerbodygroups" ) or "" )
	for i = 0, ply:GetNumBodyGroups() - 1 do
		ent:SetBodygroup( i, tonumber( groups[ i + 1 ] ) or ply:GetBodygroup( i ) )
	end
	
	local flexes = {}
	local flexcvar = GetConVar( "sv_playermodel_selector_flexes" ) -- Enhanced playermodel selector
	if flexcvar and flexcvar:GetBool() and tobool( ply:GetInfoNum( "cl_playermodel_selector_unlockflexes", 0 ) ) then
		flexes = ( string.Explode( " ", ply:GetInfo( "cl_playerflexes" ) ) or "" )
	end
	for i = 0, ply:GetFlexNum() - 1 do
		ent:SetFlexWeight( i, tonumber( flexes[ i + 1 ] ) or ply:GetFlexWeight( i ) )
	end
	
	for i = 0, ply:GetBoneCount() do
		ent:ManipulateBoneScale( i, ply:GetManipulateBoneScale( i ) )
		ent:ManipulateBoneAngles( i, ply:GetManipulateBoneAngles( i ) )
		ent:ManipulateBonePosition( i, ply:GetManipulateBonePosition( i ) )
		ent:ManipulateBoneJiggle( i, ply:GetManipulateBoneJiggle( i ) )
	end
	
	ent.EntityMods = ply.EntityMods
	ent.BoneMods = ply.BoneMods
	
	duplicator.ApplyEntityModifiers( nil, ent )
	duplicator.ApplyBoneModifiers( nil, ent )
	
end

hook.Add( 'ScaleNPCDamage', 'DeathAnimationNPCHitgroup', function( npc, hitgroup, dmginfo ) -- This is only used to set the last hit NPC hitgroup
	if IsValid( npc ) then
		LastDamageData[ npc ] = LastDamageData[ npc ] or {}
		LastDamageData[ npc ].hit = hitgroup
		LastDamageData[ npc ].backupdinfo = dmginfo -- This dmginfo is only used as a backup
	end
end )

hook.Add( 'EntityTakeDamage', 'DeathAnimationDMGInfo', function( target, dmginfo ) -- Used to set the dmginfo for NPCs
	if IsValid( target ) and target:IsNPC() then
		LastDamageData[ target ] = LastDamageData[ target ] or {}
		LastDamageData[ target ].dinfo = dmginfo
	end
end )

hook.Add( 'DoPlayerDeath', 'DeathAnimation', function( victim, attacker, dmginfo )

	if !enabled:GetBool() then return end -- Don't do anything if the convar isn't enabled
	
	if !IsValid( victim ) then return end -- We need a valid victim for this
	
	if IsValid( victim:GetRagdollEntity() ) then -- Remove the default ragdoll
		victim:GetRagdollEntity():Remove()
	end
	
	local seq = CheckAnimation( GetAppropriateAnimation( victim, victim:LastHitGroup(), dmginfo ), victim )
	
	if seq == '%no_anim_norag%' then return end

	local rag = ents.Create( 'prop_ragdoll' )
	SetEntityStuff( rag, victim )
	rag:Spawn()
	rag:SetCollisionGroup( COLLISION_GROUP_WORLD )

	TransferBones( victim, rag ) -- Transfer the bones early just in case they don't get transferred later
	
	rag.GetPlayerColor = function() return Vector( victim:GetInfo( "cl_playercolor" ) ) end
	
	net.Start( 'DeathAnimationClient' )
	net.WriteEntity( victim )
	net.WriteInt( rag:EntIndex(), 32 ) -- The ragdoll doesn't exist on the client yet
	net.Broadcast()
	
	victim.Ragdoll = rag
	
	if seq == '%no_anim_ragdoll%' then return end
	
	victim.DoNotRespawn = true -- Don't let them respawn
	AllowBoneMovement( rag, false )
	
	local animent = ents.Create( 'base_gmodentity' ) -- The entity used as a reference for the bone positioning
	animent:SetModel( GetProperPlayerModel( victim ) )
	animent:SetPos( victim:GetPos() )
	animent:SetAngles( victim:GetAngles() )
	animent:SetNoDraw( true ) -- The ragdoll is the thing getting seen
	animent:Spawn()
	
	rag:DeleteOnRemove( animent )
	
	animent:SetSequence( animent:LookupSequence( seq ) ) -- If the sequence isn't valid, the sequence length is 0, so the timer takes care of things
	animent:SetPlaybackRate( 1 )
	animent.AutomaticFrameAdvance = true
	
	animent:SetSolid( SOLID_OBB ) -- This stuff isn't really needed, but just for physics
	animent:PhysicsInit( SOLID_OBB )
	animent:SetMoveType( MOVETYPE_FLYGRAVITY )
	animent:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
	animent:PhysWake()
	
	function animent:Think() -- This makes the animation work
		TransferBones( animent, rag )
		self:NextThink( CurTime() )
		return true
	end
	
	victim:Spectate( OBS_MODE_CHASE ) -- Make them spectate
	victim:SpectateEntity( rag ) -- Spectate the ragdoll
	
	timer.Simple( animent:SequenceDuration( seq ), function() -- After the sequence is done, remove the animation reference
	
		if IsValid( animent ) then animent:Remove() end
		AllowBoneMovement( rag, true )
		
		victim.DoNotRespawn = false -- Let them respawn now
		
		if victim.AddCleanup then -- Add the ragdoll to the cleanup list
			victim:AddCleanup( "ragdolls", rag )
		end
		
		undo.Create( 'ragdoll' ) -- Add the ragdoll to the undo list
		undo.AddEntity( rag )
		undo.SetPlayer( victim )
		undo.Finish()
		
	end )
	
end )

hook.Add( 'PlayerDeathThink', 'DeathAnimationThink', function( ply )
	if enabled:GetBool() then -- Don't do anything if the convar is not enabled
		if ply.DoNotRespawn then return false end -- Don't let the player respawn yet
	end
end )

local function CheckAndRemoveRagdoll( ply ) -- Remove the player's ragdoll when they respawn or disconnect
	if !keeprags:GetBool() then -- Don't do anything if the convar is not enabled
		if IsValid( ply.Ragdoll ) then ply.Ragdoll:Remove() end
	end
end

hook.Add( 'PlayerSpawn', 'DeathAnimationRemoveRagdoll', CheckAndRemoveRagdoll )
hook.Add( 'PlayerDisconnected', 'DeathAnimationRemoveRagdoll', CheckAndRemoveRagdoll )
