function spellUpgraded(keys)
	local ability = keys.ability

	if ability:GetLevel() == 1 then caster.elekiter_charges = ability:GetSpecialValueFor("max_charges") end
end

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability

	caster.elekiter_charges = caster.elekiter_charges - 1
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_elekiter_dragon_palace_active", {})
end

function updateCharges(keys)
	local caster = keys.caster
	local ability = keys.ability
	local max_charges = ability:GetSpecialValueFor("max_charges")
	local charge_restore_time = ability:GetSpecialValueFor("charge_restore_time")
	local update_interval = ability:GetSpecialValueFor("update_interval")

	if not caster.elekiter_charges then caster.elekiter_charges = 0 end
	local remaining_time_for_charge = (1 - caster.elekiter_charges % 1) * charge_restore_time

	if caster.elekiter_charges < max_charges then
		caster.elekiter_charges = caster.elekiter_charges + update_interval / charge_restore_time
	else
		caster.elekiter_charges = max_charges
	end

	if caster.elekiter_charges >= 1 then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_elekiter_dragon_palace_charges", {})
		local old_stack_count = caster:GetModifierStackCount("modifier_elekiter_dragon_palace_charges", caster)
		local new_stack_count = math.floor(caster.elekiter_charges)
		caster:SetModifierStackCount("modifier_elekiter_dragon_palace_charges", caster, new_stack_count)
		if new_stack_count ~= old_stack_count and new_stack_count ~= max_charges and caster:IsAlive() then
			caster:FindModifierByName("modifier_elekiter_dragon_palace_charges"):SetDuration(remaining_time_for_charge, true)
		end
	else
		caster:RemoveModifierByName("modifier_elekiter_dragon_palace_charges")
	end

	if caster.elekiter_charges >= 1 and not caster:HasModifier("modifier_elekiter_dragon_palace_active") then
		ability:SetActivated(true)
	else
		ability:SetActivated(false)
	end
end