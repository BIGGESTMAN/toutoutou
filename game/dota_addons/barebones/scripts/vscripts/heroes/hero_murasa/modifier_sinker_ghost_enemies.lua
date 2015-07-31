modifier_sinker_ghost_enemies = class({})

function modifier_sinker_ghost_enemies:IsHidden()
	return false
end

function modifier_sinker_ghost_enemies:IsPurgable()
	return false
end

function modifier_sinker_ghost_enemies:DeclareFunctions()
	return { MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_sinker_ghost_enemies:OnTakeDamage(params)
	if IsServer() then
		if self:GetParent() == params.attacker then
			if params.damage_type == DAMAGE_TYPE_PHYSICAL then
				self:GetAbility():ApplyDataDrivenModifier(params.attacker, params.unit, "modifier_drowned", {})
			elseif params.damage_type == DAMAGE_TYPE_MAGICAL then
				self:GetAbility():ApplyDataDrivenModifier(params.attacker, params.unit, "modifier_drenched", {})
			end
		end
	end
end