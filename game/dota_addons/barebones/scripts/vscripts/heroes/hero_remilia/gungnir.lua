LinkLuaModifier("modifier_gungnir_armor_reduction", "heroes/hero_remilia/modifier_gungnir_armor_reduction.lua", LUA_MODIFIER_MOTION_NONE )

require "libraries/util"

function gungnirCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_gungnir", {})

	-- Enable spear throw ability
	local main_ability_name	= ability:GetAbilityName()
	local sub_ability_name	= "gungnir_throw"
	caster:SwapAbilities(main_ability_name, sub_ability_name, false, true)
end

function gungnirHit(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target = keys.target

	local range = ability:GetLevelSpecialValueFor("penetrate_range", ability_level)
	local radius = ability:GetLevelSpecialValueFor("penetrate_radius", ability_level)

	local thinker_modifier = "modifier_gungnir_dummy"
	local direction = caster:GetForwardVector()

	local targets = unitsInLine(caster, ability, thinker_modifier, caster:GetAbsOrigin(), range, radius, direction, false, true, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)
	local damage = keys.damage

	local targets_hit = 0
	for k,unit in pairs(targets) do
		if unit ~= target then
			targets_hit = targets_hit + 1
			ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = DAMAGE_TYPE_PHYSICAL})
			if caster:HasModifier("modifier_queen_of_midnight_swooping") then
				caster:FindAbilityByName("queen_of_midnight"):ApplyDataDrivenModifier(caster, unit, "modifier_queen_of_midnight_stun", {})
			end
		end
	end

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_gungnir_hits", {})
	local modifier = caster:FindModifierByName("modifier_gungnir_hits")
	modifier:SetStackCount(modifier:GetStackCount() + 1 + targets_hit)

	local particle_name = "particles/remilia/spear_pierce_a0.vpcf"
	local vertical_offset = Vector(0,0,100)
	local particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin() + vertical_offset)
	ParticleManager:SetParticleControl(particle, 2, (range + radius) * caster:GetForwardVector() + caster:GetAbsOrigin() + vertical_offset)
	ParticleManager:SetParticleControl(particle, 3, (range + radius) * caster:GetForwardVector() + caster:GetAbsOrigin() + vertical_offset)
	ParticleManager:SetParticleControl(particle, 4, (range + radius) * caster:GetForwardVector() + caster:GetAbsOrigin() + vertical_offset)
	ParticleManager:SetParticleControl(particle, 5, (range + radius) * caster:GetForwardVector() + caster:GetAbsOrigin() + vertical_offset)
end

function throw(keys)
	local caster = keys.caster
	local ability = caster:FindAbilityByName("gungnir")
	local ability_level = ability:GetLevel() - 1
	local direction = (keys.target_points[1] - caster:GetAbsOrigin()):Normalized()

	local hits = caster:GetModifierStackCount("modifier_gungnir_hits", caster)
	local base_range = ability:GetLevelSpecialValueFor("throw_base_range", ability_level)
	local range = base_range + ability:GetLevelSpecialValueFor("throw_bonus_range", ability_level) * hits
	local radius = ability:GetLevelSpecialValueFor("throw_radius", ability_level)
	local speed = range / ability:GetLevelSpecialValueFor("travel_time", ability_level)
	local damage = ability:GetLevelSpecialValueFor("damage", ability_level)
	local dummy_speed = speed * 0.03

	local dummy_unit = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeam())
	ability:ApplyDataDrivenModifier(caster, dummy_unit, "modifier_gungnir_dummy", {})
	
	local distance_traveled = 0
	dummy_unit.units_hit = {}

	local vertical_offset = Vector(0,0,100)
	dummy_unit:SetAbsOrigin(dummy_unit:GetAbsOrigin() + vertical_offset)


	dummy_endcap = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeam())
	ability:ApplyDataDrivenModifier(caster, dummy_endcap, "modifier_gungnir_dummy", {})
	local endcap_offset = direction * ability:GetLevelSpecialValueFor("penetrate_range", ability_level)

	local particle = ParticleManager:CreateParticle("particles/remilia/spear_throw.vpcf", PATTACH_POINT_FOLLOW, dummy_unit)
	ParticleManager:SetParticleControlEnt(particle, 1, dummy_unit, PATTACH_POINT_FOLLOW, "attach_hitloc", dummy_unit:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(particle, 2, dummy_endcap, PATTACH_POINT_FOLLOW, "attach_hitloc", dummy_endcap:GetAbsOrigin(), true)

	Timers:CreateTimer(0, function()
		dummy_location = dummy_unit:GetAbsOrigin()
		if distance_traveled < range then
			-- Move projectile
			dummy_unit:SetAbsOrigin(dummy_location + direction * dummy_speed)
			dummy_endcap:SetAbsOrigin(dummy_unit:GetAbsOrigin() + endcap_offset)
			distance_traveled = distance_traveled + dummy_speed

			-- Check for units hit
			local team = caster:GetTeamNumber()
			local origin = dummy_location - vertical_offset
			local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
			local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
			local iFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
			local iOrder = FIND_ANY_ORDER

			local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
			local damage_type = ability:GetAbilityDamageType()

			for k,unit in pairs(targets) do
				if not dummy_unit.units_hit[unit] then
					unit:AddNewModifier(caster, ability, "modifier_gungnir_armor_reduction", {duration = ability:GetLevelSpecialValueFor("armor_reduction_duration", ability_level)})
					unit:SetModifierStackCount("modifier_gungnir_armor_reduction", caster, hits + 1)

					ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
					dummy_unit.units_hit[unit] = true
				end
			end
			return 0.03
		else
			ParticleManager:DestroyParticle(particle, false)
			dummy_unit:RemoveSelf()
			dummy_endcap:RemoveSelf()
		end
	end)

	caster:RemoveModifierByName("modifier_gungnir")
end

function durationExpired(keys)
	if not keys.caster:FindAbilityByName("gungnir_throw"):IsInAbilityPhase() then
		endGungnir(keys.caster)
	end
end

function endGungnir(caster)
	-- Disable throw ability
	local main_ability_name	= "gungnir"
	local sub_ability_name	= "gungnir_throw"
	caster:SwapAbilities(main_ability_name, sub_ability_name, true, false)

	caster:RemoveModifierByName("modifier_gungnir_hits")

	local ability = caster:FindAbilityByName(main_ability_name)
	local ability_level = ability:GetLevel() - 1
	ability:EndCooldown()
	ability:StartCooldown(ability:GetCooldown(ability_level))
end