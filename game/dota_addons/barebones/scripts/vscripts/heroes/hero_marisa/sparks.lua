require "libraries/util"

function startSpark(caster, ability, modifier, slow_modifier, direction)
	local particle_name = "particles/units/heroes/hero_phoenix/phoenix_sunray.vpcf"

	local spark_ability = caster:FindAbilityByName("master_spark")
	local ability_level = spark_ability:GetLevel() - 1
	local end_distance = spark_ability:GetLevelSpecialValueFor("range", ability_level)
	local end_radius = spark_ability:GetLevelSpecialValueFor("end_radius", ability_level)
	local start_radius = spark_ability:GetLevelSpecialValueFor("start_radius", ability_level)
	local damage_interval = spark_ability:GetLevelSpecialValueFor("damage_interval", ability_level)
	local damage = spark_ability:GetLevelSpecialValueFor("damage", ability_level) * damage_interval / spark_ability:GetChannelTime()
	local damage_type = spark_ability:GetAbilityDamageType()

	ability:ApplyDataDrivenModifier(caster, caster, modifier, {})
	local particles = {}

	-- Reverse if cast by Blazing Star
	local reverse = caster:HasModifier("modifier_blazing_star")

	local spell_forward = direction
	if reverse then spell_forward = spell_forward * -1 end

	local pfx = ParticleManager:CreateParticle( particle_name, PATTACH_ABSORIGIN_FOLLOW, caster )
	table.insert(particles, pfx)
	ParticleManager:SetParticleControlEnt( pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true )

	local range = end_distance + end_radius
	local endcapPos = caster:GetAbsOrigin() + spell_forward * range
	ParticleManager:SetParticleControl( pfx, 1, endcapPos )

	StartSoundEvent("Touhou.Spark", caster)

	local rotationPoint = caster:GetAbsOrigin() + spell_forward * end_distance
	for i=1,3 do
		if i % 2 == 1 then
			local secondarypfx = ParticleManager:CreateParticle( particle_name, PATTACH_ABSORIGIN_FOLLOW, caster )
			table.insert(particles, secondarypfx)
			ParticleManager:SetParticleControlEnt( secondarypfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true )

			secondaryLaserPoint = RotatePosition(endcapPos, QAngle(0,i * 90,0), rotationPoint)
			ParticleManager:SetParticleControl( secondarypfx, 1, secondaryLaserPoint )
		end
	end

	Timers:CreateTimer(0, function()
		if not caster:IsNull() and caster:HasModifier(modifier) then
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

				-- Particle
				local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_sunray_beam_enemy.vpcf", PATTACH_ABSORIGIN, unit )
				ParticleManager:SetParticleControlEnt( pfx, 1, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true )
				ParticleManager:ReleaseParticleIndex( pfx )
			end

			-- Update particles for if Marisa is moved
			local range = end_distance + end_radius
			local rotationPoint = caster:GetAbsOrigin() + spell_forward * end_distance
			local laserPoints = {}
			laserPoints[1] = caster:GetAbsOrigin() + spell_forward * range
			
			for i=1,3 do
				if i % 2 == 1 then
					table.insert(laserPoints, RotatePosition(laserPoints[1], QAngle(0,i * 90,0), rotationPoint))
				end
			end

			for k,particle in pairs(particles) do
				ParticleManager:SetParticleControl(particle, 1, laserPoints[k])
			end

			return damage_interval
		else
			for k,particle in pairs(particles) do
				ParticleManager:DestroyParticle(particle, true)
				StopSoundEvent("Touhou.Spark", caster)
			end
		end
	end)
end