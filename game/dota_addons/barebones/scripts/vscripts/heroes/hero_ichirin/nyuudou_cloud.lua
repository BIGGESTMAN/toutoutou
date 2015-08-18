function attackLanded(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	if ability:IsCooldownReady() then
		punch(caster, ability, caster:GetForwardVector())

		-- Check for traditional era active
		if caster:HasModifier("modifier_traditional_era") then
			local traditional_era_ability = caster:FindAbilityByName("traditional_era")
			local traditional_era_level = traditional_era_ability:GetLevel() - 1
			local punch_delay = traditional_era_ability:GetLevelSpecialValueFor("nyuudou_attack_delay", traditional_era_level)
			Timers:CreateTimer(punch_delay, function()
				punch(caster, ability, caster:GetForwardVector())
			end)
		end

		-- Check for autumn storm clouds active
		if not caster:HasModifier("modifier_storm_clouds_active") then
			ability:StartCooldown(ability:GetCooldown(ability_level))
		end
	end
end

function punch(caster, ability, direction)
	local ability_level = ability:GetLevel() - 1

	local range = ability:GetLevelSpecialValueFor("range", ability_level)
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local speed = (range / ability:GetLevelSpecialValueFor("travel_time", ability_level)) * ability:GetLevelSpecialValueFor("update_interval", ability_level)

	local damage = ability:GetLevelSpecialValueFor("damage", ability_level)
	local damage_type = ability:GetAbilityDamageType()

	local direction = caster:GetForwardVector()

	ability.offhand_punch = not ability.offhand_punch
	local offset = 100 * direction
	if ability.offhand_punch then
		offset = RotatePosition(Vector(0,0,0), QAngle(0,-90,0), offset)
	else
		offset = RotatePosition(Vector(0,0,0), QAngle(0,90,0), offset)
	end
	local punch_origin = caster:GetAbsOrigin() + offset
	local particle_start_offset = direction * -400

	local thinker_modifier = "modifier_nyuudou_cloud_dummy"
	local dummy_unit = CreateUnitByName("npc_dummy_unit", punch_origin, false, caster, caster, caster:GetTeam())
	ability:ApplyDataDrivenModifier(caster, dummy_unit, thinker_modifier, {})
	
	local distance_traveled = 0
	dummy_unit.units_hit = {}

	local particle = ParticleManager:CreateParticle("particles/ichirin/nyuudou_cloud.vpcf", PATTACH_POINT, caster)
	ParticleManager:SetParticleControl(particle, 0, punch_origin + particle_start_offset)
	ParticleManager:SetParticleControl(particle, 1, direction + punch_origin + particle_start_offset)

	Timers:CreateTimer(0, function()
		dummy_location = dummy_unit:GetAbsOrigin()
		if distance_traveled < range then
			-- Move projectile
			dummy_unit:SetAbsOrigin(dummy_location + direction * speed)
			distance_traveled = distance_traveled + speed

			-- Check for units hit
			local team = caster:GetTeamNumber()
			local origin = dummy_location
			local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
			local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
			local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
			local iOrder = FIND_ANY_ORDER

			local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
			-- DebugDrawCircle(origin, Vector(255,100,100), 1, radius, true, 0.5)

			for k,unit in pairs(targets) do
				if not dummy_unit.units_hit[unit] then
					ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
					dummy_unit.units_hit[unit] = true
				end
			end
			return 0.03
		else
			-- ParticleManager:DestroyParticle(particle, false)
			dummy_unit:RemoveSelf()
		end
	end)
end