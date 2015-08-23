modifier_demarcation_affected = class({})

function modifier_demarcation_affected:OnCreated( kv )
	if IsServer() then
		self.trigger_counts = {}
	end
end

function modifier_demarcation_affected:IsHidden()
	return true
end

function modifier_demarcation_affected:IsPurgable()
	return false
end

function modifier_demarcation_affected:DeclareFunctions()
	return { MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_demarcation_affected:OnTakeDamage(params)
	if IsServer() then
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		local ability_level = ability:GetLevel() - 1
		if  self:GetParent() == params.unit and params.damage_type == DAMAGE_TYPE_MAGICAL and
			not params.unit:HasModifier("modifier_demarcation_cooldown") and
			(not self.trigger_counts[params.unit] or self.trigger_counts[params.unit] < ability:GetLevelSpecialValueFor("max_triggers", ability_level)) then

			ability:ApplyDataDrivenModifier(caster, params.unit, "modifier_demarcation_root", {})
			ability:ApplyDataDrivenModifier(caster, params.unit, "modifier_demarcation_cooldown", {})
			
			local damage = ability:GetLevelSpecialValueFor("damage", ability_level)
			local damage_type = ability:GetAbilityDamageType()
			ApplyDamage({victim = params.unit, attacker = caster, damage = damage, damage_type = damage_type})

			if not self.trigger_counts[params.unit] then self.trigger_counts[params.unit] = 0 end
			self.trigger_counts[params.unit] = self.trigger_counts[params.unit] + 1

			-- Particle
			local particle = ParticleManager:CreateParticle("particles/demarcation_root.vpcf", PATTACH_ABSORIGIN, params.unit)
		end
	end
end