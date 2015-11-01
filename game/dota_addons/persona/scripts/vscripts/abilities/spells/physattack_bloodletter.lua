require "personas"

function SpellCast(keys)
	local caster = keys.caster
	local ability = CreateDummyAbility(caster, keys.ability)
	local target = keys.target

	local damage = caster:GetAverageTrueAttackDamage() * ability:GetSpecialValueFor("damage_percent") / 100
	local damage_type = DAMAGE_TYPE_PHYSICAL
	local persona_damage_type = "physical"
	ApplyCustomDamage(target, caster, damage, damage_type, persona_damage_type)

	local self_damage = caster:GetMaxHealth() * ability:GetSpecialValueFor("health_cost_percent") / 100
	caster:SetHealth(caster:GetHealth() - self_damage)

	ability:ApplyDataDrivenModifier(caster, target, "modifier_bloodletter_bleed", {})
	local modifier = target:FindModifierByName("modifier_bloodletter_bleed")
	modifier.bleed_ticks = 0
	modifier.bleed_damage = caster:GetAverageTrueAttackDamage() * ability:GetSpecialValueFor("bleed_damage_percent") / 100
	modifier.damage_interval = ability:GetSpecialValueFor("damage_interval")
end

function BleedUpdate(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local modifier = target:FindModifierByName("modifier_bloodletter_bleed")

	local elapsed_time = modifier:GetElapsedTime()
	if elapsed_time >= (modifier.bleed_ticks + 1) * modifier.damage_interval then
		modifier.bleed_ticks = modifier.bleed_ticks + 1
		print(modifier.bleed_damage)
		local damage = modifier.bleed_damage
		local damage_type = DAMAGE_TYPE_PHYSICAL
		local persona_damage_type = "physical"
		ApplyCustomDamage(target, caster, damage, damage_type, persona_damage_type)
	end

	AddFOWViewer(caster:GetTeamNumber(), target:GetAbsOrigin(), ability:GetSpecialValueFor("vision_radius"), ability:GetSpecialValueFor("update_interval"), true)
end