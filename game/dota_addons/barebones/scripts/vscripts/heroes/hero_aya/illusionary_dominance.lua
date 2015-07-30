function illusionaryDominance( keys )
	local caster = keys.caster
	local caster_location = caster:GetAbsOrigin() 
	local target_point = keys.target_points[1]
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local speed = ability:GetLevelSpecialValueFor("speed", ability_level)
	if caster:HasModifier(keys.accelerating_modifier) then
		local accelerating_stacks = (caster:FindModifierByName(keys.accelerating_modifier)):GetStackCount()
		local speed = speed + ability:GetLevelSpecialValueFor("speed_increase", ability_level) * accelerating_stacks
		local maximum_speed = ability:GetLevelSpecialValueFor("max_speed", ability_level)
		if speed > maximum_speed then
			speed = maximum_speed
		end

		ability:EndCooldown()
		local final_cooldown = ability:GetCooldown(ability_level) -
								ability:GetLevelSpecialValueFor("cooldown_reduction", ability_level) * accelerating_stacks
		local minimum_cooldown = ability:GetLevelSpecialValueFor("minimum_cooldown", ability_level)
		if final_cooldown < minimum_cooldown then
			final_cooldown = minimum_cooldown
		end
		ability:StartCooldown(final_cooldown)
	end
	local final_speed = speed * 0.03
	local distance = ability:GetLevelSpecialValueFor("range", ability_level)
	local direction = (target_point - caster_location):Normalized()
	local traveled_distance = 0

	ability.targetsHit = {}
	ability.canAccelerate = true

	-- Moving the caster
	Timers:CreateTimer(0, function()
		if traveled_distance < distance then
			caster_location = caster_location + direction * final_speed
			caster:SetAbsOrigin(caster_location)
			traveled_distance = traveled_distance + final_speed
			return 0.03
		else
			caster:RemoveModifierByName(keys.dashing_modifier)
			FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), false)
		end
	end)
end

function illusionaryDominanceHit( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local hit = false
	local particleSlashName = keys.particle
	local accelerating_modifier = keys.accelerating_modifier

	-- Ignore the target if its already on the table
	local targetsHit = ability.targetsHit
	for k,v in pairs(targetsHit) do
		if v == target then
			hit = true
		end
	end

	if not hit then
		caster:PerformAttack(target, true, true, true, true )
		if ability.canAccelerate and target:IsHero() then
			if not caster:HasModifier(keys.accelerating_modifier) then
				ability:ApplyDataDrivenModifier(caster, caster, accelerating_modifier, {})
			end
			(caster:FindModifierByName(accelerating_modifier)):IncrementStackCount()
			ability.canAccelerate = false
		end

		-- Slash particles
		local slashFxIndex = ParticleManager:CreateParticle( particleSlashName, PATTACH_ABSORIGIN_FOLLOW, target )
		--StartSoundEvent( slashSound, caster )
		Timers:CreateTimer( 0.1, function()
				ParticleManager:DestroyParticle( slashFxIndex, false )
				ParticleManager:ReleaseParticleIndex( slashFxIndex )
				--StopSoundEvent( slashSound, caster )
				return nil
			end
		)
		table.insert(ability.targetsHit, target)
	end
end
