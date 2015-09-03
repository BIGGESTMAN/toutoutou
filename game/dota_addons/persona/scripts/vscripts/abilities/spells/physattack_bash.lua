function SpellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local damage = caster:GetAverageTrueAttackDamage() * ability:GetSpecialValueFor("damage_percent") / 1
	local damage_type = DAMAGE_TYPE_PHYSICAL

	local self_damage = caster:GetMaxHealth() * ability:GetSpecialValueFor("health_cost_percent") / 100
	local self_damage_type = DAMAGE_TYPE_PURE

	ApplyDamage({victim = target, attacker = caster, damage = damage, damage_type = damage_type})
	ApplyDamage({victim = caster, attacker = caster, damage = self_damage, damage_type = self_damage_type})
end