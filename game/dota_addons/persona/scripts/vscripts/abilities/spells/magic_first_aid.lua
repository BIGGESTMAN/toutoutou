require "personas"

function SpellCast(keys)
	local caster = keys.caster
	local ability = CreateDummyAbility(caster, keys.ability)
	local target = keys.target

	local mag = caster.activePersona.attributes["mag"]
	local healing = ability:GetSpecialValueFor("heal") + mag * ability:GetSpecialValueFor("heal_magic_multiplier")
	if target:HasModifier("modifier_first_aid_damage_taken") then
		print("?")
		healing = healing + ability:GetSpecialValueFor("bonus_heal") + mag * ability:GetSpecialValueFor("bonus_heal_magic_multiplier")
	end
	target:Heal(healing, caster)
end