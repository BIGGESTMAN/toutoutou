modifier_vajrapanis_charges_tracker = class({})

if IsServer() then
	function modifier_vajrapanis_charges_tracker:OnCreated(kv)
		self:GetCaster().vajrapanis_charges = 0
		self:SetDuration(self:GetAbility():GetSpecialValueFor("charge_generation_time"), true)
		self:StartIntervalThink(0.03)
	end

	function modifier_vajrapanis_charges_tracker:OnIntervalThink()
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		local max_charges = ability:GetSpecialValueFor("max_charges")
		local charge_restore_time = ability:GetSpecialValueFor("charge_generation_time")
		local update_interval = 0.03

		local remaining_time_for_charge = (1 - caster.vajrapanis_charges % 1) * charge_restore_time

		if caster.vajrapanis_charges < max_charges then
			caster.vajrapanis_charges = caster.vajrapanis_charges + update_interval / charge_restore_time
		else
			caster.vajrapanis_charges = max_charges
		end

		if caster.vajrapanis_charges >= 1 then
			caster:AddNewModifier(caster, ability, "modifier_vajrapanis_charges", {})
			local old_stack_count = caster:GetModifierStackCount("modifier_vajrapanis_charges", caster)
			local new_stack_count = math.floor(caster.vajrapanis_charges)
			caster:SetModifierStackCount("modifier_vajrapanis_charges", caster, new_stack_count)
			if new_stack_count ~= old_stack_count and new_stack_count ~= max_charges and caster:IsAlive() then
				self:SetDuration(remaining_time_for_charge, true)
			end
			setChargeAbilitiesActivated(caster, true)
		else
			caster:RemoveModifierByName("modifier_vajrapanis_charges")
			setChargeAbilitiesActivated(caster, false)
		end
	end

	function modifier_vajrapanis_charges_tracker:DestroyOnExpire()
		return false
	end

	function setChargeAbilitiesActivated(caster, enabled)
		caster:FindAbilityByName("hanumans_dance"):SetActivated(enabled)
		caster:FindAbilityByName("indras_thunder"):SetActivated(enabled)
		caster:FindAbilityByName("durgas_soul"):SetActivated(enabled)
		caster:FindAbilityByName("virudhakas_sword"):SetActivated(enabled)
	end
end