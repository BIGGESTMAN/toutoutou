modifier_veils_like_sky_windburn = class({})

function modifier_veils_like_sky_windburn:OnCreated( kv )
	if IsServer() then
		local ability = self:GetAbility()

		self:StartIntervalThink(ability:GetSpecialValueFor("elekiter_damage_interval"))
	end
end

function modifier_veils_like_sky_windburn:OnIntervalThink()
	if IsServer() then
		local unit = self:GetParent()
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		local damage = ability:GetSpecialValueFor("elekiter_damage")
		local damage_type = ability:GetAbilityDamageType()
		ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
		ability:ApplyDataDrivenModifier(caster, unit, "modifier_veils_like_sky_windburn_stun", {})
	end
end

function modifier_veils_like_sky_windburn:DeclareFunctions()
	return { MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_veils_like_sky_windburn:OnTakeDamage(params)
	if IsServer() then
		local target = self:GetParent()
		local caster = self:GetCaster()
		if params.unit == caster and params.attacker == target and params.damage_type == DAMAGE_TYPE_MAGICAL then
			self:Destroy()
		end
	end
end

function modifier_veils_like_sky_windburn:IsDebuff()
	return true
end

function modifier_veils_like_sky_windburn:IsPurgable()
	return true
end