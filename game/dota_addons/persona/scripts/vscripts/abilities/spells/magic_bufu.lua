function SpellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local damage = caster.activePersona.attributes["mag"] * ability:GetSpecialValueFor("magic_multiplier")
	local damage_type = DAMAGE_TYPE_MAGICAL

	ApplyDamage({victim = target, attacker = caster, damage = damage, damage_type = damage_type})
end