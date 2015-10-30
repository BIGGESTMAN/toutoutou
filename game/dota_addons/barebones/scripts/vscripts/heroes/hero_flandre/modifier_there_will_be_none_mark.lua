modifier_there_will_be_none_mark = class({})

function modifier_there_will_be_none_mark:OnCreated( kv )
	if IsServer() then
		local ability = self:GetAbility()

		self.trigger_duration = ability:GetSpecialValueFor("trigger_duration")
		self:StartIntervalThink(ability:GetSpecialValueFor("update_interval"))
	end
end

function modifier_there_will_be_none_mark:OnIntervalThink()
	if IsServer() then
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		local target = self:GetParent()

		local trigger_duration = ability:GetSpecialValueFor("trigger_duration")
		local update_interval = ability:GetSpecialValueFor("update_interval")
		local range = ability:GetSpecialValueFor("radius")
		local damage = target:GetMaxHealth() * ability:GetSpecialValueFor("hp_percent_as_damage") / 100
		local damage_type = ability:GetAbilityDamageType()

		local distance = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()
		if distance <= range then
			self.trigger_duration = self.trigger_duration - update_interval
			if self.trigger_duration <= 0 then
				ApplyDamage({victim = target, attacker = caster, damage = damage, damage_type = damage_type})
				self:Destroy()
			end
		else
			self.trigger_duration = trigger_duration
		end
	end
end