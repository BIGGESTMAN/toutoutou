modifier_persona_health_bonus = class({})

function modifier_persona_health_bonus:IsHidden()
	return true
end

function modifier_persona_health_bonus:DeclareFunctions()
	return { MODIFIER_PROPERTY_HEALTH_BONUS }
end

function modifier_persona_health_bonus:GetModifierHealthBonus(params)
	return self.health_bonus
end