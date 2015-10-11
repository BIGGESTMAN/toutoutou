function SpellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local mag = caster.activePersona.attributes["mag"]
	local base_damage = ability:GetSpecialValueFor("damage")
	local magic_multiplier = ability:GetSpecialValueFor("damage_magic_multiplier")
	local damage = base_damage + magic_multiplier * mag

	local bonus_damage = ability:GetSpecialValueFor("bonus_damage")
	local bonus_damage_magic_multiplier = ability:GetSpecialValueFor("bonus_damage_magic_multiplier")
	local bonus_damage = bonus_damage + bonus_damage_magic_multiplier * mag
	local health_percent = caster:GetHealthPercent()
	if health_percent >= ability:GetSpecialValueFor("bonus_damage_hp_percent") then
		damage = damage + bonus_damage
	end
	
	local damage_type = DAMAGE_TYPE_PHYSICAL
	local persona_damage_type = "thunder"

	ApplyCustomDamage(target, caster, damage, damage_type, persona_damage_type)
end