function illusionaryDominance( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local caster_location = caster:GetAbsOrigin()
	local target_point = keys.target_points[1]
	local direction = (target_point - caster_location):Normalized()
	local distance = ability:GetLevelSpecialValueFor("range", ability_level)

	if caster:HasScepter() then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_peerless_wind_god_enabled", {})
		caster:FindModifierByName("modifier_peerless_wind_god_enabled").origin = caster_location
	end

	dash(caster, ability, direction, distance)

	if caster:HasModifier("modifier_illusionary_dominance_accelerating") then
		ability:EndCooldown()
		local accelerating_stacks = (caster:FindModifierByName("modifier_illusionary_dominance_accelerating")):GetStackCount()
		local final_cooldown = ability:GetCooldown(ability_level) -
								ability:GetLevelSpecialValueFor("cooldown_reduction", ability_level) * accelerating_stacks
		local minimum_cooldown = ability:GetLevelSpecialValueFor("minimum_cooldown", ability_level)
		if final_cooldown < minimum_cooldown then
			final_cooldown = minimum_cooldown
		end
		ability:StartCooldown(final_cooldown)
	end
end

function dash(caster, ability, direction, distance)
	local ability_level = ability:GetLevel() - 1

	local speed = ability:GetLevelSpecialValueFor("speed", ability_level)
	if caster:HasModifier("modifier_illusionary_dominance_accelerating") then
		local accelerating_stacks = (caster:FindModifierByName("modifier_illusionary_dominance_accelerating")):GetStackCount()
		local speed = speed + ability:GetLevelSpecialValueFor("speed_increase", ability_level) * accelerating_stacks
		local maximum_speed = ability:GetLevelSpecialValueFor("max_speed", ability_level)
		if speed > maximum_speed then
			speed = maximum_speed
		end
	end
	local final_speed = speed * 0.03
	local traveled_distance = 0

	ability.units_hit = {}
	ability.canAccelerate = true

	local particle = ParticleManager:CreateParticle("particles/aya/illusionary_dominance_dash.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_ABSORIGIN, "attach_origin", caster:GetAbsOrigin(), true)

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_illusionary_dominance_dashing", {})
	local modifier = caster:FindModifierByName("modifier_illusionary_dominance_dashing")
	modifier.traveled_distance = 0
	modifier.distance = distance
	modifier.direction = direction
	modifier.speed = final_speed
end

function updateDashing(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local modifier = caster:FindModifierByName("modifier_illusionary_dominance_dashing")

	-- I have no literally no idea how modifier can be nil here, but whatever
	if modifier and modifier.traveled_distance < modifier.distance then
		local caster_location = caster:GetAbsOrigin() + modifier.direction * modifier.speed
		caster:SetAbsOrigin(caster_location)
		modifier.traveled_distance = modifier.traveled_distance + modifier.speed
	else
		caster:RemoveModifierByName("modifier_illusionary_dominance_dashing")
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), false)
	end

	-- Check for units hit
	local team = caster:GetTeamNumber()
	local origin = caster:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	local iOrder = FIND_ANY_ORDER
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	-- DebugDrawCircle(origin, Vector(180,40,40), 1, radius, true, 0.5)

	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

	for k,unit in pairs(targets) do
		if not ability.units_hit[unit] then
			ability.units_hit[unit] = true
			caster:PerformAttack(unit, true, true, true, true )
			if ability.canAccelerate and unit:IsHero() then
				if not caster:HasModifier("modifier_illusionary_dominance_accelerating") then
					ability:ApplyDataDrivenModifier(caster, caster, "modifier_illusionary_dominance_accelerating", {})
				end
				(caster:FindModifierByName("modifier_illusionary_dominance_accelerating")):IncrementStackCount()
				ability.canAccelerate = false
			end

			-- Slash particles
			local slashFxIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_sleightoffist_tgt.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
			--StartSoundEvent( slashSound, caster )
			Timers:CreateTimer( 0.1, function()
				ParticleManager:DestroyParticle( slashFxIndex, false )
				ParticleManager:ReleaseParticleIndex( slashFxIndex )
				--StopSoundEvent( slashSound, caster )
				return nil
			end)
		end
	end
end

-- Peerless Wind God --

function peerlessWindGod(keys)
	local caster = keys.caster
	local ability = caster:FindAbilityByName("illusionary_dominance")
	local destination = caster:FindModifierByName("modifier_peerless_wind_god_enabled").origin
	local direction = (destination - caster:GetAbsOrigin()):Normalized()
	local distance = (destination - caster:GetAbsOrigin()):Length2D()

	caster:RemoveModifierByName("modifier_peerless_wind_god_enabled")

	dash(caster, ability, direction, distance)

	if direction:Length2D() > 0 then
		direction.z = 0
		caster:SetForwardVector(direction)
	end
end

function updateAbilityEnabled(keys)
	if keys.caster:HasModifier("modifier_peerless_wind_god_enabled") then
		keys.ability:SetActivated(true)
	else
		keys.ability:SetActivated(false)
	end
end

function peerlessWindGodLearned(keys)
	local ability = keys.caster:FindAbilityByName("peerless_wind_god")
	ability:SetLevel(1)
	-- local opening_wind = keys.caster:FindAbilityByName("opening_wind")
	-- ability:SetAbilityIndex(4)
	-- opening_wind:SetAbilityIndex(5)
	keys.caster:SwapAbilities("opening_wind", "peerless_wind_god", true, true)
end