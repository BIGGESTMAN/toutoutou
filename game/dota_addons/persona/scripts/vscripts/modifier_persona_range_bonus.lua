modifier_persona_range_bonus = class({})

function modifier_persona_range_bonus:IsHidden()
	return true
end

function modifier_persona_range_bonus:DeclareFunctions()
	return { MODIFIER_PROPERTY_ATTACK_RANGE_BONUS }
end

function modifier_persona_range_bonus:GetModifierAttackRangeBonus(params)
	if IsServer() then
		return self.range_bonus
	end
end