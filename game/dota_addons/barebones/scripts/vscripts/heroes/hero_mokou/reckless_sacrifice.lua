require "libraries/util"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability

	local flames = ability:GetSpecialValueFor("flames")

	for i=1,flames do
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_reckless_sacrifice_flame", {})
	end
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_reckless_sacrifice_tracker", {})
end

function attackLanded(keys)
	local caster = keys.caster
	local attacker = keys.attacker
	local target = keys.target
	local ability = keys.ability
	if caster == attacker then
		caster:FindModifierByName("modifier_reckless_sacrifice_flame"):Destroy()

		ability:ApplyDataDrivenModifier(caster, target, "modifier_reckless_sacrifice_flame", {})
		local flame_stacks = getNumberOfModifierInstances(target, "modifier_reckless_sacrifice_flame")
		if flame_stacks >= 2 then
			ability:ApplyDataDrivenModifier(caster, target, "modifier_reckless_sacrifice_damage_reduction", {})
		end
		if flame_stacks >= 3 then
			ability:ApplyDataDrivenModifier(caster, target, "modifier_reckless_sacrifice_disarm", {})
		end
	end
end

function flameEnded(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	local flame_stacks = getNumberOfModifierInstances(target, "modifier_reckless_sacrifice_flame")
	if flame_stacks < 3 then
		target:RemoveModifierByName("modifier_reckless_sacrifice_disarm")
	end
	if flame_stacks < 2 then
		target:RemoveModifierByName("modifier_reckless_sacrifice_damage_reduction")
	end

	if not target:HasModifier("modifier_reckless_sacrifice_flame") then
		target:RemoveModifierByName("modifier_reckless_sacrifice_tracker")
	end
end