require "libraries/util"

function fantasySealCast( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target = keys.target

	local primary_target_shots = ability:GetLevelSpecialValueFor("primary_target_shots", ability_level)
	local secondary_target_shots = ability:GetLevelSpecialValueFor("secondary_target_shots", ability_level)

	-- Check for secondary targets
	local team = caster:GetTeamNumber()
	local origin = caster:GetAbsOrigin()
	local radius = ability:GetCastRange()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	local iOrder = FIND_ANY_ORDER

	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

	local valid_targets = {}

	for k,unit in pairs(targets) do
		if unit ~= target and (unit:IsStunned() or unit:IsSilenced()) then
			valid_targets[unit] = secondary_target_shots
		end
	end
	valid_targets[target] = primary_target_shots

	local total_shots = sizeOfTable(valid_targets) * secondary_target_shots + primary_target_shots - secondary_target_shots
	local total_duration = ability:GetLevelSpecialValueFor("duration", ability_level)
	local shot_delay = total_duration / total_shots
	print(total_shots, total_duration, shot_delay)

	caster.seal_firing_location = caster:GetAbsOrigin()
	local next_target = target -- Fire at main target first

	local particles = { "particles/reimu/fantasy_seal_red.vpcf", "particles/reimu/fantasy_seal_purple.vpcf", "particles/reimu/fantasy_seal_blue.vpcf", "particles/reimu/fantasy_seal_green.vpcf",
						"particles/reimu/fantasy_seal_orange.vpcf", "particles/reimu/fantasy_seal_teal.vpcf", "particles/reimu/fantasy_seal_yellow.vpcf"}
	local particle_color = 1

	Timers:CreateTimer(0, function()
		if next_target and caster:IsAlive() then

			local particle_name = particles[particle_color]
			particle_color = particle_color + 1
			if particle_color > #particles then particle_color = 1 end

			local projectile_attributes = {
		        Target = next_target,
		        Source = caster,
				EffectName = particle_name,
				Ability = ability,
		        bDodgeable = false,
		        bProvidesVision = false,
		        iMoveSpeed = ability:GetLevelSpecialValueFor("projectile_speed", ability_level),
		        iVisionRadius = 0,
		        iVisionTeamNumber = target:GetTeamNumber(),
		        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
		    }
		    ProjectileManager:CreateTrackingProjectile(projectile_attributes)

		    -- EmitSoundOn("Hero_SkywrathMage.ConcussiveShot.Cast", caster)


			valid_targets[next_target] = valid_targets[next_target] - 1
			if valid_targets[next_target] < 1 then
				valid_targets[next_target] = nil
			end

			if sizeOfTable(valid_targets) > 0 then
				if sizeOfTable(valid_targets) > 1 then -- Prefer to change targets each shot
					next_target = randomIndexOfTable(valid_targets, {next_target})
				else
					next_target = randomIndexOfTable(valid_targets)
				end
				return shot_delay
			end
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

	-- EmitSoundOn("Hero_SkywrathMage.ConcussiveShot.Target", target)
end