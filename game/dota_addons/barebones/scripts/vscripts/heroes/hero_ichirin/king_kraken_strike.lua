function krakenStrikeCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target_point = keys.target_points[1]

	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local max_delay = ability:GetLevelSpecialValueFor("max_delay", ability_level)
	local min_delay = ability:GetLevelSpecialValueFor("min_delay", ability_level)
	local max_damage = ability:GetLevelSpecialValueFor("max_damage", ability_level)
	local min_damage = ability:GetLevelSpecialValueFor("min_damage", ability_level)
	local max_root = ability:GetLevelSpecialValueFor("max_root_duration", ability_level)
	local min_root = ability:GetLevelSpecialValueFor("min_root_duration", ability_level)
	local particle_height = ability:GetLevelSpecialValueFor("particle_height", ability_level)
	local particle_delay = 0.5
	local particle_fall_time = 0.25 -- rough guess -- should probably depend on particle height to be honest

	local distance = (target_point - caster:GetAbsOrigin()):Length2D()
	local effective_scaling_factor = (distance - radius) / (ability:GetCastRange() - radius * 2)
	if effective_scaling_factor < 0 then effective_scaling_factor = 0 end
	if effective_scaling_factor > 1 then effective_scaling_factor = 1 end

	local delay = min_delay + (max_delay - min_delay) * effective_scaling_factor
	local damage = min_damage + (max_damage - min_damage) * effective_scaling_factor
	local root_duration = min_root + (max_root - min_root) * effective_scaling_factor

	-- Check for traditional era active
	if caster:HasModifier("modifier_traditional_era") then
		local traditional_era_ability = caster:FindAbilityByName("traditional_era")
		local traditional_era_level = traditional_era_ability:GetLevel() - 1
		radius = radius + traditional_era_ability:GetLevelSpecialValueFor("kraken_radius_increase", traditional_era_level)
		root_duration = root_duration * (1 + traditional_era_ability:GetLevelSpecialValueFor("kraken_root_duration_increase", traditional_era_level) / 100)
	end

	Timers:CreateTimer(delay - particle_delay, function()
		local particle = ParticleManager:CreateParticle("particles/ichirin/king_kraken_strike.vpcf", PATTACH_POINT_FOLLOW, caster)
		ParticleManager:SetParticleControl(particle, 0, target_point + Vector(0,0,particle_height)) -- Fist spawn position
		ParticleManager:SetParticleControl(particle, 1, Vector(particle_delay,0,0)) -- Particle duration
		ParticleManager:SetParticleControl(particle, 2, Vector(0,0,0)) -- Max fist velocity -- set to 0 to freeze for now
		Timers:CreateTimer(particle_delay - particle_fall_time, function()
			ParticleManager:SetParticleControl(particle, 2, Vector(100000,0,0))
			Timers:CreateTimer(particle_fall_time, function()
				-- Check for units hit
				local team = caster:GetTeamNumber()
				local origin = target_point
				local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
				local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
				local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
				local iOrder = FIND_ANY_ORDER

				local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
				local damage_type = ability:GetAbilityDamageType()

				for k,unit in pairs(targets) do
					ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
					ability:ApplyDataDrivenModifier(caster, unit, "modifier_king_kraken_strike_root", {duration = root_duration})
				end

				ParticleManager:DestroyParticle(particle, false)
			end)
		end)
	end)

	-- Check for autumn storm clouds active
	if caster:HasModifier("modifier_storm_clouds_active") then
		local storm_clouds_ability = caster:FindAbilityByName("storm_clouds")
		local storm_clouds_level = storm_clouds_ability:GetLevel() - 1
		ability:EndCooldown()
		ability:StartCooldown(storm_clouds_ability:GetLevelSpecialValueFor("active_kraken_cooldown", storm_clouds_level))
	end
end