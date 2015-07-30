LinkLuaModifier("modifier_sea_split_hit", "heroes/hero_sanae/modifier_sea_split_hit.lua", LUA_MODIFIER_MOTION_NONE )

function seaSplitStart(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local speed = ability:GetLevelSpecialValueFor("speed", ability_level)
	local range = ability:GetLevelSpecialValueFor("range", ability_level)

	local dummy_unit = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeam())
	ability:ApplyDataDrivenModifier(caster, dummy_unit, keys.dummy_modifier, {})
	-- dummy_unit:SetAbsOrigin(caster:GetAbsOrigin())

	local target_point = keys.target_points[1]
	local dummy_location = dummy_unit:GetAbsOrigin()
	local direction = (target_point - dummy_location):Normalized()

	local particle = ParticleManager:CreateParticle(keys.particle_name, PATTACH_ABSORIGIN_FOLLOW, dummy_unit)
	ParticleManager:SetParticleControl(particle, 1, speed * direction)

	local dummy_speed = speed * 0.03
	local distance_traveled = 0

	dummy_unit.units_hit = {}

	Timers:CreateTimer(0, function()
		dummy_location = dummy_unit:GetAbsOrigin()
		if distance_traveled < range then
			-- Move projectile
			dummy_unit:SetAbsOrigin(dummy_location + direction * dummy_speed)
			distance_traveled = distance_traveled + dummy_speed

			-- Check for units hit
			local team = caster:GetTeamNumber()
			local origin = dummy_location
			local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
			local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
			local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
			local iOrder = FIND_ANY_ORDER
			local radius = ability:GetLevelSpecialValueFor("radius", ability_level)

			local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
			local damage = ability:GetLevelSpecialValueFor("damage", ability_level)
			local damage_type = ability:GetAbilityDamageType()

			for k,unit in pairs(targets) do
				if not dummy_unit.units_hit[unit] then
					ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
					dummy_unit.units_hit[unit] = true

					local left_vector = RotatePosition(Vector(0,0,0), QAngle(0,-90,0), direction)
					local right_vector = RotatePosition(Vector(0,0,0), QAngle(0,90,0), direction)
					local distance_to_left = (unit:GetAbsOrigin() - (dummy_location + left_vector)):Length2D()
					local distance_to_right = (unit:GetAbsOrigin() - (dummy_location + right_vector)):Length2D()

					local knockback_direction = left_vector
					if distance_to_right < distance_to_left then knockback_direction = right_vector end
					-- Holy fuck I hate everyone
					local knockback_x = knockback_direction.x
					local knockback_y = knockback_direction.y
					local knockback_z = knockback_direction.z
					unit:AddNewModifier(caster, ability, "modifier_sea_split_hit", {x = knockback_x, y = knockback_y, z = knockback_z, knockback_direction = knockback_direction})
				end
			end
			return 0.03
		else
			dummy_unit:RemoveSelf()
		end
	end)
end