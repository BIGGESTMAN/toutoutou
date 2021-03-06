require "libraries/util"
require "libraries/animations"

function startSpark(caster, ability, modifier, debuff_modifier, stacking_debuff, direction, spark_ability, particle)
	print(spark_ability)
	local ability_level = spark_ability:GetLevel() - 1
	local end_distance = spark_ability:GetLevelSpecialValueFor("range", ability_level)
	local end_radius = spark_ability:GetLevelSpecialValueFor("end_radius", ability_level)
	local start_radius = spark_ability:GetLevelSpecialValueFor("start_radius", ability_level)
	local duration = spark_ability:GetChannelTime()
	if duration == 0 then
		duration = spark_ability:GetLevelSpecialValueFor("duration", ability_level)
	end
	local tracer_duration = spark_ability:GetSpecialValueFor("tracer_duration")
	local damage_interval = spark_ability:GetLevelSpecialValueFor("damage_interval", ability_level)
	local damage = spark_ability:GetLevelSpecialValueFor("damage", ability_level) * damage_interval / (duration + damage_interval - tracer_duration)
	local damage_type = spark_ability:GetAbilityDamageType()

	local initial_slow = spark_ability:GetSpecialValueFor("initial_slow")
	local ending_slow = spark_ability:GetSpecialValueFor("ending_slow")
	local slow_increment = (ending_slow - initial_slow) * damage_interval / (duration - tracer_duration)
	local current_slow = initial_slow

	StartAnimation(caster, {duration=duration, activity=ACT_DOTA_CAST_ABILITY_5, rate=(38/30) / duration, translate = "lsa"})

	local spell_forward = direction
	ability:ApplyDataDrivenModifier(caster, caster, modifier, {})

	-- Particle stuff
	local particle_length = spark_ability:GetLevelSpecialValueFor("particle_length", ability_level)
	local particle_offset = spell_forward * particle_length + Vector(0,0,80)
	local particle = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin() + particle_offset)

	-- Provide initial vision through hacky hacks, aww yeah
	GetEnemiesInCone(caster, start_radius, end_radius, end_distance, spell_forward, 4, false, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, damage_interval)

	EmitSoundOn("Touhou.Spark", caster)
	Timers:CreateTimer(tracer_duration, function()
		if not caster:IsNull() and caster:HasModifier(modifier) then
			-- Adjust direction if Marisa is flying around
			if caster:HasModifier("modifier_blazing_star") then
				spell_forward = caster:GetForwardVector() * -1
			end

			local cone_units = GetEnemiesInCone(caster, start_radius, end_radius, end_distance, spell_forward, 4, false, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, damage_interval)
			for k,unit in pairs(cone_units) do
				ability:ApplyDataDrivenModifier(caster, unit, debuff_modifier, {})
				if stacking_debuff then
					unit:FindModifierByName(debuff_modifier):SetStackCount(current_slow)
					current_slow = current_slow + slow_increment
				end
				ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})

				-- Provide vision of Marisa to targets hit
				caster:MakeVisibleDueToAttack(caster:GetOpposingTeamNumber())
				
				-- if caster:HasScepter() then
				-- 	spark_ability:ApplyDataDrivenModifier(caster, unit, "modifier_master_spark_vulnerability", {})
				-- 	local vulnerability_modifier = unit:FindModifierByName("modifier_master_spark_vulnerability")
				-- 	vulnerability_modifier:IncrementStackCount()
				-- end
			end

			return damage_interval
		end
	end)

	-- Update particles & sound
	Timers:CreateTimer(0, function()
		if not caster:IsNull() and caster:HasModifier(modifier) then
			-- Adjust direction if Marisa is flying around
			if caster:HasModifier("modifier_blazing_star") then
				spell_forward = caster:GetForwardVector() * -1
			end

			-- Update particle for if Marisa is moved
			ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin() + particle_offset)

			return 0.03
		else
			ParticleManager:DestroyParticle(particle, true)
			StopSoundEvent("Touhou.Spark", caster)
			EndAnimation(caster)
		end
	end)
end