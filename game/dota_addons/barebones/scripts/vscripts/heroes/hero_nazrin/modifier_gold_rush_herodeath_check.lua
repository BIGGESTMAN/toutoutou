modifier_gold_rush_herodeath_check = class({})

function modifier_gold_rush_herodeath_check:DeclareFunctions()
	return { MODIFIER_EVENT_ON_DEATH }
end

function modifier_gold_rush_herodeath_check:OnDeath(params)
	if IsServer() then
		local target = params.unit
		local mound = self:GetParent()
		local radius = self:GetAbility():GetSpecialValueFor("hero_kill_search_radius")
		local distance = (target:GetAbsOrigin() - mound:GetAbsOrigin()):Length2D()
		if target:IsRealHero() and distance <= radius then
			mound.heroes_killed = mound.heroes_killed + 1
		end
	end
end

function modifier_gold_rush_herodeath_check:IsHidden()
	return true
end