modifier_busy_rod_revealed = class({})

function modifier_busy_rod_revealed:OnCreated( kv )
	if IsServer() then
		local ability = self:GetAbility()
		local caster = self:GetCaster()

		self:GetParent():AddNewModifier(caster, ability, "modifier_truesight", {duration = self:GetDuration()})
		-- self:StartIntervalThink(ability:GetSpecialValueFor("update_interval"))
	end
end

function modifier_busy_rod_revealed:OnRefresh( kv )
	if IsServer() then
		local ability = self:GetAbility()
		local caster = self:GetCaster()

		self:GetParent():AddNewModifier(caster, ability, "modifier_truesight", {duration = self:GetDuration()})
		-- self:StartIntervalThink(ability:GetSpecialValueFor("update_interval"))
	end
end

-- function modifier_busy_rod_revealed:OnIntervalThink()
-- 	if IsServer() then
-- 		local caster = self:GetCaster()
-- 		local ability = self:GetAbility()
-- 		local target = self:GetParent()

-- 		local vision_radius = target:GetDayTimeVisionRange()
-- 		if not GameRules:IsDaytime() then vision_radius = target:GetNightTimeVisionRange() end
-- 		local vision_duration = ability:GetSpecialValueFor("update_interval")
-- 		AddFOWViewer(caster:GetTeamNumber(), target:GetAbsOrigin(), vision_radius, vision_duration, not target:HasFlyingVision())
-- 	end
-- end

function modifier_busy_rod_revealed:IsDebuff()
	return true
end

function modifier_busy_rod_revealed:CheckState()
	local state = {
	[MODIFIER_STATE_PROVIDES_VISION] = true,
	}
 
	return state
end

-- function modifier_busy_rod_revealed:IsHidden()
-- 	return false
-- end

-- function modifier_busy_rod_revealed:DeclareFunctions()
-- 	return { MODIFIER_PROPERTY_PROVIDES_FOW_POSITION  }
-- end

-- function modifier_busy_rod_revealed:GetModifierProvidesFOWVision(params)
-- 	return 1
-- end