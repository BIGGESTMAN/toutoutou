function spellCast(keys)
	local caster = keys.caster
	local target_point = keys.target_points[1]
	local ability = keys.ability

	local health_percent_as_damage = ability:GetSpecialValueFor("impact_damage_percent")
	local impact_radius = ability:GetSpecialValueFor("impact_radius")
	local impact_damage_type = DAMAGE_TYPE_PURE

	local fissure_total_damage = ability:GetSpecialValueFor("fissure_total_damage")
	local fissure_duration = ability:GetSpecialValueFor("duration")
	local fissure_damage = fissure_total_damage / fissure_duration
	local fissure_radius = ability:GetSpecialValueFor("fissure_radius")
	local fissure_damage_type = DAMAGE_TYPE_MAGICAL
	local damage_interval = ability:GetSpecialValueFor("damage_interval")

	local update_interval = ability:GetSpecialValueFor("update_interval")
	local speed = ability:GetSpecialValueFor("travel_speed") * update_interval

	local direction = (target_point - caster:GetAbsOrigin()):Normalized()
	local target_range = (target_point - caster:GetAbsOrigin()):Length2D()
	local distance_traveled = 0

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_fujiyama_volcano", {})
	local dash_particle = ParticleManager:CreateParticle("particles/mokou/fujiyama_volcano_dash.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)

	Timers:CreateTimer(0, function()
		if caster:IsAlive() then
			if distance_traveled < target_range then
				-- Move caster -- includes a distance check to prevent overshooting
				local distance = target_range - distance_traveled
				if speed < distance then
					caster:SetAbsOrigin(caster:GetAbsOrigin() + direction * speed)
				else
					caster:SetAbsOrigin(caster:GetAbsOrigin() + direction * distance)
				end
				distance_traveled = distance_traveled + speed
				return update_interval
			else
				FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), false)
				caster:RemoveModifierByName("modifier_fujiyama_volcano")

				ParticleManager:DestroyParticle(dash_particle, false)
				local impact_particle = ParticleManager:CreateParticle("particles/mokou/fujiyama_volcano_impact.vpcf", PATTACH_ABSORIGIN, caster)
				ParticleManager:SetParticleControl(impact_particle, 0, caster:GetAbsOrigin())

				local impact_damage = caster:GetHealth() * health_percent_as_damage / 100
				ApplyDamage({victim = caster, attacker = caster, damage = impact_damage, damage_type = impact_damage_type})

				local team = caster:GetTeamNumber()
				local origin = caster:GetAbsOrigin()
				local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
				local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
				local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
				local iOrder = FIND_CLOSEST
				local targets = FindUnitsInRadius(team, origin, nil, impact_radius, iTeam, iType, iFlag, iOrder, false)
				for k,unit in pairs(targets) do
					ApplyDamage({victim = unit, attacker = caster, damage = impact_damage, damage_type = impact_damage_type})
				end

				-- Start fissure dot/slow effect
				local fissure_center = caster:GetAbsOrigin()
				local fissure_time_active = 0
				local fissure_damage_ticks = 0

				Timers:CreateTimer(0, function()
					fissure_time_active = fissure_time_active + update_interval
					local damage_tick = (fissure_time_active - fissure_damage_ticks * damage_interval) >= damage_interval
					if damage_tick then
						fissure_damage_ticks = fissure_damage_ticks + 1
						-- DebugDrawCircle(origin, Vector(255,0,0), 1, fissure_radius, true, 0.2)
					end

					local team = caster:GetTeamNumber()
					local origin = caster:GetAbsOrigin()
					local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
					local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
					local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
					local iOrder = FIND_CLOSEST
					local targets = FindUnitsInRadius(team, origin, nil, fissure_radius, iTeam, iType, iFlag, iOrder, false)
					for k,unit in pairs(targets) do
						ability:ApplyDataDrivenModifier(caster, unit, "modifier_fujiyama_volcano_slow", {})
						if damage_tick then
							ApplyDamage({victim = unit, attacker = caster, damage = fissure_damage, damage_type = fissure_damage_type})
						end
					end

					if fissure_time_active < fissure_duration then return update_interval end
				end)
			end
		end
	end)
end