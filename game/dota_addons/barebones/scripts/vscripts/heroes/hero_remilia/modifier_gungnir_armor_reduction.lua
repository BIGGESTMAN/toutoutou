modifier_gungnir_armor_reduction = class({})

function modifier_gungnir_armor_reduction:IsPurgable()
	return true
end

function modifier_gungnir_armor_reduction:IsDebuff()
	return true
end

function modifier_gungnir_armor_reduction:DeclareFunctions()
	return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS  }
end

function modifier_gungnir_armor_reduction:GetModifierPhysicalArmorBonus(params)
	if IsServer() then
		local ability = self:GetAbility()
		local ability_level = ability:GetLevel() - 1
		return ability:GetLevelSpecialValueFor("base_armor_reduction", ability_level) * math.pow(ability:GetLevelSpecialValueFor("bonus_armor_reduction", ability_level), self:GetStackCount() - 1) * -1
	end
end