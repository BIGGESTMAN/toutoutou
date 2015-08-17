require "libraries/util"

function startSpark(caster, ability, modifier, slow_modifier, direction)
	local spark_ability = caster:FindAbilityByName("master_spark")
	local ability_level = spark_ability:GetLevel() - 1
	local end_distance = spark_ability:GetLevelSpecialValueFor("range", ability_level)
	local end_radius = spark_ability:GetLevelSpecialValueFor("end_radius", ability_level)
	local start_radius = spark_ability:GetLevelSpecialValueFor("start_radius", ability_level)
	local damage_interval = spark_ability:GetLevelSpecialValueFor("damage_interval", ability_level)
	local damage = spark_ability:GetLevelSpecialValueFor("damage", ability_level) * damage_interval / spark_ability:GetChannelTime()
	local damage_type = spark_ability:GetAbilityDamageType()

	local spell_forward = direction
	ability:ApplyDataDrivenModifier(caster, caster, modifier, {})

	-- Particle stuff
	local particle_offset = spell_forward * 1500 + Vector(0,0,80)
	local particle = ParticleManager:CreateParticle("particles/marisa/master_spark.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin() + particle_offset)

	StartSoundEvent("Touhou.Spark", caster)

	Timers:CreateTimer(0, function()
		if not caster:IsNull() and caster:HasModifier(modifier) then
			-- Adjust direction if Marisa is flying around
			if caster:HasModifier("modifier_blazing_star") then
				spell_forward = caster:GetForwardVector() * -1
			end

			local cone_units = GetEnemiesInCone(caster, start_radius, end_radius, end_distance, spell_forward, 3, true)
			for k,unit in pairs(cone_units) do
				-- Damage
				ApplyDamage({ victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
				ability:ApplyDataDrivenModifier(caster, unit, slow_modifier, {})
				
				if caster:HasScepter() then
					spark_ability:ApplyDataDrivenModifier(caster, unit, "modifier_master_spark_vulnerability", {})
					local vulnerability_modifier = unit:FindModifierByName("modifier_master_spark_vulnerability")
					vulnerability_modifier:IncrementStackCount()
				end
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
		end
	end)
end