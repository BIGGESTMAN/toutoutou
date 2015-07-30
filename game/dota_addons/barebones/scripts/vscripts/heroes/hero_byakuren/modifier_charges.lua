modifier_charges = class({})

function modifier_charges:OnCreated( kv )
	if IsServer() then
	end
end

function modifier_charges:OnIntervalThink()
	if IsServer() then
	end
end

function modifier_charges:IsHidden()
	return false
end

function modifier_charges:IsPurgable()
	return false
end