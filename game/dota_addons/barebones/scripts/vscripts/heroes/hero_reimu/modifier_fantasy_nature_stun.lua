modifier_fantasy_nature_stun = class({})

function modifier_fantasy_nature_stun:IsDebuff()
	return true
end

function modifier_fantasy_nature_stun:CheckState()
	local state = {
	[MODIFIER_STATE_STUNNED] = true,
	}
 
	return state
end

function modifier_fantasy_nature_stun:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION}
end

function modifier_fantasy_nature_stun:GetOverrideAnimation(params)
	return ACT_DOTA_DISABLED
end

function modifier_fantasy_nature_stun:GetEffectName()
	return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_fantasy_nature_stun:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end