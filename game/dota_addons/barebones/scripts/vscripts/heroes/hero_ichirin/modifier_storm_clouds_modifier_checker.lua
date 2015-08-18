modifier_storm_clouds_modifier_checker = class({})

function modifier_storm_clouds_modifier_checker:IsHidden()
	return true
end

function modifier_storm_clouds_modifier_checker:DeclareFunctions()
	return { MODIFIER_EVENT_ON_STATE_CHANGED }
end

function modifier_storm_clouds_modifier_checker:OnStateChanged(params)
	if IsServer() then
		-- print("STATE CHANGED --------------------------------------------------")
		-- for k,v in pairs(params) do
		-- 	print(k,v)
		-- end

		local caster = self:GetParent()
		if params.unit == caster and params.gain == 0 then
			local ability = self:GetAbility()
			local ability_level = ability:GetLevel() - 1
			local stack_duration = ability:GetLevelSpecialValueFor("stack_duration", ability_level)
			table.insert(caster.storm_clouds_stacks, stack_duration)
			if #caster.storm_clouds_stacks > ability:GetLevelSpecialValueFor("max_stacks", ability_level) then
				table.remove(caster.storm_clouds_stacks, 1)
			end
		end
	end
end