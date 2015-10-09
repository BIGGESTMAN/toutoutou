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

	local sleep = not target.activePersona and not target:IsAncient()
	if target.activePersona and target.activePersona.attributes["endr"] <= caster.activePersona.attributes["endr"] then sleep = true end
	if sleep then ability:ApplyDataDrivenModifier(caster, target, "modifier_night_fright_sleep", {}) end
end

function OnAttacked(keys)
	local elapsed_time = keys.target:FindModifierByName("modifier_night_fright_sleep"):GetElapsedTime()
	if elapsed_time > keys.ability:GetSpecialValueFor("min_sleep_duration") then
		keys.target:RemoveModifierByName("modifier_night_fright_sleep")
	end
end