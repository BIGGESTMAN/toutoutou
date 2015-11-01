require "personas"

function SpellCast(keys)
	local caster = keys.caster
	local ability = CreateDummyAbility(caster, keys.ability)
	local target = keys.target

	local damage = caster.activePersona.attributes["mag"] * ability:GetSpecialValueFor("magic_multiplier")
	local damage_type = DAMAGE_TYPE_MAGICAL

	-- ApplyDamage({victim = target, attacker = caster, damage = damage, damage_type = damage_type})
	ApplyCustomDamage(target, caster, damage, damage_type, "ice")

	local particle = ParticleManager:CreateParticle("particles/spells/magic_bufu.vpcf", PATTACH_ABSORIGIN, target)
end