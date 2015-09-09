modifier_flash_flood_debuff = class({})

function modifier_flash_flood_debuff:IsDebuff()
	return true
end

function modifier_flash_flood_debuff:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS }
end

function modifier_flash_flood_debuff:GetModifierMagicalResistanceBonus(params)
	local dummy = self:GetCaster()
	local base_damage_amp = self:GetAbility():GetSpecialValueFor("damage_amp")
	local bonus_damage_amp = self:GetAbility():GetSpecialValueFor("damage_amp_increase")
	local damage_amp = base_damage_amp
	if dummy.elapsed_duration then -- sometimes this bugs out and is nil? really no clue why
		damage_amp = damage_amp + bonus_damage_amp * dummy.elapsed_duration
	end
	print(dummy.elapsed_duration)
	local damage_taken = (100 - self:GetParent():GetBaseMagicalResistanceValue()) * (1 + damage_amp / 100)
	print(damage_taken)
	return 100 - damage_taken
end