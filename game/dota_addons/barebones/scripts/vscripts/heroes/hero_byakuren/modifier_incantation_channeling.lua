modifier_incantation_channeling = class({})

function modifier_incantation_channeling:CheckState()
	local state = {
	[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
	}

	return state
end

function modifier_incantation_channeling:IsHidden()
	return true
end