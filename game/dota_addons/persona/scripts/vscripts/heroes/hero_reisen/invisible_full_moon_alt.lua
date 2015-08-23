function checkCancelOrder(keys)
	local order_target = keys.target
	local caster = keys.caster
	local ability = keys.ability
	local unit = keys.unit

	local order_allowed = true

	if order_target then
		local team = caster:GetTeamNumber()
		local origin = caster:GetAbsOrigin()
		local iTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
		local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_ANY_ORDER
		local radius = 20100
		local allied_units = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

		for k,allied_unit in pairs(allied_units) do
			if allied_unit:GetPlayerOwnerID() == caster:GetPlayerID() and allied_unit == order_target then
				order_allowed = false
				break
			end
		end

		if not order_allowed then
			ability:ApplyDataDrivenModifier(caster, unit, "modifier_disable", {duration = 0.03})
			Timers:CreateTimer(0.03, function()
				unit:Stop()
			end)
		end
	end
end