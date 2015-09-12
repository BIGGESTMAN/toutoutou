require "heroes/hero_marisa/sparks"

function blazingStarStart( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local speed = ability:GetLevelSpecialValueFor("speed", ability_level) * 0.03
	local traveled_distance = 0
	local caught_target = false
	local direction = nil

	ability:ApplyDataDrivenModifier(caster, caster, keys.dashing_modifier, {})
	
	local master_spark_ability = caster:FindAbilityByName("master_spark")
	if master_spark_ability:GetLevel() > 0 then
		startSpark(caster, master_spark_ability, "modifier_master_spark", "modifier_master_spark_slow", true, caster:GetForwardVector() * -1, master_spark_ability, "particles/marisa/master_spark.vpcf")
	end

	-- Enable reverse-direction ability
	local main_ability_name	= ability:GetAbilityName()
	local sub_ability_name	= keys.reverse_ability_name
	caster:SwapAbilities(main_ability_name, sub_ability_name, false, true)
	caster:FindAbilityByName(sub_ability_name):SetActivated(true)

	-- Moving the caster
	Timers:CreateTimer(0, function()
		local target = keys.target

		local distance = ability:GetLevelSpecialValueFor("travel_distance", ability_level)

		if traveled_distance < distance then

			if (not direction) or caster:HasModifier(keys.reversed_modifier) then
				direction = caster:GetForwardVector()
			end
			local target_distance = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()

			if not caught_target then
				-- Check if target is in range to be caught
				if not caster:HasModifier(keys.reversed_modifier) then
					direction = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
				end

				if target_distance < ability:GetLevelSpecialValueFor("catch_radius", ability_level) then
					caught_target = true
					ability:ApplyDataDrivenModifier(caster, target, keys.caught_modifier, {})
				end
			else
				-- Pull caught target
				local drag_distance = ability:GetLevelSpecialValueFor("drag_distance", ability_level)
				local target_direction = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
				if (target_distance > drag_distance) then
					target:SetAbsOrigin(caster:GetAbsOrigin() + (target_distance - drag_distance) * target_direction)
				end
			end

			caster:SetAbsOrigin(caster:GetAbsOrigin() + direction * speed)
			traveled_distance = traveled_distance + speed

			return 0.03
		else
			FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), false)
			FindClearSpaceForUnit(target, target:GetAbsOrigin(), false)
			caster:RemoveModifierByName(keys.dashing_modifier)
			caster:RemoveModifierByName(keys.reversed_modifier)
			target:RemoveModifierByName(keys.caught_modifier)

			caster:SwapAbilities(main_ability_name, sub_ability_name, true, false)
		end
	end)
end

function reverse(keys)
	local caster = keys.caster
	caster:SetForwardVector(caster:GetForwardVector() * -1)
	caster:FindAbilityByName(keys.reverse_ability_name):SetActivated(false)
	keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_blazing_star_reversed", {})
end

function displayModifiers(hero)
	print("modifiers:")
	for i=1,hero:GetModifierCount() do
		print(hero:GetModifierNameByIndex(i - 1))
	end
end

function onUpgrade(keys)
	local reverse_ability = keys.caster:FindAbilityByName(keys.reverse_ability)
	if reverse_ability:GetLevel() < 1 then
		reverse_ability:SetLevel(1)
	end
end