require "libraries/util"

function moonlightRay(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local start_radius = ability:GetLevelSpecialValueFor("start_radius", ability_level )
	local end_radius = ability:GetLevelSpecialValueFor("end_radius", ability_level )
	local end_distance = ability:GetLevelSpecialValueFor("range", ability_level )
	local damage = ability:GetLevelSpecialValueFor("damage", ability_level)
	local damage_type = ability:GetAbilityDamageType()

	local caster_forward = caster:GetForwardVector()

	local cone_units = GetEnemiesInCone( caster, start_radius, end_radius, end_distance, caster_forward)
	for _,unit in pairs(cone_units) do
	
		-- Damage
		ApplyDamage({ victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
		ability:ApplyDataDrivenModifier(caster, unit, keys.slow_modifier, {})

		-- Particle
		-- local particle = ParticleManager:CreateParticle(keys.burn_particle, PATTACH_ABSORIGIN, unit )
		-- ParticleManager:SetParticleControlEnt( particle, 1, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true )
		-- ParticleManager:ReleaseParticleIndex( particle )
	end

	local dummy_unit = CreateUnitByName("npc_dota_invisible_vision_source", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeam())
	ability:ApplyDataDrivenModifier(caster, dummy_unit, keys.dummy_modifier, {})

	local vertical_distance = 75
	dummy_unit:SetAbsOrigin(caster:GetAbsOrigin() + Vector(0,0,vertical_distance))
	local angle = VectorToAngles(caster_forward)
	dummy_unit:SetAngles(90,angle.y,0)

	local particle = ParticleManager:CreateParticle(keys.particle_name, PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControlEnt(particle, 1, dummy_unit, PATTACH_POINT_FOLLOW, "attach_hitloc", dummy_unit:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(particle, 5, dummy_unit, PATTACH_POINT_FOLLOW, "attach_hitloc", dummy_unit:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(particle, 6, dummy_unit, PATTACH_POINT_FOLLOW, "attach_hitloc", dummy_unit:GetAbsOrigin(), true)
	-- time out particle dummy after a while
	Timers:CreateTimer(5, function()
		dummy_unit:RemoveSelf()
	end)
end

function GetEnemiesInCone(unit, start_radius, end_radius, end_distance, caster_forward)
	local DEBUG = false
	
	-- Positions
	local fv = caster_forward
	local origin = unit:GetAbsOrigin()

	local start_point = origin + fv * start_radius -- Position to find units with start_radius
	local end_point = origin + fv * (start_radius + end_distance) -- Position to find units with end_radius

	if DEBUG then
		DebugDrawCircle(start_point, Vector(255,0,0), 5, start_radius, true, 1)
		DebugDrawCircle(end_point, Vector(255,0,0), 5, end_radius, true, 1)
	end

	local intermediate_circles = {}
	local number_of_intermediate_circles = 3
	for i=1,number_of_intermediate_circles do
		local radius = start_radius + (end_radius - start_radius) / (number_of_intermediate_circles + 1) * i
		local point = origin + fv * (end_distance / (number_of_intermediate_circles + 1) * i + start_radius)
		intermediate_circles[i] = {point = point, radius = radius}
	end
	
	if DEBUG then
		for k,circle in pairs(intermediate_circles) do 
			DebugDrawCircle(circle.point, Vector(0,255,0), 5, circle.radius, true, 1)
		end
	end

	local cone_units = {}
	-- Find the units
	local team = unit:GetTeamNumber()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER

	local start_units = FindUnitsInRadius(team, start_point, nil, start_radius, iTeam, iType, iFlag, iOrder, false)
	local end_units = FindUnitsInRadius(team, end_point, nil, end_radius, iTeam, iType, iFlag, iOrder, false)

	-- Join the tables
	for k,v in pairs(end_units) do
		table.insert(cone_units, v)
	end

	for k,v in pairs(start_units) do
		if not tableContains(cone_units, v) then
			table.insert(cone_units, v)
		end
	end

	for k,circle in pairs(intermediate_circles) do
		local units = FindUnitsInRadius(team, circle.point, nil, circle.radius, iTeam, iType, iFlag, iOrder, false)
		for k,v in pairs(units) do
			if not tableContains(cone_units, v) then
				table.insert(cone_units, v)
			end
		end
	end

	--	DeepPrintTable(cone_units)

	return cone_units
end

function checkBonusDamageProc(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local proc_modifier = keys.proc_modifier
	local damage = ability:GetLevelSpecialValueFor("bonus_damage", ability_level)
	local damage_type = ability:GetAbilityDamageType()

	if not caster:CanEntityBeSeenByMyTeam(target) and not target:HasModifier(proc_modifier) then
		ApplyDamage({victim = target, attacker = caster, damage = damage, damage_type = damage_type})
		ability:ApplyDataDrivenModifier(caster, target, proc_modifier, {})
	end
end