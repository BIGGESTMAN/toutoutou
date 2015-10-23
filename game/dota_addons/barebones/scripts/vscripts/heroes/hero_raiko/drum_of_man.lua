function spellCast(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	local radius = ability:GetSpecialValueFor("radius")

	local team = caster:GetTeamNumber()
	local origin = target:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_BOTH
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
	DebugDrawCircle(origin, Vector(0,255,0), 1, radius, true, 0.2)
	for k,unit in pairs(targets) do
		if unit:GetTeamNumber() == team then
			ability:ApplyDataDrivenModifier(caster, unit, "modifier_drum_of_man_bonus_health", {})
		else
			ability:ApplyDataDrivenModifier(caster, unit, "modifier_drum_of_man_damage_reduction", {})
		end
	end

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_drum_of_man_cast_recently", {})
end