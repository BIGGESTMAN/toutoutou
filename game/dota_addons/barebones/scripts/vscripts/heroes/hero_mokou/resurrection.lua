function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability

	caster.resurrection_old_model = caster:GetModelName()
	caster:SetModel("models/heroes/phoenix/phoenix_egg.vmdl")

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_resurrection", {})
end

function healthDrainTick(keys)
	local caster = keys.caster
	local ability = keys.ability

	local health_drain_interval = ability:GetSpecialValueFor("health_drain_interval")
	local health_drain = ability:GetSpecialValueFor("health_drain_per_second") * health_drain_interval

	local health_threshold = ability:GetSpecialValueFor("health_threshold")
	local health = caster:GetHealth()
	if health <= health_threshold then
		local buff_linger_duration = ability:GetSpecialValueFor("disable_duration")

		caster:Heal(caster:GetHealthDeficit(), caster)
		caster:RemoveModifierByName("modifier_resurrection")
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_resurrection_lingering", {})

		caster:SetModel(caster.resurrection_old_model)
		caster.resurrection_old_model = nil
	else
		caster:SetHealth(health - health_drain)
	end
end