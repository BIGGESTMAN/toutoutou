modifier_midnight_bird_ordercheck = class({})

function modifier_midnight_bird_ordercheck:IsHidden()
	return true
end

function modifier_midnight_bird_ordercheck:IsPurgable()
	return false
end

function modifier_midnight_bird_ordercheck:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ORDER  }
end

function modifier_midnight_bird_ordercheck:OnOrder(params)
	if IsServer() then
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		local ability_level = ability:GetLevel() - 1
		if params.order_type == 4 and params.unit == caster and params.target:IsHero() then
			local target = params.target
			local distance = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()
			if distance < ability:GetLevelSpecialValueFor("pull_range", ability_level) then
				ability:ApplyDataDrivenModifier(caster, target, "modifier_midnight_bird_eaten", {})
				target:AddNoDraw()
				caster.midnight_units_eaten[target] = true

				local playerID = target:GetPlayerID()
				PlayerResource:SetCustomTeamAssignment(playerID, 6)
			end
		end
	end
end