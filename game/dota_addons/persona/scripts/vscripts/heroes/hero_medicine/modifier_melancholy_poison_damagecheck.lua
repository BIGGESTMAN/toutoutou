modifier_melancholy_poison_damagecheck = class({})

function modifier_melancholy_poison_damagecheck:IsHidden()
	return true
end

function modifier_melancholy_poison_damagecheck:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_melancholy_poison_damagecheck:DeclareFunctions()
	return { MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_melancholy_poison_damagecheck:OnTakeDamage(params)
	if IsServer() then
		local caster = self:GetParent()
		if params.unit == caster then
			local ability = self:GetAbility()
			local ability_level = ability:GetLevel() - 1
			if ability:IsCooldownReady() and caster.venom > 0 and params.damage_type == DAMAGE_TYPE_MAGICAL then
				ability:ApplyDataDrivenModifier(caster, caster, "modifier_release_charging", {})
				ability:StartCooldown(ability:GetCooldown(ability_level))
			end
		end
	end
end