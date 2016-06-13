
-- This file contains all the client convars to do with the animations, because each client should be able to choose their death animation, right?
-- I don't think this makes the script exploitable though, if any errors happen, the one setting these convars is usually the one that suffers

CreateClientConVar( 'deathanimation_random', 'death_01,death_02,death_03', true, true, 'Changes the table of random animations to play.' )

CreateClientConVar( 'deathanimation_headshot', 'death_04', true, true, 'Changes the head-shot death animation.' )
CreateClientConVar( 'deathanimation_chestshot', '%random_anim%', true, true, 'Changes the chest-shot death animation.' )
CreateClientConVar( 'deathanimation_stomachshot', '%random_anim%', true, true, 'Changes the stomach-shot death animation.' )
CreateClientConVar( 'deathanimation_leftarm', '%random_anim%', true, true, 'Changes the left-arm death animation.' )
CreateClientConVar( 'deathanimation_rightarm', '%random_anim%', true, true, 'Changes the right-arm death animation.' )
CreateClientConVar( 'deathanimation_leftleg', '%random_anim%', true, true, 'Changes the left-leg death animation.' )
CreateClientConVar( 'deathanimation_rightleg', '%random_anim%', true, true, 'Changes the right-leg death animation.' )
CreateClientConVar( 'deathanimation_generic', '%random_anim%', true, true, 'Changes the generic death animation.' )
