modifier_incantation_channeling = class({})

function modifier_incantation_channeling:OnCreated( kv )
	if IsServer() then
	end
end

function modifier_incantation_channeling:OnIntervalThink()
	if IsServer() then
	end
end

function modifier_incantation_channeling:IsHidden()
	return true
end

function modifier_incantation_channeling:IsPurgable()
	return false
end