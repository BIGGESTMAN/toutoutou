function checkInvis(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target = keys.target

	local team = target:GetTeamNumber()
	local origin = target:GetAbsOrigin()
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	local iOrder = FIND_ANY_ORDER

	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

	if #targets < 1 then
		ability:ApplyDataDrivenModifier(caster, target, "modifier_northern_winner_invis", {})
	else
		target:RemoveModifierByName("modifier_northern_winner_invis")
	end
end