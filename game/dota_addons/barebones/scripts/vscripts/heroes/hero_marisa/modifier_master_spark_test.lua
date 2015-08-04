modifier_master_spark_test = class({})

-- function modifier_master_spark_test:OnCreated(keys)

-- end

function modifier_master_spark_test:IsHidden()
	return false
end

function modifier_master_spark_test:IsPurgable()
	return false
end

function modifier_master_spark_test:DeclareFunctions()
	return { MODIFIER_EVENT_ON_STATE_CHANGED }
end

function modifier_master_spark_test:OnStateChanged(params)
	if IsServer() and params.unit == self:GetParent() then
		for k,v in pairs(params) do
			print(k,v)
		end
	end
end