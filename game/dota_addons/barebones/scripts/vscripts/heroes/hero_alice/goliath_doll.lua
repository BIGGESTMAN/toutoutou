function spawnDoll(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local doll = CreateUnitByName("goliath_doll", keys.target_points[1], true, caster, caster, caster:GetTeamNumber())
	if not caster.goliath_dolls then caster.goliath_dolls = {} end
	caster.goliath_dolls[doll] = true
	doll:SetControllableByPlayer(caster:GetMainControllingPlayer(), true)
	ability:ApplyDataDrivenModifier(caster, doll, keys.modifier, {})

	if ability_level > 1 then
		doll:CreatureLevelUp(ability_level - 1)
	end

	local bash_ability = doll:FindAbilityByName(keys.bash_ability)
	bash_ability:SetLevel(ability_level)

	local cleave_ability = doll:FindAbilityByName(keys.cleave_ability)
	cleave_ability:SetLevel(1)

	ability:ApplyDataDrivenModifier(caster, doll, "modifier_kill", {duration = ability:GetLevelSpecialValueFor("duration", ability_level)})
end

function killDoll(keys)
	keys.caster.goliath_dolls[keys.target] = nil
end