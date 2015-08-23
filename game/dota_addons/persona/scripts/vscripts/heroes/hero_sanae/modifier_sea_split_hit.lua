modifier_sea_split_hit = class({})

function modifier_sea_split_hit:OnCreated( kv )
	if IsServer() then
		self.knockback_direction = Vector(kv.x, kv.y, kv.z)
		self:StartIntervalThink(self:GetAbility():GetLevelSpecialValueFor("update_interval", self:GetAbility():GetLevel() - 1))
		self.time_stunned = 0
	end
end

function modifier_sea_split_hit:IsHidden()
	return false
end

function modifier_sea_split_hit:IsPurgable()
	return false
end

function modifier_sea_split_hit:OnIntervalThink()
	if IsServer() then
		local caster = self:GetCaster()
		local target = self:GetParent()
		local ability = self:GetAbility()
		local ability_level = ability:GetLevel() - 1
		local speed = ability:GetLevelSpecialValueFor("knockback_speed", ability_level)
		local distance = ability:GetLevelSpecialValueFor("knockback_distance", ability_level)
		local direction = self.knockback_direction

		local duration = distance / speed

		if self.time_stunned < duration then
			target:SetAbsOrigin(target:GetAbsOrigin() + direction * speed * 0.03)
			self.time_stunned = self.time_stunned + 0.03
			return 0.03
		else
			target:RemoveModifierByName("modifier_sea_split_hit")
			FindClearSpaceForUnit(target, target:GetAbsOrigin(), false)
		end
	end
end

function modifier_sea_split_hit:CheckState()
	local state = {
	[MODIFIER_STATE_STUNNED] = true,
	}

	return state
end

function modifier_sea_split_hit:DeclareFunctions()
	return { MODIFIER_PROPERTY_OVERRIDE_ANIMATION }
end

function modifier_sea_split_hit:GetOverrideAnimation( params )
	return ACT_DOTA_FLAIL
end