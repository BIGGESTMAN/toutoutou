function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]

	local delay = ability:GetSpecialValueFor("delay")
	local update_interval = ability:GetSpecialValueFor("update_interval")
	local duration = ability:GetSpecialValueFor("duration")
	local base_damage = ability:GetSpecialValueFor("base_damage")
	local pull_radius = ability:GetSpecialValueFor("pull_radius")
	local pull_speed = ability:GetSpecialValueFor("pull_speed")
	local damage_radius = ability:GetSpecialValueFor("damage_radius")
	local effect_increase = ability:GetSpecialValueFor("effect_increase_percent") / 100
	local effect_increase_interval = ability:GetSpecialValueFor("effect_increase_interval")
	local damage_type = ability:GetAbilityDamageType()
	local damage_interval = ability:GetSpecialValueFor("damage_interval")

	if caster:HasScepter() then
		pull_radius = ability:GetSpecialValueFor("aghanim_scepter_pull_radius")
		damage_radius = ability:GetSpecialValueFor("aghanim_scepter_damage_radius")
	end

	local debuffed_units = {}
	local damaged_units = {}
	local duration_elapsed = 0
	local damage_ticks = 0

	CT(delay, function()
		local effect_multiplier = 1 + effect_increase * math.floor(duration_elapsed / effect_increase_interval)

		local team = caster:GetTeamNumber()
		local origin = target_point
		local radius = pull_radius * effect_multiplier
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
		local iFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
		local iOrder = FIND_ANY_ORDER
		local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

		local speed = pull_speed * effect_multiplier * update_interval

		local units_in_debuff_radius = {}
		for k,unit in pairs(targets) do
			units_in_debuff_radius[unit] = true
			debuffed_units[unit] = true
			ability:ApplyDataDrivenModifier(caster, unit, "modifier_subterranean_sun_pull", {})
			if not unit:IsMagicImmune() then ability:ApplyDataDrivenModifier(caster, unit, "modifier_subterranean_sun_silence", {}) end
			local direction = (target_point - unit:GetAbsOrigin()):Normalized()
			unit:SetAbsOrigin(unit:GetAbsOrigin() + direction * speed)
		end
		for unit,v in pairs(debuffed_units) do
			if not units_in_debuff_radius[unit] then
				debuffed_units[unit] = nil
				unit:RemoveModifierByName("modifier_subterranean_sun_pull")
				unit:RemoveModifierByName("modifier_subterranean_sun_silence")
				FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), false)
			end
		end
		DebugDrawCircle(origin, Vector(255,128,128), 1, radius, true, update_interval)

		radius = damage_radius * effect_multiplier
		targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

		local damage = base_damage * effect_multiplier
		local damage_tick = false
		if duration_elapsed >= damage_interval * (1 + damage_ticks) then
			damage_ticks = damage_ticks + 1
			damage_tick = true
		end

		local units_in_damage_radius = {}
		for k,unit in pairs(targets) do
			units_in_damage_radius[unit] = true
			if not damaged_units[unit] then
				damaged_units[unit] = true
				ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
			end
			if damage_tick then ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type}) end
		end
		for unit,v in pairs(damaged_units) do
			if not units_in_damage_radius[unit] then damaged_units[unit] = nil end
		end

		duration_elapsed = duration_elapsed + update_interval
		if duration_elapsed < duration then
			return update_interval
		else
			for unit,v in pairs(debuffed_units) do
				unit:RemoveModifierByName("modifier_subterranean_sun_pull")
				unit:RemoveModifierByName("modifier_subterranean_sun_silence")
				FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), false)
			end
		end
		DebugDrawCircle(origin, Vector(255,0,0), 5, radius, true, update_interval)
	end)
end