function SpellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local damage = caster:GetAverageTrueAttackDamage() * ability:GetSpecialValueFor("damage_percent") / 100
	local damage_type = DAMAGE_TYPE_PHYSICAL
	local persona_damage_type = "physical"
	ApplyCustomDamage(target, caster, damage, damage_type, persona_damage_type)

	local self_damage = caster:GetMaxHealth() * ability:GetSpecialValueFor("health_cost_percent") / 100
	caster:SetHealth(caster:GetHealth() - self_damage)

	ability:ApplyDataDrivenModifier(caster, target, "modifier_hammer_blow_stun", {})
	ability:ApplyDataDrivenModifier(caster, target, "modifier_hammer_blow_slow", {})

	local particle = ParticleManager:CreateParticle("particles/spells/physattack_hammer_blow.vpcf", PATTACH_ABSORIGIN, target)
end