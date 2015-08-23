function openingWindHit( keys )
	local caster = keys.caster
	local ability = keys.ability

	if not caster:HasModifier(keys.modifier) then
		caster:FindAbilityByName(keys.sub_ability):SetActivated(true)
		ability:ApplyDataDrivenModifier(caster, caster, keys.modifier, {})
	end
end

function onUpgrade( keys )
	local caster = keys.caster
	local ability = keys.ability
	local illusionary_dominance_ability = caster:FindAbilityByName(keys.sub_ability)

	illusionary_dominance_ability:SetLevel(ability:GetLevel())

	if illusionary_dominance_ability:GetLevel() == 1 then
		illusionary_dominance_ability:SetActivated( false )
	end
end

function disableIllusionaryDominance( keys )
	keys.caster:FindAbilityByName(keys.sub_ability):SetActivated(false)
end