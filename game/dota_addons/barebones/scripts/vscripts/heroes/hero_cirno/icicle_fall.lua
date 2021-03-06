function icicleFallCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target = keys.target
	local target_point = target:GetAbsOrigin()

	local dummy = CreateUnitByName("npc_dummy_unit", target_point, false, caster, caster, caster:GetTeamNumber())
	ability:ApplyDataDrivenModifier(caster, dummy, "modifier_icicle_fall_dummy", {})
	dummy.units_hit = {}

	local particle = ParticleManager:CreateParticle("particles/cirno/icicle_fall.vpcf", PATTACH_ABSORIGIN, dummy)
end

function tick(keys)
	local dummy = keys.target
	local target_point = dummy:GetAbsOrigin()
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local center_radius = ability:GetLevelSpecialValueFor("center_radius", ability_level)
	local damage = ability:GetLevelSpecialValueFor("damage_per_second", ability_level) * 0.03
	local damage_type = ability:GetAbilityDamageType()

	local team = caster:GetTeamNumber()
	local origin = target_point
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER

	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

	for k,unit in pairs(targets) do
		if (unit:GetAbsOrigin() - target_point):Length2D() > center_radius then
			ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
			ability:ApplyDataDrivenModifier(caster, unit, "modifier_icicle_fall_slow", {})
			if not dummy.units_hit[unit] then
				local cold_divinity_ability = caster:FindAbilityByName("cold_divinity")
				if cold_divinity_ability:GetLevel() > 0 then
					cold_divinity_ability:ApplyDataDrivenModifier(caster, unit, "modifier_cold_divinity_chilled", {})
					local modifier = unit:FindModifierByName("modifier_cold_divinity_chilled")
					if modifier:GetStackCount() < cold_divinity_ability:GetLevelSpecialValueFor("max_stacks", cold_divinity_ability:GetLevel() - 1) then
						modifier:IncrementStackCount()
					end
					dummy.units_hit[unit] = true
				end
			end
		end
	end
end

function removeDummy(keys)
	keys.target:RemoveSelf()
end