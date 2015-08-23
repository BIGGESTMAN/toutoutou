modifier_dance_recastable = class({})

function modifier_dance_recastable:IsHidden()
	return false
end

function modifier_dance_recastable:IsPurgable()
	return false
end

-- Ability cooldown functionality, not currently used
-- function modifier_dance_recastable:OnDestroy()
-- 	if IsServer() then
-- 		print("rip modifier")
-- 		local time_elapsed = GameRules:GetGameTime() - self.initial_cast_time
-- 		print(time_elapsed)

-- 		local ability = self:GetAbility()
-- 		local ability_level = ability:GetLevel() - 1
-- 		local full_cooldown = ability:GetCooldown(ability_level)
-- 		self:GetAbility():StartCooldown(full_cooldown - time_elapsed)
-- 	end
-- end