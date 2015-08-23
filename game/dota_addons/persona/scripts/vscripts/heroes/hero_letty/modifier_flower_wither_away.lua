modifier_flower_wither_away = class({})

function modifier_flower_wither_away:IsHidden()
	return true
end

function modifier_flower_wither_away:DeclareFunctions()
	return { MODIFIER_PROPERTY_HEALTH_BONUS }
end

function modifier_flower_wither_away:GetModifierHealthBonus(params)
	-- if IsServer() then
		local target = self:GetParent()
		return target.flower_wither_health_bonus
	-- end
end