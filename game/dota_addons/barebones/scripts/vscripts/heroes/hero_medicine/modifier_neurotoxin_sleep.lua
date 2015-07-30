modifier_neurotoxin_sleep = class({})

function modifier_neurotoxin_sleep:OnCreated( kv )
	if IsServer() then
	end
end

function modifier_neurotoxin_sleep:OnIntervalThink()
	if IsServer() then
	end
end

function modifier_neurotoxin_sleep:IsHidden()
	return false
end

function modifier_neurotoxin_sleep:IsPurgable()
	return true
end

function modifier_neurotoxin_sleep:IsDebuff()
	return true
end

function modifier_neurotoxin_sleep:IsStunDebuff()
	return true
end

-- Stunned state

function modifier_neurotoxin_sleep:CheckState()
	local state = {
	[MODIFIER_STATE_STUNNED] = true,
	[MODIFIER_STATE_LOW_ATTACK_PRIORITY] = true,
	}

	return state
end

-- Sleep animation and particle

function modifier_neurotoxin_sleep:DeclareFunctions()
	return { MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
				MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_neurotoxin_sleep:GetOverrideAnimation( params )
	return ACT_DOTA_DISABLED
end

function modifier_neurotoxin_sleep:GetEffectName()
	return "particles/generic_gameplay/generic_sleep.vpcf"
end

function modifier_neurotoxin_sleep:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

-- Wake up if damaged

function modifier_neurotoxin_sleep:OnTakeDamage(params)
	if IsServer() then
		if self:GetParent() == params.unit then
			self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_neurotoxin", {duration = self:GetRemainingTime()})
			self:Destroy()
		
			-- print("--------------------")
			-- for k,v in pairs(params) do
			-- 	print(k, ": ", v)
			-- end
		end
		-- print("-----")
		-- print(params.unit:GetAbsOrigin(), params.attacker:GetAbsOrigin())
		-- print(self:GetParent(), self:GetCaster(), params.attacker, params.unit)
	end
end