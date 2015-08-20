function chillAura(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local team = caster:GetTeamNumber()
	local origin = caster:GetAbsOrigin()
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER

	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

	for k,unit in pairs(targets) do
		if not unit:HasModifier("modifier_cold_divinity_chilling") then
			ability:ApplyDataDrivenModifier(caster, unit, "modifier_cold_divinity_chilling", {})
		end
	end
end

function applyChill(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target = keys.attacker

	if not target:IsTower() and not target:IsMagicImmune() then
		ability:ApplyDataDrivenModifier(caster, target, "modifier_cold_divinity_chilled", {})
		local modifier = target:FindModifierByName("modifier_cold_divinity_chilled")
		if modifier and modifier:GetStackCount() < ability:GetLevelSpecialValueFor("max_stacks", ability_level) then -- check if they have modifier because they might be spell immune/invulnerable and thus not have it applied
			modifier:IncrementStackCount()
		end
	end
end

function applyTickingChill(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target = keys.target

	local distance = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()
	if distance <= ability:GetLevelSpecialValueFor("radius", ability_level) then
		ability:ApplyDataDrivenModifier(caster, target, "modifier_cold_divinity_chilled", {})
		local modifier = target:FindModifierByName("modifier_cold_divinity_chilled")
		if modifier:GetStackCount() < ability:GetLevelSpecialValueFor("max_stacks", ability_level) then
			modifier:IncrementStackCount()
		end
	end
end

function checkRemoveChilling(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target = keys.target

	local distance = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()
	if distance > ability:GetLevelSpecialValueFor("radius", ability_level) then
		target:RemoveModifierByName("modifier_cold_divinity_chilling")
	end
end

function shatterPerfectFreeze(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = caster:FindAbilityByName("perfect_freeze")
	local modifier = target:FindModifierByName("modifier_perfect_freeze")
	if modifier then
		local damage_type = ability:GetAbilityDamageType()
		local damage_left = modifier.damage_left

		target:RemoveModifierByName("modifier_perfect_freeze")
		ApplyDamage({victim = target, attacker = caster, damage = damage_left, damage_type = damage_type})
	end
end