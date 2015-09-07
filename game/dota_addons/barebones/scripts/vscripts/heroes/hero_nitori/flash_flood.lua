function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]

	local delay = ability:GetSpecialValueFor("delay")
	local duration = ability:GetSpecialValueFor("duration")
	local radius = ability:GetSpecialValueFor("radius")
	local damage = ability:GetSpecialValueFor("damage")
	local damage_type = ability:GetAbilityDamageType()
	local damage_interval = ability:GetSpecialValueFor("damage_interval")
	local debuff_duration = ability:GetSpecialValueFor("debuff_duration")
	local update_interval = ability:GetSpecialValueFor("update_interval")

	local elapsed_duration = 0

	Timers:CreateTimer(delay, function()
		if elapsed_duration < duration then
			elapsed_duration = elapsed_duration + damage_interval

			local team = caster:GetTeamNumber()
			local origin = target_point
			local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
			local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
			local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
			local iOrder = FIND_ANY_ORDER
			DebugDrawCircle(origin, Vector(40,40,180), 1, radius, true, 0.5)

			local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

			for k,unit in pairs(targets) do
				ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
				-- ability:ApplyDataDrivenModifier(caster, unit, "modifier_flash_flood_debuff", {duration = debuff_duration})
			end

			return damage_interval
		end
	end)
end