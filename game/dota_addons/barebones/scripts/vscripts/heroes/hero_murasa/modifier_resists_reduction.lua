modifier_resists_reduction = class({})

function modifier_resists_reduction:IsHidden()
	return true
end

function modifier_resists_reduction:IsPurgable()
	return false
end

function modifier_resists_reduction:DeclareFunctions()
	return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS }
end

function modifier_resists_reduction:GetModifierMagicalResistanceBonus(params)
	if IsServer() then
		local ability = self:GetAbility()
		local ability_level = ability:GetLevel() - 1
		return ability:GetLevelSpecialValueFor("resists_reduction", ability_level) * -1
	end
end

function modifier_resists_reduction:GetModifierPhysicalArmorBonus(params)
	if IsServer() then
		local target = self:GetParent()
		local ability = self:GetAbility()
		local ability_level = ability:GetLevel() - 1
		local target_armor = target:GetPhysicalArmorBaseValue()
		if target:IsHero() then target_armor = target_armor + target:GetAgility() end
		return target_armor * ability:GetLevelSpecialValueFor("resists_reduction", ability_level) * -.01
	end
end