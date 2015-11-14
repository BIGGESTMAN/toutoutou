function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_hells_tokamak_active", {})
	caster:FindModifierByName("modifier_hells_tokamak_active").starting_health = caster:GetHealth()
end

function restoreHealth(keys)
	local caster = keys.caster
	local ability = keys.ability

	local regen_per_second = ability:GetSpecialValueFor("health_regen")
	local update_interval = ability:GetSpecialValueFor("update_interval")
	local radius = ability:GetSpecialValueFor("radius")

	local team = caster:GetTeamNumber()
	local origin = caster:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
	for k,unit in pairs(targets) do
		unit:Heal(regen_per_second * update_interval, caster)
	end
	DebugDrawCircle(origin, Vector(0,255,0), 5, radius, true, 0.2)
end

function checkHealthThreshold(keys)
	local caster = keys.caster
	local ability = keys.ability

	local immunity_health_threshold = ability:GetSpecialValueFor("immunity_health_threshold")

	if caster:GetHealth() / caster:FindModifierByName("modifier_hells_tokamak_active").starting_health < immunity_health_threshold / 100 then
		caster:RemoveModifierByName("modifier_hells_tokamak_active")
	end
end