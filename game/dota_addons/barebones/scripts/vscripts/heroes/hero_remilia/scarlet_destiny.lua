function updateCharges(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local max_charges = ability:GetLevelSpecialValueFor("max_charges", ability_level)
	local charge_restore_time = ability:GetLevelSpecialValueFor("recharge_time", ability_level)
	local charges_modifier = "modifier_scarlet_charges"

	if not caster.scarlet_charges then caster.scarlet_charges = 0 end
	local remaining_time_for_charge = (1 - caster.scarlet_charges % 1) * charge_restore_time

	if caster.scarlet_charges < max_charges then
		caster.scarlet_charges = caster.scarlet_charges + ability:GetLevelSpecialValueFor("update_interval", ability_level) / charge_restore_time
	else
		caster.scarlet_charges = max_charges
	end

	if caster.scarlet_charges >= 1 then
		if ability.toggled_on then
			ability:ToggleAbility()
			ability.toggled_on = false
		end
		ability:ApplyDataDrivenModifier(caster, caster, charges_modifier, {})
		local old_stack_count = caster:GetModifierStackCount(charges_modifier, caster)
		local new_stack_count = math.floor(caster.scarlet_charges)
		caster:SetModifierStackCount(charges_modifier, caster, new_stack_count)
		if new_stack_count ~= old_stack_count and new_stack_count ~= max_charges and caster:IsAlive() then
			caster:FindModifierByName(charges_modifier):SetDuration(remaining_time_for_charge, true)
		end
	else
		caster:RemoveModifierByName(charges_modifier)
		if ability:IsCooldownReady() then
			ability:StartCooldown(remaining_time_for_charge)
			ability.toggled_on = true
		end
	end
end

function checkRestoreCharges(keys)
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	if ability_level == 0 then caster.scarlet_charges = ability:GetLevelSpecialValueFor("starting_charges", ability_level) end
end

function spendCharge(caster)
	caster.scarlet_charges = caster.scarlet_charges - 1
	if caster.scarlet_charges < 1 then
		caster:FindAbilityByName("scarlet_destiny"):ToggleAbility()
	end
end

function crit(keys)
	local caster = keys.caster
	local target = keys.target

	local particle_forward = caster:GetForwardVector() * -1
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin())
	ParticleManager:SetParticleControlForward(particle, 0, particle_forward)
	ParticleManager:SetParticleControlForward(particle, 1, particle_forward)

	spendCharge(caster)
end

function damageTaken(keys)
	local damage = keys.damage_taken
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	if damage / caster.old_health > ability:GetLevelSpecialValueFor("health_threshold", ability_level) / 100 then
		caster:SetHealth(caster.old_health)
		spendCharge(caster)
		ParticleManager:CreateParticle("particles/remilia/scarlet_destiny_deflect.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	end
end

function updateHealth(keys)
	keys.target.old_health = keys.target:GetHealth()
end