modifier_persona_attackspeed_bonus = class({})

function modifier_persona_attackspeed_bonus:IsHidden()
	return true
end

function modifier_persona_attackspeed_bonus:DeclareFunctions()
	return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end

function modifier_persona_attackspeed_bonus:GetModifierAttackSpeedBonus_Constant(params)
	-- print(self.speed_bonus)
	return self.attackspeed_bonus
end

function modifier_persona_attackspeed_bonus:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end