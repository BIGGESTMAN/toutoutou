function finalSparkStart(event)
	local caster = event.caster
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1
	local particleName = "particles/units/heroes/hero_phoenix/phoenix_sunray.vpcf"
	ability.particles = {}

	local pfx = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN_FOLLOW, caster )
	table.insert(ability.particles, pfx)
	ParticleManager:SetParticleControlEnt( pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true )

	local range = ability:GetLevelSpecialValueFor("range", ability_level) + ability:GetLevelSpecialValueFor("end_radius", ability_level)
	local endcapPos = caster:GetAbsOrigin() + caster:GetForwardVector() * range
	ParticleManager:SetParticleControl( pfx, 1, endcapPos )

	ability.sound_dummy = CreateUnitByName( "npc_dota_invisible_vision_source", endcapPos, false, caster, caster, caster:GetTeam() )
	ability:ApplyDataDrivenModifier(caster, ability.sound_dummy, event.sound_dummy_modifier, {})
	StartSoundEvent("Touhou.Spark", ability.sound_dummy )

	local rotationPoint = caster:GetAbsOrigin() + caster:GetForwardVector() * ability:GetLevelSpecialValueFor("range", ability_level)
	for i=1,3 do
		if i % 2 == 1 then
			local secondarypfx = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN_FOLLOW, caster )
			table.insert(ability.particles, secondarypfx)
			ParticleManager:SetParticleControlEnt( secondarypfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true )

			secondaryLaserPoint = RotatePosition(endcapPos, QAngle(0,i * 90,0), rotationPoint)
			ParticleManager:SetParticleControl( secondarypfx, 1, secondaryLaserPoint )
		end
	end
end

function finalSparkEnd(event)
	for k,particle in pairs(event.ability.particles) do
		ParticleManager:DestroyParticle(particle, false)
	end
	StopSoundEvent("Touhou.Spark", event.ability.sound_dummy)
end

function finalSparkCancelled(event)
	for k,particle in pairs(event.ability.particles) do
		ParticleManager:DestroyParticle(particle, true)
	end
end

function finalSpark(event)
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local level = ability:GetLevel() - 1
	local start_radius = ability:GetLevelSpecialValueFor("start_radius", level )
	local end_radius = ability:GetLevelSpecialValueFor("end_radius", level )
	local end_distance = ability:GetLevelSpecialValueFor("range", level )
	local damage = ability:GetLevelSpecialValueFor("damage", level) * ability:GetLevelSpecialValueFor("damage_interval", level) /
																	  ability:GetLevelSpecialValueFor("duration", level)
	local AbilityDamageType = ability:GetAbilityDamageType()
	local cone_units = GetEnemiesInCone( caster, start_radius, end_radius, end_distance )
	for _,unit in pairs(cone_units) do
		-- Particle
		-- local origin = unit:GetAbsOrigin()
		-- local lightningBolt = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, caster)
		-- ParticleManager:SetParticleControl(lightningBolt,0,Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z + caster:GetBoundingMaxs().z ))	
		-- ParticleManager:SetParticleControl(lightningBolt,1,Vector(origin.x,origin.y,origin.z + unit:GetBoundingMaxs().z ))
	
		-- Damage
		ApplyDamage({ victim = unit, attacker = caster, damage = damage, damage_type = AbilityDamageType})
		ability:ApplyDataDrivenModifier(caster, unit, event.stun_modifier, {})

		-- Particle
		local pfx = ParticleManager:CreateParticle( event.burn_particle, PATTACH_ABSORIGIN, unit )
		ParticleManager:SetParticleControlEnt( pfx, 1, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true )
		ParticleManager:ReleaseParticleIndex( pfx )
	end

	-- update particles for if Marisa is moved
	local range = end_distance + end_radius
	local rotationPoint = caster:GetAbsOrigin() + caster:GetForwardVector() * end_distance
	local laserPoints = {}
	laserPoints[1] = caster:GetAbsOrigin() + caster:GetForwardVector() * range
	
	for i=1,3 do
		if i % 2 == 1 then
			table.insert(laserPoints, RotatePosition(laserPoints[1], QAngle(0,i * 90,0), rotationPoint))
		end
	end

	for k,particle in pairs(event.ability.particles) do
		ParticleManager:SetParticleControl(particle, 1, laserPoints[k])
	end
end

function GetEnemiesInCone( unit, start_radius, end_radius, end_distance)
	local DEBUG = false
	
	-- Positions
	local fv = unit:GetForwardVector()
	local origin = unit:GetAbsOrigin()

	local start_point = origin + fv * start_radius -- Position to find units with start_radius
	local end_point = origin + fv * (start_radius + end_distance) -- Position to find units with end_radius

	if DEBUG then
		DebugDrawCircle(start_point, Vector(255,0,0), 5, start_radius, true, 1)
		DebugDrawCircle(end_point, Vector(255,0,0), 5, end_radius, true, 1)
	end

	-- 1 medium circle should be enough as long as the mid_interval isn't too large
	local mid_interval = end_distance - start_radius - end_radius
	local mid_radius = (start_radius + end_radius) / 2
	local mid_point = origin + fv * mid_radius * 2
	
	if DEBUG then
		--print("There's a space of "..mid_interval.." between the circles at the cone edges")
		DebugDrawCircle(mid_point, Vector(0,255,0), 5, mid_radius, true, 1)
	end

	-- Find the units
	local team = unit:GetTeamNumber()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER

	local start_units = FindUnitsInRadius(team, start_point, nil, start_radius, iTeam, iType, iFlag, iOrder, false)
	local end_units = FindUnitsInRadius(team, end_point, nil, end_radius, iTeam, iType, iFlag, iOrder, false)
	local mid_units = FindUnitsInRadius(team, mid_point, nil, mid_radius, iTeam, iType, iFlag, iOrder, false)

	-- Join the tables
	local cone_units = {}
	for k,v in pairs(end_units) do
		table.insert(cone_units, v)
	end

	for k,v in pairs(start_units) do
		if not tableContains(cone_units, v) then
			table.insert(cone_units, v)
		end
	end	

	for k,v in pairs(mid_units) do
		if not tableContains(cone_units, v) then
			table.insert(cone_units, v)
		end
	end

	--	DeepPrintTable(cone_units)

	return cone_units
end

-- Returns true if the element can be found on the list, false otherwise
function tableContains(list, element)
    if list == nil then return false end
    for i=1,#list do
        if list[i] == element then
            return true
        end
    end
    return false
end