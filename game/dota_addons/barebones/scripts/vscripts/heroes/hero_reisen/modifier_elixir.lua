modifier_elixir = class({})

function modifier_elixir:IsHidden()
	return false
end

function modifier_elixir:IsPurgable()
	return false
end

function modifier_elixir:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS }
end

function modifier_elixir:GetModifierBonusStats_Strength( params )
	if IsServer() then
		if self:GetParent():GetPrimaryAttribute() == 0 then
			return self:GetAbility():GetLevelSpecialValueFor("attribute_bonus", self:GetAbility():GetLevel() - 1) * 0.01 * self:GetParent():GetBaseStrength() * self:GetStackCount()
		else
			return 0
		end
	end
end

function modifier_elixir:GetModifierBonusStats_Agility( params )
	if IsServer() then
		if self:GetParent():GetPrimaryAttribute() == 1 then
			return self:GetAbility():GetLevelSpecialValueFor("attribute_bonus", self:GetAbility():GetLevel() - 1) * 0.01 * self:GetParent():GetBaseAgility()  * self:GetStackCount()
		else
			return 0
		end
	end
end

function modifier_elixir:GetModifierBonusStats_Intellect( params )
	if IsServer() then
		if self:GetParent():GetPrimaryAttribute() == 2 then
			return self:GetAbility():GetLevelSpecialValueFor("attribute_bonus", self:GetAbility():GetLevel() - 1) * 0.01 * self:GetParent():GetBaseIntellect()  * self:GetStackCount()
		else
			return 0
		end
	end
end