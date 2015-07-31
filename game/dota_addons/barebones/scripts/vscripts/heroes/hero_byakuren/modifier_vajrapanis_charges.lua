modifier_vajrapanis_charges = class({})

function modifier_vajrapanis_charges:OnCreated( kv )
	if IsServer() then
	end
end

function modifier_vajrapanis_charges:OnIntervalThink()
	if IsServer() then
	end
end

function modifier_vajrapanis_charges:IsHidden()
	return false
end

function modifier_vajrapanis_charges:IsPurgable()
	return false
end