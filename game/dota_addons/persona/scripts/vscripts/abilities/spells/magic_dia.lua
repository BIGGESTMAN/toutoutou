require "personas"

function SpellCast(keys)
	local caster = keys.caster
	local ability = CreateDummyAbility(caster, keys.ability)
	local target = keys.target

	local healing = caster.activePersona.attributes["mag"] * ability:GetSpecialValueFor("magic_multiplier")
	target:Heal(healing, caster)
end