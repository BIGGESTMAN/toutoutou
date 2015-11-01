function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability

	local radius = ability:GetSpecialValueFor("radius")

	local team = caster:GetTeamNumber()
	local origin = caster:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
	DebugDrawCircle(origin, Vector(0,255,0), 1, radius, true, 0.2)
	for k,unit in pairs(targets) do
		ability:ApplyDataDrivenModifier(caster, unit, "modifier_drum_of_earth_armor", {})
	end

	caster:RemoveModifierByName("modifier_drum_of_earth_cast_recently")
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_drum_of_earth_cast_recently", {})
end