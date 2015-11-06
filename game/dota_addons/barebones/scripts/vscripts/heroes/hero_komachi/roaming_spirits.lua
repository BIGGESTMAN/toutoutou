function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local damage = ability:GetSpecialValueFor("damage")
	local damage_type = ability:GetAbilityDamageType()
	local bonus_damage_percent_per_spirit = ability:GetSpecialValueFor("bonus_damage_percent")
	local healing = ability:GetSpecialValueFor("healing")
	local flame_count = ability:GetSpecialValueFor("flame_count")
	local bonus_flames_per_spirit = ability:GetSpecialValueFor("bonus_flames")
	local flame_duration = ability:GetSpecialValueFor("duration")
	local flame_spill_area_radius = ability:GetSpecialValueFor("flame_area_radius")
	local flame_spill_time = ability:GetSpecialValueFor("flame_spill_time")
	local flame_pickup_radius = ability:GetSpecialValueFor("flame_radius")
	local update_interval = ability:GetSpecialValueFor("update_interval")
end