require "personas"

function SpellCast(keys)
	local caster = keys.caster
	local ability = CreateDummyAbility(caster, keys.ability)

	local radius = ability:GetSpecialValueFor("radius")
	local delay = ability:GetSpecialValueFor("delay")

	local team = caster:GetTeamNumber()
	local origin = caster:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	-- DebugDrawCircle(origin, Vector(180,40,40), 0.1, radius, true, 0.2)

	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

	local teleport_units = {}
	for k,unit in pairs(targets) do
		teleport_units[unit] = unit:GetAbsOrigin() - caster:GetAbsOrigin()
	end

	local destination = caster.mischiefPreviousLocations[#caster.mischiefPreviousLocations]
	caster:Stop()
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_mischief_vanish", {})
	caster:AddNoDraw()
	ParticleManager:CreateParticle("particles/spells/magic_mischief_vanish_smoke.vpcf", PATTACH_ABSORIGIN, caster)
	for unit,_ in pairs(teleport_units) do
		unit:Stop()
		ability:ApplyDataDrivenModifier(caster, unit, "modifier_mischief_vanish", {})
		unit:AddNoDraw()
		ParticleManager:CreateParticle("particles/spells/magic_mischief_vanish_smoke.vpcf", PATTACH_ABSORIGIN, unit)
	end

	local cast_circle_particle = ParticleManager:CreateParticle("particles/spells/magic_mischief_cast_circle.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(cast_circle_particle, 0, caster:GetAbsOrigin())

	local destination_circle_particle = ParticleManager:CreateParticle("particles/spells/magic_mischief_destination_circle.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(destination_circle_particle, 0, destination)

	Timers:CreateTimer(delay, function()
		FindClearSpaceForUnit(caster, destination, true)
		caster:RemoveModifierByName("modifier_mischief_vanish")
		caster:RemoveNoDraw()
		ParticleManager:CreateParticle("particles/spells/magic_mischief_vanish_smoke.vpcf", PATTACH_ABSORIGIN, caster)
		for unit,vector in pairs(teleport_units) do
			FindClearSpaceForUnit(unit, vector + destination, true)
			unit:RemoveModifierByName("modifier_mischief_vanish")
			unit:RemoveNoDraw()
		ParticleManager:CreateParticle("particles/spells/magic_mischief_vanish_smoke.vpcf", PATTACH_ABSORIGIN, unit)
		end
		local particle = ParticleManager:CreateParticle("particles/spells/magic_mischief_reappear.vpcf", PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(particle, 0, destination)
	end)
end

function UpdateLocation(keys)
	local caster = keys.caster
	local ability = keys.ability

	local update_interval = ability:GetSpecialValueFor("update_interval")
	local seconds_teleported = ability:GetSpecialValueFor("seconds_teleported")

	if not caster.mischiefPreviousLocations then caster.mischiefPreviousLocations = {} end
	table.insert(caster.mischiefPreviousLocations, 1, caster:GetAbsOrigin())
	if #caster.mischiefPreviousLocations > seconds_teleported / update_interval then
		table.remove(caster.mischiefPreviousLocations)
	end
end