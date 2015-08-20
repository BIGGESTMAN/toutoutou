function modifierCreated(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target = keys.target

	local damage = ability:GetLevelSpecialValueFor("damage", ability_level)

	if target:HasModifier("modifier_cold_divinity_chilled") then
		local damage_threshold = ability:GetLevelSpecialValueFor("damage_threshold", ability_level)

		local modifier = target:FindModifierByName("modifier_perfect_freeze")
		modifier.damage_absorbed = 0
		modifier.damage_left = damage
		modifier:SetStackCount(damage_threshold)
	else
		target:RemoveModifierByName("modifier_perfect_freeze")
		ApplyDamage({victim = target, attacker = caster, damage = damage, damage_type = ability:GetAbilityDamageType()})
	end
end

function dealDamage(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target = keys.target

	local damage = ability:GetLevelSpecialValueFor("damage", ability_level) * ability:GetLevelSpecialValueFor("damage_interval", ability_level) / ability:GetLevelSpecialValueFor("duration", ability_level)
	local damage_type = ability:GetAbilityDamageType()

	local modifier = target:FindModifierByName("modifier_perfect_freeze")
	modifier.damage_left = modifier.damage_left - damage
	ApplyDamage({victim = target, attacker = caster, damage = damage, damage_type = damage_type})
end

function damageTaken(keys)
	local damage = keys.damage_taken
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target = keys.unit

	local modifier = target:FindModifierByName("modifier_perfect_freeze")

	local damage_threshold = ability:GetLevelSpecialValueFor("damage_threshold", ability_level)
	local damage_type = ability:GetAbilityDamageType()
	local damage_left = modifier.damage_left

	modifier.damage_absorbed = modifier.damage_absorbed + damage
	if modifier.damage_absorbed > damage_threshold then
		target:RemoveModifierByName("modifier_perfect_freeze")
		ApplyDamage({victim = target, attacker = caster, damage = damage_left, damage_type = damage_type})
	else
		modifier:SetStackCount(damage_threshold - modifier.damage_absorbed)
	end
end