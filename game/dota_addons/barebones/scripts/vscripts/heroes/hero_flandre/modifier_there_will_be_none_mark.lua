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

		local vision_radius = 100

		local distance = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()
		if distance <= range then
			if not self.rope_particle then
				self.rope_particle = ParticleManager:CreateParticle("particles/flandre/there_will_be_none/rope.vpcf", PATTACH_POINT_FOLLOW, target)
				ParticleManager:SetParticleControlEnt(self.rope_particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
				ParticleManager:SetParticleControlEnt(self.rope_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
			end

			self.trigger_duration = self.trigger_duration - update_interval
			if self.trigger_duration <= 0 then
				ApplyDamage({victim = target, attacker = caster, damage = damage, damage_type = damage_type})
				self:Destroy()
				
				local bolt_particle = ParticleManager:CreateParticle("particles/flandre/there_will_be_none/bolt.vpcf", PATTACH_POINT_FOLLOW, caster)
				ParticleManager:SetParticleControlEnt(bolt_particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
				ParticleManager:SetParticleControlEnt(bolt_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
			end
		else
			self.trigger_duration = trigger_duration
			if self.rope_particle then
				ParticleManager:DestroyParticle(self.rope_particle, true)
				self.rope_particle = nil
			end
		end

		AddFOWViewer(caster:GetTeamNumber(), target:GetAbsOrigin(), vision_radius, update_interval, false)
	end
end

function modifier_there_will_be_none_mark:GetEffectName()
	return "particles/flandre/there_will_be_none/mark.vpcf"
end

function modifier_there_will_be_none_mark:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end