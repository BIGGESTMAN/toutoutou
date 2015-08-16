function fantasySealCast( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target = keys.target

	local seals_fired = 0
	caster.seal_firing_location = caster:GetAbsOrigin()
	Timers:CreateTimer(0, function()
		if seals_fired < ability:GetLevelSpecialValueFor("number_of_seals", ability_level) then
			local projectile_attributes = {
		        Target = target,
		        Source = caster,
				EffectName = "particles/reimu/fantasy_seal2.vpcf",
				Ability = ability,
		        bDodgeable = false,
		        bProvidesVision = false,
		        iMoveSpeed = ability:GetLevelSpecialValueFor("projectile_speed", ability_level),
		        iVisionRadius = 0,
		        iVisionTeamNumber = target:GetTeamNumber(),
		        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
		    }
		    ProjectileManager:CreateTrackingProjectile(projectile_attributes)

		    seals_fired = seals_fired + 1

		    EmitSoundOn("Hero_ChaosKnight.ChaosBolt.Cast", caster)

			return ability:GetLevelSpecialValueFor("delay", ability_level)
		end
	end)
end

function fantasySealHit( keys )
	local caster = keys.caster
	local target = keys.target
	local target_location = target:GetAbsOrigin()
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local max_damage = ability:GetLevelSpecialValueFor("max_damage", ability_level)
	local min_damage = ability:GetLevelSpecialValueFor("min_damage", ability_level)
	local max_damage_distance = ability:GetLevelSpecialValueFor("max_damage_distance", ability_level)
	local min_damage_distance = ability:GetLevelSpecialValueFor("min_damage_distance", ability_level)

	local seal_damage = max_damage
	local distance = (target_location - caster.seal_firing_location):Length2D()

	if ((distance > max_damage_distance) and (distance < min_damage_distance)) then
		seal_damage = seal_damage - ((max_damage - min_damage) * ((distance - max_damage_distance) / (min_damage_distance - max_damage_distance)))
	elseif (distance > min_damage_distance) then
		seal_damage = min_damage
	end

	local damage_type = ability:GetAbilityDamageType()
	ApplyDamage({victim = target, attacker = caster, damage = seal_damage, damage_type = damage_type})

	EmitSoundOn("Hero_ChaosKnight.ChaosBolt.Impact", target)
end