modifier_persona_range_bonus = class({})

function modifier_persona_range_bonus:IsHidden()
	return true
end

function modifier_persona_range_bonus:DeclareFunctions()
	return { MODIFIER_PROPERTY_ATTACK_RANGE_BONUS }
end

function modifier_persona_range_bonus:GetModifierAttackRangeBonus(params)
	return self.range_bonus
end

function modifier_persona_range_bonus:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end