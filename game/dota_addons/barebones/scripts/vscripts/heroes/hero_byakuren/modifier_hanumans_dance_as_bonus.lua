modifier_hanumans_dance_as_bonus = class({})

function modifier_hanumans_dance_as_bonus:IsHidden()
	return true
end

function modifier_hanumans_dance_as_bonus:DeclareFunctions()
	return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT  }
end

function modifier_hanumans_dance_as_bonus:GetModifierAttackSpeedBonus_Constant()
	-- if IsServer() then
		return self:GetAbility():GetSpecialValueFor("superhuman_attackspeed_bonus")
	-- end
end