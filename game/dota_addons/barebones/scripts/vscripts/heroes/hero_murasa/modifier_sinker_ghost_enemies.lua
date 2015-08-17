-- Called _enemies because i'm lazy and it used to make sense -- just the lua, non-datadriven counterpark to modifier_sinker_ghost

modifier_sinker_ghost_enemies = class({})

function modifier_sinker_ghost_enemies:IsHidden()
	return true
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