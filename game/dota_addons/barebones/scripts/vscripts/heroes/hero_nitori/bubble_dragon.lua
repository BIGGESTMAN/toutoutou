function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]

	local duration = ability:GetSpecialValueFor("duration")
	local range = ability:GetSpecialValueFor("range")
	local radius = ability:GetSpecialValueFor("radius")
	local damage = ability:GetSpecialValueFor("damage_per_second")
	local damage_type = ability:GetAbilityDamageType()
	local damage_interval = ability:GetSpecialValueFor("damage_interval")
	local update_interval = ability:GetSpecialValueFor("update_interval")
	local speed = ability:GetSpecialValueFor("travel_speed") * update_interval
	local arrival_distance = 15

	local bubble = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
	ability:ApplyDataDrivenModifier(caster, bubble, "modifier_bubble_dragon_dummy", {})

	local particle = ParticleManager:CreateParticle("particles/nitori/bubble_dragon.vpcf", PATTACH_ABSORIGIN_FOLLOW, bubble)

	local bubble_location = bubble:GetAbsOrigin()
	local direction = (target_point - bubble_location):Normalized()
	local bubbled_units = {}
	local elapsed_duration = 0

	Timers:CreateTimer(0, function()
		bubble_location = bubble:GetAbsOrigin()
		if elapsed_duration < duration then
			-- Move bubble & caught units
			local distance = (target_point - bubble_location):Length2D()
			if distance > arrival_distance then
				bubble:SetAbsOrigin(bubble_location + direction * speed)
				for unit,v in pairs(bubbled_units) do
					unit:SetAbsOrigin(unit:GetAbsOrigin() + direction * speed)
				end
			end

			-- Check for units hit
			local team = caster:GetTeamNumber()
			local origin = bubble:GetAbsOrigin()
			local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
			local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
			local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
			local iOrder = FIND_ANY_ORDER
			-- DebugDrawCircle(origin, Vector(40,40,180), 1, radius, true, 0.5)

			local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

			for k,unit in pairs(targets) do
				if not bubbled_units[unit] then
					bubbled_units[unit] = true
					ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
					ability:ApplyDataDrivenModifier(caster, unit, "modifier_bubble_dragon_stun", {})
					ability:ApplyDataDrivenModifier(caster, unit, "modifier_bubble_dragon_bubbled", {})
				end
			end

			elapsed_duration = elapsed_duration + update_interval

			return update_interval
		else
			bubble:RemoveSelf()
			ParticleManager:DestroyParticle(particle, true)

			for unit,v in pairs(bubbled_units) do
				FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), false)
				unit:RemoveModifierByName("modifier_bubble_dragon_bubbled")
			end
		end
	end)

	Timers:CreateTimer(damage_interval, function()
		if elapsed_duration < duration then
			for unit,v in pairs(bubbled_units) do
				ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
			end
			return damage_interval
		end
	end)
end