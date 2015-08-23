LinkLuaModifier("modifier_storm_clouds_modifier_checker", "heroes/hero_ichirin/modifier_storm_clouds_modifier_checker.lua", LUA_MODIFIER_MOTION_NONE )

function modifierGained(keys)
	local caster = keys.caster
	caster:AddNewModifier(caster, keys.ability, "modifier_storm_clouds_modifier_checker", {})
	if not caster.storm_clouds_stacks then caster.storm_clouds_stacks = {} end
end

function updateStacks(keys)
	local caster = keys.caster
	local ability = keys.ability

	for i=1,#caster.storm_clouds_stacks do
		caster.storm_clouds_stacks[i] = caster.storm_clouds_stacks[i] - 0.03
	end
	for k,stack_duration in pairs(caster.storm_clouds_stacks) do
		if stack_duration < 0 then
			table.remove(caster.storm_clouds_stacks, k)
		end
	end

	-- print(#caster.storm_clouds_stacks)
	if #caster.storm_clouds_stacks > 0 then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_storm_clouds_stacks", {})
		local old_stack_count = caster:GetModifierStackCount("modifier_storm_clouds_stacks", caster)
		local new_stack_count = #caster.storm_clouds_stacks
		caster:SetModifierStackCount("modifier_storm_clouds_stacks", caster, new_stack_count)
		if new_stack_count ~= old_stack_count then
			caster:FindModifierByName("modifier_storm_clouds_stacks"):SetDuration(caster.storm_clouds_stacks[1], true)
		end
	else
		caster:RemoveModifierByName("modifier_storm_clouds_stacks")
	end
end

function removeStacks(keys)
	keys.caster.storm_clouds_stacks = {}
end

function stormCloudsCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local base_duration = ability:GetLevelSpecialValueFor("active_duration_base", ability_level)
	local bonus_duration = ability:GetLevelSpecialValueFor("active_duration_bonus", ability_level)
	local stack_count = #caster.storm_clouds_stacks

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_storm_clouds_active", {duration = base_duration + bonus_duration * stack_count})
end