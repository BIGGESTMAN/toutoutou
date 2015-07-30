function throwAnchor(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local speed = ability:GetLevelSpecialValueFor("speed", ability_level)
	local range = ability:GetLevelSpecialValueFor("range", ability_level)

	local dummy_unit = CreateUnitByName("anchor", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeam())
	ability:ApplyDataDrivenModifier(caster, dummy_unit, keys.anchor_modifier, {})

	local target_point = keys.target_points[1]
	local dummy_location = dummy_unit:GetAbsOrigin()
	local direction = (target_point - dummy_location):Normalized()

	local dummy_speed = speed * 0.03
	local arrival_distance = 25
	local height_offset = Vector(0,0,50)

	dummy_unit:SetForwardVector(direction)
	dummy_unit:SetAbsOrigin(dummy_unit:GetAbsOrigin() + height_offset)
	dummy_unit.units_hit = {}

	Timers:CreateTimer(0, function()
		dummy_location = dummy_unit:GetAbsOrigin()
		local distance = (target_point - dummy_location):Length2D()
		if distance > arrival_distance then
			-- Move projectile
			dummy_unit:SetAbsOrigin(dummy_location + direction * dummy_speed)

			-- Check for units hit
			local team = caster:GetTeamNumber()
			local origin = dummy_location
			local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
			local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
			local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
			local iOrder = FIND_ANY_ORDER
			local radius = ability:GetLevelSpecialValueFor("drag_radius", ability_level)

			local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
			local damage = ability:GetLevelSpecialValueFor("drag_damage", ability_level)
			local damage_type = ability:GetAbilityDamageType()

			for k,unit in pairs(targets) do
				if not unit:HasModifier(keys.drag_modifier) then
					ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
					ability:ApplyDataDrivenModifier(dummy_unit, unit, keys.drag_modifier, {})
					dummy_unit.units_hit[unit] = true
				end
			end
			return 0.03
		else
			dummy_unit:SetAbsOrigin(target_point + height_offset)
			dummy_unit:SetForwardVector((dummy_unit:GetForwardVector() + Vector(0,0,-1)):Normalized()) -- Goofy shit to make anchor look stuck in the ground
			for unit,v in pairs(dummy_unit.units_hit) do
				unit:RemoveModifierByName(keys.drag_modifier)
			end
		end
	end)
end